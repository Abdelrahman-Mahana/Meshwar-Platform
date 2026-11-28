import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/admin_platform_models.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminEscrowFinanceScreen extends StatefulWidget {
  const AdminEscrowFinanceScreen({super.key});

  @override
  State<AdminEscrowFinanceScreen> createState() =>
      _AdminEscrowFinanceScreenState();
}

class _AdminEscrowFinanceScreenState extends State<AdminEscrowFinanceScreen> {
  String _statusFilter = 'all';

  Color _escrowColor(String st) {
    switch (st) {
      case 'released':
        return AppColors.teal;
      case 'frozen':
      case 'refunded':
        return AppColors.coral;
      case 'receipt_pending':
        return AppColors.gold;
      default:
        return AppColors.info;
    }
  }

  String _escrowLabel(String st, bool isAr) {
    switch (st) {
      case 'released':
        return isAr ? 'تم التحرير للمنفذ' : 'Released';
      case 'frozen':
        return isAr ? 'مجمد للنزاع' : 'Frozen';
      case 'refunded':
        return isAr ? 'مسترد للطالب' : 'Refunded';
      case 'receipt_pending':
        return isAr ? 'مراجعة الفاتورة' : 'Receipt Review';
      case 'in_transit':
        return isAr ? 'بالطريق (OTP)' : 'In Transit';
      default:
        return isAr ? 'محجوز بالضمان' : 'Held';
    }
  }

  void _openEscrowActionModal(BuildContext context, AdminEscrowLedgerItem item, bool isAr) {
    final admin = context.read<AdminProvider>();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${item.id} · ${isAr ? item.serviceTitleAr : item.serviceTitleEn}'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv(isAr ? 'طالب الخدمة' : 'Requester', item.requesterName),
                _kv(isAr ? 'المنفذ' : 'Provider', item.providerName),
                _kv(isAr ? 'المسار' : 'Corridor', isAr ? item.corridorAr : item.corridorEn),
                _kv(isAr ? 'بوابة الدفع' : 'Payment Rail', item.paymentRail),
                _kv(isAr ? 'الأتعاب + المشتريات' : 'Protected Total', '${item.totalProtectedQar.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}'),
                _kv(isAr ? 'كود الاستلام OTP' : 'Handover OTP', item.otpCode),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isAr ? 'مبرر الإجراء الرقابي' : 'Compliance / Settlement Note',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (item.hasReceiptPhoto && !item.receiptApproved)
            TextButton(
              onPressed: () {
                admin.approveEscrowReceipt(item.id);
                Navigator.of(ctx).pop();
              },
              child: Text(isAr ? 'اعتماد الفاتورة' : 'Approve Receipt'),
            ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            onPressed: () {
              final reason = noteCtrl.text.trim().isEmpty
                  ? (isAr ? 'تجميد احترازي لحين التحقق' : 'Precautionary hold pending review')
                  : noteCtrl.text.trim();
              admin.freezeEscrow(item.id, reason);
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'تجميد' : 'Freeze'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            onPressed: () {
              final reason = noteCtrl.text.trim().isEmpty
                  ? (isAr ? 'استرداد بناءً على مراجعة المشرف' : 'Refund approved after admin review')
                  : noteCtrl.text.trim();
              admin.refundEscrow(item.id, reason);
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'استرداد للطالب' : 'Refund Requester'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
            onPressed: () {
              final note = noteCtrl.text.trim().isEmpty
                  ? (isAr ? 'تسليم موثق ومطابق' : 'Verified handover & settlement confirmed')
                  : noteCtrl.text.trim();
              admin.releaseEscrow(item.id, note);
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'تحرير للمنفذ' : 'Release Payout'),
          ),
        ],
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        noteCtrl.dispose();
      });
    });
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final filtered = admin.escrowItems.where((e) {
      if (_statusFilter == 'all') return true;
      return e.status == _statusFilter;
    }).toList();

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Financial Escrow KPI Strip
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
                      title: isAr ? 'التسويات قيد التحقق' : 'Pending Settlements',
                      value: '${admin.kpiActiveEscrowHoldQar.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}',
                      deltaText: isAr ? 'محمي بـ OTP والفاتورة' : 'OTP & Receipt Gated',
                      accentColor: t.accentPrimary,
                      icon: Icons.lock_clock_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'المبالغ المسوّاة اليوم' : 'Settled Today',
                      value: '${admin.kpiReleasedTodayQar.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}',
                      deltaText: isAr ? 'تسوية مباشرة وموثقة' : 'Direct Verified Settlement',
                      accentColor: t.accentTeal,
                      icon: Icons.verified_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'الطلبات المعلّقة للنزاع' : 'Frozen in Arbitration',
                      value: '${admin.kpiFrozenEscrowQar.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}',
                      deltaText: isAr ? 'بانتظار حسم المشرف' : 'Requires Dispute Verdict',
                      accentColor: AppColors.coral,
                      icon: Icons.ac_unit_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'صافي عمولات المنصة' : 'Net Platform Take',
                      value: '${admin.kpiNetPlatformCommissionQar.toStringAsFixed(1)} ${isAr ? "ر.ق" : "QAR"}',
                      deltaText: isAr ? 'الرسوم التشغيلية المعتمدة' : 'Settled Platform Revenue',
                      accentColor: AppColors.gold,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Escrow Transactions Ledger
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isAr ? 'سجل التسويات المباشرة وإيصالات التحويل (#QA)' : 'Direct Settlement & Receipt Audit Ledger (#QA)',
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final st in [
                          {'k': 'all', 'ar': 'الكل', 'en': 'All'},
                          {'k': 'receipt_pending', 'ar': 'فاتورة معلقة', 'en': 'Receipt'},
                          {'k': 'in_transit', 'ar': 'بالطريق', 'en': 'In Transit'},
                          {'k': 'frozen', 'ar': 'مجمد', 'en': 'Frozen'},
                          {'k': 'released', 'ar': 'محرر', 'en': 'Released'},
                        ])
                          ChoiceChip(
                            label: Text(isAr ? st['ar']! : st['en']!),
                            selected: _statusFilter == st['k'],
                            onSelected: (_) => setState(() => _statusFilter = st['k']!),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AdminAdaptiveDataView<AdminEscrowLedgerItem>(
                  items: filtered,
                  minTableWidth: 900,
                  columns: [
                    DataColumn(label: Text(isAr ? 'المعرف' : 'Escrow ID')),
                    DataColumn(label: Text(isAr ? 'الخدمة والأطراف' : 'Service & Parties')),
                    DataColumn(label: Text(isAr ? 'البوابة' : 'Rail')),
                    DataColumn(label: Text(isAr ? 'القيمة المحمية' : 'Protected')),
                    DataColumn(label: Text(isAr ? 'OTP' : 'OTP')),
                    DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
                    DataColumn(label: Text(isAr ? 'تحكم' : 'Control')),
                  ],
                  buildRow: (item) {
                    final col = _escrowColor(item.status);
                    return DataRow(
                      cells: [
                        DataCell(Text(item.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isAr ? item.serviceTitleAr : item.serviceTitleEn, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              Text('${item.requesterName} -> ${item.providerName}', style: TextStyle(fontSize: 11, color: t.textSecondary)),
                            ],
                          ),
                        ),
                        DataCell(Text(item.paymentRail, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataCell(Text('${item.totalProtectedQar.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}', style: TextStyle(fontWeight: FontWeight.w800, color: t.textPrimary))),
                        DataCell(Text(item.otpCode, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: item.otpVerified ? t.accentTeal : AppColors.gold))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: col.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                            child: Text(_escrowLabel(item.status, isAr), style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        DataCell(
                          OutlinedButton(
                            onPressed: () => _openEscrowActionModal(context, item, isAr),
                            child: Text(isAr ? 'حسم / إدارة' : 'Manage', style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    );
                  },
                  buildMobileCard: (ctx, item) {
                    final col = _escrowColor(item.status);
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
                              Text(item.id, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, color: t.textPrimary)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: col.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                                child: Text(_escrowLabel(item.status, isAr), style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(isAr ? item.serviceTitleAr : item.serviceTitleEn, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('${item.requesterName} -> ${item.providerName} · ${item.paymentRail} · ${item.totalProtectedQar.toStringAsFixed(0)} QAR', style: TextStyle(color: t.textSecondary, fontSize: 11)),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                              onPressed: () => _openEscrowActionModal(context, item, isAr),
                              child: Text(isAr ? 'حسم وإدارة' : 'Manage Escrow', style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Qatari Payment Gateways Switchboard
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'قنوات التسوية والدفع القطرية المرجعية (COD / تحويل بنكي)' : 'Qatar Reference Settlement Channels (COD / Direct Transfer)',
                  style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final cols = w >= 1020 ? 3 : (w >= 620 ? 2 : 1);
                    final cardW = (w - (12 * (cols - 1))) / cols;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: admin.paymentGateways.map((gw) {
                        return SizedBox(
                          width: cardW,
                          child: Container(
                            padding: const EdgeInsets.all(14),
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
                                        isAr ? gw.nameAr : gw.nameEn,
                                        style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                                      ),
                                    ),
                                    Switch(
                                      value: gw.isEnabled,
                                      activeThumbColor: t.accentTeal,
                                      onChanged: (_) => admin.togglePaymentGateway(gw.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${isAr ? gw.settlementAr : gw.settlementEn} · Fee ${gw.feePct}% · ${gw.latencyMs}ms (${gw.uptimePct}%)',
                                  style: TextStyle(color: t.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
