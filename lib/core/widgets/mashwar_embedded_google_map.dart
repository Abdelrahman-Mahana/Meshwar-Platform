import 'package:flutter/material.dart';

import '../../data/services/google_maps_service.dart';
import '../localization/app_strings.dart';
import 'mashwar_embedded_google_map_stub.dart'
    if (dart.library.js_interop) 'mashwar_embedded_google_map_web.dart'
    as impl;
import 'qatar_live_map_canvas.dart';

/// Real interactive Google Maps view embedded directly inside the MASHWAR app.
///
/// - On Flutter Web (`dart.library.js_interop`), renders a live interactive
///   Google Maps iframe via `ui_web.platformViewRegistry` & `package:web`.
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

  /// Resolves the live Google Maps embed URL for the configured route or place.
  String resolveEmbedUrl({required bool isArabic}) {
    final cleanOrigin = origin?.trim() ?? '';
    final cleanDest = destination?.trim() ?? '';
    if (cleanOrigin.isNotEmpty && cleanDest.isNotEmpty) {
      return GoogleMapsService.buildEmbeddedRouteUrl(
        origin: cleanOrigin,
        destination: cleanDest,
        stopover: stopover,
        isArabic: isArabic,
        satellite: satellite,
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
      satellite: satellite,
      zoom: zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final embedUrl = resolveEmbedUrl(isArabic: isArabic);

    return impl.buildPlatformEmbeddedGoogleMap(
      embedUrl: embedUrl,
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
