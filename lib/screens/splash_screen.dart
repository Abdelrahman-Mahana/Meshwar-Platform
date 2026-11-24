import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../core/constants/app_typography.dart';
import '../core/localization/app_strings.dart';
import '../core/widgets/brand_logo.dart';
import '../core/widgets/mashwar_animations.dart';
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

  void _resolveAuthState() async {
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
          // Ambient animated Qatar map corridors in deep navy
          const Positioned.fill(
            child: Opacity(
              opacity: 0.34,
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
          // Radial vignette with Qatari Al-Adaam Maroon & Navy depth
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: [
                  AppColors.qatarMaroon.withValues(alpha: 0.24),
                  AppColors.navy.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppDimens.space24),
                  child: MashwarFadeSlideIn(
                    duration: const Duration(milliseconds: 420),
                    offsetY: 16,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // Concentric brand halo + Qatari heritage bar + Logo
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.42),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.qatarMaroon
                                    .withValues(alpha: 0.26),
                                blurRadius: 36,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QatarSaduAccentBar(height: 5, borderRadius: 0),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 20),
                                child: BrandLogo(fontSize: 44, isLight: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isAr
                              ? 'توريد مواقع العمل والخدمات في قطر'
                              : 'Worksite Supply & Services in Qatar',
                          textAlign: TextAlign.center,
                          style: AppTypography.title(color: Colors.white)
                              .copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                AppColors.qatarMaroon.withValues(alpha: 0.36),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MashwarLivePulseDot(
                                  color: AppColors.gold, size: 7),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isAr
                                      ? 'توريد مواقع · عروض مزودين معتمدين · توثيق تسليم'
                                      : 'Site Supply · Approved Providers · Verified Handover',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label(color: Colors.white)
                                      .copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: Color(0xFF1F3E5D),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.gold),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.space12),
                        Text(
                          isAr
                              ? 'جاري تجهيز شبكة الخدمات الحية في قطر...'
                              : 'Connecting live Qatar services...',
                          style: AppTypography.bodySmall(color: AppColors.gold)
                              .copyWith(
                            fontWeight: FontWeight.w700,
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
