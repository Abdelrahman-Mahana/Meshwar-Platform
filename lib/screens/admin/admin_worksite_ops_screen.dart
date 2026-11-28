import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../data/models/worksite_models.dart';
import '../../data/services/firebase_firestore_service.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminWorksiteOpsScreen extends StatefulWidget {
  const AdminWorksiteOpsScreen({super.key});

  @override
  State<AdminWorksiteOpsScreen> createState() => _AdminWorksiteOpsScreenState();
}

class _AdminWorksiteOpsScreenState extends State<AdminWorksiteOpsScreen> {
  int _activeTab = 0; // 0: Providers KYC, 1: Worksite Requests & Payments, 2: Audit Trail

  final TextEditingController _providerSearchCtrl = TextEditingController();
  String _providerStatusFilter = 'all';

  final TextEditingController _requestSearchCtrl = TextEditingController();
  String _requestFilter = 'all';

  final TextEditingController _auditSearchCtrl = TextEditingController();
  bool _auditWorksiteOnly = false;

  @override
  void dispose() {
    _providerSearchCtrl.dispose();
    _requestSearchCtrl.dispose();
    _auditSearchCtrl.dispose();
    super.dispose();
  }

  void _copyValue(BuildContext context, String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  BadgeType _providerBadgeType(ProviderApprovalStatus status) {
    switch (status) {
      case ProviderApprovalStatus.approved:
        return BadgeType.verified;
      case ProviderApprovalStatus.pending:
        return BadgeType.pending;
      case ProviderApprovalStatus.rejected:
        return BadgeType.rejected;
      case ProviderApprovalStatus.suspended:
        return BadgeType.suspended;
    }
  }

  Color _paymentStatusColor(PaymentSettlementStatus status) {
    switch (status) {
      case PaymentSettlementStatus.verifiedSettled:
        return AppColors.teal;
      case PaymentSettlementStatus.transferProofSubmitted:
        return AppColors.gold;
      case PaymentSettlementStatus.disputed:
        return AppColors.coral;
      case PaymentSettlementStatus.unpaid:
        return AppColors.textSecondary;
    }
  }

  Color _requestStatusColor(WorkRequestStatus status) {
    switch (status) {
      case WorkRequestStatus.completed:
        return AppColors.teal;
      case WorkRequestStatus.disputed:
      case WorkRequestStatus.cancelled:
        return AppColors.coral;
      case WorkRequestStatus.deliveredPendingConfirmation:
        return AppColors.gold;
      default:
        return AppColors.info;
    }
  }

  void _openProviderReviewModal(
    BuildContext context,
    AdminWorksiteProviderRecord record,
    bool isAr,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProviderKycReviewDialog(record: record, isAr: isAr),
    );
  }

  void _openWorkRequestModal(
    BuildContext context,
    WorkRequest req,
    bool isAr,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WorkRequestModerationDialog(request: req, isAr: isAr),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final pendingProviders = admin.pendingVerificationsCount;
    final pendingProofs = admin.pendingPaymentProofsCount;
    final disputedCount = admin.disputedWorksiteRequestsCount;
    final activeRequests = admin.worksiteRequests
        .where((r) => !WorkRequestStatusMachine.isTerminal(r.status))
        .length;

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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'عمليات التوريد الميداني ومزودو المواقع (قطر)'
                            : 'Qatar Worksite Supply Ops & Provider KYC',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'المشروع: ${FirebaseConfig.projectId} · ${Firebase.apps.isNotEmpty ? 'متصل بـ Firebase الحي' : (admin.isDevMockMode ? 'وضع التطوير التجريبي (Dev Mock)' : 'بانتظار جلسة Firebase')} · المراجعة بالـ QID والتحقق من التحويلات'
                            : 'Project: ${FirebaseConfig.projectId} · ${Firebase.apps.isNotEmpty ? 'Firebase Live' : (admin.isDevMockMode ? 'Dev Mock Queue' : 'Firebase Session Required')} · QID 11-digit & Payment Settlement Ops',
                        style: TextStyle(color: t.textSecondary, fontSize: 12),
                      ),
                      if (admin.worksiteSyncStatus != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          admin.worksiteSyncStatus!,
                          style: TextStyle(
                            color: t.accentTeal,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: admin.isSyncingWorksiteOps
                      ? null
                      : () => admin.syncWorksiteOpsFromFirestore(),
                  icon: admin.isSyncingWorksiteOps
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_sync_rounded, size: 17),
                  label: Text(
                    isAr ? 'مزامنة السجلات' : 'Sync Firestore',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPI Strip
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 1100 ? 4 : (w >= 620 ? 2 : 1);
              final cardW = (w - (14 * (cols - 1))) / cols;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'توثيقات QID معلقة' : 'Pending QID Reviews',
                      value: '$pendingProviders',
                      deltaText: isAr
                          ? 'من أصل ${admin.worksiteProviders.length} مزود'
                          : 'of ${admin.worksiteProviders.length} providers',
                      accentColor: AppColors.gold,
                      icon: Icons.badge_rounded,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'طلبات التوريد النشطة' : 'Active Work Requests',
                      value: '$activeRequests',
                      deltaText: isAr
                          ? 'إجمالي ${admin.worksiteRequests.length} طلب'
                          : '${admin.worksiteRequests.length} total requests',
                      accentColor: t.accentPrimary,
                      icon: Icons.engineering_rounded,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr
                          ? 'تحويلات بانتظار التحقق'
                          : 'Transfers Pending Check',
                      value: '$pendingProofs',
                      deltaText: isAr ? 'إيصال تحويل مرفق' : 'Transfer Proof Attached',
                      accentColor: t.accentTeal,
                      icon: Icons.receipt_long_rounded,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'طلبات متنازع عليها' : 'Disputed Requests',
                      value: '$disputedCount',
                      deltaText: isAr ? 'تتطلب حسم إداري' : 'Admin Arbitration',
                      accentColor: AppColors.coral,
                      icon: Icons.gavel_rounded,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Sub-Tabs Bar (A: Providers KYC, B: Requests & Payments, C: Audit Trail)
          AdminSectionCard(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTabButton(
                  index: 0,
                  icon: Icons.verified_user_rounded,
                  label: isAr
                      ? 'توثيق واعتماد المزودين ($pendingProviders)'
                      : 'Provider Verifications ($pendingProviders)',
                  t: t,
                ),
                _buildTabButton(
                  index: 1,
                  icon: Icons.local_shipping_rounded,
                  label: isAr
                      ? 'طلبات التوريد والتحويلات (${admin.worksiteRequests.length})'
                      : 'Requests & Payments (${admin.worksiteRequests.length})',
                  t: t,
                ),
                _buildTabButton(
                  index: 2,
                  icon: Icons.policy_rounded,
                  label: isAr
                      ? 'سجل التدقيق المميز (${admin.auditLogs.length})'
                      : 'Privileged Audit Trail (${admin.auditLogs.length})',
                  t: t,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_activeTab == 0)
            _buildProvidersTab(context, admin, isAr, t)
          else if (_activeTab == 1)
            _buildRequestsTab(context, admin, isAr, t)
          else
            _buildAuditTab(context, admin, isAr, t),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required AdminThemeTokens t,
  }) {
    final isSel = _activeTab == index;
    return Material(
      color: isSel ? AppColors.navy : t.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSel ? AppColors.navy : t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSel ? AppColors.gold : t.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSel ? Colors.white : t.textPrimary,
                    fontSize: 12.5,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProvidersTab(
    BuildContext context,
    AdminProvider admin,
    bool isAr,
    AdminThemeTokens t,
  ) {
    final q = _providerSearchCtrl.text.trim().toLowerCase();
    final filtered = admin.worksiteProviders.where((rec) {
      final p = rec.profile;
      if (_providerStatusFilter != 'all' &&
          p.approvalStatus.value != _providerStatusFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return p.fullName.toLowerCase().contains(q) ||
          (p.qidNumber ?? '').toLowerCase().contains(q) ||
          p.phone.toLowerCase().contains(q) ||
          (p.vehiclePlate ?? '').toLowerCase().contains(q);
    }).toList();

    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: TextField(
                  controller: _providerSearchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: t.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    hintText: isAr
                        ? 'ابحث بالاسم أو QID أو اللوحة'
                        : 'Search name, QID, phone, plate',
                    filled: true,
                    fillColor: t.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: t.border),
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final st in [
                    {'k': 'all', 'ar': 'الكل', 'en': 'All'},
                    {'k': 'pending', 'ar': 'قيد المراجعة', 'en': 'Pending'},
                    {'k': 'approved', 'ar': 'معتمد', 'en': 'Approved'},
                    {'k': 'rejected', 'ar': 'مرفوض', 'en': 'Rejected'},
                    {'k': 'suspended', 'ar': 'موقوف', 'en': 'Suspended'},
                  ])
                    ChoiceChip(
                      label: Text(isAr ? st['ar']! : st['en']!),
                      selected: _providerStatusFilter == st['k'],
                      onSelected: (_) =>
                          setState(() => _providerStatusFilter = st['k']!),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminAdaptiveDataView<AdminWorksiteProviderRecord>(
            items: filtered,
            minTableWidth: 800,
            columns: [
              DataColumn(label: Text(isAr ? 'المزود' : 'Provider')),
              DataColumn(label: Text(isAr ? 'QID' : 'QID')),
              DataColumn(label: Text(isAr ? 'المركبة والمناطق' : 'Vehicle & Areas')),
              DataColumn(label: Text(isAr ? 'المستندات' : 'Docs')),
              DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
              DataColumn(label: Text(isAr ? 'إجراء' : 'Action')),
            ],
            buildRow: (rec) {
              final p = rec.profile;
              final qidValid =
                  AdminProvider.qatarQidRegex.hasMatch((p.qidNumber ?? '').trim());
              final docCount = [
                p.qidFrontUrl,
                p.qidBackUrl,
                p.selfieUrl,
                rec.vehicleLicenseUrl,
              ].where((u) => u != null && u.trim().isNotEmpty).length;

              return DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            p.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: t.textSecondary, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.qidNumber ?? '—',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          qidValid
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          size: 14,
                          color: qidValid ? t.accentTeal : AppColors.coral,
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 165),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p.vehicleType ?? '—'} · ${p.vehiclePlate ?? '—'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          Text(
                            p.serviceMunicipalities.isEmpty
                                ? '—'
                                : p.serviceMunicipalities.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: t.textSecondary, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '$docCount/4',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: docCount >= 3 ? t.accentTeal : AppColors.warning,
                      ),
                    ),
                  ),
                  DataCell(
                    MashwarBadge(
                      type: _providerBadgeType(p.approvalStatus),
                      customLabel: p.approvalStatus.label(isArabic: isAr),
                    ),
                  ),
                  DataCell(
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () =>
                          _openProviderReviewModal(context, rec, isAr),
                      child: Text(
                        isAr ? 'مراجعة' : 'Review KYC',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ),
                ],
              );
            },
            buildMobileCard: (ctx, rec) {
              final p = rec.profile;
              final qidValid =
                  AdminProvider.qatarQidRegex.hasMatch((p.qidNumber ?? '').trim());
              return Container(
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
                          child: Text(
                            p.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MashwarBadge(
                          type: _providerBadgeType(p.approvalStatus),
                          customLabel: p.approvalStatus.label(isArabic: isAr),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'QID: ${p.qidNumber ?? '—'} ${qidValid ? '✓' : '(!)'} · ${p.phone}',
                      style: TextStyle(
                        color: qidValid ? t.textSecondary : AppColors.coral,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.vehicleType ?? '—'} · ${p.vehiclePlate ?? '—'}',
                      style: TextStyle(color: t.textSecondary, fontSize: 11.5),
                    ),
                    if (p.rejectionReason != null &&
                        p.rejectionReason!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        p.rejectionReason!,
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _openProviderReviewModal(context, rec, isAr),
                        child: Text(
                          isAr ? 'مراجعة QID والمستندات' : 'Inspect QID & Decide',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(
    BuildContext context,
    AdminProvider admin,
    bool isAr,
    AdminThemeTokens t,
  ) {
    final q = _requestSearchCtrl.text.trim().toLowerCase();
    final filtered = admin.worksiteRequests.where((r) {
      if (_requestFilter == 'proof_pending' &&
          r.paymentSettlementStatus !=
              PaymentSettlementStatus.transferProofSubmitted) {
        return false;
      } else if (_requestFilter == 'disputed' &&
          r.status != WorkRequestStatus.disputed) {
        return false;
      } else if (_requestFilter == 'completed' &&
          r.status != WorkRequestStatus.completed) {
        return false;
      } else if (_requestFilter == 'active' &&
          WorkRequestStatusMachine.isTerminal(r.status)) {
        return false;
      }
      if (q.isEmpty) return true;
      return r.id.toLowerCase().contains(q) ||
          r.title.toLowerCase().contains(q) ||
          r.requesterName.toLowerCase().contains(q) ||
          r.municipality.toLowerCase().contains(q) ||
          (r.paymentReference ?? '').toLowerCase().contains(q);
    }).toList();

    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: TextField(
                  controller: _requestSearchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: t.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    hintText: isAr
                        ? 'ابحث بالمعرف، العنوان، البلدية، أو المرجع'
                        : 'Search ID, title, area, or tx ref',
                    filled: true,
                    fillColor: t.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: t.border),
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final f in [
                    {'k': 'all', 'ar': 'الكل', 'en': 'All'},
                    {'k': 'proof_pending', 'ar': 'تحقق تحويل', 'en': 'Proof Pending'},
                    {'k': 'disputed', 'ar': 'متنازع عليه', 'en': 'Disputed'},
                    {'k': 'active', 'ar': 'نشط', 'en': 'Active'},
                    {'k': 'completed', 'ar': 'مكتمل', 'en': 'Completed'},
                  ])
                    ChoiceChip(
                      label: Text(isAr ? f['ar']! : f['en']!),
                      selected: _requestFilter == f['k'],
                      onSelected: (_) =>
                          setState(() => _requestFilter = f['k']!),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminAdaptiveDataView<WorkRequest>(
            items: filtered,
            minTableWidth: 820,
            columns: [
              DataColumn(label: Text(isAr ? 'الطلب والموقع' : 'Request & Site')),
              DataColumn(label: Text(isAr ? 'الأطراف' : 'Parties')),
              DataColumn(label: Text(isAr ? 'الإجمالي' : 'Total')),
              DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
              DataColumn(label: Text(isAr ? 'السداد' : 'Payment')),
              DataColumn(label: Text(isAr ? 'إدارة' : 'Action')),
            ],
            buildRow: (req) {
              final stColor = _requestStatusColor(req.status);
              final payColor = _paymentStatusColor(req.paymentSettlementStatus);
              return DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${req.id} · ${req.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            req.municipality,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: t.textSecondary, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 145),
                      child: Text(
                        '${req.requesterName}\n→ ${req.assignedProviderName ?? (isAr ? 'بانتظار عرض' : 'Unassigned')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      req.effectiveTotalMinor.format(isArabic: isAr),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: stColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        req.status.label(isArabic: isAr),
                        style: TextStyle(
                          color: stColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: payColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            req.paymentSettlementStatus.label(isArabic: isAr),
                            style: TextStyle(
                              color: payColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (req.paymentReference != null &&
                            req.paymentReference!.isNotEmpty)
                          Text(
                            req.paymentReference!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DataCell(
                    OutlinedButton(
                      onPressed: () => _openWorkRequestModal(context, req, isAr),
                      child: Text(
                        isAr ? 'مراجعة / سداد' : 'Inspect',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              );
            },
            buildMobileCard: (ctx, req) {
              final stColor = _requestStatusColor(req.status);
              final payColor = _paymentStatusColor(req.paymentSettlementStatus);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: req.status == WorkRequestStatus.disputed
                        ? AppColors.coral
                        : t.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            req.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: stColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            req.status.label(isArabic: isAr),
                            style: TextStyle(
                              color: stColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      req.title,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${req.municipality} · ${req.effectiveTotalMinor.format(isArabic: isAr)}',
                      style: TextStyle(color: t.textSecondary, fontSize: 11.5),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: payColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            req.paymentSettlementStatus.label(isArabic: isAr),
                            style: TextStyle(
                              color: payColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (req.paymentReference != null &&
                            req.paymentReference!.isNotEmpty)
                          Text(
                            'Ref: ${req.paymentReference}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _openWorkRequestModal(context, req, isAr),
                        child: Text(
                          isAr ? 'مراجعة الطلب والسداد' : 'Moderate & Verify',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab(
    BuildContext context,
    AdminProvider admin,
    bool isAr,
    AdminThemeTokens t,
  ) {
    final q = _auditSearchCtrl.text.trim().toLowerCase();
    final filtered = admin.auditLogs.where((log) {
      if (_auditWorksiteOnly) {
        final combined = '${log.action} ${log.target}'.toLowerCase();
        if (!combined.contains('provider_profiles') &&
            !combined.contains('work_requests') &&
            !combined.contains('admin_staff') &&
            !combined.contains('provider_review') &&
            !combined.contains('payment') &&
            !combined.contains('moderate_')) {
          return false;
        }
      }
      if (q.isEmpty) return true;
      return log.actor.toLowerCase().contains(q) ||
          log.action.toLowerCase().contains(q) ||
          log.target.toLowerCase().contains(q) ||
          log.beforeAfter.toLowerCase().contains(q);
    }).toList();

    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: TextField(
                  controller: _auditSearchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: t.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    hintText: isAr
                        ? 'بحث في سجل التدقيق المميز...'
                        : 'Search privileged audit trail...',
                    filled: true,
                    fillColor: t.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: t.border),
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: Text(
                      isAr ? 'عمليات التوريد والمصادقة فقط' : 'Worksite & Auth Only',
                    ),
                    selected: _auditWorksiteOnly,
                    onSelected: (v) => setState(() => _auditWorksiteOnly = v),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final payload = const JsonEncoder.withIndent('  ')
                          .convert(filtered.map((e) => e.toJson()).toList());
                      _copyValue(
                        context,
                        payload,
                        isAr
                            ? 'تم تصدير ${filtered.length} سجل تدقيق بصيغة JSON'
                            : 'Exported ${filtered.length} audit logs as JSON',
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text(
                      isAr ? 'تصدير JSON' : 'Export JSON',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminAdaptiveDataView<AdminAuditLogEntry>(
            items: filtered,
            minTableWidth: 880,
            columns: [
              DataColumn(label: Text(isAr ? 'الوقت' : 'Time')),
              DataColumn(label: Text(isAr ? 'المنفذ الإداري' : 'Actor')),
              DataColumn(label: Text(isAr ? 'الإجراء' : 'Action')),
              DataColumn(label: Text(isAr ? 'الهدف' : 'Target')),
              DataColumn(label: Text(isAr ? 'التغيير' : 'Before -> After')),
            ],
            buildRow: (log) => DataRow(
              cells: [
                DataCell(Text(log.time, style: const TextStyle(fontSize: 11.5))),
                DataCell(Text(log.actor, style: const TextStyle(fontSize: 12))),
                DataCell(
                  Text(
                    log.action,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    log.target,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
                  ),
                ),
                DataCell(
                  Text(
                    log.beforeAfter,
                    style: TextStyle(
                      color: t.accentTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
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
                      Expanded(
                        child: Text(
                          log.action,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        log.time,
                        style: TextStyle(color: t.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${log.actor} · ${log.target}',
                    style: TextStyle(color: t.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.beforeAfter,
                    style: TextStyle(
                      color: t.accentTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
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

class _ProviderKycReviewDialog extends StatefulWidget {
  final AdminWorksiteProviderRecord record;
  final bool isAr;

  const _ProviderKycReviewDialog({
    required this.record,
    required this.isAr,
  });

  @override
  State<_ProviderKycReviewDialog> createState() =>
      _ProviderKycReviewDialogState();
}

class _ProviderKycReviewDialogState extends State<_ProviderKycReviewDialog> {
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _validationError;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDecision(ProviderApprovalStatus decision) async {
    final reason = _reasonCtrl.text.trim();
    if ((decision == ProviderApprovalStatus.rejected ||
            decision == ProviderApprovalStatus.suspended) &&
        reason.isEmpty) {
      setState(() {
        _validationError = widget.isAr
            ? 'يرجى كتابة سبب واضح للرفض أو الإيقاف (إلزامي).'
            : 'Mandatory reason is required when rejecting or suspending.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _validationError = null;
    });

    final admin = context.read<AdminProvider>();
    final ok = await admin.reviewWorksiteProvider(
      userId: widget.record.profile.userId,
      decision: decision,
      reason: reason.isEmpty ? null : reason,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _validationError = admin.worksiteActionError ??
            (widget.isAr ? 'تعذر حفظ القرار' : 'Failed to submit decision');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.record.profile;
    final isAr = widget.isAr;
    final qidValid =
        AdminProvider.qatarQidRegex.hasMatch((p.qidNumber ?? '').trim());

    final docs = <MapEntry<String, String?>>[
      MapEntry(isAr ? 'QID الوجه الأمامي' : 'QID Front URL', p.qidFrontUrl),
      MapEntry(isAr ? 'QID الوجه الخلفي' : 'QID Back URL', p.qidBackUrl),
      MapEntry(isAr ? 'صورة السيلفي' : 'Live Selfie URL', p.selfieUrl),
      MapEntry(
        isAr ? 'رخصة المركبة / الاستمارة' : 'Vehicle License URL',
        widget.record.vehicleLicenseUrl,
      ),
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${p.fullName} · ${p.approvalStatus.label(isArabic: isAr)}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(isAr ? 'معرف المزود' : 'Provider UID', p.userId),
                _detailRow(isAr ? 'الهاتف' : 'Phone', p.phone),
                _detailRow(
                  isAr ? 'البطاقة القطرية QID' : 'QID (11 digits)',
                  '${p.qidNumber ?? '—'} (${qidValid ? (isAr ? 'صالح 11 خانة' : 'Valid 11-digit') : (isAr ? 'غير مكتمل' : 'Invalid format')})',
                ),
                _detailRow(
                  isAr ? 'المركبة واللوحة' : 'Vehicle & Plate',
                  '${p.vehicleType ?? '—'} · ${p.vehiclePlate ?? '—'}',
                ),
                _detailRow(
                  isAr ? 'نطاق البلديات' : 'Municipalities',
                  p.serviceMunicipalities.isEmpty
                      ? '—'
                      : p.serviceMunicipalities.join('، '),
                ),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'روابط مستندات التحقق (KYC):' : 'KYC Document URLs:',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                for (final doc in docs)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AdminThemeTokens.of(context).surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminThemeTokens.of(context).border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              ),
                              Text(
                                doc.value ?? (isAr ? 'غير مرفق' : 'Not provided'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (doc.value != null && doc.value!.isNotEmpty)
                          IconButton(
                            tooltip: isAr ? 'نسخ الرابط' : 'Copy URL',
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: doc.value!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr ? 'تم نسخ رابط المستند' : 'Copied document URL',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isAr
                        ? 'سبب الرفض أو الإيقاف (إلزامي للرفض/الإيقاف)'
                        : 'Rejection / Suspension Reason (Mandatory for reject/suspend)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (_validationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _validationError!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(isAr ? 'إغلاق' : 'Close'),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning),
          onPressed: _submitting
              ? null
              : () => _submitDecision(ProviderApprovalStatus.suspended),
          child: Text(isAr ? 'إيقاف' : 'Suspend'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
          ),
          onPressed: _submitting
              ? null
              : () => _submitDecision(ProviderApprovalStatus.rejected),
          child: Text(isAr ? 'رفض' : 'Reject'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _submitting
              ? null
              : () => _submitDecision(ProviderApprovalStatus.approved),
          child: Text(isAr ? 'اعتماد المزود' : 'Approve'),
        ),
      ],
    );
  }

  Widget _detailRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              k,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkRequestModerationDialog extends StatefulWidget {
  final WorkRequest request;
  final bool isAr;

  const _WorkRequestModerationDialog({
    required this.request,
    required this.isAr,
  });

  @override
  State<_WorkRequestModerationDialog> createState() =>
      _WorkRequestModerationDialogState();
}

class _WorkRequestModerationDialogState
    extends State<_WorkRequestModerationDialog> {
  final TextEditingController _txRefCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  WorkRequestStatus _disputeTarget = WorkRequestStatus.inTransit;
  bool _submitting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _txRefCtrl.text = widget.request.paymentReference ?? '';
  }

  @override
  void dispose() {
    _txRefCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyPayment() async {
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });
    final admin = context.read<AdminProvider>();
    final ok = await admin.verifyWorksitePaymentSettlement(
      requestId: widget.request.id,
      transactionReference: _txRefCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _errorMsg = admin.worksiteActionError);
    }
  }

  Future<void> _moderateDispute(String action, {WorkRequestStatus? target}) async {
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });
    final admin = context.read<AdminProvider>();
    final ok = await admin.moderateWorksiteRequestDispute(
      requestId: widget.request.id,
      action: action,
      targetStatus: target,
      reason: _reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _errorMsg = admin.worksiteActionError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isAr = widget.isAr;
    final canVerifyTransfer = req.paymentSettlementStatus ==
        PaymentSettlementStatus.transferProofSubmitted;
    final canFlagDispute = WorkRequestStatusMachine.canTransition(
      req.status,
      WorkRequestStatus.disputed,
      actorRole: 'admin',
    );
    final isDisputed = req.status == WorkRequestStatus.disputed;
    final canCancel = WorkRequestStatusMachine.canTransition(
      req.status,
      WorkRequestStatus.cancelled,
      actorRole: 'admin',
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${req.id} · ${req.status.label(isArabic: isAr)}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _kv(isAr ? 'الطالب' : 'Requester', req.requesterName),
                _kv(
                  isAr ? 'المزود المعيّن' : 'Assigned Provider',
                  req.assignedProviderName ?? '—',
                ),
                _kv(isAr ? 'الاستلام' : 'Pickup', req.pickupLocation),
                _kv(isAr ? 'الموقع' : 'Dropoff Worksite', req.dropoffWorksite),
                _kv(
                  isAr ? 'الإجمالي الفعلي' : 'Effective Total',
                  req.effectiveTotalMinor.format(isArabic: isAr),
                ),
                _kv(
                  isAr ? 'طريقة الدفع' : 'Payment Method',
                  req.paymentMethod.label(isArabic: isAr),
                ),
                _kv(
                  isAr ? 'حالة التسوية' : 'Settlement Status',
                  req.paymentSettlementStatus.label(isArabic: isAr),
                ),
                if (req.paymentProofUrl != null &&
                    req.paymentProofUrl!.isNotEmpty)
                  _kv(isAr ? 'إيصال التحويل' : 'Transfer Proof', req.paymentProofUrl!),
                if (req.disputeReason != null && req.disputeReason!.isNotEmpty)
                  _kv(isAr ? 'سبب النزاع' : 'Dispute Reason', req.disputeReason!),
                const Divider(height: 20),

                // Pilot Manual Transfer Verification Section
                Text(
                  isAr
                      ? 'التحقق من السداد والمرجع البنكي:'
                      : 'Pilot Payment Settlement Verification:',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                if (req.paymentSettlementStatus ==
                    PaymentSettlementStatus.verifiedSettled)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.tealSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.teal),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.teal,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'تم التحقق والتسوية (غير قابل للتعديل) · مرجع: ${req.paymentReference ?? '—'}'
                                : 'Verified & Settled (Immutable) · Ref: ${req.paymentReference ?? '—'}',
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  TextField(
                    controller: _txRefCtrl,
                    enabled: canVerifyTransfer && !_submitting,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'رقم المرجع البنكي للتحويل (مطلوب للتحقق)'
                          : 'Bank Transfer Transaction Reference',
                      hintText: 'QNB-2026-XXXXX',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        canVerifyTransfer && !_submitting ? _verifyPayment : null,
                    icon: const Icon(Icons.verified_rounded, size: 16),
                    label: Text(
                      isAr
                          ? 'تأكيد التحويل ← verified_settled'
                          : 'Verify Transfer -> verified_settled',
                    ),
                  ),
                ],
                const Divider(height: 20),

                // Dispute / Cancellation Moderation
                Text(
                  isAr ? 'إدارة النزاعات والحالة:' : 'Dispute & Status Moderation:',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                if (isDisputed) ...[
                  DropdownButtonFormField<WorkRequestStatus>(
                    initialValue: _disputeTarget,
                    decoration: InputDecoration(
                      labelText:
                          isAr ? 'حالة الحسم المستهدفة' : 'Resolution Target Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      WorkRequestStatus.inTransit,
                      WorkRequestStatus.completed,
                      WorkRequestStatus.cancelled,
                    ]
                        .map(
                          (st) => DropdownMenuItem(
                            value: st,
                            child: Text(st.label(isArabic: isAr)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _disputeTarget = v);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isAr
                        ? 'سبب النزاع / الحسم / الإلغاء (إلزامي)'
                        : 'Dispute / Resolution / Cancellation Reason',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canFlagDispute)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submitting
                            ? null
                            : () => _moderateDispute('flag_dispute'),
                        child: Text(isAr ? 'تحويل لنزاع' : 'Flag Disputed'),
                      ),
                    if (isDisputed)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submitting
                            ? null
                            : () => _moderateDispute(
                                  'resolve_dispute',
                                  target: _disputeTarget,
                                ),
                        child: Text(isAr ? 'حسم النزاع' : 'Resolve Dispute'),
                      ),
                    if (canCancel && !isDisputed)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coral,
                        ),
                        onPressed: _submitting
                            ? null
                            : () => _moderateDispute('cancel'),
                        child: Text(isAr ? 'إلغاء الطلب' : 'Cancel Request'),
                      ),
                  ],
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMsg!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(isAr ? 'إغلاق' : 'Close'),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              k,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
