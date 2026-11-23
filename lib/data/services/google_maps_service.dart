import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repositories/contracts/i_maps_repository.dart';

/// Google Maps Platform service providing Places Autocomplete, Geocoding,
/// and Directions API with a robust Qatar offline geo-database fallback.
class GoogleMapsService {
  final String apiKey;
  final http.Client _client;

  GoogleMapsService({
    String? apiKey,
    http.Client? client,
  })  : apiKey = apiKey ?? const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: ''),
        _client = client ?? http.Client();

  /// Comprehensive Qatar Geo-Catalog covering all 8 municipalities & key logistics hubs
  static const Map<String, Map<String, dynamic>> qatarCitiesCatalog = {
    'الدوحة': {'lat': 25.2854, 'lng': 51.5310, 'gov': 'بلدية الدوحة'},
    'الريان': {'lat': 25.2919, 'lng': 51.4244, 'gov': 'بلدية الريان'},
    'الوكرة': {'lat': 25.1715, 'lng': 51.6034, 'gov': 'بلدية الوكرة'},
    'الخور': {'lat': 25.6804, 'lng': 51.4969, 'gov': 'بلدية الخور والذخيرة'},
    'أم صلال': {'lat': 25.4152, 'lng': 51.4065, 'gov': 'بلدية أم صلال'},
    'الضعاين': {'lat': 25.4648, 'lng': 51.4601, 'gov': 'بلدية الضعاين'},
    'الشمال': {'lat': 26.1293, 'lng': 51.2009, 'gov': 'بلدية الشمال'},
    'الشيحانية': {'lat': 25.3709, 'lng': 51.2226, 'gov': 'بلدية الشيحانية'},
    'لوسيل': {'lat': 25.4357, 'lng': 51.4910, 'gov': 'بلدية الضعاين'},
    'دخان': {'lat': 25.4247, 'lng': 50.7824, 'gov': 'بلدية الشيحانية'},
    'مسيعيد': {'lat': 24.9946, 'lng': 51.5473, 'gov': 'بلدية الوكرة'},
    'المنطقة الصناعية': {'lat': 25.1610, 'lng': 51.4417, 'gov': 'بلدية الريان'},
    'رأس لفان': {'lat': 25.9189, 'lng': 51.5370, 'gov': 'بلدية الخور والذخيرة'},
    'اللؤلؤة': {'lat': 25.3679, 'lng': 51.5514, 'gov': 'بلدية الدوحة'},
    'كتارا': {'lat': 25.3602, 'lng': 51.5245, 'gov': 'بلدية الدوحة'},
    'مشيرب': {'lat': 25.2877, 'lng': 51.5276, 'gov': 'بلدية الدوحة'},
    'المدينة التعليمية': {'lat': 25.3147, 'lng': 51.4384, 'gov': 'بلدية الريان'},
    'مطار حمد الدولي': {'lat': 25.2731, 'lng': 51.6081, 'gov': 'بلدية الدوحة'},
    'السد': {'lat': 25.2816, 'lng': 51.5008, 'gov': 'بلدية الدوحة'},
    'الدفنة': {'lat': 25.3260, 'lng': 51.5318, 'gov': 'بلدية الدوحة'},
    'الذخيرة': {'lat': 25.7302, 'lng': 51.5469, 'gov': 'بلدية الخور والذخيرة'},
    'أبو سمرة': {'lat': 24.7453, 'lng': 50.8588, 'gov': 'بلدية الريان'},
  };

  /// Search places via Google Places Autocomplete API with country=qa restriction
  Future<List<LocationSearchResult>> searchPlaces(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    // If Google Maps API key is configured, query Google Places API
    if (apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=${Uri.encodeComponent(query)}&'
          'components=country:qa&'
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
                secondaryText: structured['secondary_text'] ?? 'قطر',
              );
            }).toList();
          }
        }
      } catch (_) {
        // Fallback to local catalog below if network or API error occurs
      }
    }

    // Local High-Accuracy Qatar Catalog Fallback
    final matches = <LocationSearchResult>[];
    qatarCitiesCatalog.forEach((city, data) {
      if (city.toLowerCase().contains(cleanQuery) ||
          (data['gov'] as String).toLowerCase().contains(cleanQuery)) {
        matches.add(
          LocationSearchResult(
            placeId: 'qa_$city',
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

  /// Calculates driving route, distance and estimated travel duration across Qatar highways
  Future<RouteDetails> getRouteDetails(String origin, String destination) async {
    if (apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${Uri.encodeComponent(origin)}, قطر&'
          'destination=${Uri.encodeComponent(destination)}, قطر&'
          'region=qa&'
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

    // Qatar Highway Distance Heuristic Model
    return _estimateQatarRoute(origin, destination);
  }

  /// Reverse geocodes coordinates to Qatari address
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
            return data['results'][0]['formatted_address'] ?? 'قطر';
          }
        }
      } catch (_) {}
    }

    // Nearest known hub in Qatar catalog
    return _findNearestQatarCity(latitude, longitude);
  }

  RouteDetails _estimateQatarRoute(String origin, String destination) {
    final origData = qatarCitiesCatalog[origin];
    final destData = qatarCitiesCatalog[destination];

    double distance = 46.0; // Default Doha <-> Al Khor corridor distance
    int duration = 42;

    if (origData != null && destData != null) {
      final lat1 = (origData['lat'] as num).toDouble();
      final lng1 = (origData['lng'] as num).toDouble();
      final lat2 = (destData['lat'] as num).toDouble();
      final lng2 = (destData['lng'] as num).toDouble();

      // Approximate road distance factor (~1.18 on Qatar expressways)
      final dLat = (lat2 - lat1) * 111.0;
      final dLng = (lng2 - lng1) * 100.0;
      final straight = (dLat * dLat + dLng * dLng);
      final rawDistance = straight > 0 ? (dLat.abs() + dLng.abs()) : 38.0;
      distance = (rawDistance * 1.15).clamp(8.0, 145.0).roundToDouble();
      // Average Qatar expressway speed ~ 90 km/h + 8 mins city access
      duration = ((distance / 90.0) * 60).round() + 8;
    }

    return RouteDetails(
      distanceKm: distance,
      durationMinutes: duration,
      polyline: '',
      startAddress: origData?['gov'] ?? origin,
      endAddress: destData?['gov'] ?? destination,
    );
  }

  String _findNearestQatarCity(double lat, double lng) {
    String nearest = 'الدوحة';
    double minDiff = 999999.0;

    qatarCitiesCatalog.forEach((city, data) {
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
