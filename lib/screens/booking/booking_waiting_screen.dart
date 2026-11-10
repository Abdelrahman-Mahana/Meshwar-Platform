import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
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
  int _secondsLeft = 28 * 60 + 40; // 28:40 from Page 26
  Timer? _timer;
  bool _isTimedOut = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        setState(() => _isTimedOut = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    if (_isTimedOut) {
      return _buildTimedOutView(isAr);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Developer simulation shortcuts to test Confirmed / Rejected
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BookingResultScreen(
                    ride: widget.ride,
                    isConfirmed: true,
                    totalPrice: widget.totalPrice,
                  ),
                ),
              );
            },
            child: Text(isAr ? 'قبول (تجربة)' : 'Accept (Demo)', style: AppTypography.label(color: AppColors.teal)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BookingResultScreen(
                    ride: widget.ride,
                    isConfirmed: false,
                    totalPrice: widget.totalPrice,
                  ),
                ),
              );
            },
            child: Text(isAr ? 'رفض (تجربة)' : 'Decline (Demo)', style: AppTypography.label(color: AppColors.danger)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const SizedBox(height: AppDimens.space32),
              // Circular countdown badge (Page 26)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 3),
                ),
                child: Center(
                  child: Text(
                    _formattedTime,
                    style: AppTypography.title().copyWith(fontSize: 22, color: AppColors.navy),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space24),
              Text(
                isAr ? 'بانتظار رد ${widget.ride.driverName.split(' ').first}' : 'Waiting for ${widget.ride.driverName.split(' ').first}\'s response',
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'هنبلغك أول ما يرد. لو ما ردّش في الوقت ده هيتلغي الطلب.'
                    : 'We will notify you once they reply. If no response in time, the request will expire.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: AppDimens.space32),

              // Ride info summary card
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
                    _buildRow(isAr ? 'الرحلة' : 'Trip', context.trRoute('${widget.ride.fromCity} ← ${widget.ride.toCity}')),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(isAr ? 'الموعد' : 'Schedule', '${context.trDate(widget.ride.departureDate)} ${widget.ride.departureTime}'),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(isAr ? 'السائق' : 'Driver', widget.ride.driverName),
                  ],
                ),
              ),
              const Spacer(),
              MashwarButton(
                text: isAr ? 'إلغاء الطلب' : 'Cancel Request',
                variant: MashwarButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? 'تم إلغاء طلب الحجز' : 'Booking request cancelled')),
                  );
                },
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }

  // Timeout view (Page 26)
  Widget _buildTimedOutView(bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(Icons.timer_off_outlined, size: 72, color: AppColors.warning),
              const SizedBox(height: AppDimens.space16),
              Text(isAr ? 'الوقت خلص' : 'Time Expired', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                isAr ? 'السائق ما ردّش في الوقت المحدد. حاول تبحث عن رحلة تانية' : 'Driver didn\'t respond in time. Try finding another ride',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: isAr ? 'ابحث عن رحلة تانية' : 'Search other rides',
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
        Text(value, style: AppTypography.body()),
      ],
    );
  }
}
