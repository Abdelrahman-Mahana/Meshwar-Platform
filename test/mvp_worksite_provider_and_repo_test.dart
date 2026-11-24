import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/config/app_environment.dart';
import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/data/mock_data.dart';
import 'package:mashwar/data/models/worksite_models.dart';
import 'package:mashwar/data/repositories/app_repositories.dart';
import 'package:mashwar/data/repositories/contracts/i_worksite_repository.dart';
import 'package:mashwar/data/repositories/implementations/auth_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/firebase/firebase_auth_repository.dart';
import 'package:mashwar/data/repositories/implementations/firebase/firebase_provider_repository.dart';
import 'package:mashwar/data/repositories/implementations/firebase/firebase_worksite_repository.dart';
import 'package:mashwar/data/repositories/implementations/provider_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/worksite_repository_impl.dart';
import 'package:mashwar/data/services/firebase_firestore_service.dart';
import 'package:mashwar/main.dart';
import 'package:mashwar/screens/auth/welcome_screen.dart';
import 'package:mashwar/screens/main_nav_shell.dart';
import 'package:mashwar/screens/splash_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

class _MutableClock {
  DateTime currentUtc;
  _MutableClock(this.currentUtc);
  DateTime now() => currentUtc;
  void advance(Duration duration) {
    currentUtc = currentUtc.add(duration);
  }
}

class _FailingWorksiteRepository implements IWorksiteRepository {
  bool shouldFail = true;
  final WorksiteRepositoryImpl delegate;

  _FailingWorksiteRepository(this.delegate);

  void _maybeThrow() {
    if (shouldFail) {
      throw const WorksiteRepositoryException(
        code: 'unavailable',
        messageAr: 'تعذّر الاتصال بالخادم. تحقق من الإنترنت وأعد المحاولة.',
        messageEn: 'Network unavailable. Please retry.',
      );
    }
  }

  @override
  Future<WorkRequest> acceptOffer({
    required String requestId,
    required String offerId,
    required String requesterId,
  }) async {
    _maybeThrow();
    return delegate.acceptOffer(
      requestId: requestId,
      offerId: offerId,
      requesterId: requesterId,
    );
  }

  @override
  Future<WorkRequest> createRequest(WorkRequest request) async {
    _maybeThrow();
    return delegate.createRequest(request);
  }

  @override
  Future<String> getRequesterHandoverCode({
    required String requestId,
    required String requesterId,
  }) async {
    _maybeThrow();
    return delegate.getRequesterHandoverCode(
      requestId: requestId,
      requesterId: requesterId,
    );
  }

  @override
  Future<WorkRequest?> getRequestById(String requestId) async {
    _maybeThrow();
    return delegate.getRequestById(requestId);
  }

  @override
  Future<List<WorkOffer>> listOffersForRequest(String requestId) async {
    _maybeThrow();
    return delegate.listOffersForRequest(requestId);
  }

  @override
  Future<List<RequestEvent>> listRequestEvents(String requestId) async {
    _maybeThrow();
    return delegate.listRequestEvents(requestId);
  }

  @override
  Future<List<WorkRequest>> listRequests({
    WorkRequestStatus? status,
    String? municipality,
    String? requesterId,
    String? assignedProviderId,
    int limit = 50,
  }) async {
    _maybeThrow();
    return delegate.listRequests(
      status: status,
      municipality: municipality,
      requesterId: requesterId,
      assignedProviderId: assignedProviderId,
      limit: limit,
    );
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
    _maybeThrow();
    return delegate.recordPaymentStatus(
      requestId: requestId,
      method: method,
      settlementStatus: settlementStatus,
      actorId: actorId,
      actorRole: actorRole,
      proofUrl: proofUrl,
      referenceNumber: referenceNumber,
    );
  }

  @override
  Future<WorkRequest> reportDispute({
    required String requestId,
    required String reporterId,
    required String reporterRole,
    required String reason,
  }) async {
    _maybeThrow();
    return delegate.reportDispute(
      requestId: requestId,
      reporterId: reporterId,
      reporterRole: reporterRole,
      reason: reason,
    );
  }

  @override
  Future<WorkOffer> submitOffer(WorkOffer offer) async {
    _maybeThrow();
    return delegate.submitOffer(offer);
  }

  @override
  Future<RequestRating> submitRating(RequestRating rating) async {
    _maybeThrow();
    return delegate.submitRating(rating);
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
    _maybeThrow();
    return delegate.updateFulfillmentStatus(
      requestId: requestId,
      nextStatus: nextStatus,
      actorId: actorId,
      actorRole: actorRole,
      note: note,
      receiptImageUrl: receiptImageUrl,
      actualReceiptTotalMinor: actualReceiptTotalMinor,
    );
  }

  @override
  Future<HandoverVerificationResult> verifyHandoverCode({
    required String requestId,
    required String providerId,
    required String code,
  }) async {
    _maybeThrow();
    return delegate.verifyHandoverCode(
      requestId: requestId,
      providerId: providerId,
      code: code,
    );
  }
}

class _InMemoryFirebaseWorksiteStore implements FirebaseWorksiteStore {
  final Map<String, Map<String, dynamic>> requests = {};
  final Map<String, List<Map<String, dynamic>>> offers = {};
  final Map<String, Map<String, dynamic>> handoverViews = {};
  final Map<String, List<Map<String, dynamic>>> events = {};
  bool failQueries = false;

  @override
  Future<Map<String, dynamic>?> getHandoverViewDoc(String requestId) async {
    if (failQueries) throw const SocketException('Offline');
    return handoverViews[requestId];
  }

  @override
  Future<Map<String, dynamic>?> getWorkRequestDoc(String requestId) async {
    if (failQueries) throw const SocketException('Offline');
    return requests[requestId];
  }

  @override
  Future<List<Map<String, dynamic>>> queryRequestEvents(String requestId) async {
    if (failQueries) throw const SocketException('Offline');
    return events[requestId] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> queryWorkOffers(String requestId) async {
    if (failQueries) throw const SocketException('Offline');
    return offers[requestId] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> queryWorkRequests({
    WorkRequestStatus? status,
    String? municipality,
    String? requesterId,
    String? assignedProviderId,
    int limit = 50,
  }) async {
    if (failQueries) throw const SocketException('Offline');
    return requests.values.take(limit).toList();
  }
}

class _InMemoryFirebaseProviderStore implements FirebaseProviderStore {
  final Map<String, Map<String, dynamic>> profiles = {};
  final Map<String, Map<String, dynamic>> verifications = {};
  final Map<String, Map<String, Map<String, dynamic>>> savedWorksites = {};

  @override
  Future<Map<String, dynamic>?> getProviderProfileDoc(String uid) async =>
      profiles[uid];

  @override
  Future<Map<String, dynamic>?> getProviderVerificationDoc(String uid) async =>
      verifications[uid];

  @override
  Future<List<Map<String, dynamic>>> listSavedWorksiteDocs(
    String ownerUid,
  ) async {
    return (savedWorksites[ownerUid] ?? {}).values.toList();
  }

  @override
  Future<List<Map<String, dynamic>>> queryPendingProviderProfiles(
    int limit,
  ) async {
    return profiles.values
        .where((p) => p['approvalStatus'] == 'pending')
        .take(limit)
        .toList();
  }

  @override
  Future<void> saveWorksiteDoc(
    String ownerUid,
    String worksiteId,
    Map<String, dynamic> data, {
    required bool clearExistingDefaults,
  }) async {
    final map = savedWorksites.putIfAbsent(ownerUid, () => {});
    if (clearExistingDefaults) {
      for (final entry in map.entries) {
        entry.value['isDefault'] = false;
      }
    }
    map[worksiteId] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> setProviderProfileDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    profiles[uid] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> setProviderVerificationDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    verifications[uid] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> updateProviderProfileDoc(
    String uid,
    Map<String, dynamic> patch,
  ) async {
    profiles[uid] = {...?profiles[uid], ...patch};
  }

  @override
  Future<void> updateProviderVerificationDoc(
    String uid,
    Map<String, dynamic> patch,
  ) async {
    verifications[uid] = {...?verifications[uid], ...patch};
  }
}

void main() {
  group('Handover Crypto & Collection Constants', () {
    test('FirestoreCollections includes Worksite Supply collections 20-29', () {
      expect(FirestoreCollections.businessProfiles, 'business_profiles');
      expect(FirestoreCollections.providerProfiles, 'provider_profiles');
      expect(
        FirestoreCollections.providerVerifications,
        'provider_verifications',
      );
      expect(FirestoreCollections.workRequests, 'work_requests');
      expect(FirestoreCollections.workOffers, 'work_offers');
      expect(FirestoreCollections.workRequestSecrets, 'work_request_secrets');
      expect(
        FirestoreCollections.workRequestHandoverView,
        'work_request_handover_view',
      );
      expect(FirestoreCollections.requestEvents, 'request_events');
      expect(FirestoreCollections.ratings, 'ratings');
      expect(FirestoreCollections.notifications, 'notifications');
      expect(FirebaseConfig.region, 'europe-west1');
    });

    test('Pure-Dart SHA-256 matches standard NIST FIPS 180-4 test vectors', () {
      expect(
        WorksiteHandoverCrypto.sha256Hex(utf8.encode('')),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        WorksiteHandoverCrypto.sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );

      final pattern = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');
      for (var i = 0; i < 40; i++) {
        expect(WorksiteHandoverCrypto.generateCode(), matches(pattern));
      }

      final salt = WorksiteHandoverCrypto.generateSalt();
      final hash = WorksiteHandoverCrypto.hashCodeWithSalt('ab34kp', salt);
      expect(
        WorksiteHandoverCrypto.verifyHash(
          candidateCode: ' ab34kp ',
          salt: salt,
          expectedHashHex: hash,
        ),
        isTrue,
      );
      expect(
        WorksiteHandoverCrypto.verifyHash(
          candidateCode: 'AB34KQ',
          salt: salt,
          expectedHashHex: hash,
        ),
        isFalse,
      );
    });
  });

  group('Dev-Only Gating & Local Repository Parity', () {
    test('Default repositories do not leak mock data or permit mock mutations',
        () async {
      final providers = ProviderRepositoryImpl();
      final worksite = WorksiteRepositoryImpl(providerRepository: providers);

      expect(providers.isDevMockActive, isFalse);
      expect(worksite.isDevMockActive, isFalse);

      await expectLater(
        () => providers.getProviderProfile(
          ProviderRepositoryImpl.pilotApprovedProviderId,
        ),
        throwsA(isA<WorksiteRepositoryException>()),
      );
      await expectLater(
        () => worksite.listRequests(),
        throwsA(isA<WorksiteRepositoryException>()),
      );
    });

    test('Provider gate prevents self-approval, invalid QID, and unapproved bids',
        () async {
      final clock = _MutableClock(DateTime.utc(2026, 11, 24, 12, 0));
      final providers = ProviderRepositoryImpl(
        allowDevMocks: true,
        seedSampleData: false,
        now: clock.now,
      );
      final worksite = WorksiteRepositoryImpl(
        providerRepository: providers,
        allowDevMocks: true,
        seedSampleData: false,
        now: clock.now,
      );

      // Client trying to upsert with approvalStatus: approved is forced to pending.
      final now = clock.now();
      final saved = await providers.upsertProviderProfile(
        ProviderProfile(
          id: 'prov_new',
          userId: 'prov_new',
          fullName: 'Saad Al-Kaabi',
          phone: '55112233',
          vehicleType: 'Pickup',
          vehiclePlate: 'QA 1234',
          approvalStatus: ProviderApprovalStatus.approved,
          rating: 5.0,
          completedJobsCount: 99,
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(saved.approvalStatus, ProviderApprovalStatus.pending);
      expect(saved.rating, 0.0);
      expect(saved.completedJobsCount, 0);

      // Invalid QID rejected.
      await expectLater(
        () => providers.submitProviderVerification(
          userId: 'prov_new',
          qidNumber: '12345',
          qidFrontUrl: 'https://storage.mashwar.qa/f.jpg',
          qidBackUrl: 'https://storage.mashwar.qa/b.jpg',
          selfieUrl: 'https://storage.mashwar.qa/s.jpg',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'invalid-argument'),
        ),
      );

      // Valid 11-digit QID succeeds cleanly in pending status.
      final submitted = await providers.submitProviderVerification(
        userId: 'prov_new',
        qidNumber: '29663401842',
        qidFrontUrl: 'https://storage.mashwar.qa/f.jpg',
        qidBackUrl: 'https://storage.mashwar.qa/b.jpg',
        selfieUrl: 'https://storage.mashwar.qa/s.jpg',
      );
      expect(submitted.approvalStatus, ProviderApprovalStatus.pending);
      expect((await providers.listPendingVerifications()).length, 1);

      // Requester creates request.
      final req = await worksite.createRequest(
        WorkRequest(
          id: '',
          requesterId: 'req_1',
          requesterName: 'Eng. Fahad',
          title: '20 bags Portland cement',
          description: 'Deliver to Lusail Marina Plot 4',
          pickupLocation: 'Industrial Area St 10',
          dropoffWorksite: 'Lusail Marina Plot 4',
          municipality: 'لوسيل',
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(300),
          maxItemsCapMinor: MoneyMinor.fromMajorQar(340),
          deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(60),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Unapproved provider cannot submit offer.
      await expectLater(
        () => worksite.submitOffer(
          WorkOffer(
            id: '',
            requestId: req.id,
            providerId: 'prov_new',
            providerName: 'Saad',
            proposedFeeMinor: MoneyMinor.fromMajorQar(55),
            estimatedItemsCostMinor: MoneyMinor.fromMajorQar(300),
            estimatedEtaMinutes: 40,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'permission-denied'),
        ),
      );

      // Admin approves provider; now offer succeeds.
      final approved = await providers.reviewProviderApproval(
        userId: 'prov_new',
        decision: ProviderApprovalStatus.approved,
        reviewerId: 'admin_1',
      );
      expect(approved.canAcceptWorksiteJobs, isTrue);

      // Self-bidding by requester (even if also approved) is rejected.
      await providers.upsertProviderProfile(
        ProviderProfile(
          id: 'req_1',
          userId: 'req_1',
          fullName: 'Eng. Fahad',
          phone: '55998877',
          vehicleType: 'Sedan',
          vehiclePlate: 'QA 9988',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await providers.reviewProviderApproval(
        userId: 'req_1',
        decision: ProviderApprovalStatus.approved,
        reviewerId: 'admin_1',
      );
      await expectLater(
        () => worksite.submitOffer(
          WorkOffer(
            id: '',
            requestId: req.id,
            providerId: 'req_1',
            providerName: 'Eng. Fahad',
            proposedFeeMinor: MoneyMinor.fromMajorQar(50),
            estimatedItemsCostMinor: MoneyMinor.fromMajorQar(300),
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'permission-denied'),
        ),
      );
    });

    test(
        'Enforces state machine, handover 5-attempt/expiry/single-use, payment immutability & ratings',
        () async {
      final clock = _MutableClock(DateTime.utc(2026, 11, 24, 12, 0));
      final providers = ProviderRepositoryImpl(
        allowDevMocks: true,
        seedSampleData: true,
        now: clock.now,
      );
      final worksite = WorksiteRepositoryImpl(
        providerRepository: providers,
        allowDevMocks: true,
        seedSampleData: true,
        now: clock.now,
      );

      final now = clock.now();
      final created = await worksite.createRequest(
        WorkRequest(
          id: '',
          requesterId: 'req_owner',
          requesterName: 'Tariq Site Lead',
          title: 'Copper cables & breakers',
          description: 'Urgent electrical kit',
          pickupLocation: 'Industrial Area St 14',
          dropoffWorksite: 'Al Wakrah Plot 9',
          municipality: 'الوكرة',
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(200),
          maxItemsCapMinor: MoneyMinor.fromMajorQar(250),
          deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(50),
          paymentMethod: PaymentMethod.bankTransferManual,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final offer1 = await worksite.submitOffer(
        WorkOffer(
          id: '',
          requestId: created.id,
          providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
          providerName: 'Khalid Supply',
          proposedFeeMinor: MoneyMinor.fromMajorQar(45),
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(200),
          estimatedEtaMinutes: 35,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final offer2 = await worksite.submitOffer(
        WorkOffer(
          id: '',
          requestId: created.id,
          providerId: ProviderRepositoryImpl.pilotBackupProviderId,
          providerName: 'Tariq Runner',
          proposedFeeMinor: MoneyMinor.fromMajorQar(55),
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(200),
          estimatedEtaMinutes: 50,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Non-owner cannot accept offer.
      await expectLater(
        () => worksite.acceptOffer(
          requestId: created.id,
          offerId: offer1.id,
          requesterId: 'other_user',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'permission-denied'),
        ),
      );

      final accepted = await worksite.acceptOffer(
        requestId: created.id,
        offerId: offer1.id,
        requesterId: 'req_owner',
      );
      expect(accepted.status, WorkRequestStatus.accepted);
      expect(
        accepted.assignedProviderId,
        ProviderRepositoryImpl.pilotApprovedProviderId,
      );

      // Other pending offer was rejected.
      final allOffers = await worksite.listOffersForRequest(created.id);
      expect(
        allOffers.firstWhere((o) => o.id == offer2.id).status,
        'rejected',
      );

      // Requester gets 6-char handover code; non-requester is denied.
      final handoverCode = await worksite.getRequesterHandoverCode(
        requestId: created.id,
        requesterId: 'req_owner',
      );
      expect(handoverCode, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));
      await expectLater(
        () => worksite.getRequesterHandoverCode(
          requestId: created.id,
          requesterId: ProviderRepositoryImpl.pilotApprovedProviderId,
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'permission-denied'),
        ),
      );

      // Invalid transition rejected (cannot jump accepted -> picked_up).
      await expectLater(
        () => worksite.updateFulfillmentStatus(
          requestId: created.id,
          nextStatus: WorkRequestStatus.pickedUp,
          actorId: ProviderRepositoryImpl.pilotApprovedProviderId,
          actorRole: 'provider',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'failed-precondition'),
        ),
      );

      // Cannot attach invoice on in_progress.
      await expectLater(
        () => worksite.updateFulfillmentStatus(
          requestId: created.id,
          nextStatus: WorkRequestStatus.inProgress,
          actorId: ProviderRepositoryImpl.pilotApprovedProviderId,
          actorRole: 'provider',
          receiptImageUrl: 'https://storage.mashwar.qa/early.jpg',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'invalid-argument'),
        ),
      );

      // Progress through valid provider chain.
      await worksite.updateFulfillmentStatus(
        requestId: created.id,
        nextStatus: WorkRequestStatus.inProgress,
        actorId: ProviderRepositoryImpl.pilotApprovedProviderId,
        actorRole: 'provider',
      );
      await worksite.updateFulfillmentStatus(
        requestId: created.id,
        nextStatus: WorkRequestStatus.pickedUp,
        actorId: ProviderRepositoryImpl.pilotApprovedProviderId,
        actorRole: 'provider',
        receiptImageUrl: 'https://storage.mashwar.qa/inv_1.jpg',
        actualReceiptTotalMinor: MoneyMinor.fromMajorQar(195),
      );

      // Requester CANNOT cancel once picked_up.
      await expectLater(
        () => worksite.updateFulfillmentStatus(
          requestId: created.id,
          nextStatus: WorkRequestStatus.cancelled,
          actorId: 'req_owner',
          actorRole: 'requester',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'failed-precondition'),
        ),
      );

      await worksite.updateFulfillmentStatus(
        requestId: created.id,
        nextStatus: WorkRequestStatus.inTransit,
        actorId: ProviderRepositoryImpl.pilotApprovedProviderId,
        actorRole: 'provider',
      );
      await worksite.updateFulfillmentStatus(
        requestId: created.id,
        nextStatus: WorkRequestStatus.deliveredPendingConfirmation,
        actorId: ProviderRepositoryImpl.pilotApprovedProviderId,
        actorRole: 'provider',
      );

      // Requester CANNOT self-complete.
      await expectLater(
        () => worksite.updateFulfillmentStatus(
          requestId: created.id,
          nextStatus: WorkRequestStatus.completed,
          actorId: 'req_owner',
          actorRole: 'requester',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'failed-precondition'),
        ),
      );

      // Wrong handover code decrements attempts and fails.
      await expectLater(
        () => worksite.verifyHandoverCode(
          requestId: created.id,
          providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
          code: 'WRONG1',
        ),
        throwsA(
          isA<WorksiteRepositoryException>().having(
            (e) => e.details?['attemptsRemaining'],
            'attemptsRemaining',
            4,
          ),
        ),
      );

      // Valid handover code (lowercase + spaces) succeeds & marks completed.
      final verified = await worksite.verifyHandoverCode(
        requestId: created.id,
        providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
        code: ' ${handoverCode.toLowerCase()} ',
      );
      expect(verified.verified, isTrue);
      expect(verified.resultingStatus, WorkRequestStatus.completed);

      // Reusing code is rejected.
      await expectLater(
        () => worksite.verifyHandoverCode(
          requestId: created.id,
          providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
          code: handoverCode,
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'failed-precondition'),
        ),
      );

      // Payment proof & immutability once verified_settled.
      await worksite.recordPaymentStatus(
        requestId: created.id,
        method: PaymentMethod.bankTransferManual,
        settlementStatus: PaymentSettlementStatus.transferProofSubmitted,
        actorId: 'req_owner',
        actorRole: 'requester',
        proofUrl: 'https://storage.mashwar.qa/transfer_proof.jpg',
        referenceNumber: 'QNB-883920',
      );
      // Non-admin cannot verify settlement.
      await expectLater(
        () => worksite.recordPaymentStatus(
          requestId: created.id,
          method: PaymentMethod.bankTransferManual,
          settlementStatus: PaymentSettlementStatus.verifiedSettled,
          actorId: 'req_owner',
          actorRole: 'requester',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'permission-denied'),
        ),
      );
      await worksite.recordPaymentStatus(
        requestId: created.id,
        method: PaymentMethod.bankTransferManual,
        settlementStatus: PaymentSettlementStatus.verifiedSettled,
        actorId: 'admin_1',
        actorRole: 'admin',
      );
      // Once verified_settled, cannot overwrite.
      await expectLater(
        () => worksite.recordPaymentStatus(
          requestId: created.id,
          method: PaymentMethod.bankTransferManual,
          settlementStatus: PaymentSettlementStatus.disputed,
          actorId: 'admin_1',
          actorRole: 'admin',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'failed-precondition'),
        ),
      );

      // Submit rating once; duplicate rejected.
      final rating = await worksite.submitRating(
        RequestRating(
          id: '',
          requestId: created.id,
          raterUserId: 'req_owner',
          raterRole: 'requester',
          targetUserId: ProviderRepositoryImpl.pilotApprovedProviderId,
          score: 5,
          comment: 'Fast site delivery with invoice',
          createdAt: clock.now(),
        ),
      );
      expect(rating.score, 5);
      await expectLater(
        () => worksite.submitRating(rating),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'already-exists'),
        ),
      );
    });

    test('Handover code rejects after 5 wrong attempts and after 24h expiry',
        () async {
      final clock = _MutableClock(DateTime.utc(2026, 11, 24, 12, 0));
      final providers = ProviderRepositoryImpl(
        allowDevMocks: true,
        seedSampleData: true,
        now: clock.now,
      );
      final worksite = WorksiteRepositoryImpl(
        providerRepository: providers,
        allowDevMocks: true,
        seedSampleData: false,
        now: clock.now,
      );

      Future<({String requestId, String code})> prepareAtHandover() async {
        final req = await worksite.createRequest(
          WorkRequest(
            id: '',
            requesterId: 'req_1',
            requesterName: 'Fahad',
            title: 'Pipes',
            description: 'PVC pipes',
            pickupLocation: 'Industrial Area',
            dropoffWorksite: 'Lusail',
            municipality: 'لوسيل',
            estimatedItemsCostMinor: MoneyMinor.fromMajorQar(100),
            maxItemsCapMinor: MoneyMinor.fromMajorQar(120),
            deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(30),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
        final off = await worksite.submitOffer(
          WorkOffer(
            id: '',
            requestId: req.id,
            providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
            providerName: 'Khalid',
            proposedFeeMinor: MoneyMinor.fromMajorQar(30),
            estimatedItemsCostMinor: MoneyMinor.fromMajorQar(100),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
        await worksite.acceptOffer(
          requestId: req.id,
          offerId: off.id,
          requesterId: 'req_1',
        );
        final code = await worksite.getRequesterHandoverCode(
          requestId: req.id,
          requesterId: 'req_1',
        );
        for (final s in [
          WorkRequestStatus.inProgress,
          WorkRequestStatus.pickedUp,
          WorkRequestStatus.inTransit,
          WorkRequestStatus.deliveredPendingConfirmation,
        ]) {
          await worksite.updateFulfillmentStatus(
            requestId: req.id,
            nextStatus: s,
            actorId: ProviderRepositoryImpl.pilotApprovedProviderId,
            actorRole: 'provider',
          );
        }
        return (requestId: req.id, code: code);
      }

      // 1. Exhaust 5 attempts
      final flow1 = await prepareAtHandover();
      for (var i = 0; i < 5; i++) {
        await expectLater(
          () => worksite.verifyHandoverCode(
            requestId: flow1.requestId,
            providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
            code: 'BAD999',
          ),
          throwsA(isA<WorksiteRepositoryException>()),
        );
      }
      // Even valid code fails once attempts exhausted.
      await expectLater(
        () => worksite.verifyHandoverCode(
          requestId: flow1.requestId,
          providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
          code: flow1.code,
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.messageEn, 'msg', contains('exhausted')),
        ),
      );

      // 2. Expiry after 24h
      final flow2 = await prepareAtHandover();
      clock.advance(const Duration(hours: 24, minutes: 1));
      await expectLater(
        () => worksite.verifyHandoverCode(
          requestId: flow2.requestId,
          providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
          code: flow2.code,
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.messageEn, 'msg', contains('expired')),
        ),
      );
    });
  });

  group('WorksiteProvider State, Persistence Across Restart, Filters & Recovery',
      () {
    test(
        'Persists created requests across WorksiteProvider restart, filters accurately, and builds clean Quick Reorder draft',
        () async {
      final providers = ProviderRepositoryImpl(
        allowDevMocks: true,
        seedSampleData: true,
      );
      final worksiteRepo = WorksiteRepositoryImpl(
        providerRepository: providers,
        allowDevMocks: true,
        seedSampleData: false,
      );

      // Empty state check before any requests exist.
      final provider1 = WorksiteProvider(
        worksiteRepository: worksiteRepo,
        providerRepository: providers,
        initialUserId: 'req_alpha',
        initialUserName: 'Eng. Nasser',
      );
      await provider1.loadRequests();
      expect(provider1.isEmpty, isTrue);
      expect(provider1.hasError, isFalse);

      // Create two requests across different municipalities & budgets.
      final createdLusail = await provider1.createRequest(
        title: 'Safety harness kit',
        description: '4 full-body safety harnesses',
        pickupLocation: 'Industrial Area St 18',
        dropoffWorksite: 'Lusail Marina Plot 12',
        municipality: 'لوسيل',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(400),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(450),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(50),
      );
      expect(createdLusail, isNotNull);

      final createdWakrah = await provider1.createRequest(
        requesterId: 'req_beta',
        requesterName: 'Other User',
        title: 'Water pump valves',
        description: 'Brass check valves',
        pickupLocation: 'Salwa Road',
        dropoffWorksite: 'Al Wakrah Site 3',
        municipality: 'الوكرة',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(150),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(170),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(30),
      );
      expect(createdWakrah, isNotNull);

      // Simulate app restart by creating a fresh WorksiteProvider backed by the same repo.
      provider1.dispose();
      final provider2 = WorksiteProvider(
        worksiteRepository: worksiteRepo,
        providerRepository: providers,
        initialUserId: 'req_alpha',
        initialUserName: 'Eng. Nasser',
      );
      await provider2.loadRequests();
      expect(provider2.requests.length, 2);
      expect(provider2.isEmpty, isFalse);

      // Filters: area, maxBudgetMinor, onlyMine, assignedToMe.
      provider2.applyFilters(area: 'الوكرة');
      expect(provider2.requests.length, 1);
      expect(provider2.requests.first.id, createdWakrah!.id);

      provider2.clearFilters();
      provider2.applyFilters(maxBudgetMinor: 20000); // 200 QAR max total
      expect(provider2.requests.length, 1);
      expect(provider2.requests.first.id, createdWakrah.id);

      provider2.clearFilters();
      provider2.applyFilters(onlyMine: true);
      expect(provider2.requests.length, 1);
      expect(provider2.requests.first.requesterId, 'req_alpha');

      // Assign offer to pilot supplier and test assignedToMe filter.
      provider2.clearFilters();
      final offer = await provider2.submitOffer(
        requestId: createdLusail!.id,
        providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
        providerName: 'Khalid Supply',
        proposedFeeMinor: MoneyMinor.fromMajorQar(45),
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(400),
      );
      expect(offer, isNotNull);

      final accepted = await provider2.acceptOffer(
        requestId: createdLusail.id,
        offerId: offer!.id,
        requesterId: 'req_alpha',
      );
      expect(accepted, isNotNull);
      expect(provider2.activeHandoverCode, isNotNull);

      provider2.syncAuthSession(
        uid: ProviderRepositoryImpl.pilotApprovedProviderId,
        fullName: 'Khalid Supply',
      );
      // Handover code cleared when active user switches away from requester!
      expect(provider2.activeHandoverCode, isNull);
      provider2.applyFilters(assignedToMe: true);
      expect(provider2.requests.length, 1);
      expect(provider2.requests.first.id, createdLusail.id);

      // Quick Reorder draft resets stale assignment/payment/handover state.
      final draft = provider2.buildReorderDraft(accepted!);
      expect(draft.sourceRequestId, createdLusail.id);
      expect(draft.title, createdLusail.title);
      expect(draft.estimatedItemsCostMinor, const MoneyMinor(40000));

      final reordered = await provider2.createRequest(
        requesterId: 'req_alpha',
        requesterName: 'Eng. Nasser',
        title: draft.title,
        description: draft.description,
        pickupLocation: draft.pickupLocation,
        dropoffWorksite: draft.dropoffWorksite,
        municipality: draft.municipality,
        estimatedItemsCostMinor: draft.estimatedItemsCostMinor,
        maxItemsCapMinor: draft.maxItemsCapMinor,
        deliveryFeeBudgetMinor: draft.deliveryFeeBudgetMinor,
        sourceRequestId: draft.sourceRequestId,
      );
      expect(reordered, isNotNull);
      expect(reordered!.id, isNot(createdLusail.id));
      expect(reordered.status, WorkRequestStatus.open);
      expect(reordered.selectedOfferId, isNull);
      expect(reordered.assignedProviderId, isNull);
      expect(provider2.sourceRequestIdFor(reordered.id), createdLusail.id);

      // Saved worksites & provider profile loading.
      final site = await provider2.addSavedWorksite(
        SavedWorksite(
          id: '',
          ownerUserId: 'req_alpha',
          label: 'Site B',
          municipality: 'لوسيل',
          zoneOrStreet: 'Zone 69',
          siteContactName: 'Nasser',
          siteContactPhone: '55112233',
          isDefault: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      expect(site, isNotNull);
      expect(provider2.savedWorksites.length, 1);

      final loadedProf = await provider2.loadProviderProfile(
        ProviderRepositoryImpl.pilotApprovedProviderId,
      );
      expect(loadedProf, isNotNull);
      expect(provider2.isApprovedProvider, isTrue);

      provider2.dispose();
    });

    test('Propagates network errors explicitly and recovers on retryLastLoad',
        () async {
      final inner = WorksiteRepositoryImpl(
        allowDevMocks: true,
        seedSampleData: true,
      );
      final flakyRepo = _FailingWorksiteRepository(inner);
      final provider = WorksiteProvider(
        worksiteRepository: flakyRepo,
        initialUserId: 'dev_req_fahad',
      );

      await provider.loadRequests();
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isTrue);
      expect(provider.errorCode, 'unavailable');
      expect(provider.requests, isEmpty);
      expect(provider.localizedError(isArabic: false), contains('Network'));
      expect(provider.localizedError(isArabic: true), contains('تعذّر'));

      // Network recovers -> retryLastLoad clears error and loads real items.
      flakyRepo.shouldFail = false;
      await provider.retryLastLoad();
      expect(provider.hasError, isFalse);
      expect(provider.requests.length, 3);

      provider.dispose();
    });
  });

  group('Firebase Cloud Functions Callable Client & Firebase Repositories', () {
    test('Builds europe-west1 production and emulator URIs with Bearer ID token',
        () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;
      Map<String, dynamic>? capturedBody;

      final client = FirebaseFunctionsCallableClient(
        httpClient: MockClient((request) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'result': {'ok': true}
            }),
            200,
          );
        }),
        idTokenProvider: () async => 'firebase_id_token_abc',
      );

      final res = await client.call('submitWorkOffer', {'requestId': 'req_1'});
      expect(res['ok'], isTrue);
      expect(
        capturedUri.toString(),
        'https://europe-west1-mashwar-qatar-2026-ec99d.cloudfunctions.net/submitWorkOffer',
      );
      expect(capturedHeaders?['Authorization'], 'Bearer firebase_id_token_abc');
      expect(capturedBody, {
        'data': {'requestId': 'req_1'}
      });

      final emulatorClient = FirebaseFunctionsCallableClient(
        functionsBaseUrlOverride: 'http://127.0.0.1:5001',
        httpClient: MockClient((_) async => http.Response('{"result":{}}', 200)),
        idTokenProvider: () async => 'tok',
      );
      expect(
        emulatorClient.buildFunctionUri('acceptWorkOffer').toString(),
        'http://127.0.0.1:5001/mashwar-qatar-2026-ec99d/europe-west1/acceptWorkOffer',
      );

      // Unauthenticated caller fails before sending HTTP request.
      final unauthClient = FirebaseFunctionsCallableClient(
        idTokenProvider: () async => null,
      );
      await expectLater(
        () => unauthClient.call('createWorkRequest', {}),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'unauthenticated'),
        ),
      );
    });

    test('FirebaseWorksiteRepository & FirebaseProviderRepository execute callables and propagate errors',
        () async {
      final worksiteStore = _InMemoryFirebaseWorksiteStore();
      final providerStore = _InMemoryFirebaseProviderStore();
      final calledFunctions = <String>[];
      String? activeUid = 'req_uid_1';

      final functionsClient = FirebaseFunctionsCallableClient(
        httpClient: MockClient((request) async {
          final fnName = request.url.pathSegments.last;
          calledFunctions.add(fnName);
          final payload =
              (jsonDecode(request.body) as Map)['data'] as Map<String, dynamic>;

          if (fnName == 'createWorkRequest') {
            final doc = {
              'id': 'req_fb_1',
              'requesterId': activeUid,
              'requesterName': payload['requesterName'] ?? 'Eng. Khalid',
              'category': 'worksite_supply',
              'title': payload['title'],
              'description': payload['description'],
              'pickupLocation': payload['pickupLocation'],
              'deliveryLocation': payload['deliveryLocation'],
              'deliveryArea': payload['deliveryArea'],
              'budgetMinor': payload['budgetMinor'],
              'paymentMethod': payload['paymentMethod'],
              'paymentStatus': 'unpaid',
              'status': 'open',
              'offerCount': 0,
              'selectedOfferId': null,
              'assignedProviderId': null,
              'createdAt': '2026-11-24T12:00:00.000Z',
              'updatedAt': '2026-11-24T12:00:00.000Z',
            };
            worksiteStore.requests['req_fb_1'] = doc;
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'result': {'requestId': 'req_fb_1', 'request': doc}
                }),
              ),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }

          if (fnName == 'verifyHandoverAndComplete') {
            if (payload['code'] != 'K7M2P9') {
              return http.Response.bytes(
                utf8.encode(
                  jsonEncode({
                    'error': {
                      'status': 'FAILED_PRECONDITION',
                      'message':
                          'Invalid handover code. Attempts remaining: 4.',
                      'details': {'attemptsRemaining': 4},
                    }
                  }),
                ),
                412,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            worksiteStore.requests['req_fb_1'] = {
              ...worksiteStore.requests['req_fb_1']!,
              'status': 'completed',
            };
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'result': {
                    'requestId': 'req_fb_1',
                    'status': 'completed',
                    'completedAtUtc': '2026-11-24T13:00:00.000Z',
                  }
                }),
              ),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }

          if (fnName == 'adminReviewProvider') {
            final pid = payload['providerId'].toString();
            providerStore.profiles[pid] = {
              ...?providerStore.profiles[pid],
              'approvalStatus': payload['decision'],
            };
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'result': {
                    'providerId': pid,
                    'approvalStatus': payload['decision'],
                  }
                }),
              ),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }

          return http.Response.bytes(
            utf8.encode(jsonEncode({'result': {}})),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
        idTokenProvider: () async => activeUid == null ? null : 'tok_$activeUid',
      );

      final worksiteRepo = FirebaseWorksiteRepository.withDeps(
        currentUidProvider: () async => activeUid,
        functionsClient: functionsClient,
        store: worksiteStore,
      );
      final providerRepo = FirebaseProviderRepository.withDeps(
        currentUidProvider: () async => activeUid,
        functionsClient: functionsClient,
        store: providerStore,
      );

      final created = await worksiteRepo.createRequest(
        WorkRequest(
          id: '',
          requesterId: 'req_uid_1',
          requesterName: 'Eng. Khalid',
          title: 'Electrical switches',
          description: '20 Schneider switches',
          pickupLocation: 'Industrial Area St 10',
          dropoffWorksite: 'Lusail Plot 8',
          municipality: 'لوسيل',
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(200),
          maxItemsCapMinor: MoneyMinor.fromMajorQar(200),
          deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(40),
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      expect(created.id, 'req_fb_1');
      expect(calledFunctions, contains('createWorkRequest'));

      // Wrong handover code propagates typed failed-precondition exception.
      activeUid = 'prov_uid_1';
      await expectLater(
        () => worksiteRepo.verifyHandoverCode(
          requestId: 'req_fb_1',
          providerId: 'prov_uid_1',
          code: 'WRONG1',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'failed-precondition')
              .having((e) => e.details?['attemptsRemaining'], 'attempts', 4),
        ),
      );

      final verified = await worksiteRepo.verifyHandoverCode(
        requestId: 'req_fb_1',
        providerId: 'prov_uid_1',
        code: 'K7M2P9',
      );
      expect(verified.verified, isTrue);
      expect(verified.resultingStatus, WorkRequestStatus.completed);

      // Offline Firestore read fails explicitly instead of faking empty/mock success.
      worksiteStore.failQueries = true;
      await expectLater(
        () => worksiteRepo.listRequests(),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'unavailable'),
        ),
      );
      worksiteStore.failQueries = false;

      // Provider profile + verification + admin review
      await providerRepo.upsertProviderProfile(
        ProviderProfile(
          id: 'prov_uid_1',
          userId: 'prov_uid_1',
          fullName: 'Ali Al-Sulaiti',
          phone: '55667788',
          vehicleType: 'Pickup',
          vehiclePlate: 'QA 3210',
          serviceMunicipalities: const ['لوسيل'],
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      expect(
        providerStore.profiles['prov_uid_1']?['approvalStatus'],
        'pending',
      );
      await providerRepo.submitProviderVerification(
        userId: 'prov_uid_1',
        qidNumber: '29663401842',
        qidFrontUrl: 'https://storage.mashwar.qa/front.jpg',
        qidBackUrl: 'https://storage.mashwar.qa/back.jpg',
        selfieUrl: 'https://storage.mashwar.qa/selfie.jpg',
      );
      expect(
        providerStore.verifications['prov_uid_1']?['qidNumber'],
        '29663401842',
      );

      // Admin review callable updates approvalStatus.
      activeUid = 'admin_uid_1';
      final reviewed = await providerRepo.reviewProviderApproval(
        userId: 'prov_uid_1',
        decision: ProviderApprovalStatus.approved,
        reviewerId: 'admin_uid_1',
      );
      expect(reviewed.approvalStatus, ProviderApprovalStatus.approved);

      // Unauthenticated call throws unauthenticated.
      activeUid = null;
      await expectLater(
        () => worksiteRepo.listRequests(),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'unauthenticated'),
        ),
      );
    });
  });

  group('App Startup Boundaries & SplashScreen Auth Routing', () {
    Widget wrapTestWidget(Widget child, {required AuthProvider auth}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => WorksiteProvider()),
          ChangeNotifierProvider(create: (_) => RidesProvider()),
          ChangeNotifierProvider(create: (_) => ParcelsProvider()),
          ChangeNotifierProvider(create: (_) => BoardProvider()),
          ChangeNotifierProvider(create: (_) => AlertsProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: Consumer<SettingsProvider>(
          builder: (context, s, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            locale: s.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: child,
          ),
        ),
      );
    }

    test('Staging/production never boot dev mocks when Firebase fails or disabled',
        () async {
      AppRepositories.instance.useLocalMocks();

      final prodNoFirebaseErr = await initializeMashwarStartup(
        config: AppEnvironmentConfig.resolve(
          rawAppEnv: 'production',
          useFirebase: false,
          requestedDevMocks: true,
        ),
      );
      expect(prodNoFirebaseErr, isNotNull);
      expect(AppRepositories.instance.worksite, isA<WorksiteRepositoryImpl>());
      expect(
        (AppRepositories.instance.worksite as WorksiteRepositoryImpl)
            .isDevMockActive,
        isFalse,
      );

      final stagingFirebaseFailErr = await initializeMashwarStartup(
        config: AppEnvironmentConfig.resolve(
          rawAppEnv: 'staging',
          useFirebase: true,
          requestedDevMocks: true,
        ),
        firebaseInitializer: () async => throw Exception('Missing config'),
      );
      expect(stagingFirebaseFailErr, contains('staging'));
      expect(AppRepositories.instance.worksite, isA<WorksiteRepositoryImpl>());
      expect(
        (AppRepositories.instance.worksite as WorksiteRepositoryImpl)
            .isDevMockActive,
        isFalse,
      );
    });

    test(
        'initializeMashwarStartup() with null config connects to Firebase by default and rejects USE_FIREBASE=false without USE_DEV_MOCKS=true',
        () async {
      addTearDown(() {
        AppEnvironment.setFirebaseRuntimeActive(false);
        AppRepositories.instance.useLocalMocks();
      });

      var initializerCalls = 0;
      final defaultStartupErr = await initializeMashwarStartup(
        firebaseInitializer: () async {
          initializerCalls++;
        },
      );
      expect(defaultStartupErr, isNull);
      expect(initializerCalls, 1);
      expect(AppEnvironment.isFirebaseRuntimeActive, isTrue);
      expect(AppRepositories.instance.auth, isA<FirebaseAuthRepository>());
      expect(
        AppRepositories.instance.auth,
        isNot(isA<DevMockAuthRepository>()),
      );

      final explicitFalseNoMocksErr = await initializeMashwarStartup(
        config: AppEnvironmentConfig.resolve(
          rawAppEnv: 'development',
          useFirebase: false,
          requestedDevMocks: false,
        ),
      );
      expect(explicitFalseNoMocksErr, isNotNull);
      expect(explicitFalseNoMocksErr, contains('USE_DEV_MOCKS=true'));
      expect(AppEnvironment.isFirebaseRuntimeActive, isFalse);
    });

    testWidgets(
        'MashwarApp renders ServiceUnavailableScreen with Retry when startupError is present',
        (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(
        MashwarApp(
          initialStartupError: 'Firebase unavailable in staging',
          onRetryStartup: () async {
            retryCount++;
            return null;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ServiceUnavailableScreen), findsOneWidget);
      expect(find.textContaining('Firebase unavailable'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(retryCount, 1);
      expect(find.byType(ServiceUnavailableScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets(
        'SplashScreen routes to WelcomeScreen when unauthenticated and MainNavShell ONLY when authenticated',
        (tester) async {
      // 1. Unauthenticated -> WelcomeScreen
      final unauth = AuthProvider();
      await tester.pumpWidget(
        wrapTestWidget(
          const SplashScreen(
            key: ValueKey('splash_unauth'),
            splashDuration: Duration(milliseconds: 50),
          ),
          auth: unauth,
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(MainNavShell), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // 2. Partial auth (otpVerified, not authenticated) -> WelcomeScreen
      final otpOnly = AuthProvider.forTesting(status: AuthStatus.otpVerified);
      await tester.pumpWidget(
        wrapTestWidget(
          const SplashScreen(
            key: ValueKey('splash_otp_only'),
            splashDuration: Duration(milliseconds: 50),
          ),
          auth: otpOnly,
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(MainNavShell), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // 3. Restored real session via AuthProvider.restoreSession() -> MainNavShell
      final repoWithSession = DevMockAuthRepository(
        allowDevMocks: true,
        startSignedIn: true,
        initialUser: MockData.currentUser,
      );
      final restoredAuth = AuthProvider(authRepository: repoWithSession);
      await tester.pumpWidget(
        wrapTestWidget(
          const SplashScreen(
            key: ValueKey('splash_restored'),
            splashDuration: Duration(milliseconds: 50),
          ),
          auth: restoredAuth,
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(restoredAuth.status, AuthStatus.authenticated);
      expect(find.byType(MainNavShell), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);

      unauth.dispose();
      otpOnly.dispose();
      restoredAuth.dispose();
    });
  });
}
