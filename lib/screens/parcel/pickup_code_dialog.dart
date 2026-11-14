import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/parcel_model.dart';
import 'parcel_tracking_screen.dart';

class PickupCodeDialog extends StatefulWidget {
  const PickupCodeDialog({super.key, required this.parcel});

  final ParcelModel parcel;

  @override
  State<PickupCodeDialog> createState() => _PickupCodeDialogState();
}

class _PickupCodeDialogState extends State<PickupCodeDialog> {
  bool _isHandedOver = false;

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    if (_isHandedOver) {
      return _buildHandoverConfirmedView(context, isAr);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isAr ? 'كود الاستلام' : 'Pickup OTP Code', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                isAr ? 'اعطي الكود ده للسائق عند تسليمه الطرد' : 'Give this 4-digit code to driver upon handing over the parcel',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: 24),

              // 4-Digit Boxes (Page 34)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.parcel.pickupOtp.split(' ').map((digit) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 58,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          digit,
                          style: AppTypography.largeTitle(color: Colors.white).copyWith(fontSize: 28),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F4),
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: AppColors.teal, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr ? 'الكود بيأكد إنك سلّمت الطرد للسائق فعلياً' : 'Code proves that the parcel has been physically received by driver',
                        style: AppTypography.label(color: AppColors.navy),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),
              MashwarButton(
                text: isAr ? 'تم تسليم الطرد' : 'Parcel Handed Over',
                onPressed: () => setState(() => _isHandedOver = true),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Handover Confirmed (Page 34)
  Widget _buildHandoverConfirmedView(BuildContext context, bool isAr) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(isAr ? 'تم استلام الطرد' : 'Parcel Received', style: AppTypography.largeTitle()),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'الكابتن استلم الطرد وبدأ رحلته للوجهة المحددة.'
                    : 'Captain received the package and began traveling to the destination.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const Spacer(flex: 4),
              MashwarButton(
                text: isAr ? 'متابعة مسار الطرد' : 'Track Parcel Route',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ParcelTrackingScreen(
                        parcel: widget.parcel.copyWith(status: ParcelStatusStep.handedOver),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
