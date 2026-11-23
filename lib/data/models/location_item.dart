class LocationItem {
  final String name;
  final String region;
  final String typeLabel; // 'بلدية' | 'مدينة' | 'منطقة'
  final bool isRecent;

  const LocationItem({
    required this.name,
    required this.region,
    required this.typeLabel,
    this.isRecent = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'region': region,
      'typeLabel': typeLabel,
      'isRecent': isRecent,
    };
  }

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      name: (json['name'] ?? '').toString(),
      region: (json['region'] ?? '').toString(),
      typeLabel: (json['typeLabel'] ?? 'مدينة').toString(),
      isRecent: json['isRecent'] as bool? ?? false,
    );
  }
}


