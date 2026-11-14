import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_button.dart';
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            if (isWide) {
              return _buildWideSplitLayout(context, auth, isAr, targetDestination, isEmailMode, constraints);
            }
            return _buildMobileLayout(context, auth, isAr, targetDestination, isEmailMode, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildWideSplitLayout(
    BuildContext context,
    AuthProvider auth,
    bool isAr,
    String targetDestination,
    bool isEmailMode,
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
                        const BrandLogo(fontSize: 44, isLight: true),
                        const SizedBox(height: 18),
                        Text(
                          isAr ? 'أمان حسابك وسرية بياناتك' : 'Account Security & Privacy',
                          style: AppTypography.title(color: Colors.white).copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr
                              ? 'رمز التحقق مكوّن من 6 أرقام يحمي هويتك ومحفظتك الرقمية في مشوار.'
                              : 'Your 6-digit verification code protects your identity and wallet balance.',
                          style: AppTypography.body(color: Colors.white70).copyWith(fontSize: 15),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Security & Value Highlights
                    Column(
                      children: [
                        _buildWideTrustCard(
                          icon: Icons.lock_outline_rounded,
                          title: isAr ? 'رمز سري لمرة واحدة فقط' : 'One-Time Secret Passcode',
                          subtitle: isAr
                              ? 'صالح لمدة 10 دقائق ولا تشاركه مع أي شخص بما في ذلك موظفي مشوار.'
                              : 'Valid for 10 minutes. Never share this code with anyone.',
                        ),
                        const SizedBox(height: 14),
                        _buildWideTrustCard(
                          icon: Icons.mark_email_unread_outlined,
                          title: isAr ? 'لم يصلك الرمز؟' : 'Didn’t receive the code?',
                          subtitle: isAr
                              ? 'تأكد من تغطية شبكة هاتفك أو راجع صندوق الرسائل غير المرغوب فيها (Spam).'
                              : 'Check your mobile signal strength or spam/junk folder.',
                        ),
                        const SizedBox(height: 14),
                        _buildWideTrustCard(
                          icon: Icons.support_agent_rounded,
                          title: isAr ? 'دعم فني مباشر على مدار الساعة' : '24/7 Dedicated Support',
                          subtitle: isAr
                              ? 'فريق الدعم متواجد لمساعدتك فورياً في حال تعذر استلام الكود.'
                              : 'Support team is ready to assist if you encounter any delay.',
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Metrics Strip
                    Row(
                      children: [
                        _buildShowcaseMetric('100%', isAr ? 'مشفر' : 'Encrypted'),
                        const SizedBox(width: 32),
                        _buildShowcaseMetric('6', isAr ? 'أرقام أمان' : 'Digits'),
                        const SizedBox(width: 32),
                        _buildShowcaseMetric('24/7', isAr ? 'دعم' : 'Support'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right OTP Form Area
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
                            _buildStepBadge(isAr: isAr, currentStep: 2, totalSteps: 2),
                            const SizedBox(height: 14),

                            // Title
                            Text(
                              isAr ? 'أدخل الكود' : 'Enter Code',
                              style: AppTypography.largeTitle().copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle with destination
                            _buildDestinationSubtitle(targetDestination, isAr),
                            const SizedBox(height: 24),

                            // Error Banner
                            if (_errorMessage != null) ...[
                              AlertBanner(message: _errorMessage!, type: AlertBannerType.danger),
                              const SizedBox(height: 16),
                            ],

                            // Locked Warning
                            if (auth.isLocked) ...[
                              AlertBanner(
                                message: isAr
                                    ? 'تم إيقاف المحاولات مؤقتاً لتكرار الخطأ. جرّب بعد 15 دقيقة'
                                    : 'Attempts temporarily locked. Try after 15 mins',
                                type: AlertBannerType.danger,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // OTP Cells Stack
                            _buildOtpInputStack(isAr),
                            const SizedBox(height: 20),

                            // Resend Timer / Action
                            _buildResendSection(auth, isEmailMode, isAr),
                            const SizedBox(height: 32),

                            // Confirm CTA
                            MashwarButton(
                              text: isAr ? 'تأكيد' : 'Confirm',
                              isLoading: auth.isLoading,
                              onPressed: () => _verify(isAr),
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
    String targetDestination,
    bool isEmailMode,
    BoxConstraints constraints,
  ) {
    final isCompact = constraints.maxHeight <= 680;

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
                    _buildStepBadge(isAr: isAr, currentStep: 2, totalSteps: 2),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  isAr ? 'أدخل الكود' : 'Enter Code',
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

                if (!isCompact) ...[
                  const SizedBox(height: 18),
                  // Security Reassurance Card (Fills middle naturally with useful value)
                  _buildSecurityAdvisoryCard(isAr),
                ],
              ],
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
    );
  }

  Widget _buildOtpInputStack(bool isAr) {
    return GestureDetector(
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

          // 6 Pure Visual Display Cells (Zero inner borders, single crisp hairline border)
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
    );
  }

  Widget _buildSecurityAdvisoryCard(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Text(
                isAr ? 'إرشادات أمان الحساب والسرية' : 'Security & Privacy Guidelines',
                style: AppTypography.body(color: AppColors.navy).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAdvisoryPoint(
            isAr
                ? 'رمز التحقق صالح للاستخدام لمرة واحدة فقط لمدة 10 دقائق.'
                : 'Passcode is valid for a single use for 10 minutes.',
          ),
          const SizedBox(height: 4),
          _buildAdvisoryPoint(
            isAr
                ? 'لا تشارك هذا الرمز مطلقاً مع أي شخص حتى موظفي خدمة عملاء مشوار.'
                : 'Never share this passcode with anyone, even MASHWAR support.',
          ),
          const SizedBox(height: 4),
          _buildAdvisoryPoint(
            isAr
                ? 'إذا تأخر وصول الكود، تأكد من تغطية شبكة هاتفك أو راجع البريد غير الهام.'
                : 'If delayed, verify network signal or check your junk/spam folder.',
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.label(color: const Color(0xFF475569)).copyWith(fontSize: 11),
          ),
        ),
      ],
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

  Widget _buildWideTrustCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(color: Colors.white).copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.label(color: Colors.white70).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.title(color: AppColors.gold).copyWith(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: AppTypography.label(color: Colors.white70),
        ),
      ],
    );
  }
}
