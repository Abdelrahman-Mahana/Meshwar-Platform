import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../state/alerts_provider.dart';
import '../../state/rides_provider.dart';
import '../search/search_results_screen.dart';

class MyAlertsScreen extends StatelessWidget {
  const MyAlertsScreen({super.key});

  static const String _otherKey = '__other_custom_city__';

  void _showAddAlertSheet(BuildContext parentContext, bool isAr) {
    String selectedFrom = 'الدوحة';
    String selectedTo = 'الخور';
    String dateRange = 'الأحد القادم · صباحاً';
    String category = 'ركاب';
    String? validationError;

    final customFromController = TextEditingController();
    final customToController = TextEditingController();

    final cities = [
      'الدوحة',
      'الريان',
      'الوكرة',
      'الخور',
      'لوسيل',
      'دخان',
      'مسيعيد',
      'أم صلال',
    ];
    final dates = [
      'غداً · صباحاً',
      'الجمعة القادمة',
      'الأحد القادم · صباحاً',
      'طوال الأسبوع',
    ];

    showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.88,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppDimens.space24,
                  right: AppDimens.space24,
                  top: AppDimens.space16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                      AppDimens.space24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MashwarSheetHeader(
                      title: isAr ? 'إضافة تنبيه لمسار جديد' : 'Create Route Alert',
                      subtitle: isAr
                          ? 'سنرسل لك إشعاراً فورياً بمجرد نشر رحلة تطابق مسارك'
                          : 'We will notify you immediately when a matching trip is posted',
                      leadingIcon: Icons.notifications_active_outlined,
                      onClose: () => Navigator.of(ctx).pop(),
                    ),
                    const SizedBox(height: 16),

                    // From City
                    Text(
                      isAr ? 'من مدينة' : 'From City',
                      style: AppTypography.label(color: AppColors.navy).copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...cities.map((c) {
                          return MashwarChip(
                            label: sheetContext.trCity(c),
                            isSelected: selectedFrom == c,
                            onTap: () => setSheetState(() {
                              selectedFrom = c;
                              validationError = null;
                            }),
                          );
                        }),
                        MashwarChip(
                          key: const ValueKey('alert_from_other_chip'),
                          label: isAr ? 'أخرى (مدينة مخصصة)' : 'Other (Custom City)',
                          isSelected: selectedFrom == _otherKey,
                          onTap: () => setSheetState(() {
                            selectedFrom = _otherKey;
                            validationError = null;
                          }),
                        ),
                      ],
                    ),
                    if (selectedFrom == _otherKey) ...[
                      const SizedBox(height: 10),
                      TextField(
                        key: const ValueKey('alert_from_custom_input'),
                        controller: customFromController,
                        onChanged: (_) {
                          if (validationError != null) {
                            setSheetState(() => validationError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'اكتب مدينة أو منطقة الانطلاق (مثال: رأس لفان)'
                              : 'Enter custom departure city or hub (e.g. Ras Laffan)',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.slateBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.navy,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // To City
                    Text(
                      isAr ? 'إلى مدينة' : 'To City',
                      style: AppTypography.label(color: AppColors.navy).copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...cities.map((c) {
                          return MashwarChip(
                            label: sheetContext.trCity(c),
                            isSelected: selectedTo == c,
                            onTap: () => setSheetState(() {
                              selectedTo = c;
                              validationError = null;
                            }),
                          );
                        }),
                        MashwarChip(
                          key: const ValueKey('alert_to_other_chip'),
                          label: isAr ? 'أخرى (مدينة مخصصة)' : 'Other (Custom City)',
                          isSelected: selectedTo == _otherKey,
                          onTap: () => setSheetState(() {
                            selectedTo = _otherKey;
                            validationError = null;
                          }),
                        ),
                      ],
                    ),
                    if (selectedTo == _otherKey) ...[
                      const SizedBox(height: 10),
                      TextField(
                        key: const ValueKey('alert_to_custom_input'),
                        controller: customToController,
                        onChanged: (_) {
                          if (validationError != null) {
                            setSheetState(() => validationError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'اكتب مدينة أو منطقة الوصول (مثال: مطار حمد الدولي)'
                              : 'Enter custom destination city or hub (e.g. Hamad Airport)',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.slateBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.navy,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Preferred Time
                    Text(
                      isAr ? 'الموعد المفضل' : 'Preferred Time',
                      style: AppTypography.label(color: AppColors.navy).copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dates.map((d) {
                        return MashwarChip(
                          label: sheetContext.trDate(d),
                          isSelected: dateRange == d,
                          onTap: () => setSheetState(() => dateRange = d),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Alert Category
                    Text(
                      isAr ? 'نوع التنبيه' : 'Alert Type',
                      style: AppTypography.label(color: AppColors.navy).copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: MashwarChip(
                            label: isAr ? 'مقاعد ركاب' : 'Passenger Seats',
                            isSelected: category == 'ركاب',
                            onTap: () => setSheetState(() => category = 'ركاب'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MashwarChip(
                            label: isAr ? 'توصيل طرد' : 'Parcel Delivery',
                            isSelected: category == 'طرد',
                            onTap: () => setSheetState(() => category = 'طرد'),
                          ),
                        ),
                      ],
                    ),

                    if (validationError != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        key: const ValueKey('alert_validation_error'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                validationError!,
                                style: AppTypography.label(color: AppColors.danger)
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    MashwarButton(
                      key: const ValueKey('save_route_alert_btn'),
                      text: isAr ? 'حفظ وتفعيل التنبيه' : 'Save & Activate Alert',
                      onPressed: () {
                        final resolvedFrom = selectedFrom == _otherKey
                            ? customFromController.text.trim()
                            : selectedFrom.trim();
                        final resolvedTo = selectedTo == _otherKey
                            ? customToController.text.trim()
                            : selectedTo.trim();

                        if (resolvedFrom.isEmpty || resolvedTo.isEmpty) {
                          setSheetState(() {
                            validationError = isAr
                                ? 'يرجى كتابة اسم المدينة المخصصة للانطلاق والوصول'
                                : 'Please enter both departure and destination city names';
                          });
                          return;
                        }

                        if (AlertsProvider.areCitiesEquivalent(
                          resolvedFrom,
                          resolvedTo,
                        )) {
                          setSheetState(() {
                            validationError = isAr
                                ? 'يرجى اختيار مدينتين مختلفتين للانطلاق والوصول'
                                : 'Please select two different cities for origin and destination';
                          });
                          return;
                        }

                        final added =
                            parentContext.read<AlertsProvider>().addAlert(
                                  fromCity: resolvedFrom,
                                  toCity: resolvedTo,
                                  dateRange: dateRange,
                                  category: category,
                                );
                        if (!added) return;

                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تم تفعيل تنبيه المسار ($resolvedFrom ← $resolvedTo) بنجاح'
                                  : 'Route alert ($resolvedFrom → $resolvedTo) activated',
                            ),
                            backgroundColor: AppColors.teal,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        customFromController.dispose();
        customToController.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertsProvider = context.watch<AlertsProvider>();
    final ridesProvider = Provider.of<RidesProvider?>(context);
    final alerts = alertsProvider.alerts;
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        title: Text(
          isAr ? 'تنبيهاتي' : 'My Alerts',
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
            constraints: const BoxConstraints(maxWidth: 680),
            child: alerts.isEmpty
                ? _buildEmptyView(context, isAr)
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space16,
                      vertical: AppDimens.space14,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: alerts.length,
                            itemBuilder: (context, index) {
                              final alert = alerts[index];
                              final routeStr = context.trRoute(
                                '${alert.fromCity} ← ${alert.toCity}',
                              );
                              final routeParts =
                                  routeStr.split(RegExp(r'\s*[←→]\s*'));
                              final fromLabel = routeParts.isNotEmpty
                                  ? routeParts.first
                                  : routeStr;
                              final toLabel = routeParts.length > 1
                                  ? routeParts.last
                                  : routeStr;
                              final matchCount = alertsProvider
                                  .countMatchingRides(alert, ridesProvider);
                              final categoryLabel = alert.category == 'ركاب'
                                  ? (isAr ? 'ركاب' : 'Rides')
                                  : (alert.category == 'طرد'
                                      ? (isAr ? 'طرد' : 'Parcel')
                                      : context.tr(alert.category));

                              return MashwarFadeSlideIn(
                                offsetY: 8,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    bottom: AppDimens.space12,
                                  ),
                                  padding: const EdgeInsets.all(AppDimens.space16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.slateBorder),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                MashwarRouteTimeline(
                                                  from: fromLabel,
                                                  to: toLabel,
                                                  compact: true,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${context.trDate(alert.dateRange)} · $categoryLabel',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTypography.bodySecondary(
                                                    color: alert.isExpired
                                                        ? AppColors.textSecondary
                                                        : AppColors.navy,
                                                  ).copyWith(fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Switch.adaptive(
                                            value:
                                                alert.isActive && !alert.isExpired,
                                            activeTrackColor: AppColors.teal,
                                            onChanged: alert.isExpired
                                                ? null
                                                : (_) => alertsProvider
                                                    .toggleAlert(alert.id),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Divider(
                                          height: 1,
                                          color: AppColors.slateBorder,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  alert.isExpired
                                                      ? (isAr
                                                          ? 'منتهي الصلاحية'
                                                          : 'Expired')
                                                      : (alert.isActive
                                                          ? (isAr
                                                              ? 'مفعّل للتنبيه'
                                                              : 'Active')
                                                          : (isAr
                                                              ? 'معطّل مؤقتاً'
                                                              : 'Paused')),
                                                  style: AppTypography.label(
                                                    color: alert.isExpired
                                                        ? AppColors.textSecondary
                                                        : (alert.isActive
                                                            ? AppColors.teal
                                                            : AppColors
                                                                .textSecondary),
                                                  ).copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                if (!alert.isExpired)
                                                  InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    onTap: matchCount > 0 &&
                                                            ridesProvider != null
                                                        ? () {
                                                            ridesProvider
                                                                .searchCorridor(
                                                              from: alert.fromCity,
                                                              to: alert.toCity,
                                                            );
                                                            Navigator.of(context)
                                                                .push(
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    const SearchResultsScreen(),
                                                              ),
                                                            );
                                                          }
                                                        : null,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3.5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: matchCount > 0
                                                            ? AppColors.tealSurface
                                                            : AppColors.slateBg,
                                                        borderRadius:
                                                            BorderRadius.circular(8),
                                                        border: Border.all(
                                                          color: matchCount > 0
                                                              ? AppColors.teal
                                                                  .withValues(
                                                                      alpha: 0.3)
                                                              : AppColors
                                                                  .slateBorder,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        matchCount > 0
                                                            ? (isAr
                                                                ? '$matchCount رحلات مطابقة الآن'
                                                                : '$matchCount matching trips')
                                                            : (isAr
                                                                ? 'بانتظار رحلة مطابقة'
                                                                : 'Watching route'),
                                                        style: AppTypography.label(
                                                          color: matchCount > 0
                                                              ? AppColors.teal
                                                              : AppColors
                                                                  .textSecondary,
                                                        ).copyWith(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            key: ValueKey(
                                              'alert_delete_${alert.id}',
                                            ),
                                            visualDensity: VisualDensity.compact,
                                            tooltip: isAr ? 'حذف' : 'Delete',
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: AppColors.danger,
                                              size: 20,
                                            ),
                                            onPressed: () => alertsProvider
                                                .deleteAlert(alert.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        MashwarButton(
                          key: const ValueKey('open_create_alert_btn'),
                          text: isAr
                              ? '+ إضافة تنبيه لمسار جديد'
                              : '+ Add New Route Alert',
                          onPressed: () => _showAddAlertSheet(context, isAr),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: MashwarFadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.space24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.slateBorder),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 40,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'لا توجد تنبيهات مسجلة' : 'No Active Alerts',
                  style: AppTypography.title(),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'عند البحث عن رحلة وعدم توفرها حالياً، يمكنك إنشاء تنبيه وسنبلّغك فور إضافتها'
                      : 'Create a route alert and we will notify you as soon as a matching trip is posted',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary(),
                ),
                const SizedBox(height: 20),
                MashwarButton(
                  key: const ValueKey('open_create_alert_btn'),
                  text: isAr
                      ? '+ إضافة تنبيه لمسار جديد'
                      : '+ Add New Route Alert',
                  onPressed: () => _showAddAlertSheet(context, isAr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
