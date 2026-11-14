import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  String _selectedStatus = 'الكل';

  void _openDisputeDetails(BuildContext context, AdminDisputeItem dispute) {
    showDialog(
      context: context,
      builder: (ctx) => _DisputeDetailModal(dispute: dispute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();

    final filteredDisputes = admin.disputes.where((d) {
      if (_selectedStatus == 'الكل' || _selectedStatus == 'All') return true;
      if (isAr) {
        return d.status == _selectedStatus;
      } else {
        if (_selectedStatus == 'Open') return d.status == 'مفتوح';
        if (_selectedStatus == 'Under Review') return d.status == 'قيد المراجعة';
        if (_selectedStatus == 'Resolved') return d.status == 'محلول';
        return true;
      }
    }).toList();

    final statusFilters = isAr
        ? ['الكل', 'مفتوح', 'قيد المراجعة', 'محلول']
        : ['All', 'Open', 'Under Review', 'Resolved'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips (Page 74 - Responsive Wrap)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                isAr ? 'تصفية حسب الحالة:' : 'Filter by status:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navy),
              ),
              for (final s in statusFilters) ...[
                ChoiceChip(
                  label: Text(s),
                  selected: _selectedStatus == s,
                  selectedColor: AppColors.navy,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: _selectedStatus == s ? AppColors.navy : AppColors.borderDisabled),
                  labelStyle: TextStyle(
                    color: _selectedStatus == s ? Colors.white : AppColors.navy,
                    fontWeight: _selectedStatus == s ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedStatus = s),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppDimens.space16),

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
                    DataColumn(label: Text(isAr ? 'الرقم' : 'ID', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'النوع' : 'Type', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'الفئة' : 'Category', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'المُبلِّغ' : 'Complainant', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'المسؤول' : 'Assignee', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(isAr ? 'الإجراء' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredDisputes.map((d) {
                    BadgeType bType;
                    if (d.status == 'مفتوح') {
                      bType = BadgeType.rejected;
                    } else if (d.status == 'قيد المراجعة') {
                      bType = BadgeType.pending;
                    } else {
                      bType = BadgeType.verified;
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(d.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(d.type)),
                        DataCell(Text(d.category, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(d.complainantName)),
                        DataCell(MashwarBadge(type: bType, customLabel: d.status)),
                        DataCell(Text(d.assignedTo ?? '—')),
                        DataCell(
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: d.status == 'مفتوح' ? AppColors.navy : AppColors.sand,
                              foregroundColor: d.status == 'مفتوح' ? Colors.white : AppColors.navy,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openDisputeDetails(context, d),
                            child: Text(
                              d.status == 'مفتوح' ? (isAr ? 'فتح' : 'Open') : (isAr ? 'عرض' : 'View'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dispute Detail & Action Modal (Page 74)
class _DisputeDetailModal extends StatefulWidget {
  final AdminDisputeItem dispute;
  const _DisputeDetailModal({required this.dispute});

  @override
  State<_DisputeDetailModal> createState() => _DisputeDetailModalState();
}

class _DisputeDetailModalState extends State<_DisputeDetailModal> {
  String _selectedDecision = 'حل وتعويض';
  final TextEditingController _noteController = TextEditingController(text: 'الصور تؤكد التلف الجزئي، تم تعويض القيمة.');

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.read<AdminProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.all(AppDimens.space24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    '${widget.dispute.id}: ${widget.dispute.category}',
                    style: AppTypography.title().copyWith(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  MashwarBadge(
                    type: widget.dispute.status == 'مفتوح' ? BadgeType.rejected : BadgeType.verified,
                    customLabel: widget.dispute.status,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Parties details
              _buildRow(isAr ? 'المُبلِّغ' : 'Complainant', widget.dispute.complainantName),
              const SizedBox(height: 8),
              _buildRow(isAr ? 'الطرف المشكو' : 'Against', widget.dispute.againstName),
              const SizedBox(height: 8),
              _buildRow(isAr ? 'تفاصيل الطلب' : 'Details', widget.dispute.parcelOrRideDetails),

              const SizedBox(height: AppDimens.space16),

              // Timeline (Page 74 - خط الزمن)
              Text(
                isAr ? 'خط الزمن للعملية:' : 'Incident Timeline:',
                style: AppTypography.label().copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.dispute.timeline.map((step) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppColors.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(step, style: const TextStyle(fontSize: 12, height: 1.4)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppDimens.space20),

              // Resolution Decisions (Page 74)
              Text(
                isAr ? 'اتخاذ القرار الإداري:' : 'Administrative Decision:',
                style: AppTypography.label().copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'تحذير السائق',
                  'إيقاف مؤقت',
                  'رفض البلاغ',
                  'حل وتعويض',
                ].map((decision) {
                  final isSel = _selectedDecision == decision;
                  return ChoiceChip(
                    label: Text(decision),
                    selected: isSel,
                    selectedColor: decision == 'حل وتعويض' ? AppColors.teal : AppColors.navy,
                    backgroundColor: AppColors.sand,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    onSelected: (_) => setState(() => _selectedDecision = decision),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isAr ? 'ملاحظة القرار الداخلية' : 'Internal Decision Note',
                  filled: true,
                  fillColor: AppColors.sand,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: AppDimens.space20),

              // Actions: حفظ القرار ونشره / تعيين لموظف (Page 74)
              Row(
                children: [
                  Expanded(
                    child: MashwarButton(
                      text: isAr ? 'حفظ القرار ونشره' : 'Save & Publish Decision',
                      onPressed: () {
                        admin.resolveDispute(widget.dispute.id, _selectedDecision, _noteController.text.trim());
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isAr ? 'تم اعتماد القرار وإبلاغ الأطراف' : 'Decision saved and dispatched to parties'),
                            backgroundColor: AppColors.teal,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.navy),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: () => _showAssignStaffDialog(context, admin, isAr),
                    child: Text(isAr ? 'تعيين لموظف' : 'Assign to Staff', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignStaffDialog(BuildContext context, AdminProvider admin, bool isAr) {
    String? selectedStaffName = admin.staff.isNotEmpty ? admin.staff.first.name : null;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
              title: Text(isAr ? 'إسناد البلاغ لموظف' : 'Assign Dispute to Staff'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr
                        ? 'اختر عضو فريق الدعم أو المراجعة المسؤول عن متابعة البلاغ واتخاذ الإجراء:'
                        : 'Select the support/review team member responsible for this dispute:',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStaffName,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الموظف المسؤول' : 'Staff Member',
                      filled: true,
                      fillColor: AppColors.sand,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: admin.staff.map((member) {
                      final roleDesc = isAr ? member.roleTitleAr : member.roleTitleEn;
                      return DropdownMenuItem<String>(
                        value: member.name,
                        child: Text('${member.name} ($roleDesc)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedStaffName = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: selectedStaffName == null
                      ? null
                      : () {
                          admin.assignDispute(widget.dispute.id, selectedStaffName!);
                          Navigator.of(dialogCtx).pop(); // close assign dialog
                          Navigator.of(context).pop();   // close dispute detail modal
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isAr
                                    ? 'تم إسناد البلاغ بنجاح إلى $selectedStaffName'
                                    : 'Dispute successfully assigned to $selectedStaffName',
                              ),
                              backgroundColor: AppColors.teal,
                            ),
                          );
                        },
                  child: Text(isAr ? 'تأكيد الإسناد' : 'Confirm Assignment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy)),
      ],
    );
  }
}
