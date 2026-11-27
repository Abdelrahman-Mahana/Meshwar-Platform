import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_handover_qr_panel.dart';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space24,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MashwarFadeSlideIn(
                    duration: const Duration(milliseconds: 260),
                    child: Column(
                      children: [
                        MashwarAssetArt(
                          assetPath: 'assets/images/service_parcel.jpg',
                          width: 68,
                          height: 68,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(16),
                          fallbackIcon: Icons.inventory_2_rounded,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isAr
                              ? 'اعرض رمز QR أو أعطِ الكود للمسافر عند تسليمه الطرد'
                              : 'Show this QR code or share the 4-digit OTP with the traveler at pickup',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySecondary(),
                        ),
                        const SizedBox(height: 16),

                        // Scannable QR Code alongside the 4-Digit OTP
                        MashwarQrMatrixWidget(
                          key: const ValueKey('pickup_dialog_qr_code'),
                          data:
                              'MASHWAR|PARCEL_PICKUP|${widget.parcel.id}|${widget.parcel.pickupOtp.replaceAll(" ", "")}',
                          size: 152,
                          moduleColor: AppColors.navy,
                        ),
                        const SizedBox(height: 16),

                        // 4-Digit Boxes with Gold accent border
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 8,
                            children:
                                widget.parcel.pickupOtp.split(' ').map((digit) {
                              return Container(
                                width: 56,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.65),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.navy
                                          .withValues(alpha: 0.14),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    digit,
                                    style: AppTypography.largeTitle(
                                      color: AppColors.gold,
                                    ).copyWith(fontSize: 26),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F4),
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(
                          color: const Color(0xFFE5E5EA), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded,
                            color: AppColors.teal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'يعمل رمز QR والكود بدون إنترنت ويؤكدان استلام المسافر للطرد فعلياً'
                                : 'QR & OTP work 100% offline and verify physical handover to the traveler',
                            style: AppTypography.label(color: AppColors.navy),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('pickup_dialog_contingency_btn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: BorderSide(
                        color: AppColors.warning.withValues(alpha: 0.6),
                      ),
                      backgroundColor: AppColors.goldSurface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => showMashwarHandoverContingencySheet(
                      context,
                      isAr: isAr,
                      referenceId: widget.parcel.id,
                      handoverCode:
                          widget.parcel.pickupOtp.replaceAll(' ', ''),
                    ),
                    icon: const Icon(
                      Icons.battery_alert_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    label: Text(
                      isAr
                          ? 'مشكلة في الكاميرا أو بطارية الموبايل؟ الحلول البديلة'
                          : 'Camera broken or dead battery? Fallback options',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 22),
                  MashwarButton(
                    text: isAr ? 'تم تسليم الطرد' : 'Parcel Handed Over',
                    onPressed: () => setState(() => _isHandedOver = true),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
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
