import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
import '../../state/rides_provider.dart';
import '../booking/cancellation_sheet.dart';
import '../chat/chat_screen.dart';
import '../ride_details/widgets/ride_route_map_view.dart';
import '../safety/safety_screens.dart';
import 'rate_trip_screen.dart';

enum TripTrackingPhase {
  preTrip,    // قبل الرحلة
  inTransit,  // أثناء الرحلة
  completed,  // مكتمل
}

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key, required this.ride});

  final RideModel ride;

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  TripTrackingPhase _phase = TripTrackingPhase.preTrip;

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    switch (_phase) {
      case TripTrackingPhase.preTrip:
        return _buildPreTripView(context, isAr);
      case TripTrackingPhase.inTransit:
        return _buildInTransitView(context, isAr);
      case TripTrackingPhase.completed:
        return _buildCompletedView(context, isAr);
    }
  }

  // Phase 1: قبل الرحلة (Page 29)
  Widget _buildPreTripView(BuildContext context, bool isAr) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'الحجز' : 'Booking', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: TextButton(
              onPressed: () => setState(() => _phase = TripTrackingPhase.inTransit),
              child: Text(
                isAr ? 'التتبع المباشر' : 'Live Map',
                style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800, fontFamily: 'Cairo'),
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
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space12),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${context.trDate(widget.ride.departureDate)}${isAr ? "، " : ", "}${context.trDate(widget.ride.departureTime)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySecondary(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MashwarBadge(type: BadgeType.confirmed, customLabel: isAr ? 'مؤكد' : 'Confirmed'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Big Navy & Gold countdown block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.navy, Color(0xFF173D61)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'الرحلة هتبدأ بعد' : 'Trip starts in',
                                  style: AppTypography.label(color: AppColors.gold).copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAr ? '3 ساعات' : '3 Hours',
                                  style: AppTypography.largeTitle(color: Colors.white).copyWith(fontSize: 28),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.trRoute('${widget.ride.fromCity} ← ${widget.ride.toCity}'),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          MashwarAssetArt(
                            assetPath: 'assets/images/driver_promo.jpg',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details card with Route Timeline
                    MashwarSectionCard(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: MashwarRouteTimeline(
                              from: widget.ride.pickupPoint,
                              to: widget.ride.dropoffPoint,
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRow(isAr ? 'السائق' : 'Driver', widget.ride.driverName),
                          const Divider(height: 20, color: AppColors.borderDisabled),
                          _buildRow(isAr ? 'السيارة' : 'Vehicle', widget.ride.driverCar),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Seamless 1-Tap Communication Bar
                    MashwarCommunicationBar(
                      chatLabel: isAr ? 'محادثة شات' : 'Chat',
                      callLabel: isAr ? 'اتصل بالسائق' : 'Call Driver',
                      shareLabel: isAr ? 'مشاركة الرحلة' : 'Share Ride',
                      onChat: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              driverName: widget.ride.driverName,
                              driverCar: widget.ride.driverCar,
                              tripRoute: context.trRoute('${widget.ride.fromCity} ← ${widget.ride.toCity}'),
                            ),
                          ),
                        );
                      },
                      onCall: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isAr ? 'الاتصال بـ ${widget.ride.driverPhone}' : 'Calling ${widget.ride.driverPhone}')),
                        );
                      },
                      onShare: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const ShareTripSheet(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => CancellationSheet(
                              onCancelled: () {
                                context.read<RidesProvider>().cancelBooking();
                              },
                            ),
                          );
                        },
                        child: Text(isAr ? 'إلغاء الحجز' : 'Cancel Booking', style: AppTypography.button(color: AppColors.danger)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Phase 2: أثناء الرحلة (Page 29)
  Widget _buildInTransitView(BuildContext context, bool isAr) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'رحلتك الآن' : 'Your Ride Now', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RideRouteMapView(ride: widget.ride),
                  const SizedBox(height: 16),

                  // ETA & Speed status
                  MashwarSectionCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(isAr ? 'الوقت المتوقع للوصول' : 'Estimated Arrival', style: AppTypography.label(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(isAr ? '8:45 ص' : '8:45 AM', style: AppTypography.title().copyWith(color: AppColors.teal)),
                          ],
                        ),
                        Container(width: 1, height: 32, color: AppColors.borderDisabled),
                        Column(
                          children: [
                            Text(isAr ? 'المسافة المتبقية' : 'Distance Remaining', style: AppTypography.label(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(isAr ? '42 كم' : '42 km', style: AppTypography.title().copyWith(color: AppColors.navy)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Emergency SOS Button (Page 29)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBECE9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr ? 'طوارئ: مشاركة خط السير مع جهات الاتصال' : 'Emergency SOS: Share live path with contacts',
                            style: AppTypography.label(color: AppColors.danger),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const EmergencySosSheet(),
                            );
                          },
                          child: Text(isAr ? 'SOS طوارئ' : 'SOS', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  MashwarCommunicationBar(
                    chatLabel: isAr ? 'محادثة شات' : 'Chat',
                    callLabel: isAr ? 'اتصل بالسائق' : 'Call Driver',
                    shareLabel: isAr ? 'مشاركة المسار' : 'Share Trip',
                    onChat: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            driverName: widget.ride.driverName,
                            driverCar: widget.ride.driverCar,
                            tripRoute: context.trRoute('${widget.ride.fromCity} ← ${widget.ride.toCity}'),
                          ),
                        ),
                      );
                    },
                    onCall: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isAr ? 'الاتصال بـ ${widget.ride.driverPhone}' : 'Calling ${widget.ride.driverPhone}')),
                      );
                    },
                    onShare: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const ShareTripSheet(),
                      );
                    },
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

  // Phase 3: الرحلة اكتملت (Page 29)
  Widget _buildCompletedView(BuildContext context, bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 16),
              Text(isAr ? 'وصلت بالسلامة!' : 'Arrived Safely!', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'رحلتك مع ${widget.ride.driverName.split(' ').first} اكتملت بنجاح.'
                    : 'Your ride with ${widget.ride.driverName.split(' ').first} has completed successfully.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: 24),

              // Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Column(
                  children: [
                    _buildRow(isAr ? 'المسار' : 'Route', context.trRoute('${widget.ride.fromCity} ← ${widget.ride.toCity}')),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(isAr ? 'الإجمالي' : 'Total', '${widget.ride.pricePerSeat} ${isAr ? "ج نقداً" : "EGP Cash"}', isBold: true),
                  ],
                ),
              ),
              const Spacer(flex: 4),

              MashwarButton(
                text: isAr ? 'تقييم السائق والمشوار' : 'Rate Driver & Trip',
                icon: const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RateTripScreen(
                        driverName: widget.ride.driverName,
                        route: context.trRoute('${widget.ride.fromCity} ← ${widget.ride.toCity}'),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              MashwarButton(
                text: isAr ? 'احجز رحلة تانية' : 'Book Another Ride',
                variant: MashwarButtonVariant.secondary,
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReportIssueScreen(),
                    ),
                  );
                },
                child: Text(isAr ? 'أبلّغ عن مشكلة' : 'Report an issue', style: AppTypography.bodySecondary(color: AppColors.danger)),
              ),
              const SizedBox(height: 24),
            ],
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

