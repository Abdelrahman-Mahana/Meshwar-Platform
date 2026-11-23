import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_onboarding_shell.dart';
import '../../core/localization/app_strings.dart';
import '../main_nav_shell.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  void _finishOnboarding(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MashwarPageRoute(builder: (_) => const MainNavShell()),
      (route) => false,
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
          showcaseBadge: isAr ? 'متابعة لحظية' : 'Real-Time Alerts',
          showcaseTitle: isAr
              ? 'ابقَ على اطلاع بكل لحظة في مشوارك'
              : 'Stay informed at every step of your trip',
          showcaseSubtitle: isAr
              ? 'إشعارات فورية لقبول الكابتن، وصوله لنقطة الالتقاء، وأكواد استلام الطرود الآمنة.'
              : 'Instant alerts when your captain accepts, arrives at pickup, or validates parcel OTP.',
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
                          currentStep: 4,
                          totalSteps: 4,
                          isAr: isAr,
                          stepTitle: isAr ? 'اللمسة الأخيرة · التنبيهات' : 'Final Step · Live Alerts',
                        ),
                        const SizedBox(height: 18),
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            children: [
                              // Sleek Stacked Live Notification Preview Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: AlignmentDirectional.topStart,
                                    end: AlignmentDirectional.bottomEnd,
                                    colors: [AppColors.navy, Color(0xFF173D61)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.navy.withValues(alpha: 0.14),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildPreviewNotificationTile(
                                      icon: Icons.directions_car_filled_rounded,
                                      iconBg: AppColors.gold,
                                      iconColor: AppColors.navy,
                                      title: isAr ? 'الكابتن جاسم الكواري في طريقه إليك' : 'Captain Jassim Al-Kuwari is arriving',
                                      subtitle: isAr ? 'يبعد 3 دقائق عن مترو مشيرب' : '3 mins away from Msheireb Metro',
                                      time: isAr ? 'الآن' : 'Now',
                                    ),
                                    const SizedBox(height: 10),
                                    _buildPreviewNotificationTile(
                                      icon: Icons.verified_user_rounded,
                                      iconBg: AppColors.teal,
                                      iconColor: Colors.white,
                                      title: isAr ? 'كود أمان تسليم الطرد جاهز' : 'Parcel OTP handover code ready',
                                      subtitle: isAr ? 'توثيق يد بيد في الوجهة بنجاح' : 'Verified hand-to-hand delivery',
                                      time: isAr ? 'منذ 2 د' : '2m ago',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimens.space20),
                              Text(
                                isAr ? 'لا تفوّت أي تحديث' : "Don't miss any update",
                                textAlign: TextAlign.center,
                                style: AppTypography.largeTitle().copyWith(fontSize: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isAr
                                    ? 'سنبلغك فوراً عند قبول الكابتن لطلبك أو وصوله إلى نقطة الالتقاء.'
                                    : 'We will notify you immediately when driver accepts booking or arrives at pickup.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySecondary(),
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
                          text: isAr ? 'تفعيل التنبيهات' : 'Enable Notifications',
                          onPressed: () => _finishOnboarding(context),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: AppDimens.minTouchTarget,
                          child: TextButton(
                            onPressed: () => _finishOnboarding(context),
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

  Widget _buildPreviewNotificationTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.teal,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
