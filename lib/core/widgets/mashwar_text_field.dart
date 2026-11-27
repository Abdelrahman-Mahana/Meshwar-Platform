import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';

/// Clean, state-aware input primitive engineered for calm hierarchy,
/// crisp 1px slate borders, subtle focus ring, and high-legibility Cairo copy.
class MashwarTextField extends StatefulWidget {
  const MashwarTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextAlign textAlign;

  @override
  State<MashwarTextField> createState() => _MashwarTextFieldState();
}

class _MashwarTextFieldState extends State<MashwarTextField> {
  late FocusNode _focusNode;
  bool _isInternalFocusNode = false;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }
    _isFocused = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant MashwarTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_isInternalFocusNode) {
        _focusNode.dispose();
      }
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
        _isInternalFocusNode = false;
      } else {
        _focusNode = FocusNode();
        _isInternalFocusNode = true;
      }
      _isFocused = _focusNode.hasFocus;
      _focusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;

    late final Color bgColor;
    late final Color borderColor;
    late final double borderWidth;

    if (!widget.enabled) {
      bgColor = AppColors.slateBg;
      borderColor = AppColors.slateBorder.withValues(alpha: 0.75);
      borderWidth = AppDimens.borderWidth;
    } else if (hasError) {
      bgColor = Colors.white;
      borderColor = AppColors.danger;
      borderWidth =
          _isFocused ? AppDimens.borderWidthFocused : AppDimens.borderWidthError;
    } else if (_isFocused) {
      bgColor = Colors.white;
      borderColor = AppColors.navy;
      borderWidth = AppDimens.borderWidthFocused;
    } else {
      bgColor = Colors.white;
      borderColor = _isHovered
          ? AppColors.navy.withValues(alpha: 0.32)
          : AppColors.slateBorder;
      borderWidth = AppDimens.borderWidth;
    }

    final Color iconColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.6)
        : (hasError
            ? AppColors.danger
            : (_isFocused ? AppColors.navy : AppColors.textSecondary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.label(
              color: widget.enabled ? AppColors.navy : AppColors.textSecondary,
            ).copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimens.space6),
        ],
        MouseRegion(
          onEnter: widget.enabled
              ? (_) {
                  if (!_isHovered) setState(() => _isHovered = true);
                }
              : null,
          onExit: widget.enabled
              ? (_) {
                  if (_isHovered) setState(() => _isHovered = false);
                }
              : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? widget.onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(
                minHeight: widget.maxLines > 1 ? 84 : AppDimens.minTouchTarget,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusField),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: _isFocused && widget.enabled
                    ? [
                        BoxShadow(
                          color: (hasError ? AppColors.danger : AppColors.navy)
                              .withValues(alpha: 0.07),
                          blurRadius: 0,
                          spreadRadius: 2.5,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: widget.maxLines > 1
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (widget.prefixIcon != null)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 12,
                        end: 8,
                        top: widget.maxLines > 1 ? 13 : 0,
                      ),
                      child: IconTheme.merge(
                        data: IconThemeData(size: 20, color: iconColor),
                        child: widget.prefixIcon!,
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      readOnly: widget.readOnly,
                      onTap: widget.enabled ? widget.onTap : null,
                      keyboardType: widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                      onChanged: widget.onChanged,
                      maxLines: widget.maxLines,
                      textAlign: widget.textAlign,
                      style: AppTypography.body(
                        color: widget.enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: AppTypography.bodySecondary(
                          color: AppColors.textSecondary.withValues(alpha: 0.72),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsetsDirectional.only(
                          start: widget.prefixIcon == null ? 14 : 2,
                          end: widget.suffixIcon == null ? 14 : 2,
                          top: 13,
                          bottom: 13,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (widget.suffixIcon != null)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 8,
                        end: 12,
                        top: widget.maxLines > 1 ? 13 : 0,
                      ),
                      child: IconTheme.merge(
                        data: IconThemeData(size: 20, color: iconColor),
                        child: widget.suffixIcon!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppDimens.space4),
          Text(
            widget.errorText!,
            style: AppTypography.label(color: AppColors.danger),
          ),
        ] else if (widget.helperText != null &&
            widget.helperText!.isNotEmpty) ...[
          const SizedBox(height: AppDimens.space4),
          Text(
            widget.helperText!,
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
