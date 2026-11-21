import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Smooth finite fade-and-slide entrance wrapper.
///
/// Uses a single bounded [TweenAnimationBuilder] so widget tests using
/// `pumpAndSettle` settle predictably without infinite animation loops.
class MashwarFadeSlideIn extends StatelessWidget {
  const MashwarFadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 340),
    this.offsetY = 14.0,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final double offsetY;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * offsetY),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}

/// Tactile pressable wrapper inspired by Uber & Careem cards and bento tiles.
class MashwarPressable extends StatefulWidget {
  const MashwarPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final double pressedScale;

  @override
  State<MashwarPressable> createState() => _MashwarPressableState();
}

class _MashwarPressableState extends State<MashwarPressable> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed == pressed || !mounted) return;
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? widget.pressedScale : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onTapDown: widget.onTap != null ? (_) => _setPressed(true) : null,
          onTapUp: widget.onTap != null ? (_) => _setPressed(false) : null,
          onTapCancel: widget.onTap != null ? () => _setPressed(false) : null,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Uber/Careem route timeline showing pickup dot -> connecting hairline -> dropoff square.
class MashwarRouteTimeline extends StatelessWidget {
  const MashwarRouteTimeline({
    super.key,
    required this.from,
    required this.to,
    this.trailingTop,
    this.trailingBottom,
    this.compact = false,
  });

  final String from;
  final String to;
  final String? trailingTop;
  final Widget? trailingBottom;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTypography.body(color: AppColors.navy).copyWith(
      fontSize: compact ? 13 : 14.5,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Timeline rail: Teal origin dot + hairline + Navy destination square
        SizedBox(
          width: 18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.35), width: 1),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1.6,
                height: compact ? 14 : 18,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(2.5),
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      from,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                  if (trailingTop != null && trailingTop!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      trailingTop!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: AppColors.textSecondary).copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: compact ? 10 : 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      to,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                  if (trailingBottom != null) ...[
                    const SizedBox(width: 6),
                    trailingBottom!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Framed MASHWAR illustration renderer with graceful fallback for tests and error states.
class MashwarAssetArt extends StatelessWidget {
  const MashwarAssetArt({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.flipX = false,
    this.fallbackIcon = Icons.directions_car_filled_rounded,
    this.fallbackBg = AppColors.surfaceLight,
    this.fallbackColor = AppColors.navy,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool flipX;
  final IconData fallbackIcon;
  final Color fallbackBg;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) {
        return Container(
          width: width,
          height: height,
          color: fallbackBg,
          child: Center(
            child: Icon(
              fallbackIcon,
              color: fallbackColor,
              size: ((width ?? 48) * 0.48).clamp(18.0, 40.0),
            ),
          ),
        );
      },
    );

    if (flipX) {
      image = Transform.flip(flipX: true, child: image);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    return image;
  }
}
