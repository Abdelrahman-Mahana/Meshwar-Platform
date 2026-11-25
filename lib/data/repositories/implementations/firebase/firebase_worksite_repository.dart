import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../../../models/worksite_models.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../contracts/i_worksite_repository.dart';

/// Persistence gateway used by [FirebaseWorksiteRepository] so unit tests can
/// validate Firestore queries, Cloud Functions handoffs, and error propagation.
@visibleForTesting
abstract interface class FirebaseWorksiteStore {
  Future<List<Map<String, dynamic>>> queryWorkRequests({
    WorkRequestStatus? status,
    String? municipality,
    String? requesterId,
    String? assignedProviderId,
    int limit = 50,
  });

  Future<Map<String, dynamic>?> getWorkRequestDoc(String requestId);

  Future<List<Map<String, dynamic>>> queryWorkOffers(String requestId);

  Future<Map<String, dynamic>?> getHandoverViewDoc(String requestId);

  Future<List<Map<String, dynamic>>> queryRequestEvents(String requestId);
}

/// Client-permitted direct Firestore write gateway used ONLY as a Spark-plan
/// fallback when Cloud Functions v2 are not deployed (`not-found` / `unavailable`).
@visibleForTesting
abstract interface class SparkWorksiteWriteGateway {
  Future<void> createRequestAndEvent({
    required String requestId,
    required Map<String, dynamic> requestDoc,
    required String eventId,
    required Map<String, dynamic> eventDoc,
  });

  Future<void> createWorkOffer({
    required String offerId,
    required Map<String, dynamic> offerDoc,
  });

  Future<void> withdrawWorkOffer({
    required String offerId,
    required Map<String, dynamic> patch,
  });

  Future<void> updateWorkRequestAndAppendEvent({
    required String requestId,
    required Map<String, dynamic> requestPatch,
    String? eventId,
    Map<String, dynamic>? eventDoc,
  });

  Future<void> createRating({
    required String ratingId,
    required Map<String, dynamic> ratingDoc,
  });

  Future<Map<String, dynamic>?> getProviderProfileDoc(String uid);

  Future<Map<String, dynamic>?> getWorkOfferDoc(String offerId);

  Future<void> markNotificationReadDoc({
    required String notificationId,
    required Map<String, dynamic> patch,
  });
}

class _FirestoreWorksiteStore
    implements FirebaseWorksiteStore, SparkWorksiteWriteGateway {
  final FirebaseFirestore? _injectedFirestore;

  _FirestoreWorksiteStore([this._injectedFirestore]);

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Map<String, dynamic>>> queryWorkRequests({
    WorkRequestStatus? status,
    String? municipality,
    String? requesterId,
    String? assignedProviderId,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(FirestoreCollections.workRequests);

    final cleanReq = requesterId?.trim();
    final cleanProv = assignedProviderId?.trim();
    final cleanArea = municipality?.trim();

    // Select a single composite-indexed Firestore query path to prevent missing-index failures.
    if (cleanReq != null && cleanReq.isNotEmpty) {
      query = query.where('requesterId', isEqualTo: cleanReq);
    } else if (cleanProv != null && cleanProv.isNotEmpty) {
      query = query.where('assignedProviderId', isEqualTo: cleanProv);
    } else if (status != null && cleanArea != null && cleanArea.isNotEmpty) {
      query = query
          .where('status', isEqualTo: status.value)
          .where('deliveryArea', isEqualTo: cleanArea);
    } else if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);
    final snap = await query.get();
    return snap.docs
        .map((doc) => normalizeFirestoreDocument(doc.data(), fallbackId: doc.id))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getWorkRequestDoc(String requestId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.workRequests)
        .doc(requestId)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return normalizeFirestoreDocument(snap.data()!, fallbackId: snap.id);
  }

  @override
  Future<List<Map<String, dynamic>>> queryWorkOffers(String requestId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.workOffers)
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => normalizeFirestoreDocument(doc.data(), fallbackId: doc.id))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getHandoverViewDoc(String requestId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.workRequestHandoverView)
        .doc(requestId)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return normalizeFirestoreDocument(snap.data()!, fallbackId: snap.id);
  }

  @override
  Future<List<Map<String, dynamic>>> queryRequestEvents(String requestId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.requestEvents)
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs
        .map((doc) => normalizeFirestoreDocument(doc.data(), fallbackId: doc.id))
        .toList();
  }

  @override
  Future<void> createRequestAndEvent({
    required String requestId,
    required Map<String, dynamic> requestDoc,
    required String eventId,
    required Map<String, dynamic> eventDoc,
  }) async {
    await _firestore
        .collection(FirestoreCollections.workRequests)
        .doc(requestId)
        .set(requestDoc);
    try {
      await _firestore
          .collection(FirestoreCollections.requestEvents)
          .doc(eventId)
          .set(eventDoc);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
  }

  @override
  Future<void> createWorkOffer({
    required String offerId,
    required Map<String, dynamic> offerDoc,
  }) async {
    await _firestore
        .collection(FirestoreCollections.workOffers)
        .doc(offerId)
        .set(offerDoc);
  }

  @override
  Future<void> withdrawWorkOffer({
    required String offerId,
    required Map<String, dynamic> patch,
  }) async {
    await _firestore
        .collection(FirestoreCollections.workOffers)
        .doc(offerId)
        .update(patch);
  }

  @override
  Future<void> updateWorkRequestAndAppendEvent({
    required String requestId,
    required Map<String, dynamic> requestPatch,
    String? eventId,
    Map<String, dynamic>? eventDoc,
  }) async {
    await _firestore
        .collection(FirestoreCollections.workRequests)
        .doc(requestId)
        .update(requestPatch);
    if (eventId != null && eventDoc != null) {
      try {
        await _firestore
            .collection(FirestoreCollections.requestEvents)
            .doc(eventId)
            .set(eventDoc);
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }
    }
  }

  @override
  Future<void> createRating({
    required String ratingId,
    required Map<String, dynamic> ratingDoc,
  }) async {
    await _firestore
        .collection(FirestoreCollections.ratings)
        .doc(ratingId)
        .set(ratingDoc);
  }

  @override
  Future<Map<String, dynamic>?> getProviderProfileDoc(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.providerProfiles)
        .doc(uid)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return normalizeFirestoreDocument(snap.data()!, fallbackId: snap.id);
  }

  @override
  Future<Map<String, dynamic>?> getWorkOfferDoc(String offerId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.workOffers)
        .doc(offerId)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return normalizeFirestoreDocument(snap.data()!, fallbackId: snap.id);
  }

  @override
  Future<void> markNotificationReadDoc({
    required String notificationId,
    required Map<String, dynamic> patch,
  }) async {
    await _firestore
        .collection(FirestoreCollections.notifications)
        .doc(notificationId)
        .update(patch);
  }
}

/// Production Cloud Firestore + Cloud Functions v2 implementation of [IWorksiteRepository].
///
/// All privileged writes (`createWorkRequest`, `submitWorkOffer`, `acceptWorkOffer`,
/// `transitionWorkRequestStatus`, `verifyHandoverAndComplete`, `submitRequestRating`,
/// `recordPaymentStatus`) execute through authenticated Cloud Functions v2 HTTP
/// callable endpoints first, and—when running against live [_FirestoreWorksiteStore]
/// on a Firebase Spark project where Cloud Functions return `not-found` /
/// `unavailable`—fall back cleanly to rule-compliant direct Firestore writes for
/// client-permitted actions while surfacing clear bilingual errors for server-only ops.
class FirebaseWorksiteRepository implements IWorksiteRepository {
  static const Set<WorkRequestStatus> _invoiceAttachmentStatuses = {
    WorkRequestStatus.pickedUp,
    WorkRequestStatus.inTransit,
    WorkRequestStatus.deliveredPendingConfirmation,
  };

  static const Set<WorkRequestStatus> _activeDisputableStatuses = {
    WorkRequestStatus.accepted,
    WorkRequestStatus.inProgress,
    WorkRequestStatus.pickedUp,
    WorkRequestStatus.inTransit,
    WorkRequestStatus.deliveredPendingConfirmation,
  };

  static const Map<WorkRequestStatus, WorkRequestStatus> _providerLinearNext = {
    WorkRequestStatus.accepted: WorkRequestStatus.inProgress,
    WorkRequestStatus.inProgress: WorkRequestStatus.pickedUp,
    WorkRequestStatus.pickedUp: WorkRequestStatus.inTransit,
    WorkRequestStatus.inTransit: WorkRequestStatus.deliveredPendingConfirmation,
  };

  final Future<String?> Function() _currentUidProvider;
  final FirebaseFunctionsCallableClient _functionsClient;
  final FirebaseWorksiteStore _store;
  final SparkWorksiteWriteGateway? _sparkGatewayOverride;

  FirebaseWorksiteRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseFunctionsCallableClient? functionsClient,
  })  : _currentUidProvider = (() async =>
            (firebaseAuth ?? fb_auth.FirebaseAuth.instance).currentUser?.uid),
        _functionsClient = functionsClient ??
            FirebaseFunctionsCallableClient(
              idTokenProvider: () async =>
                  (firebaseAuth ?? fb_auth.FirebaseAuth.instance)
                      .currentUser
                      ?.getIdToken(),
            ),
        _store = _FirestoreWorksiteStore(firestore),
        _sparkGatewayOverride = null;

  @visibleForTesting
  FirebaseWorksiteRepository.withDeps({
    required Future<String?> Function() currentUidProvider,
    required FirebaseFunctionsCallableClient functionsClient,
    required FirebaseWorksiteStore store,
    SparkWorksiteWriteGateway? sparkFallbackGateway,
  })  : _currentUidProvider = currentUidProvider,
        _functionsClient = functionsClient,
        _store = store,
        _sparkGatewayOverride = sparkFallbackGateway;

  SparkWorksiteWriteGateway? get _sparkGateway {
    if (_sparkGatewayOverride != null) return _sparkGatewayOverride;
    final store = _store;
    if (store is _FirestoreWorksiteStore) return store;
    return null;
  }

  bool _isSparkFallbackTrigger(Object error) {
    return error is WorksiteRepositoryException &&
        (error.code == 'not-found' || error.code == 'unavailable') &&
        _sparkGateway != null;
  }

  dynamic _timestampToken() {
    if (_store is _FirestoreWorksiteStore) {
      return FieldValue.serverTimestamp();
    }
    return DateTime.now().toUtc().toIso8601String();
  }

  dynamic _scheduledByToken(DateTime scheduledBy) {
    if (_store is _FirestoreWorksiteStore) {
      return Timestamp.fromDate(scheduledBy.toUtc());
    }
    return scheduledBy.toUtc().toIso8601String();
  }

  String _generateClientId(String prefix) {
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '${prefix}_$micros';
  }

  Future<String> _requireSignedInUid({String? expectedUid}) async {
    final uid = (await _currentUidProvider())?.trim();
    if (uid == null || uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    if (expectedUid != null &&
        expectedUid.trim().isNotEmpty &&
        expectedUid.trim() != uid) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'لا يمكنك تنفيذ هذا الإجراء نيابةً عن مستخدم آخر.',
        messageEn: 'Authenticated UID does not match actor UID.',
      );
    }
    return uid;
  }

  WorkRequest _parseWorkRequest(Map<String, dynamic> json) {
    final parsed = WorkRequest.fromJson(json);
    if (json['isHandoverVerified'] == null &&
        parsed.status == WorkRequestStatus.completed) {
      return parsed.copyWith(isHandoverVerified: true);
    }
    return parsed;
  }

  WorksiteRepositoryException _mapSparkPermissionError(
    Object error, {
    required String permissionDeniedAr,
    required String permissionDeniedEn,
  }) {
    final wrapped = WorksiteRepositoryException.fromFirebase(error);
    if (wrapped.code == 'permission-denied') {
      return WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: permissionDeniedAr,
        messageEn: permissionDeniedEn,
      );
    }
    return wrapped;
  }

  @override
  Future<WorkRequest> createRequest(WorkRequest request) async {
    final uid = await _requireSignedInUid(expectedUid: request.requesterId);

    final itemsBudget = request.maxItemsCapMinor.minorUnits > 0
        ? request.maxItemsCapMinor.minorUnits
        : request.estimatedItemsCostMinor.minorUnits;
    final budgetMinor = itemsBudget + request.deliveryFeeBudgetMinor.minorUnits;
    if (budgetMinor <= 0) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'يجب أن تكون الميزانية التقديرية أكبر من صفر.',
        messageEn: 'Total budget minor units must be a positive integer.',
      );
    }

    final cleanTitle = request.title.trim();
    final cleanDesc = request.description.trim().isNotEmpty
        ? request.description.trim()
        : (request.itemNotes?.trim().isNotEmpty == true
            ? request.itemNotes!.trim()
            : cleanTitle);
    final cleanPickup = request.pickupLocation.trim();
    final cleanDropoff = request.dropoffWorksite.trim();
    final cleanArea = request.municipality.trim();

    try {
      final result = await _functionsClient.call('createWorkRequest', {
        'title': cleanTitle,
        'description': cleanDesc,
        'pickupLocation': cleanPickup,
        'deliveryLocation': cleanDropoff,
        'deliveryArea': cleanArea,
        'budgetMinor': budgetMinor,
        'paymentMethod': request.paymentMethod.value,
        if (request.requesterName.trim().isNotEmpty)
          'requesterName': request.requesterName.trim(),
      });

      final rawRequest = result['request'];
      if (rawRequest is Map) {
        return _parseWorkRequest(
          normalizeFirestoreDocument(
            rawRequest.map((k, v) => MapEntry(k.toString(), v)),
            fallbackId: result['requestId']?.toString(),
          ),
        );
      }

      final createdId = result['requestId']?.toString() ?? '';
      if (createdId.isNotEmpty) {
        final fetched = await getRequestById(createdId);
        if (fetched != null) return fetched;
      }

      throw const WorksiteRepositoryException(
        code: 'internal',
        messageAr: 'تعذّر قراءة بيانات الطلب بعد إنشائه.',
        messageEn: 'Server response did not include created WorkRequest.',
      );
    } on WorksiteRepositoryException catch (e) {
      if (!_isSparkFallbackTrigger(e)) rethrow;

      final gateway = _sparkGateway!;
      final requestId = request.id.trim().isNotEmpty
          ? request.id.trim()
          : _generateClientId('req');
      final eventId = _generateClientId('evt');
      final ts = _timestampToken();

      // Spark client create strictly omits server-locked/nullable meta fields and uses
      // string pickupLocation/deliveryLocation to stay well under the 1,000 AST cap.
      final doc = <String, dynamic>{
        'id': requestId,
        'requesterId': uid,
        if (request.requesterName.trim().isNotEmpty)
          'requesterName': request.requesterName.trim(),
        'category': 'worksite_supply',
        if (request.supplyCategory.trim().isNotEmpty)
          'supplyCategory': request.supplyCategory.trim(),
        'title': cleanTitle,
        'description': cleanDesc,
        'pickupLocation': cleanPickup,
        'deliveryLocation': cleanDropoff,
        'deliveryArea': cleanArea,
        if (request.siteContactName?.trim().isNotEmpty == true)
          'siteContactName': request.siteContactName!.trim(),
        if (request.siteContactPhone?.trim().isNotEmpty == true)
          'siteContactPhone': request.siteContactPhone!.trim(),
        if (request.itemNotes?.trim().isNotEmpty == true)
          'itemNotes': request.itemNotes!.trim(),
        'budgetMinor': budgetMinor,
        'estimatedItemsCostMinor': request.estimatedItemsCostMinor.minorUnits,
        'maxItemsCapMinor': request.maxItemsCapMinor.minorUnits,
        'deliveryFeeBudgetMinor': request.deliveryFeeBudgetMinor.minorUnits,
        'paymentMethod': request.paymentMethod.value,
        'paymentStatus': PaymentSettlementStatus.unpaid.value,
        'paymentProofUrl': null,
        'paymentReference': null,
        'status': WorkRequestStatus.open.value,
        'offerCount': 0,
        'selectedOfferId': null,
        'assignedProviderId': null,
        'assignedProviderName': null,
        'agreedAmountMinor': null,
        'agreedFeeMinor': null,
        'isHandoverVerified': false,
        'cancellationReason': null,
        'disputeReason': null,
        if (request.scheduledBy != null)
          'scheduledBy': _scheduledByToken(request.scheduledBy!),
        'createdAt': ts,
        'updatedAt': ts,
      };

      final eventDoc = <String, dynamic>{
        'id': eventId,
        'requestId': requestId,
        'actorId': uid,
        'actorRole': 'requester',
        'type': 'request_created',
        'eventType': 'request_created',
        'toStatus': WorkRequestStatus.open.value,
        'note': 'تم إنشاء طلب التوريد بنجاح.',
        'createdAt': ts,
      };

      try {
        await gateway.createRequestAndEvent(
          requestId: requestId,
          requestDoc: doc,
          eventId: eventId,
          eventDoc: eventDoc,
        );
      } catch (err) {
        throw _mapSparkPermissionError(
          err,
          permissionDeniedAr:
              'تعذّر إنشاء الطلب بسبب قيود صلاحيات Firestore. تحقق من تسجيل الدخول وصحة الحقول.',
          permissionDeniedEn:
              'Firestore rules denied creating this work request. Check sign-in status and required fields.',
        );
      }

      final fetched = await getRequestById(requestId);
      if (fetched != null) return fetched;

      final nowUtc = DateTime.now().toUtc();
      return request.copyWith(
        id: requestId,
        requesterId: uid,
        status: WorkRequestStatus.open,
        paymentSettlementStatus: PaymentSettlementStatus.unpaid,
        offerCount: 0,
        createdAt: nowUtc,
        updatedAt: nowUtc,
      );
    }
  }

  @override
  Future<List<WorkRequest>> listRequests({
    WorkRequestStatus? status,
    String? municipality,
    String? requesterId,
    String? assignedProviderId,
    int limit = 50,
  }) async {
    await _requireSignedInUid();
    try {
      final hasSecondaryFilter =
          (requesterId != null && requesterId.trim().isNotEmpty) &&
                  (status != null ||
                      (municipality != null && municipality.trim().isNotEmpty)) ||
              (assignedProviderId != null &&
                      assignedProviderId.trim().isNotEmpty) &&
                  (status != null ||
                      (municipality != null && municipality.trim().isNotEmpty)) ||
              (municipality != null &&
                  municipality.trim().isNotEmpty &&
                  status == null);
      final fetchLimit = hasSecondaryFilter ? limit * 2 : limit;

      final docs = await _store.queryWorkRequests(
        status: status,
        municipality: municipality,
        requesterId: requesterId,
        assignedProviderId: assignedProviderId,
        limit: fetchLimit,
      );

      final cleanArea = municipality?.trim().toLowerCase();
      final cleanReq = requesterId?.trim();
      final cleanProv = assignedProviderId?.trim();

      final filtered = docs.map(_parseWorkRequest).where((r) {
        if (status != null && r.status != status) return false;
        if (cleanArea != null &&
            cleanArea.isNotEmpty &&
            r.municipality.trim().toLowerCase() != cleanArea &&
            !r.municipality.toLowerCase().contains(cleanArea)) {
          return false;
        }
        if (cleanReq != null && cleanReq.isNotEmpty && r.requesterId != cleanReq) {
          return false;
        }
        if (cleanProv != null &&
            cleanProv.isNotEmpty &&
            r.assignedProviderId != cleanProv) {
          return false;
        }
        return true;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filtered.take(limit).toList();
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<WorkRequest?> getRequestById(String requestId) async {
    await _requireSignedInUid();
    final cleanId = requestId.trim();
    if (cleanId.isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'معرف الطلب مطلوب.',
        messageEn: 'requestId is required.',
      );
    }
    try {
      final doc = await _store.getWorkRequestDoc(cleanId);
      if (doc == null) return null;
      return _parseWorkRequest(doc);
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<List<WorkOffer>> listOffersForRequest(String requestId) async {
    await _requireSignedInUid();
    final cleanId = requestId.trim();
    if (cleanId.isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'معرف الطلب مطلوب.',
        messageEn: 'requestId is required.',
      );
    }
    try {
      final docs = await _store.queryWorkOffers(cleanId);
      return docs.map(WorkOffer.fromJson).toList();
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<WorkOffer> submitOffer(WorkOffer offer) async {
    final uid = await _requireSignedInUid(expectedUid: offer.providerId);
    final serviceFeeMinor = offer.proposedFeeMinor.minorUnits;
    final totalAmountMinor =
        (offer.estimatedItemsCostMinor?.minorUnits ?? 0) + serviceFeeMinor;
    if (serviceFeeMinor < 0 || totalAmountMinor <= 0) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'قيمة العرض ورسوم التوصيل يجب أن تكون أرقاماً صحيحة موجبة.',
        messageEn: 'Offer totalAmountMinor must be > 0 and fee >= 0.',
      );
    }

    final cleanReqId = offer.requestId.trim();

    try {
      final result = await _functionsClient.call('submitWorkOffer', {
        'requestId': cleanReqId,
        'totalAmountMinor': totalAmountMinor,
        'serviceFeeMinor': serviceFeeMinor,
        'etaMinutes': offer.estimatedEtaMinutes,
        if (offer.notes != null && offer.notes!.trim().isNotEmpty)
          'notes': offer.notes!.trim(),
      });

      final rawOffer = result['offer'];
      if (rawOffer is Map) {
        return WorkOffer.fromJson(
          normalizeFirestoreDocument(
            rawOffer.map((k, v) => MapEntry(k.toString(), v)),
            fallbackId: result['offerId']?.toString(),
          ),
        );
      }

      return offer.copyWith(
        id: result['offerId']?.toString() ?? offer.id,
        status: 'pending',
      );
    } on WorksiteRepositoryException catch (e) {
      if (!_isSparkFallbackTrigger(e)) rethrow;

      final gateway = _sparkGateway!;
      final reqDoc = await _store.getWorkRequestDoc(cleanReqId);
      if (reqDoc == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'طلب التوريد غير موجود.',
          messageEn: 'Work request not found.',
        );
      }
      if (reqDoc['requesterId'] == uid) {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'لا يمكنك تقديم عرض على طلب قمت بإنشائه.',
          messageEn: 'Requester cannot submit an offer on their own request.',
        );
      }
      final statusStr = reqDoc['status']?.toString() ?? '';
      if (statusStr != 'open' && statusStr != 'offer_received') {
        throw WorksiteRepositoryException(
          code: 'failed-precondition',
          messageAr: 'لا يمكن تقديم عرض في حالة الطلب الحالية.',
          messageEn: "Cannot submit offer when request status is '$statusStr'.",
        );
      }

      final provDoc = await gateway.getProviderProfileDoc(uid);
      if (provDoc == null || provDoc['approvalStatus'] != 'approved') {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr:
              'تقديم العروض متاح فقط للمزودين المعتمدين بالبطاقة القطرية (QID).',
          messageEn:
              'Provider profile must have approvalStatus == approved to submit offers.',
        );
      }

      final offerId = offer.id.trim().isNotEmpty
          ? offer.id.trim()
          : _generateClientId('off');
      final resolvedName = offer.providerName.trim().isNotEmpty
          ? offer.providerName.trim()
          : (provDoc['fullName']?.toString().trim().isNotEmpty == true
              ? provDoc['fullName'].toString().trim()
              : 'مزود معتمد');
      final resolvedRating =
          (provDoc['ratingAvg'] as num?)?.toDouble() ?? offer.providerRating;
      final resolvedJobs =
          (provDoc['completedTasksCount'] as num?)?.toInt() ??
              offer.providerCompletedJobs;
      final ts = _timestampToken();

      final offerDoc = <String, dynamic>{
        'id': offerId,
        'requestId': cleanReqId,
        'providerId': uid,
        'providerName': resolvedName,
        'providerRating': resolvedRating,
        'providerCompletedJobs': resolvedJobs,
        'totalAmountMinor': totalAmountMinor,
        'serviceFeeMinor': serviceFeeMinor,
        if (offer.estimatedItemsCostMinor != null)
          'estimatedItemsCostMinor': offer.estimatedItemsCostMinor!.minorUnits,
        'etaMinutes': offer.estimatedEtaMinutes,
        if (offer.notes != null && offer.notes!.trim().isNotEmpty)
          'notes': offer.notes!.trim(),
        'isSelected': false,
        'status': 'pending',
        'createdAt': ts,
        'updatedAt': ts,
      };

      try {
        await gateway.createWorkOffer(offerId: offerId, offerDoc: offerDoc);
      } catch (err) {
        throw _mapSparkPermissionError(
          err,
          permissionDeniedAr:
              'يتطلب تقديم العروض اعتماد حساب المزود، كما يتطلب تحديث عداد الطلب تفعيل Cloud Functions (خطة Blaze).',
          permissionDeniedEn:
              'Offer submission denied by Firestore rules. Provider approval and Cloud Functions (Blaze) are required for offerCount updates.',
        );
      }

      return offer.copyWith(
        id: offerId,
        requestId: cleanReqId,
        providerId: uid,
        providerName: resolvedName,
        providerRating: resolvedRating,
        providerCompletedJobs: resolvedJobs,
        isSelected: false,
        status: 'pending',
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }

  /// Withdraws a pending offer owned by [providerId].
  Future<void> withdrawOffer({
    required String requestId,
    required String offerId,
    required String providerId,
  }) async {
    final uid = await _requireSignedInUid(expectedUid: providerId);
    final gateway = _sparkGateway;
    if (gateway == null) {
      throw const WorksiteRepositoryException(
        code: 'unavailable',
        messageAr: 'خدمة سحب العرض غير متاحة في هذه البيئة.',
        messageEn: 'Offer withdrawal is unavailable in this store configuration.',
      );
    }
    final existing = await gateway.getWorkOfferDoc(offerId.trim());
    if (existing == null || existing['requestId'] != requestId.trim()) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'العرض المطلوب غير موجود.',
        messageEn: 'Offer not found.',
      );
    }
    if (existing['providerId'] != uid) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'صاحب العرض فقط يمكنه سحب عرضه.',
        messageEn: 'Only the offer owner may withdraw it.',
      );
    }
    if (existing['status'] != 'pending') {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'يمكن سحب العروض المعلقة فقط.',
        messageEn: 'Only pending offers can be withdrawn.',
      );
    }
    try {
      await gateway.withdrawWorkOffer(
        offerId: offerId.trim(),
        patch: {
          'status': 'withdrawn',
          'updatedAt': _timestampToken(),
        },
      );
    } catch (err) {
      throw _mapSparkPermissionError(
        err,
        permissionDeniedAr: 'لا يمكن سحب هذا العرض في حالته الحالية.',
        permissionDeniedEn: 'Cannot withdraw offer in its current state.',
      );
    }
  }

  @override
  Future<WorkRequest> acceptOffer({
    required String requestId,
    required String offerId,
    required String requesterId,
  }) async {
    await _requireSignedInUid(expectedUid: requesterId);
    try {
      await _functionsClient.call('acceptWorkOffer', {
        'requestId': requestId.trim(),
        'offerId': offerId.trim(),
      });

      final refreshed = await getRequestById(requestId);
      if (refreshed == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'تعذر تحميل تفاصيل الطلب بعد قبول العرض.',
          messageEn: 'Work request not found after accepting offer.',
        );
      }
      return refreshed;
    } on WorksiteRepositoryException catch (e) {
      if (!_isSparkFallbackTrigger(e)) rethrow;
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr:
            'قبول العرض وإصدار رمز التسليم السري (6 خانات) يتطلب تفعيل Cloud Functions على خطة Firebase Blaze أو التنفيذ عبر الخادم.',
        messageEn:
            'Accepting an offer and minting the cryptographic 6-char handover code requires deployed Cloud Functions (Firebase Blaze plan).',
      );
    }
  }

  @override
  Future<WorkRequest> updateFulfillmentStatus({
    required String requestId,
    required WorkRequestStatus nextStatus,
    required String actorId,
    required String actorRole,
    String? note,
    String? receiptImageUrl,
    MoneyMinor? actualReceiptTotalMinor,
  }) async {
    final uid = await _requireSignedInUid(expectedUid: actorId);
    if (nextStatus == WorkRequestStatus.completed) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr:
            'لا يمكن إكمال الطلب مباشرةً؛ يجب إدخال رمز التسليم الصحيح.',
        messageEn:
            "Status 'completed' can only be set by verifyHandoverCode.",
      );
    }

    final cleanReqId = requestId.trim();
    final cleanReceipt = receiptImageUrl?.trim();
    final cleanNote = note?.trim();

    try {
      await _functionsClient.call('transitionWorkRequestStatus', {
        'requestId': cleanReqId,
        'targetStatus': nextStatus.value,
        if (cleanNote != null && cleanNote.isNotEmpty) 'reason': cleanNote,
        if (cleanReceipt != null && cleanReceipt.isNotEmpty)
          'invoiceImageUrls': [cleanReceipt],
      });

      final refreshed = await getRequestById(cleanReqId);
      if (refreshed == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'تعذر تحديث بيانات الطلب.',
          messageEn: 'Work request not found after status update.',
        );
      }
      return refreshed;
    } on WorksiteRepositoryException catch (e) {
      if (!_isSparkFallbackTrigger(e)) rethrow;

      final gateway = _sparkGateway!;
      final prevDoc = await _store.getWorkRequestDoc(cleanReqId);
      if (prevDoc == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'طلب التوريد غير موجود.',
          messageEn: 'Work request not found.',
        );
      }

      final prevStatus =
          WorkRequestStatus.tryParse(prevDoc['status']?.toString()) ??
              WorkRequestStatus.open;
      final isRequester = prevDoc['requesterId'] == uid;
      final isAssignedProvider = prevDoc['assignedProviderId'] == uid;
      final role = actorRole.trim().toLowerCase();

      if (cleanReceipt != null && cleanReceipt.isNotEmpty) {
        if (!_invoiceAttachmentStatuses.contains(nextStatus)) {
          throw const WorksiteRepositoryException(
            code: 'invalid-argument',
            messageAr:
                'لا يمكن إرفاق الفاتورة إلا عند الاستلام أو التوصيل أو انتظار التأكيد.',
            messageEn:
                'Invoice URL can only be attached on picked_up, in_transit, or delivered_pending_confirmation.',
          );
        }
        if (!_isSafeMvpUrl(cleanReceipt)) {
          throw const WorksiteRepositoryException(
            code: 'invalid-argument',
            messageAr: 'رابط صورة الفاتورة غير صالح (مطلوب HTTPS أو GS).',
            messageEn: 'Valid HTTPS/HTTP/GS invoice URL is required.',
          );
        }
      }

      final ts = _timestampToken();
      final Map<String, dynamic> patch;
      final String resolvedEventRole;

      if (nextStatus == WorkRequestStatus.cancelled &&
          isRequester &&
          (prevStatus == WorkRequestStatus.open ||
              prevStatus == WorkRequestStatus.offerReceived)) {
        resolvedEventRole = 'requester';
        patch = {
          'status': WorkRequestStatus.cancelled.value,
          if (cleanNote != null && cleanNote.isNotEmpty)
            'cancellationReason': cleanNote,
          'updatedAt': ts,
        };
      } else if ((_providerLinearNext[prevStatus] == nextStatus ||
              (prevStatus == nextStatus &&
                  _invoiceAttachmentStatuses.contains(nextStatus) &&
                  cleanReceipt != null &&
                  cleanReceipt.isNotEmpty)) &&
          isAssignedProvider &&
          (role == 'provider' || role == 'admin')) {
        resolvedEventRole = 'provider';
        final existingInvoices = prevDoc['invoiceImageUrls'] is Iterable
            ? (prevDoc['invoiceImageUrls'] as Iterable)
                .map((item) => item.toString())
                .where((url) => url.isNotEmpty)
                .toList()
            : <String>[];
        if (cleanReceipt != null &&
            cleanReceipt.isNotEmpty &&
            !existingInvoices.contains(cleanReceipt) &&
            existingInvoices.length < 5) {
          existingInvoices.add(cleanReceipt);
        }
        patch = {
          'status': nextStatus.value,
          if (cleanReceipt != null && cleanReceipt.isNotEmpty)
            'invoiceImageUrls': existingInvoices,
          'updatedAt': ts,
        };
      } else if (nextStatus == WorkRequestStatus.disputed &&
          _activeDisputableStatuses.contains(prevStatus) &&
          (isRequester || isAssignedProvider)) {
        resolvedEventRole = isRequester ? 'requester' : 'provider';
        patch = {
          'status': WorkRequestStatus.disputed.value,
          if (cleanNote != null && cleanNote.isNotEmpty)
            'disputeReason': cleanNote,
          'updatedAt': ts,
        };
      } else {
        throw WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr:
              'هذا الانتقال (${prevStatus.value} → ${nextStatus.value}) يتطلب صلاحية الإدارة أو Cloud Functions (خطة Blaze).',
          messageEn:
              "Transition '${prevStatus.value}' -> '${nextStatus.value}' requires Admin authorization or Cloud Functions (Firebase Blaze plan).",
        );
      }

      final eventId = _generateClientId('evt');
      final eventDoc = <String, dynamic>{
        'id': eventId,
        'requestId': cleanReqId,
        'actorId': uid,
        'actorRole': resolvedEventRole,
        'type': 'status_changed',
        'eventType': 'status_changed',
        'fromStatus': prevStatus.value,
        'toStatus': nextStatus.value,
        if (cleanNote != null && cleanNote.isNotEmpty) 'note': cleanNote,
        'createdAt': ts,
      };

      try {
        await gateway.updateWorkRequestAndAppendEvent(
          requestId: cleanReqId,
          requestPatch: patch,
          eventId: eventId,
          eventDoc: eventDoc,
        );
      } catch (err) {
        throw _mapSparkPermissionError(
          err,
          permissionDeniedAr:
              'تعذّر تحديث حالة الطلب وفق قواعد أمان Firestore (تأكد من اعتماد المزود وصلاحية الانتقال أو تفعيل Blaze Cloud Functions).',
          permissionDeniedEn:
              'Firestore rules denied this status update (verify approved provider status or deploy Cloud Functions on Blaze).',
        );
      }

      final refreshed = await getRequestById(cleanReqId);
      if (refreshed == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'تعذر تحديث بيانات الطلب.',
          messageEn: 'Work request not found after status update.',
        );
      }
      return refreshed;
    }
  }

  @override
  Future<String> getRequesterHandoverCode({
    required String requestId,
    required String requesterId,
  }) async {
    final uid = await _requireSignedInUid(expectedUid: requesterId);
    try {
      final view = await _store.getHandoverViewDoc(requestId.trim());
      if (view == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'لا يوجد رمز تسليم نشط لهذا الطلب.',
          messageEn: 'No active handover view exists for this request.',
        );
      }
      final owner = view['requesterId']?.toString();
      if (owner != null && owner.isNotEmpty && owner != uid) {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'رمز التسليم متاح لصاحب الطلب فقط.',
          messageEn: 'Only the request owner may read the handover code.',
        );
      }
      final code = (view['handoverCode'] ?? '').toString().trim();
      if (code.isEmpty) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'رمز التسليم غير متوفر.',
          messageEn: 'Handover code is empty.',
        );
      }
      return code;
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<HandoverVerificationResult> verifyHandoverCode({
    required String requestId,
    required String providerId,
    required String code,
  }) async {
    final uid = await _requireSignedInUid(expectedUid: providerId);
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'يرجى إدخال رمز التسليم.',
        messageEn: 'Handover code is required.',
      );
    }

    try {
      final result = await _functionsClient.call('verifyHandoverAndComplete', {
        'requestId': requestId.trim(),
        'code': cleanCode,
      });

      final completedAt = DateTime.tryParse(
        (result['completedAtUtc'] ?? '').toString(),
      )?.toUtc();
      return HandoverVerificationResult(
        verified: true,
        requestId: requestId.trim(),
        resultingStatus: WorkRequestStatus.completed,
        message:
            'تم تأكيد التسليم وإغلاق الطلب بنجاح | Delivery verified and completed.',
        verifiedAt: completedAt ?? DateTime.now().toUtc(),
        verifiedByProviderId: uid,
      );
    } on WorksiteRepositoryException catch (e) {
      if (!_isSparkFallbackTrigger(e)) rethrow;
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr:
            'التحقق الأمني من رمز التسليم (SHA-256) وإتمام الطلب يتطلب نشر Cloud Functions على خطة Firebase Blaze.',
        messageEn:
            'Cryptographic handover verification and completion require deployed Cloud Functions (Firebase Blaze plan).',
      );
    }
  }

  @override
  Future<RequestRating> submitRating(RequestRating rating) async {
    final uid = await _requireSignedInUid(expectedUid: rating.raterUserId);
    if (rating.score < 1 || rating.score > 5) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'التقييم يجب أن يكون من 1 إلى 5 نجوم.',
        messageEn: 'Rating stars must be between 1 and 5.',
      );
    }

    final cleanReqId = rating.requestId.trim();

    try {
      final result = await _functionsClient.call('submitRequestRating', {
        'requestId': cleanReqId,
        'stars': rating.score,
        if (rating.comment != null && rating.comment!.trim().isNotEmpty)
          'comment': rating.comment!.trim(),
      });

      return rating.copyWith(
        id: result['ratingId']?.toString() ?? '${cleanReqId}_$uid',
        raterUserId: uid,
      );
    } on WorksiteRepositoryException catch (e) {
      if (!_isSparkFallbackTrigger(e)) rethrow;

      final gateway = _sparkGateway!;
      final reqDoc = await _store.getWorkRequestDoc(cleanReqId);
      if (reqDoc == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'طلب التوريد غير موجود.',
          messageEn: 'Work request not found.',
        );
      }
      if (reqDoc['status'] != WorkRequestStatus.completed.value) {
        throw const WorksiteRepositoryException(
          code: 'failed-precondition',
          messageAr: 'يمكن إرسال التقييم فقط بعد اكتمال التسليم.',
          messageEn:
              'Ratings can only be submitted after a request is completed.',
        );
      }

      final isRequester = reqDoc['requesterId'] == uid;
      final isProvider = reqDoc['assignedProviderId'] == uid;
      if (!isRequester && !isProvider) {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'أطراف الطلب فقط يمكنهم تقديم التقييم.',
          messageEn: 'Only request participants may submit ratings.',
        );
      }

      final toUserId = isRequester
          ? (reqDoc['assignedProviderId']?.toString() ?? '')
          : (reqDoc['requesterId']?.toString() ?? '');
      if (toUserId.isEmpty) {
        throw const WorksiteRepositoryException(
          code: 'failed-precondition',
          messageAr: 'تعذر تحديد الطرف المستهدف للتقييم.',
          messageEn: 'Target user is missing for rating.',
        );
      }

      final ratingId = '${cleanReqId}_$uid';
      final ts = _timestampToken();
      final ratingDoc = <String, dynamic>{
        'id': ratingId,
        'requestId': cleanReqId,
        'fromUserId': uid,
        'toUserId': toUserId,
        'fromRole': isRequester ? 'requester' : 'provider',
        'toRole': isRequester ? 'provider' : 'requester',
        'stars': rating.score,
        if (rating.comment != null && rating.comment!.trim().isNotEmpty)
          'comment': rating.comment!.trim(),
        if (rating.tags.isNotEmpty) 'tags': rating.tags.take(10).toList(),
        'createdAt': ts,
      };

      try {
        await gateway.createRating(ratingId: ratingId, ratingDoc: ratingDoc);
      } catch (err) {
        throw _mapSparkPermissionError(
          err,
          permissionDeniedAr:
              'لا يمكن إرسال التقييم (قد يكون مرسلاً مسبقاً أو الطلب غير مكتمل).',
          permissionDeniedEn:
              'Rating submission denied by Firestore rules (duplicate rating or request not completed).',
        );
      }

      return rating.copyWith(
        id: ratingId,
        raterUserId: uid,
        raterRole: isRequester ? 'requester' : 'provider',
        targetUserId: toUserId,
      );
    }
  }

  @override
  Future<WorkRequest> reportDispute({
    required String requestId,
    required String reporterId,
    required String reporterRole,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'يرجى توضيح سبب النزاع.',
        messageEn: 'Dispute reason is required.',
      );
    }
    return updateFulfillmentStatus(
      requestId: requestId,
      nextStatus: WorkRequestStatus.disputed,
      actorId: reporterId,
      actorRole: reporterRole,
      note: cleanReason,
    );
  }

  @override
  Future<List<RequestEvent>> listRequestEvents(String requestId) async {
    await _requireSignedInUid();
    try {
      final docs = await _store.queryRequestEvents(requestId.trim());
      return docs.map(RequestEvent.fromJson).toList();
    } catch (e) {
      throw WorksiteRepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<WorkRequest> recordPaymentStatus({
    required String requestId,
    required PaymentMethod method,
    required PaymentSettlementStatus settlementStatus,
    required String actorId,
    required String actorRole,
    String? proofUrl,
    String? referenceNumber,
  }) async {
    final uid = await _requireSignedInUid(expectedUid: actorId);
    final cleanReqId = requestId.trim();
    final cleanProof = proofUrl?.trim();
    final cleanRef = referenceNumber?.trim();

    try {
      await _functionsClient.call('recordPaymentStatus', {
        'requestId': cleanReqId,
        'targetPaymentStatus': settlementStatus.value,
        if (cleanProof != null && cleanProof.isNotEmpty)
          'paymentProofUrl': cleanProof,
      });

      final refreshed = await getRequestById(cleanReqId);
      if (refreshed == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'تعذر تحديث بيانات السداد.',
          messageEn: 'Work request not found after recording payment status.',
        );
      }
      return refreshed;
    } on WorksiteRepositoryException catch (e) {
      if (!_isSparkFallbackTrigger(e)) rethrow;

      final gateway = _sparkGateway!;
      if (settlementStatus != PaymentSettlementStatus.transferProofSubmitted) {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr:
              'توثيق تسوية الدفع النهائية (verified_settled) أو النزاع المالي يتطلب لوحة الإدارة أو Cloud Functions (خطة Blaze).',
          messageEn:
              'Settling payment status (verified_settled) requires Admin Portal verification or Cloud Functions (Firebase Blaze plan).',
        );
      }
      if (method != PaymentMethod.bankTransferManual) {
        throw const WorksiteRepositoryException(
          code: 'failed-precondition',
          messageAr:
              'رفع إيصال التحويل البنكي متاح فقط لطلبات التحويل البنكي اليدوي.',
          messageEn:
              'Transfer proof can only be submitted on bank_transfer_manual requests.',
        );
      }
      if (cleanProof == null || !_isSafeMvpUrl(cleanProof)) {
        throw const WorksiteRepositoryException(
          code: 'invalid-argument',
          messageAr: 'رابط إيصال التحويل البنكي مطلوب بصيغة صالحة.',
          messageEn: 'Valid HTTPS/HTTP/GS paymentProofUrl is required.',
        );
      }

      final prevDoc = await _store.getWorkRequestDoc(cleanReqId);
      if (prevDoc == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'طلب التوريد غير موجود.',
          messageEn: 'Work request not found.',
        );
      }
      if (prevDoc['requesterId'] != uid) {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'صاحب الطلب فقط يمكنه رفع إيصال التحويل البنكي.',
          messageEn: 'Only the request owner may submit bank transfer proof.',
        );
      }
      if (prevDoc['paymentMethod'] != PaymentMethod.bankTransferManual.value ||
          prevDoc['paymentStatus'] != PaymentSettlementStatus.unpaid.value) {
        throw const WorksiteRepositoryException(
          code: 'failed-precondition',
          messageAr:
              'يمكن رفع إيصال التحويل فقط للطلبات غير المسددة بطريقة التحويل البنكي اليدوي.',
          messageEn:
              'Transfer proof can only be submitted on unpaid bank_transfer_manual requests.',
        );
      }

      final ts = _timestampToken();
      final eventId = _generateClientId('evt');
      final patch = <String, dynamic>{
        'paymentStatus': PaymentSettlementStatus.transferProofSubmitted.value,
        'paymentProofUrl': cleanProof,
        if (cleanRef != null && cleanRef.isNotEmpty)
          'paymentReference': cleanRef,
        'updatedAt': ts,
      };
      final eventDoc = <String, dynamic>{
        'id': eventId,
        'requestId': cleanReqId,
        'actorId': uid,
        'actorRole': 'requester',
        'type': 'payment_status_changed',
        'eventType': 'payment_status_changed',
        'fromStatus': prevDoc['status']?.toString(),
        'toStatus': prevDoc['status']?.toString(),
        'note': cleanRef != null && cleanRef.isNotEmpty
            ? 'تم رفع إيصال التحويل البنكي (مرجع: $cleanRef).'
            : 'تم رفع إيصال التحويل البنكي.',
        'createdAt': ts,
      };

      try {
        await gateway.updateWorkRequestAndAppendEvent(
          requestId: cleanReqId,
          requestPatch: patch,
          eventId: eventId,
          eventDoc: eventDoc,
        );
      } catch (err) {
        throw _mapSparkPermissionError(
          err,
          permissionDeniedAr:
              'تعذّر حفظ إيصال التحويل البنكي وفق قواعد Firestore.',
          permissionDeniedEn:
              'Firestore rules denied updating payment transfer proof.',
        );
      }

      final refreshed = await getRequestById(cleanReqId);
      if (refreshed == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'تعذر تحديث بيانات السداد.',
          messageEn: 'Work request not found after recording payment status.',
        );
      }
      return refreshed;
    }
  }

  /// Marks a user notification as read (`isRead: true`) in Firestore,
  /// conforming to `notifications/{id}` owner-update security rules.
  Future<void> markNotificationRead(
    String notificationId, {
    String? userId,
  }) async {
    await _requireSignedInUid(expectedUid: userId);
    final cleanId = notificationId.trim();
    if (cleanId.isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'معرف الإشعار مطلوب.',
        messageEn: 'notificationId is required.',
      );
    }
    final gateway = _sparkGateway;
    if (gateway == null) {
      throw const WorksiteRepositoryException(
        code: 'unavailable',
        messageAr: 'تحديث الإشعار غير متاح في هذه البيئة.',
        messageEn:
            'Notification update is unavailable in this store configuration.',
      );
    }
    try {
      await gateway.markNotificationReadDoc(
        notificationId: cleanId,
        patch: const {'isRead': true},
      );
    } catch (err) {
      throw _mapSparkPermissionError(
        err,
        permissionDeniedAr: 'يمكن لصاحب الإشعار فقط تحديده كمقروء.',
        permissionDeniedEn:
            'Only the notification owner may mark this notification as read.',
      );
    }
  }

  bool _isSafeMvpUrl(String url) {
    return url.length >= 8 &&
        url.length <= 2000 &&
        (url.startsWith('https://') ||
            url.startsWith('http://') ||
            url.startsWith('gs://'));
  }
}
