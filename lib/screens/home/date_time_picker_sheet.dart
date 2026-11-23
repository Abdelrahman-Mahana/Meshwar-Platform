import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
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
  String? _customDateLabelAr;
  String? _customDateLabelEn;

  static const List<String> _weekdaysAr = [
    'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
  ];
  static const List<String> _weekdaysEn = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> _monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];
  static const List<String> _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  late final List<String> _daysAr;
  late final List<String> _daysEn;

  final List<String> _timesAr = ['أي وقت', 'صباحاً 5-12', 'ظهراً 12-4', 'مساءً 4-9'];
  final List<String> _timesEn = ['Any time', 'Morning 5-12', 'Afternoon 12-4', 'Evening 4-9'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final day2 = now.add(const Duration(days: 2));
    final day3 = now.add(const Duration(days: 3));
    _daysAr = [
      'اليوم',
      'غداً',
      '${_weekdaysAr[day2.weekday - 1]} ${day2.day}',
      '${_weekdaysAr[day3.weekday - 1]} ${day3.day}',
      'تاريخ آخر',
    ];
    _daysEn = [
      'Today',
      'Tomorrow',
      '${_weekdaysEn[day2.weekday - 1]} ${day2.day}',
      '${_weekdaysEn[day3.weekday - 1]} ${day3.day}',
      'Other date',
    ];
    _day = widget.selectedDay;
    _time = widget.selectedTime;
  }

  Future<void> _pickCustomDate(bool isAr) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null && mounted) {
      final arLabel = '${_weekdaysAr[picked.weekday - 1]} ${picked.day} ${_monthsAr[picked.month - 1]}';
      final enLabel = '${_weekdaysEn[picked.weekday - 1]} ${picked.day} ${_monthsEn[picked.month - 1]}';
      setState(() {
        _customDateLabelAr = arLabel;
        _customDateLabelEn = enLabel;
        _day = arLabel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;
    final days = List<String>.from(isAr ? _daysAr : _daysEn);
    if (_customDateLabelAr != null) {
      days[4] = isAr ? _customDateLabelAr! : _customDateLabelEn!;
    }
    final times = isAr ? _timesAr : _timesEn;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MashwarSheetHeader(
                    title: isAr ? 'اختر تاريخ السفر' : 'Select Travel Date',
                    leadingIcon: Icons.event_available_rounded,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(days.length, (index) {
                        final isOther = index == 4;
                        final dayVal = isOther && _customDateLabelAr != null ? _customDateLabelAr! : _daysAr[index];
                        final isSelected = isOther
                            ? (_customDateLabelAr != null && _day == _customDateLabelAr)
                            : (_day == dayVal || _day == _daysEn[index]);
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: MashwarChip(
                            label: days[index],
                            isSelected: isSelected,
                            onTap: () {
                              if (isOther) {
                                _pickCustomDate(isAr);
                              } else {
                                setState(() => _day = dayVal);
                              }
                            },
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
            ),
          ),
        ),
      ),
    );
  }
}
