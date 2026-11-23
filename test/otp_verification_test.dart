import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/widgets/mashwar_button.dart';
import 'package:mashwar/screens/auth/otp_verification_screen.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/settings_provider.dart';

void main() {
  Widget buildOtpWidget({AuthProvider? auth, SettingsProvider? settings}) {
    final authProvider = auth ?? AuthProvider();
    final settingsProvider = settings ?? SettingsProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: const MaterialApp(
        locale: Locale('ar', 'QA'),
        home: OtpVerificationScreen(),
      ),
    );
  }

  testWidgets('OtpVerificationScreen mounts with 6 empty boxes and clean Uber layout', (WidgetTester tester) async {
    await tester.pumpWidget(buildOtpWidget());
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('أدخل رمز التحقق'), findsOneWidget);
    expect(find.textContaining('أرسلنا رمزاً من 6 أرقام إلى'), findsOneWidget);

    // Verify single transparent TextField
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    expect(tester.widget<TextField>(textField).controller?.text, isEmpty);

    // Verify Confirm button and no Demo chip
    expect(find.textContaining('Demo'), findsNothing);
    expect(find.widgetWithText(MashwarButton, 'تأكيد'), findsOneWidget);
  });

  testWidgets('Typing Arabic-Indic numerals automatically normalizes to standard digits', (WidgetTester tester) async {
    await tester.pumpWidget(buildOtpWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Enter Arabic numerals '٤١'
    await tester.enterText(textField, '٤١');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(textField).controller?.text, '41');

    // Verify digits rendered in visual cells
    expect(find.text('4'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Punctuation and non-digits are strictly rejected', (WidgetTester tester) async {
    await tester.pumpWidget(buildOtpWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Try to enter punctuation '؛' and '؟' and '.'
    await tester.enterText(textField, '؛؟.');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(textField).controller?.text, isEmpty);
  });

  testWidgets('Pasting a 6-digit code distributes across all 6 boxes', (WidgetTester tester) async {
    await tester.pumpWidget(buildOtpWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Paste full 6 digits
    await tester.enterText(textField, '482911');
    await tester.pump();

    // Verify code entered
    expect(find.text('4'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));

    await tester.pumpAndSettle(const Duration(milliseconds: 700));
  });
}
