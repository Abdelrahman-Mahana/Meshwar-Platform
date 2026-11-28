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

    test('MashwarMapVehicleMode & MashwarMapStylePreset expose all Uber map modes and presets', () {
      expect(
        MashwarMapVehicleMode.values.map((m) => m.name).toList(),
        equals(<String>['trip', 'parcel', 'supply', 'place']),
      );
      expect(
        MashwarMapStylePreset.values.map((s) => s.name).toList(),
        equals(<String>['google', 'uber', 'satellite', 'dark']),
      );
    });

    test('buildUberInAppMapUrl populates fromLat/fromLng/toLat/toLng/mode/style/traffic/lang and fallbacks', () {
      // 1. Arabic trip route with Google style + traffic ON + stopover
      final arTrip = Uri.parse(
        GoogleMapsService.buildUberInAppMapUrl(
          origin: 'الدوحة',
          destination: 'الخور',
          stopover: 'لوسيل',
          mode: MashwarMapVehicleMode.trip,
          style: MashwarMapStylePreset.google,
          showTraffic: true,
          isArabic: true,
        ),
      );
      expect(arTrip.path, 'maps/mashwar_uber_map.html');
      expect(double.tryParse(arTrip.queryParameters['fromLat'] ?? ''), isNotNull);
      expect(double.tryParse(arTrip.queryParameters['fromLng'] ?? ''), isNotNull);
      expect(double.tryParse(arTrip.queryParameters['toLat'] ?? ''), isNotNull);
      expect(double.tryParse(arTrip.queryParameters['toLng'] ?? ''), isNotNull);
      expect(arTrip.queryParameters['fromLat'], isNot(arTrip.queryParameters['toLat']));
      expect(arTrip.queryParameters['mode'], 'trip');
      expect(arTrip.queryParameters['style'], 'google');
      expect(arTrip.queryParameters['traffic'], '1');
      expect(arTrip.queryParameters['lang'], 'ar');
      expect(arTrip.queryParameters['stopLat'], isNotEmpty);
      expect(arTrip.queryParameters['stopLng'], isNotEmpty);

      // 2. English parcel route with Uber style + traffic OFF
      final enParcel = Uri.parse(
        GoogleMapsService.buildUberInAppMapUrl(
          origin: 'Doha',
          destination: 'Al Wakrah',
          mode: MashwarMapVehicleMode.parcel,
          style: MashwarMapStylePreset.uber,
          showTraffic: false,
          isArabic: false,
        ),
      );
      expect(enParcel.path, 'maps/mashwar_uber_map.html');
      expect(enParcel.queryParameters['mode'], 'parcel');
      expect(enParcel.queryParameters['style'], 'uber');
      expect(enParcel.queryParameters['traffic'], '0');
      expect(enParcel.queryParameters['lang'], 'en');
      expect(enParcel.queryParameters['fromLat'], isNotEmpty);
      expect(enParcel.queryParameters['toLat'], isNotEmpty);

      // 3. Supply mode with Satellite & Dark presets
      final satSupply = Uri.parse(
        GoogleMapsService.buildUberInAppMapUrl(
          origin: 'المنطقة الصناعية',
          destination: 'لوسيل',
          mode: MashwarMapVehicleMode.supply,
          style: MashwarMapStylePreset.satellite,
          showTraffic: true,
          isArabic: true,
        ),
      );
      expect(satSupply.queryParameters['mode'], 'supply');
      expect(satSupply.queryParameters['style'], 'satellite');
      expect(satSupply.queryParameters['traffic'], '1');
      expect(satSupply.queryParameters['lang'], 'ar');

      final darkSupply = Uri.parse(
        GoogleMapsService.buildUberInAppMapUrl(
          origin: 'Industrial Area',
          destination: 'Lusail',
          mode: MashwarMapVehicleMode.supply,
          style: MashwarMapStylePreset.dark,
          showTraffic: true,
          isArabic: false,
        ),
      );
      expect(darkSupply.queryParameters['mode'], 'supply');
      expect(darkSupply.queryParameters['style'], 'dark');
      expect(darkSupply.queryParameters['lang'], 'en');

      // 4. Place mode & identical-endpoint fallback produce mode=place without toLat/toLng
      final placeOnly = Uri.parse(
        GoogleMapsService.buildUberInAppMapUrl(
          placeQuery: 'لوسيل',
          mode: MashwarMapVehicleMode.place,
          style: MashwarMapStylePreset.google,
          showTraffic: true,
          isArabic: true,
        ),
      );
      expect(placeOnly.queryParameters['mode'], 'place');
      expect(placeOnly.queryParameters['fromLat'], isNotEmpty);
      expect(placeOnly.queryParameters['fromLng'], isNotEmpty);
      expect(placeOnly.queryParameters['toLat'], isNull);
      expect(placeOnly.queryParameters['toLng'], isNull);

      final sameHubFallback = Uri.parse(
        GoogleMapsService.buildUberInAppMapUrl(
          origin: 'لوسيل',
          destination: 'Lusail',
          mode: MashwarMapVehicleMode.trip,
          style: MashwarMapStylePreset.uber,
          showTraffic: true,
          isArabic: true,
        ),
      );
      expect(sameHubFallback.queryParameters['mode'], 'place');
      expect(sameHubFallback.queryParameters['toLat'], isNull);
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

      // Toggle satellite/style & traffic controls in-app
      expect(find.byKey(const ValueKey('inapp_map_traffic_toggle')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('inapp_map_satellite_toggle')));
      await tester.pumpAndSettle();
      final embeddedInFullScreen = tester.widget<MashwarEmbeddedGoogleMap>(
        find.descendant(
          of: find.byType(MashwarInAppMapScreen),
          matching: find.byType(MashwarEmbeddedGoogleMap),
        ),
      );
      expect(embeddedInFullScreen.satellite, isTrue);
      expect(embeddedInFullScreen.effectiveStylePreset, MashwarMapStylePreset.satellite);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeScreen switches Uber map vehicleMode dynamically (trip -> parcel -> supply) and enforces distinct default corridor', (tester) async {
      _configureViewport(tester, size: const Size(1280, 1000));
      final rides = RidesProvider()..setRoute(from: 'لوسيل', to: 'لوسيل');
      await tester.pumpWidget(_buildTestApp(const HomeScreen(), rides: rides));
      await tester.pumpAndSettle();

      final mapCard = find.byKey(const ValueKey('home_corridor_map_card'));
      await tester.scrollUntilVisible(
        mapCard,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      MashwarEmbeddedGoogleMap readHomeMap() => tester.widget<MashwarEmbeddedGoogleMap>(
            find.descendant(
              of: mapCard,
              matching: find.byType(MashwarEmbeddedGoogleMap),
            ),
          );

      // Distinct corridor guard prevents same-city single-pin fallback (لوسيل -> الدوحة)
      final initialMap = readHomeMap();
      expect(initialMap.origin, isNotNull);
      expect(initialMap.destination, isNotNull);
      expect(
        initialMap.origin!.trim().toLowerCase(),
        isNot(initialMap.destination!.trim().toLowerCase()),
      );
      expect(initialMap.vehicleMode, MashwarMapVehicleMode.trip);
      expect(initialMap.showTraffic, isTrue);
      final initialUri = Uri.parse(initialMap.resolveUberMapUrl(isArabic: true));
      expect(initialUri.queryParameters['mode'], 'trip');
      expect(initialUri.queryParameters['fromLat'], isNotEmpty);
      expect(initialUri.queryParameters['toLat'], isNotEmpty);

      // Scroll back to top hero service launcher and switch trip -> parcel -> supply
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home_hero_mode_parcels')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        mapCard,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final parcelMap = readHomeMap();
      expect(parcelMap.vehicleMode, MashwarMapVehicleMode.parcel);
      expect(
        Uri.parse(parcelMap.resolveUberMapUrl(isArabic: true)).queryParameters['mode'],
        'parcel',
      );

      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home_hero_mode_supply')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        mapCard,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final supplyMap = readHomeMap();
      expect(supplyMap.vehicleMode, MashwarMapVehicleMode.supply);
      expect(
        Uri.parse(supplyMap.resolveUberMapUrl(isArabic: true)).queryParameters['mode'],
        'supply',
      );
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
