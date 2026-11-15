import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/data/api/mashwar_api_client.dart';
import 'package:mashwar/screens/settings/settings_screen.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue #33: Dynamic RTL/LTR Language Switcher & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('SettingsProvider updates locale, notifies listeners, and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();

      expect(settings.isArabic, true);
      expect(settings.locale, const Locale('ar', 'EG'));

      // Switch to English
      settings.setLocale(const Locale('en', 'US'));
      expect(settings.isArabic, false);
      expect(settings.locale, const Locale('en', 'US'));
      expect(MashwarApiClient.instance.currentLocale, 'en');

      // Allow async persistence microtask to complete
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mashwar_locale_language_code'), 'en');
      expect(prefs.getString('mashwar_locale_country_code'), 'US');

      // Switch back to Arabic
      settings.setLocale(const Locale('ar', 'EG'));
      expect(settings.isArabic, true);
      expect(settings.locale, const Locale('ar', 'EG'));
      expect(MashwarApiClient.instance.currentLocale, 'ar');

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(prefs.getString('mashwar_locale_language_code'), 'ar');
    });

    test('SettingsProvider loads saved locale upon instantiation', () async {
      // Simulate previously saved preference
      SharedPreferences.setMockInitialValues({
        'mashwar_locale_language_code': 'en',
        'mashwar_locale_country_code': 'US',
      });

      final settings = SettingsProvider();
      // Allow async _loadPreferences to resolve
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(settings.isArabic, false);
      expect(settings.locale, const Locale('en', 'US'));
      expect(MashwarApiClient.instance.currentLocale, 'en');
    });

    testWidgets('Instant rebuild and directionality flip on SettingsScreen language switch', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      final auth = AuthProvider();

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

      await tester.tap(find.text('العربية (مصر)'));
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
