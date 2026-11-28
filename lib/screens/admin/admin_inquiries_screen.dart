import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/admin_platform_models.dart';
import '../../data/services/firebase_firestore_service.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminInquiriesScreen extends StatefulWidget {
  @visibleForTesting
  static Future<bool> Function(Uri uri, {LaunchMode mode})? debugUrlLauncher;

  const AdminInquiriesScreen({super.key});

  @override
  State<AdminInquiriesScreen> createState() => _AdminInquiriesScreenState();
}

class _AdminInquiriesScreenState extends State<AdminInquiriesScreen> {
  static const String _firestoreConsoleUrl =
      'https://console.firebase.google.com/project/${FirebaseConfig.projectId}/firestore/databases/-default-/data/~2F${FirestoreCollections.investorInquiries}';

  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _copyText(BuildContext context, String value, String feedback) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedback),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchExternal(
    BuildContext context,
    Uri uri, {
    required String fallbackMessage,
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    bool launched = false;
    try {
      final override = AdminInquiriesScreen.debugUrlLauncher;
      launched = override != null
          ? await override(uri, mode: mode)
          : await launchUrl(uri, mode: mode);
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(fallbackMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _statusColor(String st) {
    switch (st) {
      case 'contacted':
        return AppColors.teal;
      case 'archived':
        return AppColors.textSecondary;
      default:
        return AppColors.coral;
    }
  }

  String _statusLabel(String st, bool isAr) {
    switch (st) {
      case 'contacted':
        return isAr ? 'تم التواصل' : 'Contacted';
      case 'archived':
        return isAr ? 'مؤرشف' : 'Archived';
      default:
        return isAr ? 'جديد' : 'New';
    }
  }

  void _openInquiryDialog(
    BuildContext context,
    AdminInvestorInquiry item,
    bool isAr,
  ) {
    final admin = context.read<AdminProvider>();
    final noteCtrl = TextEditingController(text: item.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('#${item.shortRef} · ${item.fullName}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv(isAr ? 'الجهة / الصندوق' : 'Organization', item.organization),
                _kv(isAr ? 'البريد الإلكتروني' : 'Email', item.email),
                _kv(
                  isAr ? 'الهاتف / واتساب' : 'Phone',
                  item.phone.isEmpty ? '—' : item.phone,
                ),
                _kv(isAr ? 'نوع الطلب' : 'Inquiry Type', item.inquiryType),
                _kv(isAr ? 'المصدر / اللغة' : 'Source / Lang', '${item.source} (${item.lang.toUpperCase()})'),
                _kv(isAr ? 'وقت الإرسال' : 'Submitted', item.createdAtIso),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      key: const ValueKey('admin_inquiry_mailto_btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _launchExternal(
                        context,
                        Uri.parse(
                          'mailto:${item.email}?subject=${Uri.encodeComponent('MASHWAR Qatar — Follow-up (#${item.shortRef})')}',
                        ),
                        fallbackMessage: isAr
                            ? 'لا يوجد تطبيق بريد افتراضي. راسل ${item.email} مباشرة.'
                            : 'No mail client configured. Email ${item.email} directly.',
                      ),
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: Text(isAr ? 'مراسلة بالبريد' : 'Send Email'),
                    ),
                    if (item.phone.trim().isNotEmpty)
                      OutlinedButton.icon(
                        key: const ValueKey('admin_inquiry_call_btn'),
                        onPressed: () {
                          final digits =
                              item.phone.replaceAll(RegExp(r'[^0-9+]'), '');
                          final dialTarget = digits.startsWith('+')
                              ? digits
                              : (digits.length == 8 ? '+974$digits' : digits);
                          _launchExternal(
                            context,
                            Uri(scheme: 'tel', path: dialTarget),
                            fallbackMessage: isAr
                                ? 'لا يدعم هذا الجهاز الاتصال المباشر ($dialTarget).'
                                : 'Phone dialer unavailable on this device ($dialTarget).',
                          );
                        },
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 15),
                        label: Text(isAr ? 'اتصال هاتفي' : 'Call Phone'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _copyText(
                        context,
                        item.email,
                        isAr
                            ? 'تم نسخ البريد: ${item.email}'
                            : 'Copied email: ${item.email}',
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(isAr ? 'نسخ البريد' : 'Copy Email'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isAr ? 'ملاحظات المتابعة' : 'Follow-up Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              admin.updateInquiryStatus(
                item.id,
                'archived',
                note: noteCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'أرشفة' : 'Archive'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            onPressed: () {
              admin.updateInquiryStatus(
                item.id,
                'new',
                note: noteCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'إبقاء كجديد' : 'Mark New'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              admin.updateInquiryStatus(
                item.id,
                'contacted',
                note: noteCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'تم التواصل' : 'Mark Contacted'),
          ),
        ],
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        noteCtrl.dispose();
      });
    });
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = admin.inquiries.where((inq) {
      if (_statusFilter != 'all' && inq.status != _statusFilter) return false;
      if (query.isEmpty) return true;
      return inq.fullName.toLowerCase().contains(query) ||
          inq.organization.toLowerCase().contains(query) ||
          inq.email.toLowerCase().contains(query) ||
          inq.inquiryType.toLowerCase().contains(query) ||
          inq.shortRef.toLowerCase().contains(query);
    }).toList();

    final contactedCount =
        admin.inquiries.where((inq) => inq.status == 'contacted').length;

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Firebase Project & Alert Pipeline Banner
          AdminSectionCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 660),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'صندوق تواصل المستثمرين والشركاء — Firebase Cloud Firestore'
                            : 'Investor & Partner Inquiries — Firebase Cloud Firestore',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'المشروع: ${FirebaseConfig.projectId} · المجموعة: ${FirestoreCollections.investorInquiries} · تنبيه فوري إلى: ops@mashwar.qa · +974 4400 9999'
                            : 'Project: ${FirebaseConfig.projectId} · Collection: ${FirestoreCollections.investorInquiries} · Ops Alert: ops@mashwar.qa · +974 4400 9999',
                        style: TextStyle(color: t.textSecondary, fontSize: 12),
                      ),
                      if (admin.inquiriesSyncStatus != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          admin.inquiriesSyncStatus!,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: admin.isSyncingInquiries
                          ? null
                          : () => admin.syncInquiriesFromFirestore(),
                      icon: admin.isSyncingInquiries
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
                        isAr ? 'مزامنة Firestore' : 'Sync Firestore',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('admin_open_firestore_console_btn'),
                      onPressed: () => _launchExternal(
                        context,
                        Uri.parse(_firestoreConsoleUrl),
                        mode: LaunchMode.externalApplication,
                        fallbackMessage: isAr
                            ? 'تعذّر فتح Firestore Console تلقائياً.'
                            : 'Unable to open Firestore Console externally.',
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(
                        isAr ? 'فتح Firestore Console' : 'Open Firestore Console',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _copyText(
                        context,
                        _firestoreConsoleUrl,
                        isAr
                            ? 'تم نسخ رابط Firestore Console المباشر'
                            : 'Copied direct Firestore Console URL',
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(
                        isAr ? 'نسخ رابط Firestore' : 'Copy Firestore URL',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
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
                      title: isAr ? 'إجمالي الطلبات' : 'Total Inquiries',
                      value: '${admin.inquiries.length}',
                      deltaText: isAr ? 'مزامنة سحابية مباشرة' : 'Live Cloud Sync',
                      accentColor: t.accentPrimary,
                      icon: Icons.inbox_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'بانتظار المتابعة' : 'New / Unread',
                      value: '${admin.newInquiriesCount}',
                      deltaText: isAr ? 'تتطلب رداً مباشراً' : 'Requires Ops Reply',
                      accentColor: AppColors.coral,
                      icon: Icons.mark_email_unread_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'تم التواصل معهم' : 'Contacted',
                      value: '$contactedCount',
                      deltaText: isAr ? 'تم الرد بالبريد' : 'Replied via Email',
                      accentColor: t.accentTeal,
                      icon: Icons.mark_email_read_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: AdminKpiCard(
                      title: isAr ? 'بريد العمليات' : 'Operations Inbox',
                      value: isAr ? 'نشط' : 'Active',
                      deltaText: 'ops@mashwar.qa · +974 4400 9999',
                      accentColor: AppColors.gold,
                      icon: Icons.alternate_email_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Search, Filter & Inquiries Ledger
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          hintText: isAr
                              ? 'ابحث بالاسم، البريد، الجهة أو #REF'
                              : 'Search name, email, org or #REF',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
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
                          {'k': 'new', 'ar': 'جديد', 'en': 'New'},
                          {'k': 'contacted', 'ar': 'تم التواصل', 'en': 'Contacted'},
                          {'k': 'archived', 'ar': 'مؤرشف', 'en': 'Archived'},
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
                AdminAdaptiveDataView<AdminInvestorInquiry>(
                  items: filtered,
                  minTableWidth: 940,
                  columns: [
                    DataColumn(label: Text(isAr ? 'المرجع' : 'Ref')),
                    DataColumn(label: Text(isAr ? 'المرسل والبريد' : 'Contact & Email')),
                    DataColumn(label: Text(isAr ? 'الجهة' : 'Organization')),
                    DataColumn(label: Text(isAr ? 'نوع الطلب' : 'Inquiry Type')),
                    DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
                    DataColumn(label: Text(isAr ? 'إجراء' : 'Actions')),
                  ],
                  buildRow: (item) {
                    final col = _statusColor(item.status);
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '#${item.shortRef}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  item.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: t.accentTeal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              item.organization,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              item.inquiryType,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.textSecondary,
                                fontSize: 12,
                              ),
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
                              color: col.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _statusLabel(item.status, isAr),
                              style: TextStyle(
                                color: col,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: isAr ? 'نسخ البريد' : 'Copy Email',
                                onPressed: () => _copyText(
                                  context,
                                  item.email,
                                  isAr
                                      ? 'تم نسخ ${item.email}'
                                      : 'Copied ${item.email}',
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 17),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    _openInquiryDialog(context, item, isAr),
                                child: Text(
                                  isAr ? 'تفاصيل / رد' : 'View / Reply',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  buildMobileCard: (ctx, item) {
                    final col = _statusColor(item.status);
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
                              Text(
                                '#${item.shortRef}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  color: t.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: col.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _statusLabel(item.status, isAr),
                                  style: TextStyle(
                                    color: col,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.fullName} · ${item.organization}',
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.email + (item.phone.isEmpty ? '' : ' · ${item.phone}'),
                            style: TextStyle(
                              color: t.accentTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.inquiryType,
                            style: TextStyle(color: t.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _copyText(
                                  context,
                                  item.email,
                                  isAr
                                      ? 'تم نسخ ${item.email}'
                                      : 'Copied ${item.email}',
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 15),
                                label: Text(
                                  isAr ? 'نسخ البريد' : 'Copy Email',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navy,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                    _openInquiryDialog(context, item, isAr),
                                child: Text(
                                  isAr ? 'تفاصيل / حالة' : 'Manage',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
