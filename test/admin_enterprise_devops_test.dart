import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mashwar/admin_main.dart';
import 'package:mashwar/data/models/admin_platform_models.dart';
import 'package:mashwar/data/models/board_ad_model.dart';
import 'package:mashwar/data/models/worksite_models.dart';
import 'package:mashwar/screens/admin/admin_login_screen.dart';
import 'package:mashwar/screens/admin/admin_shell.dart';
import 'package:mashwar/screens/admin/admin_worksite_ops_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/settings_provider.dart';

class _FakeAdminBackendGateway implements AdminBackendGateway {
  bool signedOutCalled = false;
  AdminAuthSessionResult? activeSession;
  Map<String, dynamic>? staffDoc;
  final List<String> events = [];
  final List<Map<String, dynamic>> writtenAuditLogs = [];
  final List<Map<String, dynamic>> reviewedProviders = [];
  final List<Map<String, dynamic>> moderatedRequests = [];
  bool shouldThrowOnSignIn = false;

  @override
  Future<AdminAuthSessionResult> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (shouldThrowOnSignIn) {
      throw StateError('invalid-credential');
    }
    final session = AdminAuthSessionResult(
      uid: 'staff_uid_1',
      email: email,
      displayName: 'Noura Al-Kuwari',
      idToken: 'fake-id-token',
    );
    activeSession = session;
    events.add('signIn');
    return session;
  }

  @override
  Future<void> signOut() async {
    signedOutCalled = true;
    activeSession = null;
    events.add('signOut');
  }

  @override
  AdminAuthSessionResult? currentSession() => activeSession;

  @override
  Future<Map<String, dynamic>?> fetchAdminStaffRecord(String uid) async {
    return staffDoc;
  }

  @override
  Future<void> writeAuditLog(Map<String, dynamic> payload) async {
    events.add('writeAuditLog:${payload['action']}');
    writtenAuditLogs.add(payload);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAuditLogs({int limit = 100}) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> fetchProviderProfiles({
    int limit = 100,
  }) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> fetchProviderVerifications({
    int limit = 100,
  }) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> fetchWorkRequests({
    int limit = 100,
  }) async =>
      const [];

  @override
  Future<Map<String, dynamic>> callAdminReviewProvider({
    required String providerId,
    required String decision,
    required String reviewerId,
    String? reason,
  }) async {
    reviewedProviders.add({
      'providerId': providerId,
      'decision': decision,
      'reviewerId': reviewerId,
      'reason': reason,
    });
    return {'providerId': providerId, 'approvalStatus': decision};
  }

  @override
  Future<Map<String, dynamic>> callAdminModerateWorkRequest({
    required String requestId,
    required String action,
    required String adminUid,
    String? targetStatus,
    String? reason,
  }) async {
    moderatedRequests.add({
      'requestId': requestId,
      'action': action,
      'adminUid': adminUid,
      'targetStatus': targetStatus,
      'reason': reason,
    });
    return {'requestId': requestId, 'action': action};
  }
}

void main() {
  group('Enterprise Admin & DevOps State Engine Tests', () {
    late AdminProvider admin;

    setUp(() {
      admin = AdminProvider.forTesting();
    });

    test('Firebase Staff Auth enforces admin_staff/{uid} active check, server role, and audit logs', () async {
      final gateway = _FakeAdminBackendGateway();
      final prodAdmin = AdminProvider(backendGateway: gateway);

      expect(prodAdmin.isLoggedIn, isFalse);
      expect(prodAdmin.canSwitchRoleLocally, isFalse);

      // 1. Missing or inactive admin_staff record fails closed and signs out
      gateway.staffDoc = {'id': 'staff_uid_1', 'isActive': false, 'role': 'superAdmin'};
      final inactiveResult = await prodAdmin.signInStaffWithFirebase(
        'inactive@mashwar.qa',
        'StrongPass!23',
      );
      expect(inactiveResult, isFalse);
      expect(prodAdmin.isLoggedIn, isFalse);
      expect(gateway.signedOutCalled, isTrue);

      // 2. Active admin_staff record assigns server-stored role and logs admin_login
      gateway.signedOutCalled = false;
      gateway.staffDoc = {
        'id': 'staff_uid_1',
        'name': 'نورة الكواري',
        'email': 'noura.reviewer@mashwar.qa',
        'role': 'reviewAdmin',
        'isActive': true,
      };
      final ok = await prodAdmin.signInStaffWithFirebase(
        'noura.reviewer@mashwar.qa',
        'StrongPass!23',
      );
      expect(ok, isTrue);
      expect(prodAdmin.isLoggedIn, isTrue);
      expect(prodAdmin.activeRole, AdminRole.reviewAdmin);
      expect(gateway.writtenAuditLogs.last['action'], 'admin_login');

      // Client-side role spoofing MUST be ignored in production
      prodAdmin.setActiveRole(AdminRole.superAdmin);
      expect(prodAdmin.activeRole, AdminRole.reviewAdmin);

      // 3. Logout records admin_logout BEFORE calling Firebase signOut
      await prodAdmin.logout();
      expect(prodAdmin.isLoggedIn, isFalse);
      expect(gateway.signedOutCalled, isTrue);
      expect(gateway.writtenAuditLogs.last['action'], 'admin_logout');
      final logoutIdx = gateway.events.lastIndexOf('writeAuditLog:admin_logout');
      final signOutIdx = gateway.events.lastIndexOf('signOut');
      expect(logoutIdx, greaterThan(-1));
      expect(signOutIdx, greaterThan(logoutIdx));
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

    test('Module 13 Worksite Supply Ops: provider KYC, payment proof settlement, dispute moderation & audit logs', () async {
      final beforeAuditCount = admin.auditLogs.length;
      final beforePending = admin.pendingVerificationsCount;
      expect(beforePending, greaterThanOrEqualTo(2));
      expect(admin.canAccessMenu(13), isTrue);

      // RBAC check for Module 13
      admin.setActiveRole(AdminRole.reviewAdmin);
      expect(admin.canAccessMenu(13), isTrue);
      admin.setActiveRole(AdminRole.financeAdmin);
      expect(admin.canAccessMenu(13), isTrue);
      admin.setActiveRole(AdminRole.devopsAdmin);
      expect(admin.canAccessMenu(13), isFalse);
      admin.setActiveRole(AdminRole.superAdmin);

      // SearchGlobal finds Module 13 worksite providers & requests
      final qidHits = admin.searchGlobal('28963401842', true);
      expect(qidHits.any((r) => r.targetMenuIndex == 13), isTrue);
      final reqHits = admin.searchGlobal('req_ws_901', true);
      expect(reqHits.any((r) => r.targetMenuIndex == 13), isTrue);

      // 1. Rejecting without reason must fail
      final emptyRejectOk = await admin.reviewWorksiteProvider(
        userId: 'prov_101',
        decision: ProviderApprovalStatus.rejected,
        reason: '   ',
      );
      expect(emptyRejectOk, isFalse);

      // 2. Approving provider updates status, decrements pending count, and logs audit
      final approveOk = await admin.reviewWorksiteProvider(
        userId: 'prov_101',
        decision: ProviderApprovalStatus.approved,
      );
      expect(approveOk, isTrue);
      expect(admin.pendingVerificationsCount, beforePending - 1);
      expect(
        admin.worksiteProviders
            .firstWhere((p) => p.profile.userId == 'prov_101')
            .profile
            .approvalStatus,
        ProviderApprovalStatus.approved,
      );
      expect(admin.auditLogs.length, beforeAuditCount + 1);
      expect(admin.auditLogs.first.action, 'provider_review');

      // 3. Suspending provider requires mandatory reason and logs audit
      final suspendOk = await admin.reviewWorksiteProvider(
        userId: 'prov_102',
        decision: ProviderApprovalStatus.suspended,
        reason: 'انتهاء صلاحية استمارة المركبة',
      );
      expect(suspendOk, isTrue);
      expect(
        admin.worksiteProviders
            .firstWhere((p) => p.profile.userId == 'prov_102')
            .profile
            .approvalStatus,
        ProviderApprovalStatus.suspended,
      );

      // 4. Verify transfer_proof_submitted -> verified_settled with transaction reference
      final emptyRefOk = await admin.verifyWorksitePaymentSettlement(
        requestId: 'req_ws_901',
        transactionReference: '',
      );
      expect(emptyRefOk, isFalse);

      final settleOk = await admin.verifyWorksitePaymentSettlement(
        requestId: 'req_ws_901',
        transactionReference: 'QNB-2026-99101',
      );
      expect(settleOk, isTrue);
      final settledReq =
          admin.worksiteRequests.firstWhere((r) => r.id == 'req_ws_901');
      expect(
        settledReq.paymentSettlementStatus,
        PaymentSettlementStatus.verifiedSettled,
      );
      expect(settledReq.paymentReference, 'QNB-2026-99101');
      expect(admin.auditLogs.first.action, 'verify_payment_settled');

      // Once verified_settled, cannot be re-verified or overwritten
      final reSettleOk = await admin.verifyWorksitePaymentSettlement(
        requestId: 'req_ws_901',
        transactionReference: 'QNB-2026-TAMPER',
      );
      expect(reSettleOk, isFalse);

      // 5. Resolve disputed request with mandatory reason
      final resolveOk = await admin.moderateWorksiteRequestDispute(
        requestId: 'req_ws_902',
        action: 'resolve_dispute',
        targetStatus: WorkRequestStatus.inTransit,
        reason: 'تم الاتفاق مع المورد على استبدال الصمامات',
      );
      expect(resolveOk, isTrue);
      expect(
        admin.worksiteRequests
            .firstWhere((r) => r.id == 'req_ws_902')
            .status,
        WorkRequestStatus.inTransit,
      );
      expect(admin.auditLogs.first.action, 'moderate_resolve_dispute');
    });
  });

  group('Auth-Guarded AdminShell & Login Security Tests', () {
    testWidgets('Unauthenticated /admin route and AdminShell render AdminLoginScreen directly without sidebar or prefilled creds', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final unauthAdmin = AdminProvider();
      expect(unauthAdmin.isLoggedIn, isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider<AdminProvider>.value(value: unauthAdmin),
          ],
          child: MaterialApp(
            initialRoute: '/admin',
            routes: {
              '/admin': (_) => const AdminShell(),
              '/admin-login': (_) => const AdminLoginScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must render AdminLoginScreen directly instead of AdminShell modules/sidebar
      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.text('مشوار · الإدارة'), findsNothing);
      expect(find.text('لوحة الأرقام'), findsNothing);

      // No prefilled admin@mashwar.example or 12345678 and no client role chips in non-dev-mock mode
      expect(find.text('admin@mashwar.example'), findsNothing);
      expect(find.text('12345678'), findsNothing);
      expect(find.text('Super Admin'), findsNothing);
      expect(find.text('مشرف أول'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('All 14 Admin & DevOps Screens Multi-Viewport Zero-Overflow Tests', () {
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

      final adminProvider = AdminProvider.forTesting(isDarkMode: isDark);
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
      testWidgets('All 14 Modules render with zero overflow on ${entry.key}', (tester) async {
        for (int idx = 0; idx < 14; idx++) {
          await pumpModule(tester, moduleIndex: idx, viewport: entry.value);
        }
      });
    }

    testWidgets('Dark NOC Mode & English LTR render cleanly on Desktop and Mobile', (tester) async {
      for (final idx in [0, 8, 9, 10, 11, 12, 13]) {
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

    testWidgets('Module 13 AdminWorksiteOpsScreen interactive provider approval & audit log flow', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adminProvider = AdminProvider.forTesting();
      final settingsProvider = SettingsProvider()..setLocale(const Locale('en', 'US'));
      final initialLogs = adminProvider.auditLogs.length;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ],
          child: const MaterialApp(
            locale: Locale('en', 'US'),
            home: AdminShell(initialIndex: 13),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdminWorksiteOpsScreen), findsOneWidget);
      expect(find.text('حمد سعيد الكواري'), findsOneWidget);

      // Open Review KYC dialog for first pending provider and approve
      final reviewBtn = find.text('Review KYC').first;
      await tester.ensureVisible(reviewBtn);
      await tester.pumpAndSettle();
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();

      expect(find.text('28963401842 (Valid 11-digit)'), findsOneWidget);
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(adminProvider.auditLogs.length, initialLogs + 1);
      expect(adminProvider.auditLogs.first.action, 'provider_review');
      expect(adminProvider.pendingVerificationsCount, 1);

      // Switch to Tab B (Requests & Payments) and Tab C (Privileged Audit Trail)
      final tabB = find.textContaining('Requests & Payments');
      await tester.ensureVisible(tabB);
      await tester.tap(tabB);
      await tester.pumpAndSettle();
      expect(find.textContaining('req_ws_901'), findsOneWidget);

      final tabC = find.textContaining('Privileged Audit Trail');
      await tester.ensureVisible(tabC);
      await tester.tap(tabC);
      await tester.pumpAndSettle();
      expect(find.text('provider_review'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MashwarAdminWebApp boots cleanly into Light & Dark modes when authenticated', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MashwarAdminWebApp(adminProvider: AdminProvider.forTesting()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdminShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
