import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../data/models/user_model.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../main_nav_shell.dart';

/// Clean, minimalist, Uber/inDrive-style Profile Setup screen.
/// Focuses on essential rider data without visual clutter, excessive lines, or emojis.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _firstNameController = TextEditingController(text: 'عبدالرحمن');
  final TextEditingController _lastNameController = TextEditingController(text: 'أحمد');
  final TextEditingController _emailController = TextEditingController(text: 'abdelrahman@mashwar.example');

  UserGender _selectedGender = UserGender.male;
  String _selectedGovernorate = 'كفر الشيخ';

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  bool _isSaving = false;

  final List<String> _governoratesAr = const [
    'كفر الشيخ',
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الغربية',
    'الدقهلية',
    'القليوبية',
    'الشرقية',
    'المنوفية',
    'البحيرة',
    'دمياط',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'أسيوط',
    'سوهاج',
    'قنا',
    'الأقصر',
    'أسوان',
    'البحر الأحمر',
    'شمال سيناء',
    'جنوب سيناء',
    'مطروح',
    'الوادي الجديد',
  ];

  final List<String> _governoratesEn = const [
    'Kafr El-Sheikh',
    'Cairo',
    'Giza',
    'Alexandria',
    'Gharbia',
    'Dakahlia',
    'Qalyubia',
    'Sharqia',
    'Monufia',
    'Beheira',
    'Damietta',
    'Port Said',
    'Ismailia',
    'Suez',
    'Fayoum',
    'Beni Suef',
    'Minya',
    'Asyut',
    'Sohag',
    'Qena',
    'Luxor',
    'Aswan',
    'Red Sea',
    'North Sinai',
    'South Sinai',
    'Matrouh',
    'New Valley',
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
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

    if (hasError) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      final fullName = '$firstName $lastName'.trim();
      context.read<AuthProvider>().saveProfile(
            fullName: fullName,
            gender: _selectedGender,
            governorate: _selectedGovernorate,
            email: email.isNotEmpty ? email : null,
          );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;
    final govList = isAr ? _governoratesAr : _governoratesEn;

    final initialChar = _firstNameController.text.trim().isNotEmpty
        ? _firstNameController.text.trim()[0]
        : (isAr ? 'م' : 'M');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return Container(
              color: isWide ? AppColors.sand : Colors.white,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.space24,
                        vertical: isWide ? AppDimens.space24 : 0,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Container(
                            padding: isWide
                                ? const EdgeInsets.all(AppDimens.space24)
                                : EdgeInsets.zero,
                            decoration: isWide
                                ? BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  )
                                : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),

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
                                      ? 'أدخل بياناتك كما تظهر في بطاقتك الشخصية لتسهيل رحلاتك وتأكيد هويتك للسائقين.'
                                      : 'Enter your name as it appears on your ID so drivers can recognize you.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                    fontFamily: 'Cairo',
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // Avatar placeholder (Uber style)
                                Center(
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F3F4),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFE5E5EA), width: 1.5),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initialChar,
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.navy,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: isAr ? 0 : null,
                                        left: isAr ? null : 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: AppColors.navy,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
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
                                        hint: isAr ? 'مثال: أحمد' : 'e.g. Ahmed',
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
                                        hint: isAr ? 'مثال: محمود' : 'e.g. Mahmoud',
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

                                // Governorate Selector
                                Text(
                                  isAr ? 'المحافظة' : 'Governorate',
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
                                      value: govList.contains(_selectedGovernorate)
                                          ? _selectedGovernorate
                                          : govList.first,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navy,
                                        fontFamily: 'Cairo',
                                      ),
                                      dropdownColor: Colors.white,
                                      items: govList.map((gov) {
                                        return DropdownMenuItem(value: gov, child: Text(gov));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedGovernorate = val);
                                      },
                                    ),
                                  ),
                                ),

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
                                            Icon(
                                              isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
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
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF555555),
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }
}
