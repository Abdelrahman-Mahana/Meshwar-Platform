/// Enterprise domain models for the MASHWAR Future-Proof Admin & DevOps Control Center.
/// Designed for zero-friction persistence across Local/SharedPreferences, REST API, and Cloud Firestore.

class AdminServiceDefinition {
  final String id;
  final String code;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String iconName;
  final int accentHex;
  final bool isEnabled;
  final bool isMaintenance;
  final double commissionPct;
  final int minFeeQar;
  final int maxFeeQar;
  final int maxReceiptCapQar;
  final bool requiresEscrow;
  final bool requiresReceiptPhoto;
  final bool requiresFourDigitOtp;
  final bool allowsLadiesOnly;
  final int slaMinutes;
  final int activeOrdersCount;

  const AdminServiceDefinition({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.iconName,
    required this.accentHex,
    this.isEnabled = true,
    this.isMaintenance = false,
    this.commissionPct = 15.0,
    this.minFeeQar = 15,
    this.maxFeeQar = 450,
    this.maxReceiptCapQar = 1500,
    this.requiresEscrow = true,
    this.requiresReceiptPhoto = false,
    this.requiresFourDigitOtp = true,
    this.allowsLadiesOnly = true,
    this.slaMinutes = 90,
    this.activeOrdersCount = 0,
  });

  AdminServiceDefinition copyWith({
    String? code,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    String? iconName,
    int? accentHex,
    bool? isEnabled,
    bool? isMaintenance,
    double? commissionPct,
    int? minFeeQar,
    int? maxFeeQar,
    int? maxReceiptCapQar,
    bool? requiresEscrow,
    bool? requiresReceiptPhoto,
    bool? requiresFourDigitOtp,
    bool? allowsLadiesOnly,
    int? slaMinutes,
    int? activeOrdersCount,
  }) {
    return AdminServiceDefinition(
      id: id,
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      iconName: iconName ?? this.iconName,
      accentHex: accentHex ?? this.accentHex,
      isEnabled: isEnabled ?? this.isEnabled,
      isMaintenance: isMaintenance ?? this.isMaintenance,
      commissionPct: commissionPct ?? this.commissionPct,
      minFeeQar: minFeeQar ?? this.minFeeQar,
      maxFeeQar: maxFeeQar ?? this.maxFeeQar,
      maxReceiptCapQar: maxReceiptCapQar ?? this.maxReceiptCapQar,
      requiresEscrow: requiresEscrow ?? this.requiresEscrow,
      requiresReceiptPhoto: requiresReceiptPhoto ?? this.requiresReceiptPhoto,
      requiresFourDigitOtp: requiresFourDigitOtp ?? this.requiresFourDigitOtp,
      allowsLadiesOnly: allowsLadiesOnly ?? this.allowsLadiesOnly,
      slaMinutes: slaMinutes ?? this.slaMinutes,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'descriptionAr': descriptionAr,
        'descriptionEn': descriptionEn,
        'iconName': iconName,
        'accentHex': accentHex,
        'isEnabled': isEnabled,
        'isMaintenance': isMaintenance,
        'commissionPct': commissionPct,
        'minFeeQar': minFeeQar,
        'maxFeeQar': maxFeeQar,
        'maxReceiptCapQar': maxReceiptCapQar,
        'requiresEscrow': requiresEscrow,
        'requiresReceiptPhoto': requiresReceiptPhoto,
        'requiresFourDigitOtp': requiresFourDigitOtp,
        'allowsLadiesOnly': allowsLadiesOnly,
        'slaMinutes': slaMinutes,
        'activeOrdersCount': activeOrdersCount,
      };

  factory AdminServiceDefinition.fromJson(Map<String, dynamic> json) {
    return AdminServiceDefinition(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      nameAr: (json['nameAr'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? '').toString(),
      descriptionAr: (json['descriptionAr'] ?? '').toString(),
      descriptionEn: (json['descriptionEn'] ?? '').toString(),
      iconName: (json['iconName'] ?? 'apps').toString(),
      accentHex: (json['accentHex'] as num?)?.toInt() ?? 0xFF0F2A43,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isMaintenance: json['isMaintenance'] as bool? ?? false,
      commissionPct: (json['commissionPct'] as num?)?.toDouble() ?? 15.0,
      minFeeQar: (json['minFeeQar'] as num?)?.toInt() ?? 15,
      maxFeeQar: (json['maxFeeQar'] as num?)?.toInt() ?? 450,
      maxReceiptCapQar: (json['maxReceiptCapQar'] as num?)?.toInt() ?? 1500,
      requiresEscrow: json['requiresEscrow'] as bool? ?? true,
      requiresReceiptPhoto: json['requiresReceiptPhoto'] as bool? ?? false,
      requiresFourDigitOtp: json['requiresFourDigitOtp'] as bool? ?? true,
      allowsLadiesOnly: json['allowsLadiesOnly'] as bool? ?? true,
      slaMinutes: (json['slaMinutes'] as num?)?.toInt() ?? 90,
      activeOrdersCount: (json['activeOrdersCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminCorridorNode {
  final String id;
  final String fromCityAr;
  final String fromCityEn;
  final String toCityAr;
  final String toCityEn;
  final String municipalityAr;
  final String municipalityEn;
  final String status; // 'active', 'peak', 'paused'
  final int activeProviders;
  final int openRequests;
  final double conversionPct;
  final int avgEtaMin;
  final double incentiveMultiplier;
  final double dailyGmvQar;

  const AdminCorridorNode({
    required this.id,
    required this.fromCityAr,
    required this.fromCityEn,
    required this.toCityAr,
    required this.toCityEn,
    required this.municipalityAr,
    required this.municipalityEn,
    this.status = 'active',
    this.activeProviders = 12,
    this.openRequests = 18,
    this.conversionPct = 42.0,
    this.avgEtaMin = 28,
    this.incentiveMultiplier = 1.0,
    this.dailyGmvQar = 1250.0,
  });

  String routeLabel(bool isAr) =>
      isAr ? '$fromCityAr ↔ $toCityAr' : '$fromCityEn ↔ $toCityEn';

  AdminCorridorNode copyWith({
    String? fromCityAr,
    String? fromCityEn,
    String? toCityAr,
    String? toCityEn,
    String? municipalityAr,
    String? municipalityEn,
    String? status,
    int? activeProviders,
    int? openRequests,
    double? conversionPct,
    int? avgEtaMin,
    double? incentiveMultiplier,
    double? dailyGmvQar,
  }) {
    return AdminCorridorNode(
      id: id,
      fromCityAr: fromCityAr ?? this.fromCityAr,
      fromCityEn: fromCityEn ?? this.fromCityEn,
      toCityAr: toCityAr ?? this.toCityAr,
      toCityEn: toCityEn ?? this.toCityEn,
      municipalityAr: municipalityAr ?? this.municipalityAr,
      municipalityEn: municipalityEn ?? this.municipalityEn,
      status: status ?? this.status,
      activeProviders: activeProviders ?? this.activeProviders,
      openRequests: openRequests ?? this.openRequests,
      conversionPct: conversionPct ?? this.conversionPct,
      avgEtaMin: avgEtaMin ?? this.avgEtaMin,
      incentiveMultiplier: incentiveMultiplier ?? this.incentiveMultiplier,
      dailyGmvQar: dailyGmvQar ?? this.dailyGmvQar,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromCityAr': fromCityAr,
        'fromCityEn': fromCityEn,
        'toCityAr': toCityAr,
        'toCityEn': toCityEn,
        'municipalityAr': municipalityAr,
        'municipalityEn': municipalityEn,
        'status': status,
        'activeProviders': activeProviders,
        'openRequests': openRequests,
        'conversionPct': conversionPct,
        'avgEtaMin': avgEtaMin,
        'incentiveMultiplier': incentiveMultiplier,
        'dailyGmvQar': dailyGmvQar,
      };

  factory AdminCorridorNode.fromJson(Map<String, dynamic> json) {
    return AdminCorridorNode(
      id: (json['id'] ?? '').toString(),
      fromCityAr: (json['fromCityAr'] ?? '').toString(),
      fromCityEn: (json['fromCityEn'] ?? '').toString(),
      toCityAr: (json['toCityAr'] ?? '').toString(),
      toCityEn: (json['toCityEn'] ?? '').toString(),
      municipalityAr: (json['municipalityAr'] ?? '').toString(),
      municipalityEn: (json['municipalityEn'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      activeProviders: (json['activeProviders'] as num?)?.toInt() ?? 10,
      openRequests: (json['openRequests'] as num?)?.toInt() ?? 10,
      conversionPct: (json['conversionPct'] as num?)?.toDouble() ?? 40.0,
      avgEtaMin: (json['avgEtaMin'] as num?)?.toInt() ?? 30,
      incentiveMultiplier: (json['incentiveMultiplier'] as num?)?.toDouble() ?? 1.0,
      dailyGmvQar: (json['dailyGmvQar'] as num?)?.toDouble() ?? 1000.0,
    );
  }
}

class AdminEscrowLedgerItem {
  final String id;
  final String serviceCode;
  final String serviceTitleAr;
  final String serviceTitleEn;
  final String requesterName;
  final String providerName;
  final String corridorAr;
  final String corridorEn;
  final double serviceFeeQar;
  final double receiptCapQar;
  final double actualReceiptQar;
  final double platformCommissionQar;
  final String paymentRail; // 'Fawran', 'QPay', 'SkipCash', 'Apple Pay', 'Wallet'
  final bool hasReceiptPhoto;
  final bool receiptApproved;
  final String otpCode;
  final bool otpVerified;
  final String status; // 'held', 'receipt_pending', 'in_transit', 'frozen', 'released', 'refunded'
  final String createdAt;

  const AdminEscrowLedgerItem({
    required this.id,
    required this.serviceCode,
    required this.serviceTitleAr,
    required this.serviceTitleEn,
    required this.requesterName,
    required this.providerName,
    required this.corridorAr,
    required this.corridorEn,
    required this.serviceFeeQar,
    required this.receiptCapQar,
    this.actualReceiptQar = 0.0,
    required this.platformCommissionQar,
    required this.paymentRail,
    this.hasReceiptPhoto = false,
    this.receiptApproved = false,
    required this.otpCode,
    this.otpVerified = false,
    this.status = 'held',
    required this.createdAt,
  });

  double get totalProtectedQar =>
      serviceFeeQar + (actualReceiptQar > 0 ? actualReceiptQar : receiptCapQar);

  AdminEscrowLedgerItem copyWith({
    double? actualReceiptQar,
    bool? hasReceiptPhoto,
    bool? receiptApproved,
    bool? otpVerified,
    String? status,
  }) {
    return AdminEscrowLedgerItem(
      id: id,
      serviceCode: serviceCode,
      serviceTitleAr: serviceTitleAr,
      serviceTitleEn: serviceTitleEn,
      requesterName: requesterName,
      providerName: providerName,
      corridorAr: corridorAr,
      corridorEn: corridorEn,
      serviceFeeQar: serviceFeeQar,
      receiptCapQar: receiptCapQar,
      actualReceiptQar: actualReceiptQar ?? this.actualReceiptQar,
      platformCommissionQar: platformCommissionQar,
      paymentRail: paymentRail,
      hasReceiptPhoto: hasReceiptPhoto ?? this.hasReceiptPhoto,
      receiptApproved: receiptApproved ?? this.receiptApproved,
      otpCode: otpCode,
      otpVerified: otpVerified ?? this.otpVerified,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceCode': serviceCode,
        'serviceTitleAr': serviceTitleAr,
        'serviceTitleEn': serviceTitleEn,
        'requesterName': requesterName,
        'providerName': providerName,
        'corridorAr': corridorAr,
        'corridorEn': corridorEn,
        'serviceFeeQar': serviceFeeQar,
        'receiptCapQar': receiptCapQar,
        'actualReceiptQar': actualReceiptQar,
        'platformCommissionQar': platformCommissionQar,
        'paymentRail': paymentRail,
        'hasReceiptPhoto': hasReceiptPhoto,
        'receiptApproved': receiptApproved,
        'otpCode': otpCode,
        'otpVerified': otpVerified,
        'status': status,
        'createdAt': createdAt,
      };

  factory AdminEscrowLedgerItem.fromJson(Map<String, dynamic> json) {
    return AdminEscrowLedgerItem(
      id: (json['id'] ?? '').toString(),
      serviceCode: (json['serviceCode'] ?? '').toString(),
      serviceTitleAr: (json['serviceTitleAr'] ?? '').toString(),
      serviceTitleEn: (json['serviceTitleEn'] ?? '').toString(),
      requesterName: (json['requesterName'] ?? '').toString(),
      providerName: (json['providerName'] ?? '').toString(),
      corridorAr: (json['corridorAr'] ?? '').toString(),
      corridorEn: (json['corridorEn'] ?? '').toString(),
      serviceFeeQar: (json['serviceFeeQar'] as num?)?.toDouble() ?? 0,
      receiptCapQar: (json['receiptCapQar'] as num?)?.toDouble() ?? 0,
      actualReceiptQar: (json['actualReceiptQar'] as num?)?.toDouble() ?? 0,
      platformCommissionQar:
          (json['platformCommissionQar'] as num?)?.toDouble() ?? 0,
      paymentRail: (json['paymentRail'] ?? 'Fawran').toString(),
      hasReceiptPhoto: json['hasReceiptPhoto'] as bool? ?? false,
      receiptApproved: json['receiptApproved'] as bool? ?? false,
      otpCode: (json['otpCode'] ?? '0000').toString(),
      otpVerified: json['otpVerified'] as bool? ?? false,
      status: (json['status'] ?? 'held').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class AdminPaymentGatewayConfig {
  final String id;
  final String nameAr;
  final String nameEn;
  final bool isEnabled;
  final bool isPrimary;
  final double feePct;
  final String settlementAr;
  final String settlementEn;
  final int latencyMs;
  final double uptimePct;

  const AdminPaymentGatewayConfig({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.isEnabled = true,
    this.isPrimary = false,
    required this.feePct,
    required this.settlementAr,
    required this.settlementEn,
    this.latencyMs = 110,
    this.uptimePct = 99.95,
  });

  AdminPaymentGatewayConfig copyWith({
    bool? isEnabled,
    bool? isPrimary,
    double? feePct,
    int? latencyMs,
    double? uptimePct,
  }) {
    return AdminPaymentGatewayConfig(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      isEnabled: isEnabled ?? this.isEnabled,
      isPrimary: isPrimary ?? this.isPrimary,
      feePct: feePct ?? this.feePct,
      settlementAr: settlementAr,
      settlementEn: settlementEn,
      latencyMs: latencyMs ?? this.latencyMs,
      uptimePct: uptimePct ?? this.uptimePct,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'isEnabled': isEnabled,
        'isPrimary': isPrimary,
        'feePct': feePct,
        'settlementAr': settlementAr,
        'settlementEn': settlementEn,
        'latencyMs': latencyMs,
        'uptimePct': uptimePct,
      };
}

class AdminFeatureFlag {
  final String key;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String category; // 'security', 'operations', 'payments', 'infra'
  final bool isEnabled;
  final int rolloutPct;
  final String environment;
  final bool isKillSwitch;
  final String updatedAt;

  const AdminFeatureFlag({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.category,
    this.isEnabled = true,
    this.rolloutPct = 100,
    this.environment = 'production',
    this.isKillSwitch = false,
    this.updatedAt = 'الآن',
  });

  AdminFeatureFlag copyWith({
    bool? isEnabled,
    int? rolloutPct,
    String? environment,
    String? updatedAt,
  }) {
    return AdminFeatureFlag(
      key: key,
      nameAr: nameAr,
      nameEn: nameEn,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      category: category,
      isEnabled: isEnabled ?? this.isEnabled,
      rolloutPct: rolloutPct ?? this.rolloutPct,
      environment: environment ?? this.environment,
      isKillSwitch: isKillSwitch,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'descriptionAr': descriptionAr,
        'descriptionEn': descriptionEn,
        'category': category,
        'isEnabled': isEnabled,
        'rolloutPct': rolloutPct,
        'environment': environment,
        'isKillSwitch': isKillSwitch,
        'updatedAt': updatedAt,
      };

  factory AdminFeatureFlag.fromJson(Map<String, dynamic> json) {
    return AdminFeatureFlag(
      key: (json['key'] ?? '').toString(),
      nameAr: (json['nameAr'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? '').toString(),
      descriptionAr: (json['descriptionAr'] ?? '').toString(),
      descriptionEn: (json['descriptionEn'] ?? '').toString(),
      category: (json['category'] ?? 'operations').toString(),
      isEnabled: json['isEnabled'] as bool? ?? true,
      rolloutPct: (json['rolloutPct'] as num?)?.toInt() ?? 100,
      environment: (json['environment'] ?? 'production').toString(),
      isKillSwitch: json['isKillSwitch'] as bool? ?? false,
      updatedAt: (json['updatedAt'] ?? 'Now').toString(),
    );
  }
}

class AdminInfraServiceHealth {
  final String id;
  final String nameAr;
  final String nameEn;
  final String region;
  final String status; // 'operational', 'degraded', 'maintenance'
  final double uptimePct;
  final int p50Ms;
  final int p95Ms;
  final double errorRatePct;
  final int rps;
  final String lastChecked;

  const AdminInfraServiceHealth({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.region,
    this.status = 'operational',
    required this.uptimePct,
    required this.p50Ms,
    required this.p95Ms,
    required this.errorRatePct,
    required this.rps,
    required this.lastChecked,
  });

  AdminInfraServiceHealth copyWith({
    String? status,
    double? uptimePct,
    int? p50Ms,
    int? p95Ms,
    double? errorRatePct,
    int? rps,
    String? lastChecked,
  }) {
    return AdminInfraServiceHealth(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      region: region,
      status: status ?? this.status,
      uptimePct: uptimePct ?? this.uptimePct,
      p50Ms: p50Ms ?? this.p50Ms,
      p95Ms: p95Ms ?? this.p95Ms,
      errorRatePct: errorRatePct ?? this.errorRatePct,
      rps: rps ?? this.rps,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

class AdminB2BAccountItem {
  final String id;
  final String companyAr;
  final String companyEn;
  final String sectorAr;
  final String sectorEn;
  final String municipalityAr;
  final String municipalityEn;
  final int monthlyRuns;
  final int creditLimitQar;
  final String status; // 'active', 'suspended'
  final String contactPhone;

  const AdminB2BAccountItem({
    required this.id,
    required this.companyAr,
    required this.companyEn,
    required this.sectorAr,
    required this.sectorEn,
    required this.municipalityAr,
    required this.municipalityEn,
    required this.monthlyRuns,
    required this.creditLimitQar,
    this.status = 'active',
    required this.contactPhone,
  });

  AdminB2BAccountItem copyWith({String? status, int? creditLimitQar}) {
    return AdminB2BAccountItem(
      id: id,
      companyAr: companyAr,
      companyEn: companyEn,
      sectorAr: sectorAr,
      sectorEn: sectorEn,
      municipalityAr: municipalityAr,
      municipalityEn: municipalityEn,
      monthlyRuns: monthlyRuns,
      creditLimitQar: creditLimitQar ?? this.creditLimitQar,
      status: status ?? this.status,
      contactPhone: contactPhone,
    );
  }
}

class AdminBroadcastBanner {
  final bool isEnabled;
  final String severity; // 'info', 'warning', 'urgent'
  final String messageAr;
  final String messageEn;

  const AdminBroadcastBanner({
    this.isEnabled = false,
    this.severity = 'info',
    this.messageAr =
        'شبكة مشوار قطر تعمل الآن عبر 8 بلديات مع حماية الضمان المالي المزدوج وفاتورة المحل الحية.',
    this.messageEn =
        'MASHWAR Qatar network live across 8 municipalities with Bilateral Escrow & live receipt verification.',
  });

  AdminBroadcastBanner copyWith({
    bool? isEnabled,
    String? severity,
    String? messageAr,
    String? messageEn,
  }) {
    return AdminBroadcastBanner(
      isEnabled: isEnabled ?? this.isEnabled,
      severity: severity ?? this.severity,
      messageAr: messageAr ?? this.messageAr,
      messageEn: messageEn ?? this.messageEn,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'severity': severity,
        'messageAr': messageAr,
        'messageEn': messageEn,
      };

  factory AdminBroadcastBanner.fromJson(Map<String, dynamic> json) {
    return AdminBroadcastBanner(
      isEnabled: json['isEnabled'] as bool? ?? false,
      severity: (json['severity'] ?? 'info').toString(),
      messageAr: (json['messageAr'] ?? '').toString(),
      messageEn: (json['messageEn'] ?? '').toString(),
    );
  }
}

class AdminModuleSpec {
  final int index;
  final String groupAr;
  final String groupEn;
  final String titleAr;
  final String titleEn;
  final String shortAr;
  final String shortEn;

  const AdminModuleSpec({
    required this.index,
    required this.groupAr,
    required this.groupEn,
    required this.titleAr,
    required this.titleEn,
    required this.shortAr,
    required this.shortEn,
  });
}

class AdminCommandSearchResult {
  final int targetMenuIndex;
  final String title;
  final String subtitle;
  final String categoryTag;

  const AdminCommandSearchResult({
    required this.targetMenuIndex,
    required this.title,
    required this.subtitle,
    required this.categoryTag,
  });
}
