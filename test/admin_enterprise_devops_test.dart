import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mashwar/admin_main.dart';
import 'package:mashwar/data/models/admin_platform_models.dart';
import 'package:mashwar/data/models/board_ad_model.dart';
import 'package:mashwar/screens/admin/admin_shell.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/settings_provider.dart';

void main() {
  group('Enterprise Admin & DevOps State Engine Tests', () {
    late AdminProvider admin;

    setUp(() {
      admin = AdminProvider();
    });

    test('Extensible 6+ Service Catalog CRUD & Pricing Updates', () {
      expect(admin.servicesCatalog.length, 6);
      final initialLogs = admin.auditLogs.length;

      // Toggle service disabled then enabled
      final target = admin.servicesCatalog.first;
      admin.toggleServiceEnabled(target.id);
      expect(admin.servicesCatalog.first.isEnabled, false);
      expect(admin.auditLogs.length, initialLogs + 1);

      // Update pricing rules
      admin.updateServiceConfig(target.copyWith(commissionPct: 19.5, isEnabled: true));
      expect(admin.servicesCatalog.first.commissionPct, 19.5);
      expect(admin.servicesCatalog.first.isEnabled, true);

      // Add a 7th future service dynamically
      admin.addServiceDefinition(
        const AdminServiceDefinition(
          id: 'svc_ev_assist',
          code: 'ev_assist',
          nameAr: 'شحن متنقل للمركبات الكهربائية',
          nameEn: 'Mobile EV Rescue',
          descriptionAr: 'خدمة طوارئ مستقبلية',
          descriptionEn: 'Future EV rescue service',
          iconName: 'extension',
          accentHex: 0xFF8A1538,
        ),
      );
      expect(admin.servicesCatalog.length, 7);
      expect(admin.servicesCatalog.last.code, 'ev_assist');
    });

    test('Qatar Corridors Status, Incentive Multiplier & Creation', () {
      final first = admin.corridors.first;
      admin.setCorridorStatus(first.id, 'paused');
      expect(admin.corridors.first.status, 'paused');

      admin.setCorridorIncentive(first.id, 1.35);
      expect(admin.corridors.first.incentiveMultiplier, 1.35);

      admin.addCorridor(
        const AdminCorridorNode(
          id: 'cor_custom',
          fromCityAr: 'الشمال',
          fromCityEn: 'Al Shamal',
          toCityAr: 'لوسيل',
          toCityEn: 'Lusail',
          municipalityAr: 'بلدية الشمال',
          municipalityEn: 'Al Shamal Municipality',
        ),
      );
      expect(admin.corridors.last.id, 'cor_custom');
      expect(admin.selectedCorridorId, 'cor_custom');
    });

    test('Bilateral Escrow Lifecycle & Financial Controls', () {
      admin.approveEscrowReceipt('#QA-8503');
      final pending = admin.escrowItems.firstWhere((e) => e.id == '#QA-8503');
      expect(pending.receiptApproved, true);
      expect(pending.status, 'in_transit');

      admin.freezeEscrow('#QA-8524', 'مراجعة فاتورة التوريد');
      expect(admin.escrowItems.firstWhere((e) => e.id == '#QA-8524').status, 'frozen');

      admin.releaseEscrow('#QA-8492', 'تم التسليم بكود 5912');
      expect(admin.escrowItems.firstWhere((e) => e.id == '#QA-8492').status, 'released');

      admin.refundEscrow('#QA-8511', 'تعويض كامل للعميل');
      expect(admin.escrowItems.firstWhere((e) => e.id == '#QA-8511').status, 'refunded');

      final gwId = admin.paymentGateways.first.id;
      admin.togglePaymentGateway(gwId);
      expect(admin.paymentGateways.first.isEnabled, false);
    });

    test('Board Ads, B2B Accounts & User Wallet Reconciliation', () {
      final adId = admin.boardAds.first.id;
      admin.moderateBoardAd(adId, BoardAdStatus.expired, 'انتهاء الحاجة');
      expect(admin.boardAds.first.status, BoardAdStatus.expired);

      final user = admin.users.first;
      final beforeBal = user.walletBalanceQar;
      admin.adjustUserWalletBalance(user.id, 150.0, 'تسوية ضمان مالي');
      expect(admin.users.first.walletBalanceQar, beforeBal + 150.0);

      final b2bCount = admin.b2bAccounts.length;
      admin.addB2BAccount(
        const AdminB2BAccountItem(
          id: 'b2b_new',
          companyAr: 'شركة الدوحة الهندسية',
          companyEn: 'Doha Engineering',
          sectorAr: 'مقاولات',
          sectorEn: 'Construction',
          municipalityAr: 'لوسيل',
          municipalityEn: 'Lusail',
          monthlyRuns: 30,
          creditLimitQar: 12000,
          contactPhone: '44112233',
        ),
      );
      expect(admin.b2bAccounts.length, b2bCount + 1);
    });

    test('DevOps Feature Flags, Health Check & Config JSON Export/Reset/Import Roundtrip', () {
      admin.setEnvironment('staging');
      expect(admin.activeEnvironment, 'staging');

      admin.toggleFeatureFlag('maintenance_mode');
      expect(
        admin.featureFlags.firstWhere((f) => f.key == 'maintenance_mode').isEnabled,
        true,
      );

      admin.updateFeatureFlagRollout('ai_route_matching_v2', 80);
      expect(
        admin.featureFlags.firstWhere((f) => f.key == 'ai_route_matching_v2').rolloutPct,
        80,
      );

      admin.runInfraHealthCheck();
      expect(admin.auditLogs.first.action, 'فحص صحة البنية التحتية');

      admin.updateBroadcastBanner(
        const AdminBroadcastBanner(
          isEnabled: true,
          severity: 'warning',
          messageAr: 'تنبيه صيانة مجدولة',
          messageEn: 'Scheduled maintenance',
        ),
      );

      final exported = admin.exportPlatformConfigJson();
      admin.resetPlatformToDefaults();
      expect(admin.activeEnvironment, 'production');
      expect(admin.broadcastBanner.isEnabled, false);

      final restored = admin.importPlatformConfigJson(exported);
      expect(restored, true);
      expect(admin.activeEnvironment, 'staging');
      expect(admin.broadcastBanner.isEnabled, true);
      expect(
        admin.featureFlags.firstWhere((f) => f.key == 'ai_route_matching_v2').rolloutPct,
        80,
      );
    });

    test('5-Role RBAC & Global Command Search Verification', () {
      admin.setActiveRole(AdminRole.financeAdmin);
      expect(admin.canAccessMenu(0), true);
      expect(admin.canAccessMenu(10), true);
      expect(admin.canAccessMenu(11), false);

      admin.setActiveRole(AdminRole.devopsAdmin);
      expect(admin.canAccessMenu(0), true);
      expect(admin.canAccessMenu(11), true);
      expect(admin.canAccessMenu(10), false);

      admin.setActiveRole(AdminRole.supportAdmin);
      expect(admin.canAccessMenu(12), true);

      admin.setActiveRole(AdminRole.superAdmin);
      final escrowHits = admin.searchGlobal('#QA-8492', true);
      expect(escrowHits.any((r) => r.targetMenuIndex == 10), true);

      final inquiryHits = admin.searchGlobal('qdb.qa', true);
      expect(inquiryHits.any((r) => r.targetMenuIndex == 12), true);
    });

    test('Firebase Investor Inquiries Lifecycle, Filtering & Status Updates', () async {
      final beforeCount = admin.inquiries.length;
      final beforeNew = admin.newInquiriesCount;

      admin.addInquiryRecord(
        const AdminInvestorInquiry(
          id: 'inq_test_99',
          fullName: 'Dr. Hamad Al-Thani',
          organization: 'Doha Ventures',
          email: 'hamad@dohaventures.qa',
          phone: '+97455001122',
          inquiryType: 'Investor Briefing & 3-Year Model Walkthrough',
          notes: 'Interested in QDB tranche schedule',
          lang: 'en',
          source: 'landing_page',
          createdAtIso: '2026-11-24T18:00:00Z',
        ),
      );

      expect(admin.inquiries.length, beforeCount + 1);
      expect(admin.newInquiriesCount, beforeNew + 1);
      expect(admin.inquiries.first.shortRef, 'INQ_TE');

      await admin.updateInquiryStatus('inq_test_99', 'contacted', note: 'Sent deck & model');
      final updated = admin.inquiries.firstWhere((e) => e.id == 'inq_test_99');
      expect(updated.status, 'contacted');
      expect(updated.notes, 'Sent deck & model');
      expect(admin.newInquiriesCount, beforeNew);

      await admin.syncInquiriesFromFirestore();
      expect(admin.inquiriesSyncStatus, isNotNull);
    });
  });

  group('All 13 Admin & DevOps Screens Multi-Viewport Zero-Overflow Tests', () {
    Future<void> pumpModule(
      WidgetTester tester, {
      required int moduleIndex,
      required Size viewport,
      bool isDark = false,
      Locale locale = const Locale('ar', 'QA'),
    }) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adminProvider = AdminProvider()..setDarkMode(isDark);
      final settingsProvider = SettingsProvider()..setLocale(locale);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ],
          child: MaterialApp(
            locale: locale,
            home: AdminShell(initialIndex: moduleIndex),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdminShell), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason:
            'Module $moduleIndex failed on ${viewport.width}x${viewport.height} (dark=$isDark, locale=${locale.languageCode})',
      );
    }

    final viewports = <String, Size>{
      'Compact Mobile 320x640': const Size(320, 640),
      'Mobile 360x780': const Size(360, 780),
      'Tablet 768x1024': const Size(768, 1024),
      'Desktop 1440x900': const Size(1440, 900),
    };

    for (final entry in viewports.entries) {
      testWidgets('All 13 Modules render with zero overflow on ${entry.key}', (tester) async {
        for (int idx = 0; idx < 13; idx++) {
          await pumpModule(tester, moduleIndex: idx, viewport: entry.value);
        }
      });
    }

    testWidgets('Dark NOC Mode & English LTR render cleanly on Desktop and Mobile', (tester) async {
      for (final idx in [0, 8, 9, 10, 11, 12]) {
        await pumpModule(
          tester,
          moduleIndex: idx,
          viewport: const Size(1440, 900),
          isDark: true,
          locale: const Locale('en', 'US'),
        );
        await pumpModule(
          tester,
          moduleIndex: idx,
          viewport: const Size(360, 780),
          isDark: true,
          locale: const Locale('en', 'US'),
        );
      }
    });

    testWidgets('MashwarAdminWebApp boots cleanly into Light & Dark modes', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MashwarAdminWebApp());
      await tester.pumpAndSettle();
      expect(find.byType(AdminShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
