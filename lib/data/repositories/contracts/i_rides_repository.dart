import '../../models/ride_model.dart';
import '../../models/booking_model.dart';

abstract class IRidesRepository {
  Future<List<RideModel>> searchRides({
    required String fromCity,
    required String toCity,
    String? date,
    int? seats,
    bool? isLadiesOnly,
  });

  Future<RideModel?> getRideDetails(String rideId);
  Future<RideModel> publishRide(RideModel ride);
  Future<BookingModel> bookRide({
    required String rideId,
    required int seats,
    required String pickupLocation,
    required String dropoffLocation,
  });
  Future<List<RideModel>> getMyBookedRides();
  Future<List<RideModel>> getMyDriverRides();
  Future<bool> cancelBooking(String bookingId, {String? reason});
}
