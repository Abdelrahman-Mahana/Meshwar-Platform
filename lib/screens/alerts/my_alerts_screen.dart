import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/widgets/mashwar_chip.dart';
import '../../core/localization/app_strings.dart';
import '../../state/alerts_provider.dart';

class MyAlertsScreen extends StatelessWidget {
  const MyAlertsScreen({super.key});

  void _showAddAlertSheet(BuildContext context, bool isAr) {
    String fromCity = 'الدوحة';
    String toCity = 'الخور';
    String dateRange = 'الأحد القادم · صباحاً';
    String category = 'ركاب';

    final cities = ['الدوحة', 'الريان', 'الوكرة', 'الخور', 'لوسيل', 'دخان', 'مسيعيد', 'أم صلال'];
    final dates = ['غداً · صباحاً', 'الجمعة القادمة', 'الأحد القادم · صباحاً', 'طوال الأسبوع'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusBottomSheet)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppDimens.space24,
                  right: AppDimens.space24,
                  top: AppDimens.space24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.space24,
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
                  leadingIcon: Icons.notifications_active_rounded,
                ),
                const SizedBox(height: 12),

                Text(isAr ? 'من مدينة' : 'From City', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cities.map((c) {
                    return MashwarChip(
                      label: context.trCity(c),
                      isSelected: fromCity == c,
                      onTap: () => setSheetState(() => fromCity = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                Text(isAr ? 'إلى مدينة' : 'To City', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cities.map((c) {
                    return MashwarChip(
                      label: context.trCity(c),
                      isSelected: toCity == c,
                      onTap: () => setSheetState(() => toCity = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                Text(isAr ? 'الموعد المفضل' : 'Preferred Time', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dates.map((d) {
                    return MashwarChip(
                      label: d,
                      isSelected: dateRange == d,
                      onTap: () => setSheetState(() => dateRange = d),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                Text(isAr ? 'نوع التنبيه' : 'Alert Type', style: AppTypography.label().copyWith(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 20),

                MashwarButton(
                  text: isAr ? 'حفظ وتفعيل التنبيه' : 'Save & Activate Alert',
                  onPressed: () {
                    if (fromCity == toCity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isAr ? 'يرجى اختيار مدينتين مختلفتين' : 'Please select two different cities'),
                          backgroundColor: AppColors.coral,
                        ),
                      );
                      return;
                    }
                    context.read<AlertsProvider>().addAlert(
                          fromCity: fromCity,
                          toCity: toCity,
                          dateRange: dateRange,
                          category: category,
                        );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'تم تفعيل تنبيه المسار بنجاح' : 'Route alert created and activated'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsProvider = context.watch<AlertsProvider>();
    final alerts = alertsProvider.alerts;
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(isAr ? 'تنبيهاتي' : 'My Alerts', style: AppTypography.title()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
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
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space12),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: alerts.length,
                            itemBuilder: (context, index) {
                              final alert = alerts[index];
                              final routeStr = context.trRoute('${alert.fromCity} ← ${alert.toCity}');
                              final routeParts = routeStr.split(RegExp(r'\s*[←→]\s*'));
                              final fromLabel = routeParts.isNotEmpty ? routeParts.first : routeStr;
                              final toLabel = routeParts.length > 1 ? routeParts.last : routeStr;
                              return MashwarFadeSlideIn(
                                offsetY: 10,
                                child: MashwarSectionCard(
                                  margin: const EdgeInsets.only(bottom: AppDimens.space12),
                                  padding: const EdgeInsets.all(AppDimens.space16),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                MashwarRouteTimeline(
                                                  from: fromLabel,
                                                  to: toLabel,
                                                  compact: true,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${context.trDate(alert.dateRange)} · ${alert.category == "ركاب" ? (isAr ? "ركاب" : "Rides") : (alert.category == "طرد" ? (isAr ? "طرد" : "Parcel") : context.tr(alert.category))}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTypography.bodySecondary(
                                                    color: alert.isExpired ? AppColors.textSecondary : AppColors.navy,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Switch.adaptive(
                                            value: alert.isActive && !alert.isExpired,
                                            activeTrackColor: AppColors.teal,
                                            onChanged: alert.isExpired
                                                ? null
                                                : (_) => alertsProvider.toggleAlert(alert.id),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            alert.isExpired
                                                ? (isAr ? 'منتهي الصلاحية' : 'Expired')
                                                : (alert.isActive ? (isAr ? 'مفعّل للتنبيه' : 'Active') : (isAr ? 'معطّل مؤقتاً' : 'Paused')),
                                            style: AppTypography.label(
                                              color: alert.isExpired
                                                  ? AppColors.textSecondary
                                                  : (alert.isActive ? AppColors.teal : AppColors.textSecondary),
                                            ).copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                            onPressed: () => alertsProvider.deleteAlert(alert.id),
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
                        MashwarButton(
                          text: isAr ? '+ إضافة تنبيه لمسار جديد' : '+ Add New Route Alert',
                          onPressed: () => _showAddAlertSheet(context, isAr),
                        ),
                        const SizedBox(height: 16),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 52, color: AppColors.navy),
              ),
              const SizedBox(height: 16),
              Text(isAr ? 'لا توجد تنبيهات مسجلة' : 'No Active Alerts', style: AppTypography.title()),
              const SizedBox(height: 8),
              Text(
                isAr ? 'عند البحث عن رحلة وعدم توفرها حالياً، يمكنك إنشاء تنبيه وسنبلّغك فور إضافتها' : 'When you search for a ride with no matches, create an alert and we will notify you',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary(),
              ),
              const SizedBox(height: 24),
              MashwarButton(
                text: isAr ? '+ إضافة تنبيه لمسار جديد' : '+ Add New Route Alert',
                onPressed: () => _showAddAlertSheet(context, isAr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

