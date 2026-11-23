import '../../models/ride_model.dart';
import '../../models/booking_model.dart';
import '../../mock_data.dart';
import '../contracts/i_rides_repository.dart';

class RidesRepositoryImpl implements IRidesRepository {
  final List<RideModel> _rides = List.from(MockData.initialRides);
  final List<RideModel> _bookedRides = [];

  @override
  Future<List<RideModel>> searchRides({
    required String fromCity,
    required String toCity,
    String? date,
    int? seats,
    bool? isLadiesOnly,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rides.where((r) {
      final matchFrom = fromCity.isEmpty || r.fromCity.contains(fromCity);
      final matchTo = toCity.isEmpty || r.toCity.contains(toCity);
      final matchSeats = seats == null || r.remainingSeats >= seats;
      final matchLadies = isLadiesOnly == null || !isLadiesOnly || r.isLadiesOnly;
      return matchFrom && matchTo && matchSeats && matchLadies;
    }).toList();
  }

  @override
  Future<RideModel?> getRideDetails(String rideId) async {
    try {
      return _rides.firstWhere((r) => r.id == rideId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RideModel> publishRide(RideModel ride) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _rides.insert(0, ride);
    return ride;
  }

  @override
  Future<BookingModel> bookRide({
    required String rideId,
    required int seats,
    required String pickupLocation,
    required String dropoffLocation,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final rideIndex = _rides.indexWhere((r) => r.id == rideId);
    if (rideIndex != -1) {
      final currentRide = _rides[rideIndex];
      final newRemaining = (currentRide.remainingSeats - seats).clamp(0, 10);
      _rides[rideIndex] = currentRide.copyWith(remainingSeats: newRemaining);
      _bookedRides.add(currentRide);

      return BookingModel(
        id: 'bk_${DateTime.now().millisecondsSinceEpoch}',
        rideId: rideId,
        passengerId: 'usr_me_01',
        passengerName: 'عبدالرحمن المهنا',
        passengerPhone: '55123456',
        seats: seats,
        totalPrice: currentRide.pricePerSeat * seats,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        otpCode: '5912',
        createdAt: DateTime.now(),
      );
    }
    throw Exception('Ride not found');
  }

  @override
  Future<List<RideModel>> getMyBookedRides() async {
    return _bookedRides;
  }

  @override
  Future<List<RideModel>> getMyDriverRides() async {
    return _rides.where((r) => r.driverName == 'عبدالرحمن المهنا').toList();
  }

  @override
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
