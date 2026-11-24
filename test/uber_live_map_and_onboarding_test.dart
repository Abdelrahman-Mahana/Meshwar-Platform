import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/core/widgets/qatar_live_map_canvas.dart';
import 'package:mashwar/screens/auth/welcome_screen.dart';
import 'package:mashwar/screens/home/home_screen.dart';
import 'package:mashwar/screens/main_nav_shell.dart';
import 'package:mashwar/screens/permissions/location_permission_screen.dart';
import 'package:mashwar/screens/permissions/notification_permission_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

void main() {
  Widget wrapApp(Widget child, {AuthProvider? auth, RidesProvider? rides, SettingsProvider? settings}) {
    final settingsProvider = settings ?? SettingsProvider()..setLocale(const Locale('ar', 'QA'));
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: auth ?? AuthProvider()),
        ChangeNotifierProvider<RidesProvider>.value(value: rides ?? RidesProvider()),
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

  testWidgets('QatarLiveMapCanvas renders all 3 styles and animates frames smoothly when forced', (tester) async {
    for (final style in QatarMapStyle.values) {
      await tester.pumpWidget(
        wrapApp(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 220,
                child: QatarLiveMapCanvas(
                  style: style,
                  activeFromCity: 'الدوحة',
                  activeToCity: 'الخور',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QatarLiveMapCanvas), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    // Live animation mode advances frames cleanly without exceptions
    await tester.pumpWidget(
      wrapApp(
        const Scaffold(
          body: SizedBox(
            width: 360,
            height: 220,
            child: QatarLiveMapCanvas(
              style: QatarMapStyle.light,
              activeFromCity: 'الدوحة',
              activeToCity: 'لوسيل',
              forceAnimate: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('First-run onboarding journey transitions cleanly from Welcome & Permissions into MainNavShell', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. WelcomeScreen renders honest Qatar Worksite Supply onboarding without errors
    await tester.pumpWidget(wrapApp(const WelcomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('توريد مواقع العمل والمشاريع في قطر'), findsOneWidget);
    expect(find.text('المتابعة بالبريد الإلكتروني'), findsOneWidget);

    // 2. LocationPermissionScreen displays live Qatar preview card and advances to Notifications
    await tester.pumpWidget(wrapApp(const LocationPermissionScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(QatarLiveMapCanvas), findsOneWidget);
    expect(find.text('اكتشف خدمات ومشاوير قريبة منك'), findsOneWidget);

    await tester.tap(find.text('تفعيل الموقع'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationPermissionScreen), findsOneWidget);
    expect(find.text('لا تفوّت أي تحديث'), findsOneWidget);

    // 3. Enabling notifications enters MainNavShell seamlessly
    await tester.tap(find.text('تفعيل التنبيهات'));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeScreen displays focused Worksite Supply hero and clean action CTAs across all viewports', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final viewports = [
      const Size(320, 568),
      const Size(375, 812),
      const Size(390, 844),
      const Size(1280, 800),
    ];

    for (final size in viewports) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      final rides = RidesProvider();
      await tester.pumpWidget(wrapApp(const HomeScreen(), rides: rides));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('شنو تحتاج ينجز اليوم؟'), findsOneWidget);
      expect(find.text('إنشاء طلب توريد'), findsOneWidget);
      expect(find.text('تصفح الطلبات المتاحة'), findsOneWidget);
    }
  });
}
