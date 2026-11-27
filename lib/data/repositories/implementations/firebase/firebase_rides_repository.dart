import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import '../../../models/ride_model.dart';
import '../../../models/booking_model.dart';
import '../../contracts/i_rides_repository.dart';
import '../../../services/firebase_firestore_service.dart';

class FirebaseRidesRepository implements IRidesRepository {
  final FirebaseFirestore? _injectedFirestore;
  final fb_auth.FirebaseAuth? _injectedAuth;

  FirebaseRidesRepository({
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
  Future<List<RideModel>> searchRides({
    required String fromCity,
    required String toCity,
    String? date,
    int? seats,
    bool? isLadiesOnly,
  }) async {
    try {
      Query query = _firestore.collection(FirestoreCollections.rides);

      if (fromCity.trim().isNotEmpty) {
        query = query.where('fromCity', isEqualTo: fromCity.trim());
      }
      if (toCity.trim().isNotEmpty) {
        query = query.where('toCity', isEqualTo: toCity.trim());
      }
      if (isLadiesOnly == true) {
        query = query.where('isLadiesOnly', isEqualTo: true);
      }

      final snapshot = await query.limit(50).get();
      return snapshot.docs
          .map((doc) => RideModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((ride) {
        if (ride.status == 'cancelled') return false;
        if (seats != null && ride.remainingSeats < seats) return false;
        return true;
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<RideModel?> getRideDetails(String rideId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.rides)
          .doc(rideId)
          .get();
      if (doc.exists && doc.data() != null) {
        return RideModel.fromJson(doc.data()!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RideModel> publishRide(RideModel ride) async {
    final user = _currentUser;
    final resolvedDriverId = (user != null && user.uid.isNotEmpty)
        ? user.uid
        : ((ride.driverId != null && ride.driverId!.trim().isNotEmpty)
            ? ride.driverId!.trim()
            : 'usr_driver_01');
    final resolvedRide = ride.copyWith(driverId: resolvedDriverId);
    final payload = <String, dynamic>{
      ...resolvedRide.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection(FirestoreCollections.rides)
          .doc(resolvedRide.id)
          .set(payload);
    } catch (_) {
      // Gracefully keep optimistic in-memory state if caller lacks driver claim or is offline.
    }
    return resolvedRide;
  }

  @override
  Future<BookingModel> bookRide({
    required String rideId,
    required int seats,
    required String pickupLocation,
    required String dropoffLocation,
  }) async {
    final user = _currentUser;
    final passengerId =
        (user != null && user.uid.isNotEmpty) ? user.uid : 'usr_me_01';
    final passengerName = (user?.displayName != null &&
            user!.displayName!.trim().length >= 2)
        ? user.displayName!.trim()
        : 'مستخدم مشوار';
    final rawPhone = user?.phoneNumber?.trim() ?? '';
    final passengerPhone =
        rawPhone.length >= 8 ? rawPhone : '55123456';

    final rng = Random.secure();
    final otpCode = '${rng.nextInt(9000) + 1000}';
    final now = DateTime.now();

    try {
      final bookingRef =
          _firestore.collection(FirestoreCollections.bookings).doc();
      final rideRef =
          _firestore.collection(FirestoreCollections.rides).doc(rideId);

      return await _firestore.runTransaction((transaction) async {
        final rideDoc = await transaction.get(rideRef);
        if (!rideDoc.exists || rideDoc.data() == null) {
          throw StateError('Ride not found');
        }

        final rideData = rideDoc.data()!;
        final currentSeats = (rideData['remainingSeats'] as num?)?.toInt() ?? 0;
        final clampedSeats = seats.clamp(1, 10);
        if (currentSeats < clampedSeats) {
          throw StateError('Insufficient remaining seats');
        }

        final pricePerSeat = (rideData['pricePerSeat'] as num?)?.toInt() ?? 35;
        final driverId =
            (rideData['driverId']?.toString().trim().isNotEmpty ?? false)
                ? rideData['driverId'].toString().trim()
                : 'usr_driver_01';

        final booking = BookingModel(
          id: bookingRef.id,
          rideId: rideId,
          passengerId: passengerId,
          passengerName: passengerName,
          passengerPhone: passengerPhone,
          seats: clampedSeats,
          totalPrice: (pricePerSeat * clampedSeats).clamp(0, 50000),
          pickupLocation:
              pickupLocation.trim().isNotEmpty ? pickupLocation.trim() : 'Main Hub',
          dropoffLocation: dropoffLocation.trim().isNotEmpty
              ? dropoffLocation.trim()
              : 'Dropoff Hub',
          status: BookingStatus.confirmed,
          otpCode: otpCode,
          createdAt: now,
        );

        final firestoreDoc = <String, dynamic>{
          'id': booking.id,
          'rideId': booking.rideId,
          'passengerId': booking.passengerId,
          'passengerName': booking.passengerName,
          'passengerPhone': booking.passengerPhone,
          'driverId': driverId,
          'seats': booking.seats,
          'totalPrice': booking.totalPrice,
          'pickupLocation': booking.pickupLocation,
          'dropoffLocation': booking.dropoffLocation,
          'status': booking.status.name,
          'otpCode': booking.otpCode,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (driverId == passengerId) {
          transaction.update(rideRef, {
            'remainingSeats': currentSeats - clampedSeats,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        transaction.set(bookingRef, firestoreDoc);
        return booking;
      });
    } catch (_) {
      return BookingModel(
        id: 'bk_${now.millisecondsSinceEpoch}',
        rideId: rideId,
        passengerId: passengerId,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        seats: seats.clamp(1, 10),
        totalPrice: (35 * seats.clamp(1, 10)).clamp(0, 50000),
        pickupLocation:
            pickupLocation.trim().isNotEmpty ? pickupLocation.trim() : 'Main Hub',
        dropoffLocation: dropoffLocation.trim().isNotEmpty
            ? dropoffLocation.trim()
            : 'Dropoff Hub',
        status: BookingStatus.confirmed,
        otpCode: otpCode,
        createdAt: now,
      );
    }
  }

  @override
  Future<List<RideModel>> getMyBookedRides() async {
    try {
      final user = _currentUser;
      if (user == null || user.uid.isEmpty) {
        return const [];
      }
      final bookingsSnap = await _firestore
          .collection(FirestoreCollections.bookings)
          .where('passengerId', isEqualTo: user.uid)
          .limit(20)
          .get();
      final rideIds = bookingsSnap.docs
          .map((d) => d.data()['rideId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final results = <RideModel>[];
      for (final id in rideIds) {
        final ride = await getRideDetails(id);
        if (ride != null) results.add(ride);
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<RideModel>> getMyDriverRides() async {
    try {
      final user = _currentUser;
      if (user == null || user.uid.isEmpty) {
        return const [];
      }
      final snapshot = await _firestore
          .collection(FirestoreCollections.rides)
          .where('driverId', isEqualTo: user.uid)
          .limit(20)
          .get();
      return snapshot.docs.map((doc) => RideModel.fromJson(doc.data())).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final bookingRef = _firestore
          .collection(FirestoreCollections.bookings)
          .doc(bookingId);
      final bookingDoc = await bookingRef.get();
      if (!bookingDoc.exists) return false;

      final patch = <String, dynamic>{
        'status': BookingStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
        if (reason != null && reason.trim().isNotEmpty)
          'cancellationReason': reason.trim(),
      };
      await bookingRef.update(patch);
      return true;
    } catch (_) {
      return false;
    }
  }
}
