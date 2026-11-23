import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import 'auth/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MashwarPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient animated Qatar map corridors in deep navy
          Positioned.fill(
            child: Opacity(
              opacity: 0.34,
              child: QatarLiveMapCanvas(
                style: QatarMapStyle.darkExecutive,
                activeFromCity: 'الدوحة',
                activeToCity: 'لوسيل',
                showHubLabels: false,
                showWaterLabels: false,
                borderRadius: 0,
              ),
            ),
          ),
          // Radial vignette so the centerpiece brand emblem pops crisply
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.92,
                colors: [
                  AppColors.navy.withValues(alpha: 0.55),
                  AppColors.navy.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
                  child: MashwarFadeSlideIn(
                    duration: const Duration(milliseconds: 420),
                    offsetY: 16,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // Concentric brand halo + Logo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.22),
                                blurRadius: 36,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const BrandLogo(fontSize: 44, isLight: true),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isAr ? 'رحلتك وطردك في نفس الطريق' : 'Your ride & parcel along the same path',
                          textAlign: TextAlign.center,
                          style: AppTypography.title(color: Colors.white).copyWith(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.teal.withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MashwarLivePulseDot(color: AppColors.gold, size: 7),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isAr ? 'دولة قطر · تنقل وتوصيل ذكي' : 'Qatar · Smart Mobility & Delivery',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label(color: Colors.white).copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: Color(0xFF1F3E5D),
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.space12),
                        Text(
                          isAr ? 'جاري تجهيز المسارات الحية...' : 'Connecting live Qatar routes...',
                          style: AppTypography.bodySmall(color: AppColors.gold).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimens.space32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
