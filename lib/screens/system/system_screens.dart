import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_button.dart';

// SYS-02: Force Update Screen
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(Icons.arrow_upward_rounded, size: 54, color: AppColors.navy),
              const SizedBox(height: 24),
              Text('لازم تحدّث التطبيق', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                'فيه نسخة جديدة فيها تحسينات مهمة للأمان',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: 'تحديث الآن',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('جاري فتح متجر التطبيقات لتحديث مشوار...')),
                  );
                },
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }
}

// SYS-03: Maintenance Screen
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(Icons.settings_outlined, size: 54, color: AppColors.navy),
              const SizedBox(height: 24),
              Text('بنحسّن التطبيق', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                'هنرجع خلال وقت قصير. شكراً لصبرك',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: 'حاول تاني',
                variant: MashwarButtonVariant.secondary,
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }
}

// SYS-04: Offline Screen
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const AlertBanner(
                message: 'لا يوجد اتصال بالإنترنت',
                type: AlertBannerType.offline,
              ),
              const Spacer(flex: 3),
              const Icon(Icons.flash_off_rounded, size: 54, color: AppColors.navy),
              const SizedBox(height: 24),
              Text('مفيش إنترنت', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                'تأكد من الاتصال وحاول تاني',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: 'حاول تاني',
                onPressed: onRetry ?? () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }
}

// SYS-04: General Error Screen
class GeneralErrorScreen extends StatelessWidget {
  const GeneralErrorScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(Icons.priority_high_rounded, size: 54, color: AppColors.navy),
              const SizedBox(height: 24),
              Text('حصل خطأ غير متوقع', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                'ماتقلقش، بياناتك في أمان. جرّب تاني',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: 'حاول تاني',
                onPressed: onRetry ?? () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 12),
              MashwarButton(
                text: 'تواصل مع الدعم',
                variant: MashwarButtonVariant.secondary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('جاري فتح محادثة الدعم الفني المباشر...')),
                  );
                },
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }
}

// SYS-05: Session Expired Screen
class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key, this.onLogin});

  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(Icons.schedule_rounded, size: 54, color: AppColors.navy),
              const SizedBox(height: 24),
              Text('انتهت الجلسة', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                'سجّل دخولك تاني عشان تكمّل',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: 'تسجيل الدخول',
                onPressed: onLogin ?? () {},
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }
}
