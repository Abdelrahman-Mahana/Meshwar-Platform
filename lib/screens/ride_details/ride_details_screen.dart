import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../core/widgets/mashwar_worksite_icons.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/user_model.dart';
import '../../state/auth_provider.dart';
import '../../state/rides_provider.dart';
import '../booking/booking_review_screen.dart';
import '../chat/chat_screen.dart';
import '../parcel/send_parcel_screen.dart';
import 'widgets/ride_route_map_view.dart';

enum RideDetailsState {
  available,
  full,
  cancelled,
  ladiesOnly,
  error,
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

    if (widget.ride.remainingSeats == 0 &&
        _state == RideDetailsState.available) {
      _state = RideDetailsState.full;
    } else if (widget.ride.isLadiesOnly &&
        auth.user.gender != UserGender.female &&
        _state == RideDetailsState.available) {
      _state = RideDetailsState.ladiesOnly;
    }

    if (_state == RideDetailsState.error) {
      return _buildErrorView(isAr);
    }

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'تفاصيل الرحلة والطرود' : 'Trip & Parcel Details',
          style: AppTypography.title().copyWith(fontSize: 17.5),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.navy),
            tooltip: isAr ? 'مشاركة الرحلة' : 'Share Trip',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم نسخ رابط الرحلة: مشوار ${widget.ride.fromCity} إلى ${widget.ride.toCity}'
                        : 'Trip link copied: MASHWAR ${widget.ride.fromCity} to ${widget.ride.toCity}',
                  ),
                  backgroundColor: AppColors.emerald,
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
              return _buildWideLayout(context, rides, isAr);
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
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space24,
            vertical: AppDimens.space20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      Container(
                        padding: const EdgeInsets.all(AppDimens.space20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusCard),
                          border: Border.all(color: AppColors.slateBorder),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: 0.04),
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
                                  isAr ? 'مساهمة المقعد' : 'Seat Contribution',
                                  style: AppTypography.title()
                                      .copyWith(fontSize: 16),
                                ),
                                Text(
                                  '${widget.ride.pricePerSeat} ${isAr ? "ر.ق" : "QAR"}',
                                  style: AppTypography.title(
                                    color: AppColors.cobalt,
                                  ).copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr
                                  ? 'المتبقي ${widget.ride.remainingSeats} مقاعد متاحة${widget.ride.acceptsParcels ? " · توصيل الطرود: ${widget.ride.parcelPrice} ر.ق" : ""}'
                                  : '${widget.ride.remainingSeats} seats left${widget.ride.acceptsParcels ? " · Parcels: ${widget.ride.parcelPrice} QAR" : ""}',
                              style: AppTypography.bodySecondary(),
                            ),
                            const SizedBox(height: 16),
                            _buildDualActionButtons(context, rides, isAr),
                            const SizedBox(height: 12),
                            Text(
                              isAr
                                  ? 'الدفع نقداً أو بتحويل مباشر مع المسافر · إلغاء مجاني قبل الموعد'
                                  : 'Cash or direct transfer on handover · Free cancellation prior to departure',
                              style: AppTypography.label(
                                color: AppColors.textSecondary,
                              ).copyWith(fontSize: 11),
                              textAlign: TextAlign.center,
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

  Widget _buildMobileLayout(
    BuildContext context,
    RidesProvider rides,
    bool isAr,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RideRouteMapView(ride: widget.ride),
                    const SizedBox(height: AppDimens.space16),
                    _buildStatusBanners(isAr),
                    _buildDriverHeaderCard(context, isAr),
                    const SizedBox(height: AppDimens.space16),
                    _buildTripDetailsContainer(context, isAr),
                    const SizedBox(height: AppDimens.space16),
                    _buildCoPassengersCard(isAr),
                    const SizedBox(height: AppDimens.space16),
                    _buildSafetyAndShareCard(context, isAr),
                    const SizedBox(height: AppDimens.space24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: AppColors.slateBorder),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _buildDualActionButtons(context, rides, isAr),
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
          message: isAr
              ? 'اكتملت مقاعد الركاب في هذه الرحلة'
              : 'Passenger seats are full for this ride',
          type: AlertBannerType.warning,
        ),
      );
    } else if (_state == RideDetailsState.cancelled) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.space12),
        child: AlertBanner(
          message: isAr
              ? 'قام المسافر بإلغاء هذه الرحلة'
              : 'The traveler cancelled this ride',
          type: AlertBannerType.danger,
        ),
      );
    } else if (_state == RideDetailsState.ladiesOnly) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.space12),
        child: AlertBanner(
          message: isAr
              ? 'مقاعد هذه الرحلة مخصصة للسيدات فقط'
              : 'Seats on this ride are for female passengers only',
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
                MashwarUserAvatar(
                  avatarUrl: null,
                  fullName: widget.ride.driverName,
                  size: 54,
                  borderWidth: 2.0,
                  borderColor: AppColors.gold,
                  autoCommunityPortrait: true,
                  showVerifiedBadge: widget.ride.isVerified,
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
                              style: AppTypography.title()
                                  .copyWith(fontSize: 16.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
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
                                  color: AppColors.gold,
                                ),
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
                        style: AppTypography.bodySecondary()
                            .copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                MashwarBadge(
                  type: BadgeType.verified,
                  customLabel: isAr ? 'مسافر موثق' : 'Verified',
                ),
              ],
            ),
            const SizedBox(height: 14),
            MashwarCommunicationBar(
              chatLabel: isAr ? 'محادثة المسافر' : 'Chat Traveler',
              callLabel: isAr ? 'اتصال' : 'Call',
              onChat: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      driverName: widget.ride.driverName,
                      driverCar: widget.ride.driverCar,
                      tripRoute: context.trRoute(
                        '${widget.ride.fromCity} ← ${widget.ride.toCity}',
                      ),
                    ),
                  ),
                );
              },
              onCall: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr
                          ? 'جاري الاتصال بـ ${widget.ride.driverName}...'
                          : 'Calling ${widget.ride.driverName}...',
                    ),
                    backgroundColor: AppColors.emerald,
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
                color: AppColors.slateBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: MashwarRouteTimeline(
                from: widget.ride.pickupPoint,
                to: widget.ride.dropoffPoint,
                trailingTop: widget.ride.departureTime,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              label: isAr ? 'موعد الانطلاق' : 'Departure Schedule',
              value:
                  '${context.trDate(widget.ride.departureDate)} · ${widget.ride.departureTime} (± 15 ${isAr ? "د" : "mins"})',
            ),
            if (widget.ride.stopoverCity != null &&
                widget.ride.stopoverCity!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                label: isAr ? 'محطة المرور' : 'Stopover City',
                value: context.trCity(widget.ride.stopoverCity!),
              ),
            ],
            if (widget.ride.notes != null &&
                widget.ride.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                label: isAr ? 'ملاحظات المسافر' : 'Traveler Notes',
                value: widget.ride.notes!,
              ),
            ],
            if (widget.ride.acceptsParcels) ...[
              const Divider(height: 22, color: AppColors.slateBorder),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.indigoSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.indigo.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const MashwarServicePillarIcon(
                      pillar: MashwarServicePillar.routeParcels,
                      size: 40,
                      showSurface: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'يقبل توصيل طرود أو أغراض على طريقه'
                                : 'Accepts Parcels & Items Along Route',
                            style: AppTypography.body().copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            isAr
                                ? 'رسوم التوصيل: ${widget.ride.parcelPrice} ر.ق · محمي بكود استلام وتسليم OTP'
                                : 'Delivery fee: ${widget.ride.parcelPrice} QAR · OTP-protected handover',
                            style: AppTypography.label(
                              color: AppColors.indigo,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDualActionButtons(
    BuildContext context,
    RidesProvider rides,
    bool isAr,
  ) {
    if (_state == RideDetailsState.cancelled) {
      return MashwarButton(
        text: isAr ? 'ابحث عن رحلة أخرى' : 'Find another ride',
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    final parcelBtn = widget.ride.acceptsParcels
        ? OutlinedButton.icon(
            key: const ValueKey('ride_details_send_parcel_btn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.indigo,
              backgroundColor: AppColors.indigoSurface,
              side: BorderSide(
                color: AppColors.indigo.withValues(alpha: 0.4),
                width: 1.2,
              ),
              minimumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SendParcelScreen(ride: widget.ride),
                ),
              );
            },
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: Text(
              isAr
                  ? 'أرسل طرداً / طلباً مع هذا المسافر (${widget.ride.parcelPrice} ر.ق)'
                  : 'Send a Parcel / Item with Traveler (${widget.ride.parcelPrice} QAR)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
              ),
            ),
          )
        : null;

    if (_state == RideDetailsState.full) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MashwarButton(
            text: isAr ? 'المقاعد مكتملة' : 'Seats Full',
            onPressed: null,
          ),
          if (parcelBtn != null) ...[
            const SizedBox(height: 10),
            parcelBtn,
          ],
        ],
      );
    }

    if (_state == RideDetailsState.ladiesOnly) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MashwarButton(
            text: isAr ? 'المقاعد للسيدات فقط' : 'Seats Ladies Only',
            onPressed: null,
          ),
          if (parcelBtn != null) ...[
            const SizedBox(height: 10),
            parcelBtn,
          ],
        ],
      );
    }

    final seatBtn = MashwarButton(
      text: isAr
          ? 'حجز مقعد في الرحلة · ${widget.ride.pricePerSeat} ر.ق'
          : 'Book a Seat · ${widget.ride.pricePerSeat} QAR',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingReviewScreen(ride: widget.ride),
          ),
        );
      },
    );

    if (parcelBtn == null) {
      return seatBtn;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        seatBtn,
        const SizedBox(height: 10),
        parcelBtn,
      ],
    );
  }

  Widget _buildErrorView(bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'تفاصيل الرحلة' : 'Ride Details',
          style: AppTypography.title(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                isAr ? 'تعذر تحميل الرحلة' : 'Could not load ride',
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: AppDimens.space8),
              Text(
                isAr
                    ? 'قد تكون هذه الرحلة محذوفة أو ملغاة'
                    : 'This ride may have been removed or cancelled',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: isAr ? 'ابحث عن رحلة أخرى' : 'Find another ride',
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
        ),
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
              const Icon(
                Icons.group_outlined,
                size: 18,
                color: AppColors.cobalt,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'من يسافر معك في نفس الرحلة؟'
                      : 'Who is traveling with you?',
                  style: AppTypography.title().copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emeraldSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAr
                      ? '$bookedSeats محجوز · $openSeats متاح'
                      : '$bookedSeats Booked · $openSeats Open',
                  style: AppTypography.label(color: AppColors.emerald)
                      .copyWith(fontSize: 11, fontWeight: FontWeight.bold),
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
                      ? (isAr ? 'نورة م.' : 'Noura M.')
                      : (isAr ? 'مقعد متاح' : 'Open Seat'),
                  subtitle: bookedSeats >= 1
                      ? (isAr ? 'طالبة · موثقة' : 'Student · Verified')
                      : (isAr ? 'متاح للحجز الآن' : 'Available now'),
                  isOccupied: bookedSeats >= 1,
                  icon: bookedSeats >= 1
                      ? Icons.person_rounded
                      : Icons.airline_seat_recline_normal_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSeatPill(
                  title: bookedSeats >= 2
                      ? (isLadies
                          ? (isAr ? 'آمنة ح.' : 'Amna H.')
                          : (isAr ? 'حمد ك.' : 'Hamad K.'))
                      : (isAr ? 'مقعد متاح' : 'Open Seat'),
                  subtitle: bookedSeats >= 2
                      ? (isLadies
                          ? (isAr ? 'طبيبة · موثقة' : 'Doctor · Verified')
                          : (isAr ? 'مهندس · موثق' : 'Engineer · Verified'))
                      : (isAr ? 'متاح للحجز' : 'Available'),
                  isOccupied: bookedSeats >= 2,
                  icon: bookedSeats >= 2
                      ? Icons.person_rounded
                      : Icons.airline_seat_recline_normal_rounded,
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
                  icon: bookedSeats >= 3
                      ? Icons.person_rounded
                      : Icons.airline_seat_recline_normal_rounded,
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
                  icon: bookedSeats >= 4
                      ? Icons.person_rounded
                      : Icons.airline_seat_recline_normal_rounded,
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
        color: isOccupied ? AppColors.slateBg : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOccupied
              ? AppColors.slateBorder
              : AppColors.emerald.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isOccupied ? AppColors.navy : AppColors.emeraldSurface,
            child: Icon(
              icon,
              size: 14,
              color: isOccupied ? Colors.white : AppColors.emerald,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isOccupied ? AppColors.textSecondary : AppColors.emerald,
                    fontWeight:
                        isOccupied ? FontWeight.normal : FontWeight.bold,
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
      backgroundColor: Colors.white,
      borderColor: AppColors.slateBorder,
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: AppColors.emerald,
              ),
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
                ? 'هوية المسافر وبيانات المركبة موثقة، وجميع الطرود المرسلة على الطريق محمية بكود الاستلام والتسليم OTP.'
                : 'Traveler identity and vehicle details are verified, and all route parcels use OTP handover codes.',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.slateBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.share_outlined,
              size: 16,
              color: AppColors.navy,
            ),
            label: Text(
              isAr
                  ? 'مشاركة تفاصيل الرحلة مع عائلتك'
                  : 'Share Trip Details with Family',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAr
                        ? 'تم نسخ رسالة تفاصيل الرحلة لمشاركتها'
                        : 'Trip details copied for sharing',
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
