import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_onboarding_shell.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import '../../core/localization/app_strings.dart';
import 'notification_permission_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isDenied = false;

  void _proceedNext() {
    Navigator.of(context).pushReplacement(
      MashwarPageRoute(builder: (_) => const NotificationPermissionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: MashwarOnboardingShell(
          isAr: isAr,
          showcaseBadge: isAr ? 'التقاط دقيق' : 'Precision Pickup',
          showcaseTitle: isAr
              ? 'نقاط التقاء ذكية في أنحاء الدوحة وقطر'
              : 'Smart pickup bays across Doha & Qatar',
          showcaseSubtitle: isAr
              ? 'من مشيرب ولوسيل إلى محطات وقود WOQOD — حدّد موقعك ليصلك الكابتن دون عناء.'
              : 'From Msheireb and Lusail to WOQOD stations — effortless pickup calibration.',
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space24,
                vertical: AppDimens.space16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - AppDimens.space32).clamp(0.0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MashwarOnboardingStepBar(
                          currentStep: 3,
                          totalSteps: 4,
                          isAr: isAr,
                          stepTitle: isAr ? 'تحديد الموقع الذكي' : 'Smart Location',
                        ),
                        const SizedBox(height: 16),
                        if (_isDenied) ...[
                          AlertBanner(
                            message: isAr
                                ? 'بدون تفعيل الموقع، ستحدد نقطة الالتقاء يدوياً'
                                : 'Without location, you will pick pickup spots manually',
                            type: AlertBannerType.warning,
                          ),
                          const SizedBox(height: 16),
                        ],
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            children: [
                              // Interactive Qatar Live Map Preview Card
                              Container(
                                height: 170,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.teal.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.navy.withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    const Positioned.fill(
                                      child: QatarLiveMapCanvas(
                                        style: QatarMapStyle.light,
                                        activeFromCity: 'الدوحة',
                                        activeToCity: 'لوسيل',
                                        borderRadius: 19,
                                      ),
                                    ),
                                    PositionedDirectional(
                                      top: 10,
                                      start: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.94),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const MashwarLivePulseDot(color: AppColors.teal, size: 8),
                                            const SizedBox(width: 6),
                                            Text(
                                              isAr ? 'نقطة الالتقاء المقترحة' : 'Calibrated pickup spot',
                                              style: AppTypography.label(color: AppColors.navy).copyWith(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimens.space20),
                              Text(
                                _isDenied
                                    ? (isAr ? 'إذن الموقع مغلق' : 'Location Permission Denied')
                                    : (isAr ? 'اكتشف رحلات قريبة منك' : 'Find Rides Near You'),
                                textAlign: TextAlign.center,
                                style: AppTypography.largeTitle().copyWith(fontSize: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isAr
                                    ? 'لاقتراح أقرب نقطة التقاء وحساب المسافة بدقة في قطر.'
                                    : 'To suggest convenient pickup spots and calculate distances accurately in Qatar.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySecondary(),
                              ),
                              const SizedBox(height: 16),
                              _buildBenefitTile(
                                icon: Icons.my_location_rounded,
                                title: isAr ? 'التقاط دقيق عند أقرب بوابة أو محطة WOQOD' : 'Exact pickup at metro gates or WOQOD',
                              ),
                              const SizedBox(height: 8),
                              _buildBenefitTile(
                                icon: Icons.shield_outlined,
                                title: isAr ? 'مشاركة خط السير المباشر مع العائلة لطمأنتهم' : 'Share live route safety link with family',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: AppDimens.space24),
                        MashwarButton(
                          text: _isDenied
                              ? (isAr ? 'المتابعة واختيار الموقع يدوياً' : 'Continue with Manual Location')
                              : (isAr ? 'تفعيل الموقع' : 'Enable Location'),
                          onPressed: _proceedNext,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: AppDimens.minTouchTarget,
                          child: TextButton(
                            onPressed: () {
                              if (!_isDenied) {
                                setState(() => _isDenied = true);
                              } else {
                                _proceedNext();
                              }
                            },
                            child: Text(
                              isAr ? 'تخطي الآن' : 'Not now',
                              style: AppTypography.bodySecondary(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitTile({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.tealSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.teal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySmall(color: AppColors.navy).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
