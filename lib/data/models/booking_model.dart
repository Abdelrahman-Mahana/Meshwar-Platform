enum BookingStatus {
  pending,
  confirmed,
  active,
  completed,
  cancelled,
}

class BookingModel {
  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final int seats;
  final int totalPrice;
  final String pickupLocation;
  final String dropoffLocation;
  final BookingStatus status;
  final String otpCode;
  final DateTime createdAt;
  final String? cancellationReason;

  const BookingModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    required this.seats,
    required this.totalPrice,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.status = BookingStatus.confirmed,
    required this.otpCode,
    required this.createdAt,
    this.cancellationReason,
  });

  BookingModel copyWith({
    String? id,
    String? rideId,
    String? passengerId,
    String? passengerName,
    String? passengerPhone,
    int? seats,
    int? totalPrice,
    String? pickupLocation,
    String? dropoffLocation,
    BookingStatus? status,
    String? otpCode,
    DateTime? createdAt,
    String? cancellationReason,
  }) {
    return BookingModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      seats: seats ?? this.seats,
      totalPrice: totalPrice ?? this.totalPrice,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      status: status ?? this.status,
      otpCode: otpCode ?? this.otpCode,
      createdAt: createdAt ?? this.createdAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'seats': seats,
      'totalPrice': totalPrice,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'status': status.name,
      'otpCode': otpCode,
      'createdAt': createdAt.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] ?? '').toString(),
      rideId: (json['rideId'] ?? '').toString(),
      passengerId: (json['passengerId'] ?? '').toString(),
      passengerName: (json['passengerName'] ?? '').toString(),
      passengerPhone: (json['passengerPhone'] ?? '').toString(),
      seats: (json['seats'] as num?)?.toInt() ?? 1,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      pickupLocation: (json['pickupLocation'] ?? '').toString(),
      dropoffLocation: (json['dropoffLocation'] ?? '').toString(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      otpCode: (json['otpCode'] ?? '0000').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      cancellationReason: json['cancellationReason'] as String?,
    );
  }
}
