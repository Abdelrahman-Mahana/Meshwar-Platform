import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models/board_ad_model.dart';
import '../data/repositories/app_repositories.dart';

class BoardProvider extends ChangeNotifier {
  BoardAdType _selectedType = BoardAdType.all;
  int _radiusKm = 50;
  String _searchQuery = '';
  final List<BoardAdModel> _ads = List.from(MockData.initialBoardAds);
  final List<BoardAdModel> _myAds = [
    const BoardAdModel(
      id: 'my_ad_1',
      type: BoardAdType.rideRequest,
      authorName: 'عبدالرحمن المهنا',
      isVerified: true,
      tripCount: 14,
      postedAgo: 'منذ ساعتين',
      fromCity: 'الدوحة',
      toCity: 'الخور',
      timeText: 'الجمعة 6 نوفمبر · صباحاً',
      description: 'أحتاج مقعدين يوم الجمعة صباحاً مع سائق موثق على طريق الشمال',
      priceOrBudget: 35,
      status: BoardAdStatus.active,
    ),
    const BoardAdModel(
      id: 'my_ad_2',
      type: BoardAdType.parcelRequest,
      authorName: 'عبدالرحمن المهنا',
      isVerified: true,
      tripCount: 14,
      postedAgo: 'منذ 3 أيام',
      fromCity: 'الوكرة',
      toCity: 'لوسيل',
      timeText: 'الثلاثاء · مساءً',
      description: 'إرسال ظرف مستندات رسمية مستعجل',
      priceOrBudget: 25,
      status: BoardAdStatus.completed,
    ),
  ];

  BoardAdType get selectedType => _selectedType;
  int get radiusKm => _radiusKm;
  String get searchQuery => _searchQuery;
  List<BoardAdModel> get myAds => List.unmodifiable(_myAds);
  List<BoardAdModel> get mySentOffers =>
      List.unmodifiable(_ads.where((ad) => ad.status == BoardAdStatus.offerSent));

  List<BoardAdModel> get filteredAds {
    Iterable<BoardAdModel> result = _ads;
    if (_selectedType != BoardAdType.all) {
      result = result.where((ad) => ad.type == _selectedType);
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((ad) =>
          ad.fromCity.toLowerCase().contains(q) ||
          ad.toCity.toLowerCase().contains(q) ||
          ad.authorName.toLowerCase().contains(q) ||
          ad.description.toLowerCase().contains(q) ||
          ad.timeText.toLowerCase().contains(q) ||
          ad.displaySubTag(true).toLowerCase().contains(q) ||
          (ad.notes?.toLowerCase().contains(q) ?? false));
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

  void postAd({
    required BoardAdType type,
    required String fromCity,
    required String toCity,
    required String timeText,
    required String description,
    required int priceOrBudget,
    String? notes,
    bool isLadiesOnly = false,
    String? serviceSubTagAr,
    String? serviceSubTagEn,
    bool hasEscrowProtection = true,
    bool requiresReceiptProof = false,
    int? estimatedItemCost,
    bool isProviderOffer = false,
  }) {
    final newAd = BoardAdModel(
      id: 'my_ad_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      authorName: 'عبدالرحمن المهنا',
      isVerified: true,
      tripCount: 14,
      postedAgo: 'الآن',
      fromCity: fromCity,
      toCity: toCity,
      timeText: timeText,
      description: description,
      priceOrBudget: priceOrBudget,
      notes: notes,
      isLadiesOnly: isLadiesOnly,
      status: BoardAdStatus.active,
      serviceSubTagAr: serviceSubTagAr,
      serviceSubTagEn: serviceSubTagEn,
      hasEscrowProtection: hasEscrowProtection,
      requiresReceiptProof: requiresReceiptProof,
      estimatedItemCost: estimatedItemCost,
      isProviderOffer: isProviderOffer || type == BoardAdType.rideOffer,
    );
    _ads.insert(0, newAd);
    _myAds.insert(0, newAd);
    notifyListeners();
    AppRepositories.instance.board.createBoardAd(newAd).ignore();
  }

  void submitOffer({
    required String adId,
    required int offerPrice,
    String? note,
  }) {
    final index = _ads.indexWhere((a) => a.id == adId);
    if (index != -1) {
      _ads[index] = _ads[index].copyWith(
        status: BoardAdStatus.offerSent,
        myOfferPrice: offerPrice,
        notes: note ?? _ads[index].notes,
      );
      notifyListeners();
      AppRepositories.instance.board.makeOffer(
        adId: adId,
        offerPrice: offerPrice,
        timeText: _ads[index].timeText,
        driverName: 'عبدالرحمن أحمد',
      ).ignore();
    }
  }

  void withdrawOffer(String adId) {
    final index = _ads.indexWhere((a) => a.id == adId);
    if (index != -1) {
      _ads[index] = _ads[index].copyWith(
        status: BoardAdStatus.active,
        myOfferPrice: null,
      );
      notifyListeners();
      AppRepositories.instance.board.withdrawOffer(adId).ignore();
    }
  }

  void markAdCompleted(String adId) {
    final idx = _myAds.indexWhere((a) => a.id == adId);
    if (idx != -1) {
      _myAds[idx] = _myAds[idx].copyWith(status: BoardAdStatus.completed);
    }
    final allIdx = _ads.indexWhere((a) => a.id == adId);
    if (allIdx != -1) {
      _ads[allIdx] = _ads[allIdx].copyWith(status: BoardAdStatus.completed);
    }
    notifyListeners();
  }

  void deleteMyAd(String adId) {
    _myAds.removeWhere((a) => a.id == adId);
    _ads.removeWhere((a) => a.id == adId);
    notifyListeners();
    AppRepositories.instance.board.deleteAd(adId).ignore();
  }
}


