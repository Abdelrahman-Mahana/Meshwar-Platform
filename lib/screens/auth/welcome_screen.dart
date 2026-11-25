import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
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
                                  isWide: true,
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
                  isWide: false,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShowcasePanel(bool isAr) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const MashwarAssetArt(
          assetPath: 'assets/images/mvp_hero_lusail_supply.jpg',
          fit: BoxFit.cover,
          fallbackIcon: Icons.local_shipping_rounded,
          fallbackBg: AppColors.navy,
          fallbackColor: AppColors.gold,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.navy.withValues(alpha: 0.90),
                const Color(0xFF173654).withValues(alpha: 0.84),
                AppColors.qatarMaroonDark.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const QatarSaduAccentBar(height: 5, borderRadius: 0),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLogo(fontSize: 30, isLight: true),
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5),
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
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTrustPill(
                          MashwarTrustType.qatarIdCrest,
                          isAr ? 'مراجعة QID' : 'QID Reviewed',
                        ),
                        _buildTrustPill(
                          MashwarTrustType.verifiedReceipt,
                          isAr ? 'فاتورة موثّقة' : 'Invoice Proof',
                        ),
                        _buildTrustPill(
                          MashwarTrustType.handoverShield,
                          isAr ? 'رمز تسليم 6 خانات' : '6-Char Handover',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      AppEnvironment.pilotScopeDisclaimer(isArabic: isAr),
                      style: AppTypography.bodySmall(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustPill(MashwarTrustType type, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: MashwarTrustEmblem(type: type, size: 20),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.label(color: Colors.white).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
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
    BoxConstraints constraints, {
    required bool isWide,
  }) {
    final isCompact = constraints.maxHeight <= 640;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppDimens.space20 : AppDimens.space24,
        vertical: isCompact ? 8 : AppDimens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Single ActionChip for language toggle
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _buildLanguageButton(settings, isAr),
          ),
          SizedBox(height: isCompact ? 6 : 18),

          if (!isWide)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
                border: Border.all(
                  color: AppColors.navy.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: MashwarAssetArt(
                      assetPath: 'assets/images/mvp_hero_lusail_supply.jpg',
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.local_shipping_rounded,
                      fallbackBg: AppColors.navy,
                      fallbackColor: AppColors.gold,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.navy.withValues(alpha: 0.90),
                            AppColors.qatarMaroonDark.withValues(alpha: 0.84),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const QatarSaduAccentBar(height: 3.5, borderRadius: 0),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: isCompact ? 8 : 16,
                        ),
                        child: isCompact
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const BrandLogo(
                                    fontSize: 22,
                                    showEnglish: false,
                                    isLight: true,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildCompactTrustIcon(
                                          MashwarTrustType.qatarIdCrest),
                                      const SizedBox(width: 6),
                                      _buildCompactTrustIcon(
                                          MashwarTrustType.verifiedReceipt),
                                      const SizedBox(width: 6),
                                      _buildCompactTrustIcon(
                                          MashwarTrustType.handoverShield),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  const BrandLogo(
                                    fontSize: 34,
                                    isLight: true,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _buildTrustPill(
                                        MashwarTrustType.qatarIdCrest,
                                        isAr ? 'مراجعة QID' : 'QID Reviewed',
                                      ),
                                      _buildTrustPill(
                                        MashwarTrustType.verifiedReceipt,
                                        isAr
                                            ? 'فاتورة موثّقة'
                                            : 'Invoice Proof',
                                      ),
                                      _buildTrustPill(
                                        MashwarTrustType.handoverShield,
                                        isAr ? 'رمز تسليم' : 'Handover Code',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            const BrandLogo(fontSize: 40),
          SizedBox(height: isCompact ? 6 : 14),
          Text(
            isAr
                ? 'توريد مواقع العمل والمشاريع في قطر'
                : 'Qatar Worksite Supply & Site Errands',
            textAlign: TextAlign.center,
            style: AppTypography.title(color: AppColors.navy).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 14.5 : 17.5,
            ),
          ),
          SizedBox(height: isCompact ? 3 : 6),
          Text(
            isAr
                ? 'سجّل الدخول أو أنشئ حساباً لإدارة طلبات التوريد وعروض المزودين المعتمدين بالريال القطري.'
                : 'Sign in or create an account to manage worksite supply requests and approved provider offers in QAR.',
            textAlign: TextAlign.center,
            maxLines: isCompact ? 2 : null,
            overflow: isCompact ? TextOverflow.ellipsis : null,
            style: AppTypography.bodySecondary().copyWith(
              fontSize: isCompact ? 12.5 : 14,
            ),
          ),
          SizedBox(height: isCompact ? 8 : 22),

          // Value pillars card (honest MVP features)
          Container(
            padding: EdgeInsets.all(isCompact ? 10 : 14),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(14),
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
                  compact: isCompact,
                ),
                SizedBox(height: isCompact ? 4 : 8),
                _buildFeatureBullet(
                  Icons.verified_user_outlined,
                  isAr
                      ? 'مزودون معتمدون بعد مراجعة البطاقة القطرية (QID)'
                      : 'Providers verified via 11-digit Qatar ID (QID) review',
                  compact: isCompact,
                ),
                SizedBox(height: isCompact ? 4 : 8),
                _buildFeatureBullet(
                  Icons.key_rounded,
                  isAr
                      ? 'تأكيد الاستلام بالموقع عبر رمز تسليم أحادي من 6 خانات'
                      : 'On-site completion gated by single-use 6-char handover code',
                  compact: isCompact,
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 10 : 22),

          // Primary CTA: Sign In with Email & Password
          MashwarButton(
            key: const ValueKey('welcome_email_login_btn'),
            height: isCompact ? 44 : AppDimens.minTouchTarget,
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
          SizedBox(height: isCompact ? 6 : 10),

          // Secondary CTA: Create New Account
          MashwarButton(
            key: const ValueKey('welcome_email_register_btn'),
            height: isCompact ? 44 : AppDimens.minTouchTarget,
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
          SizedBox(height: isCompact ? 8 : 14),

          // Phone OTP (+974): enabled when Firebase Phone Auth or explicit dev-mock auth is available;
          // otherwise shows honest unavailable notice with direct Email+Password sign-in guidance.
          if (auth.isPhoneAuthAvailable) ...[
            OutlinedButton.icon(
              key: const ValueKey('welcome_phone_btn'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.borderDisabled),
                minimumSize: Size(0, isCompact ? 40 : AppDimens.minTouchTarget),
                padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 12),
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

  Widget _buildCompactTrustIcon(MashwarTrustType type) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: MashwarTrustEmblem(type: type, size: 18),
    );
  }

  Widget _buildFeatureBullet(
    IconData icon,
    String text, {
    bool compact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: compact ? 15 : 17, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(color: AppColors.navy).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11.5 : 12,
            ),
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
