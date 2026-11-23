import '../../models/user_model.dart';
import '../contracts/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  UserModel _currentUser = const UserModel(
    id: 'usr_me_01',
    fullName: 'عبدالرحمن المهنا',
    phone: '55123456',
    gender: UserGender.male,
    isVerified: true,
    walletBalance: 450.0,
    rating: 4.9,
    completedRides: 14,
    completedParcels: 6,
    idVerificationStatus: IdVerificationStatus.verified,
  );

  @override
  Future<bool> sendPhoneOtp(String phone) async {
    // In production, this invokes Firebase Phone Auth or backend SMS gateway
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<UserModel> verifyPhoneOtp(String phone, String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = _currentUser.copyWith(phone: phone, isVerified: true);
    return _currentUser;
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = _currentUser.copyWith(email: email);
    return _currentUser;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = user;
    return _currentUser;
  }

  @override
  Future<bool> submitNationalId({
    required String nationalId,
    required String idFrontImage,
    required String idBackImage,
    required String selfieImage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = _currentUser.copyWith(
      nationalId: nationalId,
      idFrontImage: idFrontImage,
      idBackImage: idBackImage,
      selfieImage: selfieImage,
      idVerificationStatus: IdVerificationStatus.underReview,
    );
    return true;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
