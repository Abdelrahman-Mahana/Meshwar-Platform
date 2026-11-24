import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/config/app_environment.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'state/settings_provider.dart';
import 'state/admin_provider.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'data/repositories/app_repositories.dart';
import 'data/services/firebase_firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final shouldUseFirebase = !AppEnvironment.useDevMocks &&
      (!AppEnvironment.hasExplicitUseFirebase ||
          AppEnvironment.useFirebase ||
          FirebaseConfig.useFirebase);

  if (shouldUseFirebase) {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      AppEnvironment.setFirebaseRuntimeActive(true);
      AppRepositories.instance.useFirebase();
    } catch (e) {
      AppEnvironment.setFirebaseRuntimeActive(false);
      debugPrint('Firebase admin initialization notice: $e');
    }
  } else {
    AppEnvironment.setFirebaseRuntimeActive(false);
    if (AppEnvironment.useDevMocks) {
      AppRepositories.instance.useLocalMocks(allowDevMocks: true);
    }
  }

  runApp(const MashwarAdminWebApp());
}

class MashwarAdminWebApp extends StatelessWidget {
  final AdminProvider? adminProvider;
  final SettingsProvider? settingsProvider;

  const MashwarAdminWebApp({
    super.key,
    this.adminProvider,
    this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (settingsProvider != null)
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider!,
          )
        else
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        if (adminProvider != null)
          ChangeNotifierProvider<AdminProvider>.value(value: adminProvider!)
        else
          ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer2<SettingsProvider, AdminProvider>(
        builder: (context, settings, admin, _) {
          final isDark = admin.isDarkMode;
          final baseTheme = AppTheme.lightTheme;

          return MaterialApp(
            title: settings.isArabic
                ? 'مشوار · مركز القيادة والإدارة والـ DevOps'
                : 'MASHWAR · Enterprise Command & DevOps Portal',
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
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
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
            supportedLocales: const [
              Locale('ar', 'QA'),
              Locale('ar'),
              Locale('en', 'US'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routes: {
              '/admin': (_) => const AdminShell(),
              '/admin-login': (_) => const AdminLoginScreen(),
            },
            home: admin.isLoggedIn ? const AdminShell() : const AdminLoginScreen(),
          );
        },
      ),
    );
  }
}
