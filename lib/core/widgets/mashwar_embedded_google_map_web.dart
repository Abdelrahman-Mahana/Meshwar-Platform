import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../data/services/google_maps_service.dart';
import 'mashwar_embedded_google_map.dart';
import 'qatar_live_map_canvas.dart';

int _nextChannelSeq = 1;

Uri _resolveAppBaseUri() {
  final docBase = web.document.baseURI;
  if (docBase.isNotEmpty) {
    final parsed = Uri.tryParse(docBase);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
  }
  return Uri.base;
}

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
  return _WebEmbeddedLiveMap(
    embedUrl: embedUrl,
    isArabic: isArabic,
    interactive: interactive,
    height: height,
    borderRadius: borderRadius,
    origin: origin,
    destination: destination,
    stopover: stopover,
    placeQuery: placeQuery,
    lat: lat,
    lng: lng,
    vehicleMode: vehicleMode,
    stylePreset: stylePreset,
    showTraffic: showTraffic,
    enableGps: enableGps,
    pickMode: pickMode,
    navigationMode: navigationMode,
    distanceKm: distanceKm,
    durationMinutes: durationMinutes,
    highwayName: highwayName,
    channelId: channelId,
    controller: controller,
    onLocationPicked: onLocationPicked,
    onGpsUpdate: onGpsUpdate,
    onRouteUpdated: onRouteUpdated,
  );
}

class _WebEmbeddedLiveMap extends StatefulWidget {
  const _WebEmbeddedLiveMap({
    required this.embedUrl,
    required this.isArabic,
    required this.interactive,
    required this.height,
    required this.borderRadius,
    this.origin,
    this.destination,
    this.stopover,
    this.placeQuery,
    this.lat,
    this.lng,
    required this.vehicleMode,
    required this.stylePreset,
    required this.showTraffic,
    required this.enableGps,
    required this.pickMode,
    required this.navigationMode,
    this.distanceKm,
    this.durationMinutes,
    this.highwayName,
    this.channelId,
    this.controller,
    this.onLocationPicked,
    this.onGpsUpdate,
    this.onRouteUpdated,
  });

  final String embedUrl;
  final bool isArabic;
  final bool interactive;
  final double height;
  final double borderRadius;
  final String? origin;
  final String? destination;
  final String? stopover;
  final String? placeQuery;
  final double? lat;
  final double? lng;
  final MashwarMapVehicleMode vehicleMode;
  final MashwarMapStylePreset stylePreset;
  final bool showTraffic;
  final bool enableGps;
  final MashwarMapPickMode pickMode;
  final bool navigationMode;
  final double? distanceKm;
  final int? durationMinutes;
  final String? highwayName;
  final String? channelId;
  final MashwarLiveMapController? controller;
  final ValueChanged<MashwarPickedLocation>? onLocationPicked;
  final ValueChanged<MashwarGpsPosition>? onGpsUpdate;
  final ValueChanged<MashwarLiveRouteUpdate>? onRouteUpdated;

  @override
  State<_WebEmbeddedLiveMap> createState() => _WebEmbeddedLiveMapState();
}

class _WebEmbeddedLiveMapState extends State<_WebEmbeddedLiveMap> {
  late final String _channelId;
  late final String _viewType;
  late final web.EventListener _messageListener;
  web.HTMLIFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    final seq = _nextChannelSeq++;
    final explicitCh = widget.channelId?.trim() ?? '';
    _channelId = explicitCh.isNotEmpty ? explicitCh : 'mw_ch_$seq';
    _viewType = 'mashwar-livemap-$seq-$_channelId';

    final initialUrl = _withChannelParam(widget.embedUrl, _channelId);
    final resolvedInitialUrl = _resolveAppBaseUri().resolve(initialUrl).toString();

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = resolvedInitialUrl
        ..width = '100%'
        ..height = '100%'
        ..allow =
            'geolocation; fullscreen; accelerometer; gyroscope; magnetometer'
        ..referrerPolicy = 'no-referrer-when-downgrade';
      iframe.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..display = 'block'
        ..backgroundColor = 'transparent'
        ..pointerEvents = widget.interactive ? 'auto' : 'none';
      iframe.setAttribute('allowfullscreen', 'true');
      iframe.setAttribute('loading', 'eager');
      iframe.setAttribute('title', 'MASHWAR Interactive Live Map');
      _iframe = iframe;
      return iframe;
    });

    _messageListener = ((web.Event rawEvent) {
      _handleWindowMessage(rawEvent);
    }).toJS;
    web.window.addEventListener('message', _messageListener);
    widget.controller?.attach(_sendCommand);
  }

  String _withChannelParam(String url, String ch) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;
    final nextParams = Map<String, String>.from(parsed.queryParameters);
    nextParams['ch'] = ch;
    return parsed.replace(queryParameters: nextParams).toString();
  }

  void _handleWindowMessage(web.Event rawEvent) {
    if (!mounted) return;
    final event = rawEvent as web.MessageEvent;
    final expectedOrigin = web.window.location.origin;
    if (expectedOrigin.isNotEmpty &&
        expectedOrigin != 'null' &&
        event.origin != expectedOrigin) {
      return;
    }

    final Object? dartData = event.data?.dartify();
    if (dartData is! Map) return;
    final map = dartData.cast<Object?, Object?>();
    final msgChannel = (map['ch'] ?? '').toString().trim();
    if (msgChannel != _channelId) return;

    final type = (map['type'] ?? '').toString();
    if (type == 'mw_location_picked') {
      final picked = MashwarPickedLocation.fromMap(map);
      if (picked != null) {
        widget.onLocationPicked?.call(picked);
      }
    } else if (type == 'mw_gps_update') {
      final gps = MashwarGpsPosition.fromMap(map);
      if (gps != null) {
        widget.onGpsUpdate?.call(gps);
      }
    } else if (type == 'mw_route_updated') {
      final route = MashwarLiveRouteUpdate.fromMap(map);
      if (route != null) {
        widget.onRouteUpdated?.call(route);
      }
    }
  }

  void _sendCommand(String cmd, Map<String, Object?> payload) {
    final contentWin = _iframe?.contentWindow;
    if (contentWin == null) return;
    final origin = web.window.location.origin;
    final targetOrigin =
        (origin.isNotEmpty && origin != 'null') ? origin : '*';
    final envelope = <String, Object?>{
      'type': 'mw_command',
      'ch': _channelId,
      'cmd': cmd,
      'payload': payload,
    };
    contentWin.postMessage(envelope.jsify(), targetOrigin.toJS);
  }

  Map<String, Object?> _buildRouteCommandPayload() {
    final cleanOrigin = widget.origin?.trim() ?? '';
    final cleanDest = widget.destination?.trim() ?? '';
    final cleanStop = widget.stopover?.trim() ?? '';
    final cleanPlace = widget.placeQuery?.trim() ?? '';
    final hasRoute = cleanOrigin.isNotEmpty &&
        cleanDest.isNotEmpty &&
        widget.vehicleMode != MashwarMapVehicleMode.place;

    if (hasRoute) {
      final origHub = GoogleMapsService.resolveHubEntry(cleanOrigin);
      final destHub = GoogleMapsService.resolveHubEntry(cleanDest);
      final stopHub =
          cleanStop.isNotEmpty ? GoogleMapsService.resolveHubEntry(cleanStop) : null;
      return <String, Object?>{
        'mode': widget.vehicleMode.name,
        'fromLat': origHub?.lat ?? 25.2854,
        'fromLng': origHub?.lng ?? 51.5310,
        'fromName': cleanOrigin,
        'toLat': destHub?.lat ?? 25.4357,
        'toLng': destHub?.lng ?? 51.4910,
        'toName': cleanDest,
        if (stopHub != null) 'stopLat': stopHub.lat,
        if (stopHub != null) 'stopLng': stopHub.lng,
        if (stopHub != null) 'stopName': cleanStop,
        if (stopHub == null) 'clearStopover': true,
        if (widget.distanceKm != null) 'dist': widget.distanceKm,
        if (widget.durationMinutes != null) 'eta': widget.durationMinutes,
        if (widget.highwayName != null && widget.highwayName!.trim().isNotEmpty)
          'hwy': widget.highwayName!.trim(),
      };
    }

    final effectiveLabel = cleanPlace.isNotEmpty
        ? cleanPlace
        : (cleanOrigin.isNotEmpty
            ? cleanOrigin
            : (cleanDest.isNotEmpty
                ? cleanDest
                : (widget.isArabic ? 'الدوحة' : 'Doha')));
    final hub = GoogleMapsService.resolveHubEntry(effectiveLabel);
    final pLat = widget.lat ?? hub?.lat ?? 25.2854;
    final pLng = widget.lng ?? hub?.lng ?? 51.5310;
    return <String, Object?>{
      'mode': MashwarMapVehicleMode.place.name,
      'fromLat': pLat,
      'fromLng': pLng,
      'placeLat': pLat,
      'placeLng': pLng,
      'fromName': effectiveLabel,
      'placeName': effectiveLabel,
      'clearStopover': true,
    };
  }

  @override
  void didUpdateWidget(covariant _WebEmbeddedLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(_sendCommand);
      widget.controller?.attach(_sendCommand);
    }

    if (oldWidget.interactive != widget.interactive) {
      _iframe?.style.pointerEvents = widget.interactive ? 'auto' : 'none';
    }

    if (oldWidget.stylePreset != widget.stylePreset) {
      _sendCommand('set_style', <String, Object?>{
        'style': widget.stylePreset.queryValue,
      });
    }

    if (oldWidget.showTraffic != widget.showTraffic) {
      _sendCommand('set_traffic', <String, Object?>{
        'showTraffic': widget.showTraffic,
      });
    }

    if (oldWidget.pickMode != widget.pickMode) {
      _sendCommand('set_pick_mode', <String, Object?>{
        'pickMode': widget.pickMode.name,
      });
    }

    if (oldWidget.navigationMode != widget.navigationMode) {
      _sendCommand('set_nav', <String, Object?>{
        'navigationMode': widget.navigationMode,
      });
    }

    if (!oldWidget.enableGps && widget.enableGps) {
      _sendCommand('locate_me', const <String, Object?>{});
    }

    final routeChanged = oldWidget.origin != widget.origin ||
        oldWidget.destination != widget.destination ||
        oldWidget.stopover != widget.stopover ||
        oldWidget.placeQuery != widget.placeQuery ||
        oldWidget.lat != widget.lat ||
        oldWidget.lng != widget.lng ||
        oldWidget.vehicleMode != widget.vehicleMode;
    if (routeChanged) {
      _sendCommand('set_route', _buildRouteCommandPayload());
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(_sendCommand);
    web.window.removeEventListener('message', _messageListener);
    _iframe = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNightStyle = widget.stylePreset == MashwarMapStylePreset.night;
    final Widget mapView = ColoredBox(
      color: isNightStyle ? const Color(0xFF101A24) : const Color(0xFFE8EEF2),
      child: HtmlElementView(
        key: ValueKey<String>(_viewType),
        viewType: _viewType,
      ),
    );

    final Widget sized = widget.height.isFinite
        ? SizedBox(
            height: widget.height,
            width: double.infinity,
            child: mapView,
          )
        : SizedBox.expand(child: mapView);

    return ClipRRect(
      key: const ValueKey('mashwar_embedded_gmap_view'),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: sized,
    );
  }
}
