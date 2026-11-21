import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import 'auth/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: MashwarFadeSlideIn(
            duration: const Duration(milliseconds: 420),
            offsetY: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const BrandLogo(fontSize: 42, isLight: true),
                const SizedBox(height: 10),
                Text(
                  isAr ? 'رحلتك وطردك في نفس الطريق' : 'Your ride & parcel along the same path',
                  style: AppTypography.bodySecondary(color: Colors.white.withValues(alpha: 0.78)),
                ),
                const Spacer(),
                Text(
                  isAr ? 'جاري التحميل...' : 'Loading...',
                  style: AppTypography.bodySecondary(color: AppColors.gold),
                ),
                const SizedBox(height: AppDimens.space12),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
                const SizedBox(height: AppDimens.space32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

