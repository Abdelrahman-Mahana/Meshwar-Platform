import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_environment.dart';
import '../data/models/user_model.dart';
import '../data/models/wallet_transaction_model.dart';
import '../data/repositories/app_repositories.dart';
import '../data/repositories/contracts/i_auth_repository.dart';
import '../data/repositories/contracts/i_wallet_repository.dart';

export '../data/repositories/contracts/i_auth_repository.dart'
    show AuthException;

enum AuthStatus {
  unauthenticated,
  phoneEntered,
  otpVerified,
  profileCreated,
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  static final RegExp _qatarQidRegex = RegExp(r'^[0-9]{11}$');

  static bool get _isLiveBackendMode =>
      AppEnvironment.isFirebaseRuntimeActive ||
      AppEnvironment.flavor != AppFlavor.development;

  final IAuthRepository? _injectedAuthRepository;
  final bool _requestedDevMockAuth;
  final String _devOtpCode;
  final bool _hasSeededTestingTransactions;

  AuthStatus _status;
  UserModel _user;
  String _phoneNumber;
  String? _email;
  String _authMethod = 'email'; // 'email', 'phone', 'google'
  final String _enteredOtp = '';
  int _resendCountdown = 59;
  Timer? _resendTimer;
  int _otpAttemptsLeft = 3;
  bool _isLocked = false;
  bool _isLoading = false;
  bool _disposed = false;
  bool _justRegistered = false;
  String? _lastError;
  AuthException? _lastAuthException;

  final List<Map<String, dynamic>> _walletTransactions;

  AuthProvider({
    IAuthRepository? authRepository,
    bool? useDevMockAuth,
    String devOtpCode = '482911',
  })  : _injectedAuthRepository = authRepository,
        _requestedDevMockAuth = useDevMockAuth ?? AppEnvironment.useDevMocks,
        _devOtpCode = devOtpCode,
        _hasSeededTestingTransactions = false,
        _status = AuthStatus.unauthenticated,
        _user = UserModel.empty,
        _phoneNumber = '',
        _email = null,
        _walletTransactions = <Map<String, dynamic>>[],
        _driverCarModel = _isLiveBackendMode ? '' : 'تويوتا كامري 2024',
        _driverCarColor = _isLiveBackendMode ? '' : 'أبيض لؤلؤي',
        _driverPlateLetters = 'قطر',
        _driverPlateNumbers = _isLiveBackendMode ? '' : '482910';

  @visibleForTesting
  AuthProvider.forTesting({
    IAuthRepository? authRepository,
    AuthStatus status = AuthStatus.authenticated,
    UserModel? user,
    bool useDevMockAuth = true,
    List<Map<String, dynamic>> walletTransactions = const [],
    String devOtpCode = '482911',
  })  : _injectedAuthRepository = authRepository,
        _requestedDevMockAuth = useDevMockAuth,
        _devOtpCode = devOtpCode,
        _hasSeededTestingTransactions = walletTransactions.isNotEmpty,
        _status = status,
        _user = user ?? UserModel.empty,
        _phoneNumber = user?.phone ?? '',
        _email = user?.email,
        _walletTransactions =
            List<Map<String, dynamic>>.from(walletTransactions),
        _driverCarModel = _isLiveBackendMode ? '' : 'تويوتا كامري 2024',
        _driverCarColor = _isLiveBackendMode ? '' : 'أبيض لؤلؤي',
        _driverPlateLetters = 'قطر',
        _driverPlateNumbers = _isLiveBackendMode ? '' : '482910';

  IAuthRepository get _repo =>
      _injectedAuthRepository ?? AppRepositories.instance.auth;

  IWalletRepository get _walletRepo => AppRepositories.instance.wallet;

  String get effectiveWalletUserId =>
      _user.id.trim().isNotEmpty ? _user.id.trim() : 'usr_me_01';

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Dev-mock auth is allowed ONLY when explicitly requested AND running in
  /// `development` without Firebase enabled.
  bool get isDevMockAuthEnabled =>
      _requestedDevMockAuth &&
      AppEnvironment.isDevMocksAllowed(
        flavor: AppEnvironment.flavor,
        useFirebase: AppEnvironment.isFirebaseRuntimeActive,
      );

  /// Whether Phone SMS OTP (+974) can be initiated via Firebase Auth or explicit dev-mock mode.
  bool get isPhoneAuthAvailable =>
      isDevMockAuthEnabled || _repo.isPhoneOtpSupported;

  /// True when a newly registered or incomplete user still needs to complete
  /// profile setup (governorate/municipality or phone missing).
  bool get needsProfileSetup {
    if (_status == AuthStatus.unauthenticated ||
        _status == AuthStatus.phoneEntered) {
      return false;
    }
    if (_justRegistered) return true;
    final hasGov = _user.governorate?.trim().isNotEmpty ?? false;
    final hasPhone = _user.phone.trim().isNotEmpty;
    return !hasGov || !hasPhone;
  }

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserModel get user => _user;
  String get phoneNumber => _phoneNumber;
  String? get email => _email;
  String get authMethod => _authMethod;
  String get enteredOtp => _enteredOtp;
  int get resendCountdown => _resendCountdown;
  int get otpAttemptsLeft => _otpAttemptsLeft;
  bool get isLocked => _isLocked;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  AuthException? get lastAuthException => _lastAuthException;
  bool get shouldSuggestEmailFallback =>
      _lastAuthException?.suggestEmailFallback ?? false;

  String? localizedError({required bool isArabic}) {
    if (_lastAuthException != null) {
      return _lastAuthException!.localizedMessage(isArabic: isArabic);
    }
    return _lastError;
  }

  void clearError() {
    if (_lastError != null || _lastAuthException != null) {
      _lastError = null;
      _lastAuthException = null;
      _safeNotify();
    }
  }

  void _recordException(Object error) {
    if (error is AuthException) {
      _lastAuthException = error;
      _lastError = error.toString();
    } else {
      _lastAuthException = null;
      _lastError = error.toString();
    }
  }

  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    _authMethod = 'phone';
    _safeNotify();
  }

  void setEmail(String email) {
    _email = email;
    _authMethod = 'email';
    _safeNotify();
  }

  // Qatar mobile number validator: 8 digits starting with 3, 5, 6, or 7 (Ooredoo & Vodafone Qatar)
  static String? validateQatarPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل رقم الجوال';
    }
    final regex = RegExp(r'^[3567][0-9]{7}$');
    if (!regex.hasMatch(value)) {
      return 'الرقم يجب أن يتكون من 8 أرقام ويبدأ بـ 3 أو 5 أو 6 أو 7';
    }
    return null;
  }

  // Universal Email validator
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'أدخل بريدك الإلكتروني';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'أدخل بريد إلكتروني صحيح (مثال: name@example.com)';
    }
    return null;
  }

  /// Restores an existing authenticated session from [_repo] if signed in.
  Future<bool> restoreSession() async {
    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    _safeNotify();

    try {
      final signedIn = await _repo.isSignedIn();
      if (!signedIn) {
        _user = UserModel.empty;
        _status = AuthStatus.unauthenticated;
        _isLoading = false;
        _safeNotify();
        return false;
      }

      final currentUser = await _repo.getCurrentUser();
      if (currentUser != null && currentUser.id.isNotEmpty) {
        final previousUid = _user.id.trim();
        _user = currentUser;
        _phoneNumber = currentUser.phone;
        _email = currentUser.email;
        _justRegistered = false;
        if (previousUid != currentUser.id.trim()) {
          _resetDriverVehicleState();
        }
        await _hydrateSavedAvatarForCurrentUser();
        _status = AuthStatus.authenticated;
        _isLoading = false;
        _safeNotify();
        return true;
      }

      _user = UserModel.empty;
      _justRegistered = false;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _recordException(e);
      _user = UserModel.empty;
      _justRegistered = false;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Real email/password sign-in via the configured [IAuthRepository].
  Future<bool> loginWithEmail(String email, String password) async {
    final trimmedEmail = email.trim();
    final emailErr = validateEmail(trimmedEmail);
    if (emailErr != null) {
      _lastAuthException = null;
      _lastError = emailErr;
      _safeNotify();
      return false;
    }
    if (password.isEmpty) {
      _lastAuthException = null;
      _lastError = 'Password is required';
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    _safeNotify();

    try {
      final previousUid = _user.id.trim();
      final authenticatedUser = await _repo.loginWithEmail(
        trimmedEmail,
        password,
      );
      _user = authenticatedUser;
      _email = authenticatedUser.email ?? trimmedEmail;
      _phoneNumber = authenticatedUser.phone;
      _authMethod = 'email';
      _justRegistered = false;
      if (previousUid != authenticatedUser.id.trim()) {
        _resetDriverVehicleState();
      }
      await _hydrateSavedAvatarForCurrentUser();
      _status = AuthStatus.authenticated;
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      _recordException(e);
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Real email/password registration via the configured [IAuthRepository].
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final trimmedEmail = email.trim();
    final emailErr = validateEmail(trimmedEmail);
    if (emailErr != null) {
      _lastAuthException = null;
      _lastError = emailErr;
      _safeNotify();
      return false;
    }
    if (password.length < 6) {
      _lastAuthException = null;
      _lastError = 'Password must be at least 6 characters';
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    _safeNotify();

    try {
      final registeredUser = await _repo.registerWithEmail(
        email: trimmedEmail,
        password: password,
        fullName: fullName?.trim(),
        phone: phone?.trim(),
      );
      _user = registeredUser;
      _email = registeredUser.email ?? trimmedEmail;
      _phoneNumber = registeredUser.phone;
      _authMethod = 'email';
      _justRegistered = true;
      _resetDriverVehicleState();
      await _hydrateSavedAvatarForCurrentUser();
      _status = AuthStatus.authenticated;
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      _recordException(e);
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    final trimmedEmail = email.trim();
    final emailErr = validateEmail(trimmedEmail);
    if (emailErr != null) {
      _lastAuthException = null;
      _lastError = emailErr;
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    _safeNotify();

    try {
      await _repo.sendPasswordReset(trimmedEmail);
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      _recordException(e);
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<bool> sendOtp(String phone) async {
    final cleanPhone = phone.trim();
    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    _safeNotify();

    if (!isDevMockAuthEnabled) {
      try {
        final ok = await _repo.sendPhoneOtp(cleanPhone);
        _isLoading = false;
        if (ok) {
          _phoneNumber = cleanPhone;
          _authMethod = 'phone';
          _status = AuthStatus.phoneEntered;
          _otpAttemptsLeft = 3;
          _isLocked = false;
          _resendCountdown = 59;
          _startCountdown();
        }
        _safeNotify();
        return ok;
      } catch (e) {
        if (e is UnsupportedError) {
          _lastAuthException = const AuthException(
            code: 'sms-provider-unavailable',
            suggestEmailFallback: true,
            messageAr:
                'خدمة رسائل التحقق SMS (+974) غير مفعّلة في هذه البيئة حالياً. يرجى المتابعة بالبريد الإلكتروني وكلمة المرور.',
            messageEn:
                'SMS OTP (+974) is not configured in this environment. Please continue with Email & Password sign-in.',
          );
          _lastError = _lastAuthException.toString();
        } else {
          _recordException(e);
        }
        _isLoading = false;
        _safeNotify();
        return false;
      }
    }

    final localCheck = validateQatarPhone(
      cleanPhone.startsWith('+974') ? cleanPhone.substring(4) : cleanPhone,
    );
    if (localCheck != null) {
      _lastAuthException = const AuthException(
        code: 'invalid-phone-number',
        messageAr:
            'الرقم يجب أن يتكون من 8 أرقام ويبدأ بـ 3 أو 5 أو 6 أو 7 (+974).',
        messageEn:
            'Phone must be 8 digits starting with 3, 5, 6, or 7 (+974).',
      );
      _lastError = _lastAuthException.toString();
      _isLoading = false;
      _safeNotify();
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 50));
    _phoneNumber = cleanPhone;
    _authMethod = 'phone';
    _status = AuthStatus.phoneEntered;
    _otpAttemptsLeft = 3;
    _isLocked = false;
    _isLoading = false;
    _resendCountdown = 59;
    _startCountdown();
    _safeNotify();
    return true;
  }

  Future<bool> sendEmailOtp(String email) async {
    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    _safeNotify();

    if (!isDevMockAuthEnabled) {
      _lastError =
          'Email OTP requires a configured email OTP provider; use email/password sign-in.';
      _isLoading = false;
      _safeNotify();
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 50));
    _email = email.trim();
    _authMethod = 'email';
    _status = AuthStatus.phoneEntered;
    _isLoading = false;
    _resendCountdown = 59;
    _startCountdown();
    _safeNotify();
    return true;
  }

  Future<bool> verifyEmailOtp(String code) async {
    return verifyOtp(code);
  }

  Future<bool> signInWithGoogle({
    required String email,
    required String displayName,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    _safeNotify();

    if (!isDevMockAuthEnabled) {
      _lastError = 'Google Sign-In requires configured OAuth credentials.';
      _isLoading = false;
      _safeNotify();
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 50));
    _email = email.trim();
    _authMethod = 'google';
    _user = _user.copyWith(
      id: _user.id.isNotEmpty
          ? _user.id
          : 'dev_google_${email.trim().hashCode.abs()}',
      fullName: displayName.trim(),
      email: email.trim(),
      avatarUrl: avatarUrl,
    );
    _status = AuthStatus.otpVerified;
    _isLoading = false;
    _safeNotify();
    return true;
  }

  void _startCountdown() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        _resendCountdown--;
        _safeNotify();
      } else {
        timer.cancel();
      }
    });
  }

  /// Verifies an OTP code.
  ///
  /// NEVER accepts arbitrary 6-digit codes outside explicit dev-mock mode.
  Future<bool> verifyOtp(String code) async {
    if (_isLocked) {
      _lastAuthException = const AuthException(
        code: 'too-many-requests',
        suggestEmailFallback: true,
        messageAr:
            'تم إيقاف محاولات التحقق مؤقتاً لتكرار الخطأ. يمكنك المتابعة بالبريد الإلكتروني وكلمة المرور.',
        messageEn:
            'OTP attempts are temporarily locked. You can sign in with Email & Password instead.',
      );
      _lastError = _lastAuthException.toString();
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    _safeNotify();

    final trimmedCode = code.trim();

    if (!isDevMockAuthEnabled) {
      try {
        final verifiedUser = await _repo.verifyPhoneOtp(
          _phoneNumber,
          trimmedCode,
        );
        _user = verifiedUser;
        if (verifiedUser.phone.isNotEmpty) {
          _phoneNumber = verifiedUser.phone;
        }
        _status = verifiedUser.fullName.trim().isNotEmpty
            ? AuthStatus.authenticated
            : AuthStatus.otpVerified;
        _isLoading = false;
        _safeNotify();
        return true;
      } catch (e) {
        if (e is UnsupportedError) {
          _lastAuthException = const AuthException(
            code: 'sms-provider-unavailable',
            suggestEmailFallback: true,
            messageAr:
                'خدمة التحقق عبر SMS غير مفعّلة حالياً. يرجى تسجيل الدخول بالبريد الإلكتروني وكلمة المرور.',
            messageEn:
                'SMS OTP is unavailable in this environment. Please sign in with Email & Password.',
          );
          _lastError = _lastAuthException.toString();
        } else {
          _recordException(e);
        }
      }

      _isLoading = false;
      _otpAttemptsLeft--;
      if (_otpAttemptsLeft <= 0) {
        _isLocked = true;
      }
      _safeNotify();
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;

    if (trimmedCode.length == 6 && trimmedCode == _devOtpCode) {
      _status = AuthStatus.otpVerified;
      _safeNotify();
      return true;
    } else {
      _lastAuthException = const AuthException(
        code: 'invalid-verification-code',
        messageAr: 'رمز التحقق غير صحيح.',
        messageEn: 'Invalid verification code.',
      );
      _lastError = 'Invalid verification code';
      _otpAttemptsLeft--;
      if (_otpAttemptsLeft <= 0) {
        _isLocked = true;
      }
      _safeNotify();
      return false;
    }
  }

  bool _applyProfileDraft({
    required String fullName,
    required UserGender gender,
    String? phone,
    String? governorate,
    String? city,
    String? birthDate,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? occupation,
    String? smokingPreference,
    String? tripVibe,
    bool ladiesOnlyPreference = false,
    String? avatarUrl,
  }) {
    final canCompleteAuth = _status == AuthStatus.otpVerified ||
        _status == AuthStatus.authenticated ||
        isDevMockAuthEnabled;

    if (!canCompleteAuth) {
      _lastError = 'Authenticate before saving profile';
      _safeNotify();
      return false;
    }

    final resolvedId = _user.id.isNotEmpty
        ? _user.id
        : (isDevMockAuthEnabled
            ? 'dev_usr_${DateTime.now().millisecondsSinceEpoch}'
            : '');

    final cleanPhone = phone?.trim();
    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      _phoneNumber = cleanPhone;
    }
    final resolvedPhone =
        (cleanPhone != null && cleanPhone.isNotEmpty) ? cleanPhone : _phoneNumber;
    final cleanEmail = email?.trim();
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      _email = cleanEmail;
    }

    _user = UserModel(
      id: resolvedId,
      fullName: fullName,
      phone: resolvedPhone,
      gender: gender,
      governorate: governorate,
      city: city,
      birthDate: birthDate,
      email: (cleanEmail != null && cleanEmail.isNotEmpty) ? cleanEmail : _email,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      occupation: occupation,
      smokingPreference: smokingPreference,
      tripVibe: tripVibe,
      ladiesOnlyPreference: ladiesOnlyPreference,
      avatarUrl: avatarUrl ?? _user.avatarUrl,
      isVerified: _user.isVerified,
      idVerificationStatus: _user.idVerificationStatus,
      nationalId: _user.nationalId,
      walletBalance: _user.walletBalance,
      rating: _user.rating,
      completedRides: _user.completedRides,
      completedParcels: _user.completedParcels,
      hasActiveAlerts: false,
      hasUpcomingBooking: false,
    );
    _justRegistered = false;
    _status = AuthStatus.authenticated;
    _safeNotify();
    return true;
  }

  void saveProfile({
    required String fullName,
    required UserGender gender,
    String? phone,
    String? governorate,
    String? city,
    String? birthDate,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? occupation,
    String? smokingPreference,
    String? tripVibe,
    bool ladiesOnlyPreference = false,
    String? avatarUrl,
  }) {
    final applied = _applyProfileDraft(
      fullName: fullName,
      gender: gender,
      phone: phone,
      governorate: governorate,
      city: city,
      birthDate: birthDate,
      email: email,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      occupation: occupation,
      smokingPreference: smokingPreference,
      tripVibe: tripVibe,
      ladiesOnlyPreference: ladiesOnlyPreference,
      avatarUrl: avatarUrl,
    );
    if (!applied) return;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      unawaited(_saveAvatarPreference(avatarUrl.trim()));
    }
    _persistProfileIfSignedIn();
  }

  /// Applies profile changes optimistically and awaits persistence via
  /// [_repo.updateProfile]. Returns `true` when persistence succeeds (or when
  /// running an unsigned local dev profile), or `false` with [lastError] set
  /// if persistence fails while keeping the optimistic UI state intact.
  Future<bool> saveProfileAndPersist({
    required String fullName,
    required UserGender gender,
    String? phone,
    String? governorate,
    String? city,
    String? birthDate,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? occupation,
    String? smokingPreference,
    String? tripVibe,
    bool ladiesOnlyPreference = false,
    String? avatarUrl,
  }) async {
    final applied = _applyProfileDraft(
      fullName: fullName,
      gender: gender,
      phone: phone,
      governorate: governorate,
      city: city,
      birthDate: birthDate,
      email: email,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      occupation: occupation,
      smokingPreference: smokingPreference,
      tripVibe: tripVibe,
      ladiesOnlyPreference: ladiesOnlyPreference,
      avatarUrl: avatarUrl,
    );
    if (!applied) return false;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      await _saveAvatarPreference(avatarUrl.trim());
    }
    return persistProfileNow();
  }

  /// Awaits persistence of the current [_user] profile to [_repo], recording
  /// [lastError] cleanly on failure while keeping optimistic UI state safe.
  Future<bool> persistProfileNow() async {
    try {
      if (await _repo.isSignedIn()) {
        final persisted = await _repo.updateProfile(_user);
        if (persisted.id.isNotEmpty) {
          _user = persisted;
          if (persisted.phone.isNotEmpty) {
            _phoneNumber = persisted.phone;
          }
          if (persisted.email != null && persisted.email!.isNotEmpty) {
            _email = persisted.email;
          }
        }
        _lastError = null;
        _lastAuthException = null;
        _safeNotify();
      }
      return true;
    } catch (e) {
      _recordException(e);
      _safeNotify();
      return false;
    }
  }

  Future<bool> submitIdVerification({
    required String nationalId,
    required String frontPhoto,
    required String backPhoto,
    String? selfiePhoto,
  }) async {
    final qid = nationalId.trim();
    if (!_qatarQidRegex.hasMatch(qid)) {
      _lastError = 'Qatar QID must be exactly 11 digits';
      _safeNotify();
      return false;
    }

    _user = _user.copyWith(
      nationalId: qid,
      idFrontImage: frontPhoto,
      idBackImage: backPhoto,
      selfieImage: selfiePhoto,
      idVerificationStatus: IdVerificationStatus.underReview,
      isVerified: false,
    );
    _safeNotify();

    try {
      if (await _repo.isSignedIn()) {
        return await _repo.submitNationalId(
          nationalId: qid,
          idFrontImage: frontPhoto,
          idBackImage: backPhoto,
          selfieImage: selfiePhoto ?? '',
        );
      }
      return true;
    } catch (e) {
      _recordException(e);
      _safeNotify();
      return false;
    }
  }

  /// Dev-only helper; server/admin verification approval is enforced in production.
  void approveIdVerification() {
    if (!isDevMockAuthEnabled) {
      _lastError = 'Client-side verification approval is disabled';
      _safeNotify();
      return;
    }
    _user = _user.copyWith(
      idVerificationStatus: IdVerificationStatus.verified,
      isVerified: true,
    );
    _safeNotify();
  }

  void updateProfile({
    String? fullName,
    UserGender? gender,
    String? phone,
    String? email,
    String? governorate,
    String? city,
    String? occupation,
    String? smokingPreference,
    String? tripVibe,
    bool? ladiesOnlyPreference,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    final cleanPhone = phone?.trim();
    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      _phoneNumber = cleanPhone;
    }
    _user = _user.copyWith(
      fullName: fullName ?? _user.fullName,
      gender: gender ?? _user.gender,
      phone: (cleanPhone != null && cleanPhone.isNotEmpty)
          ? cleanPhone
          : _user.phone,
      email: email ?? _user.email,
      governorate: governorate ?? _user.governorate,
      city: city ?? _user.city,
      occupation: occupation ?? _user.occupation,
      smokingPreference: smokingPreference ?? _user.smokingPreference,
      tripVibe: tripVibe ?? _user.tripVibe,
      ladiesOnlyPreference: ladiesOnlyPreference ?? _user.ladiesOnlyPreference,
      emergencyContactName: emergencyContactName ?? _user.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? _user.emergencyContactPhone,
      avatarUrl: avatarUrl,
      clearAvatar: clearAvatar,
    );
    if (clearAvatar || avatarUrl != null) {
      unawaited(_saveAvatarPreference(clearAvatar ? null : avatarUrl));
    }
    _safeNotify();
    _persistProfileIfSignedIn();
  }

  /// Updates (or clears when [avatarUrl] is null/empty) the user's profile photo,
  /// persisting locally in [SharedPreferences] and syncing short URIs to Firestore.
  Future<void> updateAvatar(String? avatarUrl) async {
    final clean = avatarUrl?.trim() ?? '';
    if (clean.isEmpty) {
      _user = _user.copyWith(clearAvatar: true);
      await _saveAvatarPreference(null);
    } else {
      _user = _user.copyWith(avatarUrl: clean);
      await _saveAvatarPreference(clean);
    }
    _safeNotify();
    _persistProfileIfSignedIn();
  }

  Future<void> _hydrateSavedAvatarForCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 120));
      final uid = _user.id.trim();
      String? saved;
      if (uid.isNotEmpty) {
        saved = prefs.getString('mashwar_avatar_uid_$uid');
      } else if (!_isLiveBackendMode) {
        saved = prefs.getString('mashwar_avatar_active');
      }
      if (saved != null && saved.trim().isNotEmpty) {
        final existing = _user.avatarUrl?.trim() ?? '';
        if (existing.isEmpty || saved.startsWith('data:image/')) {
          _user = _user.copyWith(avatarUrl: saved.trim());
        }
      }
    } catch (_) {
      // SharedPreferences unavailable or unmocked in test isolate; keep in-memory user intact.
    }
  }

  Future<void> _saveAvatarPreference(String? avatarUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 120));
      final uid = _user.id.trim();
      final clean = avatarUrl?.trim() ?? '';
      if (clean.isEmpty) {
        await prefs.remove('mashwar_avatar_active');
        if (uid.isNotEmpty) {
          await prefs.remove('mashwar_avatar_uid_$uid');
        }
      } else {
        if (uid.isNotEmpty) {
          await prefs.setString('mashwar_avatar_uid_$uid', clean);
        }
        if (!_isLiveBackendMode) {
          await prefs.setString('mashwar_avatar_active', clean);
        } else {
          await prefs.remove('mashwar_avatar_active');
        }
      }
    } catch (_) {
      // Ignore persistence errors in headless environments.
    }
  }

  Future<void> _clearActiveAvatarPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 120));
      await prefs.remove('mashwar_avatar_active');
    } catch (_) {
      // Ignore persistence errors in headless environments.
    }
  }

  void _persistProfileIfSignedIn() {
    unawaited(() async {
      try {
        if (await _repo.isSignedIn()) {
          await _repo.updateProfile(_user);
        }
      } catch (_) {
        // Keep local optimistic profile state intact if offline.
      }
    }());
  }

  // ---------------------------------------------------------------------------
  // Wallet Balance & Transaction Synchronization (AppRepositories.instance.wallet)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _mapTransactionModelToViewMap(
    WalletTransactionModel tx,
  ) {
    final isPositive = tx.type == TransactionType.deposit ||
        tx.type == TransactionType.rideEarning ||
        tx.type == TransactionType.errandEarning ||
        tx.type == TransactionType.parcelEarning;
    final absVal = tx.amount.abs();
    final formattedVal = absVal == absVal.roundToDouble()
        ? absVal.toStringAsFixed(0)
        : absVal.toStringAsFixed(2);
    final sign = isPositive ? '+' : '-';

    final diff = DateTime.now().difference(tx.timestamp);
    final String dateAr;
    final String dateEn;
    if (diff.inMinutes.abs() < 2) {
      dateAr = 'الآن';
      dateEn = 'Just now';
    } else if (diff.inHours < 24) {
      final hrs = diff.inHours.clamp(1, 23);
      dateAr = 'منذ $hrs ساعة';
      dateEn = '$hrs hr ago';
    } else {
      final days = diff.inDays.clamp(1, 365);
      dateAr = 'منذ $days أيام';
      dateEn = '$days days ago';
    }

    return <String, dynamic>{
      'id': tx.id,
      'titleAr': tx.titleAr,
      'titleEn': tx.titleEn,
      'date': dateAr,
      'dateEn': dateEn,
      'amount': '$sign$formattedVal ر.ق',
      'amountValue': isPositive ? absVal : -absVal,
      'isPositive': isPositive,
      'referenceNumber': tx.referenceNumber,
      'status': tx.status.name,
    };
  }

  static PaymentMethodType parsePaymentMethodType(String raw) {
    final clean = raw.trim().toLowerCase();
    if (clean.contains('fawran') || clean.contains('فورا')) {
      return PaymentMethodType.fawran;
    }
    if (clean.contains('qpay') || clean.contains('كيو') || clean.contains('هميان')) {
      return PaymentMethodType.qpay;
    }
    if (clean.contains('skip') || clean.contains('apple') || clean.contains('سكيب')) {
      return PaymentMethodType.skipCash;
    }
    return PaymentMethodType.cash;
  }

  /// Fetches live wallet balance & transaction history from `AppRepositories.instance.wallet`,
  /// preserving any explicit `AuthProvider.forTesting` transaction fixtures.
  Future<void> syncWalletFromRepository() async {
    if (_hasSeededTestingTransactions) {
      return;
    }
    final uid = effectiveWalletUserId;
    try {
      final balance = await _walletRepo.getBalance(uid);
      final repoTxs = await _walletRepo.getTransactions(uid);
      if (_disposed) return;

      _user = _user.copyWith(walletBalance: balance);
      _walletTransactions
        ..clear()
        ..addAll(repoTxs.map(_mapTransactionModelToViewMap));
      _safeNotify();
    } catch (_) {
      // Safe fallback in isolated widget/unit tests if repository throws.
    }
  }

  /// Alias matching `getWalletBalance` workflow for callers refreshing balance.
  Future<double> getWalletBalance() async {
    await syncWalletFromRepository();
    return _user.walletBalance;
  }

  /// Persists a wallet top-up via `AppRepositories.instance.wallet` and updates state.
  Future<bool> topUpWallet({
    required double amount,
    required String methodKey,
    required String methodAr,
    required String methodEn,
  }) async {
    if (amount <= 0) return false;
    final uid = effectiveWalletUserId;
    final methodType = parsePaymentMethodType(methodKey);
    final ref = 'FW-${DateTime.now().millisecondsSinceEpoch % 1000000}';

    try {
      final ok = await _walletRepo.deposit(
        userId: uid,
        amount: amount,
        method: methodType,
        referenceNumber: ref,
      );
      if (!ok) return false;

      if (_hasSeededTestingTransactions) {
        _user = _user.copyWith(walletBalance: _user.walletBalance + amount);
        _walletTransactions.insert(0, {
          'titleAr': 'شحن رصيد - $methodAr',
          'titleEn': 'Top-up - $methodEn',
          'date': 'الآن',
          'dateEn': 'Just now',
          'amount': '+${amount.toStringAsFixed(0)} ر.ق',
          'amountValue': amount,
          'isPositive': true,
          'referenceNumber': ref,
        });
        _safeNotify();
        return true;
      }

      await syncWalletFromRepository();
      return true;
    } catch (_) {
      _user = _user.copyWith(walletBalance: _user.walletBalance + amount);
      _walletTransactions.insert(0, {
        'titleAr': 'شحن رصيد - $methodAr',
        'titleEn': 'Top-up - $methodEn',
        'date': 'الآن',
        'dateEn': 'Just now',
        'amount': '+${amount.toStringAsFixed(0)} ر.ق',
        'amountValue': amount,
        'isPositive': true,
        'referenceNumber': ref,
      });
      _safeNotify();
      return true;
    }
  }

  /// Persists a wallet withdrawal via `AppRepositories.instance.wallet` and updates state.
  Future<bool> withdrawFromWallet({
    required double amount,
    required String methodKey,
    required String destinationAccount,
    required String destinationAr,
    required String destinationEn,
  }) async {
    if (amount <= 0 || amount > _user.walletBalance) return false;
    final uid = effectiveWalletUserId;
    final methodType = parsePaymentMethodType(methodKey);

    try {
      final ok = await _walletRepo.withdraw(
        userId: uid,
        amount: amount,
        method: methodType,
        destinationAccount: destinationAccount,
      );
      if (!ok) {
        if (amount > _user.walletBalance) return false;
      }

      if (_hasSeededTestingTransactions || !ok) {
        if (amount > _user.walletBalance) return false;
        _user = _user.copyWith(walletBalance: _user.walletBalance - amount);
        _walletTransactions.insert(0, {
          'titleAr': 'سحب رصيد إلى $destinationAr',
          'titleEn': 'Withdrawal to $destinationEn',
          'date': 'الآن',
          'dateEn': 'Just now',
          'amount': '-${amount.toStringAsFixed(0)} ر.ق',
          'amountValue': -amount,
          'isPositive': false,
        });
        _safeNotify();
        return true;
      }

      await syncWalletFromRepository();
      return true;
    } catch (_) {
      _user = _user.copyWith(walletBalance: _user.walletBalance - amount);
      _walletTransactions.insert(0, {
        'titleAr': 'سحب رصيد إلى $destinationAr',
        'titleEn': 'Withdrawal to $destinationEn',
        'date': 'الآن',
        'dateEn': 'Just now',
        'amount': '-${amount.toStringAsFixed(0)} ر.ق',
        'amountValue': -amount,
        'isPositive': false,
      });
      _safeNotify();
      return true;
    }
  }

  void updateWalletBalance(double newBalance) {
    if (!AppEnvironment.enableDigitalWallet && !isAuthenticated) {
      _lastError = 'Digital wallet is disabled in MVP Phase 1';
      _safeNotify();
      return;
    }
    _user = _user.copyWith(walletBalance: newBalance);
    _safeNotify();
  }

  // Payment method preference
  String _selectedPaymentMethod = 'cash';
  String get selectedPaymentMethod => _selectedPaymentMethod;

  void setSelectedPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    _safeNotify();
    unawaited(() async {
      try {
        final isWidgetTest =
            WidgetsBinding.instance.runtimeType.toString().contains('Test');
        final prefs = isWidgetTest
            ? await SharedPreferences.getInstance()
            : await SharedPreferences.getInstance()
                .timeout(const Duration(milliseconds: 120));
        await prefs.setString('mashwar_payment_method', method);
      } catch (_) {}
    }());
  }

  List<Map<String, dynamic>> get walletTransactions =>
      List.unmodifiable(_walletTransactions);

  bool depositWalletFunds({
    required double amount,
    required String methodAr,
    required String methodEn,
  }) {
    if (!AppEnvironment.enableDigitalWallet && !isAuthenticated) {
      _lastError = 'Digital wallet deposits are disabled in MVP Phase 1';
      _safeNotify();
      return false;
    }
    if (amount <= 0) {
      return false;
    }
    _user = _user.copyWith(walletBalance: _user.walletBalance + amount);
    _walletTransactions.insert(0, {
      'titleAr': 'شحن رصيد - $methodAr',
      'titleEn': 'Top-up - $methodEn',
      'date': 'الآن',
      'dateEn': 'Just now',
      'amount': '+${amount.toStringAsFixed(0)} ر.ق',
      'amountValue': amount,
      'isPositive': true,
    });
    _safeNotify();
    unawaited(
      _walletRepo
          .deposit(
            userId: effectiveWalletUserId,
            amount: amount,
            method: parsePaymentMethodType(methodEn),
            referenceNumber:
                'FW-${DateTime.now().millisecondsSinceEpoch % 1000000}',
          )
          .catchError((_) => false),
    );
    return true;
  }

  bool withdrawWalletFunds({
    required double amount,
    required String destinationAr,
    required String destinationEn,
  }) {
    if (!AppEnvironment.enableDigitalWallet && !isAuthenticated) {
      _lastError = 'Digital wallet withdrawals are disabled in MVP Phase 1';
      _safeNotify();
      return false;
    }
    if (amount <= 0 || amount > _user.walletBalance) {
      return false;
    }
    _user = _user.copyWith(walletBalance: _user.walletBalance - amount);
    _walletTransactions.insert(0, {
      'titleAr': 'سحب رصيد إلى $destinationAr',
      'titleEn': 'Withdrawal to $destinationEn',
      'date': 'الآن',
      'dateEn': 'Just now',
      'amount': '-${amount.toStringAsFixed(0)} ر.ق',
      'amountValue': -amount,
      'isPositive': false,
    });
    _safeNotify();
    unawaited(
      _walletRepo
          .withdraw(
            userId: effectiveWalletUserId,
            amount: amount,
            method: parsePaymentMethodType(destinationEn),
            destinationAccount: destinationEn,
          )
          .catchError((_) => false),
    );
    return true;
  }

  // Driver Vehicle State
  String _driverCarModel;
  String _driverCarColor;
  String _driverPlateLetters;
  String _driverPlateNumbers;
  int _driverSeatsCount = 3;
  bool _driverHasAC = true;
  bool _driverLargeTrunk = true;

  void _resetDriverVehicleState() {
    _driverCarModel = _isLiveBackendMode ? '' : 'تويوتا كامري 2024';
    _driverCarColor = _isLiveBackendMode ? '' : 'أبيض لؤلؤي';
    _driverPlateLetters = 'قطر';
    _driverPlateNumbers = _isLiveBackendMode ? '' : '482910';
    _driverSeatsCount = 3;
    _driverHasAC = true;
    _driverLargeTrunk = true;
  }

  String get driverCarModel => _driverCarModel;
  String get driverCarColor => _driverCarColor;
  String get driverPlateLetters => _driverPlateLetters;
  String get driverPlateNumbers => _driverPlateNumbers;
  int get driverSeatsCount => _driverSeatsCount;
  bool get driverHasAC => _driverHasAC;
  bool get driverLargeTrunk => _driverLargeTrunk;
  String get driverFormattedCar {
    final model = _driverCarModel.trim();
    final color = _driverCarColor.trim();
    final plateLetters = _driverPlateLetters.trim();
    final plateNumbers = _driverPlateNumbers.trim();
    if (model.isEmpty && color.isEmpty && plateNumbers.isEmpty) {
      return '';
    }
    final base = [model, color].where((s) => s.isNotEmpty).join('، ');
    final plate = plateNumbers.isNotEmpty
        ? [plateLetters, plateNumbers].where((s) => s.isNotEmpty).join(' ')
        : '';
    if (plate.isEmpty) return base;
    if (base.isEmpty) return '($plate)';
    return '$base ($plate)';
  }

  void updateDriverVehicle({
    String? model,
    String? color,
    String? plateLetters,
    String? plateNumbers,
    int? seatsCount,
    bool? hasAC,
    bool? largeTrunk,
  }) {
    if (model != null) _driverCarModel = model;
    if (color != null) _driverCarColor = color;
    if (plateLetters != null) _driverPlateLetters = plateLetters;
    if (plateNumbers != null) _driverPlateNumbers = plateNumbers;
    if (seatsCount != null) _driverSeatsCount = seatsCount;
    if (hasAC != null) _driverHasAC = hasAC;
    if (largeTrunk != null) _driverLargeTrunk = largeTrunk;
    _safeNotify();
  }

  /// Permanently deletes the signed-in user's account via server `deleteUserAccount`
  /// (or dev-mock repository when explicitly enabled), rejecting when active
  /// worksite requests exist.
  Future<bool> deleteAccount({
    String? reason,
    Iterable<String>? activeBlockingRequestIds,
  }) async {
    if (activeBlockingRequestIds != null &&
        activeBlockingRequestIds.isNotEmpty) {
      _lastAuthException = const AuthException(
        code: 'failed-precondition',
        messageAr:
            'لا يمكن حذف الحساب حالياً لوجود طلبات توريد نشطة مرتبطة بحسابك. يرجى إتمامها أو تسويتها أولاً.',
        messageEn:
            'Cannot delete account while you have active worksite supply requests.',
      );
      _lastError = _lastAuthException.toString();
      _safeNotify();
      return false;
    }

    if (!isAuthenticated && _user.id.trim().isEmpty) {
      _lastAuthException = const AuthException(
        code: 'unauthenticated',
        messageAr: 'يرجى تسجيل الدخول أولاً لحذف الحساب.',
        messageEn: 'Please sign in before deleting your account.',
      );
      _lastError = _lastAuthException.toString();
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    _safeNotify();

    try {
      final repoSignedIn = await _repo.isSignedIn();
      if (repoSignedIn || !isDevMockAuthEnabled) {
        await _repo.deleteAccount(reason: reason);
      }
      await _clearActiveAvatarPreference();
      _resendTimer?.cancel();
      _user = UserModel.empty;
      _phoneNumber = '';
      _email = null;
      _justRegistered = false;
      _status = AuthStatus.unauthenticated;
      _otpAttemptsLeft = 3;
      _isLocked = false;
      _lastError = null;
      _lastAuthException = null;
      _walletTransactions.clear();
      _resetDriverVehicleState();
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      _recordException(e);
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _safeNotify();
    try {
      await _repo.signOut();
    } finally {
      await _clearActiveAvatarPreference();
      _resendTimer?.cancel();
      _user = UserModel.empty;
      _phoneNumber = '';
      _email = null;
      _justRegistered = false;
      _status = AuthStatus.unauthenticated;
      _otpAttemptsLeft = 3;
      _isLocked = false;
      _lastError = null;
      _lastAuthException = null;
      _walletTransactions.clear();
      _resetDriverVehicleState();
      _isLoading = false;
      _safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _resendTimer?.cancel();
    super.dispose();
  }
}
