import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_embedded_google_map.dart';
import '../../core/widgets/mashwar_google_map_panel.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/ride_model.dart';
import '../../data/services/google_maps_service.dart';
import '../../state/rides_provider.dart';
import '../booking/cancellation_sheet.dart';
import '../chat/chat_screen.dart';
import '../ride_details/widgets/ride_route_map_view.dart';
import '../safety/safety_screens.dart';
import 'rate_trip_screen.dart';

enum TripTrackingPhase {
  preTrip, // قبل الرحلة
  inTransit, // أثناء الرحلة
  completed, // مكتمل
}

class ActiveTripScreen extends StatefulWidget {
  @visibleForTesting
  static Future<bool> Function(Uri uri)? debugUrlLauncher;

  const ActiveTripScreen({
    super.key,
    required this.ride,
    this.initialPhase,
  });

  final RideModel ride;
  final TripTrackingPhase? initialPhase;

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late TripTrackingPhase _phase;

  @override
  void initState() {
    super.initState();
    _phase = widget.initialPhase ??
        (widget.ride.status == 'completed'
            ? TripTrackingPhase.completed
            : TripTrackingPhase.preTrip);
  }

  RideModel _resolveLiveRide(BuildContext context) {
    final rides = Provider.of<RidesProvider?>(context);
    if (rides == null) return widget.ride;
    for (final candidate in [
      ...rides.bookedRides,
      ...rides.allRides,
      ...rides.myPublishedRides,
    ]) {
      if (candidate.id == widget.ride.id) {
        return candidate;
      }
    }
    return widget.ride;
  }

  static String _normalizeDialPhone(String raw) {
    final compact = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
    if (compact.isEmpty) return '+97455234567';
    if (compact.startsWith('+')) return compact;
    if (compact.startsWith('00974')) return '+${compact.substring(2)}';
    if (compact.length == 8 && RegExp(r'^[3567][0-9]{7}$').hasMatch(compact)) {
      return '+974$compact';
    }
    return compact;
  }

  String _buildGoogleMapsDirectionsUrl(RideModel ride) {
    final origin = ride.pickupPoint.trim().isNotEmpty
        ? '${ride.pickupPoint.trim()}, ${ride.fromCity.trim()}, Qatar'
        : '${ride.fromCity.trim()}, Qatar';
    final destination = ride.dropoffPoint.trim().isNotEmpty
        ? '${ride.dropoffPoint.trim()}, ${ride.toCity.trim()}, Qatar'
        : '${ride.toCity.trim()}, Qatar';
    final buffer = StringBuffer(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${Uri.encodeComponent(origin)}'
      '&destination=${Uri.encodeComponent(destination)}',
    );
    if (ride.stopoverCity != null && ride.stopoverCity!.trim().isNotEmpty) {
      buffer.write(
        '&waypoints=${Uri.encodeComponent('${ride.stopoverCity!.trim()}, Qatar')}',
      );
    }
    buffer.write('&travelmode=driving');
    return buffer.toString();
  }

  Future<void> _callDriver(
    BuildContext context,
    RideModel ride,
    bool isAr,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final dialPath = _normalizeDialPhone(ride.driverPhone);
    final uri = Uri(scheme: 'tel', path: dialPath);
    bool launched = false;
    try {
      final override = ActiveTripScreen.debugUrlLauncher;
      launched = override != null
          ? await override(uri)
          : await launchMashwarExternalUri(uri);
    } catch (_) {
      launched = false;
    }

    if (!launched) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تعذّر فتح تطبيق الهاتف تلقائياً. اتصل بالسائق على $dialPath'
                : 'Dialer unavailable on this device. Call driver at $dialPath',
          ),
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  Future<void> _openGoogleMapsNavigation(
    BuildContext context,
    RideModel ride,
    bool isAr,
  ) async {
    final override = ActiveTripScreen.debugUrlLauncher;
    if (override != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final url = _buildGoogleMapsDirectionsUrl(ride);
      final uri = Uri.parse(url);
      bool launched = false;
      try {
        launched = await override(uri);
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        await Clipboard.setData(ClipboardData(text: url));
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم نسخ رابط الملاحة في Google Maps إلى الحافظة'
                  : 'Google Maps navigation link copied to clipboard',
            ),
            backgroundColor: AppColors.navy,
          ),
        );
      }
      return;
    }

    final effectiveOrigin =
        ride.pickupPoint.trim().isNotEmpty ? ride.pickupPoint : ride.fromCity;
    final effectiveDest =
        ride.dropoffPoint.trim().isNotEmpty ? ride.dropoffPoint : ride.toCity;
    await openMashwarInAppMap(
      context,
      origin: effectiveOrigin,
      destination: effectiveDest,
      stopover: ride.stopoverCity,
      vehicleMode: MashwarMapVehicleMode.trip,
      showTraffic: true,
      titleAr: 'مسار الرحلة · ${ride.fromCity} ← ${ride.toCity}',
      titleEn: 'Trip Route · ${ride.fromCity} → ${ride.toCity}',
    );
  }

  void _completeTrip(BuildContext context, RideModel ride) {
    Provider.of<RidesProvider?>(context, listen: false)?.completeRide(
      ride.id,
      fallbackRide: ride,
    );
    setState(() => _phase = TripTrackingPhase.completed);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final ride = _resolveLiveRide(context);
    switch (_phase) {
      case TripTrackingPhase.preTrip:
        return _buildPreTripView(context, ride, isAr);
      case TripTrackingPhase.inTransit:
        return _buildInTransitView(context, ride, isAr);
      case TripTrackingPhase.completed:
        return _buildCompletedView(context, ride, isAr);
    }
  }

  Widget _buildDriverIdentityCard(RideModel ride, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Row(
        children: [
          MashwarUserAvatar(
            key: const ValueKey('active_trip_driver_avatar'),
            avatarUrl: null,
            fullName: ride.driverName,
            size: 48,
            borderWidth: 1.5,
            borderColor: AppColors.slateBorder,
            autoCommunityPortrait: true,
            showVerifiedBadge: ride.isVerified,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ride.driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: AppColors.goldDark,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            ride.driverRating.toStringAsFixed(1),
                            style: AppTypography.label(color: AppColors.navy)
                                .copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ride.driverCar,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySecondary(),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('active_trip_quick_call_btn'),
            tooltip: isAr ? 'اتصل بالسائق' : 'Call Driver',
            icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.teal),
            onPressed: () => _callDriver(context, ride, isAr),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapsButton(BuildContext context, RideModel ride, bool isAr) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const ValueKey('active_trip_open_gmaps_btn'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.slateBorder),
          minimumSize: const Size(double.infinity, AppDimens.secondaryButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
        ),
        onPressed: () => _openGoogleMapsNavigation(context, ride, isAr),
        icon: const Icon(Icons.map_outlined, size: 18, color: AppColors.teal),
        label: Text(
          isAr ? 'تكبير خريطة الملاحة داخل التطبيق' : 'Open Live Map In-App',
          style: AppTypography.button(color: AppColors.navy).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // Phase 1: قبل الرحلة
  Widget _buildPreTripView(BuildContext context, RideModel ride, bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'الحجز وتفاصيل الرحلة' : 'Booking & Trip',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: TextButton(
              key: const ValueKey('active_trip_live_tab_btn'),
              onPressed: () =>
                  setState(() => _phase = TripTrackingPhase.inTransit),
              child: Text(
                isAr ? 'التتبع المباشر' : 'Live Map',
                style: AppTypography.label(color: AppColors.teal)
                    .copyWith(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space12,
              ),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${context.trDate(ride.departureDate)}${isAr ? "، " : ", "}${context.trDate(ride.departureTime)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySecondary(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MashwarBadge(
                          type: BadgeType.confirmed,
                          customLabel: isAr ? 'مؤكد' : 'Confirmed',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Executive Navy Countdown Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.navy, Color(0xFF173D61)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'تبدأ الرحلة خلال' : 'Trip starts in',
                                  style: AppTypography.label(
                                    color: AppColors.gold,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAr ? '3 ساعات' : '3 Hours',
                                  style: AppTypography.largeTitle(
                                    color: Colors.white,
                                  ).copyWith(fontSize: 26),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.trRoute(
                                    '${ride.fromCity} ← ${ride.toCity}',
                                  ),
                                  style: AppTypography.bodySmall(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          MashwarAssetArt(
                            assetPath: 'assets/images/driver_promo.jpg',
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Driver Card with MashwarUserAvatar
                    _buildDriverIdentityCard(ride, isAr),
                    const SizedBox(height: 12),

                    // Route Timeline Card
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.slateBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.slateBorder),
                            ),
                            child: MashwarRouteTimeline(
                              from: ride.pickupPoint.isNotEmpty
                                  ? ride.pickupPoint
                                  : ride.fromCity,
                              to: ride.dropoffPoint.isNotEmpty
                                  ? ride.dropoffPoint
                                  : ride.toCity,
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRow(
                            isAr ? 'تكلفة المقعد' : 'Seat Fare',
                            '${ride.pricePerSeat} ${isAr ? "ر.ق" : "QAR"}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live Embedded Google Map Preview (Pre-Trip)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: MashwarEmbeddedGoogleMap(
                        key: const ValueKey('active_trip_pretrip_embedded_gmap'),
                        origin: ride.pickupPoint.trim().isNotEmpty
                            ? ride.pickupPoint
                            : ride.fromCity,
                        destination: ride.dropoffPoint.trim().isNotEmpty
                            ? ride.dropoffPoint
                            : ride.toCity,
                        stopover: ride.stopoverCity,
                        vehicleMode: MashwarMapVehicleMode.trip,
                        showTraffic: true,
                        height: 260,
                        borderRadius: 12,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1-Tap In-App Google Maps Navigation Button
                    _buildGoogleMapsButton(context, ride, isAr),
                    const SizedBox(height: 12),

                    // Start Live Tracking CTA
                    MashwarButton(
                      key: const ValueKey('active_trip_start_live_btn'),
                      text: isAr
                          ? 'بدء تتبع الرحلة المباشر'
                          : 'Start Live Trip Tracking',
                      icon: const Icon(
                        Icons.navigation_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _phase = TripTrackingPhase.inTransit),
                    ),
                    const SizedBox(height: 12),

                    // Communication Bar
                    MashwarCommunicationBar(
                      chatLabel: isAr ? 'محادثة شات' : 'Chat',
                      callLabel: isAr ? 'اتصل بالسائق' : 'Call Driver',
                      shareLabel: isAr ? 'مشاركة الرحلة' : 'Share Ride',
                      onChat: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              driverName: ride.driverName,
                              driverCar: ride.driverCar,
                              tripRoute: context.trRoute(
                                '${ride.fromCity} ← ${ride.toCity}',
                              ),
                            ),
                          ),
                        );
                      },
                      onCall: () => _callDriver(context, ride, isAr),
                      onShare: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ShareTripSheet(ride: ride),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        key: const ValueKey('active_trip_cancel_btn'),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => CancellationSheet(
                              onCancelled: () {
                                Provider.of<RidesProvider?>(
                                  context,
                                  listen: false,
                                )?.cancelBooking();
                              },
                            ),
                          );
                        },
                        child: Text(
                          isAr ? 'إلغاء الحجز' : 'Cancel Booking',
                          style: AppTypography.button(color: AppColors.danger)
                              .copyWith(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Phase 2: أثناء الرحلة
  Widget _buildInTransitView(BuildContext context, RideModel ride, bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'رحلتك الآن' : 'Your Ride Now',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RideRouteMapView(ride: ride),
                  const SizedBox(height: 12),

                  // 1-Tap Google Maps Navigation Button
                  _buildGoogleMapsButton(context, ride, isAr),
                  const SizedBox(height: 12),

                  // Driver Card with MashwarUserAvatar
                  _buildDriverIdentityCard(ride, isAr),
                  const SizedBox(height: 12),

                  // ETA & Distance Card
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                isAr
                                    ? 'الوقت المتوقع للوصول'
                                    : 'Estimated Arrival',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr ? '8:45 ص' : '8:45 AM',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.title(
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: AppColors.slateBorder,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                isAr ? 'المسافة المتبقية' : 'Distance Remaining',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr ? '42 كم' : '42 km',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.title(
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Emergency SOS Strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'طوارئ: مشاركة خط السير المباشر أو طلب نجدة 999'
                                : 'Emergency SOS: Share live route or call 999',
                            style: AppTypography.label(color: AppColors.navy),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('active_trip_sos_btn'),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                    AppDimens.radiusBottomSheet,
                                  ),
                                ),
                              ),
                              builder: (_) => const EmergencySosSheet(),
                            );
                          },
                          child: Text(
                            isAr ? 'SOS طوارئ' : 'SOS',
                            style: AppTypography.label(color: AppColors.danger)
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  MashwarCommunicationBar(
                    chatLabel: isAr ? 'محادثة شات' : 'Chat',
                    callLabel: isAr ? 'اتصل بالسائق' : 'Call Driver',
                    shareLabel: isAr ? 'مشاركة المسار' : 'Share Trip',
                    onChat: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            driverName: ride.driverName,
                            driverCar: ride.driverCar,
                            tripRoute: context.trRoute(
                              '${ride.fromCity} ← ${ride.toCity}',
                            ),
                          ),
                        ),
                      );
                    },
                    onCall: () => _callDriver(context, ride, isAr),
                    onShare: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ShareTripSheet(ride: ride),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Complete Trip CTA -> updates RidesProvider & transitions to completed
                  MashwarButton(
                    key: const ValueKey('active_trip_complete_btn'),
                    text: isAr
                        ? 'وصلت بالسلامة · إنهاء الرحلة'
                        : 'Arrived Safely · Complete Trip',
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () => _completeTrip(context, ride),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Phase 3: الرحلة اكتملت
  Widget _buildCompletedView(BuildContext context, RideModel ride, bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'ملخص الرحلة المكتملة' : 'Completed Trip',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(0.0, 2000.0),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: MashwarFadeSlideIn(
                    duration: const Duration(milliseconds: 260),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.tealSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.teal,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAr ? 'وصلت بالسلامة!' : 'Arrived Safely!',
                          style: AppTypography.largeTitle(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAr
                              ? 'رحلتك مع ${ride.driverName.split(' ').first} اكتملت بنجاح.'
                              : 'Your ride with ${ride.driverName.split(' ').first} has completed successfully.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySecondary(),
                        ),
                        const SizedBox(height: 20),

                        // Completed Trip Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppDimens.space16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusCard,
                            ),
                            border: Border.all(color: AppColors.slateBorder),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  MashwarUserAvatar(
                                    avatarUrl: null,
                                    fullName: ride.driverName,
                                    size: 42,
                                    borderWidth: 1.5,
                                    borderColor: AppColors.slateBorder,
                                    autoCommunityPortrait: true,
                                    showVerifiedBadge: ride.isVerified,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ride.driverName,
                                          style: AppTypography.body(
                                            color: AppColors.navy,
                                          ).copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          ride.driverCar,
                                          style: AppTypography.bodySmall(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  MashwarBadge(
                                    type: BadgeType.verified,
                                    customLabel: isAr ? 'مكتملة' : 'Completed',
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 24,
                                color: AppColors.slateBorder,
                              ),
                              _buildRow(
                                isAr ? 'المسار' : 'Route',
                                context.trRoute(
                                  '${ride.fromCity} ← ${ride.toCity}',
                                ),
                              ),
                              const Divider(
                                height: 20,
                                color: AppColors.slateBorder,
                              ),
                              _buildRow(
                                isAr ? 'الإجمالي' : 'Total',
                                '${ride.pricePerSeat} ${isAr ? "ر.ق نقداً" : "QAR Cash"}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        MashwarButton(
                          key: const ValueKey('active_trip_rate_btn'),
                          text: isAr
                              ? 'تقييم السائق والمشوار'
                              : 'Rate Driver & Trip',
                          icon: const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RateTripScreen(
                                  rideId: ride.id,
                                  driverName: ride.driverName,
                                  route: context.trRoute(
                                    '${ride.fromCity} ← ${ride.toCity}',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        MashwarButton(
                          text: isAr ? 'احجز رحلة أخرى' : 'Book Another Ride',
                          variant: MashwarButtonVariant.secondary,
                          onPressed: () => Navigator.of(context)
                              .popUntil((route) => route.isFirst),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReportIssueScreen(),
                              ),
                            );
                          },
                          child: Text(
                            isAr ? 'أبلّغ عن مشكلة' : 'Report an issue',
                            style: AppTypography.bodySecondary(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.label(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isBold
                ? AppTypography.body().copyWith(fontWeight: FontWeight.w700)
                : AppTypography.body(),
          ),
        ),
      ],
    );
  }
}
