class RouteDetails {
  final double distanceKm;
  final int durationMinutes;
  final String polyline;
  final String startAddress;
  final String endAddress;
  final double? originLat;
  final double? originLng;
  final double? destLat;
  final double? destLng;
  final String? corridorHighwayAr;
  final String? corridorHighwayEn;
  final String? googleMapsDirectionsUrl;
  final List<({double lat, double lng})> polylinePoints;

  const RouteDetails({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polyline,
    required this.startAddress,
    required this.endAddress,
    this.originLat,
    this.originLng,
    this.destLat,
    this.destLng,
    this.corridorHighwayAr,
    this.corridorHighwayEn,
    this.googleMapsDirectionsUrl,
    this.polylinePoints = const [],
  });

  String corridorHighway({required bool isArabic}) {
    if (isArabic) {
      return corridorHighwayAr ?? corridorHighwayEn ?? '';
    }
    return corridorHighwayEn ?? corridorHighwayAr ?? '';
  }
}

class LocationSearchResult {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;
  final String? googleMapsPlaceUrl;

  const LocationSearchResult({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
    this.googleMapsPlaceUrl,
  });
}

abstract class IMapsRepository {
  Future<List<LocationSearchResult>> searchLocations(String query);
  Future<RouteDetails> getRouteDetails(String origin, String destination);
  Future<String> reverseGeocode(double latitude, double longitude);
}
