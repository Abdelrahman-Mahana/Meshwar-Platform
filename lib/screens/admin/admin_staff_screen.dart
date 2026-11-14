import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  void _showAddStaffDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    AdminRole selectedRole = AdminRole.reviewAdmin;
    final isAr = context.read<SettingsProvider>().isArabic;
    final admin = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
            title: Text(isAr ? 'إضافة موظف جديد' : 'Add New Staff Member'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسم الموظف' : 'Staff Name',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'البريد الإلكتروني' : 'Email Address',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(isAr ? 'الدور والصلاحيات:' : 'Role & Scope:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<AdminRole>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: AdminRole.reviewAdmin,
                      child: Text(isAr ? 'مشرف مراجعة (توثيق السائقين فقط)' : 'Review Admin (Driver Verification)'),
                    ),
                    DropdownMenuItem(
                      value: AdminRole.supportAdmin,
                      child: Text(isAr ? 'مشرف دعم (المستخدمون والنزاعات)' : 'Support Admin (Users & Disputes)'),
                    ),
                    DropdownMenuItem(
                      value: AdminRole.superAdmin,
                      child: Text(isAr ? 'مشرف أول (كل الصلاحيات والإعدادات)' : 'Super Admin (Full Access & Settings)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
              ],
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
                  final name = nameCtrl.text.trim();
                  final email = emailCtrl.text.trim();
                  if (name.isNotEmpty && email.isNotEmpty) {
                    admin.addStaff(name, email, selectedRole);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'تمت إضافة الموظف بنجاح' : 'Staff member created successfully'),
                        backgroundColor: AppColors.teal,
                      ),
                    );
                  }
                },
                child: Text(isAr ? 'حفظ الموظف' : 'Save Staff'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, AdminStaffMember staff) {
    AdminRole selectedRole = staff.role;
    bool isActive = staff.isActive;
    final isAr = context.read<SettingsProvider>().isArabic;
    final admin = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
            title: Text(isAr ? 'تعديل صلاحيات: ${staff.name}' : 'Edit Permissions: ${staff.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isAr ? "البريد الإلكتروني" : "Email"}: ${staff.email}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'الدور والصلاحيات:' : 'Role & Scope:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AdminRole>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: AdminRole.reviewAdmin,
                      child: Text(isAr ? 'مشرف مراجعة (توثيق السائقين)' : 'Review Admin (Driver Verification)'),
                    ),
                    DropdownMenuItem(
                      value: AdminRole.supportAdmin,
                      child: Text(isAr ? 'مشرف دعم (المستخدمون والنزاعات)' : 'Support Admin (Users & Disputes)'),
                    ),
                    DropdownMenuItem(
                      value: AdminRole.superAdmin,
                      child: Text(isAr ? 'مشرف أول (كل الصلاحيات)' : 'Super Admin (Full Privileges)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    isAr ? 'الحساب نشط' : 'Active Account',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    isAr ? 'تعطيل الحساب يمنع الموظف من تسجيل الدخول فوراً' : 'Disabling prevents employee from signing in',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  value: isActive,
                  activeThumbColor: AppColors.teal,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
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
                  admin.editStaff(staff.id, newRole: selectedRole, isActive: isActive);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? 'تم تحديث صلاحيات وحالة الموظف' : 'Staff role and status updated'),
                      backgroundColor: AppColors.teal,
                    ),
                  );
                },
                child: Text(isAr ? 'حفظ التعديلات' : 'Save Changes'),
              ),
            ],
          );
        },
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
          // Header action bar (Page 77 - Responsive Wrap)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(isAr ? 'إضافة موظف' : 'Add Staff Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showAddStaffDialog(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  isAr ? '${admin.staff.length} موظفين' : '${admin.staff.length} Staff',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.space16),

          // Staff Table (Page 77)
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 64,
                  columns: [
                    DataColumn(label: Text(isAr ? 'الاسم' : 'Staff Name', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'البريد' : 'Email Address', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'الدور' : 'Role', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'الإجراء' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: admin.staff.map((s) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: AppColors.gold,
                                child: Text(
                                  s.name.isNotEmpty ? s.name[0] : 'م',
                                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        DataCell(Text(s.email, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              isAr ? s.roleTitleAr : s.roleTitleEn,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navy),
                            ),
                          ),
                        ),
                        DataCell(
                          MashwarBadge(
                            type: s.isActive ? BadgeType.verified : BadgeType.rejected,
                            customLabel: s.isActive ? (isAr ? 'نشط' : 'Active') : (isAr ? 'موقوف' : 'Inactive'),
                          ),
                        ),
                        DataCell(
                          s.role == AdminRole.superAdmin
                              ? const Text('—', style: TextStyle(color: AppColors.textSecondary))
                              : OutlinedButton(
                                  onPressed: () => _showEditStaffDialog(context, s),
                                  child: Text(isAr ? 'تعديل' : 'Edit', style: const TextStyle(fontSize: 12)),
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppDimens.space20),

          // Permissions Reference Box (Page 77)
          Container(
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
                Text(
                  isAr ? 'شجرة الصلاحيات والأدوار (Permissions Matrix):' : 'Permissions & Role Matrix:',
                  style: AppTypography.title().copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildRoleDesc(
                  isAr ? 'مشرف أول (Super Admin):' : 'Super Admin:',
                  isAr ? 'كل الصلاحيات في النظام + تعديل الإعدادات الحاكمة وإدارة الموظفين والتدقيق.' : 'Full system privileges + settings modification, staff management, and audit inspection.',
                ),
                const SizedBox(height: 6),
                _buildRoleDesc(
                  isAr ? 'مشرف مراجعة (Review Admin):' : 'Review Admin:',
                  isAr ? 'فحص ومراجعة مستندات السائقين (البطاقة، الرخص، السيلفي) وقبول أو رفض التوثيق فقط.' : 'Review and verify driver identity and vehicle documents (ID, licenses, selfie).',
                ),
                const SizedBox(height: 6),
                _buildRoleDesc(
                  isAr ? 'مشرف دعم (Support Admin):' : 'Support Admin:',
                  isAr ? 'إدارة المستخدمين، حل البلاغات والنزاعات، رفع الإيقاف، والحظر الإداري المسبب.' : 'User management, handling complaints and disputes, lifting suspensions, and enforcing bans.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDesc(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline_rounded, color: AppColors.teal, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12, height: 1.5),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  TextSpan(
                    text: desc,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
