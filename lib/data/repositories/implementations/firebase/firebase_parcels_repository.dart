import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/parcel_model.dart';
import '../../contracts/i_parcels_repository.dart';
import '../../../services/firebase_firestore_service.dart';

class FirebaseParcelsRepository implements IParcelsRepository {
  final FirebaseFirestore? _injectedFirestore;

  FirebaseParcelsRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ParcelModel>> getParcels() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.parcels)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => ParcelModel.fromJson(doc.data())).toList();
  }

  @override
  Future<ParcelModel?> getParcelDetails(String parcelId) async {
    final doc = await _firestore.collection(FirestoreCollections.parcels).doc(parcelId).get();
    if (doc.exists && doc.data() != null) {
      return ParcelModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<ParcelModel> createParcel(ParcelModel parcel) async {
    await _firestore
        .collection(FirestoreCollections.parcels)
        .doc(parcel.id)
        .set(parcel.toJson());
    return parcel;
  }

  @override
  Future<bool> verifyPickupOtp(String parcelId, String otp) async {
    final parcelDoc = await _firestore.collection(FirestoreCollections.parcels).doc(parcelId).get();
    if (!parcelDoc.exists) return false;

    final data = parcelDoc.data()!;
    final storedOtp = data['pickupOtp']?.toString().replaceAll(' ', '');
    final cleanInput = otp.replaceAll(' ', '');

    if (storedOtp == cleanInput) {
      await _firestore.collection(FirestoreCollections.parcels).doc(parcelId).update({
        'status': ParcelStatusStep.handedOver.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }
    return false;
  }

  @override
  Future<bool> verifyDeliveryOtp(String parcelId, String otp) async {
    await _firestore.collection(FirestoreCollections.parcels).doc(parcelId).update({
      'status': ParcelStatusStep.delivered.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  @override
  Future<bool> updateParcelStatus(String parcelId, ParcelStatusStep status) async {
    await _firestore.collection(FirestoreCollections.parcels).doc(parcelId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }
}
