import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/ride_model.dart';
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
  bool _isLoading = false;
  bool _showSeatsWarning = false;

  @override
  void initState() {
    super.initState();
    _seats = widget.initialSeats;
    _unitPrice = widget.hasPriceChanged ? widget.ride.pricePerSeat + 10 : widget.ride.pricePerSeat;
  }

  void _handleIncrement() {
    if (_seats >= widget.ride.remainingSeats) {
      setState(() => _showSeatsWarning = true);
    } else {
      setState(() {
        _seats++;
        _showSeatsWarning = false;
      });
    }
  }

  void _handleDecrement() {
    if (_seats > 1) {
      setState(() {
        _seats--;
        _showSeatsWarning = false;
      });
    }
  }

  void _submitBooking() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingWaitingScreen(
            ride: widget.ride,
            seatsCount: _seats,
            totalPrice: _seats * _unitPrice,
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
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'مراجعة الحجز' : 'Booking Review', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
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
                                ? 'السعر اتغير من ${widget.ride.pricePerSeat} إلى $_unitPrice ج. راجع قبل ما تكمل'
                                : 'Price changed from ${widget.ride.pricePerSeat} to $_unitPrice EGP. Review before confirming',
                            type: AlertBannerType.warning,
                          ),
                          const SizedBox(height: AppDimens.space12),
                        ],
                        if (_showSeatsWarning) ...[
                          AlertBanner(
                            message: isAr
                                ? 'المتاح في الرحلة ${widget.ride.remainingSeats} ${widget.ride.remainingSeats == 1 ? "كرسي فقط" : "كراسي فقط"}'
                                : 'Only ${widget.ride.remainingSeats} ${widget.ride.remainingSeats == 1 ? "seat" : "seats"} remaining on this ride',
                            type: AlertBannerType.warning,
                          ),
                          const SizedBox(height: AppDimens.space12),
                        ],

                        // Trip & Route Timeline Card
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 260),
                          offsetY: 10,
                          child: MashwarSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    MashwarAssetArt(
                                      assetPath: 'assets/images/service_ride.jpg',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.contain,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.trRoute('${widget.ride.fromCity} ← ${widget.ride.toCity}'),
                                            style: AppTypography.title().copyWith(fontSize: 16),
                                          ),
                                          Text(
                                            '${context.trDate(widget.ride.departureDate)} · ${widget.ride.departureTime}',
                                            style: AppTypography.label(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
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
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 300),
                          offsetY: 10,
                          child: MashwarSectionCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isAr ? 'عدد الكراسي' : 'Number of Seats', style: AppTypography.body().copyWith(fontWeight: FontWeight.w800)),
                                Row(
                                  children: [
                                    _buildCounterButton(
                                      icon: Icons.remove_rounded,
                                      onTap: _handleDecrement,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      child: Text('$_seats', style: AppTypography.title()),
                                    ),
                                    _buildCounterButton(
                                      icon: Icons.add_rounded,
                                      onTap: _handleIncrement,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.space16),

                        // Price Summary Card
                        MashwarFadeSlideIn(
                          duration: const Duration(milliseconds: 340),
                          offsetY: 10,
                          child: MashwarSectionCard(
                            child: Column(
                              children: [
                                _buildRow(isAr ? 'الدفع' : 'Payment Method', isAr ? 'نقداً للسائق' : 'Cash to driver'),
                                const Divider(height: 20, color: AppColors.borderDisabled),
                                _buildRow(isAr ? 'الإجمالي' : 'Total', '$total ${isAr ? "ج" : "EGP"}', isBold: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.space16),

                        // Security & OTP Trust note
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: AppColors.teal, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isAr
                                      ? 'أمان مؤكد: ستحصل على كود OTP مكون من 4 أرقام لتأكيد ركوبك مع السائق وضمان حق الطرفين.'
                                      : 'Verified Safety: You will receive a 4-digit OTP code to verify your ride upon boarding.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
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
                  padding: const EdgeInsets.fromLTRB(AppDimens.space16, 12, AppDimens.space16, AppDimens.space16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.borderDisabled.withValues(alpha: 0.7))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MashwarButton(
                        text: isAr ? 'تأكيد الحجز · $total ج' : 'Confirm Booking · $total EGP',
                        isLoading: _isLoading,
                        onPressed: _submitBooking,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr ? 'الدفع كاش مع السائق بعد الصعود' : 'Payment in cash to driver after boarding',
                        style: AppTypography.label(color: AppColors.textSecondary),
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

  Widget _buildCounterButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppColors.sand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderDisabled),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.navy),
        ),
      ),
    );
  }
}
