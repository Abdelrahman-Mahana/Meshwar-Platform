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
import '../../core/widgets/mashwar_text_field.dart';
import '../../state/parcels_provider.dart';

enum DisputePhase {
  open, // فتح نزاع
  underReview, // قيد المراجعة
  resolved, // تم الحل
}

class ParcelDisputeScreen extends StatefulWidget {
  const ParcelDisputeScreen({
    super.key,
    this.reportId = '#4821',
    this.parcelId,
  });

  final String reportId;
  final String? parcelId;

  @override
  State<ParcelDisputeScreen> createState() => _ParcelDisputeScreenState();
}

class _ParcelDisputeScreenState extends State<ParcelDisputeScreen> {
  static const String _otherKeyAr = 'أخرى (سبب مخصص)';

  DisputePhase _phase = DisputePhase.open;
  String _selectedReason = 'وصل تالف';
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _descController =
      TextEditingController(text: 'الطرد وصل مفتوحاً');
  bool _hasAttachedPhoto = false;
  bool _isSubmitting = false;
  String? _customReasonError;
  String? _detailsError;

  static const List<String> _reasonsAr = [
    'وصل تالف',
    'لم يصل',
    'المستلم لم يستلم',
    _otherKeyAr,
  ];

  static const List<String> _reasonsEn = [
    'Arrived damaged',
    'Did not arrive',
    'Receiver didn\'t receive',
    'Other (Custom Reason)',
  ];

  bool get _isOtherSelected => _selectedReason == _otherKeyAr;

  @override
  void dispose() {
    _customReasonController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _resolvedReasonDisplay(bool isAr) {
    if (_isOtherSelected && _customReasonController.text.trim().isNotEmpty) {
      return _customReasonController.text.trim();
    }
    if (isAr) return _selectedReason;
    final idx = _reasonsAr.indexOf(_selectedReason);
    return idx != -1 ? _reasonsEn[idx] : _selectedReason;
  }

  Future<void> _submitDispute(bool isAr) async {
    if (_isSubmitting) return;

    final customText = _customReasonController.text.trim();
    final descText = _descController.text.trim();

    String? customErr;
    String? descErr;

    if (_isOtherSelected && customText.length < 2) {
      customErr = isAr
          ? 'يرجى كتابة سبب البلاغ المخصص'
          : 'Please specify the custom dispute reason';
    }
    if (descText.length < 3) {
      descErr = isAr
          ? 'يرجى توضيح تفاصيل المشكلة باختصار'
          : 'Please describe what happened';
    }

    if (customErr != null || descErr != null) {
      setState(() {
        _customReasonError = customErr;
        _detailsError = descErr;
      });
      return;
    }

    setState(() {
      _customReasonError = null;
      _detailsError = null;
      _isSubmitting = true;
    });

    final parcelsProvider = Provider.of<ParcelsProvider?>(
      context,
      listen: false,
    );
    await parcelsProvider?.submitParcelDispute(
      parcelId: widget.parcelId ?? widget.reportId,
      reason: _selectedReason,
      customReason: _isOtherSelected ? customText : null,
      details: descText,
      hasPhotoEvidence: _hasAttachedPhoto,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _phase = DisputePhase.underReview;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    switch (_phase) {
      case DisputePhase.open:
        return _buildOpenDisputeView(isAr);
      case DisputePhase.underReview:
        return _buildUnderReviewView(isAr);
      case DisputePhase.resolved:
        return _buildResolvedView(isAr);
    }
  }

  // Phase 1: فتح نزاع
  Widget _buildOpenDisputeView(bool isAr) {
    final reasons = isAr ? _reasonsAr : _reasonsEn;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'بلاغ عن الطرد' : 'Parcel Dispute',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space12,
              ),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'ما المشكلة التي حدثت؟' : 'What issue occurred?',
                            style: AppTypography.title().copyWith(fontSize: 17),
                          ),
                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(reasons.length, (index) {
                              final reasonAr = _reasonsAr[index];
                              final isOther = reasonAr == _otherKeyAr;
                              final isSelected = _selectedReason == reasonAr;
                              return MashwarChip(
                                key: isOther
                                    ? const ValueKey('parcel_dispute_reason_other')
                                    : ValueKey('parcel_dispute_reason_$index'),
                                label: reasons[index],
                                isSelected: isSelected,
                                onTap: () => setState(() {
                                  _selectedReason = reasonAr;
                                  _customReasonError = null;
                                }),
                              );
                            }),
                          ),

                          if (_isOtherSelected) ...[
                            const SizedBox(height: 14),
                            MashwarTextField(
                              key: const ValueKey(
                                'parcel_dispute_custom_reason_input',
                              ),
                              controller: _customReasonController,
                              label: isAr
                                  ? 'سبب مخصص للبلاغ'
                                  : 'Custom Dispute Reason',
                              hint: isAr
                                  ? 'مثال: تأخر التسليم عن الموعد المتفق عليه'
                                  : 'e.g. Delayed past agreed handover window',
                              errorText: _customReasonError,
                              onChanged: (_) {
                                if (_customReasonError != null) {
                                  setState(() => _customReasonError = null);
                                }
                              },
                            ),
                          ],

                          const SizedBox(height: 18),

                          MashwarTextField(
                            key: const ValueKey('parcel_dispute_details_input'),
                            controller: _descController,
                            label: isAr ? 'تفاصيل المشكلة' : 'Issue Details',
                            hint: isAr
                                ? 'اشرح بالتفصيل ما حدث'
                                : 'Describe in detail what happened',
                            errorText: _detailsError,
                            maxLines: 4,
                            onChanged: (_) {
                              if (_detailsError != null) {
                                setState(() => _detailsError = null);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Interactive Photo Proof Box
                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        side: BorderSide(
                          color: _hasAttachedPhoto
                              ? AppColors.teal
                              : AppColors.slateBorder,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const ValueKey('parcel_dispute_photo_btn'),
                        onTap: () => setState(
                          () => _hasAttachedPhoto = !_hasAttachedPhoto,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimens.space16),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _hasAttachedPhoto
                                        ? AppColors.tealSurface
                                        : AppColors.slateBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _hasAttachedPhoto
                                        ? Icons.check_circle_rounded
                                        : Icons.add_a_photo_outlined,
                                    size: 28,
                                    color: _hasAttachedPhoto
                                        ? AppColors.teal
                                        : AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _hasAttachedPhoto
                                      ? (isAr
                                          ? 'تم إرفاق صورة توثيق حالة الطرد ✓'
                                          : 'Parcel condition photo attached ✓')
                                      : (isAr
                                          ? 'ارفع صور تثبت المشكلة (اختياري ويسرّع الحل)'
                                          : 'Attach photo evidence (Optional, speeds up review)'),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.label(
                                    color: _hasAttachedPhoto
                                        ? AppColors.teal
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    MashwarButton(
                      key: const ValueKey('parcel_dispute_submit_btn'),
                      text: isAr ? 'تقديم البلاغ' : 'Submit Dispute Report',
                      isLoading: _isSubmitting,
                      onPressed: () => _submitDispute(isAr),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Phase 2: قيد المراجعة
  Widget _buildUnderReviewView(bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${isAr ? "بلاغ" : "Report"} ${widget.reportId}',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(0.0, 2000.0),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: MashwarFadeSlideIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            AlertBanner(
                              message: isAr
                                  ? 'فريق الثقة والأمان يراجع بلاغك. الرد خلال 24 - 48 ساعة.'
                                  : 'Trust & Safety team is reviewing your dispute within 24-48 hours.',
                              type: AlertBannerType.warning,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimens.space16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusCard,
                                ),
                                border: Border.all(color: AppColors.slateBorder),
                              ),
                              child: Column(
                                children: [
                                  _buildRow(
                                    isAr ? 'رقم البلاغ' : 'Report ID',
                                    widget.reportId,
                                  ),
                                  const Divider(
                                    height: 20,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildRow(
                                    isAr ? 'السبب' : 'Reason',
                                    _resolvedReasonDisplay(isAr),
                                  ),
                                  const Divider(
                                    height: 20,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildRow(
                                    isAr ? 'التفاصيل' : 'Details',
                                    _descController.text.trim(),
                                  ),
                                  const Divider(
                                    height: 20,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildRow(
                                    isAr ? 'الحالة' : 'Status',
                                    isAr
                                        ? 'قيد المراجعة والتحقيق'
                                        : 'Under Investigation',
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: MashwarButton(
                            key: const ValueKey('parcel_dispute_back_btn'),
                            text: isAr ? 'الرجوع لطرودي' : 'Back to My Parcels',
                            variant: MashwarButtonVariant.secondary,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Phase 3: تم الحل
  Widget _buildResolvedView(bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${isAr ? "بلاغ" : "Report"} ${widget.reportId}',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(0.0, 2000.0),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: MashwarFadeSlideIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            AlertBanner(
                              message: isAr
                                  ? 'تم تعويضك بمبلغ 300 ر.ق في محفظتك'
                                  : 'You have been compensated with 300 QAR in your wallet',
                              type: AlertBannerType.success,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimens.space16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusCard,
                                ),
                                border: Border.all(color: AppColors.slateBorder),
                              ),
                              child: Column(
                                children: [
                                  _buildRow(
                                    isAr ? 'القرار' : 'Resolution',
                                    isAr
                                        ? 'تمت الموافقة على التعويض'
                                        : 'Compensation Approved',
                                  ),
                                  const Divider(
                                    height: 20,
                                    color: AppColors.slateBorder,
                                  ),
                                  _buildRow(
                                    isAr ? 'المبلغ المودع' : 'Deposited Amount',
                                    '300 ${isAr ? "ر.ق" : "QAR"}',
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: MashwarButton(
                            text: isAr
                                ? 'عرض رصيد المحفظة'
                                : 'View Wallet Balance',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
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
