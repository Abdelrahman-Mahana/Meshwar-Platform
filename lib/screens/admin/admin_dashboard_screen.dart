import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../state/settings_provider.dart';
import '../../state/admin_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 5 Metric KPI Cards (Page 69 - Fully Responsive Breakpoints)
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              double cardWidth;
              if (w >= 1100) {
                cardWidth = (w - (16 * 4)) / 5;
              } else if (w >= 680) {
                cardWidth = (w - (16 * 2)) / 3;
              } else if (w >= 450) {
                cardWidth = (w - 16) / 2;
              } else {
                cardWidth = w;
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard(
                    title: isAr ? 'مستخدمون جدد' : 'New Users',
                    value: '${admin.kpiNewUsers}',
                    subtext: admin.kpiNewUsersSubtext,
                    subtextColor: AppColors.teal,
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: isAr ? 'رحلات منشورة' : 'Published Rides',
                    value: '${admin.kpiPublishedRides}',
                    subtext: admin.kpiPublishedRidesSubtext,
                    subtextColor: AppColors.teal,
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: isAr ? 'حجوزات مؤكدة' : 'Confirmed Bookings',
                    value: '${admin.kpiConfirmedBookings}',
                    subtext: admin.kpiConversionRate,
                    subtextColor: AppColors.navy,
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: isAr ? 'طرود مسلّمة' : 'Delivered Parcels',
                    value: '${admin.kpiDeliveredParcels}',
                    subtext: admin.kpiParcelSuccessRate,
                    subtextColor: AppColors.teal,
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: isAr ? 'بلاغات مفتوحة' : 'Open Disputes',
                    value: '${admin.disputes.where((d) => d.status == 'مفتوح').length}',
                    subtext: isAr ? 'تحتاج مراجعة' : 'Requires action',
                    subtextColor: AppColors.coral,
                    valueColor: AppColors.coral,
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppDimens.space24),

          // Charts & Corridors Row (Page 69)
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 850;
              if (isStacked) {
                return Column(
                  children: [
                    _buildGovernorateChart(context, isAr),
                    const SizedBox(height: 16),
                    _buildCorridorsTable(context, isAr),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildGovernorateChart(context, isAr),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: _buildCorridorsTable(context, isAr),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppDimens.space16),
          Center(
            child: Text(
              isAr ? 'الأرقام تجريبية لتوضيح الشكل ومحاكاة عمليات التشغيل.' : 'Sample metric numbers illustrating live operations.',
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required Color subtextColor,
    Color? valueColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.label(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.largeTitle().copyWith(
              fontSize: 26,
              color: valueColor ?? AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGovernorateChart(BuildContext context, bool isAr) {
    final data = [
      {'name': isAr ? 'القاهرة' : 'Cairo', 'val': 120},
      {'name': isAr ? 'الإسكندرية' : 'Alexandria', 'val': 95},
      {'name': isAr ? 'الغربية' : 'Gharbia', 'val': 70},
      {'name': isAr ? 'الدقهلية' : 'Dakahlia', 'val': 55},
      {'name': isAr ? 'كفر الشيخ' : 'Kafr El-Sheikh', 'val': 45},
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'رحلات حسب المحافظة' : 'Rides by Governorate',
            style: AppTypography.title().copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppDimens.space24),
          SizedBox(
            height: 180,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 280),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((item) {
                    final heightPct = (item['val'] as int) / 120.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${item['val']}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: 120 * heightPct,
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item['name']}',
                            style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorsTable(BuildContext context, bool isAr) {
    final rows = [
      {
        'corridor': isAr ? 'القاهرة ↔ الإسكندرية' : 'Cairo ↔ Alexandria',
        'rides': 94,
        'bookings': 71,
        'rate': '48%',
      },
      {
        'corridor': isAr ? 'القاهرة ↔ طنطا' : 'Cairo ↔ Tanta',
        'rides': 61,
        'bookings': 40,
        'rate': '39%',
      },
      {
        'corridor': isAr ? 'القاهرة ↔ كفر الشيخ' : 'Cairo ↔ Kafr El-Sheikh',
        'rides': 38,
        'bookings': 22,
        'rate': '36%',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'أداء محاور السفر الرئيسية' : 'Key Corridor Performance',
            style: AppTypography.title().copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppDimens.space16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.6),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.2),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(horizontalInside: BorderSide(color: AppColors.sand, width: 1.5)),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.sand),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(isAr ? 'المحور' : 'Corridor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(isAr ? 'رحلات' : 'Rides', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(isAr ? 'حجوزات' : 'Bookings', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(isAr ? 'تحويل' : 'Conversion', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              for (final r in rows) ...[
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      child: Text(r['corridor'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text('${r['rides']}', style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text('${r['bookings']}', style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          r['rate'] as String,
                          style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
