import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../state/rides_provider.dart';

class SearchFiltersSheet extends StatelessWidget {
  const SearchFiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final rides = context.watch<RidesProvider>();
    final count = rides.filteredRides.length;
    final isAr = context.isArabic;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusBottomSheet),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                MashwarSheetHeader(
                  title: isAr ? 'الفلاتر والترتيب' : 'Filters & Sort',
                  leadingIcon: Icons.tune_rounded,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: rides.resetFilters,
                    child: Text(
                      isAr ? 'مسح الكل' : 'Reset All',
                      style: AppTypography.label(color: AppColors.navy)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.space4),

                // Sort
                Text(
                  isAr ? 'الترتيب' : 'Sort By',
                  style: AppTypography.label(color: AppColors.navy),
                ),
                const SizedBox(height: AppDimens.space8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MashwarChip(
                      label: isAr ? 'الأقرب وقتاً' : 'Earliest',
                      isSelected: rides.sortBy == SortOption.closestTime,
                      onTap: () => rides.setSortOption(SortOption.closestTime),
                    ),
                    MashwarChip(
                      label: isAr ? 'الأرخص' : 'Cheapest',
                      isSelected: rides.sortBy == SortOption.cheapest,
                      onTap: () => rides.setSortOption(SortOption.cheapest),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space20),

                // Time Slots
                Text(
                  isAr ? 'وقت الانطلاق' : 'Departure Time',
                  style: AppTypography.label(color: AppColors.navy),
                ),
                const SizedBox(height: AppDimens.space8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    ('أي وقت', 'Any time'),
                    ('صباحاً', 'Morning'),
                    ('ظهراً', 'Afternoon'),
                    ('مساءً', 'Evening'),
                  ].map((slot) {
                    return MashwarChip(
                      label: isAr ? slot.$1 : slot.$2,
                      isSelected: rides.timeSlot == slot.$1,
                      onTap: () => rides.setTimeSlot(slot.$1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimens.space20),

                // Seats Stepper
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    border: Border.all(
                      color: AppColors.slateBorder,
                      width: AppDimens.borderWidth,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isAr ? 'المقاعد المطلوبة' : 'Seats Needed',
                          style: AppTypography.body().copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: rides.seatsCount > 1
                                ? () =>
                                    rides.setSeatsCount(rides.seatsCount - 1)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.navy,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${rides.seatsCount}',
                              style: AppTypography.title().copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: rides.seatsCount < 6
                                ? () =>
                                    rides.setSeatsCount(rides.seatsCount + 1)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.navy,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.space16),

                // Toggle Switches Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    border: Border.all(
                      color: AppColors.slateBorder,
                      width: AppDimens.borderWidth,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        title: isAr ? 'تقبل طرود' : 'Accepts Parcels',
                        value: rides.filterAcceptsParcels,
                        onChanged: (_) => rides.toggleFilterAcceptsParcels(),
                      ),
                      const Divider(height: 1, color: AppColors.slateBorder),
                      _buildSwitchTile(
                        title: isAr ? 'للسيدات فقط' : 'Ladies Only',
                        subtitle: isAr
                            ? 'متاحة للراكبات السيدات فقط'
                            : 'Available for female passengers only',
                        value: rides.filterLadiesOnly,
                        onChanged: (_) => rides.toggleFilterLadiesOnly(),
                      ),
                      const Divider(height: 1, color: AppColors.slateBorder),
                      _buildSwitchTile(
                        title: isAr ? 'حجز تلقائي' : 'Instant Booking',
                        subtitle: isAr
                            ? 'تأكيد مباشر بدون انتظار موافقة السائق'
                            : 'Without waiting for driver approval',
                        value: rides.filterInstantBooking,
                        onChanged: (_) => rides.toggleFilterInstantBooking(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.space24),

                // Primary CTA Button
                MashwarButton(
                  text: isAr
                      ? 'عرض $count ${count == 1 ? "رحلة" : "رحلات"}'
                      : 'Show $count ${count == 1 ? "Ride" : "Rides"}',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      activeTrackColor: AppColors.navy,
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: AppTypography.body().copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.bodySmall(),
            )
          : null,
    );
  }
}
