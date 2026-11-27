import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../state/rides_provider.dart';

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
  static const String _otherReasonAr = 'سبب آخر';
  String _selectedReason = 'تغيّرت خطتي';
  final TextEditingController _customReasonController = TextEditingController();
  String? _customReasonError;
  bool _isCancelled = false;

  final List<String> _reasonsAr = const [
    'تغيّرت خطتي',
    'وجدت رحلة أخرى',
    'تأخر السائق',
    _otherReasonAr,
  ];

  final List<String> _reasonsEn = const [
    'Changed my plans',
    'Found another ride',
    'Driver was delayed',
    'Other reason',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  void _confirmCancel(bool isAr) {
    if (_selectedReason == _otherReasonAr &&
        _customReasonController.text.trim().isEmpty) {
      setState(() {
        _customReasonError = isAr
            ? 'يرجى توضيح سبب الإلغاء باختصار'
            : 'Please enter a brief cancellation reason';
      });
      return;
    }

    Provider.of<RidesProvider?>(context, listen: false)?.cancelBooking();
    setState(() {
      _customReasonError = null;
      _isCancelled = true;
    });
    widget.onCancelled();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final reasons = isAr ? _reasonsAr : _reasonsEn;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    if (_isCancelled) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusBottomSheet),
          ),
        ),
        padding: const EdgeInsets.all(AppDimens.space24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'تم إلغاء حجزك' : 'Booking Cancelled',
                style: AppTypography.title(),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'تم إشعار السائق بإلغاء مقعدك وإتاحته للمسافرين الآخرين'
                    : 'We notified the driver and released your seat',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: 24),
              MashwarButton(
                key: const ValueKey('cancellation_done_btn'),
                text: isAr ? 'تم' : 'Done',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimens.space24,
        AppDimens.space20,
        AppDimens.space24,
        AppDimens.space20 + bottomInset,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MashwarSheetHeader(
                title: isAr ? 'إلغاء الحجز' : 'Cancel Booking',
                leadingIcon: Icons.event_busy_rounded,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
              if (widget.isLateCancellation) ...[
                AlertBanner(
                  message: isAr
                      ? 'بقي أقل من ساعة على الرحلة. الإلغاء المتأخر قد يؤثر على تقييمك'
                      : 'Less than 1 hour until departure. Late cancellation may affect your rating',
                  type: AlertBannerType.warning,
                ),
                const SizedBox(height: AppDimens.space16),
              ] else ...[
                Text(
                  isAr
                      ? 'الإلغاء مجاني طالما تم قبل الرحلة بوقت كافٍ'
                      : 'Free cancellation when done ahead of time',
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: AppDimens.space16),
              ],

              Text(
                isAr ? 'ما سبب الإلغاء؟' : 'Why do you want to cancel?',
                style: AppTypography.label(color: AppColors.navy),
              ),
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
                    onTap: () => setState(() {
                      _selectedReason = reasonAr;
                      _customReasonError = null;
                    }),
                  );
                }),
              ),
              if (_selectedReason == _otherReasonAr) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('cancellation_custom_reason_input'),
                  controller: _customReasonController,
                  style: AppTypography.body(),
                  onChanged: (_) {
                    if (_customReasonError != null) {
                      setState(() => _customReasonError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: isAr
                        ? 'اكتب السبب باختصار...'
                        : 'Enter cancellation reason...',
                    errorText: _customReasonError,
                    filled: true,
                    fillColor: AppColors.slateBg,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimens.radiusField,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.slateBorder,
                        width: AppDimens.borderWidth,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimens.radiusField,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.slateBorder,
                        width: AppDimens.borderWidth,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppDimens.space24),

              MashwarButton(
                key: const ValueKey('cancellation_confirm_btn'),
                text: isAr ? 'تأكيد الإلغاء' : 'Confirm Cancellation',
                variant: MashwarButtonVariant.danger,
                onPressed: () => _confirmCancel(isAr),
              ),
              const SizedBox(height: 8),
              MashwarButton(
                text: isAr ? 'تراجع' : 'Keep Booking',
                variant: MashwarButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
