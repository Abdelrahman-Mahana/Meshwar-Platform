import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/contracts/i_maps_repository.dart';

/// Structured bilingual geo-hub entry for instant Qatar & GCC resolution.
class MashwarGeoHubEntry {
  final String id;
  final String nameAr;
  final String nameEn;
  final String govAr;
  final String govEn;
  final double lat;
  final double lng;
  final String zoneCode; // north | north_coast | lusail | central | west | rayyan | industrial | salwa | south | airport | gcc
  final List<String> aliases;

  const MashwarGeoHubEntry({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.govAr,
    required this.govEn,
    required this.lat,
    required this.lng,
    required this.zoneCode,
    this.aliases = const [],
  });
}

/// Google Maps Platform service providing Places API (New) Autocomplete,
/// Routes API v2 Directions, Geocoding API, Cross-Platform Maps URLs,
/// compile-time + SharedPreferences runtime API key management, and an
/// accurate bilingual Qatar & GCC geo-engine fallback.
///
/// Official API references:
/// - Places API (New): https://developers.google.com/maps/documentation/places/web-service/op-overview?utm_campaign=gmp_git_agentskills_v1
/// - Routes API v2: https://developers.google.com/maps/documentation/routes/compute_route_directions?utm_campaign=gmp_git_agentskills_v1
/// - Maps URLs: https://developers.google.com/maps/documentation/urls/get-started?utm_campaign=gmp_git_agentskills_v1
class GoogleMapsService {
  static const String runtimeApiKeyPrefsKey = 'mashwar_google_maps_api_key';
  static const String _solutionAttributionId = 'gmp_git_agentskills_v1';
  static const String _compileTimeApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static String _runtimeApiKey = '';
  static bool _runtimeKeyLoaded = false;

  final String? _explicitApiKey;
  final http.Client _client;

  GoogleMapsService({
    String? apiKey,
    http.Client? client,
  })  : _explicitApiKey = apiKey,
        _client = client ?? http.Client();

  /// Active API key resolved in priority order:
  /// 1) Explicit constructor override (for unit tests),
  /// 2) Runtime user-configured key persisted in SharedPreferences,
  /// 3) Compile-time `--dart-define=GOOGLE_MAPS_API_KEY=...`.
  String get apiKey {
    if (_explicitApiKey != null && _explicitApiKey!.trim().isNotEmpty) {
      return _explicitApiKey!.trim();
    }
    if (_runtimeApiKey.trim().isNotEmpty) {
      return _runtimeApiKey.trim();
    }
    return _compileTimeApiKey.trim();
  }

  /// Whether a compile-time or runtime Google Maps API key is currently active.
  bool get hasConfiguredApiKey => apiKey.isNotEmpty;

  static bool get hasActiveApiKey =>
      _runtimeApiKey.trim().isNotEmpty || _compileTimeApiKey.trim().isNotEmpty;

  static bool get hasCompileTimeApiKey => _compileTimeApiKey.trim().isNotEmpty;

  static bool get hasRuntimeApiKey => _runtimeApiKey.trim().isNotEmpty;

  static String get runtimeApiKey => _runtimeApiKey;

  /// Safe masked preview (never exposes full secret key in UI/logs).
  static String get maskedActiveApiKey {
    final active = _runtimeApiKey.trim().isNotEmpty
        ? _runtimeApiKey.trim()
        : _compileTimeApiKey.trim();
    if (active.isEmpty) return '';
    if (active.length <= 8) return '••••${active.substring(active.length - 2)}';
    return '${active.substring(0, 4)}••••••••${active.substring(active.length - 4)}';
  }

  /// Loads any persisted runtime API key from SharedPreferences with a strict
  /// 120ms timeout guard so widget tests never hang.
  static Future<String> loadRuntimeApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 120));
      final saved = prefs.getString(runtimeApiKeyPrefsKey)?.trim() ?? '';
      _runtimeApiKey = saved;
    } catch (_) {
      // Safe no-op in headless widget test sandboxes without SharedPreferences mock
    } finally {
      _runtimeKeyLoaded = true;
    }
    return _runtimeApiKey;
  }

  /// Saves a runtime Google Maps API key in memory and SharedPreferences.
  static Future<void> setRuntimeApiKey(String key) async {
    final trimmed = key.trim();
    _runtimeApiKey = trimmed;
    _runtimeKeyLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 120));
      if (trimmed.isEmpty) {
        await prefs
            .remove(runtimeApiKeyPrefsKey)
            .timeout(const Duration(milliseconds: 120));
      } else {
        await prefs
            .setString(runtimeApiKeyPrefsKey, trimmed)
            .timeout(const Duration(milliseconds: 120));
      }
    } catch (_) {
      // In-memory key remains active for the session even if storage times out
    }
  }

  /// Clears any runtime-configured Google Maps API key.
  static Future<void> clearRuntimeApiKey() async {
    _runtimeApiKey = '';
    _runtimeKeyLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 120));
      await prefs
          .remove(runtimeApiKeyPrefsKey)
          .timeout(const Duration(milliseconds: 120));
    } catch (_) {}
  }

  Future<void> _ensureRuntimeKeyInitialized() async {
    if (!_runtimeKeyLoaded &&
        (_explicitApiKey == null || _explicitApiKey!.isEmpty)) {
      await loadRuntimeApiKey();
    }
  }

  /// Official Cross-Platform Google Maps Directions URL builder.
  static String buildDirectionsUrl(
    String origin,
    String destination, {
    String? stopover,
  }) {
    final cleanOrigin = _qualifyPlaceQuery(origin);
    final cleanDest = _qualifyPlaceQuery(destination);
    final params = <String, String>{
      'api': '1',
      'origin': cleanOrigin,
      'destination': cleanDest,
      if (stopover != null && stopover.trim().isNotEmpty)
        'waypoints': _qualifyPlaceQuery(stopover),
      'travelmode': 'driving',
    };
    return Uri.https('www.google.com', '/maps/dir/', params).toString();
  }

  /// Official Cross-Platform Google Maps Place Search URL builder.
  static String buildPlaceSearchUrl(
    String query, {
    double? lat,
    double? lng,
  }) {
    final trimmed = query.trim();
    final String effectiveQuery;
    if (trimmed.isEmpty && lat != null && lng != null) {
      effectiveQuery =
          '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    } else if (trimmed.isNotEmpty) {
      effectiveQuery = _qualifyPlaceQuery(trimmed);
    } else {
      effectiveQuery = 'Doha, Qatar';
    }
    return Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': effectiveQuery,
    }).toString();
  }

  static String _qualifyPlaceQuery(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return 'Doha, Qatar';
    final entry = resolveHubEntry(cleaned);
    if (entry != null && entry.zoneCode == 'gcc') {
      return cleaned;
    }
    final lower = cleaned.toLowerCase();
    if (lower.contains('qatar') ||
        lower.contains('قطر') ||
        lower.contains('saudi') ||
        lower.contains('السعودية') ||
        lower.contains('uae') ||
        lower.contains('الإمارات') ||
        lower.contains('kuwait') ||
        lower.contains('الكويت') ||
        lower.contains('bahrain') ||
        lower.contains('البحرين') ||
        lower.contains('oman') ||
        lower.contains('عمان')) {
      return cleaned;
    }
    return '$cleaned, Qatar';
  }

  /// Expanded bilingual Qatar (all 8 municipalities + logistics, ports, metro,
  /// WOQOD, industrial & coastal hubs) and GCC cross-border corridors catalog.
  static const List<MashwarGeoHubEntry> bilingualGeoCatalog = [
    // 8 Municipalities of Qatar
    MashwarGeoHubEntry(
      id: 'doha',
      nameAr: 'الدوحة',
      nameEn: 'Doha',
      govAr: 'بلدية الدوحة',
      govEn: 'Doha Municipality',
      lat: 25.2854,
      lng: 51.5310,
      zoneCode: 'central',
      aliases: ['وسط الدوحة', 'كورنيش الدوحة', 'corniche', 'central doha'],
    ),
    MashwarGeoHubEntry(
      id: 'rayyan',
      nameAr: 'الريان',
      nameEn: 'Al Rayyan',
      govAr: 'بلدية الريان',
      govEn: 'Al Rayyan Municipality',
      lat: 25.2919,
      lng: 51.4244,
      zoneCode: 'rayyan',
      aliases: ['معيذر', 'الوجبة', 'اسباير', 'aspire', 'muaither'],
    ),
    MashwarGeoHubEntry(
      id: 'wakrah',
      nameAr: 'الوكرة',
      nameEn: 'Al Wakrah',
      govAr: 'بلدية الوكرة',
      govEn: 'Al Wakrah Municipality',
      lat: 25.1715,
      lng: 51.6034,
      zoneCode: 'south',
      aliases: ['الوكير', 'سوق الوكرة', 'جنوب', 'wakra', 'al wukair'],
    ),
    MashwarGeoHubEntry(
      id: 'khor',
      nameAr: 'الخور',
      nameEn: 'Al Khor',
      govAr: 'بلدية الخور والذخيرة',
      govEn: 'Al Khor & Al Thakhira',
      lat: 25.6804,
      lng: 51.4969,
      zoneCode: 'north_coast',
      aliases: ['استاد البيت', 'سميسمة', 'al bayt', 'simaisma'],
    ),
    MashwarGeoHubEntry(
      id: 'umm_salal',
      nameAr: 'أم صلال',
      nameEn: 'Umm Salal',
      govAr: 'بلدية أم صلال',
      govEn: 'Umm Salal Municipality',
      lat: 25.4152,
      lng: 51.4065,
      zoneCode: 'north',
      aliases: ['أم صلال محمد', 'أم صلال علي', 'الخريطيات', 'umm salal mohammed', 'umm salal ali'],
    ),
    MashwarGeoHubEntry(
      id: 'daayen',
      nameAr: 'الضعاين',
      nameEn: 'Al Daayen',
      govAr: 'بلدية الضعاين',
      govEn: 'Al Daayen Municipality',
      lat: 25.4648,
      lng: 51.4601,
      zoneCode: 'north',
      aliases: ['الخيسة', 'العب', 'لعبيب', 'al kheesa', 'leabaib'],
    ),
    MashwarGeoHubEntry(
      id: 'shamal',
      nameAr: 'الشمال',
      nameEn: 'Al Shamal',
      govAr: 'بلدية الشمال',
      govEn: 'Al Shamal Municipality',
      lat: 26.1293,
      lng: 51.2009,
      zoneCode: 'north',
      aliases: ['مدينة الشمال', 'الزبارة', 'madinat ash shamal', 'zubarah'],
    ),
    MashwarGeoHubEntry(
      id: 'shahaniya',
      nameAr: 'الشيحانية',
      nameEn: 'Al Shahaniya',
      govAr: 'بلدية الشيحانية',
      govEn: 'Al Shahaniya Municipality',
      lat: 25.3709,
      lng: 51.2226,
      zoneCode: 'west',
      aliases: ['الشحانية', 'روضة راشد', 'ash shahaniyah'],
    ),

    // Major Urban, Coastal, Academic & Airport Hubs
    MashwarGeoHubEntry(
      id: 'lusail',
      nameAr: 'لوسيل',
      nameEn: 'Lusail',
      govAr: 'بلدية الضعاين',
      govEn: 'Lusail City · Al Daayen',
      lat: 25.4357,
      lng: 51.4910,
      zoneCode: 'lusail',
      aliases: ['مارينا لوسيل', 'درب لوسيل', 'بوليفارد لوسيل', 'lusail marina', 'lusail boulevard', 'vendome'],
    ),
    MashwarGeoHubEntry(
      id: 'pearl',
      nameAr: 'اللؤلؤة',
      nameEn: 'The Pearl-Qatar',
      govAr: 'بلدية الدوحة',
      govEn: 'The Pearl · Doha',
      lat: 25.3679,
      lng: 51.5514,
      zoneCode: 'lusail',
      aliases: ['بورتو أرابيا', 'قناة كارتييه', 'اللؤلؤة قطر', 'the pearl', 'porto arabia', 'qanat quartier'],
    ),
    MashwarGeoHubEntry(
      id: 'katara',
      nameAr: 'كتارا',
      nameEn: 'Katara Cultural Village',
      govAr: 'بلدية الدوحة',
      govEn: 'Katara · Doha',
      lat: 25.3602,
      lng: 51.5245,
      zoneCode: 'lusail',
      aliases: ['الحي الثقافي كتارا', 'شاطئ كتارا', 'katara beach'],
    ),
    MashwarGeoHubEntry(
      id: 'msheireb',
      nameAr: 'مشيرب',
      nameEn: 'Msheireb Downtown Doha',
      govAr: 'بلدية الدوحة',
      govEn: 'Msheireb · Doha',
      lat: 25.2877,
      lng: 51.5276,
      zoneCode: 'central',
      aliases: ['مشيرب قلب الدوحة', 'سوق واقف', 'souq waqif', 'msheireb'],
    ),
    MashwarGeoHubEntry(
      id: 'education_city',
      nameAr: 'المدينة التعليمية',
      nameEn: 'Education City',
      govAr: 'بلدية الريان',
      govEn: 'Education City · Al Rayyan',
      lat: 25.3147,
      lng: 51.4384,
      zoneCode: 'rayyan',
      aliases: ['مؤسسة قطر', 'بوابة المدينة التعليمية', 'سدرة', 'qatar foundation', 'sidra', 'qf'],
    ),
    MashwarGeoHubEntry(
      id: 'hia_airport',
      nameAr: 'مطار حمد الدولي',
      nameEn: 'Hamad International Airport (HIA)',
      govAr: 'بلدية الدوحة',
      govEn: 'HIA Airport · Doha',
      lat: 25.2731,
      lng: 51.6081,
      zoneCode: 'airport',
      aliases: ['المطار', 'مطار الدوحة', 'صالة المغادرون', 'hia', 'doha airport', 'hamad airport', 'doh'],
    ),
    MashwarGeoHubEntry(
      id: 'sadd',
      nameAr: 'السد',
      nameEn: 'Al Sadd',
      govAr: 'بلدية الدوحة',
      govEn: 'Al Sadd · Doha',
      lat: 25.2816,
      lng: 51.5008,
      zoneCode: 'central',
      aliases: ['بن محمود', 'النصر', 'bin mahmoud', 'c ring'],
    ),
    MashwarGeoHubEntry(
      id: 'west_bay',
      nameAr: 'الدفنة',
      nameEn: 'West Bay (Al Dafna)',
      govAr: 'بلدية الدوحة',
      govEn: 'West Bay · Doha',
      lat: 25.3260,
      lng: 51.5318,
      zoneCode: 'central',
      aliases: ['الخليج الغربي', 'أبراج الدفنة', 'سيتي سنتر', 'west bay', 'city center doha'],
    ),
    MashwarGeoHubEntry(
      id: 'gharafa',
      nameAr: 'الغرافة',
      nameEn: 'Al Gharafa',
      govAr: 'بلدية الريان',
      govEn: 'Al Gharafa · Al Rayyan',
      lat: 25.3510,
      lng: 51.4540,
      zoneCode: 'rayyan',
      aliases: ['إزدان مول', 'سوق الغرافة', 'gharafa', 'ezdan mall'],
    ),

    // Industrial, Logistics, Ports, Energy & Border Hubs
    MashwarGeoHubEntry(
      id: 'industrial_area',
      nameAr: 'المنطقة الصناعية',
      nameEn: 'Industrial Area',
      govAr: 'بلدية الريان',
      govEn: 'Industrial Area · Doha',
      lat: 25.1610,
      lng: 51.4417,
      zoneCode: 'industrial',
      aliases: ['الصناعية', 'صناعية الدوحة', 'منطقة الورش', 'industrial'],
    ),
    MashwarGeoHubEntry(
      id: 'industrial_st10',
      nameAr: 'شارع 10 · الصناعية',
      nameEn: 'Industrial Area Street 10',
      govAr: 'المنطقة الصناعية · بلدية الريان',
      govEn: 'Street 10 · Industrial Area',
      lat: 25.1745,
      lng: 51.4480,
      zoneCode: 'industrial',
      aliases: ['شارع ١٠', 'صناعية شارع 10', 'st 10', 'street 10'],
    ),
    MashwarGeoHubEntry(
      id: 'industrial_st18',
      nameAr: 'شارع 18 · الصناعية',
      nameEn: 'Industrial Area Street 18',
      govAr: 'المنطقة الصناعية · بلدية الريان',
      govEn: 'Street 18 · Industrial Area',
      lat: 25.1632,
      lng: 51.4395,
      zoneCode: 'industrial',
      aliases: ['شارع ١٨', 'صناعية شارع 18', 'شارع 14', 'st 14', 'st 18', 'street 18'],
    ),
    MashwarGeoHubEntry(
      id: 'salwa_road',
      nameAr: 'طريق سلوى',
      nameEn: 'Salwa Road Logistics Hub',
      govAr: 'بلدية الريان',
      govEn: 'Salwa Road · Al Rayyan',
      lat: 25.2280,
      lng: 51.4390,
      zoneCode: 'salwa',
      aliases: ['سوق الجملة', 'عين خالد', 'أبو هامور', 'salwa rd', 'ain khaled', 'abu hamour'],
    ),
    MashwarGeoHubEntry(
      id: 'hamad_port',
      nameAr: 'ميناء حمد',
      nameEn: 'Hamad Port (Umm Al Houl)',
      govAr: 'بلدية الوكرة',
      govEn: 'Hamad Port · Al Wakrah',
      lat: 25.0289,
      lng: 51.6228,
      zoneCode: 'south',
      aliases: ['أم الحول', 'المنطقة الحرة', 'الميناء', 'hamad port', 'umm al houl', 'free zone'],
    ),
    MashwarGeoHubEntry(
      id: 'mesaieed',
      nameAr: 'مسيعيد',
      nameEn: 'Mesaieed Industrial City',
      govAr: 'بلدية الوكرة',
      govEn: 'Mesaieed · Al Wakrah',
      lat: 24.9946,
      lng: 51.5473,
      zoneCode: 'south',
      aliases: ['مسيعيد الصناعية', 'امسيعيد', 'mesaieed', 'umm said'],
    ),
    MashwarGeoHubEntry(
      id: 'sealine',
      nameAr: 'سيلين',
      nameEn: 'Sealine & Khor Al Adaid',
      govAr: 'بلدية الوكرة',
      govEn: 'Sealine · Al Wakrah',
      lat: 24.8636,
      lng: 51.5119,
      zoneCode: 'south',
      aliases: ['شاطئ سيلين', 'خور العديد', 'sealine beach', 'inland sea', 'khor al adaid'],
    ),
    MashwarGeoHubEntry(
      id: 'ras_laffan',
      nameAr: 'رأس لفان',
      nameEn: 'Ras Laffan Industrial City',
      govAr: 'بلدية الخور والذخيرة',
      govEn: 'Ras Laffan · Al Khor',
      lat: 25.9189,
      lng: 51.5370,
      zoneCode: 'north_coast',
      aliases: ['راس لفان', 'مدينة رأس لفان', 'ras laffan', 'rlic'],
    ),
    MashwarGeoHubEntry(
      id: 'thakhira',
      nameAr: 'الذخيرة',
      nameEn: 'Al Thakhira',
      govAr: 'بلدية الخور والذخيرة',
      govEn: 'Al Thakhira · Al Khor',
      lat: 25.7302,
      lng: 51.5469,
      zoneCode: 'north_coast',
      aliases: ['ذخيرة', 'al dhakira', 'thakhira'],
    ),
    MashwarGeoHubEntry(
      id: 'al_ruwais',
      nameAr: 'الرويس',
      nameEn: 'Al Ruwais Port',
      govAr: 'بلدية الشمال',
      govEn: 'Al Ruwais · Al Shamal',
      lat: 26.1419,
      lng: 51.2136,
      zoneCode: 'north',
      aliases: ['ميناء الرويس', 'أبو ظلوف', 'ruwais', 'al ruwais'],
    ),
    MashwarGeoHubEntry(
      id: 'dukhan',
      nameAr: 'دخان',
      nameEn: 'Dukhan',
      govAr: 'بلدية الشيحانية',
      govEn: 'Dukhan · Al Shahaniya',
      lat: 25.4247,
      lng: 50.7824,
      zoneCode: 'west',
      aliases: ['مدينة دخان', 'زكريت', 'حقل دخان', 'dukhan city', 'zekreet'],
    ),
    MashwarGeoHubEntry(
      id: 'abu_samra',
      nameAr: 'أبو سمرة',
      nameEn: 'Abu Samra Border Crossing',
      govAr: 'بلدية الريان',
      govEn: 'Abu Samra · Saudi Border',
      lat: 24.7453,
      lng: 50.8588,
      zoneCode: 'salwa',
      aliases: ['منفذ أبو سمرة', 'معبر سلوى', 'حدود السعودية', 'abu samra', 'salwa border'],
    ),

    // WOQOD & Doha Metro Hubs
    MashwarGeoHubEntry(
      id: 'woqod_msheireb',
      nameAr: 'محطة وقود وقود (WOQOD) - الدوحة',
      nameEn: 'WOQOD Petrol Station - Doha Hub',
      govAr: 'بلدية الدوحة',
      govEn: 'WOQOD Meeting Point · Doha',
      lat: 25.3012,
      lng: 51.5150,
      zoneCode: 'central',
      aliases: ['وقود', 'محطة وقود', 'سدرة وقود', 'woqod', 'petrol station', 'sidra store'],
    ),
    MashwarGeoHubEntry(
      id: 'woqod_al_khor',
      nameAr: 'محطة وقود وقود (WOQOD) - مدخل الخور',
      nameEn: 'WOQOD Station - Al Khor Coastal Rd',
      govAr: 'بلدية الخور والذخيرة',
      govEn: 'WOQOD Hub · Al Khor',
      lat: 25.6490,
      lng: 51.4985,
      zoneCode: 'north_coast',
      aliases: ['وقود الخور', 'woqod al khor', 'woqod north'],
    ),
    MashwarGeoHubEntry(
      id: 'metro_msheireb',
      nameAr: 'محطة مترو مشيرب (الريل)',
      nameEn: 'Msheireb Metro Station (Doha Metro)',
      govAr: 'مترو الدوحة · الخط الأحمر والذهبي والأخضر',
      govEn: 'Doha Metro Central Hub · Qatar Rail',
      lat: 25.2861,
      lng: 51.5269,
      zoneCode: 'central',
      aliases: ['مترو الدوحة', 'الريل', 'محطة مترو', 'doha metro', 'qatar rail', 'msheireb metro'],
    ),
    MashwarGeoHubEntry(
      id: 'metro_lusail',
      nameAr: 'محطة مترو لوسيل QNB (الريل)',
      nameEn: 'Lusail QNB Metro Station (Doha Metro)',
      govAr: 'مترو الدوحة · الخط الأحمر',
      govEn: 'Red Line Terminal · Lusail',
      lat: 25.4215,
      lng: 51.4902,
      zoneCode: 'lusail',
      aliases: ['مترو لوسيل', 'lusail metro', 'red line metro'],
    ),
    MashwarGeoHubEntry(
      id: 'metro_wakrah',
      nameAr: 'محطة مترو الوكرة (الريل)',
      nameEn: 'Al Wakrah Metro Station (Doha Metro)',
      govAr: 'مترو الدوحة · الخط الأحمر الجنوبي',
      govEn: 'Red Line South · Al Wakrah',
      lat: 25.1852,
      lng: 51.5924,
      zoneCode: 'south',
      aliases: ['مترو الوكرة', 'wakrah metro'],
    ),

    // GCC Cross-Border Corridors
    MashwarGeoHubEntry(
      id: 'riyadh',
      nameAr: 'الرياض',
      nameEn: 'Riyadh, Saudi Arabia',
      govAr: 'المملكة العربية السعودية',
      govEn: 'Riyadh Province, KSA',
      lat: 24.7136,
      lng: 46.6753,
      zoneCode: 'gcc',
      aliases: ['السعودية', 'riyadh', 'ksa'],
    ),
    MashwarGeoHubEntry(
      id: 'dammam',
      nameAr: 'الدمام',
      nameEn: 'Dammam & Khobar, Saudi Arabia',
      govAr: 'المنطقة الشرقية · السعودية',
      govEn: 'Eastern Province, KSA',
      lat: 26.4207,
      lng: 50.0888,
      zoneCode: 'gcc',
      aliases: ['الخبر', 'الأحساء', 'الهفوف', 'khobar', 'ahsa', 'hofuf', 'dammam'],
    ),
    MashwarGeoHubEntry(
      id: 'dubai',
      nameAr: 'دبي',
      nameEn: 'Dubai, UAE',
      govAr: 'الإمارات العربية المتحدة',
      govEn: 'United Arab Emirates',
      lat: 25.2048,
      lng: 55.2708,
      zoneCode: 'gcc',
      aliases: ['أبوظبي', 'الامارات', 'abu dhabi', 'uae', 'dubai'],
    ),
    MashwarGeoHubEntry(
      id: 'kuwait',
      nameAr: 'الكويت',
      nameEn: 'Kuwait City, Kuwait',
      govAr: 'دولة الكويت',
      govEn: 'State of Kuwait',
      lat: 29.3759,
      lng: 47.9774,
      zoneCode: 'gcc',
      aliases: ['مدينة الكويت', 'kuwait'],
    ),
    MashwarGeoHubEntry(
      id: 'manama',
      nameAr: 'المنامة',
      nameEn: 'Manama, Bahrain',
      govAr: 'مملكة البحرين',
      govEn: 'Kingdom of Bahrain',
      lat: 26.2285,
      lng: 50.5860,
      zoneCode: 'gcc',
      aliases: ['البحرين', 'bahrain', 'manama'],
    ),
    MashwarGeoHubEntry(
      id: 'muscat',
      nameAr: 'مسقط',
      nameEn: 'Muscat, Oman',
      govAr: 'سلطنة عُمان',
      govEn: 'Sultanate of Oman',
      lat: 23.5880,
      lng: 58.3829,
      zoneCode: 'gcc',
      aliases: ['عمان', 'oman', 'muscat'],
    ),
  ];

  /// Backward-compatible Qatar Geo-Catalog map indexed by Arabic hub name.
  static final Map<String, Map<String, dynamic>> qatarCitiesCatalog = {
    for (final e in bilingualGeoCatalog)
      e.nameAr: {
        'lat': e.lat,
        'lng': e.lng,
        'gov': e.govAr,
        'nameEn': e.nameEn,
        'govEn': e.govEn,
        'zone': e.zoneCode,
      },
  };

  static String _normalizeSearchToken(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
  }

  static bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Resolves a free-form Arabic or English location/address string to the best
  /// matching [MashwarGeoHubEntry] in the catalog.
  static MashwarGeoHubEntry? resolveHubEntry(String rawLocation) {
    final norm = _normalizeSearchToken(rawLocation);
    if (norm.isEmpty) return null;

    // 1. Exact Arabic or English name match
    for (final e in bilingualGeoCatalog) {
      if (_normalizeSearchToken(e.nameAr) == norm ||
          _normalizeSearchToken(e.nameEn) == norm) {
        return e;
      }
    }

    // 2. Specific hub / street / landmark substring match (check more specific entries before generic Doha/Rayyan)
    final prioritized = [
      ...bilingualGeoCatalog.where((e) =>
          e.id != 'doha' && e.id != 'rayyan' && e.id != 'wakrah' && e.id != 'khor'),
      ...bilingualGeoCatalog.where((e) =>
          e.id == 'khor' || e.id == 'wakrah' || e.id == 'rayyan' || e.id == 'doha'),
    ];

    for (final e in prioritized) {
      final arNorm = _normalizeSearchToken(e.nameAr);
      final enNorm = _normalizeSearchToken(e.nameEn);
      if (norm.contains(arNorm) ||
          arNorm.contains(norm) ||
          norm.contains(enNorm) ||
          enNorm.split(' ').first.length >= 4 &&
              norm.contains(enNorm.split(' ').first)) {
        return e;
      }
      for (final alias in e.aliases) {
        final aliasNorm = _normalizeSearchToken(alias);
        if (aliasNorm.isNotEmpty && norm.contains(aliasNorm)) {
          return e;
        }
      }
    }
    return null;
  }

  /// Returns coordinates for a known hub/address if resolvable.
  static ({double lat, double lng})? resolveCoordinates(String rawLocation) {
    final entry = resolveHubEntry(rawLocation);
    if (entry == null) return null;
    return (lat: entry.lat, lng: entry.lng);
  }

  /// Search places on Web & Mobile:
  /// (a) When an API key is configured, calls CORS-friendly Google Places API (New)
  ///     (`POST https://places.googleapis.com/v1/places:autocomplete` with `X-Goog-Api-Key`),
  ///     falling back to legacy Places REST on native if needed.
  /// (b) Merges/falls back to the instant bilingual Qatar & GCC geo-catalog.
  Future<List<LocationSearchResult>> searchPlaces(String query) async {
    final rawTrimmed = query.trim();
    if (rawTrimmed.isEmpty) return [];

    await _ensureRuntimeKeyInitialized();
    final activeKey = apiKey;
    final isArQuery = _containsArabic(rawTrimmed);
    final localMatches = searchCatalogSync(rawTrimmed, preferArabic: isArQuery);

    if (activeKey.isNotEmpty) {
      // (a) Primary: Google Places API (New) — CORS-friendly POST v1 endpoint
      try {
        final v1Uri = Uri.parse(
          'https://places.googleapis.com/v1/places:autocomplete',
        );
        final response = await _client
            .post(
              v1Uri,
              headers: <String, String>{
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': activeKey,
                'X-Goog-FieldMask':
                    'suggestions.placePrediction.placeId,suggestions.placePrediction.text.text,suggestions.placePrediction.structuredFormat',
                'X-Goog-Maps-Solution-ID': _solutionAttributionId,
              },
              body: json.encode(<String, dynamic>{
                'input': rawTrimmed,
                'languageCode': isArQuery ? 'ar' : 'en',
                'regionCode': 'qa',
                'locationBias': <String, dynamic>{
                  'circle': <String, dynamic>{
                    'center': <String, double>{
                      'latitude': 25.2854,
                      'longitude': 51.5310,
                    },
                    'radius': 50000.0,
                  },
                },
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic> &&
              decoded['suggestions'] is List) {
            final suggestions = decoded['suggestions'] as List;
            final remoteResults = <LocationSearchResult>[];
            for (final item in suggestions) {
              if (item is! Map) continue;
              final pred = item['placePrediction'];
              if (pred is! Map) continue;
              final structured = pred['structuredFormat'] as Map?;
              final mainText =
                  (structured?['mainText']?['text'] ?? pred['text']?['text'] ?? '')
                      .toString()
                      .trim();
              if (mainText.isEmpty) continue;
              final secondaryText =
                  (structured?['secondaryText']?['text'] ??
                          (isArQuery ? 'قطر' : 'Qatar'))
                      .toString()
                      .trim();
              final coords = resolveCoordinates(mainText) ??
                  resolveCoordinates('$mainText $secondaryText');
              remoteResults.add(
                LocationSearchResult(
                  placeId: (pred['placeId'] ?? '').toString(),
                  mainText: mainText,
                  secondaryText: secondaryText,
                  latitude: coords?.lat,
                  longitude: coords?.lng,
                  googleMapsPlaceUrl: buildPlaceSearchUrl(
                    '$mainText, $secondaryText',
                    lat: coords?.lat,
                    lng: coords?.lng,
                  ),
                ),
              );
            }
            if (remoteResults.isNotEmpty) {
              return _mergeUniqueResults(remoteResults, localMatches);
            }
          }
        }
      } catch (_) {
        // Proceed to native legacy fallback or local catalog
      }

      // Secondary fallback on Native ONLY (never call legacy REST on Web due to CORS)
      if (!kIsWeb) {
        try {
          final legacyUri = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
            'input=${Uri.encodeComponent(rawTrimmed)}&'
            'components=country:qa&'
            'language=${isArQuery ? "ar" : "en"}&'
            'key=$activeKey',
          );
          final response = await _client
              .get(legacyUri)
              .timeout(const Duration(seconds: 4));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data is Map &&
                data['status'] == 'OK' &&
                data['predictions'] is List) {
              final predictions = data['predictions'] as List;
              final legacyResults = predictions.map((p) {
                final structured = p['structured_formatting'] ?? {};
                final mainText =
                    (structured['main_text'] ?? p['description'] ?? '')
                        .toString();
                final secondaryText =
                    (structured['secondary_text'] ?? (isArQuery ? 'قطر' : 'Qatar'))
                        .toString();
                final coords = resolveCoordinates(mainText);
                return LocationSearchResult(
                  placeId: (p['place_id'] ?? '').toString(),
                  mainText: mainText,
                  secondaryText: secondaryText,
                  latitude: coords?.lat,
                  longitude: coords?.lng,
                  googleMapsPlaceUrl: buildPlaceSearchUrl(
                    '$mainText, $secondaryText',
                    lat: coords?.lat,
                    lng: coords?.lng,
                  ),
                );
              }).toList();
              if (legacyResults.isNotEmpty) {
                return _mergeUniqueResults(legacyResults, localMatches);
              }
            }
          }
        } catch (_) {}
      }
    }

    return localMatches;
  }

  /// Instant synchronous bilingual search against [bilingualGeoCatalog].
  static List<LocationSearchResult> searchCatalogSync(
    String query, {
    bool? preferArabic,
  }) {
    final norm = _normalizeSearchToken(query);
    if (norm.isEmpty) return const [];
    final isAr = preferArabic ?? _containsArabic(query);

    final matches = <LocationSearchResult>[];
    for (final entry in bilingualGeoCatalog) {
      final matched = _normalizeSearchToken(entry.nameAr).contains(norm) ||
          _normalizeSearchToken(entry.nameEn).contains(norm) ||
          _normalizeSearchToken(entry.govAr).contains(norm) ||
          _normalizeSearchToken(entry.govEn).contains(norm) ||
          entry.aliases.any((a) => _normalizeSearchToken(a).contains(norm));
      if (matched) {
        final primary = isAr ? entry.nameAr : entry.nameEn;
        final secondary = isAr
            ? '${entry.govAr} · ${entry.nameEn}'
            : '${entry.govEn} · ${entry.nameAr}';
        matches.add(
          LocationSearchResult(
            placeId: 'qa_${entry.id}',
            mainText: primary,
            secondaryText: secondary,
            latitude: entry.lat,
            longitude: entry.lng,
            googleMapsPlaceUrl: buildPlaceSearchUrl(
              entry.nameEn,
              lat: entry.lat,
              lng: entry.lng,
            ),
          ),
        );
      }
    }
    return matches;
  }

  static List<LocationSearchResult> _mergeUniqueResults(
    List<LocationSearchResult> primary,
    List<LocationSearchResult> secondary,
  ) {
    final out = <LocationSearchResult>[...primary];
    for (final candidate in secondary) {
      final candNorm = _normalizeSearchToken(candidate.mainText);
      final candHub = resolveHubEntry(candidate.mainText);
      final exists = out.any((existing) {
        if (_normalizeSearchToken(existing.mainText) == candNorm) return true;
        final exHub = resolveHubEntry(existing.mainText);
        return candHub != null && exHub != null && candHub.id == exHub.id;
      });
      if (!exists) {
        out.add(candidate);
      }
    }
    return out;
  }

  /// Calculates driving route, road-network distance, travel duration, polyline,
  /// and accurate dynamic highway corridor name between [origin] and [destination].
  Future<RouteDetails> getRouteDetails(
    String origin,
    String destination,
  ) async {
    await _ensureRuntimeKeyInitialized();
    final activeKey = apiKey;
    final heuristic = estimateRouteSync(origin, destination);

    if (activeKey.isNotEmpty) {
      // 1. Modern Google Routes API v2 (`computeRoutes`)
      try {
        final routesUri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes',
        );
        final response = await _client
            .post(
              routesUri,
              headers: <String, String>{
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': activeKey,
                'X-Goog-FieldMask':
                    'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.description',
                'X-Goog-Maps-Solution-ID': _solutionAttributionId,
              },
              body: json.encode(<String, dynamic>{
                'origin': heuristic.originLat != null &&
                        heuristic.originLng != null
                    ? <String, dynamic>{
                        'location': <String, dynamic>{
                          'latLng': <String, double>{
                            'latitude': heuristic.originLat!,
                            'longitude': heuristic.originLng!,
                          },
                        },
                      }
                    : <String, dynamic>{
                        'address': _qualifyPlaceQuery(origin),
                      },
                'destination': heuristic.destLat != null &&
                        heuristic.destLng != null
                    ? <String, dynamic>{
                        'location': <String, dynamic>{
                          'latLng': <String, double>{
                            'latitude': heuristic.destLat!,
                            'longitude': heuristic.destLng!,
                          },
                        },
                      }
                    : <String, dynamic>{
                        'address': _qualifyPlaceQuery(destination),
                      },
                'travelMode': 'DRIVE',
                'routingPreference': 'TRAFFIC_AWARE',
                'languageCode': 'ar',
                'units': 'METRIC',
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map &&
              data['routes'] is List &&
              (data['routes'] as List).isNotEmpty) {
            final route = (data['routes'] as List).first as Map;
            final distanceMeters =
                (route['distanceMeters'] as num?)?.toDouble() ??
                    (heuristic.distanceKm * 1000.0);
            final rawDuration = (route['duration'] ?? '').toString();
            final durationSeconds = int.tryParse(
                  rawDuration.replaceAll('s', '').split('.').first,
                ) ??
                (heuristic.durationMinutes * 60);
            final encodedPoly =
                (route['polyline']?['encodedPolyline'] ?? '').toString();
            final decodedPts = encodedPoly.isNotEmpty
                ? decodePolyline(encodedPoly)
                : heuristic.polylinePoints;
            final apiDesc = (route['description'] ?? '').toString().trim();

            return RouteDetails(
              distanceKm: math.max(1.0, (distanceMeters / 1000.0).roundToDouble()),
              durationMinutes: math.max(3, (durationSeconds / 60.0).round()),
              polyline: encodedPoly,
              startAddress: heuristic.startAddress,
              endAddress: heuristic.endAddress,
              originLat: decodedPts.isNotEmpty
                  ? decodedPts.first.lat
                  : heuristic.originLat,
              originLng: decodedPts.isNotEmpty
                  ? decodedPts.first.lng
                  : heuristic.originLng,
              destLat: decodedPts.isNotEmpty
                  ? decodedPts.last.lat
                  : heuristic.destLat,
              destLng: decodedPts.isNotEmpty
                  ? decodedPts.last.lng
                  : heuristic.destLng,
              corridorHighwayAr:
                  apiDesc.isNotEmpty ? apiDesc : heuristic.corridorHighwayAr,
              corridorHighwayEn: heuristic.corridorHighwayEn,
              googleMapsDirectionsUrl: heuristic.googleMapsDirectionsUrl,
              polylinePoints: decodedPts,
            );
          }
        }
      } catch (_) {}

      // 2. Native-only legacy Directions REST fallback (compatibility with MockClient tests)
      if (!kIsWeb) {
        try {
          final uri = Uri.parse(
            'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${Uri.encodeComponent(_qualifyPlaceQuery(origin))}&'
            'destination=${Uri.encodeComponent(_qualifyPlaceQuery(destination))}&'
            'region=qa&'
            'language=ar&'
            'key=$activeKey',
          );
          final response = await _client
              .get(uri)
              .timeout(const Duration(seconds: 4));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data is Map &&
                data['status'] == 'OK' &&
                data['routes'] is List &&
                (data['routes'] as List).isNotEmpty) {
              final route = (data['routes'] as List).first;
              final leg = (route['legs'] as List).first;
              final distanceMeters =
                  (leg['distance']['value'] as num).toDouble();
              final durationSeconds =
                  (leg['duration']['value'] as num).toInt();
              final encodedPoly =
                  (route['overview_polyline']?['points'] ?? '').toString();
              final summary = (route['summary'] ?? '').toString().trim();
              final decodedPts = encodedPoly.isNotEmpty
                  ? decodePolyline(encodedPoly)
                  : heuristic.polylinePoints;

              return RouteDetails(
                distanceKm:
                    math.max(1.0, (distanceMeters / 1000.0).roundToDouble()),
                durationMinutes: math.max(3, (durationSeconds / 60).round()),
                polyline: encodedPoly,
                startAddress:
                    (leg['start_address'] ?? heuristic.startAddress).toString(),
                endAddress:
                    (leg['end_address'] ?? heuristic.endAddress).toString(),
                originLat: heuristic.originLat,
                originLng: heuristic.originLng,
                destLat: heuristic.destLat,
                destLng: heuristic.destLng,
                corridorHighwayAr:
                    summary.isNotEmpty ? summary : heuristic.corridorHighwayAr,
                corridorHighwayEn: heuristic.corridorHighwayEn,
                googleMapsDirectionsUrl: heuristic.googleMapsDirectionsUrl,
                polylinePoints: decodedPts,
              );
            }
          }
        } catch (_) {}
      }
    }

    return heuristic;
  }

  /// Reverse geocodes coordinates to a readable Qatari/GCC address.
  Future<String> reverseGeocode(double latitude, double longitude) async {
    await _ensureRuntimeKeyInitialized();
    final activeKey = apiKey;

    if (activeKey.isNotEmpty && !kIsWeb) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=$latitude,$longitude&'
          'language=ar&'
          'key=$activeKey',
        );
        final response = await _client
            .get(uri)
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map &&
              data['status'] == 'OK' &&
              data['results'] is List &&
              (data['results'] as List).isNotEmpty) {
            return (data['results'][0]['formatted_address'] ?? 'قطر')
                .toString();
          }
        }
      } catch (_) {}
    }

    return _findNearestHubLabel(latitude, longitude);
  }

  /// Great-circle Haversine distance in kilometers between two WGS84 points.
  static double haversineDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Synchronous, deterministic Haversine road-network route estimator with
  /// dynamic Qatar/GCC highway corridor classification.
  static RouteDetails estimateRouteSync(String origin, String destination) {
    final origEntry = resolveHubEntry(origin);
    final destEntry = resolveHubEntry(destination);

    final corridor = resolveCorridorHighway(
      origin: origin,
      destination: destination,
      origEntry: origEntry,
      destEntry: destEntry,
    );
    final directionsUrl = buildDirectionsUrl(origin, destination);

    if (origEntry != null && destEntry != null) {
      if (origEntry.id == destEntry.id) {
        // Intra-district / local neighborhood errand
        const localDist = 6.0;
        const localMins = 12;
        return RouteDetails(
          distanceKm: localDist,
          durationMinutes: localMins,
          polyline: '',
          startAddress: origEntry.govAr,
          endAddress: destEntry.govAr,
          originLat: origEntry.lat,
          originLng: origEntry.lng,
          destLat: destEntry.lat,
          destLng: destEntry.lng,
          corridorHighwayAr: corridor.ar,
          corridorHighwayEn: corridor.en,
          googleMapsDirectionsUrl: directionsUrl,
          polylinePoints: [
            (lat: origEntry.lat, lng: origEntry.lng),
            (lat: destEntry.lat + 0.008, lng: destEntry.lng + 0.006),
          ],
        );
      }

      final straightKm = haversineDistanceKm(
        origEntry.lat,
        origEntry.lng,
        destEntry.lat,
        destEntry.lng,
      );

      final double roadFactor;
      final double avgSpeedKmh;
      final int accessBufferMins;

      if (straightKm < 8.0) {
        roadFactor = 1.28;
        avgSpeedKmh = 50.0;
        accessBufferMins = 5;
      } else if (straightKm < 28.0) {
        roadFactor = 1.20;
        avgSpeedKmh = 74.0;
        accessBufferMins = 5;
      } else if (straightKm <= 130.0) {
        roadFactor = 1.17;
        avgSpeedKmh = 94.0;
        accessBufferMins = 6;
      } else {
        // GCC cross-border expressway
        roadFactor = 1.18;
        avgSpeedKmh = 104.0;
        accessBufferMins = 20;
      }

      final roadKm = math.max(4.0, (straightKm * roadFactor).roundToDouble());
      final travelMins =
          math.max(8, ((roadKm / avgSpeedKmh) * 60.0).round() + accessBufferMins);

      return RouteDetails(
        distanceKm: roadKm,
        durationMinutes: travelMins,
        polyline: '',
        startAddress: origEntry.govAr,
        endAddress: destEntry.govAr,
        originLat: origEntry.lat,
        originLng: origEntry.lng,
        destLat: destEntry.lat,
        destLng: destEntry.lng,
        corridorHighwayAr: corridor.ar,
        corridorHighwayEn: corridor.en,
        googleMapsDirectionsUrl: directionsUrl,
        polylinePoints: _buildCurvedPolylinePoints(
          origEntry.lat,
          origEntry.lng,
          destEntry.lat,
          destEntry.lng,
        ),
      );
    }

    // Fallback when one or both locations are custom free-text spots
    final known = origEntry ?? destEntry;
    return RouteDetails(
      distanceKm: 24.0,
      durationMinutes: 26,
      polyline: '',
      startAddress: origEntry?.govAr ?? (origin.trim().isEmpty ? 'الدوحة' : origin.trim()),
      endAddress:
          destEntry?.govAr ?? (destination.trim().isEmpty ? 'لوسيل' : destination.trim()),
      originLat: origEntry?.lat ?? known?.lat ?? 25.2854,
      originLng: origEntry?.lng ?? known?.lng ?? 51.5310,
      destLat: destEntry?.lat ?? 25.4357,
      destLng: destEntry?.lng ?? 51.4910,
      corridorHighwayAr: corridor.ar,
      corridorHighwayEn: corridor.en,
      googleMapsDirectionsUrl: directionsUrl,
      polylinePoints: _buildCurvedPolylinePoints(
        origEntry?.lat ?? 25.2854,
        origEntry?.lng ?? 51.5310,
        destEntry?.lat ?? 25.4357,
        destEntry?.lng ?? 51.4910,
      ),
    );
  }

  /// Dynamically selects the real expressway/corridor connecting [origin] and [destination].
  static ({String ar, String en}) resolveCorridorHighway({
    required String origin,
    required String destination,
    MashwarGeoHubEntry? origEntry,
    MashwarGeoHubEntry? destEntry,
  }) {
    final a = origEntry ?? resolveHubEntry(origin);
    final b = destEntry ?? resolveHubEntry(destination);
    final zones = <String>{if (a != null) a.zoneCode, if (b != null) b.zoneCode};
    final ids = <String>{if (a != null) a.id, if (b != null) b.id};

    // 1. GCC Cross-border / Abu Samra / Salwa International Highway
    if (zones.contains('gcc') || ids.contains('abu_samra')) {
      return (
        ar: 'طريق سلوى الدولي (طريق Q5 - معبر أبو سمرة)',
        en: 'Salwa International Highway (Route Q5)',
      );
    }

    // 2. Western Corridor (Dukhan / Al Shahaniya)
    if (zones.contains('west')) {
      return (
        ar: 'طريق دخان السريع (طريق Q3)',
        en: 'Dukhan Highway (Route Q3)',
      );
    }

    // 3. Northern Coastal Corridor (Al Khor / Ras Laffan / Al Thakhira)
    if (zones.contains('north_coast')) {
      if (zones.contains('industrial') || zones.contains('south')) {
        return (
          ar: 'طريق المجد المداري / طريق الخور الساحلي',
          en: 'Al Majd Orbital Hwy / Al Khor Coastal Rd',
        );
      }
      return (
        ar: 'طريق الخور الساحلي / طريق الشمال (طريق 1)',
        en: 'Al Khor Coastal Rd / Al Shamal Hwy (Route 1)',
      );
    }

    // 4. Far North Corridor (Al Shamal / Al Ruwais / Umm Salal / Al Daayen)
    if (zones.contains('north')) {
      return (
        ar: 'طريق الشمال السريع (طريق Q1)',
        en: 'Al Shamal Highway (Route Q1)',
      );
    }

    // 5. Southern Corridor (Al Wakrah / Mesaieed / Hamad Port / Sealine)
    if (zones.contains('south')) {
      if (zones.contains('industrial') || zones.contains('salwa')) {
        return (
          ar: 'طريق المجد المداري / محور الوكرة ومسيعيد',
          en: 'Al Majd Orbital / Al Wakrah Expressway',
        );
      }
      return (
        ar: 'طريق الوكرة ومسيعيد السريع (طريق Q6)',
        en: 'Al Wakrah & Mesaieed Expressway (Route Q6)',
      );
    }

    // 6. Industrial Area & Salwa Road Logistics Corridor
    if (zones.contains('industrial') || zones.contains('salwa')) {
      if (zones.contains('lusail')) {
        return (
          ar: 'طريق الدوحة السريع / محور سلوى والمداري',
          en: 'Doha Expressway / Salwa & Orbital Corridor',
        );
      }
      return (
        ar: 'طريق سلوى / محور المنطقة الصناعية',
        en: 'Salwa Road / Industrial Area Expressway',
      );
    }

    // 7. Hamad International Airport Corridor
    if (zones.contains('airport')) {
      return (
        ar: 'محور صباح الأحمد / طريق مطار حمد الدولي',
        en: 'Sabah Al Ahmad Corridor / HIA Expressway',
      );
    }

    // 8. Lusail / The Pearl / Katara <-> Central Doha
    if (zones.contains('lusail')) {
      return (
        ar: 'طريق لوسيل السريع / محور الكورنيش',
        en: 'Lusail Expressway / Corniche Corridor',
      );
    }

    // 9. Al Rayyan / Education City / Al Gharafa
    if (zones.contains('rayyan')) {
      return (
        ar: 'طريق الريان السريع / محور خليفة أفينيو',
        en: 'Al Rayyan Expressway / Khalifa Avenue',
      );
    }

    // 10. Central Doha Urban Arterial
    return (
      ar: 'طريق الدوحة السريع (محور 22 فبراير)',
      en: 'Doha Expressway (22 February Corridor)',
    );
  }

  static List<({double lat, double lng})> _buildCurvedPolylinePoints(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const int segments = 6;
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    final pts = <({double lat, double lng})>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final arch = math.sin(t * math.pi) * 0.06;
      pts.add((
        lat: lat1 + dLat * t + (-dLng * arch),
        lng: lng1 + dLng * t + (dLat * arch),
      ));
    }
    return pts;
  }

  /// Decodes a Google Maps encoded polyline string into WGS84 coordinate pairs.
  static List<({double lat, double lng})> decodePolyline(String encoded) {
    if (encoded.isEmpty) return const [];
    final points = <({double lat, double lng})>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        if (index >= len) return points;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        if (index >= len) return points;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add((lat: lat / 1e5, lng: lng / 1e5));
    }
    return points;
  }

  static String _findNearestHubLabel(double lat, double lng) {
    MashwarGeoHubEntry best = bilingualGeoCatalog.first;
    double bestDist = double.infinity;

    for (final entry in bilingualGeoCatalog) {
      final dist = haversineDistanceKm(lat, lng, entry.lat, entry.lng);
      if (dist < bestDist) {
        bestDist = dist;
        best = entry;
      }
    }
    return '${best.nameAr} (${best.govAr})';
  }
}
