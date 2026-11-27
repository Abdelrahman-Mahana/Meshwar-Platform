import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../account/account_extra_screens.dart';
import '../auth/welcome_screen.dart';
import '../safety/safety_screens.dart';

Widget _buildSystemStateScaffold({
  required BuildContext context,
  required IconData icon,
  required Color accentColor,
  required Color accentSurface,
  required String badgeLabel,
  required String title,
  required String subtitle,
  required List<Widget> actions,
  Widget? topBanner,
}) {
  return Scaffold(
    backgroundColor: AppColors.slateBg,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0.0, 2000.0),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: MashwarFadeSlideIn(
                  duration: const Duration(milliseconds: 260),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (topBanner != null) ...[
                        topBanner,
                        const SizedBox(height: AppDimens.space20),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimens.space24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accentSurface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badgeLabel,
                                style: AppTypography.label(color: accentColor)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: AppDimens.space20),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: accentSurface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Icon(icon, size: 38, color: accentColor),
                            ),
                            const SizedBox(height: AppDimens.space20),
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
                            const SizedBox(height: AppDimens.space24),
                            ...actions,
                          ],
                        ),
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

// SYS-02: Force Update Screen
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, this.onUpdate});

  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    return _buildSystemStateScaffold(
      context: context,
      icon: Icons.system_update_alt_rounded,
      accentColor: AppColors.navy,
      accentSurface: AppColors.cobaltSurface,
      badgeLabel: isAr ? 'إصدار جديد متاح' : 'New Release',
      title: isAr ? 'تحديث التطبيق مطلوب' : 'App Update Required',
      subtitle: isAr
          ? 'تتوفر نسخة جديدة تحتوي على تحسينات مهمة للأمان والأداء.'
          : 'A new version is available with important security and performance improvements.',
      actions: [
        MashwarButton(
          key: const ValueKey('system_force_update_btn'),
          text: isAr ? 'تحديث الآن' : 'Update Now',
          onPressed: onUpdate ??
              () async {
                final messenger = ScaffoldMessenger.maybeOf(context);
                final uri = Uri.parse('https://mashwar.qa/update');
                final ok = await launchMashwarExternalUri(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!ok) {
                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'جاري فتح متجر التطبيقات لتحديث مشوار...'
                            : 'Opening app store to update MASHWAR...',
                      ),
                      backgroundColor: AppColors.navy,
                    ),
                  );
                }
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
      icon: Icons.build_circle_outlined,
      accentColor: AppColors.teal,
      accentSurface: AppColors.tealSurface,
      badgeLabel: isAr ? 'صيانة مجدولة' : 'Maintenance',
      title: isAr ? 'نُجري تحديثات لتحسين الخدمة' : 'Scheduled Maintenance',
      subtitle: isAr
          ? 'سنعود خلال وقت قصير. شكراً لتفهمك وصبرك.'
          : 'We will be back shortly. Thank you for your patience.',
      actions: [
        MashwarButton(
          key: const ValueKey('system_maintenance_retry_btn'),
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
      accentColor: AppColors.navy,
      accentSurface: AppColors.cobaltSurface,
      badgeLabel: isAr ? 'غير متصل بالشبكة' : 'Offline Mode',
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
          key: const ValueKey('system_offline_retry_btn'),
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
      icon: Icons.error_outline_rounded,
      accentColor: AppColors.danger,
      accentSurface: AppColors.dangerBg,
      badgeLabel: isAr ? 'تنبيه النظام' : 'System Notice',
      title: isAr ? 'حدث خطأ غير متوقع' : 'Something Went Wrong',
      subtitle: isAr
          ? 'لا تقلق، بياناتك في أمان. يرجى المحاولة مرة أخرى.'
          : 'Don\'t worry, your data is safe. Please try again.',
      actions: [
        MashwarButton(
          key: const ValueKey('system_error_retry_btn'),
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
          key: const ValueKey('system_error_support_btn'),
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
      icon: Icons.lock_clock_outlined,
      accentColor: AppColors.navy,
      accentSurface: AppColors.cobaltSurface,
      badgeLabel: isAr ? 'حماية الحساب' : 'Session Security',
      title: isAr ? 'انتهت جلستك' : 'Session Expired',
      subtitle: isAr
          ? 'يرجى تسجيل الدخول مرة أخرى للمتابعة بأمان.'
          : 'Please sign in again to continue securely.',
      actions: [
        MashwarButton(
          key: const ValueKey('system_session_login_btn'),
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
