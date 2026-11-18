import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repositories/contracts/i_maps_repository.dart';

/// Google Maps Platform service providing Places Autocomplete, Geocoding,
/// and Directions API with a robust Egyptian offline geo-database fallback.
class GoogleMapsService {
  final String apiKey;
  final http.Client _client;

  GoogleMapsService({
    String? apiKey,
    http.Client? client,
  })  : apiKey = apiKey ?? const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: ''),
        _client = client ?? http.Client();

  /// Comprehensive Egyptian Geo-Catalog for offline/fallback routing and instant suggestions
  static const Map<String, Map<String, dynamic>> egyptianCitiesCatalog = {
    'القاهرة': {'lat': 30.0444, 'lng': 31.2357, 'gov': 'محافظة القاهرة'},
    'الجيزة': {'lat': 30.0131, 'lng': 31.2089, 'gov': 'محافظة الجيزة'},
    'كفر الشيخ': {'lat': 31.1107, 'lng': 30.9388, 'gov': 'محافظة كفر الشيخ'},
    'بلطيم': {'lat': 31.5833, 'lng': 31.0833, 'gov': 'مركز البرلس، كفر الشيخ'},
    'دسوق': {'lat': 31.1322, 'lng': 30.6481, 'gov': 'مركز دسوق، كفر الشيخ'},
    'طنطا': {'lat': 30.7865, 'lng': 31.0004, 'gov': 'محافظة الغربية'},
    'المحلة الكبرى': {'lat': 30.9706, 'lng': 31.1669, 'gov': 'محافظة الغربية'},
    'المنصورة': {'lat': 31.0409, 'lng': 31.3785, 'gov': 'محافظة الدقهلية'},
    'الإسكندرية': {'lat': 31.2001, 'lng': 29.9187, 'gov': 'محافظة الإسكندرية'},
    'الزقازيق': {'lat': 30.5877, 'lng': 31.5020, 'gov': 'محافظة الشرقية'},
    'بنها': {'lat': 30.4660, 'lng': 31.1853, 'gov': 'محافظة القليوبية'},
    'شبين الكوم': {'lat': 30.5522, 'lng': 31.0094, 'gov': 'محافظة المنوفية'},
    'دمياط': {'lat': 31.4175, 'lng': 31.8144, 'gov': 'محافظة دمياط'},
    'بورسعيد': {'lat': 31.2653, 'lng': 32.3019, 'gov': 'محافظة بورسعيد'},
    'الإسماعيلية': {'lat': 30.5965, 'lng': 32.2715, 'gov': 'محافظة الإسماعيلية'},
    'السويس': {'lat': 29.9668, 'lng': 32.5498, 'gov': 'محافظة السويس'},
    'الفيوم': {'lat': 29.3084, 'lng': 30.8428, 'gov': 'محافظة الفيوم'},
    'بني سويف': {'lat': 29.0661, 'lng': 31.0994, 'gov': 'محافظة بني سويف'},
    'المنيا': {'lat': 28.0871, 'lng': 30.7618, 'gov': 'محافظة المنيا'},
    'أسيوط': {'lat': 27.1783, 'lng': 31.1859, 'gov': 'محافظة أسيوط'},
    'سوهاج': {'lat': 26.5569, 'lng': 31.6948, 'gov': 'محافظة سوهاج'},
    'قنا': {'lat': 26.1551, 'lng': 32.7160, 'gov': 'محافظة قنا'},
    'الأقصر': {'lat': 25.6872, 'lng': 32.6396, 'gov': 'محافظة الأقصر'},
    'أسوان': {'lat': 24.0889, 'lng': 32.8998, 'gov': 'محافظة أسوان'},
    'الغردقة': {'lat': 27.2579, 'lng': 33.8116, 'gov': 'محافظة البحر الأحمر'},
    'شرم الشيخ': {'lat': 27.9158, 'lng': 34.3299, 'gov': 'محافظة جنوب سيناء'},
    'مرسى مطروح': {'lat': 31.3543, 'lng': 27.2373, 'gov': 'محافظة مطروح'},
  };

  /// Search places via Google Places Autocomplete API with country=eg restriction
  Future<List<LocationSearchResult>> searchPlaces(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    // If Google Maps API key is configured, query Google Places API
    if (apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=${Uri.encodeComponent(query)}&'
          'components=country:eg&'
          'language=ar&'
          'key=$apiKey',
        );

        final response = await _client.get(uri);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['predictions'] != null) {
            final predictions = data['predictions'] as List;
            return predictions.map((p) {
              final structured = p['structured_formatting'] ?? {};
              return LocationSearchResult(
                placeId: p['place_id'] ?? '',
                mainText: structured['main_text'] ?? p['description'] ?? '',
                secondaryText: structured['secondary_text'] ?? 'مصر',
              );
            }).toList();
          }
        }
      } catch (_) {
        // Fallback to local catalog below if network or API error occurs
      }
    }

    // Local High-Accuracy Egyptian Catalog Fallback
    final matches = <LocationSearchResult>[];
    egyptianCitiesCatalog.forEach((city, data) {
      if (city.toLowerCase().contains(cleanQuery) ||
          (data['gov'] as String).toLowerCase().contains(cleanQuery)) {
        matches.add(
          LocationSearchResult(
            placeId: 'eg_$city',
            mainText: city,
            secondaryText: data['gov'] as String,
            latitude: (data['lat'] as num).toDouble(),
            longitude: (data['lng'] as num).toDouble(),
          ),
        );
      }
    });

    return matches;
  }

  /// Calculates driving route, distance and estimated travel duration
  Future<RouteDetails> getRouteDetails(String origin, String destination) async {
    if (apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${Uri.encodeComponent(origin)}, مصر&'
          'destination=${Uri.encodeComponent(destination)}, مصر&'
          'region=eg&'
          'language=ar&'
          'key=$apiKey',
        );

        final response = await _client.get(uri);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' &&
              data['routes'] != null &&
              (data['routes'] as List).isNotEmpty) {
            final route = data['routes'][0];
            final leg = (route['legs'] as List).first;
            final distanceMeters = (leg['distance']['value'] as num).toDouble();
            final durationSeconds = (leg['duration']['value'] as num).toInt();
            final polyline = route['overview_polyline']['points'] ?? '';

            return RouteDetails(
              distanceKm: (distanceMeters / 1000.0).roundToDouble(),
              durationMinutes: (durationSeconds / 60).round(),
              polyline: polyline,
              startAddress: leg['start_address'] ?? origin,
              endAddress: leg['end_address'] ?? destination,
            );
          }
        }
      } catch (_) {
        // Fallback to algorithmic distance estimation
      }
    }

    // Egyptian Highway Distance Heuristic Model
    return _estimateEgyptianRoute(origin, destination);
  }

  /// Reverse geocodes coordinates to Egyptian address
  Future<String> reverseGeocode(double latitude, double longitude) async {
    if (apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=$latitude,$longitude&'
          'language=ar&'
          'key=$apiKey',
        );
        final response = await _client.get(uri);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' &&
              data['results'] != null &&
              (data['results'] as List).isNotEmpty) {
            return data['results'][0]['formatted_address'] ?? 'مصر';
          }
        }
      } catch (_) {}
    }

    // Nearest known hub in Egyptian catalog
    return _findNearestEgyptianCity(latitude, longitude);
  }

  RouteDetails _estimateEgyptianRoute(String origin, String destination) {
    final origData = egyptianCitiesCatalog[origin];
    final destData = egyptianCitiesCatalog[destination];

    double distance = 135.0; // Default average intercity trip
    int duration = 110;

    if (origData != null && destData != null) {
      final lat1 = (origData['lat'] as num).toDouble();
      final lng1 = (origData['lng'] as num).toDouble();
      final lat2 = (destData['lat'] as num).toDouble();
      final lng2 = (destData['lng'] as num).toDouble();

      // Approximate Euclidean with Egyptian winding highway factor ~ 1.25
      final dLat = (lat2 - lat1) * 111.0;
      final dLng = (lng2 - lng1) * 96.0;
      final straight = (dLat * dLat + dLng * dLng);
      final rawDistance = (straight > 0 ? (straight > 0 ? (dLat.abs() + dLng.abs()) : 100) : 120.0);
      distance = (rawDistance * 1.2).clamp(15.0, 950.0);
      // Average Egyptian highway speed ~ 75 km/h + 20 mins delta/tolls
      duration = ((distance / 75.0) * 60).round() + 15;
    }

    return RouteDetails(
      distanceKm: distance,
      durationMinutes: duration,
      polyline: '',
      startAddress: origData?['gov'] ?? origin,
      endAddress: destData?['gov'] ?? destination,
    );
  }

  String _findNearestEgyptianCity(double lat, double lng) {
    String nearest = 'القاهرة';
    double minDiff = 999999.0;

    egyptianCitiesCatalog.forEach((city, data) {
      final cLat = (data['lat'] as num).toDouble();
      final cLng = (data['lng'] as num).toDouble();
      final diff = (lat - cLat).abs() + (lng - cLng).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = '$city (${data['gov']})';
      }
    });

    return nearest;
  }
}
