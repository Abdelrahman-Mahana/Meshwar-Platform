import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import 'brand_logo.dart';
import 'mashwar_animations.dart';
import 'qatar_live_map_canvas.dart';

/// Shared responsive split-canvas shell for MASHWAR's first-run onboarding & auth screens.
/// - Mobile / Tablet (< 840px): Focused single-column centered viewport (maxWidth 480-540)
/// - Desktop (>= 840px): Executive 2-column layout pairing a live animated Qatar map showcase
///   on the start side with an elevated form surface on the end side.
class MashwarOnboardingShell extends StatelessWidget {
  const MashwarOnboardingShell({
    super.key,
    required this.child,
    required this.isAr,
    this.showcaseTitle,
    this.showcaseSubtitle,
    this.showcaseBadge,
    this.activeFromCity = 'الدوحة',
    this.activeToCity = 'لوسيل',
    this.maxFormWidth = 480,
    this.scrollable = true,
  });

  final Widget child;
  final bool isAr;
  final String? showcaseTitle;
  final String? showcaseSubtitle;
  final String? showcaseBadge;
  final String? activeFromCity;
  final String? activeToCity;
  final double maxFormWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;

        if (!isWide) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxFormWidth),
              child: child,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    // Showcase Column: Live Qatar Animated Corridor Map
                    Expanded(
                      flex: 5,
                      child: Container(
                        color: AppColors.navy,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const BrandLogo(fontSize: 28, isLight: true),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const MashwarLivePulseDot(color: AppColors.gold, size: 7),
                                      const SizedBox(width: 6),
                                      Text(
                                        showcaseBadge ?? (isAr ? 'شبكة قطر الحية' : 'Qatar Live Network'),
                                        style: AppTypography.label(color: Colors.white).copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    width: 1,
                                  ),
                                ),
                                child: QatarLiveMapCanvas(
                                  style: QatarMapStyle.darkExecutive,
                                  activeFromCity: activeFromCity,
                                  activeToCity: activeToCity,
                                  borderRadius: 21,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              showcaseTitle ??
                                  (isAr
                                      ? 'تنقل تشاركي وشحن موثوق بين كل مناطق قطر'
                                      : 'Trusted shared rides & deliveries across Qatar'),
                              style: AppTypography.title(color: Colors.white).copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              showcaseSubtitle ??
                                  (isAr
                                      ? 'سائقون ومنفذو خدمات موثقون بالبطاقة الشخصية القطرية QID وكود تسليم رقمي آمن.'
                                      : 'QID-verified captains & couriers with 4-digit OTP handover protection.'),
                              style: AppTypography.bodySecondary(
                                color: Colors.white.withValues(alpha: 0.78),
                              ).copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Form Column
                    Expanded(
                      flex: 5,
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxFormWidth + 40),
                            child: scrollable
                                ? child
                                : Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: child,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
