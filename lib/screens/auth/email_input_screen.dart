import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import 'otp_verification_screen.dart';
import 'phone_input_screen.dart';

/// Market-leading, minimalist Email input screen (Uber / inDrive standard).
/// Responsive layout:
/// - Wide / Desktop (>= 840px): 2-column split canvas (Left: Brand & Student/Enterprise benefits, Right: Email entry card)
/// - Mobile (< 840px): Full-height balanced vertical distribution with Step Progress, Demo chip & Benefits card
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
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildSingleLayout(context, auth, isAr, hasError, constraints),
              ),
            );
          },
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
                  isAr ? 'أدخل بريدك الإلكتروني' : 'Enter your email',
                  style: AppTypography.largeTitle().copyWith(fontSize: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'هنبعتلك كود تأكيد لتسجيل الدخول أو إنشاء حساب'
                      : 'We will send you a verification code to log in or create an account',
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: 18),

                // Input Label
                Text(
                  isAr ? 'البريد الإلكتروني' : 'Email Address',
                  style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // Email Input Card
                _buildEmailInputField(hasError: hasError, isAr: isAr),
                const SizedBox(height: 8),

                // Helper text / Error text
                _buildHelperOrError(hasError: hasError, isAr: isAr),
              ],
            ),

            const SizedBox(height: 16),

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
                const SizedBox(height: 10),

                // Switch to Phone
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.phone_iphone_rounded, size: 18, color: AppColors.navy),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
                      );
                    },
                    label: Text(
                      isAr ? 'المتابعة برقم الموبايل بدلاً من ذلك' : 'Continue with phone instead',
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

  Widget _buildEmailInputField({required bool hasError, required bool isAr}) {
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            Icons.mail_outline_rounded,
            color: _isFocused ? AppColors.navy : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _emailController,
                focusNode: _focusNode,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.body(color: AppColors.navy).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  hintStyle: AppTypography.bodySecondary(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
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
                onChanged: (val) {
                  setState(() => _errorText = null);
                },
              ),
            ),
          ),
          if (_emailController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: AppColors.textSecondary, size: 20),
              onPressed: () {
                setState(() {
                  _emailController.clear();
                  _errorText = null;
                });
              },
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
    return const SizedBox.shrink();
  }
}
