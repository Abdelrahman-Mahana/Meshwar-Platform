/// Firestore Database Schema Constants & Document Path Registry.
/// Centralizes collection naming, nested subcollections, and schema references.
class FirestoreCollections {
  static const String users = 'users';
  static const String rides = 'rides';
  static const String boardAds = 'board_ads';
  static const String boardOffers = 'offers'; // subcollection of board_ads
  static const String parcels = 'parcels';
  static const String bookings = 'bookings';
  static const String conversations = 'conversations';
  static const String messages = 'messages'; // subcollection of conversations
  static const String routeAlerts = 'route_alerts';
  static const String walletTransactions = 'wallet_transactions';
  static const String driverVerifications = 'driver_verifications';
  static const String adminAuditLogs = 'admin_audit_logs';
  static const String platformConfig = 'platform_config';
  static const String serviceCatalog = 'service_catalog';
  static const String corridors = 'corridors';
  static const String escrowHolds = 'escrow_holds';
  static const String disputes = 'disputes';
  static const String featureFlags = 'feature_flags';
  static const String adminStaff = 'admin_staff';
  static const String investorInquiries = 'investor_inquiries';

  /// Path to a specific user's document
  static String userDoc(String userId) => '$users/$userId';

  /// Path to a specific ride's document
  static String rideDoc(String rideId) => '$rides/$rideId';

  /// Path to an ad's offers subcollection
  static String adOffers(String adId) => '$boardAds/$adId/$boardOffers';

  /// Path to a conversation's messages subcollection
  static String conversationMessages(String conversationId) =>
      '$conversations/$conversationId/$messages';
}

/// Firebase & REST API Gateway Configuration
class FirebaseConfig {
  /// Check whether the app is currently in Firebase-connected mode or Local-Offline mode
  static const bool useFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: false);

  /// Target Firestore Project ID
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'mashwar-qatar-2026-ec99d',
  );

  /// Target Firebase Region
  static const String region = String.fromEnvironment(
    'FIREBASE_REGION',
    defaultValue: 'europe-west1',
  );
}
