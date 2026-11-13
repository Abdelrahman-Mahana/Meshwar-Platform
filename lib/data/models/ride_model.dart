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

  RideModel copyWith({
    String? id,
    String? driverName,
    String? driverCar,
    String? driverPhone,
    String? fromCity,
    String? toCity,
    String? pickupPoint,
    String? dropoffPoint,
    String? departureTime,
    String? departureDate,
    int? remainingSeats,
    int? pricePerSeat,
    bool? acceptsParcels,
    int? parcelPrice,
    bool? isVerified,
    bool? isLadiesOnly,
    bool? isInstantBooking,
    double? driverRating,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverName: driverName ?? this.driverName,
      driverCar: driverCar ?? this.driverCar,
      driverPhone: driverPhone ?? this.driverPhone,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      dropoffPoint: dropoffPoint ?? this.dropoffPoint,
      departureTime: departureTime ?? this.departureTime,
      departureDate: departureDate ?? this.departureDate,
      remainingSeats: remainingSeats ?? this.remainingSeats,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      acceptsParcels: acceptsParcels ?? this.acceptsParcels,
      parcelPrice: parcelPrice ?? this.parcelPrice,
      isVerified: isVerified ?? this.isVerified,
      isLadiesOnly: isLadiesOnly ?? this.isLadiesOnly,
      isInstantBooking: isInstantBooking ?? this.isInstantBooking,
      driverRating: driverRating ?? this.driverRating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverName': driverName,
      'driverCar': driverCar,
      'driverPhone': driverPhone,
      'fromCity': fromCity,
      'toCity': toCity,
      'pickupPoint': pickupPoint,
      'dropoffPoint': dropoffPoint,
      'departureTime': departureTime,
      'departureDate': departureDate,
      'remainingSeats': remainingSeats,
      'pricePerSeat': pricePerSeat,
      'acceptsParcels': acceptsParcels,
      'parcelPrice': parcelPrice,
      'isVerified': isVerified,
      'isLadiesOnly': isLadiesOnly,
      'isInstantBooking': isInstantBooking,
      'driverRating': driverRating,
    };
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: (json['id'] ?? '').toString(),
      driverName: (json['driverName'] ?? '').toString(),
      driverCar: (json['driverCar'] ?? '').toString(),
      driverPhone: (json['driverPhone'] ?? '').toString(),
      fromCity: (json['fromCity'] ?? '').toString(),
      toCity: (json['toCity'] ?? '').toString(),
      pickupPoint: (json['pickupPoint'] ?? '').toString(),
      dropoffPoint: (json['dropoffPoint'] ?? '').toString(),
      departureTime: (json['departureTime'] ?? '').toString(),
      departureDate: (json['departureDate'] ?? '').toString(),
      remainingSeats: (json['remainingSeats'] as num?)?.toInt() ?? 1,
      pricePerSeat: (json['pricePerSeat'] as num?)?.toInt() ?? 50,
      acceptsParcels: json['acceptsParcels'] as bool? ?? true,
      parcelPrice: (json['parcelPrice'] as num?)?.toInt() ?? 40,
      isVerified: json['isVerified'] as bool? ?? true,
      isLadiesOnly: json['isLadiesOnly'] as bool? ?? false,
      isInstantBooking: json['isInstantBooking'] as bool? ?? false,
      driverRating: (json['driverRating'] as num?)?.toDouble() ?? 4.9,
    );
  }
}


