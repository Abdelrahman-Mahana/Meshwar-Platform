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
}

