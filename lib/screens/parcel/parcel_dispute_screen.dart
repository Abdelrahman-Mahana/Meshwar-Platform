import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/alert_banner.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/widgets/mashwar_text_field.dart';
import '../../core/localization/app_strings.dart';

enum DisputePhase {
  open,        // فتح نزاع
  underReview, // قيد المراجعة
  resolved,    // تم الحل
}

class ParcelDisputeScreen extends StatefulWidget {
  const ParcelDisputeScreen({super.key, this.reportId = '#4821'});

  final String reportId;

  @override
  State<ParcelDisputeScreen> createState() => _ParcelDisputeScreenState();
}

class _ParcelDisputeScreenState extends State<ParcelDisputeScreen> {
  DisputePhase _phase = DisputePhase.open;
  String _selectedReason = 'وصل تالف';
  final TextEditingController _descController = TextEditingController(text: 'الطرد وصل مفتوحاً');

  final List<String> _reasonsAr = [
    'وصل تالف',
    'لم يصل',
    'المستلم لم يستلم',
    'سبب آخر',
  ];

  final List<String> _reasonsEn = [
    'Arrived damaged',
    'Did not arrive',
    'Receiver didn\'t receive',
    'Other reason',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
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

  // Phase 1: فتح نزاع (Page 36)
  Widget _buildOpenDisputeView(bool isAr) {
    final reasons = isAr ? _reasonsAr : _reasonsEn;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'بلاغ عن الطرد' : 'Parcel Dispute', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space12),
              child: MashwarFadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MashwarSectionCard(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? 'ما المشكلة التي حدثت؟' : 'What issue occurred?', style: AppTypography.title().copyWith(fontSize: 18)),
                          const SizedBox(height: 12),

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
                          const SizedBox(height: 20),

                          MashwarTextField(
                            controller: _descController,
                            label: isAr ? 'تفاصيل المشكلة' : 'Issue Details',
                            hint: isAr ? 'اشرح بالتفصيل ما حدث' : 'Describe in detail what happened',
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photo proof upload box
                    MashwarSectionCard(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.navy.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.navy),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isAr ? 'ارفع صور تثبت المشكلة (اختياري بس بيسرّع الحل)' : 'Upload photos proving issue (Optional but accelerates resolution)',
                              textAlign: TextAlign.center,
                              style: AppTypography.label(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    MashwarButton(
                      text: isAr ? 'تقديم البلاغ' : 'Submit Dispute Report',
                      onPressed: () => setState(() => _phase = DisputePhase.underReview),
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

  // Phase 2: قيد المراجعة (Page 36)
  Widget _buildUnderReviewView(bool isAr) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('${isAr ? "بلاغ" : "Report"} ${widget.reportId}', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
              child: MashwarFadeSlideIn(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    AlertBanner(
                      message: isAr
                          ? 'فريق الدعم بيراجع بلاغك. الرد خلال 48 ساعة'
                          : 'Support team is reviewing your dispute. Response within 48 hours',
                      type: AlertBannerType.warning,
                    ),
                    const SizedBox(height: 24),

                    MashwarSectionCard(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            _buildRow(isAr ? 'رقم البلاغ' : 'Report ID', widget.reportId),
                            const Divider(height: 20, color: AppColors.borderDisabled),
                            _buildRow(
                              isAr ? 'السبب' : 'Reason',
                              isAr
                                  ? _selectedReason
                                  : (_reasonsAr.contains(_selectedReason)
                                      ? _reasonsEn[_reasonsAr.indexOf(_selectedReason)]
                                      : _selectedReason),
                            ),
                            const Divider(height: 20, color: AppColors.borderDisabled),
                            _buildRow(isAr ? 'الحالة' : 'Status', isAr ? 'قيد المراجعة والتحقيق' : 'Under Investigation'),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),
                    MashwarButton(
                      text: isAr ? 'الرجوع لطرودي' : 'Back to My Parcels',
                      variant: MashwarButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
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

  // Phase 3: تم الحل (Page 36)
  Widget _buildResolvedView(bool isAr) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('${isAr ? "بلاغ" : "Report"} ${widget.reportId}', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
              child: MashwarFadeSlideIn(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    AlertBanner(
                      message: isAr
                          ? 'تم تعويضك بمبلغ 300 ر.ق في محفظتك'
                          : 'You have been compensated with 300 QAR in your wallet',
                      type: AlertBannerType.success,
                    ),
                    const SizedBox(height: 24),

                    MashwarSectionCard(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            _buildRow(isAr ? 'القرار' : 'Resolution', isAr ? 'تمت الموافقة على التعويض' : 'Compensation Approved'),
                            const Divider(height: 20, color: AppColors.borderDisabled),
                            _buildRow(isAr ? 'المبلغ المودع' : 'Deposited Amount', '300 ${isAr ? "ر.ق" : "QAR"}', isBold: true),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),
                    MashwarButton(
                      text: isAr ? 'عرض رصيد المحفظة' : 'View Wallet Balance',
                      onPressed: () => Navigator.of(context).pop(),
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
