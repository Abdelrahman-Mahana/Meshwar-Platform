class LocationItem {
  final String name;
  final String region;
  final String typeLabel; // 'محافظة' | 'مدينة' | 'قرية'
  final bool isRecent;

  const LocationItem({
    required this.name,
    required this.region,
    required this.typeLabel,
    this.isRecent = false,
  });
}

