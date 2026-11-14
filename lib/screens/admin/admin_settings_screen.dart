import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  void _editSetting(BuildContext context, AdminSystemSetting setting) {
    final controller = TextEditingController(text: setting.value);
    final isAr = context.read<SettingsProvider>().isArabic;
    final admin = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
        title: Text(
          isAr ? 'تأكيد التغيير' : 'Confirm Setting Change',
          style: AppTypography.title(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? setting.nameAr : setting.nameEn,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              isAr ? setting.descriptionAr : setting.descriptionEn,
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: isAr ? setting.unitAr : setting.unitEn,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.goldSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Text(
                isAr
                    ? 'تغيير هذا المعامل هيأثر فوراً على نتائج البحث وسلوك التطبيق لكل المستخدمين.'
                    : 'Changing this value will immediately affect search results and matching system-wide.',
                style: const TextStyle(fontSize: 11, color: AppColors.navy),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'رجوع' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              admin.updateSetting(setting.key, controller.text.trim());
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAr ? 'تم تحديث الإعداد وتسجيل التغيير في سجل التدقيق' : 'Setting updated & logged to audit trail'),
                  backgroundColor: AppColors.teal,
                ),
              );
            },
            child: Text(isAr ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 800),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 64,
                      columns: [
                        DataColumn(label: Text(isAr ? 'الإعداد' : 'Parameter', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'القيمة' : 'Value', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'الوصف' : 'Description', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'الإجراء' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: admin.settingsList.map((setting) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                isAr ? setting.nameAr : setting.nameEn,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  '${setting.value} ${isAr ? setting.unitAr : setting.unitEn}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(isAr ? setting.descriptionAr : setting.descriptionEn, style: const TextStyle(fontSize: 12)),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.teal, size: 20),
                                tooltip: isAr ? 'تعديل الإعداد' : 'Edit Parameter',
                                onPressed: () => _editSetting(context, setting),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Footer notice (Page 75)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: Text(
                      isAr ? 'التغيير يسري فوراً على كل المستخدمين بدون الحاجة لإعادة نشر التطبيق.' : 'Changes take effect immediately across all client instances.',
                      style: AppTypography.label(color: AppColors.textSecondary),
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
