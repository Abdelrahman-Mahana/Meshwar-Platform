import '../../models/user_model.dart';

/// Typed bilingual authentication & account lifecycle exception.
///
/// Maps Firebase Auth error codes (`billing-not-enabled`, `operation-not-allowed`,
/// `quota-exceeded`, `invalid-verification-code`, `too-many-requests`, etc.) and
/// `deleteUserAccount` server preconditions into actionable Arabic & English messages.
class AuthException implements Exception {
  final String code;
  final String messageAr;
  final String messageEn;
  final bool suggestEmailFallback;

  const AuthException({
    required this.code,
    required this.messageAr,
    required this.messageEn,
    this.suggestEmailFallback = false,
  });

  String localizedMessage({required bool isArabic}) =>
      isArabic ? messageAr : messageEn;

  @override
  String toString() => '$messageAr | $messageEn';
}

/// Authentication & Identity Verification contract for MASHWAR.
abstract class IAuthRepository {
  /// Whether Phone SMS OTP can be initiated with the active repository.
  bool get isPhoneOtpSupported => true;

  Future<bool> sendPhoneOtp(String phone);

  Future<UserModel> verifyPhoneOtp(String phone, String code);

  Future<UserModel> loginWithEmail(String email, String password);

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  });

  Future<void> sendPasswordReset(String email);

  Future<bool> isSignedIn();

  Future<String?> currentUid();

  Future<UserModel?> getCurrentUser();

  Future<UserModel> updateProfile(UserModel user);

  Future<bool> submitNationalId({
    required String nationalId,
    required String idFrontImage,
    required String idBackImage,
    required String selfieImage,
  });

  Future<void> deleteAccount({String? reason});

  Future<void> signOut();
}
