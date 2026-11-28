import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_environment.dart';
import '../data/mock_data.dart';
import '../data/models/ride_model.dart';
import '../data/models/route_alert_model.dart';
import '../data/services/firebase_firestore_service.dart';
import '../data/services/qatar_city_matcher.dart';
import 'rides_provider.dart';

class AlertsProvider extends ChangeNotifier {
  static const String _storageKey = 'mashwar_route_alerts_v1';
  static final Map<String, List<Map<String, dynamic>>> _sessionPersistedByKey =
      <String, List<Map<String, dynamic>>>{};

  static bool get _isLiveBackendMode =>
      AppEnvironment.isFirebaseRuntimeActive ||
      AppEnvironment.flavor != AppFlavor.development;

  static Future<SharedPreferences?> _getPrefsSafely() async {
    try {
      final isWidgetTest =
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
      if (isWidgetTest) {
        return await SharedPreferences.getInstance();
      }
      return await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 120));
    } catch (_) {
      return null;
    }
  }

  String? _boundUserId;
  final List<RouteAlertModel> _alerts = <RouteAlertModel>[];
  bool _hasLocalMutations = false;
  bool _disposed = false;
  int _seq = 0;

  AlertsProvider({String? initialUserId})
      : _boundUserId =
            (initialUserId != null && initialUserId.trim().isNotEmpty)
                ? initialUserId.trim()
                : null {
    if (!_isLiveBackendMode) {
      final cached = _sessionPersistedByKey[_effectiveStorageKey];
      if (cached != null) {
        _alerts.addAll(cached.map(RouteAlertModel.fromJson));
      } else {
        _alerts.addAll(MockData.initialAlerts);
      }
    }
    unawaited(loadAlerts());
  }

  String? get _effectiveUid {
    final bound = _boundUserId?.trim();
    if (bound != null && bound.isNotEmpty) return bound;
    return _resolveCurrentAuthUid();
  }

  String get _effectiveStorageKey {
    final uid = _effectiveUid;
    return (uid != null && uid.isNotEmpty) ? '${_storageKey}_$uid' : _storageKey;
  }

  /// Syncs active user identity from [AuthProvider], clearing any previous
  /// account's alerts and reloading user-scoped alerts when signed in.
  void syncAuthSession({required String? uid}) {
    final clean = uid?.trim();
    final normalizedNext =
        (clean != null && clean.isNotEmpty) ? clean : null;
    final previousUid = _boundUserId;
    _boundUserId = normalizedNext;

    final uidChanged = previousUid != normalizedNext;
    final shouldClearOnNull = normalizedNext == null &&
        (_isLiveBackendMode || uidChanged) &&
        _alerts.isNotEmpty;

    if (uidChanged || shouldClearOnNull) {
      _hasLocalMutations = false;
      _alerts.clear();
      if (!_isLiveBackendMode) {
        final cached = _sessionPersistedByKey[_effectiveStorageKey];
        if (cached != null) {
          _alerts.addAll(cached.map(RouteAlertModel.fromJson));
        } else if (normalizedNext != null) {
          _alerts.addAll(MockData.initialAlerts);
        }
      }
      _safeNotify();
      if (normalizedNext != null) {
        unawaited(loadAlerts());
      }
    }
  }

  List<RouteAlertModel> get alerts => List<RouteAlertModel>.unmodifiable(_alerts);

  int get activeAlertsCount =>
      _alerts.where((a) => a.isActive && !a.isExpired).length;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  String? _resolveCurrentAuthUid() {
    if (!AppEnvironment.isFirebaseRuntimeActive) return null;
    try {
      if (Firebase.apps.isEmpty) return null;
      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      return (uid != null && uid.trim().isNotEmpty) ? uid.trim() : null;
    } catch (_) {
      return null;
    }
  }

  /// Checks whether two city strings refer to the same canonical city/area.
  static bool areCitiesEquivalent(String a, String b) =>
      QatarCityMatcher.areCitiesEquivalent(a, b);

  static bool _matchesCityField(String query, List<String?> candidates) =>
      QatarCityMatcher.matchesCityField(query, candidates);

  /// Returns live active rides matching [alert]'s route and category.
  List<RideModel> matchingRidesForAlert(
    RouteAlertModel alert,
    RidesProvider? ridesProvider,
  ) {
    if (ridesProvider == null) return const <RideModel>[];
    final wantsParcel = alert.category == 'طرد' ||
        alert.category.toLowerCase().contains('parcel');

    return ridesProvider.allRides.where((ride) {
      if (ride.status == 'cancelled' || ride.status == 'completed') {
        return false;
      }
      if (wantsParcel && !ride.acceptsParcels) {
        return false;
      }
      final originOk = _matchesCityField(
        alert.fromCity,
        [ride.fromCity, ride.pickupPoint, ride.stopoverCity],
      );
      if (!originOk) return false;

      final destOk = _matchesCityField(
        alert.toCity,
        [ride.toCity, ride.dropoffPoint, ride.stopoverCity],
      );
      return destOk;
    }).toList();
  }

  /// Computes the live count of matching active rides for [alert].
  int countMatchingRides(
    RouteAlertModel alert,
    RidesProvider? ridesProvider,
  ) {
    return matchingRidesForAlert(alert, ridesProvider).length;
  }

  /// Loads persisted alerts from user-scoped `SharedPreferences` (with 120ms timeout)
  /// and merges any remote `route_alerts` documents when Firebase is active.
  Future<void> loadAlerts() async {
    final expectedUid = _effectiveUid;
    final storageKey = _effectiveStorageKey;

    if (_isLiveBackendMode && (expectedUid == null || expectedUid.isEmpty)) {
      if (_alerts.isNotEmpty) {
        _alerts.clear();
        _safeNotify();
      }
      return;
    }

    List<RouteAlertModel>? storedAlerts;
    try {
      final prefs = await _getPrefsSafely();
      final rawJson = prefs?.getString(storageKey);
      if (rawJson != null && rawJson.trim().isNotEmpty) {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          storedAlerts = decoded
              .whereType<Map>()
              .map(
                (item) => RouteAlertModel.fromJson(
                  item.map((k, v) => MapEntry(k.toString(), v)),
                ),
              )
              .where((a) => a.id.isNotEmpty)
              .toList();
        }
      }
    } catch (_) {
      // Unmocked or unavailable SharedPreferences; keep in-memory alerts.
    }

    if (_disposed || _effectiveUid != expectedUid) return;

    if (storedAlerts != null) {
      if (!_hasLocalMutations) {
        _alerts
          ..clear()
          ..addAll(storedAlerts);
      } else {
        final existingIds = _alerts.map((a) => a.id).toSet();
        for (final saved in storedAlerts) {
          if (!existingIds.contains(saved.id)) {
            _alerts.add(saved);
          }
        }
      }
      _safeNotify();
    } else if (_isLiveBackendMode && !_hasLocalMutations) {
      final cached = _sessionPersistedByKey[storageKey];
      if (cached != null) {
        _alerts
          ..clear()
          ..addAll(cached.map(RouteAlertModel.fromJson));
        _safeNotify();
      }
    }

    final uid = _resolveCurrentAuthUid();
    if (uid == null || _disposed) return;
    if (expectedUid != null && expectedUid != uid) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.routeAlerts)
          .where('userId', isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (_disposed || _effectiveUid != expectedUid) return;

      if (snapshot.docs.isNotEmpty) {
        final byId = <String, RouteAlertModel>{
          for (final a in _alerts) a.id: a,
        };
        for (final doc in snapshot.docs) {
          final parsed = RouteAlertModel.fromJson(
            normalizeFirestoreDocument(doc.data(), fallbackId: doc.id),
          );
          if (parsed.id.isNotEmpty) {
            byId[parsed.id] = parsed;
          }
        }
        _alerts
          ..clear()
          ..addAll(byId.values);
        _safeNotify();
        await _saveToPrefs();
      }
    } catch (_) {
      // Safe fallback if Firestore is offline or rules reject query.
    }
  }

  Future<void> _saveToPrefs() async {
    final uid = _effectiveUid;
    if (_isLiveBackendMode && (uid == null || uid.isEmpty)) {
      return;
    }
    final storageKey = _effectiveStorageKey;
    final serialized = _alerts.map((a) => a.toJson()).toList();
    _sessionPersistedByKey[storageKey] = serialized;
    try {
      final prefs = await _getPrefsSafely();
      if (prefs != null) {
        final encoded = jsonEncode(serialized);
        await prefs.setString(storageKey, encoded);
      }
    } catch (_) {
      // Ignore persistence failures in unmocked test isolates.
    }
  }

  Future<void> _upsertFirestoreAlert(
    RouteAlertModel alert, {
    bool isNew = false,
  }) async {
    final uid = _resolveCurrentAuthUid();
    if (uid == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection(FirestoreCollections.routeAlerts)
          .doc(alert.id);
      await docRef
          .set(
            {
              'id': alert.id,
              'userId': uid,
              'fromCity': alert.fromCity,
              'toCity': alert.toCity,
              'dateRange': alert.dateRange,
              'category': alert.category,
              'isActive': alert.isActive,
              'isExpired': alert.isExpired,
              if (isNew) 'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Safe fallback if offline or rules/auth reject.
    }
  }

  Future<void> _deleteFirestoreAlert(String id) async {
    final uid = _resolveCurrentAuthUid();
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.routeAlerts)
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Safe fallback if offline or rules/auth reject.
    }
  }

  void toggleAlert(String id) {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _hasLocalMutations = true;
      final current = _alerts[index];
      final updated = current.copyWith(isActive: !current.isActive);
      _alerts[index] = updated;
      _safeNotify();
      unawaited(_saveToPrefs());
      unawaited(_upsertFirestoreAlert(updated));
    }
  }

  void deleteAlert(String id) {
    _hasLocalMutations = true;
    _alerts.removeWhere((a) => a.id == id);
    _safeNotify();
    unawaited(_saveToPrefs());
    unawaited(_deleteFirestoreAlert(id));
  }

  bool addAlert({
    required String fromCity,
    required String toCity,
    required String dateRange,
    required String category,
  }) {
    final cleanFrom = fromCity.trim();
    final cleanTo = toCity.trim();
    if (cleanFrom.isEmpty ||
        cleanTo.isEmpty ||
        areCitiesEquivalent(cleanFrom, cleanTo)) {
      return false;
    }

    _hasLocalMutations = true;
    final newAlert = RouteAlertModel(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}_${++_seq}',
      fromCity: cleanFrom,
      toCity: cleanTo,
      dateRange: dateRange.trim().isEmpty ? 'طوال الأسبوع' : dateRange.trim(),
      category: category.trim().isEmpty ? 'ركاب' : category.trim(),
      isActive: true,
      isExpired: false,
    );
    _alerts.insert(0, newAlert);
    _safeNotify();
    unawaited(_saveToPrefs());
    unawaited(_upsertFirestoreAlert(newAlert, isNew: true));
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
