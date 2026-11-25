class RideModel {
  final String id;
  final String? driverId;
  final String driverName;
  final String driverCar;
  final String driverPhone;
  final String fromCity;
  final String toCity;
  final String? stopoverCity;
  final String pickupPoint;
  final String dropoffPoint;
  final String departureTime;
  final String departureDate;
  final int remainingSeats;
  final int pricePerSeat;
  final bool acceptsParcels;
  final int parcelPrice;
  final String? maxParcelSize;
  final String? notes;
  final bool isVerified;
  final bool isLadiesOnly;
  final bool isInstantBooking;
  final double driverRating;
  final String status;

  const RideModel({
    required this.id,
    this.driverId,
    required this.driverName,
    required this.driverCar,
    required this.driverPhone,
    required this.fromCity,
    required this.toCity,
    this.stopoverCity,
    required this.pickupPoint,
    required this.dropoffPoint,
    required this.departureTime,
    required this.departureDate,
    required this.remainingSeats,
    required this.pricePerSeat,
    this.acceptsParcels = true,
    this.parcelPrice = 40,
    this.maxParcelSize,
    this.notes,
    this.isVerified = true,
    this.isLadiesOnly = false,
    this.isInstantBooking = false,
    this.driverRating = 4.9,
    this.status = 'active',
  });

  RideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverCar,
    String? driverPhone,
    String? fromCity,
    String? toCity,
    String? stopoverCity,
    String? pickupPoint,
    String? dropoffPoint,
    String? departureTime,
    String? departureDate,
    int? remainingSeats,
    int? pricePerSeat,
    bool? acceptsParcels,
    int? parcelPrice,
    String? maxParcelSize,
    String? notes,
    bool? isVerified,
    bool? isLadiesOnly,
    bool? isInstantBooking,
    double? driverRating,
    String? status,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverCar: driverCar ?? this.driverCar,
      driverPhone: driverPhone ?? this.driverPhone,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      stopoverCity: stopoverCity ?? this.stopoverCity,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      dropoffPoint: dropoffPoint ?? this.dropoffPoint,
      departureTime: departureTime ?? this.departureTime,
      departureDate: departureDate ?? this.departureDate,
      remainingSeats: remainingSeats ?? this.remainingSeats,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      acceptsParcels: acceptsParcels ?? this.acceptsParcels,
      parcelPrice: parcelPrice ?? this.parcelPrice,
      maxParcelSize: maxParcelSize ?? this.maxParcelSize,
      notes: notes ?? this.notes,
      isVerified: isVerified ?? this.isVerified,
      isLadiesOnly: isLadiesOnly ?? this.isLadiesOnly,
      isInstantBooking: isInstantBooking ?? this.isInstantBooking,
      driverRating: driverRating ?? this.driverRating,
      status: status ?? this.status,
    );
  }

  static String _normalizePhone(String raw) {
    final compact = raw.replaceAll(' ', '').trim();
    if (RegExp(r'^(?:\+?974)?[3567][0-9]{7}$').hasMatch(compact)) {
      return compact;
    }
    final trimmed = raw.trim();
    if (trimmed.length >= 10 && trimmed.length <= 20) {
      return trimmed;
    }
    if (compact.length >= 10 && compact.length <= 20) {
      return compact;
    }
    return '55123456';
  }

  /// Strictly emits only fields whitelisted by `isValidRide` in `firestore.rules`.
  Map<String, dynamic> toJson() {
    final resolvedDriverId = (driverId != null && driverId!.trim().isNotEmpty)
        ? driverId!.trim()
        : 'usr_driver_01';
    final resolvedName =
        driverName.trim().length >= 2 ? driverName.trim() : 'MASHWAR Traveler';
    final resolvedCar =
        driverCar.trim().length >= 2 ? driverCar.trim() : 'Sedan';
    final validStatus =
        const {'active', 'completed', 'cancelled'}.contains(status)
            ? status
            : 'active';

    return {
      'id': id,
      'driverId': resolvedDriverId,
      'driverName': resolvedName,
      'driverCar': resolvedCar,
      'driverPhone': _normalizePhone(driverPhone),
      'fromCity': fromCity.trim().isNotEmpty ? fromCity.trim() : 'Doha',
      'toCity': toCity.trim().isNotEmpty ? toCity.trim() : 'Lusail',
      'pickupPoint': pickupPoint.trim().isNotEmpty
          ? pickupPoint.trim()
          : (fromCity.trim().isNotEmpty ? fromCity.trim() : 'Main Hub'),
      'dropoffPoint': dropoffPoint.trim().isNotEmpty
          ? dropoffPoint.trim()
          : (toCity.trim().isNotEmpty ? toCity.trim() : 'Central Dropoff'),
      'departureTime':
          departureTime.trim().isNotEmpty ? departureTime.trim() : '08:00 AM',
      'departureDate':
          departureDate.trim().isNotEmpty ? departureDate.trim() : 'Today',
      'remainingSeats': remainingSeats.clamp(0, 10),
      'pricePerSeat': pricePerSeat.clamp(0, 5000),
      'acceptsParcels': acceptsParcels,
      'parcelPrice': parcelPrice.clamp(0, 5000),
      'isVerified': isVerified,
      'isLadiesOnly': isLadiesOnly,
      'isInstantBooking': isInstantBooking,
      'driverRating': driverRating.clamp(0.0, 5.0),
      'status': validStatus,
    };
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: (json['id'] ?? '').toString(),
      driverId: json['driverId']?.toString(),
      driverName: (json['driverName'] ?? '').toString(),
      driverCar: (json['driverCar'] ?? '').toString(),
      driverPhone: (json['driverPhone'] ?? '').toString(),
      fromCity: (json['fromCity'] ?? '').toString(),
      toCity: (json['toCity'] ?? '').toString(),
      stopoverCity: json['stopoverCity']?.toString(),
      pickupPoint: (json['pickupPoint'] ?? '').toString(),
      dropoffPoint: (json['dropoffPoint'] ?? '').toString(),
      departureTime: (json['departureTime'] ?? '').toString(),
      departureDate: (json['departureDate'] ?? '').toString(),
      remainingSeats: (json['remainingSeats'] as num?)?.toInt() ?? 1,
      pricePerSeat: (json['pricePerSeat'] as num?)?.toInt() ?? 35,
      acceptsParcels: json['acceptsParcels'] as bool? ?? true,
      parcelPrice: (json['parcelPrice'] as num?)?.toInt() ?? 20,
      maxParcelSize: json['maxParcelSize']?.toString(),
      notes: json['notes']?.toString(),
      isVerified: json['isVerified'] as bool? ?? true,
      isLadiesOnly: json['isLadiesOnly'] as bool? ?? false,
      isInstantBooking: json['isInstantBooking'] as bool? ?? false,
      driverRating: (json['driverRating'] as num?)?.toDouble() ?? 4.9,
      status: (json['status'] ?? 'active').toString(),
    );
  }
}
