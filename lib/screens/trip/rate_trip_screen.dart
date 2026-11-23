import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/localization/app_strings.dart';
import '../../state/settings_provider.dart';

class RateTripScreen extends StatefulWidget {
  final String driverName;
  final String route;
  final bool isParcel;

  const RateTripScreen({
    super.key,
    this.driverName = 'جاسم الكواري',
    this.route = 'الدوحة ← الخور',
    this.isParcel = false,
  });

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  int _rating = 5;
  int _selectedTip = 0;
  final Set<String> _selectedCompliments = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _complimentsRideAr = [
    'ملتزم بالموعد دقيقاً',
    'قيادة هادئة ومريحة',
    'سيارة نظيفة ومكيفة',
    'تعامل راقي ومحترم',
    'وصلنا في أسرع وقت',
  ];

  final List<String> _complimentsRideEn = [
    'Punctual & On Time',
    'Smooth & Safe Driving',
    'Clean & AC Vehicle',
    'Respectful & Polite',
    'Fast & Efficient Route',
  ];

  final List<String> _complimentsParcelAr = [
    'طرد سليم وبحالة ممتازة',
    'تسليم سريع وفي الموعد',
    'حرص شديد على الشحنة',
    'تعامل أمين ومحترم',
  ];

  final List<String> _complimentsParcelEn = [
    'Parcel Safe & Intact',
    'Fast & Prompt Delivery',
    'High Care with Package',
    'Trustworthy & Reliable',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isSubmitting = false);
      final isAr = context.read<SettingsProvider>().isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'شكراً لتقييمك! تقييمك يساعد في رفع جودة مشوار.' : 'Thank you for your review! It helps keep MASHWAR great.',
          ),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;
    final compliments = widget.isParcel
        ? (isAr ? _complimentsParcelAr : _complimentsParcelEn)
        : (isAr ? _complimentsRideAr : _complimentsRideEn);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAr ? 'تقييم المشوار' : 'Rate Trip',
          style: AppTypography.title(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 280),
                child: Column(
                  children: [
                    // Driver Hero Card
                    MashwarSectionCard(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.navy.withValues(alpha: 0.14), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                widget.driverName.isNotEmpty ? widget.driverName[0] : (isAr ? 'ك' : 'D'),
                                style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.driverName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.title().copyWith(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 6),
                              MashwarBadge(type: BadgeType.verified, customLabel: isAr ? 'موثق' : 'Verified'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(AppStrings.translateRoute(widget.route, isArabic: isAr), style: AppTypography.bodySecondary()),
                          const SizedBox(height: 16),

                          // Interactive Star Rating Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starIndex = index + 1;
                              final isActive = starIndex <= _rating;
                              return AnimatedScale(
                                scale: isActive ? 1.08 : 0.94,
                                duration: const Duration(milliseconds: 140),
                                child: IconButton(
                                  iconSize: 40,
                                  icon: Icon(
                                    isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: isActive ? AppColors.gold : const Color(0xFFCBD5E1),
                                  ),
                                  onPressed: () => setState(() => _rating = starIndex),
                                ),
                              );
                            }),
                          ),
                          Text(
                            _rating == 5
                                ? (isAr ? 'تجربة ممتازة 5/5' : 'Excellent Experience 5/5')
                                : _rating >= 4
                                    ? (isAr ? 'تجربة جيدة جداً' : 'Very Good')
                                    : _rating >= 3
                                        ? (isAr ? 'تجربة مقبولة' : 'Acceptable')
                                        : (isAr ? 'تحتاج إلى تحسين' : 'Needs Improvement'),
                            style: AppTypography.body().copyWith(fontWeight: FontWeight.w800, color: AppColors.navy),
                          ),
                        ],
                      ),
                    ),

              const SizedBox(height: AppDimens.space24),

              // Compliments Chips
              Align(
                alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  isAr ? 'ما الذي نال إعجابك؟' : 'What did you like the most?',
                  style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: compliments.map((item) {
                  final isSelected = _selectedCompliments.contains(item);
                  return FilterChip(
                    label: Text(item),
                    selected: isSelected,
                    selectedColor: AppColors.tealSurface,
                    checkmarkColor: AppColors.teal,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.teal : AppColors.borderDisabled,
                    ),
                    labelStyle: AppTypography.label(
                      color: isSelected ? AppColors.teal : AppColors.textPrimary,
                    ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCompliments.add(item);
                        } else {
                          _selectedCompliments.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDimens.space24),

              // Driver Tip
              Align(
                alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  isAr ? 'إكرامية السائق (اختياري)' : 'Driver Tip (Optional)',
                  style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [0, 10, 20, 50].asMap().entries.map((entry) {
                  final idx = entry.key;
                  final tip = entry.value;
                  final isSel = _selectedTip == tip;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: idx < 3 ? 8 : 0),
                      child: Material(
                        color: isSel ? AppColors.navy : Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                        child: InkWell(
                          onTap: () => setState(() => _selectedTip = tip),
                          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: AppDimens.minTouchTarget),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                              border: Border.all(
                                color: isSel ? AppColors.navy : AppColors.borderDisabled,
                              ),
                            ),
                            child: Text(
                              tip == 0 ? (isAr ? 'بدون' : 'None') : '$tip ${isAr ? 'ر.ق' : 'QAR'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                color: isSel ? Colors.white : AppColors.navy,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDimens.space24),

              // Comment text area
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isAr ? 'أضف ملاحظات أو تعليق للكابتن...' : 'Add notes or comments for driver...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    borderSide: const BorderSide(color: AppColors.borderDisabled),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    borderSide: const BorderSide(color: AppColors.borderDisabled),
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.space32),

              MashwarButton(
                text: _isSubmitting
                    ? (isAr ? 'جاري الإرسال...' : 'Submitting...')
                    : (isAr ? 'إرسال التقييم' : 'Submit Review'),
                isLoading: _isSubmitting,
                onPressed: _submitReview,
              ),

              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    ),
    ),
    ),
    );
  }
}
