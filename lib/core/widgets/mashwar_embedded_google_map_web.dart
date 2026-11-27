import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'qatar_live_map_canvas.dart';

final Set<String> _registeredViewTypes = <String>{};

String _buildViewTypeId(String embedUrl, bool interactive) {
  int h1 = 0x811c9dc5;
  int h2 = 0x9e3779b9;
  for (int i = 0; i < embedUrl.length; i++) {
    final code = embedUrl.codeUnitAt(i);
    h1 = ((h1 ^ code) * 0x01000193) & 0x7fffffff;
    h2 = ((h2 * 31) + code) & 0x7fffffff;
  }
  final mode = interactive ? 'i' : 's';
  return 'mashwar-gmap-$mode-${embedUrl.length}-${h1.toRadixString(36)}-${h2.toRadixString(36)}';
}

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
  final viewType = _buildViewTypeId(embedUrl, interactive);
  if (_registeredViewTypes.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = embedUrl
        ..width = '100%'
        ..height = '100%'
        ..allow = 'geolocation; fullscreen'
        ..referrerPolicy = 'no-referrer-when-downgrade';
      iframe.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..display = 'block'
        ..pointerEvents = interactive ? 'auto' : 'none';
      iframe.setAttribute('allowfullscreen', 'true');
      iframe.setAttribute('title', 'Google Maps');
      return iframe;
    });
  }

  final Widget mapView = ColoredBox(
    color: const Color(0xFFE8EEF2),
    child: HtmlElementView(
      key: ValueKey<String>(viewType),
      viewType: viewType,
    ),
  );

  final Widget sized = height.isFinite
      ? SizedBox(
          height: height,
          width: double.infinity,
          child: mapView,
        )
      : SizedBox.expand(child: mapView);

  return ClipRRect(
    key: const ValueKey('mashwar_embedded_gmap_view'),
    borderRadius: BorderRadius.circular(borderRadius),
    child: sized,
  );
}
