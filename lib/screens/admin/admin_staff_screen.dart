import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  void _showAddStaffDialog(BuildContext context, bool isAr) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    AdminRole selectedRole = AdminRole.reviewAdmin;
    final admin = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
          title: Text(isAr ? 'إضافة موظف جديد' : 'Add New Staff Member'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسم الموظف' : 'Staff Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'البريد الإلكتروني' : 'Email Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<AdminRole>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الدور والصلاحيات' : 'Role & Scope',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: AdminRole.values.map((role) {
                    final dummy = AdminStaffMember(id: '', name: '', email: '', role: role);
                    return DropdownMenuItem(
                      value: role,
                      child: Text(isAr ? dummy.roleTitleAr : dummy.roleTitleEn),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedRole = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'يرجى إدخال اسم الموظف والبريد الإلكتروني'
                            : 'Please enter staff name and email address',
                      ),
                      backgroundColor: AppColors.coral,
                    ),
                  );
                  return;
                }
                admin.addStaff(name, email, selectedRole);
                Navigator.of(ctx).pop();
              },
              child: Text(isAr ? 'حفظ الموظف' : 'Save Staff'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameCtrl.dispose();
        emailCtrl.dispose();
      });
    });
  }

  void _showEditStaffDialog(BuildContext context, AdminStaffMember staff, bool isAr) {
    AdminRole selectedRole = staff.role;
    bool isActive = staff.isActive;
    final admin = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
          title: Text(isAr ? 'تعديل صلاحيات: ${staff.name}' : 'Edit Permissions: ${staff.name}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${isAr ? "البريد:" : "Email:"} ${staff.email}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                DropdownButtonFormField<AdminRole>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الدور والصلاحيات' : 'Role',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: AdminRole.values.map((role) {
                    final dummy = AdminStaffMember(id: '', name: '', email: '', role: role);
                    return DropdownMenuItem(
                      value: role,
                      child: Text(isAr ? dummy.roleTitleAr : dummy.roleTitleEn),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedRole = v);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isAr ? 'الحساب نشط' : 'Active Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: isActive,
                  activeThumbColor: AppColors.teal,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
              onPressed: () {
                admin.editStaff(staff.id, newRole: selectedRole, isActive: isActive);
                Navigator.of(ctx).pop();
              },
              child: Text(isAr ? 'حفظ التعديلات' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  bool _roleHasAccess(AdminRole role, int idx) {
    // Matches AdminProvider.canAccessMenu(index) across all 14 modules (0..13)
    switch (role) {
      case AdminRole.superAdmin:
        return true;
      case AdminRole.reviewAdmin:
        return idx == 0 || idx == 1 || idx == 13;
      case AdminRole.supportAdmin:
        return idx == 0 || idx == 2 || idx == 3 || idx == 4 || idx == 12 || idx == 13;
      case AdminRole.financeAdmin:
        return idx == 0 || idx == 3 || idx == 7 || idx == 8 || idx == 10 || idx == 13;
      case AdminRole.devopsAdmin:
        return idx == 0 || idx == 5 || idx == 7 || idx == 8 || idx == 9 || idx == 11;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  isAr ? 'إدارة فريق العمل (${admin.staff.length} موظفين) و 5 مستويات RBAC' : 'Staff Directory (${admin.staff.length}) & 5-Tier RBAC',
                  style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(isAr ? 'إضافة موظف' : 'Add Staff Member'),
                  onPressed: () => _showAddStaffDialog(context, isAr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminSectionCard(
            padding: const EdgeInsets.all(14),
            child: AdminAdaptiveDataView<AdminStaffMember>(
              items: admin.staff,
              minTableWidth: 800,
              columns: [
                DataColumn(label: Text(isAr ? 'الاسم' : 'Name')),
                DataColumn(label: Text(isAr ? 'البريد' : 'Email')),
                DataColumn(label: Text(isAr ? 'الدور' : 'Role')),
                DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
                DataColumn(label: Text(isAr ? 'الإجراء' : 'Action')),
              ],
              buildRow: (s) => DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.gold,
                          child: Text(
                            s.name.isNotEmpty ? s.name[0] : 'م',
                            style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  DataCell(Text(s.email, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                  DataCell(Text(isAr ? s.roleTitleAr : s.roleTitleEn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                  DataCell(
                    MashwarBadge(
                      type: s.isActive ? BadgeType.verified : BadgeType.rejected,
                      customLabel: s.isActive ? (isAr ? 'نشط' : 'Active') : (isAr ? 'موقوف' : 'Inactive'),
                    ),
                  ),
                  DataCell(
                    s.role == AdminRole.superAdmin
                        ? const Text('—')
                        : OutlinedButton(
                            onPressed: () => _showEditStaffDialog(context, s, isAr),
                            child: Text(isAr ? 'تعديل' : 'Edit', style: const TextStyle(fontSize: 12)),
                          ),
                  ),
                ],
              ),
              buildMobileCard: (ctx, s) => Container(
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
                        Expanded(child: Text(s.name, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800))),
                        MashwarBadge(
                          type: s.isActive ? BadgeType.verified : BadgeType.rejected,
                          customLabel: s.isActive ? (isAr ? 'نشط' : 'Active') : (isAr ? 'موقوف' : 'Inactive'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${s.email} · ${isAr ? s.roleTitleAr : s.roleTitleEn}', style: TextStyle(color: t.textSecondary, fontSize: 11)),
                    if (s.role != AdminRole.superAdmin)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () => _showEditStaffDialog(context, s, isAr),
                          child: Text(isAr ? 'تعديل الصلاحية' : 'Edit Role'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Visual 14-Module x 5-Role Permissions Matrix
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'مصفوفة الصلاحيات التفصيلية (14 وحدة × 5 أدوار)' : 'Interactive RBAC Matrix (14 Modules × 5 Roles)',
                  style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(t.tableHeaderBg),
                    columns: [
                      DataColumn(label: Text(isAr ? 'القسم' : 'Module', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(isAr ? 'مشرف أول' : 'Super', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(isAr ? 'مراجعة' : 'Review', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(isAr ? 'دعم' : 'Support', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(isAr ? 'مالية' : 'Finance', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('DevOps', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold))),
                    ],
                    rows: AdminProvider.modulesCatalog.map((m) {
                      return DataRow(
                        cells: [
                          DataCell(Text(isAr ? m.titleAr : m.titleEn, style: TextStyle(color: t.textPrimary, fontSize: 12, fontWeight: FontWeight.w700))),
                          for (final role in AdminRole.values)
                            DataCell(
                              Icon(
                                _roleHasAccess(role, m.index) ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                                size: 18,
                                color: _roleHasAccess(role, m.index) ? t.accentTeal : t.textSecondary.withValues(alpha: 0.4),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
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
