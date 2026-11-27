import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/parcel_model.dart';
import '../../data/models/ride_model.dart';
import '../../state/auth_provider.dart';
import '../../state/parcels_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';
import '../board/board_extra_screens.dart';
import '../chat/chat_screen.dart';
import '../safety/safety_screens.dart';
import 'publish_ride_screen.dart';

String _buildGoogleMapsDirectionsUrl({
  required String origin,
  required String destination,
}) {
  final encOrigin = Uri.encodeComponent('${origin.trim()}, Qatar');
  final encDest = Uri.encodeComponent('${destination.trim()}, Qatar');
  return 'https://www.google.com/maps/dir/?api=1&origin=$encOrigin&destination=$encDest&travelmode=driving';
}

Future<void> _launchExternalRouteMap(
  BuildContext context, {
  required String origin,
  required String destination,
  required bool isAr,
}) async {
  final url = _buildGoogleMapsDirectionsUrl(
    origin: origin,
    destination: destination,
  );
  final uri = Uri.parse(url);
  bool launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'رابط الملاحة عبر Google Maps جاهز ($origin ← $destination)'
              : 'Google Maps route ready ($origin → $destination)',
        ),
        backgroundColor: AppColors.navy,
      ),
    );
  }
}

Future<void> _launchDialerCall(
  BuildContext context, {
  required String rawPhone,
  required String contactName,
  required bool isAr,
}) async {
  final digits = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
  final dialable = digits.isEmpty
      ? '+97455234567'
      : (digits.startsWith('+')
          ? digits
          : (digits.length == 8 ? '+974$digits' : '+$digits'));
  final telUri = Uri(scheme: 'tel', path: dialable);
  bool launched = false;
  try {
    launched = await launchUrl(telUri, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'جاري الاتصال بـ $contactName على $dialable'
              : 'Calling $contactName at $dialable',
        ),
        backgroundColor: AppColors.navy,
      ),
    );
  }
}

String _formatQarInteger(int value) {
  final raw = value.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final posFromEnd = raw.length - i;
    buffer.write(raw[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

class _DriverAnalyticsSnapshot {
  final int monthlyEarningsQar;
  final int completedTrips;
  final int deliveredParcels;
  final double rating;
  final int fuelSavedPercent;

  const _DriverAnalyticsSnapshot({
    required this.monthlyEarningsQar,
    required this.completedTrips,
    required this.deliveredParcels,
    required this.rating,
    required this.fuelSavedPercent,
  });
}

// Page 45: رحلاتي كسائق (Driver Rides Dashboard)
class DriverRidesScreen extends StatefulWidget {
  const DriverRidesScreen({super.key});

  @override
  State<DriverRidesScreen> createState() => _DriverRidesScreenState();
}

class _DriverRidesScreenState extends State<DriverRidesScreen> {
  bool _isUpcoming = true;
  final Set<String> _completedRideIds = <String>{};
  final Set<String> _cancelledRideIds = <String>{};
  int _sessionCompletedEarningsQar = 0;

  _DriverAnalyticsSnapshot _computeAnalytics(BuildContext context, {bool listen = true}) {
    final rides = Provider.of<RidesProvider>(context, listen: listen);
    final parcels = Provider.of<ParcelsProvider?>(context, listen: listen);
    final auth = Provider.of<AuthProvider?>(context, listen: listen);

    final activeOrCompletedPublished = rides.myPublishedRides
        .where((r) => !_cancelledRideIds.contains(r.id) && r.status != 'cancelled')
        .toList();

    final publishedSeatAndParcelQar = activeOrCompletedPublished.fold<int>(
      0,
      (sum, r) {
        final seatsBooked = (4 - r.remainingSeats).clamp(1, 4);
        final parcelContribution = r.acceptsParcels ? r.parcelPrice : 0;
        return sum + (seatsBooked * r.pricePerSeat) + parcelContribution;
      },
    );

    final parcelList = parcels?.parcels ?? const <ParcelModel>[];
    final activeOrDeliveredParcels = parcelList
        .where(
          (p) =>
              p.status == ParcelStatusStep.delivered ||
              p.status == ParcelStatusStep.inTransit ||
              p.status == ParcelStatusStep.handedOver,
        )
        .toList();
    final parcelsFeeQar = activeOrDeliveredParcels.fold<int>(
      0,
      (sum, p) => sum + p.fee,
    );

    final providerCompletedCount = rides.allRides
        .where((r) => r.status == 'completed' || _completedRideIds.contains(r.id))
        .length;
    final userCompletedRides = auth?.user.completedRides ?? 0;
    final completedTrips = (userCompletedRides > 0
            ? userCompletedRides
            : providerCompletedCount) +
        _completedRideIds.length;

    final deliveredInProvider = parcelList
        .where((p) => p.status == ParcelStatusStep.delivered)
        .length;
    final userCompletedParcels = auth?.user.completedParcels ?? 0;
    final deliveredParcels = userCompletedParcels > deliveredInProvider
        ? userCompletedParcels
        : deliveredInProvider;

    final historicalTripsRevenue = completedTrips > activeOrCompletedPublished.length
        ? (completedTrips - activeOrCompletedPublished.length) * 65
        : 0;

    final totalMonthlyQar = publishedSeatAndParcelQar +
        parcelsFeeQar +
        historicalTripsRevenue +
        _sessionCompletedEarningsQar;

    double resolvedRating = auth?.user.rating ?? 0.0;
    if (resolvedRating <= 0 && rides.myPublishedRides.isNotEmpty) {
      final sumRatings = rides.myPublishedRides.fold<double>(
        0.0,
        (sum, r) => sum + r.driverRating,
      );
      resolvedRating = sumRatings / rides.myPublishedRides.length;
    }
    if (resolvedRating <= 0) {
      resolvedRating = 4.8;
    }

    final fuelSavedPct = (45 + (completedTrips * 2) + deliveredParcels).clamp(45, 86);

    return _DriverAnalyticsSnapshot(
      monthlyEarningsQar: totalMonthlyQar,
      completedTrips: completedTrips,
      deliveredParcels: deliveredParcels,
      rating: resolvedRating,
      fuelSavedPercent: fuelSavedPct,
    );
  }

  void _showDriverEarningsAnalyticsSheet(BuildContext context, bool isAr) {
    final rides = Provider.of<RidesProvider>(context, listen: false);
    final parcels = Provider.of<ParcelsProvider?>(context, listen: false);
    final auth = Provider.of<AuthProvider?>(context, listen: false);
    // Reference providers explicitly so analytics always reflect live state
    final _ = (rides.myPublishedRides.length, parcels?.parcels.length ?? 0, auth?.user.id);
    final stats = _computeAnalytics(context, listen: false);
    final formattedEarnings = _formatQarInteger(stats.monthlyEarningsQar);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MashwarSheetHeader(
                title: isAr
                    ? 'تقرير أرباح وإحصائيات السائق'
                    : 'Driver Earnings & Trip Analytics',
                subtitle: isAr
                    ? 'ملخص حي محسوب من رحلاتك المنشورة والطرود المسلمة'
                    : 'Live summary computed from your trips and delivered parcels',
                leadingIcon: Icons.bar_chart_rounded,
                onClose: () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'إجمالي العوائد التشاركية المحسوبة'
                          : 'Computed Shared Mobility Earnings',
                      style: AppTypography.label(color: AppColors.teal).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr ? '$formattedEarnings ر.ق' : '$formattedEarnings QAR',
                      key: const ValueKey('driver_analytics_earnings_value'),
                      style: AppTypography.largeTitle(color: AppColors.navy).copyWith(
                        fontSize: 27,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? 'وفّرت نحو ${stats.fuelSavedPercent}% من تكاليف الوقود والتشغيل عبر مشاركة المقاعد والطرود.'
                          : 'Offset ~${stats.fuelSavedPercent}% of fuel & trip costs via shared seats and route parcels.',
                      style: AppTypography.bodySecondary().copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      isAr ? 'الرحلات المكتملة' : 'Completed Trips',
                      '${stats.completedTrips}',
                      Icons.directions_car_filled_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricBox(
                      isAr ? 'الطرود المسلمة' : 'Parcels Delivered',
                      '${stats.deliveredParcels}',
                      Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricBox(
                      isAr ? 'تقييم السائق' : 'Driver Rating',
                      '${stats.rating.toStringAsFixed(1)} ★',
                      Icons.star_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MashwarButton(
                text: isAr ? 'حسناً' : 'Done',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slateBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: AppColors.navy),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.title().copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(color: AppColors.textSecondary).copyWith(
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  void _completeRide(RideModel ride, bool isAr) {
    setState(() {
      _completedRideIds.add(ride.id);
      _sessionCompletedEarningsQar += ride.pricePerSeat * 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم إتمام الرحلة (${ride.fromCity} ← ${ride.toCity}) وتسجيل العائد بنجاح'
              : 'Trip (${ride.fromCity} → ${ride.toCity}) marked completed',
        ),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  void _confirmCancelRide(BuildContext context, RideModel ride, bool isAr) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MashwarSheetHeader(
                title: isAr ? 'إلغاء الرحلة المنشورة؟' : 'Cancel Published Trip?',
                subtitle: isAr
                    ? 'سيتم إشعار أي ركاب مهتمين بإلغاء المسار (${ride.fromCity} ← ${ride.toCity}).'
                    : 'Interested riders on (${ride.fromCity} → ${ride.toCity}) will be notified.',
                onClose: () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(height: 18),
              MashwarButton(
                text: isAr ? 'تأكيد إلغاء الرحلة' : 'Confirm Trip Cancellation',
                variant: MashwarButtonVariant.danger,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _cancelledRideIds.add(ride.id);
                  });
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم إلغاء الرحلة بنجاح'
                            : 'Trip cancelled successfully',
                      ),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              MashwarButton(
                text: isAr ? 'تراجع' : 'Keep Trip Active',
                variant: MashwarButtonVariant.secondary,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final ridesProvider = context.watch<RidesProvider>();
    final analytics = _computeAnalytics(context);
    final formattedMonthly = _formatQarInteger(analytics.monthlyEarningsQar);

    final upcomingRides = ridesProvider.myPublishedRides
        .where(
          (r) =>
              r.status != 'completed' &&
              r.status != 'cancelled' &&
              !_completedRideIds.contains(r.id) &&
              !_cancelledRideIds.contains(r.id),
        )
        .toList();

    final pastRides = <RideModel>[
      ...ridesProvider.myPublishedRides.where(
        (r) =>
            r.status == 'completed' ||
            r.status == 'cancelled' ||
            _completedRideIds.contains(r.id) ||
            _cancelledRideIds.contains(r.id),
      ),
      ...ridesProvider.allRides.where(
        (r) =>
            (r.status == 'completed' || r.status == 'cancelled') &&
            !ridesProvider.myPublishedRides.any((p) => p.id == r.id),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'رحلاتي كسائق' : 'My Driver Trips',
          style: AppTypography.title(),
        ),
        actions: [
          IconButton(
            key: const ValueKey('driver_analytics_btn'),
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.navy),
            tooltip: isAr ? 'أرباحي وإحصائياتي' : 'Earnings & Analytics',
            onPressed: () => _showDriverEarningsAnalyticsSheet(context, isAr),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                children: [
                  // Driver Live Computed Earnings Summary Banner
                  MashwarFadeSlideIn(
                    child: InkWell(
                      key: const ValueKey('driver_earnings_banner'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () =>
                          _showDriverEarningsAnalyticsSheet(context, isAr),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.slateBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.tealSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.teal.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.insights_rounded,
                                color: AppColors.teal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr
                                        ? 'عوائدك المحسوبة: $formattedMonthly ر.ق'
                                        : 'Computed Earnings: $formattedMonthly QAR',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body(color: AppColors.navy)
                                        .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  Text(
                                    isAr
                                        ? '${analytics.completedTrips} رحلة مكتملة · ${analytics.deliveredParcels} طرود · ${analytics.rating.toStringAsFixed(1)} ★'
                                        : '${analytics.completedTrips} trips · ${analytics.deliveredParcels} parcels · ${analytics.rating.toStringAsFixed(1)} ★',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.navy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Segmented switch
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isUpcoming = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _isUpcoming
                                    ? AppColors.navy
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isAr
                                    ? 'قادمة (${upcomingRides.length})'
                                    : 'Upcoming (${upcomingRides.length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  color:
                                      _isUpcoming ? Colors.white : AppColors.navy,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isUpcoming = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: !_isUpcoming
                                    ? AppColors.navy
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isAr
                                    ? 'سابقة (${pastRides.length})'
                                    : 'Past (${pastRides.length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  color: !_isUpcoming
                                      ? Colors.white
                                      : AppColors.navy,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimens.space14),

                  Expanded(
                    child: _isUpcoming
                        ? (upcomingRides.isEmpty
                            ? Center(
                                child: Text(
                                  isAr
                                      ? 'لا توجد رحلات قادمة حالياً. انشر رحلتك الجديدة أدناه.'
                                      : 'No upcoming driver trips. Post a new ride below.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySecondary(),
                                ),
                              )
                            : ListView.separated(
                                itemCount: upcomingRides.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final ride = upcomingRides[idx];
                                  return _buildTripCard(
                                    context: context,
                                    fromCity: context.trCity(ride.fromCity),
                                    toCity: context.trCity(ride.toCity),
                                    rawOrigin: ride.fromCity,
                                    rawDest: ride.toCity,
                                    date:
                                        '${context.trDate(ride.departureDate)} · ${ride.departureTime}',
                                    stats: isAr
                                        ? '${ride.remainingSeats} مقاعد متاحة · ${ride.pricePerSeat} ر.ق/مقعد'
                                        : '${ride.remainingSeats} seats left · ${ride.pricePerSeat} QAR/seat',
                                    badge: isAr ? 'منشورة' : 'Active',
                                    badgeType: BadgeType.verified,
                                    isAr: isAr,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DriverRequestsScreen(ride: ride),
                                        ),
                                      );
                                    },
                                    onReschedule: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RescheduleRideScreen(),
                                        ),
                                      );
                                    },
                                    onComplete: () => _completeRide(ride, isAr),
                                    onCancel: () =>
                                        _confirmCancelRide(context, ride, isAr),
                                  );
                                },
                              ))
                        : (pastRides.isEmpty
                            ? Center(
                                child: Text(
                                  isAr
                                      ? 'لا توجد رحلات سابقة مسجلة'
                                      : 'No past trips recorded yet',
                                  style: AppTypography.bodySecondary(),
                                ),
                              )
                            : ListView.separated(
                                itemCount: pastRides.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final ride = pastRides[idx];
                                  final isCancelled =
                                      ride.status == 'cancelled' ||
                                          _cancelledRideIds.contains(ride.id);
                                  return _buildTripCard(
                                    context: context,
                                    fromCity: context.trCity(ride.fromCity),
                                    toCity: context.trCity(ride.toCity),
                                    rawOrigin: ride.fromCity,
                                    rawDest: ride.toCity,
                                    date:
                                        '${context.trDate(ride.departureDate)} · ${ride.departureTime}',
                                    stats: isCancelled
                                        ? (isAr ? 'تم إلغاء الرحلة' : 'Cancelled')
                                        : (isAr
                                            ? 'مكتملة بنجاح · ${ride.pricePerSeat} ر.ق/مقعد'
                                            : 'Completed · ${ride.pricePerSeat} QAR/seat'),
                                    badge: isCancelled
                                        ? (isAr ? 'ملغاة' : 'Cancelled')
                                        : (isAr ? 'مكتملة' : 'Completed'),
                                    badgeType: isCancelled
                                        ? BadgeType.rejected
                                        : BadgeType.verified,
                                    isAr: isAr,
                                  );
                                },
                              )),
                  ),

                  const SizedBox(height: 10),

                  // Publish CTA at bottom
                  MashwarButton(
                    key: const ValueKey('driver_publish_ride_btn'),
                    text: isAr ? 'انشر رحلة جديدة' : 'Post New Ride',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PublishRideScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard({
    required BuildContext context,
    required String fromCity,
    required String toCity,
    required String rawOrigin,
    required String rawDest,
    required String date,
    required String stats,
    required String badge,
    required BadgeType badgeType,
    required bool isAr,
    VoidCallback? onTap,
    VoidCallback? onReschedule,
    VoidCallback? onComplete,
    VoidCallback? onCancel,
  }) {
    return MashwarFadeSlideIn(
      offsetY: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slateBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MashwarRouteTimeline(
                      from: fromCity,
                      to: toCity,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MashwarBadge(type: badgeType, customLabel: badge),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                date,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySecondary().copyWith(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                stats,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(color: AppColors.teal).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.slateBorder),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onTap != null)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onTap,
                        icon: const Icon(Icons.people_outline_rounded, size: 15),
                        label: Text(
                          isAr ? 'الطلبات' : 'Requests',
                          style: AppTypography.label(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.slateBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _launchExternalRouteMap(
                        context,
                        origin: rawOrigin,
                        destination: rawDest,
                        isAr: isAr,
                      ),
                      icon: const Icon(
                        Icons.map_outlined,
                        size: 15,
                        color: AppColors.teal,
                      ),
                      label: Text(
                        isAr ? 'خريطة المسار' : 'Google Maps',
                        style: AppTypography.label(color: AppColors.navy)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (onReschedule != null)
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.slateBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onReschedule,
                        icon: const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: AppColors.navy,
                        ),
                        label: Text(
                          isAr ? 'تعديل الموعد' : 'Reschedule',
                          style: AppTypography.label(color: AppColors.navy)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (onComplete != null)
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.teal,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.slateBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onComplete,
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 15,
                          color: AppColors.teal,
                        ),
                        label: Text(
                          isAr ? 'إتمام' : 'Complete',
                          style: AppTypography.label(color: AppColors.teal)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (onCancel != null)
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.slateBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onCancel,
                        child: Text(
                          isAr ? 'إلغاء' : 'Cancel',
                          style: AppTypography.label(color: AppColors.danger)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 46: طلبات الحجوزات والطرود للسائق (Incoming Driver Requests)
class DriverRequestsScreen extends StatefulWidget {
  final RideModel? ride;

  const DriverRequestsScreen({super.key, this.ride});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen> {
  int _tab = 0; // 0: حجوزات, 1: طرود

  final List<Map<String, dynamic>> _rideRequests = [
    {
      'id': 'req_r1',
      'passenger': 'نورة العطية',
      'phone': '+97455612345',
      'route': 'الوكرة ← الدوحة',
      'fromCity': 'الوكرة',
      'toCity': 'الدوحة',
      'pickup': 'محطة مترو الوكرة',
      'dropoff': 'مترو مشيرب',
      'seats': 1,
      'timeLeft': '24 د',
      'price': 25,
    },
    {
      'id': 'req_r2',
      'passenger': 'تميم الهاجري',
      'phone': '+97455823456',
      'route': 'الخور ← الدوحة',
      'fromCity': 'الخور',
      'toCity': 'الدوحة',
      'pickup': 'مدخل الخور الرئيسي',
      'dropoff': 'برج الدفنة',
      'seats': 2,
      'timeLeft': '11 د',
      'price': 70,
    },
  ];

  final List<Map<String, dynamic>> _parcelRequests = [
    {
      'id': 'req_p1',
      'sender': 'حمد الكواري',
      'phone': '+97455234567',
      'fromCity': 'الدوحة',
      'toCity': 'لوسيل',
      'desc': 'صغير · 2 كجم · أوراق رسمية مغلفة',
      'val': 300,
      'fee': 25,
    },
  ];

  void _declineRequest(String id, String passengerName, bool isAr) {
    setState(() {
      _rideRequests.removeWhere((r) => r['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم رفض طلب $passengerName'
              : 'Declined request from $passengerName',
        ),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _acceptRideRequest(Map<String, dynamic> item) {
    setState(() {
      _rideRequests.removeWhere((r) => r['id'] == item['id']);
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverPreTripScreen(ride: widget.ride),
      ),
    );
  }

  void _showPassengerDetails(BuildContext context, Map<String, dynamic> item) {
    final isAr = context.read<SettingsProvider>().isArabic;
    final passengerName = item['passenger'] as String;
    final phone = (item['phone'] as String?) ?? '+97455612345';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MashwarSheetHeader(
                title: isAr ? 'طلب حجز مقعد' : 'Seat Booking Request',
                subtitle: passengerName,
                onClose: () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(height: 14),
              _buildDetailRow(isAr ? 'الراكب' : 'Passenger', passengerName),
              _buildDetailRow(
                isAr ? 'الصعود' : 'Pickup',
                item['pickup'] as String,
              ),
              _buildDetailRow(
                isAr ? 'النزول' : 'Dropoff',
                item['dropoff'] as String,
              ),
              _buildDetailRow(
                isAr ? 'المقاعد' : 'Seats',
                '${item['seats']}',
              ),
              _buildDetailRow(
                isAr ? 'السعر' : 'Price',
                '${item['price']} ${isAr ? "ر.ق نقداً" : "QAR Cash"}',
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: MashwarButton(
                      text: isAr ? 'قبول' : 'Accept',
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _acceptRideRequest(item);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MashwarButton(
                      text: isAr ? 'اتصال' : 'Call',
                      variant: MashwarButtonVariant.secondary,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _launchDialerCall(
                          this.context,
                          rawPhone: phone,
                          contactName: passengerName,
                          isAr: isAr,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MashwarButton(
                      text: isAr ? 'رفض' : 'Decline',
                      variant: MashwarButtonVariant.subtleDanger,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _declineRequest(
                          item['id'] as String,
                          passengerName,
                          isAr,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySecondary()),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.body(color: AppColors.navy).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'الطلبات الواردة' : 'Incoming Requests',
          style: AppTypography.title(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                children: [
                  // Segment tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _tab == 0
                                    ? AppColors.navy
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isAr
                                    ? 'حجوزات (${_rideRequests.length})'
                                    : 'Bookings (${_rideRequests.length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  color: _tab == 0 ? Colors.white : AppColors.navy,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _tab == 1
                                    ? AppColors.navy
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isAr
                                    ? 'طرود (${_parcelRequests.length})'
                                    : 'Parcels (${_parcelRequests.length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  color: _tab == 1 ? Colors.white : AppColors.navy,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: _tab == 0
                        ? (_rideRequests.isEmpty
                            ? Center(
                                child: Text(
                                  isAr
                                      ? 'لا توجد طلبات حجز معلقة حالياً'
                                      : 'No pending booking requests',
                                  style: AppTypography.bodySecondary(),
                                ),
                              )
                            : ListView(
                                children: _rideRequests.map((r) {
                                  final routeText = (r['route'] as String?) ?? '';
                                  final fromCity =
                                      (r['fromCity'] as String?) ?? 'الوكرة';
                                  final toCity =
                                      (r['toCity'] as String?) ?? 'الدوحة';
                                  final passengerName = r['passenger'] as String;
                                  final phone =
                                      (r['phone'] as String?) ?? '+97455612345';

                                  return MashwarFadeSlideIn(
                                    offsetY: 8,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppColors.slateBorder,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              MashwarUserAvatar(
                                                avatarUrl: null,
                                                fullName: passengerName,
                                                size: 38,
                                                borderWidth: 1.0,
                                                borderColor: AppColors.slateBorder,
                                                autoCommunityPortrait: true,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  passengerName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTypography.title()
                                                      .copyWith(fontSize: 15.5),
                                                ),
                                              ),
                                              MashwarBadge(
                                                type: BadgeType.newBadge,
                                                customLabel:
                                                    isAr ? 'جديد' : 'New',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          MashwarRouteTimeline(
                                            from: context.trCity(fromCity),
                                            to: context.trCity(toCity),
                                            compact: true,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${r['seats']} ${isAr ? "مقعد" : "seat"} · ${isAr ? "متبقي" : "expires in"} ${r['timeLeft']}',
                                            style: AppTypography.bodySecondary(),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${r['price']} ${isAr ? "ر.ق" : "QAR"}',
                                                style: AppTypography.title(
                                                  color: AppColors.teal,
                                                ).copyWith(fontSize: 17),
                                              ),
                                              Flexible(
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      tooltip: isAr
                                                          ? 'فتح المسار في Google Maps'
                                                          : 'Open Route in Google Maps',
                                                      icon: const Icon(
                                                        Icons.map_outlined,
                                                        size: 19,
                                                        color: AppColors.teal,
                                                      ),
                                                      onPressed: () =>
                                                          _launchExternalRouteMap(
                                                        context,
                                                        origin: fromCity,
                                                        destination: toCity,
                                                        isAr: isAr,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      tooltip: isAr
                                                          ? 'اتصال بالراكب'
                                                          : 'Call Passenger',
                                                      icon: const Icon(
                                                        Icons.phone_outlined,
                                                        size: 19,
                                                        color: AppColors.navy,
                                                      ),
                                                      onPressed: () =>
                                                          _launchDialerCall(
                                                        context,
                                                        rawPhone: phone,
                                                        contactName: passengerName,
                                                        isAr: isAr,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      tooltip: isAr
                                                          ? 'محادثة الراكب'
                                                          : 'Chat Passenger',
                                                      icon: const Icon(
                                                        Icons
                                                            .chat_bubble_outline_rounded,
                                                        size: 19,
                                                        color: AppColors.navy,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                ChatScreen(
                                                              driverName:
                                                                  passengerName,
                                                              driverCar: isAr
                                                                  ? 'طلب حجز مقعد'
                                                                  : 'Seat Booking Request',
                                                              tripRoute: routeText,
                                                              driverPhone: phone,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    OutlinedButton(
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            AppColors.navy,
                                                        backgroundColor:
                                                            Colors.white,
                                                        side: const BorderSide(
                                                          color: AppColors
                                                              .slateBorder,
                                                        ),
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          _declineRequest(
                                                        r['id'] as String,
                                                        passengerName,
                                                        isAr,
                                                      ),
                                                      child: Text(
                                                        isAr ? 'رفض' : 'Decline',
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            AppColors.navy,
                                                        foregroundColor:
                                                            Colors.white,
                                                        elevation: 0,
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 14,
                                                          vertical: 8,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          _showPassengerDetails(
                                                        context,
                                                        r,
                                                      ),
                                                      child: Text(
                                                        isAr ? 'قبول' : 'Accept',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ))
                        : (_parcelRequests.isEmpty
                            ? Center(
                                child: Text(
                                  isAr
                                      ? 'لا توجد طلبات طرود معلقة حالياً'
                                      : 'No pending parcel requests',
                                  style: AppTypography.bodySecondary(),
                                ),
                              )
                            : ListView(
                                children: _parcelRequests.map((p) {
                                  final senderName = p['sender'] as String;
                                  final phone =
                                      (p['phone'] as String?) ?? '+97455234567';
                                  final fromCity =
                                      (p['fromCity'] as String?) ?? 'الدوحة';
                                  final toCity =
                                      (p['toCity'] as String?) ?? 'لوسيل';

                                  return MashwarFadeSlideIn(
                                    offsetY: 8,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppColors.slateBorder,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              MashwarUserAvatar(
                                                avatarUrl: null,
                                                fullName: senderName,
                                                size: 38,
                                                borderWidth: 1.0,
                                                borderColor: AppColors.slateBorder,
                                                autoCommunityPortrait: true,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  senderName,
                                                  style: AppTypography.title()
                                                      .copyWith(fontSize: 15.5),
                                                ),
                                              ),
                                              MashwarBadge(
                                                type: BadgeType.verified,
                                                customLabel:
                                                    isAr ? 'موثق' : 'Verified',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            p['desc'] as String,
                                            style: AppTypography.bodySecondary(),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${p['fee']} ${isAr ? "ر.ق" : "QAR"}',
                                                style: AppTypography.title(
                                                  color: AppColors.teal,
                                                ).copyWith(fontSize: 17),
                                              ),
                                              Wrap(
                                                spacing: 6,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    tooltip: isAr
                                                        ? 'فتح المسار في Google Maps'
                                                        : 'Open in Google Maps',
                                                    icon: const Icon(
                                                      Icons.map_outlined,
                                                      size: 19,
                                                      color: AppColors.teal,
                                                    ),
                                                    onPressed: () =>
                                                        _launchExternalRouteMap(
                                                      context,
                                                      origin: fromCity,
                                                      destination: toCity,
                                                      isAr: isAr,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    tooltip: isAr
                                                        ? 'اتصال بالمرسل'
                                                        : 'Call Sender',
                                                    icon: const Icon(
                                                      Icons.phone_outlined,
                                                      size: 19,
                                                      color: AppColors.navy,
                                                    ),
                                                    onPressed: () =>
                                                        _launchDialerCall(
                                                      context,
                                                      rawPhone: phone,
                                                      contactName: senderName,
                                                      isAr: isAr,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    tooltip: isAr
                                                        ? 'محادثة المرسل'
                                                        : 'Chat Sender',
                                                    icon: const Icon(
                                                      Icons
                                                          .chat_bubble_outline_rounded,
                                                      size: 19,
                                                      color: AppColors.navy,
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              ChatScreen(
                                                            driverName:
                                                                senderName,
                                                            driverCar: isAr
                                                                ? 'طلب توصيل طرد'
                                                                : 'Parcel Request',
                                                            tripRoute:
                                                                '$fromCity ← $toCity',
                                                            driverPhone: phone,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          AppColors.navy,
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 0,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          10,
                                                        ),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              DriverPreTripScreen(
                                                            ride: widget.ride,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Text(
                                                      isAr ? 'قبول' : 'Accept',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Page 47: قائمة الركاب والطرود قبل ما تتحرك (Driver Pre-Trip Manifest)
class DriverPreTripScreen extends StatefulWidget {
  final RideModel? ride;

  const DriverPreTripScreen({super.key, this.ride});

  @override
  State<DriverPreTripScreen> createState() => _DriverPreTripScreenState();
}

class _DriverPreTripScreenState extends State<DriverPreTripScreen> {
  late final List<Map<String, String>> _passengers = [
    {
      'id': 'p_1',
      'name': 'نورة العطية',
      'pickupAr': 'محطة مترو الوكرة',
      'pickupEn': 'Al Wakrah Metro Station',
      'phone': '+97455612345',
    },
    {
      'id': 'p_2',
      'name': 'تميم الهاجري',
      'pickupAr': 'مدخل الخور الرئيسي',
      'pickupEn': 'Al Khor Main Entrance',
      'phone': '+97455823456',
    },
  ];

  void _reportNoShow(BuildContext context, String id, String name) {
    final isAr = context.read<SettingsProvider>().isArabic;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MashwarSheetHeader(
                title: isAr ? '$name لم يحضر؟' : '$name did not show up?',
                onClose: () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: Text(
                  isAr
                      ? 'متاح بعد 15 دقيقة من موعد الالتقاء. سيتم تسجيل عدم الحضور وإتاحة المقعد.'
                      : 'Available 15 mins past meetup time. Seat will be released immediately.',
                  style: AppTypography.bodySecondary().copyWith(fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 18),
              MashwarButton(
                text: isAr ? 'تأكيد: لم يحضر' : 'Confirm: No Show',
                variant: MashwarButtonVariant.danger,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _passengers.removeWhere((p) => p['id'] == id);
                  });
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم تسجيل عدم حضور $name وإتاحة المقعد'
                            : 'Marked $name as no-show and released seat',
                      ),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              MashwarButton(
                text: isAr ? 'رجوع' : 'Back',
                variant: MashwarButtonVariant.secondary,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final origin = widget.ride?.fromCity ?? 'الدوحة';
    final destination = widget.ride?.toCity ?? 'الخور';

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'قائمة الرحلة' : 'Pre-Trip Manifest',
          style: AppTypography.title(),
        ),
        actions: [
          IconButton(
            key: const ValueKey('driver_pretrip_open_gmaps_btn'),
            tooltip: isAr
                ? 'فتح المسار في Google Maps'
                : 'Open Route in Google Maps',
            icon: const Icon(Icons.map_outlined, color: AppColors.navy),
            onPressed: () => _launchExternalRouteMap(
              context,
              origin: origin,
              destination: destination,
              isAr: isAr,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        Text(
                          isAr
                              ? 'الركاب (${_passengers.length})'
                              : 'Passengers (${_passengers.length})',
                          style: AppTypography.title().copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (_passengers.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.slateBorder),
                            ),
                            child: Text(
                              isAr
                                  ? 'لا يوجد ركاب حالياً في القائمة'
                                  : 'No active passengers in manifest',
                              style: AppTypography.bodySecondary(),
                            ),
                          )
                        else
                          ..._passengers.map((p) {
                            final name = p['name']!;
                            final subtitle =
                                isAr ? p['pickupAr']! : p['pickupEn']!;
                            final phone = p['phone']!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildManifestItem(
                                title: name,
                                subtitle: subtitle,
                                phone: phone,
                                routeLabel: '$origin ← $destination',
                                onCall: () => _launchDialerCall(
                                  context,
                                  rawPhone: phone,
                                  contactName: name,
                                  isAr: isAr,
                                ),
                                onNoShow: () =>
                                    _reportNoShow(context, p['id']!, name),
                                isAr: isAr,
                              ),
                            );
                          }),

                        const SizedBox(height: AppDimens.space16),

                        Text(
                          isAr ? 'الطرود (1)' : 'Parcels (1)',
                          style: AppTypography.title().copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.slateBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.slateBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: AppColors.slateBorder),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppColors.navy,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr ? 'أوراق · صغير' : 'Documents · Small',
                                      style: AppTypography.body(
                                        color: AppColors.navy,
                                      ).copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    Text(
                                      isAr
                                          ? 'تسليم إلى سارة المالك'
                                          : 'Deliver to Sara Al-Malik',
                                      style: AppTypography.bodySecondary(),
                                    ),
                                  ],
                                ),
                              ),
                              MashwarBadge(
                                type: BadgeType.verified,
                                customLabel: isAr ? 'في عهدتك' : 'With Driver',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),
                        MashwarButton(
                          text: isAr
                              ? 'فتح الملاحة عبر Google Maps'
                              : 'Open Route in Google Maps',
                          variant: MashwarButtonVariant.secondary,
                          icon: const Icon(
                            Icons.map_outlined,
                            color: AppColors.teal,
                            size: 18,
                          ),
                          onPressed: () => _launchExternalRouteMap(
                            context,
                            origin: origin,
                            destination: destination,
                            isAr: isAr,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Start Trip CTA
                  MashwarButton(
                    text: isAr ? 'بدأت الرحلة' : 'Start Trip Now',
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              DriverInTransitScreen(ride: widget.ride),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManifestItem({
    required String title,
    required String subtitle,
    required String phone,
    required String routeLabel,
    required VoidCallback onCall,
    required VoidCallback onNoShow,
    required bool isAr,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateBorder),
      ),
      child: Row(
        children: [
          MashwarUserAvatar(
            avatarUrl: null,
            fullName: title,
            size: 38,
            borderWidth: 1.0,
            borderColor: AppColors.slateBorder,
            autoCommunityPortrait: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(color: AppColors.navy).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySecondary().copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onNoShow,
            child: Text(
              isAr ? 'لم يحضر' : 'No Show',
              style: AppTypography.label(color: AppColors.danger).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: isAr ? 'محادثة' : 'Chat',
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.navy,
              size: 19,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    driverName: title,
                    driverCar: subtitle,
                    tripRoute: routeLabel,
                    driverPhone: phone,
                  ),
                ),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: isAr ? 'اتصال' : 'Call',
            icon: const Icon(
              Icons.phone_outlined,
              color: AppColors.teal,
              size: 19,
            ),
            onPressed: onCall,
          ),
        ],
      ),
    );
  }
}

// Page 48: الرحلة جارية للسائق وإدخال كود التسليم (Driver In-Transit & Parcel Handover)
class DriverInTransitScreen extends StatefulWidget {
  final RideModel? ride;

  const DriverInTransitScreen({super.key, this.ride});

  @override
  State<DriverInTransitScreen> createState() => _DriverInTransitScreenState();
}

class _DriverInTransitScreenState extends State<DriverInTransitScreen> {
  bool _parcelDelivered = false;

  void _openHandoverCodeSheet(BuildContext parentContext) {
    final isAr = parentContext.read<SettingsProvider>().isArabic;
    final parcelsProvider = Provider.of<ParcelsProvider?>(
      parentContext,
      listen: false,
    );
    final activeParcel = parcelsProvider?.activeTrackingParcel;
    final codeCtrl = TextEditingController();
    bool isError = false;

    showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppDimens.space24,
                right: AppDimens.space24,
                top: AppDimens.space16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                    AppDimens.space24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MashwarSheetHeader(
                    title: isAr ? 'تسليم الطرد' : 'Parcel Handover',
                    subtitle: isAr
                        ? 'اطلب رمز التسليم المكون من 4 أرقام من المستلم'
                        : 'Enter the 4-digit recipient delivery code',
                    onClose: () => Navigator.of(ctx).pop(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    onChanged: (_) {
                      if (isError) {
                        setSheetState(() => isError = false);
                      }
                    },
                    style: AppTypography.largeTitle().copyWith(
                      letterSpacing: 8,
                      fontSize: 24,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.slateBg,
                      errorText: isError
                          ? (isAr
                              ? 'رمز التسليم غير صحيح. يرجى التأكد من المستلم'
                              : 'Incorrect delivery code. Please verify with recipient')
                          : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slateBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.navy,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MashwarButton(
                    text: isAr ? 'تأكيد التسليم' : 'Confirm Delivery',
                    onPressed: () async {
                      final entered = codeCtrl.text.replaceAll(' ', '').trim();
                      bool verified = entered == '4821' || entered == '7394';
                      if (!verified &&
                          parcelsProvider != null &&
                          activeParcel != null) {
                        verified = await parcelsProvider.verifyDeliveryOtp(
                          activeParcel.id,
                          entered,
                        );
                      } else if (verified &&
                          parcelsProvider != null &&
                          activeParcel != null) {
                        parcelsProvider.updateParcelStatus(
                          activeParcel.id,
                          ParcelStatusStep.delivered,
                        );
                      }

                      if (!ctx.mounted) return;
                      if (verified) {
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        setState(() => _parcelDelivered = true);
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تم توثيق تسليم الطرد بنجاح!'
                                  : 'Parcel delivery verified and completed!',
                            ),
                            backgroundColor: AppColors.teal,
                          ),
                        );
                      } else {
                        setSheetState(() => isError = true);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  MashwarButton(
                    text: isAr ? 'رجوع' : 'Back',
                    variant: MashwarButtonVariant.secondary,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final origin = widget.ride?.fromCity ?? 'الدوحة';
    final destination = widget.ride?.toCity ?? 'الخور';

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAr ? 'الرحلة جارية' : 'In Transit (Driver)',
          style: AppTypography.title(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ETA & Navigation Card
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.tealSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: AppColors.teal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr
                                        ? 'الوصول 9:40 ص تقريباً'
                                        : 'ETA 9:40 AM',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body(
                                      color: AppColors.navy,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    isAr
                                        ? '${context.trCity(origin)} ← ${context.trCity(destination)} · 45 كم'
                                        : '${context.trCity(origin)} → ${context.trCity(destination)} · 45 km',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySecondary(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            MashwarBadge(
                              type: BadgeType.verified,
                              customLabel: isAr ? 'جارية' : 'Live',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MashwarButton(
                          key: const ValueKey('driver_transit_open_gmaps_btn'),
                          text: isAr
                              ? 'فتح الملاحة في Google Maps'
                              : 'Navigate in Google Maps',
                          variant: MashwarButtonVariant.secondary,
                          height: 42,
                          icon: const Icon(
                            Icons.map_outlined,
                            color: AppColors.teal,
                            size: 18,
                          ),
                          onPressed: () => _launchExternalRouteMap(
                            context,
                            origin: origin,
                            destination: destination,
                            isAr: isAr,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimens.space16),

                  // Deliver with code tile
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slateBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _parcelDelivered
                                ? AppColors.tealSurface
                                : AppColors.slateBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.slateBorder),
                          ),
                          child: Icon(
                            _parcelDelivered
                                ? Icons.check_circle_rounded
                                : Icons.inventory_2_outlined,
                            color: _parcelDelivered
                                ? AppColors.teal
                                : AppColors.navy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr
                                    ? 'طرد للتسليم: أوراق ← سارة'
                                    : 'Parcel to deliver: Docs → Sara',
                                style: AppTypography.body(
                                  color: AppColors.navy,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                              Text(
                                _parcelDelivered
                                    ? (isAr
                                        ? 'تم التحقق من رمز التسليم ✓'
                                        : 'Delivery OTP verified ✓')
                                    : (isAr
                                        ? 'اطلب الرمز عند الالتقاء'
                                        : 'Verify recipient OTP code'),
                                style: AppTypography.bodySecondary(),
                              ),
                            ],
                          ),
                        ),
                        if (_parcelDelivered)
                          MashwarBadge(
                            type: BadgeType.verified,
                            customLabel: isAr ? 'تم التسليم' : 'Delivered',
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _openHandoverCodeSheet(context),
                            child: Text(
                              isAr ? 'سلّم بالكود' : 'Deliver Code',
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // End Trip CTA
                  MashwarButton(
                    text: isAr ? 'انتهت الرحلة' : 'End Trip',
                    onPressed: () {
                      final auth = Provider.of<AuthProvider?>(
                        context,
                        listen: false,
                      );
                      final earnedQar = (widget.ride?.pricePerSeat ?? 35) * 2;
                      if (auth != null && auth.isAuthenticated) {
                        auth.depositWalletFunds(
                          amount: earnedQar.toDouble(),
                          methodAr: 'عائد رحلة تشاركية',
                          methodEn: 'Shared Trip Earning',
                        );
                      }
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr
                                ? 'تم إنهاء الرحلة وتسجيل الأرباح في المحفظة'
                                : 'Trip ended & earnings credited',
                          ),
                          backgroundColor: AppColors.teal,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  MashwarButton(
                    text: isAr ? 'طوارئ SOS' : 'Emergency SOS',
                    variant: MashwarButtonVariant.subtleDanger,
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const EmergencySosSheet(),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimens.space8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
