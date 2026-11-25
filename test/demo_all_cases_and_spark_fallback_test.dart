import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/data/demo/demo_cases_catalog.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/data/models/worksite_models.dart';
import 'package:mashwar/data/repositories/implementations/firebase/firebase_worksite_repository.dart';
import 'package:mashwar/data/repositories/implementations/provider_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/worksite_repository_impl.dart';
import 'package:mashwar/data/services/firebase_firestore_service.dart';
import 'package:mashwar/screens/home/home_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

class _InMemorySparkGatewayAndStore
    implements FirebaseWorksiteStore, SparkWorksiteWriteGateway {
  final Map<String, Map<String, dynamic>> requests = {};
  final Map<String, Map<String, dynamic>> offers = {};
  final Map<String, Map<String, dynamic>> providerProfiles = {};
  final Map<String, Map<String, dynamic>> handoverViews = {};
  final Map<String, List<Map<String, dynamic>>> eventsByRequest = {};
  final Map<String, Map<String, dynamic>> ratings = {};
  final Map<String, Map<String, dynamic>> notifications = {};

  bool throwPermissionDeniedOnEvent = false;
  bool throwPermissionDeniedOnOffer = false;

  @override
  Future<void> createRequestAndEvent({
    required String requestId,
    required Map<String, dynamic> requestDoc,
    required String eventId,
    required Map<String, dynamic> eventDoc,
  }) async {
    requests[requestId] = Map<String, dynamic>.from(requestDoc);
    if (!throwPermissionDeniedOnEvent) {
      eventsByRequest
          .putIfAbsent(requestId, () => [])
          .add(Map<String, dynamic>.from(eventDoc));
    }
  }

  @override
  Future<void> createWorkOffer({
    required String offerId,
    required Map<String, dynamic> offerDoc,
  }) async {
    if (throwPermissionDeniedOnOffer) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'غير مصرح',
        messageEn: 'permission-denied',
      );
    }
    offers[offerId] = Map<String, dynamic>.from(offerDoc);
  }

  @override
  Future<void> withdrawWorkOffer({
    required String offerId,
    required Map<String, dynamic> patch,
  }) async {
    final existing = offers[offerId];
    if (existing != null) {
      offers[offerId] = {...existing, ...patch};
    }
  }

  @override
  Future<void> updateWorkRequestAndAppendEvent({
    required String requestId,
    required Map<String, dynamic> requestPatch,
    String? eventId,
    Map<String, dynamic>? eventDoc,
  }) async {
    final existing = requests[requestId];
    if (existing != null) {
      requests[requestId] = {...existing, ...requestPatch};
    }
    if (eventId != null && eventDoc != null && !throwPermissionDeniedOnEvent) {
      eventsByRequest
          .putIfAbsent(requestId, () => [])
          .add(Map<String, dynamic>.from(eventDoc));
    }
  }

  @override
  Future<void> createRating({
    required String ratingId,
    required Map<String, dynamic> ratingDoc,
  }) async {
    ratings[ratingId] = Map<String, dynamic>.from(ratingDoc);
  }

  @override
  Future<Map<String, dynamic>?> getProviderProfileDoc(String uid) async =>
      providerProfiles[uid];

  @override
  Future<Map<String, dynamic>?> getWorkOfferDoc(String offerId) async =>
      offers[offerId];

  @override
  Future<void> markNotificationReadDoc({
    required String notificationId,
    required Map<String, dynamic> patch,
  }) async {
    final existing = notifications[notificationId];
    if (existing == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'غير موجود',
        messageEn: 'not-found',
      );
    }
    notifications[notificationId] = {...existing, ...patch};
  }

  @override
  Future<Map<String, dynamic>?> getHandoverViewDoc(String requestId) async =>
      handoverViews[requestId];

  @override
  Future<Map<String, dynamic>?> getWorkRequestDoc(String requestId) async =>
      requests[requestId];

  @override
  Future<List<Map<String, dynamic>>> queryRequestEvents(
    String requestId,
  ) async =>
      List<Map<String, dynamic>>.from(eventsByRequest[requestId] ?? const []);

  @override
  Future<List<Map<String, dynamic>>> queryWorkOffers(String requestId) async =>
      offers.values.where((o) => o['requestId'] == requestId).toList();

  @override
  Future<List<Map<String, dynamic>>> queryWorkRequests({
    WorkRequestStatus? status,
    String? municipality,
    String? requesterId,
    String? assignedProviderId,
    int limit = 50,
  }) async =>
      requests.values.take(limit).toList();
}

class _FakeAdminBackendGateway implements AdminBackendGateway {
  final bool failSyncOps;
  final Map<String, Map<String, dynamic>> staffDocs = {
    'staff_super_1': {
      'uid': 'staff_super_1',
      'email': 'abdelrahmanmahana01@gmail.com',
      'name': 'عبدالرحمن مهنا',
      'role': 'superAdmin',
      'isActive': true,
    },
  };

  final List<Map<String, dynamic>> providerProfiles = [];
  final List<Map<String, dynamic>> providerVerifications = [];
  final List<Map<String, dynamic>> workRequests = [];
  final List<Map<String, dynamic>> auditLogs = [];

  AdminAuthSessionResult? _session;
  int syncCallsCount = 0;

  _FakeAdminBackendGateway({this.failSyncOps = false});

  @override
  Future<AdminAuthSessionResult> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    _session = AdminAuthSessionResult(
      uid: 'staff_super_1',
      email: email,
      displayName: 'عبدالرحمن مهنا',
      idToken: 'tok_admin_1',
    );
    return _session!;
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }

  @override
  AdminAuthSessionResult? currentSession() => _session;

  @override
  Future<Map<String, dynamic>?> fetchAdminStaffRecord(String uid) async =>
      staffDocs[uid];

  @override
  Future<void> writeAuditLog(Map<String, dynamic> payload) async {
    auditLogs.insert(0, payload);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAuditLogs({int limit = 100}) async {
    if (failSyncOps) throw const SocketException('Offline audit');
    return auditLogs.take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProviderProfiles({
    int limit = 100,
  }) async {
    syncCallsCount++;
    if (failSyncOps) throw const SocketException('Offline profiles');
    return providerProfiles.take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProviderVerifications({
    int limit = 100,
  }) async {
    if (failSyncOps) throw const SocketException('Offline verifications');
    return providerVerifications.take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchWorkRequests({
    int limit = 100,
  }) async {
    if (failSyncOps) throw const SocketException('Offline requests');
    return workRequests.take(limit).toList();
  }

  @override
  Future<Map<String, dynamic>> callAdminReviewProvider({
    required String providerId,
    required String decision,
    required String reviewerId,
    String? reason,
  }) async =>
      {'providerId': providerId, 'approvalStatus': decision};

  @override
  Future<Map<String, dynamic>> callAdminModerateWorkRequest({
    required String requestId,
    required String action,
    required String adminUid,
    String? targetStatus,
    String? reason,
  }) async =>
      {'requestId': requestId, 'action': action};
}

void main() {
  group('MashwarDemoCasesCatalog completeness & Qatar-only invariants', () {
    test(
        'Covers all 11 statuses, 4 provider statuses, 4 settlement statuses, 7+ Qatar municipalities, 5 handover codes, and zero Egypt refs',
        () {
      final bundle = MashwarDemoCasesCatalog.build(
        now: DateTime.utc(2026, 11, 25, 10, 0),
      );

      expect(bundle.currentUserId, MashwarDemoCasesCatalog.defaultOwnerUid);
      expect(bundle.savedWorksites.length, 3);
      expect(bundle.savedWorksites.any((s) => s.isDefault), isTrue);

      // All 4 ProviderApprovalStatus values + approved profile for primary owner UID
      expect(bundle.providers.length, 8);
      final providerStatuses =
          bundle.providers.map((p) => p.profile.approvalStatus).toSet();
      expect(providerStatuses, containsAll(ProviderApprovalStatus.values));
      final ownerProvider = bundle.providerProfileFor(
        MashwarDemoCasesCatalog.defaultOwnerUid,
      );
      expect(ownerProvider, isNotNull);
      expect(ownerProvider!.approvalStatus, ProviderApprovalStatus.approved);

      // All 11 WorkRequestStatus values across 14 requests
      expect(bundle.requests.length, 14);
      final requestStatuses = bundle.requests.map((r) => r.status).toSet();
      expect(requestStatuses, containsAll(WorkRequestStatus.values));

      // Both PaymentMethods and all 4 PaymentSettlementStatus values
      final methods = bundle.requests.map((r) => r.paymentMethod).toSet();
      expect(methods, containsAll(PaymentMethod.values));
      final settlementStatuses =
          bundle.requests.map((r) => r.paymentSettlementStatus).toSet();
      expect(
        settlementStatuses,
        containsAll(PaymentSettlementStatus.values),
      );

      // All 7+ Qatar municipalities/hubs covered
      final municipalities = bundle.requests.map((r) => r.municipality).toSet();
      expect(
        municipalities,
        containsAll([
          'الدوحة',
          'لوسيل',
          'المنطقة الصناعية',
          'الوكرة',
          'الخور',
          'الريان',
          'مسيعيد',
          'أم صلال',
          'الضعاين',
          'الشيحانية',
          'الشمال',
        ]),
      );

      // Every request enforces requesterId != assignedProviderId
      for (final req in bundle.requests) {
        expect(req.requesterId, isNot(equals(req.assignedProviderId)));
        expect(bundle.eventsFor(req.id), isNotEmpty);
      }

      // Competing offers on demo_wr_03_offers_mine + 5 total catalog offers
      expect(bundle.offersFor('demo_wr_03_offers_mine').length, 3);
      expect(bundle.allOffers.length, 5);

      // Exact 5 handover codes + provider-assigned active delivered job for owner
      expect(bundle.handoverCodesByRequest, {
        'demo_wr_06_accepted': 'K7M4P9',
        'demo_wr_07_in_prog': 'Q9R3W8',
        'demo_wr_08_picked_up': 'M4N8X2',
        'demo_wr_09_transit': 'H6P2V5',
        'demo_wr_10_deliv_pend': 'T5K9B3',
      });
      final providerAssignedActive = bundle.requests.where(
        (r) =>
            r.assignedProviderId == MashwarDemoCasesCatalog.defaultOwnerUid &&
            r.status == WorkRequestStatus.deliveredPendingConfirmation,
      );
      expect(providerAssignedActive.length, 1);
      expect(providerAssignedActive.first.id, 'demo_wr_10_deliv_pend');

      // Handover SHA-256 salted hash parity
      final salt = WorksiteHandoverCrypto.generateSalt();
      final hash = WorksiteHandoverCrypto.hashCodeWithSalt('T5K9B3', salt);
      expect(
        WorksiteHandoverCrypto.verifyHash(
          candidateCode: 't5k9b3',
          salt: salt,
          expectedHashHex: hash,
        ),
        isTrue,
      );

      // Ratings, notifications, investor inquiries, audit logs
      expect(bundle.ratings.length, 2);
      expect(bundle.notifications.length, 4);
      expect(bundle.investorInquiries.length, 3);
      expect(bundle.auditLogs.length, 4);

      // Zero Egypt/EGP references
      final serialized = jsonEncode({
        'requests': bundle.requests.map((r) => r.toJson()).toList(),
        'providers': bundle.providerProfiles.map((p) => p.toJson()).toList(),
        'sites': bundle.savedWorksites.map((s) => s.toJson()).toList(),
        'inquiries': bundle.investorInquiries
            .map((i) => {'n': i.fullName, 'o': i.organization, 't': i.notes})
            .toList(),
      });
      final forbidden = RegExp(
        r'egypt|cairo|giza|egp|مصر|القاهرة|الجيزة|ج\.م',
        caseSensitive: false,
      );
      expect(forbidden.hasMatch(serialized), isFalse);
    });

    test(
        'WorksiteRepositoryImpl(seedSampleData: true) preserves default 3 pilot requests unless seedAllDemoCases is called',
        () async {
      final providerRepo = ProviderRepositoryImpl(
        allowDevMocks: true,
        seedSampleData: true,
      );
      final worksiteRepo = WorksiteRepositoryImpl(
        providerRepository: providerRepo,
        allowDevMocks: true,
        seedSampleData: true,
      );

      final defaultList = await worksiteRepo.listRequests();
      expect(defaultList.length, 3);

      worksiteRepo.seedAllDemoCases(
        currentUserId: MashwarDemoCasesCatalog.defaultOwnerUid,
      );
      final expandedList = await worksiteRepo.listRequests(limit: 50);
      expect(expandedList.length, 17); // 3 default pilot + 14 all-cases demo
      final handoverCode = await worksiteRepo.getRequesterHandoverCode(
        requestId: 'demo_wr_06_accepted',
        requesterId: MashwarDemoCasesCatalog.defaultOwnerUid,
      );
      expect(handoverCode, 'K7M4P9');
    });
  });

  group('WorksiteProvider Demo Showcase & HomeScreen Toggle', () {
    test(
        'WorksiteProvider.activateDemoShowcase and exitDemoShowcase toggle cleanly even with mocked Firebase-style repository',
        () async {
      final store = _InMemorySparkGatewayAndStore();
      store.requests['live_req_1'] = {
        'id': 'live_req_1',
        'requesterId': 'live_user_1',
        'requesterName': 'Live User',
        'category': 'worksite_supply',
        'title': 'Live Firestore Request',
        'description': 'Seeded backend request',
        'pickupLocation': 'Industrial Area',
        'deliveryLocation': 'Lusail',
        'deliveryArea': 'لوسيل',
        'budgetMinor': 25000,
        'paymentMethod': 'cash_on_delivery',
        'paymentStatus': 'unpaid',
        'status': 'open',
        'offerCount': 0,
        'createdAt': '2026-11-25T09:00:00.000Z',
        'updatedAt': '2026-11-25T09:00:00.000Z',
      };

      final functionsClient = FirebaseFunctionsCallableClient(
        httpClient: MockClient(
          (_) async => http.Response('{"error":{"status":"NOT_FOUND"}}', 404),
        ),
        idTokenProvider: () async => 'tok_1',
      );
      final worksiteRepo = FirebaseWorksiteRepository.withDeps(
        currentUidProvider: () async => 'live_user_1',
        functionsClient: functionsClient,
        store: store,
      );

      final provider = WorksiteProvider(
        worksiteRepository: worksiteRepo,
        initialUserId: 'live_user_1',
        initialUserName: 'عبدالرحمن مهنا',
      );
      await provider.loadRequests();
      expect(provider.isDemoShowcaseMode, isFalse);
      expect(provider.requests.length, 1);

      await provider.activateDemoShowcase();
      expect(provider.isDemoShowcaseMode, isTrue);
      expect(provider.requests.length, 14);
      expect(provider.savedWorksites.length, 3);
      expect(provider.isApprovedProvider, isTrue);

      await provider.selectAndLoadRequest('demo_wr_03_offers_mine');
      expect(provider.selectedOffers.length, 3);

      await provider.selectAndLoadRequest('demo_wr_06_accepted');
      expect(provider.activeHandoverCode, 'K7M4P9');

      // Assigned provider on demo_wr_10_deliv_pend must NOT receive requester's secret view
      await provider.selectAndLoadRequest('demo_wr_10_deliv_pend');
      expect(provider.activeHandoverCode, isNull);

      await provider.exitDemoShowcase();
      expect(provider.isDemoShowcaseMode, isFalse);
      expect(provider.requests.length, 1);
      expect(provider.requests.first.id, 'live_req_1');
      expect(provider.selectedRequest, isNull);

      // Unauthenticated exit clears demo worksites & profile cleanly
      provider.syncAuthSession(uid: null, fullName: null);
      await provider.activateDemoShowcase();
      expect(provider.savedWorksites.length, 3);
      await provider.exitDemoShowcase();
      expect(provider.savedWorksites, isEmpty);
      expect(provider.providerProfile, isNull);

      provider.dispose();
    });

    testWidgets(
        'HomeScreen renders home_demo_all_cases_btn and toggles showcase mode cleanly across mobile and wide viewports',
        (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final viewport in [
        (const Size(360, 780), const Locale('ar', 'QA'), false),
        (const Size(1280, 800), const Locale('en', 'US'), true),
      ]) {
        tester.view.physicalSize = viewport.$1;
        tester.view.devicePixelRatio = 1.0;

        final providerRepo = ProviderRepositoryImpl(
          allowDevMocks: true,
          seedSampleData: true,
        );
        final worksiteRepo = WorksiteRepositoryImpl(
          providerRepository: providerRepo,
          allowDevMocks: true,
          seedSampleData: true,
        );
        final worksiteProvider = WorksiteProvider(
          worksiteRepository: worksiteRepo,
          providerRepository: providerRepo,
          initialUserId: 'dev_req_fahad',
          initialUserName: 'عبدالرحمن مهنا',
        );
        final authProvider = AuthProvider.forTesting(
          user: const UserModel(
            id: 'dev_req_fahad',
            fullName: 'عبدالرحمن مهنا',
            phone: '55123456',
            gender: UserGender.male,
            isVerified: true,
          ),
        );
        final settings = SettingsProvider()..setLocale(viewport.$2);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsProvider>.value(value: settings),
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<WorksiteProvider>.value(
                value: worksiteProvider,
              ),
              ChangeNotifierProvider(create: (_) => AdminProvider.forTesting()),
            ],
            child: Consumer<SettingsProvider>(
              builder: (_, s, __) => MaterialApp(
                theme: AppTheme.lightTheme,
                locale: s.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const HomeScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final toggleBtn =
            find.byKey(const ValueKey('home_demo_all_cases_btn'));
        expect(toggleBtn, findsOneWidget);
        expect(worksiteProvider.isDemoShowcaseMode, isFalse);

        await tester.ensureVisible(toggleBtn);
        await tester.tap(toggleBtn);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(worksiteProvider.isDemoShowcaseMode, isTrue);
        expect(worksiteProvider.allLoadedRequests.length, 14);

        await tester.ensureVisible(toggleBtn);
        await tester.tap(toggleBtn);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(worksiteProvider.isDemoShowcaseMode, isFalse);
        expect(worksiteProvider.allLoadedRequests.length, 3);

        worksiteProvider.dispose();
        authProvider.dispose();
        settings.dispose();
      }
    });
  });

  group('FirebaseWorksiteRepository Spark-safe fallbacks & Blaze gates', () {
    test(
        'Preserves withDeps behavior when sparkFallbackGateway is omitted (rethrows not-found)',
        () async {
      final store = _InMemorySparkGatewayAndStore();
      final functionsClient = FirebaseFunctionsCallableClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"error":{"status":"NOT_FOUND","message":"Callable missing"}}',
            404,
          ),
        ),
        idTokenProvider: () async => 'tok_1',
      );
      final repo = FirebaseWorksiteRepository.withDeps(
        currentUidProvider: () async => 'req_1',
        functionsClient: functionsClient,
        store: store,
      );

      await expectLater(
        () => repo.createRequest(
          WorkRequest(
            id: 'r1',
            requesterId: 'req_1',
            requesterName: 'Tariq',
            title: 'Switchgear',
            description: '20 switches',
            pickupLocation: 'Industrial Area',
            dropoffWorksite: 'Lusail',
            municipality: 'لوسيل',
            estimatedItemsCostMinor: MoneyMinor.fromMajorQar(200),
            maxItemsCapMinor: MoneyMinor.fromMajorQar(220),
            deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(40),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });

    test(
        'Falls back cleanly for client-allowed ops on 404/unavailable and throws bilingual errors for Blaze-gated ops',
        () async {
      final store = _InMemorySparkGatewayAndStore();
      store.providerProfiles['prov_approved'] = {
        'id': 'prov_approved',
        'userId': 'prov_approved',
        'fullName': 'Khalid Supply',
        'approvalStatus': 'approved',
        'ratingAvg': 4.9,
        'completedTasksCount': 12,
      };
      store.notifications['ntf_1'] = {
        'id': 'ntf_1',
        'userId': 'req_1',
        'isRead': false,
      };

      String activeUid = 'req_1';
      final functionsClient = FirebaseFunctionsCallableClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"error":{"status":"NOT_FOUND","message":"Function not deployed on Spark"}}',
            404,
          ),
        ),
        idTokenProvider: () async => 'tok_$activeUid',
      );
      final repo = FirebaseWorksiteRepository.withDeps(
        currentUidProvider: () async => activeUid,
        functionsClient: functionsClient,
        store: store,
        sparkFallbackGateway: store,
      );

      // 1. createRequest Spark fallback: string locations, nulled prohibited fields, isHandoverVerified == false, appends event
      final created = await repo.createRequest(
        WorkRequest(
          id: 'req_spark_1',
          requesterId: 'req_1',
          requesterName: 'المهندس فهد',
          title: 'كابلات نحاس 6مم',
          description: 'توريد عاجل إلى لوسيل',
          pickupLocation: 'المنطقة الصناعية - شارع 10',
          dropoffWorksite: 'لوسيل - برج B',
          municipality: 'لوسيل',
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(300),
          maxItemsCapMinor: MoneyMinor.fromMajorQar(340),
          deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(50),
          paymentMethod: PaymentMethod.bankTransferManual,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      expect(created.id, 'req_spark_1');
      final rawReq = store.requests['req_spark_1']!;
      expect(rawReq['pickupLocation'], isA<String>());
      expect(rawReq['deliveryLocation'], isA<String>());
      expect(rawReq['paymentReference'], isNull);
      expect(rawReq['assignedProviderName'], isNull);
      expect(rawReq['cancellationReason'], isNull);
      expect(rawReq['disputeReason'], isNull);
      expect(rawReq['isHandoverVerified'], isFalse);
      expect(store.eventsByRequest['req_spark_1']?.length, 1);

      // 2. submitPaymentTransferProof on bank_transfer_manual
      final proofUpdated = await repo.recordPaymentStatus(
        requestId: 'req_spark_1',
        method: PaymentMethod.bankTransferManual,
        settlementStatus: PaymentSettlementStatus.transferProofSubmitted,
        actorId: 'req_1',
        actorRole: 'requester',
        proofUrl: 'https://storage.mashwar.qa/proofs/qnb_1.jpg',
        referenceNumber: 'QNB-9910',
      );
      expect(
        proofUpdated.paymentSettlementStatus,
        PaymentSettlementStatus.transferProofSubmitted,
      );
      expect(proofUpdated.paymentReference, 'QNB-9910');

      // 3. Server-gated verified_settled fails with bilingual permission-denied (not raw 404)
      await expectLater(
        () => repo.recordPaymentStatus(
          requestId: 'req_spark_1',
          method: PaymentMethod.bankTransferManual,
          settlementStatus: PaymentSettlementStatus.verifiedSettled,
          actorId: 'req_1',
          actorRole: 'requester',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'permission-denied')
              .having((e) => e.messageEn, 'messageEn', contains('Blaze')),
        ),
      );

      // 4. submitOffer + withdrawOffer Spark fallback
      activeUid = 'prov_approved';
      final createdOffer = await repo.submitOffer(
        WorkOffer(
          id: 'off_spark_1',
          requestId: 'req_spark_1',
          providerId: 'prov_approved',
          providerName: 'Khalid Supply',
          proposedFeeMinor: MoneyMinor.fromMajorQar(45),
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(290),
          estimatedEtaMinutes: 40,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      expect(createdOffer.id, 'off_spark_1');
      expect(store.offers['off_spark_1']?['status'], 'pending');

      // Permission-denied on offer write maps cleanly
      store.throwPermissionDeniedOnOffer = true;
      await expectLater(
        () => repo.submitOffer(
          WorkOffer(
            id: 'off_spark_denied',
            requestId: 'req_spark_1',
            providerId: 'prov_approved',
            providerName: 'Khalid Supply',
            proposedFeeMinor: MoneyMinor.fromMajorQar(45),
            estimatedItemsCostMinor: MoneyMinor.fromMajorQar(290),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'permission-denied')
              .having((e) => e.messageEn, 'messageEn', contains('offerCount')),
        ),
      );
      store.throwPermissionDeniedOnOffer = false;

      await repo.withdrawOffer(
        requestId: 'req_spark_1',
        offerId: 'off_spark_1',
        providerId: 'prov_approved',
      );
      expect(store.offers['off_spark_1']?['status'], 'withdrawn');

      // 5. Server-gated acceptOffer & verifyHandoverCode fail cleanly with bilingual failed-precondition (not raw 404)
      activeUid = 'req_1';
      await expectLater(
        () => repo.acceptOffer(
          requestId: 'req_spark_1',
          offerId: 'off_spark_1',
          requesterId: 'req_1',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'failed-precondition')
              .having((e) => e.messageEn, 'messageEn', contains('Blaze')),
        ),
      );

      // 6. Requester cancel on open/offer_received
      final cancelled = await repo.updateFulfillmentStatus(
        requestId: 'req_spark_1',
        nextStatus: WorkRequestStatus.cancelled,
        actorId: 'req_1',
        actorRole: 'requester',
        note: 'Cancelled by site engineer',
      );
      expect(cancelled.status, WorkRequestStatus.cancelled);
      expect(cancelled.cancellationReason, 'Cancelled by site engineer');

      // 7. Assigned provider linear stage progression + invoiceImageUrls + flagDisputed + rating
      store.requests['req_active_1'] = {
        'id': 'req_active_1',
        'requesterId': 'req_1',
        'requesterName': 'المهندس فهد',
        'category': 'worksite_supply',
        'title': 'صمامات نحاسية',
        'description': 'توريد',
        'pickupLocation': 'طريق سلوى',
        'deliveryLocation': 'الوكرة',
        'deliveryArea': 'الوكرة',
        'budgetMinor': 40000,
        'paymentMethod': 'cash_on_delivery',
        'paymentStatus': 'unpaid',
        'status': 'accepted',
        'offerCount': 1,
        'selectedOfferId': 'off_1',
        'assignedProviderId': 'prov_approved',
        'createdAt': '2026-11-25T08:00:00.000Z',
        'updatedAt': '2026-11-25T08:00:00.000Z',
      };

      activeUid = 'prov_approved';
      await repo.updateFulfillmentStatus(
        requestId: 'req_active_1',
        nextStatus: WorkRequestStatus.inProgress,
        actorId: 'prov_approved',
        actorRole: 'provider',
      );
      await repo.updateFulfillmentStatus(
        requestId: 'req_active_1',
        nextStatus: WorkRequestStatus.pickedUp,
        actorId: 'prov_approved',
        actorRole: 'provider',
        receiptImageUrl: 'https://storage.mashwar.qa/invoices/inv_1.jpg',
      );
      await repo.updateFulfillmentStatus(
        requestId: 'req_active_1',
        nextStatus: WorkRequestStatus.inTransit,
        actorId: 'prov_approved',
        actorRole: 'provider',
      );
      final delivered = await repo.updateFulfillmentStatus(
        requestId: 'req_active_1',
        nextStatus: WorkRequestStatus.deliveredPendingConfirmation,
        actorId: 'prov_approved',
        actorRole: 'provider',
      );
      expect(delivered.status, WorkRequestStatus.deliveredPendingConfirmation);
      expect(
        store.requests['req_active_1']?['invoiceImageUrls'],
        contains('https://storage.mashwar.qa/invoices/inv_1.jpg'),
      );

      // Verify handover requires Blaze functions (never raw 404)
      await expectLater(
        () => repo.verifyHandoverCode(
          requestId: 'req_active_1',
          providerId: 'prov_approved',
          code: 'T5K9B3',
        ),
        throwsA(
          isA<WorksiteRepositoryException>()
              .having((e) => e.code, 'code', 'failed-precondition')
              .having((e) => e.messageEn, 'messageEn', contains('Blaze')),
        ),
      );

      // flagDisputed works in Spark mode
      final disputed = await repo.reportDispute(
        requestId: 'req_active_1',
        reporterId: 'prov_approved',
        reporterRole: 'provider',
        reason: 'Gate closed at worksite',
      );
      expect(disputed.status, WorkRequestStatus.disputed);
      expect(disputed.disputeReason, 'Gate closed at worksite');

      // 8. submitRating on completed request + markNotificationRead
      store.requests['req_done_1'] = {
        ...store.requests['req_active_1']!,
        'id': 'req_done_1',
        'status': 'completed',
      };
      activeUid = 'req_1';
      final savedRating = await repo.submitRating(
        RequestRating(
          id: '',
          requestId: 'req_done_1',
          raterUserId: 'req_1',
          raterRole: 'requester',
          targetUserId: 'prov_approved',
          score: 5,
          comment: 'Fast and accurate invoice',
          createdAt: DateTime.now().toUtc(),
        ),
      );
      expect(savedRating.id, 'req_done_1_req_1');
      expect(store.ratings['req_done_1_req_1']?['stars'], 5);

      await repo.markNotificationRead('ntf_1', userId: 'req_1');
      expect(store.notifications['ntf_1']?['isRead'], isTrue);
    });
  });

  group('AdminProvider Demo Queues & Backend Auto-Sync', () {
    test(
        'Dev queues cover all 4 ProviderApprovalStatus and all 11 WorkRequestStatus values while preserving base fixtures',
        () {
      final admin = AdminProvider.forTesting();

      final provIds = admin.worksiteProviders.map((p) => p.profile.userId).toSet();
      expect(provIds, containsAll(['prov_101', 'prov_102', 'prov_103', 'prov_104']));
      final provStatuses =
          admin.worksiteProviders.map((p) => p.profile.approvalStatus).toSet();
      expect(provStatuses, containsAll(ProviderApprovalStatus.values));

      final reqIds = admin.worksiteRequests.map((r) => r.id).toSet();
      expect(reqIds, containsAll(['req_ws_901', 'req_ws_902', 'req_ws_903', 'req_ws_904']));
      final reqStatuses = admin.worksiteRequests.map((r) => r.status).toSet();
      expect(reqStatuses, containsAll(WorkRequestStatus.values));
      admin.dispose();
    });

    test(
        'signInStaffWithFirebase and restoreStaffSession auto-sync backend ops and never crash sign-in if sync fails',
        () async {
      final catalogBundle = MashwarDemoCasesCatalog.build();
      final healthyGateway = _FakeAdminBackendGateway()
        ..providerProfiles.addAll(
          catalogBundle.providerProfiles.map((p) => p.toJson()),
        )
        ..workRequests.addAll(
          catalogBundle.requests.map((r) => r.toJson()),
        );

      final adminHealthy = AdminProvider(
        useDevMockAuth: false,
        backendGateway: healthyGateway,
      );
      final signedIn = await adminHealthy.signInStaffWithFirebase(
        'abdelrahmanmahana01@gmail.com',
        'SecretPass123!',
      );
      expect(signedIn, isTrue);
      expect(adminHealthy.isLoggedIn, isTrue);
      expect(adminHealthy.activeRole, AdminRole.superAdmin);
      expect(healthyGateway.syncCallsCount, 1);
      expect(adminHealthy.worksiteProviders.length, 8);
      expect(adminHealthy.worksiteRequests.length, 14);

      final restored = await adminHealthy.restoreStaffSession();
      expect(restored, isTrue);
      expect(healthyGateway.syncCallsCount, 2);
      adminHealthy.dispose();

      // Failing backend sync must NEVER crash signInStaffWithFirebase or restoreStaffSession
      final failingGateway = _FakeAdminBackendGateway(failSyncOps: true);
      final adminFailingSync = AdminProvider(
        useDevMockAuth: false,
        backendGateway: failingGateway,
      );
      final signedInDespiteSyncErr =
          await adminFailingSync.signInStaffWithFirebase(
        'abdelrahmanmahana01@gmail.com',
        'SecretPass123!',
      );
      expect(signedInDespiteSyncErr, isTrue);
      expect(adminFailingSync.isLoggedIn, isTrue);
      expect(adminFailingSync.worksiteSyncStatus, contains('تعذر المزامنة'));

      final restoredDespiteSyncErr =
          await adminFailingSync.restoreStaffSession();
      expect(restoredDespiteSyncErr, isTrue);
      adminFailingSync.dispose();
    });
  });
}
