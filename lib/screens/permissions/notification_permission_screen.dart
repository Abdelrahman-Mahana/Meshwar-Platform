import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_onboarding_shell.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MashwarOnboardingShell(
          isAr: isAr,
          showcaseBadge:
              isAr ? 'متابعة الضمان والخدمة' : 'Escrow & Live Alerts',
          showcaseTitle: isAr
              ? 'تابع قبول الحجوزات، الفواتير وأكواد التسليم لحظياً'
              : 'Track booking confirmations, receipts & OTP codes live',
          showcaseSubtitle: isAr
              ? 'إشعارات فورية لردود المسافرين، صور الفواتير الأصلية من المتجر، وأكواد OTP و QR لتأكيد التسليم.'
              : 'Instant alerts for driver replies, store receipts & OTP/QR handover codes.',
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
                          currentStep: 4,
                          totalSteps: 4,
                          isAr: isAr,
                          stepTitle: isAr
                              ? 'اللمسة الأخيرة · التنبيهات'
                              : 'Final Step · Live Alerts',
                        ),
                        const SizedBox(height: 18),
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 280),
                          child: Column(
                            children: [
                              // Executive Notification Preview Container (zero heavy shadow, zero maroon)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.slateBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.slateBorder,
                                    width: AppDimens.borderWidth,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildPreviewNotificationTile(
                                      icon: Icons.directions_car_outlined,
                                      iconBg: AppColors.cobaltSurface,
                                      iconColor: AppColors.navy,
                                      title: isAr
                                          ? 'تم تأكيد مقعدك على مسار الدوحة ← لوسيل'
                                          : 'Seat confirmed on Doha → Lusail trip',
                                      subtitle: isAr
                                          ? 'بطاقة الصعود ورمز QR جاهزان للعرض'
                                          : 'Boarding pass & QR code ready',
                                      time: isAr ? 'الآن' : 'Now',
                                    ),
                                    const SizedBox(height: 10),
                                    _buildPreviewNotificationTile(
                                      icon: Icons.receipt_long_rounded,
                                      iconBg: AppColors.slateBg,
                                      iconColor: AppColors.navy,
                                      title: isAr
                                          ? 'تم إرفاق فاتورة الشراء لموقع لوسيل'
                                          : 'Store purchase receipt attached',
                                      subtitle: isAr
                                          ? 'راجع الفاتورة قبل التحرك للتسليم'
                                          : 'Review receipt before dispatch',
                                      time: isAr ? 'منذ 1 د' : '1m ago',
                                    ),
                                    const SizedBox(height: 10),
                                    _buildPreviewNotificationTile(
                                      icon: Icons.verified_user_rounded,
                                      iconBg: AppColors.tealSurface,
                                      iconColor: AppColors.teal,
                                      title: isAr
                                          ? 'كود أمان التسليم OTP و QR جاهز'
                                          : 'Handover OTP & QR code ready',
                                      subtitle: isAr
                                          ? 'توثيق فوري عند الالتقاء والاستلام'
                                          : 'Instant verification upon meetup',
                                      time: isAr ? 'منذ 2 د' : '2m ago',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimens.space20),
                              Text(
                                isAr
                                    ? 'لا تفوّت أي تحديث'
                                    : "Don't miss any update",
                                textAlign: TextAlign.center,
                                style: AppTypography.largeTitle().copyWith(
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isAr
                                    ? 'سنبلغك فوراً بقبول حجوزاتك، عروض تنفيذ طلباتك، اعتماد الفواتير، وأكواد التسليم الآمنة بدون رسائل ترويجية مزعجة.'
                                    : 'Receive timely updates for booking confirmations, offers, receipts & secure handover codes — zero promotional spam.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySecondary(),
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
                          text: isAr
                              ? 'تفعيل التنبيهات'
                              : 'Enable Notifications',
                          onPressed: () => _finishOnboarding(context),
                        ),
                        const SizedBox(height: 10),
                        MashwarButton(
                          variant: MashwarButtonVariant.secondary,
                          text: isAr ? 'تخطي الآن' : 'Not now',
                          onPressed: () => _finishOnboarding(context),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: AppColors.slateBorder,
          width: AppDimens.borderWidth,
        ),
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
            child: Icon(icon, color: iconColor, size: 18),
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
                  style: AppTypography.body(color: AppColors.navy).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: AppTypography.label(color: AppColors.textSecondary)
                .copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
