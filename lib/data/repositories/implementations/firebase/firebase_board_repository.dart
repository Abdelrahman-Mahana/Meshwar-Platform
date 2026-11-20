import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/board_ad_model.dart';
import '../../contracts/i_board_repository.dart';
import '../../../services/firebase_firestore_service.dart';

class FirebaseBoardRepository implements IBoardRepository {
  final FirebaseFirestore _firestore;

  FirebaseBoardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<BoardAdModel>> getBoardAds({
    BoardAdType? type,
    String? fromCity,
    String? toCity,
  }) async {
    Query query = _firestore
        .collection(FirestoreCollections.boardAds)
        .where('status', isEqualTo: BoardAdStatus.active.name);

    if (type != null && type != BoardAdType.all) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (fromCity != null && fromCity.isNotEmpty) {
      query = query.where('fromCity', isEqualTo: fromCity);
    }
    if (toCity != null && toCity.isNotEmpty) {
      query = query.where('toCity', isEqualTo: toCity);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return BoardAdModel.fromJson(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<BoardAdModel> createBoardAd(BoardAdModel ad) async {
    await _firestore
        .collection(FirestoreCollections.boardAds)
        .doc(ad.id)
        .set(ad.toJson());
    return ad;
  }

  @override
  Future<bool> makeOffer({
    required String adId,
    required int offerPrice,
    required String timeText,
    required String driverName,
  }) async {
    final offerRef = _firestore
        .collection(FirestoreCollections.boardAds)
        .doc(adId)
        .collection(FirestoreCollections.boardOffers)
        .doc();

    final offerData = {
      'id': offerRef.id,
      'adId': adId,
      'driverName': driverName,
      'offerPrice': offerPrice,
      'timeText': timeText,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await offerRef.set(offerData);
    await _firestore.collection(FirestoreCollections.boardAds).doc(adId).update({
      'status': BoardAdStatus.offerSent.name,
      'myOfferPrice': offerPrice,
    });
    return true;
  }

  @override
  Future<bool> withdrawOffer(String adId) async {
    await _firestore.collection(FirestoreCollections.boardAds).doc(adId).update({
      'status': BoardAdStatus.active.name,
      'myOfferPrice': null,
    });
    return true;
  }

  @override
  Future<List<BoardAdModel>> getMyAds() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.boardAds)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => BoardAdModel.fromJson(doc.data())).toList();
  }

  @override
  Future<List<BoardAdModel>> getMySentOffers() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.boardAds)
        .where('status', isEqualTo: BoardAdStatus.offerSent.name)
        .get();

    return snapshot.docs.map((doc) => BoardAdModel.fromJson(doc.data())).toList();
  }

  @override
  Future<bool> deleteAd(String adId) async {
    await _firestore.collection(FirestoreCollections.boardAds).doc(adId).delete();
    return true;
  }
}
