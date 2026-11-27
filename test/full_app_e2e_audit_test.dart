import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/core/widgets/mashwar_button.dart';
import 'package:mashwar/core/widgets/mashwar_google_map_panel.dart';
import 'package:mashwar/core/widgets/mashwar_handover_qr_panel.dart';
import 'package:mashwar/data/demo/demo_cases_catalog.dart';
import 'package:mashwar/data/mock_data.dart';
import 'package:mashwar/data/models/board_ad_model.dart';
import 'package:mashwar/data/repositories/app_repositories.dart';
import 'package:mashwar/data/services/google_maps_service.dart';
import 'package:mashwar/screens/account/legal_and_backend_screens.dart';
import 'package:mashwar/screens/alerts/my_alerts_screen.dart';
import 'package:mashwar/screens/board/make_offer_sheet.dart';
import 'package:mashwar/screens/booking/booking_confirmation_screen.dart';
import 'package:mashwar/screens/booking/booking_review_screen.dart';
import 'package:mashwar/screens/chat/chat_screen.dart';
import 'package:mashwar/screens/driver/driver_rides_management_screens.dart';
import 'package:mashwar/screens/home/city_search_modal.dart';
import 'package:mashwar/screens/parcel/parcel_dispute_screen.dart';
import 'package:mashwar/screens/parcel/parcel_tracking_screen.dart';
import 'package:mashwar/screens/ride_details/widgets/ride_route_map_view.dart';
import 'package:mashwar/screens/safety/safety_screens.dart';
import 'package:mashwar/screens/trip/active_trip_screen.dart';
import 'package:mashwar/screens/trip/rate_trip_screen.dart';
import 'package:mashwar/screens/vehicle/vehicle_registration_screen.dart';
import 'package:mashwar/screens/wallet/wallet_screen.dart';
import 'package:mashwar/screens/worksite/work_request_details_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

Widget _buildFullAppHarness(
  Widget home, {
  SettingsProvider? settings,
  AuthProvider? auth,
  RidesProvider? rides,
  ParcelsProvider? parcels,
  BoardProvider? board,
  AlertsProvider? alerts,
  AdminProvider? admin,
  WorksiteProvider? worksite,
}) {
  final settingsProvider = settings ?? SettingsProvider();
  return MultiProvider(
    key: UniqueKey(),
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth ?? AuthProvider.forTesting(user: MockData.currentUser),
      ),
      ChangeNotifierProvider<RidesProvider>.value(
        value: rides ?? RidesProvider(),
      ),
      ChangeNotifierProvider<ParcelsProvider>.value(
        value: parcels ?? ParcelsProvider(),
      ),
      ChangeNotifierProvider<BoardProvider>.value(
        value: board ?? BoardProvider(),
      ),
      ChangeNotifierProvider<AlertsProvider>.value(
        value: alerts ?? AlertsProvider(),
      ),
      ChangeNotifierProvider<AdminProvider>.value(
        value: admin ?? AdminProvider(),
      ),
      ChangeNotifierProvider<WorksiteProvider>.value(
        value: worksite ?? WorksiteProvider(),
      ),
    ],
    child: Consumer<SettingsProvider>(
      builder: (context, s, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
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

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppRepositories.instance.useLocalMocks(allowDevMocks: true);
    await GoogleMapsService.clearRuntimeApiKey();
    BookingConfirmationScreen.debugUrlLauncher = null;
    ActiveTripScreen.debugUrlLauncher = null;
    EmergencySosSheet.debugUrlLauncher = null;
    WorkRequestDetailsScreen.debugUrlLauncher = null;
  });

  tearDown(() async {
    BookingConfirmationScreen.debugUrlLauncher = null;
    ActiveTripScreen.debugUrlLauncher = null;
    EmergencySosSheet.debugUrlLauncher = null;
    WorkRequestDetailsScreen.debugUrlLauncher = null;
    await GoogleMapsService.clearRuntimeApiKey();
  });

  group('1. Google Maps Platform & Bilingual Qatar/GCC Geo Engine Audit', () {
    test(
      'IMapsRepository.searchLocations resolves Arabic & English Qatar municipalities, hubs, WOQOD, Metro, and GCC cities',
      () async {
        final maps = AppRepositories.instance.maps;

        final arLusail = await maps.searchLocations('لوسيل');
        expect(arLusail, isNotEmpty);
        expect(arLusail.first.mainText, contains('لوسيل'));
        expect(arLusail.first.latitude, closeTo(25.4357, 0.05));
        expect(arLusail.first.longitude, closeTo(51.4910, 0.05));
        expect(
          arLusail.first.googleMapsPlaceUrl,
          startsWith('https://www.google.com/maps/search/?api=1'),
        );

        final enRasLaffan = await maps.searchLocations('Ras Laffan');
        expect(enRasLaffan, isNotEmpty);
        expect(
          enRasLaffan.any(
            (r) =>
                r.mainText.toLowerCase().contains('ras laffan') ||
                r.mainText.contains('رأس لفان'),
          ),
          isTrue,
        );

        final industrialSt10 = await maps.searchLocations('شارع 10');
        expect(industrialSt10, isNotEmpty);
        expect(industrialSt10.first.latitude, isNotNull);

        final woqodMatches = await maps.searchLocations('WOQOD');
        expect(woqodMatches, isNotEmpty);

        final gccMatches = await maps.searchLocations('Riyadh');
        expect(gccMatches, isNotEmpty);
        expect(gccMatches.first.latitude, closeTo(24.7136, 0.1));
      },
    );

    test(
      'IMapsRepository.getRouteDetails computes distinct dynamic corridor highways, realistic distances & polylines across North, South, and West corridors',
      () async {
        final maps = AppRepositories.instance.maps;

        // North Corridor: Doha -> Al Khor
        final northRoute = await maps.getRouteDetails('الدوحة', 'الخور');
        expect(northRoute.distanceKm, inInclusiveRange(38.0, 72.0));
        expect(northRoute.durationMinutes, inInclusiveRange(25, 65));
        expect(northRoute.corridorHighwayAr, isNotNull);
        expect(northRoute.corridorHighwayEn, isNotNull);
        expect(northRoute.polylinePoints.length, greaterThanOrEqualTo(2));
        expect(
          northRoute.googleMapsDirectionsUrl,
          startsWith('https://www.google.com/maps/dir/?api=1'),
        );

        // South Corridor: Doha -> Al Wakrah
        final southRoute = await maps.getRouteDetails('الدوحة', 'الوكرة');
        expect(southRoute.distanceKm, inInclusiveRange(10.0, 30.0));
        expect(southRoute.durationMinutes, lessThan(northRoute.durationMinutes));
        expect(southRoute.corridorHighwayAr, isNotNull);

        // West Corridor: Al Rayyan -> Dukhan
        final westRoute = await maps.getRouteDetails('الريان', 'دخان');
        expect(westRoute.distanceKm, inInclusiveRange(60.0, 105.0));
        expect(westRoute.durationMinutes, greaterThan(southRoute.durationMinutes));
        expect(westRoute.corridorHighwayAr, isNotNull);

        // Dynamic highway check: North, South, and West must NOT share one hardcoded highway!
        expect(
          northRoute.corridorHighwayAr,
          isNot(equals(southRoute.corridorHighwayAr)),
        );
        expect(
          northRoute.corridorHighwayAr,
          isNot(equals(westRoute.corridorHighwayAr)),
        );
        expect(
          southRoute.corridorHighwayAr,
          isNot(equals(westRoute.corridorHighwayAr)),
        );
      },
    );

    test(
      'GoogleMapsService URL builders and runtime API key set/load/mask/clear work safely',
      () async {
        final dirUrl = GoogleMapsService.buildDirectionsUrl(
          'الدوحة',
          'الخور',
          stopover: 'لوسيل',
        );
        final parsedDir = Uri.parse(dirUrl);
        expect(parsedDir.host, 'www.google.com');
        expect(parsedDir.path, '/maps/dir/');
        expect(parsedDir.queryParameters['api'], '1');
        expect(parsedDir.queryParameters['travelmode'], 'driving');
        expect(parsedDir.queryParameters['origin'], contains('الدوحة'));
        expect(parsedDir.queryParameters['destination'], contains('الخور'));
        expect(parsedDir.queryParameters['waypoints'], contains('لوسيل'));

        final searchUrl = GoogleMapsService.buildPlaceSearchUrl(
          'Katara',
          lat: 25.3602,
          lng: 51.5245,
        );
        final parsedSearch = Uri.parse(searchUrl);
        expect(parsedSearch.host, 'www.google.com');
        expect(parsedSearch.path, '/maps/search/');
        expect(parsedSearch.queryParameters['api'], '1');
        expect(parsedSearch.queryParameters['query'], contains('Katara'));

        final service = GoogleMapsService();
        expect(GoogleMapsService.hasRuntimeApiKey, isFalse);

        await GoogleMapsService.setRuntimeApiKey('AIzaSyRuntimeAuditKey9876');
        expect(GoogleMapsService.hasRuntimeApiKey, isTrue);
        expect(service.hasConfiguredApiKey, isTrue);
        expect(GoogleMapsService.maskedActiveApiKey, 'AIza••••••••9876');
        expect(
          GoogleMapsService.maskedActiveApiKey,
          isNot(contains('RuntimeAuditKey')),
        );

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(GoogleMapsService.runtimeApiKeyPrefsKey),
          'AIzaSyRuntimeAuditKey9876',
        );

        await GoogleMapsService.clearRuntimeApiKey();
        expect(GoogleMapsService.hasRuntimeApiKey, isFalse);
        expect(prefs.getString(GoogleMapsService.runtimeApiKeyPrefsKey), isNull);
      },
    );

    testWidgets(
      'CitySearchModal live bilingual search & MashwarGoogleMapPanel + screen Google Maps navigation buttons work cleanly',
      (tester) async {
        _configureTestViewport(tester);

        // 1. CitySearchModal live search (English & Arabic)
        String? pickedLocation;
        await tester.pumpWidget(
          _buildFullAppHarness(
            Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const ValueKey('open_city_modal_btn'),
                    onPressed: () async {
                      pickedLocation = await Navigator.of(ctx).push<String>(
                        MaterialPageRoute(
                          builder: (_) =>
                              const CitySearchModal(title: 'اختر الوجهة'),
                        ),
                      );
                    },
                    child: const Text('Open Modal'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_city_modal_btn')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('city_search_input')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('city_other_custom_chip')),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const ValueKey('city_search_input')),
          'Ras Laffan',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('city_confirm_custom_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('city_preview_gmaps_0')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('city_confirm_custom_btn')));
        await tester.pumpAndSettle();
        expect(pickedLocation, 'Ras Laffan');

        // 2. MashwarGoogleMapPanel with urlLauncherOverride
        Uri? capturedPanelUri;
        await tester.pumpWidget(
          _buildFullAppHarness(
            Scaffold(
              body: SingleChildScrollView(
                child: MashwarGoogleMapPanel(
                  origin: 'الدوحة',
                  destination: 'دخان',
                  keyPrefix: 'audit_corridor',
                  urlLauncherOverride: (uri, {mode = LaunchMode.platformDefault}) async {
                    capturedPanelUri = uri;
                    return true;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('audit_corridor_gmaps_panel')),
          findsOneWidget,
        );
        final openPanelBtn =
            find.byKey(const ValueKey('audit_corridor_open_gmaps_btn'));
        expect(openPanelBtn, findsOneWidget);
        await tester.tap(openPanelBtn);
        await tester.pumpAndSettle();

        expect(capturedPanelUri, isNotNull);
        expect(capturedPanelUri!.host, 'www.google.com');
        expect(capturedPanelUri!.path, '/maps/dir/');

        // 3. RideRouteMapView dynamic highway & Google Maps button + ParcelTrackingScreen + WorkRequestDetailsScreen
        await tester.pumpWidget(
          _buildFullAppHarness(
            Scaffold(
              body: SingleChildScrollView(
                child: RideRouteMapView(ride: MockData.initialRides[2]), // Doha -> Dukhan
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('ride_map_open_gmaps_btn')),
          findsOneWidget,
        );

        await tester.pumpWidget(
          _buildFullAppHarness(
            ParcelTrackingScreen(parcel: MockData.activeParcel),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('parcel_open_gmaps_btn')),
          findsOneWidget,
        );

        final worksite = WorksiteProvider(
          initialUserId: MashwarDemoCasesCatalog.defaultOwnerUid,
          initialUserName: MashwarDemoCasesCatalog.defaultOwnerName,
        );
        await worksite.activateDemoShowcase();
        Uri? worksiteMapUri;
        WorkRequestDetailsScreen.debugUrlLauncher = (
          uri, {
          mode = LaunchMode.externalApplication,
        }) async {
          worksiteMapUri = uri;
          return true;
        };
        await tester.pumpWidget(
          _buildFullAppHarness(
            WorkRequestDetailsScreen(requestId: worksite.requests.first.id),
            worksite: worksite,
          ),
        );
        await tester.pumpAndSettle();
        final detailsMapBtn =
            find.byKey(const ValueKey('details_open_gmaps_btn'));
        expect(detailsMapBtn, findsOneWidget);
        await tester.ensureVisible(detailsMapBtn);
        await tester.tap(detailsMapBtn);
        await tester.pumpAndSettle();
        expect(worksiteMapUri, isNotNull);
        expect(worksiteMapUri.toString(), contains('google.com/maps'));
      },
    );
  });

  group('2. Real Backend Repository & Provider Persistence Audit', () {
    testWidgets(
      'ChatScreen persists messages & Google Maps location share via AppRepositories.instance.chat across full re-mounts',
      (tester) async {
        _configureTestViewport(tester);
        const auditChatId = 'audit_chat_doha_alkhor_01';

        await tester.pumpWidget(
          _buildFullAppHarness(
            const ChatScreen(
              chatId: auditChatId,
              driverName: 'حمد الكواري',
              driverCar: 'تويوتا كامري · أبيض لؤلؤي',
              tripRoute: 'الدوحة ← الخور',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Send a real user message
        await tester.enterText(
          find.byKey(const ValueKey('chat_message_input')),
          'أنا وصلت عند بوابة مترو مشيرب الرئيسية',
        );
        await tester.tap(find.byKey(const ValueKey('chat_send_btn')));
        await tester.pumpAndSettle();

        expect(
          find.text('أنا وصلت عند بوابة مترو مشيرب الرئيسية'),
          findsOneWidget,
        );

        // Share live Google Maps location link
        await tester.tap(find.byKey(const ValueKey('chat_share_location_btn')));
        await tester.pumpAndSettle();

        final storedMessages =
            await AppRepositories.instance.chat.getMessages(auditChatId);
        expect(
          storedMessages.any(
            (m) => m.text.contains('أنا وصلت عند بوابة مترو مشيرب الرئيسية'),
          ),
          isTrue,
        );
        expect(
          storedMessages.any(
            (m) => m.text.contains('https://www.google.com/maps/search/?api=1'),
          ),
          isTrue,
        );

        // Unmount ChatScreen completely
        await tester.pumpWidget(_buildFullAppHarness(const Scaffold()));
        await tester.pumpAndSettle();
        expect(
          find.text('أنا وصلت عند بوابة مترو مشيرب الرئيسية'),
          findsNothing,
        );

        // Re-mount ChatScreen with the same chatId and verify repository restoration
        await tester.pumpWidget(
          _buildFullAppHarness(
            const ChatScreen(
              chatId: auditChatId,
              driverName: 'حمد الكواري',
              driverCar: 'تويوتا كامري · أبيض لؤلؤي',
              tripRoute: 'الدوحة ← الخور',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('أنا وصلت عند بوابة مترو مشيرب الرئيسية'),
          findsOneWidget,
        );
        expect(
          find.textContaining('https://www.google.com/maps/search/?api=1'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'WalletScreen top-up & withdrawal persist directly through AppRepositories.instance.wallet',
      (tester) async {
        _configureTestViewport(tester);
        final auth = AuthProvider.forTesting(user: MockData.currentUser);
        final uid = auth.effectiveWalletUserId;

        final initialBalance =
            await AppRepositories.instance.wallet.getBalance(uid);
        expect(initialBalance, 450.0);

        await tester.pumpWidget(
          _buildFullAppHarness(const WalletScreen(), auth: auth),
        );
        await tester.pumpAndSettle();

        expect(find.text('450.00'), findsOneWidget);

        // 1. Top up 200 QAR
        await tester.tap(find.byKey(const ValueKey('wallet_open_topup_btn')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('wallet_topup_amount_input')),
          '200',
        );
        await tester.pumpAndSettle();

        final confirmTopupBtn =
            find.byKey(const ValueKey('wallet_confirm_topup_btn'));
        await tester.ensureVisible(confirmTopupBtn);
        await tester.tap(confirmTopupBtn);
        await tester.pumpAndSettle();

        expect(auth.user.walletBalance, 650.0);
        expect(await AppRepositories.instance.wallet.getBalance(uid), 650.0);
        expect(find.text('650.00'), findsOneWidget);

        // 2. Withdraw 150 QAR
        await tester.tap(find.byKey(const ValueKey('wallet_open_withdraw_btn')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('wallet_withdraw_amount_input')),
          '150',
        );
        await tester.enterText(
          find.byKey(const ValueKey('wallet_withdraw_dest_input')),
          '+97455123456',
        );
        await tester.pumpAndSettle();

        final confirmWithdrawBtn =
            find.byKey(const ValueKey('wallet_confirm_withdraw_btn'));
        await tester.ensureVisible(confirmWithdrawBtn);
        await tester.tap(confirmWithdrawBtn);
        await tester.pumpAndSettle();

        expect(auth.user.walletBalance, 500.0);
        expect(await AppRepositories.instance.wallet.getBalance(uid), 500.0);
        expect(find.text('500.00'), findsOneWidget);

        final repoTxs =
            await AppRepositories.instance.wallet.getTransactions(uid);
        expect(repoTxs.length, greaterThanOrEqualTo(4));
      },
    );

    testWidgets(
      'MyAlertsScreen validates duplicate cities, creates custom route alerts, and persists via AlertsProvider',
      (tester) async {
        _configureTestViewport(tester);
        final alerts = AlertsProvider();
        final initialCount = alerts.alerts.length;

        await tester.pumpWidget(
          _buildFullAppHarness(const MyAlertsScreen(), alerts: alerts),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_create_alert_btn')));
        await tester.pumpAndSettle();

        // Select custom From & To cities — test invalid identical cities first
        final fromOtherChip =
            find.byKey(const ValueKey('alert_from_other_chip'));
        await tester.ensureVisible(fromOtherChip);
        await tester.tap(fromOtherChip);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('alert_from_custom_input')),
          'رأس لفان',
        );

        final toOtherChip = find.byKey(const ValueKey('alert_to_other_chip'));
        await tester.ensureVisible(toOtherChip);
        await tester.tap(toOtherChip);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('alert_to_custom_input')),
          'رأس لفان',
        );

        final saveBtn = find.byKey(const ValueKey('save_route_alert_btn'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Duplicate origin/destination must be blocked
        expect(
          find.byKey(const ValueKey('alert_validation_error')),
          findsOneWidget,
        );
        expect(alerts.alerts.length, initialCount);

        // Now enter a distinct custom destination and save
        await tester.enterText(
          find.byKey(const ValueKey('alert_to_custom_input')),
          'مطار حمد الدولي',
        );
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(alerts.alerts.length, initialCount + 1);
        expect(alerts.alerts.first.fromCity, 'رأس لفان');
        expect(alerts.alerts.first.toCity, 'مطار حمد الدولي');
        expect(find.textContaining('رأس لفان'), findsWidgets);
      },
    );

    testWidgets(
      'DriverRidesScreen computes live earnings dynamically from RidesProvider, ParcelsProvider & AuthProvider',
      (tester) async {
        _configureTestViewport(tester);
        final rides = RidesProvider();
        final parcels = ParcelsProvider();
        final auth = AuthProvider.forTesting(user: MockData.currentUser);

        await tester.pumpWidget(
          _buildFullAppHarness(
            const DriverRidesScreen(),
            rides: rides,
            parcels: parcels,
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('driver_earnings_banner')),
          findsOneWidget,
        );
        // Hardcoded legacy '1,850' must NOT appear
        expect(find.textContaining('1,850'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('driver_analytics_btn')));
        await tester.pumpAndSettle();

        final earningsFinder =
            find.byKey(const ValueKey('driver_analytics_earnings_value'));
        expect(earningsFinder, findsOneWidget);
        final beforePublishText = tester.widget<Text>(earningsFinder).data!;

        // Close sheet, publish a new high-value ride, and verify live recomputation
        await tester.tap(find.text('حسناً'));
        await tester.pumpAndSettle();

        rides.publishRide(
          driverName: auth.user.fullName,
          driverCar: 'تويوتا لاندكروزر · أبيض',
          driverPhone: auth.user.phone,
          fromCity: 'الدوحة',
          toCity: 'رأس لفان',
          departureTime: '6:00 ص',
          departureDate: 'الأحد 8 نوفمبر',
          availableSeats: 2,
          pricePerSeat: 60,
          acceptsParcels: true,
          parcelPrice: 30,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('driver_analytics_btn')));
        await tester.pumpAndSettle();

        final afterPublishText = tester.widget<Text>(earningsFinder).data!;
        expect(afterPublishText, isNot(equals(beforePublishText)));
      },
    );

    testWidgets(
      'RateTripScreen, ParcelDisputeScreen & VehicleRegistrationScreen persist updates to RidesProvider, ParcelsProvider & AuthProvider',
      (tester) async {
        _configureTestViewport(tester);
        final rides = RidesProvider();
        final parcels = ParcelsProvider();
        final auth = AuthProvider.forTesting(user: MockData.currentUser);

        // 1. RateTripScreen -> RidesProvider
        await tester.pumpWidget(
          _buildFullAppHarness(
            const RateTripScreen(
              rideId: 'ride_1',
              driverName: 'حمد الكواري',
              route: 'الدوحة ← الخور',
            ),
            rides: rides,
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('rate_trip_star_5')));
        await tester.pumpAndSettle();

        final tipBtn = find.byKey(const ValueKey('rate_trip_tip_20'));
        await tester.ensureVisible(tipBtn);
        await tester.tap(tipBtn);
        await tester.pumpAndSettle();

        final commentInput =
            find.byKey(const ValueKey('rate_trip_comment_input'));
        await tester.ensureVisible(commentInput);
        await tester.enterText(commentInput, 'التزام ممتاز بالموعد والقيادة');

        final submitRatingBtn =
            find.byKey(const ValueKey('rate_trip_submit_btn'));
        await tester.ensureVisible(submitRatingBtn);
        await tester.tap(submitRatingBtn);
        await tester.pumpAndSettle();

        final savedRating = rides.ratingForRide('ride_1');
        expect(savedRating, isNotNull);
        expect(savedRating!.rating, 5);
        expect(savedRating.tipAmount, 20);
        expect(savedRating.comment, 'التزام ممتاز بالموعد والقيادة');

        // 2. ParcelDisputeScreen -> ParcelsProvider
        await tester.pumpWidget(
          _buildFullAppHarness(
            const ParcelDisputeScreen(
              parcelId: 'parcel_991',
              reportId: '#991',
            ),
            parcels: parcels,
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();

        final otherReasonChip =
            find.byKey(const ValueKey('parcel_dispute_reason_other'));
        await tester.ensureVisible(otherReasonChip);
        await tester.tap(otherReasonChip);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('parcel_dispute_custom_reason_input')),
          'تأخر التسليم عن نافذة الموقع المتفق عليها',
        );

        final photoBtn = find.byKey(const ValueKey('parcel_dispute_photo_btn'));
        await tester.ensureVisible(photoBtn);
        await tester.tap(photoBtn);
        await tester.pumpAndSettle();

        final submitDisputeBtn =
            find.byKey(const ValueKey('parcel_dispute_submit_btn'));
        await tester.ensureVisible(submitDisputeBtn);
        await tester.tap(submitDisputeBtn);
        await tester.pumpAndSettle();

        expect(parcels.isParcelDisputed('parcel_991'), isTrue);
        final dispute = parcels.disputeForParcel('parcel_991');
        expect(dispute, isNotNull);
        expect(
          dispute!.customReason,
          'تأخر التسليم عن نافذة الموقع المتفق عليها',
        );
        expect(dispute.hasPhotoEvidence, isTrue);
        expect(find.textContaining('قيد المراجعة'), findsWidgets);

        // 3. VehicleRegistrationScreen -> AuthProvider
        await tester.pumpWidget(
          _buildFullAppHarness(
            const VehicleRegistrationScreen(),
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();

        final modelOtherChip =
            find.byKey(const ValueKey('vehicle_model_other_chip'));
        await tester.ensureVisible(modelOtherChip);
        await tester.tap(modelOtherChip);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('vehicle_model_input')),
          'تويوتا لاندكروزر 2026',
        );

        final colorOtherChip =
            find.byKey(const ValueKey('vehicle_color_other_chip'));
        await tester.ensureVisible(colorOtherChip);
        await tester.tap(colorOtherChip);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('vehicle_color_input')),
          'أبيض لؤلؤي',
        );

        final plateNumInput =
            find.byKey(const ValueKey('vehicle_plate_numbers_input'));
        await tester.ensureVisible(plateNumInput);
        await tester.enterText(plateNumInput, '774411');

        final seats4Btn = find.byKey(const ValueKey('vehicle_seats_4'));
        await tester.ensureVisible(seats4Btn);
        await tester.pumpAndSettle();
        await tester.tap(seats4Btn);
        await tester.pumpAndSettle();

        final saveVehicleBtn = find.byKey(const ValueKey('vehicle_save_btn'));
        await tester.ensureVisible(saveVehicleBtn);
        await tester.tap(saveVehicleBtn);
        await tester.pumpAndSettle();

        expect(auth.user.tripVibe, contains('تويوتا لاندكروزر 2026'));
        expect(auth.user.tripVibe, contains('774411'));
        expect(auth.user.occupation, contains('تويوتا لاندكروزر 2026'));
      },
    );
  });

  group('3. Full Multi-Screen End-to-End User Journeys', () {
    testWidgets(
      'End-to-End Passenger Journey: BookingReview -> BookingConfirmation (QR + OTP + Google Maps) -> ActiveTrip (PreTrip -> InTransit -> Completed) -> RateTrip',
      (tester) async {
        _configureTestViewport(tester);
        final rides = RidesProvider();
        final auth = AuthProvider.forTesting(user: MockData.currentUser);
        final targetRide = MockData.initialRides[1]; // Doha -> Al Wakrah (3 seats, 25 QAR, instant)

        Uri? confirmationMapsUri;
        BookingConfirmationScreen.debugUrlLauncher = (uri) async {
          confirmationMapsUri = uri;
          return true;
        };

        Uri? activeTripMapsUri;
        ActiveTripScreen.debugUrlLauncher = (uri) async {
          activeTripMapsUri = uri;
          return true;
        };

        await tester.pumpWidget(
          _buildFullAppHarness(
            BookingReviewScreen(ride: targetRide),
            rides: rides,
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();

        // Step 1: Select 2 seats & Direct Bank Transfer on BookingReviewScreen
        await tester.tap(
          find.byKey(const ValueKey('booking_seats_increment_btn')),
        );
        await tester.pumpAndSettle();
        expect(find.text('2'), findsWidgets);

        final transferOption =
            find.byKey(const ValueKey('booking_payment_transfer'));
        await tester.ensureVisible(transferOption);
        await tester.tap(transferOption);
        await tester.pumpAndSettle();
        expect(auth.selectedPaymentMethod, 'bank_transfer_manual');

        await tester.tap(
          find.byKey(const ValueKey('booking_confirm_submit_btn')),
        );
        await tester.pump(const Duration(milliseconds: 220));
        await tester.pumpAndSettle();

        // Step 2: Verify BookingConfirmationScreen (QR + 4-digit OTP + Google Maps pickup button)
        expect(find.byType(BookingConfirmationScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('booking_handover_qr_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('booking_handover_qr_code')),
          findsOneWidget,
        );
        expect(find.byType(MashwarQrMatrixWidget), findsOneWidget);
        expect(
          find.byKey(const ValueKey('booking_handover_otp_value')),
          findsOneWidget,
        );
        expect(rides.activeBooking?.id, targetRide.id);

        final gmapsPickupBtn =
            find.byKey(const ValueKey('booking_open_gmaps_btn'));
        await tester.ensureVisible(gmapsPickupBtn);
        await tester.tap(gmapsPickupBtn);
        await tester.pumpAndSettle();
        expect(confirmationMapsUri, isNotNull);
        expect(
          confirmationMapsUri.toString(),
          startsWith('https://www.google.com/maps/dir/?api=1'),
        );

        // Step 3: Navigate to ActiveTripScreen (PreTrip)
        final viewActiveBtn =
            find.byKey(const ValueKey('booking_view_active_trip_btn'));
        await tester.ensureVisible(viewActiveBtn);
        await tester.tap(viewActiveBtn);
        await tester.pumpAndSettle();

        expect(find.byType(ActiveTripScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('active_trip_driver_avatar')),
          findsOneWidget,
        );

        final preTripGmapsBtn =
            find.byKey(const ValueKey('active_trip_open_gmaps_btn'));
        await tester.ensureVisible(preTripGmapsBtn);
        await tester.tap(preTripGmapsBtn);
        await tester.pumpAndSettle();
        expect(activeTripMapsUri, isNotNull);
        expect(
          activeTripMapsUri.toString(),
          startsWith('https://www.google.com/maps/dir/?api=1'),
        );

        // Step 4: Transition PreTrip -> InTransit
        final startLiveBtn =
            find.byKey(const ValueKey('active_trip_start_live_btn'));
        await tester.ensureVisible(startLiveBtn);
        await tester.tap(startLiveBtn);
        await tester.pumpAndSettle();

        expect(find.byType(RideRouteMapView), findsOneWidget);
        expect(
          find.byKey(const ValueKey('active_trip_sos_btn')),
          findsOneWidget,
        );

        // Step 5: Complete Trip -> Completed Phase & RidesProvider status update
        final completeBtn =
            find.byKey(const ValueKey('active_trip_complete_btn'));
        await tester.ensureVisible(completeBtn);
        await tester.tap(completeBtn);
        await tester.pumpAndSettle();

        expect(find.text('وصلت بالسلامة!'), findsOneWidget);
        expect(
          rides.allRides.firstWhere((r) => r.id == targetRide.id).status,
          'completed',
        );

        // Step 6: Open RateTripScreen from Completed Trip and submit review
        final rateBtn = find.byKey(const ValueKey('active_trip_rate_btn'));
        await tester.ensureVisible(rateBtn);
        await tester.tap(rateBtn);
        await tester.pumpAndSettle();

        expect(find.byType(RateTripScreen), findsOneWidget);
        final submitReviewBtn =
            find.byKey(const ValueKey('rate_trip_submit_btn'));
        await tester.ensureVisible(submitReviewBtn);
        await tester.tap(submitReviewBtn);
        await tester.pumpAndSettle();

        expect(rides.ratingForRide(targetRide.id), isNotNull);
        expect(rides.ratingForRide(targetRide.id)!.rating, 5);
      },
    );

    testWidgets(
      'Safety Center, Emergency 999 / Ops Dialer & ShareTripSheet Custom Emergency Contact Journey',
      (tester) async {
        _configureTestViewport(tester);
        final auth = AuthProvider.forTesting(user: MockData.currentUser);
        final launchedUris = <Uri>[];
        EmergencySosSheet.debugUrlLauncher = (uri) async {
          launchedUris.add(uri);
          return true;
        };

        await tester.pumpWidget(
          _buildFullAppHarness(
            LiveTripTrackingScreen(ride: MockData.initialRides.first),
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Live Google Maps route button
        final liveGmapsBtn =
            find.byKey(const ValueKey('safety_live_open_gmaps_btn'));
        await tester.ensureVisible(liveGmapsBtn);
        await tester.tap(liveGmapsBtn);
        await tester.pumpAndSettle();
        expect(
          launchedUris.any(
            (u) => u.toString().startsWith('https://www.google.com/maps/dir/'),
          ),
          isTrue,
        );

        // 2. 24/7 Operations Support confirmation dialog -> tel:+97444009999
        final callOpsBtn = find.byKey(const ValueKey('safety_call_ops_btn'));
        await tester.ensureVisible(callOpsBtn);
        await tester.tap(callOpsBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('confirm_call_ops_support_btn')),
        );
        await tester.pumpAndSettle();
        expect(
          launchedUris.any(
            (u) => u.scheme == 'tel' && u.path.contains('44009999'),
          ),
          isTrue,
        );

        // 3. Emergency SOS Sheet -> 999
        await tester.pumpWidget(
          _buildFullAppHarness(
            const Scaffold(
              body: SingleChildScrollView(child: EmergencySosSheet()),
            ),
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('sos_call_ambulance_999_btn')),
        );
        await tester.pumpAndSettle();
        expect(
          launchedUris.any((u) => u.scheme == 'tel' && u.path.contains('999')),
          isTrue,
        );

        // 4. ShareTripSheet -> Google Maps open + custom emergency contact persisted to AuthProvider
        await tester.pumpWidget(
          _buildFullAppHarness(
            Scaffold(
              body: ShareTripSheet(ride: MockData.initialRides.first),
            ),
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('share_trip_open_gmaps_btn')),
        );
        await tester.pumpAndSettle();

        final addContactBtn =
            find.byKey(const ValueKey('share_trip_add_contact_btn'));
        await tester.ensureVisible(addContactBtn);
        await tester.tap(addContactBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('share_trip_contact_name_input')),
          'سالم المهنا (أخي)',
        );
        await tester.enterText(
          find.byKey(const ValueKey('share_trip_contact_phone_input')),
          '55887766',
        );
        await tester.tap(
          find.byKey(const ValueKey('share_trip_save_contact_btn')),
        );
        await tester.pumpAndSettle();

        expect(auth.user.emergencyContactName, 'سالم المهنا (أخي)');
        expect(auth.user.emergencyContactPhone, '55887766');
      },
    );

    testWidgets(
      'MakeOfferSheet -> BoardProvider offer submission & BackendReadinessScreen Google Maps runtime configuration card',
      (tester) async {
        _configureTestViewport(tester);
        final board = BoardProvider();
        final targetAd = board.allAds.firstWhere(
          (a) => a.status == BoardAdStatus.active,
        );

        final launchedMapsUris = <Uri>[];
        EmergencySosSheet.debugUrlLauncher = (uri) async {
          launchedMapsUris.add(uri);
          return true;
        };

        // 1. MakeOfferSheet -> Google Maps route + submit offer -> BoardProvider
        await tester.pumpWidget(
          _buildFullAppHarness(
            Scaffold(body: MakeOfferSheet(ad: targetAd)),
            board: board,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('make_offer_open_gmaps_btn')),
        );
        await tester.pumpAndSettle();
        expect(
          launchedMapsUris.any(
            (u) => u.toString().startsWith('https://www.google.com/maps/dir/'),
          ),
          isTrue,
        );

        // Open offer form (tap primary MashwarButton in initial card)
        await tester.tap(find.byType(MashwarButton).first);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('make_offer_price_input')),
          '42',
        );
        await tester.enterText(
          find.byKey(const ValueKey('make_offer_note_input')),
          'متجه الآن على نفس المسار وجاهز للتنفيذ الفوري',
        );

        final submitOfferBtn =
            find.byKey(const ValueKey('make_offer_submit_btn'));
        await tester.ensureVisible(submitOfferBtn);
        await tester.tap(submitOfferBtn);
        await tester.pumpAndSettle();

        final updatedAd = board.allAds.firstWhere((a) => a.id == targetAd.id);
        expect(updatedAd.status, BoardAdStatus.offerSent);
        expect(updatedAd.myOfferPrice, 42);

        // 2. BackendReadinessScreen Google Maps Platform Config & Live Corridor Tester
        await tester.pumpWidget(
          _buildFullAppHarness(const BackendReadinessScreen()),
        );
        await tester.pumpAndSettle();

        final gmapsCard =
            find.byKey(const ValueKey('backend_gmaps_config_card'));
        await tester.ensureVisible(gmapsCard);
        await tester.pumpAndSettle();
        expect(gmapsCard, findsOneWidget);

        final keyInput =
            find.byKey(const ValueKey('backend_gmaps_api_key_input'));
        await tester.ensureVisible(keyInput);
        await tester.enterText(keyInput, 'AIzaSyTestKeyForAudit12345');

        final saveKeyBtn =
            find.byKey(const ValueKey('backend_gmaps_save_key_btn'));
        await tester.ensureVisible(saveKeyBtn);
        await tester.tap(saveKeyBtn);
        await tester.pumpAndSettle();

        expect(GoogleMapsService.hasRuntimeApiKey, isTrue);
        expect(find.textContaining('AIza••••••••2345'), findsOneWidget);
        expect(find.textContaining('TestKeyForAudit'), findsNothing);

        // Switch corridor preset to Doha -> Dukhan and test live route
        final preset1 = find.byKey(const ValueKey('backend_gmaps_preset_1'));
        await tester.ensureVisible(preset1);
        await tester.tap(preset1);
        await tester.pumpAndSettle();

        final testRouteBtn =
            find.byKey(const ValueKey('backend_gmaps_test_route_btn'));
        await tester.ensureVisible(testRouteBtn);
        await tester.tap(testRouteBtn);
        await tester.pumpAndSettle();

        // Clear runtime key and verify clean reset
        final clearKeyBtn =
            find.byKey(const ValueKey('backend_gmaps_clear_key_btn'));
        await tester.ensureVisible(clearKeyBtn);
        await tester.tap(clearKeyBtn);
        await tester.pumpAndSettle();

        expect(GoogleMapsService.hasRuntimeApiKey, isFalse);
      },
    );
  });
}
