import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
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
      backgroundColor: Colors.white,
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
          // Developer simulation helper to switch between phases
          TextButton(
            onPressed: () => setState(() => _phase = TripTrackingPhase.inTransit),
            child: Text(isAr ? 'بدء الرحلة (تجربة)' : 'Start Trip (Demo)', style: AppTypography.label(color: AppColors.teal)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${context.trDate(widget.ride.departureDate)}، ${widget.ride.departureTime}', style: AppTypography.bodySecondary()),
                  MashwarBadge(type: BadgeType.confirmed, customLabel: isAr ? 'مؤكد' : 'Confirmed'),
                ],
              ),
              const SizedBox(height: 16),

              // Big countdown block (Page 29)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7EA),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.gold),
                ),
                child: Column(
                  children: [
                    Text(isAr ? 'الرحلة هتبدأ بعد' : 'Trip starts in', style: AppTypography.label(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? '3 ساعات' : '3 Hours',
                      style: AppTypography.largeTitle().copyWith(fontSize: 32, color: AppColors.navy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details card
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Column(
                  children: [
                    _buildRow(isAr ? 'السائق' : 'Driver', widget.ride.driverName),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(isAr ? 'السيارة' : 'Vehicle', widget.ride.driverCar),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(isAr ? 'نقطة الصعود' : 'Pickup Point', widget.ride.pickupPoint),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(isAr ? 'المسار' : 'Route', context.trRoute('${widget.ride.fromCity} ← ${widget.ride.toCity}')),
                  ],
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: MashwarButton(
                      text: isAr ? 'اتصل بالسائق' : 'Call Driver',
                      icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isAr ? 'الاتصال بـ ${widget.ride.driverPhone}' : 'Calling ${widget.ride.driverPhone}')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MashwarButton(
                      text: isAr ? 'محادثة شات' : 'Chat',
                      variant: MashwarButtonVariant.secondary,
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.navy, size: 20),
                      onPressed: () {
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MashwarButton(
                text: isAr ? 'مشاركة الرحلة' : 'Share Ride',
                variant: MashwarButtonVariant.secondary,
                icon: const Icon(Icons.share_outlined, color: AppColors.navy, size: 20),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ShareTripSheet(),
                  );
                },
              ),
              const SizedBox(height: 8),
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
    );
  }

  // Phase 2: أثناء الرحلة (Page 29)
  Widget _buildInTransitView(BuildContext context, bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'رحلتك الآن' : 'Your Ride Now', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _phase = TripTrackingPhase.completed),
            child: Text(isAr ? 'إنهاء الرحلة (تجربة)' : 'End Ride (Demo)', style: AppTypography.label(color: AppColors.teal)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accurate Live route map (Page 29)
              RideRouteMapView(ride: widget.ride),
              const SizedBox(height: 16),

              // ETA & Speed status
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(isAr ? 'الوقت المتوقع للوصول' : 'Estimated Arrival', style: AppTypography.label(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('8:45 ص', style: AppTypography.title().copyWith(color: AppColors.teal)),
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
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.danger),
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
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: MashwarButton(
                      text: isAr ? 'اتصل بالسائق' : 'Call Driver',
                      icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isAr ? 'الاتصال بـ ${widget.ride.driverPhone}' : 'Calling ${widget.ride.driverPhone}')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MashwarButton(
                      text: isAr ? 'محادثة شات' : 'Chat',
                      variant: MashwarButtonVariant.secondary,
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.navy, size: 20),
                      onPressed: () {
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
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
                text: isAr ? 'تقييم السائق والمشوار ★' : 'Rate Driver & Trip ★',
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
        Text(
          value,
          style: isBold
              ? AppTypography.body().copyWith(fontWeight: FontWeight.w700)
              : AppTypography.body(),
        ),
      ],
    );
  }
}
