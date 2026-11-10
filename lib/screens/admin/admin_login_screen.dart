import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'admin_shell.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'admin@mashwar.example');
  final TextEditingController _passwordController = TextEditingController(text: '12345678');
  bool _hasError = false;
  int _remainingAttempts = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email == 'admin@mashwar.example' && password.length >= 6) {
      context.read<AdminProvider>().login(email, password);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        if (_remainingAttempts > 1) {
          _remainingAttempts--;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand mark
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.goldSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.navy, size: 32),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Title
                    Text(
                      isAr ? 'دخول الإدارة' : 'Admin Portal Login',
                      textAlign: TextAlign.center,
                      style: AppTypography.title().copyWith(fontSize: 22, color: AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr ? 'مشوار · لوحة تحكم النظام' : 'MASHWAR · Control Center',
                      textAlign: TextAlign.center,
                      style: AppTypography.label(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Error Alert (Page 68)
                    if (_hasError) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'البريد أو كلمة المرور غير صحيحة. باقي $_remainingAttempts محاولات'
                                    : 'Invalid email or password. $_remainingAttempts attempts left',
                                style: AppTypography.label(color: AppColors.danger).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.space16),
                    ],

                    // Email Field
                    Text(
                      isAr ? 'البريد الإلكتروني' : 'Admin Email',
                      style: AppTypography.label().copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: 'admin@mashwar.example',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.navy),
                        filled: true,
                        fillColor: AppColors.sand,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusField),
                          borderSide: const BorderSide(color: AppColors.borderDisabled),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusField),
                          borderSide: const BorderSide(color: AppColors.borderDisabled),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Password Field
                    Text(
                      isAr ? 'كلمة المرور' : 'Password',
                      style: AppTypography.label().copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.navy),
                        filled: true,
                        fillColor: AppColors.sand,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusField),
                          borderSide: const BorderSide(color: AppColors.borderDisabled),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusField),
                          borderSide: const BorderSide(color: AppColors.borderDisabled),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Submit Button
                    MashwarButton(
                      text: _isLoading
                          ? (isAr ? 'جاري التحقق...' : 'Signing in...')
                          : (isAr ? 'تسجيل الدخول' : 'Sign In to Dashboard'),
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: AppDimens.space16),

                    // Return to App
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        isAr ? 'الرجوع لتطبيق مشوار' : 'Back to MASHWAR App',
                        style: AppTypography.bodySecondary(color: AppColors.navy),
                      ),
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
}
