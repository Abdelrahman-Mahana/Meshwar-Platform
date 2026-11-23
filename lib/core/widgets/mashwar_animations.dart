import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Returns `true` during live runtime (Web, Android, iOS, Desktop) and `false`
/// inside widget tests (`TestWidgetsFlutterBinding`) unless [forceAnimate] is `true`,
/// allowing smooth 60fps continuous map animations without stalling `pumpAndSettle()`.
bool mashwarShouldAnimateContinuous([bool forceAnimate = false]) {
  if (forceAnimate) return true;
  final bindingName = WidgetsBinding.instance.runtimeType.toString();
  return !bindingName.contains('Test');
}

/// Smooth Uber-grade page transition (subtle vertical slide + fade).
class MashwarPageRoute<T> extends PageRouteBuilder<T> {
  MashwarPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Live pulsing radar dot indicating active captains, rides, or courier status.
class MashwarLivePulseDot extends StatefulWidget {
  const MashwarLivePulseDot({
    super.key,
    this.color = AppColors.teal,
    this.size = 9.0,
    this.forceAnimate = false,
  });

  final Color color;
  final double size;
  final bool forceAnimate;

  @override
  State<MashwarLivePulseDot> createState() => _MashwarLivePulseDotState();
}

class _MashwarLivePulseDotState extends State<MashwarLivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (mashwarShouldAnimateContinuous(widget.forceAnimate)) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final halo = widget.size + (4.0 * _controller.value);
        return SizedBox(
          width: widget.size + 6,
          height: widget.size + 6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: halo,
                height: halo,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.25 - (_controller.value * 0.14)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Consistent segmented progress indicator across Auth & Permissions onboarding flow.
class MashwarOnboardingStepBar extends StatelessWidget {
  const MashwarOnboardingStepBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isAr,
    this.stepTitle,
  });

  final int currentStep;
  final int totalSteps;
  final bool isAr;
  final String? stepTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final stepNum = index + 1;
            final isDone = stepNum < currentStep;
            final isCurrent = stepNum == currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 4.5,
                margin: EdgeInsetsDirectional.only(end: index < totalSteps - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.teal
                      : (isCurrent ? AppColors.navy : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        if (stepTitle != null && stepTitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  stepTitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(color: AppColors.teal).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                isAr ? '$currentStep/$totalSteps' : '$currentStep/$totalSteps',
                style: AppTypography.label(color: AppColors.textSecondary).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

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

/// Elevated Super-App white section card with soft MASHWAR navy shadow and border.
class MashwarSectionCard extends StatelessWidget {
  const MashwarSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 18.0,
    this.borderColor,
    this.backgroundColor = Colors.white,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final card = Container(
      margin: onTap == null ? margin : null,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: borderColor ?? const Color(0xFFE5E7EB),
            width: 0.9,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: MashwarPressable(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Consistent Uber/Careem bottom-sheet header with drag handle and optional close button.
class MashwarSheetHeader extends StatelessWidget {
  const MashwarSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
    this.leadingIcon,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(leadingIcon, color: AppColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title().copyWith(fontSize: 17),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySecondary().copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (onClose != null)
              IconButton(
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, color: AppColors.navy, size: 20),
              ),
          ],
        ),
      ],
    );
  }
}

/// Tactile human-to-human communication action row (Chat / Call / Share).
class MashwarCommunicationBar extends StatelessWidget {
  const MashwarCommunicationBar({
    super.key,
    required this.onChat,
    required this.onCall,
    this.onShare,
    this.chatLabel = 'محادثة',
    this.callLabel = 'اتصال',
    this.shareLabel = 'مشاركة',
  });

  final VoidCallback onChat;
  final VoidCallback onCall;
  final VoidCallback? onShare;
  final String chatLabel;
  final String callLabel;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            icon: Icons.chat_bubble_outline_rounded,
            label: chatLabel,
            bgColor: AppColors.navy,
            fgColor: Colors.white,
            onTap: onChat,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionPill(
            icon: Icons.phone_in_talk_rounded,
            label: callLabel,
            bgColor: AppColors.tealSurface,
            fgColor: AppColors.teal,
            borderColor: AppColors.teal.withValues(alpha: 0.3),
            onTap: onCall,
          ),
        ),
        if (onShare != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ActionPill(
              icon: Icons.share_outlined,
              label: shareLabel,
              bgColor: AppColors.goldSurface,
              fgColor: AppColors.navy,
              borderColor: AppColors.gold.withValues(alpha: 0.45),
              onTap: onShare!,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MashwarPressable(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: fgColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
