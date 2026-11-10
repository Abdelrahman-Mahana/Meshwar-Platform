import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.ride});

  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;

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
              const SizedBox(height: AppDimens.space16),
              // Checkmark Circle (Page 12)
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                isAr ? 'تم تأكيد حجزك' : 'Booking Confirmed',
                style: AppTypography.largeTitle(),
              ),
              const SizedBox(height: 4),
              Text(
                isAr ? 'السائق وافق على طلبك' : 'Driver has accepted your request',
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: AppDimens.space24),

              // Booking Details Card
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
                    _buildRow(
                      isAr ? 'الموعد' : 'Date & Time',
                      '${AppStrings.translateDate(ride.departureDate, isArabic: isAr)}، ${AppStrings.translateDate(ride.departureTime, isArabic: isAr)}',
                    ),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(
                      isAr ? 'نقطة الصعود' : 'Pickup Point',
                      ride.pickupPoint,
                    ),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    // Driver name from DB kept intact
                    _buildRow(
                      isAr ? 'السائق' : 'Driver',
                      ride.driverName,
                    ),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    // Driver phone from DB kept intact
                    _buildRow(
                      isAr ? 'رقم السائق' : 'Driver Phone',
                      ride.driverPhone,
                    ),
                    const Divider(height: 20, color: AppColors.borderDisabled),
                    _buildRow(
                      isAr ? 'الإجمالي' : 'Total Price',
                      '${ride.pricePerSeat} ${isAr ? "ج نقداً" : "EGP Cash"}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Action Buttons
              MashwarButton(
                text: isAr ? 'اتصل بالسائق' : 'Call Driver',
                icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'الاتصال بـ ${ride.driverPhone} (${ride.driverName})'
                            : 'Calling ${ride.driverPhone} (${ride.driverName})',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimens.space12),
              MashwarButton(
                text: isAr ? 'مشاركة الرحلة' : 'Share Trip',
                variant: MashwarButtonVariant.secondary,
                icon: const Icon(Icons.share_outlined, color: AppColors.navy, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم نسخ تفاصيل الرحلة للمشاركة'
                            : 'Trip details copied to clipboard',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimens.space12),
              TextButton(
                onPressed: () {
                  context.read<RidesProvider>().cancelBooking();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'تم إلغاء الحجز' : 'Booking cancelled',
                      ),
                    ),
                  );
                },
                child: Text(
                  isAr ? 'إلغاء الحجز' : 'Cancel Booking',
                  style: AppTypography.button(color: AppColors.danger),
                ),
              ),
              const SizedBox(height: AppDimens.space16),
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
