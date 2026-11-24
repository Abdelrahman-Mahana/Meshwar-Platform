import '../../../core/config/app_environment.dart';
import '../../models/user_model.dart';
import '../contracts/i_auth_repository.dart';

/// DEV/TEST-ONLY mock authentication adapter.
///
/// Strictly gated by [AppEnvironment.useDevMocks] (which is allowed ONLY when
/// `APP_ENV == 'development'` and `!AppEnvironment.useFirebase`) or an explicit
/// `allowDevMocks: true` override in development unit/widget tests.
///
/// Never grants default `isVerified: true`, fake QIDs, or demo wallet balances.
class DevMockAuthRepository implements IAuthRepository {
  static final RegExp _qatarQidRegex = RegExp(r'^[0-9]{11}$');

  final bool? _allowDevMocks;
  final String expectedDevOtp;

  UserModel? _currentUser;
  bool _signedIn;
  String? _pendingPhone;
  final List<String> passwordResetRequests = [];

  DevMockAuthRepository({
    bool? allowDevMocks,
    UserModel? initialUser,
    bool startSignedIn = false,
    this.expectedDevOtp = '482911',
  })  : _allowDevMocks = allowDevMocks,
        _currentUser = startSignedIn ? (initialUser ?? UserModel.empty) : initialUser,
        _signedIn = startSignedIn;

  /// Whether dev-mock auth actions are permitted under current environment rules.
  bool get isDevMockActive {
    if (!AppEnvironment.isDevMocksAllowed(
      flavor: AppEnvironment.flavor,
      useFirebase: AppEnvironment.useFirebase,
    )) {
      return false;
    }
    return _allowDevMocks ?? AppEnvironment.useDevMocks;
  }

  void _ensureDevMockEnabled(String operation) {
    if (!isDevMockActive) {
      throw StateError(
        'DevMockAuthRepository.$operation is disabled unless '
        'APP_ENV=development, USE_FIREBASE=false, and USE_DEV_MOCKS=true.',
      );
    }
  }

  @override
  Future<bool> sendPhoneOtp(String phone) async {
    if (!isDevMockActive) {
      throw UnsupportedError('Phone OTP requires configured SMS provider');
    }
    final normalized = phone.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(phone, 'phone', 'Phone number cannot be empty');
    }
    _pendingPhone = normalized;
    return true;
  }

  @override
  Future<UserModel> verifyPhoneOtp(String phone, String code) async {
    if (!isDevMockActive) {
      throw UnsupportedError('Phone OTP requires configured SMS provider');
    }
    if (code.trim() != expectedDevOtp) {
      throw StateError('Invalid OTP verification code');
    }
    final normalizedPhone = phone.trim().isNotEmpty ? phone.trim() : (_pendingPhone ?? '');
    final existing = _currentUser;
    _currentUser = existing != null && existing.id.isNotEmpty
        ? existing.copyWith(phone: normalizedPhone)
        : UserModel(
            id: 'dev_usr_${normalizedPhone.isEmpty ? 'anon' : normalizedPhone}',
            fullName: '',
            phone: normalizedPhone,
            gender: UserGender.preferNotToSay,
          );
    _signedIn = true;
    return _currentUser!;
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    _ensureDevMockEnabled('loginWithEmail');
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password are required');
    }
    final existing = _currentUser;
    if (existing != null && existing.email == trimmedEmail && existing.id.isNotEmpty) {
      _signedIn = true;
      return existing;
    }
    _currentUser = UserModel(
      id: 'dev_usr_${trimmedEmail.hashCode.abs()}',
      fullName: '',
      phone: '',
      email: trimmedEmail,
      gender: UserGender.preferNotToSay,
    );
    _signedIn = true;
    return _currentUser!;
  }

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    _ensureDevMockEnabled('registerWithEmail');
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.length < 6) {
      throw ArgumentError('Valid email and password (>= 6 chars) are required');
    }
    _currentUser = UserModel(
      id: 'dev_usr_${trimmedEmail.hashCode.abs()}',
      fullName: fullName?.trim() ?? '',
      phone: phone?.trim() ?? '',
      email: trimmedEmail,
      gender: UserGender.preferNotToSay,
    );
    _signedIn = true;
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    _ensureDevMockEnabled('sendPasswordReset');
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw ArgumentError.value(email, 'email', 'Email is required');
    }
    passwordResetRequests.add(trimmedEmail);
  }

  @override
  Future<bool> isSignedIn() async {
    return _signedIn && _currentUser != null && _currentUser!.id.isNotEmpty;
  }

  @override
  Future<String?> currentUid() async {
    if (!await isSignedIn()) return null;
    return _currentUser?.id;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (!await isSignedIn()) return null;
    return _currentUser;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    if (!await isSignedIn()) {
      throw StateError('Authentication required to update profile');
    }
    final existing = _currentUser!;
    _currentUser = existing.copyWith(
      fullName: user.fullName,
      phone: user.phone,
      gender: user.gender,
      avatarUrl: user.avatarUrl,
      governorate: user.governorate,
      city: user.city,
      birthDate: user.birthDate,
      email: user.email,
      emergencyContactName: user.emergencyContactName,
      emergencyContactPhone: user.emergencyContactPhone,
      occupation: user.occupation,
      smokingPreference: user.smokingPreference,
      tripVibe: user.tripVibe,
      ladiesOnlyPreference: user.ladiesOnlyPreference,
    );
    return _currentUser!;
  }

  @override
  Future<bool> submitNationalId({
    required String nationalId,
    required String idFrontImage,
    required String idBackImage,
    required String selfieImage,
  }) async {
    if (!await isSignedIn()) {
      throw StateError('Authentication required to submit QID verification');
    }
    final qid = nationalId.trim();
    if (!_qatarQidRegex.hasMatch(qid)) {
      throw ArgumentError.value(
        nationalId,
        'nationalId',
        'Qatar QID must be exactly 11 digits',
      );
    }
    _currentUser = _currentUser!.copyWith(
      nationalId: qid,
      idFrontImage: idFrontImage,
      idBackImage: idBackImage,
      selfieImage: selfieImage,
      idVerificationStatus: IdVerificationStatus.underReview,
      isVerified: false,
    );
    return true;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _currentUser = null;
    _pendingPhone = null;
  }
}

/// Backward-compatible symbol for [AppRepositories] local mock DI wiring.
/// Strictly dev/test-only — see [DevMockAuthRepository].
class AuthRepositoryImpl extends DevMockAuthRepository {
  AuthRepositoryImpl({
    super.allowDevMocks,
    super.initialUser,
    super.startSignedIn,
    super.expectedDevOtp,
  });
}
