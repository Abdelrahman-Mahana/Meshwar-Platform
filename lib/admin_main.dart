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
                ? 'مشوار | لوحة تحكم الإدارة والعمليات'
                : 'MASHWAR | Admin & Operations Portal',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              scaffoldBackgroundColor: const Color(0xFFF4F6F9),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.navy,
                elevation: 0,
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
