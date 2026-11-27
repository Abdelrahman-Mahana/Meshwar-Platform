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

/// Executive 3-Service Welcome & Entry screen for MASHWAR:
/// Shared Trips · Route Parcels · Smart Supply.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final isAr = settings.isArabic;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
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
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.slateBorder,
                          width: AppDimens.borderWidth,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildShowcasePanel(isAr),
                          ),
                          Container(
                            width: AppDimens.borderWidth,
                            color: AppColors.slateBorder,
                          ),
                          Expanded(
                            flex: 5,
                            child: ColoredBox(
                              color: Colors.white,
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
    return Container(
      color: AppColors.navy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandLogo(fontSize: 30, isLight: true),
            const SizedBox(height: AppDimens.space20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: const MashwarAssetArt(
                  assetPath: 'assets/images/hero_banner.jpg',
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.route_rounded,
                  fallbackBg: AppColors.navy,
                  fallbackColor: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimens.radiusChip),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.5),
                  width: AppDimens.borderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 14,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isAr
                          ? 'منصة مشوار المتكاملة · 3 خدمات في تطبيق واحد'
                          : 'Unified Platform · 3 Services in One App',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space14),
            Text(
              isAr
                  ? 'شارك مقاعد رحلتك، أرسل طرداً على الطريق، أو اطلب توريد احتياجاتك بسهولة وأمان'
                  : 'Share Empty Seats, Send Parcels Along Active Routes, & Coordinate Smart Supply',
              style: AppTypography.title(color: Colors.white)
                  .copyWith(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              isAr
                  ? 'منصة حديثة تربط المسافرين وأصحاب الطلبات والمزودين المعتمدين مباشرة مع توثيق الفاتورة ورموز الأمان OTP و QR.'
                  : 'Connect directly with verified travelers and trusted supply providers with transparent pricing, receipt proof, and OTP/QR handover.',
              style: AppTypography.bodySecondary(
                color: Colors.white.withValues(alpha: 0.84),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildServiceShowcaseChip(
                  MashwarServicePillar.sharedTrips,
                  isAr ? 'رحلات ومقاعد' : 'Shared Trips',
                ),
                _buildServiceShowcaseChip(
                  MashwarServicePillar.routeParcels,
                  isAr ? 'طرود على الطريق' : 'Route Parcels',
                ),
                _buildServiceShowcaseChip(
                  MashwarServicePillar.smartSupply,
                  isAr ? 'توريد ومهام' : 'Smart Supply',
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space20),
            MashwarThreeStepsBanner(isAr: isAr, compact: true),
            const SizedBox(height: AppDimens.space16),
            Text(
              AppEnvironment.pilotScopeDisclaimer(isArabic: isAr),
              style: AppTypography.bodySmall(
                color: Colors.white.withValues(alpha: 0.74),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceShowcaseChip(MashwarServicePillar pillar, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: AppDimens.borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MashwarServicePillarIcon(pillar: pillar, size: 22),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTypography.label(color: Colors.white),
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
        horizontal: isCompact ? AppDimens.space16 : AppDimens.space24,
        vertical: isCompact ? 6 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Single ActionChip for language toggle (verified by dynamic_language_switcher_test)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _buildLanguageButton(settings, isAr),
          ),
          SizedBox(height: isCompact ? 4 : 8),

          if (!isWide)
            Container(
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                border: Border.all(
                  color: AppColors.slateBorder,
                  width: AppDimens.borderWidth,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: Opacity(
                      opacity: 0.22,
                      child: MashwarAssetArt(
                        assetPath: 'assets/images/service_ride.jpg',
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.route_rounded,
                        fallbackBg: AppColors.navy,
                        fallbackColor: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: isCompact ? 8 : 12,
                    ),
                    child: isCompact
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: BrandLogo(
                                  fontSize: 22,
                                  showEnglish: false,
                                  isLight: true,
                                ),
                              ),
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
                          )
                        : Column(
                            children: [
                              const BrandLogo(
                                fontSize: 30,
                                isLight: true,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildServiceShowcaseChip(
                                    MashwarServicePillar.sharedTrips,
                                    isAr ? 'رحلات تشاركية' : 'Shared Trips',
                                  ),
                                  _buildServiceShowcaseChip(
                                    MashwarServicePillar.routeParcels,
                                    isAr ? 'طرود بالطريق' : 'Route Parcels',
                                  ),
                                  _buildServiceShowcaseChip(
                                    MashwarServicePillar.smartSupply,
                                    isAr ? 'توريد ومهام' : 'Smart Supply',
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            )
          else
            const BrandLogo(fontSize: 34),
          SizedBox(height: isCompact ? 6 : 10),
          Text(
            isAr
                ? 'رحلات تشاركية · طرود على الطريق · توريد ومهام'
                : 'Shared Trips · Route Parcels · Smart Supply',
            textAlign: TextAlign.center,
            style: AppTypography.title(color: AppColors.navy).copyWith(
              fontSize: isCompact ? 14.5 : 17,
            ),
          ),
          SizedBox(height: isCompact ? 3 : 4),
          Text(
            isAr
                ? 'سجّل الدخول أو أنشئ حساباً لمشاركة المقاعد الشاغرة، إرسال الطرود مع المسافرين، أو طلب التوريد والمشتريات.'
                : 'Sign in or create an account to share trips, send parcels on active routes, and coordinate smart supply requests.',
            textAlign: TextAlign.center,
            maxLines: isCompact ? 2 : null,
            overflow: isCompact ? TextOverflow.ellipsis : null,
            style: AppTypography.bodySecondary().copyWith(
              fontSize: isCompact ? 12.5 : 13,
            ),
          ),
          SizedBox(height: isCompact ? 8 : 12),

          // Clean 3-Service Value Card
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: isCompact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              border: Border.all(
                color: AppColors.slateBorder,
                width: AppDimens.borderWidth,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureBullet(
                  Icons.directions_car_outlined,
                  isAr
                      ? 'سفر ومقاعد تشاركية: انشر رحلتك أو احجز مقعدك بمرونة'
                      : 'Shared Trips: Publish empty seats or find rides along your route',
                  compact: isCompact,
                ),
                SizedBox(height: isCompact ? 4 : 6),
                _buildFeatureBullet(
                  Icons.inventory_2_outlined,
                  isAr
                      ? 'طرود على الطريق: أرسل أو وصّل الأغراض مع مسافر بكود OTP و QR'
                      : 'Route Parcels: Send or carry items on the way with OTP & QR',
                  compact: isCompact,
                ),
                SizedBox(height: isCompact ? 4 : 6),
                _buildFeatureBullet(
                  Icons.verified_user_outlined,
                  isAr
                      ? 'توريد ومهام خاصة: فواتير شراء موثّقة ورمز تسليم من 6 خانات'
                      : 'Smart Supply: Verified store receipts & 6-char handover code',
                  compact: isCompact,
                  isSecurityHighlight: true,
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 8 : 14),

          // Primary CTA: Sign In with Email & Password
          MashwarButton(
            key: const ValueKey('welcome_email_login_btn'),
            height: isCompact ? 44 : AppDimens.minTouchTarget,
            text: isAr ? 'المتابعة بالبريد الإلكتروني' : 'Continue with Email',
            icon: const Icon(
              Icons.mail_outline_rounded,
              size: 19,
              color: Colors.white,
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
          ),
          SizedBox(height: isCompact ? 6 : 8),

          // Secondary CTA: Create New Account
          MashwarButton(
            key: const ValueKey('welcome_email_register_btn'),
            height: isCompact ? 44 : AppDimens.minTouchTarget,
            text: isAr ? 'إنشاء حساب جديد' : 'Create Account',
            variant: MashwarButtonVariant.secondary,
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 19,
              color: AppColors.navy,
            ),
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
          SizedBox(height: isCompact ? 8 : 12),

          // Phone OTP: enabled when Firebase Phone Auth or explicit dev-mock auth is available
          if (auth.isPhoneAuthAvailable) ...[
            MashwarButton(
              key: const ValueKey('welcome_phone_btn'),
              height: isCompact ? 42 : AppDimens.minTouchTarget,
              variant: MashwarButtonVariant.secondary,
              text: isAr ? 'المتابعة برقم الجوال' : 'Continue with Mobile Number',
              icon: const Icon(
                Icons.phone_iphone_rounded,
                size: 18,
                color: AppColors.navy,
              ),
              onPressed: () {
                auth.clearError();
                Navigator.of(context).push(
                  MashwarPageRoute(builder: (_) => const PhoneInputScreen()),
                );
              },
            ),
            if (!auth.isDevMockAuthEnabled) ...[
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'ملاحظة: رسائل التحقق عبر SMS تتطلب تفعيل فوترة الرسائل في Firebase Console، أو يمكنك الدخول فوراً بالبريد الإلكتروني وكلمة المرور أعلاه.'
                    : 'Note: SMS OTP requires SMS billing enabled in Firebase Console, or sign in anytime with Email & Password above.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(),
              ),
            ],
          ] else
            Container(
              key: const ValueKey('welcome_sms_unavailable_notice'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusAlert),
                border: Border.all(
                  color: AppColors.slateBorder,
                  width: AppDimens.borderWidth,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.sms_failed_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'الدخول عبر رسائل SMS يتطلب تفعيل Firebase Auth وفوترة الرسائل؛ يرجى استخدام البريد الإلكتروني وكلمة المرور.'
                              : 'Phone SMS OTP requires Firebase Auth & SMS billing enabled. Please sign in with Email & Password.',
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        auth.clearError();
                        Navigator.of(context).push(
                          MashwarPageRoute(
                            builder: (_) => const EmailInputScreen(
                              initialIsRegister: false,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.mail_outline_rounded,
                        size: 15,
                        color: AppColors.navy,
                      ),
                      label: Text(
                        isAr
                            ? 'الدخول بالبريد وكلمة المرور'
                            : 'Use Email & Password',
                        style: AppTypography.label(color: AppColors.navy),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Dev quick entry strictly gated by AppEnvironment.useDevMocks
          if (AppEnvironment.useDevMocks) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              key: const ValueKey('welcome_dev_demo_btn'),
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final ok = await auth.loginWithEmail(
                        'pilot.dev@mashwar.qa',
                        'devpass123',
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MainNavShell(),
                          ),
                          (_) => false,
                        );
                      } else {
                        final err = auth.localizedError(isArabic: isAr);
                        if (err != null && err.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        }
                      }
                    },
              icon: const Icon(
                Icons.developer_mode_rounded,
                size: 16,
                color: AppColors.navy,
              ),
              label: Text(
                isAr
                    ? 'دخول سريع لبيئة التطوير'
                    : 'Quick Development Sign-In',
                style: AppTypography.label(color: AppColors.navy),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Text(
            isAr
                ? 'بالمتابعة أنت توافق على شروط الاستخدام وسياسة الخصوصية'
                : 'By continuing, you agree to Terms of Service & Privacy Policy',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.textSecondary)
                .copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(
    IconData icon,
    String text, {
    bool compact = false,
    bool isSecurityHighlight = false,
  }) {
    final badgeBg =
        isSecurityHighlight ? AppColors.tealSurface : AppColors.slateBg;
    final badgeFg = isSecurityHighlight ? AppColors.teal : AppColors.navy;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 20 : 22,
          height: compact ? 20 : 22,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: compact ? 13 : 14, color: badgeFg),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(color: AppColors.navy).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11.5 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageButton(SettingsProvider settings, bool isAr) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: Colors.white,
      side: const BorderSide(
        color: AppColors.slateBorder,
        width: AppDimens.borderWidth,
      ),
      avatar: const Icon(
        Icons.language_rounded,
        size: 16,
        color: AppColors.navy,
      ),
      label: Text(
        isAr ? 'English' : 'العربية',
        style: AppTypography.label(color: AppColors.navy),
      ),
      onPressed: settings.toggleLanguage,
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
