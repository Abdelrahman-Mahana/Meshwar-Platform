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

/// Executive Phone Number input screen for +974 SMS OTP verification.
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController =
      TextEditingController(text: '55123456');
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

  Future<void> _handleSubmit(bool isAr) async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;

    final phone = normalizeDigits(_phoneController.text.trim());
    if (phone != _phoneController.text) {
      _phoneController.value = TextEditingValue(
        text: phone,
        selection: TextSelection.collapsed(offset: phone.length),
      );
    }

    final validationError = AuthProvider.validateQatarPhone(phone);
    if (validationError != null) {
      setState(() {
        _errorText = isAr
            ? validationError
            : 'Phone must be 8 digits starting with 3, 5, 6, or 7';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

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
          onPressed: () {
            context.read<AuthProvider>().clearError();
            Navigator.of(context).maybePop();
          },
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
              return _buildSingleLayout(
                context,
                auth,
                isAr,
                hasError,
                constraints,
              );
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
          minHeight: (constraints.maxHeight - (AppDimens.space16 * 2))
              .clamp(0.0, double.infinity),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MashwarFadeSlideIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MashwarOnboardingStepBar(
                    currentStep: 1,
                    totalSteps: 4,
                    isAr: isAr,
                    stepTitle: isAr ? 'تأكيد الجوال' : 'Phone Verification',
                  ),
                  const SizedBox(height: AppDimens.space16),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: BrandLogo(fontSize: 26),
                  ),
                  const SizedBox(height: AppDimens.space14),

                  Text(
                    isAr ? 'أدخل رقم جوالك' : 'Enter your mobile number',
                    style: AppTypography.largeTitle(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'سنرسل لك رمز تحقق عبر رسالة SMS'
                        : 'We will send you a verification code via SMS',
                    style: AppTypography.bodySecondary(),
                  ),
                  const SizedBox(height: AppDimens.space20),

                  Text(
                    isAr ? 'رقم الجوال' : 'Mobile Phone Number',
                    style: AppTypography.label(color: AppColors.navy),
                  ),
                  const SizedBox(height: 8),

                  _buildPhoneInputField(hasError: hasError, isAr: isAr),
                  const SizedBox(height: 10),

                  _buildHelperOrError(
                    context: context,
                    auth: auth,
                    hasError: hasError,
                    isAr: isAr,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space24),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MashwarButton(
                  text: isAr ? 'إرسال الرمز' : 'Send Code',
                  isLoading: auth.isLoading,
                  onPressed: () => _handleSubmit(isAr),
                ),
                const SizedBox(height: 12),

                Center(
                  child: TextButton.icon(
                    icon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: AppColors.navy,
                    ),
                    onPressed: () {
                      context.read<AuthProvider>().clearError();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const EmailInputScreen(),
                        ),
                      );
                    },
                    label: Text(
                      isAr
                          ? 'المتابعة بالبريد الإلكتروني بدلاً من ذلك'
                          : 'Continue with email instead',
                      style: AppTypography.bodySecondary(color: AppColors.navy)
                          .copyWith(
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

  Widget _buildPhoneInputField({required bool hasError, required bool isAr}) {
    final borderColor = hasError
        ? AppColors.danger
        : (_isFocused ? AppColors.navy : AppColors.slateBorder);
    final borderWidth = hasError
        ? AppDimens.borderWidthError
        : (_isFocused ? AppDimens.borderWidthFocused : AppDimens.borderWidth);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border.all(
                  color: AppColors.slateBorder,
                  width: AppDimens.borderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QA',
                    style: AppTypography.label(color: AppColors.teal)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+974',
                    style: AppTypography.body(color: AppColors.navy)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),

            Container(
              height: 22,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.slateBorder,
            ),

            Expanded(
              child: TextField(
                controller: _phoneController,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                maxLength: 8,
                onSubmitted: (_) => _handleSubmit(isAr),
                style: AppTypography.body(color: AppColors.navy).copyWith(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '55XXXXXX',
                  hintStyle: AppTypography.bodySecondary(
                    color: AppColors.textSecondary.withValues(alpha: 0.65),
                  ).copyWith(letterSpacing: 1.0),
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
                      selection: TextSelection.collapsed(
                        offset: normalized.length,
                      ),
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

            if (_phoneController.text.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.cancel_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(AppDimens.radiusAlert),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.35),
            width: AppDimens.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorText!,
                    style: AppTypography.label(color: AppColors.navy),
                  ),
                ),
              ],
            ),
            if (auth.shouldSuggestEmailFallback) ...[
              const SizedBox(height: 10),
              MashwarButton(
                key: const ValueKey('phone_fallback_email_btn'),
                height: 42,
                variant: MashwarButtonVariant.secondary,
                text: isAr
                    ? 'الدخول بالبريد الإلكتروني وكلمة المرور'
                    : 'Sign In with Email & Password',
                icon: const Icon(
                  Icons.mail_outline_rounded,
                  size: 16,
                  color: AppColors.navy,
                ),
                onPressed: () {
                  context.read<AuthProvider>().clearError();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          const EmailInputScreen(initialIsRegister: false),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
    }
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: AppColors.textSecondary,
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isAr
                ? 'رقم جوال قطري (Ooredoo / Vodafone) يبدأ بـ 3 أو 5 أو 6 أو 7'
                : 'Qatar mobile (Ooredoo / Vodafone) starting with 3, 5, 6, or 7',
            style: AppTypography.bodySmall(),
          ),
        ),
      ],
    );
  }
}
