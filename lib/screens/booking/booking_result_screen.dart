import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
import '../../state/rides_provider.dart';
import '../trip/active_trip_screen.dart';

class BookingResultScreen extends StatelessWidget {
  const BookingResultScreen({
    super.key,
    required this.ride,
    required this.isConfirmed,
    required this.totalPrice,
  });

  final RideModel ride;
  final bool isConfirmed;
  final int totalPrice;

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    if (!isConfirmed) {
      return _buildRejectedView(context, isAr);
    }

    return _buildConfirmedView(context, isAr);
  }

  Widget _buildConfirmedView(BuildContext context, bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Checkmark Circle
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
              Text(isAr ? 'تم تأكيد حجزك' : 'Booking Confirmed', style: AppTypography.largeTitle()),
              const SizedBox(height: 4),
              Text(
                isAr ? '${ride.driverName.split(" ").first} وافق على طلبك' : '${ride.driverName.split(" ").first} accepted your request',
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: 24),

              // Summary card
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
                    _buildRow(isAr ? 'الموعد' : 'Schedule', '${context.trDate(ride.departureDate)}، ${ride.departureTime}'),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(isAr ? 'المسار' : 'Route', context.trRoute('${ride.fromCity} ← ${ride.toCity}')),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(isAr ? 'نقطة الصعود' : 'Pickup Point', ride.pickupPoint),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(isAr ? 'الإجمالي' : 'Total Price', '$totalPrice ${isAr ? "ج نقداً" : "EGP Cash"}', isBold: true),
                  ],
                ),
              ),
              const Spacer(),

              // Primary CTA (Page 27)
              MashwarButton(
                text: isAr ? 'تفاصيل الرحلة' : 'Ride Details',
                onPressed: () {
                  context.read<RidesProvider>().confirmBooking(ride);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ActiveTripScreen(ride: ride),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text(
                  isAr ? 'الرجوع للرئيسية' : 'Back to Home',
                  style: AppTypography.bodySecondary(color: AppColors.navy),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Declined state (Page 27)
  Widget _buildRejectedView(BuildContext context, bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 16),
              Text(isAr ? 'للأسف، السائق اعتذر' : 'Unfortunately, Driver Declined', style: AppTypography.largeTitle()),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? '${ride.driverName.split(" ").first} مش هيقدر ياخدك المرة دي.'
                    : '${ride.driverName.split(" ").first} cannot take you this time.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: 24),

              // Alternative rides suggestions card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isAr ? 'لقينا رحلات تانية قريبة من نفس الوقت:' : 'Found other rides close to the same time:', style: AppTypography.label()),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? 'رحلة 8:00 ص · أحمد علي · 60 ج' : '8:00 AM Ride · Ahmed Ali · 60 EGP',
                      style: AppTypography.body().copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              MashwarButton(
                text: isAr ? 'ابحث عن رحلة تانية' : 'Search Other Rides',
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text(
                  isAr ? 'الرجوع للرئيسية' : 'Back to Home',
                  style: AppTypography.bodySecondary(color: AppColors.navy),
                ),
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
