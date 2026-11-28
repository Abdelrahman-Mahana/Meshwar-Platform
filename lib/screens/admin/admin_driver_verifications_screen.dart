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

class AdminDriverVerificationsScreen extends StatefulWidget {
  const AdminDriverVerificationsScreen({super.key});

  @override
  State<AdminDriverVerificationsScreen> createState() =>
      _AdminDriverVerificationsScreenState();
}

class _AdminDriverVerificationsScreenState
    extends State<AdminDriverVerificationsScreen> {
  String _selectedTab = 'pending'; // 'pending', 'rejected', 'approved'

  void _showReviewDialog(BuildContext context, AdminDriverVerificationRequest req) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DriverReviewModal(req: req),
    );
  }

  String _localizeReqStatus(String status, bool isAr) {
    if (isAr) return status;
    switch (status.trim()) {
      case 'قيد المراجعة':
        return 'Pending';
      case 'مرفوضة':
        return 'Rejected';
      case 'مقبولة':
        return 'Approved';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

    final pendingCount = admin.driverRequests.where((r) => r.status == 'قيد المراجعة').length;
    final rejectedCount = admin.driverRequests.where((r) => r.status == 'مرفوضة').length;
    final approvedCount = admin.driverRequests.where((r) => r.status == 'مقبولة').length;

    final filteredList = admin.driverRequests.where((r) {
      if (_selectedTab == 'pending') {
        return r.status == 'قيد المراجعة';
      } else if (_selectedTab == 'rejected') {
        return r.status == 'مرفوضة';
      } else {
        return r.status == 'مقبولة';
      }
    }).toList();

    return AdminPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterTab(
                label: isAr ? 'قيد المراجعة ($pendingCount)' : 'Pending ($pendingCount)',
                isSelected: _selectedTab == 'pending',
                t: t,
                onTap: () => setState(() => _selectedTab = 'pending'),
              ),
              _buildFilterTab(
                label: isAr ? 'مرفوضة ($rejectedCount)' : 'Rejected ($rejectedCount)',
                isSelected: _selectedTab == 'rejected',
                t: t,
                onTap: () => setState(() => _selectedTab = 'rejected'),
              ),
              _buildFilterTab(
                label: isAr ? 'مقبولة ($approvedCount)' : 'Approved ($approvedCount)',
                isSelected: _selectedTab == 'approved',
                t: t,
                onTap: () => setState(() => _selectedTab = 'approved'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminSectionCard(
            padding: const EdgeInsets.all(14),
            child: filteredList.isEmpty
                ? _buildEmptyState(isAr, t)
                : AdminAdaptiveDataView<AdminDriverVerificationRequest>(
                    items: filteredList,
                    minTableWidth: 860,
                    columns: [
                      DataColumn(label: Text(isAr ? 'السائق' : 'Driver')),
                      DataColumn(label: Text(isAr ? 'QID' : 'QID')),
                      DataColumn(label: Text(isAr ? 'البلدية' : 'Municipality')),
                      DataColumn(label: Text(isAr ? 'المركبة' : 'Vehicle')),
                      DataColumn(label: Text(isAr ? 'المدة' : 'Wait')),
                      DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
                      DataColumn(label: Text(isAr ? 'الإجراء' : 'Action')),
                    ],
                    buildRow: (req) {
                      final bType = req.status == 'مقبولة'
                          ? BadgeType.verified
                          : (req.status == 'مرفوضة' ? BadgeType.rejected : BadgeType.pending);
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: AppColors.gold,
                                  child: Text(
                                    req.driverName.isNotEmpty ? req.driverName[0] : 'س',
                                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(req.driverName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          DataCell(Text(req.qidMasked, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                          DataCell(Text(req.governorate)),
                          DataCell(Text(req.carModel, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(req.durationText, style: const TextStyle(fontSize: 12))),
                          DataCell(MashwarBadge(type: bType, customLabel: _localizeReqStatus(req.status, isAr))),
                          DataCell(
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showReviewDialog(context, req),
                              child: Text(isAr ? 'مراجعة' : 'Review', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      );
                    },
                    buildMobileCard: (ctx, req) {
                      final bType = req.status == 'مقبولة'
                          ? BadgeType.verified
                          : (req.status == 'مرفوضة' ? BadgeType.rejected : BadgeType.pending);
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
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.gold,
                                  child: Text(
                                    req.driverName.isNotEmpty ? req.driverName[0] : 'س',
                                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(req.driverName, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
                                      Text('${req.governorate} · QID ${req.qidMasked}', style: TextStyle(color: t.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                MashwarBadge(type: bType, customLabel: req.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('${req.carModel} · ${req.carPlate}', style: TextStyle(color: t.textSecondary, fontSize: 12)),
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                                onPressed: () => _showReviewDialog(context, req),
                                child: Text(isAr ? 'فحص المستندات' : 'Inspect KYC', style: const TextStyle(fontSize: 12)),
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

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required AdminThemeTokens t,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.navy : t.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : t.textPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAr, AdminThemeTokens t) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: AppColors.tealSurface, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.teal, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            isAr ? 'لا توجد طلبات بانتظار المراجعة' : 'No Pending Requests',
            style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            isAr ? 'تمت مراجعة جميع الطلبات وهي جاهزة.' : 'All driver requests have been processed.',
            style: TextStyle(color: t.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DriverReviewModal extends StatefulWidget {
  final AdminDriverVerificationRequest req;
  const _DriverReviewModal({required this.req});

  @override
  State<_DriverReviewModal> createState() => _DriverReviewModalState();
}

class _DriverReviewModalState extends State<_DriverReviewModal> {
  static const List<(String ar, String en)> _rejectReasons = [
    ('صورة غير واضحة', 'Blurry Document'),
    ('مستند منتهي', 'Expired Document'),
    ('بيانات غير مطابقة', 'Mismatched Info'),
    ('أخرى', 'Other'),
  ];

  bool _isRejecting = false;
  String _rejectReason = 'صورة غير واضحة';
  final TextEditingController _rejectMsgController = TextEditingController();

  @override
  void dispose() {
    _rejectMsgController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 740),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: t.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.req.status == 'مقبولة')
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.tealSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.teal),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr ? 'تم قبول السائق. وصله إشعار' : 'Driver approved. Notification sent.',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isAr ? 'مراجعة: ${widget.req.driverName}' : 'Review: ${widget.req.driverName}',
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
              const Divider(height: 20),
              Text(isAr ? 'المستندات المرفوعة' : 'Uploaded Documents', style: AppTypography.label(color: t.textPrimary).copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildDocCard(t, isAr ? 'QID (وجه)' : 'QID (Front)', Icons.badge_outlined),
                  _buildDocCard(t, isAr ? 'QID (ظهر)' : 'QID (Back)', Icons.qr_code_scanner_outlined),
                  _buildDocCard(t, isAr ? 'رخصة قيادة' : 'Driving License', Icons.card_membership_outlined),
                  _buildDocCard(t, isAr ? 'استمارة المركبة' : 'Istamara', Icons.directions_car_filled_outlined),
                  _buildDocCard(t, isAr ? 'سيلفي التحقق' : 'Live Selfie', Icons.face_rounded),
                  _buildDocCard(t, isAr ? 'صور السيارة' : 'Car Photos', Icons.camera_alt_outlined),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  children: [
                    _detail(t, isAr ? 'الاسم' : 'Driver Name', widget.req.driverName),
                    const Divider(height: 14),
                    _detail(t, 'QID', widget.req.qidMasked),
                    const Divider(height: 14),
                    _detail(t, isAr ? 'البلدية' : 'Municipality', widget.req.governorate),
                    const Divider(height: 14),
                    _detail(t, isAr ? 'السيارة' : 'Vehicle', widget.req.carModel),
                    const Divider(height: 14),
                    _detail(t, isAr ? 'اللوحة' : 'Plate', widget.req.carPlate),
                    const Divider(height: 14),
                    _detail(t, isAr ? 'انتهاء الرخصة' : 'Expiry', widget.req.licenseExpiryDate),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isRejecting) ...[
                Text(isAr ? 'سبب الرفض' : 'Rejection Reason', style: AppTypography.label(color: t.textPrimary).copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _rejectReasons.map((reason) {
                    final isSel = _rejectReason == reason.$1;
                    return ChoiceChip(
                      label: Text(isAr ? reason.$1 : reason.$2),
                      selected: isSel,
                      selectedColor: AppColors.coral,
                      backgroundColor: t.surfaceAlt,
                      labelStyle: TextStyle(color: isSel ? Colors.white : t.textPrimary, fontWeight: FontWeight.w700, fontSize: 11),
                      onSelected: (_) => setState(() => _rejectReason = reason.$1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _rejectMsgController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رسالة للسائق' : 'Message to driver',
                    hintText: isAr
                        ? 'مثال: صورة الرخصة غير واضحة، يرجى إعادة التصوير'
                        : 'e.g. License photo is blurry, please re-upload',
                    filled: true,
                    fillColor: t.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => setState(() => _isRejecting = false), child: Text(isAr ? 'رجوع' : 'Back')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
                      onPressed: () {
                        admin.rejectDriver(widget.req.id, _rejectReason, _rejectMsgController.text.trim());
                        Navigator.of(context).pop();
                      },
                      child: Text(isAr ? 'تأكيد الرفض' : 'Confirm Rejection'),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: MashwarButton(
                        text: isAr ? 'قبول' : 'Approve',
                        onPressed: () {
                          admin.acceptDriver(widget.req.id);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MashwarButton(
                        text: isAr ? 'رفض' : 'Reject',
                        variant: MashwarButtonVariant.danger,
                        onPressed: () => setState(() => _isRejecting = true),
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

  Widget _buildDocCard(AdminThemeTokens t, String label, IconData icon) {
    return Container(
      width: 100,
      height: 82,
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: t.accentPrimary, size: 24),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t.textPrimary)),
        ],
      ),
    );
  }

  Widget _detail(AdminThemeTokens t, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: t.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: t.textPrimary)),
      ],
    );
  }
}
