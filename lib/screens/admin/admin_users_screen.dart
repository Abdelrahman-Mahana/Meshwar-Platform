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
      if (_searchQuery.isEmpty) return true;
      return u.fullName.contains(_searchQuery) || u.rawPhone.contains(_searchQuery);
    }).toList();

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
              border: Border.all(color: AppColors.borderDisabled),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: isAr ? 'بحث بالاسم أو الموبايل...' : 'Search by name or phone...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy),
                      filled: true,
                      fillColor: AppColors.sand,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusField),
                        borderSide: const BorderSide(color: AppColors.borderDisabled),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusField),
                        borderSide: const BorderSide(color: AppColors.borderDisabled),
                      ),
                    ),
                  ),
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
              border: Border.all(color: AppColors.borderDisabled),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 800),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.sand),
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 64,
                      columns: [
                        DataColumn(label: Text(isAr ? 'الاسم' : 'Name', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'الموبايل' : 'Phone (Masked)', style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                    backgroundColor: AppColors.gold,
                                    child: Text(
                                      user.fullName.isNotEmpty ? user.fullName[0] : 'ع',
                                      style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            DataCell(Text(user.maskedPhone, style: const TextStyle(letterSpacing: 1.2))),
                            DataCell(Text(user.role)),
                            DataCell(MashwarBadge(type: bType, customLabel: user.status)),
                            DataCell(Text(user.registeredDate)),
                            DataCell(
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navy,
                                  side: const BorderSide(color: AppColors.navy),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showUserDetail(context, user),
                                child: Text(isAr ? 'عرض' : 'View', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Data Privacy Compliance Notice (Page 72)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimens.radiusCard)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.teal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'الأرقام مخفية جزئياً لحماية الخصوصية. تصدير بيانات الهوية غير متاح بموجب القانون رقم 151 لسنة 2020.'
                              : 'Phone numbers partially masked for privacy. ID data export prohibited under Egyptian Law 151/2020.',
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
  final TextEditingController _banReasonController = TextEditingController(text: 'تحرش متكرر موثق في 3 بلاغات');

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
              _buildRow(isAr ? 'الموبايل' : 'Phone', widget.user.maskedPhone),
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
