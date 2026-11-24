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
  // MVP Phase 1 Feature Flags (Qatar Worksite Supply Pilot)
  // ---------------------------------------------------------------------------

  /// Core MVP workflow: B2B/site hardware & supply errands in Qatar (QAR).
  static const bool enableWorksiteSupply = true;

  /// Deferred pending Qatar Ministry of Transport (MoT) passenger licensing.
  static const bool enablePassengerRides = false;

  /// Deferred pending Qatar MoT regulatory approval.
  static const bool enableCarpooling = false;

  /// Deferred pending commercial transport/cargo licensing.
  static const bool enableCommercialCargo = false;

  /// Deferred pending Qatar Central Bank (QCB) PSP / stored-value compliance.
  static const bool enableDigitalWallet = false;

  /// Deferred pending QCB-compliant payment custody & PSP escrow integration.
  static const bool enableEscrowClaims = false;

  // ---------------------------------------------------------------------------
  // Legal, Regulatory & Scope Disclaimers
  // ---------------------------------------------------------------------------

  static const String pilotCountryCode = 'QA';
  static const String pilotCurrencyCode = 'QAR';

  static const String pilotScopeDisclaimerEn =
      'Pilot Scope: MASHWAR MVP Phase 1 supports Qatar worksite supply and '
      'material delivery coordination priced in QAR using Cash on Delivery or '
      'manual bank transfer tracking only.';

  static const String pilotScopeDisclaimerAr =
      'نطاق المرحلة التجريبية: يدعم إصدار MVP الأول من مشوار تنسيق توريد '
      'ومستلزمات مواقع العمل داخل دولة قطر بالريال القطري (QAR) عبر الدفع عند '
      'الاستلام أو التحويل البنكي اليدوي الموثق فقط.';

  static const String passengerTransportNoticeEn =
      'Regulatory Prerequisite: Passenger rides, carpooling, and commercial '
      'cargo features remain disabled until applicable Qatar Ministry of '
      'Transport (MoT) licensing is obtained.';

  static const String passengerTransportNoticeAr =
      'متطلب تنظيمي: تظل خدمات نقل الركاب والتشارك والشحن التجاري معطّلة إلى '
      'حين استكمال التراخيص النظامية المطلوبة من وزارة المواصلات في قطر.';

  static const String paymentsEscrowNoticeEn =
      'Payment & Custody Prerequisite: In-app digital wallet custody, online '
      'card/PSP processing, and regulated escrow claims remain disabled pending '
      'Qatar Central Bank (QCB) payment compliance and licensed PSP onboarding.';

  static const String paymentsEscrowNoticeAr =
      'متطلب مالي: تظل المحفظة الرقمية وبوابات الدفع الإلكتروني وحفظ مبالغ '
      'الضمان المالي معطّلة إلى حين استكمال متطلبات مصرف قطر المركزي والتعاقد '
      'مع مزود دفع مرخص.';

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
