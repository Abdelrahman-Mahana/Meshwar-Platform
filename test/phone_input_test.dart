import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/screens/auth/phone_input_screen.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/settings_provider.dart';

void main() {
  Widget buildPhoneWidget({AuthProvider? auth, SettingsProvider? settings}) {
    final authProvider = auth ?? AuthProvider();
    final settingsProvider = settings ?? SettingsProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: const MaterialApp(
        locale: Locale('ar', 'QA'),
        home: PhoneInputScreen(),
      ),
    );
  }

  testWidgets('PhoneInputScreen mounts with Qatari country badge (+974) and clean layout', (WidgetTester tester) async {
    await tester.pumpWidget(buildPhoneWidget());
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('أدخل رقم جوالك'), findsOneWidget);
    expect(find.text('سنرسل لك رمز تحقق عبر رسالة SMS'), findsOneWidget);

    // Verify Country Code Badge
    expect(find.text('QA'), findsOneWidget);
    expect(find.text('+974'), findsOneWidget);

    // Verify Helper text
    expect(find.text('رقم جوال قطري (Ooredoo / Vodafone) يبدأ بـ 3 أو 5 أو 6 أو 7'), findsOneWidget);

    // Verify Button
    expect(find.text('إرسال الرمز'), findsOneWidget);
  });

  testWidgets('Normalizes Arabic numerals to standard digits in phone field', (WidgetTester tester) async {
    await tester.pumpWidget(buildPhoneWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Clear existing text and enter Arabic numerals
    await tester.enterText(textField, '٥٥٩٨٧٦٥٤');
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(textField).controller?.text, '55987654');
  });

  testWidgets('Validation error triggers on invalid Qatari phone', (WidgetTester tester) async {
    await tester.pumpWidget(buildPhoneWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Enter invalid number (invalid prefix for Qatar)
    await tester.enterText(textField, '41234567');
    await tester.pumpAndSettle();

    await tester.tap(find.text('إرسال الرمز'));
    await tester.pumpAndSettle();

    expect(find.text('الرقم يجب أن يتكون من 8 أرقام ويبدأ بـ 3 أو 5 أو 6 أو 7'), findsOneWidget);
  });
}
