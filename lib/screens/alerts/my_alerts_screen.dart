import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../core/localization/app_strings.dart';
import '../../state/alerts_provider.dart';

class MyAlertsScreen extends StatelessWidget {
  const MyAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertsProvider = context.watch<AlertsProvider>();
    final alerts = alertsProvider.alerts;
    final isAr = context.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
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
        child: alerts.isEmpty
            ? _buildEmptyView(context, isAr)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppDimens.space12),
                            padding: const EdgeInsets.all(AppDimens.space16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.trRoute('${alert.fromCity} ← ${alert.toCity}'),
                                          style: AppTypography.title().copyWith(fontSize: 18),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${context.trDate(alert.dateRange)} · ${context.tr(alert.category)}',
                                          style: AppTypography.bodySecondary(
                                            color: alert.isExpired ? AppColors.textSecondary : AppColors.navy,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: alert.isActive && !alert.isExpired,
                                      activeThumbColor: AppColors.teal,
                                      onChanged: alert.isExpired
                                          ? null
                                          : (_) => alertsProvider.toggleAlert(alert.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                      onPressed: () => alertsProvider.deleteAlert(alert.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    MashwarButton(
                      text: isAr ? '+ إضافة تنبيه لمسار جديد' : '+ Add New Route Alert',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.borderDisabled),
            const SizedBox(height: 16),
            Text(isAr ? 'مفيش تنبيهات مسجلة' : 'No Active Alerts', style: AppTypography.title()),
            const SizedBox(height: 8),
            Text(
              isAr ? 'لما تبحث عن رحلة ومش تلاقي، تقدر تعمل تنبيه وهنبلغك فور توفرها' : 'When you search for a ride with no matches, create an alert and we will notify you',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary(),
            ),
            const SizedBox(height: 24),
            MashwarButton(
              text: isAr ? 'ابحث عن رحلة' : 'Search for a ride',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
