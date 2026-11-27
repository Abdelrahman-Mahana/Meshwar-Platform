import '../contracts/i_maps_repository.dart';
import '../../services/google_maps_service.dart';

class MapsRepositoryImpl implements IMapsRepository {
  final GoogleMapsService _googleMapsService;

  MapsRepositoryImpl({GoogleMapsService? googleMapsService})
      : _googleMapsService = googleMapsService ?? GoogleMapsService();

  GoogleMapsService get service => _googleMapsService;

  bool get hasConfiguredApiKey => _googleMapsService.hasConfiguredApiKey;

  @override
  Future<List<LocationSearchResult>> searchLocations(String query) {
    return _googleMapsService.searchPlaces(query);
  }

  @override
  Future<RouteDetails> getRouteDetails(String origin, String destination) {
    return _googleMapsService.getRouteDetails(origin, destination);
  }

  @override
  Future<String> reverseGeocode(double latitude, double longitude) {
    return _googleMapsService.reverseGeocode(latitude, longitude);
  }
}
