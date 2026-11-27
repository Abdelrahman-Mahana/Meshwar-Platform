import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../localization/app_strings.dart';
import '../../state/settings_provider.dart';

enum BadgeType {
  verified,    // موثق
  underReview, // قيد المراجعة
  pending,     // قيد الانتظار / المراجعة
  rejected,    // مرفوض
  newBadge,    // جديد
  suspended,   // موقوف
  confirmed,   // مؤكد
  ladiesOnly,  // سيدات فقط
}

class MashwarBadge extends StatelessWidget {
  const MashwarBadge({
    super.key,
    required this.type,
    this.customLabel,
  });

  final BadgeType type;
  final String? customLabel;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? true;

    late final Color textColor;
    late final Color bgColor;
    late final Color borderColor;
    late final String defaultLabelAr;
    late final String defaultLabelEn;

    switch (type) {
      case BadgeType.verified:
        textColor = AppColors.teal;
        bgColor = AppColors.badgeVerifiedBg;
        borderColor = AppColors.teal.withValues(alpha: 0.20);
        defaultLabelAr = 'موثق';
        defaultLabelEn = 'Verified';
        break;
      case BadgeType.underReview:
      case BadgeType.pending:
        textColor = AppColors.warning;
        bgColor = AppColors.badgeReviewBg;
        borderColor = AppColors.warning.withValues(alpha: 0.22);
        defaultLabelAr = 'قيد المراجعة';
        defaultLabelEn = 'Under Review';
        break;
      case BadgeType.rejected:
        textColor = AppColors.danger;
        bgColor = AppColors.badgeRejectedBg;
        borderColor = AppColors.danger.withValues(alpha: 0.22);
        defaultLabelAr = 'مرفوض';
        defaultLabelEn = 'Rejected';
        break;
      case BadgeType.newBadge:
        textColor = AppColors.info;
        bgColor = AppColors.badgeNewBg;
        borderColor = AppColors.info.withValues(alpha: 0.20);
        defaultLabelAr = 'جديد';
        defaultLabelEn = 'New';
        break;
      case BadgeType.suspended:
        textColor = AppColors.textSecondary;
        bgColor = AppColors.slateBg;
        borderColor = AppColors.slateBorder;
        defaultLabelAr = 'موقوف';
        defaultLabelEn = 'Suspended';
        break;
      case BadgeType.confirmed:
        textColor = AppColors.teal;
        bgColor = AppColors.badgeVerifiedBg;
        borderColor = AppColors.teal.withValues(alpha: 0.20);
        defaultLabelAr = 'مؤكد';
        defaultLabelEn = 'Confirmed';
        break;
      case BadgeType.ladiesOnly:
        textColor = AppColors.ladiesPink;
        bgColor = AppColors.badgeLadiesBg;
        borderColor = AppColors.ladiesPink.withValues(alpha: 0.20);
        defaultLabelAr = 'سيدات فقط';
        defaultLabelEn = 'Ladies Only';
        break;
    }

    final rawLabel = customLabel ?? (isAr ? defaultLabelAr : defaultLabelEn);
    final displayLabel = AppStrings.translateStatus(rawLabel, isArabic: isAr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusBadge),
        border: Border.all(color: borderColor, width: AppDimens.borderWidth),
      ),
      child: Text(
        displayLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.label(color: textColor).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          height: 1.2,
        ),
      ),
    );
  }
}
