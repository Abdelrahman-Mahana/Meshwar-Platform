import '../../models/user_model.dart';

/// Authentication & Identity Verification contract for MASHWAR.
///
/// Note on Phone OTP in Qatar Pilot Phase 1:
/// When an SMS OTP provider is not configured, [sendPhoneOtp] and
/// [verifyPhoneOtp] explicitly throw [UnsupportedError] rather than silently
/// succeeding or authenticating arbitrary codes.
abstract class IAuthRepository {
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

  Future<void> signOut();
}
