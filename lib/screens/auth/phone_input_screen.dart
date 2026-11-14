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
import 'email_input_screen.dart';
import 'otp_verification_screen.dart';

/// Market-leading, minimalist Phone Number input screen (Uber / inDrive standard).
/// Features a dedicated Egyptian country badge (🇪🇬 +20), responsive focus outline,
/// automatic Arabic-to-English digit normalization, and one-tap clear button.
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '01012345678');
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  final bool _rateLimitExceeded = false;
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
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return Container(
              color: isWide ? AppColors.sand : Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space24,
                  vertical: AppDimens.space16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - (AppDimens.space16 * 2)).clamp(0.0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const SizedBox(height: AppDimens.space8),

                            // Title
                            Text(
                              isAr ? 'أدخل رقم موبايلك' : 'Enter your mobile number',
                              style: AppTypography.largeTitle(),
                            ),
                            const SizedBox(height: AppDimens.space8),

                            // Subtitle
                            Text(
                              isAr ? 'هنبعتلك كود تأكيد عبر رسالة SMS' : 'We will send you a verification code via SMS',
                              style: AppTypography.bodySecondary(),
                            ),
                            const SizedBox(height: AppDimens.space24),

                            if (_rateLimitExceeded) ...[
                              AlertBanner(
                                message: isAr ? 'طلبت كود مرات كتير. جرّب تاني بعد ساعة' : 'Too many attempts. Please try again after 1 hour',
                                type: AlertBannerType.danger,
                              ),
                              const SizedBox(height: AppDimens.space16),
                            ],

                            // Label
                            Text(
                              isAr ? 'رقم الهاتف المحمول' : 'Mobile Phone Number',
                              style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppDimens.space8),

                            // Uber / inDrive Styled Phone Input Field Card
                            AnimatedContainer(
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
                                  // Egyptian Flag & Country Code Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F3F4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🇪🇬', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '+20',
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
                                    color: const Color(0xFFE5E5EA),
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

                                  // Clear button
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
                                ],
                              ),
                            ),

                            const SizedBox(height: AppDimens.space12),

                            // Helper or Error text
                            if (hasError)
                              Row(
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
                              )
                            else
                              Row(
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
                              ),
                          ],
                        ),

                        const SizedBox(height: AppDimens.space24),

                        Column(
                          children: [
                            // Switch to Email Option
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
                            const SizedBox(height: AppDimens.space12),

                            // Submit Button
                            MashwarButton(
                              text: isAr ? 'إرسال الكود' : 'Send Code',
                              isLoading: auth.isLoading,
                              onPressed: () => _handleSubmit(isAr),
                            ),
                            const SizedBox(height: AppDimens.space8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
      ),
    );
  }
}
