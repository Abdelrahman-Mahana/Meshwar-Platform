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
  String _selectedRoleFilter = 'الكل';
  String _selectedStatusFilter = 'الكل';

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
      if (_selectedRoleFilter != 'الكل' && _selectedRoleFilter != 'All') {
        if (isAr) {
          if (!u.role.contains(_selectedRoleFilter)) return false;
        } else {
          if (_selectedRoleFilter == 'Driver' && !u.role.contains('سائق')) return false;
          if (_selectedRoleFilter == 'Passenger' && !u.role.contains('راكب')) return false;
        }
      }
      if (_selectedStatusFilter != 'الكل' && _selectedStatusFilter != 'All') {
        if (isAr) {
          if (u.status != _selectedStatusFilter) return false;
        } else {
          if (_selectedStatusFilter == 'Active' && u.status != 'نشط') return false;
          if (_selectedStatusFilter == 'Banned' && u.status != 'محظور') return false;
        }
      }
      return true;
    }).toList();

    final roleFilters = isAr ? ['الكل', 'سائق', 'راكب'] : ['All', 'Driver', 'Passenger'];
    final statusFilters = isAr ? ['الكل', 'نشط', 'محظور'] : ['All', 'Active', 'Banned'];

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
                        label: Text(r),
                        selected: _selectedRoleFilter == r,
                        onSelected: (_) => setState(() => _selectedRoleFilter = r),
                      ),
                    const SizedBox(width: 4),
                    for (final s in statusFilters)
                      ChoiceChip(
                        label: Text(s),
                        selected: _selectedStatusFilter == s,
                        onSelected: (_) => setState(() => _selectedStatusFilter = s),
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
                        DataCell(Text(user.role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(Text('${user.walletBalanceQar.toStringAsFixed(0)} ${isAr ? "ر.ق" : "QAR"}', style: const TextStyle(fontWeight: FontWeight.w800))),
                        DataCell(MashwarBadge(type: bType, customLabel: user.status)),
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
  final TextEditingController _walletDeltaController = TextEditingController(text: '50');
  final TextEditingController _walletReasonController = TextEditingController(text: 'مكافأة التزام / تسوية ضمان');

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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(AppDimens.space20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
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
                      widget.user.fullName.isNotEmpty ? widget.user.fullName[0] : 'ع',
                      style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user.fullName, style: AppTypography.title().copyWith(fontSize: 16)),
                        Text('${widget.user.role} · ${widget.user.qidStatus}', style: AppTypography.label(color: AppColors.textSecondary)),
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
              _row(isAr ? 'رقم الجوال' : 'Phone', widget.user.maskedPhone),
              _row(isAr ? 'رصيد المحفظة' : 'Wallet', '${widget.user.walletBalanceQar.toStringAsFixed(0)} QAR'),
              _row(isAr ? 'الرحلات' : 'Trips', '${widget.user.rideCount}'),
              _row(isAr ? 'البلاغات' : 'Strikes', '${widget.user.strikesCount}'),
              const SizedBox(height: 14),
              // Wallet Reconciliation Widget
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تسوية / شحن رصيد المحفظة (موثق بالتدقيق)' : 'Wallet Reconciliation (Audit Logged)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
                          onPressed: () {
                            final delta = double.tryParse(_walletDeltaController.text.trim()) ?? 0;
                            if (delta == 0) return;
                            admin.adjustUserWalletBalance(widget.user.id, delta, _walletReasonController.text.trim());
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
                  decoration: InputDecoration(
                    labelText: isAr ? 'سبب الحظر الإجباري' : 'Mandatory Ban Reason',
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
                        admin.banUser(widget.user.id, _banReasonController.text.trim());
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

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy)),
        ],
      ),
    );
  }
}
