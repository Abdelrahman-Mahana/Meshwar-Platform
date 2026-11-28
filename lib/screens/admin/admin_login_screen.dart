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
import 'widgets/admin_ui_kit.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hasError = false;
  int _remainingAttempts = 5;
  DateTime? _lockoutUntil;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get _isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (_isLockedOut) {
      setState(() => _hasError = true);
      return;
    }
    if (_lockoutUntil != null && !DateTime.now().isBefore(_lockoutUntil!)) {
      _lockoutUntil = null;
      _remainingAttempts = 5;
    }

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
      setState(() {
        _isLoading = false;
        _remainingAttempts = 5;
        _lockoutUntil = null;
      });
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
        if (_remainingAttempts > 0) {
          _remainingAttempts--;
        }
        if (_remainingAttempts == 0) {
          _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
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
    final t = AdminThemeTokens.of(context);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
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
                                    isAr ? 'م' : 'M',
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
    final t = AdminThemeTokens.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.space24),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: t.isDark ? 0.25 : 0.05),
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
                          isAr ? 'م' : 'M',
                          style: AppTypography.brandLogo(
                            size: 20,
                            color: AppColors.navy,
                          ).copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    ActionChip(
                      backgroundColor: t.surfaceAlt,
                      side: BorderSide(color: t.border, width: 0.8),
                      avatar: Icon(Icons.language_rounded, size: 16, color: t.textPrimary),
                      label: Text(
                        isAr ? 'English' : 'العربية',
                        style: AppTypography.label(color: t.textPrimary)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                      onPressed: settings.toggleLanguage,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  isAr ? 'تسجيل دخول فريق الإدارة' : 'Operations Team Sign In',
                  style: AppTypography.title(color: t.textPrimary).copyWith(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? 'مشوار · إدارة الرحلات والطرود والتوريد' : 'MASHWAR · Trips, Parcels & Supply Ops',
                  style: AppTypography.label(color: t.textSecondary),
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
                            _isLockedOut
                                ? (isAr
                                    ? 'تم تجاوز الحد المسموح من المحاولات. يرجى الانتظار 30 ثانية ثم إعادة المحاولة.'
                                    : 'Too many failed attempts. Please wait 30 seconds before trying again.')
                                : (context.watch<AdminProvider>().authError ??
                                    (isAr
                                        ? 'بيانات الدخول غير صحيحة أو الحساب غير مخوّل. باقي $_remainingAttempts محاولات'
                                        : 'Invalid credentials or inactive staff access. $_remainingAttempts attempts remaining')),
                            style: AppTypography.label(color: AppColors.danger).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(isAr ? 'البريد الإلكتروني الإداري' : 'Admin Email', style: AppTypography.label(color: t.textPrimary).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _handleLogin(),
                  style: AppTypography.body(color: t.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'staff@mashwar.qa',
                    hintStyle: AppTypography.bodySecondary(
                      color: t.textSecondary.withValues(alpha: 0.72),
                    ),
                    prefixIcon: Icon(Icons.email_outlined, color: t.accentPrimary),
                    filled: true,
                    fillColor: t.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusField)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(isAr ? 'كلمة المرور' : 'Password', style: AppTypography.label(color: t.textPrimary).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _handleLogin(),
                  style: AppTypography.body(color: t.textPrimary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTypography.bodySecondary(
                      color: t.textSecondary.withValues(alpha: 0.72),
                    ),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: t.accentPrimary),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? (isAr ? 'إظهار كلمة المرور' : 'Show password')
                          : (isAr ? 'إخفاء كلمة المرور' : 'Hide password'),
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: t.surfaceAlt,
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
