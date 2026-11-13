enum ParcelSize {
  envelope, // ظرف
  small,  // صغير
  medium, // متوسط
  large,  // كبير
}

enum ParcelStatusStep {
  requested,  // تم إرسال الطلب
  accepted,   // وافق السائق
  handedOver, // تسليم الطرد للسائق
  inTransit,  // في الطريق
  delivered,  // تم التسليم
}

class ParcelModel {
  final String id;
  final String driverName;
  final String route;
  final String description;
  final ParcelSize size;
  final double weightKg;
  final int estimatedValue;
  final String receiverName;
  final String receiverPhone;
  final int fee;
  final String pickupOtp;
  final ParcelStatusStep status;

  const ParcelModel({
    required this.id,
    required this.driverName,
    required this.route,
    required this.description,
    required this.size,
    required this.weightKg,
    required this.estimatedValue,
    required this.receiverName,
    required this.receiverPhone,
    required this.fee,
    required this.pickupOtp,
    this.status = ParcelStatusStep.accepted,
  });

  String get sizeName {
    switch (size) {
      case ParcelSize.envelope:
        return 'ظرف';
      case ParcelSize.small:
        return 'صغير';
      case ParcelSize.medium:
        return 'متوسط';
      case ParcelSize.large:
        return 'كبير';
    }
  }

  ParcelModel copyWith({
    String? id,
    String? driverName,
    String? route,
    String? description,
    ParcelSize? size,
    double? weightKg,
    int? estimatedValue,
    String? receiverName,
    String? receiverPhone,
    int? fee,
    String? pickupOtp,
    ParcelStatusStep? status,
  }) {
    return ParcelModel(
      id: id ?? this.id,
      driverName: driverName ?? this.driverName,
      route: route ?? this.route,
      description: description ?? this.description,
      size: size ?? this.size,
      weightKg: weightKg ?? this.weightKg,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      fee: fee ?? this.fee,
      pickupOtp: pickupOtp ?? this.pickupOtp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverName': driverName,
      'route': route,
      'description': description,
      'size': size.name,
      'weightKg': weightKg,
      'estimatedValue': estimatedValue,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'fee': fee,
      'pickupOtp': pickupOtp,
      'status': status.name,
    };
  }

  factory ParcelModel.fromJson(Map<String, dynamic> json) {
    return ParcelModel(
      id: (json['id'] ?? '').toString(),
      driverName: (json['driverName'] ?? '').toString(),
      route: (json['route'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      size: ParcelSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () => ParcelSize.medium,
      ),
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 1.0,
      estimatedValue: (json['estimatedValue'] as num?)?.toInt() ?? 100,
      receiverName: (json['receiverName'] ?? '').toString(),
      receiverPhone: (json['receiverPhone'] ?? '').toString(),
      fee: (json['fee'] as num?)?.toInt() ?? 40,
      pickupOtp: (json['pickupOtp'] ?? '0000').toString(),
      status: ParcelStatusStep.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ParcelStatusStep.requested,
      ),
    );
  }
}


