import 'package:flutter/material.dart';

import '../../data/services/google_maps_service.dart';
import '../localization/app_strings.dart';
import 'mashwar_embedded_google_map_stub.dart'
    if (dart.library.js_interop) 'mashwar_embedded_google_map_web.dart'
    as impl;
import 'qatar_live_map_canvas.dart';

/// Real interactive Uber-grade map view embedded directly inside the MASHWAR app.
///
/// - On Flutter Web (`dart.library.js_interop`), renders the self-contained
///   Uber-style Leaflet + Google Live Traffic + OSRM map engine
///   (`web/maps/mashwar_uber_map.html`) via `ui_web.platformViewRegistry` &
///   `package:web`.
/// - On Dart VM / widget tests / non-web runtimes, renders a `pumpAndSettle`-safe
///   [QatarLiveMapCanvas] fallback while preserving the exact same key contract
///   (`ValueKey('mashwar_embedded_gmap_view')`).
class MashwarEmbeddedGoogleMap extends StatelessWidget {
  const MashwarEmbeddedGoogleMap({
    super.key,
    this.origin,
    this.destination,
    this.stopover,
    this.placeQuery,
    this.lat,
    this.lng,
    this.satellite = false,
    this.zoom = 11,
    this.height = 220,
    this.borderRadius = 14,
    this.interactive = true,
    this.fallbackStyle = QatarMapStyle.routeFocused,
    this.onHubTap,
    this.vehicleMode = MashwarMapVehicleMode.trip,
    this.stylePreset,
    this.showTraffic = true,
    this.showNearbyCars = true,
    this.distanceKm,
    this.durationMinutes,
    this.highwayName,
  });

  final String? origin;
  final String? destination;
  final String? stopover;
  final String? placeQuery;
  final double? lat;
  final double? lng;
  final bool satellite;
  final int zoom;
  final double height;
  final double borderRadius;
  final bool interactive;
  final QatarMapStyle fallbackStyle;
  final ValueChanged<String>? onHubTap;
  final MashwarMapVehicleMode vehicleMode;
  final MashwarMapStylePreset? stylePreset;
  final bool showTraffic;
  final bool showNearbyCars;
  final double? distanceKm;
  final int? durationMinutes;
  final String? highwayName;

  /// Resolves the active tile style preset, defaulting to [satellite] when
  /// [stylePreset] is omitted.
  MashwarMapStylePreset get effectiveStylePreset =>
      stylePreset ??
      (satellite
          ? MashwarMapStylePreset.satellite
          : MashwarMapStylePreset.google);

  /// Resolves the relative URL for the self-contained Uber-grade in-app map
  /// engine (`maps/mashwar_uber_map.html?...`).
  String resolveUberMapUrl({required bool isArabic}) {
    final cleanOrigin = origin?.trim() ?? '';
    final cleanDest = destination?.trim() ?? '';
    final hasRouteEndpoints = cleanOrigin.isNotEmpty && cleanDest.isNotEmpty;
    final effectiveMode = hasRouteEndpoints
        ? vehicleMode
        : MashwarMapVehicleMode.place;

    return GoogleMapsService.buildUberInAppMapUrl(
      origin: cleanOrigin.isNotEmpty ? cleanOrigin : null,
      destination: cleanDest.isNotEmpty ? cleanDest : null,
      stopover: stopover,
      placeQuery: placeQuery,
      lat: lat,
      lng: lng,
      mode: effectiveMode,
      style: effectiveStylePreset,
      showTraffic: showTraffic,
      isArabic: isArabic,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      highwayName: highwayName,
      showNearbyCars: showNearbyCars,
    );
  }

  /// Resolves the classic Google Maps embed URL for backward compatibility.
  String resolveEmbedUrl({required bool isArabic}) {
    final cleanOrigin = origin?.trim() ?? '';
    final cleanDest = destination?.trim() ?? '';
    if (cleanOrigin.isNotEmpty && cleanDest.isNotEmpty) {
      return GoogleMapsService.buildEmbeddedRouteUrl(
        origin: cleanOrigin,
        destination: cleanDest,
        stopover: stopover,
        isArabic: isArabic,
        satellite: satellite || effectiveStylePreset == MashwarMapStylePreset.satellite,
        zoom: zoom,
      );
    }

    final cleanQuery = placeQuery?.trim() ?? '';
    final effectiveQuery = cleanQuery.isNotEmpty
        ? cleanQuery
        : (cleanOrigin.isNotEmpty
            ? cleanOrigin
            : (cleanDest.isNotEmpty ? cleanDest : 'Doha'));

    return GoogleMapsService.buildEmbeddedPlaceUrl(
      query: effectiveQuery,
      lat: lat,
      lng: lng,
      isArabic: isArabic,
      satellite: satellite || effectiveStylePreset == MashwarMapStylePreset.satellite,
      zoom: zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final uberMapUrl = resolveUberMapUrl(isArabic: isArabic);

    return impl.buildPlatformEmbeddedGoogleMap(
      embedUrl: uberMapUrl,
      interactive: interactive,
      height: height,
      borderRadius: borderRadius,
      fallbackStyle: fallbackStyle,
      origin: origin,
      destination: destination,
      placeQuery: placeQuery,
      onHubTap: onHubTap,
    );
  }
}
