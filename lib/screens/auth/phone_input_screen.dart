import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_onboarding_shell.dart';
import '../../state/auth_provider.dart';
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
  final TextEditingController _phoneController = TextEditingController(text: '55123456');
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
    final validationError = AuthProvider.validateQatarPhone(phone);
    if (validationError != null) {
      setState(() {
        _errorText = isAr ? validationError : 'Phone must be 8 digits starting with 3, 5, 6, or 7';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(phone);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).push(
        MashwarPageRoute(builder: (_) => const OtpVerificationScreen()),
      );
    } else {
      setState(() {
        _errorText = auth.localizedError(isArabic: isAr) ??
            (isAr
                ? 'تعذّر إرسال رمز التحقق عبر SMS. يرجى المحاولة بالبريد الإلكتروني وكلمة المرور.'
                : 'Unable to send SMS verification code. Please sign in with Email & Password.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAr = context.isArabic;
    final hasError = _errorText != null && _errorText!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: MashwarOnboardingShell(
          isAr: isAr,
          showcaseBadge: isAr ? 'توثيق سريع' : 'Instant SMS',
          showcaseTitle: isAr
              ? 'دخول آمن لحماية طلباتك وخدماتك برقمك القطري +974'
              : 'Secure +974 access for all your Qatar services & rides',
          showcaseSubtitle: isAr
              ? 'ربط فوري مع شبكة Ooredoo و Vodafone Qatar لضمان موثوقية طالب الخدمة والمنفّذ.'
              : 'Instant OTP across Ooredoo & Vodafone Qatar protecting every transaction.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildSingleLayout(context, auth, isAr, hasError, constraints);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSingleLayout(
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
            MashwarFadeSlideIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top: Onboarding Progress + Brand Identity Header with Step Indicator
                  MashwarOnboardingStepBar(
                    currentStep: 1,
                    totalSteps: 4,
                    isAr: isAr,
                    stepTitle: isAr ? 'تأكيد الجوال' : 'Phone Verification',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BrandLogo(fontSize: 26),
                      _buildStepBadge(isAr: isAr, currentStep: 1, totalSteps: 2),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title & Subtitle
                  Text(
                    isAr ? 'أدخل رقم جوالك' : 'Enter your mobile number',
                    style: AppTypography.largeTitle().copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr ? 'سنرسل لك رمز تحقق عبر رسالة SMS' : 'We will send you a verification code via SMS',
                    style: AppTypography.bodySecondary().copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Input Label
                  Text(
                    isAr ? 'رقم الجوال' : 'Mobile Phone Number',
                    style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  // Phone Input Card
                  _buildPhoneInputField(hasError: hasError, isAr: isAr),
                  const SizedBox(height: 8),

                  // Helper text / Error text
                  _buildHelperOrError(
                    context: context,
                    auth: auth,
                    hasError: hasError,
                    isAr: isAr,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Actions Group
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bottom Actions: Submit Button
                MashwarButton(
                  text: isAr ? 'إرسال الرمز' : 'Send Code',
                  isLoading: auth.isLoading,
                  onPressed: () => _handleSubmit(isAr),
                ),
                const SizedBox(height: 12),

                // Switch to Email
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.navy),
                    onPressed: () {
                      context.read<AuthProvider>().clearError();
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
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        border: Border.all(
          color: hasError
              ? AppColors.danger
              : (_isFocused ? AppColors.navy : AppColors.borderDisabled),
          width: hasError ? 1.4 : (_isFocused ? 1.8 : 1.0),
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
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            // Clean Qatari Country Code Badge (+974 QA) always on left in LTR phone format
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.chipInactiveBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDisabled, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QA',
                    style: AppTypography.label(color: AppColors.teal).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '+974',
                    style: AppTypography.body(color: AppColors.navy).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Vertical Divider
            Container(
              height: 22,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.borderDisabled,
            ),

            // Phone input field
            Expanded(
              child: TextField(
                controller: _phoneController,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                maxLength: 8,
                style: AppTypography.body(color: AppColors.navy).copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '55XXXXXX',
                  hintStyle: AppTypography.bodySecondary(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ).copyWith(fontSize: 15, letterSpacing: 1.0),
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
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.lastError != null) {
                    authProvider.clearError();
                  }
                  setState(() => _errorText = null);
                },
              ),
            ),

            // Clear button if text exists
            if (_phoneController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.cancel_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.lastError != null) {
                    authProvider.clearError();
                  }
                  setState(() {
                    _phoneController.clear();
                    _errorText = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperOrError({
    required BuildContext context,
    required AuthProvider auth,
    required bool hasError,
    required bool isAr,
  }) {
    if (hasError) {
      return Container(
        key: const ValueKey('phone_auth_error_banner'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.danger, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorText!,
                    style: AppTypography.label(color: AppColors.danger)
                        .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (auth.shouldSuggestEmailFallback) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('phone_fallback_email_btn'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.navy, width: 1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  context.read<AuthProvider>().clearError();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) =>
                            const EmailInputScreen(initialIsRegister: false)),
                  );
                },
                icon: const Icon(Icons.mail_outline_rounded, size: 16),
                label: Text(
                  isAr
                      ? 'الدخول بالبريد الإلكتروني وكلمة المرور'
                      : 'Sign In with Email & Password',
                  style: AppTypography.label(color: AppColors.navy)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isAr
                ? 'رقم جوال قطري (Ooredoo / Vodafone) يبدأ بـ 3 أو 5 أو 6 أو 7'
                : 'Qatar mobile (Ooredoo / Vodafone) starting with 3, 5, 6, or 7',
            style: AppTypography.label(color: const Color(0xFF64748B)).copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
