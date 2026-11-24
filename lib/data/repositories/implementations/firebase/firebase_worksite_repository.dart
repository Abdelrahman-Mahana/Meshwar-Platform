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

class _FirestoreWorksiteStore implements FirebaseWorksiteStore {
  final FirebaseFirestore _firestore;

  _FirestoreWorksiteStore(this._firestore);

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
}

/// Production Cloud Firestore + Cloud Functions v2 implementation of [IWorksiteRepository].
///
/// All privileged writes (`createWorkRequest`, `submitWorkOffer`, `acceptWorkOffer`,
/// `transitionWorkRequestStatus`, `verifyHandoverAndComplete`, `submitRequestRating`,
/// `recordPaymentStatus`) execute through authenticated Cloud Functions v2 HTTP
/// callable endpoints and fail explicitly with [WorksiteRepositoryException] — never
/// faking success when offline or unauthorized.
class FirebaseWorksiteRepository implements IWorksiteRepository {
  final Future<String?> Function() _currentUidProvider;
  final FirebaseFunctionsCallableClient _functionsClient;
  final FirebaseWorksiteStore _store;

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
        _store =
            _FirestoreWorksiteStore(firestore ?? FirebaseFirestore.instance);

  @visibleForTesting
  FirebaseWorksiteRepository.withDeps({
    required Future<String?> Function() currentUidProvider,
    required FirebaseFunctionsCallableClient functionsClient,
    required FirebaseWorksiteStore store,
  })  : _currentUidProvider = currentUidProvider,
        _functionsClient = functionsClient,
        _store = store;

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

  @override
  Future<WorkRequest> createRequest(WorkRequest request) async {
    await _requireSignedInUid(expectedUid: request.requesterId);

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

    final result = await _functionsClient.call('createWorkRequest', {
      'title': request.title.trim(),
      'description': request.description.trim().isNotEmpty
          ? request.description.trim()
          : (request.itemNotes?.trim().isNotEmpty == true
              ? request.itemNotes!.trim()
              : request.title.trim()),
      'pickupLocation': request.pickupLocation.trim(),
      'deliveryLocation': request.dropoffWorksite.trim(),
      'deliveryArea': request.municipality.trim(),
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
    await _requireSignedInUid(expectedUid: offer.providerId);
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

    final result = await _functionsClient.call('submitWorkOffer', {
      'requestId': offer.requestId.trim(),
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
  }

  @override
  Future<WorkRequest> acceptOffer({
    required String requestId,
    required String offerId,
    required String requesterId,
  }) async {
    await _requireSignedInUid(expectedUid: requesterId);
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
    await _requireSignedInUid(expectedUid: actorId);
    if (nextStatus == WorkRequestStatus.completed) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr:
            'لا يمكن إكمال الطلب مباشرةً؛ يجب إدخال رمز التسليم الصحيح.',
        messageEn:
            "Status 'completed' can only be reached via verifyHandoverCode.",
      );
    }

    final cleanReceipt = receiptImageUrl?.trim();
    await _functionsClient.call('transitionWorkRequestStatus', {
      'requestId': requestId.trim(),
      'targetStatus': nextStatus.value,
      if (note != null && note.trim().isNotEmpty) 'reason': note.trim(),
      if (cleanReceipt != null && cleanReceipt.isNotEmpty)
        'invoiceImageUrls': [cleanReceipt],
    });

    final refreshed = await getRequestById(requestId);
    if (refreshed == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'تعذر تحديث بيانات الطلب.',
        messageEn: 'Work request not found after status update.',
      );
    }
    return refreshed;
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
      message: 'تم تأكيد التسليم وإغلاق الطلب بنجاح | Delivery verified and completed.',
      verifiedAt: completedAt ?? DateTime.now().toUtc(),
      verifiedByProviderId: uid,
    );
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

    final result = await _functionsClient.call('submitRequestRating', {
      'requestId': rating.requestId.trim(),
      'stars': rating.score,
      if (rating.comment != null && rating.comment!.trim().isNotEmpty)
        'comment': rating.comment!.trim(),
    });

    return rating.copyWith(
      id: result['ratingId']?.toString() ?? '${rating.requestId}_$uid',
      raterUserId: uid,
    );
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
    await _requireSignedInUid(expectedUid: actorId);
    await _functionsClient.call('recordPaymentStatus', {
      'requestId': requestId.trim(),
      'targetPaymentStatus': settlementStatus.value,
      if (proofUrl != null && proofUrl.trim().isNotEmpty)
        'paymentProofUrl': proofUrl.trim(),
    });

    final refreshed = await getRequestById(requestId);
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
