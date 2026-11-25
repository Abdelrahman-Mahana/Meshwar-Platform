enum BoardAdType {
  all,
  rideOffer,     // عرض مقاعد ورحلة مشتركة
  rideRequest,   // طلب مقعد على مسار
  localTrip,     // مشاوير يومية ومحلية
  errandService, // مهام واستلام مستندات
  goodsDelivery, // توريد مستلزمات ومواقع
  parcelRequest, // شحن طرد أو أمانة على الطريق
}

enum BoardAdStatus {
  active,
  offerSent,
  completed,
  expired,
  cancelled,
}

class BoardAdModel {
  final String id;
  final String? authorId;
  final BoardAdType type;
  final String authorName;
  final bool isVerified;
  final int tripCount;
  final String postedAgo;
  final String fromCity;
  final String toCity;
  final String? stopoverCity;
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
  final String? maxParcelSize;
  final int? seatsNeeded;

  const BoardAdModel({
    required this.id,
    this.authorId,
    required this.type,
    required this.authorName,
    this.isVerified = true,
    this.tripCount = 6,
    required this.postedAgo,
    required this.fromCity,
    required this.toCity,
    this.stopoverCity,
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
    this.maxParcelSize,
    this.seatsNeeded,
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
        return isAr ? 'مقاعد ورحلة مشتركة' : 'Shared Seats';
      case BoardAdType.rideRequest:
        return isAr ? 'طلب مقعد على مسار' : 'Seat Request';
      case BoardAdType.localTrip:
        return isAr ? 'مشاوير يومية ومحلية' : 'Daily Commutes';
      case BoardAdType.errandService:
        return isAr ? 'مهام ومستندات' : 'Errands & Docs';
      case BoardAdType.goodsDelivery:
        return isAr ? 'توريد ذكي ومستلزمات' : 'Smart Supply';
      case BoardAdType.parcelRequest:
        return isAr ? 'طرود على الطريق' : 'Route Parcels';
      case BoardAdType.all:
        return isAr ? 'كافة المسارات والطلبات' : 'All Requests';
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
        return isAr ? 'أتعاب المهمة' : 'Service Fee';
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
    String? authorId,
    BoardAdType? type,
    String? authorName,
    bool? isVerified,
    int? tripCount,
    String? postedAgo,
    String? fromCity,
    String? toCity,
    String? stopoverCity,
    String? timeText,
    String? description,
    int? priceOrBudget,
    String? notes,
    bool? isLadiesOnly,
    BoardAdStatus? status,
    int? myOfferPrice,
    bool clearMyOfferPrice = false,
    String? serviceSubTagAr,
    String? serviceSubTagEn,
    bool? hasEscrowProtection,
    bool? requiresReceiptProof,
    int? estimatedItemCost,
    bool? isProviderOffer,
    String? maxParcelSize,
    int? seatsNeeded,
  }) {
    return BoardAdModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      type: type ?? this.type,
      authorName: authorName ?? this.authorName,
      isVerified: isVerified ?? this.isVerified,
      tripCount: tripCount ?? this.tripCount,
      postedAgo: postedAgo ?? this.postedAgo,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      stopoverCity: stopoverCity ?? this.stopoverCity,
      timeText: timeText ?? this.timeText,
      description: description ?? this.description,
      priceOrBudget: priceOrBudget ?? this.priceOrBudget,
      notes: notes ?? this.notes,
      isLadiesOnly: isLadiesOnly ?? this.isLadiesOnly,
      status: status ?? this.status,
      myOfferPrice:
          clearMyOfferPrice ? null : (myOfferPrice ?? this.myOfferPrice),
      serviceSubTagAr: serviceSubTagAr ?? this.serviceSubTagAr,
      serviceSubTagEn: serviceSubTagEn ?? this.serviceSubTagEn,
      hasEscrowProtection: hasEscrowProtection ?? this.hasEscrowProtection,
      requiresReceiptProof: requiresReceiptProof ?? this.requiresReceiptProof,
      estimatedItemCost: estimatedItemCost ?? this.estimatedItemCost,
      isProviderOffer: isProviderOffer ?? this.isProviderOffer,
      maxParcelSize: maxParcelSize ?? this.maxParcelSize,
      seatsNeeded: seatsNeeded ?? this.seatsNeeded,
    );
  }

  /// Strictly emits only fields whitelisted by `isValidBoardAd` in `firestore.rules`.
  Map<String, dynamic> toJson() {
    final resolvedAuthorId = (authorId != null && authorId!.trim().isNotEmpty)
        ? authorId!.trim()
        : 'usr_author_01';
    final resolvedAuthorName =
        authorName.trim().length >= 2 ? authorName.trim() : 'MASHWAR Member';
    final cleanPostedAgo = postedAgo.trim().isNotEmpty
        ? (postedAgo.trim().length > 100
            ? postedAgo.trim().substring(0, 100)
            : postedAgo.trim())
        : 'Now';
    final cleanNotes = (notes != null && notes!.trim().isNotEmpty)
        ? (notes!.trim().length > 500
            ? notes!.trim().substring(0, 500)
            : notes!.trim())
        : null;
    final cleanDesc = description.trim().isNotEmpty
        ? (description.trim().length > 1000
            ? description.trim().substring(0, 1000)
            : description.trim())
        : '$fromCity -> $toCity';

    return {
      'id': id,
      'authorId': resolvedAuthorId,
      'type': type.name,
      'authorName': resolvedAuthorName,
      'isVerified': isVerified,
      'tripCount': tripCount < 0 ? 0 : tripCount,
      'postedAgo': cleanPostedAgo,
      'fromCity': fromCity.trim().isNotEmpty ? fromCity.trim() : 'Doha',
      'toCity': toCity.trim().isNotEmpty ? toCity.trim() : 'Lusail',
      'timeText': timeText.trim().isNotEmpty ? timeText.trim() : 'Flexible',
      'description': cleanDesc,
      'priceOrBudget': priceOrBudget.clamp(0, 50000),
      if (cleanNotes != null) 'notes': cleanNotes,
      'isLadiesOnly': isLadiesOnly,
      'status': status.name,
      if (myOfferPrice != null && myOfferPrice! >= 0)
        'myOfferPrice': myOfferPrice,
    };
  }

  factory BoardAdModel.fromJson(Map<String, dynamic> json) {
    return BoardAdModel(
      id: (json['id'] ?? '').toString(),
      authorId: json['authorId']?.toString(),
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
      stopoverCity: json['stopoverCity']?.toString(),
      timeText: (json['timeText'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priceOrBudget: (json['priceOrBudget'] as num?)?.toInt() ?? 35,
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
      maxParcelSize: json['maxParcelSize']?.toString(),
      seatsNeeded: (json['seatsNeeded'] as num?)?.toInt(),
    );
  }
}
