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

  @override
  Future<bool> savePlatformSnapshot(Map<String, dynamic> snapshot) async {
    await _localFallback.savePlatformSnapshot(snapshot);
    try {
      await _globalSnapshotDoc.set({
        ...snapshot,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      await _firestore.collection(FirestoreCollections.adminAuditLogs).add({
        ...event,
        'serverTimestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
