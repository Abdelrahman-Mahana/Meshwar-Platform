import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_onboarding_shell.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/user_model.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../permissions/location_permission_screen.dart';

/// Executive Profile Setup screen with clean typography and zero clutter.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _firstNameController =
      TextEditingController(text: 'عبدالرحمن');
  final TextEditingController _lastNameController =
      TextEditingController(text: 'المهنا');
  final TextEditingController _emailController =
      TextEditingController(text: 'abdelrahman@mashwar.qa');

  static const String _otherGovValue = '__other_gov__';

  UserGender _selectedGender = UserGender.male;
  String _selectedGovernorate = 'بلدية الدوحة';
  final TextEditingController _customGovController = TextEditingController();
  String? _customGovError;
  String? _selectedAvatarUrl;

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _submitError;
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

  Future<void> _handleSave(bool isAr) async {
    if (_isSaving) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    bool hasError = false;

    if (firstName.length < 2) {
      _firstNameError =
          isAr ? 'أدخل الاسم الأول بشكل صحيح' : 'Please enter your first name';
      hasError = true;
    } else {
      _firstNameError = null;
    }

    if (lastName.length < 2) {
      _lastNameError =
          isAr ? 'أدخل اسم العائلة بشكل صحيح' : 'Please enter your last name';
      hasError = true;
    } else {
      _lastNameError = null;
    }

    if (email.isNotEmpty && AuthProvider.validateEmail(email) != null) {
      _emailError = isAr
          ? 'أدخل بريد إلكتروني صحيح'
          : 'Please enter a valid email address';
      hasError = true;
    } else {
      _emailError = null;
    }

    if (_selectedGovernorate == _otherGovValue &&
        _customGovController.text.trim().length < 2) {
      _customGovError = isAr
          ? 'أدخل اسم المنطقة أو البلدية المخصصة'
          : 'Please enter your custom municipality or area';
      hasError = true;
    } else {
      _customGovError = null;
    }

    setState(() => _submitError = null);
    if (hasError) return;

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final fullName = '$firstName $lastName'.trim();
    final resolvedGov = _selectedGovernorate == _otherGovValue &&
            _customGovController.text.trim().isNotEmpty
        ? _customGovController.text.trim()
        : _selectedGovernorate;

    final auth = context.read<AuthProvider>();
    auth.clearError();
    auth.saveProfile(
      fullName: fullName,
      gender: _selectedGender,
      governorate: resolvedGov,
      email: email.isNotEmpty ? email : null,
      avatarUrl: _selectedAvatarUrl,
    );

    setState(() => _isSaving = false);
    if (auth.lastError != null && !auth.isAuthenticated) {
      setState(() {
        _submitError = auth.localizedError(isArabic: isAr);
      });
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MashwarPageRoute(builder: (_) => const LocationPermissionScreen()),
      (route) => false,
    );
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
      backgroundColor: Colors.white,
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
                                stepTitle: isAr
                                    ? 'إعداد الملف الشخصي'
                                    : 'Profile Setup',
                              ),
                              const SizedBox(height: AppDimens.space14),

                              Text(
                                isAr ? 'ما اسمك؟' : "What's your name?",
                                style: AppTypography.largeTitle(),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isAr
                                    ? 'أدخل بياناتك كما تظهر في بطاقتك القطرية لتسهيل طلب الخدمات والمشاوير وتوثيق الضمان بين الطرفين.'
                                    : 'Enter your name as shown on your QID so service providers and requesters can verify you safely.',
                                style: AppTypography.bodySecondary(),
                              ),

                              if (_submitError != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerBg,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusAlert,
                                    ),
                                    border: Border.all(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.35),
                                      width: AppDimens.borderWidth,
                                    ),
                                  ),
                                  child: Text(
                                    _submitError!,
                                    style: AppTypography.label(
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: AppDimens.space24),

                              Center(
                                child: Column(
                                  children: [
                                    MashwarUserAvatar(
                                      key: const ValueKey(
                                        'profile_setup_avatar_btn',
                                      ),
                                      avatarUrl: _selectedAvatarUrl,
                                      fullName: previewFullName.isNotEmpty
                                          ? previewFullName
                                          : (isAr ? 'عضو مشوار' : 'Member'),
                                      size: 84,
                                      borderWidth: 1.5,
                                      borderColor: AppColors.slateBorder,
                                      showCameraBadge: true,
                                      onTap: () {
                                        showMashwarAvatarPickerSheet(
                                          context,
                                          currentAvatarUrl: _selectedAvatarUrl,
                                          fullName: previewFullName,
                                          onAvatarSelected: (picked) {
                                            setState(
                                              () => _selectedAvatarUrl = picked,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isAr
                                          ? 'اضغط لإضافة صورتك الشخصية (اختياري)'
                                          : 'Tap to add your profile photo (optional)',
                                      style: AppTypography.label(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppDimens.space24),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildExecutiveInputField(
                                      label:
                                          isAr ? 'الاسم الأول' : 'First name',
                                      controller: _firstNameController,
                                      hint: isAr ? 'مثال: حمد' : 'e.g. Hamad',
                                      errorText: _firstNameError,
                                      onChanged: (_) {
                                        setState(() {
                                          _firstNameError = null;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildExecutiveInputField(
                                      label:
                                          isAr ? 'اسم العائلة' : 'Last name',
                                      controller: _lastNameController,
                                      hint: isAr
                                          ? 'مثال: الكواري'
                                          : 'e.g. Al-Kuwari',
                                      errorText: _lastNameError,
                                      onChanged: (_) {
                                        setState(() {
                                          _lastNameError = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppDimens.space20),

                              _buildExecutiveInputField(
                                label: isAr
                                    ? 'البريد الإلكتروني'
                                    : 'Email address',
                                controller: _emailController,
                                hint: 'name@example.com',
                                keyboardType: TextInputType.emailAddress,
                                errorText: _emailError,
                                helperText: isAr
                                    ? 'لإرسال إيصالات وفواتير المشاوير'
                                    : 'For sending ride receipts and trip updates',
                                onChanged: (_) {
                                  if (_emailError != null) {
                                    setState(() => _emailError = null);
                                  }
                                },
                              ),

                              const SizedBox(height: AppDimens.space20),

                              Text(
                                isAr
                                    ? 'البلدية / المنطقة'
                                    : 'Municipality / Area',
                                style: AppTypography.label(
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusField,
                                  ),
                                  border: Border.all(
                                    color: AppColors.slateBorder,
                                    width: AppDimens.borderWidth,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    key: const ValueKey(
                                      'profile_setup_gov_dropdown',
                                    ),
                                    value: _selectedGovernorate ==
                                            _otherGovValue
                                        ? _otherGovValue
                                        : (govList
                                                .contains(_selectedGovernorate)
                                            ? _selectedGovernorate
                                            : govList.first),
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.navy,
                                    ),
                                    style: AppTypography.body(
                                      color: AppColors.navy,
                                    ),
                                    dropdownColor: Colors.white,
                                    items: [
                                      ...govList.map((gov) {
                                        return DropdownMenuItem(
                                          value: gov,
                                          child: Text(gov),
                                        );
                                      }),
                                      DropdownMenuItem(
                                        value: _otherGovValue,
                                        child: Text(
                                          isAr
                                              ? 'أخرى (حدد منطقتك بنفسك)'
                                              : 'Other (Specify Area)',
                                          style: AppTypography.body(
                                            color: AppColors.navy,
                                          ).copyWith(
                                            fontWeight: FontWeight.w700,
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
                                _buildExecutiveInputField(
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

                              const SizedBox(height: AppDimens.space20),

                              Text(
                                isAr ? 'النوع' : 'Gender',
                                style: AppTypography.label(
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGenderPill(
                                      label: isAr ? 'ذكر' : 'Male',
                                      isSelected:
                                          _selectedGender == UserGender.male,
                                      onTap: () => setState(
                                        () => _selectedGender = UserGender.male,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildGenderPill(
                                      label: isAr ? 'أنثى' : 'Female',
                                      isSelected:
                                          _selectedGender == UserGender.female,
                                      onTap: () => setState(
                                        () =>
                                            _selectedGender = UserGender.female,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildGenderPill(
                                      label:
                                          isAr ? 'أفضّل عدم الذكر' : 'Other',
                                      isSelected: _selectedGender ==
                                          UserGender.preferNotToSay,
                                      onTap: () => setState(
                                        () => _selectedGender =
                                            UserGender.preferNotToSay,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppDimens.space24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space24,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.slateBorder,
                        width: AppDimens.borderWidth,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: MashwarButton(
                          text: isAr ? 'متابعة' : 'Continue',
                          isLoading: _isSaving,
                          onPressed: () => _handleSave(isAr),
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
              showcaseTitle: isAr
                  ? 'هوية موثوقة ومصممة للرحلات والخدمات'
                  : 'Verified profile tailored for seamless journeys',
              showcaseSubtitle: isAr
                  ? 'اختر بلديتك واسمك ليظهر لك أقرب المسافرين والخدمات في الدوحة ولوسيل والخور والوكرة.'
                  : 'Select your municipality so travelers & services match you faster.',
              child: formBody,
            );
          },
        ),
      ),
    );
  }

  Widget _buildExecutiveInputField({
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
          style: AppTypography.label(color: AppColors.navy),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppTypography.body(color: AppColors.navy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySecondary(
              color: AppColors.textSecondary.withValues(alpha: 0.65),
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.slateBorder,
                width: hasError
                    ? AppDimens.borderWidthError
                    : AppDimens.borderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.slateBorder,
                width: hasError
                    ? AppDimens.borderWidthError
                    : AppDimens.borderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.navy,
                width: AppDimens.borderWidthFocused,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTypography.bodySmall(color: AppColors.danger),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: AppTypography.bodySmall(),
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
          duration: const Duration(milliseconds: 160),
          constraints:
              const BoxConstraints(minHeight: AppDimens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusField),
            border: Border.all(
              color: isSelected ? AppColors.navy : AppColors.slateBorder,
              width: AppDimens.borderWidth,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.label(
                color: isSelected ? Colors.white : AppColors.navy,
              ).copyWith(fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
