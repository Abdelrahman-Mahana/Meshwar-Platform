import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models/board_ad_model.dart';

class BoardProvider extends ChangeNotifier {
  BoardAdType _selectedType = BoardAdType.all;
  int _radiusKm = 50;
  final List<BoardAdModel> _ads = List.from(MockData.initialBoardAds);
  final List<BoardAdModel> _myAds = [
    const BoardAdModel(
      id: 'my_ad_1',
      type: BoardAdType.rideRequest,
      authorName: 'عبدالرحمن أحمد',
      isVerified: true,
      tripCount: 14,
      postedAgo: 'منذ ساعتين',
      fromCity: 'كفر الشيخ',
      toCity: 'القاهرة',
      timeText: 'الجمعة 6 نوفمبر · صباحاً',
      description: 'محتاج مقعدين يوم الجمعة الصبح بدري مع سائق موثق',
      priceOrBudget: 65,
      status: BoardAdStatus.active,
    ),
    const BoardAdModel(
      id: 'my_ad_2',
      type: BoardAdType.parcelRequest,
      authorName: 'عبدالرحمن أحمد',
      isVerified: true,
      tripCount: 14,
      postedAgo: 'منذ 3 أيام',
      fromCity: 'طنطا',
      toCity: 'المنصورة',
      timeText: 'الثلاثاء · مساءً',
      description: 'إرسال ظرف أوراق رسمية مستعجل',
      priceOrBudget: 40,
      status: BoardAdStatus.completed,
    ),
  ];

  BoardAdType get selectedType => _selectedType;
  int get radiusKm => _radiusKm;
  List<BoardAdModel> get myAds => List.unmodifiable(_myAds);

  List<BoardAdModel> get filteredAds {
    if (_selectedType == BoardAdType.all) return _ads;
    return _ads.where((ad) => ad.type == _selectedType).toList();
  }

  void setSelectedType(BoardAdType type) {
    _selectedType = type;
    notifyListeners();
  }

  void setRadiusKm(int radius) {
    _radiusKm = radius;
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
  }) {
    final newAd = BoardAdModel(
      id: 'ad_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      authorName: 'عبدالرحمن أحمد',
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
    );
    _ads.insert(0, newAd);
    _myAds.insert(0, newAd);
    notifyListeners();
  }

  void submitOffer({
    required String adId,
    required int offerPrice,
  }) {
    final index = _ads.indexWhere((a) => a.id == adId);
    if (index != -1) {
      _ads[index] = _ads[index].copyWith(
        status: BoardAdStatus.offerSent,
        myOfferPrice: offerPrice,
      );
      notifyListeners();
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
  }
}


