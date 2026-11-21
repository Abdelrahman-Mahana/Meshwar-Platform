import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/localization/app_strings.dart';

class CancellationSheet extends StatefulWidget {
  const CancellationSheet({
    super.key,
    this.isLateCancellation = false,
    required this.onCancelled,
  });

  final bool isLateCancellation;
  final VoidCallback onCancelled;

  @override
  State<CancellationSheet> createState() => _CancellationSheetState();
}

class _CancellationSheetState extends State<CancellationSheet> {
  String _selectedReason = 'غيّرت خطتي';
  bool _isCancelled = false;

  final List<String> _reasonsAr = [
    'غيّرت خطتي',
    'لقيت رحلة تانية',
    'السائق اتأخر',
    'سبب تاني',
  ];

  final List<String> _reasonsEn = [
    'Changed my plans',
    'Found another ride',
    'Driver was delayed',
    'Other reason',
  ];

  void _confirmCancel() {
    setState(() => _isCancelled = true);
    widget.onCancelled();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final reasons = isAr ? _reasonsAr : _reasonsEn;

    if (_isCancelled) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
        ),
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(isAr ? 'تم إلغاء حجزك' : 'Booking Cancelled', style: AppTypography.title()),
            const SizedBox(height: 8),
            Text(
              isAr ? 'بلّغنا السائق بإلغاء مقعدك' : 'We notified the driver of your cancellation',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary(),
            ),
            const SizedBox(height: 24),
            MashwarButton(
              text: isAr ? 'تم' : 'Done',
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
      ),
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space16),
          Text(isAr ? 'إلغاء الحجز' : 'Cancel Booking', style: AppTypography.title()),
          const SizedBox(height: 8),
          if (widget.isLateCancellation) ...[
            AlertBanner(
              message: isAr
                  ? 'باقي أقل من ساعة على الرحلة. الإلغاء المتأخر ممكن يأثر على تقييمك'
                  : 'Less than 1 hour until departure. Late cancellation may affect your rating',
              type: AlertBannerType.warning,
            ),
            const SizedBox(height: AppDimens.space16),
          ] else ...[
            Text(
              isAr ? 'الإلغاء مجاني طالما قبل الرحلة بوقت كافي' : 'Free cancellation when done ahead of time',
              style: AppTypography.bodySecondary(),
            ),
            const SizedBox(height: AppDimens.space16),
          ],

          Text(isAr ? 'ليه عايز تلغي؟' : 'Why do you want to cancel?', style: AppTypography.label()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(reasons.length, (index) {
              final reasonAr = _reasonsAr[index];
              final isSelected = _selectedReason == reasonAr;
              return MashwarChip(
                label: reasons[index],
                isSelected: isSelected,
                onTap: () => setState(() => _selectedReason = reasonAr),
              );
            }),
          ),
          const SizedBox(height: AppDimens.space32),

          MashwarButton(
            text: isAr ? 'تأكيد الإلغاء' : 'Confirm Cancellation',
            variant: MashwarButtonVariant.danger,
            onPressed: _confirmCancel,
          ),
          const SizedBox(height: 8),
          MashwarButton(
            text: isAr ? 'تراجع' : 'Nevermind',
            variant: MashwarButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
