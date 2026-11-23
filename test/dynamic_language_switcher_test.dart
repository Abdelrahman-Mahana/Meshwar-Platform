import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/data/api/mashwar_api_client.dart';
import 'package:mashwar/screens/settings/settings_screen.dart';
import 'package:mashwar/screens/auth/welcome_screen.dart';
import 'package:mashwar/screens/auth/phone_input_screen.dart';
import 'package:mashwar/screens/auth/profile_setup_screen.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue #33: Dynamic RTL/LTR Language Switcher & System Language Detection', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('SettingsProvider detects system locale by default and can switch/persist', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.initFuture;

      expect(settings.isFollowingSystem, true);

      // Switch to English explicitly
      settings.setLocale(const Locale('en', 'US'));
      expect(settings.isArabic, false);
      expect(settings.isFollowingSystem, false);
      expect(settings.locale, const Locale('en', 'US'));
      expect(MashwarApiClient.instance.currentLocale, 'en');

      // Allow async persistence microtask to complete
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mashwar_locale_language_code'), 'en');
      expect(prefs.getString('mashwar_locale_country_code'), 'US');

      // Switch to Follow System
      settings.setFollowSystem();
      expect(settings.isFollowingSystem, true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(prefs.getString('mashwar_locale_language_code'), 'system');

      settings.dispose();
    });

    test('SettingsProvider loads saved locale upon instantiation', () async {
      SharedPreferences.setMockInitialValues({
        'mashwar_locale_language_code': 'en',
        'mashwar_locale_country_code': 'US',
      });

      final settings = SettingsProvider();
      await settings.initFuture;

      expect(settings.isFollowingSystem, false);
      expect(settings.isArabic, false);
      expect(settings.locale, const Locale('en', 'US'));
      expect(MashwarApiClient.instance.currentLocale, 'en');

      settings.dispose();
    });

    testWidgets('Language toggle pill is on WelcomeScreen and NOT on secondary screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.initFuture;
      final auth = AuthProvider();

      Widget buildHarness(Widget child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: auth),
          ],
          child: MaterialApp(
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme,
            home: child,
          ),
        );
      }

      // 1. WelcomeScreen MUST have the language ActionChip button
      await tester.pumpWidget(buildHarness(const WelcomeScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsOneWidget);

      // 2. PhoneInputScreen must NOT have the language pill in AppBar or anywhere
      await tester.pumpWidget(buildHarness(const PhoneInputScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNothing);

      // 3. ProfileSetupScreen must NOT have the language pill in AppBar or anywhere
      await tester.pumpWidget(buildHarness(const ProfileSetupScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNothing);

      auth.dispose();
      settings.dispose();
    });

    testWidgets('Instant rebuild and directionality flip on SettingsScreen language switch', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.initFuture;
      final auth = AuthProvider();

      // Explicitly lock to Arabic initially for test determinism
      settings.setLocale(const Locale('ar', 'EG'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: auth),
          ],
          child: Consumer<SettingsProvider>(
            builder: (context, s, _) {
              return MaterialApp(
                locale: s.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: AppTheme.lightTheme,
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in Arabic
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('لغة التطبيق'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);

      // Tap language tile to open modal sheet
      await tester.tap(find.text('لغة التطبيق'));
      await tester.pumpAndSettle();

      // Verify Modal has System Default, Arabic, and English
      expect(find.text('لغة الهاتف الافتراضية'), findsOneWidget);
      expect(find.text('العربية (قطر)'), findsOneWidget);
      expect(find.text('English (United States)'), findsOneWidget);

      // Select English
      await tester.tap(find.text('English (United States)'));
      await tester.pumpAndSettle();

      // UI should immediately rebuild in English without app restart!
      expect(settings.isArabic, false);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('App Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Switch back to Arabic
      await tester.tap(find.text('App Language'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('العربية (قطر)'));
      await tester.pumpAndSettle();

      expect(settings.isArabic, true);
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('لغة التطبيق'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);

      auth.dispose();
      settings.dispose();
    });
  });
}
