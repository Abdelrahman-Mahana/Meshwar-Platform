import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'state/settings_provider.dart';
import 'state/auth_provider.dart';
import 'state/rides_provider.dart';
import 'state/parcels_provider.dart';
import 'state/board_provider.dart';
import 'state/alerts_provider.dart';
import 'state/admin_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MashwarApp());
}

class MashwarApp extends StatelessWidget {
  const MashwarApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: settings.isArabic ? 'مشوار | MASHWAR' : 'MASHWAR | Carpooling & Shipping',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
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
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
