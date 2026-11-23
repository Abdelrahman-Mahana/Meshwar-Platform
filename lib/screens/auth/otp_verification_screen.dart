import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_onboarding_shell.dart';
import '../../state/auth_provider.dart';
import 'profile_setup_screen.dart';

/// Clean, bulletproof, minimalist OTP Verification Screen (Uber/inDrive standard).
/// Responsive layout:
/// - Wide / Desktop (>= 840px): 2-column split canvas (Left: Security & OTP advisory, Right: Verification form)
/// - Mobile (< 840px): Full-height balanced vertical distribution with Step Progress, 6 clean cells & Safety card
class OtpVerificationScreen extends StatefulWidget {
  final String? email;

  const OtpVerificationScreen({super.key, this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;
  bool _isFocused = false;

  /// Normalizes Arabic-Indic numerals (٠-٩) and Eastern Arabic numerals to standard 0-9 digits.
  /// Also strictly strips non-digit characters (punctuation, letters, spaces).
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
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });

    // Auto-focus after mounting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged(String rawVal, bool isAr) {
    final normalized = normalizeDigits(rawVal);

    if (normalized != rawVal) {
      _otpController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    setState(() => _errorMessage = null);

    if (normalized.length == 6) {
      _focusNode.unfocus();
      _verify(isAr);
    }
  }

  void _verify(bool isAr) async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() {
        _errorMessage = isAr ? 'الرجاء إدخال الكود كاملاً (6 أرقام)' : 'Please enter full 6-digit code';
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    final isEmailMode = widget.email != null && widget.email!.isNotEmpty;
    final success = isEmailMode
        ? await auth.verifyEmailOtp(code)
        : await auth.verifyOtp(code);
    if (success && mounted) {
      Navigator.of(context).push(
        MashwarPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    } else if (mounted) {
      setState(() {
        _errorMessage = isAr
            ? 'الكود غير صحيح. المتبقي ${auth.otpAttemptsLeft} محاولات'
            : 'Invalid code. ${auth.otpAttemptsLeft} attempts remaining';
      });
    }
  }

  String _formatMaskedPhone(String? raw) {
    if (raw == null || raw.isEmpty) return '+974 5512 ****';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 8) {
      final prefix = digits.substring(0, 4);
      return '+974 $prefix ****';
    }
    if (digits.length >= 10) {
      final prefix = digits.substring(0, 4);
      final suffix = digits.substring(digits.length - 4);
      return '$prefix *** $suffix';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAr = context.isArabic;
    final isEmailMode = widget.email != null && widget.email!.isNotEmpty;
    final targetDestination = isEmailMode ? widget.email! : _formatMaskedPhone(auth.phoneNumber);

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
          showcaseBadge: isAr ? 'حماية مزدوجة' : 'OTP Protected',
          showcaseTitle: isAr ? 'تأكيد فوري وآمن لهويتك' : 'Instant & secure verification',
          showcaseSubtitle: isAr
              ? 'نحمي كل حساب برمز تحقق لمرة واحدة لضمان موثوقية مجتمع مشوار في قطر.'
              : 'Every account is secured with one-time OTP verification across Qatar.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildSingleLayout(context, auth, isAr, targetDestination, isEmailMode, constraints);
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
    String targetDestination,
    bool isEmailMode,
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
                  // Top: Step Progress + Brand Identity Header with Step Indicator
                  MashwarOnboardingStepBar(
                    currentStep: 1,
                    totalSteps: 4,
                    isAr: isAr,
                    stepTitle: isAr ? 'رمز التحقق الآمن' : 'Security Code',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BrandLogo(fontSize: 26),
                      _buildStepBadge(isAr: isAr, currentStep: 2, totalSteps: 2),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    isAr ? 'أدخل رمز التحقق' : 'Enter Code',
                    style: AppTypography.largeTitle().copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle with destination
                  _buildDestinationSubtitle(targetDestination, isAr),
                  const SizedBox(height: 20),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    AlertBanner(message: _errorMessage!, type: AlertBannerType.danger),
                    const SizedBox(height: 14),
                  ],

                  // Locked Warning
                  if (auth.isLocked) ...[
                    AlertBanner(
                      message: isAr
                          ? 'تم إيقاف المحاولات مؤقتاً لتكرار الخطأ. جرّب بعد 15 دقيقة'
                          : 'Attempts temporarily locked. Try after 15 mins',
                      type: AlertBannerType.danger,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // OTP Cells Stack
                  _buildOtpInputStack(isAr),
                  const SizedBox(height: 16),

                  // Resend Section
                  _buildResendSection(auth, isEmailMode, isAr),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Confirm CTA
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MashwarButton(
                  text: isAr ? 'تأكيد' : 'Confirm',
                  isLoading: auth.isLoading,
                  onPressed: () => _verify(isAr),
                ),
                const SizedBox(height: 8),
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
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAr ? 'الخطوة $currentStep من $totalSteps' : 'Step $currentStep of $totalSteps',
        style: AppTypography.label(color: AppColors.teal).copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDestinationSubtitle(String targetDestination, bool isAr) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isAr ? 'أرسلنا رمزاً من 6 أرقام إلى ' : 'We sent a 6-digit code to ',
          style: AppTypography.bodySecondary(),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            targetDestination,
            style: AppTypography.bodySecondary().copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              isAr ? 'تغيير' : 'Edit',
              style: AppTypography.label(color: AppColors.teal).copyWith(
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputStack(bool isAr) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 6 Pure Visual Display Cells (Responsive width so never overflows on <= 360px)
        IgnorePointer(
          child: ExcludeSemantics(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 5 ? 6 : 0),
                      child: _buildVisualCell(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        // Native input capturing taps, accessibility focus, keyboard, paste, and backspace events directly
        Positioned.fill(
          child: Opacity(
            opacity: 0.01,
            child: TextField(
              controller: _otpController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              cursorColor: Colors.transparent,
              showCursor: false,
              style: const TextStyle(color: Colors.transparent, fontSize: 16),
              enableInteractiveSelection: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
              ],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => _onCodeChanged(val, isAr),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResendSection(AuthProvider auth, bool isEmailMode, bool isAr) {
    return Center(
      child: auth.resendCountdown > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  isAr
                      ? 'إعادة إرسال الرمز بعد 00:${auth.resendCountdown.toString().padLeft(2, "0")}'
                      : 'Resend code in 00:${auth.resendCountdown.toString().padLeft(2, "0")}',
                  style: AppTypography.bodySecondary(),
                ),
              ],
            )
          : TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.teal),
              onPressed: () {
                if (isEmailMode) {
                  auth.sendEmailOtp(widget.email!);
                } else {
                  auth.sendOtp(auth.phoneNumber);
                }
              },
              label: Text(
                isAr ? 'إعادة إرسال الرمز' : 'Resend Code',
                style: AppTypography.body(color: AppColors.teal).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  Widget _buildVisualCell(int index) {
    final code = _otpController.text;
    final hasChar = index < code.length;
    final char = hasChar ? code[index] : '';
    final isCurrentActive = _isFocused && (index == code.length || (index == 5 && code.length == 6));
    final hasError = _errorMessage != null;

    Color borderColor;
    double borderWidth;
    Color bgColor;

    if (hasError) {
      borderColor = AppColors.danger;
      borderWidth = 1.4;
      bgColor = const Color(0xFFFEF2F2);
    } else if (isCurrentActive) {
      borderColor = AppColors.navy;
      borderWidth = 1.8;
      bgColor = Colors.white;
    } else if (hasChar) {
      borderColor = AppColors.navy;
      borderWidth = 1.2;
      bgColor = Colors.white;
    } else {
      borderColor = const Color(0xFFE5E5EA);
      borderWidth = 0.8;
      bgColor = const Color(0xFFF8F9FA);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      constraints: const BoxConstraints(minHeight: 56, maxWidth: 48),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isCurrentActive && !hasError
            ? [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        textAlign: TextAlign.center,
        style: AppTypography.title(
          color: hasError ? AppColors.danger : AppColors.navy,
        ).copyWith(fontSize: 22),
      ),
    );
  }
}
