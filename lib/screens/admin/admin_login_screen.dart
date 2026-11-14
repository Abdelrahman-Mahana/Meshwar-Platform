import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/brand_logo.dart';
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
            final isWide = constraints.maxWidth >= 880;
            if (isWide) {
              return _buildWideLayout(context, settings, isAr, constraints);
            }
            return _buildMobileLayout(context, settings, isAr, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    SettingsProvider settings,
    bool isAr,
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
                colors: [AppColors.navy, Color(0xFF091E33)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
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
                      isAr ? 'منصة العمليات والإدارة المركزية' : 'Central Operations & Admin Portal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'إدارة الرحلات بين المحافظات، توثيق السائقين بالرقم القومي، ومراقبة أمان شحن الطرود لحظياً.'
                          : 'Intercity carpooling ops, National ID driver verifications, and parcel delivery monitoring.',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
                    ),
                  ],
                ),

                // Feature Highlights
                Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.cell_tower_rounded,
                      title: isAr ? 'تغطية شاملة لـ 27 محافظة' : 'All 27 Governorates Active',
                      subtitle: isAr ? 'متابعة حية للرحلات ومحاور السفر الرئيسية على مدار الساعة.' : 'Real-time tracking of intercity travel corridors.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.verified_user_rounded,
                      title: isAr ? 'مراجعة وتدقيق المستندات الرسمية' : 'Verified Identity Checks',
                      subtitle: isAr ? 'فحص بطاقات الرقم القومي ورخص القيادة والسيارات بدقة.' : 'Thorough review of National IDs, driver and car licenses.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.security_rounded,
                      title: isAr ? 'سجل تدقيق رقابي غير قابل للتعديل' : 'Immutable Operations Audit Log',
                      subtitle: isAr ? 'كل إجراء إداري موثق بالوقت ومسؤول التشغيل والسبب.' : 'Every action logged with timestamp, actor role, and reason.',
                    ),
                  ],
                ),

                // Metrics Strip
                Row(
                  children: [
                    _buildMetricChip('99.98%', isAr ? 'جاهزية الخوادم' : 'System Uptime'),
                    const SizedBox(width: 24),
                    _buildMetricChip('27', isAr ? 'محافظة مغطاة' : 'Governorates'),
                    const SizedBox(width: 24),
                    _buildMetricChip('24/7', isAr ? 'مراقبة أمنية' : 'Live Ops'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Right Login Form Area
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildFormContent(context, settings, isAr),
              ),
            ),
          ),
        ),
      ],
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
          isAr ? 'محاكاة الأدوار الإدارية (صفحة 77):' : 'Simulated Admin Roles (Page 77):',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
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

        // Return to App
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
      ],
    );
  }
}
