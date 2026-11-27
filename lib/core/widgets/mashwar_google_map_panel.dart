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
      ),
    ),
  );
}

/// Opens Google Maps directly INSIDE the MASHWAR app via [MashwarInAppMapScreen].
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
                ? 'تم تجهيز ونسخ رابط الملاحة في Google Maps: $url'
                : 'Google Maps link copied to clipboard: $url',
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

/// Full-screen interactive Google Maps view hosted directly inside the app.
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

  @override
  State<MashwarInAppMapScreen> createState() => _MashwarInAppMapScreenState();
}

class _MashwarInAppMapScreenState extends State<MashwarInAppMapScreen> {
  late bool _satellite;
  RouteDetails? _routeDetails;
  int _loadSeq = 0;

  bool get _isRouteMode {
    final o = widget.origin?.trim() ?? '';
    final d = widget.destination?.trim() ?? '';
    return o.isNotEmpty && d.isNotEmpty && o.toLowerCase() != d.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _satellite = widget.initialSatellite;
    if (_isRouteMode) {
      _routeDetails = GoogleMapsService.estimateRouteSync(
        widget.origin!.trim(),
        widget.destination!.trim(),
      );
      _fetchRouteDetails();
    }
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
    if (widget.lat != null && widget.lng != null) {
      return '${widget.lat!.toStringAsFixed(4)}, ${widget.lng!.toStringAsFixed(4)}';
    }
    return isAr ? 'دولة قطر' : 'State of Qatar';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final titleText = isAr
        ? (widget.titleAr ?? 'خريطة Google Maps المباشرة')
        : (widget.titleEn ?? 'Live Google Maps');
    final subtitleText = _resolveSubtitle(isAr);
    final route = _routeDetails;
    final highway = route?.corridorHighway(isArabic: isAr) ?? '';

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
                fontSize: 15,
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
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: InkWell(
              key: const ValueKey('inapp_map_satellite_toggle'),
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _satellite = !_satellite),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: _satellite ? AppColors.tealSurface : AppColors.slateBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _satellite
                        ? AppColors.teal.withValues(alpha: 0.45)
                        : AppColors.slateBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _satellite
                          ? Icons.map_rounded
                          : Icons.satellite_alt_rounded,
                      size: 15,
                      color: _satellite ? AppColors.tealDark : AppColors.navy,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _satellite
                          ? (isAr ? 'خريطة' : 'Map')
                          : (isAr ? 'قمر صناعي' : 'Satellite'),
                      style: AppTypography.label(
                        color: _satellite ? AppColors.tealDark : AppColors.navy,
                      ).copyWith(
                        fontSize: 11.5,
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
          if (_isRouteMode && route != null)
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
                        ? '${route.distanceKm.round()} كم'
                        : '${route.distanceKm.round()} km',
                  ),
                  _MapMetricPill(
                    icon: Icons.schedule_rounded,
                    label: _formatMapDuration(route.durationMinutes, isAr),
                  ),
                  if (highway.isNotEmpty)
                    _MapMetricPill(
                      icon: Icons.alt_route_rounded,
                      label: highway,
                    ),
                ],
              ),
            ),
          Expanded(
            child: MashwarEmbeddedGoogleMap(
              origin: widget.origin,
              destination: widget.destination,
              stopover: widget.stopover,
              placeQuery: widget.placeQuery,
              lat: widget.lat,
              lng: widget.lng,
              satellite: _satellite,
              zoom: _isRouteMode ? 11 : 14,
              height: double.infinity,
              borderRadius: 0,
              interactive: true,
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
                child: SizedBox(
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
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
                    label: Text(
                      isAr ? 'تأكيد هذا الموقع' : 'Confirm This Location',
                      style: AppTypography.label(color: Colors.white).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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

/// Executive, `pumpAndSettle`-safe reusable in-app Google Maps route & navigation card.
///
/// Features:
/// - Live interactive [MashwarEmbeddedGoogleMap] embedded right inside the panel
///   by default, with 1-tap toggle to [QatarLiveMapCanvas] schematic view and
///   Satellite / Map switcher
/// - Live distance (`كم` / `km`), ETA (`دقيقة` / `min`), and dynamic corridor highway
///   fetched via `AppRepositories.instance.maps.getRouteDetails(origin, destination)`
/// - 1-tap full-screen in-app Google Maps action button
///   (`ValueKey('${keyPrefix}_open_gmaps_btn')`) that keeps users inside the app
///   while preserving `urlLauncherOverride` compatibility for automated tests.
class MashwarGoogleMapPanel extends StatefulWidget {
  const MashwarGoogleMapPanel({
    super.key,
    required this.origin,
    required this.destination,
    this.stopover,
    this.keyPrefix = 'mashwar_map',
    this.mapHeight = 210.0,
    this.showMapCanvas = true,
    this.style = QatarMapStyle.routeFocused,
    this.openButtonLabelAr,
    this.openButtonLabelEn,
    this.urlLauncherOverride,
    this.onHubTap,
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

  @override
  State<MashwarGoogleMapPanel> createState() => _MashwarGoogleMapPanelState();
}

class _MashwarGoogleMapPanelState extends State<MashwarGoogleMapPanel> {
  late RouteDetails _routeDetails;
  int _loadSeq = 0;
  bool _useLiveGoogleMap = true;
  bool _satellite = false;

  @override
  void initState() {
    super.initState();
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
    if (widget.mapHeight >= 148.0 && widget.mapHeight < 210.0) {
      return 210.0;
    }
    return widget.mapHeight;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final hasApiKey = GoogleMapsService.hasActiveApiKey;
    final distanceLabel = isAr
        ? '${_routeDetails.distanceKm.round()} كم'
        : '${_routeDetails.distanceKm.round()} km';
    final etaLabel = _formatMapDuration(_routeDetails.durationMinutes, isAr);
    final highway = _routeDetails.corridorHighway(isArabic: isAr);
    final buttonText = isAr
        ? (widget.openButtonLabelAr ?? 'تكبير خريطة Google Maps داخل التطبيق')
        : (widget.openButtonLabelEn ?? 'Full-Screen Google Maps');
    final directionsUrl = GoogleMapsService.buildDirectionsUrl(
      widget.origin,
      widget.destination,
      stopover: widget.stopover,
    );
    final resolvedMapHeight = _effectiveMapHeight;

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
                  color: hasApiKey ? AppColors.tealSurface : AppColors.slateBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasApiKey
                        ? AppColors.teal.withValues(alpha: 0.35)
                        : AppColors.slateBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasApiKey
                          ? Icons.cloud_done_rounded
                          : Icons.public_rounded,
                      size: 13.5,
                      color: hasApiKey ? AppColors.teal : AppColors.navy,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasApiKey
                          ? (isAr ? 'Google Maps متصل' : 'Google Maps Connected')
                          : (isAr ? 'خرائط Google المباشرة' : 'Live Google Maps'),
                      style: AppTypography.label(
                        color: hasApiKey ? AppColors.tealDark : AppColors.navy,
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
            // Compact Mode Switcher (Google Maps vs Schematic) + Satellite Toggle
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      key: ValueKey('${widget.keyPrefix}_mode_toggle'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(
                        () => _useLiveGoogleMap = !_useLiveGoogleMap,
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
                                selected: _useLiveGoogleMap,
                                icon: Icons.map_rounded,
                                label:
                                    isAr ? 'خريطة جوجل الحية' : 'Google Maps',
                              ),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: _PanelModePill(
                                selected: !_useLiveGoogleMap,
                                icon: Icons.hub_rounded,
                                label: isAr ? 'خريطة المحاور' : 'Schematic',
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
                  message: _satellite
                      ? (isAr ? 'عرض الخريطة العادية' : 'Standard Map')
                      : (isAr ? 'عرض القمر الصناعي' : 'Satellite View'),
                  child: InkWell(
                    key: ValueKey('${widget.keyPrefix}_satellite_btn'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() {
                      _useLiveGoogleMap = true;
                      _satellite = !_satellite;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: (_useLiveGoogleMap && _satellite)
                            ? AppColors.tealSurface
                            : AppColors.slateBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_useLiveGoogleMap && _satellite)
                              ? AppColors.teal.withValues(alpha: 0.45)
                              : AppColors.slateBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.satellite_alt_rounded,
                        size: 16,
                        color: (_useLiveGoogleMap && _satellite)
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
              child: _useLiveGoogleMap
                  ? MashwarEmbeddedGoogleMap(
                      origin: widget.origin,
                      destination: widget.destination,
                      stopover: widget.stopover,
                      satellite: _satellite,
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
              initialSatellite: _satellite,
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
