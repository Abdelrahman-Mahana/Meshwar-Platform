import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  String _selectedActor = 'الكل';
  String _selectedAction = 'الكل';
  String _selectedTarget = 'الكل';
  String _selectedDate = 'الكل';

  void _resetFilters() {
    setState(() {
      _selectedActor = 'الكل';
      _selectedAction = 'الكل';
      _selectedTarget = 'الكل';
      _selectedDate = 'الكل';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();

    // Actor options
    final actorOptions = isAr
        ? ['الكل', 'مدير النظام', 'أحمد', 'منى']
        : ['All', 'System Admin', 'Ahmed', 'Mona'];

    // Action options
    final actionOptions = isAr
        ? [
            'الكل',
            'قبول سائق',
            'رفض توثيق سائق',
            'حظر مستخدم',
            'رفع الإيقاف',
            'تعديل إعداد',
            'حل نزاع وبلاغ',
            'إسناد بلاغ لموظف',
            'تعديل حالة رحلة يدوياً',
            'إضافة موظف جديد',
            'تعديل صلاحيات موظف',
          ]
        : [
            'All',
            'Approve Driver',
            'Reject Driver',
            'Ban User',
            'Lift Ban',
            'Edit Setting',
            'Resolve Dispute',
            'Assign Dispute',
            'Ride Status Override',
            'Add Staff',
            'Edit Staff Role',
          ];

    // Target options
    final targetOptions = isAr
        ? ['الكل', 'سائق', 'مستخدم', 'رحلة', 'بلاغ', 'إعداد']
        : ['All', 'Driver', 'User', 'Ride', 'Dispute', 'Setting'];

    // Date options
    final dateOptions = isAr
        ? ['الكل', 'اليوم', 'الأمس', 'آخر 7 أيام']
        : ['All', 'Today', 'Yesterday', 'Last 7 Days'];

    // Filtering logic
    final filteredLogs = admin.auditLogs.where((log) {
      if (_selectedActor != 'الكل' && _selectedActor != 'All') {
        final query = _selectedActor == 'مدير النظام' || _selectedActor == 'System Admin'
            ? 'مدير النظام'
            : _selectedActor;
        if (!log.actor.contains(query)) return false;
      }

      if (_selectedAction != 'الكل' && _selectedAction != 'All') {
        if (!log.action.contains(_selectedAction)) return false;
      }

      if (_selectedTarget != 'الكل' && _selectedTarget != 'All') {
        final matchTerm = isAr
            ? _selectedTarget
            : (_selectedTarget == 'Driver'
                ? 'سائق'
                : _selectedTarget == 'User'
                    ? 'مستخدم'
                    : _selectedTarget == 'Ride'
                        ? 'رحلة'
                        : _selectedTarget == 'Dispute'
                            ? 'بلاغ'
                            : 'إعداد');
        if (!log.target.contains(matchTerm)) return false;
      }

      return true;
    }).toList();

    final isFiltered = _selectedActor != 'الكل' ||
        _selectedAction != 'الكل' ||
        _selectedTarget != 'الكل' ||
        _selectedDate != 'الكل';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Badges Row (Page 76)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFilterDropdown(
                label: isAr ? 'الفاعل' : 'Actor',
                selectedValue: _selectedActor,
                options: actorOptions,
                onChanged: (val) => setState(() => _selectedActor = val),
              ),
              _buildFilterDropdown(
                label: isAr ? 'الإجراء' : 'Action',
                selectedValue: _selectedAction,
                options: actionOptions,
                onChanged: (val) => setState(() => _selectedAction = val),
              ),
              _buildFilterDropdown(
                label: isAr ? 'الكائن' : 'Target',
                selectedValue: _selectedTarget,
                options: targetOptions,
                onChanged: (val) => setState(() => _selectedTarget = val),
              ),
              _buildFilterDropdown(
                label: isAr ? 'التاريخ' : 'Date',
                selectedValue: _selectedDate,
                options: dateOptions,
                onChanged: (val) => setState(() => _selectedDate = val),
              ),
              if (isFiltered)
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.coral),
                  label: Text(
                    isAr ? 'إعادة ضبط الفلاتر' : 'Reset Filters',
                    style: const TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppDimens.space16),

          // Audit Table Container (Page 76)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              border: Border.all(color: AppColors.borderDisabled),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (filteredLogs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(36.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            isAr ? 'لا توجد سجلات تدقيق مطابقة للفلاتر المحددة' : 'No audit records match the selected filters',
                            style: AppTypography.body(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _resetFilters,
                            child: Text(isAr ? 'عرض كل السجلات' : 'View All Logs'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 800),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.sand),
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        columns: [
                          DataColumn(label: Text(isAr ? 'الوقت' : 'Timestamp', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isAr ? 'الفاعل' : 'Actor', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isAr ? 'الإجراء' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isAr ? 'الكائن' : 'Target Object', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isAr ? 'قبل ← بعد' : 'Before → After', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredLogs.map((log) {
                          return DataRow(
                            cells: [
                              DataCell(Text(log.time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                              DataCell(Text(log.actor, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.sand,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(log.action, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataCell(Text(log.target, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                              DataCell(Text(log.beforeAfter, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Footer Immutable Warning (Page 76)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimens.radiusCard)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        isAr
                            ? 'السجل للقراءة فقط ومحمي بالتشفير وغير قابل للتعديل أو الحذف.'
                            : 'Audit trail is append-only, tamper-proof and immutable by regulation.',
                        style: AppTypography.label(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String selectedValue,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final isSelected = selectedValue != 'الكل' && selectedValue != 'All';

    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (ctx) => options.map((opt) {
        final isItemSel = opt == selectedValue;
        return PopupMenuItem<String>(
          value: opt,
          child: Row(
            children: [
              if (isItemSel)
                const Icon(Icons.check_rounded, size: 16, color: AppColors.teal)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                opt,
                style: TextStyle(
                  fontWeight: isItemSel ? FontWeight.bold : FontWeight.normal,
                  color: isItemSel ? AppColors.navy : Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.navy : AppColors.borderDisabled),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $selectedValue',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.navy,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
