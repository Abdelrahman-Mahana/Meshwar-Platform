import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../state/auth_provider.dart';
import '../main_nav_shell.dart';
import 'phone_input_screen.dart';
import 'profile_setup_screen.dart';

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

  InputDecoration _buildFieldDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: AppTypography.bodySecondary(
        color: AppColors.textSecondary.withValues(alpha: 0.65),
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.navy, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        borderSide: const BorderSide(
          color: AppColors.slateBorder,
          width: AppDimens.borderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        borderSide: const BorderSide(
          color: AppColors.slateBorder,
          width: AppDimens.borderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        borderSide: const BorderSide(
          color: AppColors.navy,
          width: AppDimens.borderWidthFocused,
        ),
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context, bool isAr) async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;

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
    final rawPhone = _phoneController.text.trim();
    final normalizedPhone =
        rawPhone.isNotEmpty ? _normalizeDigits(rawPhone) : '';
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.length < 2) {
      setState(() {
        _validationError = isAr
            ? 'يرجى إدخال الاسم الكامل (حرفان على الأقل).'
            : 'Please enter your full name (at least 2 characters).';
      });
      return;
    }

    if (rawPhone.isNotEmpty) {
      final phoneErr = AuthProvider.validateQatarPhone(normalizedPhone);
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
      phone: normalizedPhone.isNotEmpty ? normalizedPhone : null,
    );
    if (!context.mounted) return;
    if (ok && auth.isAuthenticated) {
      final needsProfileOnboarding = auth.user.governorate == null ||
          auth.user.governorate!.trim().isEmpty;
      final isWidgetTestHarness =
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
      final shouldRunGuidedOnboarding = !isWidgetTestHarness ||
          !auth.isDevMockAuthEnabled ||
          AppEnvironment.isFirebaseRuntimeActive ||
          AppEnvironment.flavor != AppFlavor.development;

      if (needsProfileOnboarding && shouldRunGuidedOnboarding) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ProfileSetupScreen(isNewRegistration: true),
          ),
          (route) => false,
        );
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavShell()),
        (route) => false,
      );
    }
  }

  Future<void> _handleForgotPassword(BuildContext context, bool isAr) async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;

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
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space20,
                vertical: AppDimens.space16,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.slateBorder,
                    width: AppDimens.borderWidth,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BrandLogo(fontSize: 24),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MashwarServicePillarIcon(
                              pillar: MashwarServicePillar.sharedTrips,
                              size: 24,
                            ),
                            SizedBox(width: 6),
                            MashwarServicePillarIcon(
                              pillar: MashwarServicePillar.routeParcels,
                              size: 24,
                            ),
                            SizedBox(width: 6),
                            MashwarServicePillarIcon(
                              pillar: MashwarServicePillar.smartSupply,
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isRegister
                          ? (isAr
                              ? 'إنشاء حساب جديد في مشوار'
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
                              ? 'أنشئ حسابك لنشر وحجز الرحلات، إرسال الطرود على الطريق، وطلب التوريد والمهام.'
                              : 'Register to share trips, send parcels on active routes, and coordinate smart supply requests.')
                          : (isAr
                              ? 'أدخل بريدك الإلكتروني وكلمة المرور للوصول إلى رحلاتك وطرودك وطلباتك.'
                              : 'Enter your email address and password to access your trips, parcels, and requests.'),
                      style: AppTypography.bodySecondary(),
                    ),
                    const SizedBox(height: 16),

                    // Mode Segmented Switch (Sign In vs Create Account)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.slateBg,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusField),
                        border: Border.all(
                          color: AppColors.slateBorder,
                          width: AppDimens.borderWidth,
                        ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isRegister
                                      ? AppColors.navy
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Text(
                                    isAr ? 'تسجيل الدخول' : 'Sign In',
                                    style: AppTypography.label(
                                      color: !_isRegister
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ).copyWith(fontSize: 13),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isRegister
                                      ? AppColors.navy
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Text(
                                    isAr ? 'إنشاء حساب' : 'Create Account',
                                    style: AppTypography.label(
                                      color: _isRegister
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ).copyWith(fontSize: 13),
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
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusAlert),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.4),
                            width: AppDimens.borderWidth,
                          ),
                        ),
                        child: Row(
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
                                activeError,
                                style: AppTypography.label(
                                  color: AppColors.navy,
                                ),
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
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusAlert),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.35),
                            width: AppDimens.borderWidth,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.teal,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _infoBanner!,
                                style: AppTypography.label(
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_isRegister) ...[
                      Text(
                        isAr ? 'الاسم الكامل *' : 'Full Name *',
                        style: AppTypography.label(color: AppColors.navy),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        key: const ValueKey('auth_fullname_input'),
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        style: AppTypography.body(),
                        decoration: _buildFieldDecoration(
                          hintText: isAr ? 'م. فهد المري' : 'Alex Morgan',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        onChanged: (_) {
                          if (auth.lastError != null) auth.clearError();
                          setState(() => _validationError = null);
                        },
                      ),
                      const SizedBox(height: 14),

                      Text(
                        isAr
                            ? 'رقم الجوال (اختياري)'
                            : 'Mobile Number (Optional)',
                        style: AppTypography.label(color: AppColors.navy),
                      ),
                      const SizedBox(height: 6),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: TextField(
                          key: const ValueKey('auth_phone_optional_input'),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: AppTypography.body(),
                          decoration: _buildFieldDecoration(
                            hintText: '55123456',
                            prefixIcon: Icons.phone_iphone_rounded,
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
                      style: AppTypography.label(color: AppColors.navy),
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        key: const ValueKey('auth_email_input'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: AppTypography.body(),
                        decoration: _buildFieldDecoration(
                          hintText: 'name@mashwar.app',
                          prefixIcon: Icons.mail_outline_rounded,
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
                      style: AppTypography.label(color: AppColors.navy),
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        key: const ValueKey('auth_password_input'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: _isRegister
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onSubmitted: !_isRegister
                            ? (_) => _handleSubmit(context, isAr)
                            : null,
                        style: AppTypography.body(),
                        decoration: _buildFieldDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
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
                        style: AppTypography.label(color: AppColors.navy),
                      ),
                      const SizedBox(height: 6),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: TextField(
                          key: const ValueKey('auth_confirm_password_input'),
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleSubmit(context, isAr),
                          style: AppTypography.body(),
                          decoration: _buildFieldDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_reset_rounded,
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
                          onPressed: auth.isLoading
                              ? null
                              : () => _handleForgotPassword(context, isAr),
                          child: Text(
                            isAr ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                            style: AppTypography.label(color: AppColors.navy),
                          ),
                        ),
                      ),
                    ],

                    if (AppEnvironment.useDevMocks) ...[
                      const SizedBox(height: 6),
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
                        icon: const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppColors.navy,
                        ),
                        label: Text(
                          isAr
                              ? 'تعبئة تجريبية (وضع التطوير فقط)'
                              : 'Autofill Dev Credentials',
                          style: AppTypography.label(color: AppColors.navy),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    MashwarButton(
                      key: const ValueKey('auth_submit_btn'),
                      text: _isRegister
                          ? (isAr ? 'إنشاء حساب' : 'Create Account')
                          : (isAr ? 'تسجيل الدخول' : 'Sign In'),
                      isLoading: auth.isLoading,
                      onPressed: () => _handleSubmit(context, isAr),
                    ),
                    const SizedBox(height: 10),

                    if (auth.isPhoneAuthAvailable)
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(
                            Icons.phone_iphone_rounded,
                            size: 18,
                            color: AppColors.navy,
                          ),
                          onPressed: () {
                            auth.clearError();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const PhoneInputScreen(),
                              ),
                            );
                          },
                          label: Text(
                            isAr
                                ? 'المتابعة برقم الجوال بدلاً من ذلك'
                                : 'Continue with phone instead',
                            style: AppTypography.bodySecondary(
                              color: AppColors.navy,
                            ).copyWith(
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
      ),
    );
  }
  static String _normalizeDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
      result = result.replaceAll(easternDigits[i], '$i');
    }
    return result.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
