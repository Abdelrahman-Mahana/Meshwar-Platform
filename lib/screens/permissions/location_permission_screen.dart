import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_onboarding_shell.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import 'notification_permission_screen.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  void _proceedNext(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MashwarPageRoute(builder: (_) => const NotificationPermissionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MashwarOnboardingShell(
          isAr: isAr,
          showcaseBadge: isAr ? 'التقاط وتوصيل دقيق' : 'Precision Matching',
          showcaseTitle: isAr
              ? 'نقاط التقاء ومواقع عمل دقيقة على مسارك'
              : 'Exact pickup spots & worksites along your route',
          showcaseSubtitle: isAr
              ? 'من لوسيل والخور والوكرة إلى المنطقة الصناعية — نصل طالب الخدمة بأقرب منفّذ أو مسافر بدقة.'
              : 'From Lusail, Al Khor & Al Wakrah to Industrial Area — accurate peer-to-peer matching.',
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space24,
                vertical: AppDimens.space16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - AppDimens.space32)
                      .clamp(0.0, double.infinity),
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
                          stepTitle:
                              isAr ? 'تحديد الموقع الذكي' : 'Smart Location',
                        ),
                        const SizedBox(height: AppDimens.space16),
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 280),
                          child: Column(
                            children: [
                              // Crisp Live Map Preview Card (1px slate border, zero heavy shadow)
                              Container(
                                height: 168,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.slateBorder,
                                    width: AppDimens.borderWidth,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    const Positioned.fill(
                                      child: QatarLiveMapCanvas(
                                        style: QatarMapStyle.light,
                                        activeFromCity: 'الدوحة',
                                        activeToCity: 'لوسيل',
                                        borderRadius: 17,
                                      ),
                                    ),
                                    PositionedDirectional(
                                      top: 10,
                                      start: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.96),
                                          borderRadius: BorderRadius.circular(
                                            AppDimens.radiusChip,
                                          ),
                                          border: Border.all(
                                            color: AppColors.slateBorder,
                                            width: AppDimens.borderWidth,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const MashwarLivePulseDot(
                                              color: AppColors.teal,
                                              size: 8,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isAr
                                                  ? 'معاينة توضيحية · نقطة الالتقاء المقترحة'
                                                  : 'Example Preview · Calibrated pickup spot',
                                              style: AppTypography.label(
                                                color: AppColors.navy,
                                              ).copyWith(fontSize: 11),
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
                                isAr
                                    ? 'اكتشف خدمات ومشاوير قريبة منك'
                                    : 'Find Nearby Services & Rides',
                                textAlign: TextAlign.center,
                                style: AppTypography.largeTitle().copyWith(
                                  fontSize: 23,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isAr
                                    ? 'لمطابقة الرحلات المشتركة والطرود وطلبات التوريد القريبة منك بدقة وسلاسة.'
                                    : 'To match nearby shared trips, route parcels & supply errands accurately.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySecondary(),
                              ),
                              const SizedBox(height: AppDimens.space16),
                              _buildBenefitCard(
                                icon: Icons.my_location_rounded,
                                title: isAr
                                    ? 'اقتراح أقرب نقطة التقاء أو بوابة موقع تلقائياً'
                                    : 'Auto-suggest nearest pickup gate or landmark',
                                subtitle: isAr
                                    ? 'يوفر وقت التنسيق الهاتفي مع المسافر أو المنفّذ'
                                    : 'Saves back-and-forth coordination calls',
                              ),
                              const SizedBox(height: 10),
                              _buildBenefitCard(
                                icon: Icons.verified_user_outlined,
                                isSecurity: true,
                                title: isAr
                                    ? 'مشاركة المسار المباشر لطمأنة العائلة وفريق العمل'
                                    : 'Share live trip & delivery link with family or team',
                                subtitle: isAr
                                    ? 'يُستخدم الموقع أثناء النشاط فقط ويمكن اختيار المدن يدوياً دائماً'
                                    : 'Used only while active — manual city selection is always available',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppDimens.space24),
                        MashwarButton(
                          key: const ValueKey('location_permission_enable_btn'),
                          text: isAr ? 'تفعيل الموقع' : 'Enable Location',
                          onPressed: () => _proceedNext(context),
                        ),
                        const SizedBox(height: 10),
                        MashwarButton(
                          key: const ValueKey('location_permission_skip_btn'),
                          variant: MashwarButtonVariant.secondary,
                          text: isAr ? 'تخطي الآن' : 'Not now',
                          onPressed: () => _proceedNext(context),
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

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isSecurity = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: AppColors.slateBorder,
          width: AppDimens.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSecurity ? AppColors.tealSurface : AppColors.slateBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isSecurity ? AppColors.teal : AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(color: AppColors.navy).copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
