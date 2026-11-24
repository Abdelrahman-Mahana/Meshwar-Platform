import '../../../core/config/app_environment.dart';
import '../../models/worksite_models.dart';
import '../../services/firebase_firestore_service.dart';
import '../contracts/i_provider_repository.dart';

/// DEV/TEST-ONLY local implementation of [IProviderRepository].
///
/// Pre-seeds a deterministic Qatar Worksite Supply approved pilot supplier
/// ONLY when running in explicit local dev/test mode (`APP_ENV=development`,
/// `!USE_FIREBASE`, and `USE_DEV_MOCKS=true` or explicit `allowDevMocks: true`).
/// Never seeds mock data or allows mock mutations in staging/production.
class ProviderRepositoryImpl implements IProviderRepository {
  static final RegExp _qatarQidRegex = RegExp(r'^[0-9]{11}$');
  static final RegExp _phoneRegex =
      RegExp(r'^(?:\+?974)?[3567][0-9]{7}$|^\+?[0-9\s-]{10,20}$');

  static const String pilotApprovedProviderId = 'dev_prov_khalid';
  static const String pilotBackupProviderId = 'dev_prov_tariq';
  static const String pilotPendingProviderId = 'dev_prov_pending';

  final bool? _allowDevMocks;
  final DateTime Function() _now;
  final Map<String, ProviderProfile> _profiles = {};
  final Map<String, Map<String, dynamic>> _verifications = {};
  final Map<String, List<SavedWorksite>> _savedWorksitesByOwner = {};
  int _ratingCountByProvider = 0;

  ProviderRepositoryImpl({
    bool? allowDevMocks,
    bool? seedSampleData,
    DateTime Function()? now,
  })  : _allowDevMocks = allowDevMocks,
        _now = now ?? (() => DateTime.now().toUtc()) {
    if (isDevMockActive && (seedSampleData ?? true)) {
      _seedPilotProviders();
    }
  }

  /// Whether local dev mock mode is active under [AppEnvironment] boundaries.
  bool get isDevMockActive {
    if (!AppEnvironment.isDevMocksAllowed(
      flavor: AppEnvironment.flavor,
      useFirebase: AppEnvironment.isFirebaseRuntimeActive,
    )) {
      return false;
    }
    return _allowDevMocks ?? AppEnvironment.useDevMocks;
  }

  void _requireDevMockMode() {
    if (!isDevMockActive) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr:
            'مستودع مزودي التوريد المحلي معطّل خارج وضع التطوير التجريبي.',
        messageEn:
            'Local dev provider repository is disabled unless APP_ENV=development, USE_FIREBASE=false, and dev mocks are enabled.',
      );
    }
  }

  void _seedPilotProviders() {
    final seedTime = DateTime.utc(2026, 11, 20, 9, 0);
    _profiles[pilotApprovedProviderId] = ProviderProfile(
      id: pilotApprovedProviderId,
      userId: pilotApprovedProviderId,
      fullName: 'خالد المناعي للتوريدات',
      phone: '55234567',
      qidNumber: '29163401122',
      vehicleType: 'بيك أب غمارة',
      vehiclePlate: 'قطر 48291',
      serviceMunicipalities: const [
        'الدوحة',
        'لوسيل',
        'الريان',
        'الوكرة',
        'المنطقة الصناعية',
      ],
      supplySpecialties: const ['electrical', 'plumbing', 'hardware'],
      approvalStatus: ProviderApprovalStatus.approved,
      rating: 4.9,
      completedJobsCount: 18,
      isAvailable: true,
      createdAt: seedTime,
      updatedAt: seedTime,
    );
    _ratingCountByProvider = 18;

    _profiles[pilotBackupProviderId] = ProviderProfile(
      id: pilotBackupProviderId,
      userId: pilotBackupProviderId,
      fullName: 'طارق المهندي للخدمات اللوجستية',
      phone: '66778899',
      qidNumber: '28945612301',
      vehicleType: 'فان توصيل مبرد ومجهز',
      vehiclePlate: 'قطر 73104',
      serviceMunicipalities: const ['الدوحة', 'الخور', 'رأس لفان', 'لوسيل'],
      supplySpecialties: const ['safety_ppe', 'tools', 'civil_materials'],
      approvalStatus: ProviderApprovalStatus.approved,
      rating: 4.7,
      completedJobsCount: 9,
      isAvailable: true,
      createdAt: seedTime,
      updatedAt: seedTime,
    );

    _profiles[pilotPendingProviderId] = ProviderProfile(
      id: pilotPendingProviderId,
      userId: pilotPendingProviderId,
      fullName: 'سالم الدوسري',
      phone: '77112233',
      qidNumber: '29663401842',
      qidFrontUrl: 'https://storage.mashwar.qa/dev/qid_front.jpg',
      qidBackUrl: 'https://storage.mashwar.qa/dev/qid_back.jpg',
      selfieUrl: 'https://storage.mashwar.qa/dev/selfie.jpg',
      vehicleType: 'سيدان / بيك أب خفيف',
      vehiclePlate: 'قطر 90215',
      serviceMunicipalities: const ['الوكرة', 'مسيعيد'],
      supplySpecialties: const ['hardware'],
      approvalStatus: ProviderApprovalStatus.pending,
      rating: 0.0,
      completedJobsCount: 0,
      isAvailable: false,
      createdAt: seedTime,
      updatedAt: seedTime,
    );
    _verifications[pilotPendingProviderId] = {
      'id': pilotPendingProviderId,
      'providerId': pilotPendingProviderId,
      'fullName': 'سالم الدوسري',
      'qidNumber': '29663401842',
      'status': 'pending',
    };

    _savedWorksitesByOwner['dev_req_fahad'] = [
      SavedWorksite(
        id: 'dev_site_lusail_42',
        ownerUserId: 'dev_req_fahad',
        label: 'مشروع مارينا لوسيل - قطعة 42',
        municipality: 'لوسيل',
        zoneOrStreet: 'منطقة 69، شارع 210',
        landmark: 'بوابة المقاولين الشرقية',
        gateInstructions: 'الاتصال بالمشرف قبل الوصول بـ 10 دقائق',
        siteContactName: 'م. فهد المري',
        siteContactPhone: '55112233',
        isDefault: true,
        createdAt: seedTime,
        updatedAt: seedTime,
      ),
    ];
  }

  /// Internal helper used by [WorksiteRepositoryImpl] to verify approved-provider status.
  bool isProviderApprovedSync(String userId) {
    final profile = _profiles[userId];
    return profile != null &&
        profile.approvalStatus == ProviderApprovalStatus.approved;
  }

  /// Internal helper used by [WorksiteRepositoryImpl] when a delivery completes.
  void incrementCompletedJobs(String providerId) {
    final existing = _profiles[providerId];
    if (existing == null) return;
    _profiles[providerId] = existing.copyWith(
      completedJobsCount: existing.completedJobsCount + 1,
      updatedAt: _now(),
    );
  }

  /// Internal helper used by [WorksiteRepositoryImpl] when a rating is submitted.
  void applyRatingToProvider(String providerId, int stars) {
    final existing = _profiles[providerId];
    if (existing == null) return;
    final prevCount = providerId == pilotApprovedProviderId
        ? _ratingCountByProvider
        : existing.completedJobsCount;
    final nextCount = prevCount + 1;
    final nextAvg = double.parse(
      (((existing.rating * prevCount) + stars) / nextCount).toStringAsFixed(2),
    );
    if (providerId == pilotApprovedProviderId) {
      _ratingCountByProvider = nextCount;
    }
    _profiles[providerId] = existing.copyWith(
      rating: nextAvg,
      updatedAt: _now(),
    );
  }

  @override
  Future<ProviderProfile?> getProviderProfile(String userId) async {
    _requireDevMockMode();
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    return _profiles[trimmed];
  }

  @override
  Future<ProviderProfile> upsertProviderProfile(ProviderProfile profile) async {
    _requireDevMockMode();
    final uid = profile.userId.trim();
    if (uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    if (profile.fullName.trim().length < 2) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'الاسم الكامل للمزود مطلوب (حرفان على الأقل).',
        messageEn: 'Provider fullName must be at least 2 characters.',
      );
    }
    if (!_phoneRegex.hasMatch(profile.phone.trim())) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'رقم الجوال القطري غير صالح.',
        messageEn: 'Valid Qatar mobile number is required.',
      );
    }

    final now = _now();
    final existing = _profiles[uid];
    // Prevent client-side self-approval or metric fabrication.
    final sanitized = existing == null
        ? profile.copyWith(
            id: uid,
            userId: uid,
            approvalStatus: ProviderApprovalStatus.pending,
            rejectionReason: null,
            rating: 0.0,
            completedJobsCount: 0,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            fullName: profile.fullName.trim(),
            phone: profile.phone.trim(),
            vehicleType: profile.vehicleType?.trim(),
            vehiclePlate: profile.vehiclePlate?.trim(),
            serviceMunicipalities: profile.serviceMunicipalities,
            supplySpecialties: profile.supplySpecialties,
            isAvailable: profile.isAvailable,
            updatedAt: now,
          );

    _profiles[uid] = sanitized;
    return sanitized;
  }

  @override
  Future<ProviderProfile> submitProviderVerification({
    required String userId,
    required String qidNumber,
    required String qidFrontUrl,
    required String qidBackUrl,
    String? selfieUrl,
    String? vehicleType,
    String? vehiclePlate,
    List<String> serviceMunicipalities = const [],
    List<String> supplySpecialties = const [],
  }) async {
    _requireDevMockMode();
    final uid = userId.trim();
    if (uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    final cleanQid = qidNumber.trim();
    if (!_qatarQidRegex.hasMatch(cleanQid)) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'البطاقة الشخصية القطرية (QID) يجب أن تتكون من 11 رقماً.',
        messageEn: 'Qatar QID must be exactly 11 numeric digits.',
      );
    }
    if (!_isValidUrl(qidFrontUrl) ||
        !_isValidUrl(qidBackUrl) ||
        (selfieUrl != null && selfieUrl.trim().isNotEmpty && !_isValidUrl(selfieUrl))) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'روابط صور البطاقة القطرية غير صالحة.',
        messageEn: 'Valid HTTPS/GS URLs are required for verification photos.',
      );
    }

    final now = _now();
    final existing = _profiles[uid];
    final updated = ProviderProfile(
      id: uid,
      userId: uid,
      fullName: existing?.fullName.isNotEmpty == true
          ? existing!.fullName
          : 'مزود خدمات',
      phone: existing?.phone.isNotEmpty == true ? existing!.phone : '55000000',
      qidNumber: cleanQid,
      qidFrontUrl: qidFrontUrl.trim(),
      qidBackUrl: qidBackUrl.trim(),
      selfieUrl: selfieUrl?.trim(),
      vehicleType: vehicleType?.trim() ?? existing?.vehicleType ?? 'بيك أب',
      vehiclePlate: vehiclePlate?.trim() ?? existing?.vehiclePlate ?? 'قطر 00000',
      serviceMunicipalities: serviceMunicipalities.isNotEmpty
          ? serviceMunicipalities
          : (existing?.serviceMunicipalities ?? const ['الدوحة']),
      supplySpecialties: supplySpecialties.isNotEmpty
          ? supplySpecialties
          : (existing?.supplySpecialties ?? const ['general_site_supply']),
      approvalStatus: ProviderApprovalStatus.pending,
      rejectionReason: null,
      rating: existing?.rating ?? 0.0,
      completedJobsCount: existing?.completedJobsCount ?? 0,
      isAvailable: existing?.isAvailable ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    _profiles[uid] = updated;
    _verifications[uid] = {
      'id': uid,
      'providerId': uid,
      'fullName': updated.fullName,
      'qidNumber': cleanQid,
      'qidFrontUrl': qidFrontUrl.trim(),
      'qidBackUrl': qidBackUrl.trim(),
      'selfieUrl': selfieUrl?.trim(),
      'status': 'pending',
      'updatedAt': now.toIso8601String(),
    };
    return updated;
  }

  @override
  Future<List<ProviderProfile>> listPendingVerifications({int limit = 50}) async {
    _requireDevMockMode();
    return _profiles.values
        .where((p) => p.approvalStatus == ProviderApprovalStatus.pending)
        .take(limit)
        .toList();
  }

  @override
  Future<ProviderProfile> reviewProviderApproval({
    required String userId,
    required ProviderApprovalStatus decision,
    required String reviewerId,
    String? reason,
  }) async {
    _requireDevMockMode();
    final uid = userId.trim();
    if (reviewerId.trim().isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    final cleanReason = reason?.trim();
    if ((decision == ProviderApprovalStatus.rejected ||
            decision == ProviderApprovalStatus.suspended) &&
        (cleanReason == null || cleanReason.isEmpty)) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'سبب الرفض أو الإيقاف مطلوب.',
        messageEn: 'A non-empty reason is required for rejection or suspension.',
      );
    }

    final existing = _profiles[uid];
    if (existing == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'ملف مزود الخدمة غير موجود.',
        messageEn: 'Provider profile not found.',
      );
    }

    final now = _now();
    final reviewed = ProviderProfile(
      id: existing.id,
      userId: existing.userId,
      fullName: existing.fullName,
      phone: existing.phone,
      qidNumber: existing.qidNumber,
      qidFrontUrl: existing.qidFrontUrl,
      qidBackUrl: existing.qidBackUrl,
      selfieUrl: existing.selfieUrl,
      vehicleType: existing.vehicleType,
      vehiclePlate: existing.vehiclePlate,
      serviceMunicipalities: existing.serviceMunicipalities,
      supplySpecialties: existing.supplySpecialties,
      approvalStatus: decision,
      rejectionReason: (decision == ProviderApprovalStatus.rejected ||
              decision == ProviderApprovalStatus.suspended)
          ? cleanReason
          : null,
      rating: existing.rating,
      completedJobsCount: existing.completedJobsCount,
      isAvailable: decision == ProviderApprovalStatus.approved
          ? existing.isAvailable
          : false,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    _profiles[uid] = reviewed;
    if (_verifications.containsKey(uid)) {
      _verifications[uid] = {
        ..._verifications[uid]!,
        'status': decision.value,
        'reviewedBy': reviewerId.trim(),
        'reviewedAtUtc': now.toIso8601String(),
        'rejectionReason': reviewed.rejectionReason,
      };
    }
    return reviewed;
  }

  @override
  Future<SavedWorksite> saveWorksite(SavedWorksite worksite) async {
    _requireDevMockMode();
    final ownerId = worksite.ownerUserId.trim();
    if (ownerId.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    if (worksite.label.trim().isEmpty ||
        worksite.municipality.trim().isEmpty ||
        worksite.zoneOrStreet.trim().isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'يرجى إدخال اسم الموقع والبلدية والعنوان.',
        messageEn: 'Worksite label, municipality, and zone/street are required.',
      );
    }

    final now = _now();
    final list =
        List<SavedWorksite>.from(_savedWorksitesByOwner[ownerId] ?? const []);
    final effectiveId = worksite.id.trim().isNotEmpty
        ? worksite.id.trim()
        : 'site_${now.microsecondsSinceEpoch}';
    final normalized = worksite.copyWith(
      id: effectiveId,
      ownerUserId: ownerId,
      createdAt: worksite.createdAt,
      updatedAt: now,
    );

    if (normalized.isDefault) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }

    final existingIdx = list.indexWhere((s) => s.id == effectiveId);
    if (existingIdx >= 0) {
      list[existingIdx] = normalized;
    } else {
      list.insert(0, normalized);
    }
    _savedWorksitesByOwner[ownerId] = list;
    return normalized;
  }

  @override
  Future<List<SavedWorksite>> listSavedWorksites(String ownerUserId) async {
    _requireDevMockMode();
    final ownerId = ownerUserId.trim();
    if (ownerId.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    return List<SavedWorksite>.unmodifiable(
      _savedWorksitesByOwner[ownerId] ?? const [],
    );
  }

  bool _isValidUrl(String url) {
    final clean = url.trim();
    return clean.length >= 8 &&
        clean.length <= 1000 &&
        (clean.startsWith('https://') ||
            clean.startsWith('http://') ||
            clean.startsWith('gs://'));
  }
}
