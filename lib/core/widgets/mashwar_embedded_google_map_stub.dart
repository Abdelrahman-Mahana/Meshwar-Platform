import 'package:flutter/material.dart';

import 'qatar_live_map_canvas.dart';

Widget buildPlatformEmbeddedGoogleMap({
  required String embedUrl,
  required bool interactive,
  required double height,
  required double borderRadius,
  required QatarMapStyle fallbackStyle,
  String? origin,
  String? destination,
  String? placeQuery,
  ValueChanged<String>? onHubTap,
}) {
  final effectiveFrom =
      (origin != null && origin.trim().isNotEmpty) ? origin : placeQuery;
  final effectiveTo = (destination != null && destination.trim().isNotEmpty)
      ? destination
      : placeQuery;

  final Widget canvas = QatarLiveMapCanvas(
    style: fallbackStyle,
    showCarTrails: false,
    activeFromCity: effectiveFrom,
    activeToCity: effectiveTo,
    borderRadius: borderRadius,
    onHubTap: interactive ? onHubTap : null,
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
