import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/localization/app_strings.dart';
import '../../state/rides_provider.dart';

class SearchFiltersSheet extends StatelessWidget {
  const SearchFiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final rides = context.watch<RidesProvider>();
    final count = rides.filteredRides.length;
    final isAr = context.isArabic;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
      ),
      padding: const EdgeInsets.all(AppDimens.space24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? 'الفلاتر' : 'Filters', style: AppTypography.title()),
                TextButton(
                  onPressed: () => rides.resetFilters(),
                  child: Text(
                    isAr ? 'مسح الكل' : 'Reset All',
                    style: AppTypography.bodySecondary(color: AppColors.navy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // Sort
            Text(isAr ? 'الترتيب' : 'Sort By', style: AppTypography.label()),
            const SizedBox(height: AppDimens.space8),
            Row(
              children: [
                MashwarChip(
                  label: isAr ? 'الأقرب وقتاً' : 'Earliest',
                  isSelected: rides.sortBy == SortOption.closestTime,
                  onTap: () => rides.setSortOption(SortOption.closestTime),
                ),
                const SizedBox(width: 8),
                MashwarChip(
                  label: isAr ? 'الأرخص' : 'Cheapest',
                  isSelected: rides.sortBy == SortOption.cheapest,
                  onTap: () => rides.setSortOption(SortOption.cheapest),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space20),

            // Time Slots
            Text(isAr ? 'وقت الانطلاق' : 'Departure Time', style: AppTypography.label()),
            const SizedBox(height: AppDimens.space8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['أي وقت', 'صباحاً', 'ظهراً', 'مساءً'].map((t) {
                return MashwarChip(
                  label: context.tr(t),
                  isSelected: rides.timeSlot == t,
                  onTap: () => rides.setTimeSlot(t),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.space20),

            // Toggle Switches
            _buildSwitchTile(
              title: isAr ? 'تقبل طرود' : 'Accepts Parcels',
              value: rides.filterAcceptsParcels,
              onChanged: (_) => rides.toggleFilterAcceptsParcels(),
            ),
            _buildSwitchTile(
              title: isAr ? 'للسيدات فقط' : 'Ladies Only',
              subtitle: isAr ? 'متاحة للراكبات السيدات فقط' : 'Available for female passengers only',
              value: rides.filterLadiesOnly,
              onChanged: (_) => rides.toggleFilterLadiesOnly(),
            ),
            _buildSwitchTile(
              title: isAr ? 'حجز تلقائي' : 'Instant Booking',
              subtitle: isAr ? 'من غير انتظار موافقة السائق' : 'Without waiting for driver approval',
              value: rides.filterInstantBooking,
              onChanged: (_) => rides.toggleFilterInstantBooking(),
            ),
            const SizedBox(height: AppDimens.space24),

            // CTA Button
            MashwarButton(
              text: isAr ? 'عرض $count ${count == 1 ? "رحلة" : "رحلات"}' : 'Show $count ${count == 1 ? "Ride" : "Rides"}',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppDimens.space12),
          ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null) ...[
                Text(
                  subtitle,
                  style: AppTypography.label(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.teal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
