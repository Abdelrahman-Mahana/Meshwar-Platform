import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/widgets/mashwar_button.dart';
import 'package:mashwar/screens/auth/email_input_screen.dart';
import 'package:mashwar/screens/auth/otp_verification_screen.dart';
import 'package:mashwar/screens/auth/phone_input_screen.dart';
import 'package:mashwar/screens/auth/profile_setup_screen.dart';
import 'package:mashwar/screens/auth/welcome_screen.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/settings_provider.dart';

void main() {
  Widget buildAppWidget({required Widget child, AuthProvider? auth, SettingsProvider? settings}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth ?? AuthProvider.forTesting(useDevMockAuth: true),
        ),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings ?? SettingsProvider()),
      ],
      child: MaterialApp(
        locale: const Locale('ar', 'QA'),
        home: child,
      ),
    );
  }

  group('WelcomeScreen Dual Auth Flow Tests (Uber/inDrive Standard)', () {
    testWidgets('WelcomeScreen renders all 3 sign-in options and brand logo', (WidgetTester tester) async {
      await tester.pumpWidget(buildAppWidget(child: const WelcomeScreen()));
      await tester.pumpAndSettle();

      // Brand Logo & Universal Qatari Community Services Tagline
      expect(find.text('كل خدمة ومشوار في طريقك داخل قطر'), findsOneWidget);

      // Primary Choice 1: Phone
      expect(find.text('المتابعة برقم الجوال'), findsOneWidget);

      // Divider OR
      expect(find.text('أو'), findsOneWidget);

      // Choice 2: Google
      expect(find.text('المتابعة باستخدام Google'), findsOneWidget);

      // Choice 3: Email
      expect(find.text('المتابعة بالبريد الإلكتروني'), findsOneWidget);

      // Terms
      expect(find.textContaining('شروط الاستخدام'), findsOneWidget);
    });

    testWidgets('Tapping Continue with Phone navigates to PhoneInputScreen', (WidgetTester tester) async {
      await tester.pumpWidget(buildAppWidget(child: const WelcomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('المتابعة برقم الجوال'));
      await tester.pumpAndSettle();

      expect(find.byType(PhoneInputScreen), findsOneWidget);
      expect(find.text('أدخل رقم جوالك'), findsOneWidget);
    });

    testWidgets('Tapping Continue with Email navigates to EmailInputScreen', (WidgetTester tester) async {
      await tester.pumpWidget(buildAppWidget(child: const WelcomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('المتابعة بالبريد الإلكتروني'));
      await tester.pumpAndSettle();

      expect(find.byType(EmailInputScreen), findsOneWidget);
      expect(find.text('أدخل بريدك الإلكتروني'), findsOneWidget);
    });

    testWidgets('Tapping Continue with Google opens Google Account Sheet and selects account', (WidgetTester tester) async {
      final auth = AuthProvider.forTesting(useDevMockAuth: true);
      await tester.pumpWidget(buildAppWidget(child: const WelcomeScreen(), auth: auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('المتابعة باستخدام Google'));
      await tester.pumpAndSettle();

      // Verify Google Account bottom sheet appears
      expect(find.text('تسجيل الدخول باستخدام Google'), findsOneWidget);
      expect(find.text('حمد الكواري'), findsOneWidget);
      expect(find.text('hamad.alkuwari@gmail.com'), findsOneWidget);
      expect(find.text('عبدالرحمن المهنا'), findsOneWidget);
      expect(find.text('abdelrahman@mashwar.qa'), findsOneWidget);

      // Tap on Hamad Al-Kuwari
      await tester.tap(find.text('حمد الكواري'));
      await tester.pumpAndSettle();

      // Verifies auth provider updated and navigated to ProfileSetupScreen
      expect(auth.authMethod, 'google');
      expect(auth.email, 'hamad.alkuwari@gmail.com');
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
    });
  });

  group('EmailInputScreen & Switching Tests', () {
    testWidgets('EmailInputScreen mounts with clean field and demo chip', (WidgetTester tester) async {
      await tester.pumpWidget(buildAppWidget(child: const EmailInputScreen()));
      await tester.pumpAndSettle();

      expect(find.text('أدخل بريدك الإلكتروني'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('المتابعة برقم الجوال بدلاً من ذلك'), findsOneWidget);
      expect(find.widgetWithText(MashwarButton, 'إرسال الرمز'), findsOneWidget);
    });

    testWidgets('Email validation triggers on invalid email format', (WidgetTester tester) async {
      await tester.pumpWidget(buildAppWidget(child: const EmailInputScreen()));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'invalid-email');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MashwarButton, 'إرسال الرمز'));
      await tester.pumpAndSettle();

      expect(find.textContaining('أدخل بريد إلكتروني صحيح'), findsOneWidget);
    });

    testWidgets('Submitting valid email sends OTP and navigates to OtpVerificationScreen in email mode', (WidgetTester tester) async {
      final auth = AuthProvider.forTesting(useDevMockAuth: true);
      await tester.pumpWidget(buildAppWidget(child: const EmailInputScreen(), auth: auth));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'student@mashwar.qa');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MashwarButton, 'إرسال الرمز'));
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(find.textContaining('student@mashwar.qa'), findsOneWidget);
      expect(auth.email, 'student@mashwar.qa');
      expect(auth.authMethod, 'email');

      auth.dispose();
    });

    testWidgets('Switch link switches between Phone and Email seamlessly', (WidgetTester tester) async {
      await tester.pumpWidget(buildAppWidget(child: const PhoneInputScreen()));
      await tester.pumpAndSettle();

      // Tap switch to email
      await tester.tap(find.text('المتابعة بالبريد الإلكتروني بدلاً من ذلك'));
      await tester.pumpAndSettle();
      expect(find.byType(EmailInputScreen), findsOneWidget);

      // Tap switch back to phone
      await tester.tap(find.text('المتابعة برقم الجوال بدلاً من ذلك'));
      await tester.pumpAndSettle();
      expect(find.byType(PhoneInputScreen), findsOneWidget);
    });
  });

  group('OtpVerificationScreen with Email Mode Tests', () {
    testWidgets('Renders email address destination and verifies with 6 digits', (WidgetTester tester) async {
      final auth = AuthProvider.forTesting(useDevMockAuth: true);
      await tester.pumpWidget(buildAppWidget(
        child: const OtpVerificationScreen(email: 'user@mashwar.qa'),
        auth: auth,
      ));
      await tester.pumpAndSettle();

      // Subtitle mentions the email
      expect(find.textContaining('user@mashwar.qa'), findsOneWidget);

      // Enter 6-digit OTP code
      await tester.enterText(find.byType(TextField), '482911');
      await tester.pumpAndSettle();

      // Navigated to ProfileSetupScreen
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
    });
  });
}
