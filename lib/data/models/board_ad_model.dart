enum BoardAdType {
  all,
  rideOffer,     // رحلات
  rideRequest,   // طلب مشوار
  parcelRequest, // طلب طرد
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
  double get authorRating => 4.8;
  String get route => '$fromCity ← $toCity';
  int get suggestedPrice => priceOrBudget;

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


