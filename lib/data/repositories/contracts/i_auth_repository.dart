import '../../models/user_model.dart';

abstract class IAuthRepository {
  Future<bool> sendPhoneOtp(String phone);
  Future<UserModel> verifyPhoneOtp(String phone, String code);
  Future<UserModel> loginWithEmail(String email, String password);
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
