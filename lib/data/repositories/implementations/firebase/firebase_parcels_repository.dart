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
      if (user == null || user.uid.isEmpty) {
        return const [];
      }
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
      final storedClean = rawDeliveryOtp.replaceAll(' ', '').trim();
      final cleanInput = otp.replaceAll(' ', '').trim();
      // Fail closed when deliveryOtp is missing/empty or input does not match.
      if (storedClean.isEmpty ||
          cleanInput.isEmpty ||
          storedClean != cleanInput) {
        return false;
      }

      await _firestore
          .collection(FirestoreCollections.parcels)
          .doc(parcelId)
          .update({
        'status': ParcelStatusStep.delivered.name,
        'submittedOtp': rawDeliveryOtp,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Assigns a verified carrier (`driverId`) to an open parcel request and
  /// transitions status to `accepted`, complying with `firestore.rules`.
  Future<bool> assignDriver({
    required String parcelId,
    required String driverId,
    String? driverName,
    String? route,
    int? fee,
  }) async {
    final effectiveDriverId = driverId.trim().isNotEmpty
        ? driverId.trim()
        : (_currentUser?.uid ?? '');
    if (effectiveDriverId.isEmpty) return false;

    try {
      final patch = <String, dynamic>{
        'driverId': effectiveDriverId,
        if (driverName != null && driverName.trim().length >= 2)
          'driverName': driverName.trim(),
        if (route != null && route.trim().isNotEmpty) 'route': route.trim(),
        if (fee != null && fee >= 0 && fee <= 10000) 'fee': fee,
        'status': ParcelStatusStep.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection(FirestoreCollections.parcels)
          .doc(parcelId)
          .update(patch);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Persists a real `cancelled` status transition on `parcels/{parcelId}`.
  Future<bool> cancelParcel(String parcelId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.parcels)
          .doc(parcelId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Creates a schema-compliant dispute document in `disputes/{disputeId}`
  /// matching `isValidDispute` in `firestore.rules`.
  Future<bool> submitDispute({
    required String disputeId,
    required String parcelId,
    required String category,
    required String description,
    String? complainantId,
    String? complainantName,
    String? respondentId,
    String? againstName,
    String? parcelDetails,
    List<String> evidenceUrls = const [],
  }) async {
    final user = _currentUser;
    final resolvedComplainantId = (user != null && user.uid.isNotEmpty)
        ? user.uid
        : (complainantId?.trim() ?? '');
    if (resolvedComplainantId.isEmpty) return false;

    final rawName = complainantName?.trim().isNotEmpty == true
        ? complainantName!.trim()
        : (user?.displayName?.trim() ?? '');
    final resolvedComplainantName =
        rawName.length >= 2 ? rawName : 'MASHWAR User';

    final cleanDisputeId = disputeId
        .replaceAll('#', '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .trim();
    final effectiveId = cleanDisputeId.isNotEmpty
        ? cleanDisputeId
        : 'dsp_${DateTime.now().millisecondsSinceEpoch}';
    final cleanCategory = category.trim().isNotEmpty
        ? (category.trim().length > 100
            ? category.trim().substring(0, 100)
            : category.trim())
        : 'Parcel Dispute';
    final cleanDescription = description.trim().length > 2000
        ? description.trim().substring(0, 2000)
        : description.trim();

    final payload = <String, dynamic>{
      'id': effectiveId,
      'type': 'parcel',
      'category': cleanCategory,
      'complainantId': resolvedComplainantId,
      'complainantName': resolvedComplainantName,
      'status': 'open',
      if (respondentId != null && respondentId.trim().isNotEmpty)
        'respondentId': respondentId.trim(),
      if (againstName != null && againstName.trim().isNotEmpty)
        'againstName': againstName.trim(),
      if (parcelId.trim().isNotEmpty) 'referenceId': parcelId.trim(),
      if (parcelDetails != null && parcelDetails.trim().isNotEmpty)
        'parcelOrRideDetails': parcelDetails.trim().length > 500
            ? parcelDetails.trim().substring(0, 500)
            : parcelDetails.trim(),
      if (cleanDescription.isNotEmpty) 'description': cleanDescription,
      if (evidenceUrls.isNotEmpty)
        'evidenceUrls': evidenceUrls.take(10).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection(FirestoreCollections.disputes)
          .doc(effectiveId)
          .set(payload);
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
