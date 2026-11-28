import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../data/models/ride_model.dart';
import '../../state/rides_provider.dart';
import 'booking_result_screen.dart';

class BookingWaitingScreen extends StatefulWidget {
  const BookingWaitingScreen({
    super.key,
    required this.ride,
    required this.seatsCount,
    required this.totalPrice,
  });

  final RideModel ride;
  final int seatsCount;
  final int totalPrice;

  @override
  State<BookingWaitingScreen> createState() => _BookingWaitingScreenState();
}

class _BookingWaitingScreenState extends State<BookingWaitingScreen> {
  int _secondsLeft = 28 * 60 + 40;
  Timer? _countdownTimer;
  bool _isTimedOut = false;
  bool _isRefreshing = false;
  bool _hasNavigated = false;

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        setState(() => _isTimedOut = true);
        _cancelTimers();
      }
    });
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  RideModel? _findTrackedRide(RidesProvider? rides) {
    if (rides == null) return null;
    if (rides.activeBooking?.id == widget.ride.id) {
      return rides.activeBooking;
    }
    for (final r in rides.bookedRides) {
      if (r.id == widget.ride.id) return r;
    }
    for (final r in rides.allRides) {
      if (r.id == widget.ride.id) return r;
    }
    return null;
  }

  void _checkBookingStatusAndTransition(RidesProvider? rides) {
    if (_hasNavigated || _isTimedOut) return;
    final tracked = _findTrackedRide(rides);
    if (tracked == null) return;
    final status = tracked.status.trim().toLowerCase();
    final isConfirmed = status == 'confirmed' || status == 'accepted';
    final isRejected = status == 'rejected' || status == 'cancelled';
    if (!isConfirmed && !isRejected) return;

    _hasNavigated = true;
    _cancelTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MashwarPageRoute(
          builder: (_) => BookingResultScreen(
            ride: tracked,
            isConfirmed: isConfirmed,
            totalPrice: widget.totalPrice,
          ),
        ),
      );
    });
  }

  Future<void> _handleRefreshStatus(bool isAr) async {
    if (_isRefreshing) return;
    final rides = context.read<RidesProvider?>();
    if (rides == null) return;
    setState(() => _isRefreshing = true);
    try {
      await rides.loadRides();
      if (!mounted) return;
      _checkBookingStatusAndTransition(rides);
      if (!_hasNavigated) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'لا يزال الطلب بانتظار رد السائق — تم تحديث الحالة'
                  : 'Still waiting for driver response — status refreshed',
            ),
            backgroundColor: AppColors.navy,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _handleCancelRequest(bool isAr) {
    _cancelTimers();
    context.read<RidesProvider?>()?.cancelBooking();
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تم إلغاء طلب الحجز بنجاح' : 'Booking request cancelled',
        ),
      ),
    );
  }

  String get _formattedTime {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final rides = Provider.of<RidesProvider?>(context);
    _checkBookingStatusAndTransition(rides);

    if (_isTimedOut) {
      return _buildTimedOutView(isAr);
    }

    final driverFirstName = widget.ride.driverName.trim().isNotEmpty
        ? widget.ride.driverName.trim().split(' ').first
        : (isAr ? 'المسافر' : 'Driver');

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        title: Text(
          isAr ? 'طلب حجز قيد التأكيد' : 'Booking Pending',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          tooltip: isAr ? 'إغلاق' : 'Close',
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () {
            _cancelTimers();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space24,
                vertical: AppDimens.space16,
              ),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  children: [
                    // Executive Countdown Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.space24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.slateBorder,
                          width: AppDimens.borderWidth,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.slateBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.navy,
                                width: 2.0,
                              ),
                            ),
                            child: Center(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  _formattedTime,
                                  style: AppTypography.title(
                                    color: AppColors.navy,
                                  ).copyWith(fontSize: 22),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimens.space16),
                          Text(
                            isAr
                                ? 'بانتظار رد $driverFirstName'
                                : "Waiting for $driverFirstName's response",
                            textAlign: TextAlign.center,
                            style: AppTypography.largeTitle().copyWith(
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAr
                                ? 'سنبلغك فور قبول الطلب وإصدار رمز الصعود QR و OTP. في حال انتهاء المهلة يُلغى الطلب تلقائياً.'
                                : 'We will notify you as soon as they confirm and issue your QR & OTP pass. Request expires automatically if unanswered.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySecondary(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Ride Info Summary Card
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(
                          color: AppColors.slateBorder,
                          width: AppDimens.borderWidth,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.slateBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.slateBorder,
                                width: AppDimens.borderWidth,
                              ),
                            ),
                            child: MashwarRouteTimeline(
                              from: context.trCity(widget.ride.fromCity),
                              to: context.trCity(widget.ride.toCity),
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRow(
                            isAr ? 'الموعد' : 'Schedule',
                            '${context.trDate(widget.ride.departureDate)} · ${widget.ride.departureTime}',
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.slateBorder,
                          ),
                          _buildRow(
                            isAr ? 'المسافر' : 'Driver',
                            widget.ride.driverName,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.slateBorder,
                          ),
                          _buildRow(
                            isAr ? 'المقاعد والإجمالي' : 'Seats & Total',
                            '${widget.seatsCount} · ${widget.totalPrice} ${isAr ? "ر.ق" : "QAR"}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),
                    MashwarButton(
                      key: const ValueKey('booking_waiting_refresh_btn'),
                      text: isAr ? 'تحديث حالة الطلب' : 'Refresh Booking Status',
                      isLoading: _isRefreshing,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => _handleRefreshStatus(isAr),
                    ),
                    const SizedBox(height: 10),
                    MashwarButton(
                      key: const ValueKey('booking_waiting_cancel_btn'),
                      text: isAr ? 'إلغاء الطلب' : 'Cancel Request',
                      variant: MashwarButtonVariant.secondary,
                      onPressed: () => _handleCancelRequest(isAr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimedOutView(bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.warningBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_off_outlined,
                  size: 38,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                isAr ? 'انتهت مهلة الانتظار' : 'Time Expired',
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'لم يتمكن المسافر من الرد خلال المهلة المحددة. يمكنك اختيار رحلة أخرى متاحة فوراً.'
                    : "Driver didn't respond in time. Try finding another available ride.",
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: isAr ? 'البحث عن رحلة أخرى' : 'Search other rides',
                onPressed: () {
                  context.read<RidesProvider?>()?.cancelBooking();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.label(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.body(),
          ),
        ),
      ],
    );
  }
}
