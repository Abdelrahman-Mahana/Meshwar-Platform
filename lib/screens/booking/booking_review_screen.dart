import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/ride_model.dart';
import '../../state/auth_provider.dart';
import '../../state/rides_provider.dart';
import 'booking_confirmation_screen.dart';
import 'booking_waiting_screen.dart';

class BookingReviewScreen extends StatefulWidget {
  const BookingReviewScreen({
    super.key,
    required this.ride,
    this.initialSeats = 1,
    this.hasPriceChanged = false,
  });

  final RideModel ride;
  final int initialSeats;
  final bool hasPriceChanged;

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  late int _seats;
  late int _unitPrice;
  late String _paymentMethod;
  bool _isLoading = false;
  bool _showSeatsWarning = false;

  int get _maxSeats => math.max(1, widget.ride.remainingSeats);

  @override
  void initState() {
    super.initState();
    _seats = widget.initialSeats.clamp(1, _maxSeats);
    _unitPrice = widget.hasPriceChanged
        ? widget.ride.pricePerSeat + 10
        : widget.ride.pricePerSeat;
    final currentMethod =
        context.read<AuthProvider?>()?.selectedPaymentMethod ?? 'cash';
    _paymentMethod =
        currentMethod == 'bank_transfer_manual' ? 'bank_transfer_manual' : 'cash';
  }

  void _handleIncrement() {
    if (_seats >= widget.ride.remainingSeats) {
      setState(() => _showSeatsWarning = true);
    } else {
      final nextSeats = _seats + 1;
      setState(() {
        _seats = nextSeats;
        _showSeatsWarning = false;
      });
      context.read<RidesProvider?>()?.setSeatsCount(nextSeats);
    }
  }

  void _handleDecrement() {
    if (_seats > 1) {
      final nextSeats = _seats - 1;
      setState(() {
        _seats = nextSeats;
        _showSeatsWarning = false;
      });
      context.read<RidesProvider?>()?.setSeatsCount(nextSeats);
    }
  }

  void _selectPaymentMethod(String method) {
    setState(() => _paymentMethod = method);
    context.read<AuthProvider?>()?.setSelectedPaymentMethod(method);
  }

  Future<void> _submitBooking() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final ridesProvider = context.read<RidesProvider?>();
    final authProvider = context.read<AuthProvider?>();
    authProvider?.setSelectedPaymentMethod(_paymentMethod);
    ridesProvider?.setSeatsCount(_seats);
    ridesProvider?.bookRide(widget.ride);

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _isLoading = false);

    final total = _seats * _unitPrice;
    if (widget.ride.isInstantBooking) {
      Navigator.of(context).pushReplacement(
        MashwarPageRoute(
          builder: (_) => BookingConfirmationScreen(
            ride: widget.ride,
            seatsCount: _seats,
            totalPrice: total,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MashwarPageRoute(
          builder: (_) => BookingWaitingScreen(
            ride: widget.ride,
            seatsCount: _seats,
            totalPrice: total,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _seats * _unitPrice;
    final isAr = context.isArabic;

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
          isAr ? 'مراجعة الحجز' : 'Booking Review',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.hasPriceChanged) ...[
                          AlertBanner(
                            message: isAr
                                ? 'تم تعديل السعر من ${widget.ride.pricePerSeat} إلى $_unitPrice ر.ق. يرجى المراجعة قبل المتابعة'
                                : 'Price changed from ${widget.ride.pricePerSeat} to $_unitPrice QAR. Review before confirming',
                            type: AlertBannerType.warning,
                          ),
                          const SizedBox(height: AppDimens.space12),
                        ],
                        if (_showSeatsWarning) ...[
                          AlertBanner(
                            message: isAr
                                ? 'المتاح في الرحلة ${widget.ride.remainingSeats} ${widget.ride.remainingSeats == 1 ? "مقعد فقط" : "مقاعد فقط"}'
                                : 'Only ${widget.ride.remainingSeats} ${widget.ride.remainingSeats == 1 ? "seat" : "seats"} remaining on this ride',
                            type: AlertBannerType.warning,
                          ),
                          const SizedBox(height: AppDimens.space12),
                        ],

                        // Trip & Traveler Route Card
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 240),
                          offsetY: 10,
                          child: Container(
                            padding: const EdgeInsets.all(AppDimens.space16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusCard,
                              ),
                              border: Border.all(
                                color: AppColors.slateBorder,
                                width: AppDimens.borderWidth,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    MashwarUserAvatar(
                                      avatarUrl: null,
                                      fullName: widget.ride.driverName,
                                      size: 44,
                                      borderWidth: 1.0,
                                      borderColor: AppColors.slateBorder,
                                      autoCommunityPortrait: true,
                                      showVerifiedBadge: widget.ride.isVerified,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.trRoute(
                                              '${widget.ride.fromCity} ← ${widget.ride.toCity}',
                                            ),
                                            style: AppTypography.title()
                                                .copyWith(fontSize: 16),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${widget.ride.driverName} · ${context.trDate(widget.ride.departureDate)} · ${widget.ride.departureTime}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodySmall(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (widget.ride.isInstantBooking)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.tealSurface,
                                          borderRadius: BorderRadius.circular(
                                            AppDimens.radiusSmall,
                                          ),
                                        ),
                                        child: Text(
                                          isAr ? 'تأكيد فوري' : 'Instant',
                                          style: AppTypography.label(
                                            color: AppColors.teal,
                                          ).copyWith(fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.slateBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.slateBorder,
                                      width: AppDimens.borderWidth,
                                    ),
                                  ),
                                  child: MashwarRouteTimeline(
                                    from: widget.ride.pickupPoint,
                                    to: widget.ride.dropoffPoint,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.space16),

                        // Seats Counter Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusCard),
                            border: Border.all(
                              color: AppColors.slateBorder,
                              width: AppDimens.borderWidth,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr ? 'عدد المقاعد' : 'Number of Seats',
                                      style: AppTypography.body().copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      isAr
                                          ? 'المتاح: ${widget.ride.remainingSeats} · $_unitPrice ر.ق للمقعد'
                                          : 'Available: ${widget.ride.remainingSeats} · $_unitPrice QAR / seat',
                                      style: AppTypography.bodySmall(),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _buildCounterButton(
                                    buttonKey: const ValueKey(
                                      'booking_seats_decrement_btn',
                                    ),
                                    icon: Icons.remove_rounded,
                                    enabled: _seats > 1,
                                    onTap: _handleDecrement,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    child: Text(
                                      '$_seats',
                                      key: const ValueKey(
                                        'booking_seats_count_text',
                                      ),
                                      style: AppTypography.title(),
                                    ),
                                  ),
                                  _buildCounterButton(
                                    buttonKey: const ValueKey(
                                      'booking_seats_increment_btn',
                                    ),
                                    icon: Icons.add_rounded,
                                    enabled: true,
                                    onTap: _handleIncrement,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.space16),

                        // Payment Method Selection Card
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'وسيلة الدفع' : 'Payment Method',
                                style: AppTypography.body().copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildPaymentOptionTile(
                                optionKey:
                                    const ValueKey('booking_payment_cash'),
                                value: 'cash',
                                icon: Icons.payments_outlined,
                                title: isAr
                                    ? 'نقداً عند الالتقاء (Cash)'
                                    : 'Cash at Pickup',
                                subtitle: isAr
                                    ? 'تسوية مباشرة مع المسافر بعد التحقق برمز OTP / QR'
                                    : 'Pay traveler directly upon OTP / QR boarding check',
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentOptionTile(
                                optionKey:
                                    const ValueKey('booking_payment_transfer'),
                                value: 'bank_transfer_manual',
                                icon: Icons.account_balance_outlined,
                                title: isAr
                                    ? 'تحويل بنكي / فوري مباشر'
                                    : 'Direct Bank / Instant Transfer',
                                subtitle: isAr
                                    ? 'تحويل مباشر بين الطرفين عند الصعود والالتقاء'
                                    : 'Direct peer-to-peer transfer at meetup',
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(
                                  height: 1,
                                  color: AppColors.slateBorder,
                                ),
                              ),
                              _buildRow(
                                isAr ? 'تفصيل المقاعد' : 'Seat Breakdown',
                                '$_seats × $_unitPrice ${isAr ? "ر.ق" : "QAR"}',
                              ),
                              const SizedBox(height: 8),
                              _buildRow(
                                isAr ? 'الإجمالي المستحق' : 'Total Contribution',
                                '$total ${isAr ? "ر.ق" : "QAR"}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.space16),

                        // Security & OTP + QR Trust note
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tealSurface,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusCard),
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.3),
                              width: AppDimens.borderWidth,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: AppColors.teal,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isAr
                                      ? 'أمان مؤكد: ستحصل فوراً على رمز QR قابل للمسح وكود OTP من 4 أرقام لتأكيد ركوبك، مع اتجاهات نقطة الالتقاء على Google Maps.'
                                      : 'Verified Handover: Receive a scannable QR pass and 4-digit OTP code to confirm boarding, plus Google Maps pickup directions.',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom CTA Container
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.space16,
                    12,
                    AppDimens.space16,
                    AppDimens.space16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.slateBorder,
                        width: AppDimens.borderWidth,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MashwarButton(
                        key: const ValueKey('booking_confirm_submit_btn'),
                        text: isAr
                            ? 'تأكيد الحجز · $total ر.ق'
                            : 'Confirm Booking · $total QAR',
                        isLoading: _isLoading,
                        onPressed: _submitBooking,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _paymentMethod == 'bank_transfer_manual'
                            ? (isAr
                                ? 'تحويل مباشر للسائق عند الالتقاء · إلغاء مجاني قبل الموعد'
                                : 'Direct transfer at pickup · Free cancellation before departure')
                            : (isAr
                                ? 'الدفع نقداً للسائق بعد الركوب · إلغاء مجاني قبل الموعد'
                                : 'Pay cash to driver after boarding · Free cancellation'),
                        style: AppTypography.label(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required Key optionKey,
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      key: optionKey,
      borderRadius: BorderRadius.circular(AppDimens.radiusField),
      onTap: () => _selectPaymentMethod(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slateBg : Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusField),
          border: Border.all(
            color: isSelected ? AppColors.navy : AppColors.slateBorder,
            width: isSelected
                ? AppDimens.borderWidthFocused
                : AppDimens.borderWidth,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.navy),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body(color: AppColors.navy).copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: isSelected ? AppColors.navy : AppColors.textSecondary,
            ),
          ],
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
                ? AppTypography.title(color: AppColors.navy)
                    .copyWith(fontSize: 16.5)
                : AppTypography.body(),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterButton({
    required Key buttonKey,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      key: buttonKey,
      color: enabled ? Colors.white : AppColors.slateBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        side: const BorderSide(
          color: AppColors.slateBorder,
          width: AppDimens.borderWidth,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.navy : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
