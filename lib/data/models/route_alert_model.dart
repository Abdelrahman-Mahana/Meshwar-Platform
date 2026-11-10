class RouteAlertModel {
  final String id;
  final String fromCity;
  final String toCity;
  final String dateRange;
  final String category; // 'ركاب' or 'طرد'
  final bool isActive;
  final bool isExpired;

  const RouteAlertModel({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.dateRange,
    required this.category,
    this.isActive = true,
    this.isExpired = false,
  });

  RouteAlertModel copyWith({
    String? id,
    String? fromCity,
    String? toCity,
    String? dateRange,
    String? category,
    bool? isActive,
    bool? isExpired,
  }) {
    return RouteAlertModel(
      id: id ?? this.id,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      dateRange: dateRange ?? this.dateRange,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

