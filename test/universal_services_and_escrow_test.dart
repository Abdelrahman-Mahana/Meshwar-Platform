import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/screens/board/post_ad_screen.dart';
import 'package:mashwar/screens/escrow/service_escrow_screen.dart';
import 'package:mashwar/screens/home/home_screen.dart';
import 'package:mashwar/screens/worksite/create_work_request_screen.dart';
import 'package:mashwar/screens/worksite/work_requests_feed_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

void main() {
  Widget wrapWithProviders(Widget child, {SettingsProvider? settings}) {
    final settingsProvider = settings ?? SettingsProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

  group('Universal Qatari Community Services & Bilateral Escrow Tests', () {
    testWidgets('HomeScreen displays 3-Service international prompt and primary/secondary CTAs', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('إلى أين مشوارك أو طلبك اليوم؟'), findsOneWidget);
      expect(find.text('إنشاء طلب توريد'), findsOneWidget);
      expect(find.text('تصفح الطلبات المتاحة'), findsOneWidget);
      expect(find.text('شراء وتوريد ومهام خاصة'), findsOneWidget);

      final browseBtn = find.text('تصفح الطلبات المتاحة');
      await tester.ensureVisible(browseBtn);
      await tester.pumpAndSettle();
      await tester.tap(browseBtn);
      await tester.pumpAndSettle();
      expect(find.byType(WorkRequestsFeedScreen), findsOneWidget);
    });

    testWidgets('ServiceEscrowScreen handles role toggle, receipt approval, OTP release & responsive viewports', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final size in [const Size(320, 568), const Size(375, 812), const Size(1280, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithProviders(const ServiceEscrowScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(wrapWithProviders(const ServiceEscrowScreen()));
      await tester.pumpAndSettle();

      // 1. Toggle Provider Shield perspective
      await tester.tap(find.text('حماية منفّذ الخدمة'));
      await tester.pumpAndSettle();
      expect(find.text('مستحقاتك + ميزانية الشراء محجوزة مسبقاً'), findsOneWidget);

      // 2. Approve store receipt & photo
      await tester.ensureVisible(find.text('اعتماد الفاتورة وصورة الغرض'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اعتماد الفاتورة وصورة الغرض'));
      await tester.pumpAndSettle();
      expect(find.text('تم اعتماد الفاتورة وصورة الغرض ✓'), findsOneWidget);

      // 3. Fill demo OTP 4829 and release Escrow
      await tester.ensureVisible(find.text('تعبئة 4829'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعبئة 4829'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('تأكيد الكود وتحرير المستحقات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد الكود وتحرير المستحقات'));
      await tester.pumpAndSettle();
      expect(find.textContaining('تم التسليم وتحرير مبلغ الضمان بنجاح'), findsOneWidget);

      // 4. Interactive post-completion star rating
      await tester.ensureVisible(find.text('إرسال'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إرسال'));
      await tester.pumpAndSettle();
      expect(find.textContaining('شكراً! تم تسجيل تقييمك'), findsOneWidget);
    });

    testWidgets('HomeScreen Worksite Supply category shortcut opens pre-selected CreateWorkRequestScreen', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final electricalBtn = find.text('كهرباء وكابلات');
      await tester.ensureVisible(electricalBtn);
      await tester.pumpAndSettle();
      await tester.tap(electricalBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CreateWorkRequestScreen), findsOneWidget);
      expect(find.text('إنشاء طلب توريد موقع'), findsOneWidget);
    });

    testWidgets('PostAdScreen renders Qatari phrasing (من وين؟) and 1-tap quick templates', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const PostAdScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('نقطة الانطلاق (من وين؟)'), findsOneWidget);
      expect(find.text('توريد لموقع هندسي'), findsOneWidget);
      expect(find.text('توصيل ومشوار يومي'), findsOneWidget);

      await tester.tap(find.text('توريد لموقع هندسي'));
      await tester.pumpAndSettle();
      expect(find.text('تفاصيل البضاعة والتوريد'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
    });
  });
}
