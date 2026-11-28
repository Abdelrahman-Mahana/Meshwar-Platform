import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../core/config/app_environment.dart';
import '../data/mock_data.dart';
import '../data/models/board_ad_model.dart';
import '../data/repositories/app_repositories.dart';
import '../data/repositories/implementations/firebase/firebase_board_repository.dart';
import '../data/services/qatar_city_matcher.dart';

class BoardProvider extends ChangeNotifier {
  static bool get _isLiveBackendMode =>
      AppEnvironment.isFirebaseRuntimeActive ||
      AppEnvironment.flavor != AppFlavor.development;

  static const List<BoardAdModel> _devSeedMyAds = [
    BoardAdModel(
      id: 'my_ad_1',
      authorId: 'user_01',
      type: BoardAdType.rideRequest,
      authorName: 'عبدالرحمن المهنا',
      isVerified: true,
      tripCount: 14,
      postedAgo: 'منذ ساعتين',
      fromCity: 'الدوحة',
      toCity: 'الخور',
      seatsNeeded: 2,
      timeText: 'الجمعة 6 نوفمبر · صباحاً',
      description: 'أحتاج مقعدين يوم الجمعة صباحاً مع مسافر موثق على طريق الشمال',
      priceOrBudget: 35,
      status: BoardAdStatus.active,
    ),
    BoardAdModel(
      id: 'my_ad_2',
      authorId: 'user_01',
      type: BoardAdType.parcelRequest,
      authorName: 'عبدالرحمن المهنا',
      isVerified: true,
      tripCount: 14,
      postedAgo: 'منذ 3 أيام',
      fromCity: 'الوكرة',
      toCity: 'لوسيل',
      maxParcelSize: 'envelope',
      timeText: 'الثلاثاء · مساءً',
      description: 'إرسال ظرف مستندات رسمية مستعجل مع تسليم بكود الأمان',
      priceOrBudget: 25,
      status: BoardAdStatus.completed,
    ),
    BoardAdModel(
      id: 'my_ad_3',
      authorId: 'user_01',
      type: BoardAdType.parcelRequest,
      authorName: 'عبدالرحمن المهنا',
      isVerified: true,
      tripCount: 14,
      postedAgo: 'منذ 40 دقيقة',
      fromCity: 'لوسيل',
      toCity: 'دخان',
      maxParcelSize: 'small',
      timeText: 'اليوم 5:00 م · علبة معدات قياس صغيرة',
      description:
          'أرغب في إرسال جهاز قياس ليزري مغلف بعناية مع مسافر متجه إلى دخان هذا المساء بكود تحقق مزدوج.',
      priceOrBudget: 35,
      serviceSubTagAr: 'طرد موثّق · OTP',
      serviceSubTagEn: 'Verified Parcel · OTP',
      status: BoardAdStatus.active,
    ),
  ];

  String? _boundUserId;
  BoardAdType _selectedType = BoardAdType.all;
  int _radiusKm = 50;
  String _searchQuery = '';
  String _fromFilter = '';
  String _toFilter = '';
  bool _isLoading = false;

  final List<BoardAdModel> _ads = [];
  final List<BoardAdModel> _myAds = [];

  BoardProvider({String? initialUserId})
      : _boundUserId =
            (initialUserId != null && initialUserId.trim().isNotEmpty)
                ? initialUserId.trim()
                : null {
    if (!_isLiveBackendMode) {
      _ads.addAll(MockData.initialBoardAds);
      _myAds.addAll(_devSeedMyAds);
    }
  }

  /// Syncs active auth user identity from [AuthProvider], clearing previous
  /// account ads/offers on sign-out or user switch.
  void syncAuthSession({required String? uid}) {
    final clean = uid?.trim();
    final normalizedNext =
        (clean != null && clean.isNotEmpty) ? clean : null;
    final previousUid = _boundUserId;
    _boundUserId = normalizedNext;

    final uidChanged = previousUid != normalizedNext;
    final shouldClearOnNull = normalizedNext == null &&
        (_isLiveBackendMode || uidChanged) &&
        (_myAds.isNotEmpty || (_isLiveBackendMode && _ads.isNotEmpty));

    if (uidChanged || shouldClearOnNull) {
      _myAds.clear();
      if (_isLiveBackendMode) {
        _ads.clear();
      }
      notifyListeners();
    }
  }

  BoardAdType get selectedType => _selectedType;
  int get radiusKm => _radiusKm;
  String get searchQuery => _searchQuery;
  String get fromFilter => _fromFilter;
  String get toFilter => _toFilter;
  bool get isLoading => _isLoading;
  bool get hasRouteFilter =>
      _fromFilter.trim().isNotEmpty || _toFilter.trim().isNotEmpty;
  List<BoardAdModel> get allAds => List.unmodifiable(_ads);
  List<BoardAdModel> get myAds => List.unmodifiable(_myAds);
  List<BoardAdModel> get mySentOffers => List.unmodifiable(
        _ads.where((ad) => ad.status == BoardAdStatus.offerSent),
      );

  static bool _matchesRouteToken(String query, List<String?> candidates) =>
      QatarCityMatcher.matchesCityField(query, candidates);

  /// Fetches live `board_ads` and user-owned ads from [AppRepositories.instance.board].
  /// In live Firebase/production mode, never merges [MockData.initialBoardAds].
  Future<void> loadBoardAds() async {
    _isLoading = true;
    notifyListeners();
    try {
      final repo = AppRepositories.instance.board;
      if (_isLiveBackendMode) {
        final results = await Future.wait<List<BoardAdModel>>([
          repo.getBoardAds(),
          repo.getMyAds(),
        ]);
        final remoteAds = results[0];
        final remoteMyAds = results[1];

        final myById = <String, BoardAdModel>{
          for (final ad in remoteMyAds)
            if (ad.id.isNotEmpty) ad.id: ad,
        };
        for (final localOwn in _myAds) {
          if (localOwn.id.isNotEmpty) {
            myById.putIfAbsent(localOwn.id, () => localOwn);
          }
        }
        _myAds
          ..clear()
          ..addAll(myById.values);

        final mergedById = <String, BoardAdModel>{
          for (final ad in remoteAds)
            if (ad.id.isNotEmpty) ad.id: ad,
        };
        for (final own in _myAds) {
          if (own.status == BoardAdStatus.active ||
              own.status == BoardAdStatus.offerSent) {
            mergedById.putIfAbsent(own.id, () => own);
          }
        }
        _ads
          ..clear()
          ..addAll(mergedById.values);
        return;
      }

      final remoteAds = await repo.getBoardAds();
      final mergedById = <String, BoardAdModel>{};
      for (final ad in remoteAds) {
        if (ad.id.isNotEmpty) {
          mergedById[ad.id] = ad;
        }
      }
      for (final own in _myAds) {
        if (own.status == BoardAdStatus.active ||
            own.status == BoardAdStatus.offerSent) {
          mergedById.putIfAbsent(own.id, () => own);
        }
      }
      for (final seed in MockData.initialBoardAds) {
        mergedById.putIfAbsent(seed.id, () => seed);
      }
      _ads
        ..clear()
        ..addAll(mergedById.values);
    } catch (_) {
      if (!_isLiveBackendMode && _ads.isEmpty) {
        _ads.addAll(MockData.initialBoardAds);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<BoardAdModel> get filteredAds {
    Iterable<BoardAdModel> result = _ads.where(
      (ad) => ad.status != BoardAdStatus.cancelled,
    );
    if (_selectedType != BoardAdType.all) {
      result = result.where((ad) => ad.type == _selectedType);
    }
    if (_fromFilter.trim().isNotEmpty) {
      result = result.where(
        (ad) => _matchesRouteToken(
          _fromFilter,
          [ad.fromCity, ad.stopoverCity],
        ),
      );
    }
    if (_toFilter.trim().isNotEmpty) {
      result = result.where(
        (ad) => _matchesRouteToken(
          _toFilter,
          [ad.toCity, ad.stopoverCity],
        ),
      );
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where(
        (ad) =>
            ad.fromCity.toLowerCase().contains(q) ||
            ad.toCity.toLowerCase().contains(q) ||
            (ad.stopoverCity?.toLowerCase().contains(q) ?? false) ||
            ad.authorName.toLowerCase().contains(q) ||
            ad.description.toLowerCase().contains(q) ||
            ad.timeText.toLowerCase().contains(q) ||
            ad.displaySubTag(true).toLowerCase().contains(q) ||
            ad.displaySubTag(false).toLowerCase().contains(q) ||
            (ad.notes?.toLowerCase().contains(q) ?? false),
      );
    }
    return result.toList();
  }

  void setSelectedType(BoardAdType type) {
    _selectedType = type;
    notifyListeners();
  }

  void setRadiusKm(int radius) {
    _radiusKm = radius;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRouteFilter({String? from, String? to}) {
    if (from != null) _fromFilter = from.trim();
    if (to != null) _toFilter = to.trim();
    notifyListeners();
  }

  void clearRouteFilter() {
    _fromFilter = '';
    _toFilter = '';
    notifyListeners();
  }

  fb_auth.User? _resolveCurrentAuthUser() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return fb_auth.FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  BoardAdModel postAd({
    required BoardAdType type,
    required String fromCity,
    required String toCity,
    String? stopoverCity,
    required String timeText,
    required String description,
    required int priceOrBudget,
    String? authorName,
    String? authorId,
    String? maxParcelSize,
    int? seatsNeeded,
    String? notes,
    bool isLadiesOnly = false,
    String? serviceSubTagAr,
    String? serviceSubTagEn,
    bool hasEscrowProtection = true,
    bool requiresReceiptProof = false,
    int? estimatedItemCost,
    bool isProviderOffer = false,
    bool isVerified = false,
    int tripCount = 0,
  }) {
    final authUser = _resolveCurrentAuthUser();
    final resolvedAuthorId = (authorId != null && authorId.trim().isNotEmpty)
        ? authorId.trim()
        : ((authUser != null && authUser.uid.isNotEmpty)
            ? authUser.uid
            : (_boundUserId ??
                (_isLiveBackendMode ? '' : MockData.currentUser.id)));
    final resolvedAuthorName =
        (authorName != null && authorName.trim().length >= 2)
            ? authorName.trim()
            : ((authUser?.displayName != null &&
                    authUser!.displayName!.trim().length >= 2)
                ? authUser.displayName!.trim()
                : (_isLiveBackendMode ? 'عضو مشوار' : MockData.currentUser.fullName));

    final newAd = BoardAdModel(
      id: 'my_ad_${DateTime.now().millisecondsSinceEpoch}',
      authorId: resolvedAuthorId,
      type: type,
      authorName: resolvedAuthorName,
      isVerified: isVerified,
      tripCount: tripCount,
      postedAgo: 'الآن',
      fromCity: fromCity.trim(),
      toCity: toCity.trim(),
      stopoverCity:
          (stopoverCity != null && stopoverCity.trim().isNotEmpty)
              ? stopoverCity.trim()
              : null,
      timeText: timeText.trim(),
      description: description.trim(),
      priceOrBudget: priceOrBudget.clamp(0, 50000),
      notes: (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
      isLadiesOnly: isLadiesOnly,
      status: BoardAdStatus.active,
      serviceSubTagAr: serviceSubTagAr,
      serviceSubTagEn: serviceSubTagEn,
      hasEscrowProtection: hasEscrowProtection,
      requiresReceiptProof: requiresReceiptProof,
      estimatedItemCost: estimatedItemCost,
      isProviderOffer: isProviderOffer || type == BoardAdType.rideOffer,
      maxParcelSize: maxParcelSize,
      seatsNeeded: seatsNeeded,
    );
    _ads.insert(0, newAd);
    _myAds.insert(0, newAd);
    notifyListeners();
    AppRepositories.instance.board
        .createBoardAd(newAd)
        .catchError((_) => newAd);
    return newAd;
  }

  void submitOffer({
    required String adId,
    required int offerPrice,
    String? note,
    String? driverName,
    String? driverId,
    String? timeText,
  }) {
    final index = _ads.indexWhere((a) => a.id == adId);
    if (index != -1) {
      final authUser = _resolveCurrentAuthUser();
      final resolvedDriverName =
          (driverName != null && driverName.trim().length >= 2)
              ? driverName.trim()
              : ((authUser?.displayName != null &&
                      authUser!.displayName!.trim().length >= 2)
                  ? authUser.displayName!.trim()
                  : (_isLiveBackendMode
                      ? 'مسافر مشوار'
                      : MockData.currentUser.fullName));
      final cleanNote =
          (note != null && note.trim().isNotEmpty) ? note.trim() : null;

      _ads[index] = _ads[index].copyWith(
        status: BoardAdStatus.offerSent,
        myOfferPrice: offerPrice,
        notes: cleanNote ?? _ads[index].notes,
      );
      notifyListeners();
      AppRepositories.instance.board
          .makeOffer(
            adId: adId,
            offerPrice: offerPrice,
            timeText: (timeText != null && timeText.trim().isNotEmpty)
                ? timeText.trim()
                : _ads[index].timeText,
            driverName: resolvedDriverName,
          )
          .ignore();
    }
  }

  void acceptOfferOnMyAd(
    String adId, {
    int? acceptedPrice,
    String? providerName,
  }) {
    int? resolvedPrice = acceptedPrice;
    final myIdx = _myAds.indexWhere((a) => a.id == adId);
    if (myIdx != -1) {
      final existing = _myAds[myIdx];
      resolvedPrice ??= existing.myOfferPrice ?? existing.priceOrBudget;
      final updatedNote = (providerName != null && providerName.trim().isNotEmpty)
          ? '${existing.notes != null && existing.notes!.isNotEmpty ? "${existing.notes} · " : ""}${providerName.trim()}'
          : existing.notes;
      _myAds[myIdx] = existing.copyWith(
        status: BoardAdStatus.completed,
        myOfferPrice: resolvedPrice,
        notes: updatedNote,
      );
    }

    final allIdx = _ads.indexWhere((a) => a.id == adId);
    if (allIdx != -1) {
      final existing = _ads[allIdx];
      resolvedPrice ??= existing.myOfferPrice ?? existing.priceOrBudget;
      _ads[allIdx] = existing.copyWith(
        status: BoardAdStatus.completed,
        myOfferPrice: resolvedPrice,
      );
    }

    notifyListeners();
    final repo = AppRepositories.instance.board;
    if (repo is FirebaseBoardRepository) {
      repo
          .updateMyAdStatus(
            adId,
            BoardAdStatus.completed,
            acceptedPrice: resolvedPrice,
          )
          .ignore();
    }
  }

  void withdrawOffer(String adId) {
    final index = _ads.indexWhere((a) => a.id == adId);
    if (index != -1) {
      _ads[index] = _ads[index].copyWith(
        status: BoardAdStatus.active,
        clearMyOfferPrice: true,
      );
      notifyListeners();
      AppRepositories.instance.board.withdrawOffer(adId).ignore();
    }
  }

  void markAdCompleted(String adId) {
    acceptOfferOnMyAd(adId);
  }

  void deleteMyAd(String adId) {
    _myAds.removeWhere((a) => a.id == adId);
    _ads.removeWhere((a) => a.id == adId);
    notifyListeners();
    AppRepositories.instance.board.deleteAd(adId).ignore();
  }
}
