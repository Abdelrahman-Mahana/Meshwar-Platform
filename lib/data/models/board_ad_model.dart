enum BoardAdType {
  all,
  rideOffer,     // عرض سفر / مقاعد متاحة في سيارة
  rideRequest,   // طلب سفر تشاركي
  localTrip,     // انتقال ومشاوير محلية ومركبات فورية
  errandService, // قضاء مصلحة / إحضار أوراق ومستندات
  goodsDelivery, // توصيل ونقل بضائع ومستلزمات محلات
  parcelRequest, // شحن طرد أو أمانة
}

enum BoardAdStatus {
  active,
  offerSent,
  completed,
  expired,
}

class BoardAdModel {
  final String id;
  final BoardAdType type;
  final String authorName;
  final bool isVerified;
  final int tripCount;
  final String postedAgo;
  final String fromCity;
  final String toCity;
  final String timeText;
  final String description;
  final int priceOrBudget;
  final String? notes;
  final bool isLadiesOnly;
  final BoardAdStatus status;
  final int? myOfferPrice;
  final String? serviceSubTagAr;
  final String? serviceSubTagEn;
  final bool hasEscrowProtection;
  final bool requiresReceiptProof;
  final int? estimatedItemCost;
  final bool isProviderOffer;

  const BoardAdModel({
    required this.id,
    required this.type,
    required this.authorName,
    this.isVerified = true,
    this.tripCount = 6,
    required this.postedAgo,
    required this.fromCity,
    required this.toCity,
    required this.timeText,
    required this.description,
    required this.priceOrBudget,
    this.notes,
    this.isLadiesOnly = false,
    this.status = BoardAdStatus.active,
    this.myOfferPrice,
    this.serviceSubTagAr,
    this.serviceSubTagEn,
    this.hasEscrowProtection = true,
    this.requiresReceiptProof = false,
    this.estimatedItemCost,
    this.isProviderOffer = false,
  });

  String get timeAgo => postedAgo;
  double get authorRating => 4.9;
  String get route => '$fromCity ← $toCity';
  int get suggestedPrice => priceOrBudget;
  bool get isOfferCard => isProviderOffer || type == BoardAdType.rideOffer;

  String displaySubTag(bool isAr) {
    final tag = isAr ? serviceSubTagAr : serviceSubTagEn;
    if (tag != null && tag.trim().isNotEmpty) return tag;
    return typeTitle(isAr);
  }

  String typeTitle(bool isAr) {
    switch (type) {
      case BoardAdType.rideOffer:
        return isAr ? 'مقاعد وسفر تشاركي' : 'Shared Seats';
      case BoardAdType.rideRequest:
        return isAr ? 'طلب سفر ومقعد' : 'Need a Seat';
      case BoardAdType.localTrip:
        return isAr ? 'مشاوير يومية وحضانات' : 'Daily & Nursery Rides';
      case BoardAdType.errandService:
        return isAr ? 'جلب أوراق ومصالح' : 'Errands & Documents';
      case BoardAdType.goodsDelivery:
        return isAr ? 'توريد مواقع وبضائع' : 'Worksite & Cargo';
      case BoardAdType.parcelRequest:
        return isAr ? 'شراء وتوصيل أمانات' : 'Shop & Parcel';
      case BoardAdType.all:
        return isAr ? 'كافة الخدمات والمشاوير' : 'All Services';
    }
  }

  String priceTagLabel(bool isAr) {
    switch (type) {
      case BoardAdType.rideOffer:
        return isAr ? 'للمقعد' : 'Per Seat';
      case BoardAdType.rideRequest:
        return isAr ? 'الميزانية' : 'Budget';
      case BoardAdType.localTrip:
        return isAr ? 'أتعاب المشوار' : 'Trip Fare';
      case BoardAdType.errandService:
        return isAr ? 'أتعاب الخدمة' : 'Service Fee';
      case BoardAdType.goodsDelivery:
        return isAr ? 'أتعاب التوريد' : 'Supply Fee';
      case BoardAdType.parcelRequest:
        return isAr ? 'رسوم التوصيل' : 'Delivery Fee';
      case BoardAdType.all:
        return isAr ? 'السعر' : 'Price';
    }
  }

  BoardAdModel copyWith({
    String? id,
    BoardAdType? type,
    String? authorName,
    bool? isVerified,
    int? tripCount,
    String? postedAgo,
    String? fromCity,
    String? toCity,
    String? timeText,
    String? description,
    int? priceOrBudget,
    String? notes,
    bool? isLadiesOnly,
    BoardAdStatus? status,
    int? myOfferPrice,
    String? serviceSubTagAr,
    String? serviceSubTagEn,
    bool? hasEscrowProtection,
    bool? requiresReceiptProof,
    int? estimatedItemCost,
    bool? isProviderOffer,
  }) {
    return BoardAdModel(
      id: id ?? this.id,
      type: type ?? this.type,
      authorName: authorName ?? this.authorName,
      isVerified: isVerified ?? this.isVerified,
      tripCount: tripCount ?? this.tripCount,
      postedAgo: postedAgo ?? this.postedAgo,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      timeText: timeText ?? this.timeText,
      description: description ?? this.description,
      priceOrBudget: priceOrBudget ?? this.priceOrBudget,
      notes: notes ?? this.notes,
      isLadiesOnly: isLadiesOnly ?? this.isLadiesOnly,
      status: status ?? this.status,
      myOfferPrice: myOfferPrice ?? this.myOfferPrice,
      serviceSubTagAr: serviceSubTagAr ?? this.serviceSubTagAr,
      serviceSubTagEn: serviceSubTagEn ?? this.serviceSubTagEn,
      hasEscrowProtection: hasEscrowProtection ?? this.hasEscrowProtection,
      requiresReceiptProof: requiresReceiptProof ?? this.requiresReceiptProof,
      estimatedItemCost: estimatedItemCost ?? this.estimatedItemCost,
      isProviderOffer: isProviderOffer ?? this.isProviderOffer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'authorName': authorName,
      'isVerified': isVerified,
      'tripCount': tripCount,
      'postedAgo': postedAgo,
      'fromCity': fromCity,
      'toCity': toCity,
      'timeText': timeText,
      'description': description,
      'priceOrBudget': priceOrBudget,
      'notes': notes,
      'isLadiesOnly': isLadiesOnly,
      'status': status.name,
      'myOfferPrice': myOfferPrice,
      'serviceSubTagAr': serviceSubTagAr,
      'serviceSubTagEn': serviceSubTagEn,
      'hasEscrowProtection': hasEscrowProtection,
      'requiresReceiptProof': requiresReceiptProof,
      'estimatedItemCost': estimatedItemCost,
      'isProviderOffer': isProviderOffer,
    };
  }

  factory BoardAdModel.fromJson(Map<String, dynamic> json) {
    return BoardAdModel(
      id: (json['id'] ?? '').toString(),
      type: BoardAdType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BoardAdType.rideRequest,
      ),
      authorName: (json['authorName'] ?? '').toString(),
      isVerified: json['isVerified'] as bool? ?? true,
      tripCount: (json['tripCount'] as num?)?.toInt() ?? 1,
      postedAgo: (json['postedAgo'] ?? 'الآن').toString(),
      fromCity: (json['fromCity'] ?? '').toString(),
      toCity: (json['toCity'] ?? '').toString(),
      timeText: (json['timeText'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priceOrBudget: (json['priceOrBudget'] as num?)?.toInt() ?? 50,
      notes: json['notes'] as String?,
      isLadiesOnly: json['isLadiesOnly'] as bool? ?? false,
      status: BoardAdStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BoardAdStatus.active,
      ),
      myOfferPrice: (json['myOfferPrice'] as num?)?.toInt(),
      serviceSubTagAr: json['serviceSubTagAr'] as String?,
      serviceSubTagEn: json['serviceSubTagEn'] as String?,
      hasEscrowProtection: json['hasEscrowProtection'] as bool? ?? true,
      requiresReceiptProof: json['requiresReceiptProof'] as bool? ?? false,
      estimatedItemCost: (json['estimatedItemCost'] as num?)?.toInt(),
      isProviderOffer: json['isProviderOffer'] as bool? ?? false,
    );
  }
}


