import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/ride_model.dart';
import '../../../models/booking_model.dart';
import '../../contracts/i_rides_repository.dart';
import '../../../services/firebase_firestore_service.dart';

class FirebaseRidesRepository implements IRidesRepository {
  final FirebaseFirestore _firestore;

  FirebaseRidesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<RideModel>> searchRides({
    required String fromCity,
    required String toCity,
    String? date,
    int? seats,
    bool? isLadiesOnly,
  }) async {
    Query query = _firestore.collection(FirestoreCollections.rides);

    if (fromCity.isNotEmpty) {
      query = query.where('fromCity', isEqualTo: fromCity);
    }
    if (toCity.isNotEmpty) {
      query = query.where('toCity', isEqualTo: toCity);
    }
    if (isLadiesOnly == true) {
      query = query.where('isLadiesOnly', isEqualTo: true);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return RideModel.fromJson(doc.data() as Map<String, dynamic>);
    }).where((ride) {
      if (seats != null && ride.remainingSeats < seats) return false;
      return true;
    }).toList();
  }

  @override
  Future<RideModel?> getRideDetails(String rideId) async {
    final doc = await _firestore.collection(FirestoreCollections.rides).doc(rideId).get();
    if (doc.exists && doc.data() != null) {
      return RideModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<RideModel> publishRide(RideModel ride) async {
    await _firestore
        .collection(FirestoreCollections.rides)
        .doc(ride.id)
        .set(ride.toJson());
    return ride;
  }

  @override
  Future<BookingModel> bookRide({
    required String rideId,
    required int seats,
    required String pickupLocation,
    required String dropoffLocation,
  }) async {
    final bookingRef = _firestore.collection(FirestoreCollections.bookings).doc();
    final rideRef = _firestore.collection(FirestoreCollections.rides).doc(rideId);

    // Cryptographically secure 4-digit OTP code
    final rng = Random.secure();
    final otpCode = '${rng.nextInt(9000) + 1000}';

    return await _firestore.runTransaction((transaction) async {
      final rideDoc = await transaction.get(rideRef);
      if (!rideDoc.exists) {
        throw Exception('الرحلة المطلوبة غير موجودة');
      }

      final rideData = rideDoc.data()!;
      final currentSeats = (rideData['remainingSeats'] as num?)?.toInt() ?? 0;
      if (currentSeats < seats) {
        throw Exception('عذراً، المقاعد المتبقية في هذه الرحلة أقل من المطلوب');
      }

      final pricePerSeat = (rideData['pricePerSeat'] as num?)?.toInt() ?? 50;
      final newRemaining = currentSeats - seats;

      // Update seats atomically
      transaction.update(rideRef, {'remainingSeats': newRemaining});

      final booking = BookingModel(
        id: bookingRef.id,
        rideId: rideId,
        passengerId: 'usr_me_01',
        passengerName: 'مستخدم مشوار',
        passengerPhone: '01012345678',
        seats: seats,
        totalPrice: pricePerSeat * seats,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        status: BookingStatus.confirmed,
        otpCode: otpCode,
        createdAt: DateTime.now(),
      );

      transaction.set(bookingRef, booking.toJson());
      return booking;
    });
  }

  @override
  Future<List<RideModel>> getMyBookedRides() async {
    // In production, queries bookings where passengerId == currentUser.uid, then gets rides
    final snapshot = await _firestore
        .collection(FirestoreCollections.rides)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => RideModel.fromJson(doc.data())).toList();
  }

  @override
  Future<List<RideModel>> getMyDriverRides() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.rides)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => RideModel.fromJson(doc.data())).toList();
  }

  @override
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    final bookingRef = _firestore.collection(FirestoreCollections.bookings).doc(bookingId);
    return await _firestore.runTransaction((transaction) async {
      final bookingDoc = await transaction.get(bookingRef);
      if (!bookingDoc.exists) return false;

      final data = bookingDoc.data()!;
      final rideId = data['rideId'] as String;
      final seats = (data['seats'] as num?)?.toInt() ?? 1;

      // Restock seats on the ride
      final rideRef = _firestore.collection(FirestoreCollections.rides).doc(rideId);
      final rideDoc = await transaction.get(rideRef);
      if (rideDoc.exists) {
        final currentSeats = (rideDoc.data()!['remainingSeats'] as num?)?.toInt() ?? 0;
        transaction.update(rideRef, {'remainingSeats': currentSeats + seats});
      }

      transaction.update(bookingRef, {
        'status': BookingStatus.cancelled.name,
        'cancellationReason': reason,
      });

      return true;
    });
  }
}
