/// Environment & MVP Feature Configuration for MASHWAR Qatar Pilot.
///
/// Controlled via compile-time `--dart-define` values:
/// - `APP_ENV=development|staging|production` (default: `development`)
/// - `USE_FIREBASE=true|false` (default: `false`)
/// - `USE_DEV_MOCKS=true|false` (default: `false`, ONLY permitted when
///   `APP_ENV == 'development'` and `!USE_FIREBASE`)
enum AppFlavor {
  development,
  staging,
  production,
}

/// Immutable snapshot of resolved runtime environment configuration.
class AppEnvironmentConfig {
  final AppFlavor flavor;
  final bool useFirebase;
  final bool useDevMocks;
  final String firebaseProjectId;
  final String firebaseRegion;
  final String googleMapsApiKey;

  const AppEnvironmentConfig._({
    required this.flavor,
    required this.useFirebase,
    required this.useDevMocks,
    required this.firebaseProjectId,
    required this.firebaseRegion,
    required this.googleMapsApiKey,
  });

  /// Resolves an [AppEnvironmentConfig] while strictly enforcing that dev mocks
  /// can NEVER be activated in `staging`, `production`, or when `useFirebase`
  /// is enabled.
  factory AppEnvironmentConfig.resolve({
    String rawAppEnv = 'development',
    bool useFirebase = false,
    bool requestedDevMocks = false,
    String firebaseProjectId = AppEnvironment.defaultFirebaseProjectId,
    String firebaseRegion = AppEnvironment.defaultFirebaseRegion,
    String googleMapsApiKey = '',
  }) {
    final parsedFlavor = AppEnvironment.parseFlavor(rawAppEnv);
    final resolvedMocks = AppEnvironment.resolveUseDevMocks(
      flavor: parsedFlavor,
      useFirebase: useFirebase,
      requestedDevMocks: requestedDevMocks,
    );
    return AppEnvironmentConfig._(
      flavor: parsedFlavor,
      useFirebase: useFirebase,
      useDevMocks: resolvedMocks,
      firebaseProjectId: firebaseProjectId,
      firebaseRegion: firebaseRegion,
      googleMapsApiKey: googleMapsApiKey,
    );
  }

  bool get isDevelopment => flavor == AppFlavor.development;
  bool get isStaging => flavor == AppFlavor.staging;
  bool get isProduction => flavor == AppFlavor.production;
}

class AppEnvironment {
  AppEnvironment._();

  static const String defaultFirebaseProjectId = 'mashwar-qatar-2026-ec99d';
  static const String defaultFirebaseRegion = 'europe-west1';

  static const String rawAppEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const bool useFirebase = bool.fromEnvironment(
    'USE_FIREBASE',
    defaultValue: false,
  );

  static const bool hasExplicitUseFirebase = bool.hasEnvironment(
    'USE_FIREBASE',
  );

  static bool _runtimeFirebaseActive = false;

  static bool get isFirebaseRuntimeActive =>
      useFirebase || _runtimeFirebaseActive;

  static void setFirebaseRuntimeActive(bool active) {
    _runtimeFirebaseActive = active;
  }

  static const bool rawUseDevMocks = bool.fromEnvironment(
    'USE_DEV_MOCKS',
    defaultValue: false,
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: defaultFirebaseProjectId,
  );

  static const String firebaseRegion = String.fromEnvironment(
    'FIREBASE_REGION',
    defaultValue: defaultFirebaseRegion,
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// Active flavor parsed from `--dart-define=APP_ENV`.
  static AppFlavor get flavor => parseFlavor(rawAppEnv);

  /// Whether local/dev mock shortcuts are permitted and active.
  ///
  /// Returns `true` ONLY when `APP_ENV == 'development'`, `!useFirebase`,
  /// and `USE_DEV_MOCKS == true`. Always returns `false` in staging/production
  /// or whenever Firebase is enabled.
  static bool get useDevMocks => resolveUseDevMocks(
        flavor: flavor,
        useFirebase: isFirebaseRuntimeActive,
        requestedDevMocks: rawUseDevMocks,
      );

  static AppEnvironmentConfig get current => AppEnvironmentConfig.resolve(
        rawAppEnv: rawAppEnv,
        useFirebase: useFirebase,
        requestedDevMocks: rawUseDevMocks,
        firebaseProjectId: firebaseProjectId,
        firebaseRegion: firebaseRegion,
        googleMapsApiKey: googleMapsApiKey,
      );

  /// Parses an environment name (`development`, `staging`, `production`).
  /// When [strict] is `true`, unknown values throw [ArgumentError].
  static AppFlavor parseFlavor(String raw, {bool strict = false}) {
    switch (raw.trim().toLowerCase()) {
      case 'development':
      case 'dev':
        return AppFlavor.development;
      case 'staging':
      case 'stage':
        return AppFlavor.staging;
      case 'production':
      case 'prod':
        return AppFlavor.production;
      default:
        if (strict) {
          throw ArgumentError.value(
            raw,
            'APP_ENV',
            'Expected one of: development, staging, production',
          );
        }
        return AppFlavor.development;
    }
  }

  /// Returns `true` only when dev mocks are permitted for the given configuration.
  static bool isDevMocksAllowed({
    required AppFlavor flavor,
    required bool useFirebase,
  }) {
    return flavor == AppFlavor.development && !useFirebase;
  }

  /// Enforces `USE_DEV_MOCKS` boundary: allowed ONLY in `development` with `!useFirebase`.
  static bool resolveUseDevMocks({
    required AppFlavor flavor,
    required bool useFirebase,
    required bool requestedDevMocks,
  }) {
    if (!requestedDevMocks) return false;
    return isDevMocksAllowed(flavor: flavor, useFirebase: useFirebase);
  }

  // ---------------------------------------------------------------------------
  // MASHWAR International 3-Service Platform Feature Flags
  // ---------------------------------------------------------------------------

  /// Pillar 3: Smart Supply, Errands & Worksite Fulfillment.
  static const bool enableWorksiteSupply = true;

  /// Pillar 1: Shared Trips & Empty Seats along active corridors.
  static const bool enablePassengerRides = true;

  /// Pillar 1 & 2: Bidirectional Carpooling & Parcels Along the Route.
  static const bool enableCarpooling = true;

  /// Heavy commercial freight fleet dispatch remains gated separately.
  static const bool enableCommercialCargo = false;

  /// Stored-value wallet custody remains disabled in favor of direct settlement.
  static const bool enableDigitalWallet = false;

  /// Automated PSP escrow custody remains disabled (Cash / Manual Transfer + OTP).
  static const bool enableEscrowClaims = false;

  // ---------------------------------------------------------------------------
  // Platform Scope, Settlement & Legal Notices
  // ---------------------------------------------------------------------------

  static const String pilotCountryCode = 'QA';
  static const String pilotCurrencyCode = 'QAR';

  static const String pilotScopeDisclaimerEn =
      'Platform Scope: MASHWAR is an international 3-service mobility, parcel, '
      'and fulfillment platform uniting Shared Trips & Empty Seats, Parcels '
      'Along the Route, and Smart Supply & Errands with Cash on Delivery, '
      'verified manual transfer proof, and Handover OTP confirmation.';

  static const String pilotScopeDisclaimerAr =
      'نطاق المنصة: مشوار منصة عالمية ثلاثية الخدمات تجمع الرحلات المشتركة '
      'والمقاعد الشاغرة، والطرود على الطريق، والتوريد والمهام الذكية عبر الدفع '
      'النقدي عند التسليم أو التحويل البنكي اليدوي الموثق وتأكيد الاستلام برمز الأمان OTP.';

  static const String passengerTransportNoticeEn =
      'Shared Mobility & Route Parcels: Trips and on-route parcel deliveries '
      'connect independent community travelers heading along the same corridor '
      'with transparent seat/parcel pricing and dual OTP handover verification.';

  static const String passengerTransportNoticeAr =
      'التنقل التشاركي والطرود على المسار: تربط المنصة المسافرين المستقلين '
      'المتجهين على نفس الخط لمشاركة المقاعد الشاغرة أو توصيل الطرود الخفيفة '
      'بتسعير واضح وتأكيد استلام وتسليم عبر رمز التحقق الرقمي OTP.';

  static const String paymentsEscrowNoticeEn =
      'Direct Settlement Notice: Settlements use Cash on Handover or verified '
      'manual transfer receipts without stored-value wallet custody; invoice '
      'photos and OTP codes protect both parties at handover.';

  static const String paymentsEscrowNoticeAr =
      'تنويه التسوية المالية: تتم التسويات مباشرة نقداً عند التسليم أو عبر إرفاق '
      'إيصال التحويل البنكي اليدوي دون احتجاز محفظة رقمية؛ وتوثّق الفواتير ورموز '
      'التسليم OTP حقوق الطرفين.';

  static const String trademarkNoticeEn =
      'Trademark Notice: MASHWAR / مشوار brand registration and third-party '
      'mark checks are separate legal prerequisites. Referenced institutions or '
      'payment networks remain property of their respective owners with no '
      'implied endorsement or partnership.';

  static const String trademarkNoticeAr =
      'تنويه العلامات التجارية: إجراءات تسجيل العلامة التجارية «مشوار / MASHWAR» '
      'وفحص العلامات التجارية متطلبات قانونية مستقلة، وأي جهات أو شبكات دفع '
      'مُشار إليها تعود ملكيتها لأصحابها دون أي شراكة أو اعتماد ضمني غير مصرّح به.';

  static String pilotScopeDisclaimer({required bool isArabic}) =>
      isArabic ? pilotScopeDisclaimerAr : pilotScopeDisclaimerEn;

  static String passengerTransportNotice({required bool isArabic}) =>
      isArabic ? passengerTransportNoticeAr : passengerTransportNoticeEn;

  static String paymentsEscrowNotice({required bool isArabic}) =>
      isArabic ? paymentsEscrowNoticeAr : paymentsEscrowNoticeEn;

  static String trademarkNotice({required bool isArabic}) =>
      isArabic ? trademarkNoticeAr : trademarkNoticeEn;

  static List<String> allLegalDisclaimers({required bool isArabic}) => [
        pilotScopeDisclaimer(isArabic: isArabic),
        passengerTransportNotice(isArabic: isArabic),
        paymentsEscrowNotice(isArabic: isArabic),
        trademarkNotice(isArabic: isArabic),
      ];
}
