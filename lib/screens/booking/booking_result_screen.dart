import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_handover_qr_panel.dart';
import '../../data/models/ride_model.dart';
import '../../state/rides_provider.dart';
import '../chat/chat_screen.dart';
import '../ride_details/ride_details_screen.dart';
import '../trip/active_trip_screen.dart';
import 'booking_confirmation_screen.dart';

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
          context.read<RidesProvider?>()?.confirmBooking(widget.ride);
        }
      });
    }
  }

  RideModel get ride => widget.ride;
  bool get isConfirmed => widget.isConfirmed;
  int get totalPrice => widget.totalPrice;

  Future<void> _launchWithFallback(
    BuildContext context, {
    required Uri uri,
    required String clipboardText,
    required String fallbackMessage,
  }) async {
    bool launched = false;
    final debugHook = BookingConfirmationScreen.debugUrlLauncher;
    try {
      launched = debugHook != null
          ? await debugHook(uri)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!context.mounted || launched) return;
    try {
      await Clipboard.setData(ClipboardData(text: clipboardText));
    } catch (_) {}
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fallbackMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    if (!isConfirmed) {
      return _buildRejectedView(context, isAr);
    }

    return _buildConfirmedView(context, isAr);
  }

  Widget _buildConfirmedView(BuildContext context, bool isAr) {
    final otpCode = BookingConfirmationScreen.handoverOtpForRide(ride);
    final qrPayload = 'MASHWAR|RIDE|${ride.id}|$otpCode';
    final driverFirst = ride.driverName.trim().isNotEmpty
        ? ride.driverName.trim().split(' ').first
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
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space20,
                vertical: AppDimens.space16,
              ),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isAr ? 'تم تأكيد حجزك' : 'Booking Confirmed',
                      textAlign: TextAlign.center,
                      style: AppTypography.largeTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? '$driverFirst وافق على طلبك'
                          : '$driverFirst accepted your request',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySecondary(),
                    ),
                    const SizedBox(height: AppDimens.space20),

                    // Scannable QR + 4-Digit OTP Pass
                    MashwarHandoverQrCard(
                      title: isAr
                          ? 'بطاقة الصعود (QR + كود OTP)'
                          : 'Boarding Pass (QR + OTP)',
                      subtitle: isAr
                          ? 'اعرض الرمز للسائق عند الالتقاء لتأكيد صعودك بأمان.'
                          : 'Show QR or share OTP at pickup to confirm boarding.',
                      code: otpCode,
                      qrPayload: qrPayload,
                      isAr: isAr,
                      referenceId: ride.id,
                      accentColor: AppColors.navy,
                      surfaceColor: Colors.white,
                      borderColor: AppColors.slateBorder,
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Summary Card with Route Timeline + Google Maps Pickup Directions
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              from: context.trCity(ride.fromCity),
                              to: context.trCity(ride.toCity),
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          MashwarButton(
                            height: 44,
                            variant: MashwarButtonVariant.secondary,
                            text: isAr
                                ? 'اتجاهات نقطة الالتقاء في Google Maps'
                                : 'Pickup Directions in Google Maps',
                            icon: const Icon(
                              Icons.directions_rounded,
                              size: 18,
                              color: AppColors.navy,
                            ),
                            onPressed: () {
                              final mapsUri = BookingConfirmationScreen
                                  .buildPickupDirectionsUri(ride);
                              _launchWithFallback(
                                context,
                                uri: mapsUri,
                                clipboardText: mapsUri.toString(),
                                fallbackMessage: isAr
                                    ? 'تم نسخ رابط موقع الالتقاء على Google Maps'
                                    : 'Google Maps pickup link copied to clipboard',
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildRow(
                            isAr ? 'الموعد' : 'Schedule',
                            '${context.trDate(ride.departureDate)}${isAr ? "، " : ", "}${context.trDate(ride.departureTime)}',
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.slateBorder,
                          ),
                          _buildRow(
                            isAr ? 'نقطة الصعود' : 'Pickup Point',
                            ride.pickupPoint,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.slateBorder,
                          ),
                          _buildRow(
                            isAr ? 'الإجمالي' : 'Total Price',
                            '$totalPrice ${isAr ? "ر.ق" : "QAR"}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    MashwarCommunicationBar(
                      chatLabel: isAr ? 'محادثة السائق' : 'Chat Driver',
                      callLabel: isAr ? 'اتصال بالسائق' : 'Call Driver',
                      onChat: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              driverName: ride.driverName,
                              driverCar: ride.driverCar,
                              tripRoute: context.trRoute(
                                '${ride.fromCity} ← ${ride.toCity}',
                              ),
                            ),
                          ),
                        );
                      },
                      onCall: () {
                        final dial = BookingConfirmationScreen.normalizeDialPhone(
                          ride.driverPhone,
                        );
                        _launchWithFallback(
                          context,
                          uri: Uri(scheme: 'tel', path: dial),
                          clipboardText: dial,
                          fallbackMessage: isAr
                              ? 'رقم المسافر: $dial — تم نسخه للاتصال'
                              : 'Driver phone: $dial — copied to clipboard',
                        );
                      },
                    ),
                    const SizedBox(height: AppDimens.space16),

                    MashwarButton(
                      text: isAr ? 'تفاصيل الرحلة' : 'Ride Details',
                      onPressed: () {
                        context.read<RidesProvider?>()?.confirmBooking(ride);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ActiveTripScreen(ride: ride),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    MashwarButton(
                      variant: MashwarButtonVariant.secondary,
                      text: isAr
                          ? 'بطاقة تأكيد الحجز الكاملة'
                          : 'Full Booking Pass',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MashwarPageRoute(
                            builder: (_) => BookingConfirmationScreen(
                              ride: ride,
                              totalPrice: totalPrice,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                        child: Text(
                          isAr ? 'الرجوع للرئيسية' : 'Back to Home',
                          style: AppTypography.bodySecondary(
                            color: AppColors.navy,
                          ),
                        ),
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

  Widget _buildRejectedView(BuildContext context, bool isAr) {
    final alternatives = context
            .watch<RidesProvider?>()
            ?.filteredRides
            .where((r) => r.id != ride.id && r.remainingSeats > 0)
            .take(2)
            .toList() ??
        const <RideModel>[];
    final driverFirst = ride.driverName.trim().isNotEmpty
        ? ride.driverName.trim().split(' ').first
        : (isAr ? 'المسافر' : 'Driver');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.space24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: AppColors.dangerBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.danger,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr
                        ? 'تعذر قبول الحجز هذه المرة'
                        : 'Driver Unavailable',
                    textAlign: TextAlign.center,
                    style: AppTypography.largeTitle(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'اعتذر $driverFirst عن قبول المقعد. تتوفر رحلات بديلة جاهزة للحجز الفوري أدناه.'
                        : '$driverFirst could not take this booking. Check available alternatives below.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySecondary(),
                  ),
                  const SizedBox(height: 24),

                  if (alternatives.isNotEmpty)
                    Container(
                      width: double.infinity,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'رحلات بديلة متاحة الآن:'
                                : 'Available alternative rides:',
                            style: AppTypography.label(color: AppColors.navy),
                          ),
                          const SizedBox(height: 10),
                          ...alternatives.map(
                            (alt) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RideDetailsScreen(ride: alt),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slateBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.slateBorder,
                                      width: AppDimens.borderWidth,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${alt.departureTime} · ${alt.driverName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.body().copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${alt.pricePerSeat} ${isAr ? "ر.ق" : "QAR"}',
                                        style: AppTypography.label(
                                          color: AppColors.navy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),

                  MashwarButton(
                    text: isAr ? 'ابحث عن رحلة أخرى' : 'Search Other Rides',
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                  ),
                  const SizedBox(height: 10),
                  MashwarButton(
                    variant: MashwarButtonVariant.secondary,
                    text: isAr ? 'الرجوع للرئيسية' : 'Back to Home',
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                  ),
                  const SizedBox(height: 24),
                ],
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
