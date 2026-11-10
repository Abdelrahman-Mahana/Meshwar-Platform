import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models/board_ad_model.dart';

class BoardProvider extends ChangeNotifier {
  BoardAdType _selectedType = BoardAdType.all;
  int _radiusKm = 50;
  final List<BoardAdModel> _ads = List.from(MockData.initialBoardAds);

  BoardAdType get selectedType => _selectedType;
  int get radiusKm => _radiusKm;

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
      tripCount: 1,
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
}

