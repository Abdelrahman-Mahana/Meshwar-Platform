import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
import '../../state/auth_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';
import '../chat/chat_screen.dart';
import '../escrow/service_escrow_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.ride});

  final RideModel ride;

  String _paymentLabel(String method, bool isAr) {
    switch (method) {
      case 'fawran':
        return isAr ? 'فوراً Fawran (محمي بالضمان)' : 'Fawran (Escrow Protected)';
      case 'qpay':
        return isAr ? 'كيوباي QPay / هميان' : 'QPay / Himyan';
      case 'skipcash':
        return isAr ? 'SkipCash / Apple Pay' : 'SkipCash / Apple Pay';
      default:
        return isAr ? 'نقداً عند التسليم (مع OTP)' : 'Cash with OTP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final isAr = settings.isArabic;
    final methodLabel = _paymentLabel(auth.selectedPaymentMethod, isAr);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: AppDimens.space12),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 280),
                child: Column(
                  children: [
                    // Hero Confirmation Badge + Sadu Heritage Card
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
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
                    const SizedBox(height: AppDimens.space20),

                    // Booking Details Card with Route Timeline & Payment Method
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
                              from: ride.pickupPoint,
                              to: ride.dropoffPoint,
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRow(
                            isAr ? 'الموعد' : 'Date & Time',
                            '${AppStrings.translateDate(ride.departureDate, isArabic: isAr)}، ${AppStrings.translateDate(ride.departureTime, isArabic: isAr)}',
                          ),
                          const Divider(height: 20, color: AppColors.borderDisabled),
                          _buildRow(isAr ? 'السائق' : 'Driver', ride.driverName),
                          const Divider(height: 20, color: AppColors.borderDisabled),
                          _buildRow(isAr ? 'رقم السائق' : 'Driver Phone', ride.driverPhone),
                          const Divider(height: 20, color: AppColors.borderDisabled),
                          _buildRow(isAr ? 'وسيلة الدفع' : 'Payment', methodLabel),
                          const Divider(height: 20, color: AppColors.borderDisabled),
                          _buildRow(
                            isAr ? 'الإجمالي' : 'Total Price',
                            '${ride.pricePerSeat} ${isAr ? "ر.ق" : "QAR"}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space12),

                    // 4-Digit Security OTP + Escrow Protection Strip
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.escrowSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.escrowGreen.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: AppColors.escrowGreen, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'كود أمان الركوب والاستلام (OTP)' : 'Boarding & Handover OTP',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.escrowGreen,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Text(
                                  isAr
                                      ? 'سلّم الكود عند الانطلاق والوصول لضمان حقك'
                                      : 'Share at meetup to confirm safe arrival',
                                  style: const TextStyle(fontSize: 11, color: AppColors.navy, fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '5912',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.qatarMaroon,
                          side: BorderSide(color: AppColors.qatarMaroon.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MashwarPageRoute(builder: (_) => const ServiceEscrowScreen()),
                          );
                        },
                        icon: const Icon(Icons.shield_outlined, size: 18),
                        label: Text(
                          isAr ? 'مركز الضمان والتتبع الحي (Escrow)' : 'Open Bilateral Escrow & Tracking',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Seamless 1-Tap Driver Communication Bar
                    MashwarCommunicationBar(
                      chatLabel: isAr ? 'محادثة السائق' : 'Chat Driver',
                      callLabel: isAr ? 'اتصال بالسائق' : 'Call Driver',
                      shareLabel: isAr ? 'مشاركة الرحلة' : 'Share Trip',
                      onChat: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              driverName: ride.driverName,
                              driverCar: ride.driverCar,
                              tripRoute: AppStrings.translateRoute('${ride.fromCity} ← ${ride.toCity}', isArabic: isAr),
                            ),
                          ),
                        );
                      },
                      onCall: () {
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
                      onShare: () {
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
                    const SizedBox(height: AppDimens.space16),
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
                  ],
                ),
              ),
            ),
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
