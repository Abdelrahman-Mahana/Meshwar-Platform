import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_driver_verifications_screen.dart';
import 'admin_users_screen.dart';
import 'admin_rides_parcels_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_audit_log_screen.dart';
import 'admin_staff_screen.dart';
import 'admin_login_screen.dart';

class AdminShell extends StatefulWidget {
  final int initialIndex;
  const AdminShell({super.key, this.initialIndex = 0});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _selectedIndex;

  final List<String> _menuTitlesAr = [
    'لوحة الأرقام',
    'توثيق السائقين',
    'المستخدمون',
    'الرحلات والطرود',
    'البلاغات والنزاعات',
    'الإعدادات',
    'الموظفون',
    'سجل التدقيق',
  ];

  final List<String> _menuTitlesEn = [
    'Metrics Dashboard',
    'Driver Verifications',
    'Users',
    'Rides & Parcels',
    'Disputes & Reports',
    'Settings',
    'Staff & Roles',
    'Audit Log',
  ];

  final List<IconData> _menuIcons = [
    Icons.dashboard_rounded,
    Icons.verified_user_rounded,
    Icons.people_alt_rounded,
    Icons.directions_car_rounded,
    Icons.report_problem_rounded,
    Icons.settings_suggest_rounded,
    Icons.badge_rounded,
    Icons.receipt_long_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _showNotificationsDialog(BuildContext context, AdminProvider admin, bool isAr) {
    final pendingDrivers = admin.driverRequests.where((r) => r.status == 'قيد المراجعة').length;
    final openDisputes = admin.disputes.where((d) => d.status == 'مفتوح').length;

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
            Text(
              isAr ? 'الإشعارات والعمليات العاجلة' : 'Operations Alerts',
              style: AppTypography.title().copyWith(fontSize: 16),
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
                isAr ? 'بحاجة لمراجعة بطاقة الرقم القومي ورخص القيادة' : 'Requires National ID & License checks',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Icon(isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() => _selectedIndex = 1);
              },
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.coral.withValues(alpha: 0.2),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 20),
              ),
              title: Text(
                isAr ? '$openDisputes بلاغات مفتوحة' : '$openDisputes open disputes & reports',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                isAr ? 'تتطلب إسناداً لموظف دعم وحلاً عاجلاً' : 'Requires staff assignment & resolution',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Icon(isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() => _selectedIndex = 4);
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

  Widget _getSelectedView(AdminProvider admin, bool isAr) {
    if (!admin.canAccessMenu(_selectedIndex)) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, size: 36, color: AppColors.coral),
              ),
              const SizedBox(height: 20),
              Text(
                isAr ? 'الصفحة غير متاحة لدورك الحالي' : 'Access Restricted for Current Role',
                style: AppTypography.title().copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isAr
                    ? 'بموجب مصفوفة الصلاحيات (صفحة 77)، دورك الحالي محدد فقط لأقسام معينة. يمكنك تبديل دورك التجريبي من الشريط العلوي لتجربة بقية الشاشات.'
                    : 'Per the Page 77 permissions matrix, your current role does not have access to this screen. Switch roles from the top-bar to preview other views.',
                style: AppTypography.body(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
        return const AdminDashboardScreen();
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
      default:
        return const AdminDashboardScreen();
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
    }
  }

  String _getRoleInitial(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return 'م';
      case AdminRole.reviewAdmin:
        return 'ر';
      case AdminRole.supportAdmin:
        return 'د';
    }
  }

  PopupMenuItem<AdminRole> _buildRoleMenuItem(AdminRole role, bool isAr, AdminRole currentRole) {
    final isSel = role == currentRole;
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
                  color: isSel ? AppColors.navy : Colors.black87,
                ),
              ),
              Text(
                role == AdminRole.superAdmin
                    ? (isAr ? 'كل شيء + الإعدادات والموظفون' : 'Full access & settings')
                    : role == AdminRole.reviewAdmin
                        ? (isAr ? 'توثيق السائقين فقط' : 'Driver verifications only')
                        : (isAr ? 'المستخدمون والنزاعات' : 'Users & disputes only'),
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final admin = context.watch<AdminProvider>();
    final isAr = settings.isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final pendingDriversCount = admin.driverRequests.where((r) => r.status == 'قيد المراجعة').length;
    final openDisputesCount = admin.disputes.where((d) => d.status == 'مفتوح').length;

    final sidebar = Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, Color(0xFF091E33)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Logo & System Identity (Pages 69-77)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E3A58))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'م',
                          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                    ),
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
                          ),
                          Text(
                            isAr ? 'لوحة تحكم النظام' : 'Control Panel',
                            style: const TextStyle(color: Color(0xFF8FA3B8), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Operational status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isAr ? 'الخوادم تعمل بنسبة 99.9%' : 'All Systems Operational',
                          style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 10, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _menuTitlesAr.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                final title = isAr ? _menuTitlesAr[index] : _menuTitlesEn[index];
                final icon = _menuIcons[index];
                final canAccess = admin.canAccessMenu(index);

                // Badge counts for pending reviews
                int? badgeCount;
                Color badgeBg = AppColors.gold;
                Color badgeText = AppColors.navy;

                if (index == 1 && pendingDriversCount > 0) {
                  badgeCount = pendingDriversCount;
                  badgeBg = AppColors.gold;
                  badgeText = AppColors.navy;
                } else if (index == 4 && openDisputesCount > 0) {
                  badgeCount = openDisputesCount;
                  badgeBg = AppColors.coral;
                  badgeText = Colors.white;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Material(
                    color: isSelected ? const Color(0xFF1E3A58) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        canAccess ? icon : Icons.lock_outline_rounded,
                        color: isSelected
                            ? AppColors.gold
                            : canAccess
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF5A7188),
                        size: 20,
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : canAccess
                                  ? const Color(0xFFCDD6DF)
                                  : const Color(0xFF6C8299),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (badgeCount != null && badgeCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: TextStyle(
                                  color: badgeText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (!canAccess) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF5A7188)),
                          ],
                        ],
                      ),
                      onTap: () {
                        if (!canAccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isAr
                                    ? 'هذه الشاشة مقصورة على أدوار إدارية أخرى بموجب مصفوفة الصلاحيات (صفحة 77).'
                                    : 'Access restricted for current simulated role under Page 77 matrix.',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        setState(() => _selectedIndex = index);
                        if (!isDesktop) Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Return to Mobile App & Language Switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E3A58))),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.language_rounded, color: AppColors.teal, size: 20),
                    title: Text(
                      isAr ? 'English (US)' : 'العربية (مصر)',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      settings.setLocale(isAr ? const Locale('en', 'US') : const Locale('ar', 'EG'));
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.logout_rounded, color: AppColors.coral, size: 20),
                    title: Text(
                      isAr ? 'تسجيل الخروج' : 'Log Out',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    onTap: () {
                      context.read<AdminProvider>().logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مشوار v2.4.0 · مصر 🇪🇬',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.navy,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Row(
                children: [
                  const BrandLogo(fontSize: 20, isLight: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '· ${isAr ? _menuTitlesAr[_selectedIndex] : _menuTitlesEn[_selectedIndex]}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: isAr ? 'التنبيهات العاجلة' : 'Alerts',
                  icon: Badge(
                    label: Text('${pendingDriversCount + openDisputesCount}'),
                    isLabelVisible: (pendingDriversCount + openDisputesCount) > 0,
                    child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  ),
                  onPressed: () => _showNotificationsDialog(context, admin, isAr),
                ),
              ],
            ),
      drawer: isDesktop ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Column(
              children: [
                // Top Global Bar (Responsive & Adaptive)
                Container(
                  height: 64,
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: isDesktop
                            ? (screenWidth - 260 - 48).clamp(0.0, double.infinity)
                            : (screenWidth - 24).clamp(0.0, double.infinity),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isDesktop) ...[
                            Row(
                              children: [
                                Icon(_menuIcons[_selectedIndex], color: AppColors.navy, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  isAr ? _menuTitlesAr[_selectedIndex] : _menuTitlesEn[_selectedIndex],
                                  style: AppTypography.title().copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                          ],

                          // Filter & Role Controls (Always accessible)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Notification Action Button
                              IconButton(
                                tooltip: isAr ? 'التنبيهات والعمليات' : 'Notifications',
                                icon: Badge(
                                  label: Text('${pendingDriversCount + openDisputesCount}'),
                                  isLabelVisible: (pendingDriversCount + openDisputesCount) > 0,
                                  child: const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 22),
                                ),
                                onPressed: () => _showNotificationsDialog(context, admin, isAr),
                              ),
                              const SizedBox(width: 8),

                              // Period filter chips (Pages 69-76)
                              Consumer<AdminProvider>(
                                builder: (context, admin, _) {
                                  final periods = isAr ? ['اليوم', '7 أيام', '30 يوم'] : ['Today', '7 Days', '30 Days'];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: Row(
                                      children: [
                                        for (int i = 0; i < periods.length; i++) ...[
                                          GestureDetector(
                                            onTap: () => admin.setPeriod(periods[i]),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: (i == 1 && admin.currentPeriod.contains('7')) ||
                                                        (i == 0 && (admin.currentPeriod == 'اليوم' || admin.currentPeriod == 'Today')) ||
                                                        (i == 2 && admin.currentPeriod.contains('30'))
                                                    ? AppColors.navy
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                periods[i],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: (i == 1 && admin.currentPeriod.contains('7')) ||
                                                          (i == 0 && (admin.currentPeriod == 'اليوم' || admin.currentPeriod == 'Today')) ||
                                                          (i == 2 && admin.currentPeriod.contains('30'))
                                                      ? Colors.white
                                                      : AppColors.navy,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),

                              // Role Selector Staff Pill (Pages 69 & 77)
                              PopupMenuButton<AdminRole>(
                                tooltip: isAr ? 'تبديل الدور الإداري التجريبي' : 'Switch Simulated Admin Role',
                                onSelected: (newRole) {
                                  admin.setActiveRole(newRole);
                                  if (!admin.canAccessMenu(_selectedIndex)) {
                                    setState(() => _selectedIndex = 0);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isAr
                                            ? 'تم تبديل الدور الإداري إلى: ${_getRoleLabel(newRole, true)}'
                                            : 'Role switched to: ${_getRoleLabel(newRole, false)}',
                                      ),
                                      backgroundColor: AppColors.navy,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                itemBuilder: (ctx) => [
                                  _buildRoleMenuItem(AdminRole.superAdmin, isAr, admin.activeRole),
                                  _buildRoleMenuItem(AdminRole.reviewAdmin, isAr, admin.activeRole),
                                  _buildRoleMenuItem(AdminRole.supportAdmin, isAr, admin.activeRole),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: admin.activeRole == AdminRole.superAdmin
                                            ? AppColors.navy
                                            : admin.activeRole == AdminRole.reviewAdmin
                                                ? AppColors.teal
                                                : AppColors.gold,
                                        child: Text(
                                          _getRoleInitial(admin.activeRole),
                                          style: TextStyle(
                                            color: admin.activeRole == AdminRole.supportAdmin ? AppColors.navy : Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getRoleLabel(admin.activeRole, isAr),
                                        style: AppTypography.label().copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Selected Tab Body
                Expanded(
                  child: _getSelectedView(admin, isAr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
