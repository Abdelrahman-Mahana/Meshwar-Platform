import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/config/app_environment.dart';
import '../../models/worksite_models.dart';
import '../../services/firebase_firestore_service.dart';
import '../contracts/i_provider_repository.dart';
import '../contracts/i_worksite_repository.dart';
import 'provider_repository_impl.dart';

/// Pure-Dart FIPS 180-4 SHA-256 & salted handover verification helper matching
/// `functions/src/handoverCrypto.ts`.
@visibleForTesting
class WorksiteHandoverCrypto {
  WorksiteHandoverCrypto._();

  static const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int codeLength = 6;
  static const Duration handoverTtl = Duration(hours: 24);
  static const int maxAttempts = 5;

  static final List<int> _k = const [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static final Random _secureRandom = Random.secure();

  static String generateCode([Random? random]) {
    final rng = random ?? _secureRandom;
    final buffer = StringBuffer();
    for (var i = 0; i < codeLength; i++) {
      final byte = rng.nextInt(256);
      buffer.write(alphabet[byte % alphabet.length]);
    }
    return buffer.toString();
  }

  static String generateSalt([Random? random]) {
    final rng = random ?? _secureRandom;
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buffer.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static String normalizeCode(String code) => code.trim().toUpperCase();

  static String hashCodeWithSalt(String code, String salt) {
    final normalized = normalizeCode(code);
    return sha256Hex(utf8.encode('$salt:$normalized'));
  }

  static bool verifyHash({
    required String candidateCode,
    required String salt,
    required String expectedHashHex,
  }) {
    if (candidateCode.trim().isEmpty ||
        salt.isEmpty ||
        expectedHashHex.isEmpty) {
      return false;
    }
    final actualHex = hashCodeWithSalt(candidateCode, salt);
    if (actualHex.length != expectedHashHex.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < actualHex.length; i++) {
      diff |= actualHex.codeUnitAt(i) ^ expectedHashHex.codeUnitAt(i);
    }
    return diff == 0;
  }

  static String sha256Hex(List<int> input) {
    final msgLen = input.length;
    final bitLen = msgLen * 8;
    // Pad with 0x80, then 0x00 until length % 64 == 56, then 8-byte big-endian bit length.
    final paddedLen = ((msgLen + 9 + 63) ~/ 64) * 64;
    final padded = Uint8List(paddedLen);
    padded.setRange(0, msgLen, input);
    padded[msgLen] = 0x80;

    final bd = ByteData.sublistView(padded);
    // Support up to 53-bit integer message lengths cleanly across Dart VM & JS web.
    final highBits = (bitLen ~/ 0x100000000);
    final lowBits = bitLen & 0xFFFFFFFF;
    bd.setUint32(paddedLen - 8, highBits, Endian.big);
    bd.setUint32(paddedLen - 4, lowBits, Endian.big);

    var h0 = 0x6a09e667;
    var h1 = 0xbb67ae85;
    var h2 = 0x3c6ef372;
    var h3 = 0xa54ff53a;
    var h4 = 0x510e527f;
    var h5 = 0x9b05688c;
    var h6 = 0x1f83d9ab;
    var h7 = 0x5be0cd19;

    final w = Uint32List(64);

    for (var offset = 0; offset < paddedLen; offset += 64) {
      for (var i = 0; i < 16; i++) {
        w[i] = bd.getUint32(offset + (i * 4), Endian.big);
      }
      for (var i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
        final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;
      var f = h5;
      var g = h6;
      var h = h7;

      for (var i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e & 0xFFFFFFFF) & g);
        final temp1 = (h + s1 + ch + _k[i] + w[i]) & 0xFFFFFFFF;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xFFFFFFFF;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xFFFFFFFF;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
      h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF;
      h7 = (h7 + h) & 0xFFFFFFFF;
    }

    return [h0, h1, h2, h3, h4, h5, h6, h7]
        .map((v) => v.toRadixString(16).padLeft(8, '0'))
        .join();
  }

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;
}

class _HandoverSecretRecord {
  final String requestId;
  final String codeHash;
  final String codeSalt;
  final DateTime expiresAtUtc;
  final int attemptsRemaining;
  final int maxAttempts;
  final DateTime? usedAtUtc;

  const _HandoverSecretRecord({
    required this.requestId,
    required this.codeHash,
    required this.codeSalt,
    required this.expiresAtUtc,
    required this.attemptsRemaining,
    required this.maxAttempts,
    this.usedAtUtc,
  });

  _HandoverSecretRecord copyWith({
    int? attemptsRemaining,
    DateTime? usedAtUtc,
  }) {
    return _HandoverSecretRecord(
      requestId: requestId,
      codeHash: codeHash,
      codeSalt: codeSalt,
      expiresAtUtc: expiresAtUtc,
      attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
      maxAttempts: maxAttempts,
      usedAtUtc: usedAtUtc ?? this.usedAtUtc,
    );
  }
}

class _HandoverViewRecord {
  final String requestId;
  final String requesterId;
  final String handoverCode;
  final DateTime expiresAtUtc;

  const _HandoverViewRecord({
    required this.requestId,
    required this.requesterId,
    required this.handoverCode,
    required this.expiresAtUtc,
  });
}

/// DEV/TEST-ONLY local implementation of [IWorksiteRepository].
///
/// Enforces exact parity with `functions/src/handlers.ts` and `firestore.rules`:
/// - Strictly gated to explicit local dev/test mode (`APP_ENV=development`,
///   `!USE_FIREBASE`, and `USE_DEV_MOCKS=true` or explicit `allowDevMocks: true`).
/// - Same state machine, requester/provider ownership checks, approved-provider gate,
///   no-self-bidding, invoice attachment rules, payment immutability once
///   `verified_settled`, single-rating rule, and salted SHA-256 6-char handover
///   verification with 24h expiry and max 5 attempts.
class WorksiteRepositoryImpl implements IWorksiteRepository {
  static const Set<WorkRequestStatus> _invoiceAttachmentStatuses = {
    WorkRequestStatus.pickedUp,
    WorkRequestStatus.inTransit,
    WorkRequestStatus.deliveredPendingConfirmation,
  };

  static const Set<WorkRequestStatus> _requesterCancellableStatuses = {
    WorkRequestStatus.open,
    WorkRequestStatus.offerReceived,
    WorkRequestStatus.offerSelected,
    WorkRequestStatus.accepted,
    WorkRequestStatus.inProgress,
  };

  static const Set<WorkRequestStatus> _disputableStatuses = {
    WorkRequestStatus.accepted,
    WorkRequestStatus.inProgress,
    WorkRequestStatus.pickedUp,
    WorkRequestStatus.inTransit,
    WorkRequestStatus.deliveredPendingConfirmation,
  };

  final bool? _allowDevMocks;
  final IProviderRepository _providerRepo;
  final DateTime Function() _now;
  final Random? _random;

  final Map<String, WorkRequest> _requests = {};
  final Map<String, List<WorkOffer>> _offersByRequest = {};
  final Map<String, List<RequestEvent>> _eventsByRequest = {};
  final Map<String, _HandoverSecretRecord> _secretsByRequest = {};
  final Map<String, _HandoverViewRecord> _handoverViewsByRequest = {};
  final Map<String, RequestRating> _ratingsById = {};
  int _idSeq = 0;

  WorksiteRepositoryImpl({
    IProviderRepository? providerRepository,
    bool? allowDevMocks,
    bool? seedSampleData,
    DateTime Function()? now,
    Random? random,
  })  : _allowDevMocks = allowDevMocks,
        _providerRepo = providerRepository ??
            ProviderRepositoryImpl(
              allowDevMocks: allowDevMocks,
              seedSampleData: seedSampleData,
              now: now,
            ),
        _now = now ?? (() => DateTime.now().toUtc()),
        _random = random {
    if (isDevMockActive && (seedSampleData ?? true)) {
      _seedPilotRequests();
    }
  }

  /// Whether local dev mock mode is permitted and active.
  bool get isDevMockActive {
    if (!AppEnvironment.isDevMocksAllowed(
      flavor: AppEnvironment.flavor,
      useFirebase: AppEnvironment.useFirebase,
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
            'مستودع طلبات المواقع المحلي معطّل خارج وضع التطوير التجريبي.',
        messageEn:
            'Local dev worksite repository is disabled unless APP_ENV=development, USE_FIREBASE=false, and dev mocks are enabled.',
      );
    }
  }

  String _nextId(String prefix) {
    _idSeq++;
    return '${prefix}_dev_$_idSeq';
  }

  void _seedPilotRequests() {
    final t1 = DateTime.utc(2026, 11, 24, 8, 30);
    final t2 = DateTime.utc(2026, 11, 24, 9, 15);
    final t3 = DateTime.utc(2026, 11, 24, 10, 0);

    const req1Id = 'dev_req_lusail_breakers';
    _requests[req1Id] = WorkRequest(
      id: req1Id,
      requesterId: 'dev_req_fahad',
      requesterName: 'م. فهد المري',
      savedWorksiteId: 'dev_site_lusail_42',
      title: 'قواطع كهربائية 32A ووصلات نحاسية',
      description:
          'شراء 12 قاطع كهربائي Schneider 32A و3 لفات أسلاك من المنطقة الصناعية شارع 10 مع فاتورة أصلية.',
      supplyCategory: 'electrical',
      pickupLocation: 'المنطقة الصناعية - شارع 10 (مستودع الكهرباء)',
      dropoffWorksite: 'مارينا لوسيل - قطعة 42',
      municipality: 'لوسيل',
      siteContactName: 'م. فهد المري',
      siteContactPhone: '55112233',
      estimatedItemsCostMinor: MoneyMinor.fromMajorQar(180),
      maxItemsCapMinor: MoneyMinor.fromMajorQar(220),
      deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(45),
      status: WorkRequestStatus.open,
      paymentMethod: PaymentMethod.cashOnDelivery,
      paymentSettlementStatus: PaymentSettlementStatus.unpaid,
      createdAt: t1,
      updatedAt: t1,
    );
    _eventsByRequest[req1Id] = [
      RequestEvent(
        id: 'evt_seed_1',
        requestId: req1Id,
        actorId: 'dev_req_fahad',
        actorRole: 'requester',
        eventType: 'request_created',
        toStatus: WorkRequestStatus.open,
        note: 'تم إنشاء طلب توريد موقع جديد.',
        createdAt: t1,
      ),
    ];

    const req2Id = 'dev_req_wakrah_plumbing';
    _requests[req2Id] = WorkRequest(
      id: req2Id,
      requesterId: 'dev_req_sara',
      requesterName: 'م. سارة الكواري',
      title: 'مواسير PPR ومحابس مياه للسباكة',
      description:
          '20 ماسورة PPR مقاس 25مم + 10 محابس إيطالي مع تسليم موقع الوكرة وإيصال التحويل.',
      supplyCategory: 'plumbing',
      pickupLocation: 'طريق سلوى - مجمع مواد البناء',
      dropoffWorksite: 'الوكرة - موقع 12',
      municipality: 'الوكرة',
      siteContactName: 'المشرف راشد',
      siteContactPhone: '55449988',
      estimatedItemsCostMinor: MoneyMinor.fromMajorQar(320),
      maxItemsCapMinor: MoneyMinor.fromMajorQar(350),
      deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(55),
      status: WorkRequestStatus.offerReceived,
      offerCount: 1,
      paymentMethod: PaymentMethod.bankTransferManual,
      paymentSettlementStatus: PaymentSettlementStatus.unpaid,
      createdAt: t2,
      updatedAt: t2,
    );
    _offersByRequest[req2Id] = [
      WorkOffer(
        id: 'off_seed_2',
        requestId: req2Id,
        providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
        providerName: 'خالد المناعي للتوريدات',
        providerRating: 4.9,
        providerCompletedJobs: 18,
        proposedFeeMinor: MoneyMinor.fromMajorQar(50),
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(310),
        estimatedEtaMinutes: 45,
        notes: 'السيارة البيك أب جاهزة وقريب من طريق سلوى',
        status: 'pending',
        createdAt: t2.add(const Duration(minutes: 12)),
        updatedAt: t2.add(const Duration(minutes: 12)),
      ),
    ];
    _eventsByRequest[req2Id] = [
      RequestEvent(
        id: 'evt_seed_2',
        requestId: req2Id,
        actorId: 'dev_req_sara',
        actorRole: 'requester',
        eventType: 'request_created',
        toStatus: WorkRequestStatus.open,
        note: 'تم إنشاء الطلب.',
        createdAt: t2,
      ),
      RequestEvent(
        id: 'evt_seed_3',
        requestId: req2Id,
        actorId: ProviderRepositoryImpl.pilotApprovedProviderId,
        actorRole: 'provider',
        eventType: 'offer_submitted',
        fromStatus: WorkRequestStatus.open,
        toStatus: WorkRequestStatus.offerReceived,
        note: 'تم تقديم عرض تنفيذ بقيمة 50 ر.ق رسوم توصيل.',
        createdAt: t2.add(const Duration(minutes: 12)),
      ),
    ];

    const req3Id = 'dev_req_alkhor_ppe';
    _requests[req3Id] = WorkRequest(
      id: req3Id,
      requesterId: 'dev_req_fahad',
      requesterName: 'م. فهد المري',
      title: 'خوذات سلامة وسترات عاكسة (25 طقم)',
      description: 'مستلزمات السلامة المهنية للموقع مع فاتورة ضريبية معتمدة.',
      supplyCategory: 'safety_ppe',
      pickupLocation: 'المنطقة الصناعية - شارع 18',
      dropoffWorksite: 'الخور - بوابة رأس لفان 3',
      municipality: 'الخور',
      siteContactName: 'مشرف السلامة طلال',
      siteContactPhone: '66332211',
      estimatedItemsCostMinor: MoneyMinor.fromMajorQar(450),
      maxItemsCapMinor: MoneyMinor.fromMajorQar(500),
      deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(75),
      status: WorkRequestStatus.open,
      paymentMethod: PaymentMethod.cashOnDelivery,
      paymentSettlementStatus: PaymentSettlementStatus.unpaid,
      createdAt: t3,
      updatedAt: t3,
    );
    _eventsByRequest[req3Id] = [
      RequestEvent(
        id: 'evt_seed_4',
        requestId: req3Id,
        actorId: 'dev_req_fahad',
        actorRole: 'requester',
        eventType: 'request_created',
        toStatus: WorkRequestStatus.open,
        note: 'تم إنشاء طلب مستلزمات السلامة.',
        createdAt: t3,
      ),
    ];
  }

  Future<bool> _isProviderApproved(String uid) async {
    final repo = _providerRepo;
    if (repo is ProviderRepositoryImpl) {
      return repo.isProviderApprovedSync(uid);
    }
    final profile = await repo.getProviderProfile(uid);
    return profile?.canAcceptWorksiteJobs ?? false;
  }

  void _appendEvent(
    String requestId, {
    required String actorId,
    required String actorRole,
    required String eventType,
    WorkRequestStatus? fromStatus,
    required WorkRequestStatus toStatus,
    String? note,
    Map<String, dynamic> metadata = const {},
    DateTime? createdAt,
  }) {
    final list = _eventsByRequest.putIfAbsent(requestId, () => []);
    list.add(
      RequestEvent(
        id: _nextId('evt'),
        requestId: requestId,
        actorId: actorId,
        actorRole: actorRole,
        eventType: eventType,
        fromStatus: fromStatus,
        toStatus: toStatus,
        note: note,
        metadata: metadata,
        createdAt: (createdAt ?? _now()).toUtc(),
      ),
    );
  }

  @override
  Future<WorkRequest> createRequest(WorkRequest request) async {
    _requireDevMockMode();
    final uid = request.requesterId.trim();
    if (uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    if (request.title.trim().length < 2 || request.title.trim().length > 160) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'عنوان الطلب يجب أن يكون بين حرفين و160 حرفاً.',
        messageEn: 'Request title must be between 2 and 160 characters.',
      );
    }
    if (request.pickupLocation.trim().length < 2 ||
        request.dropoffWorksite.trim().length < 2 ||
        request.municipality.trim().isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'نقطة الاستلام وموقع التسليم والبلدية مطلوبة.',
        messageEn:
            'Pickup location, dropoff worksite, and municipality are required.',
      );
    }
    if (request.estimatedItemsCostMinor.minorUnits <= 0 ||
        request.maxItemsCapMinor.minorUnits <
            request.estimatedItemsCostMinor.minorUnits ||
        request.deliveryFeeBudgetMinor.minorUnits < 0) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'قيم الميزانية يجب أن تكون أرقاماً صحيحة موجبة بالهللة/الدرهم.',
        messageEn:
            'Budget minor units must be valid positive integers with max cap >= estimated cost.',
      );
    }

    final now = _now();
    final id = request.id.trim().isNotEmpty ? request.id.trim() : _nextId('req');

    // Enforce clean server-authoritative initial state regardless of client input.
    final created = request.copyWith(
      id: id,
      requesterId: uid,
      title: request.title.trim(),
      description: request.description.trim().isEmpty
          ? request.title.trim()
          : request.description.trim(),
      pickupLocation: request.pickupLocation.trim(),
      dropoffWorksite: request.dropoffWorksite.trim(),
      municipality: request.municipality.trim(),
      status: WorkRequestStatus.open,
      paymentSettlementStatus: PaymentSettlementStatus.unpaid,
      paymentProofUrl: null,
      paymentReference: null,
      selectedOfferId: null,
      assignedProviderId: null,
      assignedProviderName: null,
      agreedFeeMinor: null,
      receiptImageUrl: null,
      actualReceiptTotalMinor: null,
      offerCount: 0,
      isHandoverVerified: false,
      cancellationReason: null,
      disputeReason: null,
      createdAt: now,
      updatedAt: now,
    );

    _requests[id] = created;
    _offersByRequest.putIfAbsent(id, () => []);
    _appendEvent(
      id,
      actorId: uid,
      actorRole: 'requester',
      eventType: 'request_created',
      toStatus: WorkRequestStatus.open,
      note: 'Worksite supply request created.',
      createdAt: now,
    );
    return created;
  }

  @override
  Future<List<WorkRequest>> listRequests({
    WorkRequestStatus? status,
    String? municipality,
    String? requesterId,
    String? assignedProviderId,
    int limit = 50,
  }) async {
    _requireDevMockMode();
    final cleanArea = municipality?.trim().toLowerCase();
    final cleanReq = requesterId?.trim();
    final cleanProv = assignedProviderId?.trim();

    final list = _requests.values.where((r) {
      if (status != null && r.status != status) return false;
      if (cleanArea != null &&
          cleanArea.isNotEmpty &&
          r.municipality.trim().toLowerCase() != cleanArea &&
          !r.municipality.toLowerCase().contains(cleanArea)) {
        return false;
      }
      if (cleanReq != null && cleanReq.isNotEmpty && r.requesterId != cleanReq) {
        return false;
      }
      if (cleanProv != null &&
          cleanProv.isNotEmpty &&
          r.assignedProviderId != cleanProv) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return list.take(limit).toList();
  }

  @override
  Future<WorkRequest?> getRequestById(String requestId) async {
    _requireDevMockMode();
    return _requests[requestId.trim()];
  }

  @override
  Future<List<WorkOffer>> listOffersForRequest(String requestId) async {
    _requireDevMockMode();
    final offers =
        List<WorkOffer>.from(_offersByRequest[requestId.trim()] ?? const [])
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return offers;
  }

  @override
  Future<WorkOffer> submitOffer(WorkOffer offer) async {
    _requireDevMockMode();
    final providerId = offer.providerId.trim();
    if (providerId.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    final reqId = offer.requestId.trim();
    final request = _requests[reqId];
    if (request == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'طلب التوريد غير موجود.',
        messageEn: 'Work request not found.',
      );
    }

    if (request.requesterId == providerId) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'لا يمكنك تقديم عرض على طلب قمت بإنشائه.',
        messageEn: 'Requester cannot submit an offer on their own work request.',
      );
    }

    final approved = await _isProviderApproved(providerId);
    if (!approved) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'يجب اعتماد حساب المزود بالبطاقة القطرية قبل تقديم العروض.',
        messageEn:
            "Provider profile must have approvalStatus == 'approved' to submit offers.",
      );
    }

    if (request.status != WorkRequestStatus.open &&
        request.status != WorkRequestStatus.offerReceived) {
      throw WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'لا يمكن تقديم عرض في حالة الطلب الحالية.',
        messageEn:
            "Cannot submit offer when request status is '${request.status.value}'.",
      );
    }

    final totalMinor = (offer.estimatedItemsCostMinor?.minorUnits ?? 0) +
        offer.proposedFeeMinor.minorUnits;
    if (offer.proposedFeeMinor.minorUnits < 0 ||
        totalMinor <= 0 ||
        offer.estimatedEtaMinutes <= 0 ||
        offer.estimatedEtaMinutes > 10080) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'تفاصيل السعر أو مدة الوصول في العرض غير صالحة.',
        messageEn: 'Offer fee, total amount, and ETA minutes must be valid.',
      );
    }

    final now = _now();
    final profile = await _providerRepo.getProviderProfile(providerId);
    final offerId =
        offer.id.trim().isNotEmpty ? offer.id.trim() : _nextId('off');
    final savedOffer = offer.copyWith(
      id: offerId,
      requestId: reqId,
      providerId: providerId,
      providerName: offer.providerName.trim().isNotEmpty
          ? offer.providerName.trim()
          : (profile?.fullName ?? 'مزود معتمد'),
      providerRating: profile?.rating ?? offer.providerRating,
      providerCompletedJobs:
          profile?.completedJobsCount ?? offer.providerCompletedJobs,
      status: 'pending',
      isSelected: false,
      createdAt: now,
      updatedAt: now,
    );

    final offers = _offersByRequest.putIfAbsent(reqId, () => []);
    offers.add(savedOffer);

    final nextStatus = WorkRequestStatus.offerReceived;
    _requests[reqId] = request.copyWith(
      status: nextStatus,
      offerCount: request.offerCount + 1,
      updatedAt: now,
    );

    _appendEvent(
      reqId,
      actorId: providerId,
      actorRole: 'provider',
      eventType: 'offer_submitted',
      fromStatus: request.status,
      toStatus: nextStatus,
      note: 'Offer $offerId submitted.',
      metadata: {
        'offerId': offerId,
        'feeMinor': savedOffer.proposedFeeMinor.minorUnits,
        'etaMinutes': savedOffer.estimatedEtaMinutes,
      },
      createdAt: now,
    );

    return savedOffer;
  }

  @override
  Future<WorkRequest> acceptOffer({
    required String requestId,
    required String offerId,
    required String requesterId,
  }) async {
    _requireDevMockMode();
    final uid = requesterId.trim();
    if (uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    final reqId = requestId.trim();
    final request = _requests[reqId];
    if (request == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'طلب التوريد غير موجود.',
        messageEn: 'Work request not found.',
      );
    }
    if (request.requesterId != uid) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'صاحب الطلب فقط يحق له قبول العرض.',
        messageEn: 'Only the request owner may accept an offer.',
      );
    }
    if (request.status != WorkRequestStatus.open &&
        request.status != WorkRequestStatus.offerReceived) {
      throw WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'لا يمكن قبول عرض في حالة الطلب الحالية.',
        messageEn:
            "Cannot accept offer when request status is '${request.status.value}'.",
      );
    }

    final offers = _offersByRequest[reqId] ?? [];
    final offerIdx = offers.indexWhere((o) => o.id == offerId.trim());
    if (offerIdx < 0) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'العرض المختار غير موجود لهذا الطلب.',
        messageEn: 'Offer does not belong to this work request.',
      );
    }
    final selected = offers[offerIdx];
    if (selected.status != 'pending') {
      throw WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'العرض المختار لم يعد متاحاً.',
        messageEn: "Offer is not pending (current: '${selected.status}').",
      );
    }

    final approved = await _isProviderApproved(selected.providerId);
    if (!approved) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'مزود الخدمة المختار لم يعد معتمداً.',
        messageEn: 'Selected provider is no longer approved.',
      );
    }

    final now = _now();
    for (var i = 0; i < offers.length; i++) {
      final current = offers[i];
      if (current.id == selected.id) {
        offers[i] = current.copyWith(
          status: 'accepted',
          isSelected: true,
          updatedAt: now,
        );
      } else if (current.status == 'pending') {
        offers[i] = current.copyWith(
          status: 'rejected',
          isSelected: false,
          updatedAt: now,
        );
      }
    }

    final handoverCode = WorksiteHandoverCrypto.generateCode(_random);
    final codeSalt = WorksiteHandoverCrypto.generateSalt(_random);
    final codeHash =
        WorksiteHandoverCrypto.hashCodeWithSalt(handoverCode, codeSalt);
    final expiresAtUtc = now.add(WorksiteHandoverCrypto.handoverTtl);

    _secretsByRequest[reqId] = _HandoverSecretRecord(
      requestId: reqId,
      codeHash: codeHash,
      codeSalt: codeSalt,
      expiresAtUtc: expiresAtUtc,
      attemptsRemaining: WorksiteHandoverCrypto.maxAttempts,
      maxAttempts: WorksiteHandoverCrypto.maxAttempts,
      usedAtUtc: null,
    );
    _handoverViewsByRequest[reqId] = _HandoverViewRecord(
      requestId: reqId,
      requesterId: request.requesterId,
      handoverCode: handoverCode,
      expiresAtUtc: expiresAtUtc,
    );

    final updated = request.copyWith(
      selectedOfferId: selected.id,
      assignedProviderId: selected.providerId,
      assignedProviderName: selected.providerName,
      agreedFeeMinor: selected.proposedFeeMinor,
      status: WorkRequestStatus.accepted,
      updatedAt: now,
    );
    _requests[reqId] = updated;

    _appendEvent(
      reqId,
      actorId: uid,
      actorRole: 'requester',
      eventType: 'offer_selected',
      fromStatus: request.status,
      toStatus: WorkRequestStatus.offerSelected,
      note: 'Selected offer ${selected.id}.',
      metadata: {'offerId': selected.id, 'providerId': selected.providerId},
      createdAt: now,
    );
    _appendEvent(
      reqId,
      actorId: uid,
      actorRole: 'requester',
      eventType: 'offer_accepted',
      fromStatus: WorkRequestStatus.offerSelected,
      toStatus: WorkRequestStatus.accepted,
      note: 'Assigned provider confirmed and handover secret generated.',
      metadata: {'offerId': selected.id, 'providerId': selected.providerId},
      createdAt: now,
    );

    return updated;
  }

  @override
  Future<WorkRequest> updateFulfillmentStatus({
    required String requestId,
    required WorkRequestStatus nextStatus,
    required String actorId,
    required String actorRole,
    String? note,
    String? receiptImageUrl,
    MoneyMinor? actualReceiptTotalMinor,
  }) async {
    _requireDevMockMode();
    final uid = actorId.trim();
    if (uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    final reqId = requestId.trim();
    final request = _requests[reqId];
    if (request == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'طلب التوريد غير موجود.',
        messageEn: 'Work request not found.',
      );
    }

    if (nextStatus == WorkRequestStatus.completed) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr:
            'لا يمكن إنهاء الطلب إلا عبر التحقق من رمز التسليم عند الاستلام.',
        messageEn:
            "Status 'completed' can only be set by verifyHandoverCode after valid handover verification.",
      );
    }

    if (WorkRequestStatusMachine.isTerminal(request.status) ||
        request.status == nextStatus) {
      throw WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'لا يمكن تغيير حالة الطلب من حالته الحالية.',
        messageEn:
            "Invalid transition from '${request.status.value}' to '${nextStatus.value}'.",
      );
    }

    final cleanReceipt = receiptImageUrl?.trim();
    if (cleanReceipt != null &&
        cleanReceipt.isNotEmpty &&
        !_invoiceAttachmentStatuses.contains(nextStatus)) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr:
            'لا يمكن إرفاق الفاتورة إلا عند الاستلام أو التوصيل أو انتظار التأكيد.',
        messageEn:
            'Invoice image URL can only be attached when transitioning to picked_up, in_transit, or delivered_pending_confirmation.',
      );
    }

    final role = actorRole.trim().toLowerCase();
    final isRequester = request.requesterId == uid;
    final isAssignedProvider = request.assignedProviderId == uid;
    final isAdmin = role == 'admin';

    bool isApprovedProvider = false;
    if (isAssignedProvider || role == 'provider') {
      isApprovedProvider = await _isProviderApproved(uid);
    }

    // Strict parity with functions/src/stateMachine.ts:
    // - Provider linear chain: accepted -> in_progress -> picked_up -> in_transit -> delivered_pending_confirmation
    const linearNext = <WorkRequestStatus, WorkRequestStatus>{
      WorkRequestStatus.accepted: WorkRequestStatus.inProgress,
      WorkRequestStatus.inProgress: WorkRequestStatus.pickedUp,
      WorkRequestStatus.pickedUp: WorkRequestStatus.inTransit,
      WorkRequestStatus.inTransit:
          WorkRequestStatus.deliveredPendingConfirmation,
    };

    String resolvedActorRole;
    if (linearNext[request.status] == nextStatus) {
      if (!isAssignedProvider || (role != 'provider' && !isAdmin)) {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'المزود المكلّف بالطلب فقط يمكنه تحديث مراحل التنفيذ.',
          messageEn: 'Only the assigned provider may advance fulfillment stages.',
        );
      }
      if (!isApprovedProvider) {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'حساب المزود غير معتمد حالياً لتحديث مراحل التنفيذ.',
          messageEn:
              'Provider approvalStatus must remain approved to update fulfillment stages.',
        );
      }
      resolvedActorRole = 'provider';
    } else if (nextStatus == WorkRequestStatus.cancelled) {
      if (isAdmin) {
        resolvedActorRole = 'admin';
      } else if (isRequester && role == 'requester') {
        if (!_requesterCancellableStatuses.contains(request.status)) {
          throw WorksiteRepositoryException(
            code: 'failed-precondition',
            messageAr: 'لا يمكن للطالب إلغاء الطلب بعد استلام المشتريات.',
            messageEn:
                "Requester cannot cancel once status has reached '${request.status.value}'.",
          );
        }
        resolvedActorRole = 'requester';
      } else {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'لا تملك صلاحية إلغاء هذا الطلب.',
          messageEn:
              'Only the requester (before pickup) or an admin may cancel this request.',
        );
      }
    } else if (nextStatus == WorkRequestStatus.disputed) {
      if (!_disputableStatuses.contains(request.status)) {
        throw WorksiteRepositoryException(
          code: 'failed-precondition',
          messageAr: 'يمكن فتح النزاع فقط أثناء مراحل التنفيذ النشطة.',
          messageEn:
              "Disputes can only be opened during active fulfillment, not from '${request.status.value}'.",
        );
      }
      if (isAdmin) {
        resolvedActorRole = 'admin';
      } else if (isRequester) {
        resolvedActorRole = 'requester';
      } else if (isAssignedProvider) {
        resolvedActorRole = 'provider';
      } else {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'أطراف الطلب فقط يمكنهم فتح نزاع.',
          messageEn: 'Only request participants or admin may open a dispute.',
        );
      }
    } else {
      throw WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr:
            'الانتقال من ${request.status.value} إلى ${nextStatus.value} غير مسموح.',
        messageEn:
            "Invalid state transition from '${request.status.value}' to '${nextStatus.value}'.",
      );
    }

    final now = _now();
    final updated = request.copyWith(
      status: nextStatus,
      receiptImageUrl: (cleanReceipt != null && cleanReceipt.isNotEmpty)
          ? cleanReceipt
          : request.receiptImageUrl,
      actualReceiptTotalMinor:
          actualReceiptTotalMinor ?? request.actualReceiptTotalMinor,
      cancellationReason: nextStatus == WorkRequestStatus.cancelled
          ? (note ?? request.cancellationReason)
          : request.cancellationReason,
      disputeReason: nextStatus == WorkRequestStatus.disputed
          ? (note ?? request.disputeReason)
          : request.disputeReason,
      updatedAt: now,
    );
    _requests[reqId] = updated;

    _appendEvent(
      reqId,
      actorId: uid,
      actorRole: resolvedActorRole,
      eventType: 'status_changed',
      fromStatus: request.status,
      toStatus: nextStatus,
      note: note ?? "Transitioned from '${request.status.value}' to '${nextStatus.value}'.",
      createdAt: now,
    );

    return updated;
  }

  @override
  Future<String> getRequesterHandoverCode({
    required String requestId,
    required String requesterId,
  }) async {
    _requireDevMockMode();
    final uid = requesterId.trim();
    if (uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    final reqId = requestId.trim();
    final request = _requests[reqId];
    if (request == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'طلب التوريد غير موجود.',
        messageEn: 'Work request not found.',
      );
    }
    if (request.requesterId != uid) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'رمز التسليم متاح لصاحب الطلب فقط.',
        messageEn: 'Only the request owner may view the handover code.',
      );
    }
    final view = _handoverViewsByRequest[reqId];
    if (view == null || view.requesterId != uid) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'لا يوجد رمز تسليم نشط لهذا الطلب.',
        messageEn: 'No active handover code exists for this request.',
      );
    }
    return view.handoverCode;
  }

  @override
  Future<HandoverVerificationResult> verifyHandoverCode({
    required String requestId,
    required String providerId,
    required String code,
  }) async {
    _requireDevMockMode();
    final uid = providerId.trim();
    if (uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'يرجى إدخال رمز التسليم.',
        messageEn: 'Handover code is required.',
      );
    }

    final reqId = requestId.trim();
    final request = _requests[reqId];
    if (request == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'طلب التوريد غير موجود.',
        messageEn: 'Work request not found.',
      );
    }
    if (request.assignedProviderId != uid) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'المزود المكلّف فقط يمكنه تأكيد رمز التسليم.',
        messageEn:
            'Only the assigned provider may verify handover and complete this request.',
      );
    }
    if (!await _isProviderApproved(uid)) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'يجب أن يبقى حساب المزود معتمداً لإتمام التسليم.',
        messageEn: 'Assigned provider must remain approved to complete handover.',
      );
    }
    if (request.status != WorkRequestStatus.deliveredPendingConfirmation) {
      throw WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'لا يمكن تأكيد رمز التسليم قبل الوصول لحالة التسليم.',
        messageEn:
            "Handover can only be verified when status is 'delivered_pending_confirmation' (current: '${request.status.value}').",
      );
    }

    final secret = _secretsByRequest[reqId];
    if (secret == null) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'لا يوجد رمز تحقق مسجل لهذا الطلب.',
        messageEn: 'No handover verification secret exists for this request.',
      );
    }
    if (secret.usedAtUtc != null) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'تم استخدام رمز التسليم مسبقاً.',
        messageEn: 'Handover code has already been used.',
      );
    }
    if (secret.attemptsRemaining <= 0) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'تم استنفاد جميع محاولات التحقق من رمز التسليم.',
        messageEn: 'Handover verification attempts have been exhausted.',
      );
    }

    final now = _now();
    if (now.isAfter(secret.expiresAtUtc)) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'انتهت صلاحية رمز التسليم.',
        messageEn: 'Handover code has expired.',
      );
    }

    final isMatch = WorksiteHandoverCrypto.verifyHash(
      candidateCode: cleanCode,
      salt: secret.codeSalt,
      expectedHashHex: secret.codeHash,
    );

    if (!isMatch) {
      final nextAttempts =
          secret.attemptsRemaining > 0 ? secret.attemptsRemaining - 1 : 0;
      _secretsByRequest[reqId] =
          secret.copyWith(attemptsRemaining: nextAttempts);
      _appendEvent(
        reqId,
        actorId: uid,
        actorRole: 'provider',
        eventType: 'handover_attempt_failed',
        fromStatus: request.status,
        toStatus: request.status,
        note: 'Invalid handover code attempt ($nextAttempts remaining).',
        metadata: {'attemptsRemaining': nextAttempts},
        createdAt: now,
      );
      throw WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'رمز التسليم غير صحيح. المحاولات المتبقية: $nextAttempts.',
        messageEn:
            'Invalid handover code. Attempts remaining: $nextAttempts.',
        details: {'attemptsRemaining': nextAttempts},
      );
    }

    _secretsByRequest[reqId] = secret.copyWith(usedAtUtc: now);
    _requests[reqId] = request.copyWith(
      status: WorkRequestStatus.completed,
      isHandoverVerified: true,
      updatedAt: now,
    );

    final repo = _providerRepo;
    if (repo is ProviderRepositoryImpl) {
      repo.incrementCompletedJobs(uid);
    }

    _appendEvent(
      reqId,
      actorId: uid,
      actorRole: 'provider',
      eventType: 'handover_completed',
      fromStatus: WorkRequestStatus.deliveredPendingConfirmation,
      toStatus: WorkRequestStatus.completed,
      note: 'Handover code verified; delivery confirmed and completed.',
      createdAt: now,
    );

    final eventId = _eventsByRequest[reqId]!.last.id;
    return HandoverVerificationResult(
      verified: true,
      requestId: reqId,
      resultingStatus: WorkRequestStatus.completed,
      message: 'تم تأكيد التسليم بنجاح | Handover verified and completed.',
      verifiedAt: now,
      verifiedByProviderId: uid,
      eventId: eventId,
    );
  }

  @override
  Future<RequestRating> submitRating(RequestRating rating) async {
    _requireDevMockMode();
    final uid = rating.raterUserId.trim();
    if (uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    if (rating.score < 1 || rating.score > 5) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'التقييم يجب أن يكون من 1 إلى 5 نجوم.',
        messageEn: 'Rating score must be between 1 and 5.',
      );
    }
    final reqId = rating.requestId.trim();
    final request = _requests[reqId];
    if (request == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'طلب التوريد غير موجود.',
        messageEn: 'Work request not found.',
      );
    }
    if (request.status != WorkRequestStatus.completed) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'يمكن إرسال التقييم فقط بعد اكتمال التسليم.',
        messageEn: 'Ratings can only be submitted after a request is completed.',
      );
    }

    final isRequester = request.requesterId == uid;
    final isProvider = request.assignedProviderId == uid;
    if (!isRequester && !isProvider) {
      throw const WorksiteRepositoryException(
        code: 'permission-denied',
        messageAr: 'أطراف الطلب فقط يمكنهم تقديم التقييم.',
        messageEn: 'Only request participants may submit ratings.',
      );
    }

    final ratingId = '${reqId}_$uid';
    if (_ratingsById.containsKey(ratingId)) {
      throw const WorksiteRepositoryException(
        code: 'already-exists',
        messageAr: 'قمت بتقييم هذا الطلب مسبقاً.',
        messageEn: 'You have already submitted a rating for this request.',
      );
    }

    final toUserId = isRequester
        ? (request.assignedProviderId ?? '')
        : request.requesterId;
    if (toUserId.isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'تعذر تحديد الطرف المستهدف للتقييم.',
        messageEn: 'Target user is missing for rating.',
      );
    }

    final now = _now();
    final saved = rating.copyWith(
      id: ratingId,
      requestId: reqId,
      raterUserId: uid,
      raterRole: isRequester ? 'requester' : 'provider',
      targetUserId: toUserId,
      createdAt: now,
    );
    _ratingsById[ratingId] = saved;

    final repo = _providerRepo;
    if (isRequester && repo is ProviderRepositoryImpl) {
      repo.applyRatingToProvider(toUserId, saved.score);
    }

    return saved;
  }

  @override
  Future<WorkRequest> reportDispute({
    required String requestId,
    required String reporterId,
    required String reporterRole,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw const WorksiteRepositoryException(
        code: 'invalid-argument',
        messageAr: 'يرجى توضيح سبب النزاع.',
        messageEn: 'Dispute reason cannot be empty.',
      );
    }
    return updateFulfillmentStatus(
      requestId: requestId,
      nextStatus: WorkRequestStatus.disputed,
      actorId: reporterId,
      actorRole: reporterRole,
      note: reason.trim(),
    );
  }

  @override
  Future<List<RequestEvent>> listRequestEvents(String requestId) async {
    _requireDevMockMode();
    final list =
        List<RequestEvent>.from(_eventsByRequest[requestId.trim()] ?? const [])
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<WorkRequest> recordPaymentStatus({
    required String requestId,
    required PaymentMethod method,
    required PaymentSettlementStatus settlementStatus,
    required String actorId,
    required String actorRole,
    String? proofUrl,
    String? referenceNumber,
  }) async {
    _requireDevMockMode();
    final uid = actorId.trim();
    if (uid.isEmpty) {
      throw WorksiteRepositoryException.unauthenticated();
    }
    final reqId = requestId.trim();
    final request = _requests[reqId];
    if (request == null) {
      throw const WorksiteRepositoryException(
        code: 'not-found',
        messageAr: 'طلب التوريد غير موجود.',
        messageEn: 'Work request not found.',
      );
    }

    if (request.paymentSettlementStatus ==
        PaymentSettlementStatus.verifiedSettled) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'تم توثيق السداد مسبقاً ولا يمكن تعديله.',
        messageEn:
            "Payment status is already 'verified_settled' and cannot be modified.",
      );
    }
    if (request.paymentSettlementStatus == settlementStatus) {
      throw WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'حالة السداد هي نفسها بالفعل.',
        messageEn: "Payment status is already '${settlementStatus.value}'.",
      );
    }
    if (settlementStatus == PaymentSettlementStatus.unpaid) {
      throw const WorksiteRepositoryException(
        code: 'failed-precondition',
        messageAr: 'لا يمكن إعادة حالة السداد إلى غير مدفوع.',
        messageEn: "Cannot revert payment status back to 'unpaid'.",
      );
    }

    final role = actorRole.trim().toLowerCase();
    final isRequester = request.requesterId == uid;
    final isAssignedProvider = request.assignedProviderId == uid;
    final isAdmin = role == 'admin';

    String resolvedRole;
    if (settlementStatus == PaymentSettlementStatus.transferProofSubmitted) {
      if (!isRequester) {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'صاحب الطلب فقط يمكنه رفع إيصال التحويل البنكي.',
          messageEn: 'Only the request owner may submit bank transfer proof.',
        );
      }
      if (request.paymentMethod != PaymentMethod.bankTransferManual) {
        throw const WorksiteRepositoryException(
          code: 'failed-precondition',
          messageAr: 'إيصال التحويل متاح فقط لطلبات التحويل البنكي اليدوي.',
          messageEn:
              "Transfer proof is only applicable when paymentMethod is 'bank_transfer_manual'.",
        );
      }
      if (request.paymentSettlementStatus != PaymentSettlementStatus.unpaid) {
        throw const WorksiteRepositoryException(
          code: 'failed-precondition',
          messageAr: 'لا يمكن رفع إيصال التحويل في الحالة الحالية للسداد.',
          messageEn: 'Cannot submit transfer proof from current payment status.',
        );
      }
      final cleanProof = proofUrl?.trim();
      if (cleanProof == null || !_isSafeUrl(cleanProof)) {
        throw const WorksiteRepositoryException(
          code: 'invalid-argument',
          messageAr: 'رابط إيصال التحويل البنكي مطلوب وصالح.',
          messageEn: 'Valid paymentProofUrl is required.',
        );
      }
      resolvedRole = 'requester';
    } else if (settlementStatus == PaymentSettlementStatus.verifiedSettled) {
      if (!isAdmin) {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'الإدارة المعتمدة فقط يمكنها تأكيد تسوية السداد.',
          messageEn:
              "Only an active administrator may mark payment status as 'verified_settled'.",
        );
      }
      resolvedRole = 'admin';
    } else {
      // disputed
      if (isAdmin) {
        resolvedRole = 'admin';
      } else if (isRequester) {
        resolvedRole = 'requester';
      } else if (isAssignedProvider) {
        resolvedRole = 'provider';
      } else {
        throw const WorksiteRepositoryException(
          code: 'permission-denied',
          messageAr: 'أطراف الطلب أو الإدارة فقط يمكنهم الاعتراض على السداد.',
          messageEn:
              'Only request participants or an administrator may dispute payment status.',
        );
      }
    }

    final now = _now();
    final updated = request.copyWith(
      paymentSettlementStatus: settlementStatus,
      paymentProofUrl: proofUrl?.trim().isNotEmpty == true
          ? proofUrl!.trim()
          : request.paymentProofUrl,
      paymentReference: referenceNumber?.trim().isNotEmpty == true
          ? referenceNumber!.trim()
          : request.paymentReference,
      updatedAt: now,
    );
    _requests[reqId] = updated;

    _appendEvent(
      reqId,
      actorId: uid,
      actorRole: resolvedRole,
      eventType: 'payment_status_changed',
      fromStatus: request.status,
      toStatus: request.status,
      note:
          "Payment status updated from '${request.paymentSettlementStatus.value}' to '${settlementStatus.value}'.",
      createdAt: now,
    );

    return updated;
  }

  bool _isSafeUrl(String url) {
    return url.length <= 1000 &&
        (url.startsWith('https://') ||
            url.startsWith('http://') ||
            url.startsWith('gs://'));
  }
}
