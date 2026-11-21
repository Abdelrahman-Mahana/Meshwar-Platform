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
  bool _obscurePassword = true;

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

  void _fillDemoRole(AdminRole role) {
    setState(() {
      _emailController.text = 'admin@mashwar.example';
      _passwordController.text = '12345678';
      _hasError = false;
    });
    context.read<AdminProvider>().setActiveRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildMobileLayout(context, settings, isAr, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    SettingsProvider settings,
    bool isAr,
    BoxConstraints constraints,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.space24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildFormContent(context, settings, isAr),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, SettingsProvider settings, bool isAr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Language Switch & Brand Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('م', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 20)),
              ),
            ),
            ActionChip(
              backgroundColor: const Color(0xFFF1F5F9),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
              avatar: const Icon(Icons.language_rounded, size: 16, color: AppColors.navy),
              label: Text(
                isAr ? 'English' : 'العربية',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.navy),
              ),
              onPressed: () => settings.toggleLanguage(),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Title
        Text(
          isAr ? 'دخول الإدارة والعمليات' : 'Admin Portal Login',
          style: AppTypography.title().copyWith(fontSize: 22, color: AppColors.navy, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'مشوار · لوحة تحكم النظام المركزية' : 'MASHWAR · Central Operations Center',
          style: AppTypography.label(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Quick Role Presets (Helpful for review & testing)
        Text(
          isAr ? 'اختر الدور الإداري:' : 'Select Staff Role:',
          style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ActionChip(
              backgroundColor: const Color(0xFFEBF3FA),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 0.8),
              avatar: const Icon(Icons.shield_rounded, size: 14, color: AppColors.navy),
              label: Text(
                isAr ? 'مشرف أول' : 'Super Admin',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              onPressed: () => _fillDemoRole(AdminRole.superAdmin),
            ),
            ActionChip(
              backgroundColor: const Color(0xFFE6F7F0),
              side: const BorderSide(color: Color(0xFFA7F3D0), width: 0.8),
              avatar: const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.teal),
              label: Text(
                isAr ? 'مشرف مراجعة' : 'Reviewer',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal),
              ),
              onPressed: () => _fillDemoRole(AdminRole.reviewAdmin),
            ),
            ActionChip(
              backgroundColor: const Color(0xFFFFFBEB),
              side: const BorderSide(color: Color(0xFFFDE68A), width: 0.8),
              avatar: const Icon(Icons.support_agent_rounded, size: 14, color: Color(0xFFD97706)),
              label: Text(
                isAr ? 'مشرف دعم' : 'Support',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
              ),
              onPressed: () => _fillDemoRole(AdminRole.supportAdmin),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Error Alert (Page 68)
        if (_hasError) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: 16),
        ],

        // Email Field
        Text(
          isAr ? 'البريد الإلكتروني الإداري' : 'Admin Email',
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
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Password Field
        Text(
          isAr ? 'كلمة المرور' : 'Password',
          style: AppTypography.label().copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.navy),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Submit Button
        MashwarButton(
          text: _isLoading
              ? (isAr ? 'جاري التحقق...' : 'Signing in...')
              : (isAr ? 'تسجيل الدخول' : 'Sign In to Dashboard'),
          isLoading: _isLoading,
          onPressed: _handleLogin,
        ),

        const SizedBox(height: 14),

        // Return to App (only when pushed over another route)
        if (Navigator.of(context).canPop())
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isAr ? 'الرجوع لتطبيق مشوار' : 'Back to MASHWAR App',
                style: AppTypography.bodySecondary(color: AppColors.navy).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
