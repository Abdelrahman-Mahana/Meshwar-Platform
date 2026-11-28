import 'package:flutter/material.dart';

import '../../data/services/google_maps_service.dart';
import '../localization/app_strings.dart';
import 'mashwar_embedded_google_map_stub.dart'
    if (dart.library.js_interop) 'mashwar_embedded_google_map_web.dart'
    as impl;
import 'qatar_live_map_canvas.dart';

/// Lightweight controller to issue zero-reload live commands (`locate_me`,
/// `fit_route`) to an active [MashwarEmbeddedGoogleMap].
class MashwarLiveMapController {
  void Function(String cmd, Map<String, Object?> payload)? _commandSender;

  /// Internal hook bound by the active platform map widget.
  void attach(void Function(String cmd, Map<String, Object?> payload) sender) {
    _commandSender = sender;
  }

  /// Internal hook unbound when the platform map widget disposes.
  void detach(void Function(String cmd, Map<String, Object?> payload) sender) {
    if (_commandSender == sender) {
      _commandSender = null;
    }
  }

  /// Centers the map on the user's live GPS fix and engages follow mode.
  void locateMe() {
    _commandSender?.call('locate_me', const <String, Object?>{});
  }

  /// Re-centers the camera to frame the active route or place marker.
  void fitRoute() {
    _commandSender?.call('fit_route', const <String, Object?>{});
  }
}

/// Real interactive MASHWAR live GPS, pin-picker, and routing map embedded
/// directly inside the app.
///
/// - On Flutter Web (`dart.library.js_interop`), renders a stable, zero-reload
///   `HtmlElementView` hosting `web/maps/mashwar_live_map.html` with same-origin
///   `postMessage` bidirectional events (`mw_command`, `mw_location_picked`,
///   `mw_gps_update`, `mw_route_updated`).
/// - On Dart VM / widget tests / non-web runtimes, renders a `pumpAndSettle`-safe
///   [QatarLiveMapCanvas] fallback while preserving `ValueKey('mashwar_embedded_gmap_view')`.
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
    this.enableGps = false,
    this.pickMode = MashwarMapPickMode.none,
    this.navigationMode = false,
    this.channelId,
    this.controller,
    this.onLocationPicked,
    this.onGpsUpdate,
    this.onRouteUpdated,
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
  final bool enableGps;
  final MashwarMapPickMode pickMode;
  final bool navigationMode;
  final String? channelId;
  final MashwarLiveMapController? controller;
  final ValueChanged<MashwarPickedLocation>? onLocationPicked;
  final ValueChanged<MashwarGpsPosition>? onGpsUpdate;
  final ValueChanged<MashwarLiveRouteUpdate>? onRouteUpdated;

  /// Resolves the active tile style preset, defaulting to [satellite] when
  /// [stylePreset] is omitted.
  MashwarMapStylePreset get effectiveStylePreset =>
      stylePreset ??
      (satellite
          ? MashwarMapStylePreset.satellite
          : MashwarMapStylePreset.standard);

  /// Resolves the relative URL for the self-contained MASHWAR live map engine
  /// (`maps/mashwar_live_map.html?...`).
  String resolveLiveMapUrl({
    required bool isArabic,
    String? overrideChannelId,
  }) {
    final cleanOrigin = origin?.trim() ?? '';
    final cleanDest = destination?.trim() ?? '';
    final hasRouteEndpoints = cleanOrigin.isNotEmpty && cleanDest.isNotEmpty;
    final effectiveMode = hasRouteEndpoints
        ? vehicleMode
        : MashwarMapVehicleMode.place;

    return GoogleMapsService.buildLiveMapUrl(
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
      enableGps: enableGps,
      pickMode: pickMode,
      navigationMode: navigationMode,
      channelId: overrideChannelId ?? channelId,
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
        satellite: satellite ||
            effectiveStylePreset == MashwarMapStylePreset.satellite,
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
      satellite:
          satellite || effectiveStylePreset == MashwarMapStylePreset.satellite,
      zoom: zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final liveMapUrl = resolveLiveMapUrl(isArabic: isArabic);

    return impl.buildPlatformEmbeddedGoogleMap(
      embedUrl: liveMapUrl,
      isArabic: isArabic,
      interactive: interactive,
      height: height,
      borderRadius: borderRadius,
      fallbackStyle: fallbackStyle,
      origin: origin,
      destination: destination,
      stopover: stopover,
      placeQuery: placeQuery,
      lat: lat,
      lng: lng,
      vehicleMode: vehicleMode,
      stylePreset: effectiveStylePreset,
      showTraffic: showTraffic,
      enableGps: enableGps,
      pickMode: pickMode,
      navigationMode: navigationMode,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      highwayName: highwayName,
      channelId: channelId,
      controller: controller,
      onHubTap: onHubTap,
      onLocationPicked: onLocationPicked,
      onGpsUpdate: onGpsUpdate,
      onRouteUpdated: onRouteUpdated,
    );
  }
}
