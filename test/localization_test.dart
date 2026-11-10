import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/widgets/mashwar_badge.dart';
import 'package:mashwar/core/widgets/mashwar_button.dart';
import 'package:mashwar/core/widgets/mashwar_chip.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/auth_provider.dart';

void main() {
  group('MASHWAR Bidirectional Localization & DB Data Preservation Tests', () {
    test('UI strings translate between Arabic and English accurately', () {
      // 1. Egyptian Cities translation
      expect(AppStrings.translateCity('القاهرة', isArabic: false), 'Cairo');
      expect(AppStrings.translateCity('Cairo', isArabic: true), 'القاهرة');
      expect(AppStrings.translateCity('الإسكندرية', isArabic: false), 'Alexandria');
      expect(AppStrings.translateCity('كفر الشيخ', isArabic: false), 'Kafr El-Sheikh');
      expect(AppStrings.translateCity('طنطا', isArabic: false), 'Tanta');

      // 2. Egyptian Routes translation
      expect(AppStrings.translateRoute('كفر الشيخ ← القاهرة', isArabic: false), 'Kafr El-Sheikh → Cairo');
      expect(AppStrings.translateRoute('Kafr El-Sheikh → Cairo', isArabic: true), 'كفر الشيخ ← القاهرة');

      // 3. Statuses and Badges translation
      expect(AppStrings.translateStatus('موثق', isArabic: false), 'Verified');
      expect(AppStrings.translateStatus('Verified', isArabic: true), 'موثق');
      expect(AppStrings.translateStatus('قيد المراجعة', isArabic: false), 'Under Review');
      expect(AppStrings.translateStatus('في الطريق', isArabic: false), 'In Transit');
      expect(AppStrings.translateStatus('تم التسليم', isArabic: false), 'Delivered');

      // 4. Dates & Times translation
      expect(AppStrings.translateDate('الجمعة 6 نوفمبر، 7:30 ص', isArabic: false), 'Fri 6 Nov, 7:30 AM');
      expect(AppStrings.translateDate('Fri 6 Nov, 7:30 AM', isArabic: true), 'الجمعة 6 نوفمبر، 7:30 ص');

      // 5. Common UI Buttons & phrases
      expect(AppStrings.translate('تأكيد الحجز', isArabic: false), 'Confirm Booking');
      expect(AppStrings.translate('Confirm Booking', isArabic: true), 'تأكيد الحجز');
      expect(AppStrings.translate('تسجيل الخروج', isArabic: false), 'Log Out');
      expect(AppStrings.translate('إعدادات التطبيق', isArabic: false), 'App Settings');
      expect(AppStrings.translate('توثيق بطاقة الرقم القومي', isArabic: false), 'National ID Verification');
    });

    test('Primary customer data from DB is NEVER translated or corrupted', () {
      const customerFullName = 'محمد سعيد';
      const customerPhone = '01012345678';
      const nationalId = '29810150102934';
      const licensePlate = 'س ق ر 1942';
      const driverName = 'عبدالرحمن أحمد';
      const customPickupPoint = 'أمام محطة قطار طنطا، بجوار بنك مصر';

      // Verify that translation lookups return customer data strictly as-is
      expect(AppStrings.translate(customerFullName, isArabic: false), customerFullName);
      expect(AppStrings.translate(customerPhone, isArabic: false), customerPhone);
      expect(AppStrings.translate(nationalId, isArabic: false), nationalId);
      expect(AppStrings.translate(licensePlate, isArabic: false), licensePlate);
      expect(AppStrings.translate(driverName, isArabic: false), driverName);
      expect(AppStrings.translate(customPickupPoint, isArabic: false), customPickupPoint);

      // Verify in Arabic mode as well
      expect(AppStrings.translate(customerFullName, isArabic: true), customerFullName);
      expect(AppStrings.translate(driverName, isArabic: true), driverName);
    });

    testWidgets('Reactive widgets update on language switch while preserving DB fields', (WidgetTester tester) async {
      final settings = SettingsProvider();
      final auth = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: auth),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Standard localized UI button
                  const MashwarButton(text: 'تأكيد الحجز'),
                  // Standard localized badge
                  const MashwarBadge(type: BadgeType.verified),
                  // Standard localized chip
                  const MashwarChip(label: 'سيدات فقط', isSelected: true),
                  // Customer DB raw data displayed directly
                  Consumer<AuthProvider>(
                    builder: (context, a, _) => Column(
                      children: [
                        Text('Customer: ${a.user.fullName}'),
                        Text('Phone: ${a.user.phone}'),
                        Text('ID: ${a.user.nationalId}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 1. Initial Arabic Mode
      expect(find.text('تأكيد الحجز'), findsOneWidget);
      expect(find.text('موثق'), findsOneWidget);
      expect(find.text('سيدات فقط'), findsOneWidget);
      expect(find.text('Customer: عبدالرحمن أحمد'), findsOneWidget);
      expect(find.text('Phone: 01012345678'), findsOneWidget);
      expect(find.text('ID: 29810150102934'), findsOneWidget);

      // 2. Switch Language to English
      settings.setLocale(const Locale('en', 'US'));
      await tester.pumpAndSettle();

      // UI labels should flip to English
      expect(find.text('Confirm Booking'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Ladies Only'), findsOneWidget);

      // Customer DB fields MUST stay 100% intact!
      expect(find.text('Customer: عبدالرحمن أحمد'), findsOneWidget);
      expect(find.text('Phone: 01012345678'), findsOneWidget);
      expect(find.text('ID: 29810150102934'), findsOneWidget);

      // 3. Switch Language back to Arabic
      settings.setLocale(const Locale('ar', 'EG'));
      await tester.pumpAndSettle();

      // UI labels should flip back to Arabic
      expect(find.text('تأكيد الحجز'), findsOneWidget);
      expect(find.text('موثق'), findsOneWidget);
      expect(find.text('سيدات فقط'), findsOneWidget);

      // Customer DB fields continue to be intact
      expect(find.text('Customer: عبدالرحمن أحمد'), findsOneWidget);
      expect(find.text('Phone: 01012345678'), findsOneWidget);
      expect(find.text('ID: 29810150102934'), findsOneWidget);
    });
  });
}
