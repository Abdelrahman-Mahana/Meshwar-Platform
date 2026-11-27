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
import '../main_nav_shell.dart';
import 'email_input_screen.dart';
import 'profile_setup_screen.dart';

/// Executive 6-digit OTP Verification Screen.
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

  Future<void> _verify(bool isAr) async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading || auth.isLocked) return;

    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() {
        _errorMessage = isAr
            ? 'الرجاء إدخال الكود كاملاً (6 أرقام)'
            : 'Please enter full 6-digit code';
      });
      return;
    }

    final isEmailMode = widget.email != null && widget.email!.isNotEmpty;
    final success = isEmailMode
        ? await auth.verifyEmailOtp(code)
        : await auth.verifyOtp(code);
    if (success && mounted) {
      if (auth.isAuthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavShell()),
          (_) => false,
        );
      } else {
        Navigator.of(context).push(
          MashwarPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      }
    } else if (mounted) {
      final mappedMsg = auth.lastAuthException?.localizedMessage(isArabic: isAr);
      final isInvalidCode =
          auth.lastAuthException?.code == 'invalid-verification-code';
      setState(() {
        if (mappedMsg != null && !isInvalidCode) {
          _errorMessage = mappedMsg;
        } else {
          _errorMessage = isAr
              ? 'الكود غير صحيح. المتبقي ${auth.otpAttemptsLeft} محاولات'
              : 'Invalid code. ${auth.otpAttemptsLeft} attempts remaining';
        }
      });
    }
  }

  Future<void> _handleResend(
    AuthProvider auth,
    bool isEmailMode,
    bool isAr,
  ) async {
    if (auth.isLoading) return;
    setState(() => _errorMessage = null);

    final ok = isEmailMode
        ? await auth.sendEmailOtp(widget.email!)
        : await auth.sendOtp(auth.phoneNumber);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _errorMessage = auth.localizedError(isArabic: isAr) ??
            (isAr
                ? 'تعذّر إعادة إرسال الرمز حالياً.'
                : 'Unable to resend verification code right now.');
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
    final targetDestination =
        isEmailMode ? widget.email! : _formatMaskedPhone(auth.phoneNumber);

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
          showcaseBadge: isAr ? 'حماية مزدوجة' : 'OTP Protected',
          showcaseTitle: isAr
              ? 'خطوة أمان أولى في منظومة مشوار الخالية من الاحتيال'
              : 'Zero-fraud authentication for every MASHWAR user',
          showcaseSubtitle: isAr
              ? 'كل حساب مربوط بالتحقق اللحظي وتوثيق الهوية لضمان أمان الطرفين.'
              : 'Every account pairs instant OTP verification with identity protection.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildSingleLayout(
                context,
                auth,
                isAr,
                targetDestination,
                isEmailMode,
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
                    stepTitle: isAr ? 'رمز التحقق الآمن' : 'Security Code',
                  ),
                  const SizedBox(height: AppDimens.space16),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: BrandLogo(fontSize: 26),
                  ),
                  const SizedBox(height: AppDimens.space14),

                  Text(
                    isAr ? 'أدخل رمز التحقق' : 'Enter Code',
                    style: AppTypography.largeTitle(),
                  ),
                  const SizedBox(height: 6),

                  _buildDestinationSubtitle(targetDestination, isAr),
                  const SizedBox(height: AppDimens.space20),

                  if (_errorMessage != null) ...[
                    AlertBanner(
                      message: _errorMessage!,
                      type: AlertBannerType.danger,
                    ),
                    const SizedBox(height: AppDimens.space14),
                  ],

                  if (auth.isLocked) ...[
                    AlertBanner(
                      message: isAr
                          ? 'تم إيقاف المحاولات مؤقتاً لتكرار الخطأ. جرّب بعد 15 دقيقة'
                          : 'Attempts temporarily locked. Try after 15 mins',
                      type: AlertBannerType.danger,
                    ),
                    const SizedBox(height: AppDimens.space14),
                  ],

                  _buildOtpInputStack(isAr),
                  const SizedBox(height: AppDimens.space16),

                  _buildResendSection(auth, isEmailMode, isAr),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MashwarButton(
                  text: isAr ? 'تأكيد' : 'Confirm',
                  isLoading: auth.isLoading,
                  onPressed: auth.isLocked ? null : () => _verify(isAr),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    key: const ValueKey('otp_switch_to_email_btn'),
                    icon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 17,
                      color: AppColors.navy,
                    ),
                    onPressed: () {
                      auth.clearError();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              const EmailInputScreen(initialIsRegister: false),
                        ),
                      );
                    },
                    label: Text(
                      isAr
                          ? 'المتابعة بالبريد الإلكتروني وكلمة المرور'
                          : 'Sign in with Email & Password instead',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(decoration: TextDecoration.underline),
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
            style: AppTypography.bodySecondary(color: AppColors.navy)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            context.read<AuthProvider>().clearError();
            Navigator.of(context).maybePop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              isAr ? 'تغيير' : 'Edit',
              style: AppTypography.label(color: AppColors.navy)
                  .copyWith(decoration: TextDecoration.underline),
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
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
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
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.navy,
              ),
              onPressed: () => _handleResend(auth, isEmailMode, isAr),
              label: Text(
                isAr ? 'إعادة إرسال الرمز' : 'Resend Code',
                style: AppTypography.body(color: AppColors.navy)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  Widget _buildVisualCell(int index) {
    final code = _otpController.text;
    final hasChar = index < code.length;
    final char = hasChar ? code[index] : '';
    final isCurrentActive =
        _isFocused && (index == code.length || (index == 5 && code.length == 6));
    final hasError = _errorMessage != null;

    Color borderColor;
    double borderWidth;
    Color bgColor;

    if (hasError) {
      borderColor = AppColors.danger;
      borderWidth = AppDimens.borderWidthError;
      bgColor = AppColors.dangerBg;
    } else if (isCurrentActive) {
      borderColor = AppColors.navy;
      borderWidth = AppDimens.borderWidthFocused;
      bgColor = Colors.white;
    } else if (hasChar) {
      borderColor = AppColors.navy;
      borderWidth = AppDimens.borderWidth;
      bgColor = Colors.white;
    } else {
      borderColor = AppColors.slateBorder;
      borderWidth = AppDimens.borderWidth;
      bgColor = AppColors.slateBg;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      constraints: const BoxConstraints(minHeight: 54, maxWidth: 48),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        textAlign: TextAlign.center,
        style: AppTypography.title(
          color: hasError ? AppColors.danger : AppColors.navy,
        ).copyWith(fontSize: 21),
      ),
    );
  }
}
