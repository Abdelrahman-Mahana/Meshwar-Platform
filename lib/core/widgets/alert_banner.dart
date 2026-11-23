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

    Color borderColor;
    Color bgColor;
    IconData iconData;

    switch (type) {
      case AlertBannerType.success:
        borderColor = AppColors.teal;
        bgColor = AppColors.successBg;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case AlertBannerType.warning:
        borderColor = AppColors.warning;
        bgColor = AppColors.warningBg;
        iconData = Icons.schedule_rounded;
        break;
      case AlertBannerType.danger:
        borderColor = AppColors.danger;
        bgColor = AppColors.dangerBg;
        iconData = Icons.error_outline_rounded;
        break;
      case AlertBannerType.offline:
        borderColor = AppColors.textSecondary;
        bgColor = AppColors.offlineBg;
        iconData = Icons.wifi_off_rounded;
        break;
      case AlertBannerType.info:
        borderColor = AppColors.info;
        bgColor = AppColors.infoBg;
        iconData = Icons.info_outline_rounded;
        break;
    }

    String displayMessage = message;
    if (displayMessage.contains('لقينا رحلة مطابقة لتنبيهك') || displayMessage.contains('توفرت رحلة مطابقة لتنبيهك')) {
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Icon(iconData, color: borderColor, size: 22),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  displayMessage,
                  style: AppTypography.body(color: AppColors.navy).copyWith(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppDimens.space8),
                Icon(Icons.chevron_right_rounded, size: 20, color: borderColor),
              ],
              if (showClose) ...[
                const SizedBox(width: AppDimens.space4),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, size: 18, color: borderColor),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
