import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  String _searchText = '';
  String _selectedTarget = 'الكل';

  void _resetFilters() {
    setState(() {
      _searchText = '';
      _selectedTarget = 'الكل';
    });
  }

  void _copyAuditJson(BuildContext context, List<AdminAuditLogEntry> logs, bool isAr) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(logs.map((l) => l.toJson()).toList());
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم نسخ ${logs.length} سجل تدقيق بصيغة JSON' : 'Copied ${logs.length} audit records as JSON'),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final targetOptions = isAr
        ? ['الكل', 'سائق', 'مستخدم', 'رحلة', 'بلاغ', 'إعداد', 'Escrow', 'Flag']
        : ['All', 'Driver', 'User', 'Ride', 'Dispute', 'Setting', 'Escrow', 'Flag'];

    final filteredLogs = admin.auditLogs.where((log) {
      if (_searchText.isNotEmpty) {
        final q = _searchText.toLowerCase();
        if (!log.actor.toLowerCase().contains(q) &&
            !log.action.toLowerCase().contains(q) &&
            !log.target.toLowerCase().contains(q) &&
            !log.beforeAfter.toLowerCase().contains(q)) {
          return false;
        }
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
                            : _selectedTarget);
        if (!log.target.toLowerCase().contains(matchTerm.toLowerCase()) &&
            !log.action.toLowerCase().contains(matchTerm.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    style: TextStyle(color: t.textPrimary, fontSize: 13),
                    onChanged: (v) => setState(() => _searchText = v.trim()),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: isAr ? 'بحث في الأحداث، الفاعل، أو القيمة...' : 'Search audit events, actor, or diff...',
                      hintStyle: TextStyle(color: t.textSecondary, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: t.accentPrimary),
                      filled: true,
                      fillColor: t.surfaceAlt,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final opt in targetOptions)
                      ChoiceChip(
                        label: Text(opt),
                        selected: _selectedTarget == opt,
                        onSelected: (_) => setState(() => _selectedTarget = opt),
                      ),
                    if (_searchText.isNotEmpty || _selectedTarget != 'الكل')
                      TextButton(onPressed: _resetFilters, child: Text(isAr ? 'إعادة ضبط' : 'Reset')),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_all_rounded, size: 16),
                      label: Text(isAr ? 'نسخ JSON' : 'Export JSON', style: const TextStyle(fontSize: 12)),
                      onPressed: () => _copyAuditJson(context, filteredLogs, isAr),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminSectionCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminAdaptiveDataView<AdminAuditLogEntry>(
                  items: filteredLogs,
                  minTableWidth: 860,
                  columns: [
                    DataColumn(label: Text(isAr ? 'الوقت' : 'Time')),
                    DataColumn(label: Text(isAr ? 'الفاعل' : 'Actor')),
                    DataColumn(label: Text(isAr ? 'الإجراء' : 'Action')),
                    DataColumn(label: Text(isAr ? 'الكائن' : 'Target')),
                    DataColumn(label: Text(isAr ? 'قبل ← بعد' : 'Before -> After')),
                  ],
                  buildRow: (log) => DataRow(
                    cells: [
                      DataCell(Text(log.time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataCell(Text(log.actor, style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.border),
                          ),
                          child: Text(log.action, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: t.textPrimary)),
                        ),
                      ),
                      DataCell(Text(log.target, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                      DataCell(Text(log.beforeAfter, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    ],
                  ),
                  buildMobileCard: (ctx, log) => Container(
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
                            Expanded(child: Text(log.action, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 13))),
                            Text(log.time, style: TextStyle(color: t.textSecondary, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${log.actor} · ${log.target}', style: TextStyle(color: t.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(log.beforeAfter, style: TextStyle(color: t.accentTeal, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 16, color: t.textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isAr
                              ? 'السجل للقراءة فقط ومحمي بالتشفير وغير قابل للتعديل أو الحذف (Append-Only).'
                              : 'Audit trail is append-only, tamper-proof and immutable by regulation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: t.textSecondary, fontSize: 11),
                        ),
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
}
