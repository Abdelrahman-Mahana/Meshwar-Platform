import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../localization/app_strings.dart';
import '../../state/settings_provider.dart';

enum AlertBannerType {
  success,
  warning,
  danger,
  info,
  offline,
}

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.message,
    this.type = AlertBannerType.info,
    this.onTap,
    this.showClose = false,
    this.onClose,
  });

  final String message;
  final AlertBannerType type;
  final VoidCallback? onTap;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? true;

    late final Color accentColor;
    late final Color bgColor;
    late final Color borderColor;
    late final IconData iconData;

    switch (type) {
      case AlertBannerType.success:
        accentColor = AppColors.teal;
        bgColor = AppColors.successBg;
        borderColor = AppColors.teal.withValues(alpha: 0.24);
        iconData = Icons.check_circle_outline_rounded;
        break;
      case AlertBannerType.warning:
        accentColor = AppColors.warning;
        bgColor = AppColors.warningBg;
        borderColor = AppColors.warning.withValues(alpha: 0.26);
        iconData = Icons.schedule_rounded;
        break;
      case AlertBannerType.danger:
        accentColor = AppColors.danger;
        bgColor = AppColors.dangerBg;
        borderColor = AppColors.danger.withValues(alpha: 0.26);
        iconData = Icons.error_outline_rounded;
        break;
      case AlertBannerType.offline:
        accentColor = AppColors.textSecondary;
        bgColor = AppColors.slateBg;
        borderColor = AppColors.slateBorder;
        iconData = Icons.wifi_off_rounded;
        break;
      case AlertBannerType.info:
        accentColor = AppColors.info;
        bgColor = AppColors.infoBg;
        borderColor = AppColors.info.withValues(alpha: 0.22);
        iconData = Icons.info_outline_rounded;
        break;
    }

    String displayMessage = message;
    if (displayMessage.contains('لقينا رحلة مطابقة لتنبيهك') ||
        displayMessage.contains('توفرت رحلة مطابقة لتنبيهك')) {
      displayMessage = isAr
          ? 'توفرت رحلة مطابقة لتنبيهك: الدوحة ← الخور\n7:30 ص'
          : 'Found a matching ride for your alert: Doha → Al Khor\n7:30 AM';
    } else if (displayMessage.contains('أنت في وضع غير متصل')) {
      displayMessage = isAr
          ? 'أنت في وضع غير متصل. النتائج المعروضة من آخر تحديث'
          : 'You are offline. Results shown are from last update';
    } else {
      displayMessage = AppStrings.translate(message, isArabic: isAr);
    }

    final borderRadius = BorderRadius.circular(AppDimens.radiusAlert);
    final bool interactive = onTap != null;

    return Material(
      color: bgColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: borderColor, width: AppDimens.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        mouseCursor:
            interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        hoverColor: accentColor.withValues(alpha: 0.04),
        splashColor: accentColor.withValues(alpha: 0.07),
        highlightColor: accentColor.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                ),
                alignment: Alignment.center,
                child: Icon(iconData, color: accentColor, size: 17),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  displayMessage,
                  style: AppTypography.bodySecondary(color: AppColors.navy)
                      .copyWith(
                    height: 1.42,
                  ),
                ),
              ),
              if (interactive) ...[
                const SizedBox(width: AppDimens.space8),
                Icon(
                  isAr
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ],
              if (showClose) ...[
                const SizedBox(width: AppDimens.space4),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, size: 17, color: accentColor),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
