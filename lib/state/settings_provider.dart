import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';

class SettingsProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar', 'EG');
  bool _isDarkMode = false;

  // Notification preferences
  bool _ridesNotifications = true;
  bool _parcelsNotifications = true;
  bool _boardNotifications = true;
  bool _marketingNotifications = false;

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isDarkMode => _isDarkMode;

  bool get ridesNotifications => _ridesNotifications;
  bool get parcelsNotifications => _parcelsNotifications;
  bool get boardNotifications => _boardNotifications;
  bool get marketingNotifications => _marketingNotifications;

  String tr(String key) => AppStrings.get(key, isArabic: isArabic);

  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
  }

  void toggleLanguage() {
    if (isArabic) {
      _locale = const Locale('en', 'US');
    } else {
      _locale = const Locale('ar', 'EG');
    }
    notifyListeners();
  }

  void toggleDarkMode(bool enabled) {
    _isDarkMode = enabled;
    notifyListeners();
  }

  void setRidesNotifications(bool val) {
    _ridesNotifications = val;
    notifyListeners();
  }

  void setParcelsNotifications(bool val) {
    _parcelsNotifications = val;
    notifyListeners();
  }

  void setBoardNotifications(bool val) {
    _boardNotifications = val;
    notifyListeners();
  }

  void setMarketingNotifications(bool val) {
    _marketingNotifications = val;
    notifyListeners();
  }
}
