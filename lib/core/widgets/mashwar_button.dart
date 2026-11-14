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

    final bool isDisabled = onPressed == null || isLoading;

    Color bgColor;
    Color fgColor;
    BorderSide? borderSide;

    switch (variant) {
      case MashwarButtonVariant.primary:
        bgColor = isDisabled ? AppColors.borderDisabled : AppColors.navy;
        fgColor = Colors.white;
        break;
      case MashwarButtonVariant.secondary:
        bgColor = Colors.transparent;
        fgColor = isDisabled ? AppColors.borderDisabled : AppColors.navy;
        borderSide = BorderSide(
          color: isDisabled ? AppColors.borderDisabled : AppColors.navy,
          width: 1.5,
        );
        break;
      case MashwarButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = isDisabled ? AppColors.borderDisabled : AppColors.navy;
        break;
      case MashwarButtonVariant.danger:
        bgColor = isDisabled ? AppColors.borderDisabled : AppColors.danger;
        fgColor = Colors.white;
        break;
    }

    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else ...[
          if (icon != null) ...[
            icon!,
            const SizedBox(width: AppDimens.space8),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.button(color: fgColor),
              ),
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusButton),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusButton),
              border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
            ),
            alignment: Alignment.center,
            child: buttonChild,
          ),
        ),
      ),
    );
  }
}

