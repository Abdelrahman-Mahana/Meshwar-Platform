import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
import '../../state/rides_provider.dart';
import '../chat/chat_screen.dart';
import '../trip/active_trip_screen.dart';

class BookingResultScreen extends StatefulWidget {
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
  State<BookingResultScreen> createState() => _BookingResultScreenState();
}

class _BookingResultScreenState extends State<BookingResultScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.isConfirmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<RidesProvider>().confirmBooking(widget.ride);
        }
      });
    }
  }

  RideModel get ride => widget.ride;
  bool get isConfirmed => widget.isConfirmed;
  int get totalPrice => widget.totalPrice;

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
                    Container(
                      width: 76,
                      height: 76,
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
                    const SizedBox(height: 20),

                    // Summary card with Route Timeline
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
                              from: context.trCity(ride.fromCity),
                              to: context.trCity(ride.toCity),
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRow(
                            isAr ? 'الموعد' : 'Schedule',
                            '${context.trDate(ride.departureDate)}${isAr ? "، " : ", "}${context.trDate(ride.departureTime)}',
                          ),
                          const Divider(height: 20, color: AppColors.borderDisabled),
                          _buildRow(isAr ? 'نقطة الصعود' : 'Pickup Point', ride.pickupPoint),
                          const Divider(height: 20, color: AppColors.borderDisabled),
                          _buildRow(isAr ? 'الإجمالي' : 'Total Price', '$totalPrice ${isAr ? "ج نقداً" : "EGP Cash"}', isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    MashwarCommunicationBar(
                      chatLabel: isAr ? 'محادثة السائق' : 'Chat Driver',
                      callLabel: isAr ? 'اتصال بالسائق' : 'Call Driver',
                      onChat: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              driverName: ride.driverName,
                              driverCar: ride.driverCar,
                              tripRoute: context.trRoute('${ride.fromCity} ← ${ride.toCity}'),
                            ),
                          ),
                        );
                      },
                      onCall: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isAr ? 'الاتصال بـ ${ride.driverPhone}' : 'Calling ${ride.driverPhone}')),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

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
                  ],
                ),
              ),
            ),
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
