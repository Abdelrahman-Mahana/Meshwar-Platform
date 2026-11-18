enum BoardAdType {
  all,
  rideOffer,     // عرض سفر / كراسي فاضية بعربية
  rideRequest,   // طلب سفر تشاركي
  localTrip,     // انتقال ومشاوير محلية ومركبات فورية
  errandService, // قضاء مصلحة / إحضار أوراق ومستندات
  goodsDelivery, // توصيل ونقل بضائع ومستلزمات محلات
  parcelRequest, // شحن طرد أو شنطة
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
  });

  String get timeAgo => postedAgo;
  double get authorRating => 4.9;
  String get route => '$fromCity ← $toCity';
  int get suggestedPrice => priceOrBudget;

  String typeTitle(bool isAr) {
    switch (type) {
      case BoardAdType.rideOffer:
        return isAr ? 'سفر بين المحافظات' : 'Inter-city Travel';
      case BoardAdType.rideRequest:
        return isAr ? 'طلب سفر بين المحافظات' : 'Travel Request';
      case BoardAdType.localTrip:
        return isAr ? 'انتقال ومشاوير محلية' : 'Local Mobility';
      case BoardAdType.errandService:
        return isAr ? 'قضاء مصالح وخدمات رسمية' : 'Official Errand Service';
      case BoardAdType.goodsDelivery:
        return isAr ? 'لوجستيات وتوريد بضائع' : 'Commercial Logistics';
      case BoardAdType.parcelRequest:
        return isAr ? 'شحن وتوصيل أمانات' : 'Express Delivery';
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
        return isAr ? 'أجرة الانتقال' : 'Fare';
      case BoardAdType.errandService:
        return isAr ? 'أتعاب الخدمة' : 'Service Fee';
      case BoardAdType.goodsDelivery:
        return isAr ? 'أجرة التوريد' : 'Freight';
      case BoardAdType.parcelRequest:
        return isAr ? 'أجرة الشحن' : 'Delivery Fee';
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
    );
  }
}


