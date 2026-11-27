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
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/ride_model.dart';
import '../../state/auth_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';
import '../chat/chat_screen.dart';
import '../escrow/service_escrow_screen.dart';
import '../trip/active_trip_screen.dart';
import 'cancellation_sheet.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.ride,
    this.seatsCount = 1,
    this.totalPrice,
  });

  final RideModel ride;
  final int seatsCount;
  final int? totalPrice;

  /// Optional test hook for intercepting `tel:` and Google Maps `https:` launches.
  static Future<bool> Function(Uri uri)? debugUrlLauncher;

  /// Deterministic 4-digit boarding OTP seeded from [ride.id].
  static String handoverOtpForRide(RideModel ride) {
    int hash = 5912;
    for (final codeUnit in ride.id.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7FFFFFFF;
    }
    final fourDigits = 1000 + (hash % 9000);
    return '$fourDigits';
  }

  static String normalizeDialPhone(String rawPhone) {
    final trimmed = rawPhone.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.length == 8) return '+974$digits';
    return digits.isNotEmpty ? digits : '+97444009999';
  }

  static Uri buildPickupDirectionsUri(RideModel ride) {
    final pickupQuery = '${ride.pickupPoint}, ${ride.fromCity}, Qatar';
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(pickupQuery)}&travelmode=driving',
    );
  }

  Future<bool> _launchExternalUri(Uri uri) async {
    final override = debugUrlLauncher;
    if (override != null) {
      return override(uri);
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _callDriver(BuildContext context, bool isAr) async {
    final dialNumber = normalizeDialPhone(ride.driverPhone);
    final telUri = Uri(scheme: 'tel', path: dialNumber);
    final launched = await _launchExternalUri(telUri);
    if (!context.mounted) return;
    if (!launched) {
      try {
        await Clipboard.setData(ClipboardData(text: dialNumber));
      } catch (_) {}
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'رقم المسافر: $dialNumber (${ride.driverName}) — تم نسخه للاتصال المباشر'
                : 'Driver number: $dialNumber (${ride.driverName}) — copied to clipboard',
          ),
        ),
      );
    }
  }

  Future<void> _openGoogleMapsPickup(BuildContext context, bool isAr) async {
    final mapsUri = buildPickupDirectionsUri(ride);
    final launched = await _launchExternalUri(mapsUri);
    if (!context.mounted) return;
    if (!launched) {
      try {
        await Clipboard.setData(ClipboardData(text: mapsUri.toString()));
      } catch (_) {}
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تم نسخ رابط اتجاهات نقطة الالتقاء على Google Maps'
                : 'Google Maps pickup directions link copied to clipboard',
          ),
        ),
      );
    }
  }

  Future<void> _shareTripSummary(BuildContext context, bool isAr) async {
    final mapsUri = buildPickupDirectionsUri(ride);
    final summary = isAr
        ? 'رحلة مشوار المؤكدة: ${ride.fromCity} ← ${ride.toCity} | المسافر: ${ride.driverName} (${ride.driverCar}) | نقطة الالتقاء: ${ride.pickupPoint} | الخريطة: $mapsUri'
        : 'Confirmed MASHWAR Trip: ${ride.fromCity} -> ${ride.toCity} | Driver: ${ride.driverName} (${ride.driverCar}) | Pickup: ${ride.pickupPoint} | Map: $mapsUri';
    try {
      await Clipboard.setData(ClipboardData(text: summary));
    } catch (_) {}
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم نسخ تفاصيل الرحلة ورابط الخريطة للمشاركة'
              : 'Trip details & Google Maps link copied to clipboard',
        ),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  void _openCancellationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancellationSheet(
        onCancelled: () {
          context.read<RidesProvider?>()?.cancelBooking();
        },
      ),
    );
  }

  String _paymentLabel(String method, bool isAr) {
    switch (method) {
      case 'bank_transfer_manual':
      case 'fawran':
        return isAr ? 'تحويل بنكي / فوري مباشر' : 'Direct Bank Transfer';
      default:
        return isAr
            ? 'نقداً عند الالتقاء (مع OTP و QR)'
            : 'Cash at Pickup (with OTP & QR)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final isAr = settings.isArabic;
    final methodLabel = _paymentLabel(auth.selectedPaymentMethod, isAr);
    final effectiveTotal = totalPrice ?? (ride.pricePerSeat * seatsCount);
    final otpCode = handoverOtpForRide(ride);
    final qrPayload = 'MASHWAR|RIDE|${ride.id}|$otpCode';

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
          isAr ? 'تأكيد الحجز وبطاقة الصعود' : 'Booking Confirmation',
          style: AppTypography.title().copyWith(fontSize: 17),
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
                    // Hero Confirmation Header
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
                    const SizedBox(height: AppDimens.space14),
                    Text(
                      isAr ? 'تم تأكيد حجزك' : 'Booking Confirmed',
                      textAlign: TextAlign.center,
                      style: AppTypography.largeTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'مقعدك محجوز — اعرض رمز QR أو كود OTP عند الالتقاء'
                          : 'Your seat is reserved — present QR or OTP at pickup',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySecondary(),
                    ),
                    const SizedBox(height: AppDimens.space20),

                    // Scannable QR + 4-Digit Boarding OTP Card
                    MashwarHandoverQrCard(
                      cardKey: const ValueKey('booking_handover_qr_card'),
                      qrKey: const ValueKey('booking_handover_qr_code'),
                      codeValueKey:
                          const ValueKey('booking_handover_otp_value'),
                      contingencyButtonKey:
                          const ValueKey('booking_handover_contingency_btn'),
                      title: isAr
                          ? 'رمز الصعود والتحقق (QR + كود OTP)'
                          : 'Boarding Pass (QR + 4-Digit OTP)',
                      subtitle: isAr
                          ? 'امسح رمز QR مع السائق عند نقطة الالتقاء أو شاركه الكود المكون من 4 أرقام لتوثيق بداية الرحلة بأمان.'
                          : 'Let the driver scan your QR code at pickup or share the 4-digit OTP to verify safe boarding.',
                      code: otpCode,
                      qrPayload: qrPayload,
                      isAr: isAr,
                      referenceId: ride.id,
                      accentColor: AppColors.navy,
                      surfaceColor: Colors.white,
                      borderColor: AppColors.slateBorder,
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Booking Details Card + 1-Tap Google Maps Pickup Directions
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
                          Row(
                            children: [
                              MashwarUserAvatar(
                                avatarUrl: null,
                                fullName: ride.driverName,
                                size: 44,
                                borderWidth: 1.0,
                                borderColor: AppColors.slateBorder,
                                autoCommunityPortrait: true,
                                showVerifiedBadge: ride.isVerified,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ride.driverName,
                                      style: AppTypography.body().copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      ride.driverCar,
                                      style: AppTypography.bodySmall(),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 15,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${ride.driverRating}',
                                    style: AppTypography.label(
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                              from: ride.pickupPoint,
                              to: ride.dropoffPoint,
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          MashwarButton(
                            key: const ValueKey('booking_open_gmaps_btn'),
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
                            onPressed: () =>
                                _openGoogleMapsPickup(context, isAr),
                          ),
                          const SizedBox(height: 14),
                          _buildRow(
                            isAr ? 'الموعد' : 'Date & Time',
                            '${AppStrings.translateDate(ride.departureDate, isArabic: isAr)} · ${AppStrings.translateDate(ride.departureTime, isArabic: isAr)}',
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.slateBorder,
                          ),
                          _buildRow(
                            isAr ? 'رقم المسافر' : 'Driver Phone',
                            ride.driverPhone,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.slateBorder,
                          ),
                          _buildRow(
                            isAr ? 'وسيلة الدفع' : 'Payment',
                            methodLabel,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.slateBorder,
                          ),
                          _buildRow(
                            isAr ? 'الإجمالي' : 'Total Price',
                            '$effectiveTotal ${isAr ? "ر.ق" : "QAR"}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Seamless 1-Tap Driver Communication Bar (Chat + Real tel: Call + Share)
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
                              tripRoute: AppStrings.translateRoute(
                                '${ride.fromCity} ← ${ride.toCity}',
                                isArabic: isAr,
                              ),
                            ),
                          ),
                        );
                      },
                      onCall: () => _callDriver(context, isAr),
                      onShare: () => _shareTripSummary(context, isAr),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Primary CTA: Active Trip Tracking
                    MashwarButton(
                      key: const ValueKey('booking_view_active_trip_btn'),
                      text: isAr
                          ? 'متابعة الرحلة الحية'
                          : 'View Active Trip',
                      onPressed: () {
                        Navigator.of(context).push(
                          MashwarPageRoute(
                            builder: (_) => ActiveTripScreen(ride: ride),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Secondary CTA: Bilateral Escrow & Safety Center
                    MashwarButton(
                      variant: MashwarButtonVariant.secondary,
                      text: isAr
                          ? 'مركز الضمان والتتبع الحي'
                          : 'Open Bilateral Escrow & Tracking',
                      icon: const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppColors.navy,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MashwarPageRoute(
                            builder: (_) => const ServiceEscrowScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Cancel Booking via CancellationSheet -> RidesProvider.cancelBooking
                    Center(
                      child: TextButton(
                        key: const ValueKey('booking_cancel_btn'),
                        onPressed: () => _openCancellationSheet(context),
                        child: Text(
                          isAr ? 'إلغاء الحجز' : 'Cancel Booking',
                          style: AppTypography.button(color: AppColors.danger),
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
