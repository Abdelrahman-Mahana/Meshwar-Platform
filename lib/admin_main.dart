import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'state/settings_provider.dart';
import 'state/admin_provider.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MashwarAdminWebApp());
}

class MashwarAdminWebApp extends StatelessWidget {
  const MashwarAdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: settings.isArabic
                ? 'مشوار · لوحة تحكم العمليات والإدارة المركزية'
                : 'MASHWAR · Central Operations & Admin Portal',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                ),
              ),
            ),
            locale: settings.locale,
            supportedLocales: const [
              Locale('ar', 'EG'),
              Locale('ar'),
              Locale('en', 'US'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Consumer<AdminProvider>(
              builder: (context, admin, _) {
                // If already logged in, show AdminShell; otherwise show official login screen (Page 68)
                if (admin.isLoggedIn) {
                  return const AdminShell();
                }
                return const AdminLoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
