import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/core/widgets/mashwar_animations.dart';
import 'package:mashwar/core/widgets/mashwar_worksite_icons.dart';
import 'package:mashwar/data/demo/demo_cases_catalog.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/data/models/worksite_models.dart';
import 'package:mashwar/data/repositories/implementations/provider_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/worksite_repository_impl.dart';
import 'package:mashwar/screens/account/account_extra_screens.dart';
import 'package:mashwar/screens/worksite/create_work_request_screen.dart';
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

void main() {
  (ProviderRepositoryImpl, WorksiteRepositoryImpl) createSeededRepos() {
    final provRepo = ProviderRepositoryImpl(
      allowDevMocks: true,
      seedSampleData: true,
    );
    final wsRepo = WorksiteRepositoryImpl(
      providerRepository: provRepo,
      allowDevMocks: true,
      seedSampleData: true,
    );
    return (provRepo, wsRepo);
  }

  Widget buildHarness({
    required Widget home,
    required WorksiteProvider worksite,
    AuthProvider? auth,
    SettingsProvider? settings,
  }) {
    final effectiveSettings = settings ??
        (SettingsProvider()..setLocale(const Locale('en', 'US')));
    final effectiveAuth = auth ??
        AuthProvider.forTesting(
          user: const UserModel(
            id: MashwarDemoCasesCatalog.defaultOwnerUid,
            fullName: MashwarDemoCasesCatalog.defaultOwnerName,
            phone: '55123456',
            email: MashwarDemoCasesCatalog.defaultOwnerEmail,
            gender: UserGender.male,
            idVerificationStatus: IdVerificationStatus.verified,
            isVerified: true,
            governorate: 'الدوحة',
            city: 'لوسيل',
          ),
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
          value: effectiveSettings,
        ),
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

  group('Wave 8 UI/UX Upgrade & Missing MVP Features Tests', () {
    testWidgets(
      'Custom vector icons, visual banners, trust emblems, deterministic shimmer, hover card, and status stepper settle under pumpAndSettle across 375x812 and 1280x900',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        for (final size in const [Size(375, 812), Size(1280, 900)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          for (final isAr in [true, false]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.lightTheme,
                locale: isAr
                    ? const Locale('ar', 'QA')
                    : const Locale('en', 'US'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: mashwarWorksiteCategories
                              .map(
                                (meta) => MashwarCategoryIcon(
                                  category: meta.id,
                                  size: 38,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        ...mashwarWorksiteCategories.map(
                          (meta) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MashwarCategoryVisualBanner(
                              category: meta.id,
                              height: 76,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: MashwarTrustType.values
                              .map(
                                (type) => MashwarTrustEmblem(
                                  type: type,
                                  size: 40,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        const MashwarShimmerBox(width: 180, height: 18),
                        const SizedBox(height: 8),
                        const MashwarShimmerBox(height: 44),
                        const SizedBox(height: 12),
                        MashwarHoverCard(
                          onTap: () {},
                          padding: const EdgeInsets.all(12),
                          child: Text(isAr ? 'بطاقة تفاعلية' : 'Hover Card'),
                        ),
                        const SizedBox(height: 12),
                        MashwarWorksiteStatusStepper(
                          status: WorkRequestStatus.open,
                          isAr: isAr,
                          compact: true,
                        ),
                        const SizedBox(height: 8),
                        MashwarWorksiteStatusStepper(
                          status: WorkRequestStatus.inTransit,
                          isAr: isAr,
                        ),
                        const SizedBox(height: 8),
                        MashwarWorksiteStatusStepper(
                          status: WorkRequestStatus.completed,
                          isAr: isAr,
                        ),
                        const SizedBox(height: 8),
                        MashwarWorksiteStatusStepper(
                          status: WorkRequestStatus.cancelled,
                          isAr: isAr,
                        ),
                        const SizedBox(height: 8),
                        MashwarWorksiteStatusStepper(
                          status: WorkRequestStatus.disputed,
                          isAr: isAr,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            expect(
              find.byType(MashwarCategoryIcon),
              findsNWidgets(mashwarWorksiteCategories.length * 2),
            );
            expect(
              find.byType(MashwarCategoryVisualBanner),
              findsNWidgets(mashwarWorksiteCategories.length),
            );
            expect(
              find.byType(MashwarTrustEmblem),
              findsNWidgets(MashwarTrustType.values.length),
            );
            expect(find.byType(MashwarShimmerBox), findsNWidgets(2));
            expect(find.byType(MashwarWorksiteStatusStepper), findsNWidgets(5));
          }
        }
      },
    );

    testWidgets(
      'WorkRequestsFeedScreen supports instant search, category chips, perspective pills, sort options, and clear filters',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, wsRepo) = createSeededRepos();
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: MashwarDemoCasesCatalog.defaultOwnerUid,
          initialUserName: MashwarDemoCasesCatalog.defaultOwnerName,
        );
        await worksite.activateDemoShowcase();
        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));

        await tester.pumpWidget(
          buildHarness(
            home: const WorkRequestsFeedScreen(),
            worksite: worksite,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        expect(worksite.requests.length, 14);

        // 1. Instant search query + clear button
        await tester.enterText(
          find.byKey(const ValueKey('feed_search_input')),
          'PPR',
        );
        await tester.pumpAndSettle();
        expect(worksite.searchQuery, 'PPR');
        expect(worksite.requests, isNotEmpty);
        expect(
          worksite.requests.any((r) => r.id == 'demo_wr_03_offers_mine'),
          isTrue,
        );

        await tester.tap(find.byKey(const ValueKey('feed_search_clear_btn')));
        await tester.pumpAndSettle();
        expect(worksite.searchQuery, isEmpty);
        expect(worksite.requests.length, 14);

        // 2. Category filter chip (electrical)
        final electricalChip =
            find.byKey(const ValueKey('feed_category_chip_electrical'));
        await tester.ensureVisible(electricalChip);
        await tester.tap(electricalChip);
        await tester.pumpAndSettle();
        expect(worksite.filterCategory, 'electrical');
        expect(worksite.requests, isNotEmpty);
        expect(
          worksite.requests.every((r) => r.supplyCategory == 'electrical'),
          isTrue,
        );

        final allCatChip = find.byKey(const ValueKey('feed_category_chip_all'));
        await tester.ensureVisible(allCatChip);
        await tester.tap(allCatChip);
        await tester.pumpAndSettle();
        expect(worksite.filterCategory, isNull);

        // 3. Perspective pills (My Requests, Assigned Jobs, Open to Bid, All)
        final minePill = find.byKey(const ValueKey('feed_perspective_mine'));
        await tester.ensureVisible(minePill);
        await tester.tap(minePill);
        await tester.pumpAndSettle();
        expect(worksite.filterOnlyMine, isTrue);
        expect(
          worksite.requests.every(
            (r) => r.requesterId == MashwarDemoCasesCatalog.defaultOwnerUid,
          ),
          isTrue,
        );

        final assignedPill =
            find.byKey(const ValueKey('feed_perspective_assigned'));
        await tester.ensureVisible(assignedPill);
        await tester.tap(assignedPill);
        await tester.pumpAndSettle();
        expect(worksite.filterAssignedToMe, isTrue);
        expect(
          worksite.requests.every(
            (r) =>
                r.assignedProviderId == MashwarDemoCasesCatalog.defaultOwnerUid,
          ),
          isTrue,
        );

        final openMarketPill =
            find.byKey(const ValueKey('feed_perspective_open_market'));
        await tester.ensureVisible(openMarketPill);
        await tester.tap(openMarketPill);
        await tester.pumpAndSettle();
        expect(worksite.filterOnlyMine, isFalse);
        expect(worksite.filterAssignedToMe, isFalse);
        expect(
          find.byKey(const ValueKey('feed_request_card_demo_wr_02_open_mkt')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('feed_request_card_demo_wr_01_open_mine')),
          findsNothing,
        );

        final allPill = find.byKey(const ValueKey('feed_perspective_all'));
        await tester.ensureVisible(allPill);
        await tester.tap(allPill);
        await tester.pumpAndSettle();
        expect(worksite.requests.length, 14);

        // 4. Sort option (Highest Budget)
        await tester.tap(find.byKey(const ValueKey('feed_sort_btn')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('feed_sort_option_highestBudget')),
        );
        await tester.pumpAndSettle();
        expect(worksite.sortBy, WorksiteSortOption.highestBudget);
        expect(
          worksite.requests.first.effectiveTotalMinor.minorUnits,
          greaterThanOrEqualTo(
            worksite.requests.last.effectiveTotalMinor.minorUnits,
          ),
        );

        // 5. Clear Filters resets search, category, perspective, and sort
        final clearBtn = find.byKey(const ValueKey('feed_clear_filters_btn'));
        await tester.ensureVisible(clearBtn);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();
        expect(worksite.hasActiveFilters, isFalse);
        expect(worksite.sortBy, WorksiteSortOption.newest);
        expect(worksite.requests.length, 14);
        expect(tester.takeException(), isNull);

        worksite.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'CreateWorkRequestScreen supports 1-tap quick template prefill and dynamic live QAR cost calculator',
      (tester) async {
        tester.view.physicalSize = const Size(412, 892);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, wsRepo) = createSeededRepos();
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: MashwarDemoCasesCatalog.defaultOwnerUid,
        );
        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));

        await tester.pumpWidget(
          buildHarness(
            home: const CreateWorkRequestScreen(),
            worksite: worksite,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        // Tap 1-tap quick template for Electrical Breakers
        final tplCard = find.byKey(
          const ValueKey('create_quick_template_electrical_breakers'),
        );
        expect(tplCard, findsOneWidget);
        await tester.tap(tplCard);
        await tester.pumpAndSettle();

        expect(
          find.text('12x 32A Circuit Breakers & 4mm Copper Cable'),
          findsOneWidget,
        );
        expect(find.text('12'), findsOneWidget);

        // Advance Step 1 -> Step 2 (pickup is already prefilled by template)
        await tester.tap(find.byKey(const ValueKey('create_next_btn')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('create_step2_dropoff')),
          'Lusail Marina Plot 42 - Gate 3',
        );
        await tester.tap(find.byKey(const ValueKey('create_next_btn')));
        await tester.pumpAndSettle();

        // Step 3 live cost summary shows template totals (420 + 55 = 475 QAR, cap 480 + 55 = 535 QAR)
        final summaryCard =
            find.byKey(const ValueKey('create_live_cost_summary'));
        await tester.ensureVisible(summaryCard);
        expect(summaryCard, findsOneWidget);
        expect(
          find.descendant(of: summaryCard, matching: find.text('475 QAR')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('535 QAR')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('+60 QAR')),
          findsOneWidget,
        );

        // Update QAR fields and verify live cost summary recalculates immediately
        await tester.enterText(
          find.byKey(const ValueKey('create_step3_items_qar')),
          '500',
        );
        await tester.enterText(
          find.byKey(const ValueKey('create_step3_cap_qar')),
          '600',
        );
        await tester.enterText(
          find.byKey(const ValueKey('create_step3_fee_qar')),
          '75',
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(summaryCard);
        expect(
          find.descendant(of: summaryCard, matching: find.text('575 QAR')),
          findsWidgets,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('675 QAR')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('+100 QAR')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        worksite.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'WorkRequestDetailsScreen renders status stepper, smart offer comparison badges, and supports requester cancellation',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, wsRepo) = createSeededRepos();
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: MashwarDemoCasesCatalog.defaultOwnerUid,
          initialUserName: MashwarDemoCasesCatalog.defaultOwnerName,
        );
        await worksite.activateDemoShowcase();
        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));

        await tester.pumpWidget(
          buildHarness(
            home: const WorkRequestDetailsScreen(
              requestId: 'demo_wr_03_offers_mine',
            ),
            worksite: worksite,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MashwarWorksiteStatusStepper), findsOneWidget);
        expect(
          find.byKey(const ValueKey('offer_badge_lowest_price_demo_off_01')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('offer_badge_fastest_eta_demo_off_01')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('offer_badge_top_rated_demo_off_01')),
          findsOneWidget,
        );

        final cancelBtn =
            find.byKey(const ValueKey('details_cancel_request_btn'));
        await tester.ensureVisible(cancelBtn);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('cancel_reason_input')),
          'Worksite schedule postponed',
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm_cancel_request_btn')),
        );
        await tester.pumpAndSettle();

        expect(worksite.selectedRequest!.status, WorkRequestStatus.cancelled);
        expect(
          worksite.selectedRequest!.cancellationReason,
          'Worksite schedule postponed',
        );
        expect(find.text('Request Cancelled'), findsOneWidget);
        expect(tester.takeException(), isNull);

        worksite.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'WorkRequestDetailsScreen allows provider offer withdrawal and reverts offer_received to open when 0 pending offers remain',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, wsRepo) = createSeededRepos();
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: MashwarDemoCasesCatalog.approvedSafetyProviderId,
          initialUserName: 'Tariq Al-Mohannadi Safety',
        );
        await worksite.activateDemoShowcase();
        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));

        await tester.pumpWidget(
          buildHarness(
            home: const WorkRequestDetailsScreen(
              requestId: 'demo_wr_04_offers_mkt',
            ),
            worksite: worksite,
            auth: AuthProvider.forTesting(
              user: const UserModel(
                id: MashwarDemoCasesCatalog.approvedSafetyProviderId,
                fullName: 'Tariq Al-Mohannadi Safety',
                phone: '55345678',
                gender: UserGender.male,
              ),
            ),
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        final withdrawBtn =
            find.byKey(const ValueKey('withdraw_offer_btn_demo_off_04'));
        await tester.ensureVisible(withdrawBtn);
        await tester.tap(withdrawBtn);
        await tester.pumpAndSettle();

        expect(worksite.selectedOffers.first.status, 'withdrawn');
        expect(find.text('Withdrawn'), findsOneWidget);
        expect(withdrawBtn, findsNothing);
        expect(worksite.selectedRequest!.status, WorkRequestStatus.open);
        expect(worksite.selectedRequest!.offerCount, 0);
        expect(tester.takeException(), isNull);

        worksite.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'NotificationsCenterScreen manages real notifications & navigation, and UserProfileScreen + HelpSupportScreen enforce Qatar MVP compliance',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final (provRepo, wsRepo) = createSeededRepos();
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: MashwarDemoCasesCatalog.defaultOwnerUid,
          initialUserName: MashwarDemoCasesCatalog.defaultOwnerName,
        );
        await worksite.activateDemoShowcase();
        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));

        // 1. NotificationsCenterScreen
        await tester.pumpWidget(
          buildHarness(
            home: const NotificationsCenterScreen(),
            worksite: worksite,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        expect(worksite.unreadNotificationsCount, 3);
        expect(find.text('All (4)'), findsOneWidget);
        expect(find.text('Unread (3)'), findsOneWidget);
        expect(find.text('Mark All Read'), findsOneWidget);

        // Filter to unread only
        await tester.tap(find.text('Unread (3)'));
        await tester.pumpAndSettle();
        expect(
          find.text('Al Shamal delivery completed & settled'),
          findsNothing,
        );
        expect(
          find.text('3 new offers on your plumbing supply request'),
          findsOneWidget,
        );

        // Tap notification -> marks read & navigates to WorkRequestDetailsScreen
        await tester.tap(
          find.text('3 new offers on your plumbing supply request'),
        );
        await tester.pumpAndSettle();
        expect(worksite.unreadNotificationsCount, 2);
        expect(find.byType(WorkRequestDetailsScreen), findsOneWidget);

        // Back to NotificationsCenterScreen -> Mark All Read -> Unread empty state
        await tester.tap(
          find.descendant(
            of: find.byType(WorkRequestDetailsScreen),
            matching: find.byIcon(Icons.arrow_back_ios_new_rounded),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Unread (2)'), findsOneWidget);

        await tester.tap(find.text('Mark All Read'));
        await tester.pumpAndSettle();
        expect(worksite.unreadNotificationsCount, 0);
        expect(find.text('No Unread Alerts'), findsOneWidget);

        // 2. UserProfileScreen Qatar MVP compliance (no Wallet / Rides / Parcels / Board Ads)
        await tester.pumpWidget(
          buildHarness(
            home: const UserProfileScreen(),
            worksite: worksite,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Requests'), findsOneWidget);
        expect(find.text('Completed Jobs'), findsOneWidget);
        expect(find.text('QID Verification & Worksites'), findsOneWidget);
        expect(find.text('Notifications Center'), findsOneWidget);
        expect(find.textContaining('Wallet'), findsNothing);
        expect(find.text('Rides'), findsNothing);
        expect(find.text('Parcels'), findsNothing);
        expect(find.textContaining('Board Ads'), findsNothing);

        // 3. HelpSupportScreen Qatar MVP compliance (no '19884', no fake rides FAQ)
        await tester.pumpWidget(
          buildHarness(
            home: const HelpSupportScreen(),
            worksite: worksite,
            settings: settings,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Qatar Worksite Operations Desk'), findsOneWidget);
        expect(find.text('ops@mashwar.qa · +974 4400 9999'), findsOneWidget);
        expect(
          find.text('Call Qatar Support (+974 4400 9999)'),
          findsOneWidget,
        );
        expect(
          find.text('Email Operations (ops@mashwar.qa)'),
          findsOneWidget,
        );
        expect(find.textContaining('19884'), findsNothing);
        expect(find.textContaining('book a seat'), findsNothing);
        expect(tester.takeException(), isNull);

        worksite.dispose();
        settings.dispose();
      },
    );
  });
}
