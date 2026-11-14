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
          // Operational Banner / Ticker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2942), Color(0xFF1E3A58)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (MediaQuery.of(context).size.width - 64).clamp(180.0, 700.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isAr
                              ? 'شبكة السفر بين المحافظات تعمل بكامل كفاءتها عبر 27 محافظة'
                              : 'Intercity carpooling network fully operational across 27 governorates',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    isAr ? 'الفترة المحددة: ${admin.currentPeriod}' : 'Active Scope: ${admin.currentPeriod}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 5 Metric KPI Cards (Page 69 - Fully Responsive Breakpoints)
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              double cardWidth;
              if (w >= 1180) {
                cardWidth = (w - (16 * 4)) / 5;
              } else if (w >= 720) {
                cardWidth = (w - (16 * 2)) / 3;
              } else if (w >= 480) {
                cardWidth = (w - 16) / 2;
              } else {
                cardWidth = w;
              }

              final openDisputesCount = admin.disputes.where((d) => d.status == 'مفتوح').length;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard(
                    title: isAr ? 'مستخدمون جدد' : 'New Users',
                    value: '${admin.kpiNewUsers}',
                    subtext: admin.kpiNewUsersSubtext,
                    subtextColor: AppColors.teal,
                    icon: Icons.group_add_rounded,
                    iconBg: const Color(0xFFE6F7F0),
                    iconColor: AppColors.teal,
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: isAr ? 'رحلات منشورة' : 'Published Rides',
                    value: '${admin.kpiPublishedRides}',
                    subtext: admin.kpiPublishedRidesSubtext,
                    subtextColor: AppColors.teal,
                    icon: Icons.directions_car_filled_rounded,
                    iconBg: const Color(0xFFE8F1FA),
                    iconColor: AppColors.navy,
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: isAr ? 'حجوزات مؤكدة' : 'Confirmed Bookings',
                    value: '${admin.kpiConfirmedBookings}',
                    subtext: admin.kpiConversionRate,
                    subtextColor: AppColors.navy,
                    icon: Icons.confirmation_number_rounded,
                    iconBg: const Color(0xFFFFF8E1),
                    iconColor: const Color(0xFFD97706),
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: isAr ? 'طرود مسلّمة' : 'Delivered Parcels',
                    value: '${admin.kpiDeliveredParcels}',
                    subtext: admin.kpiParcelSuccessRate,
                    subtextColor: AppColors.teal,
                    icon: Icons.inventory_2_rounded,
                    iconBg: const Color(0xFFE6F7F0),
                    iconColor: AppColors.teal,
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: isAr ? 'بلاغات مفتوحة' : 'Open Disputes',
                    value: '$openDisputesCount',
                    subtext: isAr ? 'تحتاج مراجعة' : 'Requires action',
                    subtextColor: AppColors.coral,
                    valueColor: AppColors.coral,
                    icon: Icons.warning_amber_rounded,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: AppColors.coral,
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
              final isStacked = constraints.maxWidth < 920;
              if (isStacked) {
                return Column(
                  children: [
                    _buildGovernorateChart(context, isAr),
                    const SizedBox(height: 18),
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
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 6,
                    child: _buildCorridorsTable(context, isAr),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppDimens.space20),

          // Platform Health & Ops Indicator Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.teal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr
                        ? 'الأرقام تجريبية لتوضيح الشكل ومحاكاة عمليات التشغيل · نظام أمان وتشفير البيانات فعال'
                        : 'Sample metric numbers illustrating live operations · Real-time data encryption active',
                    style: AppTypography.label(color: AppColors.textSecondary).copyWith(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.label(color: AppColors.textSecondary).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.largeTitle().copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: valueColor ?? AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: subtextColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subtext,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: subtextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGovernorateChart(BuildContext context, bool isAr) {
    final data = [
      {'name': isAr ? 'القاهرة' : 'Cairo', 'val': 120, 'pct': '31%'},
      {'name': isAr ? 'الإسكندرية' : 'Alexandria', 'val': 95, 'pct': '25%'},
      {'name': isAr ? 'الغربية' : 'Gharbia', 'val': 70, 'pct': '18%'},
      {'name': isAr ? 'الدقهلية' : 'Dakahlia', 'val': 55, 'pct': '14%'},
      {'name': isAr ? 'كفر الشيخ' : 'Kafr El-Sheikh', 'val': 45, 'pct': '12%'},
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isAr ? 'رحلات حسب المحافظة' : 'Rides by Governorate',
                  style: AppTypography.title().copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAr ? 'أعلى 5 محافظات' : 'Top 5 Regions',
                  style: const TextStyle(fontSize: 11, color: AppColors.navy, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space24),
          SizedBox(
            height: 190,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 320),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((item) {
                    final heightPct = (item['val'] as int) / 120.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${item['val']}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.navy),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['pct'] as String,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 36,
                            height: 110 * heightPct,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.navy, Color(0xFF1E3A58)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item['name']}',
                            style: AppTypography.label(color: AppColors.textSecondary).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
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
        'status': isAr ? 'ذروة' : 'Peak',
      },
      {
        'corridor': isAr ? 'القاهرة ↔ طنطا' : 'Cairo ↔ Tanta',
        'rides': 61,
        'bookings': 40,
        'rate': '39%',
        'status': isAr ? 'مستقر' : 'Stable',
      },
      {
        'corridor': isAr ? 'القاهرة ↔ كفر الشيخ' : 'Cairo ↔ Kafr El-Sheikh',
        'rides': 38,
        'bookings': 22,
        'rate': '36%',
        'status': isAr ? 'نشط' : 'Active',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isAr ? 'أداء محاور السفر الرئيسية' : 'Key Corridor Performance',
                  style: AppTypography.title().copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAr ? 'طرق حية' : 'Live Routes',
                  style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 420),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.6),
                  1: FlexColumnWidth(1.0),
                  2: FlexColumnWidth(1.0),
                  3: FlexColumnWidth(1.2),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: const TableBorder(horizontalInside: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          isAr ? 'المحور' : 'Corridor',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          isAr ? 'رحلات' : 'Rides',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          isAr ? 'حجوزات' : 'Bookings',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          isAr ? 'تحويل' : 'Conversion',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                        ),
                      ),
                    ],
                  ),
                  for (final r in rows) ...[
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          child: Text(
                            r['corridor'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('${r['rides']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('${r['bookings']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.tealSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              r['rate'] as String,
                              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
