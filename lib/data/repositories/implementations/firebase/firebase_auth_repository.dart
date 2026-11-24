import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../../../models/user_model.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../contracts/i_auth_repository.dart';

/// Persistence abstraction used by [FirebaseAuthRepository] so Cloud Firestore
/// reads/writes can be unit-tested cleanly without subclassing sealed SDK types.
abstract interface class FirebaseAuthUserStore {
  Future<Map<String, dynamic>?> getUserDoc(String uid);

  Future<void> setUserDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = true,
  });

  Future<void> setProviderVerificationDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = true,
  });
}

class _FirestoreAuthUserStore implements FirebaseAuthUserStore {
  final FirebaseFirestore _firestore;

  _FirestoreAuthUserStore(this._firestore);

  @override
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final doc =
        await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  Future<void> setUserDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(data, SetOptions(merge: merge));
  }

  @override
  Future<void> setProviderVerificationDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    await _firestore
        .collection(FirebaseAuthRepository.providerVerificationsCollection)
        .doc(uid)
        .set(data, SetOptions(merge: merge));
  }
}

typedef PhoneCredentialFactory = fb_auth.PhoneAuthCredential Function({
  required String verificationId,
  required String smsCode,
});

class FirebaseAuthRepository implements IAuthRepository {
  static const String providerVerificationsCollection =
      'provider_verifications';
  static final RegExp qatarQidRegex = RegExp(r'^[0-9]{11}$');
  static final RegExp qatarLocalPhoneRegex = RegExp(r'^[3567][0-9]{7}$');
  static final RegExp _otpSixDigitsRegex = RegExp(r'^[0-9]{6}$');

  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseAuthUserStore _userStore;
  final FirebaseFunctionsCallableClient? _injectedCallableClient;
  final bool _isWeb;
  final PhoneCredentialFactory _credentialFactory;

  fb_auth.ConfirmationResult? _webConfirmationResult;
  String? _pendingVerificationId;
  int? _resendToken;
  String? _pendingPhoneE164;
  fb_auth.UserCredential? _autoVerifiedCredential;
  bool _phoneAuthUnsupportedByStub = false;

  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseFunctionsCallableClient? callableClient,
  })  : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _userStore =
            _FirestoreAuthUserStore(firestore ?? FirebaseFirestore.instance),
        _injectedCallableClient = callableClient,
        _isWeb = kIsWeb,
        _credentialFactory = fb_auth.PhoneAuthProvider.credential;

  @visibleForTesting
  FirebaseAuthRepository.withUserStore({
    required fb_auth.FirebaseAuth firebaseAuth,
    required FirebaseAuthUserStore userStore,
    FirebaseFunctionsCallableClient? callableClient,
    bool? isWebOverride,
    PhoneCredentialFactory? credentialFactory,
  })  : _firebaseAuth = firebaseAuth,
        _userStore = userStore,
        _injectedCallableClient = callableClient,
        _isWeb = isWebOverride ?? kIsWeb,
        _credentialFactory =
            credentialFactory ?? fb_auth.PhoneAuthProvider.credential;

  FirebaseFunctionsCallableClient get _callableClient =>
      _injectedCallableClient ?? FirebaseFunctionsCallableClient();

  @override
  bool get isPhoneOtpSupported => !_phoneAuthUnsupportedByStub;

  static bool isValidQatarQid(String qid) => qatarQidRegex.hasMatch(qid.trim());

  /// Normalizes Arabic/Eastern digits and formats a Qatar mobile number (`[3567]xxxxxxx`)
  /// into strict E.164 format (`+974XXXXXXXX`). Throws [AuthException] on invalid input.
  static String normalizeQatarE164(String rawPhone) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var normalized = rawPhone.trim();
    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(arabicDigits[i], '$i');
      normalized = normalized.replaceAll(easternDigits[i], '$i');
    }
    normalized = normalized.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    String localDigits = normalized;
    if (localDigits.startsWith('+974')) {
      localDigits = localDigits.substring(4);
    } else if (localDigits.startsWith('00974')) {
      localDigits = localDigits.substring(5);
    } else if (localDigits.length == 11 && localDigits.startsWith('974')) {
      localDigits = localDigits.substring(3);
    }

    if (!qatarLocalPhoneRegex.hasMatch(localDigits)) {
      throw const AuthException(
        code: 'invalid-phone-number',
        messageAr:
            'رقم الجوال القطري غير صالح. يجب أن يتكون من 8 أرقام ويبدأ بـ 3 أو 5 أو 6 أو 7 (+974).',
        messageEn:
            'Invalid Qatar mobile number. Must be +974 followed by 8 digits starting with 3, 5, 6, or 7.',
      );
    }
    return '+974$localDigits';
  }

  static String extractQatarLocalDigits(String phoneOrE164) {
    final trimmed = phoneOrE164.trim();
    if (trimmed.startsWith('+974') && trimmed.length == 12) {
      return trimmed.substring(4);
    }
    return trimmed;
  }

  /// Maps [fb_auth.FirebaseAuthException] codes into clear bilingual [AuthException]s
  /// explaining SMS billing / console configuration status and suggesting Email+Password fallback.
  static AuthException mapFirebaseAuthException(
    fb_auth.FirebaseAuthException e,
  ) {
    final code = e.code.trim().toLowerCase();
    switch (code) {
      case 'billing-not-enabled':
        return const AuthException(
          code: 'billing-not-enabled',
          suggestEmailFallback: true,
          messageAr:
              'إرسال رسائل SMS (+974) يتطلب تفعيل فوترة الرسائل (Blaze Plan) في Firebase Console. يمكنك المتابعة فوراً بالبريد الإلكتروني وكلمة المرور.',
          messageEn:
              'SMS OTP (+974) requires SMS billing (Blaze plan) enabled in Firebase Console. Please sign in with Email & Password instead.',
        );
      case 'operation-not-allowed':
        return const AuthException(
          code: 'operation-not-allowed',
          suggestEmailFallback: true,
          messageAr:
              'مزود الدخول برقم الجوال غير مفعّل حالياً في Firebase Console. يرجى تسجيل الدخول بالبريد الإلكتروني وكلمة المرور.',
          messageEn:
              'Phone authentication is not enabled in Firebase Console. Please sign in with Email & Password instead.',
        );
      case 'quota-exceeded':
        return const AuthException(
          code: 'quota-exceeded',
          suggestEmailFallback: true,
          messageAr:
              'تم استنفاد الحصة اليومية لرسائل التحقق SMS في Firebase. يرجى المتابعة بالبريد الإلكتروني وكلمة المرور.',
          messageEn:
              'Firebase SMS quota has been exceeded for today. Please sign in with Email & Password instead.',
        );
      case 'too-many-requests':
        return const AuthException(
          code: 'too-many-requests',
          suggestEmailFallback: true,
          messageAr:
              'تم حظر الطلبات مؤقتاً لكثرة المحاولات. يرجى الانتظار قليلاً أو المتابعة بالبريد الإلكتروني وكلمة المرور.',
          messageEn:
              'Too many SMS verification requests from this device. Please wait or sign in with Email & Password.',
        );
      case 'invalid-verification-code':
        return const AuthException(
          code: 'invalid-verification-code',
          suggestEmailFallback: false,
          messageAr:
              'رمز التحقق غير صحيح. يرجى التأكد من الرمز المكون من 6 أرقام المرسل إلى جوالك.',
          messageEn:
              'Invalid 6-digit verification code. Please check the SMS code and try again.',
        );
      case 'session-expired':
      case 'code-expired':
        return const AuthException(
          code: 'session-expired',
          suggestEmailFallback: true,
          messageAr:
              'انتهت صلاحية رمز التحقق SMS. اطلب رمزاً جديداً أو تابع بالبريد الإلكتروني وكلمة المرور.',
          messageEn:
              'SMS verification code has expired. Request a new code or sign in with Email & Password.',
        );
      case 'invalid-phone-number':
        return const AuthException(
          code: 'invalid-phone-number',
          suggestEmailFallback: false,
          messageAr:
              'رقم الجوال القطري غير صالح (+974). تأكد من إدخال 8 أرقام تبدأ بـ 3 أو 5 أو 6 أو 7.',
          messageEn:
              'Invalid +974 Qatar phone number. Enter 8 digits starting with 3, 5, 6, or 7.',
        );
      case 'captcha-check-failed':
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return const AuthException(
          code: 'captcha-check-failed',
          suggestEmailFallback: true,
          messageAr:
              'تعذّر إتمام فحص الأمان (reCAPTCHA / App Check) لرسائل الجوال. يمكنك المتابعة بالبريد الإلكتروني وكلمة المرور.',
          messageEn:
              'Phone verification security check could not complete. Please sign in with Email & Password instead.',
        );
      default:
        return AuthException(
          code: code.isEmpty ? 'auth-error' : code,
          suggestEmailFallback: true,
          messageAr:
              'تعذّر إتمام التحقق عبر الجوال (${e.code}). يمكنك استخدام البريد الإلكتروني وكلمة المرور.',
          messageEn: e.message?.trim().isNotEmpty == true
              ? '${e.message!.trim()} (${e.code})'
              : 'Authentication failed (${e.code}). You can sign in with Email & Password.',
        );
    }
  }

  @override
  Future<bool> sendPhoneOtp(String phone) async {
    final e164 = normalizeQatarE164(phone);
    _autoVerifiedCredential = null;

    if (_isWeb) {
      try {
        final confirmation = await _firebaseAuth.signInWithPhoneNumber(e164);
        _webConfirmationResult = confirmation;
        _pendingVerificationId = null;
        _pendingPhoneE164 = e164;
        return true;
      } on fb_auth.FirebaseAuthException catch (e) {
        throw mapFirebaseAuthException(e);
      } on AuthException {
        rethrow;
      } on NoSuchMethodError {
        _phoneAuthUnsupportedByStub = true;
        throw UnsupportedError(
          'Phone OTP requires FirebaseAuth.signInWithPhoneNumber implementation',
        );
      }
    }

    final completer = Completer<bool>();
    // Attach silent listener immediately so synchronous verificationFailed callbacks
    // never trigger an unhandled Zone error before `await completer.future` executes.
    completer.future.ignore();
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: e164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          try {
            _autoVerifiedCredential =
                await _firebaseAuth.signInWithCredential(credential);
            _pendingPhoneE164 = e164;
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          } on fb_auth.FirebaseAuthException catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(mapFirebaseAuthException(e));
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(mapFirebaseAuthException(e));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _pendingVerificationId = verificationId;
          _resendToken = resendToken;
          _pendingPhoneE164 = e164;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _pendingVerificationId = verificationId;
          _pendingPhoneE164 = e164;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );
      return await completer.future;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } on AuthException {
      rethrow;
    } on NoSuchMethodError {
      _phoneAuthUnsupportedByStub = true;
      throw UnsupportedError(
        'Phone OTP requires FirebaseAuth.verifyPhoneNumber implementation',
      );
    }
  }

  @override
  Future<UserModel> verifyPhoneOtp(String phone, String code) async {
    if (_phoneAuthUnsupportedByStub) {
      throw UnsupportedError(
        'Phone OTP is not supported by this FirebaseAuth test stub',
      );
    }

    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var normalizedCode = code.trim();
    for (var i = 0; i < 10; i++) {
      normalizedCode = normalizedCode.replaceAll(arabicDigits[i], '$i');
      normalizedCode = normalizedCode.replaceAll(easternDigits[i], '$i');
    }

    if (!_otpSixDigitsRegex.hasMatch(normalizedCode)) {
      throw const AuthException(
        code: 'invalid-verification-code',
        messageAr: 'يرجى إدخال رمز تحقق صحيح مكون من 6 أرقام.',
        messageEn: 'Please enter a valid 6-digit verification code.',
      );
    }

    final resolvedE164 = _pendingPhoneE164 ??
        (phone.trim().isNotEmpty ? normalizeQatarE164(phone) : '');

    try {
      late final fb_auth.UserCredential userCredential;

      if (_autoVerifiedCredential != null) {
        userCredential = _autoVerifiedCredential!;
        _autoVerifiedCredential = null;
      } else if (_isWeb) {
        final confirmation = _webConfirmationResult;
        if (confirmation == null) {
          throw const AuthException(
            code: 'session-expired',
            suggestEmailFallback: true,
            messageAr:
                'لا توجد جلسة تحقق نشطة. يرجى طلب رمز SMS جديد أولاً أو المتابعة بالبريد الإلكتروني.',
            messageEn:
                'No active phone verification session. Request an SMS code first or sign in with Email & Password.',
          );
        }
        userCredential = await confirmation.confirm(normalizedCode);
        _webConfirmationResult = null;
      } else {
        final verificationId = _pendingVerificationId;
        if (verificationId == null || verificationId.isEmpty) {
          throw const AuthException(
            code: 'session-expired',
            suggestEmailFallback: true,
            messageAr:
                'لا توجد جلسة تحقق نشطة. يرجى طلب رمز SMS جديد أولاً أو المتابعة بالبريد الإلكتروني.',
            messageEn:
                'No active phone verification session. Request an SMS code first or sign in with Email & Password.',
          );
        }
        final credential = _credentialFactory(
          verificationId: verificationId,
          smsCode: normalizedCode,
        );
        userCredential = await _firebaseAuth.signInWithCredential(credential);
        _pendingVerificationId = null;
      }

      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw const AuthException(
          code: 'no-user',
          suggestEmailFallback: true,
          messageAr: 'لم يُرجع نظام المصادقة بيانات المستخدم.',
          messageEn: 'Firebase Phone Auth returned no user.',
        );
      }

      return await _hydrateOrCreateUserDoc(
        fbUser,
        fallbackPhone: resolvedE164.isNotEmpty
            ? extractQatarLocalDigits(resolvedE164)
            : null,
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } on AuthException {
      rethrow;
    } on NoSuchMethodError {
      _phoneAuthUnsupportedByStub = true;
      throw UnsupportedError(
        'Phone OTP requires FirebaseAuth.signInWithCredential implementation',
      );
    }
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password are required');
    }
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );
    final fbUser = credential.user;
    if (fbUser == null) {
      throw StateError('FirebaseAuth sign-in returned no user');
    }
    return _hydrateOrCreateUserDoc(fbUser, fallbackEmail: trimmedEmail);
  }

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password are required');
    }
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );
    final fbUser = credential.user;
    if (fbUser == null) {
      throw StateError('FirebaseAuth registration returned no user');
    }

    final cleanName = fullName?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      await fbUser.updateDisplayName(cleanName);
    }

    return _hydrateOrCreateUserDoc(
      fbUser,
      fallbackEmail: trimmedEmail,
      fallbackName: cleanName,
      fallbackPhone: phone?.trim(),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw ArgumentError.value(email, 'email', 'Email is required');
    }
    await _firebaseAuth.sendPasswordResetEmail(email: trimmedEmail);
  }

  @override
  Future<bool> isSignedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<String?> currentUid() async {
    return _firebaseAuth.currentUser?.uid;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return _hydrateOrCreateUserDoc(fbUser);
  }

  Future<UserModel> _hydrateOrCreateUserDoc(
    fb_auth.User fbUser, {
    String? fallbackEmail,
    String? fallbackName,
    String? fallbackPhone,
  }) async {
    final existing = await _userStore.getUserDoc(fbUser.uid);
    if (existing != null) {
      final data = Map<String, dynamic>.from(existing);
      data['id'] = fbUser.uid;
      return UserModel.fromJson(data);
    }

    final newUser = UserModel(
      id: fbUser.uid,
      fullName: fallbackName ?? fbUser.displayName ?? '',
      phone: fallbackPhone ??
          (fbUser.phoneNumber != null
              ? extractQatarLocalDigits(fbUser.phoneNumber!)
              : ''),
      email: fbUser.email ?? fallbackEmail,
      gender: UserGender.preferNotToSay,
      isVerified: false,
      idVerificationStatus: IdVerificationStatus.unverified,
      nationalId: null,
      walletBalance: 0.0,
      rating: 0.0,
      completedRides: 0,
      completedParcels: 0,
    );

    final payload = Map<String, dynamic>.from(newUser.toJson())
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _userStore.setUserDoc(fbUser.uid, payload, merge: true);
    return newUser;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Authentication required to update profile');
    }

    // Restrict client updates strictly to editable profile attributes so
    // verification flags and financial fields remain server-authoritative.
    final safeProfileUpdate = <String, dynamic>{
      'id': uid,
      'fullName': user.fullName,
      'phone': user.phone,
      'gender': user.gender.name,
      'avatarUrl': user.avatarUrl,
      'governorate': user.governorate,
      'city': user.city,
      'birthDate': user.birthDate,
      'email': user.email,
      'emergencyContactName': user.emergencyContactName,
      'emergencyContactPhone': user.emergencyContactPhone,
      'occupation': user.occupation,
      'smokingPreference': user.smokingPreference,
      'tripVibe': user.tripVibe,
      'ladiesOnlyPreference': user.ladiesOnlyPreference,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _userStore.setUserDoc(uid, safeProfileUpdate, merge: true);
    final refreshed = await _userStore.getUserDoc(uid);
    if (refreshed != null) {
      final data = Map<String, dynamic>.from(refreshed);
      data['id'] = uid;
      return UserModel.fromJson(data);
    }
    return user.copyWith(id: uid);
  }

  @override
  Future<bool> submitNationalId({
    required String nationalId,
    required String idFrontImage,
    required String idBackImage,
    required String selfieImage,
  }) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Authentication required to submit QID verification');
    }

    final trimmedQid = nationalId.trim();
    if (!isValidQatarQid(trimmedQid)) {
      throw ArgumentError.value(
        nationalId,
        'nationalId',
        'Qatar QID must be exactly 11 numeric digits',
      );
    }

    final verificationDoc = <String, dynamic>{
      'id': 'ver_$uid',
      'userId': uid,
      'qidNumber': trimmedQid,
      'nationalId': trimmedQid,
      'idFrontImage': idFrontImage,
      'idBackImage': idBackImage,
      'selfieImage': selfieImage,
      'status': 'pending',
      'approvalStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _userStore.setProviderVerificationDoc(
      uid,
      verificationDoc,
      merge: true,
    );

    await _userStore.setUserDoc(
      uid,
      {
        'id': uid,
        'nationalId': trimmedQid,
        'idVerificationStatus': IdVerificationStatus.underReview.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      merge: true,
    );
    return true;
  }

  @override
  Future<void> deleteAccount({String? reason}) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) {
      throw const AuthException(
        code: 'unauthenticated',
        messageAr: 'يرجى تسجيل الدخول أولاً لحذف الحساب.',
        messageEn: 'Authentication is required to delete your account.',
      );
    }

    try {
      await _callableClient.call('deleteUserAccount', <String, dynamic>{
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
    } on WorksiteRepositoryException catch (e) {
      if (e.code == 'failed-precondition') {
        throw AuthException(
          code: 'failed-precondition',
          messageAr:
              'لا يمكن حذف الحساب حالياً لوجود طلبات توريد نشطة مرتبطة بحسابك. يرجى إتمامها أو تسويتها أولاً.',
          messageEn: e.messageEn.isNotEmpty
              ? e.messageEn
              : 'Cannot delete account while active worksite supply requests are in progress.',
        );
      }
      throw AuthException(
        code: e.code,
        messageAr: e.messageAr,
        messageEn: e.messageEn,
      );
    }

    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      // Server already deleted Firebase Auth record; ignore local signOut cleanup errors.
    }
    _webConfirmationResult = null;
    _pendingVerificationId = null;
    _pendingPhoneE164 = null;
    _autoVerifiedCredential = null;
  }

  @override
  Future<void> signOut() async {
    _webConfirmationResult = null;
    _pendingVerificationId = null;
    _pendingPhoneE164 = null;
    _autoVerifiedCredential = null;
    await _firebaseAuth.signOut();
  }
}
