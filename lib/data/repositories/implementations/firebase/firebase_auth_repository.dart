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

class FirebaseAuthRepository implements IAuthRepository {
  static const String providerVerificationsCollection = 'provider_verifications';
  static final RegExp qatarQidRegex = RegExp(r'^[0-9]{11}$');

  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseAuthUserStore _userStore;

  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _userStore =
            _FirestoreAuthUserStore(firestore ?? FirebaseFirestore.instance);

  @visibleForTesting
  FirebaseAuthRepository.withUserStore({
    required fb_auth.FirebaseAuth firebaseAuth,
    required FirebaseAuthUserStore userStore,
  })  : _firebaseAuth = firebaseAuth,
        _userStore = userStore;

  static bool isValidQatarQid(String qid) => qatarQidRegex.hasMatch(qid.trim());

  @override
  Future<bool> sendPhoneOtp(String phone) async {
    throw UnsupportedError('Phone OTP requires configured SMS provider');
  }

  @override
  Future<UserModel> verifyPhoneOtp(String phone, String code) async {
    throw UnsupportedError('Phone OTP requires configured SMS provider');
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
      phone: fallbackPhone ?? fbUser.phoneNumber ?? '',
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
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
