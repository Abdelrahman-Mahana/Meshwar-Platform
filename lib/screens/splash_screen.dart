import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../core/constants/app_typography.dart';
import '../core/localization/app_strings.dart';
import '../core/widgets/brand_logo.dart';
import '../core/widgets/mashwar_animations.dart';
import '../core/widgets/mashwar_worksite_icons.dart';
import '../core/widgets/qatar_live_map_canvas.dart';
import '../state/auth_provider.dart';
import 'auth/welcome_screen.dart';
import 'main_nav_shell.dart';

class SplashScreen extends StatefulWidget {
  final Duration splashDuration;
  final bool restoreSession;

  const SplashScreen({
    super.key,
    this.splashDuration = const Duration(milliseconds: 1800),
    this.restoreSession = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;
  AuthProvider? _watchedAuth;
  bool _minSplashElapsed = false;
  bool _authCheckCompleted = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(widget.splashDuration, () {
      _minSplashElapsed = true;
      _tryNavigate();
    });

    Future.microtask(_resolveAuthState);
  }

  Future<void> _resolveAuthState() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    if (!widget.restoreSession || auth.status == AuthStatus.authenticated) {
      _authCheckCompleted = true;
      _tryNavigate();
      return;
    }

    if (auth.isLoading) {
      _watchedAuth = auth;
      auth.addListener(_onWatchedAuthChanged);
      return;
    }

    if (auth.status == AuthStatus.unauthenticated) {
      await auth.restoreSession();
    }

    if (mounted) {
      _authCheckCompleted = true;
      _tryNavigate();
    }
  }

  void _onWatchedAuthChanged() {
    final auth = _watchedAuth;
    if (auth == null) return;
    if (!auth.isLoading) {
      auth.removeListener(_onWatchedAuthChanged);
      _watchedAuth = null;
      _authCheckCompleted = true;
      _tryNavigate();
    }
  }

  void _tryNavigate() {
    if (!mounted ||
        _hasNavigated ||
        !_minSplashElapsed ||
        !_authCheckCompleted) {
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;

    _hasNavigated = true;
    final destination = auth.status == AuthStatus.authenticated
        ? const MainNavShell()
        : const WelcomeScreen();
    Navigator.of(context).pushReplacement(
      MashwarPageRoute(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _watchedAuth?.removeListener(_onWatchedAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: Opacity(
              opacity: 0.20,
              child: QatarLiveMapCanvas(
                style: QatarMapStyle.darkExecutive,
                activeFromCity: 'الدوحة',
                activeToCity: 'لوسيل',
                showHubLabels: false,
                showWaterLabels: false,
                borderRadius: 0,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.navy.withValues(alpha: 0.88),
                  AppColors.navy.withValues(alpha: 0.96),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space24,
                  ),
                  child: MashwarFadeSlideIn(
                    duration: const Duration(milliseconds: 380),
                    offsetY: 14,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 22,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                              width: AppDimens.borderWidth,
                            ),
                          ),
                          child: const BrandLogo(fontSize: 44, isLight: true),
                        ),
                        const SizedBox(height: AppDimens.space20),
                        Text(
                          isAr
                              ? 'رحلات تشاركية · طرود على الطريق · توريد ومهام'
                              : 'Shared Trips · Route Parcels · Smart Supply',
                          textAlign: TextAlign.center,
                          style: AppTypography.title(color: Colors.white)
                              .copyWith(fontSize: 16.5),
                        ),
                        const SizedBox(height: AppDimens.space14),
                        const Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            MashwarServicePillarIcon(
                              pillar: MashwarServicePillar.sharedTrips,
                              size: 36,
                            ),
                            MashwarServicePillarIcon(
                              pillar: MashwarServicePillar.routeParcels,
                              size: 36,
                            ),
                            MashwarServicePillarIcon(
                              pillar: MashwarServicePillar.smartSupply,
                              size: 36,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.space14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusChip),
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.45),
                              width: AppDimens.borderWidth,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: AppColors.teal,
                                size: 15,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isAr
                                      ? 'توصيل موثّق بكود الأمان OTP و QR · تواصل مباشر'
                                      : 'OTP & QR Verified Handover · Direct Connection',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label(
                                    color: Colors.white,
                                  ).copyWith(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 148,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.18, end: 1.0),
                              duration: widget.splashDuration,
                              curve: Curves.easeOutCubic,
                              builder: (context, progress, _) {
                                return LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 3.5,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.14),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.gold,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.space12),
                        Text(
                          isAr
                              ? 'جاري تجهيز تجربة مشوار...'
                              : 'Preparing your MASHWAR workspace...',
                          style: AppTypography.bodySmall(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: AppDimens.space32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
