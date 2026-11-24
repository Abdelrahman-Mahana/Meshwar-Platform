import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
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
import '../worksite/work_request_details_screen.dart';

// الملف الشخصي للمستخدم (User Profile Screen)
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final user = context.watch<AuthProvider>().user;
    final isIdVerified = user.idVerificationStatus == IdVerificationStatus.verified;

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
                      if (isIdVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: AppColors.teal, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
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

            final preferencesAndAccount = Column(
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

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    final faqs = isAr
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
          ];

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
                    Text(isAr ? 'أسئلة شائعة' : 'Frequently Asked Questions', style: AppTypography.title().copyWith(fontSize: 16)),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView(
                        children: faqs.map((f) {
                          return MashwarSectionCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: EdgeInsets.zero,
                            borderRadius: 14,
                            child: ExpansionTile(
                              title: Text(f['q']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        final uri = Uri(scheme: 'tel', path: '19884');
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
                                    ? 'لا يدعم هذا الجهاز الاتصال المباشر. اتصل بالخط الساخن 19884 من هاتفك.'
                                    : 'This device lacks a phone handler. Dial 19884 on your phone.',
                              ),
                              backgroundColor: AppColors.navy,
                            ),
                          );
                        }
                      },
                      label: Text(isAr ? 'الاتصال بالخط الساخن' : 'Call Support Hotline', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
class NotificationsCenterScreen extends StatelessWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    final notifications = [
      {
        'title': isAr ? 'وافق جاسم على حجزك' : 'Jassim accepted your booking',
        'sub': isAr ? 'الجمعة 6 نوفمبر، 7:30 ص' : 'Fri Nov 6, 7:30 AM',
        'time': isAr ? 'الآن' : 'Just now',
        'isNew': true,
      },
      {
        'title': isAr ? 'طردك وصل' : 'Your parcel has arrived',
        'sub': isAr ? 'تم التسليم إلى نورة' : 'Delivered safely to Noura',
        'time': isAr ? 'أمس' : 'Yesterday',
        'isNew': false,
      },
      {
        'title': isAr ? 'تذكير برحلتك' : 'Trip reminder',
        'sub': isAr ? 'تبدأ بعد ساعتين' : 'Departs in 2 hours',
        'time': isAr ? 'أمس' : 'Yesterday',
        'isNew': false,
      },
    ];

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
        title: Text(isAr ? 'الإشعارات' : 'Notifications', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimens.space16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = notifications[index];
                final isNew = n['isNew'] as bool;
                return MashwarFadeSlideIn(
                  offsetY: 8,
                  child: MashwarSectionCard(
                    backgroundColor: isNew ? const Color(0xFFF9FAFB) : Colors.white,
                    borderColor: isNew ? AppColors.teal.withValues(alpha: 0.35) : const Color(0xFFE5E5EA),
                    padding: const EdgeInsets.all(AppDimens.space16),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isNew ? AppColors.tealSurface : const Color(0xFFF3F3F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: isNew ? AppColors.teal : AppColors.navy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n['title'] as String,
                                      style: TextStyle(
                                        fontWeight: isNew ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ),
                                  if (isNew)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.teal,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(n['sub'] as String, style: AppTypography.bodySecondary().copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(n['time'] as String, style: AppTypography.label(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
