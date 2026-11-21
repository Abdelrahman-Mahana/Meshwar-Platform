import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';

/// Clean, state-aware input field following Uber/inDrive minimal standard.
/// Features dynamic focus borders, subtle neutral fill, zero inner outline artifacts,
/// and high-contrast Cairo typography.
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

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }
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
    final bool hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    Color bgColor;
    Color borderColor;
    double borderWidth;

    if (hasError) {
      bgColor = AppColors.dangerBg;
      borderColor = AppColors.danger;
      borderWidth = 1.4;
    } else if (_isFocused && widget.enabled) {
      bgColor = Colors.white;
      borderColor = AppColors.navy;
      borderWidth = 1.8;
    } else if (widget.enabled) {
      bgColor = AppColors.surfaceLight;
      borderColor = AppColors.borderDisabled;
      borderWidth = 1.0;
    } else {
      bgColor = AppColors.chipInactiveBg;
      borderColor = AppColors.borderDisabled.withValues(alpha: 0.6);
      borderWidth = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.label(
              color: widget.enabled ? AppColors.navy : AppColors.textSecondary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppDimens.radiusField),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: _isFocused && widget.enabled && !hasError
                  ? [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: widget.prefixIcon,
                  ),
                ],
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
                      color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
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
                        start: widget.prefixIcon == null ? 14 : 0,
                        end: widget.suffixIcon == null ? 14 : 0,
                        top: 14,
                        bottom: 14,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.suffixIcon != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: widget.suffixIcon,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppDimens.space4),
          Text(
            widget.errorText!,
            style: AppTypography.label(color: AppColors.danger),
          ),
        ] else if (widget.helperText != null && widget.helperText!.isNotEmpty) ...[
          const SizedBox(height: AppDimens.space4),
          Text(
            widget.helperText!,
            style: AppTypography.label(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
