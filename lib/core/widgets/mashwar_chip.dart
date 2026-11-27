import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../localization/app_strings.dart';
import '../../state/settings_provider.dart';

class MashwarChip extends StatefulWidget {
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
  State<MashwarChip> createState() => _MashwarChipState();
}

class _MashwarChipState extends State<MashwarChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? true;
    final displayLabel = AppStrings.translate(widget.label, isArabic: isAr);

    final bool selected = widget.isSelected;
    final bool interactive = widget.onTap != null;

    final Color bgColor = selected
        ? AppColors.navy
        : (_isHovered && interactive ? AppColors.slateBg : Colors.white);

    final Color borderColor = selected
        ? AppColors.navy
        : (_isHovered && interactive
            ? AppColors.navy.withValues(alpha: 0.28)
            : AppColors.slateBorder);

    final Color contentColor =
        selected ? Colors.white : AppColors.textPrimary;

    final borderRadius = BorderRadius.circular(AppDimens.radiusChip);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: interactive
            ? (hovered) {
                if (_isHovered != hovered) {
                  setState(() => _isHovered = hovered);
                }
              }
            : null,
        borderRadius: borderRadius,
        mouseCursor:
            interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        splashColor: AppColors.navy.withValues(alpha: 0.06),
        highlightColor: AppColors.navy.withValues(alpha: 0.03),
        hoverColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 38),
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor,
              width: AppDimens.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(
                    size: 16,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  child: widget.icon!,
                ),
                const SizedBox(width: AppDimens.space6),
              ],
              Flexible(
                child: Text(
                  displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary(color: contentColor)
                      .copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.25,
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
