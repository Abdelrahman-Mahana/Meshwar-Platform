import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_onboarding_shell.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/user_model.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../permissions/location_permission_screen.dart';

/// Clean, minimalist, Uber/inDrive-style Profile Setup screen.
/// Focuses on essential rider data without visual clutter, excessive lines, or emojis.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _firstNameController = TextEditingController(text: 'عبدالرحمن');
  final TextEditingController _lastNameController = TextEditingController(text: 'المهنا');
  final TextEditingController _emailController = TextEditingController(text: 'abdelrahman@mashwar.qa');

  static const String _otherGovValue = '__other_gov__';

  UserGender _selectedGender = UserGender.male;
  String _selectedGovernorate = 'بلدية الدوحة';
  final TextEditingController _customGovController = TextEditingController();
  String? _customGovError;
  String? _selectedAvatarUrl;

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  bool _isSaving = false;

  final List<String> _governoratesAr = const [
    'بلدية الدوحة',
    'بلدية الريان',
    'بلدية الوكرة',
    'بلدية الخور والذخيرة',
    'بلدية أم صلال',
    'بلدية الضعاين (لوسيل)',
    'بلدية الشمال',
    'بلدية الشيحانية (دخان)',
  ];

  final List<String> _governoratesEn = const [
    'Doha Municipality',
    'Al Rayyan Municipality',
    'Al Wakrah Municipality',
    'Al Khor & Al Thakhira',
    'Umm Salal Municipality',
    'Al Daayen (Lusail)',
    'Al Shamal Municipality',
    'Al Shahaniya (Dukhan)',
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _selectedAvatarUrl = auth.user.avatarUrl;
    if (auth.email != null && auth.email!.isNotEmpty) {
      _emailController.text = auth.email!;
    }
    if (auth.user.fullName.isNotEmpty && auth.user.fullName != 'أحمد محمد') {
      final parts = auth.user.fullName.trim().split(' ');
      if (parts.isNotEmpty) {
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _customGovController.dispose();
    super.dispose();
  }

  void _handleSave(bool isAr) async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    bool hasError = false;

    if (firstName.isEmpty || firstName.length < 2) {
      setState(() {
        _firstNameError = isAr ? 'أدخل الاسم الأول بشكل صحيح' : 'Please enter your first name';
      });
      hasError = true;
    } else {
      setState(() => _firstNameError = null);
    }

    if (lastName.isEmpty || lastName.length < 2) {
      setState(() {
        _lastNameError = isAr ? 'أدخل اسم العائلة بشكل صحيح' : 'Please enter your last name';
      });
      hasError = true;
    } else {
      setState(() => _lastNameError = null);
    }

    if (email.isNotEmpty && !email.contains('@')) {
      setState(() {
        _emailError = isAr ? 'أدخل بريد إلكتروني صحيح' : 'Please enter a valid email address';
      });
      hasError = true;
    } else {
      setState(() => _emailError = null);
    }

    if (_selectedGovernorate == _otherGovValue &&
        _customGovController.text.trim().length < 2) {
      setState(() {
        _customGovError = isAr
            ? 'أدخل اسم المنطقة أو البلدية المخصصة'
            : 'Please enter your custom municipality or area';
      });
      hasError = true;
    } else {
      setState(() => _customGovError = null);
    }

    if (hasError) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      final fullName = '$firstName $lastName'.trim();
      final resolvedGov = _selectedGovernorate == _otherGovValue &&
              _customGovController.text.trim().isNotEmpty
          ? _customGovController.text.trim()
          : _selectedGovernorate;
      context.read<AuthProvider>().saveProfile(
            fullName: fullName,
            gender: _selectedGender,
            governorate: resolvedGov,
            email: email.isNotEmpty ? email : null,
            avatarUrl: _selectedAvatarUrl,
          );

      Navigator.of(context).pushAndRemoveUntil(
        MashwarPageRoute(builder: (_) => const LocationPermissionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;
    final govList = isAr ? _governoratesAr : _governoratesEn;

    final previewFullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            final formBody = Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.space24,
                      vertical: isWide ? AppDimens.space16 : 0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: MashwarFadeSlideIn(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MashwarOnboardingStepBar(
                                currentStep: 2,
                                totalSteps: 4,
                                isAr: isAr,
                                stepTitle: isAr ? 'إعداد الملف الشخصي' : 'Profile Setup',
                              ),
                              const SizedBox(height: 14),

                                  // Title
                                  Text(
                                    isAr ? 'ما اسمك؟' : "What's your name?",
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isAr
                                        ? 'أدخل بياناتك كما تظهر في بطاقتك القطرية لتسهيل طلب الخدمات والمشاوير وتوثيق الضمان بين الطرفين.'
                                        : 'Enter your name as shown on your QID so service providers and requesters can verify you safely.',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // Interactive Profile Photo Picker
                                  Center(
                                    child: Column(
                                      children: [
                                        MashwarUserAvatar(
                                          key: const ValueKey('profile_setup_avatar_btn'),
                                          avatarUrl: _selectedAvatarUrl,
                                          fullName: previewFullName.isNotEmpty
                                              ? previewFullName
                                              : (isAr ? 'عضو مشوار' : 'Member'),
                                          size: 88,
                                          borderWidth: 2.6,
                                          borderColor: AppColors.gold,
                                          showCameraBadge: true,
                                          onTap: () {
                                            showMashwarAvatarPickerSheet(
                                              context,
                                              currentAvatarUrl: _selectedAvatarUrl,
                                              fullName: previewFullName,
                                              onAvatarSelected: (picked) {
                                                setState(() => _selectedAvatarUrl = picked);
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isAr
                                              ? 'اضغط لإضافة صورتك الشخصية (اختياري)'
                                              : 'Tap to add your profile photo (optional)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.teal,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 28),

                                // First Name & Last Name (Side by side on wider / clean on mobile)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildUberInputField(
                                        label: isAr ? 'الاسم الأول' : 'First name',
                                        controller: _firstNameController,
                                        hint: isAr ? 'مثال: حمد' : 'e.g. Hamad',
                                        errorText: _firstNameError,
                                        onChanged: (val) {
                                          setState(() {
                                            if (_firstNameError != null) _firstNameError = null;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildUberInputField(
                                        label: isAr ? 'اسم العائلة' : 'Last name',
                                        controller: _lastNameController,
                                        hint: isAr ? 'مثال: الكواري' : 'e.g. Al-Kuwari',
                                        errorText: _lastNameError,
                                        onChanged: (val) {
                                          setState(() {
                                            if (_lastNameError != null) _lastNameError = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Email Address
                                _buildUberInputField(
                                  label: isAr ? 'البريد الإلكتروني' : 'Email address',
                                  controller: _emailController,
                                  hint: 'name@example.com',
                                  keyboardType: TextInputType.emailAddress,
                                  errorText: _emailError,
                                  helperText: isAr
                                      ? 'لإرسال إيصالات وفواتير المشاوير'
                                      : 'For sending ride receipts and trip updates',
                                  onChanged: (val) {
                                    if (_emailError != null) setState(() => _emailError = null);
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Municipality Selector
                                Text(
                                  isAr ? 'البلدية / المنطقة' : 'Municipality / Area',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F3F4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      key: const ValueKey('profile_setup_gov_dropdown'),
                                      value: _selectedGovernorate == _otherGovValue
                                          ? _otherGovValue
                                          : (govList.contains(_selectedGovernorate)
                                              ? _selectedGovernorate
                                              : govList.first),
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navy,
                                        fontFamily: 'Cairo',
                                      ),
                                      dropdownColor: Colors.white,
                                      items: [
                                        ...govList.map((gov) {
                                          return DropdownMenuItem(value: gov, child: Text(gov));
                                        }),
                                        DropdownMenuItem(
                                          value: _otherGovValue,
                                          child: Text(
                                            isAr
                                                ? 'أخرى (حدد منطقتك بنفسك)'
                                                : 'Other (Specify Area)',
                                            style: const TextStyle(
                                              color: AppColors.cobalt,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedGovernorate = val;
                                            _customGovError = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                if (_selectedGovernorate == _otherGovValue) ...[
                                  const SizedBox(height: 12),
                                  _buildUberInputField(
                                    label: isAr
                                        ? 'اكتب اسم المنطقة أو المدينة *'
                                        : 'Specify Custom Area / City *',
                                    controller: _customGovController,
                                    hint: isAr
                                        ? 'مثال: اللؤلؤة، مشيرب، سيلين...'
                                        : 'e.g. The Pearl, Msheireb, Sealine...',
                                    errorText: _customGovError,
                                    onChanged: (_) {
                                      if (_customGovError != null) {
                                        setState(() => _customGovError = null);
                                      }
                                    },
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Gender Selector (Pills, clean, NO EMOJIS)
                                Text(
                                  isAr ? 'النوع' : 'Gender',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGenderPill(
                                        label: isAr ? 'ذكر' : 'Male',
                                        isSelected: _selectedGender == UserGender.male,
                                        onTap: () => setState(() => _selectedGender = UserGender.male),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildGenderPill(
                                        label: isAr ? 'أنثى' : 'Female',
                                        isSelected: _selectedGender == UserGender.female,
                                        onTap: () => setState(() => _selectedGender = UserGender.female),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildGenderPill(
                                        label: isAr ? 'أفضّل عدم الذكر' : 'Other',
                                        isSelected: _selectedGender == UserGender.preferNotToSay,
                                        onTap: () => setState(() => _selectedGender = UserGender.preferNotToSay),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom CTA Area (Uber style, constrained cleanly on wide viewports)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.navy,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isSaving ? null : () => _handleSave(isAr),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              isAr ? 'متابعة' : 'Continue',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );

            return MashwarOnboardingShell(
              isAr: isAr,
              maxFormWidth: 640,
              scrollable: false,
              showcaseBadge: isAr ? 'ملفك الشخصي' : 'Your Profile',
              showcaseTitle: isAr ? 'هوية موثوقة ومصممة للرحلات في قطر' : 'Verified profile tailored for Qatar travel',
              showcaseSubtitle: isAr
                  ? 'اختر بلديتك واسمك ليظهر لك أقرب الكباتن والخدمات في الدوحة والخور والوكرة.'
                  : 'Select your municipality so captains & services match you faster.',
              child: formBody,
            );
          },
        ),
      ),
    );
  }

  Widget _buildUberInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? errorText,
    String? helperText,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F4),
            borderRadius: BorderRadius.circular(10),
            border: hasError ? Border.all(color: AppColors.danger, width: 1.2) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.navy,
              fontFamily: 'Cairo',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
                fontFamily: 'Cairo',
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.danger,
              fontFamily: 'Cairo',
            ),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8E8E93),
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: AppDimens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navy : AppColors.chipInactiveBg,
            borderRadius: BorderRadius.circular(AppDimens.radiusField),
            border: Border.all(
              color: isSelected ? AppColors.navy : AppColors.borderDisabled,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
