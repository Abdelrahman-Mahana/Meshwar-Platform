import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../localization/app_strings.dart';
import '../../state/settings_provider.dart';

enum MashwarButtonVariant {
  primary,
  secondary,
  text,
  danger,
  subtleDanger,
}

class MashwarButton extends StatelessWidget {
  const MashwarButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = MashwarButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimens.minTouchTarget,
  });

  final String text;
  final VoidCallback? onPressed;
  final MashwarButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? true;
    final displayLabel = AppStrings.translate(text, isArabic: isAr);

    final bool isDisabled = onPressed == null;
    final bool isNonInteractive = isDisabled || isLoading;

    late final Color bgColor;
    late final Color fgColor;
    BorderSide? borderSide;
    FontWeight labelWeight = FontWeight.w700;
    double labelSize = 15;

    switch (variant) {
      case MashwarButtonVariant.primary:
        bgColor = isLoading
            ? AppColors.navy.withValues(alpha: 0.88)
            : isDisabled
                ? AppColors.slateBorder
                : AppColors.navy;
        fgColor =
            isDisabled && !isLoading ? AppColors.textSecondary : Colors.white;
        break;

      case MashwarButtonVariant.secondary:
        bgColor = isDisabled && !isLoading ? AppColors.slateBg : Colors.white;
        fgColor = isDisabled && !isLoading
            ? AppColors.textSecondary.withValues(alpha: 0.65)
            : AppColors.navy;
        borderSide = BorderSide(
          color: isDisabled && !isLoading
              ? AppColors.slateBorder.withValues(alpha: 0.75)
              : AppColors.slateBorder,
          width: AppDimens.borderWidth,
        );
        labelWeight = FontWeight.w600;
        labelSize = 14.5;
        break;

      case MashwarButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = isDisabled && !isLoading
            ? AppColors.textSecondary.withValues(alpha: 0.65)
            : AppColors.navy;
        labelWeight = FontWeight.w600;
        labelSize = 14;
        break;

      case MashwarButtonVariant.danger:
        bgColor = isLoading
            ? AppColors.danger.withValues(alpha: 0.88)
            : isDisabled
                ? AppColors.slateBorder
                : AppColors.danger;
        fgColor =
            isDisabled && !isLoading ? AppColors.textSecondary : Colors.white;
        break;

      case MashwarButtonVariant.subtleDanger:
        bgColor = isDisabled && !isLoading
            ? AppColors.slateBg
            : AppColors.dangerBg;
        fgColor = isDisabled && !isLoading
            ? AppColors.textSecondary.withValues(alpha: 0.65)
            : AppColors.danger;
        borderSide = BorderSide(
          color: isDisabled && !isLoading
              ? AppColors.slateBorder.withValues(alpha: 0.75)
              : AppColors.danger.withValues(alpha: 0.28),
          width: AppDimens.borderWidth,
        );
        labelWeight = FontWeight.w600;
        labelSize = 14.5;
        break;
    }

    final borderRadius = BorderRadius.circular(AppDimens.radiusButton);
    final bool isLightSurface = variant == MashwarButtonVariant.secondary ||
        variant == MashwarButtonVariant.text ||
        variant == MashwarButtonVariant.subtleDanger;

    final Color overlayBase = variant == MashwarButtonVariant.subtleDanger
        ? AppColors.danger
        : (isLightSurface ? AppColors.navy : Colors.white);

    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else ...[
          if (icon != null) ...[
            IconTheme.merge(
              data: IconThemeData(size: 18, color: fgColor),
              child: icon!,
            ),
            const SizedBox(width: AppDimens.space8),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.button(color: fgColor).copyWith(
                  fontSize: labelSize,
                  fontWeight: labelWeight,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width ?? double.infinity,
        maxWidth: width ?? double.infinity,
        minHeight: height,
      ),
      child: Material(
        color: bgColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: borderSide ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isNonInteractive ? null : onPressed,
          borderRadius: borderRadius,
          mouseCursor: isNonInteractive
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          hoverColor: overlayBase.withValues(alpha: 0.05),
          splashColor: overlayBase.withValues(alpha: 0.08),
          highlightColor: overlayBase.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Center(
              heightFactor: 1.0,
              child: buttonChild,
            ),
          ),
        ),
      ),
    );
  }
}
