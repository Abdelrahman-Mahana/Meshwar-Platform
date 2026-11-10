class RideModel {
  final String id;
  final String driverName;
  final String driverCar;
  final String driverPhone;
  final String fromCity;
  final String toCity;
  final String pickupPoint;
  final String dropoffPoint;
  final String departureTime;
  final String departureDate;
  final int remainingSeats;
  final int pricePerSeat;
  final bool acceptsParcels;
  final int parcelPrice;
  final bool isVerified;
  final bool isLadiesOnly;
  final bool isInstantBooking;
  final double driverRating;

  const RideModel({
    required this.id,
    required this.driverName,
    required this.driverCar,
    required this.driverPhone,
    required this.fromCity,
    required this.toCity,
    required this.pickupPoint,
    required this.dropoffPoint,
    required this.departureTime,
    required this.departureDate,
    required this.remainingSeats,
    required this.pricePerSeat,
    this.acceptsParcels = true,
    this.parcelPrice = 40,
    this.isVerified = true,
    this.isLadiesOnly = false,
    this.isInstantBooking = false,
    this.driverRating = 4.9,
  });
}

