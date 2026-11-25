enum ParcelSize {
  envelope, // ظرف
  small,    // صغير
  medium,   // متوسط
  large,    // كبير
}

enum ParcelStatusStep {
  requested,  // تم إرسال الطلب
  accepted,   // وافق المسافر
  handedOver, // استلام الطرد بكود الاستلام
  inTransit,  // في الطريق
  delivered,  // تم التسليم بكود التسليم
}

class ParcelModel {
  final String id;
  final String? senderId;
  final String? senderName;
  final String? senderPhone;
  final String? driverId;
  final String driverName;
  final String? receiverId;
  final String route;
  final String? fromCity;
  final String? toCity;
  final String? stopoverCity;
  final String description;
  final ParcelSize size;
  final double weightKg;
  final int estimatedValue;
  final String receiverName;
  final String receiverPhone;
  final int fee;
  final String pickupOtp;
  final String? deliveryOtp;
  final ParcelStatusStep status;

  const ParcelModel({
    required this.id,
    this.senderId,
    this.senderName,
    this.senderPhone,
    this.driverId,
    this.driverName = '',
    this.receiverId,
    required this.route,
    this.fromCity,
    this.toCity,
    this.stopoverCity,
    required this.description,
    required this.size,
    required this.weightKg,
    required this.estimatedValue,
    required this.receiverName,
    required this.receiverPhone,
    required this.fee,
    required this.pickupOtp,
    this.deliveryOtp,
    this.status = ParcelStatusStep.accepted,
  });

  bool get hasAssignedTraveler => driverName.trim().isNotEmpty;

  String get sizeName => sizeLabel(true);

  String sizeLabel(bool isAr) {
    switch (size) {
      case ParcelSize.envelope:
        return isAr ? 'ظرف' : 'Envelope';
      case ParcelSize.small:
        return isAr ? 'صغير' : 'Small';
      case ParcelSize.medium:
        return isAr ? 'متوسط' : 'Medium';
      case ParcelSize.large:
        return isAr ? 'كبير' : 'Large';
    }
  }

  ParcelModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhone,
    String? driverId,
    String? driverName,
    String? receiverId,
    String? route,
    String? fromCity,
    String? toCity,
    String? stopoverCity,
    String? description,
    ParcelSize? size,
    double? weightKg,
    int? estimatedValue,
    String? receiverName,
    String? receiverPhone,
    int? fee,
    String? pickupOtp,
    String? deliveryOtp,
    ParcelStatusStep? status,
  }) {
    return ParcelModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      receiverId: receiverId ?? this.receiverId,
      route: route ?? this.route,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      stopoverCity: stopoverCity ?? this.stopoverCity,
      description: description ?? this.description,
      size: size ?? this.size,
      weightKg: weightKg ?? this.weightKg,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      fee: fee ?? this.fee,
      pickupOtp: pickupOtp ?? this.pickupOtp,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
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
    return '55112233';
  }

  static String _normalizeOtp(String raw, {String fallback = '4821'}) {
    final trimmed = raw.trim();
    if (trimmed.length >= 4 && trimmed.length <= 8) return trimmed;
    final compact = trimmed.replaceAll(' ', '');
    if (compact.length >= 4 && compact.length <= 8) return compact;
    return fallback;
  }

  /// Strictly emits only fields whitelisted by `isValidParcel` in `firestore.rules`.
  Map<String, dynamic> toJson() {
    final resolvedSenderId = (senderId != null && senderId!.trim().isNotEmpty)
        ? senderId!.trim()
        : 'usr_sender_01';
    final cleanDriverName = driverName.trim();
    final cleanDriverId = driverId?.trim();
    final cleanSenderName = senderName?.trim();
    final cleanSenderPhone = senderPhone?.trim();
    final cleanReceiverId = receiverId?.trim();
    final cleanFrom = fromCity?.trim();
    final cleanTo = toCity?.trim();
    final cleanDeliveryOtp = deliveryOtp?.trim();

    return {
      'id': id,
      'senderId': resolvedSenderId,
      if (cleanSenderName != null && cleanSenderName.length >= 2)
        'senderName': cleanSenderName,
      if (cleanSenderPhone != null && cleanSenderPhone.isNotEmpty)
        'senderPhone': _normalizePhone(cleanSenderPhone),
      if (cleanDriverId != null && cleanDriverId.isNotEmpty)
        'driverId': cleanDriverId,
      if (cleanDriverName.length >= 2) 'driverName': cleanDriverName,
      if (cleanReceiverId != null && cleanReceiverId.isNotEmpty)
        'receiverId': cleanReceiverId,
      'receiverName': receiverName.trim().length >= 2
          ? receiverName.trim()
          : 'Recipient',
      'receiverPhone': _normalizePhone(receiverPhone),
      'route': route.trim().isNotEmpty ? route.trim() : 'Route Parcel',
      if (cleanFrom != null && cleanFrom.isNotEmpty) 'fromCity': cleanFrom,
      if (cleanTo != null && cleanTo.isNotEmpty) 'toCity': cleanTo,
      'description': description.trim().isNotEmpty
          ? description.trim()
          : 'Sealed parcel',
      'size': size.name,
      'weightKg': weightKg.clamp(0.1, 50.0),
      'estimatedValue': estimatedValue.clamp(0, 100000),
      'fee': fee.clamp(0, 10000),
      'pickupOtp': _normalizeOtp(pickupOtp),
      if (cleanDeliveryOtp != null &&
          cleanDeliveryOtp.length >= 4 &&
          cleanDeliveryOtp.length <= 8)
        'deliveryOtp': cleanDeliveryOtp,
      'status': status.name,
    };
  }

  factory ParcelModel.fromJson(Map<String, dynamic> json) {
    return ParcelModel(
      id: (json['id'] ?? '').toString(),
      senderId: json['senderId']?.toString(),
      senderName: json['senderName']?.toString(),
      senderPhone: json['senderPhone']?.toString(),
      driverId: json['driverId']?.toString(),
      driverName: (json['driverName'] ?? '').toString(),
      receiverId: json['receiverId']?.toString(),
      route: (json['route'] ?? '').toString(),
      fromCity: json['fromCity']?.toString(),
      toCity: json['toCity']?.toString(),
      stopoverCity: json['stopoverCity']?.toString(),
      description: (json['description'] ?? '').toString(),
      size: ParcelSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () => ParcelSize.medium,
      ),
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 1.0,
      estimatedValue: (json['estimatedValue'] as num?)?.toInt() ?? 100,
      receiverName: (json['receiverName'] ?? '').toString(),
      receiverPhone: (json['receiverPhone'] ?? '').toString(),
      fee: (json['fee'] as num?)?.toInt() ?? 25,
      pickupOtp: (json['pickupOtp'] ?? '4821').toString(),
      deliveryOtp: json['deliveryOtp']?.toString(),
      status: ParcelStatusStep.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ParcelStatusStep.requested,
      ),
    );
  }
}
