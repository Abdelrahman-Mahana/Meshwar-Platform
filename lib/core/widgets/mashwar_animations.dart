import 'package:flutter/material.dart';
import '../../data/models/worksite_models.dart';
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

/// Smooth MASHWAR page transition (subtle vertical slide + fade).
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

/// Tactile pressable wrapper for MASHWAR cards and bento tiles.
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

/// Clean MASHWAR route timeline showing pickup dot -> connecting hairline -> dropoff square.
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
                    Flexible(
                      child: Text(
                        trailingTop!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTypography.label(color: AppColors.textSecondary).copyWith(
                          fontSize: 11,
                        ),
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
                    Flexible(child: trailingBottom!),
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

/// Consistent MASHWAR bottom-sheet header with drag handle and optional close button.
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

/// Deprecated regional Sadu strip — returns [SizedBox.shrink] globally so
/// zero maroon/gold triangle bars ever render anywhere in the international UI.
class QatarSaduAccentBar extends StatelessWidget {
  const QatarSaduAccentBar({
    super.key,
    this.height = 5.0,
    this.borderRadius = 4.0,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Sleek international 3-step visual strip illustrating how MASHWAR connects
/// travelers, senders, and service providers effortlessly (`pumpAndSettle`-safe).
class MashwarThreeStepsBanner extends StatelessWidget {
  const MashwarThreeStepsBanner({
    super.key,
    required this.isAr,
    this.compact = false,
  });

  final bool isAr;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final steps = <({
      String numLabel,
      String title,
      IconData icon,
      Color accent,
      Color surface,
    })>[
      (
        numLabel: '1',
        title: isAr ? 'حدّد وجهتك أو طلبك' : 'Post Your Route or Request',
        icon: Icons.route_rounded,
        accent: AppColors.navy,
        surface: AppColors.sand,
      ),
      (
        numLabel: '2',
        title: isAr ? 'تواصل واختر الأنسب' : 'Match & Connect Directly',
        icon: Icons.handshake_outlined,
        accent: AppColors.goldDark,
        surface: AppColors.goldSurface,
      ),
      (
        numLabel: '3',
        title: isAr ? 'تابع وسلّم بكود الأمان' : 'Track & Confirm with OTP',
        icon: Icons.verified_user_outlined,
        accent: AppColors.teal,
        surface: AppColors.tealSurface,
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560 && !compact;

          if (isWide) {
            return Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: steps[i].accent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: steps[i].surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: steps[i].accent.withValues(alpha: 0.35),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              steps[i].numLabel,
                              style: AppTypography.label(
                                color: steps[i].accent,
                              ).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              steps[i].title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                color: AppColors.navy,
                              ).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        isAr
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textSecondary.withValues(alpha: 0.65),
                      ),
                    ),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: steps[i].surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: steps[i].accent.withValues(alpha: 0.35),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          steps[i].numLabel,
                          style: AppTypography.label(
                            color: steps[i].accent,
                          ).copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i].title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(
                          color: AppColors.navy,
                        ).copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
                    child: Container(
                      width: 12,
                      height: 1.5,
                      margin: const EdgeInsets.only(top: 6),
                      color: AppColors.slateBorder,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Clean international numbered step progress bar (`1 -> 2 -> 3`) with
/// [AnimatedContainer] pills for creation and booking wizards (`pumpAndSettle`-safe).
///
/// [currentStep] is 1-based (`1..stepTitles.length`; values `< 1` clamp to `1`).
class MashwarWizardStepHeader extends StatelessWidget {
  const MashwarWizardStepHeader({
    super.key,
    required this.currentStep,
    required this.stepTitles,
    required this.isAr,
    this.subtitle,
  });

  final int currentStep;
  final List<String> stepTitles;
  final bool isAr;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (stepTitles.isEmpty) return const SizedBox.shrink();
    final total = stepTitles.length;
    final activeStep = currentStep.clamp(1, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                Expanded(
                  child: _buildStepPill(
                    stepNumber: i + 1,
                    title: stepTitles[i],
                    isDone: (i + 1) < activeStep,
                    isActive: (i + 1) == activeStep,
                  ),
                ),
                if (i < total - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 10,
                      height: 2,
                      decoration: BoxDecoration(
                        color: (i + 1) < activeStep
                            ? AppColors.emerald
                            : AppColors.slateBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondary,
              ).copyWith(fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepPill({
    required int stepNumber,
    required String title,
    required bool isDone,
    required bool isActive,
  }) {
    final bgColor = isActive
        ? AppColors.cobaltSurface
        : (isDone ? AppColors.emeraldSurface : Colors.white);
    final borderColor = isActive
        ? AppColors.cobalt.withValues(alpha: 0.45)
        : (isDone
            ? AppColors.emerald.withValues(alpha: 0.35)
            : AppColors.slateBorder);
    final badgeBg = isActive
        ? AppColors.cobalt
        : (isDone ? AppColors.emerald : AppColors.slateBg);
    final badgeFg =
        (isActive || isDone) ? Colors.white : AppColors.textSecondary;
    final textColor = isActive
        ? AppColors.navy
        : (isDone ? AppColors.emerald : AppColors.textSecondary);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isActive ? 1.2 : 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: badgeFg,
                      fontFamily: 'Cairo',
                      height: 1.0,
                    ),
                  ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: textColor).copyWith(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact responsive badge signifying MASHWAR OTP Handover & Direct Settlement verification.
class MashwarEscrowBadge extends StatelessWidget {
  const MashwarEscrowBadge({
    super.key,
    required this.isAr,
    this.compact = false,
  });

  final bool isAr;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.escrowSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.escrowGreen.withValues(alpha: 0.35),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: compact ? 11.5 : 13,
            color: AppColors.escrowGreen,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isAr ? 'موثّق بـ OTP' : 'OTP Verified',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 9.5 : 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.escrowGreen,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom vector art tile for Qatar Family, School & Remote-Area Daily Commutes.
class MashwarFamilyCommuteArt extends StatelessWidget {
  const MashwarFamilyCommuteArt({
    super.key,
    this.size = 56.0,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: AppColors.sand,
        child: CustomPaint(
          painter: _FamilyCommutePainter(),
        ),
      ),
    );
  }
}

class _FamilyCommutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Warm desert sky dome
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFAF4E8), Color(0xFFF3E9D2)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Qatari compound arch silhouette in back
    final archPaint = Paint()..color = const Color(0xFFE7D8BC);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.10, h * 0.22, w * 0.42, h * 0.48),
        topLeft: Radius.circular(w * 0.14),
        topRight: Radius.circular(w * 0.14),
      ),
      archPaint,
    );

    // Subtle palm leaves
    final palmPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.72)
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.78, h * 0.64), Offset(w * 0.78, h * 0.34), palmPaint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.78, h * 0.34), width: w * 0.26, height: h * 0.14),
      3.14,
      3.14,
      false,
      palmPaint,
    );

    // Ground asphalt strip
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.68, w, h * 0.32),
      Paint()..color = const Color(0xFFDFD7C8),
    );

    // Family SUV body (Pearl white + Qatari Maroon accent strip + Navy windows)
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.47, w * 0.62, h * 0.25),
      Radius.circular(w * 0.07),
    );
    canvas.drawRRect(body, Paint()..color = Colors.white);
    canvas.drawRRect(
      body,
      Paint()
        ..color = AppColors.navy.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Maroon heritage trim band along SUV
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.59, w * 0.58, h * 0.06),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = AppColors.qatarMaroon,
    );

    // SUV Cabin Roof & Windows
    final cabin = Path()
      ..moveTo(w * 0.27, h * 0.47)
      ..lineTo(w * 0.34, h * 0.34)
      ..lineTo(w * 0.64, h * 0.34)
      ..lineTo(w * 0.70, h * 0.47)
      ..close();
    canvas.drawPath(cabin, Paint()..color = AppColors.navy);

    // Wheels
    final wheelPaint = Paint()..color = AppColors.navy;
    final hubPaint = Paint()..color = AppColors.gold;
    canvas.drawCircle(Offset(w * 0.30, h * 0.72), w * 0.08, wheelPaint);
    canvas.drawCircle(Offset(w * 0.30, h * 0.72), w * 0.035, hubPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.72), w * 0.08, wheelPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.72), w * 0.035, hubPaint);

    // Top-start Gold-and-Teal verified shield crest
    final shieldCenter = Offset(w * 0.22, h * 0.22);
    canvas.drawCircle(shieldCenter, w * 0.14, Paint()..color = AppColors.teal);
    canvas.drawCircle(
      shieldCenter,
      w * 0.14,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final check = Path()
      ..moveTo(w * 0.16, h * 0.22)
      ..lineTo(w * 0.205, h * 0.265)
      ..lineTo(w * 0.28, h * 0.18);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _FamilyCommutePainter oldDelegate) => false;
}

/// Deterministic test-safe shimmer skeleton placeholder.
///
/// Sweeps a smooth highlight gradient during live runtime and renders a static
/// container during widget tests (`mashwarShouldAnimateContinuous() == false`)
/// or when platform reduced-motion is active so `pumpAndSettle()` never hangs.
class MashwarShimmerBox extends StatefulWidget {
  const MashwarShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 10,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<MashwarShimmerBox> createState() => _MashwarShimmerBoxState();
}

class _MashwarShimmerBoxState extends State<MashwarShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shouldRun = mashwarShouldAnimateContinuous() && !disableAnimations;
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? const Color(0xFFECEFF4);
    final highlight = widget.highlightColor ?? const Color(0xFFF8FAFC);
    final radius = BorderRadius.circular(widget.borderRadius);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (!mashwarShouldAnimateContinuous() || disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: radius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final slide = (_controller.value * 3.0) - 1.0;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(slide - 1.0, -0.2),
              end: Alignment(slide + 1.0, 0.2),
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// Interactive hover + pressable card with zero layout shift across mouse/touch.
class MashwarHoverCard extends StatefulWidget {
  const MashwarHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.backgroundColor = Colors.white,
    this.borderColor = AppColors.borderDisabled,
    this.hoverBorderColor = AppColors.navy,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final Color hoverBorderColor;
  final EdgeInsetsGeometry padding;

  @override
  State<MashwarHoverCard> createState() => _MashwarHoverCardState();
}

class _MashwarHoverCardState extends State<MashwarHoverCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _setHovered(bool hovered) {
    if (_isHovered == hovered || !mounted) return;
    setState(() => _isHovered = hovered);
  }

  void _setPressed(bool pressed) {
    if (_isPressed == pressed || !mounted) return;
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final activeHover = _isHovered && widget.onTap != null;
    final resolvedBorder = activeHover
        ? widget.hoverBorderColor.withValues(alpha: 0.65)
        : widget.borderColor;

    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            border: Border.all(color: resolvedBorder, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(
                  alpha: activeHover ? 0.08 : 0.035,
                ),
                blurRadius: activeHover ? 18 : 10,
                offset: Offset(0, activeHover ? 6 : 3),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: widget.borderRadius,
            clipBehavior: Clip.antiAlias,
            child: widget.onTap == null
                ? Padding(padding: widget.padding, child: widget.child)
                : InkWell(
                    borderRadius: widget.borderRadius,
                    onTap: widget.onTap,
                    onTapDown: (_) => _setPressed(true),
                    onTapUp: (_) => _setPressed(false),
                    onTapCancel: () => _setPressed(false),
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// 6-stage worksite supply progress stepper with distinct banners for
/// `cancelled` and `disputed` states.
class MashwarWorksiteStatusStepper extends StatelessWidget {
  const MashwarWorksiteStatusStepper({
    super.key,
    required this.status,
    required this.isAr,
    this.compact = false,
  });

  final WorkRequestStatus status;
  final bool isAr;
  final bool compact;

  int _stageIndex(WorkRequestStatus value) {
    switch (value) {
      case WorkRequestStatus.open:
        return 0;
      case WorkRequestStatus.offerReceived:
      case WorkRequestStatus.offerSelected:
        return 1;
      case WorkRequestStatus.accepted:
      case WorkRequestStatus.inProgress:
        return 2;
      case WorkRequestStatus.pickedUp:
        return 3;
      case WorkRequestStatus.inTransit:
        return 4;
      case WorkRequestStatus.deliveredPendingConfirmation:
      case WorkRequestStatus.completed:
        return 5;
      case WorkRequestStatus.cancelled:
      case WorkRequestStatus.disputed:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == WorkRequestStatus.cancelled ||
        status == WorkRequestStatus.disputed) {
      final isCancelled = status == WorkRequestStatus.cancelled;
      final accent = isCancelled ? AppColors.danger : AppColors.warning;
      final bg = isCancelled ? AppColors.dangerBg : AppColors.warningBg;
      final icon = isCancelled
          ? Icons.cancel_outlined
          : Icons.report_problem_outlined;
      final title = isCancelled
          ? (isAr ? 'تم إلغاء الطلب' : 'Request Cancelled')
          : (isAr ? 'الطلب قيد مراجعة النزاع' : 'Request Under Dispute');
      final subtitle = isCancelled
          ? (isAr
              ? 'أُغلق الطلب قبل بدء التوصيل.'
              : 'Supply order stopped before store pickup.')
          : (isAr
              ? 'تم تجميد التسليم لحين مراجعة فريق الدعم.'
              : 'Completion paused pending support arbitration.');

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: compact ? 17 : 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.navy).copyWith(
                      fontSize: compact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ).copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final stages = <(String ar, String en)>[
      ('مفتوح', 'Open'),
      (
        status == WorkRequestStatus.offerSelected ? 'ترسية' : 'عروض',
        status == WorkRequestStatus.offerSelected ? 'Selected' : 'Offers',
      ),
      (
        status == WorkRequestStatus.inProgress ? 'تجهيز' : 'مقبول',
        status == WorkRequestStatus.inProgress ? 'Preparing' : 'Accepted',
      ),
      ('استلام', 'Picked Up'),
      ('بالطريق', 'In Transit'),
      (
        status == WorkRequestStatus.completed ? 'مكتمل' : 'بالموقع',
        status == WorkRequestStatus.completed ? 'Done' : 'At Site',
      ),
    ];

    final activeIdx = _stageIndex(status);
    final isAllDone = status == WorkRequestStatus.completed;
    final targetProgress = (activeIdx / (stages.length - 1)).clamp(0.0, 1.0);
    final dotSize = compact ? 16.0 : 20.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 8 : 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: dotSize + 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      height: 3.5,
                      margin: EdgeInsets.symmetric(horizontal: dotSize * 0.5),
                      decoration: BoxDecoration(
                        color: AppColors.borderDisabled,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0.0,
                              end: targetProgress,
                            ),
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Container(
                                  width: constraints.maxWidth * value,
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: AppColors.teal,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(stages.length, (i) {
                    final done = isAllDone ? true : i < activeIdx;
                    final current = !isAllDone && i == activeIdx;

                    if (current) {
                      return Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.teal, width: 1.5),
                        ),
                        child: Center(
                          child: MashwarLivePulseDot(
                            color: AppColors.teal,
                            size: compact ? 6.5 : 8.0,
                          ),
                        ),
                      );
                    }

                    return Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: done ? AppColors.teal : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done ? AppColors.teal : AppColors.slateBorder,
                          width: 1.5,
                        ),
                      ),
                      child: done
                          ? Icon(
                              Icons.check_rounded,
                              size: compact ? 10 : 12,
                              color: Colors.white,
                            )
                          : null,
                    );
                  }),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Row(
            children: List.generate(stages.length, (i) {
              final isCurrent = !isAllDone && i == activeIdx;
              final isReached = isAllDone || i <= activeIdx;
              return Expanded(
                child: Text(
                  isAr ? stages[i].$1 : stages[i].$2,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    color: isCurrent
                        ? AppColors.navy
                        : (isReached
                            ? AppColors.teal
                            : AppColors.textSecondary),
                  ).copyWith(
                    fontSize: compact ? 9.0 : 10.0,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Thumbnail card for store invoices, transfer proofs, and site reference photos
/// with graceful vector fallback and tap-to-zoom preview.
class MashwarAttachmentThumbnail extends StatelessWidget {
  const MashwarAttachmentThumbnail({
    super.key,
    required this.url,
    required this.label,
    this.isInvoice = false,
    this.onTap,
  });

  final String url;
  final String label;
  final bool isInvoice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url.trim();
    final accent = isInvoice ? AppColors.escrowGreen : AppColors.navy;
    final surface = isInvoice ? AppColors.escrowSurface : AppColors.slateBg;

    void handleTap() {
      if (onTap != null) {
        onTap!();
      } else {
        MashwarImagePreviewDialog.show(
          context,
          url: cleanUrl,
          title: label,
        );
      }
    }

    return MashwarPressable(
      borderRadius: BorderRadius.circular(14),
      onTap: handleTap,
      child: Container(
        width: 124,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 76,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _MashwarResolvedAttachmentImage(
                    url: cleanUrl,
                    fit: BoxFit.cover,
                    fallbackBg: surface,
                    fallbackAccent: accent,
                    isInvoice: isInvoice,
                  ),
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.zoom_out_map_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    isInvoice
                        ? Icons.receipt_long_rounded
                        : Icons.photo_library_outlined,
                    size: 13,
                    color: accent,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: AppColors.navy).copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen modal image preview with pinch-to-zoom and graceful fallback.
class MashwarImagePreviewDialog extends StatelessWidget {
  const MashwarImagePreviewDialog({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required String url,
    required String title,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => MashwarImagePreviewDialog(url: url, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url.trim();
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.image_outlined,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title(color: Colors.white)
                          .copyWith(fontSize: 15.5),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF1F3E5E)),
            Flexible(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Container(
                  color: const Color(0xFF0A1B2C),
                  constraints: const BoxConstraints(minHeight: 240),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: _MashwarResolvedAttachmentImage(
                        url: cleanUrl,
                        fit: BoxFit.contain,
                        fallbackBg: const Color(0xFF102A43),
                        fallbackAccent: AppColors.gold,
                        isInvoice: false,
                        largeFallback: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MashwarResolvedAttachmentImage extends StatelessWidget {
  const _MashwarResolvedAttachmentImage({
    required this.url,
    required this.fit,
    required this.fallbackBg,
    required this.fallbackAccent,
    required this.isInvoice,
    this.largeFallback = false,
  });

  final String url;
  final BoxFit fit;
  final Color fallbackBg;
  final Color fallbackAccent;
  final bool isInvoice;
  final bool largeFallback;

  @override
  Widget build(BuildContext context) {
    Widget buildFallback() {
      return Container(
        color: fallbackBg,
        padding: EdgeInsets.all(largeFallback ? 24 : 8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isInvoice
                    ? Icons.receipt_long_rounded
                    : Icons.image_search_rounded,
                size: largeFallback ? 52 : 28,
                color: fallbackAccent,
              ),
              if (largeFallback && url.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  url,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (url.isEmpty) return buildFallback();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (_, __, ___) => buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: fallbackBg,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: (_, __, ___) => buildFallback(),
      );
    }

    return buildFallback();
  }
}
