import '../../models/board_ad_model.dart';
import '../../mock_data.dart';
import '../contracts/i_board_repository.dart';

class BoardRepositoryImpl implements IBoardRepository {
  final List<BoardAdModel> _ads = List.from(MockData.initialBoardAds);
  final List<BoardAdModel> _myOffers = [];

  @override
  Future<List<BoardAdModel>> getBoardAds({
    BoardAdType? type,
    String? fromCity,
    String? toCity,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _ads.where((ad) {
      if (type != null && type != BoardAdType.all && ad.type != type) {
        return false;
      }
      if (fromCity != null && fromCity.isNotEmpty && !ad.fromCity.contains(fromCity)) {
        return false;
      }
      if (toCity != null && toCity.isNotEmpty && !ad.toCity.contains(toCity)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<BoardAdModel> createBoardAd(BoardAdModel ad) async {
    await Future.delayed(const Duration(milliseconds: 350));
    _ads.insert(0, ad);
    return ad;
  }

  @override
  Future<bool> makeOffer({
    required String adId,
    required int offerPrice,
    required String timeText,
    required String driverName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _ads.indexWhere((a) => a.id == adId);
    if (index != -1) {
      final updated = _ads[index].copyWith(
        status: BoardAdStatus.offerSent,
        myOfferPrice: offerPrice,
      );
      _ads[index] = updated;
      _myOffers.add(updated);
      return true;
    }
    return false;
  }

  @override
  Future<bool> withdrawOffer(String adId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _ads.indexWhere((a) => a.id == adId);
    if (index != -1) {
      _ads[index] = _ads[index].copyWith(
        status: BoardAdStatus.active,
        myOfferPrice: null,
      );
      _myOffers.removeWhere((a) => a.id == adId);
      return true;
    }
    return false;
  }

  @override
  Future<List<BoardAdModel>> getMyAds() async {
    return _ads.where((a) => a.authorName == 'أحمد محمود' || a.id.startsWith('my_ad_')).toList();
  }

  @override
  Future<List<BoardAdModel>> getMySentOffers() async {
    return _myOffers;
  }

  @override
  Future<bool> deleteAd(String adId) async {
    _ads.removeWhere((a) => a.id == adId);
    return true;
  }
}
