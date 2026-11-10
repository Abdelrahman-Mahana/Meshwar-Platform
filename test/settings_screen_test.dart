import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/widgets/mashwar_button.dart';
import 'package:mashwar/screens/settings/settings_screen.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/settings_provider.dart';

void main() {
  Widget buildSettingsWidget({AuthProvider? auth, SettingsProvider? settings}) {
    final authProvider = auth ?? AuthProvider();
    final settingsProvider = settings ?? SettingsProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        title: 'مشوار',
        locale: const Locale('ar', 'EG'),
        home: const SettingsScreen(),
      ),
    );
  }

  testWidgets('SettingsScreen mounts with clean Uber/inDrive minimal layout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSettingsWidget());
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('الإعدادات'), findsOneWidget);

    // Verify User Profile Card
    expect(find.text('عبدالرحمن أحمد'), findsOneWidget);
    expect(find.text('01012345678'), findsOneWidget);
    expect(find.text('تعديل'), findsOneWidget);

    // Verify Section Headers
    expect(find.text('الحساب والتوثيق'), findsOneWidget);
    expect(find.text('التفضيلات وتجربة السفر'), findsOneWidget);
    expect(find.text('إشعارات التطبيق الذكية'), findsOneWidget);
    expect(find.text('الدعم والشروط القانونية'), findsOneWidget);

    // Verify Key Tiles
    expect(find.text('توثيق بطاقة الرقم القومي'), findsOneWidget);
    expect(find.text('بيانات سيارتي ورخص القيادة'), findsOneWidget);
    expect(find.text('محفظة مشوار وطرق الدفع'), findsOneWidget);
    expect(find.text('جهات الاتصال في حالات الطوارئ'), findsOneWidget);
    expect(find.text('لغة التطبيق'), findsOneWidget);
    expect(find.text('الترخيص والامتثال لوزارة النقل'), findsOneWidget);
    expect(find.text('حذف الحساب نهائياً'), findsOneWidget);

    // Verify Version Info & Logout Button
    expect(find.text('مشوار MASHWAR v1.2.0 (Build 42)'), findsOneWidget);
    expect(find.byType(MashwarButton), findsOneWidget);
  });

  testWidgets('Language selection modal bottom sheet opens cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSettingsWidget());
    await tester.pumpAndSettle();

    // Tap on Language tile
    final langTile = find.text('لغة التطبيق');
    expect(langTile, findsOneWidget);
    await tester.tap(langTile);
    await tester.pumpAndSettle();

    // Verify Modal contents
    expect(find.text('اختر لغة التطبيق'), findsOneWidget);
    expect(find.text('العربية (مصر)'), findsOneWidget);
    expect(find.text('English (United States)'), findsOneWidget);

    // Dismiss bottom sheet
    await tester.tap(find.text('العربية (مصر)'));
    await tester.pumpAndSettle();
    expect(find.text('اختر لغة التطبيق'), findsNothing);
  });

  testWidgets('Notification switches toggle correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settingsProvider = SettingsProvider();
    await tester.pumpWidget(buildSettingsWidget(settings: settingsProvider));
    await tester.pumpAndSettle();

    expect(settingsProvider.ridesNotifications, isTrue);

    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(3));

    await tester.tap(switches.first);
    await tester.pumpAndSettle();
    expect(settingsProvider.ridesNotifications, isFalse);
  });

  testWidgets('Minimalist logout dialog opens on button tap', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSettingsWidget());
    await tester.pumpAndSettle();

    final logoutBtn = find.byType(MashwarButton);
    expect(logoutBtn, findsOneWidget);

    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();

    // Verify Logout Alert Dialog
    expect(find.text('هل أنت متأكد من رغبتك في تسجيل الخروج من حساب مشوار؟'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('تأكيد الخروج'), findsOneWidget);

    // Tap cancel
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('هل أنت متأكد من رغبتك في تسجيل الخروج من حساب مشوار؟'), findsNothing);
  });
}
