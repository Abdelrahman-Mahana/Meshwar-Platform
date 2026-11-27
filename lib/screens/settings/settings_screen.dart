import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/user_model.dart';
import '../../state/alerts_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/admin_provider.dart';
import '../admin/admin_shell.dart';
import '../account/account_extra_screens.dart';
import '../account/legal_and_backend_screens.dart';
import '../alerts/my_alerts_screen.dart';
import '../auth/id_verification_screen.dart';
import '../auth/welcome_screen.dart';
import '../safety/safety_screens.dart';
import '../vehicle/vehicle_registration_screen.dart';
import '../wallet/wallet_screen.dart';

/// Clean, minimalist, Uber/inDrive-style Settings screen.
/// Implements pure white surfaces, soft neutral icon containers, indented hairlines,
/// high-contrast Cairo typography, and zero emoji clutter.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final isAr = settings.isArabic;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: AppDimens.space16),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  Text(
                    isAr ? 'اختر لغة التطبيق' : 'Select App Language',
                    style: AppTypography.title(),
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // System Default Option
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: settings.isFollowingSystem ? AppColors.navy : const Color(0xFFF3F3F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.smartphone_rounded,
                            size: 20,
                            color: settings.isFollowingSystem ? Colors.white : AppColors.navy,
                          ),
                        ),
                      ),
                      title: Text(
                        isAr ? 'لغة الهاتف الافتراضية' : 'System Default Language',
                        style: AppTypography.body().copyWith(
                          fontWeight: settings.isFollowingSystem ? FontWeight.w800 : FontWeight.w600,
                          color: settings.isFollowingSystem ? AppColors.navy : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        isAr ? 'يتبع لغة الجهاز تلقائياً' : 'Follows phone settings automatically',
                        style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11),
                      ),
                      trailing: settings.isFollowingSystem
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 22)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusField),
                        side: BorderSide(
                          color: settings.isFollowingSystem ? AppColors.teal : const Color(0xFFE5E5EA),
                          width: settings.isFollowingSystem ? 1.5 : 0.8,
                        ),
                      ),
                      onTap: () {
                        settings.setFollowSystem();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimens.space12),

                  // Arabic Option
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (!settings.isFollowingSystem && isAr) ? AppColors.navy : const Color(0xFFF3F3F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'AR',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: (!settings.isFollowingSystem && isAr) ? Colors.white : AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'العربية (قطر)',
                        style: AppTypography.body().copyWith(
                          fontWeight: (!settings.isFollowingSystem && isAr) ? FontWeight.w800 : FontWeight.w600,
                          color: (!settings.isFollowingSystem && isAr) ? AppColors.navy : AppColors.textPrimary,
                        ),
                      ),
                      trailing: (!settings.isFollowingSystem && isAr)
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 22)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusField),
                        side: BorderSide(
                          color: (!settings.isFollowingSystem && isAr) ? AppColors.teal : const Color(0xFFE5E5EA),
                          width: (!settings.isFollowingSystem && isAr) ? 1.5 : 0.8,
                        ),
                      ),
                      onTap: () {
                        settings.setLocale(const Locale('ar', 'QA'));
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimens.space12),

                  // English Option
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (!settings.isFollowingSystem && !isAr) ? AppColors.navy : const Color(0xFFF3F3F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'EN',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: (!settings.isFollowingSystem && !isAr) ? Colors.white : AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'English (United States)',
                        style: AppTypography.body().copyWith(
                          fontWeight: (!settings.isFollowingSystem && !isAr) ? FontWeight.w800 : FontWeight.w600,
                          color: (!settings.isFollowingSystem && !isAr) ? AppColors.navy : AppColors.textPrimary,
                        ),
                      ),
                      trailing: (!settings.isFollowingSystem && !isAr)
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 22)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusField),
                        side: BorderSide(
                          color: (!settings.isFollowingSystem && !isAr) ? AppColors.teal : const Color(0xFFE5E5EA),
                          width: (!settings.isFollowingSystem && !isAr) ? 1.5 : 0.8,
                        ),
                      ),
                      onTap: () {
                        settings.setLocale(const Locale('en', 'US'));
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimens.space16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, SettingsProvider settings) {
    final isAr = settings.isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              isAr ? 'تسجيل الخروج' : 'Log Out',
              style: AppTypography.title().copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من رغبتك في تسجيل الخروج من حساب مشوار؟'
              : 'Are you sure you want to log out of your MASHWAR account?',
          style: AppTypography.bodySecondary().copyWith(fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: AppTypography.body().copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: Text(
              isAr ? 'تأكيد الخروج' : 'Log Out',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    AlertsProvider? alerts;
    try {
      alerts = context.watch<AlertsProvider>();
    } catch (_) {
      alerts = null;
    }
    final isAr = settings.isArabic;
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        title: Text(
          isAr ? 'الإعدادات' : 'Settings',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;

            final accountGroup = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(isAr ? 'الحساب والتوثيق' : 'Account & Verification'),
                _buildCardGroup([
                  _buildSettingsTile(
                    icon: Icons.badge_outlined,
                    iconColor: AppColors.teal,
                    title: isAr ? 'توثيق البطاقة الشخصية القطرية (QID)' : 'Qatar ID (QID) Verification',
                    subtitle: user.nationalId != null
                        ? (isAr ? 'البطاقة القطرية: ${user.nationalId}' : 'QID: ${user.nationalId}')
                        : (isAr ? 'إلزامي للأمان ومطابقة بيانات الهوية' : 'Mandatory for safety compliance'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user.idVerificationStatus == IdVerificationStatus.verified)
                          MashwarBadge(
                            type: BadgeType.verified,
                            customLabel: isAr ? 'موثق' : 'Verified',
                          )
                        else if (user.idVerificationStatus == IdVerificationStatus.underReview)
                          MashwarBadge(
                            type: BadgeType.pending,
                            customLabel: isAr ? 'قيد المراجعة' : 'Under Review',
                          )
                        else
                          MashwarBadge(
                            type: BadgeType.rejected,
                            customLabel: isAr ? 'غير موثق' : 'Unverified',
                          ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IdVerificationScreen(isOnboarding: false),
                        ),
                      );
                    },
                  ),
                  _buildIndentedDivider(),
                  _buildSettingsTile(
                    icon: Icons.directions_car_filled_outlined,
                    iconColor: AppColors.navy,
                    title: isAr ? 'بيانات سيارتي ورخص القيادة' : 'My Vehicle & Driver Licenses',
                    subtitle: isAr ? 'سجل مركبتك لنشر الرحلات وتقديم عروض التوصيل' : 'Register your car to offer rides',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VehicleRegistrationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildIndentedDivider(),
                  _buildSettingsTile(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.teal,
                    title: isAr ? 'محفظة مشوار وطرق الدفع' : 'Wallet & Payment Methods',
                    subtitle: isAr ? 'فوراً، كيوباي، سكيب كاش، الدفع نقداً' : 'Fawran, QPay, SkipCash, Cash',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.tealSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.teal.withValues(alpha: 0.28), width: 0.9),
                          ),
                          child: Text(
                            '${user.walletBalance.toStringAsFixed(0)} ${isAr ? 'ر.ق' : 'QAR'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WalletScreen(),
                        ),
                      );
                    },
                  ),
                  _buildIndentedDivider(),
                  _buildSettingsTile(
                    icon: Icons.emergency_outlined,
                    iconColor: AppColors.navy,
                    title: isAr ? 'جهات الاتصال في حالات الطوارئ' : 'Emergency Contacts (SOS)',
                    subtitle: user.emergencyContactName != null
                        ? '${user.emergencyContactName} (${user.emergencyContactPhone})'
                        : (isAr ? 'حدد جهات اتصال لمشاركة المسار معهم فورياً' : 'Set contacts for instant tracking share'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                ]),
              ],
            );

            final preferencesGroup = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(isAr ? 'التفضيلات وتجربة السفر' : 'Preferences & Trip Comfort'),
                _buildCardGroup([
                  _buildSettingsTile(
                    icon: Icons.language_rounded,
                    iconColor: AppColors.navy,
                    title: isAr ? 'لغة التطبيق' : 'App Language',
                    subtitle: settings.isFollowingSystem
                        ? (isAr ? 'لغة الهاتف الافتراضية' : 'System Default (Phone)')
                        : (isAr ? 'العربية (دولة قطر)' : 'English (United States)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.slateBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.slateBorder, width: 1.0),
                          ),
                          child: Text(
                            settings.isFollowingSystem
                                ? (isAr ? 'لغة الهاتف' : 'System')
                                : (isAr ? 'العربية' : 'English'),
                            style: AppTypography.label(color: AppColors.navy).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                    onTap: () => _showLanguageDialog(context, settings),
                  ),
                ]),
              ],
            );

            final notificationsGroup = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(isAr ? 'إشعارات التطبيق الذكية' : 'Smart Notifications'),
                _buildCardGroup([
                  SwitchListTile.adaptive(
                    activeTrackColor: AppColors.teal,
                    value: settings.ridesNotifications,
                    onChanged: settings.setRidesNotifications,
                    secondary: _buildSwitchIconBox(Icons.notifications_active_outlined),
                    title: Text(
                      isAr ? 'تنبيهات الرحلات' : 'Ride Alerts',
                      style: AppTypography.body(color: AppColors.navy).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      isAr ? 'إشعارات مواعيد الرحلات وتأكيد الحجز وتذكير السفر' : 'Departure reminders & booking confirmations',
                      style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11.5),
                    ),
                  ),
                  _buildIndentedDivider(),
                  SwitchListTile.adaptive(
                    activeTrackColor: AppColors.teal,
                    value: settings.parcelsNotifications,
                    onChanged: settings.setParcelsNotifications,
                    secondary: _buildSwitchIconBox(Icons.inventory_2_outlined),
                    title: Text(
                      isAr ? 'تحديثات الشحن والطرود' : 'Parcel Shipping Updates',
                      style: AppTypography.body(color: AppColors.navy).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      isAr ? 'إشعارات كود الاستلام ولحظات حركة الطرد حتى التسليم' : 'Pickup OTP & parcel transit milestones',
                      style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11.5),
                    ),
                  ),
                  _buildIndentedDivider(),
                  SwitchListTile.adaptive(
                    activeTrackColor: AppColors.teal,
                    value: settings.boardNotifications,
                    onChanged: settings.setBoardNotifications,
                    secondary: _buildSwitchIconBox(Icons.radar_rounded),
                    title: Text(
                      isAr ? 'عروض اللوحة المجتمعية القريبة' : 'Community Board Near Me',
                      style: AppTypography.body(color: AppColors.navy).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      isAr ? 'تنبيه فوري عند نشر طلب مشوار أو طرد في نطاق 50 كم' : 'Alerts when a request is posted within 50 km',
                      style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11.5),
                    ),
                  ),
                  _buildIndentedDivider(),
                  _buildSettingsTile(
                    icon: Icons.add_alert_rounded,
                    iconColor: AppColors.navy,
                    title: isAr ? 'تنبيهاتي للمسارات المتابعة' : 'My Monitored Route Alerts',
                    subtitle: isAr ? 'إدارة وتخصيص تنبيهات المسارات ومواعيد السفر' : 'Manage custom corridor alerts & departure dates',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (alerts != null && alerts.alerts.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.tealSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.teal.withValues(alpha: 0.28), width: 0.9),
                            ),
                            child: Text(
                              '${alerts.alerts.where((a) => a.isActive).length} ${isAr ? 'نشط' : 'active'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyAlertsScreen()),
                      );
                    },
                  ),
                ]),
              ],
            );

            final supportLegalGroup = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(isAr ? 'الدعم والشروط القانونية' : 'Support & Legal'),
                _buildCardGroup([
                  _buildSettingsTile(
                    icon: Icons.support_agent_rounded,
                    iconColor: AppColors.navy,
                    title: isAr ? 'مركز المساعدة والدعم المباشر 24/7' : 'Help & Support 24/7',
                    subtitle: isAr ? 'فريق خدمة عملاء مشوار متواجد على مدار الساعة' : 'Customer support available around the clock',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildIndentedDivider(),
                  _buildSettingsTile(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.navy,
                    title: isAr ? 'شروط الخدمة وسياسة الخصوصية' : 'Terms of Service & Privacy',
                    subtitle: isAr ? 'القواعد وحقوق الركاب والسائقين وحماية البيانات' : 'Rights, terms & data protection policies',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LegalComplianceScreen(initialTabIndex: 0),
                        ),
                      );
                    },
                  ),
                  _buildIndentedDivider(),
                  _buildSettingsTile(
                    icon: Icons.verified_outlined,
                    iconColor: AppColors.teal,
                    title: isAr
                        ? 'الامتثال التنظيمي وحماية البيانات (قطر)'
                        : 'Regulatory Compliance & Data Protection (Qatar)',
                    subtitle: isAr
                        ? 'الإفصاحات القانونية ونطاق المنصة وقانون الخصوصية رقم 13 لسنة 2016'
                        : 'Platform scope, legal disclosures & Qatar Law No. 13 of 2016',
                    trailing: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 18),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LegalComplianceScreen(initialTabIndex: 2),
                        ),
                      );
                    },
                  ),
                  if (!AppEnvironment.current.isProduction || AppEnvironment.useDevMocks) ...[
                    _buildIndentedDivider(),
                    _buildSettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: AppColors.navy,
                      title: isAr ? 'لوحة التحكم المركزية والـ DevOps' : 'Central Admin & DevOps Portal',
                      subtitle: isAr ? 'إدارة الخدمات الست، الضمان المالي، المحاور وFeature Flags' : 'Services, Bilateral Escrow, Corridors & SRE Console',
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onTap: () {
                        final existingAdmin = context.read<AdminProvider?>();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => existingAdmin != null
                                ? const AdminShell()
                                : ChangeNotifierProvider(
                                    create: (_) => AdminProvider(),
                                    child: const AdminShell(),
                                  ),
                          ),
                        );
                      },
                    ),
                    _buildIndentedDivider(),
                    _buildSettingsTile(
                      icon: Icons.developer_mode_rounded,
                      iconColor: AppColors.navy,
                      title: isAr ? 'جاهزية الخادم وحالة النظام' : 'Backend & System Diagnostics',
                      subtitle: isAr ? 'فحص العقود والواجهات البرمجية وحالات النظام' : 'API contracts & system state health check',
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BackendReadinessScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  _buildIndentedDivider(),
                  _buildSettingsTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.danger,
                    title: isAr ? 'حذف الحساب نهائياً' : 'Delete Account Permanently',
                    subtitle: isAr ? 'إلغاء تنشيط الحساب ومسح البيانات الخاصة بك' : 'Deactivate account & erase personal data',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DeleteAccountScreen(),
                        ),
                      );
                    },
                  ),
                ]),
              ],
            );

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1160 : 680),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20, vertical: AppDimens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserProfileCard(context, user, isAr),
                      const SizedBox(height: AppDimens.space20),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  accountGroup,
                                  const SizedBox(height: AppDimens.space20),
                                  preferencesGroup,
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDimens.space24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  notificationsGroup,
                                  const SizedBox(height: AppDimens.space20),
                                  supportLegalGroup,
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        accountGroup,
                        const SizedBox(height: AppDimens.space20),
                        preferencesGroup,
                        const SizedBox(height: AppDimens.space20),
                        notificationsGroup,
                        const SizedBox(height: AppDimens.space20),
                        supportLegalGroup,
                      ],
                      const SizedBox(height: AppDimens.space24),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isWide ? 420 : double.infinity),
                          child: MashwarButton(
                            text: isAr ? 'تسجيل الخروج' : 'Log Out',
                            variant: MashwarButtonVariant.secondary,
                            icon: const Icon(Icons.logout_rounded, color: AppColors.navy, size: 18),
                            onPressed: () => _showLogoutDialog(context, auth, settings),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.space16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'مشوار MASHWAR v2.5.0',
                              style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAr ? 'دولة قطر · جميع الحقوق محفوظة' : 'State of Qatar · All Rights Reserved',
                              style: AppTypography.label(color: const Color(0xFF94A3B8)).copyWith(fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.space24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwitchIconBox(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slateBorder.withValues(alpha: 0.75)),
      ),
      child: Icon(icon, color: AppColors.navy, size: 19),
    );
  }

  Widget _buildUserProfileCard(BuildContext context, UserModel user, bool isAr) {
    final trimmedPhone = user.phone.trim();
    final trimmedEmail = user.email?.trim() ?? '';
    final contactSubtitle = trimmedPhone.isNotEmpty
        ? trimmedPhone
        : (trimmedEmail.isNotEmpty
            ? trimmedEmail
            : (isAr ? 'أضف رقم جوالك' : 'Add your mobile number'));
    final trimmedGovernorate = user.governorate?.trim() ?? '';
    final trimmedCity = user.city?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          MashwarUserAvatar(
            avatarUrl: user.avatarUrl,
            fullName: user.fullName.isNotEmpty ? user.fullName : 'ع',
            size: 52,
            borderWidth: 1.5,
            borderColor: AppColors.slateBorder,
          ),
          const SizedBox(width: AppDimens.space12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: AppTypography.body(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (user.isVerified)
                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.teal),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  contactSubtitle,
                  style: AppTypography.bodySecondary().copyWith(fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (trimmedGovernorate.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    trimmedCity.isNotEmpty
                        ? '$trimmedGovernorate · $trimmedCity'
                        : trimmedGovernorate,
                    style: AppTypography.label(color: const Color(0xFF64748B))
                        .copyWith(fontSize: 11.5, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Edit profile action
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              backgroundColor: AppColors.slateBg,
              side: const BorderSide(color: AppColors.slateBorder, width: 1.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
            child: Text(
              isAr ? 'تعديل' : 'Edit',
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
      child: Text(
        title,
        style: AppTypography.label(color: const Color(0xFF64748B)).copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return MashwarSectionCard(
      padding: EdgeInsets.zero,
      borderRadius: 14,
      borderColor: AppColors.slateBorder,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.slateBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.slateBorder.withValues(alpha: 0.75)),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(
        title,
        style: AppTypography.body(color: AppColors.navy)
            .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11.5),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildIndentedDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 16,
      color: AppColors.slateBorder,
    );
  }
}
