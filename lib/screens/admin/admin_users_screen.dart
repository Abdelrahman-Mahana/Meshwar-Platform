import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';

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
      builder: (ctx) => _UserDetailModal(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();

    final filteredUsers = admin.users.where((u) {
      if (_searchQuery.isNotEmpty) {
        final matchesName = u.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesPhone = u.rawPhone.contains(_searchQuery) || u.maskedPhone.contains(_searchQuery);
        if (!matchesName && !matchesPhone) return false;
      }
      if (_selectedRoleFilter != 'الكل' && _selectedRoleFilter != 'All') {
        if (isAr) {
          if (u.role != _selectedRoleFilter) return false;
        } else {
          if (_selectedRoleFilter == 'Driver' && u.role != 'سائق') return false;
          if (_selectedRoleFilter == 'Passenger' && u.role != 'راكب') return false;
        }
      }
      if (_selectedStatusFilter != 'الكل' && _selectedStatusFilter != 'All') {
        if (isAr) {
          if (u.status != _selectedStatusFilter) return false;
        } else {
          if (_selectedStatusFilter == 'Active' && u.status != 'نشط') return false;
          if (_selectedStatusFilter == 'Suspended' && u.status != 'موقوف') return false;
          if (_selectedStatusFilter == 'Banned' && u.status != 'محظور') return false;
        }
      }
      return true;
    }).toList();

    final roleFilters = isAr ? ['الكل', 'سائق', 'راكب'] : ['All', 'Driver', 'Passenger'];
    final statusFilters = isAr ? ['الكل', 'نشط', 'محظور'] : ['All', 'Active', 'Banned'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Filter Box (Page 72)
          Container(
            padding: const EdgeInsets.all(AppDimens.space16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: isAr ? 'بحث بالاسم أو رقم الجوال...' : 'Search by name or mobile number...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy),
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
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusField),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusField),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusField),
                            borderSide: const BorderSide(color: AppColors.navy, width: 1.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isAr ? 'تصفية:' : 'Filters:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                    ),
                    for (final r in roleFilters) ...[
                      ChoiceChip(
                        label: Text(r),
                        selected: _selectedRoleFilter == r,
                        selectedColor: AppColors.navy,
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide(color: _selectedRoleFilter == r ? AppColors.navy : const Color(0xFFE2E8F0)),
                        labelStyle: TextStyle(
                          color: _selectedRoleFilter == r ? Colors.white : AppColors.navy,
                          fontWeight: _selectedRoleFilter == r ? FontWeight.bold : FontWeight.w500,
                          fontSize: 11,
                        ),
                        onSelected: (_) => setState(() => _selectedRoleFilter = r),
                      ),
                    ],
                    const SizedBox(width: 8),
                    for (final s in statusFilters) ...[
                      ChoiceChip(
                        label: Text(s),
                        selected: _selectedStatusFilter == s,
                        selectedColor: AppColors.navy,
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide(color: _selectedStatusFilter == s ? AppColors.navy : const Color(0xFFE2E8F0)),
                        labelStyle: TextStyle(
                          color: _selectedStatusFilter == s ? Colors.white : AppColors.navy,
                          fontWeight: _selectedStatusFilter == s ? FontWeight.bold : FontWeight.w500,
                          fontSize: 11,
                        ),
                        onSelected: (_) => setState(() => _selectedStatusFilter = s),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.space16),

          // Users Table (Page 72)
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double minW = math.max(constraints.maxWidth, 850.0);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: minW),
                        child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 64,
                      columns: [
                        DataColumn(label: Text(isAr ? 'الاسم' : 'Name', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'رقم الجوال' : 'Phone (Masked)', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'الدور' : 'Role', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'التسجيل' : 'Registration', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'الإجراء' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredUsers.map((user) {
                        BadgeType bType;
                        if (user.status == 'نشط') {
                          bType = BadgeType.verified;
                        } else if (user.status == 'موقوف') {
                          bType = BadgeType.pending;
                        } else {
                          bType = BadgeType.rejected;
                        }

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: user.role == 'سائق' ? AppColors.gold : const Color(0xFFE2E8F0),
                                    child: Text(
                                      user.fullName.isNotEmpty ? user.fullName[0] : 'ع',
                                      style: TextStyle(
                                        color: user.role == 'سائق' ? AppColors.navy : const Color(0xFF475569),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            DataCell(Text(user.maskedPhone, style: const TextStyle(letterSpacing: 1.2))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: user.role == 'سائق' ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.role,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: user.role == 'سائق' ? const Color(0xFFB45309) : AppColors.navy,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(MashwarBadge(type: bType, customLabel: user.status)),
                            DataCell(Text(user.registeredDate)),
                            DataCell(
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navy,
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                label: Text(isAr ? 'عرض وتعديل' : 'View & Edit', style: const TextStyle(fontSize: 12)),
                                onPressed: () => _showUserDetail(context, user),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),

                // Data Privacy Compliance Notice (Page 72)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimens.radiusCard)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.teal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'الأرقام مخفية جزئياً لحماية الخصوصية. تصدير بيانات الهوية غير متاح بموجب القانون القطري رقم 13 لسنة 2016.'
                              : 'Phone numbers partially masked for privacy. ID data export prohibited under Qatar Law No. 13/2016.',
                          style: AppTypography.label(color: AppColors.textSecondary),
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

// User Detail Modal (Page 72)
class _UserDetailModal extends StatefulWidget {
  final AdminUserItem user;
  const _UserDetailModal({required this.user});

  @override
  State<_UserDetailModal> createState() => _UserDetailModalState();
}

class _UserDetailModalState extends State<_UserDetailModal> {
  bool _isBanning = false;
  final TextEditingController _banReasonController = TextEditingController();

  @override
  void dispose() {
    _banReasonController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 550),
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      widget.user.fullName.isNotEmpty ? widget.user.fullName[0] : 'ك',
                      style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user.fullName, style: AppTypography.title().copyWith(fontSize: 16)),
                        Text(widget.user.role, style: AppTypography.label(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  MashwarBadge(
                    type: widget.user.status == 'نشط'
                        ? BadgeType.verified
                        : widget.user.status == 'موقوف'
                            ? BadgeType.pending
                            : BadgeType.rejected,
                    customLabel: widget.user.status,
                  ),
                ],
              ),
              const Divider(height: 24),

              // Info Grid
              _buildRow(isAr ? 'رقم الجوال' : 'Phone', widget.user.maskedPhone),
              const SizedBox(height: 10),
              _buildRow(isAr ? 'رحلات' : 'Rides', '${widget.user.rideCount} ${isAr ? "حجوزات" : "Bookings"}'),
              const SizedBox(height: 10),
              _buildRow(
                isAr ? 'بلاغات ضده' : 'Strikes / Reports',
                '${widget.user.strikesCount}',
                isDanger: widget.user.strikesCount > 0,
              ),

              if (widget.user.currentStrikeReason != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'السبب الحالي:' : 'Current Strike Reason:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.danger),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.currentStrikeReason!,
                        style: const TextStyle(fontSize: 12, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
              ],

              if (widget.user.internalNotes != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'ملاحظات داخلية:' : 'Internal Staff Notes:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.internalNotes!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],

              // Ban Confirmation View (Page 72 - نافذة تأكيد الحظر)
              if (_isBanning) ...[
                const SizedBox(height: AppDimens.space20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'حظر ${widget.user.fullName}؟' : 'Ban ${widget.user.fullName}?',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.danger),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'الحظر نهائي. السبب إجباري ويتسجل في سجل التدقيق.'
                            : 'Permanent ban. Mandatory reason will be logged to audit trail.',
                        style: const TextStyle(fontSize: 11, color: AppColors.navy),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _banReasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: isAr ? 'اكتب سبب الحظر بدقة...' : 'Write exact ban reason...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isBanning = false),
                            child: Text(isAr ? 'رجوع' : 'Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.coral,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              admin.banUser(widget.user.id, _banReasonController.text.trim());
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr ? 'تم حظر المستخدم وتسجيل القرار في سجل التدقيق' : 'User banned and logged to audit trail'),
                                  backgroundColor: AppColors.coral,
                                ),
                              );
                            },
                            child: Text(isAr ? 'تأكيد الحظر' : 'Confirm Ban'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppDimens.space24),
                // Decision Buttons (Page 72)
                Row(
                  children: [
                    if (widget.user.status == 'موقوف') ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.teal),
                            foregroundColor: AppColors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            admin.unbanUser(widget.user.id);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isAr ? 'تم رفع الإيقاف عن المستخدم' : 'Suspension lifted'),
                                backgroundColor: AppColors.teal,
                              ),
                            );
                          },
                          child: Text(isAr ? 'رفع الإيقاف' : 'Lift Suspension', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => setState(() => _isBanning = true),
                        child: Text(isAr ? 'حظر نهائي' : 'Permanent Ban', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isDanger = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isDanger ? AppColors.danger : AppColors.navy,
          ),
        ),
      ],
    );
  }
}
