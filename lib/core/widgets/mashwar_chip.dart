import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../localization/app_strings.dart';
import '../../state/settings_provider.dart';

class MashwarChip extends StatelessWidget {
  const MashwarChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.icon,
    this.padding,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? true;
    final displayLabel = AppStrings.translate(label, isArabic: isAr);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusChip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 40),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusChip),
            border: Border.all(
              color: isSelected ? AppColors.navy : AppColors.chipInactiveBorder,
              width: isSelected ? 1.0 : 0.9,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppDimens.space8),
              ],
              Flexible(
                child: Text(
                  displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
