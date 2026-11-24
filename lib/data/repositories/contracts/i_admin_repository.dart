/// Abstract repository contract for MASHWAR Enterprise Admin & DevOps configuration.
/// Supports seamless switching between Local/Mock persistence, REST API, and Cloud Firestore.
abstract class IAdminRepository {
  Future<Map<String, dynamic>?> loadPlatformSnapshot();
  Future<bool> savePlatformSnapshot(Map<String, dynamic> snapshot);
  Future<bool> clearPlatformSnapshot();
  Future<bool> writeAuditEvent(Map<String, dynamic> event);
}
