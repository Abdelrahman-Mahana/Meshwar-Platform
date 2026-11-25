import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/user_model.dart';
import '../../data/models/worksite_models.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/worksite_provider.dart';
import '../auth/id_verification_screen.dart';
import '../auth/welcome_screen.dart';
import '../board/board_extra_screens.dart';
import '../settings/settings_screen.dart';
import '../wallet/wallet_screen.dart';
import '../worksite/provider_profile_screen.dart';
import '../worksite/work_request_details_screen.dart';

// الملف الشخصي للمستخدم (User Profile Screen)
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  static const bool _isMvpWorksiteOnly =
      AppEnvironment.enableWorksiteSupply &&
      !AppEnvironment.enablePassengerRides;

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final user = context.watch<AuthProvider>().user;
    final worksite = context.watch<WorksiteProvider?>();
    final isIdVerified = user.idVerificationStatus == IdVerificationStatus.verified;
    final prov = worksite?.providerProfile;
    final uid = worksite?.currentUserId ?? user.id;

    final myRequestsCount = uid.isEmpty || worksite == null
        ? 0
        : worksite.allLoadedRequests
            .where((r) => r.requesterId == uid)
            .length;
    final completedOwnedCount = uid.isEmpty || worksite == null
        ? 0
        : worksite.allLoadedRequests
            .where((r) =>
                (r.requesterId == uid || r.assignedProviderId == uid) &&
                r.status == WorkRequestStatus.completed)
            .length;
    final completedSuppliesCount =
        prov?.completedJobsCount ?? completedOwnedCount;
    final realRating =
        (prov != null && prov.rating > 0) ? prov.rating : user.rating;
    final unreadNotificationsCount = worksite?.unreadNotificationsCount ?? 0;
    final savedSites = worksite?.savedWorksites ?? const <SavedWorksite>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isAr ? 'الملف الشخصي' : 'My Profile', style: AppTypography.title()),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.teal),
            label: Text(
              isAr ? 'تعديل' : 'Edit',
              style: AppTypography.label(color: AppColors.teal).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;

            final heroCard = MashwarFadeSlideIn(
              child: MashwarSectionCard(
                padding: const EdgeInsets.all(AppDimens.space20),
                child: Column(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.navy.withValues(alpha: 0.16), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0] : 'ع',
                          style: AppTypography.largeTitle(color: AppColors.navy).copyWith(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title().copyWith(fontSize: 20),
                          ),
                        ),
                        if (isIdVerified || (prov?.canAcceptWorksiteJobs ?? false)) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: AppColors.teal, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (user.phone.isNotEmpty)
                      Text(user.phone, style: AppTypography.bodySecondary()),
                    if (user.email != null && user.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(user.email!, style: AppTypography.label(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        MashwarBadge(
                          type: isIdVerified ? BadgeType.verified : BadgeType.pending,
                          customLabel: isIdVerified
                              ? (isAr ? 'موثق بالبطاقة القطرية' : 'Qatar ID Verified')
                              : (isAr ? 'غير موثق' : 'Unverified'),
                        ),
                        if (_isMvpWorksiteOnly && prov != null)
                          MashwarBadge(
                            type: prov.approvalStatus == ProviderApprovalStatus.approved
                                ? BadgeType.verified
                                : (prov.approvalStatus == ProviderApprovalStatus.rejected
                                    ? BadgeType.rejected
                                    : BadgeType.pending),
                            customLabel: prov.approvalStatus.label(isArabic: isAr),
                          ),
                        if (user.governorate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              user.city != null ? '${user.governorate} · ${user.city}' : user.governorate!,
                              style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        if (user.occupation != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.tealSurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              user.occupation!,
                              style: AppTypography.label(color: AppColors.teal).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE5E5EA)),
                    const SizedBox(height: 14),
                    if (_isMvpWorksiteOnly)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              '$myRequestsCount',
                              isAr ? 'طلباتي' : 'My Requests',
                            ),
                          ),
                          Container(width: 1, height: 28, color: const Color(0xFFE5E5EA)),
                          Expanded(
                            child: _buildStatItem(
                              '$completedSuppliesCount',
                              isAr ? 'توريدات مكتملة' : 'Completed Jobs',
                            ),
                          ),
                          Container(width: 1, height: 28, color: const Color(0xFFE5E5EA)),
                          Expanded(
                            child: _buildStatItem(
                              realRating > 0 ? '${realRating.toStringAsFixed(1)} ★' : '—',
                              isAr ? 'التقييم' : 'Rating',
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _buildStatItem('${user.completedRides}', isAr ? 'رحلة مكتملة' : 'Rides'),
                          ),
                          Container(width: 1, height: 28, color: const Color(0xFFE5E5EA)),
                          Expanded(
                            child: _buildStatItem('${user.completedParcels}', isAr ? 'طرد مُوصل' : 'Parcels'),
                          ),
                          Container(width: 1, height: 28, color: const Color(0xFFE5E5EA)),
                          Expanded(
                            child: _buildStatItem('${user.rating} ★', isAr ? 'التقييم' : 'Rating'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );

            final preferencesAndAccount = _isMvpWorksiteOnly
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isAr ? 'حالة التوثيق ومواقع العمل' : 'QID Verification & Worksites',
                        style: AppTypography.title().copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      MashwarSectionCard(
                        padding: const EdgeInsets.all(AppDimens.space16),
                        borderRadius: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const MashwarTrustEmblem(
                                  type: MashwarTrustType.qatarIdCrest,
                                  size: 32,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAr
                                            ? 'حالة المزود / البطاقة القطرية (QID)'
                                            : 'Provider / QID Status',
                                        style: AppTypography.label(color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        prov != null
                                            ? prov.approvalStatus.label(isArabic: isAr)
                                            : (isIdVerified
                                                ? (isAr ? 'هوية موثقة' : 'Identity Verified')
                                                : (isAr ? 'حساب طالب توريد' : 'Requester Profile')),
                                        style: AppTypography.body(color: AppColors.navy)
                                            .copyWith(fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F1F4)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    isAr ? 'مواقع العمل المحفوظة' : 'Saved Worksites',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySecondary(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ProviderProfileScreen(
                                          focusSavedWorksites: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    isAr ? 'إدارة' : 'Manage',
                                    style: AppTypography.label(color: AppColors.teal)
                                        .copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (savedSites.isEmpty)
                              Text(
                                isAr
                                    ? 'لم تتم إضافة مواقع عمل محفوظة بعد.'
                                    : 'No saved worksites added yet.',
                                style: AppTypography.bodySmall(),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: savedSites.take(4).map((site) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.sand,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.gold.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      '${site.label} · ${AppStrings.translateCity(site.municipality, isArabic: isAr)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.label(color: AppColors.navy)
                                          .copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.space20),
                      Text(
                        isAr ? 'إدارة الحساب' : 'Account Management',
                        style: AppTypography.title().copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _buildActionTile(
                              icon: Icons.person_outline_rounded,
                              title: isAr ? 'تعديل البيانات الشخصية' : 'Edit Personal Info',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            _buildActionTile(
                              icon: Icons.badge_outlined,
                              title: isAr
                                  ? 'ملف المزود وتوثيق البطاقة القطرية (QID)'
                                  : 'Provider Profile & QID Verification',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ProviderProfileScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            _buildActionTile(
                              icon: Icons.factory_outlined,
                              title: isAr ? 'مواقع العمل المحفوظة' : 'Saved Worksites',
                              trailingText: '${savedSites.length}',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProviderProfileScreen(
                                      focusSavedWorksites: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            _buildActionTile(
                              icon: Icons.notifications_active_outlined,
                              title: isAr ? 'مركز الإشعارات' : 'Notifications Center',
                              trailingText: unreadNotificationsCount > 0
                                  ? '$unreadNotificationsCount'
                                  : null,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const NotificationsCenterScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            _buildActionTile(
                              icon: Icons.support_agent_rounded,
                              title: isAr ? 'المساعدة والدعم' : 'Help & Support',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            _buildActionTile(
                              icon: Icons.settings_outlined,
                              title: isAr ? 'الإعدادات' : 'Settings',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isAr ? 'تفضيلات السفر والبيانات' : 'Travel Preferences & Info',
                        style: AppTypography.title().copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(AppDimens.space16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.smoke_free_rounded,
                              isAr ? 'التدخين' : 'Smoking Preference',
                              user.smokingPreference ?? (isAr ? 'غير مدخن' : 'Non-smoker'),
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F1F4)),
                            _buildInfoRow(
                              Icons.airline_seat_recline_normal_rounded,
                              isAr ? 'طبيعة الرحلة' : 'Trip Vibe',
                              user.tripVibe ?? (isAr ? 'هادئ ومريح' : 'Calm & Comfortable'),
                            ),
                            if (user.emergencyContactName != null) ...[
                              const Divider(height: 20, color: Color(0xFFF1F1F4)),
                              _buildInfoRow(
                                Icons.emergency_outlined,
                                isAr ? 'جهة اتصال الطوارئ' : 'Emergency Contact',
                                '${user.emergencyContactName} (${user.emergencyContactPhone ?? ""})',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.space20),
                      Text(
                        isAr ? 'إدارة الحساب' : 'Account Management',
                        style: AppTypography.title().copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _buildActionTile(
                              icon: Icons.person_outline_rounded,
                              title: isAr ? 'تعديل البيانات الشخصية' : 'Edit Personal Info',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            _buildActionTile(
                              icon: Icons.badge_outlined,
                              title: isAr ? 'توثيق البطاقة الشخصية القطرية (QID)' : 'Qatar ID (QID) Verification',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const IdVerificationScreen(isOnboarding: false)),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            _buildActionTile(
                              icon: Icons.campaign_outlined,
                              title: isAr ? 'إعلاناتي وعروضي في اللوحة' : 'My Board Ads & Offers',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const MyBoardAdsScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            _buildActionTile(
                              icon: Icons.account_balance_wallet_outlined,
                              title: isAr ? 'محفظة مشوار' : 'Wallet',
                              trailingText: '${user.walletBalance.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F1F4)),
                            _buildActionTile(
                              icon: Icons.settings_outlined,
                              title: isAr ? 'الإعدادات' : 'Settings',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1160 : 680),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space20,
                    vertical: AppDimens.space16,
                  ),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: heroCard),
                            const SizedBox(width: AppDimens.space24),
                            Expanded(flex: 6, child: preferencesAndAccount),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            heroCard,
                            const SizedBox(height: AppDimens.space20),
                            preferencesAndAccount,
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

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.label(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.teal),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySecondary(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F3F4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.navy),
      ),
      title: Text(title, style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(trailingText, style: AppTypography.label(color: AppColors.teal).copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }
}

// Page 58: تعديل الملف الشخصي (Edit Profile)
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _govController;
  late TextEditingController _cityController;
  late TextEditingController _occupationController;
  String? _nameError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user.fullName);
    _phoneController = TextEditingController(text: user.phone);
    _govController = TextEditingController(text: user.governorate ?? 'بلدية الدوحة');
    _cityController = TextEditingController(text: user.city ?? 'الدوحة');
    _occupationController = TextEditingController(text: user.occupation ?? 'مهندس برمجيات');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _govController.dispose();
    _cityController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  void _handleSave(bool isAr) async {
    final name = _nameController.text.trim();
    if (!name.contains(' ') || name.split(' ').length < 2) {
      setState(() {
        _nameError = isAr ? 'اكتب اسمك بالكامل (اسمين على الأقل)' : 'Please enter your full name (at least 2 words)';
      });
      return;
    }

    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      context.read<AuthProvider>().updateProfile(
            fullName: name,
            governorate: _govController.text.trim(),
            city: _cityController.text.trim(),
            occupation: _occupationController.text.trim(),
          );
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم حفظ التعديلات بنجاح' : 'Profile updated successfully'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isAr ? 'تعديل الملف الشخصي' : 'Edit Profile', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar with Gold Accent Ring
              Center(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.goldSurface,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0] : 'ع',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space24),

              Text(isAr ? 'الاسم الكامل' : 'Full Name', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF3F3F4),
                  errorText: _nameError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              Text(isAr ? 'رقم الجوال' : 'Mobile Number', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF3F3F4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAr ? 'يتطلب تغيير رقم الجوال رمز تأكيد جديد.' : 'Changing mobile number requires SMS OTP verification.',
                style: AppTypography.label(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimens.space16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? 'البلدية / المنطقة' : 'Municipality', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _govController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F3F4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? 'المدينة / المركز' : 'City', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F3F4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space16),

              Text(isAr ? 'المهنة / التخصص' : 'Occupation', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _occupationController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF3F3F4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
                ),
              ),

              const SizedBox(height: AppDimens.space32),
              MashwarButton(
                text: _isSaving ? (isAr ? 'جاري الحفظ...' : 'Saving...') : (isAr ? 'حفظ' : 'Save Changes'),
                isLoading: _isSaving,
                onPressed: () => _handleSave(isAr),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 60: المساعدة والدعم (Help & Support FAQ)
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const bool _isMvpWorksiteOnly =
      AppEnvironment.enableWorksiteSupply &&
      !AppEnvironment.enablePassengerRides;

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    final faqs = _isMvpWorksiteOnly
        ? (isAr
            ? [
                {
                  'q': 'كيف أنشئ طلب توريد لموقع العمل؟',
                  'a': 'اضغط «إنشاء طلب توريد»، حدد الفئة والمواد والكمية، اختر موقع العمل المحفوظ أو أدخل الموقع في قطر، ثم حدد الميزانية التقديرية وأجرة التوصيل بالريال القطري (QAR).',
                },
                {
                  'q': 'كيف يتم اعتماد مزودي التوريد في قطر؟',
                  'a': 'يرفع المزود البطاقة الشخصية القطرية (QID من 11 خانة) ومناطق الخدمة والتخصصات، ولا يُسمح له بتقديم عروض أو قبول مهام إلا بعد المراجعة والاعتماد.',
                },
                {
                  'q': 'كيف أضمن مطابقة المشتريات والفاتورة؟',
                  'a': 'يلتزم المزود بإرفاق صورة فاتورة الشراء الفعلية وعدم تجاوز السقف الأقصى المعتمد للمواد (QAR) دون موافقتك.',
                },
                {
                  'q': 'كيف يعمل رمز التسليم السري (6 خانات)؟',
                  'a': 'بعد ترسية العرض يظهر رمز سري من 6 خانات لدى طالب التوريد فقط؛ عند وصول المواد لبوابة الموقع ومطابقة الفاتورة تسلمه للمزود لإغلاق الطلب كمكتمل.',
                },
                {
                  'q': 'ما طرق الدفع المتاحة في المرحلة التجريبية؟',
                  'a': 'تتوفر حالياً خدمة الدفع نقداً عند الاستلام (COD) أو التحويل البنكي اليدوي مع رفع إيصال التحويل، ولا توجد محفظة رقمية مفعّلة في هذه المرحلة.',
                },
              ]
            : [
                {
                  'q': 'How do I create a worksite supply request?',
                  'a': 'Tap "Create a Request", select the supply category and items, pick a saved Qatar worksite or enter delivery details, and set QAR item cap and delivery fee.',
                },
                {
                  'q': 'How are Qatar supply providers verified?',
                  'a': 'Providers submit their 11-digit Qatar ID (QID), service municipalities, and specialties for review. Only approved providers can submit offers.',
                },
                {
                  'q': 'How are material purchases and store invoices verified?',
                  'a': 'Providers attach the actual store purchase receipt image and total in QAR within your approved maximum item cap.',
                },
                {
                  'q': 'How does the 6-character handover code work?',
                  'a': 'Once an offer is accepted, a private 6-char handover code is generated for the requester. Share it at the worksite gate after verifying items and invoice to close the order.',
                },
                {
                  'q': 'Which settlement methods are supported in Pilot Phase 1?',
                  'a': 'Cash on Delivery (COD) and Manual Bank Transfer with proof tracking are supported in QAR. In-app digital wallet custody remains disabled in Phase 1.',
                },
              ])
        : (isAr
            ? [
                {'q': 'كيف أحجز مقعداً؟', 'a': 'ابحث عن خط سيرك، اختر السائق الأنسب، واضغط حجز مقعد. لدى السائق 30 دقيقة للموافقة.'},
                {'q': 'كيف أرسل طرداً؟', 'a': 'اختر خدمة الطرود، حدد الحجم والوزن وموقع الاستلام والتسليم، وأتمم التسليم برمز التحقق OTP.'},
                {'q': 'ماذا لو لم يحضر السائق؟', 'a': 'يمكنك تسجيل "لم يحضر" بعد 15 دقيقة من الموعد، وسيتم إلغاء الحجز واسترداد المبلغ فوراً.'},
                {'q': 'كيف أوثق حسابي كسائق؟', 'a': 'ادخل إلى حسابك واضغط توثيق السائق، ثم ارفع البطاقة الشخصية القطرية (QID) ورخص القيادة والمركبة.'},
              ]
            : [
                {'q': 'How do I book a seat?', 'a': 'Search your corridor, pick a verified driver, and request seat. Driver has 30 mins to confirm.'},
                {'q': 'How do I send a parcel?', 'a': 'Toggle parcels mode, select package size & weight, and hand over to verified driver with OTP.'},
                {'q': 'What if the driver does not show up?', 'a': 'Mark as "No Show" 15 mins past schedule. Booking is cancelled with zero penalty.'},
                {'q': 'How do I verify as a driver?', 'a': 'Go to account, select driver verification, and upload your Qatar ID (QID) and valid licenses.'},
              ]);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isAr ? 'المساعدة والدعم' : 'Help & Support', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: MashwarFadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isMvpWorksiteOnly) ...[
                      MashwarSectionCard(
                        backgroundColor: AppColors.sand,
                        borderColor: AppColors.gold.withValues(alpha: 0.35),
                        padding: const EdgeInsets.all(14),
                        borderRadius: 14,
                        child: Row(
                          children: [
                            const MashwarTrustEmblem(
                              type: MashwarTrustType.handoverShield,
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr
                                        ? 'مركز عمليات توريد المواقع · قطر'
                                        : 'Qatar Worksite Operations Desk',
                                    style: AppTypography.label(color: AppColors.navy)
                                        .copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ops@mashwar.qa · +974 4400 9999',
                                    style: AppTypography.bodySmall(color: AppColors.teal)
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      isAr ? 'أسئلة شائعة' : 'Frequently Asked Questions',
                      style: AppTypography.title().copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView(
                        children: faqs.map((f) {
                          return MashwarSectionCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: EdgeInsets.zero,
                            borderRadius: 14,
                            child: ExpansionTile(
                              title: Text(
                                f['q']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(f['a']!, style: AppTypography.bodySecondary()),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    MashwarButton(
                      text: isAr ? 'محادثة مباشرة عبر واتساب' : 'Chat via WhatsApp Support',
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        final uri = Uri.parse('https://wa.me/97444009999');
                        bool launched = false;
                        try {
                          launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          launched = false;
                        }
                        if (!launched) {
                          messenger?.showSnackBar(
                            SnackBar(
                              content: Text(
                                isAr
                                    ? 'تعذّر فتح واتساب تلقائياً. تواصل معنا على +974 4400 9999'
                                    : 'Unable to launch WhatsApp automatically. Contact +974 4400 9999.',
                              ),
                              backgroundColor: AppColors.navy,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        final targetPhone = _isMvpWorksiteOnly ? '+97444009999' : '19884';
                        final uri = Uri(scheme: 'tel', path: targetPhone);
                        bool launched = false;
                        try {
                          launched = await launchUrl(uri);
                        } catch (_) {
                          launched = false;
                        }
                        if (!launched) {
                          messenger?.showSnackBar(
                            SnackBar(
                              content: Text(
                                _isMvpWorksiteOnly
                                    ? (isAr
                                        ? 'لا يدعم هذا الجهاز الاتصال المباشر. تواصل مع دعم مشوار قطر على +974 4400 9999.'
                                        : 'This device lacks a phone handler. Contact MASHWAR Qatar Support at +974 4400 9999.')
                                    : (isAr
                                        ? 'لا يدعم هذا الجهاز الاتصال المباشر. اتصل بالخط الساخن 19884 من هاتفك.'
                                        : 'This device lacks a phone handler. Dial 19884 on your phone.'),
                              ),
                              backgroundColor: AppColors.navy,
                            ),
                          );
                        }
                      },
                      label: Text(
                        _isMvpWorksiteOnly
                            ? (isAr
                                ? 'الاتصال بدعم قطر (+974 4400 9999)'
                                : 'Call Qatar Support (+974 4400 9999)')
                            : (isAr ? 'الاتصال بالخط الساخن' : 'Call Support Hotline'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_isMvpWorksiteOnly) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.teal,
                          side: BorderSide(color: AppColors.teal.withValues(alpha: 0.45)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.mail_outline_rounded, size: 18),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          final uri = Uri(
                            scheme: 'mailto',
                            path: 'ops@mashwar.qa',
                            query: 'subject=MASHWAR%20Qatar%20Worksite%20Support',
                          );
                          bool launched = false;
                          try {
                            launched = await launchUrl(uri);
                          } catch (_) {
                            launched = false;
                          }
                          if (!launched) {
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAr
                                      ? 'راسل فريق العمليات مباشرة على ops@mashwar.qa'
                                      : 'Email our operations desk directly at ops@mashwar.qa',
                                ),
                                backgroundColor: AppColors.navy,
                              ),
                            );
                          }
                        },
                        label: Text(
                          isAr
                              ? 'مراسلة العمليات (ops@mashwar.qa)'
                              : 'Email Operations (ops@mashwar.qa)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimens.space16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Page 61: حذف الحساب ومانع الحذف الفعلي (Delete Account Screen)
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const Set<WorkRequestStatus> _activeBlockingStatuses = {
    WorkRequestStatus.accepted,
    WorkRequestStatus.inProgress,
    WorkRequestStatus.pickedUp,
    WorkRequestStatus.inTransit,
    WorkRequestStatus.deliveredPendingConfirmation,
    WorkRequestStatus.disputed,
  };

  final TextEditingController _confirmController = TextEditingController();
  bool _serverRejectedActiveRequests = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ws = context.read<WorksiteProvider?>();
      if (ws != null && ws.allLoadedRequests.isEmpty && !ws.isLoading) {
        ws.loadRequests();
      }
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  List<WorkRequest> _findActiveBlockingRequests(
    WorksiteProvider? worksite,
    String uid,
  ) {
    if (worksite == null || uid.trim().isEmpty) return const [];
    return worksite.allLoadedRequests.where((req) {
      final isParticipant =
          req.requesterId == uid || req.assignedProviderId == uid;
      return isParticipant && _activeBlockingStatuses.contains(req.status);
    }).toList();
  }

  Future<void> _handleConfirmDelete(
    BuildContext context,
    AuthProvider auth,
    List<WorkRequest> activeRequests,
    bool isAr,
  ) async {
    final text = _confirmController.text.trim();
    if (text != 'حذف' && text.toLowerCase() != 'delete') {
      setState(() {
        _errorMessage = isAr
            ? 'يرجى كتابة كلمة «حذف» أو "delete" للتأكيد أولاً.'
            : 'Please type "delete" to confirm account deletion first.';
      });
      return;
    }

    setState(() => _errorMessage = null);

    final ok = await auth.deleteAccount(
      reason: 'Self-service account deletion from DeleteAccountScreen',
      activeBlockingRequestIds: activeRequests.map((r) => r.id),
    );
    if (!context.mounted) return;

    if (ok) {
      context.read<WorksiteProvider?>()?.syncAuthSession(uid: null);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
      return;
    }

    final ex = auth.lastAuthException;
    setState(() {
      if (ex?.code == 'failed-precondition') {
        _serverRejectedActiveRequests = true;
      }
      _errorMessage = auth.localizedError(isArabic: isAr) ??
          (isAr
              ? 'تعذّر حذف الحساب حالياً. يرجى المحاولة لاحقاً.'
              : 'Unable to delete account right now. Please try again.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final auth = context.watch<AuthProvider>();
    final worksite = context.watch<WorksiteProvider?>();
    final uid = auth.user.id.trim().isNotEmpty
        ? auth.user.id.trim()
        : (worksite?.currentUserId ?? '');
    final activeBlockingRequests = _findActiveBlockingRequests(worksite, uid);
    final isBlocked =
        activeBlockingRequests.isNotEmpty || _serverRejectedActiveRequests;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'حذف الحساب' : 'Delete Account',
          style: AppTypography.title(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: isBlocked
                  ? _buildActiveRequestsBlockerView(
                      context,
                      activeBlockingRequests,
                      isAr,
                    )
                  : _buildConfirmationView(
                      context,
                      auth,
                      activeBlockingRequests,
                      isAr,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRequestsBlockerView(
    BuildContext context,
    List<WorkRequest> activeRequests,
    bool isAr,
  ) {
    return Column(
      key: const ValueKey('delete_account_blocker_card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFB45309), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorMessage ??
                      (isAr
                          ? 'لا يمكن حذف الحساب حالياً لوجود طلبات توريد نشطة مرتبطة بحسابك. يرجى إتمامها أو تسويتها أولاً.'
                          : 'Cannot delete account right now: You have active worksite supply requests that must be completed or resolved first.'),
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...activeRequests.map(
          (req) => Container(
            key: ValueKey('delete_blocker_req_${req.id}'),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      req.title,
                      style: AppTypography.body(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    MashwarBadge(
                      type: req.status == WorkRequestStatus.disputed
                          ? BadgeType.rejected
                          : BadgeType.confirmed,
                      customLabel: req.status.label(isArabic: isAr),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${req.pickupLocation} → ${req.dropoffWorksite}',
                  style: AppTypography.bodySmall(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkRequestDetailsScreen(requestId: req.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded,
                        size: 15, color: AppColors.teal),
                    label: Text(
                      isAr ? 'فتح تفاصيل الطلب' : 'Open Request Details',
                      style: AppTypography.label(color: AppColors.teal)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_serverRejectedActiveRequests && activeRequests.isEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('delete_account_retry_btn'),
            onPressed: () {
              setState(() {
                _serverRejectedActiveRequests = false;
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: Text(
              isAr ? 'إعادة التحقق والمحاولة' : 'Re-check & Retry Deletion',
            ),
          ),
        ],
        const SizedBox(height: 16),
        MashwarButton(
          key: const ValueKey('delete_account_back_btn'),
          text: isAr ? 'الرجوع لإدارة الطلبات' : 'Back to Manage Requests',
          variant: MashwarButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildConfirmationView(
    BuildContext context,
    AuthProvider auth,
    List<WorkRequest> activeRequests,
    bool isAr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.dangerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3), width: 0.8),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr
                      ? 'الحذف نهائي ولا يمكن استرجاع الحساب'
                      : 'Account deletion is permanent and irreversible',
                  style: AppTypography.bodySecondary(color: AppColors.danger)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isAr
              ? 'سيتم حذف ملفك الشخصي وملف المزود وبيانات التوثيق وحساب المصادقة نهائياً عبر الخادم، مع الاحتفاظ بسجلات التدقيق القانونية وفقاً للقانون القطري لحماية خصوصية البيانات رقم 13 لسنة 2016.'
              : 'Your user profile, provider/business records, QID verification record, and authentication account will be permanently deleted on the server. Mandatory audit records are retained per Qatar Personal Data Privacy Law No. 13 of 2016.',
          style: AppTypography.bodySecondary().copyWith(fontSize: 13),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('delete_account_error_banner'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
            ),
            child: Text(
              _errorMessage!,
              style: AppTypography.label(color: AppColors.danger)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          isAr ? 'اكتب كلمة «حذف» للتأكيد:' : 'Type "delete" to confirm:',
          style: AppTypography.label().copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('delete_account_confirm_input'),
          controller: _confirmController,
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
          decoration: InputDecoration(
            hintText: isAr ? 'حذف' : 'delete',
            filled: true,
            fillColor: AppColors.chipInactiveBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide:
                  const BorderSide(color: AppColors.borderDisabled, width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide:
                  const BorderSide(color: AppColors.borderDisabled, width: 0.8),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space32),
        MashwarButton(
          key: const ValueKey('delete_account_submit_btn'),
          text:
              isAr ? 'حذف الحساب نهائياً' : 'Delete My Account Permanently',
          variant: MashwarButtonVariant.danger,
          isLoading: auth.isLoading,
          onPressed: () => _handleConfirmDelete(
            context,
            auth,
            activeRequests,
            isAr,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            isAr ? 'إلغاء والرجوع' : 'Cancel',
            style: AppTypography.body().copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// Page 62: مركز الإشعارات (Notifications Center)
class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  bool _unreadOnly = false;
  bool _didLoadInitial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didLoadInitial) return;
      _didLoadInitial = true;
      final ws = context.read<WorksiteProvider?>();
      if (ws != null && ws.notifications.isEmpty) {
        ws.loadNotifications();
      }
    });
  }

  (IconData, Color, Color) _iconForType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'new_offer':
        return (
          Icons.local_offer_outlined,
          AppColors.teal,
          AppColors.tealSurface,
        );
      case 'handover_pending':
        return (
          Icons.key_rounded,
          AppColors.warning,
          AppColors.goldSurface,
        );
      case 'dispute_alert':
        return (
          Icons.report_problem_outlined,
          AppColors.danger,
          AppColors.dangerBg,
        );
      case 'request_completed':
        return (
          Icons.task_alt_rounded,
          AppColors.escrowGreen,
          AppColors.escrowSurface,
        );
      case 'status_update':
      default:
        return (
          Icons.local_shipping_outlined,
          AppColors.info,
          AppColors.infoBg,
        );
    }
  }

  String _formatTimestamp(DateTime createdAt, bool isAr) {
    final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
    if (diff.inMinutes < 1) {
      return isAr ? 'الآن' : 'Just now';
    }
    if (diff.inMinutes < 60) {
      return isAr ? 'منذ ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isAr ? 'منذ ${diff.inHours} س' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return isAr ? 'منذ ${diff.inDays} ي' : '${diff.inDays}d ago';
    }
    final local = createdAt.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final worksite = context.watch<WorksiteProvider?>();
    final allItems = worksite?.notifications ?? const <WorksiteNotificationItem>[];
    final unreadCount = worksite?.unreadNotificationsCount ?? 0;
    final displayed = _unreadOnly
        ? allItems.where((n) => !n.isRead).toList()
        : allItems;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                isAr ? 'الإشعارات' : 'Notifications',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title(),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.qatarMaroonSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.qatarMaroon.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '$unreadCount',
                  style: AppTypography.label(color: AppColors.qatarMaroon)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: worksite == null
                  ? null
                  : () => worksite.markAllNotificationsRead(),
              child: Text(
                isAr ? 'تحديد الكل كمقروء' : 'Mark All Read',
                style: AppTypography.label(color: AppColors.teal)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.space16, 10, AppDimens.space16, 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: !_unreadOnly,
                        onSelected: (_) => setState(() => _unreadOnly = false),
                        label: Text(
                          isAr
                              ? 'الكل (${allItems.length})'
                              : 'All (${allItems.length})',
                        ),
                      ),
                      FilterChip(
                        selected: _unreadOnly,
                        onSelected: (_) => setState(() => _unreadOnly = true),
                        label: Text(
                          isAr
                              ? 'غير مقروءة ($unreadCount)'
                              : 'Unread ($unreadCount)',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.navy,
                    onRefresh: () async {
                      await worksite?.loadNotifications();
                    },
                    child: displayed.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(AppDimens.space24),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: (constraints.maxHeight - 48)
                                        .clamp(0.0, double.infinity),
                                  ),
                                  child: Center(
                                    child: MashwarSectionCard(
                                      padding: const EdgeInsets.all(
                                          AppDimens.space24),
                                      borderRadius: 18,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const MashwarTrustEmblem(
                                            type: MashwarTrustType.liveCorridor,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _unreadOnly
                                                ? (isAr
                                                    ? 'لا توجد تنبيهات غير مقروءة'
                                                    : 'No Unread Alerts')
                                                : (isAr
                                                    ? 'لا توجد إشعارات حالياً'
                                                    : 'No Notifications Yet'),
                                            textAlign: TextAlign.center,
                                            style: AppTypography.title()
                                                .copyWith(fontSize: 16),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            isAr
                                                ? 'ستظهر هنا تحديثات العروض وحالة التوريد ورموز التسليم الخاصة بطلباتك في قطر.'
                                                : 'Offer alerts, worksite delivery updates, and handover notifications will appear here.',
                                            textAlign: TextAlign.center,
                                            style: AppTypography.bodySecondary(),
                                          ),
                                          if (_unreadOnly &&
                                              allItems.isNotEmpty) ...[
                                            const SizedBox(height: 14),
                                            OutlinedButton(
                                              onPressed: () => setState(
                                                  () => _unreadOnly = false),
                                              child: Text(
                                                isAr
                                                    ? 'عرض كل الإشعارات'
                                                    : 'Show All Notifications',
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppDimens.space16),
                            itemCount: displayed.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final n = displayed[index];
                              final visual = _iconForType(n.type);
                              final isUnread = !n.isRead;
                              return MashwarFadeSlideIn(
                                offsetY: 8,
                                child: MashwarHoverCard(
                                  backgroundColor: isUnread
                                      ? const Color(0xFFF8FAFC)
                                      : Colors.white,
                                  borderColor: isUnread
                                      ? visual.$2.withValues(alpha: 0.45)
                                      : const Color(0xFFE5E5EA),
                                  hoverBorderColor: visual.$2,
                                  padding:
                                      const EdgeInsets.all(AppDimens.space16),
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    worksite?.markNotificationRead(n.id);
                                    final reqId = n.requestId?.trim();
                                    if (reqId != null && reqId.isNotEmpty) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              WorkRequestDetailsScreen(
                                            requestId: reqId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: visual.$3,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          visual.$1,
                                          color: visual.$2,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    n.localizedTitle(
                                                        isArabic: isAr),
                                                    style: TextStyle(
                                                      fontWeight: isUnread
                                                          ? FontWeight.w800
                                                          : FontWeight.w600,
                                                      fontSize: 14,
                                                      color: AppColors.navy,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatTimestamp(
                                                      n.createdAt, isAr),
                                                  style: AppTypography.label(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ).copyWith(fontSize: 11),
                                                ),
                                                if (isUnread) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            top: 4),
                                                    decoration: BoxDecoration(
                                                      color: visual.$2,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              n.localizedBody(isArabic: isAr),
                                              style:
                                                  AppTypography.bodySecondary()
                                                      .copyWith(fontSize: 12.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
