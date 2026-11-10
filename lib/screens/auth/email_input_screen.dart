import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import 'otp_verification_screen.dart';
import 'phone_input_screen.dart';

/// Market-leading, minimalist Email input screen (Uber / inDrive standard).
/// Features email formatting validation, dynamic focus state, quick-demo filling chip,
/// and seamless switching to Phone input.
class EmailInputScreen extends StatefulWidget {
  const EmailInputScreen({super.key});

  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'student@mashwar.eg');
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(bool isAr) async {
    final email = _emailController.text.trim();
    final validationError = AuthProvider.validateEmail(email);
    if (validationError != null) {
      setState(() {
        _errorText = isAr ? validationError : 'Please enter a valid email address';
      });
      return;
    }

    setState(() => _errorText = null);

    final auth = context.read<AuthProvider>();
    final success = await auth.sendEmailOtp(email);
    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email),
        ),
      );
    }
  }

  void _fillDemoEmail(String demo) {
    setState(() {
      _emailController.text = demo;
      _errorText = null;
    });
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimens.space16),

              // Title
              Text(
                isAr ? 'أدخل بريدك الإلكتروني' : 'Enter your email',
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: AppDimens.space8),

              // Subtitle
              Text(
                isAr
                    ? 'هنبعتلك كود تأكيد لتسجيل الدخول أو إنشاء حساب'
                    : 'We will send you a verification code to log in or create an account',
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: AppDimens.space24),

              // Label
              Text(
                isAr ? 'البريد الإلكتروني' : 'Email Address',
                style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppDimens.space8),

              // Uber / inDrive Styled Email Input Card
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.navy,
                      size: 20,
                    ),
                    const SizedBox(width: 12),

                    // Email input textfield
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: TextField(
                          controller: _emailController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: AppTypography.body(color: AppColors.navy).copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'name@example.com',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
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
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() => _errorText = null);
                            }
                          },
                        ),
                      ),
                    ),

                    // Clear button
                    if (_emailController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 20),
                        onPressed: () {
                          setState(() {
                            _emailController.clear();
                            _errorText = null;
                          });
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Helper / Error Text
              if (hasError)
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 14),
                    const SizedBox(width: 4),
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
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'هنبعت كود مكون من 6 أرقام لتأكيد حسابك'
                            : 'We will send a 6-digit code to verify your account',
                        style: AppTypography.label(color: const Color(0xFF64748B)).copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: AppDimens.space16),

              // Quick Prototype Demo Chip
              InkWell(
                onTap: () => _fillDemoEmail('student@mashwar.eg'),
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
                        isAr ? 'تجربة سريعة: student@mashwar.eg' : 'Quick Demo: student@mashwar.eg',
                        style: AppTypography.label(color: AppColors.navy).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Switch to Phone Option
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.phone_iphone_rounded, size: 18, color: AppColors.navy),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
                    );
                  },
                  label: Text(
                    isAr ? 'المتابعة برقم الموبايل بدلاً من ذلك' : 'Continue with mobile number instead',
                    style: AppTypography.body(color: AppColors.navy).copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space12),

              // Submit CTA
              MashwarButton(
                text: isAr ? 'إرسال الكود' : 'Send Code',
                isLoading: auth.isLoading,
                onPressed: () => _handleSubmit(isAr),
              ),

              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }
}
