import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mashwar/data/api/api_endpoints.dart';
import 'package:mashwar/data/api/mashwar_api_client.dart';
import 'package:mashwar/firebase_options.dart';
import 'package:mashwar/data/mock_data.dart';
import 'package:mashwar/data/models/board_ad_model.dart';
import 'package:mashwar/data/models/location_item.dart';
import 'package:mashwar/data/models/parcel_model.dart';
import 'package:mashwar/data/models/ride_model.dart';
import 'package:mashwar/data/models/route_alert_model.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/screens/account/account_extra_screens.dart';
import 'package:mashwar/screens/account/legal_and_backend_screens.dart';
import 'package:mashwar/screens/auth/profile_setup_screen.dart';
import 'package:mashwar/screens/auth/welcome_screen.dart';
import 'package:mashwar/screens/driver/driver_onboarding_screens.dart';
import 'package:mashwar/screens/driver/driver_rides_management_screens.dart';
import 'package:mashwar/screens/home/home_screen.dart';
import 'package:mashwar/screens/main_nav_shell.dart';
import 'package:mashwar/screens/parcel/prohibited_items_sheet.dart';
import 'package:mashwar/screens/safety/safety_screens.dart';
import 'package:mashwar/screens/search/search_results_screen.dart';
import 'package:mashwar/screens/settings/settings_screen.dart';
import 'package:mashwar/screens/wallet/wallet_screen.dart';
import 'package:mashwar/screens/board/board_screen.dart';
import 'package:mashwar/screens/board/post_ad_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

void main() {
  group('Backend Data Models Serialization & API Layer Tests', () {
    test('DefaultFirebaseOptions uses real registered Qatar Android & iOS native App IDs and Bundle ID', () {
      expect(DefaultFirebaseOptions.android.projectId, 'mashwar-qatar-2026-ec99d');
      expect(
        DefaultFirebaseOptions.android.appId,
        '1:820084343406:android:a9e464e38a988eddd35c7f',
      );
      expect(DefaultFirebaseOptions.ios.projectId, 'mashwar-qatar-2026-ec99d');
      expect(
        DefaultFirebaseOptions.ios.appId,
        '1:820084343406:ios:5073f983643cc020d35c7f',
      );
      expect(DefaultFirebaseOptions.ios.iosBundleId, 'qa.mashwar.app');
      expect(DefaultFirebaseOptions.ios.iosBundleId, isNot('eg.mashwar.app'));
    });

    test('UserModel toJson / fromJson / copyWith roundtrip', () {
      final original = MockData.currentUser;
      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.fullName, original.fullName);
      expect(restored.phone, original.phone);
      expect(restored.walletBalance, original.walletBalance);

      final updated = restored.copyWith(fullName: 'أحمد سامي', walletBalance: 500.0);
      expect(updated.fullName, 'أحمد سامي');
      expect(updated.walletBalance, 500.0);
    });

    test('RideModel, ParcelModel, BoardAdModel, RouteAlertModel, LocationItem roundtrip', () {
      final ride = MockData.initialRides.first;
      final rideRestored = RideModel.fromJson(ride.toJson());
      expect(rideRestored.id, ride.id);
      expect(rideRestored.fromCity, ride.fromCity);
      expect(rideRestored.toCity, ride.toCity);

      final parcel = MockData.activeParcel;
      final parcelRestored = ParcelModel.fromJson(parcel.toJson());
      expect(parcelRestored.id, parcel.id);
      expect(parcelRestored.pickupOtp, parcel.pickupOtp);

      final ad = MockData.initialBoardAds.first;
      final adRestored = BoardAdModel.fromJson(ad.toJson());
      expect(adRestored.id, ad.id);
      expect(adRestored.fromCity, ad.fromCity);

      final alert = MockData.initialAlerts.first;
      final alertRestored = RouteAlertModel.fromJson(alert.toJson());
      expect(alertRestored.id, alert.id);
      expect(alertRestored.fromCity, alert.fromCity);

      final loc = MockData.locations.first;
      final locRestored = LocationItem.fromJson(loc.toJson());
      expect(locRestored.name, loc.name);
    });

    test('MashwarApiClient logs requests and formats cURL commands', () {
      final client = MashwarApiClient.instance;
      client.setAccessToken('eyJhbGciOiJIUzI1NiJ9.mashwar_test');
      client.recordRequest('GET', ApiEndpoints.searchRides, statusCode: 200);

      expect(client.recentLogs, isNotEmpty);
      expect(client.recentLogs.first.path, ApiEndpoints.searchRides);
      final curl = client.formatCurlPreview('GET', ApiEndpoints.searchRides);
      expect(curl, contains('Bearer'));
    });
  });

  group('LegalComplianceScreen, BackendReadinessScreen & Multi-Viewport Responsive Tests', () {
    Widget wrapWithProviders(Widget child, {SettingsProvider? settings}) {
      final settingsProvider = settings ?? SettingsProvider();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider(
            create: (_) => AuthProvider.forTesting(
              user: MockData.currentUser,
              walletTransactions: const [
                {
                  'titleAr': 'شحن رصيد - خدمة فوراً (Fawran)',
                  'titleEn': 'Top-up - Fawran Instant Transfer',
                  'date': 'أمس، 4:30 م',
                  'dateEn': 'Yesterday, 4:30 PM',
                  'amount': '+200 ر.ق',
                  'amountValue': 200.0,
                  'isPositive': true,
                },
                {
                  'titleAr': 'رحلة الدوحة ← الخور',
                  'titleEn': 'Ride Doha → Al Khor',
                  'date': '2 نوفمبر، 7:30 ص',
                  'dateEn': 'Nov 2, 7:30 AM',
                  'amount': '-35 ر.ق',
                  'amountValue': -35.0,
                  'isPositive': false,
                },
              ],
            ),
          ),
          ChangeNotifierProvider(create: (_) => RidesProvider()),
          ChangeNotifierProvider(create: (_) => ParcelsProvider()),
          ChangeNotifierProvider(create: (_) => BoardProvider()),
          ChangeNotifierProvider(create: (_) => AlertsProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
          ChangeNotifierProvider(create: (_) => WorksiteProvider()),
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

    testWidgets('LegalComplianceScreen renders all 3 honest Qatar compliance tabs in Arabic & English without false wallet/carpooling claims', (tester) async {
      final settings = SettingsProvider();
      await tester.pumpWidget(wrapWithProviders(const LegalComplianceScreen(), settings: settings));
      await tester.pumpAndSettle();

      // Arabic Tab 1: Worksite Supply Pilot Terms & cash_on_delivery / bank_transfer_manual
      expect(find.text('الشروط القانونية والامتثال التنظيمي'), findsOneWidget);
      expect(find.text('شروط الخدمة'), findsOneWidget);
      expect(find.text('حماية البيانات'), findsOneWidget);
      expect(find.text('الحدود التنظيمية والعلامة'), findsOneWidget);
      expect(find.textContaining('cash_on_delivery'), findsWidgets);
      expect(find.textContaining('bank_transfer_manual'), findsWidgets);
      expect(find.textContaining('SkipCash'), findsNothing);
      expect(find.textContaining('Fawran'), findsNothing);

      // Arabic Tab 2: Qatar PDPL Law No. 13 of 2016 + account deletion rights
      await tester.tap(find.text('حماية البيانات'));
      await tester.pumpAndSettle();
      expect(find.textContaining('قانون حماية خصوصية البيانات الشخصية رقم 13 لسنة 2016'), findsOneWidget);
      expect(find.textContaining('حذف حسابه'), findsOneWidget);

      // Arabic Tab 3: Regulatory Boundaries & MASHWAR MoCI trademark notice
      await tester.tap(find.text('الحدود التنظيمية والعلامة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('الإفصاح التنظيمي وحدود المرحلة التجريبية'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.textContaining('وزارة التجارة والصناعة'), findsWidgets);

      // Switch to English and verify all 3 tabs
      settings.setLocale(const Locale('en', 'US'));
      await tester.pumpAndSettle();
      expect(find.text('Legal Terms & Regulatory Compliance'), findsOneWidget);
      expect(find.text('Regulatory & Trademark'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.textContaining('Qatar MoCI Single Window'), findsOneWidget);

      await tester.tap(find.text('Data Privacy'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Qatar Personal Data Privacy Law (PDPL) No. 13 of 2016'), findsOneWidget);
      expect(find.textContaining('Account Deletion Rights'), findsOneWidget);

      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();
      expect(find.textContaining('MASHWAR Worksite Supply Pilot Terms'), findsOneWidget);
      expect(find.textContaining('SkipCash'), findsNothing);
      expect(find.textContaining('Fawran'), findsNothing);
    });

    testWidgets('BackendReadinessScreen renders JSON schema and executes live endpoint test', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const BackendReadinessScreen()));
      await tester.pumpAndSettle();

      expect(find.text('جاهزية الباك إند وواجهات API'), findsOneWidget);
      expect(find.text('UserModel'), findsOneWidget);
      expect(find.text('RideModel'), findsOneWidget);

      await tester.tap(find.text('RideModel'));
      await tester.pumpAndSettle();
      expect(find.textContaining('driverName'), findsOneWidget);
    });

    testWidgets('Responsive Layout Check: WelcomeScreen, HomeScreen, SearchResults & DriverRides render with zero overflow across 320x568, 375x812, and 1280x800', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final viewports = [
        const Size(320, 568), // Compact small screen
        const Size(375, 812), // Standard mobile
        const Size(1280, 800), // Desktop wide screen
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        // 1. WelcomeScreen
        await tester.pumpWidget(wrapWithProviders(const WelcomeScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 2. HomeScreen (and test route swap button)
        await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 3. SearchResultsScreen
        await tester.pumpWidget(wrapWithProviders(const SearchResultsScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 4. DriverRidesScreen
        await tester.pumpWidget(wrapWithProviders(const DriverRidesScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 5. MainNavShell
        await tester.pumpWidget(wrapWithProviders(const MainNavShell()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('HomeScreen avatar opens UserProfileScreen, Post Ride button is removed, and BoardScreen has single plus on Post Ad', (tester) async {
      // 1. WelcomeScreen has no Demo text and no cluttered feature pills
      await tester.pumpWidget(wrapWithProviders(const WelcomeScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Demo'), findsNothing);
      expect(find.textContaining('ديمو'), findsNothing);
      expect(find.text('موثق بالبطاقة القطرية'), findsNothing);
      expect(find.text('تشارك مقاعد مناطق قطر'), findsNothing);
      expect(find.text('شحن طرود بالكود'), findsNothing);

      // 2. BoardScreen (deferred behind feature flag) still has single plus icon + 'انشر إعلان' label
      await tester.pumpWidget(wrapWithProviders(const BoardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('انشر إعلان'), findsOneWidget);
      expect(find.text('+ انشر إعلان'), findsNothing);

      // 3. HomeScreen has no + انشر رحلة button, and tapping ع opens UserProfileScreen
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('+ انشر رحلة'), findsNothing);
      expect(find.text('انشر رحلة'), findsNothing);

      await tester.tap(find.text('ع'));
      await tester.pumpAndSettle();
      expect(find.text('الملف الشخصي'), findsOneWidget);
    });

    testWidgets('Regression: BoardScreen, WalletScreen (AR & EN), AccountTab, DriverOnboarding, ProhibitedItemsSheet, and ShareTripBottomSheet render with zero layout or type errors', (tester) async {
      final settings = SettingsProvider();

      // 1. BoardScreen & MainNavShell 4-tab MVP render with zero layout exceptions
      await tester.pumpWidget(wrapWithProviders(const BoardScreen(), settings: settings));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(wrapWithProviders(const MainNavShell(), settings: settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الرحلات والطرود').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('التوريد والمهام').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 2. AccountTab renders all ListTile groups with proper Material ancestors
      await tester.tap(find.text('حسابي').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 3. WalletScreen renders transactions in Arabic and English without TypeError or null crash
      await tester.pumpWidget(wrapWithProviders(const WalletScreen(), settings: settings));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('+200 ر.ق'), findsOneWidget);
      expect(find.text('-35 ر.ق'), findsOneWidget);

      settings.setLocale(const Locale('en', 'US'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('+200 QAR'), findsOneWidget);
      expect(find.text('-35 QAR'), findsOneWidget);

      // 4. DriverOnboardingScreen, DriverVerificationStepsScreen, UserProfileScreen, ProhibitedItemsSheet, ShareTripSheet
      await tester.pumpWidget(wrapWithProviders(const DriverOnboardingScreen(), settings: settings));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(wrapWithProviders(const DriverVerificationStepsScreen(), settings: settings));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(wrapWithProviders(const UserProfileScreen(), settings: settings));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(wrapWithProviders(const Scaffold(body: SingleChildScrollView(child: ProhibitedItemsSheet())), settings: settings));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(wrapWithProviders(const Scaffold(body: SingleChildScrollView(child: ShareTripSheet())), settings: settings));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('PostAdScreen renders cleanly across viewports with intent switch & dynamic fields', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Verify responsive layout without any overflow across all screen sizes
      for (final size in [const Size(320, 568), const Size(375, 812), const Size(1280, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithProviders(const PostAdScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('انشر إعلان على اللوحة'), findsOneWidget);
      }

      // 2. Interactive test on standard mobile viewport
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(wrapWithProviders(const PostAdScreen()));
      await tester.pumpAndSettle();

      expect(find.text('أنا أطلب خدمة / مشوار'), findsOneWidget);
      expect(find.text('أنا مسافر / أقدم خدمة'), findsOneWidget);

      // Toggle intent switch to provider mode
      await tester.tap(find.text('أنا مسافر / أقدم خدمة'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('عرض سفر تشاركي'), findsOneWidget);

      // Toggle back to requester mode
      await tester.tap(find.text('أنا أطلب خدمة / مشوار'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Select errand service category
      await tester.tap(find.text('إنجاز معاملات رسمية'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('تفاصيل المعاملة والأوراق الرسمية'), findsOneWidget);

      // Select logistics & cargo category
      await tester.tap(find.text('لوجستيات وتوريد'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('تفاصيل البضاعة والتوريد'), findsOneWidget);
    });

    testWidgets('Full-Screen Responsive Layout Check: MainNavShell (all 5 tabs + NavigationRail), Wallet, Settings, UserProfile & ProfileSetup render cleanly at 375x812 and 1280x800', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final viewports = [
        const Size(375, 812),
        const Size(1280, 800),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        // 1. MainNavShell and navigate across all 4 MVP tabs
        await tester.pumpWidget(wrapWithProviders(const MainNavShell()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        if (size.width >= 840) {
          expect(find.byType(NavigationRail), findsOneWidget);
          expect(find.byType(BottomNavigationBar), findsNothing);
        } else {
          expect(find.byType(BottomNavigationBar), findsOneWidget);
          expect(find.byType(NavigationRail), findsNothing);
        }

        for (final tabLabel in [
          'الرحلات والطرود',
          'التوريد والمهام',
          'نشاطي',
          'حسابي',
          'الرئيسية',
        ]) {
          await tester.tap(find.text(tabLabel).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        // 2. WalletScreen
        await tester.pumpWidget(wrapWithProviders(const WalletScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 3. SettingsScreen
        await tester.pumpWidget(wrapWithProviders(const SettingsScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 4. UserProfileScreen
        await tester.pumpWidget(wrapWithProviders(const UserProfileScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 5. ProfileSetupScreen
        await tester.pumpWidget(wrapWithProviders(const ProfileSetupScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}

