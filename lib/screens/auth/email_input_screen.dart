import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import '../main_nav_shell.dart';
import 'phone_input_screen.dart';

/// Real Email + Password Authentication screen supporting both Sign In
/// (`AuthProvider.loginWithEmail`) and Create Account (`AuthProvider.registerWithEmail`),
/// plus password reset (`AuthProvider.sendPasswordReset`).
class EmailInputScreen extends StatefulWidget {
  final bool initialIsRegister;

  const EmailInputScreen({
    super.key,
    this.initialIsRegister = false,
  });

  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen> {
  late bool _isRegister;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  String? _validationError;
  String? _infoBanner;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(BuildContext context, bool isAr) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    setState(() {
      _validationError = null;
      _infoBanner = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailErr = AuthProvider.validateEmail(email);
    if (emailErr != null) {
      setState(() {
        _validationError =
            isAr ? emailErr : 'Please enter a valid email address.';
      });
      return;
    }

    if (!_isRegister) {
      if (password.isEmpty) {
        setState(() {
          _validationError =
              isAr ? 'يرجى إدخال كلمة المرور.' : 'Password is required.';
        });
        return;
      }

      final ok = await auth.loginWithEmail(email, password);
      if (!context.mounted) return;
      if (ok && auth.isAuthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavShell()),
          (route) => false,
        );
      }
      return;
    }

    // Registration validation
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.length < 2) {
      setState(() {
        _validationError = isAr
            ? 'يرجى إدخال الاسم الكامل (حرفان على الأقل).'
            : 'Please enter your full name (at least 2 characters).';
      });
      return;
    }

    if (phone.isNotEmpty) {
      final phoneErr = AuthProvider.validateQatarPhone(phone);
      if (phoneErr != null) {
        setState(() {
          _validationError = isAr
              ? phoneErr
              : 'Phone must be 8 digits starting with 3, 5, 6, or 7.';
        });
        return;
      }
    }

    if (password.length < 6) {
      setState(() {
        _validationError = isAr
            ? 'كلمة المرور يجب أن تتكون من 6 أحرف أو أرقام على الأقل.'
            : 'Password must be at least 6 characters.';
      });
      return;
    }

    if (confirmPassword != password) {
      setState(() {
        _validationError = isAr
            ? 'كلمتا المرور غير متطابقتين.'
            : 'Passwords do not match.';
      });
      return;
    }

    final ok = await auth.registerWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone.isNotEmpty ? phone : null,
    );
    if (!context.mounted) return;
    if (ok && auth.isAuthenticated) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavShell()),
        (route) => false,
      );
    }
  }

  Future<void> _handleForgotPassword(BuildContext context, bool isAr) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final email = _emailController.text.trim();
    final emailErr = AuthProvider.validateEmail(email);
    if (emailErr != null) {
      setState(() {
        _validationError = isAr
            ? 'أدخل بريدك الإلكتروني أولاً لإرسال رابط استعادة كلمة المرور.'
            : 'Enter a valid email address first to reset your password.';
        _infoBanner = null;
      });
      return;
    }

    setState(() => _validationError = null);
    final ok = await auth.sendPasswordReset(email);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _infoBanner = isAr
            ? 'تم إرسال رابط إعادة تعيين كلمة المرور إلى $email.'
            : 'Password reset link sent to $email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAr = context.isArabic;
    final activeError = _validationError ?? auth.localizedError(isArabic: isAr);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 46,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space24,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandLogo(fontSize: 24),
                  const SizedBox(height: 8),
                  Text(
                    _isRegister
                        ? (isAr
                            ? 'إنشاء حساب في مشوار قطر'
                            : 'Create Your MASHWAR Account')
                        : (isAr
                            ? 'تسجيل الدخول بالبريد الإلكتروني'
                            : 'Sign In with Email'),
                    style: AppTypography.largeTitle().copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isRegister
                        ? (isAr
                            ? 'أنشئ حساباً حقيقياً لطلب توريد مواقع العمل أو التقدم كمزود معتمد.'
                            : 'Register with your email and password to create worksite requests or verify as a provider.')
                        : (isAr
                            ? 'أدخل بريدك الإلكتروني وكلمة المرور للوصول إلى طلباتك ومواقعك.'
                            : 'Enter your email address and password to access your worksite supply account.'),
                    style: AppTypography.bodySecondary().copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Mode Segmented Switch (Sign In vs Create Account)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            key: const ValueKey('auth_mode_login_tab'),
                            onTap: () {
                              auth.clearError();
                              setState(() {
                                _isRegister = false;
                                _validationError = null;
                                _infoBanner = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isRegister
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  isAr ? 'تسجيل الدخول' : 'Sign In',
                                  style: AppTypography.bodySecondary(
                                    color: !_isRegister
                                        ? AppColors.navy
                                        : AppColors.textSecondary,
                                  ).copyWith(
                                    fontWeight: !_isRegister
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            key: const ValueKey('auth_mode_register_tab'),
                            onTap: () {
                              auth.clearError();
                              setState(() {
                                _isRegister = true;
                                _validationError = null;
                                _infoBanner = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRegister
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  isAr ? 'إنشاء حساب' : 'Create Account',
                                  style: AppTypography.bodySecondary(
                                    color: _isRegister
                                        ? AppColors.navy
                                        : AppColors.textSecondary,
                                  ).copyWith(
                                    fontWeight: _isRegister
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (activeError != null && activeError.isNotEmpty) ...[
                    Container(
                      key: const ValueKey('auth_error_banner'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activeError,
                              style: AppTypography.label(color: AppColors.navy)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (_infoBanner != null) ...[
                    Container(
                      key: const ValueKey('auth_info_banner'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.tealSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _infoBanner!,
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (_isRegister) ...[
                    Text(
                      isAr ? 'الاسم الكامل *' : 'Full Name *',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const ValueKey('auth_fullname_input'),
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        hintText: isAr ? 'م. فهد المري' : 'Eng. Fahad Al-Marri',
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: AppColors.navy),
                      ),
                      onChanged: (_) {
                        if (auth.lastError != null) auth.clearError();
                        setState(() => _validationError = null);
                      },
                    ),
                    const SizedBox(height: 14),

                    Text(
                      isAr
                          ? 'رقم الجوال القطري (+974 - اختياري)'
                          : 'Qatar Mobile (+974 - Optional)',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        key: const ValueKey('auth_phone_optional_input'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '55123456',
                          prefixIcon: Icon(Icons.phone_iphone_rounded,
                              color: AppColors.navy),
                        ),
                        onChanged: (_) {
                          if (auth.lastError != null) auth.clearError();
                          setState(() => _validationError = null);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  Text(
                    isAr ? 'البريد الإلكتروني *' : 'Email Address *',
                    style: AppTypography.label(color: AppColors.navy)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      key: const ValueKey('auth_email_input'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'name@company.qa',
                        prefixIcon: Icon(Icons.mail_outline_rounded,
                            color: AppColors.navy),
                      ),
                      onChanged: (_) {
                        if (auth.lastError != null) auth.clearError();
                        setState(() => _validationError = null);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    isAr ? 'كلمة المرور *' : 'Password *',
                    style: AppTypography.label(color: AppColors.navy)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      key: const ValueKey('auth_password_input'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.navy),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      onChanged: (_) {
                        if (auth.lastError != null) auth.clearError();
                        setState(() => _validationError = null);
                      },
                    ),
                  ),

                  if (_isRegister) ...[
                    const SizedBox(height: 14),
                    Text(
                      isAr ? 'تأكيد كلمة المرور *' : 'Confirm Password *',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        key: const ValueKey('auth_confirm_password_input'),
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: const InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_reset_rounded,
                              color: AppColors.navy),
                        ),
                        onChanged: (_) {
                          if (auth.lastError != null) auth.clearError();
                          setState(() => _validationError = null);
                        },
                      ),
                    ),
                  ] else ...[
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        key: const ValueKey('auth_forgot_password_btn'),
                        onPressed: () => _handleForgotPassword(context, isAr),
                        child: Text(
                          isAr ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                          style: AppTypography.label(color: AppColors.teal)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],

                  if (AppEnvironment.useDevMocks) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const ValueKey('email_dev_autofill_btn'),
                      onPressed: () {
                        setState(() {
                          _emailController.text = 'engineer@mashwar.qa';
                          _passwordController.text = 'pilot1234';
                          if (_isRegister) {
                            _fullNameController.text = 'م. فهد المري';
                            _confirmPasswordController.text = 'pilot1234';
                          }
                        });
                      },
                      icon: const Icon(Icons.bolt_rounded,
                          size: 16, color: AppColors.teal),
                      label: Text(
                        isAr
                            ? 'تعبئة تجريبية (وضع التطوير فقط)'
                            : 'Autofill Dev Credentials',
                        style: AppTypography.label(color: AppColors.teal),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  MashwarButton(
                    key: const ValueKey('auth_submit_btn'),
                    text: _isRegister
                        ? (isAr ? 'إنشاء حساب' : 'Create Account')
                        : (isAr ? 'تسجيل الدخول' : 'Sign In'),
                    isLoading: auth.isLoading,
                    onPressed: () => _handleSubmit(context, isAr),
                  ),
                  const SizedBox(height: 8),

                  if (auth.isPhoneAuthAvailable)
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.phone_iphone_rounded,
                            size: 18, color: AppColors.navy),
                        onPressed: () {
                          auth.clearError();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const PhoneInputScreen()),
                          );
                        },
                        label: Text(
                          isAr
                              ? 'المتابعة برقم الجوال بدلاً من ذلك'
                              : 'Continue with phone instead',
                          style: AppTypography.body(color: AppColors.navy)
                              .copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      isAr
                          ? 'ملاحظة: تسجيل الدخول عبر رسائل SMS معطّل حالياً لحين ربط مزود رسائل معتمد.'
                          : 'Note: SMS OTP login is disabled until an SMS provider is configured.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
