import 'dart:async';
import 'package:flutter/material.dart';
import '../core/config/app_environment.dart';
import '../data/models/user_model.dart';
import '../data/repositories/app_repositories.dart';
import '../data/repositories/contracts/i_auth_repository.dart';

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

  final IAuthRepository? _injectedAuthRepository;
  final bool _requestedDevMockAuth;
  final String _devOtpCode;

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
        _status = AuthStatus.unauthenticated,
        _user = UserModel.empty,
        _phoneNumber = '',
        _email = null,
        _walletTransactions = <Map<String, dynamic>>[];

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
        _status = status,
        _user = user ?? UserModel.empty,
        _phoneNumber = user?.phone ?? '',
        _email = user?.email,
        _walletTransactions =
            List<Map<String, dynamic>>.from(walletTransactions);

  IAuthRepository get _repo =>
      _injectedAuthRepository ?? AppRepositories.instance.auth;

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
      notifyListeners();
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
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    _authMethod = 'email';
    notifyListeners();
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
    notifyListeners();

    try {
      final signedIn = await _repo.isSignedIn();
      if (!signedIn) {
        _user = UserModel.empty;
        _status = AuthStatus.unauthenticated;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final currentUser = await _repo.getCurrentUser();
      if (currentUser != null && currentUser.id.isNotEmpty) {
        _user = currentUser;
        _phoneNumber = currentUser.phone;
        _email = currentUser.email;
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _user = UserModel.empty;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _recordException(e);
      _user = UserModel.empty;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
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
      notifyListeners();
      return false;
    }
    if (password.isEmpty) {
      _lastAuthException = null;
      _lastError = 'Password is required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    notifyListeners();

    try {
      final authenticatedUser = await _repo.loginWithEmail(
        trimmedEmail,
        password,
      );
      _user = authenticatedUser;
      _email = authenticatedUser.email ?? trimmedEmail;
      _phoneNumber = authenticatedUser.phone;
      _authMethod = 'email';
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _recordException(e);
      _isLoading = false;
      notifyListeners();
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
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _lastAuthException = null;
      _lastError = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    notifyListeners();

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
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _recordException(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    final trimmedEmail = email.trim();
    final emailErr = validateEmail(trimmedEmail);
    if (emailErr != null) {
      _lastAuthException = null;
      _lastError = emailErr;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    notifyListeners();

    try {
      await _repo.sendPasswordReset(trimmedEmail);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _recordException(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp(String phone) async {
    final cleanPhone = phone.trim();
    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    notifyListeners();

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
        notifyListeners();
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
        notifyListeners();
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
      notifyListeners();
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
    notifyListeners();
    return true;
  }

  Future<bool> sendEmailOtp(String email) async {
    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    notifyListeners();

    if (!isDevMockAuthEnabled) {
      _lastError =
          'Email OTP requires a configured email OTP provider; use email/password sign-in.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 50));
    _email = email.trim();
    _authMethod = 'email';
    _status = AuthStatus.phoneEntered;
    _isLoading = false;
    _resendCountdown = 59;
    _startCountdown();
    notifyListeners();
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
    notifyListeners();

    if (!isDevMockAuthEnabled) {
      _lastError = 'Google Sign-In requires configured OAuth credentials.';
      _isLoading = false;
      notifyListeners();
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
    notifyListeners();
    return true;
  }

  void _startCountdown() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        _resendCountdown--;
        notifyListeners();
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
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    notifyListeners();

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
        // If returning user already has a saved full name, enter authenticated directly;
        // otherwise transition to otpVerified so ProfileSetupScreen completes onboarding.
        _status = verifiedUser.fullName.trim().isNotEmpty
            ? AuthStatus.authenticated
            : AuthStatus.otpVerified;
        _isLoading = false;
        notifyListeners();
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
      notifyListeners();
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;

    if (trimmedCode.length == 6 && trimmedCode == _devOtpCode) {
      _status = AuthStatus.otpVerified;
      notifyListeners();
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
      notifyListeners();
      return false;
    }
  }

  void saveProfile({
    required String fullName,
    required UserGender gender,
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
      notifyListeners();
      return;
    }

    final resolvedId = _user.id.isNotEmpty
        ? _user.id
        : (isDevMockAuthEnabled
            ? 'dev_usr_${DateTime.now().millisecondsSinceEpoch}'
            : '');

    _user = UserModel(
      id: resolvedId,
      fullName: fullName,
      phone: _phoneNumber,
      gender: gender,
      governorate: governorate,
      city: city,
      birthDate: birthDate,
      email: email ?? _email,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      occupation: occupation,
      smokingPreference: smokingPreference,
      tripVibe: tripVibe,
      ladiesOnlyPreference: ladiesOnlyPreference,
      avatarUrl: avatarUrl,
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
    _status = AuthStatus.authenticated;
    notifyListeners();
    _persistProfileIfSignedIn();
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
      notifyListeners();
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
    notifyListeners();

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
      notifyListeners();
      return false;
    }
  }

  /// Dev-only helper; server/admin verification approval is enforced in production.
  void approveIdVerification() {
    if (!isDevMockAuthEnabled) {
      _lastError = 'Client-side verification approval is disabled';
      notifyListeners();
      return;
    }
    _user = _user.copyWith(
      idVerificationStatus: IdVerificationStatus.verified,
      isVerified: true,
    );
    notifyListeners();
  }

  void updateProfile({
    String? fullName,
    UserGender? gender,
    String? email,
    String? governorate,
    String? city,
    String? occupation,
    String? smokingPreference,
    String? tripVibe,
    bool? ladiesOnlyPreference,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    _user = _user.copyWith(
      fullName: fullName ?? _user.fullName,
      gender: gender ?? _user.gender,
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
    );
    notifyListeners();
    _persistProfileIfSignedIn();
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

  void updateWalletBalance(double newBalance) {
    if (!AppEnvironment.enableDigitalWallet) {
      _lastError = 'Digital wallet is disabled in MVP Phase 1';
      notifyListeners();
      return;
    }
    _user = _user.copyWith(walletBalance: newBalance);
    notifyListeners();
  }

  // Payment method preference (COD / manual bank transfer in MVP Phase 1)
  String _selectedPaymentMethod = 'cash';
  String get selectedPaymentMethod => _selectedPaymentMethod;

  void setSelectedPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  List<Map<String, dynamic>> get walletTransactions =>
      List.unmodifiable(_walletTransactions);

  bool depositWalletFunds({
    required double amount,
    required String methodAr,
    required String methodEn,
  }) {
    if (!AppEnvironment.enableDigitalWallet) {
      _lastError = 'Digital wallet deposits are disabled in MVP Phase 1';
      notifyListeners();
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
    notifyListeners();
    return true;
  }

  bool withdrawWalletFunds({
    required double amount,
    required String destinationAr,
    required String destinationEn,
  }) {
    if (!AppEnvironment.enableDigitalWallet) {
      _lastError = 'Digital wallet withdrawals are disabled in MVP Phase 1';
      notifyListeners();
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
    notifyListeners();
    return true;
  }

  // Driver Vehicle State
  String _driverCarModel = 'تويوتا كامري 2024';
  String _driverCarColor = 'أبيض لؤلؤي';
  String _driverPlateLetters = 'قطر';
  String _driverPlateNumbers = '482910';
  int _driverSeatsCount = 3;
  bool _driverHasAC = true;
  bool _driverLargeTrunk = true;

  String get driverCarModel => _driverCarModel;
  String get driverCarColor => _driverCarColor;
  String get driverPlateLetters => _driverPlateLetters;
  String get driverPlateNumbers => _driverPlateNumbers;
  int get driverSeatsCount => _driverSeatsCount;
  bool get driverHasAC => _driverHasAC;
  bool get driverLargeTrunk => _driverLargeTrunk;
  String get driverFormattedCar =>
      '$_driverCarModel، $_driverCarColor ($_driverPlateLetters $_driverPlateNumbers)';

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
    notifyListeners();
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
      notifyListeners();
      return false;
    }

    if (!isAuthenticated && _user.id.trim().isEmpty) {
      _lastAuthException = const AuthException(
        code: 'unauthenticated',
        messageAr: 'يرجى تسجيل الدخول أولاً لحذف الحساب.',
        messageEn: 'Please sign in before deleting your account.',
      );
      _lastError = _lastAuthException.toString();
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _lastError = null;
    _lastAuthException = null;
    notifyListeners();

    try {
      final repoSignedIn = await _repo.isSignedIn();
      if (repoSignedIn || !isDevMockAuthEnabled) {
        await _repo.deleteAccount(reason: reason);
      }
      _resendTimer?.cancel();
      _user = UserModel.empty;
      _phoneNumber = '';
      _email = null;
      _status = AuthStatus.unauthenticated;
      _otpAttemptsLeft = 3;
      _isLocked = false;
      _lastError = null;
      _lastAuthException = null;
      _walletTransactions.clear();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _recordException(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.signOut();
    } finally {
      _resendTimer?.cancel();
      _user = UserModel.empty;
      _phoneNumber = '';
      _email = null;
      _status = AuthStatus.unauthenticated;
      _otpAttemptsLeft = 3;
      _isLocked = false;
      _lastError = null;
      _lastAuthException = null;
      _walletTransactions.clear();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
