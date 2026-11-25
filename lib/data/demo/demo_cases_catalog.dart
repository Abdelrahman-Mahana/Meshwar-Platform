import '../models/admin_platform_models.dart';
import '../models/worksite_models.dart';

/// Provider profile + KYC verification metadata entry for the Qatar MVP demo catalog.
class DemoProviderEntry {
  final ProviderProfile profile;
  final String? vehicleLicenseUrl;
  final String? reviewedBy;
  final DateTime? reviewedAtUtc;
  final bool hasVerificationRecord;

  const DemoProviderEntry({
    required this.profile,
    this.vehicleLicenseUrl,
    this.reviewedBy,
    this.reviewedAtUtc,
    this.hasVerificationRecord = true,
  });
}

/// Owner-scoped notification item matching Firestore `notifications/{id}` schema.
class DemoNotificationEntry {
  final String id;
  final String userId;
  final String title;
  final String titleAr;
  final String titleEn;
  final String body;
  final String bodyAr;
  final String bodyEn;
  final String type;
  final String category;
  final String? requestId;
  final String? offerId;
  final String? targetRoute;
  final bool isRead;
  final DateTime createdAt;

  const DemoNotificationEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.titleAr,
    required this.titleEn,
    required this.body,
    required this.bodyAr,
    required this.bodyEn,
    required this.type,
    required this.category,
    this.requestId,
    this.offerId,
    this.targetRoute,
    this.isRead = false,
    required this.createdAt,
  });
}

/// Admin governance audit log entry matching Firestore `admin_audit_logs/{id}` schema.
class DemoAuditLogEntry {
  final String id;
  final String adminUid;
  final String adminRole;
  final String action;
  final String targetCollection;
  final String targetEntityId;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic> newState;
  final String? reason;
  final String beforeAfter;
  final DateTime createdAt;

  const DemoAuditLogEntry({
    required this.id,
    required this.adminUid,
    required this.adminRole,
    required this.action,
    required this.targetCollection,
    required this.targetEntityId,
    this.previousState,
    required this.newState,
    this.reason,
    required this.beforeAfter,
    required this.createdAt,
  });
}

/// Immutable bundle containing all Qatar Worksite Supply MVP demo cases across
/// every status, Qatar municipality, payment method, settlement status, and role.
class MashwarDemoCasesBundle {
  final String currentUserId;
  final String currentUserName;
  final DateTime anchorUtc;
  final List<SavedWorksite> savedWorksites;
  final List<DemoProviderEntry> providers;
  final List<WorkRequest> requests;
  final Map<String, List<WorkOffer>> offersByRequest;
  final Map<String, String> handoverCodesByRequest;
  final Map<String, List<RequestEvent>> eventsByRequest;
  final List<RequestRating> ratings;
  final List<DemoNotificationEntry> notifications;
  final List<AdminInvestorInquiry> investorInquiries;
  final List<DemoAuditLogEntry> auditLogs;

  const MashwarDemoCasesBundle({
    required this.currentUserId,
    required this.currentUserName,
    required this.anchorUtc,
    required this.savedWorksites,
    required this.providers,
    required this.requests,
    required this.offersByRequest,
    required this.handoverCodesByRequest,
    required this.eventsByRequest,
    required this.ratings,
    required this.notifications,
    required this.investorInquiries,
    required this.auditLogs,
  });

  List<ProviderProfile> get providerProfiles =>
      List.unmodifiable(providers.map((p) => p.profile));

  List<WorkOffer> get allOffers => List.unmodifiable(
        offersByRequest.values.expand((items) => items),
      );

  WorkRequest? requestById(String requestId) {
    final clean = requestId.trim();
    for (final req in requests) {
      if (req.id == clean) return req;
    }
    return null;
  }

  List<WorkOffer> offersFor(String requestId) =>
      List.unmodifiable(offersByRequest[requestId.trim()] ?? const []);

  List<RequestEvent> eventsFor(String requestId) =>
      List.unmodifiable(eventsByRequest[requestId.trim()] ?? const []);

  String? handoverCodeFor(String requestId) =>
      handoverCodesByRequest[requestId.trim()];

  ProviderProfile? providerProfileFor(String userId) {
    final clean = userId.trim();
    for (final item in providers) {
      if (item.profile.userId == clean) return item.profile;
    }
    return null;
  }
}

/// Canonical bilingual Qatar MVP "ALL cases" showcase & seeding catalog.
///
/// Covers:
/// - 3 Qatar `SavedWorksite`s for the signed-in user
/// - All 4 `ProviderApprovalStatus` values (`approved`, `pending`, `rejected`, `suspended`)
///   including an approved provider profile for `currentUserId`
/// - 14 `WorkRequest`s spanning ALL 11 `WorkRequestStatus` values, ALL 7+ Qatar
///   municipalities/hubs, BOTH `PaymentMethod`s, ALL 4 `PaymentSettlementStatus`
///   values, and ALL 3 perspectives (requester, marketplace peer, assigned provider)
///   with `requesterId != assignedProviderId` on every request
/// - 5 `WorkOffer`s, 5 deterministic 6-character handover codes, rich `RequestEvent`
///   timelines, post-completion `RequestRating`s, bilingual `notifications`,
///   Qatar `investor_inquiries`, and `admin_audit_logs`.
class MashwarDemoCasesCatalog {
  MashwarDemoCasesCatalog._();

  static const String defaultOwnerUid = 'QB0hyc4BVZTkr91EC9KUd2EFbCw1';
  static const String defaultOwnerName = 'عبدالرحمن مهنا';
  static const String defaultOwnerEmail = 'abdelrahmanmahana01@gmail.com';

  static const String peerRequesterKhaledId = 'demo_req_khaled';
  static const String peerRequesterSaraId = 'demo_req_sara';

  static const String approvedMainProviderId = 'demo_prov_main';
  static const String approvedSafetyProviderId = 'demo_prov_safety';
  static const String approvedFastProviderId = 'demo_prov_fast';
  static const String pendingReviewProviderId = 'demo_prov_pending';
  static const String pendingUnverifiedProviderId = 'demo_prov_unverified_docs';
  static const String rejectedProviderId = 'demo_prov_rejected';
  static const String suspendedProviderId = 'demo_prov_suspended';

  static const Map<String, String> handoverCodes = {
    'demo_wr_06_accepted': 'K7M4P9',
    'demo_wr_07_in_prog': 'Q9R3W8',
    'demo_wr_08_picked_up': 'M4N8X2',
    'demo_wr_09_transit': 'H6P2V5',
    'demo_wr_10_deliv_pend': 'T5K9B3',
  };

  static MashwarDemoCasesBundle build({
    String currentUserId = defaultOwnerUid,
    String? currentUserName,
    DateTime? now,
  }) {
    final ownerUid =
        currentUserId.trim().isNotEmpty ? currentUserId.trim() : defaultOwnerUid;
    final ownerName = (currentUserName != null && currentUserName.trim().isNotEmpty)
        ? currentUserName.trim()
        : defaultOwnerName;
    final anchor = (now ?? DateTime.now()).toUtc();

    final savedWorksites = <SavedWorksite>[
      SavedWorksite(
        id: 'demo_site_lusail_marina',
        ownerUserId: ownerUid,
        label: 'مارينا لوسيل - برج B | Lusail Marina Tower B',
        municipality: 'لوسيل',
        zoneOrStreet: 'منطقة 69، شارع المارينا 210',
        landmark: 'بوابة المقاولين الشمالية',
        gateInstructions: 'الاتصال بمسؤول الموقع قبل الوصول بـ 10 دقائق',
        siteContactName: ownerName,
        siteContactPhone: '55123456',
        latitude: 25.4192,
        longitude: 51.5290,
        isDefault: true,
        createdAt: anchor.subtract(const Duration(days: 10)),
        updatedAt: anchor.subtract(const Duration(days: 2)),
      ),
      SavedWorksite(
        id: 'demo_site_industrial_18',
        ownerUserId: ownerUid,
        label: 'المنطقة الصناعية - ورشة شارع 18 | Industrial Area St. 18 Yard',
        municipality: 'المنطقة الصناعية',
        zoneOrStreet: 'المنطقة الصناعية، شارع 18، قسيمة 44',
        landmark: 'مقابل مخازن المعدات الثقيلة',
        gateInstructions: 'الدخول من بوابة الشحن الخلفية وإبراز سند التوريد',
        siteContactName: 'م. طارق الكواري',
        siteContactPhone: '55224466',
        latitude: 25.1610,
        longitude: 51.4417,
        isDefault: false,
        createdAt: anchor.subtract(const Duration(days: 8)),
        updatedAt: anchor.subtract(const Duration(days: 1)),
      ),
      SavedWorksite(
        id: 'demo_site_wakrah_yard',
        ownerUserId: ownerUid,
        label: 'ساحة الوكرة اللوجستية - قطاع 4 | Al Wakrah Logistics Yard',
        municipality: 'الوكرة',
        zoneOrStreet: 'طريق الوكير، قطاع 90، بوابة 4',
        landmark: 'بجوار محطة وقود وقود الوكرة',
        gateInstructions: 'تسليم السند عند مكتب الأمن الداخلي قبل التفريغ',
        siteContactName: 'م. جاسم المهندي',
        siteContactPhone: '66335577',
        latitude: 25.1715,
        longitude: 51.6034,
        isDefault: false,
        createdAt: anchor.subtract(const Duration(days: 5)),
        updatedAt: anchor.subtract(const Duration(days: 1)),
      ),
    ];

    final providers = <DemoProviderEntry>[
      DemoProviderEntry(
        profile: ProviderProfile(
          id: approvedMainProviderId,
          userId: approvedMainProviderId,
          fullName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
          phone: '55341122',
          qidNumber: '28963401122',
          qidFrontUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_main/qid_front.jpg',
          qidBackUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_main/qid_back.jpg',
          selfieUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_main/selfie.jpg',
          vehicleType: 'Toyota Hilux 4x4 Pickup',
          vehiclePlate: 'قطر 482910',
          serviceMunicipalities: const [
            'الدوحة',
            'لوسيل',
            'المنطقة الصناعية',
            'الريان',
            'الوكرة',
            'مسيعيد',
          ],
          supplySpecialties: const ['electrical', 'plumbing', 'hardware'],
          approvalStatus: ProviderApprovalStatus.approved,
          rating: 4.9,
          completedJobsCount: 24,
          isAvailable: true,
          createdAt: anchor.subtract(const Duration(days: 28)),
          updatedAt: anchor.subtract(const Duration(days: 1)),
        ),
        vehicleLicenseUrl:
            'https://storage.mashwar.qa/kyc/demo_prov_main/istamara.jpg',
        reviewedBy: ownerUid,
        reviewedAtUtc: anchor.subtract(const Duration(days: 25)),
        hasVerificationRecord: true,
      ),
      DemoProviderEntry(
        profile: ProviderProfile(
          id: approvedSafetyProviderId,
          userId: approvedSafetyProviderId,
          fullName: 'طارق جاسم المهندي للسلامة | Tariq Al-Mohannadi Safety',
          phone: '66778899',
          qidNumber: '28745612301',
          qidFrontUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_safety/qid_front.jpg',
          qidBackUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_safety/qid_back.jpg',
          selfieUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_safety/selfie.jpg',
          vehicleType: 'Nissan Urvan Cargo Van',
          vehiclePlate: 'قطر 731042',
          serviceMunicipalities: const [
            'الدوحة',
            'الخور',
            'لوسيل',
            'الضعاين',
            'أم صلال',
          ],
          supplySpecialties: const ['safety_ppe', 'tools', 'electrical'],
          approvalStatus: ProviderApprovalStatus.approved,
          rating: 4.8,
          completedJobsCount: 15,
          isAvailable: true,
          createdAt: anchor.subtract(const Duration(days: 20)),
          updatedAt: anchor.subtract(const Duration(days: 2)),
        ),
        vehicleLicenseUrl:
            'https://storage.mashwar.qa/kyc/demo_prov_safety/istamara.jpg',
        reviewedBy: ownerUid,
        reviewedAtUtc: anchor.subtract(const Duration(days: 18)),
        hasVerificationRecord: true,
      ),
      DemoProviderEntry(
        profile: ProviderProfile(
          id: approvedFastProviderId,
          userId: approvedFastProviderId,
          fullName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
          phone: '77445566',
          qidNumber: '29011223344',
          qidFrontUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_fast/qid_front.jpg',
          qidBackUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_fast/qid_back.jpg',
          selfieUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_fast/selfie.jpg',
          vehicleType: 'Mitsubishi L200 Double Cab',
          vehiclePlate: 'قطر 519204',
          serviceMunicipalities: const [
            'المنطقة الصناعية',
            'الوكرة',
            'مسيعيد',
            'الشيحانية',
            'الشمال',
          ],
          supplySpecialties: const ['civil_materials', 'hardware', 'tools'],
          approvalStatus: ProviderApprovalStatus.approved,
          rating: 4.7,
          completedJobsCount: 11,
          isAvailable: true,
          createdAt: anchor.subtract(const Duration(days: 15)),
          updatedAt: anchor.subtract(const Duration(days: 1)),
        ),
        vehicleLicenseUrl:
            'https://storage.mashwar.qa/kyc/demo_prov_fast/istamara.jpg',
        reviewedBy: ownerUid,
        reviewedAtUtc: anchor.subtract(const Duration(days: 14)),
        hasVerificationRecord: true,
      ),
      if (ownerUid != approvedMainProviderId &&
          ownerUid != approvedSafetyProviderId &&
          ownerUid != approvedFastProviderId)
        DemoProviderEntry(
          profile: ProviderProfile(
            id: ownerUid,
            userId: ownerUid,
            fullName: ownerName,
            phone: '55889900',
            qidNumber: '29263401845',
            qidFrontUrl:
                'https://storage.mashwar.qa/kyc/$ownerUid/qid_front.jpg',
            qidBackUrl: 'https://storage.mashwar.qa/kyc/$ownerUid/qid_back.jpg',
            selfieUrl: 'https://storage.mashwar.qa/kyc/$ownerUid/selfie.jpg',
            vehicleType: 'GMC Sierra 1500 Worksite Pickup',
            vehiclePlate: 'قطر 610482',
            serviceMunicipalities: const [
              'الدوحة',
              'لوسيل',
              'المنطقة الصناعية',
              'الوكرة',
              'الريان',
              'الشيحانية',
            ],
            supplySpecialties: const [
              'electrical',
              'plumbing',
              'hardware',
              'safety_ppe',
            ],
            approvalStatus: ProviderApprovalStatus.approved,
            rating: 4.95,
            completedJobsCount: 12,
            isAvailable: true,
            createdAt: anchor.subtract(const Duration(days: 22)),
            updatedAt: anchor.subtract(const Duration(hours: 6)),
          ),
          vehicleLicenseUrl:
              'https://storage.mashwar.qa/kyc/$ownerUid/istamara.jpg',
          reviewedBy: ownerUid,
          reviewedAtUtc: anchor.subtract(const Duration(days: 21)),
          hasVerificationRecord: true,
        ),
      DemoProviderEntry(
        profile: ProviderProfile(
          id: pendingReviewProviderId,
          userId: pendingReviewProviderId,
          fullName: 'سالم فهد الدوسري | Salem Al-Dosari',
          phone: '77112233',
          qidNumber: '29663401842',
          qidFrontUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_pending/qid_front.jpg',
          qidBackUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_pending/qid_back.jpg',
          selfieUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_pending/selfie.jpg',
          vehicleType: 'Ford Ranger Pickup',
          vehiclePlate: 'قطر 902150',
          serviceMunicipalities: const ['الوكرة', 'مسيعيد', 'الدوحة'],
          supplySpecialties: const ['hardware', 'plumbing'],
          approvalStatus: ProviderApprovalStatus.pending,
          rating: 0.0,
          completedJobsCount: 0,
          isAvailable: false,
          createdAt: anchor.subtract(const Duration(hours: 7)),
          updatedAt: anchor.subtract(const Duration(hours: 4)),
        ),
        vehicleLicenseUrl:
            'https://storage.mashwar.qa/kyc/demo_prov_pending/istamara.jpg',
        hasVerificationRecord: true,
      ),
      DemoProviderEntry(
        profile: ProviderProfile(
          id: pendingUnverifiedProviderId,
          userId: pendingUnverifiedProviderId,
          fullName: 'عبدالعزيز حمد النعيمي | Abdulaziz Al-Nuaimi',
          phone: '50119988',
          qidNumber: null,
          qidFrontUrl: null,
          qidBackUrl: null,
          selfieUrl: null,
          vehicleType: 'Isuzu D-Max',
          vehiclePlate: 'قطر 314509',
          serviceMunicipalities: const ['الريان', 'أم صلال'],
          supplySpecialties: const ['general_site_supply'],
          approvalStatus: ProviderApprovalStatus.pending,
          rating: 0.0,
          completedJobsCount: 0,
          isAvailable: false,
          createdAt: anchor.subtract(const Duration(hours: 3)),
          updatedAt: anchor.subtract(const Duration(hours: 3)),
        ),
        hasVerificationRecord: false,
      ),
      DemoProviderEntry(
        profile: ProviderProfile(
          id: rejectedProviderId,
          userId: rejectedProviderId,
          fullName: 'جاسم محمد الكعبي | Jassim Al-Kaabi',
          phone: '66448822',
          qidNumber: '29163407781',
          qidFrontUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_rejected/qid_front.jpg',
          qidBackUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_rejected/qid_back.jpg',
          selfieUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_rejected/selfie.jpg',
          vehicleType: 'Toyota Land Cruiser Pickup',
          vehiclePlate: 'قطر 339105',
          serviceMunicipalities: const ['الضعاين', 'لوسيل'],
          supplySpecialties: const ['civil_materials'],
          approvalStatus: ProviderApprovalStatus.rejected,
          rejectionReason:
              'صورة الوجه الخلفي للبطاقة القطرية (QID) منتهية الصلاحية وغير واضحة — يرجى إعادة الرفع | Back of Qatar QID is expired and blurry.',
          rating: 0.0,
          completedJobsCount: 0,
          isAvailable: false,
          createdAt: anchor.subtract(const Duration(days: 6)),
          updatedAt: anchor.subtract(const Duration(days: 4)),
        ),
        vehicleLicenseUrl:
            'https://storage.mashwar.qa/kyc/demo_prov_rejected/istamara.jpg',
        reviewedBy: ownerUid,
        reviewedAtUtc: anchor.subtract(const Duration(days: 4)),
        hasVerificationRecord: true,
      ),
      DemoProviderEntry(
        profile: ProviderProfile(
          id: suspendedProviderId,
          userId: suspendedProviderId,
          fullName: 'مشعل سلطان العطية | Mishaal Al-Attiyah',
          phone: '55998811',
          qidNumber: '28863405599',
          qidFrontUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_suspended/qid_front.jpg',
          qidBackUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_suspended/qid_back.jpg',
          selfieUrl:
              'https://storage.mashwar.qa/kyc/demo_prov_suspended/selfie.jpg',
          vehicleType: 'Hyundai H100 Van',
          vehiclePlate: 'قطر 228941',
          serviceMunicipalities: const ['الدوحة', 'الريان'],
          supplySpecialties: const ['tools', 'hardware'],
          approvalStatus: ProviderApprovalStatus.suspended,
          rejectionReason:
              'إيقاف مؤقت لحين تجديد رخصة المركبة (استمارة قطر) | Suspended pending Qatar vehicle istamara renewal.',
          rating: 4.2,
          completedJobsCount: 6,
          isAvailable: false,
          createdAt: anchor.subtract(const Duration(days: 14)),
          updatedAt: anchor.subtract(const Duration(days: 2)),
        ),
        vehicleLicenseUrl:
            'https://storage.mashwar.qa/kyc/demo_prov_suspended/istamara.jpg',
        reviewedBy: ownerUid,
        reviewedAtUtc: anchor.subtract(const Duration(days: 2)),
        hasVerificationRecord: true,
      ),
    ];

    final requests = <WorkRequest>[
      // 1. open (mine - Lusail, COD, unpaid, urgent)
      WorkRequest(
        id: 'demo_wr_01_open_mine',
        requesterId: ownerUid,
        requesterName: ownerName,
        savedWorksiteId: 'demo_site_lusail_marina',
        title:
            'قواطع كهربائية Schneider 32A وكابلات نحاس | Schneider 32A Breakers & Copper Cables',
        description:
            'توريد 12 قاطع كهربائي Schneider 32A و3 لفات أسلاك نحاس 4مم من المنطقة الصناعية مع فاتورة متجر معتمدة.',
        supplyCategory: 'electrical',
        pickupLocation: 'المنطقة الصناعية - شارع 10 (شركة الدوحة للكهرباء)',
        dropoffWorksite: 'مارينا لوسيل - برج B',
        municipality: 'لوسيل',
        siteContactName: ownerName,
        siteContactPhone: '55123456',
        itemNotes: 'التأكد من ختم الوكيل المعتمد على الكرتون وإرفاق الفاتورة.',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(420),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(480),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(55),
        status: WorkRequestStatus.open,
        paymentMethod: PaymentMethod.cashOnDelivery,
        paymentSettlementStatus: PaymentSettlementStatus.unpaid,
        createdAt: anchor.subtract(const Duration(minutes: 25)),
        updatedAt: anchor.subtract(const Duration(minutes: 25)),
        scheduledBy: anchor.add(const Duration(hours: 3)),
      ),

      // 2. open (marketplace peer - Industrial Area, bank transfer, unpaid, urgent)
      WorkRequest(
        id: 'demo_wr_02_open_mkt',
        requesterId: peerRequesterKhaledId,
        requesterName: 'م. خالد العطية (شركة المدار)',
        title:
            'أسمنت مقاوم للأملاح 30 كيس وشبكة تسليح | 30 Bags Sulfate-Resistant Cement',
        description:
            'مطلوب 30 كيس أسمنت قطري مقاوم للأملاح مع شبك حديدي خفيف وتسليم فوري لساحة المدار.',
        supplyCategory: 'civil_materials',
        pickupLocation: 'المنطقة الصناعية - ساحة 22 لمواد البناء',
        dropoffWorksite: 'المنطقة الصناعية - مستودع المدار شارع 33',
        municipality: 'المنطقة الصناعية',
        siteContactName: 'م. خالد العطية',
        siteContactPhone: '50312290',
        itemNotes: 'تغطية الأكياس بمشمع مقاوم للرطوبة أثناء التحميل.',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(560),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(650),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(70),
        status: WorkRequestStatus.open,
        paymentMethod: PaymentMethod.bankTransferManual,
        paymentSettlementStatus: PaymentSettlementStatus.unpaid,
        createdAt: anchor.subtract(const Duration(minutes: 45)),
        updatedAt: anchor.subtract(const Duration(minutes: 45)),
        scheduledBy: anchor.add(const Duration(hours: 4)),
      ),

      // 3. offer_received (mine - 3 competing offers! Doha, bank transfer, unpaid)
      WorkRequest(
        id: 'demo_wr_03_offers_mine',
        requesterId: ownerUid,
        requesterName: ownerName,
        title:
            'مواسير PPR إيطالية 32مم ومحابس نحاس | Italian 32mm PPR Pipes & Brass Valves',
        description:
            '20 ماسورة PPR مقاس 32مم مع 8 محابس نحاس إيطالي، مطلوب مقارنة عروض الموردين قبل الترسية.',
        supplyCategory: 'plumbing',
        pickupLocation: 'طريق سلوى - مجمع الدوحة للسباكة',
        dropoffWorksite: 'مشيرب قلب الدوحة - مبنى الصيانة 4',
        municipality: 'الدوحة',
        siteContactName: ownerName,
        siteContactPhone: '55123456',
        itemNotes: 'مطابقة المقاس 32mm PN20 مع الفاتورة الأصلية.',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(340),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(400),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(50),
        status: WorkRequestStatus.offerReceived,
        offerCount: 3,
        paymentMethod: PaymentMethod.bankTransferManual,
        paymentSettlementStatus: PaymentSettlementStatus.unpaid,
        createdAt: anchor.subtract(const Duration(hours: 2)),
        updatedAt: anchor.subtract(const Duration(minutes: 15)),
        scheduledBy: anchor.add(const Duration(hours: 5)),
      ),

      // 4. offer_received (marketplace peer - Al Wakrah, COD, unpaid)
      WorkRequest(
        id: 'demo_wr_04_offers_mkt',
        requesterId: peerRequesterSaraId,
        requesterName: 'م. سارة الكواري (الخليج الهندسية)',
        title:
            'خوذات سلامة MSA وسترات عاكسة (25 طقم) | 25 MSA Safety Helmets & Vests',
        description:
            'توريد مستلزمات السلامة المهنية المعتمدة لفرق التشغيل في مرفأ الوكرة.',
        supplyCategory: 'safety_ppe',
        pickupLocation: 'المنطقة الصناعية - مركز الخليج للسلامة المهنية',
        dropoffWorksite: 'الوكرة - مشروع المرفأ الساحلي بوابة 2',
        municipality: 'الوكرة',
        siteContactName: 'مشرف السلامة راشد',
        siteContactPhone: '55449988',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(480),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(550),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(60),
        status: WorkRequestStatus.offerReceived,
        offerCount: 1,
        paymentMethod: PaymentMethod.cashOnDelivery,
        paymentSettlementStatus: PaymentSettlementStatus.unpaid,
        createdAt: anchor.subtract(const Duration(hours: 3)),
        updatedAt: anchor.subtract(const Duration(minutes: 40)),
        scheduledBy: anchor.add(const Duration(hours: 6)),
      ),

      // 5. offer_selected (mine - Al Rayyan, COD, unpaid)
      WorkRequest(
        id: 'demo_wr_05_offer_sel',
        requesterId: ownerUid,
        requesterName: ownerName,
        title:
            'مثقاب خرسانة Makita SDS-Plus وقرص قص | Makita SDS-Plus Hammer Drill',
        description:
            'شراء مثقاب خرسانة مع طقم ريش 8-16مم وقرص قطع ألماس من وكيل المعدات.',
        supplyCategory: 'tools',
        pickupLocation: 'طريق سلوى - وكيل معدات البناء',
        dropoffWorksite: 'الريان - المدينة التعليمية بوابة الصيانة 6',
        municipality: 'الريان',
        siteContactName: 'م. يوسف السليطي',
        siteContactPhone: '55771122',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(780),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(850),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(65),
        agreedFeeMinor: MoneyMinor.fromMajorQar(60),
        selectedOfferId: 'demo_off_05',
        assignedProviderId: approvedFastProviderId,
        assignedProviderName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
        offerCount: 1,
        status: WorkRequestStatus.offerSelected,
        paymentMethod: PaymentMethod.cashOnDelivery,
        paymentSettlementStatus: PaymentSettlementStatus.unpaid,
        createdAt: anchor.subtract(const Duration(hours: 4)),
        updatedAt: anchor.subtract(const Duration(hours: 1)),
      ),

      // 6. accepted (mine - Al Khor, bank transfer with proof submitted, code K7M4P9)
      WorkRequest(
        id: 'demo_wr_06_accepted',
        requesterId: ownerUid,
        requesterName: ownerName,
        title:
            'مرابط تثبيت فولاذية M16 ومفاتيح عزم | M16 Steel Anchor Bolts & Wrenches',
        description:
            'توريد 100 مسمار تثبيت فولاذي M16 مع مفاتيح شد عيارية لبوابة رأس لفان.',
        supplyCategory: 'hardware',
        pickupLocation: 'المنطقة الصناعية - شارع 14 مستودع الحديد',
        dropoffWorksite: 'الخور - بوابة رأس لفان اللوجستية 3',
        municipality: 'الخور',
        siteContactName: 'مشرف التركيبات فهد',
        siteContactPhone: '66332211',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(620),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(700),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(85),
        agreedFeeMinor: MoneyMinor.fromMajorQar(80),
        selectedOfferId: 'demo_off_seed_06',
        assignedProviderId: approvedMainProviderId,
        assignedProviderName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
        offerCount: 2,
        status: WorkRequestStatus.accepted,
        paymentMethod: PaymentMethod.bankTransferManual,
        paymentSettlementStatus: PaymentSettlementStatus.transferProofSubmitted,
        paymentProofUrl:
            'https://storage.mashwar.qa/demo/proof_demo_wr_06_qnb.jpg',
        paymentReference: 'QNB-2026-44102',
        createdAt: anchor.subtract(const Duration(hours: 6)),
        updatedAt: anchor.subtract(const Duration(hours: 2)),
      ),

      // 7. in_progress (mine - Umm Salal, COD, unpaid, code Q9R3W8)
      WorkRequest(
        id: 'demo_wr_07_in_prog',
        requesterId: ownerUid,
        requesterName: ownerName,
        title:
            'طفايات حريق CO2 6كجم ولوحات تحذير | 6kg CO2 Fire Extinguishers & Signage',
        description:
            'تجهيز 6 طفايات حريق معتمدة من الدفاع المدني مع لوحات إرشادية لمستودع أم صلال.',
        supplyCategory: 'safety_ppe',
        pickupLocation: 'الدوحة - شارع المطار التجاري معدات السلامة',
        dropoffWorksite: 'أم صلال محمد - مجمع المخازن رقم 9',
        municipality: 'أم صلال',
        siteContactName: 'مشرف المستودع عادل',
        siteContactPhone: '55883322',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(510),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(580),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(55),
        agreedFeeMinor: MoneyMinor.fromMajorQar(50),
        selectedOfferId: 'demo_off_seed_07',
        assignedProviderId: approvedSafetyProviderId,
        assignedProviderName: 'طارق جاسم المهندي للسلامة | Tariq Al-Mohannadi Safety',
        offerCount: 1,
        status: WorkRequestStatus.inProgress,
        paymentMethod: PaymentMethod.cashOnDelivery,
        paymentSettlementStatus: PaymentSettlementStatus.unpaid,
        createdAt: anchor.subtract(const Duration(hours: 8)),
        updatedAt: anchor.subtract(const Duration(hours: 1, minutes: 30)),
      ),

      // 8. picked_up (mine - Al Daayen, bank transfer proof submitted, receipt attached, code M4N8X2)
      WorkRequest(
        id: 'demo_wr_08_picked_up',
        requesterId: ownerUid,
        requesterName: ownerName,
        title:
            'كشافات LED مقاومة للماء 150W للموقع | IP66 150W Site LED Floodlights',
        description:
            'شراء 8 كشافات LED للعمل الليلي بالموقع مع إرفاق فاتورة المتجر الأصلية.',
        supplyCategory: 'electrical',
        pickupLocation: 'المنطقة الصناعية - شارع 10 معرض الإنارة',
        dropoffWorksite: 'الضعاين - مشروع الفلل الشمالية قطعة 14',
        municipality: 'الضعاين',
        siteContactName: 'المهندس ماجد',
        siteContactPhone: '55994411',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(450),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(500),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(50),
        agreedFeeMinor: MoneyMinor.fromMajorQar(45),
        selectedOfferId: 'demo_off_seed_08',
        assignedProviderId: approvedFastProviderId,
        assignedProviderName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
        receiptImageUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_08.jpg',
        actualReceiptTotalMinor: MoneyMinor.fromMajorQar(435),
        offerCount: 2,
        status: WorkRequestStatus.pickedUp,
        paymentMethod: PaymentMethod.bankTransferManual,
        paymentSettlementStatus: PaymentSettlementStatus.transferProofSubmitted,
        paymentProofUrl:
            'https://storage.mashwar.qa/demo/proof_demo_wr_08_cbq.jpg',
        paymentReference: 'CBQ-2026-55819',
        createdAt: anchor.subtract(const Duration(hours: 10)),
        updatedAt: anchor.subtract(const Duration(minutes: 50)),
      ),

      // 9. in_transit (mine - Mesaieed, COD, unpaid, receipt attached, code H6P2V5)
      WorkRequest(
        id: 'demo_wr_09_transit',
        requesterId: ownerUid,
        requesterName: ownerName,
        title:
            'عوازل مائية بيتومين وغراء سيراميك صناعي | Bitumen Waterproofing & Adhesive',
        description:
            'توريد 10 براميل عازل مائي و15 كيس غراء صناعي لمحطة الصيانة في مسيعيد.',
        supplyCategory: 'civil_materials',
        pickupLocation: 'المنطقة الصناعية - شارع 28 مستودع العوازل',
        dropoffWorksite: 'مسيعيد الصناعية - محطة الصيانة البحرية',
        municipality: 'مسيعيد',
        siteContactName: 'م. حمد البوعينين',
        siteContactPhone: '66115522',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(720),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(780),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(95),
        agreedFeeMinor: MoneyMinor.fromMajorQar(90),
        selectedOfferId: 'demo_off_seed_09',
        assignedProviderId: approvedMainProviderId,
        assignedProviderName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
        receiptImageUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_09.jpg',
        actualReceiptTotalMinor: MoneyMinor.fromMajorQar(710),
        offerCount: 2,
        status: WorkRequestStatus.inTransit,
        paymentMethod: PaymentMethod.cashOnDelivery,
        paymentSettlementStatus: PaymentSettlementStatus.unpaid,
        createdAt: anchor.subtract(const Duration(hours: 12)),
        updatedAt: anchor.subtract(const Duration(minutes: 30)),
      ),

      // 10. delivered_pending_confirmation (assigned to currentUserId so user can test 6-char handover verify T5K9B3!)
      WorkRequest(
        id: 'demo_wr_10_deliv_pend',
        requesterId: peerRequesterKhaledId,
        requesterName: 'م. خالد العطية (شركة المدار)',
        title:
            'مضخة ضغط مياه 2 حصان ومفاتيح أوتوماتيك | 2HP Booster Pump & Pressure Switch',
        description:
            'وصلت الشحنة مع الفاتورة الأصلية إلى موقع الشيحانية بانتظار إدخال رمز التسليم T5K9B3 لإغلاق الطلب.',
        supplyCategory: 'plumbing',
        pickupLocation: 'طريق سلوى - مركز المضخات القطري',
        dropoffWorksite: 'الشيحانية - محطة الخدمات بوابة 2',
        municipality: 'الشيحانية',
        siteContactName: 'م. خالد العطية',
        siteContactPhone: '50312290',
        itemNotes: 'استخدم رمز التسليم التجريبي T5K9B3 لتأكيد التسليم وإكمال المهمة.',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(540),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(600),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(80),
        agreedFeeMinor: MoneyMinor.fromMajorQar(75),
        selectedOfferId: 'demo_off_seed_10',
        assignedProviderId: ownerUid,
        assignedProviderName: ownerName,
        receiptImageUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_10.jpg',
        actualReceiptTotalMinor: MoneyMinor.fromMajorQar(530),
        offerCount: 2,
        status: WorkRequestStatus.deliveredPendingConfirmation,
        paymentMethod: PaymentMethod.bankTransferManual,
        paymentSettlementStatus: PaymentSettlementStatus.transferProofSubmitted,
        paymentProofUrl:
            'https://storage.mashwar.qa/demo/proof_demo_wr_10_qib.jpg',
        paymentReference: 'FAWRAN-2026-88301',
        createdAt: anchor.subtract(const Duration(hours: 15)),
        updatedAt: anchor.subtract(const Duration(minutes: 10)),
      ),

      // 11. completed (mine - Al Shamal, COD, verifiedSettled)
      WorkRequest(
        id: 'demo_wr_11_comp_cash',
        requesterId: ownerUid,
        requesterName: ownerName,
        title:
            'أقفال أمان حديدية وسلاسل ربط للمعدات | Heavy-Duty Padlocks & Equipment Chains',
        description:
            'تم شراء 15 قفل أمان ثقيل وسلاسل تثبيت وتسليمها في ميناء الرويس بالشمال.',
        supplyCategory: 'hardware',
        pickupLocation: 'الخور - سوق المعدات المركزي',
        dropoffWorksite: 'الشمال - مشروع ميناء الرويس قطاع C',
        municipality: 'الشمال',
        siteContactName: 'مشرف المخازن علي',
        siteContactPhone: '55441100',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(400),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(450),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(110),
        agreedFeeMinor: MoneyMinor.fromMajorQar(100),
        selectedOfferId: 'demo_off_seed_11',
        assignedProviderId: approvedMainProviderId,
        assignedProviderName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
        receiptImageUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_11.jpg',
        actualReceiptTotalMinor: MoneyMinor.fromMajorQar(390),
        offerCount: 2,
        isHandoverVerified: true,
        status: WorkRequestStatus.completed,
        paymentMethod: PaymentMethod.cashOnDelivery,
        paymentSettlementStatus: PaymentSettlementStatus.verifiedSettled,
        paymentReference: 'COD-2026-10492',
        createdAt: anchor.subtract(const Duration(days: 2)),
        updatedAt: anchor.subtract(const Duration(days: 1, hours: 18)),
      ),

      // 12. completed (provider-assigned to currentUserId - Lusail, bank transfer, verifiedSettled)
      WorkRequest(
        id: 'demo_wr_12_comp_bank',
        requesterId: peerRequesterSaraId,
        requesterName: 'م. سارة الكواري (الخليج الهندسية)',
        title:
            'لوحة توزيع فرعية 3 فاز وقاطع رئيسي 100A | 3-Phase Distribution Board 100A',
        description:
            'توريد لوحة توزيع كهربائية 3 فاز مع قاطع 100A وفاتورة ضريبية معتمدة لبوليفارد لوسيل.',
        supplyCategory: 'electrical',
        pickupLocation: 'المنطقة الصناعية - شارع 10 الموزع الكهربائي',
        dropoffWorksite: 'لوسيل - منطقة البوليفارد مبنى الأعمال 7',
        municipality: 'لوسيل',
        siteContactName: 'م. سارة الكواري',
        siteContactPhone: '55449988',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(880),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(950),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(75),
        agreedFeeMinor: MoneyMinor.fromMajorQar(70),
        selectedOfferId: 'demo_off_seed_12',
        assignedProviderId: ownerUid,
        assignedProviderName: ownerName,
        receiptImageUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_12.jpg',
        actualReceiptTotalMinor: MoneyMinor.fromMajorQar(865),
        offerCount: 3,
        isHandoverVerified: true,
        status: WorkRequestStatus.completed,
        paymentMethod: PaymentMethod.bankTransferManual,
        paymentSettlementStatus: PaymentSettlementStatus.verifiedSettled,
        paymentProofUrl:
            'https://storage.mashwar.qa/demo/proof_demo_wr_12_qnb.jpg',
        paymentReference: 'QNB-2026-77419',
        createdAt: anchor.subtract(const Duration(days: 3)),
        updatedAt: anchor.subtract(const Duration(days: 2, hours: 20)),
      ),

      // 13. cancelled (mine - Al Wakrah, COD, unpaid)
      WorkRequest(
        id: 'demo_wr_13_cancelled',
        requesterId: ownerUid,
        requesterName: ownerName,
        savedWorksiteId: 'demo_site_wakrah_yard',
        title:
            'مواد تغليف وبلاستيك حماية للأرضيات | Heavy Polythene Floor Protection Rolls',
        description:
            'طلب 10 لفات بلاستيك حماية ثقيل لأرضيات المستودع قبل البدء بأعمال الدهان.',
        supplyCategory: 'general_site_supply',
        pickupLocation: 'طريق سلوى - سوق الجملة',
        dropoffWorksite: 'ساحة الوكرة اللوجستية - قطاع 4',
        municipality: 'الوكرة',
        siteContactName: 'م. جاسم المهندي',
        siteContactPhone: '66335577',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(260),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(300),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(45),
        cancellationReason:
            'تم توفير الكمية من المستودع الداخلي للمشروع قبل الترسية | Quantities sourced from project warehouse.',
        status: WorkRequestStatus.cancelled,
        paymentMethod: PaymentMethod.cashOnDelivery,
        paymentSettlementStatus: PaymentSettlementStatus.unpaid,
        createdAt: anchor.subtract(const Duration(days: 4)),
        updatedAt: anchor.subtract(const Duration(days: 3, hours: 22)),
      ),

      // 14. disputed (mine - Doha, bank transfer, payment disputed)
      WorkRequest(
        id: 'demo_wr_14_disputed',
        requesterId: ownerUid,
        requesterName: ownerName,
        savedWorksiteId: 'demo_site_industrial_18',
        title:
            'صمامات عدم رجوع نحاسية 2 إنش PN16 | 2-Inch Brass Check Valves PN16',
        description:
            'توريد 12 صمام عدم رجوع نحاسي مقاس 2 إنش لغرفة المضخات في الدفنة.',
        supplyCategory: 'plumbing',
        pickupLocation: 'المنطقة الصناعية - شارع 18 مخزن الصمامات',
        dropoffWorksite: 'الدفنة - برج الأعمال رقم 12 غرفة المضخات',
        municipality: 'الدوحة',
        siteContactName: 'م. طارق الكواري',
        siteContactPhone: '55224466',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(460),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(520),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(60),
        agreedFeeMinor: MoneyMinor.fromMajorQar(55),
        selectedOfferId: 'demo_off_seed_14',
        assignedProviderId: approvedFastProviderId,
        assignedProviderName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
        receiptImageUrl: 'https://storage.mashwar.qa/demo/inv_demo_wr_14.jpg',
        actualReceiptTotalMinor: MoneyMinor.fromMajorQar(495),
        offerCount: 2,
        disputeReason:
            'اختلاف مقاس الصمامات الموردة عن المواصفة الهندسية (1.5 إنش بدلاً من 2 إنش) | Supplied 1.5" valves instead of 2" PN16 spec.',
        status: WorkRequestStatus.disputed,
        paymentMethod: PaymentMethod.bankTransferManual,
        paymentSettlementStatus: PaymentSettlementStatus.disputed,
        paymentProofUrl:
            'https://storage.mashwar.qa/demo/proof_demo_wr_14_qnb.jpg',
        paymentReference: 'QNB-2026-66201',
        createdAt: anchor.subtract(const Duration(days: 1, hours: 6)),
        updatedAt: anchor.subtract(const Duration(hours: 3)),
      ),
    ];

    final offersByRequest = <String, List<WorkOffer>>{
      'demo_wr_03_offers_mine': [
        WorkOffer(
          id: 'demo_off_01',
          requestId: 'demo_wr_03_offers_mine',
          providerId: approvedMainProviderId,
          providerName: 'خالد بن حمد المناعي للتوريدات | Khalid Al-Mannai Supply',
          providerRating: 4.9,
          providerCompletedJobs: 24,
          proposedFeeMinor: MoneyMinor.fromMajorQar(45),
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(330),
          estimatedEtaMinutes: 35,
          notes:
              'متواجد قرب طريق سلوى والسيارة البيك أب جاهزة مع فاتورة ضريبية فورية.',
          isSelected: false,
          status: 'pending',
          createdAt: anchor.subtract(const Duration(minutes: 55)),
          updatedAt: anchor.subtract(const Duration(minutes: 55)),
        ),
        WorkOffer(
          id: 'demo_off_02',
          requestId: 'demo_wr_03_offers_mine',
          providerId: approvedSafetyProviderId,
          providerName: 'طارق جاسم المهندي للسلامة | Tariq Al-Mohannadi Safety',
          providerRating: 4.8,
          providerCompletedJobs: 15,
          proposedFeeMinor: MoneyMinor.fromMajorQar(50),
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(340),
          estimatedEtaMinutes: 45,
          notes:
              'تسليم مباشر لبوابة الصيانة في مشيرب مع تغليف محكم للمحابس.',
          isSelected: false,
          status: 'pending',
          createdAt: anchor.subtract(const Duration(minutes: 35)),
          updatedAt: anchor.subtract(const Duration(minutes: 35)),
        ),
        WorkOffer(
          id: 'demo_off_03',
          requestId: 'demo_wr_03_offers_mine',
          providerId: approvedFastProviderId,
          providerName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
          providerRating: 4.7,
          providerCompletedJobs: 11,
          proposedFeeMinor: MoneyMinor.fromMajorQar(40),
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(350),
          estimatedEtaMinutes: 55,
          notes: 'أقل رسوم توصيل مع الالتزام بمواصفات PN20 الإيطالية.',
          isSelected: false,
          status: 'pending',
          createdAt: anchor.subtract(const Duration(minutes: 15)),
          updatedAt: anchor.subtract(const Duration(minutes: 15)),
        ),
      ],
      'demo_wr_04_offers_mkt': [
        WorkOffer(
          id: 'demo_off_04',
          requestId: 'demo_wr_04_offers_mkt',
          providerId: approvedSafetyProviderId,
          providerName: 'طارق جاسم المهندي للسلامة | Tariq Al-Mohannadi Safety',
          providerRating: 4.8,
          providerCompletedJobs: 15,
          proposedFeeMinor: MoneyMinor.fromMajorQar(55),
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(475),
          estimatedEtaMinutes: 50,
          notes:
              'خبرة في توريد معدات السلامة المهنية PPE ومطابقة مواصفات HSE.',
          isSelected: false,
          status: 'pending',
          createdAt: anchor.subtract(const Duration(minutes: 40)),
          updatedAt: anchor.subtract(const Duration(minutes: 40)),
        ),
      ],
      'demo_wr_05_offer_sel': [
        WorkOffer(
          id: 'demo_off_05',
          requestId: 'demo_wr_05_offer_sel',
          providerId: approvedFastProviderId,
          providerName: 'ناصر راشد الهاجري للنقل السريع | Nasser Al-Hajri Supply',
          providerRating: 4.7,
          providerCompletedJobs: 11,
          proposedFeeMinor: MoneyMinor.fromMajorQar(60),
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(760),
          estimatedEtaMinutes: 40,
          notes: 'تم فحص توفر المثقاب الأصلي لدى الوكيل وجاهز للتنفيذ.',
          isSelected: true,
          status: 'accepted',
          createdAt: anchor.subtract(const Duration(hours: 2)),
          updatedAt: anchor.subtract(const Duration(hours: 1)),
        ),
      ],
    };

    final eventsByRequest = <String, List<RequestEvent>>{
      'demo_wr_01_open_mine': [
        RequestEvent(
          id: 'demo_evt_01_1',
          requestId: 'demo_wr_01_open_mine',
          actorId: ownerUid,
          actorRole: 'requester',
          eventType: 'request_created',
          toStatus: WorkRequestStatus.open,
          note: 'تم نشر طلب التوريد لموقع مارينا لوسيل بانتظار عروض المزودين.',
          createdAt: anchor.subtract(const Duration(minutes: 25)),
        ),
      ],
      'demo_wr_02_open_mkt': [
        RequestEvent(
          id: 'demo_evt_02_1',
          requestId: 'demo_wr_02_open_mkt',
          actorId: peerRequesterKhaledId,
          actorRole: 'requester',
          eventType: 'request_created',
          toStatus: WorkRequestStatus.open,
          note: 'تم نشر طلب توريد مواد بناء للمنطقة الصناعية.',
          createdAt: anchor.subtract(const Duration(minutes: 45)),
        ),
      ],
      'demo_wr_03_offers_mine': [
        RequestEvent(
          id: 'demo_evt_03_1',
          requestId: 'demo_wr_03_offers_mine',
          actorId: ownerUid,
          actorRole: 'requester',
          eventType: 'request_created',
          toStatus: WorkRequestStatus.open,
          note: 'تم إنشاء طلب السباكة لمشروع مشيرب.',
          createdAt: anchor.subtract(const Duration(hours: 2)),
        ),
        RequestEvent(
          id: 'demo_evt_03_2',
          requestId: 'demo_wr_03_offers_mine',
          actorId: approvedMainProviderId,
          actorRole: 'provider',
          eventType: 'offer_submitted',
          fromStatus: WorkRequestStatus.open,
          toStatus: WorkRequestStatus.offerReceived,
          note: 'تم تقديم 3 عروض تنافسية من مزودين معتمدين بالبطاقة القطرية.',
          metadata: const {'offerId': 'demo_off_01', 'feeMinor': 4500},
          createdAt: anchor.subtract(const Duration(minutes: 55)),
        ),
      ],
      'demo_wr_04_offers_mkt': [
        RequestEvent(
          id: 'demo_evt_04_1',
          requestId: 'demo_wr_04_offers_mkt',
          actorId: peerRequesterSaraId,
          actorRole: 'requester',
          eventType: 'request_created',
          toStatus: WorkRequestStatus.open,
          note: 'تم نشر طلب خوذات السلامة لمرفأ الوكرة.',
          createdAt: anchor.subtract(const Duration(hours: 3)),
        ),
        RequestEvent(
          id: 'demo_evt_04_2',
          requestId: 'demo_wr_04_offers_mkt',
          actorId: approvedSafetyProviderId,
          actorRole: 'provider',
          eventType: 'offer_submitted',
          fromStatus: WorkRequestStatus.open,
          toStatus: WorkRequestStatus.offerReceived,
          note: 'عرض مقدم من طارق المهندي للسلامة (55 ر.ق رسوم توصيل).',
          metadata: const {'offerId': 'demo_off_04', 'feeMinor': 5500},
          createdAt: anchor.subtract(const Duration(minutes: 40)),
        ),
      ],
      'demo_wr_05_offer_sel': [
        RequestEvent(
          id: 'demo_evt_05_1',
          requestId: 'demo_wr_05_offer_sel',
          actorId: ownerUid,
          actorRole: 'requester',
          eventType: 'request_created',
          toStatus: WorkRequestStatus.open,
          note: 'تم إنشاء طلب المثقاب الكهربائي لموقع الريان.',
          createdAt: anchor.subtract(const Duration(hours: 4)),
        ),
        RequestEvent(
          id: 'demo_evt_05_2',
          requestId: 'demo_wr_05_offer_sel',
          actorId: ownerUid,
          actorRole: 'requester',
          eventType: 'offer_selected',
          fromStatus: WorkRequestStatus.offerReceived,
          toStatus: WorkRequestStatus.offerSelected,
          note: 'تم اختيار عرض ناصر الهاجري بانتظار تأكيد بدء التنفيذ.',
          metadata: const {'offerId': 'demo_off_05', 'feeMinor': 6000},
          createdAt: anchor.subtract(const Duration(hours: 1)),
        ),
      ],
      'demo_wr_06_accepted': [
        RequestEvent(
          id: 'demo_evt_06_1',
          requestId: 'demo_wr_06_accepted',
          actorId: ownerUid,
          actorRole: 'requester',
          eventType: 'offer_accepted',
          fromStatus: WorkRequestStatus.offerSelected,
          toStatus: WorkRequestStatus.accepted,
          note: 'تم قبول العرض وإصدار رمز التسليم السري (6 خانات).',
          createdAt: anchor.subtract(const Duration(hours: 3)),
        ),
        RequestEvent(
          id: 'demo_evt_06_2',
          requestId: 'demo_wr_06_accepted',
          actorId: ownerUid,
          actorRole: 'requester',
          eventType: 'payment_status_changed',
          fromStatus: WorkRequestStatus.accepted,
          toStatus: WorkRequestStatus.accepted,
          note: 'تم رفع إيصال التحويل البنكي QNB-2026-44102 بانتظار المراجعة.',
          createdAt: anchor.subtract(const Duration(hours: 2)),
        ),
      ],
      'demo_wr_07_in_prog': [
        RequestEvent(
          id: 'demo_evt_07_1',
          requestId: 'demo_wr_07_in_prog',
          actorId: ownerUid,
          actorRole: 'requester',
          eventType: 'offer_accepted',
          fromStatus: WorkRequestStatus.offerSelected,
          toStatus: WorkRequestStatus.accepted,
          note: 'تم قبول العرض وتعيين طارق المهندي للتوريد.',
          createdAt: anchor.subtract(const Duration(hours: 5)),
        ),
        RequestEvent(
          id: 'demo_evt_07_2',
          requestId: 'demo_wr_07_in_prog',
          actorId: approvedSafetyProviderId,
          actorRole: 'provider',
          eventType: 'status_changed',
          fromStatus: WorkRequestStatus.accepted,
          toStatus: WorkRequestStatus.inProgress,
          note: 'توجه المزود إلى مورد السلامة المهنية في شارع المطار.',
          createdAt: anchor.subtract(const Duration(hours: 1, minutes: 30)),
        ),
      ],
      'demo_wr_08_picked_up': [
        RequestEvent(
          id: 'demo_evt_08_1',
          requestId: 'demo_wr_08_picked_up',
          actorId: approvedFastProviderId,
          actorRole: 'provider',
          eventType: 'status_changed',
          fromStatus: WorkRequestStatus.inProgress,
          toStatus: WorkRequestStatus.pickedUp,
          note: 'تم شراء الكشافات وإرفاق فاتورة المتجر بقيمة 435 ر.ق.',
          createdAt: anchor.subtract(const Duration(minutes: 50)),
        ),
      ],
      'demo_wr_09_transit': [
        RequestEvent(
          id: 'demo_evt_09_1',
          requestId: 'demo_wr_09_transit',
          actorId: approvedMainProviderId,
          actorRole: 'provider',
          eventType: 'status_changed',
          fromStatus: WorkRequestStatus.pickedUp,
          toStatus: WorkRequestStatus.inTransit,
          note: 'المزود في الطريق عبر طريق الوكرة السريع نحو مسيعيد.',
          createdAt: anchor.subtract(const Duration(minutes: 30)),
        ),
      ],
      'demo_wr_10_deliv_pend': [
        RequestEvent(
          id: 'demo_evt_10_1',
          requestId: 'demo_wr_10_deliv_pend',
          actorId: peerRequesterKhaledId,
          actorRole: 'requester',
          eventType: 'offer_accepted',
          fromStatus: WorkRequestStatus.offerSelected,
          toStatus: WorkRequestStatus.accepted,
          note: 'تم تعيين المزود وتوليد رمز التسليم السري.',
          createdAt: anchor.subtract(const Duration(hours: 10)),
        ),
        RequestEvent(
          id: 'demo_evt_10_2',
          requestId: 'demo_wr_10_deliv_pend',
          actorId: ownerUid,
          actorRole: 'provider',
          eventType: 'status_changed',
          fromStatus: WorkRequestStatus.inTransit,
          toStatus: WorkRequestStatus.deliveredPendingConfirmation,
          note:
              'وصل المزود إلى بوابة الشيحانية وبانتظار إدخال رمز التسليم T5K9B3.',
          createdAt: anchor.subtract(const Duration(minutes: 10)),
        ),
      ],
      'demo_wr_11_comp_cash': [
        RequestEvent(
          id: 'demo_evt_11_1',
          requestId: 'demo_wr_11_comp_cash',
          actorId: approvedMainProviderId,
          actorRole: 'provider',
          eventType: 'handover_completed',
          fromStatus: WorkRequestStatus.deliveredPendingConfirmation,
          toStatus: WorkRequestStatus.completed,
          note: 'تم التحقق من رمز التسليم وإتمام التسليم النقدي في ميناء الرويس.',
          createdAt: anchor.subtract(const Duration(days: 1, hours: 18)),
        ),
      ],
      'demo_wr_12_comp_bank': [
        RequestEvent(
          id: 'demo_evt_12_1',
          requestId: 'demo_wr_12_comp_bank',
          actorId: ownerUid,
          actorRole: 'provider',
          eventType: 'handover_completed',
          fromStatus: WorkRequestStatus.deliveredPendingConfirmation,
          toStatus: WorkRequestStatus.completed,
          note: 'تم تأكيد التسليم في لوسيل وتسوية التحويل البنكي QNB-2026-77419.',
          createdAt: anchor.subtract(const Duration(days: 2, hours: 20)),
        ),
      ],
      'demo_wr_13_cancelled': [
        RequestEvent(
          id: 'demo_evt_13_1',
          requestId: 'demo_wr_13_cancelled',
          actorId: ownerUid,
          actorRole: 'requester',
          eventType: 'status_changed',
          fromStatus: WorkRequestStatus.open,
          toStatus: WorkRequestStatus.cancelled,
          note: 'أُلغي الطلب لعدم الحاجة بعد توفر المواد بالمستودع الداخلي.',
          createdAt: anchor.subtract(const Duration(days: 3, hours: 22)),
        ),
      ],
      'demo_wr_14_disputed': [
        RequestEvent(
          id: 'demo_evt_14_1',
          requestId: 'demo_wr_14_disputed',
          actorId: ownerUid,
          actorRole: 'requester',
          eventType: 'status_changed',
          fromStatus: WorkRequestStatus.deliveredPendingConfirmation,
          toStatus: WorkRequestStatus.disputed,
          note: 'تم فتح نزاع تشغيلي ومالي لمراجعة اختلاف مقاس الصمامات.',
          createdAt: anchor.subtract(const Duration(hours: 3)),
        ),
      ],
    };

    final ratings = <RequestRating>[
      RequestRating(
        id: 'demo_wr_11_comp_cash_$ownerUid',
        requestId: 'demo_wr_11_comp_cash',
        raterUserId: ownerUid,
        raterRole: 'requester',
        targetUserId: approvedMainProviderId,
        score: 5,
        comment:
            'التزام تام بالموعد ومطابقة كاملة لفاتورة الشراء في ميناء الرويس.',
        tags: const ['on_time', 'accurate_invoice', 'verified_handover'],
        createdAt: anchor.subtract(const Duration(days: 1, hours: 17)),
      ),
      RequestRating(
        id: 'demo_wr_12_comp_bank_$peerRequesterSaraId',
        requestId: 'demo_wr_12_comp_bank',
        raterUserId: peerRequesterSaraId,
        raterRole: 'requester',
        targetUserId: ownerUid,
        score: 5,
        comment:
            'توريد احترافي وسرعة في إيصال لوحة التوزيع إلى بوليفارد لوسيل.',
        tags: const ['fast_delivery', 'professional_handover'],
        createdAt: anchor.subtract(const Duration(days: 2, hours: 19)),
      ),
    ];

    final notifications = <DemoNotificationEntry>[
      DemoNotificationEntry(
        id: 'demo_ntf_01',
        userId: ownerUid,
        title: '3 عروض جديدة على طلب مواسير السباكة',
        titleAr: '3 عروض جديدة على طلب مواسير السباكة',
        titleEn: '3 new offers on your plumbing supply request',
        body:
            'تلقيت 3 عروض من مزودين معتمدين بالبطاقة القطرية لموقع مشيرب الدوحة.',
        bodyAr:
            'تلقيت 3 عروض من مزودين معتمدين بالبطاقة القطرية لموقع مشيرب الدوحة.',
        bodyEn:
            'You received 3 offers from QID-approved providers for Msheireb Doha.',
        type: 'new_offer',
        category: 'worksite_supply',
        requestId: 'demo_wr_03_offers_mine',
        offerId: 'demo_off_01',
        targetRoute: '/work-requests/demo_wr_03_offers_mine',
        isRead: false,
        createdAt: anchor.subtract(const Duration(minutes: 15)),
      ),
      DemoNotificationEntry(
        id: 'demo_ntf_02',
        userId: ownerUid,
        title: 'شحنة مسيعيد في الطريق إلى الموقع',
        titleAr: 'شحنة مسيعيد في الطريق إلى الموقع',
        titleEn: 'Mesaieed delivery is in transit',
        body:
            'المزود خالد المناعي في الطريق. رمز تأكيد التسليم السري: H6P2V5',
        bodyAr:
            'المزود خالد المناعي في الطريق. رمز تأكيد التسليم السري: H6P2V5',
        bodyEn:
            'Provider Khalid Al-Mannai is en route. Secret handover code: H6P2V5',
        type: 'status_update',
        category: 'worksite_supply',
        requestId: 'demo_wr_09_transit',
        targetRoute: '/work-requests/demo_wr_09_transit',
        isRead: false,
        createdAt: anchor.subtract(const Duration(minutes: 30)),
      ),
      DemoNotificationEntry(
        id: 'demo_ntf_03',
        userId: ownerUid,
        title: 'بانتظار إدخال رمز التسليم لمهمة الشيحانية',
        titleAr: 'بانتظار إدخال رمز التسليم لمهمة الشيحانية',
        titleEn: 'Handover verification pending for Al Shahaniya job',
        body:
            'أدخل رمز التسليم المكون من 6 خانات (T5K9B3) لإتمام توصيل مضخة المياه.',
        bodyAr:
            'أدخل رمز التسليم المكون من 6 خانات (T5K9B3) لإتمام توصيل مضخة المياه.',
        bodyEn:
            'Enter the 6-char handover code (T5K9B3) to complete the water pump job.',
        type: 'handover_pending',
        category: 'worksite_supply',
        requestId: 'demo_wr_10_deliv_pend',
        targetRoute: '/work-requests/demo_wr_10_deliv_pend',
        isRead: false,
        createdAt: anchor.subtract(const Duration(minutes: 10)),
      ),
      DemoNotificationEntry(
        id: 'demo_ntf_04',
        userId: ownerUid,
        title: 'تم توثيق السداد وإغلاق طلب الشمال',
        titleAr: 'تم توثيق السداد وإغلاق طلب الشمال',
        titleEn: 'Al Shamal delivery completed & settled',
        body: 'تم إغلاق طلب ميناء الرويس بنجاح وتقييم المزود 5 نجوم.',
        bodyAr: 'تم إغلاق طلب ميناء الرويس بنجاح وتقييم المزود 5 نجوم.',
        bodyEn: 'Ruwais Port order completed and rated 5 stars.',
        type: 'request_completed',
        category: 'worksite_supply',
        requestId: 'demo_wr_11_comp_cash',
        targetRoute: '/work-requests/demo_wr_11_comp_cash',
        isRead: true,
        createdAt: anchor.subtract(const Duration(days: 1)),
      ),
    ];

    final investorInquiries = <AdminInvestorInquiry>[
      AdminInvestorInquiry(
        id: 'demo_inq_qdb_2026',
        fullName: 'طارق المنصور | Tariq Al-Mansoor',
        organization: 'Startup Qatar / QDB Venture Desk',
        email: 'tariq.mansoor@qdb.qa',
        phone: '+974 5512 8840',
        inquiryType: 'جلسة عرض ومراجعة نموذج توريد المواقع (Startup Qatar / VC)',
        notes:
            'مراجعة خطة التوسع بين المنطقة الصناعية ولوسيل ومؤشرات الامتثال بالريال القطري.',
        lang: 'ar',
        source: 'landing_page',
        pageUrl: 'https://mashwar-qatar.vercel.app/#contact',
        status: 'new',
        createdAtIso: anchor.subtract(const Duration(hours: 6)).toIso8601String(),
      ),
      AdminInvestorInquiry(
        id: 'demo_inq_qstp_2026',
        fullName: 'Nadia Al-Kuwari',
        organization: 'QSTP Incubation & Tech Review',
        email: 'n.alkuwari@qstp.org.qa',
        phone: '+974 4454 7120',
        inquiryType: 'B2B Pilot & Security Rules Walkthrough',
        notes:
            'Requested live walkthrough of QID 11-digit KYC review and SHA-256 handover verification.',
        lang: 'en',
        source: 'landing_page',
        pageUrl: 'https://mashwar-qatar.vercel.app/#contact',
        status: 'contacted',
        createdAtIso: anchor.subtract(const Duration(days: 1)).toIso8601String(),
      ),
      AdminInvestorInquiry(
        id: 'demo_inq_almadar_b2b',
        fullName: 'م. خالد العطية',
        organization: 'شركة المدار للمقاولات - لوسيل',
        email: 'khaled@almadar-contracting.qa',
        phone: '+974 5031 2290',
        inquiryType: 'شراكة توريد يومي للمواقع الإنشائية (B2B Supply)',
        notes:
            'تغطية 12 موقع عمل بين المنطقة الصناعية ولوسيل والوكرة.',
        lang: 'ar',
        source: 'web_app',
        pageUrl: 'https://mashwar-qatar.vercel.app',
        status: 'new',
        createdAtIso: anchor.subtract(const Duration(days: 2)).toIso8601String(),
      ),
    ];

    final auditLogs = <DemoAuditLogEntry>[
      DemoAuditLogEntry(
        id: 'demo_aud_01',
        adminUid: ownerUid,
        adminRole: 'superAdmin',
        action: 'provider_review',
        targetCollection: 'provider_profiles',
        targetEntityId: approvedMainProviderId,
        previousState: const {'approvalStatus': 'pending'},
        newState: const {'approvalStatus': 'approved'},
        reason: 'تم التحقق من البطاقة القطرية QID والاستمارة',
        beforeAfter: 'pending ← approved (QID verified)',
        createdAt: anchor.subtract(const Duration(days: 2)),
      ),
      DemoAuditLogEntry(
        id: 'demo_aud_02',
        adminUid: ownerUid,
        adminRole: 'superAdmin',
        action: 'verify_payment_settled',
        targetCollection: 'work_requests',
        targetEntityId: 'demo_wr_12_comp_bank',
        previousState: const {'paymentStatus': 'transfer_proof_submitted'},
        newState: const {
          'paymentStatus': 'verified_settled',
          'paymentReference': 'QNB-2026-77419',
        },
        reason: 'Ref: QNB-2026-77419',
        beforeAfter: 'transfer_proof_submitted ← verified_settled (QNB-2026-77419)',
        createdAt: anchor.subtract(const Duration(days: 1, hours: 12)),
      ),
      DemoAuditLogEntry(
        id: 'demo_aud_03',
        adminUid: ownerUid,
        adminRole: 'superAdmin',
        action: 'provider_review',
        targetCollection: 'provider_profiles',
        targetEntityId: rejectedProviderId,
        previousState: const {'approvalStatus': 'pending'},
        newState: const {'approvalStatus': 'rejected'},
        reason: 'صورة الوجه الخلفي للبطاقة القطرية منتهية الصلاحية',
        beforeAfter: 'pending ← rejected (Expired QID back photo)',
        createdAt: anchor.subtract(const Duration(days: 1)),
      ),
      DemoAuditLogEntry(
        id: 'demo_aud_04',
        adminUid: ownerUid,
        adminRole: 'superAdmin',
        action: 'moderate_flag_dispute',
        targetCollection: 'work_requests',
        targetEntityId: 'demo_wr_14_disputed',
        previousState: const {'status': 'delivered_pending_confirmation'},
        newState: const {'status': 'disputed'},
        reason: 'اختلاف مقاس الصمامات الموردة عن المواصفة الهندسية',
        beforeAfter: 'delivered_pending_confirmation ← disputed',
        createdAt: anchor.subtract(const Duration(hours: 3)),
      ),
    ];

    return MashwarDemoCasesBundle(
      currentUserId: ownerUid,
      currentUserName: ownerName,
      anchorUtc: anchor,
      savedWorksites: List.unmodifiable(savedWorksites),
      providers: List.unmodifiable(providers),
      requests: List.unmodifiable(requests),
      offersByRequest: Map.unmodifiable(offersByRequest),
      handoverCodesByRequest: Map.unmodifiable(handoverCodes),
      eventsByRequest: Map.unmodifiable(eventsByRequest),
      ratings: List.unmodifiable(ratings),
      notifications: List.unmodifiable(notifications),
      investorInquiries: List.unmodifiable(investorInquiries),
      auditLogs: List.unmodifiable(auditLogs),
    );
  }
}
