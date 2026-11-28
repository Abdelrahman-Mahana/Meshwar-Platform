import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'admin_audit_log_screen.dart';
import 'admin_corridors_geo_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_devops_sre_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_driver_verifications_screen.dart';
import 'admin_escrow_finance_screen.dart';
import 'admin_inquiries_screen.dart';
import 'admin_login_screen.dart';
import 'admin_rides_parcels_screen.dart';
import 'admin_services_catalog_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_staff_screen.dart';
import 'admin_users_screen.dart';
import 'admin_worksite_ops_screen.dart';
import 'widgets/admin_ui_kit.dart';

class AdminShell extends StatefulWidget {
  final int initialIndex;
  const AdminShell({super.key, this.initialIndex = 0});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _selectedIndex;

  static const Map<int, IconData> _moduleIcons = {
    0: Icons.dashboard_rounded,
    1: Icons.verified_user_rounded,
    2: Icons.people_alt_rounded,
    3: Icons.directions_car_rounded,
    4: Icons.report_problem_rounded,
    5: Icons.settings_suggest_rounded,
    6: Icons.badge_rounded,
    7: Icons.receipt_long_rounded,
    8: Icons.grid_view_rounded,
    9: Icons.map_rounded,
    10: Icons.account_balance_wallet_rounded,
    11: Icons.terminal_rounded,
    12: Icons.mark_email_unread_rounded,
    13: Icons.engineering_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _navigateToModule(int index, AdminProvider admin, bool isAr, {bool closeDrawer = false}) {
    if (!admin.canAccessMenu(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'هذه الشاشة مقصورة على أدوار إدارية أخرى وفق سياسة الصلاحيات.'
                : 'Access restricted for your current staff role.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
    if (closeDrawer) {
      Navigator.of(context).pop();
    }
  }

  void _openSpotlight(BuildContext context, AdminProvider admin, bool isAr) {
    showDialog(
      context: context,
      builder: (_) => AdminCommandPaletteDialog(
        onNavigate: (idx) => _navigateToModule(idx, admin, isAr),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context, AdminProvider admin, bool isAr) {
    final pendingDrivers = admin.driverRequests.where((r) => r.status == 'قيد المراجعة').length;
    final openDisputes = admin.disputes.where((d) => d.status == 'مفتوح').length;
    final frozenEscrows = admin.escrowItems.where((e) => e.status == 'frozen').length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_active_rounded, color: AppColors.coral, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isAr ? 'الإشعارات والعمليات العاجلة' : 'Operations Alerts',
                style: AppTypography.title().copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                child: const Icon(Icons.verified_user_rounded, color: AppColors.navy, size: 20),
              ),
              title: Text(
                isAr ? '$pendingDrivers طلبات توثيق معلقة' : '$pendingDrivers pending driver verifications',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                isAr ? 'بحاجة لمراجعة QID ورخص القيادة' : 'Requires QID & license checks',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(ctx).pop();
                _navigateToModule(1, admin, isAr);
              },
            ),
            const Divider(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.coral.withValues(alpha: 0.2),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 20),
              ),
              title: Text(
                isAr ? '$openDisputes بلاغات مفتوحة · $frozenEscrows ضمان مجمد' : '$openDisputes open disputes · $frozenEscrows frozen escrows',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                isAr ? 'تتطلب مراجعة وحسماً عبر التسوية والتحكيم' : 'Requires arbitration & settlement review',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(ctx).pop();
                _navigateToModule(4, admin, isAr);
              },
            ),
            const Divider(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.teal.withValues(alpha: 0.2),
                child: const Icon(Icons.engineering_rounded, color: AppColors.teal, size: 20),
              ),
              title: Text(
                isAr
                    ? '${admin.pendingVerificationsCount} توثيق مزود توريد · ${admin.pendingPaymentProofsCount} إيصال تحويل'
                    : '${admin.pendingVerificationsCount} pending supply KYC · ${admin.pendingPaymentProofsCount} transfer proofs',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                isAr ? 'عمليات التوريد الميداني والتحقق من الدفع' : 'Worksite Supply Ops & Settlement Review',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(ctx).pop();
                _navigateToModule(13, admin, isAr);
              },
            ),
            const Divider(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.navy.withValues(alpha: 0.14),
                child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.navy, size: 20),
              ),
              title: Text(
                isAr
                    ? '${admin.newInquiriesCount} رسائل جديدة من صفحة الموقع'
                    : '${admin.newInquiriesCount} new landing page inquiries',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                isAr ? 'طلبات المعاينة والشراكات والمستثمرين' : 'Demo requests, partnerships & investor leads',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(ctx).pop();
                _navigateToModule(12, admin, isAr);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedView(AdminProvider admin, bool isAr, AdminThemeTokens t) {
    if (!admin.canAccessMenu(_selectedIndex)) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, size: 34, color: AppColors.coral),
              ),
              const SizedBox(height: 18),
              Text(
                isAr ? 'الصفحة غير متاحة لدورك الحالي' : 'Access Restricted for Current Role',
                style: TextStyle(color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isAr
                    ? 'دورك الإداري الحالي مخصص لأقسام محددة فقط وفق سياسة الصلاحيات. تواصل مع المشرف الأول لطلب صلاحيات إضافية.'
                    : 'Your current staff role is scoped to specific operational sections.',
                style: TextStyle(color: t.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.dashboard_rounded, size: 18),
                label: Text(isAr ? 'العودة للوحة الأرقام' : 'Return to Dashboard'),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return AdminDashboardScreen(onJumpToModule: (idx) => _navigateToModule(idx, admin, isAr));
      case 1:
        return const AdminDriverVerificationsScreen();
      case 2:
        return const AdminUsersScreen();
      case 3:
        return const AdminRidesParcelsScreen();
      case 4:
        return const AdminDisputesScreen();
      case 5:
        return const AdminSettingsScreen();
      case 6:
        return const AdminStaffScreen();
      case 7:
        return const AdminAuditLogScreen();
      case 8:
        return const AdminServicesCatalogScreen();
      case 9:
        return const AdminCorridorsGeoScreen();
      case 10:
        return const AdminEscrowFinanceScreen();
      case 11:
        return const AdminDevOpsSreScreen();
      case 12:
        return const AdminInquiriesScreen();
      case 13:
        return const AdminWorksiteOpsScreen();
      default:
        return AdminDashboardScreen(onJumpToModule: (idx) => _navigateToModule(idx, admin, isAr));
    }
  }

  String _getRoleLabel(AdminRole role, bool isAr) {
    switch (role) {
      case AdminRole.superAdmin:
        return isAr ? 'مشرف أول' : 'Super Admin';
      case AdminRole.reviewAdmin:
        return isAr ? 'مشرف مراجعة' : 'Review Admin';
      case AdminRole.supportAdmin:
        return isAr ? 'مشرف دعم' : 'Support Admin';
      case AdminRole.financeAdmin:
        return isAr ? 'مشرف مالية وضمان' : 'Finance & Escrow';
      case AdminRole.devopsAdmin:
        return isAr ? 'مهندس DevOps' : 'DevOps & SRE';
    }
  }

  String _getRoleInitial(AdminRole role, bool isAr) {
    switch (role) {
      case AdminRole.superAdmin:
        return isAr ? 'م' : 'S';
      case AdminRole.reviewAdmin:
        return isAr ? 'ر' : 'R';
      case AdminRole.supportAdmin:
        return isAr ? 'د' : 'U';
      case AdminRole.financeAdmin:
        return isAr ? 'ض' : 'F';
      case AdminRole.devopsAdmin:
        return 'D';
    }
  }

  PopupMenuItem<AdminRole> _buildRoleMenuItem(AdminRole role, bool isAr, AdminRole currentRole) {
    final isSel = role == currentRole;
    String desc;
    switch (role) {
      case AdminRole.superAdmin:
        desc = isAr ? 'كامل الصلاحيات + DevOps والمالية' : 'Full Command Center access';
      case AdminRole.reviewAdmin:
        desc = isAr ? 'توثيق السائقين والـ QID فقط' : 'Driver & QID KYC only';
      case AdminRole.supportAdmin:
        desc = isAr ? 'المستخدمون، الطلبات والنزاعات' : 'Users, Orders & Disputes';
      case AdminRole.financeAdmin:
        desc = isAr ? 'الضمان المالي، البوابات والخدمات' : 'Escrow, Gateways & Pricing';
      case AdminRole.devopsAdmin:
        desc = isAr ? 'SRE، الأعلام البرمجية والمحاور' : 'Infra SRE, Flags & Corridors';
    }
    return PopupMenuItem<AdminRole>(
      value: role,
      child: Row(
        children: [
          if (isSel)
            const Icon(Icons.check_rounded, size: 16, color: AppColors.teal)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getRoleLabel(role, isAr),
                style: TextStyle(
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? AppColors.navy : null,
                ),
              ),
              Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({
    required BuildContext context,
    required AdminProvider admin,
    required SettingsProvider settings,
    required bool isAr,
    required bool isCollapsed,
    required bool closeOnSelect,
    required int pendingDriversCount,
    required int openDisputesCount,
    required int pendingEscrowCount,
  }) {
    final double width = isCollapsed ? 76 : 268;
    String? lastGroup;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, Color(0xFF071627)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Header (Preserves 'مشوار · الإدارة' and 'لوحة تحكم النظام')
          Container(
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 18, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E3A58))),
            ),
            child: Column(
              crossAxisAlignment: isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, Color(0xFFE08D0B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          isAr ? 'م' : 'M',
                          style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'مشوار · الإدارة' : 'MASHWAR · Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isAr ? 'لوحة تحكم النظام' : 'Control Panel',
                              style: const TextStyle(color: Color(0xFF8FA3B8), fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!closeOnSelect)
                        IconButton(
                          tooltip: isAr ? 'طي القائمة الجانبية' : 'Collapse sidebar',
                          icon: const Icon(Icons.menu_open_rounded, color: Color(0xFF94A3B8), size: 18),
                          onPressed: admin.toggleSidebarCollapsed,
                        ),
                    ],
                  ],
                ),
                if (isCollapsed && !closeOnSelect) ...[
                  const SizedBox(height: 8),
                  IconButton(
                    tooltip: isAr ? 'توسيع القائمة' : 'Expand sidebar',
                    icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                    onPressed: admin.toggleSidebarCollapsed,
                  ),
                ],
                if (!isCollapsed) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MashwarLivePulseDot(color: Color(0xFF10B981), size: 7),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isAr
                                ? '${admin.activeEnvironment.toUpperCase()} · الأنظمة 99.9%'
                                : '${admin.activeEnvironment.toUpperCase()} · 99.9% Healthy',
                            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 10, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Grouped 14-Module Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                for (final mod in AdminProvider.modulesCatalog) ...[
                  Builder(
                    builder: (context) {
                      final groupName = isAr ? mod.groupAr : mod.groupEn;
                      final showGroupHeader = !isCollapsed && groupName != lastGroup;
                      lastGroup = groupName;

                      final isSelected = _selectedIndex == mod.index;
                      final canAccess = admin.canAccessMenu(mod.index);
                      final icon = _moduleIcons[mod.index] ?? Icons.extension_rounded;
                      final title = isAr ? mod.titleAr : mod.titleEn;

                      int? badgeCount;
                      Color badgeBg = AppColors.gold;
                      Color badgeText = AppColors.navy;
                      if (mod.index == 1 && pendingDriversCount > 0) {
                        badgeCount = pendingDriversCount;
                      } else if (mod.index == 4 && openDisputesCount > 0) {
                        badgeCount = openDisputesCount;
                        badgeBg = AppColors.coral;
                        badgeText = Colors.white;
                      } else if (mod.index == 10 && pendingEscrowCount > 0) {
                        badgeCount = pendingEscrowCount;
                        badgeBg = AppColors.teal;
                        badgeText = Colors.white;
                      } else if (mod.index == 12 && admin.newInquiriesCount > 0) {
                        badgeCount = admin.newInquiriesCount;
                        badgeBg = AppColors.coral;
                        badgeText = Colors.white;
                      } else if (mod.index == 13 && admin.pendingVerificationsCount > 0) {
                        badgeCount = admin.pendingVerificationsCount;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showGroupHeader)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                              child: Text(
                                groupName,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 10, vertical: 2),
                            child: Tooltip(
                              message: isCollapsed ? title : '',
                              child: Material(
                                color: isSelected ? const Color(0xFF1E3A58) : Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                clipBehavior: Clip.antiAlias,
                                child: isCollapsed
                                    ? InkWell(
                                        onTap: () => _navigateToModule(
                                          mod.index,
                                          admin,
                                          isAr,
                                          closeDrawer: closeOnSelect,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 11),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                canAccess ? icon : Icons.lock_outline_rounded,
                                                color: isSelected
                                                    ? AppColors.gold
                                                    : canAccess
                                                        ? const Color(0xFF94A3B8)
                                                        : const Color(0xFF5A7188),
                                                size: 21,
                                              ),
                                              if (badgeCount != null)
                                                Positioned(
                                                  top: 0,
                                                  right: 14,
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: badgeBg,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListTile(
                                        dense: true,
                                        visualDensity: const VisualDensity(vertical: -1),
                                        leading: Icon(
                                          canAccess ? icon : Icons.lock_outline_rounded,
                                          color: isSelected
                                              ? AppColors.gold
                                              : canAccess
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF5A7188),
                                          size: 19,
                                        ),
                                        title: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : canAccess
                                                    ? const Color(0xFFCDD6DF)
                                                    : const Color(0xFF6C8299),
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (badgeCount != null && badgeCount > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: badgeBg,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '$badgeCount',
                                                  style: TextStyle(
                                                    color: badgeText,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            if (!canAccess) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF5A7188)),
                                            ],
                                          ],
                                        ),
                                        onTap: () => _navigateToModule(
                                          mod.index,
                                          admin,
                                          isAr,
                                          closeDrawer: closeOnSelect,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // Footer Controls
          Container(
            padding: EdgeInsets.all(isCollapsed ? 8 : 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E3A58))),
            ),
            child: Material(
              color: Colors.transparent,
              child: isCollapsed
                  ? Column(
                      children: [
                        IconButton(
                          tooltip: isAr ? 'تبديل اللغة' : 'Switch Language',
                          icon: const Icon(Icons.language_rounded, color: AppColors.teal, size: 20),
                          onPressed: () => settings.setLocale(isAr ? const Locale('en', 'US') : const Locale('ar', 'QA')),
                        ),
                        IconButton(
                          tooltip: isAr ? 'الوضع الداكن/الفاتح' : 'Toggle Theme',
                          icon: Icon(admin.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: AppColors.gold, size: 20),
                          onPressed: admin.toggleDarkMode,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          leading: Icon(
                            admin.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: AppColors.gold,
                            size: 19,
                          ),
                          title: Text(
                            admin.isDarkMode
                                ? (isAr ? 'الوضع الفاتح القياسي' : 'Light Workspace')
                                : (isAr ? 'الوضع الليلي NOC' : 'Dark NOC Mode'),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onTap: admin.toggleDarkMode,
                        ),
                        ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          leading: const Icon(Icons.language_rounded, color: AppColors.teal, size: 19),
                          title: Text(
                            isAr ? 'English (US)' : 'العربية (قطر)',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onTap: () => settings.setLocale(isAr ? const Locale('en', 'US') : const Locale('ar', 'QA')),
                        ),
                        ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          leading: const Icon(Icons.logout_rounded, color: AppColors.coral, size: 19),
                          title: Text(
                            isAr ? 'تسجيل الخروج' : 'Log Out',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          onTap: () => admin.logout(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAr ? 'عمليات مشوار · قطر 🇶🇦' : 'MASHWAR Ops · Qatar 🇶🇦',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePillOrSwitcher(
    AdminProvider admin,
    AdminThemeTokens t,
    bool isAr, {
    required bool compact,
  }) {
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: t.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: compact ? 10 : 11,
            backgroundColor: AppColors.navy,
            child: Text(
              _getRoleInitial(admin.activeRole, isAr),
              style: TextStyle(
                color: AppColors.gold,
                fontSize: compact ? 9.5 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            _getRoleLabel(admin.activeRole, isAr),
            style: TextStyle(
              color: t.textPrimary,
              fontSize: compact ? 10.5 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (admin.canSwitchRoleLocally)
            Icon(
              Icons.arrow_drop_down_rounded,
              size: compact ? 15 : 16,
              color: t.textSecondary,
            ),
        ],
      ),
    );

    if (!admin.canSwitchRoleLocally) {
      return Tooltip(
        message: admin.staffEmail ?? _getRoleLabel(admin.activeRole, isAr),
        child: pill,
      );
    }

    return PopupMenuButton<AdminRole>(
      tooltip: isAr ? 'تبديل الدور الإداري' : 'Switch Role',
      onSelected: (newRole) {
        admin.setActiveRole(newRole);
        if (!admin.canAccessMenu(_selectedIndex)) {
          setState(() => _selectedIndex = 0);
        }
      },
      itemBuilder: (ctx) => [
        for (final role in AdminRole.values)
          _buildRoleMenuItem(role, isAr, admin.activeRole),
      ],
      child: pill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final admin = context.watch<AdminProvider>();

    // Strict route guard: never expose any admin module or sidebar when unauthenticated.
    if (!admin.isLoggedIn) {
      return const AdminLoginScreen();
    }

    final t = AdminThemeTokens.of(context);
    final isAr = settings.isArabic;

    final pendingDriversCount = admin.driverRequests.where((r) => r.status == 'قيد المراجعة').length;
    final openDisputesCount = admin.disputes.where((d) => d.status == 'مفتوح').length;
    final pendingEscrowCount = admin.escrowItems.where((e) => e.status == 'frozen' || e.status == 'receipt_pending').length;
    final totalAlertsCount =
        pendingDriversCount + openDisputesCount + admin.pendingVerificationsCount;

    final currentMod = AdminProvider.modulesCatalog.firstWhere(
      (m) => m.index == _selectedIndex,
      orElse: () => AdminProvider.modulesCatalog.first,
    );
    final currentTitle = isAr ? currentMod.titleAr : currentMod.titleEn;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _openSpotlight(context, admin, isAr),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _openSpotlight(context, admin, isAr),
      },
      child: Focus(
        autofocus: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWideDesktop = width >= 1080;
            final isTabletRail = width >= 680 && width < 1080;
            final isMobile = width < 680;

            return Scaffold(
              backgroundColor: t.scaffoldBg,
              appBar: isMobile
                  ? AppBar(
                      backgroundColor: AppColors.navy,
                      elevation: 0,
                      titleSpacing: 4,
                      iconTheme: const IconThemeData(color: Colors.white),
                      title: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                isAr ? 'م' : 'M',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${isAr ? "مشوار" : "MASHWAR"} · $currentTitle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: isAr ? 'بحث سريع' : 'Search',
                          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                          onPressed: () => _openSpotlight(context, admin, isAr),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: isAr ? 'التنبيهات' : 'Alerts',
                          icon: Badge(
                            label: Text('$totalAlertsCount'),
                            isLabelVisible: totalAlertsCount > 0,
                            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                          ),
                          onPressed: () => _showNotificationsDialog(context, admin, isAr),
                        ),
                        if (Navigator.of(context).canPop())
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: isAr ? 'العودة للتطبيق' : 'Back to App',
                            icon: const Icon(Icons.exit_to_app_rounded, color: AppColors.gold, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        const SizedBox(width: 6),
                      ],
                    )
                  : null,
              drawer: isWideDesktop
                  ? null
                  : Drawer(
                      child: _buildSidebar(
                        context: context,
                        admin: admin,
                        settings: settings,
                        isAr: isAr,
                        isCollapsed: false,
                        closeOnSelect: true,
                        pendingDriversCount: pendingDriversCount,
                        openDisputesCount: openDisputesCount,
                        pendingEscrowCount: pendingEscrowCount,
                      ),
                    ),
              body: Row(
                children: [
                  if (isWideDesktop)
                    _buildSidebar(
                      context: context,
                      admin: admin,
                      settings: settings,
                      isAr: isAr,
                      isCollapsed: admin.isSidebarCollapsed,
                      closeOnSelect: false,
                      pendingDriversCount: pendingDriversCount,
                      openDisputesCount: openDisputesCount,
                      pendingEscrowCount: pendingEscrowCount,
                    )
                  else if (isTabletRail)
                    _buildSidebar(
                      context: context,
                      admin: admin,
                      settings: settings,
                      isAr: isAr,
                      isCollapsed: true,
                      closeOnSelect: false,
                      pendingDriversCount: pendingDriversCount,
                      openDisputesCount: openDisputesCount,
                      pendingEscrowCount: pendingEscrowCount,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        // Global Command Top Bar
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 20,
                            vertical: isMobile ? 8 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: t.headerBg,
                            border: Border(bottom: BorderSide(color: t.border)),
                          ),
                          child: isMobile
                              ? Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // Compact Period Switcher
                                    Container(
                                      decoration: BoxDecoration(
                                        color: t.surfaceMuted,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: t.border, width: 0.8),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (int i = 0; i < 3; i++)
                                            Builder(
                                              builder: (_) {
                                                final periods = isAr ? ['اليوم', '7 أيام', '30 يوم'] : ['Today', '7 Days', '30 Days'];
                                                final isSel = (i == 1 && admin.currentPeriod.contains('7')) ||
                                                    (i == 0 && (admin.currentPeriod == 'اليوم' || admin.currentPeriod == 'Today')) ||
                                                    (i == 2 && admin.currentPeriod.contains('30'));
                                                return GestureDetector(
                                                  onTap: () => admin.setPeriod(periods[i]),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: isSel ? AppColors.navy : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: Text(
                                                      periods[i],
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: isSel ? Colors.white : t.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: admin.toggleDarkMode,
                                          borderRadius: BorderRadius.circular(14),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: t.surfaceMuted,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: t.border, width: 0.8),
                                            ),
                                            child: Icon(
                                              admin.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                              color: admin.isDarkMode ? AppColors.gold : t.textPrimary,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildRolePillOrSwitcher(admin, t, isAr, compact: true),
                                      ],
                                    ),
                                  ],
                                )
                              : LayoutBuilder(
                            builder: (ctx, topConstraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: topConstraints.maxWidth),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isTabletRail)
                                            Builder(
                                              builder: (scaffoldCtx) => IconButton(
                                                tooltip: isAr ? 'فتح القائمة الكاملة' : 'Open full menu',
                                                icon: Icon(Icons.menu_rounded, color: t.textPrimary),
                                                onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
                                              ),
                                            ),
                                          Icon(_moduleIcons[_selectedIndex] ?? Icons.dashboard_rounded,
                                              color: t.accentPrimary, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            currentTitle,
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 17,
                                              fontWeight: FontWeight.w800,
                                              color: t.textPrimary,
                                            ),
                                          ),
                                          if (!isMobile) ...[
                                            const SizedBox(width: 14),
                                            InkWell(
                                              onTap: () => _openSpotlight(context, admin, isAr),
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: t.surfaceAlt,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: t.border),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.search_rounded, size: 15, color: t.textSecondary),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      isAr ? 'بحث سريع (Ctrl+K)' : 'Quick Jump (Ctrl+K)',
                                                      style: TextStyle(color: t.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isMobile)
                                            IconButton(
                                              tooltip: isAr ? 'تبديل الوضع الليلي/الفاتح' : 'Toggle Dark/Light Mode',
                                              icon: Icon(
                                                admin.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                                color: admin.isDarkMode ? AppColors.gold : t.textPrimary,
                                                size: 20,
                                              ),
                                              onPressed: admin.toggleDarkMode,
                                            ),
                                          if (!isMobile)
                                            IconButton(
                                              tooltip: isAr ? 'التنبيهات' : 'Alerts',
                                              icon: Badge(
                                                label: Text('$totalAlertsCount'),
                                                isLabelVisible: totalAlertsCount > 0,
                                                child: Icon(Icons.notifications_none_rounded, color: t.textPrimary, size: 20),
                                              ),
                                              onPressed: () => _showNotificationsDialog(context, admin, isAr),
                                            ),
                                          const SizedBox(width: 6),
                                          // Period Switcher
                                          Container(
                                            decoration: BoxDecoration(
                                              color: t.surfaceMuted,
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(color: t.border, width: 0.8),
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: Row(
                                              children: [
                                                for (int i = 0; i < 3; i++)
                                                  Builder(
                                                    builder: (_) {
                                                      final periods = isAr ? ['اليوم', '7 أيام', '30 يوم'] : ['Today', '7 Days', '30 Days'];
                                                      final isSel = (i == 1 && admin.currentPeriod.contains('7')) ||
                                                          (i == 0 && (admin.currentPeriod == 'اليوم' || admin.currentPeriod == 'Today')) ||
                                                          (i == 2 && admin.currentPeriod.contains('30'));
                                                      return GestureDetector(
                                                        onTap: () => admin.setPeriod(periods[i]),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                          decoration: BoxDecoration(
                                                            color: isSel ? AppColors.navy : Colors.transparent,
                                                            borderRadius: BorderRadius.circular(14),
                                                          ),
                                                          child: Text(
                                                            periods[i],
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w700,
                                                              color: isSel ? Colors.white : t.textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildRolePillOrSwitcher(admin, t, isAr, compact: false),
                                          if (!isMobile && Navigator.of(context).canPop()) ...[
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: t.accentPrimary,
                                                side: BorderSide(color: t.border),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              ),
                                              icon: const Icon(Icons.arrow_back_rounded, size: 15),
                                              label: Text(isAr ? 'التطبيق' : 'App', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Mobile Quick-Jump Strip (1-tap module switcher on small screens)
                        if (isMobile)
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: t.surface,
                              border: Border(bottom: BorderSide(color: t.border)),
                            ),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              children: AdminProvider.modulesCatalog
                                  .where((m) => admin.canAccessMenu(m.index))
                                  .map((m) {
                                final isSel = _selectedIndex == m.index;
                                return Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 8),
                                  child: Material(
                                    color: isSel ? AppColors.navy : t.surfaceAlt,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(color: isSel ? AppColors.navy : t.border),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => _navigateToModule(m.index, admin, isAr),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        child: Center(
                                          child: Text(
                                            isAr ? m.shortAr : m.shortEn,
                                            style: TextStyle(
                                              color: isSel ? Colors.white : t.textPrimary,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // Active Screen Content
                        Expanded(
                          child: _getSelectedView(admin, isAr, t),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
