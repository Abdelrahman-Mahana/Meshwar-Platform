import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final TextEditingController _bannerArCtrl = TextEditingController();
  final TextEditingController _bannerEnCtrl = TextEditingController();
  bool _controllersSeeded = false;

  @override
  void dispose() {
    _bannerArCtrl.dispose();
    _bannerEnCtrl.dispose();
    super.dispose();
  }

  void _editSetting(BuildContext context, AdminSystemSetting setting, bool isAr) {
    final controller = TextEditingController(text: setting.value);
    final admin = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
        title: Text(isAr ? 'تعديل معامل التشغيل' : 'Edit Platform Parameter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAr ? setting.nameAr : setting.nameEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(isAr ? setting.descriptionAr : setting.descriptionEn, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: isAr ? setting.unitAr : setting.unitEn,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'رجوع' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
            onPressed: () {
              admin.updateSetting(setting.key, controller.text.trim());
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
  }

  void _openAddSettingDialog(BuildContext context, bool isAr) {
    final admin = context.read<AdminProvider>();
    final keyCtrl = TextEditingController();
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'QAR');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAr ? 'إضافة معامل نظام جديد' : 'Add Custom System Setting'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: keyCtrl,
                  decoration: InputDecoration(labelText: isAr ? 'المفتاح البرمجي (مثل: max_escrow_qar)' : 'Key', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameArCtrl,
                  decoration: InputDecoration(labelText: isAr ? 'الاسم بالعربية' : 'Arabic Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameEnCtrl,
                  decoration: InputDecoration(labelText: isAr ? 'الاسم بالإنجليزية' : 'English Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: valCtrl,
                        decoration: InputDecoration(labelText: isAr ? 'القيمة' : 'Value', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: InputDecoration(labelText: isAr ? 'الوحدة' : 'Unit', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
            onPressed: () {
              final k = keyCtrl.text.trim();
              if (k.isEmpty || valCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr
                          ? 'يرجى إدخال المفتاح البرمجي والقيمة'
                          : 'Please enter both key and value',
                    ),
                    backgroundColor: AppColors.coral,
                  ),
                );
                return;
              }
              admin.addSystemSetting(
                AdminSystemSetting(
                  key: k,
                  nameAr: nameArCtrl.text.trim().isEmpty ? k : nameArCtrl.text.trim(),
                  nameEn: nameEnCtrl.text.trim().isEmpty ? k : nameEnCtrl.text.trim(),
                  value: valCtrl.text.trim(),
                  unitAr: unitCtrl.text.trim(),
                  unitEn: unitCtrl.text.trim(),
                  descriptionAr: 'معامل تحكم مضاف عبر الإعدادات الديناميكية',
                  descriptionEn: 'Dynamically provisioned configuration parameter',
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'حفظ المعامل' : 'Save Parameter'),
          ),
        ],
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        keyCtrl.dispose();
        nameArCtrl.dispose();
        nameEnCtrl.dispose();
        valCtrl.dispose();
        unitCtrl.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    if (!_controllersSeeded) {
      _bannerArCtrl.text = admin.broadcastBanner.messageAr;
      _bannerEnCtrl.text = admin.broadcastBanner.messageEn;
      _controllersSeeded = true;
    }

    final banner = admin.broadcastBanner;

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Consumer App Broadcast Controller
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'شريط التنبيهات المباشر لتطبيق المستخدمين (Live Broadcast)' : 'Consumer App Live Broadcast Banner',
                          style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          isAr ? 'يظهر فوراً أعلى الشاشة الرئيسية لكل المستخدمين في قطر' : 'Displays instantly at the top of the MASHWAR Home screen',
                          style: TextStyle(color: t.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    Switch(
                      value: banner.isEnabled,
                      activeThumbColor: AppColors.qatarMaroon,
                      onChanged: (v) => admin.updateBroadcastBanner(
                        banner.copyWith(
                          isEnabled: v,
                          messageAr: _bannerArCtrl.text.trim(),
                          messageEn: _bannerEnCtrl.text.trim(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bannerArCtrl,
                  style: TextStyle(color: t.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isAr ? 'رسالة البث بالعربية' : 'Arabic Broadcast Message',
                    filled: true,
                    fillColor: t.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bannerEnCtrl,
                  style: TextStyle(color: t.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isAr ? 'رسالة البث بالإنجليزية' : 'English Broadcast Message',
                    filled: true,
                    fillColor: t.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final sev in ['info', 'warning', 'urgent'])
                      ChoiceChip(
                        label: Text(sev.toUpperCase()),
                        selected: banner.severity == sev,
                        onSelected: (_) => admin.updateBroadcastBanner(
                          banner.copyWith(
                            severity: sev,
                            messageAr: _bannerArCtrl.text.trim(),
                            messageEn: _bannerEnCtrl.text.trim(),
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                      icon: const Icon(Icons.campaign_rounded, size: 17),
                      label: Text(isAr ? 'بث وتحديث النص' : 'Push Banner'),
                      onPressed: () {
                        admin.updateBroadcastBanner(
                          banner.copyWith(
                            isEnabled: true,
                            messageAr: _bannerArCtrl.text.trim(),
                            messageEn: _bannerEnCtrl.text.trim(),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isAr ? 'تم تفعيل شريط البث على التطبيق مباشرة' : 'Live banner pushed to client app'),
                            backgroundColor: AppColors.teal,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // System Parameters Table
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isAr ? 'معاملات التشغيل وقواعد المطابقة والضمان' : 'Operational Thresholds & Matching Parameters',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: Text(isAr ? 'إضافة معامل جديد' : 'Add Parameter'),
                      onPressed: () => _openAddSettingDialog(context, isAr),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AdminAdaptiveDataView<AdminSystemSetting>(
                  items: admin.settingsList,
                  minTableWidth: 820,
                  columns: [
                    DataColumn(label: Text(isAr ? 'الإعداد' : 'Parameter')),
                    DataColumn(label: Text(isAr ? 'القيمة' : 'Value')),
                    DataColumn(label: Text(isAr ? 'الوصف' : 'Description')),
                    DataColumn(label: Text(isAr ? 'تعديل' : 'Edit')),
                  ],
                  buildRow: (setting) => DataRow(
                    cells: [
                      DataCell(Text(isAr ? setting.nameAr : setting.nameEn, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.surfaceMuted,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: t.border),
                          ),
                          child: Text(
                            '${setting.value} ${isAr ? setting.unitAr : setting.unitEn}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: t.textPrimary),
                          ),
                        ),
                      ),
                      DataCell(Text(isAr ? setting.descriptionAr : setting.descriptionEn, style: const TextStyle(fontSize: 12))),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: t.accentTeal, size: 20),
                          onPressed: () => _editSetting(context, setting, isAr),
                        ),
                      ),
                    ],
                  ),
                  buildMobileCard: (ctx, setting) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(isAr ? setting.nameAr : setting.nameEn, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
                            ),
                            Text('${setting.value} ${isAr ? setting.unitAr : setting.unitEn}', style: TextStyle(color: t.accentTeal, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(isAr ? setting.descriptionAr : setting.descriptionEn, style: TextStyle(color: t.textSecondary, fontSize: 11)),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () => _editSetting(context, setting, isAr),
                            child: Text(isAr ? 'تعديل القيمة' : 'Edit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
