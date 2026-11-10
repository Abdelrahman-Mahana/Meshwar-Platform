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
        locale: Locale('ar', 'EG'),
        home: PhoneInputScreen(),
      ),
    );
  }

  testWidgets('PhoneInputScreen mounts with Egyptian country badge (+20) and clean layout', (WidgetTester tester) async {
    await tester.pumpWidget(buildPhoneWidget());
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('أدخل رقم موبايلك'), findsOneWidget);
    expect(find.text('هنبعتلك كود تأكيد عبر رسالة SMS'), findsOneWidget);

    // Verify Country Code Badge
    expect(find.text('🇪🇬'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);

    // Verify Helper text
    expect(find.text('رقم مصري يبدأ بـ 010 أو 011 أو 012 أو 015'), findsOneWidget);

    // Verify Button
    expect(find.text('إرسال الكود'), findsOneWidget);
  });

  testWidgets('Normalizes Arabic numerals to standard digits in phone field', (WidgetTester tester) async {
    await tester.pumpWidget(buildPhoneWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Clear existing text and enter Arabic numerals
    await tester.enterText(textField, '٠١٠٩٨٧٦٥٤٣٢');
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(textField).controller?.text, '01098765432');
  });

  testWidgets('Validation error triggers on invalid Egyptian phone', (WidgetTester tester) async {
    await tester.pumpWidget(buildPhoneWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Enter invalid number (less than 11 digits or invalid prefix)
    await tester.enterText(textField, '01999999999');
    await tester.pumpAndSettle();

    await tester.tap(find.text('إرسال الكود'));
    await tester.pumpAndSettle();

    expect(find.text('الرقم لازم يكون 11 رقم ويبدأ بـ 010 أو 011 أو 012 أو 015'), findsOneWidget);
  });
}
