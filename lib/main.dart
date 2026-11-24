import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'state/settings_provider.dart';
import 'state/auth_provider.dart';
import 'state/rides_provider.dart';
import 'state/parcels_provider.dart';
import 'state/board_provider.dart';
import 'state/alerts_provider.dart';
import 'state/admin_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/admin_login_screen.dart';
import 'data/repositories/app_repositories.dart';
import 'data/services/firebase_firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (FirebaseConfig.useFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppRepositories.instance.useFirebase();
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  runApp(const MashwarApp());
}

class MashwarApp extends StatelessWidget {
  const MashwarApp({super.key});

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RidesProvider()),
        ChangeNotifierProvider(create: (_) => ParcelsProvider()),
        ChangeNotifierProvider(create: (_) => BoardProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer2<SettingsProvider, AdminProvider>(
        builder: (context, settings, admin, child) {
          return MaterialApp(
            title: settings.isArabic
                ? 'مشوار | خدمات ومشاوير قطر بالضمان'
                : 'MASHWAR | Qatar Community Services & Mobility',
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
            home: openAdminAtBoot ? const AdminShell() : const SplashScreen(),
          );
        },
      ),
    );
  }
}
