import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/contracts/i_maps_repository.dart';
import '../../data/services/google_maps_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../localization/app_strings.dart';
import 'qatar_live_map_canvas.dart';

/// Launches a Google Maps URL externally (`LaunchMode.externalApplication`),
/// falling back gracefully to copying the URL + showing a clear SnackBar when
/// running in headless widget tests or restricted browser sandboxes.
Future<bool> launchMashwarGoogleMapsUrl(
  BuildContext context,
  String url, {
  required bool isAr,
  Future<bool> Function(Uri uri, {LaunchMode mode})? launcherOverride,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = Uri.parse(url);
  bool launched = false;
  try {
    if (launcherOverride != null) {
      launched = await launcherOverride(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
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

/// Executive, `pumpAndSettle`-safe reusable Google Maps route & navigation card.
///
/// Features:
/// - Interactive [QatarLiveMapCanvas] preview with origin & destination pins
/// - Live distance (`كم` / `km`), ETA (`دقيقة` / `min`), and dynamic corridor highway
///   fetched via `AppRepositories.instance.maps.getRouteDetails(origin, destination)`
/// - Clean "Google Maps Connected" / "Live Geo Engine" status chip
/// - 1-tap "فتح الملاحة في Google Maps" / "Open in Google Maps" action button
///   (`ValueKey('${keyPrefix}_open_gmaps_btn')`) with graceful sandbox fallback.
class MashwarGoogleMapPanel extends StatefulWidget {
  const MashwarGoogleMapPanel({
    super.key,
    required this.origin,
    required this.destination,
    this.stopover,
    this.keyPrefix = 'mashwar_map',
    this.mapHeight = 148.0,
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

  String _formatDuration(int minutes, bool isAr) {
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

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final hasApiKey = GoogleMapsService.hasActiveApiKey;
    final distanceLabel = isAr
        ? '${_routeDetails.distanceKm.round()} كم'
        : '${_routeDetails.distanceKm.round()} km';
    final etaLabel = _formatDuration(_routeDetails.durationMinutes, isAr);
    final highway = _routeDetails.corridorHighway(isArabic: isAr);
    final buttonText = isAr
        ? (widget.openButtonLabelAr ?? 'فتح الملاحة في Google Maps')
        : (widget.openButtonLabelEn ?? 'Open in Google Maps');
    final directionsUrl = GoogleMapsService.buildDirectionsUrl(
      widget.origin,
      widget.destination,
      stopover: widget.stopover,
    );

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
                          : Icons.satellite_alt_rounded,
                      size: 13.5,
                      color: hasApiKey ? AppColors.teal : AppColors.navy,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasApiKey
                          ? (isAr ? 'Google Maps متصل' : 'Google Maps Connected')
                          : (isAr ? 'محرك الخرائط المباشر' : 'Live Geo Engine'),
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
            const SizedBox(height: 10),
            Container(
              height: widget.mapHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: QatarLiveMapCanvas(
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
              launcherOverride: widget.urlLauncherOverride,
            ),
            icon: const Icon(
              Icons.navigation_rounded,
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
