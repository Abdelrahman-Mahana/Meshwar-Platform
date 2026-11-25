import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import '../../../models/board_ad_model.dart';
import '../../contracts/i_board_repository.dart';
import '../../../services/firebase_firestore_service.dart';

class FirebaseBoardRepository implements IBoardRepository {
  final FirebaseFirestore? _injectedFirestore;
  final fb_auth.FirebaseAuth? _injectedAuth;

  FirebaseBoardRepository({
    FirebaseFirestore? firestore,
    fb_auth.FirebaseAuth? auth,
  })  : _injectedFirestore = firestore,
        _injectedAuth = auth;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  fb_auth.User? get _currentUser {
    try {
      final injected = _injectedAuth;
      if (injected != null) return injected.currentUser;
      if (Firebase.apps.isEmpty) return null;
      return fb_auth.FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BoardAdModel>> getBoardAds({
    BoardAdType? type,
    String? fromCity,
    String? toCity,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirestoreCollections.boardAds)
          .where('status', isEqualTo: BoardAdStatus.active.name);

      if (type != null && type != BoardAdType.all) {
        query = query.where('type', isEqualTo: type.name);
      }
      if (fromCity != null && fromCity.trim().isNotEmpty) {
        query = query.where('fromCity', isEqualTo: fromCity.trim());
      }
      if (toCity != null && toCity.trim().isNotEmpty) {
        query = query.where('toCity', isEqualTo: toCity.trim());
      }

      final snapshot = await query.limit(50).get();
      return snapshot.docs
          .map((doc) => BoardAdModel.fromJson(doc.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<BoardAdModel> createBoardAd(BoardAdModel ad) async {
    final user = _currentUser;
    final resolvedAuthorId = (user != null && user.uid.isNotEmpty)
        ? user.uid
        : ((ad.authorId != null && ad.authorId!.trim().isNotEmpty)
            ? ad.authorId!.trim()
            : 'usr_author_01');
    final resolvedAuthorName = (ad.authorName.trim().length >= 2)
        ? ad.authorName.trim()
        : ((user?.displayName != null && user!.displayName!.trim().length >= 2)
            ? user.displayName!.trim()
            : 'عضو مشوار');

    final resolvedAd = ad.copyWith(
      authorId: resolvedAuthorId,
      authorName: resolvedAuthorName,
    );

    final payload = <String, dynamic>{
      ...resolvedAd.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection(FirestoreCollections.boardAds)
          .doc(resolvedAd.id)
          .set(payload);
    } catch (_) {
      // Keep optimistic local board state when offline or unauthenticated.
    }
    return resolvedAd;
  }

  @override
  Future<bool> makeOffer({
    required String adId,
    required int offerPrice,
    required String timeText,
    required String driverName,
  }) async {
    final user = _currentUser;
    final resolvedDriverId =
        (user != null && user.uid.isNotEmpty) ? user.uid : 'usr_driver_01';
    final resolvedDriverName = driverName.trim().length >= 2
        ? driverName.trim()
        : ((user?.displayName != null && user!.displayName!.trim().length >= 2)
            ? user.displayName!.trim()
            : 'مسافر مشوار');

    try {
      final offerRef = _firestore
          .collection(FirestoreCollections.boardAds)
          .doc(adId)
          .collection(FirestoreCollections.boardOffers)
          .doc();

      final offerData = <String, dynamic>{
        'id': offerRef.id,
        'adId': adId,
        'driverId': resolvedDriverId,
        'driverName': resolvedDriverName,
        'offerPrice': offerPrice.clamp(1, 50000),
        'timeText': timeText.trim().isNotEmpty ? timeText.trim() : 'Flexible',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await offerRef.set(offerData);
    } catch (_) {
      return false;
    }

    // Author/admin may also reflect offer summary on parent board_ads doc.
    try {
      await _firestore
          .collection(FirestoreCollections.boardAds)
          .doc(adId)
          .update({
        'status': BoardAdStatus.offerSent.name,
        'myOfferPrice': offerPrice.clamp(1, 50000),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return true;
  }

  @override
  Future<bool> withdrawOffer(String adId) async {
    final user = _currentUser;
    try {
      if (user != null && user.uid.isNotEmpty) {
        final myOffers = await _firestore
            .collection(FirestoreCollections.boardAds)
            .doc(adId)
            .collection(FirestoreCollections.boardOffers)
            .where('driverId', isEqualTo: user.uid)
            .get();
        for (final doc in myOffers.docs) {
          await doc.reference.update({
            'status': 'withdrawn',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (_) {}

    try {
      await _firestore
          .collection(FirestoreCollections.boardAds)
          .doc(adId)
          .update({
        'status': BoardAdStatus.active.name,
        'myOfferPrice': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMyAdStatus(
    String adId,
    BoardAdStatus status, {
    int? acceptedPrice,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.boardAds)
          .doc(adId)
          .update({
        'status': status.name,
        if (acceptedPrice != null && acceptedPrice >= 0)
          'myOfferPrice': acceptedPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<BoardAdModel>> getMyAds() async {
    try {
      final user = _currentUser;
      Query<Map<String, dynamic>> query =
          _firestore.collection(FirestoreCollections.boardAds);
      if (user != null && user.uid.isNotEmpty) {
        query = query.where('authorId', isEqualTo: user.uid);
      }
      final snapshot = await query.limit(20).get();
      return snapshot.docs
          .map((doc) => BoardAdModel.fromJson(doc.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<BoardAdModel>> getMySentOffers() async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.boardAds)
          .where('status', isEqualTo: BoardAdStatus.offerSent.name)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => BoardAdModel.fromJson(doc.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> deleteAd(String adId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.boardAds)
          .doc(adId)
          .delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
