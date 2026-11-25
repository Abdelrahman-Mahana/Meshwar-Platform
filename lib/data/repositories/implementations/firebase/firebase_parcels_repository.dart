import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import '../../../models/parcel_model.dart';
import '../../contracts/i_parcels_repository.dart';
import '../../../services/firebase_firestore_service.dart';

class FirebaseParcelsRepository implements IParcelsRepository {
  final FirebaseFirestore? _injectedFirestore;
  final fb_auth.FirebaseAuth? _injectedAuth;

  FirebaseParcelsRepository({
    FirebaseFirestore? firestore,
    fb_auth.FirebaseAuth? auth,
  })  : _injectedFirestore = firestore,
        _injectedAuth = auth;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  fb_auth.User? get _currentUser {
    try {
      final injected = _injectedAuth;
      if (injected != null) return injected.currentUser;
      if (Firebase.apps.isEmpty) return null;
      return fb_auth.FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ParcelModel>> getParcels() async {
    try {
      final user = _currentUser;
      if (user != null && user.uid.isNotEmpty) {
        final senderSnap = await _firestore
            .collection(FirestoreCollections.parcels)
            .where('senderId', isEqualTo: user.uid)
            .limit(20)
            .get();
        final driverSnap = await _firestore
            .collection(FirestoreCollections.parcels)
            .where('driverId', isEqualTo: user.uid)
            .limit(20)
            .get();

        final byId = <String, ParcelModel>{};
        for (final doc in [...senderSnap.docs, ...driverSnap.docs]) {
          final model = ParcelModel.fromJson(doc.data());
          if (model.id.isNotEmpty) {
            byId[model.id] = model;
          }
        }
        return byId.values.toList();
      }

      final snapshot = await _firestore
          .collection(FirestoreCollections.parcels)
          .limit(20)
          .get();
      return snapshot.docs
          .map((doc) => ParcelModel.fromJson(doc.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<ParcelModel?> getParcelDetails(String parcelId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.parcels)
          .doc(parcelId)
          .get();
      if (doc.exists && doc.data() != null) {
        return ParcelModel.fromJson(doc.data()!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ParcelModel> createParcel(ParcelModel parcel) async {
    final user = _currentUser;
    final resolvedSenderId = (user != null && user.uid.isNotEmpty)
        ? user.uid
        : ((parcel.senderId != null && parcel.senderId!.trim().isNotEmpty)
            ? parcel.senderId!.trim()
            : 'usr_sender_01');
    final resolvedSenderName = (parcel.senderName != null &&
            parcel.senderName!.trim().length >= 2)
        ? parcel.senderName!.trim()
        : ((user?.displayName != null && user!.displayName!.trim().length >= 2)
            ? user.displayName!.trim()
            : null);

    final resolvedParcel = parcel.copyWith(
      senderId: resolvedSenderId,
      senderName: resolvedSenderName,
    );

    final payload = <String, dynamic>{
      ...resolvedParcel.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection(FirestoreCollections.parcels)
          .doc(resolvedParcel.id)
          .set(payload);
    } catch (_) {
      // Keep optimistic in-memory parcel state when offline or unauthenticated.
    }
    return resolvedParcel;
  }

  @override
  Future<bool> verifyPickupOtp(String parcelId, String otp) async {
    try {
      final parcelDoc = await _firestore
          .collection(FirestoreCollections.parcels)
          .doc(parcelId)
          .get();
      if (!parcelDoc.exists || parcelDoc.data() == null) return false;

      final data = parcelDoc.data()!;
      final rawStored = data['pickupOtp']?.toString() ?? '';
      final storedClean = rawStored.replaceAll(' ', '').trim();
      final inputClean = otp.replaceAll(' ', '').trim();

      if (storedClean.isNotEmpty && storedClean == inputClean) {
        await _firestore
            .collection(FirestoreCollections.parcels)
            .doc(parcelId)
            .update({
          'status': ParcelStatusStep.handedOver.name,
          'submittedOtp': rawStored,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> verifyDeliveryOtp(String parcelId, String otp) async {
    try {
      final parcelDoc = await _firestore
          .collection(FirestoreCollections.parcels)
          .doc(parcelId)
          .get();
      if (!parcelDoc.exists || parcelDoc.data() == null) return false;

      final data = parcelDoc.data()!;
      final rawDeliveryOtp = data['deliveryOtp']?.toString() ?? '';
      final cleanInput = otp.replaceAll(' ', '').trim();
      if (rawDeliveryOtp.trim().isNotEmpty &&
          rawDeliveryOtp.replaceAll(' ', '').trim() != cleanInput) {
        return false;
      }

      await _firestore
          .collection(FirestoreCollections.parcels)
          .doc(parcelId)
          .update({
        'status': ParcelStatusStep.delivered.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> updateParcelStatus(
    String parcelId,
    ParcelStatusStep status,
  ) async {
    try {
      await _firestore
          .collection(FirestoreCollections.parcels)
          .doc(parcelId)
          .update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
