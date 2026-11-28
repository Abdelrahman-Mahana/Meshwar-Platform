import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/admin_platform_models.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminServicesCatalogScreen extends StatefulWidget {
  const AdminServicesCatalogScreen({super.key});

  @override
  State<AdminServicesCatalogScreen> createState() =>
      _AdminServicesCatalogScreenState();
}

class _AdminServicesCatalogScreenState
    extends State<AdminServicesCatalogScreen> {
  String _searchQuery = '';
  bool _onlyEnabled = false;

  IconData _iconForName(String name) {
    switch (name) {
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'engineering':
        return Icons.engineering_rounded;
      case 'description':
        return Icons.description_rounded;
      case 'family_restroom':
        return Icons.family_restroom_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'local_shipping':
        return Icons.local_shipping_rounded;
      default:
        return Icons.extension_rounded;
    }
  }

  void _openEditDialog(BuildContext context, AdminServiceDefinition svc, bool isAr) {
    final admin = context.read<AdminProvider>();
    final nameArCtrl = TextEditingController(text: svc.nameAr);
    final nameEnCtrl = TextEditingController(text: svc.nameEn);
    final commCtrl = TextEditingController(text: svc.commissionPct.toStringAsFixed(1));
    final minFeeCtrl = TextEditingController(text: '${svc.minFeeQar}');
    final maxFeeCtrl = TextEditingController(text: '${svc.maxFeeQar}');
    final receiptCapCtrl = TextEditingController(text: '${svc.maxReceiptCapQar}');
    final slaCtrl = TextEditingController(text: '${svc.slaMinutes}');

    bool isMaintenance = svc.isMaintenance;
    bool requiresEscrow = svc.requiresEscrow;
    bool requiresReceipt = svc.requiresReceiptPhoto;
    bool requiresOtp = svc.requiresFourDigitOtp;
    bool allowsLadiesOnly = svc.allowsLadiesOnly;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isAr ? 'ضبط قواعد: ${svc.nameAr}' : 'Configure: ${svc.nameEn}'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameArCtrl,
                      decoration: InputDecoration(
                        labelText: isAr ? 'الاسم بالعربية' : 'Arabic Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameEnCtrl,
                      decoration: InputDecoration(
                        labelText: isAr ? 'الاسم بالإنجليزية' : 'English Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'عمولة المنصة (%)' : 'Commission %',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: slaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'زمن SLA (دقيقة)' : 'SLA (mins)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minFeeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'الحد الأدنى (ر.ق)' : 'Min Fee (QAR)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: maxFeeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'الحد الأقصى (ر.ق)' : 'Max Fee (QAR)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: receiptCapCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isAr ? 'سقف الفاتورة في الضمان (ر.ق)' : 'Max Receipt Cap (QAR)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const Divider(height: 20),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(isAr ? 'التحقق من التسوية والتسليم' : 'Verified Settlement & Handover'),
                      value: requiresEscrow,
                      onChanged: (v) => setModalState(() => requiresEscrow = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(isAr ? 'إلزامية تصوير الفاتورة قبل التحرك' : 'Mandatory Live Receipt Photo'),
                      value: requiresReceipt,
                      onChanged: (v) => setModalState(() => requiresReceipt = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(isAr ? 'تأكيد التسليم بكود 4 أرقام (OTP)' : '4-Digit Handover OTP'),
                      value: requiresOtp,
                      onChanged: (v) => setModalState(() => requiresOtp = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(isAr ? 'إتاحة خيار "السيدات فقط"' : 'Allow Ladies-Only Filter'),
                      value: allowsLadiesOnly,
                      onChanged: (v) => setModalState(() => allowsLadiesOnly = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(isAr ? 'تفعيل شارة صيانة الخدمة' : 'Maintenance Mode Badge'),
                      value: isMaintenance,
                      onChanged: (v) => setModalState(() => isMaintenance = v),
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
                  final updated = svc.copyWith(
                    nameAr: nameArCtrl.text.trim(),
                    nameEn: nameEnCtrl.text.trim(),
                    commissionPct: double.tryParse(commCtrl.text.trim()) ?? svc.commissionPct,
                    minFeeQar: int.tryParse(minFeeCtrl.text.trim()) ?? svc.minFeeQar,
                    maxFeeQar: int.tryParse(maxFeeCtrl.text.trim()) ?? svc.maxFeeQar,
                    maxReceiptCapQar: int.tryParse(receiptCapCtrl.text.trim()) ?? svc.maxReceiptCapQar,
                    slaMinutes: int.tryParse(slaCtrl.text.trim()) ?? svc.slaMinutes,
                    isMaintenance: isMaintenance,
                    requiresEscrow: requiresEscrow,
                    requiresReceiptPhoto: requiresReceipt,
                    requiresFourDigitOtp: requiresOtp,
                    allowsLadiesOnly: allowsLadiesOnly,
                  );
                  admin.updateServiceConfig(updated);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? 'تم حفظ قواعد الخدمة وتحديثها بالمنصة' : 'Service policy saved & synced'),
                      backgroundColor: AppColors.teal,
                    ),
                  );
                },
                child: Text(isAr ? 'حفظ التعديلات' : 'Save Policy'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameArCtrl.dispose();
        nameEnCtrl.dispose();
        commCtrl.dispose();
        minFeeCtrl.dispose();
        maxFeeCtrl.dispose();
        receiptCapCtrl.dispose();
        slaCtrl.dispose();
      });
    });
  }

  void _openCreateServiceDialog(BuildContext context, bool isAr) {
    final admin = context.read<AdminProvider>();
    final codeCtrl = TextEditingController();
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final descArCtrl = TextEditingController();
    final commCtrl = TextEditingController(text: '16');
    final minCtrl = TextEditingController(text: '25');
    final maxCtrl = TextEditingController(text: '600');
    bool escrow = true;
    bool receipt = true;
    bool otp = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isAr ? 'إضافة خط خدمة مستقبلي جديد' : 'Add Future Platform Service'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'المعرف البرمجي (مثل: ev_assist)' : 'Service Code (e.g. ev_assist)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameArCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'اسم الخدمة بالعربية' : 'Arabic Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameEnCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'اسم الخدمة بالإنجليزية' : 'English Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descArCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الوصف التشغيلي' : 'Operational Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: isAr ? 'العمولة %' : 'Fee %',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: isAr ? 'أدنى سعر' : 'Min QAR',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: isAr ? 'أقصى سعر' : 'Max QAR',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(isAr ? 'حماية الضمان المالي' : 'Escrow Protected'),
                    value: escrow,
                    onChanged: (v) => setModalState(() => escrow = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(isAr ? 'إلزامية الفاتورة' : 'Receipt Required'),
                    value: receipt,
                    onChanged: (v) => setModalState(() => receipt = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(isAr ? 'كود استلام OTP' : 'OTP Verification'),
                    value: otp,
                    onChanged: (v) => setModalState(() => otp = v),
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
                backgroundColor: AppColors.qatarMaroon,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final ar = nameArCtrl.text.trim();
                final en = nameEnCtrl.text.trim();
                if (ar.isEmpty || en.isEmpty) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'يرجى إدخال اسم الخدمة بالعربية والإنجليزية'
                            : 'Please enter both Arabic and English service titles',
                      ),
                      backgroundColor: AppColors.coral,
                    ),
                  );
                  return;
                }
                final minFee = int.tryParse(minCtrl.text) ?? 25;
                final maxFee = int.tryParse(maxCtrl.text) ?? 600;
                final code = codeCtrl.text.trim().isEmpty
                    ? 'custom_${DateTime.now().millisecondsSinceEpoch}'
                    : codeCtrl.text.trim();
                admin.addServiceDefinition(
                  AdminServiceDefinition(
                    id: 'svc_$code',
                    code: code,
                    nameAr: ar,
                    nameEn: en,
                    descriptionAr: descArCtrl.text.trim().isEmpty
                        ? 'خدمة مجتمعية مضافة ديناميكياً عبر مركز الإدارة'
                        : descArCtrl.text.trim(),
                    descriptionEn: 'Dynamically provisioned service line.',
                    iconName: 'extension',
                    accentHex: 0xFF8A1538,
                    isEnabled: true,
                    commissionPct: double.tryParse(commCtrl.text) ?? 16.0,
                    minFeeQar: minFee,
                    maxFeeQar: maxFee >= minFee ? maxFee : minFee,
                    requiresEscrow: escrow,
                    requiresReceiptPhoto: receipt,
                    requiresFourDigitOtp: otp,
                  ),
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAr ? 'تمت إضافة الخدمة الجديدة وتفعيلها فوراً' : 'New service published live'),
                    backgroundColor: AppColors.teal,
                  ),
                );
              },
              child: Text(isAr ? 'نشر الخدمة الآن' : 'Publish Service'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        codeCtrl.dispose();
        nameArCtrl.dispose();
        nameEnCtrl.dispose();
        descArCtrl.dispose();
        commCtrl.dispose();
        minCtrl.dispose();
        maxCtrl.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final items = admin.servicesCatalog.where((s) {
      if (_onlyEnabled && !s.isEnabled) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return s.nameAr.toLowerCase().contains(q) ||
            s.nameEn.toLowerCase().contains(q) ||
            s.code.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final enabledCount = admin.servicesCatalog.where((s) => s.isEnabled).length;
    final avgCommission = admin.servicesCatalog.isEmpty
        ? 0.0
        : admin.servicesCatalog.fold(0.0, (sum, s) => sum + s.commissionPct) /
            admin.servicesCatalog.length;

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
                          ? 'محرك إدارة الخدمات الـ ${admin.servicesCatalog.length} والتسعير الديناميكي'
                          : 'Extensible Service Catalog (${admin.servicesCatalog.length} Lines) & Pricing Engine',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'تشغيل وإيقاف أي خدمة لحظياً، تعديل نسب العمولات، سقوف الفواتير، وقواعد الضمان المالي.'
                          : 'Enable/pause lines live, tune platform commissions, receipt caps, OTP & Escrow rules.',
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.qatarMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text(isAr ? 'إضافة خدمة مستقبلية جديدة' : 'Add New Service Line'),
                  onPressed: () => _openCreateServiceDialog(context, isAr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Strip
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 1000 ? 3 : (w >= 600 ? 2 : 1);
              final cardW = (w - (14 * (cols - 1))) / cols;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'الخدمات المفعلة' : 'Active Services',
                      value: '$enabledCount / ${admin.servicesCatalog.length}',
                      deltaText: isAr ? 'متاحة بالتطبيق الآن' : 'Live in Mobile/Web',
                      accentColor: t.accentTeal,
                      icon: Icons.grid_view_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'متوسط عمولة المنصة' : 'Avg Take Rate',
                      value: '${avgCommission.toStringAsFixed(1)}%',
                      deltaText: isAr ? 'محمي بحد أدنى وأقصى' : 'Dynamic Floor/Cap Guardrails',
                      accentColor: AppColors.gold,
                      icon: Icons.percent_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'الطلبات الجارية بالخدمات' : 'Open Orders Across Lines',
                      value:
                          '${admin.servicesCatalog.fold<int>(0, (s, e) => s + e.activeOrdersCount)}',
                      deltaText: isAr ? 'حماية مزدوجة Escrow + OTP' : 'Escrow + OTP Protected',
                      accentColor: AppColors.qatarMaroon,
                      icon: Icons.verified_user_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Search & Filter
          AdminSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(color: t.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: isAr ? 'ابحث باسم الخدمة أو الكود...' : 'Filter service or code...',
                      hintStyle: TextStyle(color: t.textSecondary, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: t.accentPrimary),
                      filled: true,
                      fillColor: t.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: t.border),
                      ),
                    ),
                  ),
                ),
                FilterChip(
                  label: Text(isAr ? 'الخدمات المفعلة فقط' : 'Enabled Only'),
                  selected: _onlyEnabled,
                  onSelected: (v) => setState(() => _onlyEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Responsive Grid of Service Control Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 1200 ? 3 : (w >= 720 ? 2 : 1);
              final cardW = (w - (16 * (cols - 1))) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: items.map((svc) {
                  final accent = Color(svc.accentHex);
                  return SizedBox(
                    width: cardW,
                    child: AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_iconForName(svc.iconName), color: accent, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr ? svc.nameAr : svc.nameEn,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: t.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      svc.code,
                                      style: TextStyle(
                                        color: t.textSecondary,
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: svc.isEnabled,
                                activeThumbColor: t.accentTeal,
                                onChanged: (_) => admin.toggleServiceEnabled(svc.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isAr ? svc.descriptionAr : svc.descriptionEn,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: t.textSecondary, fontSize: 12, height: 1.45),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _pill('${isAr ? "عمولة" : "Fee"} ${svc.commissionPct.toStringAsFixed(1)}%', accent, t),
                              _pill('${svc.minFeeQar}-${svc.maxFeeQar} QAR', t.accentPrimary, t),
                              if (svc.maxReceiptCapQar > 0)
                                _pill('${isAr ? "فاتورة حتى" : "Receipt"} ${svc.maxReceiptCapQar}', AppColors.gold, t),
                              if (svc.requiresEscrow)
                                _pill('Escrow', t.accentTeal, t),
                              if (svc.requiresFourDigitOtp)
                                _pill('OTP', AppColors.qatarMaroon, t),
                              if (svc.isMaintenance)
                                _pill(isAr ? 'صيانة' : 'Maint.', AppColors.coral, t),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: t.border),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SLA: ${svc.slaMinutes} ${isAr ? "د" : "m"} · ${svc.activeOrdersCount} ${isAr ? "نشط" : "active"}',
                                style: TextStyle(
                                  color: t.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: t.accentPrimary,
                                  side: BorderSide(color: t.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.tune_rounded, size: 15),
                                label: Text(isAr ? 'ضبط القواعد' : 'Configure', style: const TextStyle(fontSize: 12)),
                                onPressed: () => _openEditDialog(context, svc, isAr),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color, AdminThemeTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: t.isDark ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
