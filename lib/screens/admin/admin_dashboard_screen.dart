import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminDashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onJumpToModule;

  const AdminDashboardScreen({super.key, this.onJumpToModule});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final openDisputesCount = admin.disputes.where((d) => d.status == 'مفتوح').length;
    final pendingDriversCount = admin.driverRequests.where((r) => r.status == 'قيد المراجعة').length;
    final enabledFlags = admin.featureFlags.where((f) => f.isEnabled && !f.isKillSwitch).length;

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Executive Live Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2A43), Color(0xFF8A1538)],
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MashwarLivePulseDot(color: Color(0xFF10B981), size: 9),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        isAr
                            ? 'مركز عمليات مشوار قطر · ${admin.servicesCatalog.where((s) => s.isEnabled).length} خدمات · ${admin.corridors.length} محور حي · $enabledFlags Feature Flags'
                            : 'MASHWAR Qatar Command · ${admin.servicesCatalog.where((s) => s.isEnabled).length} Services · ${admin.corridors.length} Corridors · $enabledFlags Flags',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _bannerTag(
                      isAr ? 'النطاق: ${admin.currentPeriod}' : 'Scope: ${admin.currentPeriod}',
                      AppColors.gold,
                    ),
                    _bannerTag(
                      'ENV: ${admin.activeEnvironment.toUpperCase()}',
                      const Color(0xFF2DD4BF),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary 5 Operational KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 1220 ? 5 : (w >= 760 ? 3 : (w >= 480 ? 2 : 1));
              final cardWidth = (w - (14 * (cols - 1))) / cols;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: AdminKpiCard(
                      title: isAr ? 'مستخدمون جدد' : 'New Users',
                      value: '${admin.kpiNewUsers}',
                      deltaText: admin.kpiNewUsersSubtext,
                      accentColor: t.accentTeal,
                      icon: Icons.group_add_rounded,
                      onTap: () => onJumpToModule?.call(2),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AdminKpiCard(
                      title: isAr ? 'رحلات منشورة' : 'Published Rides',
                      value: '${admin.kpiPublishedRides}',
                      deltaText: admin.kpiPublishedRidesSubtext,
                      accentColor: t.accentPrimary,
                      icon: Icons.directions_car_filled_rounded,
                      onTap: () => onJumpToModule?.call(3),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AdminKpiCard(
                      title: isAr ? 'حجوزات مؤكدة' : 'Confirmed Bookings',
                      value: '${admin.kpiConfirmedBookings}',
                      deltaText: admin.kpiConversionRate,
                      accentColor: AppColors.gold,
                      icon: Icons.confirmation_number_rounded,
                      onTap: () => onJumpToModule?.call(3),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AdminKpiCard(
                      title: isAr ? 'طرود مسلّمة' : 'Delivered Parcels',
                      value: '${admin.kpiDeliveredParcels}',
                      deltaText: admin.kpiParcelSuccessRate,
                      accentColor: t.accentTeal,
                      icon: Icons.inventory_2_rounded,
                      onTap: () => onJumpToModule?.call(3),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AdminKpiCard(
                      title: isAr ? 'بلاغات مفتوحة' : 'Open Disputes',
                      value: '$openDisputesCount',
                      deltaText: isAr ? 'تحتاج مراجعة فورية' : 'Requires action',
                      accentColor: AppColors.coral,
                      icon: Icons.warning_amber_rounded,
                      onTap: () => onJumpToModule?.call(4),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Quick-Action Command Strip (1-Click Jump to Urgent Ops)
          AdminSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  isAr ? 'وصول تنفيذي سريع:' : 'Quick Operational Actions:',
                  style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quickActionBtn(
                      icon: Icons.verified_user_rounded,
                      label: isAr ? 'مراجعة السائقين ($pendingDriversCount)' : 'Verify Drivers ($pendingDriversCount)',
                      color: AppColors.gold,
                      onTap: () => onJumpToModule?.call(1),
                    ),
                    _quickActionBtn(
                      icon: Icons.account_balance_wallet_rounded,
                      label: isAr
                          ? 'الضمان المالي (${admin.kpiActiveEscrowHoldQar.toStringAsFixed(0)} ر.ق)'
                          : 'Escrow Holds (${admin.kpiActiveEscrowHoldQar.toStringAsFixed(0)} QAR)',
                      color: AppColors.qatarMaroon,
                      onTap: () => onJumpToModule?.call(10),
                    ),
                    _quickActionBtn(
                      icon: Icons.grid_view_rounded,
                      label: isAr ? 'إدارة الخدمات (${admin.servicesCatalog.length})' : 'Services (${admin.servicesCatalog.length})',
                      color: AppColors.teal,
                      onTap: () => onJumpToModule?.call(8),
                    ),
                    _quickActionBtn(
                      icon: Icons.terminal_rounded,
                      label: isAr ? 'غرفة DevOps والـ Flags' : 'DevOps & SRE',
                      color: const Color(0xFF4338CA),
                      onTap: () => onJumpToModule?.call(11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GMV Telemetry Chart + Live Qatar Corridor Map
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 960;
              final telemetryCard = AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isAr ? 'مؤشر حجم المعاملات والضمان المالي (ر.ق)' : 'GMV & Bilateral Escrow Flow (QAR)',
                            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        Text(
                          '${admin.kpiNetPlatformCommissionQar.toStringAsFixed(1)} ${isAr ? "ر.ق عمولة" : "QAR Take"}',
                          style: TextStyle(color: t.accentTeal, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const AdminTelemetryLineChart(
                      primarySeries: [1850, 2240, 2680, 2510, 3190, 3840, 4420],
                      secondarySeries: [1200, 1480, 1790, 1720, 2140, 2610, 3050],
                      labels: ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Today'],
                      primaryColor: AppColors.qatarMaroon,
                      secondaryColor: AppColors.teal,
                    ),
                  ],
                ),
              );

              final mapCard = AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isAr ? 'شبكة المحاور والبلديات القطرية الحية' : 'Live Qatar Corridor Network',
                            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        TextButton(
                          onPressed: () => onJumpToModule?.call(9),
                          child: Text(isAr ? 'إدارة المحاور' : 'Manage'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 196,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: QatarLiveMapCanvas(
                          style: t.isDark ? QatarMapStyle.darkExecutive : QatarMapStyle.light,
                          activeFromCity: 'المنطقة الصناعية',
                          activeToCity: 'لوسيل',
                          showHubLabels: true,
                          showCarTrails: true,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isStacked) {
                return Column(
                  children: [
                    telemetryCard,
                    const SizedBox(height: 16),
                    mapCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: telemetryCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: mapCard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Service Mix Breakdown + Live Corridor Performance Table
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 960;
              final serviceMixCard = AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'توزيع الطلبات حسب خطوط الخدمة' : 'Order Volume Across Service Lines',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    for (final svc in admin.servicesCatalog) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    isAr ? svc.nameAr : svc.nameEn,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: t.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  '${svc.activeOrdersCount} (${svc.commissionPct.toStringAsFixed(0)}%)',
                                  style: TextStyle(color: t.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (svc.activeOrdersCount / 100.0).clamp(0.08, 1.0),
                                minHeight: 7,
                                backgroundColor: t.surfaceMuted,
                                valueColor: AlwaysStoppedAnimation(Color(svc.accentHex)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );

              final corridorsCard = AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'أداء محاور السفر والإمداد الرئيسية' : 'Key Corridor Performance',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    AdminAdaptiveDataView(
                      items: admin.corridors.take(4).toList(),
                      minTableWidth: 460,
                      columns: [
                        DataColumn(label: Text(isAr ? 'المحور' : 'Corridor')),
                        DataColumn(label: Text(isAr ? 'الطلبات' : 'Requests')),
                        DataColumn(label: Text(isAr ? 'التحويل' : 'Conv.')),
                        DataColumn(label: Text(isAr ? 'التحفيز' : 'Boost')),
                      ],
                      buildRow: (c) => DataRow(
                        cells: [
                          DataCell(Text(c.routeLabel(isAr), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                          DataCell(Text('${c.openRequests}')),
                          DataCell(Text('${c.conversionPct.toStringAsFixed(0)}%', style: TextStyle(color: t.accentTeal, fontWeight: FontWeight.bold))),
                          DataCell(Text('${c.incentiveMultiplier.toStringAsFixed(2)}x', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      buildMobileCard: (ctx, c) => Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: t.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: t.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(c.routeLabel(isAr), style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                            Text('${c.conversionPct.toStringAsFixed(0)}% · ${c.incentiveMultiplier.toStringAsFixed(2)}x', style: TextStyle(color: t.accentTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isStacked) {
                return Column(
                  children: [
                    serviceMixCard,
                    const SizedBox(height: 16),
                    corridorsCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: serviceMixCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: corridorsCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bannerTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }

  Widget _quickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 15, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
      onPressed: onTap,
    );
  }
}
