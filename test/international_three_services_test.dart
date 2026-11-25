import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/core/widgets/mashwar_animations.dart';
import 'package:mashwar/core/widgets/mashwar_worksite_icons.dart';
import 'package:mashwar/data/models/board_ad_model.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/data/repositories/implementations/provider_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/worksite_repository_impl.dart';
import 'package:mashwar/screens/board/make_offer_sheet.dart';
import 'package:mashwar/screens/board/post_ad_screen.dart';
import 'package:mashwar/screens/driver/publish_ride_screen.dart';
import 'package:mashwar/screens/home/home_screen.dart';
import 'package:mashwar/screens/main_nav_shell.dart';
import 'package:mashwar/screens/parcel/parcel_tracking_screen.dart';
import 'package:mashwar/screens/parcel/send_parcel_screen.dart';
import 'package:mashwar/screens/ride_details/ride_details_screen.dart';
import 'package:mashwar/screens/trips/trips_and_parcels_hub_screen.dart';
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

  Widget buildIntlHarness({
    required Widget home,
    SettingsProvider? settings,
    AuthProvider? auth,
    RidesProvider? rides,
    BoardProvider? board,
    ParcelsProvider? parcels,
    WorksiteProvider? worksite,
  }) {
    final effectiveSettings =
        settings ?? (SettingsProvider()..setLocale(const Locale('ar', 'QA')));
    final effectiveAuth = auth ??
        AuthProvider.forTesting(
          user: const UserModel(
            id: 'intl_traveler_01',
            fullName: 'Tariq Al-Mansoor',
            phone: '55112233',
            email: 'tariq@mashwar.app',
            gender: UserGender.male,
            isVerified: true,
          ),
        );
    final (provRepo, wsRepo) = createSeededRepos();
    final effectiveWorksite = worksite ??
        WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: effectiveAuth.user.id,
          initialUserName: effectiveAuth.user.fullName,
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
          value: effectiveSettings,
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: effectiveAuth),
        ChangeNotifierProvider<RidesProvider>.value(
          value: rides ?? RidesProvider(),
        ),
        ChangeNotifierProvider<BoardProvider>.value(
          value: board ?? BoardProvider(),
        ),
        ChangeNotifierProvider<ParcelsProvider>.value(
          value: parcels ?? ParcelsProvider(),
        ),
        ChangeNotifierProvider<WorksiteProvider>.value(
          value: effectiveWorksite,
        ),
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

  group('MASHWAR International 3-Service E2E Widget & State Suite', () {
    testWidgets(
      'Zero Sadu strip & International HomeScreen render all 3 service pillars, dual CTAs, and MashwarThreeStepsBanner across 375x812 & 1280x900 in AR RTL & EN LTR',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. QatarSaduAccentBar renders strictly 0.0 height
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  QatarSaduAccentBar(height: 8.0),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(QatarSaduAccentBar)).height,
          equals(0.0),
        );

        final settings = SettingsProvider();
        final (provRepo, wsRepo) = createSeededRepos();
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: 'intl_traveler_01',
          initialUserName: 'Tariq Al-Mansoor',
        );
        await worksite.loadRequests();

        const dualCtaKeys = [
          ValueKey('home_publish_trip_cta'),
          ValueKey('home_find_trip_cta'),
          ValueKey('home_send_parcel_cta'),
          ValueKey('home_browse_parcels_cta'),
          ValueKey('home_create_request_cta'),
          ValueKey('home_browse_requests_cta'),
        ];

        for (final size in const [Size(375, 812), Size(1280, 900)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          // Arabic RTL
          settings.setLocale(const Locale('ar', 'QA'));
          await tester.pumpWidget(
            buildIntlHarness(
              home: const HomeScreen(),
              settings: settings,
              worksite: worksite,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            Directionality.of(tester.element(find.byType(HomeScreen))),
            TextDirection.rtl,
          );
          expect(find.text('إلى أين مشوارك أو طلبك اليوم؟'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('home_three_services_section')),
            findsOneWidget,
          );
          expect(find.byType(MashwarServicePillarIcon), findsNWidgets(3));
          for (final key in dualCtaKeys) {
            expect(find.byKey(key), findsOneWidget);
          }
          expect(find.byType(MashwarThreeStepsBanner), findsOneWidget);

          // English LTR
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
          expect(
            find.byKey(const ValueKey('home_three_services_section')),
            findsOneWidget,
          );
          for (final key in dualCtaKeys) {
            expect(find.byKey(key), findsOneWidget);
          }
          expect(find.byType(MashwarThreeStepsBanner), findsOneWidget);
        }

        worksite.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'Service 1A — Traveler completes 3-step PublishRideScreen wizard and published trip syncs to RidesProvider, BoardProvider & TripsAndParcelsHubScreen',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));
        final rides = RidesProvider();
        final board = BoardProvider();
        final initialRidesCount = rides.allRides.length;
        final initialMyAdsCount = board.myAds.length;

        await tester.pumpWidget(
          buildIntlHarness(
            home: const PublishRideScreen(),
            settings: settings,
            rides: rides,
            board: board,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Step 1: Route & Schedule + MashwarWizardStepHeader
        expect(find.byType(MashwarWizardStepHeader), findsOneWidget);
        expect(find.byKey(const ValueKey('publish_step_1')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('publish_trip_next_1')));
        await tester.pumpAndSettle();

        // Step 2: Empty Seats (select 4) + Accepts Parcels switch
        expect(find.byKey(const ValueKey('publish_step_2')), findsOneWidget);
        await tester.tap(find.text('4'));
        await tester.pumpAndSettle();

        final parcelsSwitch =
            find.byKey(const ValueKey('publish_accepts_parcels_switch'));
        expect(parcelsSwitch, findsOneWidget);
        // Toggle off then back on to verify interactive parcel-on-route switch
        await tester.ensureVisible(parcelsSwitch);
        await tester.tap(parcelsSwitch);
        await tester.pumpAndSettle();
        await tester.tap(parcelsSwitch);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('publish_trip_next_2')));
        await tester.pumpAndSettle();

        // Step 3: Preferences & Live Summary -> Submit
        expect(find.byKey(const ValueKey('publish_step_3')), findsOneWidget);
        final submitBtn =
            find.byKey(const ValueKey('publish_trip_submit_btn'));
        expect(submitBtn, findsOneWidget);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(find.text('Trip Published Live!'), findsOneWidget);
        expect(rides.allRides.length, initialRidesCount + 1);
        expect(rides.myPublishedRides, isNotEmpty);

        final publishedRide = rides.myPublishedRides.first;
        expect(publishedRide.remainingSeats, 4);
        expect(publishedRide.acceptsParcels, isTrue);
        expect(board.myAds.length, initialMyAdsCount + 1);
        expect(board.myAds.first.type, BoardAdType.rideOffer);

        // Verify visible in TripsAndParcelsHubScreen (hub_tab_trips)
        await tester.pumpWidget(
          buildIntlHarness(
            home: const TripsAndParcelsHubScreen(initialTabIndex: 0),
            settings: settings,
            rides: rides,
            board: board,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('hub_tab_trips')), findsOneWidget);
        expect(
          find.byKey(ValueKey('hub_book_seat_${publishedRide.id}')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('hub_send_parcel_${publishedRide.id}')),
          findsOneWidget,
        );

        rides.dispose();
        board.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'Service 1B — Passenger posts destination ride request via PostAdScreen and traveler submits offer via MakeOfferSheet in TripsAndParcelsHubScreen',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));
        final rides = RidesProvider();
        final board = BoardProvider();
        final initialAdsCount = board.allAds.length;

        // 1. Passenger posts destination ride request via 3-step PostAdScreen
        await tester.pumpWidget(
          buildIntlHarness(
            home: const PostAdScreen(
              initialCategory: BoardAdType.rideRequest,
              initialIntent: 0,
            ),
            settings: settings,
            rides: rides,
            board: board,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MashwarWizardStepHeader), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Publish Request / Offer'));
        await tester.pumpAndSettle();

        expect(board.allAds.length, initialAdsCount + 1);
        expect(board.myAds.first.type, BoardAdType.rideRequest);

        // 2. Traveler opens TripsAndParcelsHubScreen on hub_tab_requests and submits an offer via MakeOfferSheet
        final targetRequest = board.filteredAds.firstWhere(
          (ad) =>
              ad.type == BoardAdType.rideRequest &&
              !ad.id.startsWith('my_ad_') &&
              ad.status == BoardAdStatus.active,
        );

        await tester.pumpWidget(
          buildIntlHarness(
            home: const TripsAndParcelsHubScreen(
              initialTabIndex: 1,
              initialRequestFilter: 1,
            ),
            settings: settings,
            rides: rides,
            board: board,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('hub_tab_requests')), findsOneWidget);

        final makeOfferBtn =
            find.byKey(ValueKey('hub_make_offer_${targetRequest.id}'));
        await tester.ensureVisible(makeOfferBtn);
        await tester.pumpAndSettle();
        await tester.tap(makeOfferBtn);
        await tester.pumpAndSettle();

        expect(find.byType(MakeOfferSheet), findsOneWidget);
        await tester.tap(find.text('Make a Ride Offer'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Send Offer Now'));
        await tester.pumpAndSettle();

        final updatedAd =
            board.allAds.firstWhere((ad) => ad.id == targetRequest.id);
        expect(updatedAd.status, BoardAdStatus.offerSent);
        expect(board.mySentOffers.any((ad) => ad.id == targetRequest.id), isTrue);
        expect(tester.takeException(), isNull);

        rides.dispose();
        board.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'Service 2A — RideDetailsScreen opens SendParcelScreen(ride: ...) and 3-step submission navigates to ParcelTrackingScreen with 4-digit Pickup & Delivery OTPs',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));
        final rides = RidesProvider();
        final parcels = ParcelsProvider();
        final board = BoardProvider();
        final initialParcelsCount = parcels.parcels.length;

        final parcelFriendlyRide = rides.allRides.firstWhere(
          (r) => r.acceptsParcels && !r.isLadiesOnly && r.remainingSeats > 0,
        );

        await tester.pumpWidget(
          buildIntlHarness(
            home: RideDetailsScreen(ride: parcelFriendlyRide),
            settings: settings,
            rides: rides,
            parcels: parcels,
            board: board,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final sendParcelBtn =
            find.byKey(const ValueKey('ride_details_send_parcel_btn'));
        expect(sendParcelBtn, findsOneWidget);
        await tester.tap(sendParcelBtn);
        await tester.pumpAndSettle();

        expect(find.byType(SendParcelScreen), findsOneWidget);
        expect(find.byType(MashwarWizardStepHeader), findsOneWidget);

        // Step 1 -> Step 2 -> Step 3 -> Submit
        expect(find.byKey(const ValueKey('parcel_step_1')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('send_parcel_next_1')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('parcel_step_2')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('send_parcel_next_2')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('parcel_step_3')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('send_parcel_submit_btn')));
        await tester.pumpAndSettle();

        expect(find.byType(ParcelTrackingScreen), findsOneWidget);
        expect(parcels.parcels.length, initialParcelsCount + 1);

        final createdParcel = parcels.parcels.first;
        expect(createdParcel.hasAssignedTraveler, isTrue);
        expect(createdParcel.driverName, parcelFriendlyRide.driverName);
        expect(RegExp(r'^\d{4}$').hasMatch(createdParcel.pickupOtp), isTrue);
        expect(createdParcel.deliveryOtp, isNotNull);
        expect(
          RegExp(r'^\d{4}$').hasMatch(createdParcel.deliveryOtp!),
          isTrue,
        );

        expect(
          find.text('Pickup OTP (Share with traveler at pickup)'),
          findsOneWidget,
        );
        expect(find.textContaining('Recipient Delivery OTP'), findsOneWidget);
        for (final digit in createdParcel.pickupOtp.split('')) {
          expect(find.text(digit), findsWidgets);
        }
        for (final digit in createdParcel.deliveryOtp!.split('')) {
          expect(find.text(digit), findsWidgets);
        }
        expect(tester.takeException(), isNull);

        rides.dispose();
        parcels.dispose();
        board.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'Service 2B — Standalone SendParcelScreen() creates an open route parcel request in ParcelsProvider & BoardProvider with valid 4-digit dual OTPs',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final settings = SettingsProvider()..setLocale(const Locale('en', 'US'));
        final rides = RidesProvider();
        final parcels = ParcelsProvider();
        final board = BoardProvider();
        final initialParcelsCount = parcels.parcels.length;
        final initialBoardAdsCount = board.allAds.length;

        await tester.pumpWidget(
          buildIntlHarness(
            home: const SendParcelScreen(),
            settings: settings,
            rides: rides,
            parcels: parcels,
            board: board,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Keep Open Route Request selected (no pre-selected ride) -> Next -> Next -> Submit
        await tester.tap(find.byKey(const ValueKey('send_parcel_next_1')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('send_parcel_next_2')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('send_parcel_submit_btn')));
        await tester.pumpAndSettle();

        expect(find.byType(ParcelTrackingScreen), findsOneWidget);
        expect(parcels.parcels.length, initialParcelsCount + 1);
        expect(board.allAds.length, initialBoardAdsCount + 1);

        final openParcel = parcels.parcels.first;
        expect(openParcel.hasAssignedTraveler, isFalse);
        expect(RegExp(r'^\d{4}$').hasMatch(openParcel.pickupOtp), isTrue);
        expect(openParcel.deliveryOtp, isNotNull);
        expect(RegExp(r'^\d{4}$').hasMatch(openParcel.deliveryOtp!), isTrue);

        final mirroredBoardAd = board.allAds.first;
        expect(mirroredBoardAd.type, BoardAdType.parcelRequest);
        expect(tester.takeException(), isNull);

        rides.dispose();
        parcels.dispose();
        board.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      '5-Tab MainNavShell navigates across all 5 tabs and My Activity filter pills on mobile (390x844) & desktop (1280x900) with zero exceptions',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final settings = SettingsProvider()..setLocale(const Locale('ar', 'QA'));
        final (provRepo, wsRepo) = createSeededRepos();
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: 'intl_traveler_01',
          initialUserName: 'Tariq Al-Mansoor',
        );
        await worksite.loadRequests();

        for (final size in const [Size(390, 844), Size(1280, 900)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            buildIntlHarness(
              home: const MainNavShell(),
              settings: settings,
              worksite: worksite,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          if (size.width >= 840) {
            final rail =
                tester.widget<NavigationRail>(find.byType(NavigationRail));
            expect(rail.destinations.length, 5);
          } else {
            final bar = tester
                .widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
            expect(bar.items.length, 5);
          }

          // Tab 2: الرحلات والطرود
          await tester.tap(find.text('الرحلات والطرود').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Tab 3: التوريد والمهام
          await tester.tap(find.text('التوريد والمهام').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Tab 4: نشاطي + filter pills
          await tester.tap(find.text('نشاطي').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          for (final filterKey in const [
            ValueKey('activity_filter_trips'),
            ValueKey('activity_filter_parcels'),
            ValueKey('activity_filter_supply'),
            ValueKey('activity_filter_all'),
          ]) {
            await tester.ensureVisible(find.byKey(filterKey));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(filterKey));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          await tester.tap(find.byKey(const ValueKey('activity_segment_completed')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(find.byKey(const ValueKey('activity_segment_active')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Tab 5: حسابي
          await tester.tap(find.text('حسابي').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Back to Tab 1: الرئيسية
          await tester.tap(find.text('الرئيسية').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        worksite.dispose();
        settings.dispose();
      },
    );
  });
}
