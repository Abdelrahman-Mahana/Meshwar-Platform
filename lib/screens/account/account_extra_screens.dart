import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/user_model.dart';
import '../../data/models/worksite_models.dart';
import '../../state/auth_provider.dart';
import '../../state/board_provider.dart';
import '../../state/parcels_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/worksite_provider.dart';
import '../auth/welcome_screen.dart';
import '../board/board_extra_screens.dart';
import '../driver/driver_rides_management_screens.dart';
import '../settings/settings_screen.dart';
import '../worksite/provider_profile_screen.dart';
import '../worksite/work_request_details_screen.dart';

// الملف الشخصي للمستخدم (Unified International 3-Service User Profile Screen)
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final user = context.watch<AuthProvider>().user;
    final worksite = context.watch<WorksiteProvider?>();
    final rides = context.watch<RidesProvider?>();
    final parcels = context.watch<ParcelsProvider?>();
    final board = context.watch<BoardProvider?>();
    final isIdVerified =
        user.idVerificationStatus == IdVerificationStatus.verified;
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
    final publishedTripsCount = rides?.myPublishedRides.length ?? 0;
    final activeParcelsCount = parcels?.parcels.length ?? 0;
    final routeAdsCount = board?.myAds.length ?? 0;
    final realRating =
        (prov != null && prov.rating > 0) ? prov.rating : user.rating;
    final unreadNotificationsCount = worksite?.unreadNotificationsCount ?? 0;
    final savedSites = worksite?.savedWorksites ?? const <SavedWorksite>[];

    final metaParts = <String>[
      if (user.phone.trim().isNotEmpty) user.phone.trim(),
      if (user.city != null && user.city!.trim().isNotEmpty)
        user.city!.trim()
      else if (user.governorate != null && user.governorate!.trim().isNotEmpty)
        user.governorate!.trim(),
      if (user.occupation != null && user.occupation!.trim().isNotEmpty)
        user.occupation!.trim(),
    ];
    final metaLine = metaParts.join(' · ');

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'الملف الشخصي' : 'My Profile',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              icon: const Icon(Icons.edit_outlined,
                  size: 17, color: AppColors.navy),
              label: Text(
                isAr ? 'تعديل' : 'Edit',
                style: AppTypography.label(color: AppColors.navy)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space20,
                  vertical: 22,
                ),
                borderRadius: 16,
                borderColor: AppColors.slateBorder,
                child: Column(
                  children: [
                    MashwarUserAvatar(
                      key: const ValueKey('user_profile_avatar_btn'),
                      avatarUrl: user.avatarUrl,
                      fullName: user.fullName.isNotEmpty
                          ? user.fullName
                          : (isAr ? 'عضو مشوار' : 'MASHWAR Member'),
                      size: 80,
                      borderWidth: 1.8,
                      borderColor: AppColors.slateBorder,
                      showCameraBadge: true,
                      onTap: () => pickAndSaveCurrentUserAvatar(context),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const ValueKey('user_profile_change_photo_btn'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => pickAndSaveCurrentUserAvatar(context),
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      label: Text(
                        (user.avatarUrl != null &&
                                user.avatarUrl!.trim().isNotEmpty)
                            ? (isAr ? 'تغيير الصورة الشخصية' : 'Change Photo')
                            : (isAr
                                ? 'إضافة صورة شخصية'
                                : 'Add Profile Photo'),
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName
                                : (isAr ? 'عضو مشوار' : 'MASHWAR Member'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title().copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isIdVerified ||
                            (prov?.canAcceptWorksiteJobs ?? false)) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: AppColors.teal, size: 19),
                        ],
                      ],
                    ),
                    if (metaLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySecondary()
                            .copyWith(fontSize: 12.5),
                      ),
                    ],
                    if (user.email != null && user.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(
                          color: AppColors.textSecondary,
                        ).copyWith(fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 10),
                    MashwarBadge(
                      type: isIdVerified
                          ? BadgeType.verified
                          : BadgeType.pending,
                      customLabel: isIdVerified
                          ? (isAr ? 'هوية موثّقة' : 'Identity Verified')
                          : (isAr ? 'بانتظار التوثيق' : 'Unverified'),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: AppColors.slateBorder),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            '$publishedTripsCount',
                            isAr ? 'رحلات' : 'Trips',
                          ),
                        ),
                        _buildStatDivider(),
                        Expanded(
                          child: _buildStatItem(
                            '$activeParcelsCount',
                            isAr ? 'طرود' : 'Packages',
                          ),
                        ),
                        _buildStatDivider(),
                        Expanded(
                          child: _buildStatItem(
                            '$completedSuppliesCount',
                            isAr ? 'مهام مكتملة' : 'Completed Jobs',
                          ),
                        ),
                        _buildStatDivider(),
                        Expanded(
                          child: _buildStatItem(
                            realRating > 0
                                ? '${realRating.toStringAsFixed(1)} ★'
                                : '—',
                            isAr ? 'التقييم' : 'Rating',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            final preferencesAndAccount = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 4, end: 4, bottom: 8),
                  child: Text(
                    isAr
                        ? 'حالة التوثيق والمواقع المحفوظة'
                        : 'QID Verification & Worksites',
                    style: AppTypography.label(color: const Color(0xFF64748B))
                        .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
                MashwarSectionCard(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  borderRadius: 14,
                  borderColor: AppColors.slateBorder,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProviderProfileScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.tealSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.teal.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.verified_user_outlined,
                                size: 18,
                                color: AppColors.teal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr
                                        ? 'توثيق الهوية القطرية والمزود'
                                        : 'QID & Provider Verification',
                                    style: AppTypography.body(
                                      color: AppColors.navy,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    prov != null
                                        ? prov.approvalStatus
                                            .label(isArabic: isAr)
                                        : (isIdVerified
                                            ? (isAr
                                                ? 'هوية موثّقة ومعتمدة'
                                                : 'Verified Identity')
                                            : (isAr
                                                ? 'عضو نشط · اضغط لإكمال التوثيق'
                                                : 'Active Member · Tap to verify QID')),
                                    style: AppTypography.label(
                                      color: AppColors.textSecondary,
                                    ).copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 22, color: AppColors.slateBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isAr ? 'المواقع المحفوظة' : 'Saved Worksites',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(color: AppColors.navy)
                                  .copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.navy,
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
                              style: AppTypography.label(color: AppColors.navy)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (savedSites.isEmpty)
                        Text(
                          isAr
                              ? 'لا توجد مواقع محفوظة بعد.'
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
                                  horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: AppColors.slateBg,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: AppColors.slateBorder),
                              ),
                              child: Text(
                                '${site.label} · ${AppStrings.translateCity(site.municipality, isArabic: isAr)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(color: AppColors.navy)
                                    .copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.space20),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 4, end: 4, bottom: 8),
                  child: Text(
                    isAr ? 'إدارة الحساب والخدمات' : 'Account & Services',
                    style: AppTypography.label(color: const Color(0xFF64748B))
                        .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                        color: AppColors.slateBorder, width: 1.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildActionTile(
                        icon: Icons.assignment_outlined,
                        title: isAr ? 'طلباتي للتوريد والمهام' : 'My Requests',
                        trailingText:
                            myRequestsCount > 0 ? '$myRequestsCount' : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ProviderProfileScreen()),
                          );
                        },
                      ),
                      _buildIndentedDivider(),
                      _buildActionTile(
                        icon: Icons.directions_car_outlined,
                        title: isAr
                            ? 'رحلاتي المنشورة'
                            : 'My Published Trips',
                        trailingText: publishedTripsCount > 0
                            ? '$publishedTripsCount'
                            : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const DriverRidesScreen()),
                          );
                        },
                      ),
                      _buildIndentedDivider(),
                      _buildActionTile(
                        icon: Icons.route_outlined,
                        title: isAr
                            ? 'طلبات المسار والتوصيل'
                            : 'Route & Delivery Requests',
                        trailingText:
                            routeAdsCount > 0 ? '$routeAdsCount' : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MyBoardAdsScreen()),
                          );
                        },
                      ),
                      _buildIndentedDivider(),
                      _buildActionTile(
                        icon: Icons.notifications_none_rounded,
                        title: isAr
                            ? 'مركز الإشعارات'
                            : 'Notifications Center',
                        trailingText: unreadNotificationsCount > 0
                            ? '$unreadNotificationsCount'
                            : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationsCenterScreen()),
                          );
                        },
                      ),
                      _buildIndentedDivider(),
                      _buildActionTile(
                        icon: Icons.tune_rounded,
                        title: isAr ? 'الإعدادات' : 'Settings',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      _buildIndentedDivider(),
                      _buildActionTile(
                        icon: Icons.support_agent_rounded,
                        title: isAr ? 'المساعدة والدعم' : 'Help & Support',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const HelpSupportScreen()),
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

  Widget _buildStatDivider() {
    return Container(width: 1, height: 26, color: AppColors.slateBorder);
  }

  Widget _buildIndentedDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
      color: AppColors.slateBorder,
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.title(color: AppColors.navy).copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.label(color: AppColors.textSecondary).copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.slateBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.slateBorder.withValues(alpha: 0.75),
          ),
        ),
        child: Icon(icon, size: 18, color: AppColors.navy),
      ),
      title: Text(
        title,
        style: AppTypography.body(color: AppColors.navy)
            .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Text(
                trailingText,
                style: AppTypography.label(color: AppColors.navy).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Color(0xFF94A3B8),
          ),
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
  String? _avatarUrl;
  bool _avatarChanged = false;
  String? _nameError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user.fullName);
    _phoneController = TextEditingController(text: user.phone);
    _govController =
        TextEditingController(text: user.governorate ?? 'بلدية الدوحة');
    _cityController = TextEditingController(text: user.city ?? 'الدوحة');
    _occupationController =
        TextEditingController(text: user.occupation ?? 'مهندس مشاريع');
    _avatarUrl = user.avatarUrl;
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
        _nameError = isAr
            ? 'اكتب اسمك بالكامل (اسمين على الأقل)'
            : 'Please enter your full name (at least 2 words)';
      });
      return;
    }

    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      final auth = context.read<AuthProvider>();
      auth.updateProfile(
        fullName: name,
        governorate: _govController.text.trim(),
        city: _cityController.text.trim(),
        occupation: _occupationController.text.trim(),
        avatarUrl: _avatarChanged ? _avatarUrl : null,
        clearAvatar: _avatarChanged &&
            (_avatarUrl == null || _avatarUrl!.trim().isEmpty),
      );
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تم حفظ التعديلات بنجاح' : 'Profile updated successfully',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  InputDecoration _fieldDecoration({
    String? errorText,
    bool readOnly = false,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: readOnly ? AppColors.slateBg : Colors.white,
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.slateBorder, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.slateBorder, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final user = context.watch<AuthProvider>().user;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space20),
              child: MashwarSectionCard(
                padding: const EdgeInsets.all(AppDimens.space20),
                borderRadius: 16,
                borderColor: AppColors.slateBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          MashwarUserAvatar(
                            key: const ValueKey('edit_profile_avatar_btn'),
                            avatarUrl:
                                _avatarChanged ? _avatarUrl : user.avatarUrl,
                            fullName: _nameController.text.trim().isNotEmpty
                                ? _nameController.text.trim()
                                : user.fullName,
                            size: 82,
                            borderWidth: 1.8,
                            borderColor: AppColors.slateBorder,
                            showCameraBadge: true,
                            onTap: () {
                              showMashwarAvatarPickerSheet(
                                context,
                                currentAvatarUrl: _avatarChanged
                                    ? _avatarUrl
                                    : user.avatarUrl,
                                fullName: _nameController.text.trim().isNotEmpty
                                    ? _nameController.text.trim()
                                    : user.fullName,
                                onAvatarSelected: (picked) {
                                  setState(() {
                                    _avatarUrl = picked;
                                    _avatarChanged = true;
                                  });
                                  context
                                      .read<AuthProvider>()
                                      .updateAvatar(picked);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            key: const ValueKey(
                                'edit_profile_change_photo_btn'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.navy,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              showMashwarAvatarPickerSheet(
                                context,
                                currentAvatarUrl: _avatarChanged
                                    ? _avatarUrl
                                    : user.avatarUrl,
                                fullName: _nameController.text.trim().isNotEmpty
                                    ? _nameController.text.trim()
                                    : user.fullName,
                                onAvatarSelected: (picked) {
                                  setState(() {
                                    _avatarUrl = picked;
                                    _avatarChanged = true;
                                  });
                                  context
                                      .read<AuthProvider>()
                                      .updateAvatar(picked);
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            label: Text(
                              isAr
                                  ? 'رفع أو تغيير الصورة الشخصية'
                                  : 'Upload or Change Profile Photo',
                              style: AppTypography.label(color: AppColors.navy)
                                  .copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space20),
                    Text(
                      isAr ? 'الاسم الكامل' : 'Full Name',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: _fieldDecoration(errorText: _nameError),
                    ),
                    const SizedBox(height: AppDimens.space16),
                    Text(
                      isAr ? 'رقم الجوال' : 'Mobile Number',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      readOnly: true,
                      decoration: _fieldDecoration(readOnly: true),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? 'يتطلب تغيير رقم الجوال رمز تأكيد جديد.'
                          : 'Changing mobile number requires SMS OTP verification.',
                      style: AppTypography.label(color: AppColors.textSecondary)
                          .copyWith(fontSize: 11.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppDimens.space16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr
                                    ? 'المنطقة / البلدية'
                                    : 'Region / Municipality',
                                style:
                                    AppTypography.label(color: AppColors.navy)
                                        .copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _govController,
                                decoration: _fieldDecoration(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'المدينة' : 'City',
                                style:
                                    AppTypography.label(color: AppColors.navy)
                                        .copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _cityController,
                                decoration: _fieldDecoration(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space16),
                    Text(
                      isAr ? 'المهنة / التخصص' : 'Occupation',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _occupationController,
                      decoration: _fieldDecoration(),
                    ),
                    const SizedBox(height: AppDimens.space24),
                    MashwarButton(
                      text: _isSaving
                          ? (isAr ? 'جاري الحفظ...' : 'Saving...')
                          : (isAr ? 'حفظ' : 'Save Changes'),
                      isLoading: _isSaving,
                      onPressed: () => _handleSave(isAr),
                    ),
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

// Page 60: المساعدة والدعم (Unified International 3-Service Help & Support)
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    final faqs = isAr
        ? [
            {
              'q': 'كيف أشارك مقاعد رحلتي أو أنشر طلب سفر على الطريق؟',
              'a': 'يمكنك نشر رحلتك وتحديد المقاعد الشاغرة وإمكانية قبول الطرود في 3 خطوات سريعة، أو نشر طلب سفر ليصلك عرض مباشر من مسافر في نفس المسار.',
            },
            {
              'q': 'كيف أرسل طرداً أو غرضاً مع مسافر موثّق؟',
              'a': 'اختر «إرسال طرد»، حدد نقطة الانطلاق والوصول وحجم الغرض، واختر مسافراً متجهاً لنفس الوجهة أو انشر طلب طرد مفتوح، مع تأمين الاستلام والتسليم بكود OTP من 4 أرقام.',
            },
            {
              'q': 'كيف أنشئ طلب شراء وتوريد للمواقع أو المهام الخاصة؟',
              'a': 'اضغط «إنشاء طلب توريد»، حدد الفئة والمواد والكمية والموقع، ثم عيّن سقف المشتريات وأجرة التوصيل لاستقبال عروض المزودين المعتمدين.',
            },
            {
              'q': 'كيف أضمن مطابقة المشتريات والتسليم بأمان؟',
              'a': 'يرفق المزود صورة الفاتورة الفعلية ضمن السقف المعتمد، ولا يُغلق طلب التوريد إلا بإدخال رمز التسليم السري المكون من 6 خانات عند الاستلام.',
            },
            {
              'q': 'كيف يتم اعتماد المزودين وطرق التسوية؟',
              'a': 'يخضع المزودون لمراجعة الوثائق الرسمية قبل تقديم العروض، وتتم التسوية بشفافية نقداً عند التسليم أو بتحويل بنكي موثّق بإيصال.',
            },
          ]
        : [
            {
              'q': 'How do I share empty seats or request a trip along a route?',
              'a': 'Publish your upcoming trip with empty seats and optional parcel space in 3 quick steps, or post a passenger route request so verified travelers heading your way can connect.',
            },
            {
              'q': 'How do I send a parcel or item with a traveler on the way?',
              'a': 'Open Send Parcel, choose origin, destination, and package size, then match with a parcel-friendly traveler or post an open route parcel request protected by 4-digit pickup & delivery OTPs.',
            },
            {
              'q': 'How do I create a smart supply or worksite request?',
              'a': 'Tap "Create a Request", select the supply category and items, pick a saved location or enter delivery details, and set your item cap and delivery fee.',
            },
            {
              'q': 'How are store purchases, invoices, and handovers verified?',
              'a': 'Approved providers attach actual store receipt photos within your maximum item cap, and completion is gated by your private 6-character handover code.',
            },
            {
              'q': 'Which settlement methods are supported?',
              'a': 'Direct settlement via Cash on Delivery (COD) or Manual Bank Transfer with receipt proof tracking is supported transparently.',
            },
          ];

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'المساعدة والدعم' : 'Help & Support',
          style: AppTypography.title().copyWith(fontSize: 18),
        ),
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
                    MashwarSectionCard(
                      backgroundColor: Colors.white,
                      borderColor: AppColors.slateBorder,
                      padding: const EdgeInsets.all(16),
                      borderRadius: 14,
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.tealSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: AppColors.teal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr
                                      ? 'مكتب عمليات ودعم مشوار (الرحلات · الطرود · التوريد)'
                                      : 'Qatar Worksite Operations Desk',
                                  style: AppTypography.body(
                                          color: AppColors.navy)
                                      .copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ops@mashwar.qa · +974 4400 9999',
                                  style: AppTypography.bodySmall(
                                          color: AppColors.textSecondary)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 4, bottom: 8),
                      child: Text(
                        isAr ? 'أسئلة شائعة' : 'Frequently Asked Questions',
                        style:
                            AppTypography.label(color: const Color(0xFF64748B))
                                .copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: faqs.map((f) {
                          return MashwarSectionCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: EdgeInsets.zero,
                            borderRadius: 12,
                            borderColor: AppColors.slateBorder,
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                iconColor: AppColors.navy,
                                collapsedIconColor: const Color(0xFF94A3B8),
                                title: Text(
                                  f['q']!,
                                  style: AppTypography.body(
                                    color: AppColors.navy,
                                  ).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 14),
                                    child: Text(
                                      f['a']!,
                                      style: AppTypography.bodySecondary()
                                          .copyWith(fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    MashwarButton(
                      text: isAr
                          ? 'محادثة مباشرة عبر واتساب'
                          : 'Chat via WhatsApp Support',
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white, size: 18),
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
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                            color: AppColors.slateBorder, width: 1.0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 17),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        final uri = Uri(scheme: 'tel', path: '+97444009999');
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
                                    ? 'لا يدعم هذا الجهاز الاتصال المباشر. تواصل مع الدعم على +974 4400 9999.'
                                    : 'This device lacks a phone handler. Contact Support at +974 4400 9999.',
                              ),
                              backgroundColor: AppColors.navy,
                            ),
                          );
                        }
                      },
                      label: Text(
                        isAr
                            ? 'الاتصال بالدعم المباشر (+974 4400 9999)'
                            : 'Call Qatar Support (+974 4400 9999)',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                            color: AppColors.slateBorder, width: 1.0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.mail_outline_rounded, size: 17),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'ops@mashwar.qa',
                          query: 'subject=MASHWAR%20Support',
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
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space12),
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
                          ? 'لا يمكن حذف الحساب حالياً لوجود طلبات نشطة مرتبطة بحسابك. يرجى إتمامها أو تسويتها أولاً.'
                          : 'Cannot delete account right now: You have active requests that must be completed or resolved first.'),
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
              border: Border.all(color: AppColors.slateBorder, width: 0.9),
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
                        size: 15, color: AppColors.cobalt),
                    label: Text(
                      isAr ? 'فتح تفاصيل الطلب' : 'Open Request Details',
                      style: AppTypography.label(color: AppColors.cobalt)
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
              ? 'سيتم حذف ملفك الشخصي وملف المزود وبيانات التوثيق وحساب المصادقة نهائياً عبر الخادم، مع الاحتفاظ بسجلات التدقيق القانونية وفقاً لقوانين حماية خصوصية البيانات.'
              : 'Your user profile, provider/business records, verification record, and authentication account will be permanently deleted on the server. Mandatory audit records are retained per applicable data privacy laws.',
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
            fillColor: AppColors.slateBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide:
                  const BorderSide(color: AppColors.slateBorder, width: 0.9),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide:
                  const BorderSide(color: AppColors.slateBorder, width: 0.9),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space32),
        MashwarButton(
          key: const ValueKey('delete_account_submit_btn'),
          text: isAr ? 'حذف الحساب نهائياً' : 'Delete My Account Permanently',
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
          Icons.verified_user_outlined,
          AppColors.teal,
          AppColors.tealSurface,
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
          AppColors.teal,
          AppColors.tealSurface,
        );
      case 'status_update':
      default:
        return (
          Icons.local_shipping_outlined,
          AppColors.navy,
          AppColors.slateBg,
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
    final allItems =
        worksite?.notifications ?? const <WorksiteNotificationItem>[];
    final unreadCount = worksite?.unreadNotificationsCount ?? 0;
    final displayed =
        _unreadOnly ? allItems.where((n) => !n.isRead).toList() : allItems;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy),
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
                style: AppTypography.title().copyWith(fontSize: 18),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.slateBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: Text(
                  '$unreadCount',
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w700),
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
                style: AppTypography.label(color: AppColors.navy)
                    .copyWith(fontWeight: FontWeight.w700),
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
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space16, vertical: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: !_unreadOnly,
                        selectedColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: !_unreadOnly
                              ? AppColors.navy
                              : AppColors.slateBorder,
                        ),
                        onSelected: (_) => setState(() => _unreadOnly = false),
                        label: Text(
                          isAr
                              ? 'الكل (${allItems.length})'
                              : 'All (${allItems.length})',
                          style: AppTypography.label(
                            color: !_unreadOnly ? Colors.white : AppColors.navy,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      FilterChip(
                        selected: _unreadOnly,
                        selectedColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: _unreadOnly
                              ? AppColors.navy
                              : AppColors.slateBorder,
                        ),
                        onSelected: (_) => setState(() => _unreadOnly = true),
                        label: Text(
                          isAr
                              ? 'غير مقروءة ($unreadCount)'
                              : 'Unread ($unreadCount)',
                          style: AppTypography.label(
                            color: _unreadOnly ? Colors.white : AppColors.navy,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.slateBorder),
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
                                padding:
                                    const EdgeInsets.all(AppDimens.space24),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: (constraints.maxHeight - 48)
                                        .clamp(0.0, double.infinity),
                                  ),
                                  child: Center(
                                    child: MashwarSectionCard(
                                      padding: const EdgeInsets.all(
                                          AppDimens.space24),
                                      borderRadius: 16,
                                      borderColor: AppColors.slateBorder,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const MashwarTrustEmblem(
                                            type: MashwarTrustType.liveCorridor,
                                            size: 46,
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
                                                .copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            isAr
                                                ? 'ستظهر هنا تحديثات الرحلات والطرود وعروض التوريد ورموز الاستلام.'
                                                : 'Trip matches, parcel updates, supply offers, and handover alerts will appear here.',
                                            textAlign: TextAlign.center,
                                            style:
                                                AppTypography.bodySecondary(),
                                          ),
                                          if (_unreadOnly &&
                                              allItems.isNotEmpty) ...[
                                            const SizedBox(height: 14),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.navy,
                                                backgroundColor: Colors.white,
                                                side: const BorderSide(
                                                  color: AppColors.slateBorder,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
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
                              final reqId = n.requestId?.trim();
                              final hasRequestTarget =
                                  reqId != null && reqId.isNotEmpty;

                              void markSingleReadOnly() {
                                if (!isUnread) return;
                                worksite?.markNotificationRead(n.id);
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isAr
                                            ? 'تم تعيين الإشعار كمقروء بدون فتحه'
                                            : 'Notification marked as read',
                                      ),
                                      backgroundColor: AppColors.teal,
                                      behavior: SnackBarBehavior.floating,
                                      duration:
                                          const Duration(milliseconds: 1800),
                                    ),
                                  );
                              }

                              void openNotificationTarget() {
                                worksite?.markNotificationRead(n.id);
                                if (hasRequestTarget) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WorkRequestDetailsScreen(
                                        requestId: reqId,
                                      ),
                                    ),
                                  );
                                }
                              }

                              return MashwarFadeSlideIn(
                                offsetY: 8,
                                child: MashwarHoverCard(
                                  backgroundColor: Colors.white,
                                  borderColor: AppColors.slateBorder,
                                  hoverBorderColor:
                                      AppColors.navy.withValues(alpha: 0.35),
                                  padding:
                                      const EdgeInsets.all(AppDimens.space16),
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: openNotificationTarget,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: visual.$3,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.slateBorder,
                                          ),
                                        ),
                                        child: Icon(
                                          visual.$1,
                                          color: visual.$2,
                                          size: 19,
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
                                                    style: AppTypography.body(
                                                      color: AppColors.navy,
                                                    ).copyWith(
                                                      fontWeight: isUnread
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                      fontSize: 13.5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
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
                                                    width: 7,
                                                    height: 7,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            top: 5),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: AppColors.teal,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                                if (isUnread ||
                                                    hasRequestTarget) ...[
                                                  const SizedBox(width: 2),
                                                  PopupMenuButton<String>(
                                                    key: ValueKey(
                                                        'notif_menu_${n.id}'),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                      minWidth: 28,
                                                      minHeight: 28,
                                                    ),
                                                    icon: const Icon(
                                                      Icons.more_vert_rounded,
                                                      size: 18,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                    tooltip: isAr
                                                        ? 'خيارات الإشعار'
                                                        : 'Notification options',
                                                    onSelected: (action) {
                                                      if (action ==
                                                          'mark_read') {
                                                        markSingleReadOnly();
                                                      } else if (action ==
                                                          'open') {
                                                        openNotificationTarget();
                                                      }
                                                    },
                                                    itemBuilder: (_) => [
                                                      if (isUnread)
                                                        PopupMenuItem<String>(
                                                          value: 'mark_read',
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .done_all_rounded,
                                                                size: 17,
                                                                color: AppColors
                                                                    .teal,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                isAr
                                                                    ? 'تعيين كمقروء بدون فتح'
                                                                    : 'Mark as read (no open)',
                                                                style: AppTypography
                                                                    .label(
                                                                  color:
                                                                      AppColors
                                                                          .navy,
                                                                ).copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      if (hasRequestTarget)
                                                        PopupMenuItem<String>(
                                                          value: 'open',
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .open_in_new_rounded,
                                                                size: 17,
                                                                color: AppColors
                                                                    .navy,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                isAr
                                                                    ? 'فتح التفاصيل'
                                                                    : 'Open details',
                                                                style: AppTypography
                                                                    .label(
                                                                  color:
                                                                      AppColors
                                                                          .navy,
                                                                ).copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
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
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                if (isUnread)
                                                  OutlinedButton.icon(
                                                    key: ValueKey(
                                                      'notif_mark_read_${n.id}',
                                                    ),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      foregroundColor:
                                                          AppColors.navy,
                                                      backgroundColor:
                                                          AppColors.slateBg,
                                                      side: const BorderSide(
                                                        color: AppColors
                                                            .slateBorder,
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    onPressed:
                                                        markSingleReadOnly,
                                                    icon: const Icon(
                                                      Icons.done_all_rounded,
                                                      size: 14,
                                                      color: AppColors.teal,
                                                    ),
                                                    label: Text(
                                                      isAr
                                                          ? 'تعيين كمقروء'
                                                          : 'Mark as read',
                                                      style:
                                                          AppTypography.label(
                                                        color: AppColors.navy,
                                                      ).copyWith(
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Container(
                                                    key: ValueKey(
                                                      'notif_read_badge_${n.id}',
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.slateBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                        color: AppColors
                                                            .slateBorder,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .check_circle_outline_rounded,
                                                          size: 13,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          isAr
                                                              ? 'مقروء'
                                                              : 'Read',
                                                          style: AppTypography
                                                              .label(
                                                            color: AppColors
                                                                .textSecondary,
                                                          ).copyWith(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
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
