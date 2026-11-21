import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/user_model.dart';
import '../../state/auth_provider.dart';
import '../../state/rides_provider.dart';
import '../booking/booking_review_screen.dart';
import '../chat/chat_screen.dart';
import '../parcel/send_parcel_screen.dart';
import 'widgets/ride_route_map_view.dart';

enum RideDetailsState {
  available,  // متاحة
  full,       // مكتملة
  cancelled,  // ملغاة
  ladiesOnly, // للسيدات فقط
  error,      // خطأ
}

class RideDetailsScreen extends StatefulWidget {
  const RideDetailsScreen({
    super.key,
    required this.ride,
    this.initialState = RideDetailsState.available,
  });

  final RideModel ride;
  final RideDetailsState initialState;

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  late RideDetailsState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    final rides = context.watch<RidesProvider>();
    final auth = context.watch<AuthProvider>();
    final isAr = context.isArabic;

    // Determine state
    if (widget.ride.remainingSeats == 0 && _state == RideDetailsState.available) {
      _state = RideDetailsState.full;
    } else if (widget.ride.isLadiesOnly && auth.user.gender != UserGender.female && _state == RideDetailsState.available) {
      _state = RideDetailsState.ladiesOnly;
    }

    if (_state == RideDetailsState.error) {
      return _buildErrorView(isAr);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'تفاصيل الرحلة' : 'Ride Details', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.navy),
            tooltip: isAr ? 'مشاركة الرحلة' : 'Share Ride',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم نسخ رابط الرحلة: مشوار ${widget.ride.fromCity} إلى ${widget.ride.toCity}'
                        : 'Ride link copied: MASHWAR ${widget.ride.fromCity} to ${widget.ride.toCity}',
                  ),
                  backgroundColor: AppColors.teal,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            if (isWide) {
              return _buildWideLayout(context, rides, isAr, constraints);
            }
            return _buildMobileLayout(context, rides, isAr);
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    RidesProvider rides,
    bool isAr,
    BoxConstraints constraints,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: AppDimens.space20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Interactive Map & Waypoint details
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RideRouteMapView(ride: widget.ride),
                      const SizedBox(height: AppDimens.space16),
                      _buildTripDetailsContainer(context, isAr),
                      const SizedBox(height: AppDimens.space16),
                      _buildCoPassengersCard(isAr),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.space24),

              // Right Column: Driver, Amenities, Safety and Booking Card
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusBanners(isAr),
                      _buildDriverHeaderCard(context, isAr),
                      const SizedBox(height: AppDimens.space16),
                      _buildSafetyAndShareCard(context, isAr),
                      const SizedBox(height: AppDimens.space16),

                      // Wide Action Card
                      Container(
                        padding: const EdgeInsets.all(AppDimens.space20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isAr ? 'سعر المقعد' : 'Seat Price',
                                  style: AppTypography.title().copyWith(fontSize: 16),
                                ),
                                Text(
                                  '${widget.ride.pricePerSeat} ${isAr ? "ج.م" : "EGP"}',
                                  style: AppTypography.title(color: AppColors.teal).copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isAr
                                  ? 'المتبقي ${widget.ride.remainingSeats} مقاعد متاحة'
                                  : '${widget.ride.remainingSeats} seats available',
                              style: AppTypography.bodySecondary(),
                            ),
                            const SizedBox(height: 16),
                            _buildBottomButton(context, rides, isAr),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                isAr
                                    ? 'الدفع نقداً للسائق عند الركوب · إلغاء مجاني حتى ساعتين قبل الموعد'
                                    : 'Cash upon boarding to driver · Free cancellation up to 2h before',
                                style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildMobileLayout(BuildContext context, RidesProvider rides, bool isAr) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accurate Interactive Route Map (for Passenger & Driver)
                    RideRouteMapView(ride: widget.ride),
                    const SizedBox(height: AppDimens.space16),

                    // Status Banners
                    _buildStatusBanners(isAr),

                    // Driver Header Card with Instant Chat & Call
                    _buildDriverHeaderCard(context, isAr),
                    const SizedBox(height: AppDimens.space16),

                    // Trip Details Container
                    _buildTripDetailsContainer(context, isAr),
                    const SizedBox(height: AppDimens.space16),

                    // Co-passengers Preview
                    _buildCoPassengersCard(isAr),
                    const SizedBox(height: AppDimens.space16),

                    // Safety & Family Share Card
                    _buildSafetyAndShareCard(context, isAr),
                    const SizedBox(height: AppDimens.space16),

                    // Cash & Report Note
                    Center(
                      child: Text(
                        isAr ? 'الدفع نقداً للسائق عند الركوب · إبلاغ عن الرحلة' : 'Cash upon boarding to driver · Report trip',
                        style: AppTypography.bodySecondary(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),
                  ],
                ),
              ),
            ),

            // Sticky Uber-style Bottom Bar with Seat Price Summary & CTA
            Container(
              padding: const EdgeInsets.fromLTRB(AppDimens.space16, 12, AppDimens.space16, AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderDisabled.withValues(alpha: 0.7))),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _buildBottomButton(context, rides, isAr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanners(bool isAr) {
    if (_state == RideDetailsState.full) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.space12),
        child: AlertBanner(
          message: isAr ? 'الرحلة اكتملت. مفيش كراسي فاضية' : 'This ride is full. No available seats',
          type: AlertBannerType.warning,
        ),
      );
    } else if (_state == RideDetailsState.cancelled) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.space12),
        child: AlertBanner(
          message: isAr ? 'السائق لغى الرحلة' : 'The driver cancelled this ride',
          type: AlertBannerType.danger,
        ),
      );
    } else if (_state == RideDetailsState.ladiesOnly) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.space12),
        child: AlertBanner(
          message: isAr ? 'الرحلة دي للسيدات فقط' : 'This ride is for female passengers only',
          type: AlertBannerType.info,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDriverHeaderCard(BuildContext context, bool isAr) {
    return MashwarFadeSlideIn(
      duration: const Duration(milliseconds: 280),
      offsetY: 10,
      child: MashwarSectionCard(
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.navy.withValues(alpha: 0.14), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          widget.ride.driverName.isNotEmpty ? widget.ride.driverName[0] : 'م',
                          style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 22),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, size: 14, color: AppColors.teal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.ride.driverName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.title().copyWith(fontSize: 16.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.goldSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                                const SizedBox(width: 2),
                                Text(
                                  '${widget.ride.driverRating}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.ride.driverCar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySecondary().copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                MashwarBadge(type: BadgeType.verified, customLabel: isAr ? 'سائق موثق' : 'Verified Driver'),
              ],
            ),
            const SizedBox(height: 14),
            MashwarCommunicationBar(
              chatLabel: isAr ? 'محادثة السائق' : 'Chat Driver',
              callLabel: isAr ? 'اتصال' : 'Call',
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
                  SnackBar(
                    content: Text(
                      isAr
                          ? 'جاري الاتصال بالكابتن ${widget.ride.driverName}...'
                          : 'Calling Captain ${widget.ride.driverName}...',
                    ),
                    backgroundColor: AppColors.teal,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailsContainer(BuildContext context, bool isAr) {
    return MashwarFadeSlideIn(
      duration: const Duration(milliseconds: 320),
      offsetY: 12,
      child: MashwarSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.7),
              ),
              child: MashwarRouteTimeline(
                from: widget.ride.pickupPoint,
                to: widget.ride.dropoffPoint,
                trailingTop: widget.ride.departureTime,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              label: isAr ? 'الموعد' : 'Schedule',
              value: '${context.trDate(widget.ride.departureDate)} ${widget.ride.departureTime} (± 15 ${isAr ? "د" : "mins"})',
            ),
            if (widget.ride.acceptsParcels) ...[
              const Divider(height: 22, color: AppColors.borderDisabled),
              Row(
                children: [
                  MashwarAssetArt(
                    assetPath: 'assets/images/service_parcel.jpg',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(10),
                    fallbackIcon: Icons.inventory_2_rounded,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? 'الطرود' : 'Parcels', style: AppTypography.label(color: AppColors.textSecondary)),
                        Text(
                          isAr ? 'تقبل: صغير ${widget.ride.parcelPrice} ج' : 'Accepts: Small ${widget.ride.parcelPrice} EGP',
                          style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.tealSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SendParcelScreen(ride: widget.ride)),
                      );
                    },
                    child: Text(
                      isAr ? 'ابعت طرد' : 'Send Parcel',
                      style: AppTypography.label(color: AppColors.teal).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, RidesProvider rides, bool isAr) {
    if (_state == RideDetailsState.full) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MashwarButton(
            text: isAr ? 'الرحلة مكتملة' : 'Ride Full',
            onPressed: null, // Disabled
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isAr ? 'تم تفعيل التنبيه لو اتفضى كرسي' : 'Alert enabled for freed seats')),
              );
            },
            child: Text(isAr ? 'نبهني لو اتفضى كرسي' : 'Alert me if a seat opens', style: AppTypography.bodySecondary(color: AppColors.teal)),
          ),
        ],
      );
    }

    if (_state == RideDetailsState.cancelled) {
      return MashwarButton(
        text: isAr ? 'ابحث عن رحلة تانية' : 'Find another ride',
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    if (_state == RideDetailsState.ladiesOnly) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MashwarButton(
            text: isAr ? 'غير متاحة' : 'Not Available',
            onPressed: null, // Disabled
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isAr ? 'شوف رحلات تانية' : 'Browse other rides', style: AppTypography.bodySecondary(color: AppColors.navy)),
          ),
        ],
      );
    }

    // Default Available state -> opens BookingReviewScreen (Page 25)
    return rides.rideMode == RideMode.seats
        ? MashwarButton(
            text: isAr ? 'احجز كرسي · ${widget.ride.pricePerSeat} ج' : 'Book Seat · ${widget.ride.pricePerSeat} EGP',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BookingReviewScreen(ride: widget.ride)),
              );
            },
          )
        : MashwarButton(
            text: isAr ? 'ابعت طرد · ${widget.ride.parcelPrice} ج' : 'Send Parcel · ${widget.ride.parcelPrice} EGP',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SendParcelScreen(ride: widget.ride)),
              );
            },
          );
  }

  Widget _buildErrorView(bool isAr) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'تفاصيل الرحلة' : 'Ride Details', style: AppTypography.title()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              ClipOval(
                child: MashwarAssetArt(
                  assetPath: 'assets/images/service_ride.jpg',
                  width: 96,
                  height: 96,
                  fallbackIcon: Icons.error_outline_rounded,
                  fallbackBg: AppColors.danger.withValues(alpha: 0.1),
                  fallbackColor: AppColors.danger,
                ),
              ),
              const SizedBox(height: AppDimens.space16),
              Text(isAr ? 'تعذر تحميل الرحلة' : 'Could not load ride', style: AppTypography.largeTitle()),
              const SizedBox(height: AppDimens.space8),
              Text(
                isAr ? 'الرحلة دي ممكن تكون اتمسحت أو اتلغت من السائق' : 'This ride may have been deleted or cancelled by driver',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: isAr ? 'ابحث عن رحلة تانية' : 'Find another ride',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isBold = false,
    Widget? actionWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.label(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: isBold
                    ? AppTypography.body().copyWith(fontWeight: FontWeight.w700)
                    : AppTypography.body(),
              ),
            ],
          ),
        ),
        if (actionWidget != null) actionWidget,
      ],
    );
  }

  Widget _buildCoPassengersCard(bool isAr) {
    final openSeats = widget.ride.remainingSeats.clamp(0, 4);
    final bookedSeats = (4 - openSeats).clamp(0, 4);
    final isLadies = widget.ride.isLadiesOnly;
    return MashwarSectionCard(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_outlined, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'من يسافر معك في نفس الرحلة؟' : 'Who is traveling with you?',
                  style: AppTypography.title().copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.chipInactiveBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAr ? '$bookedSeats محجوز · $openSeats متاح' : '$bookedSeats Booked · $openSeats Open',
                  style: AppTypography.label(color: AppColors.teal).copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSeatPill(
                  title: bookedSeats >= 1
                      ? (isAr ? 'سارة م.' : 'Sara M.')
                      : (isAr ? 'مقعد متاح' : 'Open Seat'),
                  subtitle: bookedSeats >= 1
                      ? (isAr ? 'طالبة · موثقة' : 'Student · Verified')
                      : (isAr ? 'متاح للحجز الآن' : 'Available now'),
                  isOccupied: bookedSeats >= 1,
                  icon: bookedSeats >= 1 ? Icons.person_rounded : Icons.airline_seat_recline_normal_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSeatPill(
                  title: bookedSeats >= 2
                      ? (isLadies ? (isAr ? 'منى ح.' : 'Mona H.') : (isAr ? 'أحمد ك.' : 'Ahmed K.'))
                      : (isAr ? 'مقعد متاح' : 'Open Seat'),
                  subtitle: bookedSeats >= 2
                      ? (isLadies
                          ? (isAr ? 'طبيبة · موثقة' : 'Doctor · Verified')
                          : (isAr ? 'مهندس · موثق' : 'Engineer · Verified'))
                      : (isAr ? 'متاح للحجز' : 'Available'),
                  isOccupied: bookedSeats >= 2,
                  icon: bookedSeats >= 2 ? Icons.person_rounded : Icons.airline_seat_recline_normal_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSeatPill(
                  title: bookedSeats >= 3
                      ? (isAr ? 'راكب موثق' : 'Verified Rider')
                      : (isAr ? 'مقعد متاح لك' : 'Available Seat'),
                  subtitle: bookedSeats >= 3
                      ? (isAr ? 'موثق بالهوية' : 'ID Verified')
                      : (isAr ? 'متاح للحجز الآن' : 'Available now'),
                  isOccupied: bookedSeats >= 3,
                  icon: bookedSeats >= 3 ? Icons.person_rounded : Icons.airline_seat_recline_normal_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSeatPill(
                  title: bookedSeats >= 4
                      ? (isAr ? 'راكب موثق' : 'Verified Rider')
                      : (isAr ? 'مقعد إضافي' : 'Extra Seat'),
                  subtitle: bookedSeats >= 4
                      ? (isAr ? 'موثق بالهوية' : 'ID Verified')
                      : (isAr ? 'متاح للحجز' : 'Available'),
                  isOccupied: bookedSeats >= 4,
                  icon: bookedSeats >= 4 ? Icons.person_rounded : Icons.airline_seat_recline_normal_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatPill({
    required String title,
    required String subtitle,
    required bool isOccupied,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOccupied ? const Color(0xFFF8F9FA) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOccupied ? const Color(0xFFE5E5EA) : AppColors.teal.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isOccupied ? AppColors.navy : const Color(0xFFF3F3F4),
            child: Icon(
              icon,
              size: 14,
              color: isOccupied ? Colors.white : AppColors.teal,
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isOccupied ? AppColors.textSecondary : AppColors.teal,
                    fontWeight: isOccupied ? FontWeight.normal : FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyAndShareCard(BuildContext context, bool isAr) {
    return MashwarSectionCard(
      backgroundColor: const Color(0xFFF8F9FA),
      borderColor: const Color(0xFFE5E5EA),
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'الأمان وضمان السفر' : 'Safety & Ride Guarantee',
                  style: AppTypography.title().copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'الدفع نقداً للسائق عند الركوب فقط. بيانات السائق ورقم اللوحة موثقة ومطابقة في سجلات إدارة المرور.'
                : 'Cash payment upon boarding only. Driver license plate and ID verified with national records.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.share_outlined, size: 16, color: AppColors.navy),
            label: Text(
              isAr ? 'مشاركة تفاصيل الرحلة مع عائلتك' : 'Share Trip Details with Family',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم نسخ رسالة تفاصيل الرحلة لمشاركتها عبر واتساب'
                        : 'Trip details message copied for WhatsApp sharing',
                  ),
                  backgroundColor: AppColors.navy,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
