import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import 'email_input_screen.dart';
import 'otp_verification_screen.dart';

/// Market-leading, minimalist Phone Number input screen (Uber / inDrive standard).
/// Fully distributed responsive layout styled after WelcomeScreen:
/// - Wide / Desktop (>= 840px): 2-column split canvas (Left: Brand & Trust showcase, Right: Phone entry form)
/// - Mobile (< 840px): Full-height balanced distribution with Brand Header, Step Progress, Operator Chips,
///   Safety Benefit Cards, Metrics Strip, and Bottom CTA Actions.
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '01012345678');
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  bool _isFocused = false;

  static String normalizeDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
      result = result.replaceAll(easternDigits[i], '$i');
    }
    return result.replaceAll(RegExp(r'[^0-9]'), '');
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(bool isAr) async {
    final phone = _phoneController.text.trim();
    final validationError = AuthProvider.validateEgyptianPhone(phone);
    if (validationError != null) {
      setState(() {
        _errorText = isAr ? validationError : 'Phone must be 11 digits starting with 010, 011, 012, or 015';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(phone);
    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpVerificationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isAr = context.isArabic;
    final hasError = _errorText != null && _errorText!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: ActionChip(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
              avatar: const Icon(Icons.language_rounded, size: 16, color: AppColors.navy),
              label: Text(
                isAr ? 'English' : 'العربية',
                style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.bold),
              ),
              onPressed: () => settings.toggleLanguage(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            if (isWide) {
              return _buildWideSplitLayout(context, auth, isAr, hasError, constraints);
            }
            return _buildMobileLayout(context, auth, isAr, hasError, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildWideSplitLayout(
    BuildContext context,
    AuthProvider auth,
    bool isAr,
    bool hasError,
    BoxConstraints constraints,
  ) {
    return Row(
      children: [
        // Left Showcase Panel
        Expanded(
          flex: 6,
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy, Color(0xFF14385A)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 80).clamp(0.0, double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandLogo(fontSize: 48, isLight: true),
                        const SizedBox(height: 18),
                        Text(
                          isAr ? 'سفر موثق وآمن برقم موبايلك' : 'Verified & Secure Intercity Travel',
                          style: AppTypography.title(color: Colors.white).copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isAr
                              ? 'رقم هاتفك هو وسيلة التحقق الأساسية لحجز المقاعد ومتابعة الرحلات بأعلى درجات الأمان والخصوصية.'
                              : 'Your phone number is the primary verification key for secure intercity rides and privacy.',
                          style: AppTypography.body(color: Colors.white70).copyWith(fontSize: 15, height: 1.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right Phone Input Form Area
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 64).clamp(0.0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Step Indicator Badge
                            _buildStepBadge(isAr: isAr, currentStep: 1, totalSteps: 2),
                            const SizedBox(height: 14),

                            // Title
                            Text(
                              isAr ? 'أدخل رقم موبايلك' : 'Enter your mobile number',
                              style: AppTypography.largeTitle().copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle
                            Text(
                              isAr ? 'هنبعتلك كود تأكيد عبر رسالة SMS' : 'We will send you a verification code via SMS',
                              style: AppTypography.bodySecondary(),
                            ),
                            const SizedBox(height: 22),

                            // Input Label
                            Text(
                              isAr ? 'رقم الهاتف المحمول' : 'Mobile Phone Number',
                              style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),

                            // Phone input field card
                            _buildPhoneInputField(hasError: hasError, isAr: isAr),
                            const SizedBox(height: 10),

                            // Helper / Error
                            _buildHelperOrError(hasError: hasError, isAr: isAr),
                            const SizedBox(height: 24),

                            // Submit Button
                            MashwarButton(
                              text: isAr ? 'إرسال الكود' : 'Send Code',
                              isLoading: auth.isLoading,
                              onPressed: () => _handleSubmit(isAr),
                            ),
                            const SizedBox(height: 16),

                            // Switch to email
                            Center(
                              child: TextButton.icon(
                                icon: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.navy),
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const EmailInputScreen()),
                                  );
                                },
                                label: Text(
                                  isAr ? 'المتابعة بالبريد الإلكتروني بدلاً من ذلك' : 'Continue with email instead',
                                  style: AppTypography.body(color: AppColors.navy).copyWith(
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
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
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AuthProvider auth,
    bool isAr,
    bool hasError,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space24,
        vertical: AppDimens.space16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - (AppDimens.space16 * 2)).clamp(0.0, double.infinity),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top: Brand Identity Header with Step Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BrandLogo(fontSize: 28),
                    _buildStepBadge(isAr: isAr, currentStep: 1, totalSteps: 2),
                  ],
                ),
                const SizedBox(height: 14),

                // Title & Subtitle
                Text(
                  isAr ? 'أدخل رقم موبايلك' : 'Enter your mobile number',
                  style: AppTypography.largeTitle().copyWith(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? 'هنبعتلك كود تأكيد عبر رسالة SMS' : 'We will send you a verification code via SMS',
                  style: AppTypography.bodySecondary().copyWith(fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Input Label
                Text(
                  isAr ? 'رقم الهاتف المحمول' : 'Mobile Phone Number',
                  style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // Phone Input Card
                _buildPhoneInputField(hasError: hasError, isAr: isAr),
                const SizedBox(height: 8),

                // Helper text / Error text
                _buildHelperOrError(hasError: hasError, isAr: isAr),
              ],
            ),

            const SizedBox(height: 24),

            // Bottom Actions Group
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bottom Actions: Submit Button
                MashwarButton(
                  text: isAr ? 'إرسال الكود' : 'Send Code',
                  isLoading: auth.isLoading,
                  onPressed: () => _handleSubmit(isAr),
                ),
                const SizedBox(height: 12),

                // Switch to Email
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.navy),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const EmailInputScreen()),
                      );
                    },
                    label: Text(
                      isAr ? 'المتابعة بالبريد الإلكتروني بدلاً من ذلك' : 'Continue with email instead',
                      style: AppTypography.body(color: AppColors.navy).copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBadge({required bool isAr, required int currentStep, required int totalSteps}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAr ? 'الخطوة $currentStep من $totalSteps' : 'Step $currentStep of $totalSteps',
        style: AppTypography.label(color: AppColors.navy).copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildPhoneInputField({required bool hasError, required bool isAr}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 56,
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? AppColors.danger
              : (_isFocused ? AppColors.navy : const Color(0xFFE5E5EA)),
          width: hasError ? 1.4 : (_isFocused ? 1.8 : 0.8),
        ),
        boxShadow: _isFocused && !hasError
            ? [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Clear button if text exists
          if (_phoneController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 20),
              onPressed: () {
                setState(() {
                  _phoneController.clear();
                  _errorText = null;
                });
              },
            ),

          // Phone input field
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _phoneController,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                style: AppTypography.body(color: AppColors.navy).copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '01XXXXXXXXX',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
                ],
                onChanged: (val) {
                  final normalized = normalizeDigits(val);
                  if (normalized != val) {
                    _phoneController.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(offset: normalized.length),
                    );
                  }
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
              ),
            ),
          ),

          // Vertical Divider
          Container(
            height: 22,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFE5E5EA),
          ),

          // Egyptian Flag & Country Code Badge (+20 🇪🇬)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+20',
                  style: AppTypography.body(color: AppColors.navy).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🇪🇬', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelperOrError({required bool hasError, required bool isAr}) {
    if (hasError) {
      return Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _errorText!,
              style: AppTypography.label(color: AppColors.danger).copyWith(fontSize: 12),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isAr
                ? 'رقم مصري يبدأ بـ 010 أو 011 أو 012 أو 015'
                : 'Egyptian phone starting with 010, 011, 012, or 015',
            style: AppTypography.label(color: const Color(0xFF64748B)).copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
