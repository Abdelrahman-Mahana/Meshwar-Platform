import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';

class RateTripScreen extends StatefulWidget {
  final String? rideId;
  final String driverName;
  final String route;
  final bool isParcel;

  const RateTripScreen({
    super.key,
    this.rideId,
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

  static const List<String> _complimentsRideAr = [
    'ملتزم بالموعد دقيقاً',
    'قيادة هادئة ومريحة',
    'سيارة نظيفة ومكيفة',
    'تعامل راقي ومحترم',
    'وصلنا في أسرع وقت',
  ];

  static const List<String> _complimentsRideEn = [
    'Punctual & On Time',
    'Smooth & Safe Driving',
    'Clean & AC Vehicle',
    'Respectful & Polite',
    'Fast & Efficient Route',
  ];

  static const List<String> _complimentsParcelAr = [
    'طرد سليم وبحالة ممتازة',
    'تسليم سريع وفي الموعد',
    'حرص شديد على الشحنة',
    'تعامل أمين ومحترم',
  ];

  static const List<String> _complimentsParcelEn = [
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

  Future<void> _submitReview() async {
    if (_isSubmitting) return;
    final settings = Provider.of<SettingsProvider?>(context, listen: false);
    final isAr = settings?.isArabic ?? context.isArabic;
    final ridesProvider = Provider.of<RidesProvider?>(context, listen: false);

    setState(() => _isSubmitting = true);
    await ridesProvider?.submitRideRating(
      rideId: widget.rideId,
      driverName: widget.driverName,
      rating: _rating,
      tags: _selectedCompliments.toList(),
      tipAmount: _selectedTip,
      comment: _commentController.text.trim(),
      isParcel: widget.isParcel,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'شكراً لتقييمك! تقييمك ($_rating/5) تم حفظه بنجاح.'
              : 'Thank you! Your review ($_rating/5) has been saved.',
        ),
        backgroundColor: AppColors.teal,
      ),
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_rating);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? context.isArabic;
    final compliments = widget.isParcel
        ? (isAr ? _complimentsParcelAr : _complimentsParcelEn)
        : (isAr ? _complimentsRideAr : _complimentsRideEn);

    return Scaffold(
      backgroundColor: AppColors.slateBg,
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: MashwarFadeSlideIn(
                duration: const Duration(milliseconds: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Driver Hero Card
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                        border: Border.all(color: AppColors.slateBorder),
                      ),
                      child: Column(
                        children: [
                          MashwarUserAvatar(
                            key: const ValueKey('rate_trip_driver_avatar'),
                            avatarUrl: null,
                            fullName: widget.driverName,
                            size: 72,
                            borderWidth: 2,
                            borderColor: AppColors.slateBorder,
                            autoCommunityPortrait: true,
                            showVerifiedBadge: true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.driverName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.title(),
                                ),
                              ),
                              const SizedBox(width: 6),
                              MashwarBadge(
                                type: BadgeType.verified,
                                customLabel: isAr ? 'موثق' : 'Verified',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.translateRoute(
                              widget.route,
                              isArabic: isAr,
                            ),
                            style: AppTypography.bodySecondary(),
                          ),
                          const SizedBox(height: 16),

                          // Interactive Star Rating Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starIndex = index + 1;
                              final isActive = starIndex <= _rating;
                              return AnimatedScale(
                                scale: isActive ? 1.06 : 0.94,
                                duration: const Duration(milliseconds: 140),
                                child: IconButton(
                                  key: ValueKey('rate_trip_star_$starIndex'),
                                  iconSize: 40,
                                  icon: Icon(
                                    isActive
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: isActive
                                        ? AppColors.gold
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  onPressed: () =>
                                      setState(() => _rating = starIndex),
                                ),
                              );
                            }),
                          ),
                          Text(
                            _rating == 5
                                ? (isAr
                                    ? 'تجربة ممتازة 5/5'
                                    : 'Excellent Experience 5/5')
                                : _rating >= 4
                                    ? (isAr ? 'تجربة جيدة جداً' : 'Very Good')
                                    : _rating >= 3
                                        ? (isAr ? 'تجربة مقبولة' : 'Acceptable')
                                        : (isAr
                                            ? 'تحتاج إلى تحسين'
                                            : 'Needs Improvement'),
                            style: AppTypography.body(color: AppColors.navy)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimens.space20),

                    // Compliments Chips
                    Text(
                      isAr
                          ? 'ما الذي نال إعجابك؟'
                          : 'What did you like the most?',
                      style: AppTypography.body(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700),
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
                            color: isSelected
                                ? AppColors.teal
                                : AppColors.slateBorder,
                          ),
                          labelStyle: AppTypography.label(
                            color:
                                isSelected ? AppColors.teal : AppColors.navy,
                          ).copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
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

                    const SizedBox(height: AppDimens.space20),

                    // Driver Tip
                    Text(
                      isAr
                          ? 'إكرامية السائق (اختياري)'
                          : 'Driver Tip (Optional)',
                      style: AppTypography.body(color: AppColors.navy)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [0, 10, 20, 50].asMap().entries.map((entry) {
                        final idx = entry.key;
                        final tip = entry.value;
                        final isSel = _selectedTip == tip;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: idx < 3 ? 8 : 0,
                            ),
                            child: Material(
                              color: isSel ? AppColors.navy : Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusButton,
                              ),
                              child: InkWell(
                                key: ValueKey('rate_trip_tip_$tip'),
                                onTap: () => setState(() => _selectedTip = tip),
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusButton,
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: AppDimens.minTouchTarget,
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusButton,
                                    ),
                                    border: Border.all(
                                      color: isSel
                                          ? AppColors.navy
                                          : AppColors.slateBorder,
                                    ),
                                  ),
                                  child: Text(
                                    tip == 0
                                        ? (isAr ? 'بدون' : 'None')
                                        : '$tip ${isAr ? "ر.ق" : "QAR"}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label(
                                      color:
                                          isSel ? Colors.white : AppColors.navy,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppDimens.space20),

                    // Comment text area
                    TextField(
                      key: const ValueKey('rate_trip_comment_input'),
                      controller: _commentController,
                      maxLines: 3,
                      style: AppTypography.body(),
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'أضف ملاحظات أو تعليق للكابتن...'
                            : 'Add notes or comments for driver...',
                        hintStyle: AppTypography.bodySecondary(),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusCard,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.slateBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusCard,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.slateBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusCard,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.navy,
                            width: AppDimens.borderWidthFocused,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimens.space24),

                    MashwarButton(
                      key: const ValueKey('rate_trip_submit_btn'),
                      text: _isSubmitting
                          ? (isAr ? 'جاري الإرسال...' : 'Submitting...')
                          : (isAr ? 'إرسال التقييم' : 'Submit Review'),
                      isLoading: _isSubmitting,
                      onPressed: _submitReview,
                    ),

                    const SizedBox(height: AppDimens.space20),
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
