import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/contracts/i_maps_repository.dart';
import '../../data/services/google_maps_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../localization/app_strings.dart';
import 'mashwar_embedded_google_map.dart';
import 'qatar_live_map_canvas.dart';

String _formatMapDuration(int minutes, bool isAr) {
  final hours = minutes ~/ 60;
  final rem = minutes % 60;
  if (hours > 0 && rem > 0) {
    return isAr ? '$hours س و $rem د' : '${hours}h ${rem}m';
  }
  if (hours > 0) {
    return isAr ? '$hours س' : '${hours}h';
  }
  return isAr ? '$minutes دقيقة' : '$minutes min';
}

({double lat, double lng})? _tryParseCoordinatePair(String? raw) {
  if (raw == null) return null;
  final match = RegExp(
    r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
  ).firstMatch(raw);
  if (match == null) return null;
  final lat = double.tryParse(match.group(1)!);
  final lng = double.tryParse(match.group(2)!);
  if (lat == null || lng == null) return null;
  return (lat: lat, lng: lng);
}

/// Cycles MASHWAR map tile presets:
/// Standard -> Satellite -> MASHWAR Light -> Night -> Standard.
MashwarMapStylePreset _nextMapStylePreset(MashwarMapStylePreset current) {
  switch (current) {
    case MashwarMapStylePreset.standard:
      return MashwarMapStylePreset.satellite;
    case MashwarMapStylePreset.satellite:
      return MashwarMapStylePreset.mashwarLight;
    case MashwarMapStylePreset.mashwarLight:
      return MashwarMapStylePreset.night;
    case MashwarMapStylePreset.night:
      return MashwarMapStylePreset.standard;
  }
}

String _mapStyleLabel(MashwarMapStylePreset preset, bool isAr) {
  switch (preset) {
    case MashwarMapStylePreset.standard:
      return isAr ? 'قياسي' : 'Standard';
    case MashwarMapStylePreset.mashwarLight:
      return isAr ? 'مشوار الفاتح' : 'MASHWAR Light';
    case MashwarMapStylePreset.satellite:
      return isAr ? 'قمر صناعي' : 'Satellite';
    case MashwarMapStylePreset.night:
      return isAr ? 'ليلي' : 'Night';
  }
}

IconData _mapStyleIcon(MashwarMapStylePreset preset) {
  switch (preset) {
    case MashwarMapStylePreset.standard:
      return Icons.map_rounded;
    case MashwarMapStylePreset.mashwarLight:
      return Icons.layers_rounded;
    case MashwarMapStylePreset.satellite:
      return Icons.satellite_alt_rounded;
    case MashwarMapStylePreset.night:
      return Icons.dark_mode_rounded;
  }
}

/// Pushes [MashwarInAppMapScreen] directly inside the app — never leaving to an
/// external browser tab.
Future<bool?> openMashwarInAppMap(
  BuildContext context, {
  String? origin,
  String? destination,
  String? stopover,
  String? placeQuery,
  double? lat,
  double? lng,
  String? titleAr,
  String? titleEn,
  bool initialSatellite = false,
  bool showConfirmLocationButton = false,
  MashwarMapVehicleMode vehicleMode = MashwarMapVehicleMode.trip,
  MashwarMapStylePreset? stylePreset,
  bool showTraffic = true,
  bool enableGps = true,
  MashwarMapPickMode pickMode = MashwarMapPickMode.none,
  bool navigationMode = false,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => MashwarInAppMapScreen(
        origin: origin,
        destination: destination,
        stopover: stopover,
        placeQuery: placeQuery,
        lat: lat,
        lng: lng,
        titleAr: titleAr,
        titleEn: titleEn,
        initialSatellite: initialSatellite,
        showConfirmLocationButton: showConfirmLocationButton,
        vehicleMode: vehicleMode,
        stylePreset: stylePreset,
        showTraffic: showTraffic,
        enableGps: enableGps,
        pickMode: pickMode,
        navigationMode: navigationMode,
      ),
    ),
  );
}

/// Opens the full-screen MASHWAR Live GPS & Interactive Pin Picker and returns
/// the confirmed [MashwarPickedLocation] (or `null` if dismissed).
Future<MashwarPickedLocation?> openMashwarMapPicker(
  BuildContext context, {
  String? initialLocation,
  String? origin,
  String? destination,
  double? lat,
  double? lng,
  String? titleAr,
  String? titleEn,
  bool enableGps = true,
  MashwarMapPickMode pickMode = MashwarMapPickMode.origin,
  MashwarMapStylePreset? stylePreset,
}) {
  return Navigator.of(context).push<MashwarPickedLocation>(
    MaterialPageRoute<MashwarPickedLocation>(
      builder: (_) => MashwarInAppMapScreen(
        origin: origin,
        destination: destination,
        placeQuery: initialLocation,
        lat: lat,
        lng: lng,
        titleAr: titleAr ?? 'اختر الموقع على خريطة مشوار',
        titleEn: titleEn ?? 'Pick Location on MASHWAR Map',
        showConfirmLocationButton: true,
        returnPickedLocation: true,
        vehicleMode: (origin != null &&
                origin.trim().isNotEmpty &&
                destination != null &&
                destination.trim().isNotEmpty)
            ? MashwarMapVehicleMode.trip
            : MashwarMapVehicleMode.place,
        stylePreset: stylePreset,
        showTraffic: true,
        enableGps: enableGps,
        pickMode: pickMode == MashwarMapPickMode.none
            ? MashwarMapPickMode.origin
            : pickMode,
      ),
    ),
  );
}

/// Opens the interactive MASHWAR live map directly INSIDE the app via
/// [MashwarInAppMapScreen].
///
/// - When [launcherOverride] is injected (automated tests), invokes
///   `launcherOverride(uri, mode: LaunchMode.externalApplication)` so existing
///   test assertions remain 100% compatible.
/// - For all live users (`launcherOverride == null`), parses route/place params
///   from the explicit arguments or [url] query parameters and pushes
///   [MashwarInAppMapScreen] inside the app — NEVER opening an external tab.
Future<bool> launchMashwarGoogleMapsUrl(
  BuildContext context,
  String url, {
  required bool isAr,
  String? origin,
  String? destination,
  String? stopover,
  String? placeQuery,
  double? lat,
  double? lng,
  String? titleAr,
  String? titleEn,
  bool initialSatellite = false,
  MashwarMapVehicleMode vehicleMode = MashwarMapVehicleMode.trip,
  MashwarMapStylePreset? stylePreset,
  bool showTraffic = true,
  bool enableGps = true,
  bool navigationMode = false,
  Future<bool> Function(Uri uri, {LaunchMode mode})? launcherOverride,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = Uri.tryParse(url);

  if (launcherOverride != null && uri != null) {
    bool launched = false;
    try {
      launched = await launcherOverride(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }

    if (!launched) {
      try {
        await Clipboard.setData(ClipboardData(text: url))
            .timeout(const Duration(milliseconds: 100));
      } catch (_) {}
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تم تجهيز ونسخ رابط المسار: $url'
                : 'Route link copied to clipboard: $url',
          ),
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return launched;
  }

  final qp = uri?.queryParameters ?? const <String, String>{};
  final resolvedOrigin = (origin != null && origin.trim().isNotEmpty)
      ? origin.trim()
      : (qp['origin'] ?? qp['saddr'])?.trim();
  final resolvedDestination =
      (destination != null && destination.trim().isNotEmpty)
          ? destination.trim()
          : (qp['destination'] ?? qp['daddr'])?.trim();
  final resolvedStopover = (stopover != null && stopover.trim().isNotEmpty)
      ? stopover.trim()
      : qp['waypoints']?.trim();
  final resolvedPlaceQuery =
      (placeQuery != null && placeQuery.trim().isNotEmpty)
          ? placeQuery.trim()
          : (qp['query'] ?? qp['q'])?.trim();

  double? resolvedLat = lat;
  double? resolvedLng = lng;
  if (resolvedLat == null || resolvedLng == null) {
    final parsed = _tryParseCoordinatePair(resolvedPlaceQuery);
    if (parsed != null) {
      resolvedLat = parsed.lat;
      resolvedLng = parsed.lng;
    }
  }

  final navigator = Navigator.maybeOf(context);
  if (navigator != null) {
    await navigator.push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MashwarInAppMapScreen(
          origin: resolvedOrigin,
          destination: resolvedDestination,
          stopover: resolvedStopover,
          placeQuery: resolvedPlaceQuery,
          lat: resolvedLat,
          lng: resolvedLng,
          titleAr: titleAr,
          titleEn: titleEn,
          initialSatellite: initialSatellite,
          vehicleMode: vehicleMode,
          stylePreset: stylePreset,
          showTraffic: showTraffic,
          enableGps: enableGps,
          navigationMode: navigationMode,
        ),
      ),
    );
    return true;
  }

  try {
    await Clipboard.setData(ClipboardData(text: url))
        .timeout(const Duration(milliseconds: 100));
  } catch (_) {}
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        isAr
            ? 'تعذّر فتح الخريطة الداخلية في هذا السياق، تم نسخ الرابط.'
            : 'Unable to open in-app map here; link copied.',
      ),
      backgroundColor: AppColors.navy,
      behavior: SnackBarBehavior.floating,
    ),
  );
  return false;
}

/// Full-screen interactive MASHWAR Live GPS, Pin-Picker & Navigation Map screen.
class MashwarInAppMapScreen extends StatefulWidget {
  const MashwarInAppMapScreen({
    super.key,
    this.origin,
    this.destination,
    this.stopover,
    this.placeQuery,
    this.lat,
    this.lng,
    this.titleAr,
    this.titleEn,
    this.initialSatellite = false,
    this.showConfirmLocationButton = false,
    this.returnPickedLocation = false,
    this.vehicleMode = MashwarMapVehicleMode.trip,
    this.stylePreset,
    this.showTraffic = true,
    this.enableGps = true,
    this.pickMode = MashwarMapPickMode.none,
    this.navigationMode = false,
  });

  final String? origin;
  final String? destination;
  final String? stopover;
  final String? placeQuery;
  final double? lat;
  final double? lng;
  final String? titleAr;
  final String? titleEn;
  final bool initialSatellite;
  final bool showConfirmLocationButton;
  final bool returnPickedLocation;
  final MashwarMapVehicleMode vehicleMode;
  final MashwarMapStylePreset? stylePreset;
  final bool showTraffic;
  final bool enableGps;
  final MashwarMapPickMode pickMode;
  final bool navigationMode;

  @override
  State<MashwarInAppMapScreen> createState() => _MashwarInAppMapScreenState();
}

class _MashwarInAppMapScreenState extends State<MashwarInAppMapScreen> {
  final MashwarLiveMapController _mapController = MashwarLiveMapController();
  late MashwarMapStylePreset _stylePreset;
  late bool _showTraffic;
  late bool _navigationMode;
  RouteDetails? _routeDetails;
  MashwarPickedLocation? _pickedLocation;
  MashwarGpsPosition? _gpsPosition;
  MashwarLiveRouteUpdate? _liveRouteUpdate;
  int _loadSeq = 0;

  bool get _isSatellite => _stylePreset == MashwarMapStylePreset.satellite;

  bool get _isRouteMode {
    final o = widget.origin?.trim() ?? '';
    final d = widget.destination?.trim() ?? '';
    return o.isNotEmpty && d.isNotEmpty && o.toLowerCase() != d.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _stylePreset = widget.stylePreset ??
        (widget.initialSatellite
            ? MashwarMapStylePreset.satellite
            : MashwarMapStylePreset.standard);
    _showTraffic = widget.showTraffic;
    _navigationMode = widget.navigationMode;
    _seedInitialPickedLocation();
    if (_isRouteMode) {
      _routeDetails = GoogleMapsService.estimateRouteSync(
        widget.origin!.trim(),
        widget.destination!.trim(),
      );
      _fetchRouteDetails();
    }
  }

  void _seedInitialPickedLocation() {
    if (!widget.showConfirmLocationButton &&
        widget.pickMode == MashwarMapPickMode.none) {
      return;
    }
    final raw = (widget.placeQuery?.trim().isNotEmpty == true)
        ? widget.placeQuery!.trim()
        : (widget.origin?.trim().isNotEmpty == true
            ? widget.origin!.trim()
            : (widget.destination?.trim().isNotEmpty == true
                ? widget.destination!.trim()
                : 'الدوحة'));
    final hub = GoogleMapsService.resolveHubEntry(raw);
    _pickedLocation = MashwarPickedLocation(
      target: widget.pickMode == MashwarMapPickMode.destination
          ? 'destination'
          : (widget.pickMode == MashwarMapPickMode.origin ? 'origin' : 'point'),
      lat: widget.lat ?? hub?.lat ?? 25.2854,
      lng: widget.lng ?? hub?.lng ?? 51.5310,
      labelAr: hub?.nameAr ?? raw,
      labelEn: hub?.nameEn ?? raw,
      municipality: hub?.govAr ?? '',
    );
  }

  void _fetchRouteDetails() {
    if (!_isRouteMode) return;
    final seq = ++_loadSeq;
    AppRepositories.instance.maps
        .getRouteDetails(widget.origin!.trim(), widget.destination!.trim())
        .then((details) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _routeDetails = details;
      });
    }).catchError((_) {});
  }

  String _resolveSubtitle(bool isAr) {
    if (_pickedLocation != null &&
        (widget.returnPickedLocation || widget.pickMode != MashwarMapPickMode.none)) {
      return _pickedLocation!.localizedLabel(isArabic: isAr);
    }
    if (_isRouteMode) {
      final arrow = isAr ? '←' : '→';
      return '${widget.origin!.trim()} $arrow ${widget.destination!.trim()}';
    }
    final pq = widget.placeQuery?.trim() ?? '';
    if (pq.isNotEmpty) return pq;
    final o = widget.origin?.trim() ?? '';
    if (o.isNotEmpty) return o;
    final d = widget.destination?.trim() ?? '';
    if (d.isNotEmpty) return d;
    return isAr ? 'دولة قطر' : 'State of Qatar';
  }

  void _handleConfirmLocation() {
    if (widget.returnPickedLocation) {
      final resolved = _pickedLocation ??
          const MashwarPickedLocation(
            target: 'point',
            lat: 25.2854,
            lng: 51.5310,
            labelAr: 'الدوحة',
            labelEn: 'Doha',
            municipality: 'بلدية الدوحة',
          );
      Navigator.of(context).pop<MashwarPickedLocation>(resolved);
    } else {
      Navigator.of(context).pop<bool>(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final titleText = isAr
        ? (widget.titleAr ?? 'خريطة مشوار المباشرة')
        : (widget.titleEn ?? 'MASHWAR Live Map');
    final subtitleText = _resolveSubtitle(isAr);
    final route = _routeDetails;
    final highway = route?.corridorHighway(isArabic: isAr) ?? '';
    final styleActive = _stylePreset != MashwarMapStylePreset.standard;
    final effectiveDistKm = _liveRouteUpdate?.distKm ?? route?.distanceKm;
    final effectiveEtaMin = _liveRouteUpdate?.etaMin ?? route?.durationMinutes;
    final nextStepText =
        _liveRouteUpdate?.localizedNextStep(isArabic: isAr) ?? '';

    return Scaffold(
      key: const ValueKey('inapp_google_map_screen'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.slateBorder),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: AppColors.navy).copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: AppColors.textSecondary)
                  .copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          if (_isRouteMode)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: InkWell(
                key: const ValueKey('inapp_map_nav_toggle'),
                borderRadius: BorderRadius.circular(18),
                onTap: () =>
                    setState(() => _navigationMode = !_navigationMode),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _navigationMode
                        ? AppColors.navy
                        : AppColors.slateBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _navigationMode
                          ? AppColors.navy
                          : AppColors.slateBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.turn_right_rounded,
                        size: 14,
                        color:
                            _navigationMode ? Colors.white : AppColors.navy,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isAr ? 'ملاحة' : 'Nav',
                        style: AppTypography.label(
                          color:
                              _navigationMode ? Colors.white : AppColors.navy,
                        ).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isRouteMode) const SizedBox(width: 5),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: InkWell(
              key: const ValueKey('inapp_map_traffic_toggle'),
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _showTraffic = !_showTraffic),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _showTraffic ? AppColors.tealSurface : AppColors.slateBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _showTraffic
                        ? AppColors.teal.withValues(alpha: 0.45)
                        : AppColors.slateBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.traffic_rounded,
                      size: 14,
                      color: _showTraffic ? AppColors.tealDark : AppColors.navy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAr ? 'الزحمة' : 'Traffic',
                      style: AppTypography.label(
                        color:
                            _showTraffic ? AppColors.tealDark : AppColors.navy,
                      ).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Padding(
            padding:
                const EdgeInsetsDirectional.only(end: 10, top: 9, bottom: 9),
            child: InkWell(
              key: const ValueKey('inapp_map_satellite_toggle'),
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(
                () => _stylePreset = _nextMapStylePreset(_stylePreset),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: styleActive ? AppColors.tealSurface : AppColors.slateBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: styleActive
                        ? AppColors.teal.withValues(alpha: 0.45)
                        : AppColors.slateBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _mapStyleIcon(_stylePreset),
                      size: 14,
                      color: styleActive ? AppColors.tealDark : AppColors.navy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _mapStyleLabel(_stylePreset, isAr),
                      style: AppTypography.label(
                        color:
                            styleActive ? AppColors.tealDark : AppColors.navy,
                      ).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isRouteMode && effectiveDistKm != null && effectiveEtaMin != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.sand,
                border: Border(
                  bottom: BorderSide(color: AppColors.slateBorder),
                ),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MapMetricPill(
                    icon: Icons.straighten_rounded,
                    label: isAr
                        ? '${effectiveDistKm.round()} كم'
                        : '${effectiveDistKm.round()} km',
                  ),
                  _MapMetricPill(
                    icon: Icons.schedule_rounded,
                    label: _formatMapDuration(effectiveEtaMin, isAr),
                  ),
                  if (highway.isNotEmpty)
                    _MapMetricPill(
                      icon: Icons.alt_route_rounded,
                      label: highway,
                    ),
                  if (_navigationMode && nextStepText.isNotEmpty)
                    _MapMetricPill(
                      icon: Icons.turn_right_rounded,
                      label: nextStepText,
                    ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                MashwarEmbeddedGoogleMap(
                  origin: widget.origin,
                  destination: widget.destination,
                  stopover: widget.stopover,
                  placeQuery: widget.placeQuery,
                  lat: widget.lat,
                  lng: widget.lng,
                  satellite: _isSatellite,
                  stylePreset: _stylePreset,
                  vehicleMode: _isRouteMode
                      ? widget.vehicleMode
                      : MashwarMapVehicleMode.place,
                  showTraffic: _showTraffic,
                  enableGps: widget.enableGps,
                  pickMode: widget.pickMode,
                  navigationMode: _navigationMode,
                  controller: _mapController,
                  distanceKm: route?.distanceKm,
                  durationMinutes: route?.durationMinutes,
                  highwayName: highway.isNotEmpty ? highway : null,
                  zoom: _isRouteMode ? 11 : 14,
                  height: double.infinity,
                  borderRadius: 0,
                  interactive: true,
                  onLocationPicked: (picked) {
                    if (!mounted) return;
                    setState(() => _pickedLocation = picked);
                  },
                  onGpsUpdate: (gps) {
                    if (!mounted) return;
                    setState(() {
                      _gpsPosition = gps;
                      if (gps.isTracking &&
                          widget.returnPickedLocation &&
                          _pickedLocation == null) {
                        _pickedLocation = MashwarPickedLocation(
                          target: 'origin',
                          lat: gps.lat,
                          lng: gps.lng,
                          labelAr: 'موقعي الحالي',
                          labelEn: 'My Current Location',
                        );
                      }
                    });
                  },
                  onRouteUpdated: (update) {
                    if (!mounted) return;
                    setState(() => _liveRouteUpdate = update);
                  },
                ),
                PositionedDirectional(
                  bottom: 14,
                  start: 14,
                  child: Material(
                    color: _gpsPosition?.isTracking == true
                        ? const Color(0xFF2563EB)
                        : Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.navy.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      key: const ValueKey('inapp_map_locate_btn'),
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _mapController.locateMe(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              size: 16,
                              color: _gpsPosition?.isTracking == true
                                  ? Colors.white
                                  : const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAr ? 'موقعي الآن' : 'Locate Me',
                              style: AppTypography.label(
                                color: _gpsPosition?.isTracking == true
                                    ? Colors.white
                                    : AppColors.navy,
                              ).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showConfirmLocationButton)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.slateBorder),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_pickedLocation != null) ...[
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.tealSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.pin_drop_rounded,
                              size: 18,
                              color: AppColors.teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedLocation!
                                      .localizedLabel(isArabic: isAr),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body(
                                    color: AppColors.navy,
                                  ).copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  _pickedLocation!.municipality.isNotEmpty
                                      ? _pickedLocation!.municipality
                                      : (isAr
                                          ? 'اضغط على الخريطة أو اسحب الدبوس لتعديل النقطة'
                                          : 'Tap map or drag pin to adjust point'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label(
                                    color: AppColors.textSecondary,
                                  ).copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const ValueKey('inapp_map_confirm_location_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _handleConfirmLocation,
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 19,
                        ),
                        label: Text(
                          isAr ? 'تأكيد هذا الموقع' : 'Confirm This Location',
                          style:
                              AppTypography.label(color: Colors.white).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapMetricPill extends StatelessWidget {
  const _MapMetricPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: AppColors.teal),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: AppColors.navy).copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Executive, `pumpAndSettle`-safe reusable in-app MASHWAR Live Map route &
/// navigation card.
///
/// Features:
/// - Live interactive [MashwarEmbeddedGoogleMap] embedded right inside the panel
///   by default, with 1-tap toggle to [QatarLiveMapCanvas] schematic view,
///   Live Traffic toggle, and Layer/Style switcher
///   (`standard / satellite / mashwarLight / night`)
/// - Live distance (`كم` / `km`), ETA (`دقيقة` / `min`), and dynamic corridor
///   highway fetched via `AppRepositories.instance.maps.getRouteDetails(origin, destination)`
/// - 1-tap full-screen in-app map action button
///   (`ValueKey('${keyPrefix}_open_gmaps_btn')`) that keeps users inside the app
///   while preserving `urlLauncherOverride` compatibility for automated tests.
class MashwarGoogleMapPanel extends StatefulWidget {
  const MashwarGoogleMapPanel({
    super.key,
    required this.origin,
    required this.destination,
    this.stopover,
    this.keyPrefix = 'mashwar_map',
    this.mapHeight = 250.0,
    this.showMapCanvas = true,
    this.style = QatarMapStyle.routeFocused,
    this.openButtonLabelAr,
    this.openButtonLabelEn,
    this.urlLauncherOverride,
    this.onHubTap,
    this.vehicleMode = MashwarMapVehicleMode.trip,
    this.stylePreset,
    this.showTraffic = true,
    this.enableGps = false,
    this.navigationMode = false,
  });

  final String origin;
  final String destination;
  final String? stopover;
  final String keyPrefix;
  final double mapHeight;
  final bool showMapCanvas;
  final QatarMapStyle style;
  final String? openButtonLabelAr;
  final String? openButtonLabelEn;
  final Future<bool> Function(Uri uri, {LaunchMode mode})? urlLauncherOverride;
  final ValueChanged<String>? onHubTap;
  final MashwarMapVehicleMode vehicleMode;
  final MashwarMapStylePreset? stylePreset;
  final bool showTraffic;
  final bool enableGps;
  final bool navigationMode;

  @override
  State<MashwarGoogleMapPanel> createState() => _MashwarGoogleMapPanelState();
}

class _MashwarGoogleMapPanelState extends State<MashwarGoogleMapPanel> {
  late RouteDetails _routeDetails;
  int _loadSeq = 0;
  bool _useLiveMap = true;
  late MashwarMapStylePreset _stylePreset;
  late bool _showTraffic;

  bool get _isSatellite => _stylePreset == MashwarMapStylePreset.satellite;

  @override
  void initState() {
    super.initState();
    _stylePreset = widget.stylePreset ?? MashwarMapStylePreset.standard;
    _showTraffic = widget.showTraffic;
    _routeDetails = GoogleMapsService.estimateRouteSync(
      widget.origin,
      widget.destination,
    );
    _fetchRouteDetails();
  }

  @override
  void didUpdateWidget(covariant MashwarGoogleMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin ||
        oldWidget.destination != widget.destination) {
      _routeDetails = GoogleMapsService.estimateRouteSync(
        widget.origin,
        widget.destination,
      );
      _fetchRouteDetails();
    }
    if (oldWidget.stylePreset != widget.stylePreset &&
        widget.stylePreset != null) {
      _stylePreset = widget.stylePreset!;
    }
    if (oldWidget.showTraffic != widget.showTraffic) {
      _showTraffic = widget.showTraffic;
    }
  }

  void _fetchRouteDetails() {
    final seq = ++_loadSeq;
    AppRepositories.instance.maps
        .getRouteDetails(widget.origin, widget.destination)
        .then((details) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _routeDetails = details;
      });
    }).catchError((_) {});
  }

  double get _effectiveMapHeight {
    if (widget.mapHeight >= 148.0 && widget.mapHeight < 250.0) {
      return 250.0;
    }
    return widget.mapHeight;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final distanceLabel = isAr
        ? '${_routeDetails.distanceKm.round()} كم'
        : '${_routeDetails.distanceKm.round()} km';
    final etaLabel = _formatMapDuration(_routeDetails.durationMinutes, isAr);
    final highway = _routeDetails.corridorHighway(isArabic: isAr);
    final buttonText = isAr
        ? (widget.openButtonLabelAr ?? 'فتح خريطة مشوار ملء الشاشة')
        : (widget.openButtonLabelEn ?? 'Full-Screen MASHWAR Live Map');
    final directionsUrl = GoogleMapsService.buildDirectionsUrl(
      widget.origin,
      widget.destination,
      stopover: widget.stopover,
    );
    final resolvedMapHeight = _effectiveMapHeight;
    final styleHighlighted =
        _useLiveMap && _stylePreset != MashwarMapStylePreset.standard;
    final trafficHighlighted = _useLiveMap && _showTraffic;

    return Container(
      key: ValueKey('${widget.keyPrefix}_gmaps_panel'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Status & Live Distance/ETA Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.navigation_rounded,
                      size: 13.5,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isAr ? 'خريطة مشوار المباشرة' : 'MASHWAR Live Map',
                      style: AppTypography.label(
                        color: AppColors.tealDark,
                      ).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 14,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$distanceLabel · $etaLabel',
                      style: AppTypography.label(color: AppColors.navy).copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.showMapCanvas) ...[
            const SizedBox(height: 8),
            // Compact Mode Switcher (Live Map vs Schematic) + Traffic + Layer Toggle
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      key: ValueKey('${widget.keyPrefix}_mode_toggle'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(
                        () => _useLiveMap = !_useLiveMap,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: AppColors.slateBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: _PanelModePill(
                                selected: _useLiveMap,
                                icon: Icons.map_rounded,
                                label: isAr ? 'خريطة حية' : 'Live Map',
                              ),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: _PanelModePill(
                                selected: !_useLiveMap,
                                icon: Icons.hub_rounded,
                                label: isAr ? 'مخطط المسار' : 'Schematic',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: _showTraffic
                      ? (isAr ? 'إخفاء حالة الزحمة' : 'Hide Live Traffic')
                      : (isAr ? 'عرض حالة الزحمة المباشرة' : 'Show Live Traffic'),
                  child: InkWell(
                    key: ValueKey('${widget.keyPrefix}_traffic_btn'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() {
                      _useLiveMap = true;
                      _showTraffic = !_showTraffic;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: trafficHighlighted
                            ? AppColors.tealSurface
                            : AppColors.slateBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: trafficHighlighted
                              ? AppColors.teal.withValues(alpha: 0.45)
                              : AppColors.slateBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.traffic_rounded,
                            size: 14.5,
                            color: trafficHighlighted
                                ? AppColors.tealDark
                                : AppColors.navy,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'الزحمة' : 'Traffic',
                            style: AppTypography.label(
                              color: trafficHighlighted
                                  ? AppColors.tealDark
                                  : AppColors.navy,
                            ).copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Tooltip(
                  message: isAr
                      ? 'تغيير طبقة الخريطة (${_mapStyleLabel(_stylePreset, true)})'
                      : 'Switch Map Layer (${_mapStyleLabel(_stylePreset, false)})',
                  child: InkWell(
                    key: ValueKey('${widget.keyPrefix}_satellite_btn'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() {
                      _useLiveMap = true;
                      _stylePreset = _nextMapStylePreset(_stylePreset);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6.5),
                      decoration: BoxDecoration(
                        color: styleHighlighted
                            ? AppColors.tealSurface
                            : AppColors.slateBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: styleHighlighted
                              ? AppColors.teal.withValues(alpha: 0.45)
                              : AppColors.slateBorder,
                        ),
                      ),
                      child: Icon(
                        _mapStyleIcon(_stylePreset),
                        size: 16,
                        color: styleHighlighted
                            ? AppColors.tealDark
                            : AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: resolvedMapHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: _useLiveMap
                  ? MashwarEmbeddedGoogleMap(
                      origin: widget.origin,
                      destination: widget.destination,
                      stopover: widget.stopover,
                      satellite: _isSatellite,
                      stylePreset: _stylePreset,
                      vehicleMode: widget.vehicleMode,
                      showTraffic: _showTraffic,
                      enableGps: widget.enableGps,
                      navigationMode: widget.navigationMode,
                      distanceKm: _routeDetails.distanceKm,
                      durationMinutes: _routeDetails.durationMinutes,
                      highwayName: highway.isNotEmpty ? highway : null,
                      height: resolvedMapHeight,
                      borderRadius: 13.0,
                      interactive: true,
                      fallbackStyle: widget.style,
                      onHubTap: widget.onHubTap,
                    )
                  : QatarLiveMapCanvas(
                      style: widget.style,
                      showCarTrails: false,
                      activeFromCity: widget.origin,
                      activeToCity: widget.destination,
                      borderRadius: 13.0,
                      onHubTap: widget.onHubTap,
                    ),
            ),
          ],

          if (highway.isNotEmpty) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(
                  Icons.alt_route_rounded,
                  size: 15,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    highway,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.textSecondary)
                        .copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: ValueKey('${widget.keyPrefix}_open_gmaps_btn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              backgroundColor: AppColors.slateBg,
              side: const BorderSide(color: AppColors.slateBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => launchMashwarGoogleMapsUrl(
              context,
              directionsUrl,
              isAr: isAr,
              origin: widget.origin,
              destination: widget.destination,
              stopover: widget.stopover,
              initialSatellite: _isSatellite,
              stylePreset: _stylePreset,
              vehicleMode: widget.vehicleMode,
              showTraffic: _showTraffic,
              enableGps: true,
              navigationMode: widget.navigationMode,
              launcherOverride: widget.urlLauncherOverride,
            ),
            icon: const Icon(
              Icons.open_in_full_rounded,
              size: 16,
              color: AppColors.teal,
            ),
            label: Text(
              buttonText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(color: AppColors.navy).copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelModePill extends StatelessWidget {
  const _PanelModePill({
    required this.selected,
    required this.icon,
    required this.label,
  });

  final bool selected;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: selected ? AppColors.teal : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(
                color: selected ? AppColors.navy : AppColors.textSecondary,
              ).copyWith(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
