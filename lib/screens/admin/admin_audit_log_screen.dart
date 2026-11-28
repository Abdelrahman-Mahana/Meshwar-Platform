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
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String _selectedTarget = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedTarget = 'all';
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

    const targetOptions = [
      ('all', 'الكل', 'All', <String>[]),
      ('driver', 'سائق', 'Driver', ['سائق', 'driver', 'provider']),
      ('user', 'مستخدم', 'User', ['مستخدم', 'user']),
      ('ride', 'رحلة', 'Ride', ['رحلة', 'ride']),
      ('dispute', 'بلاغ', 'Dispute', ['بلاغ', 'dispute']),
      ('setting', 'إعداد', 'Setting', ['إعداد', 'setting', 'config']),
      ('escrow', 'التسوية', 'Settlement', ['escrow', 'ضمان', 'settlement', 'payment']),
      ('flag', 'Flag', 'Flag', ['flag', 'علم']),
    ];

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
      if (_selectedTarget != 'all') {
        final matchedOpt = targetOptions.firstWhere(
          (o) => o.$1 == _selectedTarget,
          orElse: () => targetOptions.first,
        );
        final targetLower = log.target.toLowerCase();
        final actionLower = log.action.toLowerCase();
        final matches = matchedOpt.$4.any(
          (term) => targetLower.contains(term) || actionLower.contains(term),
        );
        if (!matches) return false;
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
                    controller: _searchController,
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
                        label: Text(isAr ? opt.$2 : opt.$3),
                        selected: _selectedTarget == opt.$1,
                        onSelected: (_) => setState(() => _selectedTarget = opt.$1),
                      ),
                    if (_searchText.isNotEmpty || _selectedTarget != 'all')
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
