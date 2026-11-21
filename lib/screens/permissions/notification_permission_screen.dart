import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../main_nav_shell.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  void _finishOnboarding(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: AppDimens.space20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: AppDimens.space32),
                        Column(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: AppColors.goldSurface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                              ),
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                color: AppColors.navy,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: AppDimens.space24),
                            Text(
                              isAr ? 'ماتفوتش أي تحديث' : 'Don\'t miss any update',
                              textAlign: TextAlign.center,
                              style: AppTypography.largeTitle(),
                            ),
                            const SizedBox(height: AppDimens.space12),
                            Text(
                              isAr
                                  ? 'هنبلّغك فوراً لما السائق يوافق على حجزك أو يوصل نقطة الصعود.'
                                  : 'We will notify you immediately when driver accepts booking or arrives at pickup.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySecondary(),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const SizedBox(height: AppDimens.space32),
                            MashwarButton(
                              text: isAr ? 'تفعيل التنبيهات' : 'Enable Notifications',
                              onPressed: () => _finishOnboarding(context),
                            ),
                            const SizedBox(height: AppDimens.space12),
                            SizedBox(
                              width: double.infinity,
                              height: AppDimens.minTouchTarget,
                              child: TextButton(
                                onPressed: () => _finishOnboarding(context),
                                child: Text(
                                  isAr ? 'مش دلوقتي' : 'Not now',
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
        ),
      ),
    );
  }
}
