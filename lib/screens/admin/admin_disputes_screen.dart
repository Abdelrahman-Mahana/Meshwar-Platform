import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  String _selectedStatus = 'all';

  void _openDisputeDetails(BuildContext context, AdminDisputeItem dispute) {
    showDialog(
      context: context,
      builder: (_) => _DisputeDetailModal(dispute: dispute),
    );
  }

  String _localizeDisputeStatus(String raw, bool isAr) {
    if (isAr) return raw;
    switch (raw.trim()) {
      case 'مفتوح':
        return 'Open';
      case 'قيد المراجعة':
        return 'Under Review';
      case 'محلول':
        return 'Resolved';
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final filteredDisputes = admin.disputes.where((d) {
      if (_selectedStatus == 'all') return true;
      if (_selectedStatus == 'sos') return d.isSosPriority;
      if (_selectedStatus == 'open') {
        return d.status == 'مفتوح' || d.status.toLowerCase() == 'open';
      }
      if (_selectedStatus == 'under_review') {
        return d.status == 'قيد المراجعة' || d.status.toLowerCase() == 'underreview';
      }
      if (_selectedStatus == 'resolved') {
        return d.status == 'محلول' || d.status.toLowerCase() == 'resolved';
      }
      return true;
    }).toList();

    const statusFilters = [
      ('all', 'الكل', 'All'),
      ('sos', 'SOS 999', 'SOS 999'),
      ('open', 'مفتوح', 'Open'),
      ('under_review', 'قيد المراجعة', 'Under Review'),
      ('resolved', 'محلول', 'Resolved'),
    ];

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                isAr ? 'تصفية البلاغات والـ SOS:' : 'Filter Disputes & SOS:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: t.textPrimary),
              ),
              for (final s in statusFilters)
                ChoiceChip(
                  label: Text(isAr ? s.$2 : s.$3),
                  selected: _selectedStatus == s.$1,
                  onSelected: (_) => setState(() => _selectedStatus = s.$1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AdminSectionCard(
            padding: const EdgeInsets.all(14),
            child: AdminAdaptiveDataView<AdminDisputeItem>(
              items: filteredDisputes,
              minTableWidth: 880,
              columns: [
                DataColumn(label: Text(isAr ? 'الرقم' : 'ID')),
                DataColumn(label: Text(isAr ? 'الأولوية / الضمان' : 'Priority / Escrow')),
                DataColumn(label: Text(isAr ? 'الفئة' : 'Category')),
                DataColumn(label: Text(isAr ? 'المُبلِّغ' : 'Complainant')),
                DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
                DataColumn(label: Text(isAr ? 'المسؤول' : 'Assignee')),
                DataColumn(label: Text(isAr ? 'الإجراء' : 'Action')),
              ],
              buildRow: (d) {
                final bType = d.status == 'مفتوح'
                    ? BadgeType.rejected
                    : (d.status == 'قيد المراجعة' ? BadgeType.pending : BadgeType.verified);
                return DataRow(
                  cells: [
                    DataCell(Text(d.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      Wrap(
                        spacing: 4,
                        children: [
                          if (d.isSosPriority)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(6)),
                              child: const Text('SOS 999', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          if (d.linkedEscrowId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
                              child: Text(d.linkedEscrowId!, style: TextStyle(color: t.accentTeal, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          if (!d.isSosPriority && d.linkedEscrowId == null) Text(d.type),
                        ],
                      ),
                    ),
                    DataCell(Text(d.category, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(d.complainantName)),
                    DataCell(MashwarBadge(type: bType, customLabel: _localizeDisputeStatus(d.status, isAr))),
                    DataCell(Text(d.assignedTo ?? '—')),
                    DataCell(
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: d.status == 'مفتوح' ? AppColors.navy : t.surfaceMuted,
                          foregroundColor: d.status == 'مفتوح' ? Colors.white : t.textPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _openDisputeDetails(context, d),
                        child: Text(
                          d.status == 'مفتوح' ? (isAr ? 'حسم' : 'Resolve') : (isAr ? 'عرض' : 'View'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
              buildMobileCard: (ctx, d) {
                final bType = d.status == 'مفتوح'
                    ? BadgeType.rejected
                    : (d.status == 'قيد المراجعة' ? BadgeType.pending : BadgeType.verified);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: d.isSosPriority ? AppColors.coral : t.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${d.id} · ${d.category}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          MashwarBadge(type: bType, customLabel: d.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${d.complainantName} -> ${d.againstName}', style: TextStyle(color: t.textSecondary, fontSize: 12)),
                      if (d.linkedEscrowId != null)
                        Text('Escrow: ${d.linkedEscrowId}', style: TextStyle(color: t.accentTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                          onPressed: () => _openDisputeDetails(context, d),
                          child: Text(isAr ? 'فتح التحكيم' : 'Open Arbitration', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeDetailModal extends StatefulWidget {
  final AdminDisputeItem dispute;
  const _DisputeDetailModal({required this.dispute});

  @override
  State<_DisputeDetailModal> createState() => _DisputeDetailModalState();
}

class _DisputeDetailModalState extends State<_DisputeDetailModal> {
  static const List<(String ar, String en)> _decisions = [
    ('تحذير السائق', 'Warn Driver'),
    ('إيقاف مؤقت', 'Temporary Suspension'),
    ('رفض البلاغ', 'Dismiss Report'),
    ('حل وتعويض', 'Resolve & Compensate'),
  ];

  String _selectedDecision = 'حل وتعويض';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.read<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.all(AppDimens.space20),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: t.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.dispute.id}: ${widget.dispute.category}',
                      style: AppTypography.title(color: t.textPrimary).copyWith(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    tooltip: isAr ? 'إغلاق' : 'Close',
                    icon: Icon(Icons.close_rounded, color: t.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 18),
              _row(t, isAr ? 'المُبلِّغ' : 'Complainant', widget.dispute.complainantName),
              _row(t, isAr ? 'الطرف المشكو' : 'Against', widget.dispute.againstName),
              _row(t, isAr ? 'التفاصيل' : 'Details', widget.dispute.parcelOrRideDetails),
              if (widget.dispute.linkedEscrowId != null)
                _row(t, isAr ? 'المرجع المرتبط' : 'Linked Reference', widget.dispute.linkedEscrowId!),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.dispute.timeline
                      .map((step) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text('• $step', style: TextStyle(fontSize: 12, color: t.textPrimary)),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _decisions.map((decision) {
                  final isSel = _selectedDecision == decision.$1;
                  return ChoiceChip(
                    label: Text(isAr ? decision.$1 : decision.$2),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedDecision = decision.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isAr ? 'ملاحظة القرار' : 'Decision Note',
                  hintText: isAr
                      ? 'اكتب تفاصيل القرار والمراجعة الموثّقة...'
                      : 'Enter documented arbitration notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MashwarButton(
                      text: isAr ? 'حفظ القرار ونشره' : 'Save & Publish',
                      onPressed: () {
                        admin.resolveDispute(widget.dispute.id, _selectedDecision, _noteController.text.trim());
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      final staffName = admin.staff.isNotEmpty ? admin.staff.first.name : (isAr ? 'مدير الدعم' : 'Support Lead');
                      admin.assignDispute(widget.dispute.id, staffName);
                      Navigator.of(context).pop();
                    },
                    child: Text(isAr ? 'تعيين لموظف' : 'Assign'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(AdminThemeTokens t, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: t.textSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
