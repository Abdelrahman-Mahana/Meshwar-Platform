import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';
  String _selectedStatusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetail(BuildContext context, AdminUserItem user) {
    showDialog(
      context: context,
      builder: (_) => _UserDetailModal(user: user),
    );
  }

  String _localizeStatus(String status, bool isAr) {
    if (isAr) return status;
    switch (status.trim()) {
      case 'نشط':
        return 'Active';
      case 'موقوف':
        return 'Suspended';
      case 'محظور':
        return 'Banned';
      default:
        return status;
    }
  }

  String _localizeRole(String role, bool isAr) {
    if (isAr) return role;
    return role
        .replaceAll('سائق ومزود', 'Driver & Provider')
        .replaceAll('سائق', 'Driver')
        .replaceAll('راكب', 'Passenger');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final filteredUsers = admin.users.where((u) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!u.fullName.toLowerCase().contains(q) &&
            !u.rawPhone.contains(q) &&
            !u.maskedPhone.contains(q)) {
          return false;
        }
      }
      if (_selectedRoleFilter == 'driver' &&
          !u.role.contains('سائق') &&
          !u.role.toLowerCase().contains('driver')) {
        return false;
      }
      if (_selectedRoleFilter == 'passenger' &&
          !u.role.contains('راكب') &&
          !u.role.toLowerCase().contains('passenger')) {
        return false;
      }
      if (_selectedStatusFilter == 'active' &&
          u.status != 'نشط' &&
          u.status.toLowerCase() != 'active') {
        return false;
      }
      if (_selectedStatusFilter == 'banned' &&
          u.status != 'محظور' &&
          u.status.toLowerCase() != 'banned') {
        return false;
      }
      return true;
    }).toList();

    final roleFilters = const [
      ('all', 'الكل', 'All'),
      ('driver', 'سائق', 'Driver'),
      ('passenger', 'راكب', 'Passenger'),
    ];
    final statusFilters = const [
      ('all', 'الكل', 'All'),
      ('active', 'نشط', 'Active'),
      ('banned', 'محظور', 'Banned'),
    ];

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: t.textPrimary),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: isAr ? 'بحث بالاسم أو رقم الجوال...' : 'Search by name or mobile number...',
                    hintStyle: TextStyle(color: t.textSecondary, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: t.accentPrimary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: isAr ? 'مسح البحث' : 'Clear search',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: t.surfaceAlt,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isAr ? 'تصفية:' : 'Filters:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.textPrimary),
                    ),
                    for (final r in roleFilters)
                      ChoiceChip(
                        label: Text(isAr ? r.$2 : r.$3),
                        selected: _selectedRoleFilter == r.$1,
                        onSelected: (_) => setState(() => _selectedRoleFilter = r.$1),
                      ),
                    const SizedBox(width: 4),
                    for (final s in statusFilters)
                      ChoiceChip(
                        label: Text(isAr ? s.$2 : s.$3),
                        selected: _selectedStatusFilter == s.$1,
                        onSelected: (_) => setState(() => _selectedStatusFilter = s.$1),
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
                AdminAdaptiveDataView<AdminUserItem>(
                  items: filteredUsers,
                  minTableWidth: 880,
                  columns: [
                    DataColumn(label: Text(isAr ? 'الاسم والـ QID' : 'User & QID')),
                    DataColumn(label: Text(isAr ? 'الجوال' : 'Phone')),
                    DataColumn(label: Text(isAr ? 'الدور' : 'Role')),
                    DataColumn(label: Text(isAr ? 'المحفظة' : 'Wallet')),
                    DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
                    DataColumn(label: Text(isAr ? 'الإجراء' : 'Action')),
                  ],
                  buildRow: (user) {
                    final bType = user.status == 'نشط'
                        ? BadgeType.verified
                        : (user.status == 'موقوف' ? BadgeType.pending : BadgeType.rejected);
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: user.role.contains('سائق') ? AppColors.gold : t.surfaceMuted,
                                child: Text(
                                  user.fullName.isNotEmpty ? user.fullName[0] : 'ع',
                                  style: TextStyle(
                                    color: user.role.contains('سائق') ? AppColors.navy : t.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(user.qidStatus, style: TextStyle(fontSize: 10, color: t.accentTeal, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(user.maskedPhone, style: const TextStyle(letterSpacing: 1.0))),
                        DataCell(Text(_localizeRole(user.role, isAr), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(Text('${user.walletBalanceQar.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}', style: const TextStyle(fontWeight: FontWeight.w800))),
                        DataCell(MashwarBadge(type: bType, customLabel: _localizeStatus(user.status, isAr))),
                        DataCell(
                          OutlinedButton.icon(
                            icon: const Icon(Icons.manage_accounts_outlined, size: 15),
                            label: Text(isAr ? 'عرض وتعديل' : 'Manage', style: const TextStyle(fontSize: 12)),
                            onPressed: () => _showUserDetail(context, user),
                          ),
                        ),
                      ],
                    );
                  },
                  buildMobileCard: (ctx, user) {
                    final bType = user.status == 'نشط'
                        ? BadgeType.verified
                        : (user.status == 'موقوف' ? BadgeType.pending : BadgeType.rejected);
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
                                child: Text(user.fullName, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
                              ),
                              MashwarBadge(type: bType, customLabel: user.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${user.role} · ${user.maskedPhone} · ${user.walletBalanceQar.toStringAsFixed(0)} QAR',
                            style: TextStyle(color: t.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: OutlinedButton(
                              onPressed: () => _showUserDetail(context, user),
                              child: Text(isAr ? 'إدارة الحساب والمحفظة' : 'Manage & Wallet', style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded, color: t.accentTeal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'الأرقام مخفية جزئياً لحماية الخصوصية بموجب القانون القطري رقم 13 لسنة 2016.'
                              : 'Phone numbers partially masked under Qatar Data Privacy Law No. 13/2016.',
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

class _UserDetailModal extends StatefulWidget {
  final AdminUserItem user;
  const _UserDetailModal({required this.user});

  @override
  State<_UserDetailModal> createState() => _UserDetailModalState();
}

class _UserDetailModalState extends State<_UserDetailModal> {
  bool _isBanning = false;
  final TextEditingController _banReasonController = TextEditingController();
  final TextEditingController _walletDeltaController = TextEditingController();
  final TextEditingController _walletReasonController = TextEditingController();
  String? _banError;

  @override
  void dispose() {
    _banReasonController.dispose();
    _walletDeltaController.dispose();
    _walletReasonController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 560),
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      widget.user.fullName.isNotEmpty ? widget.user.fullName[0] : (isAr ? 'ع' : 'U'),
                      style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user.fullName, style: AppTypography.title(color: t.textPrimary).copyWith(fontSize: 16)),
                        Text('${widget.user.role} · ${widget.user.qidStatus}', style: AppTypography.label(color: t.textSecondary)),
                      ],
                    ),
                  ),
                  MashwarBadge(
                    type: widget.user.status == 'نشط'
                        ? BadgeType.verified
                        : (widget.user.status == 'موقوف' ? BadgeType.pending : BadgeType.rejected),
                    customLabel: widget.user.status,
                  ),
                ],
              ),
              const Divider(height: 22),
              _row(t, isAr ? 'رقم الجوال' : 'Phone', widget.user.maskedPhone),
              _row(t, isAr ? 'رصيد المحفظة' : 'Wallet', '${widget.user.walletBalanceQar.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}'),
              _row(t, isAr ? 'الرحلات' : 'Trips', '${widget.user.rideCount}'),
              _row(t, isAr ? 'البلاغات' : 'Strikes', '${widget.user.strikesCount}'),
              const SizedBox(height: 14),
              // Wallet Reconciliation Widget
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تسوية / شحن رصيد المحفظة (موثق بالتدقيق)' : 'Wallet Reconciliation (Audit Logged)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _walletDeltaController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: isAr ? 'المبلغ ر.ق' : 'QAR',
                              hintText: '50',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _walletReasonController,
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: isAr ? 'السبب' : 'Reason',
                              hintText: isAr ? 'مثال: تسوية أو مكافأة التزام' : 'e.g. Settlement adjustment',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
                          onPressed: () {
                            final delta = double.tryParse(_walletDeltaController.text.trim()) ?? 0;
                            if (delta == 0) {
                              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr ? 'يرجى إدخال مبلغ صحيح غير صفري' : 'Enter a valid non-zero amount',
                                  ),
                                  backgroundColor: AppColors.coral,
                                ),
                              );
                              return;
                            }
                            final reason = _walletReasonController.text.trim().isNotEmpty
                                ? _walletReasonController.text.trim()
                                : (isAr ? 'تسوية إدارية' : 'Admin adjustment');
                            admin.adjustUserWalletBalance(widget.user.id, delta, reason);
                            setState(() {});
                          },
                          child: Text(isAr ? 'تطبيق' : 'Apply', style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isBanning) ...[
                TextField(
                  controller: _banReasonController,
                  maxLines: 2,
                  onChanged: (_) {
                    if (_banError != null) setState(() => _banError = null);
                  },
                  decoration: InputDecoration(
                    labelText: isAr ? 'سبب الحظر الإجباري' : 'Mandatory Ban Reason',
                    errorText: _banError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => setState(() => _isBanning = false), child: Text(isAr ? 'رجوع' : 'Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
                      onPressed: () {
                        final reason = _banReasonController.text.trim();
                        if (reason.isEmpty) {
                          setState(() {
                            _banError = isAr
                                ? 'يرجى إدخال سبب الحظر قبل التأكيد'
                                : 'Please enter a mandatory ban reason';
                          });
                          return;
                        }
                        admin.banUser(widget.user.id, reason);
                        Navigator.of(context).pop();
                      },
                      child: Text(isAr ? 'تأكيد الحظر' : 'Confirm Ban'),
                    ),
                  ],
                ),
              ] else
                Row(
                  children: [
                    if (widget.user.status == 'موقوف' || widget.user.status == 'محظور') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            admin.unbanUser(widget.user.id);
                            Navigator.of(context).pop();
                          },
                          child: Text(isAr ? 'رفع الإيقاف' : 'Lift Suspension'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
                        onPressed: () => setState(() => _isBanning = true),
                        child: Text(isAr ? 'حظر نهائي' : 'Permanent Ban'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(AdminThemeTokens t, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: t.textSecondary, fontSize: 13)),
          Text(v, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: t.textPrimary)),
        ],
      ),
    );
  }
}
