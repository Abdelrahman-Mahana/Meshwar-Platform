import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/data/repositories/implementations/auth_repository_impl.dart';
import 'package:mashwar/screens/auth/email_input_screen.dart';
import 'package:mashwar/screens/auth/otp_verification_screen.dart';
import 'package:mashwar/screens/auth/phone_input_screen.dart';
import 'package:mashwar/screens/auth/profile_setup_screen.dart';
import 'package:mashwar/screens/auth/welcome_screen.dart';
import 'package:mashwar/screens/main_nav_shell.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

void main() {
  Widget buildAppWidget({
    required Widget child,
    AuthProvider? auth,
    SettingsProvider? settings,
  }) {
    final effectiveSettings = settings ??
        (SettingsProvider()..setLocale(const Locale('ar', 'QA')));
    final effectiveAuth = auth ??
        AuthProvider.forTesting(
          authRepository: AuthRepositoryImpl(allowDevMocks: true),
          status: AuthStatus.unauthenticated,
          useDevMockAuth: true,
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: effectiveAuth),
        ChangeNotifierProvider<SettingsProvider>.value(
            value: effectiveSettings),
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

  group('WelcomeScreen Real Email Auth & SMS Gate Tests', () {
    testWidgets(
      'WelcomeScreen renders Email Login, Create Account, and hides fake SMS OTP when SMS provider unavailable',
      (WidgetTester tester) async {
        final nonMockAuth = AuthProvider(useDevMockAuth: false);
        await tester.pumpWidget(
          buildAppWidget(child: const WelcomeScreen(), auth: nonMockAuth),
        );
        await tester.pumpAndSettle();

        expect(find.text('توريد مواقع العمل والمشاريع في قطر'), findsOneWidget);
        expect(find.text('المتابعة بالبريد الإلكتروني'), findsOneWidget);
        expect(find.text('إنشاء حساب جديد'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('welcome_sms_unavailable_notice')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('welcome_phone_btn')), findsNothing);
        nonMockAuth.dispose();
      },
    );

    testWidgets(
      'Tapping Continue with Email navigates to EmailInputScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildAppWidget(child: const WelcomeScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('المتابعة بالبريد الإلكتروني'));
        await tester.pumpAndSettle();

        expect(find.byType(EmailInputScreen), findsOneWidget);
        expect(find.text('تسجيل الدخول بالبريد الإلكتروني'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Continue with Phone in explicit dev-mock mode navigates to PhoneInputScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildAppWidget(child: const WelcomeScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('المتابعة برقم الجوال'));
        await tester.pumpAndSettle();

        expect(find.byType(PhoneInputScreen), findsOneWidget);
        expect(find.text('أدخل رقم جوالك'), findsOneWidget);
      },
    );
  });

  group('EmailInputScreen Real Email+Password Login & Registration Tests', () {
    testWidgets(
      'Email validation and password requirement trigger clearly on invalid input',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildAppWidget(child: const EmailInputScreen()),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('auth_email_input')),
          'invalid-email',
        );
        final submitBtn = find.byKey(const ValueKey('auth_submit_btn'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(find.textContaining('أدخل بريد إلكتروني صحيح'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('auth_email_input')),
          'valid@mashwar.qa',
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(find.textContaining('يرجى إدخال كلمة المرور'), findsOneWidget);
      },
    );

    testWidgets(
      'Valid Email+Password login authenticates via AuthProvider.loginWithEmail and enters MainNavShell',
      (WidgetTester tester) async {
        final auth = AuthProvider(
          authRepository: AuthRepositoryImpl(allowDevMocks: true),
          useDevMockAuth: true,
        );
        await tester.pumpWidget(
          buildAppWidget(child: const EmailInputScreen(), auth: auth),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('auth_email_input')),
          'engineer@mashwar.qa',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_password_input')),
          'secret123',
        );
        final submitBtn = find.byKey(const ValueKey('auth_submit_btn'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(auth.isAuthenticated, isTrue);
        expect(auth.email, 'engineer@mashwar.qa');
        expect(find.byType(MainNavShell), findsOneWidget);
        auth.dispose();
      },
    );

    testWidgets(
      'Switch link switches between Phone and Email seamlessly in dev-mock mode',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildAppWidget(child: const PhoneInputScreen()),
        );
        await tester.pumpAndSettle();

        final toEmailBtn =
            find.text('المتابعة بالبريد الإلكتروني بدلاً من ذلك');
        await tester.ensureVisible(toEmailBtn);
        await tester.tap(toEmailBtn);
        await tester.pumpAndSettle();
        expect(find.byType(EmailInputScreen), findsOneWidget);

        final toPhoneBtn = find.text('المتابعة برقم الجوال بدلاً من ذلك');
        await tester.ensureVisible(toPhoneBtn);
        await tester.tap(toPhoneBtn);
        await tester.pumpAndSettle();
        expect(find.byType(PhoneInputScreen), findsOneWidget);
      },
    );
  });

  group('OtpVerificationScreen with Email Mode Tests', () {
    testWidgets(
      'Renders email address destination and verifies with 6 digits in dev-mock mode',
      (WidgetTester tester) async {
        final auth = AuthProvider.forTesting(useDevMockAuth: true);
        await tester.pumpWidget(
          buildAppWidget(
            child: const OtpVerificationScreen(email: 'user@mashwar.qa'),
            auth: auth,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('user@mashwar.qa'), findsOneWidget);

        await tester.enterText(find.byType(TextField), '482911');
        await tester.pumpAndSettle();

        expect(find.byType(ProfileSetupScreen), findsOneWidget);
        auth.dispose();
      },
    );
  });
}
