class RouteDetails {
  final double distanceKm;
  final int durationMinutes;
  final String polyline;
  final String startAddress;
  final String endAddress;

  const RouteDetails({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polyline,
    required this.startAddress,
    required this.endAddress,
  });
}

class LocationSearchResult {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;

  const LocationSearchResult({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
  });
}

abstract class IMapsRepository {
  Future<List<LocationSearchResult>> searchLocations(String query);
  Future<RouteDetails> getRouteDetails(String origin, String destination);
  Future<String> reverseGeocode(double latitude, double longitude);
}
