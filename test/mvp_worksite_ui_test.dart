import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/data/models/worksite_models.dart';
import 'package:mashwar/data/repositories/contracts/i_worksite_repository.dart';
import 'package:mashwar/data/repositories/implementations/auth_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/provider_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/worksite_repository_impl.dart';
import 'package:mashwar/screens/auth/email_input_screen.dart';
import 'package:mashwar/screens/auth/welcome_screen.dart';
import 'package:mashwar/screens/chat/chat_screen.dart';
import 'package:mashwar/screens/home/home_screen.dart';
import 'package:mashwar/screens/main_nav_shell.dart';
import 'package:mashwar/screens/worksite/create_work_request_screen.dart';
import 'package:mashwar/screens/worksite/provider_profile_screen.dart';
import 'package:mashwar/screens/worksite/work_request_details_screen.dart';
import 'package:mashwar/screens/worksite/work_requests_feed_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

class _ControllableFeedRepo implements IWorksiteRepository {
  final WorksiteRepositoryImpl delegate;
  Completer<List<WorkRequest>>? pendingLoadCompleter;
  bool failListRequests = false;

  _ControllableFeedRepo(this.delegate);

  @override
  Future<List<WorkRequest>> listRequests({
    WorkRequestStatus? status,
    String? municipality,
    String? requesterId,
    String? assignedProviderId,
    int limit = 50,
  }) async {
    if (pendingLoadCompleter != null) {
      return pendingLoadCompleter!.future;
    }
    if (failListRequests) {
      throw const WorksiteRepositoryException(
        code: 'unavailable',
        messageAr: 'انقطع الاتصال بالخادم، يرجى إعادة المحاولة.',
        messageEn: 'Server connection lost, please retry.',
      );
    }
    return delegate.listRequests(
      status: status,
      municipality: municipality,
      requesterId: requesterId,
      assignedProviderId: assignedProviderId,
      limit: limit,
    );
  }

  @override
  Future<WorkRequest> acceptOffer({
    required String requestId,
    required String offerId,
    required String requesterId,
  }) =>
      delegate.acceptOffer(
        requestId: requestId,
        offerId: offerId,
        requesterId: requesterId,
      );

  @override
  Future<WorkRequest> createRequest(WorkRequest request) =>
      delegate.createRequest(request);

  @override
  Future<String> getRequesterHandoverCode({
    required String requestId,
    required String requesterId,
  }) =>
      delegate.getRequesterHandoverCode(
        requestId: requestId,
        requesterId: requesterId,
      );

  @override
  Future<WorkRequest?> getRequestById(String requestId) =>
      delegate.getRequestById(requestId);

  @override
  Future<List<WorkOffer>> listOffersForRequest(String requestId) =>
      delegate.listOffersForRequest(requestId);

  @override
  Future<List<RequestEvent>> listRequestEvents(String requestId) =>
      delegate.listRequestEvents(requestId);

  @override
  Future<WorkRequest> recordPaymentStatus({
    required String requestId,
    required PaymentMethod method,
    required PaymentSettlementStatus settlementStatus,
    required String actorId,
    required String actorRole,
    String? proofUrl,
    String? referenceNumber,
  }) =>
      delegate.recordPaymentStatus(
        requestId: requestId,
        method: method,
        settlementStatus: settlementStatus,
        actorId: actorId,
        actorRole: actorRole,
        proofUrl: proofUrl,
        referenceNumber: referenceNumber,
      );

  @override
  Future<WorkRequest> reportDispute({
    required String requestId,
    required String reporterId,
    required String reporterRole,
    required String reason,
  }) =>
      delegate.reportDispute(
        requestId: requestId,
        reporterId: reporterId,
        reporterRole: reporterRole,
        reason: reason,
      );

  @override
  Future<WorkOffer> submitOffer(WorkOffer offer) => delegate.submitOffer(offer);

  @override
  Future<void> withdrawOffer({
    required String requestId,
    required String offerId,
    required String providerId,
  }) =>
      delegate.withdrawOffer(
        requestId: requestId,
        offerId: offerId,
        providerId: providerId,
      );

  @override
  Future<WorkRequest> cancelRequest({
    required String requestId,
    required String requesterId,
    String? reason,
  }) =>
      delegate.cancelRequest(
        requestId: requestId,
        requesterId: requesterId,
        reason: reason,
      );

  @override
  Future<RequestRating> submitRating(RequestRating rating) =>
      delegate.submitRating(rating);

  @override
  Future<WorkRequest> updateFulfillmentStatus({
    required String requestId,
    required WorkRequestStatus nextStatus,
    required String actorId,
    required String actorRole,
    String? note,
    String? receiptImageUrl,
    MoneyMinor? actualReceiptTotalMinor,
  }) =>
      delegate.updateFulfillmentStatus(
        requestId: requestId,
        nextStatus: nextStatus,
        actorId: actorId,
        actorRole: actorRole,
        note: note,
        receiptImageUrl: receiptImageUrl,
        actualReceiptTotalMinor: actualReceiptTotalMinor,
      );

  @override
  Future<HandoverVerificationResult> verifyHandoverCode({
    required String requestId,
    required String providerId,
    required String code,
  }) =>
      delegate.verifyHandoverCode(
        requestId: requestId,
        providerId: providerId,
        code: code,
      );
}

void main() {
  Widget buildMvpHarness({
    required Widget home,
    required WorksiteProvider worksite,
    AuthProvider? auth,
    SettingsProvider? settings,
  }) {
    final effectiveSettings = settings ?? SettingsProvider();
    final effectiveAuth = auth ??
        AuthProvider.forTesting(
          user: const UserModel(
            id: 'dev_req_fahad',
            fullName: 'فهد المري',
            phone: '55112233',
            email: 'fahad@mashwar.qa',
            gender: UserGender.male,
          ),
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
            value: effectiveSettings),
        ChangeNotifierProvider<AuthProvider>.value(value: effectiveAuth),
        ChangeNotifierProvider<WorksiteProvider>.value(value: worksite),
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
          home: home,
        ),
      ),
    );
  }

  (ProviderRepositoryImpl, WorksiteRepositoryImpl) createSeededRepos({
    bool seed = true,
  }) {
    final provRepo = ProviderRepositoryImpl(
      allowDevMocks: true,
      seedSampleData: seed,
    );
    final wsRepo = WorksiteRepositoryImpl(
      providerRepository: provRepo,
      allowDevMocks: true,
      seedSampleData: seed,
    );
    return (provRepo, wsRepo);
  }

  group('Qatar Worksite Supply MVP Customer UI & Responsive Journey Tests', () {
    testWidgets(
      '5-tab MainNavShell & HomeScreen render AR RTL & EN LTR cleanly across 360x780 and 1280x800 with zero fake balances or overflow',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, wsRepo) = createSeededRepos();
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: 'dev_req_fahad',
          initialUserName: 'فهد المري',
        );
        await worksite.loadRequests();
        await worksite.loadSavedWorksites('dev_req_fahad');

        final settings = SettingsProvider()..setLocale(const Locale('ar', 'QA'));

        for (final size in [const Size(360, 780), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          // Arabic RTL check
          settings.setLocale(const Locale('ar', 'QA'));
          await tester.pumpWidget(
            buildMvpHarness(
              home: const MainNavShell(),
              worksite: worksite,
              settings: settings,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            Directionality.of(tester.element(find.byType(HomeScreen))),
            TextDirection.rtl,
          );

          // Exact 5 international tabs
          if (size.width >= 840) {
            final rail =
                tester.widget<NavigationRail>(find.byType(NavigationRail));
            expect(rail.destinations.length, 5);
          } else {
            final bar = tester
                .widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
            expect(bar.items.length, 5);
          }

          expect(find.text('إلى أين مشوارك أو طلبك اليوم؟'), findsOneWidget);
          expect(find.text('450 ر.ق'), findsNothing);
          expect(find.text('450 QAR'), findsNothing);
          expect(find.textContaining('18 منفّذ'), findsNothing);

          // Navigate across all 5 tabs cleanly in Arabic
          for (final label in [
            'الرحلات والطرود',
            'التوريد والمهام',
            'نشاطي',
            'حسابي',
            'الرئيسية',
          ]) {
            await tester.tap(find.text(label).first);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          // Switch to English LTR
          settings.setLocale(const Locale('en', 'US'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            Directionality.of(tester.element(find.byType(HomeScreen))),
            TextDirection.ltr,
          );
          expect(
            find.text('Where does your journey take you today?'),
            findsOneWidget,
          );

          for (final label in [
            'Trips & Parcels',
            'Supply & Tasks',
            'My Activity',
            'Account',
            'Home',
          ]) {
            await tester.tap(find.text(label).first);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }

        worksite.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      '3-step CreateWorkRequestScreen validates fields, picks saved worksite, converts QAR to MoneyMinor, and publishes cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, wsRepo) = createSeededRepos();
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: 'dev_req_fahad',
          initialUserName: 'م. فهد المري',
        );
        await worksite.loadSavedWorksites('dev_req_fahad');
        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));

        await tester.pumpWidget(
          buildMvpHarness(
            home: const CreateWorkRequestScreen(),
            worksite: worksite,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        // Step 1 validation blocks empty submission
        await tester.tap(find.byKey(const ValueKey('create_next_btn')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('create_request_error_banner')),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const ValueKey('create_step1_title')),
          'Heavy Duty Bosch Drill Bits & Anchors',
        );
        await tester.enterText(
          find.byKey(const ValueKey('create_step1_desc')),
          '4 boxes M10 concrete wedge anchors + SDS-Plus bit set',
        );
        await tester.enterText(
          find.byKey(const ValueKey('create_step1_qty')),
          '4',
        );
        await tester.tap(find.byKey(const ValueKey('create_next_btn')));
        await tester.pumpAndSettle();

        // Step 2 validation blocks empty pickup
        await tester.tap(find.byKey(const ValueKey('create_next_btn')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('create_request_error_banner')),
          findsOneWidget,
        );

        // Select saved worksite chip to auto-fill dropoff & area
        final savedChip =
            find.byKey(const ValueKey('saved_site_chip_dev_site_lusail_42'));
        expect(savedChip, findsOneWidget);
        await tester.tap(savedChip);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('create_step2_pickup')),
          'Industrial Area - St 10 Hardware Depot',
        );
        await tester.tap(find.byKey(const ValueKey('create_next_btn')));
        await tester.pumpAndSettle();

        // Step 3 validation blocks invalid/empty QAR budget
        await tester.tap(find.byKey(const ValueKey('create_publish_btn')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('create_request_error_banner')),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const ValueKey('create_step3_items_qar')),
          '240.50',
        );
        await tester.enterText(
          find.byKey(const ValueKey('create_step3_cap_qar')),
          '280',
        );
        await tester.enterText(
          find.byKey(const ValueKey('create_step3_fee_qar')),
          '55',
        );
        await tester.pumpAndSettle();

        // Select Manual Bank Transfer pilot option
        final bankOption =
            find.byKey(const ValueKey('payment_method_bank_transfer_manual'));
        await tester.ensureVisible(bankOption);
        await tester.tap(bankOption);
        await tester.pumpAndSettle();

        // Publish -> creates MoneyMinor(24050) + MoneyMinor(5500) and opens Details
        await tester.tap(find.byKey(const ValueKey('create_publish_btn')));
        await tester.pumpAndSettle();

        expect(find.byType(WorkRequestDetailsScreen), findsOneWidget);
        expect(worksite.selectedRequest, isNotNull);
        expect(
          worksite.selectedRequest!.estimatedItemsCostMinor.minorUnits,
          24050,
        );
        expect(
          worksite.selectedRequest!.deliveryFeeBudgetMinor.minorUnits,
          5500,
        );
        expect(
          worksite.selectedRequest!.paymentMethod,
          PaymentMethod.bankTransferManual,
        );
        expect(tester.takeException(), isNull);

        worksite.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'WorkRequestsFeedScreen handles loading skeleton, error + retry, empty state, and Qatar area / budget filters',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, baseWsRepo) = createSeededRepos();
        final controllableRepo = _ControllableFeedRepo(baseWsRepo);
        final worksite = WorksiteProvider(
          worksiteRepository: controllableRepo,
          providerRepository: provRepo,
          initialUserId: 'dev_req_fahad',
        );
        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));

        // 1. Loading skeleton state
        final loadCompleter = Completer<List<WorkRequest>>();
        controllableRepo.pendingLoadCompleter = loadCompleter;
        unawaited(worksite.loadRequests());
        await tester.pumpWidget(
          buildMvpHarness(
            home: const WorkRequestsFeedScreen(),
            worksite: worksite,
            settings: settings,
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('feed_loading_skeleton')),
          findsOneWidget,
        );

        // Finish initial load as empty list -> Empty State
        loadCompleter.complete(const []);
        controllableRepo.pendingLoadCompleter = null;
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('feed_empty_state')), findsOneWidget);

        // 2. Error state + Retry recovery
        controllableRepo.failListRequests = true;
        await worksite.loadRequests();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('feed_error_state')), findsOneWidget);

        controllableRepo.failListRequests = false;
        await tester.tap(find.byKey(const ValueKey('feed_retry_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('feed_error_state')), findsNothing);
        expect(worksite.requests.length, 3);

        // 3. Filter by Qatar area (Lusail) and Max Budget
        final lusailChip = find.byKey(const ValueKey('feed_area_chip_لوسيل'));
        await tester.ensureVisible(lusailChip);
        await tester.pumpAndSettle();
        await tester.tap(lusailChip);
        await tester.pumpAndSettle();
        expect(worksite.requests.length, 1);
        expect(worksite.requests.first.municipality, 'لوسيل');

        // Clear filters restores full list
        final clearBtn = find.byKey(const ValueKey('feed_clear_filters_btn'));
        await tester.ensureVisible(clearBtn);
        await tester.pumpAndSettle();
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();
        expect(worksite.requests.length, 3);

        worksite.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'End-to-end Offer Gate, Offer Submission/Acceptance, Fulfillment + Invoice, 6-Char Handover Modal, Chat, Rating & Quick Reorder',
      (tester) async {
        tester.view.physicalSize = const Size(412, 892);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, wsRepo) = createSeededRepos();
        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));

        // A. Pending/Unapproved provider CANNOT submit offer (strictly gated)
        final pendingProviderState = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: ProviderRepositoryImpl.pilotPendingProviderId,
          initialUserName: 'سالم الدوسري',
        );
        await pendingProviderState
            .loadProviderProfile(ProviderRepositoryImpl.pilotPendingProviderId);

        await tester.pumpWidget(
          buildMvpHarness(
            home: const WorkRequestDetailsScreen(
              requestId: 'dev_req_lusail_breakers',
            ),
            worksite: pendingProviderState,
            auth: AuthProvider.forTesting(
              user: const UserModel(
                id: ProviderRepositoryImpl.pilotPendingProviderId,
                fullName: 'سالم الدوسري',
                phone: '77112233',
                gender: UserGender.male,
              ),
            ),
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        expect(pendingProviderState.isApprovedProvider, isFalse);
        expect(
          find.byKey(const ValueKey('details_submit_offer_btn')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('details_verify_provider_btn')),
          findsOneWidget,
        );
        pendingProviderState.dispose();

        // B. Approved provider submits an offer on 'dev_req_lusail_breakers'
        final approvedProviderState = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: ProviderRepositoryImpl.pilotApprovedProviderId,
          initialUserName: 'خالد المناعي للتوريدات',
        );
        await approvedProviderState.loadProviderProfile(
          ProviderRepositoryImpl.pilotApprovedProviderId,
        );

        await tester.pumpWidget(
          buildMvpHarness(
            home: const WorkRequestDetailsScreen(
              requestId: 'dev_req_lusail_breakers',
            ),
            worksite: approvedProviderState,
            auth: AuthProvider.forTesting(
              user: const UserModel(
                id: ProviderRepositoryImpl.pilotApprovedProviderId,
                fullName: 'خالد المناعي للتوريدات',
                phone: '55234567',
                gender: UserGender.male,
              ),
            ),
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        expect(approvedProviderState.isApprovedProvider, isTrue);
        final submitOfferBtn =
            find.byKey(const ValueKey('details_submit_offer_btn'));
        await tester.ensureVisible(submitOfferBtn);
        await tester.tap(submitOfferBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('offer_fee_qar_input')),
          '40',
        );
        await tester.enterText(
          find.byKey(const ValueKey('offer_eta_input')),
          '35',
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm_submit_offer_btn')),
        );
        await tester.pumpAndSettle();

        expect(approvedProviderState.selectedOffers.length, 1);
        final createdOfferId = approvedProviderState.selectedOffers.first.id;

        // C. Requester ('dev_req_fahad') views offer, accepts it, and gets secret 6-char handover code
        final requesterState = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: 'dev_req_fahad',
          initialUserName: 'م. فهد المري',
        );

        await tester.pumpWidget(
          buildMvpHarness(
            home: const WorkRequestDetailsScreen(
              requestId: 'dev_req_lusail_breakers',
            ),
            worksite: requesterState,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        final acceptBtn =
            find.byKey(ValueKey('accept_offer_btn_$createdOfferId'));
        await tester.ensureVisible(acceptBtn);
        await tester.tap(acceptBtn);
        await tester.pumpAndSettle();

        expect(requesterState.selectedRequest!.status, WorkRequestStatus.accepted);
        expect(requesterState.activeHandoverCode, isNotNull);
        final realHandoverCode = requesterState.activeHandoverCode!;
        expect(realHandoverCode.length, 6);
        expect(
          find.byKey(const ValueKey('requester_handover_code_card')),
          findsOneWidget,
        );

        // Contextual ChatScreen opens cleanly from details
        final chatBtn = find.byKey(const ValueKey('details_open_chat_btn'));
        await tester.ensureVisible(chatBtn);
        await tester.tap(chatBtn);
        await tester.pumpAndSettle();
        expect(find.byType(ChatScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        // D. Assigned approved provider advances stages + attaches invoice + verifies 6-char handover code
        await approvedProviderState
            .selectAndLoadRequest('dev_req_lusail_breakers');
        await tester.pumpWidget(
          buildMvpHarness(
            home: const WorkRequestDetailsScreen(
              requestId: 'dev_req_lusail_breakers',
            ),
            worksite: approvedProviderState,
            auth: AuthProvider.forTesting(
              user: const UserModel(
                id: ProviderRepositoryImpl.pilotApprovedProviderId,
                fullName: 'خالد المناعي للتوريدات',
                phone: '55234567',
                gender: UserGender.male,
              ),
            ),
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        // Stage: accepted -> in_progress
        await tester.tap(
          find.byKey(const ValueKey('advance_stage_in_progress')),
        );
        await tester.pumpAndSettle();
        expect(
          approvedProviderState.selectedRequest!.status,
          WorkRequestStatus.inProgress,
        );

        // Stage: in_progress -> picked_up (with invoice attachment)
        await tester.tap(find.byKey(const ValueKey('advance_stage_picked_up')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('stage_invoice_url_input')),
          'https://storage.mashwar.qa/invoices/lusail_breakers.jpg',
        );
        await tester.enterText(
          find.byKey(const ValueKey('stage_actual_total_input')),
          '175',
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm_stage_update_btn')),
        );
        await tester.pumpAndSettle();
        expect(
          approvedProviderState.selectedRequest!.status,
          WorkRequestStatus.pickedUp,
        );

        // Stage: picked_up -> in_transit -> delivered_pending_confirmation
        await tester.tap(find.byKey(const ValueKey('advance_stage_in_transit')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('confirm_stage_update_btn')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            const ValueKey('advance_stage_delivered_pending_confirmation'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('confirm_stage_update_btn')),
        );
        await tester.pumpAndSettle();
        expect(
          approvedProviderState.selectedRequest!.status,
          WorkRequestStatus.deliveredPendingConfirmation,
        );

        // Open 6-char Handover Verification Modal: test invalid code first, then valid code
        final verifyBtn =
            find.byKey(const ValueKey('details_verify_handover_btn'));
        await tester.ensureVisible(verifyBtn);
        await tester.tap(verifyBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('handover_code_input')),
          'ZZZZZZ',
        );
        await tester.tap(find.byKey(const ValueKey('handover_confirm_btn')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('handover_modal_error')),
          findsOneWidget,
        );
        expect(find.textContaining('4'), findsWidgets); // 4 attempts remaining

        await tester.enterText(
          find.byKey(const ValueKey('handover_code_input')),
          realHandoverCode,
        );
        await tester.tap(find.byKey(const ValueKey('handover_confirm_btn')));
        await tester.pumpAndSettle();

        expect(
          approvedProviderState.selectedRequest!.status,
          WorkRequestStatus.completed,
        );
        expect(
          approvedProviderState.selectedRequest!.isHandoverVerified,
          isTrue,
        );

        // E. Requester Quick Reorder prefill & Post-Completion Rating
        await requesterState.selectAndLoadRequest('dev_req_lusail_breakers');
        await tester.pumpWidget(
          buildMvpHarness(
            home: const WorkRequestDetailsScreen(
              requestId: 'dev_req_lusail_breakers',
            ),
            worksite: requesterState,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        // Submit post-completion rating
        final rateBtn = find.byKey(const ValueKey('details_rate_btn'));
        await tester.ensureVisible(rateBtn);
        await tester.tap(rateBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm_rating_btn')));
        await tester.pumpAndSettle();

        // 1-Tap Quick Reorder opens prefilled CreateWorkRequestScreen
        final reorderBtn =
            find.byKey(const ValueKey('details_quick_reorder_btn'));
        await tester.ensureVisible(reorderBtn);
        await tester.tap(reorderBtn);
        await tester.pumpAndSettle();

        expect(find.byType(CreateWorkRequestScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('reorder_prefill_banner')),
          findsOneWidget,
        );

        approvedProviderState.dispose();
        requesterState.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'ProviderProfileScreen validates 11-digit QID, submits verification, and saves worksites; EmailInputScreen performs real registration',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, wsRepo) = createSeededRepos();
        final authRepo = AuthRepositoryImpl(allowDevMocks: true);
        final auth = AuthProvider(
          authRepository: authRepo,
          useDevMockAuth: true,
        );
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          currentUidProvider: () => auth.user.id,
        );
        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));

        // 1. Register real account via EmailInputScreen
        await tester.pumpWidget(
          buildMvpHarness(
            home: const WelcomeScreen(),
            worksite: worksite,
            auth: auth,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('welcome_email_register_btn')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(EmailInputScreen), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('auth_fullname_input')),
          'Nasser Al-Thani',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_email_input')),
          'nasser@site.qa',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_password_input')),
          'securePass99',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_confirm_password_input')),
          'securePass99',
        );
        final registerSubmitBtn = find.byKey(const ValueKey('auth_submit_btn'));
        await tester.ensureVisible(registerSubmitBtn);
        await tester.pumpAndSettle();
        await tester.tap(registerSubmitBtn);
        await tester.pumpAndSettle();

        expect(auth.isAuthenticated, isTrue);
        expect(find.byType(MainNavShell), findsOneWidget);

        // 2. Navigate via Account tab -> ProviderProfileScreen for QID validation, submission & saved worksites
        await tester.tap(find.text('Account').first);
        await tester.pumpAndSettle();

        final providerTile =
            find.text('Provider Profile & QID Verification');
        await tester.ensureVisible(providerTile);
        await tester.tap(providerTile);
        await tester.pumpAndSettle();
        expect(find.byType(ProviderProfileScreen), findsOneWidget);

        final qidInput = find.byKey(const ValueKey('provider_qid_input'));
        final submitQidBtn =
            find.byKey(const ValueKey('submit_qid_verification_btn'));

        // Rejects short QID (< 11 digits)
        await tester.ensureVisible(qidInput);
        await tester.pumpAndSettle();
        await tester.enterText(qidInput, '12345');
        await tester.ensureVisible(submitQidBtn);
        await tester.pumpAndSettle();
        await tester.tap(submitQidBtn);
        await tester.pumpAndSettle();
        expect(find.textContaining('11'), findsWidgets);

        // Accepts valid 11-digit QID and sets status to Pending Review
        await tester.ensureVisible(qidInput);
        await tester.enterText(qidInput, '29463401188');
        await tester.ensureVisible(submitQidBtn);
        await tester.tap(submitQidBtn);
        await tester.pumpAndSettle();
        expect(
          worksite.providerProfile?.approvalStatus,
          ProviderApprovalStatus.pending,
        );

        // Save a new worksite from ProviderProfileScreen
        final addSiteBtn = find.byKey(const ValueKey('add_saved_worksite_btn'));
        await tester.ensureVisible(addSiteBtn);
        await tester.pumpAndSettle();
        await tester.tap(addSiteBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('worksite_label_input')),
          'Al Rayyan Villas Project',
        );
        await tester.enterText(
          find.byKey(const ValueKey('worksite_street_input')),
          'Zone 53, St 410',
        );
        await tester.enterText(
          find.byKey(const ValueKey('worksite_contact_name_input')),
          'Nasser Al-Thani',
        );
        await tester.enterText(
          find.byKey(const ValueKey('worksite_contact_phone_input')),
          '55998877',
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm_save_worksite_btn')),
        );
        await tester.pumpAndSettle();
        expect(worksite.savedWorksites.length, 1);

        auth.dispose();
        worksite.dispose();
        settings.dispose();
      },
    );
  });
}
