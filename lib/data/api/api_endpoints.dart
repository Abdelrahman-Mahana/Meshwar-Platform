/// Central REST API endpoints & configuration for MASHWAR Backend Integration.
/// Ready to connect to Node.js / NestJS / Laravel / Go / FastAPI backend.
class ApiEndpoints {
  /// Base URL configured via `--dart-define=API_BASE_URL=...` or defaults to local/staging server.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.mashwar.eg/api/v1',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://api.mashwar.eg/ws',
  );

  // 1. Auth & Identity Verification
  static const String sendPhoneOtp = '/auth/otp/phone/send';
  static const String sendEmailOtp = '/auth/otp/email/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String refreshToken = '/auth/token/refresh';
  static const String logout = '/auth/logout';
  static const String userProfile = '/users/me';
  static const String submitNationalId = '/users/me/verification/national-id';
  static const String emergencyContacts = '/users/me/emergency-contacts';
  static const String deleteAccount = '/users/me/delete';

  // 2. Rides & Search
  static const String searchRides = '/rides/search';
  static const String publishRide = '/rides';
  static String rideDetails(String rideId) => '/rides/$rideId';
  static String rescheduleRide(String rideId) => '/rides/$rideId/reschedule';
  static String cancelRide(String rideId) => '/rides/$rideId/cancel';
  static const String myDriverRides = '/driver/rides';
  static String driverRideRequests(String rideId) => '/driver/rides/$rideId/requests';
  static String respondRideRequest(String rideId, String requestId) =>
      '/driver/rides/$rideId/requests/$requestId';

  // 3. Bookings & Active Trips
  static const String bookings = '/bookings';
  static String bookingDetails(String bookingId) => '/bookings/$bookingId';
  static String cancelBooking(String bookingId) => '/bookings/$bookingId/cancel';
  static String rateTrip(String tripId) => '/trips/$tripId/rating';
  static String shareLiveTrip(String tripId) => '/trips/$tripId/share-link';
  static String reportSafetyIssue(String tripId) => '/trips/$tripId/safety-report';
  static const String triggerSos = '/safety/sos';

  // 4. Crowd-Shipping (Parcels)
  static const String parcels = '/parcels';
  static String parcelDetails(String parcelId) => '/parcels/$parcelId';
  static String verifyParcelPickupOtp(String parcelId) => '/parcels/$parcelId/verify-pickup-otp';
  static String verifyParcelDeliveryOtp(String parcelId) => '/parcels/$parcelId/verify-delivery-otp';
  static String parcelDispute(String parcelId) => '/parcels/$parcelId/disputes';

  // 5. Community Board (إعلانات المشاوير والطرود)
  static const String boardAds = '/board/ads';
  static const String myBoardAds = '/board/ads/mine';
  static String makeBoardOffer(String adId) => '/board/ads/$adId/offers';
  static String boardAdOffers(String adId) => '/board/ads/$adId/offers';

  // 6. Route Alerts
  static const String routeAlerts = '/alerts/routes';
  static String routeAlertItem(String alertId) => '/alerts/routes/$alertId';

  // 7. Wallet & Payments (Vodafone Cash / InstaPay / Fawry / Cards)
  static const String walletOverview = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletDeposit = '/wallet/deposit';
  static const String walletWithdraw = '/wallet/withdraw';

  // 8. Driver Onboarding & Vehicle Registration
  static const String driverOnboardingStatus = '/driver/onboarding/status';
  static const String driverVehicles = '/driver/vehicles';
  static const String driverEarnings = '/driver/earnings';

  // 9. Admin Portal Endpoints
  static const String adminKpiStats = '/admin/kpis';
  static const String adminDriverVerifications = '/admin/verifications/drivers';
  static const String adminUsers = '/admin/users';
  static const String adminOperations = '/admin/operations';
  static const String adminDisputes = '/admin/disputes';
  static const String adminSettings = '/admin/settings';
  static const String adminStaff = '/admin/staff';
  static const String adminAuditLogs = '/admin/audit-logs';
}
