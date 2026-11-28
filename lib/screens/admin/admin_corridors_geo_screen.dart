import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/mashwar_embedded_google_map.dart';
import '../../core/widgets/mashwar_google_map_panel.dart';
import '../../core/widgets/qatar_live_map_canvas.dart';
import '../../data/models/admin_platform_models.dart';
import '../../data/services/google_maps_service.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminCorridorsGeoScreen extends StatefulWidget {
  const AdminCorridorsGeoScreen({super.key});

  @override
  State<AdminCorridorsGeoScreen> createState() =>
      _AdminCorridorsGeoScreenState();
}

class _AdminCorridorsGeoScreenState extends State<AdminCorridorsGeoScreen> {
  String _statusFilter = 'all';
  bool _useLiveMap = true;
  bool _showTraffic = true;
  MashwarMapVehicleMode _vehicleMode = MashwarMapVehicleMode.trip;

  void _openAddCorridorDialog(BuildContext context, bool isAr) {
    final admin = context.read<AdminProvider>();
    final fromAr = TextEditingController();
    final fromEn = TextEditingController();
    final toAr = TextEditingController();
    final toEn = TextEditingController();
    final munAr = TextEditingController(text: 'بلدية الدوحة');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAr ? 'إضافة محور أو منطقة جديدة' : 'Add New Qatar Corridor'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fromAr,
                  decoration: InputDecoration(
                    labelText: isAr ? 'من (بالعربية)' : 'From (Arabic)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fromEn,
                  decoration: InputDecoration(
                    labelText: isAr ? 'من (بالإنجليزية)' : 'From (English)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: toAr,
                  decoration: InputDecoration(
                    labelText: isAr ? 'إلى (بالعربية)' : 'To (Arabic)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: toEn,
                  decoration: InputDecoration(
                    labelText: isAr ? 'إلى (بالإنجليزية)' : 'To (English)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: munAr,
                  decoration: InputDecoration(
                    labelText: isAr ? 'البلدية القطرية' : 'Municipality',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (fromAr.text.trim().isEmpty || toAr.text.trim().isEmpty) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr
                          ? 'يرجى إدخال نقطة الانطلاق والوجهة'
                          : 'Please enter origin and destination',
                    ),
                    backgroundColor: AppColors.coral,
                  ),
                );
                return;
              }
              admin.addCorridor(
                AdminCorridorNode(
                  id: 'cor_${DateTime.now().millisecondsSinceEpoch}',
                  fromCityAr: fromAr.text.trim(),
                  fromCityEn: fromEn.text.trim().isEmpty ? fromAr.text.trim() : fromEn.text.trim(),
                  toCityAr: toAr.text.trim(),
                  toCityEn: toEn.text.trim().isEmpty ? toAr.text.trim() : toEn.text.trim(),
                  municipalityAr: munAr.text.trim(),
                  municipalityEn: 'Qatar Municipality',
                  status: 'active',
                  activeProviders: 0,
                  openRequests: 0,
                  conversionPct: 0.0,
                  avgEtaMin: 25,
                  incentiveMultiplier: 1.0,
                  dailyGmvQar: 0,
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'حفظ المحور' : 'Save Corridor'),
          ),
        ],
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fromAr.dispose();
        fromEn.dispose();
        toAr.dispose();
        toEn.dispose();
        munAr.dispose();
      });
    });
  }

  String _statusLabel(String st, bool isAr) {
    if (st == 'peak') return isAr ? 'ذروة عالية' : 'Peak';
    if (st == 'paused') return isAr ? 'متوقف مؤقتاً' : 'Paused';
    return isAr ? 'نشط' : 'Active';
  }

  Color _statusColor(String st) {
    if (st == 'peak') return AppColors.gold;
    if (st == 'paused') return AppColors.coral;
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final filtered = admin.corridors.where((c) {
      if (_statusFilter == 'all') return true;
      return c.status == _statusFilter;
    }).toList();

    final AdminCorridorNode? selectedCorridor = admin.corridors.isEmpty
        ? null
        : admin.corridors.firstWhere(
            (c) => c.id == admin.selectedCorridorId,
            orElse: () => admin.corridors.first,
          );
    const validCorridorStatuses = ['active', 'peak', 'paused'];
    final safeCorridorStatus = selectedCorridor != null &&
            validCorridorStatuses.contains(selectedCorridor.status)
        ? selectedCorridor.status
        : 'active';

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'خريطة المحاور والبلديات النشطة (${admin.corridors.length} محور في قطر)'
                          : 'Active Qatar Corridors & Municipalities (${admin.corridors.length} Routes)',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'اختر أي محور من الجدول لعرض المسار كاملًا مع الزحمة الحية وتعديل حالة المحور أو معامل التحفيز.'
                          : 'Pick any corridor from the table to inspect its full live traffic route and tune status or boost rules.',
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_road_rounded, size: 18),
                  label: Text(isAr ? 'إضافة محور جديد' : 'Add Corridor'),
                  onPressed: () => _openAddCorridorDialog(context, isAr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Map + Corridor Selector Split
          if (selectedCorridor == null)
            AdminSectionCard(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alt_route_rounded, size: 42, color: t.accentTeal),
                    const SizedBox(height: 12),
                    Text(
                      isAr
                          ? 'لا توجد محاور مسجلة بعد — اضغط "إضافة محور جديد" للبدء'
                          : 'No corridors configured yet — click "Add Corridor" to begin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 960;
              final mapPanel = AdminSectionCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selectedCorridor.routeLabel(isAr),
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(selectedCorridor.status).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusLabel(selectedCorridor.status, isAr),
                            style: TextStyle(
                              color: _statusColor(selectedCorridor.status),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ChoiceChip(
                          label: Text(
                            isAr ? 'خريطة حية + زحمة' : 'Live Traffic Map',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _useLiveMap ? Colors.white : t.textPrimary,
                            ),
                          ),
                          selectedColor: AppColors.navy,
                          checkmarkColor: Colors.white,
                          selected: _useLiveMap,
                          onSelected: (_) => setState(() => _useLiveMap = true),
                        ),
                        ChoiceChip(
                          label: Text(
                            isAr ? 'مخطط المحاور' : 'Schematic',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: !_useLiveMap ? Colors.white : t.textPrimary,
                            ),
                          ),
                          selectedColor: AppColors.navy,
                          checkmarkColor: Colors.white,
                          selected: !_useLiveMap,
                          onSelected: (_) => setState(() => _useLiveMap = false),
                        ),
                        if (_useLiveMap) ...[
                          FilterChip(
                            label: Text(
                              isAr ? 'الزحمة' : 'Traffic',
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
                            avatar: Icon(
                              _vehicleMode == MashwarMapVehicleMode.supply
                                  ? Icons.local_shipping_rounded
                                  : Icons.directions_car_rounded,
                              size: 14,
                            ),
                            label: Text(
                              _vehicleMode == MashwarMapVehicleMode.supply
                                  ? (isAr ? 'وضع التوريد' : 'Supply')
                                  : (isAr ? 'وضع الرحلات' : 'Trips'),
                              style: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () => setState(() {
                              _vehicleMode = _vehicleMode == MashwarMapVehicleMode.supply
                                  ? MashwarMapVehicleMode.trip
                                  : MashwarMapVehicleMode.supply;
                            }),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.open_in_full_rounded, size: 13),
                            label: Text(isAr ? 'ملء الشاشة' : 'Fullscreen', style: const TextStyle(fontSize: 11)),
                            onPressed: () => openMashwarInAppMap(
                              context,
                              titleAr: selectedCorridor.routeLabel(true),
                              titleEn: selectedCorridor.routeLabel(false),
                              origin: selectedCorridor.fromCityAr,
                              destination: selectedCorridor.toCityAr,
                              vehicleMode: _vehicleMode,
                              showTraffic: _showTraffic,
                              stylePreset: t.isDark
                                  ? MashwarMapStylePreset.night
                                  : MashwarMapStylePreset.standard,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 310,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _useLiveMap
                            ? MashwarEmbeddedGoogleMap(
                                key: ValueKey(
                                  'admin_cor_${selectedCorridor.id}_${_vehicleMode.name}_$_showTraffic',
                                ),
                                origin: selectedCorridor.fromCityAr,
                                destination: selectedCorridor.toCityAr,
                                vehicleMode: _vehicleMode,
                                showTraffic: _showTraffic,
                                stylePreset: t.isDark
                                    ? MashwarMapStylePreset.night
                                    : MashwarMapStylePreset.standard,
                                height: 310,
                                borderRadius: 14,
                              )
                            : QatarLiveMapCanvas(
                                style: t.isDark ? QatarMapStyle.darkExecutive : QatarMapStyle.light,
                                activeFromCity: selectedCorridor.fromCityAr,
                                activeToCity: selectedCorridor.toCityAr,
                                showHubLabels: true,
                                showCarTrails: true,
                                onHubTap: (city) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isAr ? 'النقطة المحددة: $city' : 'Selected Hub: $city'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          isAr
                              ? 'تحفيز المنفذين: ${selectedCorridor.incentiveMultiplier.toStringAsFixed(2)}x'
                              : 'Provider Boost: ${selectedCorridor.incentiveMultiplier.toStringAsFixed(2)}x',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Slider(
                            value: selectedCorridor.incentiveMultiplier.clamp(1.0, 1.5),
                            min: 1.0,
                            max: 1.5,
                            divisions: 10,
                            activeColor: AppColors.teal,
                            onChanged: (v) => admin.setCorridorIncentive(selectedCorridor.id, v),
                          ),
                        ),
                        DropdownButton<String>(
                          value: safeCorridorStatus,
                          items: validCorridorStatuses
                              .map((st) => DropdownMenuItem(value: st, child: Text(_statusLabel(st, isAr))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) admin.setCorridorStatus(selectedCorridor.id, v);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final corridorsListPanel = AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in [
                          {'k': 'all', 'ar': 'الكل', 'en': 'All'},
                          {'k': 'peak', 'ar': 'ذروة', 'en': 'Peak'},
                          {'k': 'active', 'ar': 'نشط', 'en': 'Active'},
                          {'k': 'paused', 'ar': 'متوقف', 'en': 'Paused'},
                        ])
                          ChoiceChip(
                            label: Text(isAr ? f['ar']! : f['en']!),
                            selected: _statusFilter == f['k'],
                            onSelected: (_) => setState(() => _statusFilter = f['k']!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AdminAdaptiveDataView<AdminCorridorNode>(
                      items: filtered,
                      minTableWidth: 640,
                      columns: [
                        DataColumn(label: Text(isAr ? 'المحور' : 'Corridor')),
                        DataColumn(label: Text(isAr ? 'منفذون' : 'Providers')),
                        DataColumn(label: Text(isAr ? 'التحويل' : 'Conv.')),
                        DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
                        DataColumn(label: Text(isAr ? 'معاينة' : 'Inspect')),
                      ],
                      buildRow: (c) {
                        final col = _statusColor(c.status);
                        return DataRow(
                          selected: c.id == selectedCorridor.id,
                          cells: [
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.routeLabel(isAr), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(
                                    isAr ? c.municipalityAr : c.municipalityEn,
                                    style: TextStyle(fontSize: 11, color: t.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text('${c.activeProviders} / ${c.openRequests}')),
                            DataCell(Text('${c.conversionPct.toStringAsFixed(0)}%', style: TextStyle(color: t.accentTeal, fontWeight: FontWeight.bold))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: col.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                                child: Text(_statusLabel(c.status, isAr), style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataCell(
                              TextButton(
                                onPressed: () => admin.selectCorridor(c.id),
                                child: Text(isAr ? 'تتبع' : 'Focus'),
                              ),
                            ),
                          ],
                        );
                      },
                      buildMobileCard: (ctx, c) {
                        final col = _statusColor(c.status);
                        final isSel = c.id == selectedCorridor.id;
                        return InkWell(
                          onTap: () => admin.selectCorridor(c.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.teal.withValues(alpha: 0.10) : t.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSel ? AppColors.teal : t.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.routeLabel(isAr),
                                        style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    Text(
                                      _statusLabel(c.status, isAr),
                                      style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${isAr ? c.municipalityAr : c.municipalityEn} · ${c.activeProviders} ${isAr ? "منفذ" : "providers"} · ${c.incentiveMultiplier.toStringAsFixed(2)}x',
                                  style: TextStyle(color: t.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );

              if (isStacked) {
                return Column(
                  children: [
                    mapPanel,
                    const SizedBox(height: 16),
                    corridorsListPanel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: mapPanel),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: corridorsListPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
