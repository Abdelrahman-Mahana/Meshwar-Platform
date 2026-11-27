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
import '../main_nav_shell.dart';
import '../permissions/location_permission_screen.dart';

/// Executive Profile Setup screen with clean typography, warm welcome onboarding,
/// and zero hardcoded personal defaults.
class ProfileSetupScreen extends StatefulWidget {
  final bool isNewRegistration;

  const ProfileSetupScreen({
    super.key,
    this.isNewRegistration = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  static const String _otherGovValue = '__other_gov__';

  UserGender _selectedGender = UserGender.preferNotToSay;
  String _selectedGovernorate = 'بلدية الدوحة';
  final TextEditingController _customGovController = TextEditingController();
  String? _customGovError;
  String? _selectedAvatarUrl;

  bool _isEmergencyExpanded = true;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _emergencyPhoneError;
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

  static String _normalizeQatarLocalDigits(String raw) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = raw.trim();
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
      result = result.replaceAll(easternDigits[i], '$i');
    }
    result = result.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (result.startsWith('+974')) {
      result = result.substring(4);
    } else if (result.startsWith('00974')) {
      result = result.substring(5);
    } else if (result.length == 11 && result.startsWith('974')) {
      result = result.substring(3);
    }
    return result.replaceAll(RegExp(r'[^0-9]'), '');
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    _selectedAvatarUrl = user.avatarUrl;
    _selectedGender = user.gender;

    final hydratedEmail = (user.email != null && user.email!.trim().isNotEmpty)
        ? user.email!.trim()
        : (auth.email?.trim() ?? '');
    if (hydratedEmail.isNotEmpty) {
      _emailController.text = hydratedEmail;
    }

    final hydratedName = user.fullName.trim();
    if (hydratedName.isNotEmpty) {
      final parts = hydratedName.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }

    final hydratedPhone = user.phone.trim().isNotEmpty
        ? user.phone.trim()
        : auth.phoneNumber.trim();
    if (hydratedPhone.isNotEmpty) {
      _phoneController.text = _normalizeQatarLocalDigits(hydratedPhone);
    }

    final hydratedGov = user.governorate?.trim() ?? '';
    if (hydratedGov.isNotEmpty) {
      if (_governoratesAr.contains(hydratedGov) ||
          _governoratesEn.contains(hydratedGov)) {
        _selectedGovernorate = hydratedGov;
      } else {
        _selectedGovernorate = _otherGovValue;
        _customGovController.text = hydratedGov;
      }
    }

    final hydratedEmergencyName = user.emergencyContactName?.trim() ?? '';
    if (hydratedEmergencyName.isNotEmpty) {
      _emergencyNameController.text = hydratedEmergencyName;
    }
    final hydratedEmergencyPhone = user.emergencyContactPhone?.trim() ?? '';
    if (hydratedEmergencyPhone.isNotEmpty) {
      _emergencyPhoneController.text =
          _normalizeQatarLocalDigits(hydratedEmergencyPhone);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _customGovController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(bool isAr) async {
    if (_isSaving) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final rawPhone = _phoneController.text.trim();
    final normalizedPhone =
        rawPhone.isNotEmpty ? _normalizeQatarLocalDigits(rawPhone) : '';
    final emergencyName = _emergencyNameController.text.trim();
    final rawEmergencyPhone = _emergencyPhoneController.text.trim();
    final normalizedEmergencyPhone = rawEmergencyPhone.isNotEmpty
        ? _normalizeQatarLocalDigits(rawEmergencyPhone)
        : '';

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

    if (rawPhone.isNotEmpty &&
        AuthProvider.validateQatarPhone(normalizedPhone) != null) {
      _phoneError = isAr
          ? 'الرقم يجب أن يتكون من 8 أرقام ويبدأ بـ 3 أو 5 أو 6 أو 7'
          : 'Mobile number must be 8 digits starting with 3, 5, 6, or 7';
      hasError = true;
    } else {
      _phoneError = null;
    }

    if (rawEmergencyPhone.isNotEmpty &&
        AuthProvider.validateQatarPhone(normalizedEmergencyPhone) != null) {
      _emergencyPhoneError = isAr
          ? 'رقم الطوارئ يجب أن يتكون من 8 أرقام ويبدأ بـ 3 أو 5 أو 6 أو 7'
          : 'Emergency number must be 8 digits starting with 3, 5, 6, or 7';
      hasError = true;
    } else {
      _emergencyPhoneError = null;
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

    final govList = isAr ? _governoratesAr : _governoratesEn;
    final fullName = '$firstName $lastName'.trim();
    final resolvedGov = _selectedGovernorate == _otherGovValue &&
            _customGovController.text.trim().isNotEmpty
        ? _customGovController.text.trim()
        : (govList.contains(_selectedGovernorate)
            ? _selectedGovernorate
            : govList.first);

    final auth = context.read<AuthProvider>();
    auth.clearError();
    if (normalizedPhone.isNotEmpty) {
      auth.setPhoneNumber(normalizedPhone);
    }
    auth.saveProfile(
      fullName: fullName,
      gender: _selectedGender,
      governorate: resolvedGov,
      email: email.isNotEmpty ? email : null,
      emergencyContactName: emergencyName.isNotEmpty ? emergencyName : null,
      emergencyContactPhone: normalizedEmergencyPhone.isNotEmpty
          ? normalizedEmergencyPhone
          : null,
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
    final auth = context.watch<AuthProvider>();
    final isAr = settings.isArabic;
    final govList = isAr ? _governoratesAr : _governoratesEn;

    final previewFullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();
    final welcomeFirstName = _firstNameController.text.trim().isNotEmpty
        ? _firstNameController.text.trim()
        : (auth.user.fullName.trim().isNotEmpty
            ? auth.user.fullName.trim().split(RegExp(r'\s+')).first
            : '');
    final showSkipBtn = widget.isNewRegistration &&
        auth.user.fullName.trim().length >= 2;

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

                              // Warm Executive Welcome Banner
                              Container(
                                key: const ValueKey(
                                  'profile_setup_welcome_banner',
                                ),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.tealSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.slateBorder,
                                    width: AppDimens.borderWidth,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.teal
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.verified_user_rounded,
                                        color: AppColors.teal,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            welcomeFirstName.isNotEmpty
                                                ? (isAr
                                                    ? 'أهلاً بك في مشوار، $welcomeFirstName!'
                                                    : 'Welcome to MASHWAR, $welcomeFirstName!')
                                                : (isAr
                                                    ? 'أهلاً بك في مشوار!'
                                                    : 'Welcome to MASHWAR!'),
                                            style: AppTypography.title(
                                              color: AppColors.navy,
                                            ).copyWith(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isAr
                                                ? 'أكمل بياناتك الأساسية الآن لحفظ ملفك الشخصي بأمان، وتسهيل مطابقة الرحلات والطرود والتوريد وحماية رحلاتك.'
                                                : 'Complete your essential details now to save your profile securely, match trips, parcels & supply faster, and protect your journeys.',
                                            style: AppTypography.bodySecondary(
                                              color: AppColors.navy
                                                  .withValues(alpha: 0.8),
                                            ).copyWith(
                                              fontSize: 12.5,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimens.space16),

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

                              const SizedBox(height: AppDimens.space20),

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

                              const SizedBox(height: AppDimens.space20),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildExecutiveInputField(
                                      fieldKey: const ValueKey(
                                        'profile_setup_first_name_input',
                                      ),
                                      label:
                                          isAr ? 'الاسم الأول' : 'First name',
                                      controller: _firstNameController,
                                      hint: isAr ? 'مثال: سالم' : 'e.g. Salem',
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
                                      fieldKey: const ValueKey(
                                        'profile_setup_last_name_input',
                                      ),
                                      label:
                                          isAr ? 'اسم العائلة' : 'Last name',
                                      controller: _lastNameController,
                                      hint: isAr
                                          ? 'مثال: القحطاني'
                                          : 'e.g. Al-Qahtani',
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

                              const SizedBox(height: AppDimens.space16),

                              // Qatar Mobile Number (+974)
                              _buildQatarPhoneField(
                                fieldKey: const ValueKey(
                                  'profile_setup_phone_input',
                                ),
                                label: isAr
                                    ? 'رقم الجوال القطري (+974)'
                                    : 'Qatar Mobile Number (+974)',
                                controller: _phoneController,
                                hint: '55123456',
                                errorText: _phoneError,
                                helperText: isAr
                                    ? 'يُستخدم للتنسيق المباشر مع السائق أو طالب الخدمة وتأكيد أكواد التسليم OTP.'
                                    : 'Used for direct driver/requester coordination & secure OTP handovers.',
                                onChanged: (_) {
                                  if (_phoneError != null) {
                                    setState(() => _phoneError = null);
                                  }
                                },
                              ),

                              const SizedBox(height: AppDimens.space16),

                              _buildExecutiveInputField(
                                fieldKey: const ValueKey(
                                  'profile_setup_email_input',
                                ),
                                label: isAr
                                    ? 'البريد الإلكتروني'
                                    : 'Email address',
                                controller: _emailController,
                                hint: 'name@example.com',
                                keyboardType: TextInputType.emailAddress,
                                forceLtr: true,
                                errorText: _emailError,
                                helperText: isAr
                                    ? 'لإرسال إيصالات وفواتير المشاوير وتأمين استعادة الحساب'
                                    : 'For sending trip receipts and securing account recovery',
                                onChanged: (_) {
                                  if (_emailError != null) {
                                    setState(() => _emailError = null);
                                  }
                                },
                              ),

                              const SizedBox(height: AppDimens.space16),

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

                              const SizedBox(height: AppDimens.space16),

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

                              const SizedBox(height: AppDimens.space20),

                              // Emergency Contact (Optional — Recommended for Safety SOS)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.slateBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.slateBorder,
                                    width: AppDimens.borderWidth,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => setState(
                                        () => _isEmergencyExpanded =
                                            !_isEmergencyExpanded,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: AppColors.tealSurface,
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                              child: const Icon(
                                                Icons.health_and_safety_outlined,
                                                color: AppColors.teal,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isAr
                                                        ? 'جهة اتصال الطوارئ (موصى به للأمان)'
                                                        : 'Emergency Contact (Recommended for Safety SOS)',
                                                    style: AppTypography.label(
                                                      color: AppColors.navy,
                                                    ).copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    isAr
                                                        ? 'اختياري · لمشاركة مسار رحلتك مع قريب أو زميل موثوق'
                                                        : 'Optional · Share live trip routes with a trusted contact',
                                                    style:
                                                        AppTypography.bodySmall(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              _isEmergencyExpanded
                                                  ? Icons
                                                      .keyboard_arrow_up_rounded
                                                  : Icons
                                                      .keyboard_arrow_down_rounded,
                                              color: AppColors.textSecondary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_isEmergencyExpanded) ...[
                                      const Divider(
                                        height: 1,
                                        color: AppColors.slateBorder,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _buildExecutiveInputField(
                                              fieldKey: const ValueKey(
                                                'profile_setup_emergency_name_input',
                                              ),
                                              label: isAr
                                                  ? 'اسم جهة اتصال الطوارئ'
                                                  : 'Emergency Contact Name',
                                              controller:
                                                  _emergencyNameController,
                                              hint: isAr
                                                  ? 'مثال: ناصر القحطاني (الوالد / الأخ)'
                                                  : 'e.g. Nasser Al-Qahtani (Family)',
                                            ),
                                            const SizedBox(height: 12),
                                            _buildQatarPhoneField(
                                              fieldKey: const ValueKey(
                                                'profile_setup_emergency_phone_input',
                                              ),
                                              label: isAr
                                                  ? 'رقم جوال الطوارئ (+974)'
                                                  : 'Emergency Mobile (+974)',
                                              controller:
                                                  _emergencyPhoneController,
                                              hint: '55998877',
                                              errorText: _emergencyPhoneError,
                                              onChanged: (_) {
                                                if (_emergencyPhoneError !=
                                                    null) {
                                                  setState(
                                                    () => _emergencyPhoneError =
                                                        null,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MashwarButton(
                              key: const ValueKey('profile_setup_save_btn'),
                              text: widget.isNewRegistration
                                  ? (isAr
                                      ? 'حفظ بياناتي والمتابعة'
                                      : 'Save My Data & Continue')
                                  : (isAr ? 'متابعة' : 'Continue'),
                              isLoading: _isSaving,
                              onPressed: () => _handleSave(isAr),
                            ),
                            if (showSkipBtn) ...[
                              const SizedBox(height: 6),
                              TextButton(
                                key: const ValueKey('profile_setup_skip_btn'),
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MashwarPageRoute(
                                            builder: (_) =>
                                                const MainNavShell(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                child: Text(
                                  isAr
                                      ? 'تخطي الآن والدخول للتطبيق'
                                      : 'Skip for now & enter app',
                                  style: AppTypography.label(
                                    color: AppColors.textSecondary,
                                  ).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
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
              showcaseTitle: isAr
                  ? 'هوية موثوقة ومصممة للرحلات والخدمات'
                  : 'Verified profile tailored for seamless journeys',
              showcaseSubtitle: isAr
                  ? 'اختر بلديتك ورقم تواصلك ليظهر لك أقرب المسافرين والخدمات في الدوحة ولوسيل والخور والوكرة.'
                  : 'Complete your municipality and contact details so travelers & services match you faster.',
              child: formBody,
            );
          },
        ),
      ),
    );
  }

  Widget _buildQatarPhoneField({
    required Key fieldKey,
    required String label,
    required TextEditingController controller,
    required String hint,
    String? errorText,
    String? helperText,
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
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: TextInputType.phone,
            onChanged: onChanged,
            style: AppTypography.body(color: AppColors.navy),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodySecondary(
                color: AppColors.textSecondary.withValues(alpha: 0.65),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.slateBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.slateBorder,
                    width: AppDimens.borderWidth,
                  ),
                ),
                child: Text(
                  '+974',
                  style: AppTypography.label(color: AppColors.navy).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
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

  Widget _buildExecutiveInputField({
    Key? fieldKey,
    required String label,
    required TextEditingController controller,
    String? hint,
    String? errorText,
    String? helperText,
    TextInputType? keyboardType,
    bool forceLtr = false,
    ValueChanged<String>? onChanged,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;

    final field = TextField(
      key: fieldKey,
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label(color: AppColors.navy),
        ),
        const SizedBox(height: 6),
        if (forceLtr)
          Directionality(textDirection: TextDirection.ltr, child: field)
        else
          field,
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
