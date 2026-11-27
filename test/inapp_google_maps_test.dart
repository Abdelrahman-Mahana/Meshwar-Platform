import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/core/widgets/mashwar_embedded_google_map.dart';
import 'package:mashwar/core/widgets/mashwar_google_map_panel.dart';
import 'package:mashwar/data/mock_data.dart';
import 'package:mashwar/data/repositories/app_repositories.dart';
import 'package:mashwar/data/services/google_maps_service.dart';
import 'package:mashwar/screens/booking/booking_confirmation_screen.dart';
import 'package:mashwar/screens/home/city_search_modal.dart';
import 'package:mashwar/screens/home/home_screen.dart';
import 'package:mashwar/screens/ride_details/widgets/ride_route_map_view.dart';
import 'package:mashwar/screens/safety/safety_screens.dart';
import 'package:mashwar/screens/trip/active_trip_screen.dart';
import 'package:mashwar/screens/worksite/work_request_details_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

Widget _buildTestApp(
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

void _configureViewport(WidgetTester tester, {Size size = const Size(430, 932)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
    await GoogleMapsService.clearRuntimeApiKey();
    BookingConfirmationScreen.debugUrlLauncher = null;
    ActiveTripScreen.debugUrlLauncher = null;
    EmergencySosSheet.debugUrlLauncher = null;
    WorkRequestDetailsScreen.debugUrlLauncher = null;
  });

  group('GoogleMapsService embedded URL builders', () {
    test('buildEmbeddedRouteUrl keyless mode supports Arabic/English, roadmap/satellite, stopover & fallback', () {
      final arRoadmap = Uri.parse(
        GoogleMapsService.buildEmbeddedRouteUrl(
          origin: 'الدوحة',
          destination: 'الخور',
          isArabic: true,
          satellite: false,
          zoom: 11,
        ),
      );
      expect(arRoadmap.host, 'maps.google.com');
      expect(arRoadmap.path, '/maps');
      expect(arRoadmap.queryParameters['output'], 'embed');
      expect(arRoadmap.queryParameters['hl'], 'ar');
      expect(arRoadmap.queryParameters['t'], 'm');
      expect(arRoadmap.queryParameters['z'], '11');
      expect(arRoadmap.queryParameters['saddr'], contains(','));
      expect(arRoadmap.queryParameters['daddr'], contains(','));

      final enSatelliteStop = Uri.parse(
        GoogleMapsService.buildEmbeddedRouteUrl(
          origin: 'Doha',
          destination: 'Al Khor',
          stopover: 'لوسيل',
          isArabic: false,
          satellite: true,
          zoom: 12,
        ),
      );
      expect(enSatelliteStop.host, 'maps.google.com');
      expect(enSatelliteStop.queryParameters['output'], 'embed');
      expect(enSatelliteStop.queryParameters['hl'], 'en');
      expect(enSatelliteStop.queryParameters['t'], 'k');
      expect(enSatelliteStop.queryParameters['z'], '12');
      expect(enSatelliteStop.queryParameters['daddr'], contains(' to:'));

      // Same origin & destination gracefully falls back to embedded place view
      final sameHub = Uri.parse(
        GoogleMapsService.buildEmbeddedRouteUrl(
          origin: 'الدوحة',
          destination: 'Doha',
          isArabic: true,
        ),
      );
      expect(sameHub.host, 'maps.google.com');
      expect(sameHub.queryParameters['output'], 'embed');
      expect(sameHub.queryParameters['q'], isNotEmpty);
      expect(sameHub.queryParameters['saddr'], isNull);
    });

    test('buildEmbeddedPlaceUrl keyless mode supports coordinates, Arabic/English, roadmap/satellite', () {
      final arPlace = Uri.parse(
        GoogleMapsService.buildEmbeddedPlaceUrl(
          query: 'لوسيل',
          isArabic: true,
          satellite: false,
          zoom: 14,
        ),
      );
      expect(arPlace.host, 'maps.google.com');
      expect(arPlace.path, '/maps');
      expect(arPlace.queryParameters['output'], 'embed');
      expect(arPlace.queryParameters['hl'], 'ar');
      expect(arPlace.queryParameters['t'], 'm');
      expect(arPlace.queryParameters['z'], '14');
      expect(arPlace.queryParameters['q'], contains(','));

      final enSatCoords = Uri.parse(
        GoogleMapsService.buildEmbeddedPlaceUrl(
          query: 'Worksite A',
          lat: 25.41234,
          lng: 51.49876,
          isArabic: false,
          satellite: true,
          zoom: 15,
        ),
      );
      expect(enSatCoords.host, 'maps.google.com');
      expect(enSatCoords.queryParameters['output'], 'embed');
      expect(enSatCoords.queryParameters['hl'], 'en');
      expect(enSatCoords.queryParameters['t'], 'k');
      expect(enSatCoords.queryParameters['q'], '25.41234,51.49876');
    });

    test('buildEmbeddedRouteUrl & buildEmbeddedPlaceUrl use Google Maps Embed API v1 when runtime key is active', () async {
      await GoogleMapsService.setRuntimeApiKey('AIzaSyTestInAppEmbedKey123456');
      expect(GoogleMapsService.hasActiveApiKey, isTrue);

      final keyedRoute = Uri.parse(
        GoogleMapsService.buildEmbeddedRouteUrl(
          origin: 'الدوحة',
          destination: 'الخور',
          stopover: 'لوسيل',
          isArabic: true,
          satellite: true,
        ),
      );
      expect(keyedRoute.host, 'www.google.com');
      expect(keyedRoute.path, '/maps/embed/v1/directions');
      expect(keyedRoute.queryParameters['key'], 'AIzaSyTestInAppEmbedKey123456');
      expect(keyedRoute.queryParameters['mode'], 'driving');
      expect(keyedRoute.queryParameters['maptype'], 'satellite');
      expect(keyedRoute.queryParameters['language'], 'ar');
      expect(keyedRoute.queryParameters['origin'], contains(','));
      expect(keyedRoute.queryParameters['destination'], contains(','));
      expect(keyedRoute.queryParameters['waypoints'], contains(','));

      final keyedPlace = Uri.parse(
        GoogleMapsService.buildEmbeddedPlaceUrl(
          query: 'Al Wakrah',
          isArabic: false,
          satellite: false,
          zoom: 13,
        ),
      );
      expect(keyedPlace.host, 'www.google.com');
      expect(keyedPlace.path, '/maps/embed/v1/place');
      expect(keyedPlace.queryParameters['key'], 'AIzaSyTestInAppEmbedKey123456');
      expect(keyedPlace.queryParameters['maptype'], 'roadmap');
      expect(keyedPlace.queryParameters['language'], 'en');
      expect(keyedPlace.queryParameters['zoom'], '13');
      expect(keyedPlace.queryParameters['q'], contains(','));
    });
  });

  group('MashwarEmbeddedGoogleMap renders across core screens', () {
    testWidgets('renders inside MashwarGoogleMapPanel', (tester) async {
      _configureViewport(tester);
      await tester.pumpWidget(
        _buildTestApp(
          const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: MashwarGoogleMapPanel(
                origin: 'الدوحة',
                destination: 'الخور',
                keyPrefix: 'panel_test',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MashwarEmbeddedGoogleMap), findsOneWidget);
      expect(find.byKey(const ValueKey('mashwar_embedded_gmap_view')), findsOneWidget);
      expect(find.byKey(const ValueKey('panel_test_open_gmaps_btn')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inside HomeScreen and home_open_gmaps_btn navigates in-app to MashwarInAppMapScreen', (tester) async {
      _configureViewport(tester, size: const Size(430, 1000));
      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      final btn = find.byKey(const ValueKey('home_open_gmaps_btn'));
      await tester.scrollUntilVisible(
        btn,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MashwarEmbeddedGoogleMap), findsWidgets);
      expect(find.byKey(const ValueKey('mashwar_embedded_gmap_view')), findsWidgets);

      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.byType(MashwarInAppMapScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('inapp_google_map_screen')), findsOneWidget);
      expect(find.byKey(const ValueKey('inapp_map_satellite_toggle')), findsOneWidget);

      // Toggle satellite mode in-app
      await tester.tap(find.byKey(const ValueKey('inapp_map_satellite_toggle')));
      await tester.pumpAndSettle();
      final embeddedInFullScreen = tester.widget<MashwarEmbeddedGoogleMap>(
        find.descendant(
          of: find.byType(MashwarInAppMapScreen),
          matching: find.byType(MashwarEmbeddedGoogleMap),
        ),
      );
      expect(embeddedInFullScreen.satellite, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inside RideRouteMapView and ride_map_open_gmaps_btn navigates in-app', (tester) async {
      _configureViewport(tester);
      final ride = MockData.initialRides.first;
      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RideRouteMapView(ride: ride),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MashwarEmbeddedGoogleMap), findsOneWidget);
      expect(find.byKey(const ValueKey('mashwar_embedded_gmap_view')), findsOneWidget);

      final btn = find.byKey(const ValueKey('ride_map_open_gmaps_btn'));
      expect(btn, findsOneWidget);
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.byType(MashwarInAppMapScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('inapp_google_map_screen')), findsOneWidget);
      expect(find.byKey(const ValueKey('inapp_map_satellite_toggle')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inside BookingConfirmationScreen and booking_open_gmaps_btn navigates in-app when debugUrlLauncher is null', (tester) async {
      _configureViewport(tester);
      BookingConfirmationScreen.debugUrlLauncher = null;
      final ride = MockData.initialRides.first;

      await tester.pumpWidget(
        _buildTestApp(
          BookingConfirmationScreen(ride: ride, seatsCount: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MashwarEmbeddedGoogleMap), findsOneWidget);
      expect(find.byKey(const ValueKey('mashwar_embedded_gmap_view')), findsOneWidget);

      final btn = find.byKey(const ValueKey('booking_open_gmaps_btn'));
      await _scrollToAndTap(tester, btn);

      expect(find.byType(MashwarInAppMapScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('inapp_google_map_screen')), findsOneWidget);
      expect(find.byKey(const ValueKey('inapp_map_satellite_toggle')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inside ActiveTripScreen', (tester) async {
      _configureViewport(tester);
      final ride = MockData.initialRides.first;

      await tester.pumpWidget(
        _buildTestApp(
          ActiveTripScreen(
            ride: ride,
            initialPhase: TripTrackingPhase.preTrip,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final embedded = find.byType(MashwarEmbeddedGoogleMap);
      await tester.scrollUntilVisible(
        embedded,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(embedded, findsWidgets);
      expect(find.byKey(const ValueKey('mashwar_embedded_gmap_view')), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inside WorkRequestDetailsScreen', (tester) async {
      _configureViewport(tester);
      final worksite = WorksiteProvider();
      await worksite.activateDemoShowcase();
      final reqId = worksite.allLoadedRequests.first.id;

      await tester.pumpWidget(
        _buildTestApp(
          WorkRequestDetailsScreen(requestId: reqId),
          worksite: worksite,
        ),
      );
      await tester.pumpAndSettle();

      final embedded = find.byType(MashwarEmbeddedGoogleMap);
      await tester.scrollUntilVisible(
        embedded,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(embedded, findsWidgets);
      expect(find.byKey(const ValueKey('mashwar_embedded_gmap_view')), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping city_preview_gmaps_0 navigates in-app to MashwarInAppMapScreen with confirm button', (tester) async {
      _configureViewport(tester);
      String? pickedCity;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const ValueKey('open_city_search_btn'),
                  onPressed: () async {
                    pickedCity = await Navigator.of(context).push<String>(
                      MaterialPageRoute<String>(
                        builder: (_) => const CitySearchModal(title: 'اختر الوجهة'),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_city_search_btn')));
      await tester.pumpAndSettle();

      final previewBtn = find.byKey(const ValueKey('city_preview_gmaps_0'));
      expect(previewBtn, findsOneWidget);
      await tester.tap(previewBtn);
      await tester.pumpAndSettle();

      expect(find.byType(MashwarInAppMapScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('inapp_google_map_screen')), findsOneWidget);
      expect(find.byKey(const ValueKey('inapp_map_satellite_toggle')), findsOneWidget);
      expect(find.byKey(const ValueKey('inapp_map_confirm_location_btn')), findsOneWidget);

      // Confirming location inside the in-app map pops back with the chosen city
      await tester.tap(find.byKey(const ValueKey('inapp_map_confirm_location_btn')));
      await tester.pumpAndSettle();

      expect(pickedCity, isNotNull);
      expect(pickedCity, isNotEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
