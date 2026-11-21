import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../account/account_extra_screens.dart';
import '../auth/welcome_screen.dart';

Widget _buildSystemStateScaffold({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required List<Widget> actions,
  Widget? topBanner,
}) {
  return Scaffold(
    backgroundColor: const Color(0xFFFCFCFD),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.space24),
                  child: MashwarFadeSlideIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (topBanner != null) topBanner else const SizedBox(height: AppDimens.space24),
                        Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: AppColors.goldSurface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: 1.5),
                              ),
                              child: Icon(icon, size: 42, color: AppColors.navy),
                            ),
                            const SizedBox(height: AppDimens.space24),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTypography.largeTitle(),
                            ),
                            const SizedBox(height: AppDimens.space8),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySecondary(),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const SizedBox(height: AppDimens.space32),
                            ...actions,
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
    ),
  );
}

// SYS-02: Force Update Screen
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, this.onUpdate});

  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    return _buildSystemStateScaffold(
      context: context,
      icon: Icons.arrow_upward_rounded,
      title: isAr ? 'تحديث التطبيق مطلوب' : 'App Update Required',
      subtitle: isAr
          ? 'تتوفر نسخة جديدة تحتوي على تحسينات مهمة للأمان والأداء.'
          : 'A new version is available with important security and performance improvements.',
      actions: [
        MashwarButton(
          text: isAr ? 'تحديث الآن' : 'Update Now',
          onPressed: onUpdate ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr
                          ? 'جاري فتح متجر التطبيقات لتحديث مشوار...'
                          : 'Opening app store to update MASHWAR...',
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }
}

// SYS-03: Maintenance Screen
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    return _buildSystemStateScaffold(
      context: context,
      icon: Icons.settings_outlined,
      title: isAr ? 'نُجري تحديثات لتحسين الخدمة' : 'Scheduled Maintenance',
      subtitle: isAr
          ? 'سنعود خلال وقت قصير. شكراً لتفهمك وصبرك.'
          : 'We will be back shortly. Thank you for your patience.',
      actions: [
        MashwarButton(
          text: isAr ? 'إعادة المحاولة' : 'Try Again',
          variant: MashwarButtonVariant.secondary,
          onPressed: onRetry ??
              () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
        ),
      ],
    );
  }
}

// SYS-04: Offline Screen
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    return _buildSystemStateScaffold(
      context: context,
      icon: Icons.wifi_off_rounded,
      topBanner: AlertBanner(
        message: isAr ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection',
        type: AlertBannerType.offline,
      ),
      title: isAr ? 'لا يوجد اتصال بالإنترنت' : 'You\'re Offline',
      subtitle: isAr
          ? 'تأكد من اتصالك بالشبكة ثم أعد المحاولة.'
          : 'Check your internet connection and try again.',
      actions: [
        MashwarButton(
          text: isAr ? 'إعادة المحاولة' : 'Try Again',
          onPressed: onRetry ??
              () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
        ),
      ],
    );
  }
}

// SYS-04: General Error Screen
class GeneralErrorScreen extends StatelessWidget {
  const GeneralErrorScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    return _buildSystemStateScaffold(
      context: context,
      icon: Icons.priority_high_rounded,
      title: isAr ? 'حدث خطأ غير متوقع' : 'Something Went Wrong',
      subtitle: isAr
          ? 'لا تقلق، بياناتك في أمان. يرجى المحاولة مرة أخرى.'
          : 'Don\'t worry, your data is safe. Please try again.',
      actions: [
        MashwarButton(
          text: isAr ? 'إعادة المحاولة' : 'Try Again',
          onPressed: onRetry ??
              () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
        ),
        const SizedBox(height: AppDimens.space12),
        MashwarButton(
          text: isAr ? 'تواصل مع الدعم' : 'Contact Support',
          variant: MashwarButtonVariant.secondary,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            );
          },
        ),
      ],
    );
  }
}

// SYS-05: Session Expired Screen
class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key, this.onLogin});

  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    return _buildSystemStateScaffold(
      context: context,
      icon: Icons.schedule_rounded,
      title: isAr ? 'انتهت جلستك' : 'Session Expired',
      subtitle: isAr
          ? 'يرجى تسجيل الدخول مرة أخرى للمتابعة بأمان.'
          : 'Please sign in again to continue securely.',
      actions: [
        MashwarButton(
          text: isAr ? 'تسجيل الدخول' : 'Sign In',
          onPressed: onLogin ??
              () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
        ),
      ],
    );
  }
}
