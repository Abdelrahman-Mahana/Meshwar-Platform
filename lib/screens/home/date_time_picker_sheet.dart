import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/localization/app_strings.dart';

class DateTimePickerSheet extends StatefulWidget {
  const DateTimePickerSheet({
    super.key,
    required this.selectedDay,
    required this.selectedTime,
    required this.onApply,
  });

  final String selectedDay;
  final String selectedTime;
  final void Function(String day, String time) onApply;

  @override
  State<DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<DateTimePickerSheet> {
  late String _day;
  late String _time;

  final List<String> _daysAr = ['النهارده', 'بكرة', 'الجمعة 6', 'السبت 7', 'تاريخ تاني'];
  final List<String> _daysEn = ['Today', 'Tomorrow', 'Fri 6', 'Sat 7', 'Other date'];

  final List<String> _timesAr = ['أي وقت', 'صباحاً 5-12', 'ظهراً 12-4', 'مساءً 4-9'];
  final List<String> _timesEn = ['Any time', 'Morning 5-12', 'Afternoon 12-4', 'Evening 4-9'];

  @override
  void initState() {
    super.initState();
    _day = widget.selectedDay;
    _time = widget.selectedTime;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final days = isAr ? _daysAr : _daysEn;
    final times = isAr ? _timesAr : _timesEn;

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

          // Day Selection
          Text(isAr ? 'اختر تاريخ السفر' : 'Select Travel Date', style: AppTypography.title().copyWith(fontSize: 18)),
          const SizedBox(height: AppDimens.space12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(days.length, (index) {
                final dayVal = _daysAr[index];
                final isSelected = _day == dayVal || _day == _daysEn[index];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: MashwarChip(
                    label: days[index],
                    isSelected: isSelected,
                    onTap: () => setState(() => _day = dayVal),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppDimens.space24),

          // Time Slots Selection
          Text(isAr ? 'الوقت المفضل للتحرك' : 'Preferred Departure Time', style: AppTypography.title().copyWith(fontSize: 18)),
          const SizedBox(height: AppDimens.space12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(times.length, (index) {
              final timeVal = _timesAr[index];
              final isSelected = _time == timeVal || _time == _timesEn[index];
              return MashwarChip(
                label: times[index],
                isSelected: isSelected,
                onTap: () => setState(() => _time = timeVal),
              );
            }),
          ),
          const SizedBox(height: AppDimens.space32),

          // Apply Button
          MashwarButton(
            text: isAr ? 'تطبيق' : 'Apply',
            onPressed: () {
              widget.onApply(_day, _time);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
