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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Bell Icon Circle
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
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
              const Spacer(flex: 4),

              MashwarButton(
                text: isAr ? 'تفعيل التنبيهات' : 'Enable Notifications',
                onPressed: () => _finishOnboarding(context),
              ),
              const SizedBox(height: AppDimens.space12),
              TextButton(
                onPressed: () => _finishOnboarding(context),
                child: Text(
                  isAr ? 'مش دلوقتي' : 'Not now',
                  style: AppTypography.bodySecondary(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }
}
