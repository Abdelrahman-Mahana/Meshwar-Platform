import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
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
        if (mounted) setState(() => _secondsLeft--);
      } else {
        if (mounted) setState(() => _isTimedOut = true);
        timer.cancel();
      }
    });

    // Realistic driver response simulation for interactive prototype
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted && !_isTimedOut) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BookingResultScreen(
              ride: widget.ride,
              isConfirmed: true,
              totalPrice: widget.totalPrice,
            ),
          ),
        );
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
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'طلب حجز معلق' : 'Booking Pending',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: AppDimens.space16),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 280),
                child: Column(
                  children: [
                    // Deep Navy countdown hero + 3D car badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.navy, Color(0xFF173D61)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gold, width: 3.5),
                            ),
                            child: Center(
                              child: Text(
                                _formattedTime,
                                style: AppTypography.title().copyWith(fontSize: 22, color: AppColors.navy),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isAr ? 'بانتظار رد ${widget.ride.driverName.split(' ').first}' : 'Waiting for ${widget.ride.driverName.split(' ').first}\'s response',
                            textAlign: TextAlign.center,
                            style: AppTypography.largeTitle(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAr
                                ? 'هنبلغك أول ما يرد. لو ما ردّش في الوقت ده هيتلغي الطلب.'
                                : 'We will notify you once they reply. If no response in time, the request will expire.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySecondary(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space20),

                    // Ride info summary card
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
                              from: context.trCity(widget.ride.fromCity),
                              to: context.trCity(widget.ride.toCity),
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRow(isAr ? 'الموعد' : 'Schedule', '${context.trDate(widget.ride.departureDate)} ${widget.ride.departureTime}'),
                          const Divider(height: 20, color: AppColors.borderDisabled),
                          _buildRow(isAr ? 'السائق' : 'Driver', widget.ride.driverName),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),
                    MashwarButton(
                      text: isAr ? 'إلغاء الطلب' : 'Cancel Request',
                      variant: MashwarButtonVariant.secondary,
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        messenger.showSnackBar(
                          SnackBar(content: Text(isAr ? 'تم إلغاء طلب الحجز' : 'Booking request cancelled')),
                        );
                      },
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

  // Timeout view (Page 26)
  Widget _buildTimedOutView(bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
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
