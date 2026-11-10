import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import 'profile_setup_screen.dart';

/// Clean, bulletproof, minimalist OTP Verification Screen (Uber/inDrive standard).
/// Uses a unified input architecture with 6 pure visual cells:
/// - Eliminates any double-borders, inner pills, or clipping artifacts.
/// - Prevents focus-jump character cascading on Flutter Web.
/// - Automatically normalizes Arabic-Indic numerals (٠-٩ -> 0-9).
/// - Completely filters out punctuation (؛, ؟, ., etc.).
/// - Supports 1-tap pasting and native backspace across all 6 cells.
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

  void _fillDemoCode(bool isAr) {
    const demo = '482911';
    _otpController.value = const TextEditingValue(
      text: demo,
      selection: TextSelection.collapsed(offset: demo.length),
    );
    setState(() => _errorMessage = null);
    _verify(isAr);
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
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
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
    if (raw == null || raw.isEmpty) return '0101 *** 5678';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
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
      backgroundColor: Colors.white,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimens.space16),

              // Title
              Text(
                isAr ? 'أدخل الكود' : 'Enter Code',
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: AppDimens.space8),

              // Subtitle with LTR-safe masked phone or email & edit link
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    isAr ? 'بعتنا كود من 6 أرقام على ' : 'We sent a 6-digit code to ',
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
              ),

              const SizedBox(height: AppDimens.space24),

              // Error Banner
              if (_errorMessage != null) ...[
                AlertBanner(
                  message: _errorMessage!,
                  type: AlertBannerType.danger,
                ),
                const SizedBox(height: AppDimens.space16),
              ],

              // Locked Warning
              if (auth.isLocked) ...[
                AlertBanner(
                  message: isAr
                      ? 'تم إيقاف المحاولات مؤقتاً لتكرار الخطأ. جرّب بعد 15 دقيقة'
                      : 'Attempts temporarily locked. Try after 15 mins',
                  type: AlertBannerType.danger,
                ),
                const SizedBox(height: AppDimens.space16),
              ],

              // Unified OTP Input: Transparent native TextField + 6 pure visual display cells
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Invisible native input capturing all keyboard, paste, and backspace events
                    Opacity(
                      opacity: 0.0,
                      child: SizedBox(
                        height: 56,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          cursorColor: Colors.transparent,
                          showCursor: false,
                          style: const TextStyle(color: Colors.transparent, fontSize: 1),
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

                    // 6 Pure Visual Display Cells (Zero inner borders, zero pill artifacts)
                    IgnorePointer(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) => _buildVisualCell(index)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space24),

              // Resend Timer / Action
              Center(
                child: auth.resendCountdown > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            isAr
                                ? 'إعادة إرسال الكود بعد 00:${auth.resendCountdown.toString().padLeft(2, "0")}'
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
                          isAr ? 'إعادة إرسال الكود' : 'Resend Code',
                          style: AppTypography.body(color: AppColors.teal).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
              ),

              const SizedBox(height: AppDimens.space16),

              // Quick Prototype Demo Chip
              Center(
                child: InkWell(
                  onTap: () => _fillDemoCode(isAr),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 15, color: AppColors.teal),
                        const SizedBox(width: 6),
                        Text(
                          isAr ? 'تجربة سريعة: تعبئة الكود 482911' : 'Quick Demo: Fill 482911',
                          style: AppTypography.label(color: AppColors.navy).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.space32),

              // Confirm CTA
              MashwarButton(
                text: isAr ? 'تأكيد' : 'Confirm',
                isLoading: auth.isLoading,
                onPressed: () => _verify(isAr),
              ),

              const SizedBox(height: AppDimens.space24),
            ],
          ),
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
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
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
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: hasError ? AppColors.danger : AppColors.navy,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
