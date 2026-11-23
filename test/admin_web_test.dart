import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mashwar/admin_main.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/screens/admin/admin_shell.dart';

void main() {
  group('Admin Control Panel Business Logic Tests (Pages 68-77)', () {
    late AdminProvider admin;

    setUp(() {
      admin = AdminProvider();
    });

    test('Initial Admin State and Default Stats', () {
      expect(admin.isLoggedIn, true);
      expect(admin.activeRole, AdminRole.superAdmin);
      expect(admin.currentPeriod, '7 أيام');
      expect(admin.kpiNewUsers, 128);
      expect(admin.kpiPublishedRides, 342);
      expect(admin.kpiConfirmedBookings, 215);
      expect(admin.kpiDeliveredParcels, 87);
      expect(admin.kpiConversionRate, 'نسبة التحويل 41%');
      expect(admin.kpiParcelSuccessRate, 'نجاح 95%');
    });

    test('Dynamic KPI Stats Scale by Period', () {
      admin.setPeriod('اليوم');
      expect(admin.kpiNewUsers, 18);
      expect(admin.kpiPublishedRides, 45);

      admin.setPeriod('30 يوم');
      expect(admin.kpiNewUsers, 540);
      expect(admin.kpiPublishedRides, 1420);
    });

    test('Role-Based Access Control Matrix (Page 77)', () {
      // Super Admin: access to all 8 screens (0 to 7)
      admin.setActiveRole(AdminRole.superAdmin);
      for (int i = 0; i < 8; i++) {
        expect(admin.canAccessMenu(i), true);
      }

      // Review Admin: only Dashboard (0) and Driver Verifications (1)
      admin.setActiveRole(AdminRole.reviewAdmin);
      expect(admin.canAccessMenu(0), true);
      expect(admin.canAccessMenu(1), true);
      expect(admin.canAccessMenu(2), false); // Users locked
      expect(admin.canAccessMenu(3), false); // Rides locked
      expect(admin.canAccessMenu(4), false); // Disputes locked
      expect(admin.canAccessMenu(5), false); // Settings locked
      expect(admin.canAccessMenu(6), false); // Staff locked
      expect(admin.canAccessMenu(7), false); // Audit locked

      // Support Admin: Dashboard (0), Users (2), Rides (3), Disputes (4)
      admin.setActiveRole(AdminRole.supportAdmin);
      expect(admin.canAccessMenu(0), true);
      expect(admin.canAccessMenu(1), false); // Driver verifications locked
      expect(admin.canAccessMenu(2), true);  // Users accessible
      expect(admin.canAccessMenu(3), true);  // Rides accessible
      expect(admin.canAccessMenu(4), true);  // Disputes accessible
      expect(admin.canAccessMenu(5), false); // Settings locked
      expect(admin.canAccessMenu(6), false); // Staff locked
      expect(admin.canAccessMenu(7), false); // Audit locked
    });

    test('Driver Verification Approval and Rejection Audit Trail (Pages 70-71)', () {
      final initialLogsCount = admin.auditLogs.length;

      // Approve driver
      admin.acceptDriver('req_1');
      final approvedReq = admin.driverRequests.firstWhere((r) => r.id == 'req_1');
      expect(approvedReq.status, 'مقبولة');
      expect(admin.auditLogs.length, initialLogsCount + 1);
      expect(admin.auditLogs.first.action, 'قبول سائق');
      expect(admin.auditLogs.first.target, contains(approvedReq.driverName));

      // Reject driver with specific reason
      admin.rejectDriver('req_2', 'صورة رخصة القيادة غير واضحة', 'أعد التصوير بدقة');
      final rejectedReq = admin.driverRequests.firstWhere((r) => r.id == 'req_2');
      expect(rejectedReq.status, 'مرفوضة');
      expect(rejectedReq.rejectionReason, 'صورة رخصة القيادة غير واضحة');
      expect(admin.auditLogs.first.action, 'رفض توثيق سائق');
    });

    test('User Ban with Reason and Unban (Page 72)', () {
      final user = admin.users.firstWhere((u) => u.id == 'user_1');
      expect(user.status, 'نشط');

      admin.banUser('user_1', 'مخالفة معايير الأمان 3 مرات');
      expect(user.status, 'محظور');
      expect(admin.auditLogs.first.action, 'حظر مستخدم');
      expect(admin.auditLogs.first.beforeAfter, contains('مخالفة معايير الأمان'));

      admin.unbanUser('user_1');
      expect(user.status, 'نشط');
      expect(admin.auditLogs.first.action, 'رفع الإيقاف');
    });

    test('Ride Manual Status Override with Mandatory Reason (Page 73)', () {
      final ride = admin.rides.first;
      final prevStatus = ride.status;

      admin.manualUpdateRideStatus(ride.id, 'ملغاة', 'عطل مفاجئ بالسيارة قبل الانطلاق');
      expect(ride.status, 'ملغاة');
      expect(ride.statusOverrideReason, 'عطل مفاجئ بالسيارة قبل الانطلاق');
      expect(admin.auditLogs.first.action, 'تعديل حالة رحلة يدوياً');
      expect(admin.auditLogs.first.beforeAfter, contains(prevStatus));
      expect(admin.auditLogs.first.beforeAfter, contains('ملغاة'));
    });

    test('Dispute Assignment and Resolution Workflow (Page 74)', () {
      final dispute = admin.disputes.firstWhere((d) => d.id == '#5127');
      expect(dispute.status, 'مفتوح');
      expect(dispute.assignedTo, isNull);

      // Assign to staff
      admin.assignDispute(dispute.id, 'أحمد (مشرف مراجعة)');
      expect(dispute.assignedTo, 'أحمد (مشرف مراجعة)');
      expect(dispute.status, 'قيد المراجعة');
      expect(dispute.timeline.last, contains('تم إسناد البلاغ'));
      expect(admin.auditLogs.first.action, 'إسناد بلاغ لموظف');

      // Resolve dispute
      admin.resolveDispute(dispute.id, 'حل وتعويض', 'تم تعويض المتضرر 300 ر.ق');
      expect(dispute.status, 'محلول');
      expect(dispute.resolutionDecision, 'حل وتعويض');
      expect(admin.auditLogs.first.action, 'حل نزاع وبلاغ');
    });

    test('Staff Management and Role Editing (Page 77)', () {
      final initialCount = admin.staff.length;

      // Add new staff
      admin.addStaff('نورة الكواري', 'noura@mashwar.qa', AdminRole.supportAdmin);
      expect(admin.staff.length, initialCount + 1);
      final newMember = admin.staff.last;
      expect(newMember.name, 'نورة الكواري');
      expect(newMember.role, AdminRole.supportAdmin);
      expect(admin.auditLogs.first.action, 'إضافة موظف جديد');

      // Edit staff role & active status
      admin.editStaff(newMember.id, newRole: AdminRole.superAdmin, isActive: false);
      final updatedMember = admin.staff.firstWhere((s) => s.id == newMember.id);
      expect(updatedMember.role, AdminRole.superAdmin);
      expect(updatedMember.isActive, false);
      expect(admin.auditLogs.first.action, 'تعديل صلاحيات موظف');
    });

    test('Settings Modification with Audit Trail (Page 75)', () {
      admin.updateSetting('match_radius_m', '4500');
      final setting = admin.settingsList.firstWhere((s) => s.key == 'match_radius_m');
      expect(setting.value, '4500');
      expect(admin.auditLogs.first.action, 'تعديل إعداد');
      expect(admin.auditLogs.first.beforeAfter, '3000 ← 4500');
    });
  });

  group('Admin Web App UI & Smoke Tests', () {
    testWidgets('MashwarAdminWebApp boots properly into AdminShell', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MashwarAdminWebApp());
      await tester.pumpAndSettle();

      // Verify Admin Shell is mounted in desktop mode
      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.text('مشوار · الإدارة'), findsOneWidget);
      expect(find.text('لوحة تحكم النظام'), findsOneWidget);
      expect(find.text('لوحة الأرقام'), findsWidgets);
      expect(find.text('توثيق السائقين'), findsWidgets);
      expect(find.text('المستخدمون'), findsWidgets);
      expect(find.text('الرحلات والطرود'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Admin Control Panel Viewport Responsiveness Tests', () {
    final viewports = [
      {'name': 'Desktop 1080p', 'size': const Size(1920, 1080)},
      {'name': 'Laptop / Tablet Landscape', 'size': const Size(1024, 768)},
      {'name': 'Tablet Portrait', 'size': const Size(768, 1024)},
      {'name': 'Mobile Screen', 'size': const Size(375, 812)},
      {'name': 'Compact Mobile', 'size': const Size(320, 640)},
    ];

    for (final vp in viewports) {
      testWidgets('Renders AdminShell without overflow on ${vp['name']} (${(vp['size'] as Size).width}x${(vp['size'] as Size).height})', (WidgetTester tester) async {
        final size = vp['size'] as Size;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MashwarAdminWebApp());
        await tester.pumpAndSettle();

        expect(find.byType(AdminShell), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Must not throw any overflow or layout exceptions on ${vp['name']}');
      });
    }

    testWidgets('All 8 Admin Screens mount and adapt cleanly without overflow on Mobile (375x812)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (int screenIndex = 0; screenIndex < 8; screenIndex++) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SettingsProvider()),
              ChangeNotifierProvider(create: (_) => AdminProvider()),
            ],
            child: MaterialApp(
              home: AdminShell(initialIndex: screenIndex),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AdminShell), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Screen index $screenIndex must render without layout overflow on mobile viewport',
        );
      }
    });
  });
}
