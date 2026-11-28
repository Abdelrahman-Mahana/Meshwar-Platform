import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../contracts/i_admin_repository.dart';
import '../admin_repository_impl.dart';

/// Production Cloud Firestore implementation of [IAdminRepository].
/// Synchronizes platform configuration, service catalog rules, corridors, feature flags,
/// and immutable audit logs with graceful offline fallback to [AdminRepositoryImpl].
class FirebaseAdminRepository implements IAdminRepository {
  final FirebaseFirestore? _injectedFirestore;
  final AdminRepositoryImpl _localFallback = AdminRepositoryImpl();

  FirebaseAdminRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _globalSnapshotDoc =>
      _firestore.collection(FirestoreCollections.platformConfig).doc('global');

  @override
  Future<Map<String, dynamic>?> loadPlatformSnapshot() async {
    try {
      final doc = await _globalSnapshotDoc.get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (_) {
      // Fallback safely if unauthenticated or offline during startup.
    }
    return _localFallback.loadPlatformSnapshot();
  }

  static String _normalizeBannerType(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'warning':
        return 'warning';
      case 'urgent':
      case 'alert':
        return 'alert';
      case 'promo':
        return 'promo';
      case 'maintenance':
        return 'maintenance';
      default:
        return 'info';
    }
  }

  static String _truncate(String value, int maxLen) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLen) return trimmed;
    return trimmed.substring(0, maxLen);
  }

  @override
  Future<bool> savePlatformSnapshot(Map<String, dynamic> snapshot) async {
    await _localFallback.savePlatformSnapshot(snapshot);
    try {
      final batch = _firestore.batch();

      // 1. Write strictly whitelisted fields to `platform_config/global` (`isValidPlatformConfig`).
      final rawBanner = snapshot['broadcastBanner'];
      final bannerMap =
          rawBanner is Map ? Map<String, dynamic>.from(rawBanner) : null;
      final bannerAr = _truncate(
        (bannerMap?['messageAr'] ?? snapshot['bannerAr'] ?? '').toString(),
        500,
      );
      final bannerEn = _truncate(
        (bannerMap?['messageEn'] ?? snapshot['bannerEn'] ?? '').toString(),
        500,
      );
      final bannerActive = bannerMap?['isEnabled'] as bool? ??
          snapshot['bannerActive'] as bool? ??
          false;
      final bannerType = _normalizeBannerType(
        (bannerMap?['severity'] ?? snapshot['bannerType'] ?? 'info').toString(),
      );
      final broadcastText = bannerEn.isNotEmpty ? bannerEn : bannerAr;

      final thresholds = <String, dynamic>{};
      final rawSettings = snapshot['settings'];
      if (rawSettings is List) {
        for (final item in rawSettings.take(50)) {
          if (item is Map) {
            final key = (item['key'] ?? '').toString().trim();
            if (key.isNotEmpty) {
              thresholds[key] = item['value'];
            }
          }
        }
      }

      bool maintenanceMode = snapshot['maintenanceMode'] as bool? ?? false;
      final rawFlags = snapshot['featureFlags'];
      if (rawFlags is List) {
        for (final item in rawFlags) {
          if (item is Map && item['key'] == 'maintenance_mode') {
            maintenanceMode = item['isEnabled'] as bool? ??
                item['enabled'] as bool? ??
                maintenanceMode;
          }
        }
      }

      final configDoc = <String, dynamic>{
        'id': 'global',
        'key': 'global_platform_config',
        'broadcastBanner': broadcastText,
        'bannerAr': bannerAr,
        'bannerEn': bannerEn,
        'bannerActive': bannerActive,
        'bannerType': bannerType,
        'maintenanceMode': maintenanceMode,
        if (thresholds.isNotEmpty) 'thresholds': thresholds,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(_globalSnapshotDoc, configDoc, SetOptions(merge: true));

      // 2. Write `service_catalog/{id}` docs matching `isValidServiceCatalogItem`.
      final rawServices = snapshot['services'];
      if (rawServices is List) {
        for (var i = 0; i < rawServices.length; i++) {
          final item = rawServices[i];
          if (item is! Map) continue;
          final id = _truncate((item['id'] ?? '').toString(), 128);
          final nameAr = _truncate((item['nameAr'] ?? '').toString(), 100);
          final nameEn = _truncate((item['nameEn'] ?? '').toString(), 100);
          if (id.isEmpty || nameAr.isEmpty || nameEn.isEmpty) continue;

          final code = _truncate((item['code'] ?? '').toString(), 64);
          final iconName = _truncate((item['iconName'] ?? '').toString(), 64);
          final serviceDoc = <String, dynamic>{
            'id': id,
            if (code.isNotEmpty) 'code': code,
            'nameAr': nameAr,
            'nameEn': nameEn,
            'descriptionAr':
                _truncate((item['descriptionAr'] ?? '').toString(), 500),
            'descriptionEn':
                _truncate((item['descriptionEn'] ?? '').toString(), 500),
            if (iconName.isNotEmpty) 'iconName': iconName,
            if (item['minFeeQar'] is num)
              'minPrice': (item['minFeeQar'] as num).clamp(0, 100000),
            if (item['maxFeeQar'] is num)
              'maxPrice': (item['maxFeeQar'] as num).clamp(0, 100000),
            if (item['commissionPct'] is num)
              'commissionPct': (item['commissionPct'] as num).clamp(0, 100),
            if (item['requiresEscrow'] is bool)
              'escrowRequired': item['requiresEscrow'],
            'isActive':
                item['isEnabled'] as bool? ?? item['isActive'] as bool? ?? true,
            'sortOrder': i,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          batch.set(
            _firestore.collection(FirestoreCollections.serviceCatalog).doc(id),
            serviceDoc,
            SetOptions(merge: true),
          );
        }
      }

      // 3. Write `corridors/{id}` docs matching `isValidCorridor`.
      final rawCorridors = snapshot['corridors'];
      if (rawCorridors is List) {
        for (var i = 0; i < rawCorridors.length; i++) {
          final item = rawCorridors[i];
          if (item is! Map) continue;
          final id = _truncate((item['id'] ?? '').toString(), 128);
          final fromCity = _truncate(
            (item['fromCityAr'] ?? item['fromCity'] ?? '').toString(),
            100,
          );
          final toCity = _truncate(
            (item['toCityAr'] ?? item['toCity'] ?? '').toString(),
            100,
          );
          if (id.isEmpty || fromCity.isEmpty || toCity.isEmpty) continue;

          final fromEn = _truncate((item['fromCityEn'] ?? fromCity).toString(), 55);
          final toEn = _truncate((item['toCityEn'] ?? toCity).toString(), 55);
          final gov = _truncate(
            (item['municipalityAr'] ?? item['governorate'] ?? '').toString(),
            60,
          );
          final status = (item['status'] ?? 'active').toString();
          final corridorDoc = <String, dynamic>{
            'id': id,
            'nameAr': _truncate('$fromCity ↔ $toCity', 120),
            'nameEn': _truncate('$fromEn ↔ $toEn', 120),
            'fromCity': fromCity,
            'toCity': toCity,
            if (gov.isNotEmpty) 'governorate': gov,
            if (item['avgEtaMin'] is num)
              'estimatedMinutes': (item['avgEtaMin'] as num).toInt().clamp(0, 2000),
            'isActive': status != 'paused',
            'isPopular': status == 'peak',
            'sortOrder': i,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          batch.set(
            _firestore.collection(FirestoreCollections.corridors).doc(id),
            corridorDoc,
            SetOptions(merge: true),
          );
        }
      }

      // 4. Write `feature_flags/{id}` docs matching `isValidFeatureFlag`.
      if (rawFlags is List) {
        for (final item in rawFlags) {
          if (item is! Map) continue;
          final key = _truncate((item['key'] ?? '').toString(), 100);
          if (key.isEmpty) continue;
          final nameAr = _truncate((item['nameAr'] ?? key).toString(), 100);
          final nameEn = _truncate((item['nameEn'] ?? key).toString(), 100);
          final desc = _truncate(
            (item['descriptionEn'] ?? item['description'] ?? '').toString(),
            500,
          );
          final env = _truncate((item['environment'] ?? 'production').toString(), 40);
          final flagDoc = <String, dynamic>{
            'id': key,
            'key': key,
            if (nameAr.isNotEmpty) 'nameAr': nameAr,
            if (nameEn.isNotEmpty) 'nameEn': nameEn,
            'description': desc,
            'enabled':
                item['isEnabled'] as bool? ?? item['enabled'] as bool? ?? false,
            if (item['rolloutPct'] is num)
              'rolloutPercentage': (item['rolloutPct'] as num).clamp(0, 100),
            if (env.isNotEmpty) 'targetEnvironments': <String>[env],
            'updatedAt': FieldValue.serverTimestamp(),
          };
          batch.set(
            _firestore.collection(FirestoreCollections.featureFlags).doc(key),
            flagDoc,
            SetOptions(merge: true),
          );
        }
      }

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> clearPlatformSnapshot() async {
    await _localFallback.clearPlatformSnapshot();
    try {
      await _globalSnapshotDoc.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> writeAuditEvent(Map<String, dynamic> event) async {
    try {
      final createdAt = (event['createdAt']?.toString().trim().isNotEmpty == true)
          ? event['createdAt']
          : DateTime.now().toUtc().toIso8601String();
      await _firestore.collection(FirestoreCollections.adminAuditLogs).add({
        ...event,
        'createdAt': createdAt,
        'serverTimestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
