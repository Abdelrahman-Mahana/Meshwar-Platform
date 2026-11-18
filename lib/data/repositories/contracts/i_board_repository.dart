import '../../models/board_ad_model.dart';

abstract class IBoardRepository {
  Future<List<BoardAdModel>> getBoardAds({
    BoardAdType? type,
    String? fromCity,
    String? toCity,
  });

  Future<BoardAdModel> createBoardAd(BoardAdModel ad);
  Future<bool> makeOffer({
    required String adId,
    required int offerPrice,
    required String timeText,
    required String driverName,
  });
  Future<bool> withdrawOffer(String adId);
  Future<List<BoardAdModel>> getMyAds();
  Future<List<BoardAdModel>> getMySentOffers();
  Future<bool> deleteAd(String adId);
}
