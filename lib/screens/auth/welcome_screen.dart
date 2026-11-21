import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import 'email_input_screen.dart';
import 'phone_input_screen.dart';
import 'profile_setup_screen.dart';

/// Market-ready responsive Welcome & Entry screen (Uber / inDrive standard).
/// - Wide / Desktop (>= 840px): 2-column split canvas (Navy brand showcase + clean Auth panel)
/// - Mobile (< 840px): Full-height balanced vertical distribution across the entire viewport
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _showGoogleSignInSheet(BuildContext context, bool isAr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: AppDimens.space20),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.space16),
                      Row(
                        children: [
                          const GoogleLogo(size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'تسجيل الدخول باستخدام Google' : 'Sign in with Google',
                                  style: AppTypography.title(color: AppColors.navy).copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  isAr ? 'اختر حساباً للمتابعة إلى تطبيق مشوار' : 'Choose an account for MASHWAR',
                                  style: AppTypography.label(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.space16),
                      const Divider(height: 1, color: Color(0xFFE5E5EA)),
                      const SizedBox(height: AppDimens.space8),
                      _buildGoogleAccountTile(
                        sheetContext: sheetContext,
                        context: context,
                        displayName: isAr ? 'أحمد مصطفى' : 'Ahmed Mostafa',
                        email: 'ahmed.mostafa@gmail.com',
                        initial: isAr ? 'أ' : 'A',
                        color: const Color(0xFF4285F4),
                      ),
                      _buildGoogleAccountTile(
                        sheetContext: sheetContext,
                        context: context,
                        displayName: isAr ? 'عبدالرحمن أحمد' : 'Abdelrahman Ahmed',
                        email: 'abdelrahman@mashwar.eg',
                        initial: isAr ? 'ع' : 'A',
                        color: const Color(0xFF0F9D58),
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F4),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.navy, size: 20),
                        ),
                        title: Text(
                          isAr ? 'استخدام حساب آخر' : 'Use another account',
                          style: AppTypography.body(color: AppColors.navy).copyWith(fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EmailInputScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: AppDimens.space12),
                      Text(
                        isAr
                            ? 'بالمتابعة، ستشارك Google اسمك وعنوان بريدك الإلكتروني مع تطبيق مشوار.'
                            : 'By continuing, Google will share your name and email address with MASHWAR.',
                        style: AppTypography.label(color: const Color(0xFF94A3B8)).copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: AppDimens.space8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoogleAccountTile({
    required BuildContext sheetContext,
    required BuildContext context,
    required String displayName,
    required String email,
    required String initial,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      title: Text(
        displayName,
        style: AppTypography.body(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        email,
        style: AppTypography.label(color: AppColors.textSecondary),
      ),
      onTap: () async {
        final auth = context.read<AuthProvider>();
        await auth.signInWithGoogle(email: email, displayName: displayName);
        if (sheetContext.mounted) {
          Navigator.of(sheetContext).pop();
        }
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildSingleLayout(context, settings, isAr, constraints),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSingleLayout(
    BuildContext context,
    SettingsProvider settings,
    bool isAr,
    BoxConstraints constraints,
  ) {
    final isCompact = constraints.maxHeight <= 640;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space24,
        vertical: AppDimens.space12,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - (AppDimens.space12 * 2)).clamp(0.0, double.infinity),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Language Switch
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _buildLanguageButton(settings, isAr),
            ),

            // Center Hero Brand Identity + Framed 3D Illustration
            MashwarFadeSlideIn(
              duration: const Duration(milliseconds: 340),
              offsetY: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandLogo(fontSize: isCompact ? 34 : 44),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? 'رحلتك وطردك في نفس الطريق' : 'Your ride and parcel along the same path',
                    textAlign: TextAlign.center,
                    style: AppTypography.title(color: AppColors.navy).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: isCompact ? 15 : 17.5,
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 18),
                  Container(
                    height: isCompact ? 116 : 156,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.14),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MashwarAssetArt(
                            assetPath: 'assets/images/hero_banner.jpg',
                            fit: BoxFit.cover,
                            flipX: isAr,
                            fallbackIcon: Icons.directions_car_filled_rounded,
                            fallbackBg: AppColors.navy,
                            fallbackColor: AppColors.gold,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.navy.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Authentication Choices
            _buildAuthActions(context, isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(SettingsProvider settings, bool isAr) {
    return ActionChip(
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
      avatar: const Icon(Icons.language_rounded, size: 16, color: AppColors.navy),
      label: Text(
        isAr ? 'English' : 'العربية',
        style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.bold),
      ),
      onPressed: () => settings.toggleLanguage(),
    );
  }

  Widget _buildAuthActions(BuildContext context, bool isAr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Choice 1: Primary Mobile Number CTA
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.phone_iphone_rounded, size: 20, color: Colors.white),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isAr ? 'المتابعة برقم الموبايل' : 'Continue with Mobile Number',
                style: AppTypography.button(color: Colors.white).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
              );
            },
          ),
        ),

        const SizedBox(height: AppDimens.space16),

        // OR Divider
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE5E5EA), height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isAr ? 'أو' : 'OR',
                style: AppTypography.label(color: const Color(0xFF94A3B8)).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE5E5EA), height: 1)),
          ],
        ),

        const SizedBox(height: AppDimens.space16),

        // Choice 2: Continue with Google
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _showGoogleSignInSheet(context, isAr),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogo(size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isAr ? 'المتابعة باستخدام Google' : 'Continue with Google',
                      style: AppTypography.body(color: AppColors.navy).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDimens.space12),

        // Choice 3: Continue with Email
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF8F9FA),
              side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmailInputScreen()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.navy),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isAr ? 'المتابعة بالبريد الإلكتروني' : 'Continue with Email',
                      style: AppTypography.body(color: AppColors.navy).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDimens.space20),

        // Footnote Terms
        Text(
          isAr
              ? 'بالمتابعة أنت توافق على شروط الاستخدام وسياسة الخصوصية'
              : 'By continuing, you agree to Terms of Service & Privacy Policy',
          textAlign: TextAlign.center,
          style: AppTypography.label(color: const Color(0xFF94A3B8)).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

/// Official 4-color Google "G" emblem drawn vector-sharp via CustomPainter
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

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Blue arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.65, 1.4, false, paint);

    // Blue horizontal crossbar
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

    // Green arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.75, 1.5, false, paint);

    // Yellow arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.25, 1.45, false, paint);

    // Red arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.7, 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
