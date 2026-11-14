import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
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

    Color textColor;
    Color bgColor;
    String defaultLabelAr;
    String defaultLabelEn;

    switch (type) {
      case BadgeType.verified:
        textColor = AppColors.teal;
        bgColor = AppColors.badgeVerifiedBg;
        defaultLabelAr = 'موثق';
        defaultLabelEn = 'Verified';
        break;
      case BadgeType.underReview:
      case BadgeType.pending:
        textColor = AppColors.warning;
        bgColor = AppColors.badgeReviewBg;
        defaultLabelAr = 'قيد المراجعة';
        defaultLabelEn = 'Under Review';
        break;
      case BadgeType.rejected:
        textColor = AppColors.danger;
        bgColor = AppColors.badgeRejectedBg;
        defaultLabelAr = 'مرفوض';
        defaultLabelEn = 'Rejected';
        break;
      case BadgeType.newBadge:
        textColor = AppColors.info;
        bgColor = AppColors.badgeNewBg;
        defaultLabelAr = 'جديد';
        defaultLabelEn = 'New';
        break;
      case BadgeType.suspended:
        textColor = AppColors.textSecondary;
        bgColor = AppColors.badgeSuspendedBg;
        defaultLabelAr = 'موقوف';
        defaultLabelEn = 'Suspended';
        break;
      case BadgeType.confirmed:
        textColor = AppColors.teal;
        bgColor = AppColors.badgeVerifiedBg;
        defaultLabelAr = 'مؤكد';
        defaultLabelEn = 'Confirmed';
        break;
      case BadgeType.ladiesOnly:
        textColor = const Color(0xFFBE185D);
        bgColor = const Color(0xFFFCE7F3);
        defaultLabelAr = 'سيدات فقط';
        defaultLabelEn = 'Ladies Only';
        break;
    }

    final rawLabel = customLabel ?? (isAr ? defaultLabelAr : defaultLabelEn);
    final displayLabel = AppStrings.translateStatus(rawLabel, isArabic: isAr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        displayLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.label(color: textColor).copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

