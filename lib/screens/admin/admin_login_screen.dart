import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin_main.dart';
import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_embedded_google_map.dart';
import '../../data/services/google_maps_service.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'admin_shell.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final admin = context.read<AdminProvider>();
    final bool ok;
    if (AppEnvironment.useDevMocks && admin.isDevMockMode) {
      ok = admin.login(email, password);
    } else {
      ok = await admin.signInStaffWithFirebase(email, password);
    }

    if (!mounted) return;

    if (ok) {
      setState(() => _isLoading = false);
      final insideShell =
          context.findAncestorWidgetOfExactType<AdminShell>() != null;
      final insideAdminApp =
          context.findAncestorWidgetOfExactType<MashwarAdminWebApp>() != null;
      if (!insideShell && !insideAdminApp) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminShell()),
        );
      }
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
    if (!AppEnvironment.useDevMocks) return;
    setState(() {
      _emailController.text = 'dev-staff@mashwar.qa';
      _passwordController.text = 'dev-mock-only';
      _hasError = false;
    });
    context.read<AdminProvider>().setActiveRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 960) {
              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.navy, Color(0xFF071627)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Center(
                                  child: Text(
                                    'م',
                                    style: AppTypography.brandLogo(
                                      size: 22,
                                      color: AppColors.navy,
                                    ).copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  isAr ? 'لوحة إدارة مشوار' : 'MASHWAR Operations Portal',
                                  style: AppTypography.title(color: Colors.white)
                                      .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAr
                                ? 'تابع عمليات اليوم في مكان واحد: الرحلات التشاركية، الطرود على الطريق، التوريد الميداني، مراجعة هويات QID، ورسائل الموقع.'
                                : 'Follow daily operations from one workspace: shared trips, route parcels, worksite supply, QID verification, and site inquiries.',
                            style: AppTypography.body(color: const Color(0xFFCBD5E1))
                                .copyWith(fontSize: 14, height: 1.55),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(18)),
                              child: LayoutBuilder(
                                builder: (context, mapBox) {
                                  return MashwarEmbeddedGoogleMap(
                                    key: const ValueKey('admin_login_uber_map'),
                                    origin: 'المنطقة الصناعية',
                                    destination: 'لوسيل',
                                    vehicleMode: MashwarMapVehicleMode.supply,
                                    stylePreset: MashwarMapStylePreset.dark,
                                    showTraffic: true,
                                    height: mapBox.maxHeight.clamp(220.0, 520.0),
                                    borderRadius: 18,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _securityChip(Icons.verified_user_rounded, isAr ? 'توثيق QID (11 رقماً)' : '11-Digit QID KYC'),
                              _securityChip(Icons.qr_code_2_rounded, isAr ? 'تحقق تسليم OTP و SHA-256' : 'OTP & SHA-256 Handover'),
                              _securityChip(Icons.cloud_done_rounded, isAr ? 'صلاحيات 5 أدوار · Firebase حي' : '5 RBAC Roles · Live Firebase'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: _buildFormCard(context, settings, isAr),
                  ),
                ],
              );
            }
            return _buildFormCard(context, settings, isAr);
          },
        ),
      ),
    );
  }

  Widget _securityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.label(color: Colors.white)
                .copyWith(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, SettingsProvider settings, bool isAr) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.space24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text(
                          'م',
                          style: AppTypography.brandLogo(
                            size: 20,
                            color: AppColors.navy,
                          ).copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    ActionChip(
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                      avatar: const Icon(Icons.language_rounded, size: 16, color: AppColors.navy),
                      label: Text(
                        isAr ? 'English' : 'العربية',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                      onPressed: settings.toggleLanguage,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  isAr ? 'تسجيل دخول فريق الإدارة' : 'Operations Team Sign In',
                  style: AppTypography.title().copyWith(fontSize: 20, color: AppColors.navy, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? 'مشوار · إدارة الرحلات والطرود والتوريد' : 'MASHWAR · Trips, Parcels & Supply Ops',
                  style: AppTypography.label(color: AppColors.textSecondary),
                ),
                if (AppEnvironment.useDevMocks) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.goldSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.developer_mode_rounded,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'وضع التطوير التجريبي (DEV MOCK ONLY)'
                                    : 'DEV MOCK MODE ONLY — Not active in production',
                                style: AppTypography.label(
                                  color: AppColors.navy,
                                ).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _roleChip(
                              AdminRole.superAdmin,
                              Icons.shield_rounded,
                              isAr ? 'مشرف أول' : 'Super Admin',
                              AppColors.navy,
                            ),
                            _roleChip(
                              AdminRole.reviewAdmin,
                              Icons.verified_user_rounded,
                              isAr ? 'مراجعة QID' : 'Reviewer',
                              AppColors.teal,
                            ),
                            _roleChip(
                              AdminRole.supportAdmin,
                              Icons.support_agent_rounded,
                              isAr ? 'الدعم والنزاعات' : 'Support',
                              const Color(0xFFD97706),
                            ),
                            _roleChip(
                              AdminRole.financeAdmin,
                              Icons.account_balance_wallet_rounded,
                              isAr ? 'مالية وضمان' : 'Escrow',
                              AppColors.qatarMaroon,
                            ),
                            _roleChip(
                              AdminRole.devopsAdmin,
                              Icons.terminal_rounded,
                              'DevOps / SRE',
                              const Color(0xFF4338CA),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
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
                            context.watch<AdminProvider>().authError ??
                                (isAr
                                    ? 'بيانات الدخول غير صحيحة أو الحساب غير مخوّل. باقي $_remainingAttempts محاولات'
                                    : 'Invalid credentials or inactive staff access. $_remainingAttempts attempts left'),
                            style: AppTypography.label(color: AppColors.danger).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(isAr ? 'البريد الإلكتروني الإداري' : 'Admin Email', style: AppTypography.label().copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.body(color: AppColors.navy),
                  decoration: InputDecoration(
                    hintText: 'staff@mashwar.qa',
                    hintStyle: AppTypography.bodySecondary(
                      color: AppColors.textSecondary.withValues(alpha: 0.72),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.navy),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusField)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(isAr ? 'كلمة المرور' : 'Password', style: AppTypography.label().copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.body(color: AppColors.navy),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTypography.bodySecondary(
                      color: AppColors.textSecondary.withValues(alpha: 0.72),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.navy),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusField)),
                  ),
                ),
                const SizedBox(height: 20),
                MashwarButton(
                  text: _isLoading
                      ? (isAr ? 'جاري التحقق من الصلاحيات...' : 'Checking access...')
                      : (isAr ? 'دخول لوحة الإدارة' : 'Sign in to Admin Portal'),
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                if (Navigator.of(context).canPop()) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        isAr ? 'الرجوع لتطبيق مشوار' : 'Back to MASHWAR App',
                        style: AppTypography.bodySecondary(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(AdminRole role, IconData icon, String label, Color color) {
    final activeRole = context.watch<AdminProvider>().activeRole;
    final isSel = activeRole == role;
    return ActionChip(
      backgroundColor: isSel ? color.withValues(alpha: 0.14) : const Color(0xFFF8FAFC),
      side: BorderSide(color: isSel ? color : const Color(0xFFCBD5E1), width: isSel ? 1.4 : 0.8),
      avatar: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: AppTypography.label(color: color)
            .copyWith(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      onPressed: () => _fillDemoRole(role),
    );
  }
}
