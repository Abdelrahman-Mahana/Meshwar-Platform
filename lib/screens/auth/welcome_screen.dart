import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../main_nav_shell.dart';
import 'email_input_screen.dart';
import 'phone_input_screen.dart';

/// Clean, honest Welcome & Entry screen for MASHWAR Qatar Worksite Supply MVP.
///
/// - Real Email+Password Sign In & Create Account CTAs.
/// - Dev quick-demo entry shown ONLY when `AppEnvironment.useDevMocks` is `true`.
/// - Clear explanatory copy when SMS phone OTP provider is unavailable.
/// - Zero fake live counters, fake moving cars, or fake verified personas.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final isAr = settings.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            if (isWide) {
              return Padding(
                padding: const EdgeInsets.all(AppDimens.space24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.borderDisabled),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.08),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildShowcasePanel(isAr),
                          ),
                          Expanded(
                            flex: 5,
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 480),
                                child: _buildFormColumn(
                                  context,
                                  settings,
                                  auth,
                                  isAr,
                                  constraints,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildFormColumn(
                  context,
                  settings,
                  auth,
                  isAr,
                  constraints,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShowcasePanel(bool isAr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF173654), AppColors.qatarMaroonDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const QatarSaduAccentBar(height: 5, borderRadius: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogo(fontSize: 30, isLight: true),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          isAr
                              ? 'قطر · المرحلة التجريبية الأولى (QAR)'
                              : 'Qatar Pilot Phase 1 · QAR',
                          style: AppTypography.label(color: AppColors.gold)
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAr
                            ? 'تنسيق توريد ومشتريات مواقع العمل في دولة قطر'
                            : 'Worksite Supply & Material Delivery Coordination in Qatar',
                        style: AppTypography.title(color: Colors.white)
                            .copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAr
                            ? 'اربط مهندسي ومشرفي المواقع بمزودي التوريد المعتمدين بالبطاقة القطرية (QID)، مع توثيق الفاتورة ورمز تسليم سري من 6 خانات.'
                            : 'Connect site supervisors with QID-approved providers across Doha, Industrial Area, Lusail, Al Wakrah & Al Khor with verified receipts and 6-char handover codes.',
                        style: AppTypography.bodySecondary(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    AppEnvironment.pilotScopeDisclaimer(isArabic: isAr),
                    style: AppTypography.bodySmall(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormColumn(
    BuildContext context,
    SettingsProvider settings,
    AuthProvider auth,
    bool isAr,
    BoxConstraints constraints,
  ) {
    final isCompact = constraints.maxHeight <= 640;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space24,
        vertical: AppDimens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Single ActionChip for language toggle
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _buildLanguageButton(settings, isAr),
          ),
          SizedBox(height: isCompact ? 12 : 24),

          BrandLogo(fontSize: isCompact ? 32 : 40),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'توريد مواقع العمل والمشاريع في قطر'
                : 'Qatar Worksite Supply & Site Errands',
            textAlign: TextAlign.center,
            style: AppTypography.title(color: AppColors.navy).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 15 : 17.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'سجّل الدخول أو أنشئ حساباً لإدارة طلبات التوريد وعروض المزودين المعتمدين بالريال القطري.'
                : 'Sign in or create an account to manage worksite supply requests and approved provider offers in QAR.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary(),
          ),
          SizedBox(height: isCompact ? 16 : 24),

          // Value pillars card (honest MVP features)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.qatarMaroon.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureBullet(
                  Icons.receipt_long_outlined,
                  isAr
                      ? 'ميزانيات دقيقة بالريال القطري وإرفاق فاتورة الشراء'
                      : 'Integer QAR budgets & store purchase invoice proof',
                ),
                const SizedBox(height: 8),
                _buildFeatureBullet(
                  Icons.verified_user_outlined,
                  isAr
                      ? 'مزودون معتمدون بعد مراجعة البطاقة القطرية (QID)'
                      : 'Providers verified via 11-digit Qatar ID (QID) review',
                ),
                const SizedBox(height: 8),
                _buildFeatureBullet(
                  Icons.key_rounded,
                  isAr
                      ? 'تأكيد الاستلام بالموقع عبر رمز تسليم أحادي من 6 خانات'
                      : 'On-site completion gated by single-use 6-char handover code',
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 18 : 24),

          // Primary CTA: Sign In with Email & Password
          MashwarButton(
            key: const ValueKey('welcome_email_login_btn'),
            text: isAr
                ? 'المتابعة بالبريد الإلكتروني'
                : 'Continue with Email',
            icon: const Icon(Icons.mail_outline_rounded,
                size: 20, color: Colors.white),
            onPressed: () {
              auth.clearError();
              Navigator.of(context).push(
                MashwarPageRoute(
                  builder: (_) =>
                      const EmailInputScreen(initialIsRegister: false),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Secondary CTA: Create New Account
          MashwarButton(
            key: const ValueKey('welcome_email_register_btn'),
            text: isAr ? 'إنشاء حساب جديد' : 'Create Account',
            variant: MashwarButtonVariant.secondary,
            icon: const Icon(Icons.person_add_alt_1_rounded,
                size: 19, color: AppColors.navy),
            onPressed: () {
              auth.clearError();
              Navigator.of(context).push(
                MashwarPageRoute(
                  builder: (_) =>
                      const EmailInputScreen(initialIsRegister: true),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Phone OTP (+974): enabled when Firebase Phone Auth or explicit dev-mock auth is available;
          // otherwise shows honest unavailable notice with direct Email+Password sign-in guidance.
          if (auth.isPhoneAuthAvailable) ...[
            OutlinedButton.icon(
              key: const ValueKey('welcome_phone_btn'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.borderDisabled),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                auth.clearError();
                Navigator.of(context).push(
                  MashwarPageRoute(builder: (_) => const PhoneInputScreen()),
                );
              },
              icon: const Icon(Icons.phone_iphone_rounded, size: 18),
              label: Text(
                isAr ? 'المتابعة برقم الجوال' : 'Continue with Mobile Number',
                style: AppTypography.body(color: AppColors.navy)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            if (!auth.isDevMockAuthEnabled) ...[
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'ملاحظة: رسائل التحقق (+974 SMS) تتطلب تفعيل فوترة الرسائل في Firebase Console، أو يمكنك الدخول فوراً بالبريد الإلكتروني وكلمة المرور أعلاه.'
                    : 'Note: +974 SMS OTP requires SMS billing enabled in Firebase Console, or sign in anytime with Email & Password above.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(color: AppColors.textSecondary)
                    .copyWith(fontSize: 11.5),
              ),
            ],
          ] else
            Container(
              key: const ValueKey('welcome_sms_unavailable_notice'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.sms_failed_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'الدخول عبر رسائل SMS (+974) يتطلب تفعيل Firebase Auth وفوترة الرسائل في Firebase Console؛ يرجى استخدام البريد الإلكتروني وكلمة المرور.'
                              : 'Phone SMS OTP (+974) requires Firebase Auth & SMS billing enabled in Firebase Console. Please sign in with Email & Password.',
                          style: AppTypography.bodySmall(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      key: const ValueKey('welcome_sms_fallback_email_btn'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        auth.clearError();
                        Navigator.of(context).push(
                          MashwarPageRoute(
                            builder: (_) =>
                                const EmailInputScreen(initialIsRegister: false),
                          ),
                        );
                      },
                      icon: const Icon(Icons.mail_outline_rounded,
                          size: 15, color: AppColors.teal),
                      label: Text(
                        isAr
                            ? 'الدخول بالبريد وكلمة المرور'
                            : 'Use Email & Password',
                        style: AppTypography.label(color: AppColors.teal)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Dev quick-demo entry strictly gated by AppEnvironment.useDevMocks
          if (AppEnvironment.useDevMocks) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              key: const ValueKey('welcome_dev_demo_btn'),
              onPressed: () async {
                final ok = await auth.loginWithEmail(
                  'pilot.dev@mashwar.qa',
                  'devpass123',
                );
                if (ok && context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainNavShell()),
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.developer_mode_rounded,
                  size: 16, color: AppColors.teal),
              label: Text(
                isAr
                    ? 'دخول سريع لبيئة التطوير (Dev Demo)'
                    : 'Quick Dev Environment Entry (Dev Demo)',
                style: AppTypography.label(color: AppColors.teal)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Text(
            isAr
                ? 'بالمتابعة أنت توافق على شروط الاستخدام وسياسة الخصوصية'
                : 'By continuing, you agree to Terms of Service & Privacy Policy',
            textAlign: TextAlign.center,
            style: AppTypography.label(color: const Color(0xFF94A3B8))
                .copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(color: AppColors.navy)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageButton(SettingsProvider settings, bool isAr) {
    return ActionChip(
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
      avatar:
          const Icon(Icons.language_rounded, size: 16, color: AppColors.navy),
      label: Text(
        isAr ? 'English' : 'العربية',
        style: AppTypography.label(color: AppColors.navy)
            .copyWith(fontWeight: FontWeight.bold),
      ),
      onPressed: () => settings.toggleLanguage(),
    );
  }
}

/// Vector Google "G" emblem retained for shared widget compatibility.
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final center = Offset(w / 2, size.height / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.65, 1.4, false, paint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx - 1,
        center.dy - strokeWidth / 2,
        center.dx + radius,
        center.dy + strokeWidth / 2,
      ),
      barPaint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.75, 1.5, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.25, 1.45, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.7, 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
