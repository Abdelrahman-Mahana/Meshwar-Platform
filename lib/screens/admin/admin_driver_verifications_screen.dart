import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_button.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';

class AdminDriverVerificationsScreen extends StatefulWidget {
  const AdminDriverVerificationsScreen({super.key});

  @override
  State<AdminDriverVerificationsScreen> createState() => _AdminDriverVerificationsScreenState();
}

class _AdminDriverVerificationsScreenState extends State<AdminDriverVerificationsScreen> {
  String _selectedTab = 'قيد المراجعة'; // 'قيد المراجعة', 'مرفوضة', 'مقبولة'

  void _showReviewDialog(BuildContext context, AdminDriverVerificationRequest req) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _DriverReviewModal(req: req);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();

    final pendingCount = admin.driverRequests.where((r) => r.status == 'قيد المراجعة').length;
    final rejectedCount = admin.driverRequests.where((r) => r.status == 'مرفوضة').length;
    final approvedCount = admin.driverRequests.where((r) => r.status == 'مقبولة').length;

    final filteredList = admin.driverRequests.where((r) {
      if (_selectedTab == 'قيد المراجعة' || _selectedTab == 'Under Review') {
        return r.status == 'قيد المراجعة';
      } else if (_selectedTab == 'مرفوضة' || _selectedTab == 'Rejected') {
        return r.status == 'مرفوضة';
      } else {
        return r.status == 'مقبولة';
      }
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Tabs (Page 70 - Responsive Wrap)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterTab(
                label: isAr ? 'قيد المراجعة ($pendingCount)' : 'Pending ($pendingCount)',
                isSelected: _selectedTab.startsWith('قيد') || _selectedTab.startsWith('Pend'),
                onTap: () => setState(() => _selectedTab = isAr ? 'قيد المراجعة' : 'Under Review'),
              ),
              _buildFilterTab(
                label: isAr ? 'مرفوضة ($rejectedCount)' : 'Rejected ($rejectedCount)',
                isSelected: _selectedTab.startsWith('مرفوض') || _selectedTab.startsWith('Reject'),
                onTap: () => setState(() => _selectedTab = isAr ? 'مرفوضة' : 'Rejected'),
              ),
              _buildFilterTab(
                label: isAr ? 'مقبولة ($approvedCount)' : 'Approved ($approvedCount)',
                isSelected: _selectedTab.startsWith('مقبول') || _selectedTab.startsWith('Approv'),
                onTap: () => setState(() => _selectedTab = isAr ? 'مقبولة' : 'Approved'),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.space16),

          // Table Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              border: Border.all(color: AppColors.borderDisabled),
            ),
            child: filteredList.isEmpty
                ? _buildEmptyState(isAr)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 800),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.sand),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 64,
                        columns: [
                          DataColumn(label: Text(isAr ? 'السائق' : 'Driver', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isAr ? 'المحافظة' : 'Governorate', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isAr ? 'تاريخ الإرسال' : 'Submitted At', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isAr ? 'المدة' : 'Wait Time', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isAr ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isAr ? 'الإجراء' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredList.map((req) {
                          BadgeType bType;
                          if (req.status == 'مقبولة') {
                            bType = BadgeType.verified;
                          } else if (req.status == 'مرفوضة') {
                            bType = BadgeType.rejected;
                          } else {
                            bType = BadgeType.pending;
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
                                        req.driverName.isNotEmpty ? req.driverName[0] : 'س',
                                        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(req.driverName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              DataCell(Text(req.governorate)),
                              DataCell(Text(req.submittedAt)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.sand,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderDisabled),
                                  ),
                                  child: Text(req.durationText, style: const TextStyle(fontSize: 11)),
                                ),
                              ),
                              DataCell(MashwarBadge(type: bType, customLabel: req.status)),
                              DataCell(
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.navy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _showReviewDialog(context, req),
                                  child: Text(isAr ? 'مراجعة' : 'Review', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.navy : AppColors.borderDisabled),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.tealSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.teal, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? 'مفيش طلبات في الانتظار' : 'No Pending Requests',
            style: AppTypography.title(),
          ),
          const SizedBox(height: 6),
          Text(
            isAr ? 'كل الطلبات اتراجعت وجاهزة.' : 'All driver requests have been processed.',
            style: AppTypography.bodySecondary(),
          ),
        ],
      ),
    );
  }
}

// Modal Review (Page 71)
class _DriverReviewModal extends StatefulWidget {
  final AdminDriverVerificationRequest req;
  const _DriverReviewModal({required this.req});

  @override
  State<_DriverReviewModal> createState() => _DriverReviewModalState();
}

class _DriverReviewModalState extends State<_DriverReviewModal> {
  bool _isRejecting = false;
  String _rejectReason = 'صورة غير واضحة';
  final TextEditingController _rejectMsgController = TextEditingController(text: 'صورة الرخصة مش واضحة، صوّرها تاني');

  @override
  void dispose() {
    _rejectMsgController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 750),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Approved Banner if already accepted (Page 71 - تم القبول)
              if (widget.req.status == 'مقبولة') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tealSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.teal),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'تم قبول السائق. وصله إشعار' : 'Driver approved. Notification sent.',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              // Header
              Row(
                children: [
                  Text(
                    isAr ? 'مراجعة: ${widget.req.driverName}' : 'Review: ${widget.req.driverName}',
                    style: AppTypography.title().copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Documents Grid (Page 71)
              Text(
                isAr ? 'المستندات المرفوعة' : 'Uploaded Documents',
                style: AppTypography.label().copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDocCard(context, isAr ? 'بطاقة (وجه)' : 'ID (Front)', Icons.badge_outlined, isAr),
                  _buildDocCard(context, isAr ? 'بطاقة (ظهر)' : 'ID (Back)', Icons.qr_code_scanner_outlined, isAr),
                  _buildDocCard(context, isAr ? 'رخصة قيادة' : 'Driving License', Icons.card_membership_outlined, isAr),
                  _buildDocCard(context, isAr ? 'رخصة السيارة' : 'Car License', Icons.directions_car_filled_outlined, isAr),
                  _buildDocCard(context, isAr ? 'سيلفي' : 'Selfie', Icons.face_rounded, isAr),
                  _buildDocCard(context, isAr ? 'صور السيارة' : 'Car Photos', Icons.camera_alt_outlined, isAr),
                ],
              ),

              const SizedBox(height: AppDimens.space20),

              // Driver Details Card (Page 71)
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(isAr ? 'الاسم' : 'Driver Name', widget.req.driverName),
                    const Divider(height: 16),
                    _buildDetailRow(isAr ? 'المحافظة' : 'Governorate', widget.req.governorate),
                    const Divider(height: 16),
                    _buildDetailRow(isAr ? 'السيارة' : 'Vehicle', widget.req.carModel),
                    const Divider(height: 16),
                    _buildDetailRow(isAr ? 'اللوحة' : 'License Plate', widget.req.carPlate),
                    const Divider(height: 16),
                    _buildDetailRow(isAr ? 'انتهاء الرخصة' : 'Expiry Date', widget.req.licenseExpiryDate),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space16),

              // Checklist Callout Box (Page 71)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.goldSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.navy, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'راجع: الاسم يطابق البطاقة والرخصة، الصورة تطابق السيلفي، الرخصة سارية.'
                            : 'Verify: Name matches ID & license, photo matches selfie, license is valid.',
                        style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Rejection Form (Page 71 - نافذة الرفض)
              if (_isRejecting) ...[
                const SizedBox(height: AppDimens.space20),
                Text(
                  isAr ? 'سبب الرفض' : 'Rejection Reason',
                  style: AppTypography.label().copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    'صورة غير واضحة',
                    'مستند منتهي',
                    'بيانات غير مطابقة',
                    'أخرى',
                  ].map((reason) {
                    final isSel = _rejectReason == reason;
                    return ChoiceChip(
                      label: Text(reason),
                      selected: isSel,
                      selectedColor: AppColors.coral,
                      backgroundColor: AppColors.sand,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setState(() => _rejectReason = reason),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _rejectMsgController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رسالة للسائق' : 'Message to driver',
                    filled: true,
                    fillColor: AppColors.sand,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr ? 'السبب هيوصل للسائق ويتسجل في سجل التدقيق.' : 'Reason will be dispatched to driver and recorded in audit log.',
                  style: AppTypography.label(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isRejecting = false),
                      child: Text(isAr ? 'رجوع' : 'Back'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        admin.rejectDriver(widget.req.id, _rejectReason, _rejectMsgController.text.trim());
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isAr ? 'تم رفض توثيق السائق وإرسال الملاحظات' : 'Driver verification rejected with feedback'),
                            backgroundColor: AppColors.coral,
                          ),
                        );
                      },
                      child: Text(isAr ? 'تأكيد الرفض' : 'Confirm Rejection'),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: AppDimens.space24),
                // Action Buttons: قبول / رفض (Page 71)
                Row(
                  children: [
                    Expanded(
                      child: MashwarButton(
                        text: isAr ? 'قبول' : 'Approve',
                        onPressed: () {
                          admin.acceptDriver(widget.req.id);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isAr ? 'تم قبول السائق. وصله إشعار' : 'Driver approved. Notification sent.'),
                              backgroundColor: AppColors.teal,
                            ),
                          );
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

  Widget _buildDocCard(BuildContext context, String label, IconData icon, bool isAr) {
    return InkWell(
      onTap: () => _showDocPreview(context, label, icon),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 104,
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDisabled),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.navy, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 2),
            Text(
              isAr ? 'انقر للمعاينة' : 'Inspect',
              style: const TextStyle(fontSize: 9, color: AppColors.teal, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocPreview(BuildContext context, String label, IconData icon) {
    final isAr = context.read<SettingsProvider>().isArabic;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$label - ${widget.req.driverName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF0F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 64, color: AppColors.navy.withValues(alpha: 0.6)),
                          const SizedBox(height: 12),
                          Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr ? 'مستند رسمي عالي الدقة موثق لدى مشوار' : 'High resolution official document verified by MASHWAR',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAr ? 'سارية ومعتمدة' : 'Valid & Verified',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(isAr ? 'إغلاق المعاينة' : 'Close Preview'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy)),
      ],
    );
  }
}
