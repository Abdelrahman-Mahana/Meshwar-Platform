import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/mashwar_animations.dart';
import '../../../core/widgets/mashwar_embedded_google_map.dart';
import '../../../core/widgets/mashwar_google_map_panel.dart';
import '../../../data/models/ride_model.dart';
import '../../../data/repositories/app_repositories.dart';
import '../../../data/repositories/contracts/i_maps_repository.dart';
import '../../../data/services/google_maps_service.dart';

enum RoutePerspective {
  passenger, // منظور الراكب: تركيز على نقطة ركوبك ونزولك ومسافة المشي
  driver,    // منظور السائق: مسار القيادة، نقطة التجمع المخصصة، والمحطات السريعة
}

MashwarMapStylePreset _nextRideMapStyle(MashwarMapStylePreset current) {
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

String _rideMapStyleLabel(MashwarMapStylePreset preset, bool isAr) {
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

IconData _rideMapStyleIcon(MashwarMapStylePreset preset) {
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

/// Rich, high-fidelity interactive route map view for ride details.
/// Precisely delineates route milestones for both Passenger and Driver perspectives.
class RideRouteMapView extends StatefulWidget {
  const RideRouteMapView({
    super.key,
    required this.ride,
    this.initialPerspective = RoutePerspective.passenger,
    this.enableGps = false,
    this.navigationMode = false,
  });

  final RideModel ride;
  final RoutePerspective initialPerspective;
  final bool enableGps;
  final bool navigationMode;

  @override
  State<RideRouteMapView> createState() => _RideRouteMapViewState();
}

class _RideRouteMapViewState extends State<RideRouteMapView>
    with SingleTickerProviderStateMixin {
  late RoutePerspective _perspective;
  bool _useLiveMap = true;
  MashwarMapStylePreset _stylePreset = MashwarMapStylePreset.standard;
  bool _showTraffic = true;
  bool _isRouteExpanded = false;
  late RouteDetails _routeDetails;
  late final AnimationController _routeAnimController;

  bool get _showSatellite => _stylePreset == MashwarMapStylePreset.satellite;
  bool get _isDarkSchematic =>
      _stylePreset == MashwarMapStylePreset.satellite ||
      _stylePreset == MashwarMapStylePreset.night;

  @override
  void initState() {
    super.initState();
    _perspective = widget.initialPerspective;
    _routeDetails = GoogleMapsService.estimateRouteSync(
      widget.ride.fromCity,
      widget.ride.toCity,
    );
    _routeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    if (mashwarShouldAnimateContinuous()) {
      _routeAnimController.repeat();
    } else {
      _routeAnimController.value = 0.42;
    }
    _loadRouteDetails();
  }

  @override
  void didUpdateWidget(covariant RideRouteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ride.fromCity != widget.ride.fromCity ||
        oldWidget.ride.toCity != widget.ride.toCity) {
      _routeDetails = GoogleMapsService.estimateRouteSync(
        widget.ride.fromCity,
        widget.ride.toCity,
      );
      _loadRouteDetails();
    }
  }

  @override
  void dispose() {
    _routeAnimController.dispose();
    super.dispose();
  }

  void _loadRouteDetails() {
    AppRepositories.instance.maps
        .getRouteDetails(widget.ride.fromCity, widget.ride.toCity)
        .then((details) {
      if (mounted) {
        setState(() {
          _routeDetails = details;
        });
      }
    }).catchError((_) {});
  }

  // Route metrics dynamically derived via Google Maps & Qatar Expressway calculations
  String _distanceKm(bool isAr) {
    final km = _routeDetails.distanceKm.round();
    return isAr ? '$km كم' : '$km km';
  }

  String _durationFormatted(bool isAr) {
    final hours = _routeDetails.durationMinutes ~/ 60;
    final mins = _routeDetails.durationMinutes % 60;
    if (hours > 0 && mins > 0) {
      return isAr ? '$hours س و $mins د' : '${hours}h ${mins}m';
    } else if (hours > 0) {
      return isAr ? '$hours ساعات' : '$hours hrs';
    } else {
      return isAr ? '$mins دقيقة' : '$mins min';
    }
  }

  String _highwayName(bool isAr) {
    final dynamicName = _routeDetails.corridorHighway(isArabic: isAr);
    if (dynamicName.isNotEmpty) return dynamicName;
    final fallback = GoogleMapsService.resolveCorridorHighway(
      origin: widget.ride.fromCity,
      destination: widget.ride.toCity,
    );
    return isAr ? fallback.ar : fallback.en;
  }

  String get _originQuery => widget.ride.pickupPoint.trim().isNotEmpty
      ? '${widget.ride.pickupPoint}, ${widget.ride.fromCity}'
      : widget.ride.fromCity;

  String get _destinationQuery => widget.ride.dropoffPoint.trim().isNotEmpty
      ? '${widget.ride.dropoffPoint}, ${widget.ride.toCity}'
      : widget.ride.toCity;

  void _openFullScreenMap(BuildContext context, bool isAr) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenRouteMapModal(
          ride: widget.ride,
          perspective: _perspective,
          originQuery: _originQuery,
          destinationQuery: _destinationQuery,
          initialSatellite: _showSatellite,
          initialStylePreset: _stylePreset,
          initialShowTraffic: _showTraffic,
          enableGps: widget.enableGps,
          navigationMode: widget.navigationMode,
          vehicleMode: MashwarMapVehicleMode.trip,
          distanceKm: _routeDetails.distanceKm,
          durationMinutes: _routeDetails.durationMinutes,
          distance: _distanceKm(isAr),
          duration: _durationFormatted(isAr),
          highway: _highwayName(isAr),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Perspective Switcher Tabs (منظور الراكب vs منظور السائق)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildPerspectiveTab(
                  title: isAr ? 'منظور الراكب' : 'Passenger View',
                  subtitle: isAr ? 'نقطة ركوبك والنزول' : 'Your Pickup & Dropoff',
                  icon: Icons.person_pin_circle_outlined,
                  isSelected: _perspective == RoutePerspective.passenger,
                  onTap: () => setState(() => _perspective = RoutePerspective.passenger),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildPerspectiveTab(
                  title: isAr ? 'منظور السائق' : 'Driver View',
                  subtitle: isAr ? 'مسار القيادة والمحطات' : 'Drive Corridor & Stops',
                  icon: Icons.directions_car_filled_outlined,
                  isSelected: _perspective == RoutePerspective.driver,
                  onTap: () => setState(() => _perspective = RoutePerspective.driver),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Compact Map Layer Toolbar (MASHWAR Live Map / Vector Schematic + Layer + Full-Screen)
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  key: const ValueKey('ride_map_mode_toggle'),
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMapModeChip(
                          selected: _useLiveMap,
                          icon: Icons.map_rounded,
                          label: isAr ? 'خريطة مشوار المباشرة' : 'MASHWAR Live Map',
                          onTap: () => setState(() => _useLiveMap = true),
                        ),
                        const SizedBox(width: 3),
                        _buildMapModeChip(
                          selected: !_useLiveMap,
                          icon: Icons.timeline_rounded,
                          label: isAr ? 'مخطط المسار' : 'Schematic',
                          onTap: () =>
                              setState(() => _useLiveMap = false),
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
                  ? (isAr ? 'إخفاء الزحمة الحية' : 'Hide Live Traffic')
                  : (isAr ? 'عرض الزحمة الحية' : 'Show Live Traffic'),
              child: InkWell(
                key: const ValueKey('ride_map_traffic_btn'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() {
                  if (!_useLiveMap) {
                    _useLiveMap = true;
                    _showTraffic = true;
                  } else {
                    _showTraffic = !_showTraffic;
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (_useLiveMap && _showTraffic)
                        ? AppColors.tealSurface
                        : AppColors.slateBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_useLiveMap && _showTraffic)
                          ? AppColors.teal.withValues(alpha: 0.45)
                          : AppColors.slateBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.traffic_rounded,
                    size: 16,
                    color: (_useLiveMap && _showTraffic)
                        ? AppColors.tealDark
                        : AppColors.navy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message:
                  '${isAr ? 'طبقة الخريطة' : 'Map Layer'}: ${_rideMapStyleLabel(_stylePreset, isAr)}',
              child: InkWell(
                key: const ValueKey('ride_map_satellite_btn'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() {
                  _useLiveMap = true;
                  _stylePreset = _nextRideMapStyle(_stylePreset);
                }),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _stylePreset != MashwarMapStylePreset.standard
                        ? AppColors.tealSurface
                        : AppColors.slateBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _stylePreset != MashwarMapStylePreset.standard
                          ? AppColors.teal.withValues(alpha: 0.45)
                          : AppColors.slateBorder,
                    ),
                  ),
                  child: Icon(
                    _rideMapStyleIcon(_stylePreset),
                    size: 16,
                    color: _stylePreset != MashwarMapStylePreset.standard
                        ? AppColors.tealDark
                        : AppColors.navy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: isAr ? 'تكبير الخريطة ملء الشاشة' : 'Full-Screen Map',
              child: InkWell(
                key: const ValueKey('ride_map_expand_btn'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openFullScreenMap(context, isAr),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    size: 16,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2b. Main 290px Map Container (MASHWAR Live Embedded Map default + Animated Vector Schematic option)
        Container(
          height: 290,
          decoration: BoxDecoration(
            color: _isDarkSchematic
                ? const Color(0xFF1E2833)
                : const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            child: _useLiveMap
                ? MashwarEmbeddedGoogleMap(
                    origin: _originQuery,
                    destination: _destinationQuery,
                    stopover: widget.ride.stopoverCity,
                    satellite: _showSatellite,
                    stylePreset: _stylePreset,
                    vehicleMode: MashwarMapVehicleMode.trip,
                    showTraffic: _showTraffic,
                    enableGps: widget.enableGps,
                    navigationMode: widget.navigationMode,
                    distanceKm: _routeDetails.distanceKm,
                    durationMinutes: _routeDetails.durationMinutes,
                    highwayName: _highwayName(isAr),
                    height: 290,
                    borderRadius: AppDimens.radiusCard,
                    interactive: true,
                  )
                : Stack(
                    children: [
                      // Animated Vector Map Drawing
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _routeAnimController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _AccurateRouteMapPainter(
                                perspective: _perspective,
                                isSatellite: _isDarkSchematic,
                                fromCity: widget.ride.fromCity,
                                toCity: widget.ride.toCity,
                                pickupPoint: widget.ride.pickupPoint,
                                dropoffPoint: widget.ride.dropoffPoint,
                                isAr: isAr,
                                animationProgress: _routeAnimController.value,
                              ),
                            );
                          },
                        ),
                      ),

                      // Top Info Bar: Highway & Live Traffic Badge
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.route_rounded,
                                      size: 13,
                                      color: AppColors.teal,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${_distanceKm(isAr)} · ${_durationFormatted(isAr)}',
                                        style: AppTypography.label(
                                          color: AppColors.navy,
                                        ).copyWith(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAr ? 'سالك' : 'Clear',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Floating Map Action Buttons (Expand & Layer Toggle)
                      Positioned(
                        bottom: 10,
                        left: isAr ? 10 : null,
                        right: isAr ? null : 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFloatingMapButton(
                              icon: _rideMapStyleIcon(_stylePreset),
                              tooltip: isAr
                                  ? 'تبديل طبقة الخريطة'
                                  : 'Toggle Layer',
                              onTap: () => setState(
                                () => _stylePreset =
                                    _nextRideMapStyle(_stylePreset),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildFloatingMapButton(
                              icon: Icons.fullscreen_rounded,
                              tooltip: isAr
                                  ? 'تكبير الخريطة للشاشة الكاملة'
                                  : 'Full Screen Map',
                              onTap: () => _openFullScreenMap(context, isAr),
                            ),
                          ],
                        ),
                      ),

                      // Perspective Floating Pin Summary Card
                      Positioned(
                        bottom: 10,
                        right: isAr ? 10 : null,
                        left: isAr ? null : 10,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 210),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE5E5EA),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _perspective == RoutePerspective.passenger
                                    ? Icons.hail_rounded
                                    : Icons.navigation_rounded,
                                size: 16,
                                color:
                                    _perspective == RoutePerspective.passenger
                                        ? AppColors.teal
                                        : AppColors.navy,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _perspective == RoutePerspective.passenger
                                      ? (isAr
                                          ? 'نقطة الركوب محددة بدقة'
                                          : 'Pickup spot calibrated')
                                      : (isAr
                                          ? 'مسار الطريق السريع ومحطات التجمع'
                                          : 'Highway route & stops'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),

        // 2c. Dynamic Corridor Bar + 1-Tap Full-Screen In-App Route Map Action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slateBorder),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.alt_route_rounded,
                    size: 16,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Text(
                      '${_distanceKm(isAr)} · ${_durationFormatted(isAr)} · ${_highwayName(isAr)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                key: const ValueKey('ride_map_open_gmaps_btn'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  backgroundColor: AppColors.slateBg,
                  side: const BorderSide(color: AppColors.slateBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => openMashwarInAppMap(
                  context,
                  origin: _originQuery,
                  destination: _destinationQuery,
                  stopover: widget.ride.stopoverCity,
                  initialSatellite: _showSatellite,
                  stylePreset: _stylePreset,
                  vehicleMode: MashwarMapVehicleMode.trip,
                  showTraffic: _showTraffic,
                  enableGps: true,
                  navigationMode: widget.navigationMode,
                  titleAr: 'مسار الرحلة المباشر',
                  titleEn: 'Live Trip Route Map',
                ),
                icon: const Icon(
                  Icons.open_in_full_rounded,
                  size: 15,
                  color: AppColors.teal,
                ),
                label: Text(
                  isAr ? 'عرض المسار ملء الشاشة' : 'Full-Screen Route Map',
                  style: AppTypography.label(color: AppColors.navy).copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. Perspective-Specific Guidance Card
        _buildPerspectiveGuidanceCard(isAr),
        const SizedBox(height: 10),

        // 4. Detailed Route Milestones (Step-by-Step Waypoints)
        Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.timeline_rounded, size: 18, color: AppColors.navy),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isAr ? 'المسار ومحطات التوقف' : 'Route & Waypoints',
                            style: AppTypography.title().copyWith(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => setState(() => _isRouteExpanded = !_isRouteExpanded),
                    icon: Icon(
                      _isRouteExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.teal,
                    ),
                    label: Text(
                      _isRouteExpanded ? (isAr ? 'طي' : 'Collapse') : (isAr ? 'عرض التفاصيل' : 'Details'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.teal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Milestone Timeline
              _buildMilestoneItem(
                time: '${widget.ride.departureTime} (-15 د)',
                title: isAr ? 'انطلاق السائق' : 'Driver Departure',
                location: isAr ? '${widget.ride.fromCity} (وسط المدينة)' : '${widget.ride.fromCity} Center',
                isHighlighted: _perspective == RoutePerspective.driver,
                roleTag: _perspective == RoutePerspective.driver ? (isAr ? 'بداية خط السير' : 'Start Point') : null,
                icon: Icons.trip_origin_rounded,
                iconColor: AppColors.navy,
                isFirst: true,
              ),

              _buildMilestoneItem(
                time: widget.ride.departureTime,
                title: isAr ? 'نقطة ركوب الراكب' : 'Passenger Pickup Spot',
                location: widget.ride.pickupPoint,
                isHighlighted: _perspective == RoutePerspective.passenger,
                roleTag: isAr ? 'مكان تجمعك الدقيق' : 'Your Calibrated Spot',
                note: _perspective == RoutePerspective.passenger
                    ? (isAr ? 'يبعد 4 دقائق مشياً · التواجد بالجانب الأيمن المضاء' : '4 mins walk · Wait in safe lit area')
                    : (isAr ? 'توقف سهل ومسموح لمدة 5 دقائق لركوب الراكب' : 'Safe 5-min stopping bay for pickup'),
                icon: Icons.person_pin_circle_rounded,
                iconColor: AppColors.teal,
              ),

              if (_isRouteExpanded) ..._buildDynamicIntermediateMilestones(isAr),

              _buildMilestoneItem(
                time: isAr ? 'الوقت المقدر' : 'Estimated Arrival',
                title: isAr ? 'نقطة نزول الراكب' : 'Passenger Dropoff Spot',
                location: widget.ride.dropoffPoint,
                isHighlighted: true,
                roleTag: isAr ? 'وجهة الوصول' : 'Destination',
                note: isAr ? 'بجوار محطة المترو أو الدوار الرئيسي لتسهيل استكمال مشوارك' : 'Close to main Metro exit for connection',
                icon: Icons.location_on_rounded,
                iconColor: AppColors.danger,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerspectiveTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navy : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.navy : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? AppColors.teal : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapModeChip({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
              size: 13.5,
              color: selected ? AppColors.teal : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.label(
                color: selected ? AppColors.navy : AppColors.textSecondary,
              ).copyWith(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: AppColors.navy),
          ),
        ),
      ),
    );
  }

  Widget _buildPerspectiveGuidanceCard(bool isAr) {
    if (_perspective == RoutePerspective.passenger) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_walk_rounded, color: Color(0xFF15803D), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'إرشادات الراكب للوصول لمكان التجمع' : 'Passenger Boarding Instructions',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF14532D)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr
                        ? 'مكان الركوب: "${widget.ride.pickupPoint}". على بُعد 350 متر من مركز التجمع. يُرجى التواجد قبل الموعد بـ 5 دقائق.'
                        : 'Pickup: "${widget.ride.pickupPoint}". 350m from hub. Please arrive 5 minutes prior.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.alt_route_rounded, color: Color(0xFF0369A1), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'إرشادات القيادة ومسار السائق' : 'Driver Route & Pickups',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF075985)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr
                        ? 'المسار الموصى به: ${_highwayName(true)}. نقطة التوقف المحددة لالتقاط الراكب بمساحة ركن سهلة وآمنة.'
                        : 'Recommended corridor: ${_highwayName(false)}. Clear pull-over bay for safe passenger boarding.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0C4A6E)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  List<Widget> _buildDynamicIntermediateMilestones(bool isAr) {
    final origHub = GoogleMapsService.resolveHubEntry(widget.ride.fromCity);
    final destHub = GoogleMapsService.resolveHubEntry(widget.ride.toCity);
    final zones = <String>{
      if (origHub != null) origHub.zoneCode,
      if (destHub != null) destHub.zoneCode,
    };

    if (zones.contains('north_coast') || zones.contains('north')) {
      return [
        _buildMilestoneItem(
          time: isAr ? '+15 دقيقة' : '+15 mins',
          title: isAr
              ? 'محور لوسيل / بوابة الشمال'
              : 'Lusail Expressway / North Gate',
          location: isAr
              ? 'مخرج لوسيل واستاد البيت السريع'
              : 'Lusail & Al Bayt Express Exit',
          icon: Icons.alt_route_rounded,
          iconColor: const Color(0xFF64748B),
        ),
        _buildMilestoneItem(
          time: isAr ? '+30 دقيقة' : '+30 mins',
          title: isAr
              ? 'طريق الخور الساحلي السريع'
              : 'Al Khor Coastal Highway',
          location: isAr
              ? 'تقاطع سميسمة - مخرج الخور الجنوبي'
              : 'Simaisma Interchange - South Al Khor Exit',
          icon: Icons.toll_rounded,
          iconColor: const Color(0xFF64748B),
        ),
      ];
    }

    final halfMins = math.max(8, _routeDetails.durationMinutes ~/ 2);
    return [
      _buildMilestoneItem(
        time: isAr ? '+$halfMins دقيقة' : '+$halfMins mins',
        title: _highwayName(isAr),
        location: isAr
            ? '${context.trCity(widget.ride.fromCity)} ↔ ${context.trCity(widget.ride.toCity)}'
            : '${context.trCity(widget.ride.fromCity)} ↔ ${context.trCity(widget.ride.toCity)}',
        icon: Icons.alt_route_rounded,
        iconColor: const Color(0xFF64748B),
      ),
    ];
  }

  Widget _buildMilestoneItem({
    required String time,
    required String title,
    required String location,
    required IconData icon,
    required Color iconColor,
    bool isHighlighted = false,
    String? roleTag,
    String? note,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline bar & dot
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 10,
                    color: const Color(0xFFE5E5EA),
                  ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isHighlighted ? iconColor.withValues(alpha: 0.15) : const Color(0xFFF3F3F4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHighlighted ? iconColor : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, size: 12, color: iconColor),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE5E5EA),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                                color: isHighlighted ? AppColors.navy : const Color(0xFF334155),
                              ),
                            ),
                            if (roleTag != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isHighlighted ? iconColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  roleTag,
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: iconColor),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isHighlighted ? AppColors.navy : const Color(0xFF475569),
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                      ),
                      child: Text(
                        note,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accurate Vector Qatar Route Painter with animated cruising vehicle & bay coastline
class _AccurateRouteMapPainter extends CustomPainter {
  final RoutePerspective perspective;
  final bool isSatellite;
  final String fromCity;
  final String toCity;
  final String pickupPoint;
  final String dropoffPoint;
  final bool isAr;
  final double animationProgress;

  _AccurateRouteMapPainter({
    required this.perspective,
    required this.isSatellite,
    required this.fromCity,
    required this.toCity,
    required this.pickupPoint,
    required this.dropoffPoint,
    required this.isAr,
    this.animationProgress = 0.42,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Background Land & Subtle Street Blocks
    final canvasRect = Rect.fromLTWH(0, 0, w, h);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isSatellite
            ? const [Color(0xFF0E2133), Color(0xFF162F47)]
            : const [Color(0xFFFBF8F1), Color(0xFFF3EFE4)],
      ).createShader(canvasRect);
    canvas.drawRect(canvasRect, bgPaint);

    // Subtle urban city blocks
    final gridPaint = Paint()
      ..color = isSatellite ? Colors.white.withValues(alpha: 0.045) : const Color(0xFFE4DED0)
      ..strokeWidth = 0.9;

    for (double x = 22; x < w; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 22; y < h; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Lush Qatar urban greenery & park patches
    final parkPaint = Paint()
      ..color = isSatellite
          ? AppColors.teal.withValues(alpha: 0.14)
          : const Color(0xFFDDF0E2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.10, h * 0.58, w * 0.14, h * 0.18), const Radius.circular(14)),
      parkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.46, h * 0.25), width: w * 0.12, height: h * 0.12),
      parkPaint,
    );

    // 2. Arabian Gulf Coastline & Doha Corniche Bay Filled Polygon
    final gulfWater = Path()
      ..moveTo(w * 0.56, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.62)
      ..quadraticBezierTo(w * 0.84, h * 0.56, w * 0.78, h * 0.40)
      ..quadraticBezierTo(w * 0.72, h * 0.24, w * 0.56, 0)
      ..close();
    canvas.drawPath(
      gulfWater,
      Paint()
        ..color = isSatellite
            ? const Color(0xFF072238)
            : const Color(0xFFD0E8F6),
    );
    canvas.drawPath(
      gulfWater,
      Paint()
        ..color = isSatellite
            ? AppColors.teal.withValues(alpha: 0.4)
            : const Color(0xFF9AC5DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // 3. Secondary Qatari Road Connectors (Dual casing)
    final secPath1 = Path()
      ..moveTo(0, h * 0.42)
      ..cubicTo(w * 0.28, h * 0.36, w * 0.68, h * 0.66, w, h * 0.62);
    canvas.drawPath(
      secPath1,
      Paint()
        ..color = isSatellite ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFD4DCE6)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      secPath1,
      Paint()
        ..color = isSatellite ? const Color(0xFF1F3B57) : Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 4. Main Highway Route Polyline (Qatar Coastal & Expressway corridor)
    final startOffset = Offset(w * 0.16, h * 0.28);  // e.g. Doha / Msheireb
    final pickupOffset = Offset(w * 0.32, h * 0.39); // Passenger pickup spot
    final waypoint1 = Offset(w * 0.51, h * 0.52);    // Lusail junction
    final waypoint2 = Offset(w * 0.69, h * 0.65);    // Simaisma corridor
    final dropoffOffset = Offset(w * 0.84, h * 0.78); // Destination entrance / Dropoff

    final routePath = Path();
    routePath.moveTo(startOffset.dx, startOffset.dy);
    routePath.lineTo(pickupOffset.dx, pickupOffset.dy);
    routePath.cubicTo(w * 0.42, h * 0.46, waypoint1.dx, waypoint1.dy, waypoint1.dx, waypoint1.dy);
    routePath.cubicTo(w * 0.59, h * 0.58, waypoint2.dx, waypoint2.dy, waypoint2.dx, waypoint2.dy);
    routePath.lineTo(dropoffOffset.dx, dropoffOffset.dy);

    final activeColor = perspective == RoutePerspective.passenger ? AppColors.teal : AppColors.navy;

    // Soft glowing halo around active route
    canvas.drawPath(
      routePath,
      Paint()
        ..color = activeColor.withValues(alpha: isSatellite ? 0.38 : 0.20)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Outer casing
    canvas.drawPath(
      routePath,
      Paint()
        ..color = AppColors.navy.withValues(alpha: 0.45)
        ..strokeWidth = 7.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Inner route polyline
    canvas.drawPath(
      routePath,
      Paint()
        ..color = activeColor
        ..strokeWidth = 4.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Animated white directional flow dashes along route
    final metrics = routePath.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final totalLen = metric.length;
      const double dash = 9.0;
      const double gap = 15.0;
      final double phaseOffset = (animationProgress * (dash + gap) * 6) % (dash + gap);
      final dashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (double d = phaseOffset; d < totalLen; d += dash + gap) {
        final end = math.min(d + dash, totalLen);
        canvas.drawPath(metric.extractPath(d, end), dashPaint);
      }

      // Smoothly Gliding Driver Vehicle along active corridor
      final carT = perspective == RoutePerspective.passenger
          ? (0.14 + (animationProgress * 0.55) % 0.72)
          : (animationProgress % 1.0);
      final carDist = (totalLen * carT).clamp(0.0, totalLen);
      final tangent = metric.getTangentForOffset(carDist);
      if (tangent != null) {
        final angle = math.atan2(-tangent.vector.dy, tangent.vector.dx);
        _drawCruisingCar(canvas, tangent.position, angle, isSatellite);
      }
    }

    // 5. Drawing Specific Pins based on Perspective
    final pulse = (math.sin(animationProgress * math.pi * 2) + 1) / 2;
    if (perspective == RoutePerspective.passenger) {
      // Walking dashed line to pickup spot
      final walkStart = Offset(pickupOffset.dx - 24, pickupOffset.dy + 20);
      final walkPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(walkStart, pickupOffset, walkPaint);

      // Walking dot (user standing)
      canvas.drawCircle(walkStart, 5, Paint()..color = const Color(0xFF10B981));
      canvas.drawCircle(walkStart, 2.2, Paint()..color = Colors.white);

      // Animated Concentric Radar Halo on Passenger Pickup Spot
      canvas.drawCircle(
        pickupOffset,
        11 + pulse * 10,
        Paint()..color = AppColors.teal.withValues(alpha: (1 - pulse) * 0.35),
      );
      canvas.drawCircle(pickupOffset, 10, Paint()..color = Colors.white);
      canvas.drawCircle(pickupOffset, 7, Paint()..color = AppColors.teal);
      canvas.drawCircle(pickupOffset, 2.8, Paint()..color = Colors.white);

      // Dropoff Spot (Red / Navy Pin)
      canvas.drawCircle(dropoffOffset, 13, Paint()..color = AppColors.danger.withValues(alpha: 0.22));
      canvas.drawCircle(dropoffOffset, 7.5, Paint()..color = AppColors.danger);
      canvas.drawCircle(dropoffOffset, 3.2, Paint()..color = Colors.white);
    } else {
      // DRIVER PERSPECTIVE:
      // Driver starting pin
      canvas.drawCircle(startOffset, 9, Paint()..color = Colors.white);
      canvas.drawCircle(startOffset, 7, Paint()..color = AppColors.navy);
      canvas.drawCircle(startOffset, 3, Paint()..color = AppColors.gold);

      // Designated stopping bay rect around pickup spot
      final bayRect = Rect.fromCenter(center: pickupOffset, width: 30, height: 19);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bayRect, const Radius.circular(5)),
        Paint()
          ..color = AppColors.teal.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bayRect, const Radius.circular(5)),
        Paint()
          ..color = AppColors.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(pickupOffset, 4.2, Paint()..color = AppColors.teal);

      // Waypoint 1 (Lusail stop)
      canvas.drawCircle(waypoint1, 5.5, Paint()..color = const Color(0xFF64748B));
      canvas.drawCircle(waypoint1, 2.2, Paint()..color = Colors.white);

      // Dropoff & Destination pin
      canvas.drawCircle(dropoffOffset, 9, Paint()..color = Colors.white);
      canvas.drawCircle(dropoffOffset, 7.5, Paint()..color = AppColors.danger);
      canvas.drawCircle(dropoffOffset, 3.2, Paint()..color = Colors.white);
    }

    // 6. Clean Pill-Framed City Geographic Labels on Canvas
    _drawCityLabel(canvas, fromCity, Offset(startOffset.dx, startOffset.dy - 19), isSatellite, isOrigin: true);
    _drawCityLabel(canvas, isAr ? 'لوسيل' : 'Lusail', Offset(waypoint1.dx + 12, waypoint1.dy - 14), isSatellite);
    _drawCityLabel(canvas, toCity, Offset(dropoffOffset.dx - 16, dropoffOffset.dy - 20), isSatellite, isDest: true);
  }

  void _drawCruisingCar(Canvas canvas, Offset pos, double angleRad, bool isDark) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angleRad);

    // Subtle headlight cone
    final beam = Path()
      ..moveTo(8, -2.5)
      ..lineTo(22, -7)
      ..lineTo(22, 7)
      ..lineTo(8, 2.5)
      ..close();
    canvas.drawPath(
      beam,
      Paint()..color = AppColors.gold.withValues(alpha: isDark ? 0.34 : 0.22),
    );

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -5, 21, 12), const Radius.circular(4.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.26),
    );

    // Sleek vehicle body
    const body = Rect.fromLTWH(-10, -5.8, 20, 11.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(4.5)),
      Paint()..color = isDark ? Colors.white : AppColors.navy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(4.5)),
      Paint()
        ..color = isDark ? AppColors.gold : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Cabin windshield + MASHWAR gold roof badge
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4.5, -3.8, 10, 7.6), const Radius.circular(2.5)),
      Paint()..color = isDark ? AppColors.navy : const Color(0xFF284D70),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-1.5, -2.0, 4, 4), const Radius.circular(1.2)),
      Paint()..color = AppColors.gold,
    );

    canvas.restore();
  }

  void _drawCityLabel(
    Canvas canvas,
    String text,
    Offset center,
    bool isDark, {
    bool isOrigin = false,
    bool isDest = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: (isOrigin || isDest)
              ? Colors.white
              : (isDark ? Colors.white : AppColors.navy),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          fontFamily: 'Cairo',
        ),
      ),
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
    )..layout();

    final pillW = tp.width + 14;
    final pillH = tp.height + 6;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: pillW, height: pillH),
      const Radius.circular(8),
    );
    final fillColor = isOrigin
        ? AppColors.teal
        : (isDest
            ? AppColors.navy
            : (isDark ? const Color(0xFF0B1F33).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.95)));
    canvas.drawRRect(rect, Paint()..color = fillColor);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = (isOrigin || isDest) ? Colors.white.withValues(alpha: 0.85) : const Color(0xFFDDE3EC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AccurateRouteMapPainter oldDelegate) {
    return oldDelegate.perspective != perspective ||
        oldDelegate.isSatellite != isSatellite ||
        oldDelegate.fromCity != fromCity ||
        oldDelegate.toCity != toCity ||
        oldDelegate.isAr != isAr ||
        oldDelegate.animationProgress != animationProgress;
  }
}

/// Fullscreen Interactive In-App MASHWAR Live Map & Route Modal
class _FullScreenRouteMapModal extends StatefulWidget {
  final RideModel ride;
  final RoutePerspective perspective;
  final String originQuery;
  final String destinationQuery;
  final bool initialSatellite;
  final MashwarMapStylePreset? initialStylePreset;
  final bool initialShowTraffic;
  final bool enableGps;
  final bool navigationMode;
  final MashwarMapVehicleMode vehicleMode;
  final double? distanceKm;
  final int? durationMinutes;
  final String distance;
  final String duration;
  final String highway;

  const _FullScreenRouteMapModal({
    required this.ride,
    required this.perspective,
    required this.originQuery,
    required this.destinationQuery,
    required this.initialSatellite,
    this.initialStylePreset,
    this.initialShowTraffic = true,
    this.enableGps = false,
    this.navigationMode = false,
    this.vehicleMode = MashwarMapVehicleMode.trip,
    this.distanceKm,
    this.durationMinutes,
    required this.distance,
    required this.duration,
    required this.highway,
  });

  @override
  State<_FullScreenRouteMapModal> createState() => _FullScreenRouteMapModalState();
}

class _FullScreenRouteMapModalState extends State<_FullScreenRouteMapModal>
    with SingleTickerProviderStateMixin {
  late RoutePerspective _currentPerspective;
  bool _useLiveMap = true;
  late MashwarMapStylePreset _stylePreset;
  late bool _showTraffic;
  final TransformationController _transformController = TransformationController();
  late final AnimationController _modalAnimController;

  bool get _isSat => _stylePreset == MashwarMapStylePreset.satellite;
  bool get _isDarkSchematic =>
      _stylePreset == MashwarMapStylePreset.satellite ||
      _stylePreset == MashwarMapStylePreset.night;

  @override
  void initState() {
    super.initState();
    _currentPerspective = widget.perspective;
    _stylePreset = widget.initialStylePreset ??
        (widget.initialSatellite
            ? MashwarMapStylePreset.satellite
            : MashwarMapStylePreset.standard);
    _showTraffic = widget.initialShowTraffic;
    _modalAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    if (mashwarShouldAnimateContinuous()) {
      _modalAnimController.repeat();
    } else {
      _modalAnimController.value = 0.42;
    }
  }

  @override
  void dispose() {
    _modalAnimController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'الخريطة الكاملة للمسار' : 'Full Route Map',
              style: AppTypography.title().copyWith(fontSize: 16),
            ),
            Text(
              '${widget.ride.fromCity} ↔ ${widget.ride.toCity}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.traffic_rounded,
              color: (_useLiveMap && _showTraffic)
                  ? AppColors.teal
                  : AppColors.navy,
            ),
            tooltip: _showTraffic
                ? (isAr ? 'إخفاء الزحمة الحية' : 'Hide Live Traffic')
                : (isAr ? 'عرض الزحمة الحية' : 'Show Live Traffic'),
            onPressed: () => setState(() {
              _useLiveMap = true;
              _showTraffic = !_showTraffic;
            }),
          ),
          IconButton(
            icon: Icon(
              _useLiveMap ? Icons.timeline_rounded : Icons.map_rounded,
              color: AppColors.navy,
            ),
            tooltip: _useLiveMap
                ? (isAr ? 'عرض المخطط التفاعلي' : 'View Schematic')
                : (isAr ? 'عرض خريطة مشوار المباشرة' : 'View MASHWAR Live Map'),
            onPressed: () =>
                setState(() => _useLiveMap = !_useLiveMap),
          ),
          IconButton(
            icon: Icon(
              _rideMapStyleIcon(_stylePreset),
              color: _stylePreset != MashwarMapStylePreset.standard
                  ? AppColors.teal
                  : AppColors.navy,
            ),
            tooltip:
                '${isAr ? 'طبقة الخريطة' : 'Map Layer'}: ${_rideMapStyleLabel(_stylePreset, isAr)}',
            onPressed: () => setState(() {
              _useLiveMap = true;
              _stylePreset = _nextRideMapStyle(_stylePreset);
            }),
          ),
          if (!_useLiveMap)
            IconButton(
              icon: const Icon(Icons.center_focus_strong_rounded, color: AppColors.navy),
              tooltip: isAr ? 'إعادة ضبط المنظور' : 'Recenter',
              onPressed: () => _transformController.value = Matrix4.identity(),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Perspective Switcher in Modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentPerspective = RoutePerspective.passenger),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentPerspective == RoutePerspective.passenger ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              isAr ? 'منظور الراكب' : 'Passenger View',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _currentPerspective == RoutePerspective.passenger ? FontWeight.bold : FontWeight.normal,
                                color: _currentPerspective == RoutePerspective.passenger ? AppColors.navy : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentPerspective = RoutePerspective.driver),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentPerspective == RoutePerspective.driver ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              isAr ? 'منظور السائق' : 'Driver View',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _currentPerspective == RoutePerspective.driver ? FontWeight.bold : FontWeight.normal,
                                color: _currentPerspective == RoutePerspective.driver ? AppColors.navy : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Full-Screen MASHWAR Live Map (default) or Zoomable Schematic Canvas
            Expanded(
              child: _useLiveMap
                  ? MashwarEmbeddedGoogleMap(
                      origin: widget.originQuery,
                      destination: widget.destinationQuery,
                      stopover: widget.ride.stopoverCity,
                      satellite: _isSat,
                      stylePreset: _stylePreset,
                      vehicleMode: widget.vehicleMode,
                      showTraffic: _showTraffic,
                      enableGps: true,
                      navigationMode: widget.navigationMode,
                      distanceKm: widget.distanceKm,
                      durationMinutes: widget.durationMinutes,
                      highwayName: widget.highway,
                      zoom: 11,
                      height: double.infinity,
                      borderRadius: 0,
                      interactive: true,
                    )
                  : InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1.1,
                          child: AnimatedBuilder(
                            animation: _modalAnimController,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _AccurateRouteMapPainter(
                                  perspective: _currentPerspective,
                                  isSatellite: _isDarkSchematic,
                                  fromCity: widget.ride.fromCity,
                                  toCity: widget.ride.toCity,
                                  pickupPoint: widget.ride.pickupPoint,
                                  dropoffPoint: widget.ride.dropoffPoint,
                                  isAr: isAr,
                                  animationProgress: _modalAnimController.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),

            // Bottom Floating Route Summary Card
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E5EA), width: 0.8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.highway,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.navy),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.distance} · ${widget.duration}',
                              style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        key: const ValueKey('ride_fullscreen_open_gmaps_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(
                          _rideMapStyleIcon(_stylePreset),
                          size: 16,
                        ),
                        label: Text(
                          _rideMapStyleLabel(_stylePreset, isAr),
                        ),
                        onPressed: () => setState(() {
                          _useLiveMap = true;
                          _stylePreset = _nextRideMapStyle(_stylePreset);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
