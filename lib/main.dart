import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/app_environment.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_dimens.dart';
import 'core/constants/app_typography.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/brand_logo.dart';
import 'data/repositories/app_repositories.dart';
import 'firebase_options.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/splash_screen.dart';
import 'state/admin_provider.dart';
import 'state/alerts_provider.dart';
import 'state/auth_provider.dart';
import 'state/board_provider.dart';
import 'state/parcels_provider.dart';
import 'state/rides_provider.dart';
import 'state/settings_provider.dart';
import 'state/worksite_provider.dart';

/// Initializes backend wiring for MASHWAR according to [AppEnvironment].
///
/// Returns `null` when startup succeeds, or an explicit diagnostic message when
/// Firebase/configuration fails in `staging`/`production` or when `USE_FIREBASE=true`.
/// Never silently falls back to local dev mocks when `useDevMocks == false`.
@visibleForTesting
Future<String?> initializeMashwarStartup({
  AppEnvironmentConfig? config,
  Future<void> Function()? firebaseInitializer,
}) async {
  final env = config ?? AppEnvironment.current;
  final bool shouldUseFirebase = config != null
      ? config.useFirebase
      : (!env.useDevMocks &&
          (!AppEnvironment.hasExplicitUseFirebase || env.useFirebase));

  if (shouldUseFirebase) {
    try {
      if (firebaseInitializer != null) {
        await firebaseInitializer();
      } else if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      AppEnvironment.setFirebaseRuntimeActive(true);
      AppRepositories.instance.useFirebase();
      return null;
    } catch (e) {
      AppEnvironment.setFirebaseRuntimeActive(false);
      debugPrint('Firebase initialization error (${env.flavor.name}): $e');
      return 'Firebase initialization failed in ${env.flavor.name} mode: $e';
    }
  }

  AppEnvironment.setFirebaseRuntimeActive(false);
  if (env.flavor != AppFlavor.development) {
    return 'Configuration error: ${env.flavor.name} builds require USE_FIREBASE=true.';
  }

  if (env.useDevMocks) {
    AppRepositories.instance.useLocalMocks(allowDevMocks: true);
    return null;
  }

  return 'Configuration error: USE_FIREBASE=false requires USE_DEV_MOCKS=true in development mode, or omit USE_FIREBASE to connect to Firebase.';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final startupError = await initializeMashwarStartup();
  final authProvider = AuthProvider();
  if (startupError == null) {
    await authProvider.restoreSession();
  }

  runApp(
    MashwarApp(
      initialStartupError: startupError,
      authProvider: authProvider,
      onRetryStartup: initializeMashwarStartup,
    ),
  );
}

class MashwarApp extends StatefulWidget {
  final String? initialStartupError;
  final Future<String?> Function()? onRetryStartup;
  final AuthProvider? authProvider;
  final WorksiteProvider? worksiteProvider;
  final RidesProvider? ridesProvider;
  final ParcelsProvider? parcelsProvider;
  final BoardProvider? boardProvider;
  final AlertsProvider? alertsProvider;

  const MashwarApp({
    super.key,
    this.initialStartupError,
    this.onRetryStartup,
    this.authProvider,
    this.worksiteProvider,
    this.ridesProvider,
    this.parcelsProvider,
    this.boardProvider,
    this.alertsProvider,
  });

  @override
  State<MashwarApp> createState() => _MashwarAppState();
}

class _MashwarAppState extends State<MashwarApp> {
  AuthProvider? _ownedAuthProvider;
  WorksiteProvider? _ownedWorksiteProvider;
  RidesProvider? _ownedRidesProvider;
  ParcelsProvider? _ownedParcelsProvider;
  BoardProvider? _ownedBoardProvider;
  AlertsProvider? _ownedAlertsProvider;
  String? _startupError;
  bool _isRetrying = false;

  AuthProvider get _effectiveAuth => widget.authProvider ?? _ownedAuthProvider!;
  WorksiteProvider get _effectiveWorksite =>
      widget.worksiteProvider ?? _ownedWorksiteProvider!;
  RidesProvider get _effectiveRides =>
      widget.ridesProvider ?? _ownedRidesProvider!;
  ParcelsProvider get _effectiveParcels =>
      widget.parcelsProvider ?? _ownedParcelsProvider!;
  BoardProvider get _effectiveBoard =>
      widget.boardProvider ?? _ownedBoardProvider!;
  AlertsProvider get _effectiveAlerts =>
      widget.alertsProvider ?? _ownedAlertsProvider!;

  @override
  void initState() {
    super.initState();
    _startupError = widget.initialStartupError;

    if (widget.authProvider == null) {
      _ownedAuthProvider = AuthProvider();
    }
    final initialUser = _effectiveAuth.user;
    final initialUid = initialUser.id.isNotEmpty ? initialUser.id : null;
    if (widget.worksiteProvider == null) {
      _ownedWorksiteProvider = WorksiteProvider(
        initialUserId: initialUid,
        initialUserName:
            initialUser.fullName.isNotEmpty ? initialUser.fullName : null,
      );
    }
    if (widget.ridesProvider == null) {
      _ownedRidesProvider = RidesProvider(initialUserId: initialUid);
    }
    if (widget.parcelsProvider == null) {
      _ownedParcelsProvider = ParcelsProvider(initialUserId: initialUid);
    }
    if (widget.boardProvider == null) {
      _ownedBoardProvider = BoardProvider(initialUserId: initialUid);
    }
    if (widget.alertsProvider == null) {
      _ownedAlertsProvider = AlertsProvider(initialUserId: initialUid);
    }

    _syncSessionProviders(
      uid: initialUser.id,
      fullName: initialUser.fullName,
    );

    _effectiveAuth.addListener(_onAuthChanged);

    if (_startupError == null && widget.authProvider == null) {
      Future.microtask(() async {
        if (mounted) {
          await _ownedAuthProvider!.restoreSession();
        }
      });
    }
  }

  void _syncSessionProviders({
    required String uid,
    required String fullName,
  }) {
    _effectiveWorksite.syncAuthSession(
      uid: uid,
      fullName: fullName,
    );
    _effectiveRides.syncAuthSession(uid: uid);
    _effectiveParcels.syncAuthSession(uid: uid);
    _effectiveBoard.syncAuthSession(uid: uid);
    _effectiveAlerts.syncAuthSession(uid: uid);
  }

  void _onAuthChanged() {
    final user = _effectiveAuth.user;
    _syncSessionProviders(
      uid: user.id,
      fullName: user.fullName,
    );
  }

  @override
  void dispose() {
    _effectiveAuth.removeListener(_onAuthChanged);
    _ownedAuthProvider?.dispose();
    _ownedWorksiteProvider?.dispose();
    _ownedRidesProvider?.dispose();
    _ownedParcelsProvider?.dispose();
    _ownedBoardProvider?.dispose();
    _ownedAlertsProvider?.dispose();
    super.dispose();
  }

  Future<void> _handleRetryStartup() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      final retryFn = widget.onRetryStartup ?? initializeMashwarStartup;
      final error = await retryFn();
      if (error == null) {
        await _effectiveAuth.restoreSession();
      }
      if (mounted) {
        setState(() {
          _startupError = error;
          _isRetrying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _startupError = e.toString();
          _isRetrying = false;
        });
      }
    }
  }

  bool _shouldBootAdminPortal() {
    try {
      final base = Uri.base;
      final frag = base.fragment.toLowerCase();
      final path = base.path.toLowerCase();
      final portal = base.queryParameters['portal']?.toLowerCase();
      return portal == 'admin' ||
          frag.startsWith('/admin') ||
          path.endsWith('/admin') ||
          path.contains('/admin/');
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final openAdminAtBoot = _shouldBootAdminPortal();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: _effectiveAuth),
        ChangeNotifierProvider<WorksiteProvider>.value(
          value: _effectiveWorksite,
        ),
        ChangeNotifierProvider<RidesProvider>.value(value: _effectiveRides),
        ChangeNotifierProvider<ParcelsProvider>.value(value: _effectiveParcels),
        ChangeNotifierProvider<BoardProvider>.value(value: _effectiveBoard),
        ChangeNotifierProvider<AlertsProvider>.value(value: _effectiveAlerts),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer2<SettingsProvider, AdminProvider>(
        builder: (context, settings, admin, child) {
          final Widget homeWidget;
          if (_startupError != null && !openAdminAtBoot) {
            homeWidget = ServiceUnavailableScreen(
              errorDetails: _startupError!,
              isRetrying: _isRetrying,
              onRetry: _handleRetryStartup,
            );
          } else if (openAdminAtBoot) {
            homeWidget = const AdminShell();
          } else {
            homeWidget = const SplashScreen();
          }

          return MaterialApp(
            title: settings.isArabic
                ? 'مشوار | رحلات تشاركية، طرود وتوريد ذكي'
                : 'MASHWAR | Shared Trips, Parcels & Smart Supply',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routes: {
              '/admin': (_) => const AdminShell(),
              '/admin-login': (_) => const AdminLoginScreen(),
            },
            home: homeWidget,
          );
        },
      ),
    );
  }
}

/// Explicit non-fake startup error screen shown when Firebase or environment
/// configuration is unavailable in non-mock environments.
class ServiceUnavailableScreen extends StatelessWidget {
  final String errorDetails;
  final bool isRetrying;
  final VoidCallback onRetry;

  const ServiceUnavailableScreen({
    super.key,
    required this.errorDetails,
    required this.isRetrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: AppColors.sand,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.qatarMaroon.withValues(alpha: 0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(fontSize: 34),
                    const SizedBox(height: AppDimens.space20),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        color: AppColors.danger,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),
                    Text(
                      isAr
                          ? 'الخدمة السحابية غير متاحة حالياً'
                          : 'Cloud Service Unavailable',
                      textAlign: TextAlign.center,
                      style: AppTypography.title(color: AppColors.navy),
                    ),
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      isAr
                          ? 'تعذّر الاتصال بخدمات Firebase أو التحقق من إعدادات البيئة التشغيلية. لا يمكن تشغيل البيانات التجريبية في هذا الوضع.'
                          : 'Unable to initialize Firebase services or verify runtime configuration. Local mock data is disabled in this environment.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySecondary(),
                    ),
                    const SizedBox(height: AppDimens.space12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.space12),
                      decoration: BoxDecoration(
                        color: AppColors.slateBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Text(
                        errorDetails,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isRetrying ? null : onRetry,
                        icon: isRetrying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          isAr ? 'إعادة المحاولة' : 'Retry',
                          style: AppTypography.button(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
