import 'package:flutter/foundation.dart';

import '../core/config/app_environment.dart';
import '../data/demo/demo_cases_catalog.dart';
import '../data/models/worksite_models.dart';
import '../data/repositories/app_repositories.dart';
import '../data/repositories/contracts/i_provider_repository.dart';
import '../data/repositories/contracts/i_worksite_repository.dart';
import '../data/repositories/implementations/firebase/firebase_worksite_repository.dart';
import '../data/services/firebase_firestore_service.dart';

export '../data/services/firebase_firestore_service.dart'
    show WorksiteRepositoryException;

/// Sort modes for the Worksite Supply marketplace & requests list.
enum WorksiteSortOption {
  newest,
  highestBudget,
  soonestDeadline,
  fewestOffers,
}

/// Owner-scoped notification item hydrated from Firestore `notifications`,
/// [MashwarDemoCasesCatalog], or live request/offer state fallback.
@immutable
class WorksiteNotificationItem {
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
  final bool isDerived;
  final DateTime createdAt;

  const WorksiteNotificationItem({
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
    this.isDerived = false,
    required this.createdAt,
  });

  String localizedTitle({required bool isArabic}) {
    final preferred = isArabic ? titleAr : titleEn;
    return preferred.trim().isNotEmpty ? preferred : title;
  }

  String localizedBody({required bool isArabic}) {
    final preferred = isArabic ? bodyAr : bodyEn;
    return preferred.trim().isNotEmpty ? preferred : body;
  }

  WorksiteNotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? titleAr,
    String? titleEn,
    String? body,
    String? bodyAr,
    String? bodyEn,
    String? type,
    String? category,
    String? requestId,
    String? offerId,
    String? targetRoute,
    bool? isRead,
    bool? isDerived,
    DateTime? createdAt,
  }) {
    return WorksiteNotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      body: body ?? this.body,
      bodyAr: bodyAr ?? this.bodyAr,
      bodyEn: bodyEn ?? this.bodyEn,
      type: type ?? this.type,
      category: category ?? this.category,
      requestId: requestId ?? this.requestId,
      offerId: offerId ?? this.offerId,
      targetRoute: targetRoute ?? this.targetRoute,
      isRead: isRead ?? this.isRead,
      isDerived: isDerived ?? this.isDerived,
      createdAt: (createdAt ?? this.createdAt).toUtc(),
    );
  }

  factory WorksiteNotificationItem.fromDemoEntry(DemoNotificationEntry entry) {
    return WorksiteNotificationItem(
      id: entry.id,
      userId: entry.userId,
      title: entry.title,
      titleAr: entry.titleAr,
      titleEn: entry.titleEn,
      body: entry.body,
      bodyAr: entry.bodyAr,
      bodyEn: entry.bodyEn,
      type: entry.type,
      category: entry.category,
      requestId: entry.requestId,
      offerId: entry.offerId,
      targetRoute: entry.targetRoute,
      isRead: entry.isRead,
      isDerived: false,
      createdAt: entry.createdAt.toUtc(),
    );
  }

  factory WorksiteNotificationItem.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['title'] ?? '').toString();
    final rawTitleAr = (json['titleAr'] ?? rawTitle).toString();
    final rawTitleEn = (json['titleEn'] ?? rawTitle).toString();
    final rawBody = (json['body'] ?? '').toString();
    final rawBodyAr = (json['bodyAr'] ?? rawBody).toString();
    final rawBodyEn = (json['bodyEn'] ?? rawBody).toString();
    final rawCreated = json['createdAt'];
    DateTime createdAt;
    if (rawCreated is DateTime) {
      createdAt = rawCreated.toUtc();
    } else if (rawCreated is String && rawCreated.trim().isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreated.trim())?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    } else if (rawCreated is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreated, isUtc: true);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    return WorksiteNotificationItem(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      title: rawTitle.isNotEmpty ? rawTitle : rawTitleAr,
      titleAr: rawTitleAr,
      titleEn: rawTitleEn,
      body: rawBody.isNotEmpty ? rawBody : rawBodyAr,
      bodyAr: rawBodyAr,
      bodyEn: rawBodyEn,
      type: (json['type'] ?? 'status_update').toString(),
      category: (json['category'] ?? 'worksite_supply').toString(),
      requestId: json['requestId']?.toString(),
      offerId: json['offerId']?.toString(),
      targetRoute: json['targetRoute']?.toString(),
      isRead: json['isRead'] as bool? ?? false,
      isDerived: false,
      createdAt: createdAt,
    );
  }
}

/// Clean draft payload generated by [WorksiteProvider.buildReorderDraft] for Quick Reorder.
/// Carries over items, route, site contact, and QAR minor-unit budgets without leaking
/// stale offer/assignment/handover/payment settlement fields.
@immutable
class WorkRequestReorderDraft {
  final String sourceRequestId;
  final String title;
  final String description;
  final String supplyCategory;
  final String pickupLocation;
  final String dropoffWorksite;
  final String municipality;
  final String? businessProfileId;
  final String? savedWorksiteId;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? itemNotes;
  final MoneyMinor estimatedItemsCostMinor;
  final MoneyMinor maxItemsCapMinor;
  final MoneyMinor deliveryFeeBudgetMinor;
  final PaymentMethod paymentMethod;
  final bool requiresPurchaseReceipt;

  const WorkRequestReorderDraft({
    required this.sourceRequestId,
    required this.title,
    required this.description,
    required this.supplyCategory,
    required this.pickupLocation,
    required this.dropoffWorksite,
    required this.municipality,
    this.businessProfileId,
    this.savedWorksiteId,
    this.siteContactName,
    this.siteContactPhone,
    this.itemNotes,
    required this.estimatedItemsCostMinor,
    required this.maxItemsCapMinor,
    required this.deliveryFeeBudgetMinor,
    required this.paymentMethod,
    required this.requiresPurchaseReceipt,
  });

  /// Materializes a fresh open [WorkRequest] with zeroed offers and unpaid settlement status.
  WorkRequest toNewRequest({
    required String requesterId,
    required String requesterName,
    DateTime? now,
  }) {
    final ts = (now ?? DateTime.now()).toUtc();
    return WorkRequest(
      id: '',
      requesterId: requesterId,
      requesterName: requesterName,
      businessProfileId: businessProfileId,
      savedWorksiteId: savedWorksiteId,
      title: title,
      description: description,
      supplyCategory: supplyCategory,
      pickupLocation: pickupLocation,
      dropoffWorksite: dropoffWorksite,
      municipality: municipality,
      siteContactName: siteContactName,
      siteContactPhone: siteContactPhone,
      itemNotes: itemNotes,
      estimatedItemsCostMinor: estimatedItemsCostMinor,
      maxItemsCapMinor: maxItemsCapMinor,
      deliveryFeeBudgetMinor: deliveryFeeBudgetMinor,
      status: WorkRequestStatus.open,
      paymentMethod: paymentMethod,
      paymentSettlementStatus: PaymentSettlementStatus.unpaid,
      requiresPurchaseReceipt: requiresPurchaseReceipt,
      createdAt: ts,
      updatedAt: ts,
    );
  }
}

/// State management provider for Qatar Worksite Supply MVP (P0 + P1).
class WorksiteProvider extends ChangeNotifier {
  static const Set<WorkRequestStatus> _handoverVisibleStatuses = {
    WorkRequestStatus.accepted,
    WorkRequestStatus.inProgress,
    WorkRequestStatus.pickedUp,
    WorkRequestStatus.inTransit,
    WorkRequestStatus.deliveredPendingConfirmation,
  };

  final IWorksiteRepository? _injectedWorksiteRepo;
  final IProviderRepository? _injectedProviderRepo;
  final String? Function()? _currentUidProvider;

  String? _boundUserId;
  String? _boundUserName;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _errorCode;
  WorksiteRepositoryException? _lastException;

  List<WorkRequest> _allLoadedRequests = const [];
  List<WorkRequest> _filteredRequests = const [];

  String? _filterArea;
  int? _filterMaxBudgetMinor;
  WorkRequestStatus? _filterStatus;
  bool _filterOnlyMine = false;
  bool _filterAssignedToMe = false;
  String _searchQuery = '';
  String? _filterCategory;
  WorksiteSortOption _sortBy = WorksiteSortOption.newest;
  int _lastLimit = 50;
  String? _lastSelectedRequestId;
  bool _lastOperationWasSelect = false;

  WorkRequest? _selectedRequest;
  List<WorkOffer> _selectedOffers = const [];
  List<RequestEvent> _selectedEvents = const [];
  String? _activeHandoverCode;

  ProviderProfile? _providerProfile;
  List<SavedWorksite> _savedWorksites = const [];
  List<WorksiteNotificationItem> _notifications = const [];
  final Set<String> _locallyReadNotificationIds = <String>{};
  final Map<String, String> _reorderedFromMap = {};
  bool _isDemoShowcaseMode = false;
  MashwarDemoCasesBundle? _showcaseBundle;
  Map<String, List<WorkOffer>> _demoOffersByRequest = {};
  Map<String, List<RequestEvent>> _demoEventsByRequest = {};

  WorksiteProvider({
    IWorksiteRepository? worksiteRepository,
    IProviderRepository? providerRepository,
    String? Function()? currentUidProvider,
    String? initialUserId,
    String? initialUserName,
  })  : _injectedWorksiteRepo = worksiteRepository,
        _injectedProviderRepo = providerRepository,
        _currentUidProvider = currentUidProvider,
        _boundUserId = initialUserId,
        _boundUserName = initialUserName;

  IWorksiteRepository get _worksiteRepo =>
      _injectedWorksiteRepo ?? AppRepositories.instance.worksite;

  IProviderRepository get _providerRepo =>
      _injectedProviderRepo ?? AppRepositories.instance.providers;

  bool get _isLiveBackendMode =>
      AppEnvironment.isFirebaseRuntimeActive ||
      AppEnvironment.flavor != AppFlavor.development;

  /// True ONLY in local development without Firebase active (and when no
  /// stub/mock repository was injected by unit tests). NEVER true when
  /// Firebase runtime is active or in staging/production builds.
  bool get _shouldHydrateRichDemoBaseline =>
      _injectedWorksiteRepo == null &&
      _injectedProviderRepo == null &&
      !_isLiveBackendMode &&
      _worksiteRepo is! FirebaseWorksiteRepository;

  MashwarDemoCasesBundle _buildPersonalizedDemoBundle([String? explicitUid]) {
    final uid = (explicitUid != null && explicitUid.trim().isNotEmpty)
        ? explicitUid.trim()
        : (currentUserId ?? MashwarDemoCasesCatalog.defaultOwnerUid);
    final name = currentUserName.isNotEmpty
        ? currentUserName
        : MashwarDemoCasesCatalog.defaultOwnerName;
    return MashwarDemoCasesCatalog.build(
      currentUserId: uid,
      currentUserName: name,
    );
  }

  String? get currentUserId {
    final supplied = _currentUidProvider?.call()?.trim();
    if (supplied != null && supplied.isNotEmpty) return supplied;
    final bound = _boundUserId?.trim();
    return (bound != null && bound.isNotEmpty) ? bound : null;
  }

  String get currentUserName =>
      (_boundUserName?.trim().isNotEmpty == true) ? _boundUserName!.trim() : '';

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  WorksiteRepositoryException? get lastException => _lastException;
  bool get hasError => _errorMessage != null;

  String? localizedError({required bool isArabic}) {
    if (_lastException != null) {
      return _lastException!.localizedMessage(isArabic: isArabic);
    }
    return _errorMessage;
  }

  List<WorkRequest> get requests => List.unmodifiable(_filteredRequests);
  List<WorkRequest> get allLoadedRequests =>
      List.unmodifiable(_allLoadedRequests);
  bool get isEmpty => !_isLoading && !hasError && _filteredRequests.isEmpty;
  bool get hasActiveFilters =>
      (_filterArea != null && _filterArea!.isNotEmpty) ||
      _filterMaxBudgetMinor != null ||
      _filterStatus != null ||
      _filterOnlyMine ||
      _filterAssignedToMe ||
      _searchQuery.isNotEmpty ||
      (_filterCategory != null && _filterCategory!.isNotEmpty) ||
      _sortBy != WorksiteSortOption.newest;

  String? get filterArea => _filterArea;
  int? get filterMaxBudgetMinor => _filterMaxBudgetMinor;
  WorkRequestStatus? get filterStatus => _filterStatus;
  bool get filterOnlyMine => _filterOnlyMine;
  bool get filterAssignedToMe => _filterAssignedToMe;
  String get searchQuery => _searchQuery;
  String? get filterCategory => _filterCategory;
  WorksiteSortOption get sortBy => _sortBy;

  List<WorksiteNotificationItem> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadNotificationsCount =>
      _notifications.where((item) => !item.isRead).length;

  WorkRequest? get selectedRequest => _selectedRequest;
  List<WorkOffer> get selectedOffers => List.unmodifiable(_selectedOffers);
  List<RequestEvent> get selectedEvents => List.unmodifiable(_selectedEvents);
  String? get activeHandoverCode => _activeHandoverCode;

  ProviderProfile? get providerProfile => _providerProfile;
  bool get isApprovedProvider => _providerProfile?.canAcceptWorksiteJobs ?? false;
  List<SavedWorksite> get savedWorksites => List.unmodifiable(_savedWorksites);
  bool get isDemoShowcaseMode => _isDemoShowcaseMode;

  /// Returns the source request ID if [requestId] was created via Quick Reorder in this session.
  String? sourceRequestIdFor(String requestId) => _reorderedFromMap[requestId];

  /// Loads the full bilingual 14-case Qatar demo showcase into active provider state,
  /// enabling end-to-end UI inspection even when connected to live Firebase.
  Future<void> activateDemoShowcase() async {
    final uid = currentUserId ?? MashwarDemoCasesCatalog.defaultOwnerUid;
    final name = currentUserName.isNotEmpty
        ? currentUserName
        : MashwarDemoCasesCatalog.defaultOwnerName;
    final bundle = MashwarDemoCasesCatalog.build(
      currentUserId: uid,
      currentUserName: name,
    );

    _showcaseBundle = bundle;
    _isDemoShowcaseMode = true;
    _clearErrorSilently();
    _allLoadedRequests = List<WorkRequest>.from(bundle.requests)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _demoOffersByRequest = {
      for (final entry in bundle.offersByRequest.entries)
        entry.key: List<WorkOffer>.from(entry.value),
    };
    _demoEventsByRequest = {
      for (final entry in bundle.eventsByRequest.entries)
        entry.key: List<RequestEvent>.from(entry.value),
    };
    _savedWorksites = bundle.savedWorksites;
    _providerProfile = bundle.providerProfileFor(uid) ?? _providerProfile;
    _notifications = _buildShowcaseNotifications(bundle);
    _recomputeFilteredRequests();

    final selectedId = _selectedRequest?.id;
    if (selectedId != null) {
      final demoSelected = _findShowcaseRequest(selectedId);
      if (demoSelected != null) {
        _selectedRequest = demoSelected;
        _selectedOffers = List.unmodifiable(
          _demoOffersByRequest[selectedId] ?? const [],
        );
        _selectedEvents = List.unmodifiable(
          _demoEventsByRequest[selectedId] ?? const [],
        );
        _activeHandoverCode = (uid == demoSelected.requesterId &&
                _handoverVisibleStatuses.contains(demoSelected.status))
            ? bundle.handoverCodesByRequest[selectedId]
            : null;
      } else {
        _selectedRequest = null;
        _selectedOffers = const [];
        _selectedEvents = const [];
        _activeHandoverCode = null;
      }
    }
    notifyListeners();
  }

  /// Exits the local 14-case showcase overlay and restores normal repository reads.
  Future<void> exitDemoShowcase() async {
    _isDemoShowcaseMode = false;
    _showcaseBundle = null;
    _demoOffersByRequest = {};
    _demoEventsByRequest = {};
    _selectedRequest = null;
    _selectedOffers = const [];
    _selectedEvents = const [];
    _activeHandoverCode = null;
    await loadRequests(limit: _lastLimit);
    final uid = currentUserId;
    if (uid != null && uid.isNotEmpty) {
      try {
        _savedWorksites = await _providerRepo.listSavedWorksites(uid);
      } catch (_) {
        _savedWorksites = const [];
      }
      try {
        _providerProfile = await _providerRepo.getProviderProfile(uid);
      } catch (_) {
        _providerProfile = null;
      }
      notifyListeners();
    } else {
      _savedWorksites = const [];
      _providerProfile = null;
      _notifications = const [];
      notifyListeners();
    }
  }

  /// Syncs active Firebase/App auth user identity from [AuthProvider] without retaining stale session state.
  void syncAuthSession({
    required String? uid,
    String? fullName,
  }) {
    final nextUid = uid?.trim();
    final normalizedNext =
        (nextUid != null && nextUid.isNotEmpty) ? nextUid : null;
    final previousUid = _boundUserId;

    _boundUserId = normalizedNext;
    _boundUserName = fullName?.trim();

    final uidChanged = previousUid != normalizedNext;
    final hasLiveStaleOnNull = _isLiveBackendMode &&
        normalizedNext == null &&
        (_allLoadedRequests.isNotEmpty ||
            _filteredRequests.isNotEmpty ||
            _selectedRequest != null ||
            _notifications.isNotEmpty ||
            _savedWorksites.isNotEmpty ||
            _providerProfile != null);

    if (uidChanged || hasLiveStaleOnNull) {
      _activeHandoverCode = null;
      _isDemoShowcaseMode = false;
      _showcaseBundle = null;
      _demoOffersByRequest = {};
      _demoEventsByRequest = {};
      _locallyReadNotificationIds.clear();
      if (_isLiveBackendMode) {
        _allLoadedRequests = const [];
        _filteredRequests = const [];
        _selectedRequest = null;
        _selectedOffers = const [];
        _selectedEvents = const [];
        _providerProfile = null;
        _savedWorksites = const [];
        _notifications = const [];
      } else {
        _allLoadedRequests = _allLoadedRequests
            .where((r) => !r.id.startsWith('demo_wr_'))
            .toList();
        if (_selectedRequest != null &&
            _selectedRequest!.id.startsWith('demo_wr_')) {
          _selectedRequest = null;
          _selectedOffers = const [];
          _selectedEvents = const [];
        }
        if (normalizedNext == null) {
          _providerProfile = null;
          _savedWorksites = const [];
          _notifications = const [];
        } else {
          _notifications = _deriveLiveNotifications(normalizedNext);
        }
      }
      _recomputeFilteredRequests();
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null || _lastException != null || _errorCode != null) {
      _errorMessage = null;
      _errorCode = null;
      _lastException = null;
      notifyListeners();
    }
  }

  void _clearErrorSilently() {
    _errorMessage = null;
    _errorCode = null;
    _lastException = null;
  }

  void _recordError(Object error) {
    if (error is WorksiteRepositoryException) {
      _lastException = error;
      _errorCode = error.code;
      _errorMessage = error.message;
    } else {
      final wrapped = WorksiteRepositoryException.fromFirebase(error);
      _lastException = wrapped;
      _errorCode = wrapped.code;
      _errorMessage = wrapped.message;
    }
  }

  String _resolveRequiredUid(String? explicitUid) {
    final clean = explicitUid?.trim();
    if (clean != null && clean.isNotEmpty) return clean;
    final current = currentUserId;
    if (current != null && current.isNotEmpty) return current;
    throw WorksiteRepositoryException.unauthenticated();
  }

  /// Loads requests from [IWorksiteRepository] and updates filtered state.
  Future<void> loadRequests({
    WorkRequestStatus? status,
    String? area,
    int? maxBudgetMinor,
    bool? onlyMine,
    bool? assignedToMe,
    String? currentUserIdOverride,
    int limit = 50,
  }) async {
    if (status != null) _filterStatus = status;
    if (area != null) {
      _filterArea = area.trim().isEmpty ? null : area.trim();
    }
    if (maxBudgetMinor != null) _filterMaxBudgetMinor = maxBudgetMinor;
    if (onlyMine != null) _filterOnlyMine = onlyMine;
    if (assignedToMe != null) _filterAssignedToMe = assignedToMe;
    if (currentUserIdOverride != null &&
        currentUserIdOverride.trim().isNotEmpty) {
      _boundUserId = currentUserIdOverride.trim();
    }

    _lastLimit = limit;
    _lastOperationWasSelect = false;
    _isLoading = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      if (_isDemoShowcaseMode && _showcaseBundle != null) {
        if (_allLoadedRequests.isEmpty) {
          _allLoadedRequests = List<WorkRequest>.from(_showcaseBundle!.requests)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        _recomputeFilteredRequests();
        await _refreshNotifications(notify: false);
        return;
      }
      final uid = currentUserId;
      List<WorkRequest> fetched = const [];
      Object? fetchError;
      try {
        fetched = await _worksiteRepo.listRequests(
          status: _filterStatus,
          municipality: _filterArea,
          requesterId: _filterOnlyMine ? uid : null,
          assignedProviderId: _filterAssignedToMe ? uid : null,
          limit: limit,
        );
      } catch (err) {
        fetchError = err;
        if (!_shouldHydrateRichDemoBaseline) {
          rethrow;
        }
      }

      if (_shouldHydrateRichDemoBaseline) {
        final demoBundle = _buildPersonalizedDemoBundle(uid);
        final personalizedById = <String, WorkRequest>{
          for (final d in demoBundle.requests) d.id: d,
        };
        final mergedById = <String, WorkRequest>{};
        for (final remote in fetched) {
          if (remote.id.startsWith('demo_wr_') &&
              personalizedById.containsKey(remote.id) &&
              uid != null &&
              uid != MashwarDemoCasesCatalog.defaultOwnerUid &&
              (remote.requesterId == MashwarDemoCasesCatalog.defaultOwnerUid ||
                  remote.assignedProviderId ==
                      MashwarDemoCasesCatalog.defaultOwnerUid)) {
            // Re-bind seeded demo_wr_* ownership to the active user so My Activity
            // (Active & Completed) and Handover Codes work out of the box.
            mergedById[remote.id] = personalizedById[remote.id]!;
          } else {
            mergedById[remote.id] = remote;
          }
        }
        for (final demoReq in demoBundle.requests) {
          mergedById.putIfAbsent(demoReq.id, () => demoReq);
        }
        _demoOffersByRequest = {
          for (final entry in demoBundle.offersByRequest.entries)
            entry.key: List<WorkOffer>.from(entry.value),
        };
        _demoEventsByRequest = {
          for (final entry in demoBundle.eventsByRequest.entries)
            entry.key: List<RequestEvent>.from(entry.value),
        };
        final mergedList = mergedById.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _allLoadedRequests = mergedList;
      } else {
        if (fetchError != null) throw fetchError;
        _allLoadedRequests = fetched;
      }
      _recomputeFilteredRequests();
      await _refreshNotifications(notify: false);
    } catch (e) {
      _recordError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retries the most recent failed load operation (`loadRequests` or `selectAndLoadRequest`).
  Future<void> retryLastLoad() async {
    if (_lastOperationWasSelect && _lastSelectedRequestId != null) {
      await selectAndLoadRequest(_lastSelectedRequestId!);
      return;
    }
    await loadRequests(limit: _lastLimit);
  }

  /// Applies local filters & sorting over loaded requests and refreshes the filtered list.
  void applyFilters({
    String? area,
    int? maxBudgetMinor,
    WorkRequestStatus? status,
    bool? onlyMine,
    bool? assignedToMe,
    String? searchQuery,
    String? category,
    WorksiteSortOption? sortBy,
    bool clearArea = false,
    bool clearMaxBudget = false,
    bool clearStatus = false,
    bool clearSearchQuery = false,
    bool clearCategory = false,
  }) {
    if (clearArea) {
      _filterArea = null;
    } else if (area != null) {
      _filterArea = area.trim().isEmpty ? null : area.trim();
    }

    if (clearMaxBudget) {
      _filterMaxBudgetMinor = null;
    } else if (maxBudgetMinor != null) {
      _filterMaxBudgetMinor = maxBudgetMinor;
    }

    if (clearStatus) {
      _filterStatus = null;
    } else if (status != null) {
      _filterStatus = status;
    }

    if (clearSearchQuery) {
      _searchQuery = '';
    } else if (searchQuery != null) {
      _searchQuery = searchQuery.trim();
    }

    if (clearCategory) {
      _filterCategory = null;
    } else if (category != null) {
      final cleanCat = category.trim();
      _filterCategory =
          (cleanCat.isEmpty || cleanCat.toLowerCase() == 'all') ? null : cleanCat;
    }

    if (sortBy != null) _sortBy = sortBy;
    if (onlyMine != null) _filterOnlyMine = onlyMine;
    if (assignedToMe != null) _filterAssignedToMe = assignedToMe;

    _recomputeFilteredRequests();
    notifyListeners();
  }

  void clearFilters() {
    _filterArea = null;
    _filterMaxBudgetMinor = null;
    _filterStatus = null;
    _filterOnlyMine = false;
    _filterAssignedToMe = false;
    _searchQuery = '';
    _filterCategory = null;
    _sortBy = WorksiteSortOption.newest;
    _recomputeFilteredRequests();
    notifyListeners();
  }

  void _recomputeFilteredRequests() {
    final uid = currentUserId;
    final cleanArea = _filterArea?.trim().toLowerCase();
    final cleanCat = _filterCategory?.trim().toLowerCase();
    final cleanQuery = _searchQuery.trim().toLowerCase();

    final list = _allLoadedRequests.where((req) {
      if (_filterStatus != null && req.status != _filterStatus) {
        return false;
      }
      if (cleanArea != null &&
          cleanArea.isNotEmpty &&
          req.municipality.trim().toLowerCase() != cleanArea &&
          !req.municipality.toLowerCase().contains(cleanArea)) {
        return false;
      }
      if (cleanCat != null &&
          cleanCat.isNotEmpty &&
          req.supplyCategory.trim().toLowerCase() != cleanCat) {
        return false;
      }
      if (_filterMaxBudgetMinor != null &&
          req.effectiveTotalMinor.minorUnits > _filterMaxBudgetMinor!) {
        return false;
      }
      if (_filterOnlyMine) {
        if (uid == null || req.requesterId != uid) return false;
      }
      if (_filterAssignedToMe) {
        if (uid == null || req.assignedProviderId != uid) return false;
      }
      if (cleanQuery.isNotEmpty) {
        final haystack = <String>[
          req.title,
          req.description,
          req.pickupLocation,
          req.dropoffWorksite,
          req.municipality,
          req.requesterName,
          req.supplyCategory,
          req.itemNotes ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(cleanQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case WorksiteSortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case WorksiteSortOption.highestBudget:
        list.sort((a, b) {
          final cmp = b.effectiveTotalMinor.minorUnits
              .compareTo(a.effectiveTotalMinor.minorUnits);
          return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
        });
        break;
      case WorksiteSortOption.soonestDeadline:
        list.sort((a, b) {
          final da = a.scheduledBy;
          final db = b.scheduledBy;
          if (da == null && db == null) {
            return b.createdAt.compareTo(a.createdAt);
          }
          if (da == null) return 1;
          if (db == null) return -1;
          final cmp = da.compareTo(db);
          return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
        });
        break;
      case WorksiteSortOption.fewestOffers:
        list.sort((a, b) {
          final cmp = a.offerCount.compareTo(b.offerCount);
          return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    _filteredRequests = list;
  }

  /// Loads request details, offers, audit events, and requester-only handover code (when owner).
  Future<void> selectAndLoadRequest(
    String requestId, {
    String? currentUserIdOverride,
  }) async {
    if (currentUserIdOverride != null &&
        currentUserIdOverride.trim().isNotEmpty) {
      _boundUserId = currentUserIdOverride.trim();
    }

    _lastSelectedRequestId = requestId;
    _lastOperationWasSelect = true;
    _isLoading = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      if (_isDemoShowcaseMode && _showcaseBundle != null) {
        final demoReq = _findShowcaseRequest(requestId);
        if (demoReq != null) {
          final uid = currentUserId;
          _selectedRequest = demoReq;
          _selectedOffers = List.unmodifiable(
            _demoOffersByRequest[requestId] ??
                _showcaseBundle!.offersByRequest[requestId] ??
                const [],
          );
          _selectedEvents = List.unmodifiable(
            _demoEventsByRequest[requestId] ??
                _showcaseBundle!.eventsByRequest[requestId] ??
                const [],
          );
          _activeHandoverCode = (uid != null &&
                  uid == demoReq.requesterId &&
                  _handoverVisibleStatuses.contains(demoReq.status))
              ? _showcaseBundle!.handoverCodesByRequest[requestId]
              : null;
          _upsertRequestInCache(demoReq);
          return;
        }
      }

      WorkRequest? request;
      try {
        request = await _worksiteRepo.getRequestById(requestId);
      } catch (_) {
        if (!_shouldHydrateRichDemoBaseline) rethrow;
      }

      if (_shouldHydrateRichDemoBaseline && requestId.startsWith('demo_wr_')) {
        final uid = currentUserId;
        final demoBundle = _buildPersonalizedDemoBundle(uid);
        final demoReq = demoBundle.requestById(requestId);
        if (demoReq != null) {
          final effectiveReq = (request != null &&
                  uid != null &&
                  uid == request.requesterId)
              ? request
              : demoReq;
          List<WorkOffer> offers = const [];
          List<RequestEvent> events = const [];
          try {
            offers = await _worksiteRepo.listOffersForRequest(requestId);
            events = await _worksiteRepo.listRequestEvents(requestId);
          } catch (_) {}
          if (offers.isEmpty) {
            offers = List<WorkOffer>.from(
              _demoOffersByRequest[requestId] ??
                  demoBundle.offersByRequest[requestId] ??
                  const [],
            );
          }
          if (events.isEmpty) {
            events = List<RequestEvent>.from(
              _demoEventsByRequest[requestId] ??
                  demoBundle.eventsByRequest[requestId] ??
                  const [],
            );
          }
          String? handoverCode;
          if (uid != null &&
              uid == effectiveReq.requesterId &&
              _handoverVisibleStatuses.contains(effectiveReq.status)) {
            handoverCode = demoBundle.handoverCodesByRequest[requestId];
          }
          _selectedRequest = effectiveReq;
          _selectedOffers = List.unmodifiable(offers);
          _selectedEvents = List.unmodifiable(events);
          _activeHandoverCode = handoverCode;
          _upsertRequestInCache(effectiveReq);
          return;
        }
      }

      if (request == null) {
        throw const WorksiteRepositoryException(
          code: 'not-found',
          messageAr: 'تعذر العثور على طلب التوريد المطلوب.',
          messageEn: 'Worksite request not found.',
        );
      }

      final offers = await _worksiteRepo.listOffersForRequest(requestId);
      final events = await _worksiteRepo.listRequestEvents(requestId);

      String? handoverCode;
      final uid = currentUserId;
      if (uid != null &&
          uid == request.requesterId &&
          _handoverVisibleStatuses.contains(request.status)) {
        try {
          handoverCode = await _worksiteRepo.getRequesterHandoverCode(
            requestId: requestId,
            requesterId: uid,
          );
        } on WorksiteRepositoryException catch (e) {
          if (e.code != 'not-found') rethrow;
          handoverCode = null;
        }
      }

      _selectedRequest = request;
      _selectedOffers = offers;
      _selectedEvents = events;
      _activeHandoverCode = handoverCode;
      _upsertRequestInCache(request);
    } catch (e) {
      _recordError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _upsertRequestInCache(WorkRequest request) {
    final next = List<WorkRequest>.from(_allLoadedRequests);
    final idx = next.indexWhere((r) => r.id == request.id);
    if (idx >= 0) {
      next[idx] = request;
    } else {
      next.insert(0, request);
    }
    _allLoadedRequests = next;
    _recomputeFilteredRequests();
    if (_selectedRequest?.id == request.id) {
      _selectedRequest = request;
    }
  }

  /// Creates a new Worksite Supply request using integer minor units (QAR dirhams).
  Future<WorkRequest?> createRequest({
    String? requesterId,
    String? requesterName,
    required String title,
    required String description,
    String supplyCategory = 'general_site_supply',
    required String pickupLocation,
    required String dropoffWorksite,
    required String municipality,
    required MoneyMinor estimatedItemsCostMinor,
    MoneyMinor? maxItemsCapMinor,
    required MoneyMinor deliveryFeeBudgetMinor,
    PaymentMethod paymentMethod = PaymentMethod.cashOnDelivery,
    String? businessProfileId,
    String? savedWorksiteId,
    String? siteContactName,
    String? siteContactPhone,
    String? itemNotes,
    bool requiresPurchaseReceipt = true,
    DateTime? scheduledBy,
    String? sourceRequestId,
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(requesterId);
      final now = DateTime.now().toUtc();
      final effectiveMaxCap = maxItemsCapMinor ?? estimatedItemsCostMinor;
      final draft = WorkRequest(
        id: '',
        requesterId: uid,
        requesterName: (requesterName?.trim().isNotEmpty == true)
            ? requesterName!.trim()
            : currentUserName,
        businessProfileId: businessProfileId,
        savedWorksiteId: savedWorksiteId,
        title: title,
        description: description,
        supplyCategory: supplyCategory,
        pickupLocation: pickupLocation,
        dropoffWorksite: dropoffWorksite,
        municipality: municipality,
        siteContactName: siteContactName,
        siteContactPhone: siteContactPhone,
        itemNotes: itemNotes,
        estimatedItemsCostMinor: estimatedItemsCostMinor,
        maxItemsCapMinor: effectiveMaxCap,
        deliveryFeeBudgetMinor: deliveryFeeBudgetMinor,
        paymentMethod: paymentMethod,
        requiresPurchaseReceipt: requiresPurchaseReceipt,
        createdAt: now,
        updatedAt: now,
        scheduledBy: scheduledBy,
      );

      final created = await _worksiteRepo.createRequest(draft);
      if (sourceRequestId != null && sourceRequestId.trim().isNotEmpty) {
        _reorderedFromMap[created.id] = sourceRequestId.trim();
      }
      _upsertRequestInCache(created);
      _selectedRequest = created;
      _selectedOffers = const [];
      _selectedEvents = await _worksiteRepo.listRequestEvents(created.id);
      _activeHandoverCode = null;
      return created;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Builds a clean Quick Reorder draft from an existing [WorkRequest] without leaking
  /// stale offer/assignment/handover/payment state.
  WorkRequestReorderDraft buildReorderDraft(WorkRequest source) {
    return WorkRequestReorderDraft(
      sourceRequestId: source.id,
      title: source.title,
      description: source.description,
      supplyCategory: source.supplyCategory,
      pickupLocation: source.pickupLocation,
      dropoffWorksite: source.dropoffWorksite,
      municipality: source.municipality,
      businessProfileId: source.businessProfileId,
      savedWorksiteId: source.savedWorksiteId,
      siteContactName: source.siteContactName,
      siteContactPhone: source.siteContactPhone,
      itemNotes: source.itemNotes,
      estimatedItemsCostMinor: source.estimatedItemsCostMinor,
      maxItemsCapMinor: source.maxItemsCapMinor,
      deliveryFeeBudgetMinor: source.deliveryFeeBudgetMinor,
      paymentMethod: source.paymentMethod,
      requiresPurchaseReceipt: source.requiresPurchaseReceipt,
    );
  }

  /// Approved provider submits an offer on an open/offer_received request.
  Future<WorkOffer?> submitOffer({
    required String requestId,
    String? providerId,
    String? providerName,
    required MoneyMinor proposedFeeMinor,
    MoneyMinor? estimatedItemsCostMinor,
    int estimatedEtaMinutes = 45,
    String? notes,
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(providerId);
      final now = DateTime.now().toUtc();
      final offer = WorkOffer(
        id: '',
        requestId: requestId,
        providerId: uid,
        providerName: (providerName?.trim().isNotEmpty == true)
            ? providerName!.trim()
            : (_providerProfile?.fullName ?? currentUserName),
        providerRating: _providerProfile?.rating ?? 0.0,
        providerCompletedJobs: _providerProfile?.completedJobsCount ?? 0,
        proposedFeeMinor: proposedFeeMinor,
        estimatedItemsCostMinor: estimatedItemsCostMinor,
        estimatedEtaMinutes: estimatedEtaMinutes,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      final created = await _worksiteRepo.submitOffer(offer);
      final refreshedRequest = await _worksiteRepo.getRequestById(requestId);
      if (refreshedRequest != null) {
        _upsertRequestInCache(refreshedRequest);
      }
      if (_selectedRequest?.id == requestId) {
        _selectedOffers = await _worksiteRepo.listOffersForRequest(requestId);
        _selectedEvents = await _worksiteRepo.listRequestEvents(requestId);
      }
      return created;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Withdraws a pending offer submitted by the signed-in provider.
  Future<bool> withdrawOffer({
    required String requestId,
    required String offerId,
    String? providerId,
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(providerId);
      final cleanReqId = requestId.trim();
      final cleanOfferId = offerId.trim();

      if (_isDemoShowcaseMode && _showcaseBundle != null) {
        final offers = _demoOffersByRequest[cleanReqId];
        if (offers == null) {
          throw const WorksiteRepositoryException(
            code: 'not-found',
            messageAr: 'العرض المطلوب غير موجود.',
            messageEn: 'Offer not found.',
          );
        }
        final idx = offers.indexWhere((o) => o.id == cleanOfferId);
        if (idx < 0) {
          throw const WorksiteRepositoryException(
            code: 'not-found',
            messageAr: 'العرض المطلوب غير موجود.',
            messageEn: 'Offer not found.',
          );
        }
        final existing = offers[idx];
        if (existing.providerId != uid) {
          throw const WorksiteRepositoryException(
            code: 'permission-denied',
            messageAr: 'صاحب العرض فقط يمكنه سحب عرضه.',
            messageEn: 'Only the offer owner may withdraw it.',
          );
        }
        if (existing.status != 'pending') {
          throw const WorksiteRepositoryException(
            code: 'failed-precondition',
            messageAr: 'يمكن سحب العروض المعلقة فقط.',
            messageEn: 'Only pending offers can be withdrawn.',
          );
        }
        final now = DateTime.now().toUtc();
        offers[idx] = existing.copyWith(
          status: 'withdrawn',
          isSelected: false,
          updatedAt: now,
        );

        final req = _findShowcaseRequest(cleanReqId);
        if (req != null) {
          final pendingCount = offers.where((o) => o.status == 'pending').length;
          final nextStatus = (req.status == WorkRequestStatus.offerReceived &&
                  pendingCount == 0)
              ? WorkRequestStatus.open
              : req.status;
          final updatedReq = req.copyWith(
            status: nextStatus,
            offerCount: pendingCount,
            updatedAt: now,
          );
          _upsertRequestInCache(updatedReq);
          final events = _demoEventsByRequest.putIfAbsent(cleanReqId, () => []);
          events.add(
            RequestEvent(
              id: 'demo_evt_withdraw_${now.microsecondsSinceEpoch}',
              requestId: cleanReqId,
              actorId: uid,
              actorRole: 'provider',
              eventType: 'offer_withdrawn',
              fromStatus: req.status,
              toStatus: nextStatus,
              note: 'تم سحب العرض من قبل المزود.',
              metadata: {'offerId': cleanOfferId, 'providerId': uid},
              createdAt: now,
            ),
          );
          if (_selectedRequest?.id == cleanReqId) {
            _selectedRequest = updatedReq;
            _selectedOffers = List.unmodifiable(offers);
            _selectedEvents = List.unmodifiable(events);
          }
        }
        await _refreshNotifications(notify: false);
        return true;
      }

      await _worksiteRepo.withdrawOffer(
        requestId: cleanReqId,
        offerId: cleanOfferId,
        providerId: uid,
      );
      final refreshedRequest = await _worksiteRepo.getRequestById(cleanReqId);
      if (refreshedRequest != null) {
        _upsertRequestInCache(refreshedRequest);
      }
      if (_selectedRequest?.id == cleanReqId) {
        _selectedOffers = await _worksiteRepo.listOffersForRequest(cleanReqId);
        _selectedEvents = await _worksiteRepo.listRequestEvents(cleanReqId);
      }
      await _refreshNotifications(notify: false);
      return true;
    } catch (e) {
      _recordError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Cancels an active requester-owned work request before store pickup.
  Future<WorkRequest?> cancelRequest({
    required String requestId,
    String? requesterId,
    String? reason,
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(requesterId);
      final cleanReqId = requestId.trim();
      final cleanReason = reason?.trim();

      if (_isDemoShowcaseMode && _showcaseBundle != null) {
        final req = _findShowcaseRequest(cleanReqId);
        if (req == null) {
          throw const WorksiteRepositoryException(
            code: 'not-found',
            messageAr: 'طلب التوريد غير موجود.',
            messageEn: 'Work request not found.',
          );
        }
        if (req.requesterId != uid) {
          throw const WorksiteRepositoryException(
            code: 'permission-denied',
            messageAr: 'صاحب الطلب فقط يمكنه إلغاء هذا الطلب.',
            messageEn: 'Only the request owner may cancel this request.',
          );
        }
        const cancellableStatuses = {
          WorkRequestStatus.open,
          WorkRequestStatus.offerReceived,
          WorkRequestStatus.offerSelected,
          WorkRequestStatus.accepted,
          WorkRequestStatus.inProgress,
        };
        if (!cancellableStatuses.contains(req.status)) {
          throw WorksiteRepositoryException(
            code: 'failed-precondition',
            messageAr: 'لا يمكن إلغاء الطلب في مرحلته الحالية.',
            messageEn:
                "Cannot cancel request when status is '${req.status.value}'.",
          );
        }

        final now = DateTime.now().toUtc();
        final updated = req.copyWith(
          status: WorkRequestStatus.cancelled,
          cancellationReason:
              (cleanReason != null && cleanReason.isNotEmpty)
                  ? cleanReason
                  : req.cancellationReason,
          updatedAt: now,
        );
        _upsertRequestInCache(updated);
        final events = _demoEventsByRequest.putIfAbsent(cleanReqId, () => []);
        events.add(
          RequestEvent(
            id: 'demo_evt_cancel_${now.microsecondsSinceEpoch}',
            requestId: cleanReqId,
            actorId: uid,
            actorRole: 'requester',
            eventType: 'status_changed',
            fromStatus: req.status,
            toStatus: WorkRequestStatus.cancelled,
            note: (cleanReason != null && cleanReason.isNotEmpty)
                ? cleanReason
                : 'تم إلغاء الطلب من قبل صاحب الطلب.',
            createdAt: now,
          ),
        );
        if (_selectedRequest?.id == cleanReqId) {
          _selectedRequest = updated;
          _selectedEvents = List.unmodifiable(events);
          _activeHandoverCode = null;
        }
        await _refreshNotifications(notify: false);
        return updated;
      }

      final updated = await _worksiteRepo.cancelRequest(
        requestId: cleanReqId,
        requesterId: uid,
        reason: cleanReason,
      );
      _upsertRequestInCache(updated);
      if (_selectedRequest?.id == cleanReqId) {
        _selectedRequest = updated;
        _selectedEvents = await _worksiteRepo.listRequestEvents(cleanReqId);
        _activeHandoverCode = null;
      }
      await _refreshNotifications(notify: false);
      return updated;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Requester accepts an offer and loads the newly generated handover code.
  Future<WorkRequest?> acceptOffer({
    required String requestId,
    required String offerId,
    String? requesterId,
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(requesterId);
      final updated = await _worksiteRepo.acceptOffer(
        requestId: requestId,
        offerId: offerId,
        requesterId: uid,
      );
      _upsertRequestInCache(updated);
      _selectedRequest = updated;
      _selectedOffers = await _worksiteRepo.listOffersForRequest(requestId);
      _selectedEvents = await _worksiteRepo.listRequestEvents(requestId);
      _activeHandoverCode = await _worksiteRepo.getRequesterHandoverCode(
        requestId: requestId,
        requesterId: uid,
      );
      return updated;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Advances request fulfillment or cancels before pickup, optionally attaching receipt/invoice proof URLs.
  Future<WorkRequest?> advanceStatus({
    required String requestId,
    required WorkRequestStatus nextStatus,
    String? actorId,
    String actorRole = 'provider',
    String? note,
    List<String> invoiceProofUrls = const [],
    String? receiptImageUrl,
    MoneyMinor? actualReceiptTotalMinor,
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(actorId);
      final primaryReceiptUrl = receiptImageUrl?.trim().isNotEmpty == true
          ? receiptImageUrl!.trim()
          : (invoiceProofUrls.isNotEmpty
              ? invoiceProofUrls.first.trim()
              : null);

      final updated = await _worksiteRepo.updateFulfillmentStatus(
        requestId: requestId,
        nextStatus: nextStatus,
        actorId: uid,
        actorRole: actorRole,
        note: note,
        receiptImageUrl: primaryReceiptUrl,
        actualReceiptTotalMinor: actualReceiptTotalMinor,
      );
      _upsertRequestInCache(updated);
      if (_selectedRequest?.id == requestId) {
        _selectedRequest = updated;
        _selectedEvents = await _worksiteRepo.listRequestEvents(requestId);
      }
      return updated;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Verifies the requester's 6-char handover code as the assigned approved provider.
  Future<HandoverVerificationResult?> verifyHandoverCode(
    String requestId,
    String code, {
    String? providerId,
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(providerId);
      final result = await _worksiteRepo.verifyHandoverCode(
        requestId: requestId,
        providerId: uid,
        code: code,
      );
      final refreshed = await _worksiteRepo.getRequestById(requestId);
      if (refreshed != null) {
        _upsertRequestInCache(refreshed);
        if (_selectedRequest?.id == requestId) {
          _selectedRequest = refreshed;
          _selectedEvents = await _worksiteRepo.listRequestEvents(requestId);
          _activeHandoverCode = null;
        }
      }
      return result;
    } catch (e) {
      _recordError(e);
      if (_selectedRequest?.id == requestId) {
        try {
          _selectedEvents = await _worksiteRepo.listRequestEvents(requestId);
        } catch (_) {}
      }
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Submits a 1..5 star post-completion rating.
  Future<RequestRating?> submitRating({
    required String requestId,
    String? raterUserId,
    String raterRole = 'requester',
    required String targetUserId,
    required int score,
    String? comment,
    List<String> tags = const [],
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(raterUserId);
      final rating = RequestRating(
        id: '${requestId}_$uid',
        requestId: requestId,
        raterUserId: uid,
        raterRole: raterRole,
        targetUserId: targetUserId,
        score: score,
        comment: comment,
        tags: tags,
        createdAt: DateTime.now().toUtc(),
      );
      return await _worksiteRepo.submitRating(rating);
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Opens a dispute on an active request.
  Future<WorkRequest?> reportDispute({
    required String requestId,
    String? reporterId,
    String reporterRole = 'requester',
    required String reason,
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(reporterId);
      final updated = await _worksiteRepo.reportDispute(
        requestId: requestId,
        reporterId: uid,
        reporterRole: reporterRole,
        reason: reason,
      );
      _upsertRequestInCache(updated);
      if (_selectedRequest?.id == requestId) {
        _selectedRequest = updated;
        _selectedEvents = await _worksiteRepo.listRequestEvents(requestId);
      }
      return updated;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Submits manual bank transfer proof for a `bank_transfer_manual` request.
  Future<WorkRequest?> submitTransferProof({
    required String requestId,
    String? requesterId,
    required String proofUrl,
    String? referenceNumber,
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(requesterId);
      final updated = await _worksiteRepo.recordPaymentStatus(
        requestId: requestId,
        method: PaymentMethod.bankTransferManual,
        settlementStatus: PaymentSettlementStatus.transferProofSubmitted,
        actorId: uid,
        actorRole: 'requester',
        proofUrl: proofUrl,
        referenceNumber: referenceNumber,
      );
      _upsertRequestInCache(updated);
      if (_selectedRequest?.id == requestId) {
        _selectedRequest = updated;
        _selectedEvents = await _worksiteRepo.listRequestEvents(requestId);
      }
      return updated;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<ProviderProfile?> loadProviderProfile(String uid) async {
    _isLoading = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      if (_isDemoShowcaseMode && _showcaseBundle != null) {
        final demoProfile = _showcaseBundle!.providerProfileFor(uid);
        if (demoProfile != null) {
          _providerProfile = demoProfile;
          return demoProfile;
        }
      }
      ProviderProfile? profile;
      try {
        profile = await _providerRepo.getProviderProfile(uid);
      } catch (_) {
        if (!_shouldHydrateRichDemoBaseline) rethrow;
      }
      if (profile == null && _shouldHydrateRichDemoBaseline) {
        profile = _buildPersonalizedDemoBundle(uid).providerProfileFor(uid);
      }
      _providerProfile = profile;
      return profile;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProviderProfile?> saveProviderProfile(ProviderProfile profile) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final saved = await _providerRepo.upsertProviderProfile(profile);
      _providerProfile = saved;
      return saved;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<ProviderProfile?> submitVerification({
    String? userId,
    required String qidNumber,
    required String qidFrontUrl,
    required String qidBackUrl,
    String? selfieUrl,
    String? vehicleType,
    String? vehiclePlate,
    List<String> serviceMunicipalities = const [],
    List<String> supplySpecialties = const [],
  }) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final uid = _resolveRequiredUid(userId);
      final updated = await _providerRepo.submitProviderVerification(
        userId: uid,
        qidNumber: qidNumber,
        qidFrontUrl: qidFrontUrl,
        qidBackUrl: qidBackUrl,
        selfieUrl: selfieUrl,
        vehicleType: vehicleType,
        vehiclePlate: vehiclePlate,
        serviceMunicipalities: serviceMunicipalities,
        supplySpecialties: supplySpecialties,
      );
      _providerProfile = updated;
      return updated;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<List<SavedWorksite>> loadSavedWorksites(String uid) async {
    _isLoading = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      if (_isDemoShowcaseMode &&
          _showcaseBundle != null &&
          uid.trim() == _showcaseBundle!.currentUserId) {
        _savedWorksites = _showcaseBundle!.savedWorksites;
        return _savedWorksites;
      }
      List<SavedWorksite> sites = const [];
      try {
        sites = await _providerRepo.listSavedWorksites(uid);
      } catch (_) {
        if (!_shouldHydrateRichDemoBaseline) rethrow;
      }
      if (sites.isEmpty && _shouldHydrateRichDemoBaseline) {
        sites = _buildPersonalizedDemoBundle(uid).savedWorksites;
      }
      _savedWorksites = sites;
      return sites;
    } catch (e) {
      _recordError(e);
      return const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SavedWorksite?> addSavedWorksite(SavedWorksite worksite) async {
    _isSubmitting = true;
    _clearErrorSilently();
    notifyListeners();

    try {
      final saved = await _providerRepo.saveWorksite(worksite);
      _savedWorksites =
          await _providerRepo.listSavedWorksites(saved.ownerUserId);
      return saved;
    } catch (e) {
      _recordError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Loads notifications for the active user from Firestore (Firebase mode),
  /// [MashwarDemoCasesCatalog] (showcase/demo mode), or live request/offer alerts.
  Future<void> loadNotifications({String? currentUserIdOverride}) async {
    if (currentUserIdOverride != null &&
        currentUserIdOverride.trim().isNotEmpty) {
      _boundUserId = currentUserIdOverride.trim();
    }
    await _refreshNotifications(notify: true);
  }

  /// Marks a single notification as read locally and in Firestore when applicable.
  Future<void> markNotificationRead(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return;
    _locallyReadNotificationIds.add(cleanId);

    WorksiteNotificationItem? target;
    final next = _notifications.map((item) {
      if (item.id == cleanId) {
        target = item;
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    _notifications = next;
    notifyListeners();

    final item = target;
    final repo = _worksiteRepo;
    final uid = currentUserId;
    if (item != null &&
        !item.isDerived &&
        !_isDemoShowcaseMode &&
        repo is FirebaseWorksiteRepository &&
        uid != null &&
        uid.isNotEmpty) {
      try {
        await repo.markNotificationRead(cleanId, userId: uid);
      } catch (_) {}
    }
  }

  /// Marks every loaded notification as read locally and persists to Firestore when applicable.
  Future<void> markAllNotificationsRead() async {
    if (_notifications.isEmpty) return;

    final pendingRemoteIds = <String>[];
    final next = _notifications.map((item) {
      _locallyReadNotificationIds.add(item.id);
      if (!item.isRead && !item.isDerived) {
        pendingRemoteIds.add(item.id);
      }
      return item.copyWith(isRead: true);
    }).toList();
    _notifications = next;
    notifyListeners();

    final repo = _worksiteRepo;
    final uid = currentUserId;
    if (!_isDemoShowcaseMode &&
        repo is FirebaseWorksiteRepository &&
        uid != null &&
        uid.isNotEmpty &&
        pendingRemoteIds.isNotEmpty) {
      for (final notifId in pendingRemoteIds) {
        try {
          await repo.markNotificationRead(notifId, userId: uid);
        } catch (_) {}
      }
    }
  }

  WorkRequest? _findShowcaseRequest(String requestId) {
    final clean = requestId.trim();
    for (final req in _allLoadedRequests) {
      if (req.id == clean) return req;
    }
    return _showcaseBundle?.requestById(clean);
  }

  List<WorksiteNotificationItem> _buildShowcaseNotifications(
    MashwarDemoCasesBundle bundle,
  ) {
    final list = bundle.notifications.map((entry) {
      final item = WorksiteNotificationItem.fromDemoEntry(entry);
      return _locallyReadNotificationIds.contains(item.id)
          ? item.copyWith(isRead: true)
          : item;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _refreshNotifications({required bool notify}) async {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      _notifications = const [];
      if (notify) notifyListeners();
      return;
    }

    if (_isDemoShowcaseMode && _showcaseBundle != null) {
      _notifications = _buildShowcaseNotifications(_showcaseBundle!);
      if (notify) notifyListeners();
      return;
    }

    final repo = _worksiteRepo;
    if (repo is FirebaseWorksiteRepository || _isLiveBackendMode) {
      final byId = <String, WorksiteNotificationItem>{};
      if (repo is FirebaseWorksiteRepository) {
        try {
          final rawDocs = await repo.listNotifications(userId: uid);
          for (final doc in rawDocs) {
            final item = WorksiteNotificationItem.fromJson(doc);
            if (item.id.isEmpty) continue;
            byId[item.id] = _locallyReadNotificationIds.contains(item.id)
                ? item.copyWith(isRead: true)
                : item;
          }
        } catch (_) {}
      }
      for (final derived in _deriveLiveNotifications(uid)) {
        byId.putIfAbsent(derived.id, () => derived);
      }
      _notifications = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (notify) notifyListeners();
      return;
    }

    // Dev/local mode: hydrate catalog notifications when seeded with demo_wr_* cases,
    // or derive live alerts from loaded requests/offers/events.
    final hasCatalogRequests =
        _allLoadedRequests.any((r) => r.id.startsWith('demo_wr_'));
    if (hasCatalogRequests) {
      final demoBundle = MashwarDemoCasesCatalog.build(
        currentUserId: uid,
        currentUserName:
            currentUserName.isNotEmpty ? currentUserName : null,
      );
      _notifications = _buildShowcaseNotifications(demoBundle);
      if (notify) notifyListeners();
      return;
    }

    _notifications = _deriveLiveNotifications(uid);
    if (notify) notifyListeners();
  }

  List<WorksiteNotificationItem> _deriveLiveNotifications(String uid) {
    final items = <WorksiteNotificationItem>[];
    for (final req in _allLoadedRequests) {
      if (_isLiveBackendMode &&
          !_isDemoShowcaseMode &&
          req.id.startsWith('demo_wr_')) {
        continue;
      }
      final isRequester = req.requesterId == uid;
      final isAssignedProvider = req.assignedProviderId == uid;
      if (!isRequester && !isAssignedProvider) continue;

      final derivedId =
          'derived_${req.id}_${req.status.value}_${req.offerCount}';
      final isRead = _locallyReadNotificationIds.contains(derivedId);

      if (isRequester &&
          req.status == WorkRequestStatus.offerReceived &&
          req.offerCount > 0) {
        items.add(
          WorksiteNotificationItem(
            id: derivedId,
            userId: uid,
            title: '${req.offerCount} عروض جديدة على ${req.title}',
            titleAr: '${req.offerCount} عروض جديدة على ${req.title}',
            titleEn: '${req.offerCount} new offer(s) on ${req.title}',
            body:
                'تلقيت ${req.offerCount} عرضاً لموقع ${req.dropoffWorksite} في ${req.municipality}.',
            bodyAr:
                'تلقيت ${req.offerCount} عرضاً لموقع ${req.dropoffWorksite} في ${req.municipality}.',
            bodyEn:
                'You received ${req.offerCount} offer(s) for ${req.dropoffWorksite} (${req.municipality}).',
            type: 'new_offer',
            category: 'worksite_supply',
            requestId: req.id,
            targetRoute: '/work-requests/${req.id}',
            isRead: isRead,
            isDerived: true,
            createdAt: req.updatedAt,
          ),
        );
      } else if (req.status == WorkRequestStatus.deliveredPendingConfirmation) {
        items.add(
          WorksiteNotificationItem(
            id: derivedId,
            userId: uid,
            title: isAssignedProvider
                ? 'بانتظار إدخال رمز التسليم: ${req.title}'
                : 'بانتظار تأكيد استلامك: ${req.title}',
            titleAr: isAssignedProvider
                ? 'بانتظار إدخال رمز التسليم: ${req.title}'
                : 'بانتظار تأكيد استلامك: ${req.title}',
            titleEn: isAssignedProvider
                ? 'Enter handover code to close: ${req.title}'
                : 'Delivery awaiting confirmation: ${req.title}',
            body: isAssignedProvider
                ? 'اطلب رمز التسليم المكون من 6 خانات عند بوابة ${req.dropoffWorksite}.'
                : 'وصل المزود إلى ${req.dropoffWorksite}. شارك رمز التسليم عند مطابقة المواد والفاتورة.',
            bodyAr: isAssignedProvider
                ? 'اطلب رمز التسليم المكون من 6 خانات عند بوابة ${req.dropoffWorksite}.'
                : 'وصل المزود إلى ${req.dropoffWorksite}. شارك رمز التسليم عند مطابقة المواد والفاتورة.',
            bodyEn: isAssignedProvider
                ? 'Request the 6-char handover code at ${req.dropoffWorksite}.'
                : 'Provider arrived at ${req.dropoffWorksite}. Share handover code after verifying items.',
            type: 'handover_pending',
            category: 'worksite_supply',
            requestId: req.id,
            targetRoute: '/work-requests/${req.id}',
            isRead: isRead,
            isDerived: true,
            createdAt: req.updatedAt,
          ),
        );
      } else if (req.status == WorkRequestStatus.disputed) {
        items.add(
          WorksiteNotificationItem(
            id: derivedId,
            userId: uid,
            title: 'تنبيه نزاع: ${req.title}',
            titleAr: 'تنبيه نزاع: ${req.title}',
            titleEn: 'Dispute alert: ${req.title}',
            body: req.disputeReason ?? 'الطلب قيد مراجعة فريق الدعم.',
            bodyAr: req.disputeReason ?? 'الطلب قيد مراجعة فريق الدعم.',
            bodyEn: req.disputeReason ?? 'Request is under Trust & Safety review.',
            type: 'dispute_alert',
            category: 'worksite_supply',
            requestId: req.id,
            targetRoute: '/work-requests/${req.id}',
            isRead: isRead,
            isDerived: true,
            createdAt: req.updatedAt,
          ),
        );
      } else if (req.status == WorkRequestStatus.accepted ||
          req.status == WorkRequestStatus.inProgress ||
          req.status == WorkRequestStatus.pickedUp ||
          req.status == WorkRequestStatus.inTransit) {
        items.add(
          WorksiteNotificationItem(
            id: derivedId,
            userId: uid,
            title: 'تحديث التوريد: ${req.title}',
            titleAr: 'تحديث التوريد: ${req.title}',
            titleEn: 'Supply update: ${req.title}',
            body:
                'الحالة الحالية: ${req.status.label(isArabic: true)} — ${req.dropoffWorksite}',
            bodyAr:
                'الحالة الحالية: ${req.status.label(isArabic: true)} — ${req.dropoffWorksite}',
            bodyEn:
                'Current status: ${req.status.label(isArabic: false)} — ${req.dropoffWorksite}',
            type: 'status_update',
            category: 'worksite_supply',
            requestId: req.id,
            targetRoute: '/work-requests/${req.id}',
            isRead: isRead,
            isDerived: true,
            createdAt: req.updatedAt,
          ),
        );
      }
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }
}
