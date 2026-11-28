import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'main.dart' show ServiceUnavailableScreen, initializeMashwarStartup;
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'state/admin_provider.dart';
import 'state/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final startupError = await initializeMashwarStartup();

  runApp(
    MashwarAdminWebApp(
      initialStartupError: startupError,
      onRetryStartup: initializeMashwarStartup,
    ),
  );
}

class MashwarAdminWebApp extends StatefulWidget {
  final AdminProvider? adminProvider;
  final SettingsProvider? settingsProvider;
  final String? initialStartupError;
  final Future<String?> Function()? onRetryStartup;

  const MashwarAdminWebApp({
    super.key,
    this.adminProvider,
    this.settingsProvider,
    this.initialStartupError,
    this.onRetryStartup,
  });

  @override
  State<MashwarAdminWebApp> createState() => _MashwarAdminWebAppState();
}

class _MashwarAdminWebAppState extends State<MashwarAdminWebApp> {
  String? _startupError;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startupError = widget.initialStartupError;
  }

  Future<void> _handleRetryStartup() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      final retryFn = widget.onRetryStartup ?? initializeMashwarStartup;
      final error = await retryFn();
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (widget.settingsProvider != null)
          ChangeNotifierProvider<SettingsProvider>.value(
            value: widget.settingsProvider!,
          )
        else
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        if (widget.adminProvider != null)
          ChangeNotifierProvider<AdminProvider>.value(
            value: widget.adminProvider!,
          )
        else
          ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer2<SettingsProvider, AdminProvider>(
        builder: (context, settings, admin, _) {
          final isDark = admin.isDarkMode;
          final baseTheme = AppTheme.lightTheme;
          final baseDarkTheme = ThemeData.dark(useMaterial3: true);

          final Widget homeWidget;
          if (_startupError != null) {
            homeWidget = ServiceUnavailableScreen(
              errorDetails: _startupError!,
              isRetrying: _isRetrying,
              onRetry: _handleRetryStartup,
            );
          } else {
            homeWidget =
                admin.isLoggedIn ? const AdminShell() : const AdminLoginScreen();
          }

          return MaterialApp(
            title: settings.isArabic
                ? 'مشوار · لوحة إدارة العمليات'
                : 'MASHWAR · Operations & Admin Portal',
            debugShowCheckedModeBanner: false,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: baseTheme.copyWith(
              scaffoldBackgroundColor: const Color(0xFFF4F6FA),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.navy,
                elevation: 0,
                centerTitle: false,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                ),
              ),
            ),
            darkTheme: baseDarkTheme.copyWith(
              textTheme: GoogleFonts.cairoTextTheme(baseDarkTheme.textTheme),
              primaryTextTheme:
                  GoogleFonts.cairoTextTheme(baseDarkTheme.primaryTextTheme),
              scaffoldBackgroundColor: const Color(0xFF0A1422),
              colorScheme: const ColorScheme.dark(
                primary: AppColors.gold,
                secondary: Color(0xFF2DD4BF),
                surface: Color(0xFF102033),
                error: Color(0xFFF87171),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF091320),
                elevation: 0,
                centerTitle: false,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF102033),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF24405F), width: 1.0),
                ),
              ),
            ),
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
