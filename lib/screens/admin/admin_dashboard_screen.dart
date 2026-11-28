import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_embedded_google_map.dart';
import '../../core/widgets/mashwar_google_map_panel.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import '../../data/services/google_maps_service.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onJumpToModule;

  const AdminDashboardScreen({super.key, this.onJumpToModule});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _useLiveUberMap = true;
  bool _showTraffic = true;
  MashwarMapVehicleMode _previewMode = MashwarMapVehicleMode.supply;

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final openDisputesCount = admin.disputes.where((d) => d.status == 'مفتوح').length;
    final pendingDriversCount = admin.driverRequests.where((r) => r.status == 'قيد المراجعة').length;
    final pendingWorksiteKyc = admin.pendingVerificationsCount;
    final pendingProofsCount = admin.pendingPaymentProofsCount;
    final newInquiriesCount = admin.newInquiriesCount;
    final worksiteTotal = admin.worksiteRequests.length;

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Executive Live Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2A43), Color(0xFF155E63)],
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
                            ? 'متابعة عمليات مشوار اليومية · 3 خدمات رئيسية · $worksiteTotal طلب توريد · ${admin.corridors.length} محور نشط'
                            : 'MASHWAR Daily Operations · 3 Core Pillars · $worksiteTotal Supply Orders · ${admin.corridors.length} Corridors',
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
                      isAr ? 'الفترة: ${admin.currentPeriod}' : 'Period: ${admin.currentPeriod}',
                      AppColors.gold,
                    ),
                    _bannerTag(
                      'ENV: ${admin.activeEnvironment.toUpperCase()}',
                      const Color(0xFF5EEAD4),
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
                      title: isAr ? 'طلبات التوريد الميداني' : 'Worksite Supply Orders',
                      value: '$worksiteTotal',
                      deltaText: isAr
                          ? '$pendingWorksiteKyc توثيق مزود · $pendingProofsCount تحويل'
                          : '$pendingWorksiteKyc KYC · $pendingProofsCount transfers',
                      accentColor: t.accentTeal,
                      icon: Icons.engineering_rounded,
                      onTap: () => widget.onJumpToModule?.call(13),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AdminKpiCard(
                      title: isAr ? 'الرحلات المنشورة' : 'Published Rides',
                      value: '${admin.kpiPublishedRides}',
                      deltaText: admin.kpiPublishedRidesSubtext,
                      accentColor: t.accentPrimary,
                      icon: Icons.directions_car_filled_rounded,
                      onTap: () => widget.onJumpToModule?.call(3),
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
                      onTap: () => widget.onJumpToModule?.call(3),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AdminKpiCard(
                      title: isAr ? 'طرود مسلّمة بـ OTP' : 'OTP Delivered Parcels',
                      value: '${admin.kpiDeliveredParcels}',
                      deltaText: admin.kpiParcelSuccessRate,
                      accentColor: t.accentTeal,
                      icon: Icons.inventory_2_rounded,
                      onTap: () => widget.onJumpToModule?.call(3),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AdminKpiCard(
                      title: isAr ? 'بلاغات واستفسارات' : 'Disputes & Inquiries',
                      value: '${openDisputesCount + newInquiriesCount}',
                      deltaText: isAr
                          ? '$openDisputesCount نزاع · $newInquiriesCount رسالة موقع'
                          : '$openDisputesCount disputes · $newInquiriesCount inquiries',
                      accentColor: AppColors.coral,
                      icon: Icons.mark_chat_unread_rounded,
                      onTap: () => widget.onJumpToModule?.call(openDisputesCount > 0 ? 4 : 12),
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
                  isAr ? 'مهام تحتاج مراجعتك الآن:' : 'Needs Your Review:',
                  style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quickActionBtn(
                      icon: Icons.engineering_rounded,
                      label: isAr
                          ? 'التوريد الميداني ($pendingWorksiteKyc)'
                          : 'Worksite Ops ($pendingWorksiteKyc)',
                      color: AppColors.teal,
                      onTap: () => widget.onJumpToModule?.call(13),
                    ),
                    _quickActionBtn(
                      icon: Icons.mark_email_unread_rounded,
                      label: isAr ? 'رسائل الموقع ($newInquiriesCount)' : 'Inquiries ($newInquiriesCount)',
                      color: AppColors.navy,
                      onTap: () => widget.onJumpToModule?.call(12),
                    ),
                    _quickActionBtn(
                      icon: Icons.verified_user_rounded,
                      label: isAr ? 'السائقون ($pendingDriversCount)' : 'Drivers ($pendingDriversCount)',
                      color: const Color(0xFFD97706),
                      onTap: () => widget.onJumpToModule?.call(1),
                    ),
                    _quickActionBtn(
                      icon: Icons.map_rounded,
                      label: isAr ? 'المحاور الحية' : 'Live Corridors',
                      color: const Color(0xFF0369A1),
                      onTap: () => widget.onJumpToModule?.call(9),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GMV Telemetry Chart + Live Uber Corridor Map
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
                            isAr ? 'حركة الطلبات والتسويات الأسبوعية (ر.ق)' : 'Weekly Order Volume & Settlements (QAR)',
                            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        Text(
                          '${admin.kpiNetPlatformCommissionQar.toStringAsFixed(1)} ${isAr ? "ر.ق صافي" : "QAR Net"}',
                          style: TextStyle(color: t.accentTeal, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AdminTelemetryLineChart(
                      primarySeries: const [1850, 2240, 2680, 2510, 3190, 3840, 4420],
                      secondarySeries: const [1200, 1480, 1790, 1720, 2140, 2610, 3050],
                      labels: const ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Today'],
                      primaryColor: t.isDark ? AppColors.gold : AppColors.navy,
                      secondaryColor: AppColors.teal,
                    ),
                  ],
                ),
              );

              final mapCard = AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          isAr ? 'خريطة حركة المحاور الحية (قطر)' : 'Live Qatar Corridor Traffic Map',
                          style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: () => setState(() => _useLiveUberMap = !_useLiveUberMap),
                              icon: Icon(
                                _useLiveUberMap ? Icons.hub_rounded : Icons.map_rounded,
                                size: 15,
                              ),
                              label: Text(
                                _useLiveUberMap
                                    ? (isAr ? 'مخطط' : 'Schematic')
                                    : (isAr ? 'خريطة حية' : 'Live Map'),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () => widget.onJumpToModule?.call(9),
                              child: Text(
                                isAr ? 'كل المحاور' : 'Corridors',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_useLiveUberMap) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: Text(
                              isAr ? 'شاحنة توريد' : 'Supply',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _previewMode == MashwarMapVehicleMode.supply
                                    ? Colors.white
                                    : t.textPrimary,
                              ),
                            ),
                            selectedColor: AppColors.navy,
                            checkmarkColor: Colors.white,
                            selected: _previewMode == MashwarMapVehicleMode.supply,
                            onSelected: (_) => setState(() => _previewMode = MashwarMapVehicleMode.supply),
                          ),
                          ChoiceChip(
                            label: Text(
                              isAr ? 'رحلة سيارة' : 'Trip Car',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _previewMode == MashwarMapVehicleMode.trip
                                    ? Colors.white
                                    : t.textPrimary,
                              ),
                            ),
                            selectedColor: AppColors.navy,
                            checkmarkColor: Colors.white,
                            selected: _previewMode == MashwarMapVehicleMode.trip,
                            onSelected: (_) => setState(() => _previewMode = MashwarMapVehicleMode.trip),
                          ),
                          FilterChip(
                            label: Text(
                              isAr ? 'الزحمة الحية' : 'Traffic',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _showTraffic ? Colors.white : t.textPrimary,
                              ),
                            ),
                            selectedColor: AppColors.teal,
                            checkmarkColor: Colors.white,
                            selected: _showTraffic,
                            onSelected: (v) => setState(() => _showTraffic = v),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.open_in_full_rounded, size: 13),
                            label: Text(isAr ? 'تكبير' : 'Expand', style: const TextStyle(fontSize: 11)),
                            onPressed: () => openMashwarInAppMap(
                              context,
                              titleAr: 'محور المنطقة الصناعية — لوسيل',
                              titleEn: 'Industrial Area — Lusail',
                              origin: 'المنطقة الصناعية',
                              destination: 'لوسيل',
                              vehicleMode: _previewMode,
                              showTraffic: _showTraffic,
                              stylePreset: t.isDark ? MashwarMapStylePreset.dark : MashwarMapStylePreset.google,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _useLiveUberMap
                            ? MashwarEmbeddedGoogleMap(
                                key: ValueKey('admin_dash_map_${_previewMode.name}_$_showTraffic'),
                                origin: 'المنطقة الصناعية',
                                destination: 'لوسيل',
                                vehicleMode: _previewMode,
                                showTraffic: _showTraffic,
                                stylePreset: t.isDark
                                    ? MashwarMapStylePreset.dark
                                    : MashwarMapStylePreset.google,
                                height: 220,
                                borderRadius: 12,
                              )
                            : QatarLiveMapCanvas(
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
