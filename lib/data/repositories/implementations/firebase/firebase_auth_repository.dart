import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../../models/user_model.dart';
import '../../contracts/i_auth_repository.dart';
import '../../../services/firebase_firestore_service.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<bool> sendPhoneOtp(String phone) async {
    // Note: Phone OTP requires backend SMS gateway or Firebase phone verification
    return true;
  }

  @override
  Future<UserModel> verifyPhoneOtp(String phone, String code) async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final updated = currentUser.copyWith(phone: phone, isVerified: true);
      await updateProfile(updated);
      return updated;
    }
    final newUser = UserModel(
      id: _firebaseAuth.currentUser?.uid ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: 'مستخدم مشوار',
      phone: phone,
      gender: UserGender.male,
      isVerified: true,
      walletBalance: 0.0,
      rating: 5.0,
      completedRides: 0,
      completedParcels: 0,
    );
    await updateProfile(newUser);
    return newUser;
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final userDoc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(credential.user?.uid)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      return UserModel.fromJson(userDoc.data()!);
    }
    return UserModel(
      id: credential.user!.uid,
      fullName: credential.user!.displayName ?? 'مستخدم مشوار',
      phone: credential.user!.phoneNumber ?? '',
      email: email,
      gender: UserGender.male,
      walletBalance: 0.0,
      rating: 5.0,
      completedRides: 0,
      completedParcels: 0,
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.id)
        .set(user.toJson(), SetOptions(merge: true));
    return user;
  }

  @override
  Future<bool> submitNationalId({
    required String nationalId,
    required String idFrontImage,
    required String idBackImage,
    required String selfieImage,
  }) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return false;

    final verificationDoc = {
      'id': 'ver_${DateTime.now().millisecondsSinceEpoch}',
      'userId': uid,
      'nationalId': nationalId,
      'idFrontImage': idFrontImage,
      'idBackImage': idBackImage,
      'selfieImage': selfieImage,
      'status': 'underReview',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection(FirestoreCollections.driverVerifications).doc(uid).set(verificationDoc);
    await _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'nationalId': nationalId,
      'idVerificationStatus': 'underReview',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
