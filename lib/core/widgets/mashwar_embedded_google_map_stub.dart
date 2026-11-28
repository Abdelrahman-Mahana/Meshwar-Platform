import 'package:flutter/material.dart';

import '../../data/services/google_maps_service.dart';
import 'mashwar_embedded_google_map.dart';
import 'qatar_live_map_canvas.dart';

Widget buildPlatformEmbeddedGoogleMap({
  required String embedUrl,
  required bool isArabic,
  required bool interactive,
  required double height,
  required double borderRadius,
  required QatarMapStyle fallbackStyle,
  String? origin,
  String? destination,
  String? stopover,
  String? placeQuery,
  double? lat,
  double? lng,
  required MashwarMapVehicleMode vehicleMode,
  required MashwarMapStylePreset stylePreset,
  required bool showTraffic,
  required bool enableGps,
  required MashwarMapPickMode pickMode,
  required bool navigationMode,
  double? distanceKm,
  int? durationMinutes,
  String? highwayName,
  String? channelId,
  MashwarLiveMapController? controller,
  ValueChanged<String>? onHubTap,
  ValueChanged<MashwarPickedLocation>? onLocationPicked,
  ValueChanged<MashwarGpsPosition>? onGpsUpdate,
  ValueChanged<MashwarLiveRouteUpdate>? onRouteUpdated,
}) {
  final effectiveFrom =
      (origin != null && origin.trim().isNotEmpty) ? origin : placeQuery;
  final effectiveTo = (destination != null && destination.trim().isNotEmpty)
      ? destination
      : placeQuery;

  void handleHubTap(String city) {
    onHubTap?.call(city);
    if (onLocationPicked != null) {
      final hub = GoogleMapsService.resolveHubEntry(city);
      final target = pickMode == MashwarMapPickMode.origin
          ? 'origin'
          : (pickMode == MashwarMapPickMode.destination
              ? 'destination'
              : 'point');
      onLocationPicked(
        MashwarPickedLocation(
          target: target,
          lat: hub?.lat ?? 25.2854,
          lng: hub?.lng ?? 51.5310,
          labelAr: hub?.nameAr ?? city,
          labelEn: hub?.nameEn ?? city,
          municipality: isArabic ? (hub?.govAr ?? '') : (hub?.govEn ?? ''),
        ),
      );
    }
  }

  final Widget canvas = QatarLiveMapCanvas(
    style: fallbackStyle,
    showCarTrails: false,
    activeFromCity: effectiveFrom,
    activeToCity: effectiveTo,
    borderRadius: borderRadius,
    onHubTap: interactive && (onHubTap != null || onLocationPicked != null)
        ? handleHubTap
        : null,
  );

  final Widget sized = height.isFinite
      ? SizedBox(
          height: height,
          width: double.infinity,
          child: canvas,
        )
      : SizedBox.expand(child: canvas);

  return ClipRRect(
    key: const ValueKey('mashwar_embedded_gmap_view'),
    borderRadius: BorderRadius.circular(borderRadius),
    child: sized,
  );
}
