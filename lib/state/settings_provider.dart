import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization/app_strings.dart';
import '../data/api/mashwar_api_client.dart';

/// App Settings and Localization Provider with Local Persistence
class SettingsProvider extends ChangeNotifier {
  static const String _prefLanguageCode = 'mashwar_locale_language_code';
  static const String _prefCountryCode = 'mashwar_locale_country_code';
  static const String _prefDarkMode = 'mashwar_is_dark_mode';
  static const String _prefRidesNotifications = 'mashwar_notif_rides';
  static const String _prefParcelsNotifications = 'mashwar_notif_parcels';
  static const String _prefBoardNotifications = 'mashwar_notif_board';
  static const String _prefMarketingNotifications = 'mashwar_notif_marketing';

  Locale _locale = const Locale('ar', 'EG');
  bool _isDarkMode = false;
  bool _isInitialized = false;

  // Notification preferences
  bool _ridesNotifications = true;
  bool _parcelsNotifications = true;
  bool _boardNotifications = true;
  bool _marketingNotifications = false;

  SettingsProvider() {
    _loadPreferences();
  }

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  bool get ridesNotifications => _ridesNotifications;
  bool get parcelsNotifications => _parcelsNotifications;
  bool get boardNotifications => _boardNotifications;
  bool get marketingNotifications => _marketingNotifications;

  String tr(String key) => AppStrings.get(key, isArabic: isArabic);

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString(_prefLanguageCode);
      final countryCode = prefs.getString(_prefCountryCode);
      if (langCode != null && (langCode == 'ar' || langCode == 'en')) {
        _locale = Locale(langCode, countryCode ?? (langCode == 'ar' ? 'EG' : 'US'));
        MashwarApiClient.instance.setLocale(_locale.languageCode);
      }
      _isDarkMode = prefs.getBool(_prefDarkMode) ?? false;
      _ridesNotifications = prefs.getBool(_prefRidesNotifications) ?? true;
      _parcelsNotifications = prefs.getBool(_prefParcelsNotifications) ?? true;
      _boardNotifications = prefs.getBool(_prefBoardNotifications) ?? true;
      _marketingNotifications = prefs.getBool(_prefMarketingNotifications) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      // Graceful fallback for test or headless environments
      _isInitialized = true;
    }
  }

  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    _locale = newLocale;
    MashwarApiClient.instance.setLocale(newLocale.languageCode);
    notifyListeners();
    _saveLocale(newLocale);
  }

  Future<void> _saveLocale(Locale newLocale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageCode, newLocale.languageCode);
      if (newLocale.countryCode != null) {
        await prefs.setString(_prefCountryCode, newLocale.countryCode!);
      }
    } catch (_) {}
  }

  void toggleLanguage() {
    if (isArabic) {
      setLocale(const Locale('en', 'US'));
    } else {
      setLocale(const Locale('ar', 'EG'));
    }
  }

  void toggleDarkMode(bool enabled) {
    _isDarkMode = enabled;
    notifyListeners();
    _saveDarkMode(enabled);
  }

  Future<void> _saveDarkMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefDarkMode, enabled);
    } catch (_) {}
  }

  void setRidesNotifications(bool val) {
    _ridesNotifications = val;
    notifyListeners();
    _saveNotificationPref(_prefRidesNotifications, val);
  }

  void setParcelsNotifications(bool val) {
    _parcelsNotifications = val;
    notifyListeners();
    _saveNotificationPref(_prefParcelsNotifications, val);
  }

  void setBoardNotifications(bool val) {
    _boardNotifications = val;
    notifyListeners();
    _saveNotificationPref(_prefBoardNotifications, val);
  }

  void setMarketingNotifications(bool val) {
    _marketingNotifications = val;
    notifyListeners();
    _saveNotificationPref(_prefMarketingNotifications, val);
  }

  Future<void> _saveNotificationPref(String key, bool val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, val);
    } catch (_) {}
  }
}
