import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/settings_provider.dart';
import '../../state/admin_provider.dart';

class AdminRidesParcelsScreen extends StatefulWidget {
  const AdminRidesParcelsScreen({super.key});

  @override
  State<AdminRidesParcelsScreen> createState() => _AdminRidesParcelsScreenState();
}

class _AdminRidesParcelsScreenState extends State<AdminRidesParcelsScreen> {
  int _selectedSubTab = 0; // 0: رحلات, 1: حجوزات, 2: طرود
  String _selectedGov = 'الكل';
  String _selectedStatus = 'الكل';
  String _selectedDate = 'آخر 7 أيام';

  void _showRideDetail(BuildContext context, AdminRideItem item) {
    final isAr = context.read<SettingsProvider>().isArabic;
    final admin = context.read<AdminProvider>();
    String targetStatus = item.status;
    final reasonController = TextEditingController(text: item.statusOverrideReason ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
            title: Text('${item.id} · ${item.route}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${isAr ? "السائق:" : "Driver:"} ${item.driver}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('${isAr ? "الموعد:" : "Time:"} ${item.time}'),
                  const SizedBox(height: 6),
                  Text('${isAr ? "الكراسي:" : "Seats:"} ${item.seats}'),
                  const SizedBox(height: 6),
                  Text('${isAr ? "المحافظة:" : "Governorate:"} ${item.governorate}'),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    isAr ? 'تعديل حالة الرحلة يدوياً:' : 'Manual Status Override:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navy),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: targetStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.sand,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['منشورة', 'مكتملة الحجز', 'ملغاة', 'جارية'].map((st) {
                      return DropdownMenuItem(value: st, child: Text(st));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => targetStatus = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isAr ? 'سبب التعديل اليدوي (إجباري)' : 'Override Reason (Mandatory)',
                      filled: true,
                      fillColor: AppColors.sand,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      isAr
                          ? 'تعديل أي حالة يدوياً يتطلب كتابة السبب وسيتم توثيقه في سجل التدقيق الرقابي.'
                          : 'Manual state changes require a documented reason recorded in the immutable audit log.',
                      style: AppTypography.label(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إلغاء' : 'Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isAr ? 'برجاء كتابة سبب التعديل' : 'Please provide override reason')),
                    );
                    return;
                  }
                  admin.manualUpdateRideStatus(item.id, targetStatus, reason);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? 'تم تعديل حالة الرحلة وتوثيق السبب في سجل التدقيق' : 'Status overridden and logged to audit trail'),
                      backgroundColor: AppColors.teal,
                    ),
                  );
                },
                child: Text(isAr ? 'تأكيد التعديل' : 'Save Override'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBookingDetail(BuildContext context, AdminBookingItem item) {
    final isAr = context.read<SettingsProvider>().isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
        title: Text('${item.id} · ${item.route}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${isAr ? "الراكب:" : "Passenger:"} ${item.passenger}'),
            const SizedBox(height: 4),
            Text('${isAr ? "السائق:" : "Driver:"} ${item.driver}'),
            const SizedBox(height: 4),
            Text('${isAr ? "الموعد:" : "Time:"} ${item.time}'),
            const SizedBox(height: 4),
            Text('${isAr ? "عدد المقاعد:" : "Seats:"} ${item.seats}'),
            const SizedBox(height: 4),
            Text('${isAr ? "المبلغ الإجمالي:" : "Fare:"} ${item.fare.toStringAsFixed(0)} ${isAr ? "ج.م" : "EGP"}'),
            const SizedBox(height: 4),
            Text('${isAr ? "الحالة:" : "Status:"} ${item.status}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إغلاق' : 'Close')),
        ],
      ),
    );
  }

  void _showParcelDetail(BuildContext context, AdminParcelItem item) {
    final isAr = context.read<SettingsProvider>().isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
        title: Text('${item.id} · ${item.route}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${isAr ? "المرسل:" : "Sender:"} ${item.sender}'),
            const SizedBox(height: 4),
            Text('${isAr ? "المستلم:" : "Receiver:"} ${item.receiver}'),
            const SizedBox(height: 4),
            Text('${isAr ? "السائق:" : "Driver:"} ${item.driver}'),
            const SizedBox(height: 4),
            Text('${isAr ? "محتوى الطرد:" : "Item:"} ${item.item}'),
            const SizedBox(height: 4),
            Text('${isAr ? "الأجر:" : "Fee:"} ${item.fee.toStringAsFixed(0)} ${isAr ? "ج.م" : "EGP"}'),
            const SizedBox(height: 4),
            Text('${isAr ? "كود التسليم:" : "Handover PIN:"} ${item.pin}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal)),
            const SizedBox(height: 4),
            Text('${isAr ? "الحالة:" : "Status:"} ${item.status}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إغلاق' : 'Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub-tabs & Filter Dropdowns (Page 73)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // 3 Segmented sub-tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderDisabled),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSegment(isAr ? 'رحلات' : 'Rides', 0),
                    _buildSegment(isAr ? 'حجوزات' : 'Bookings', 1),
                    _buildSegment(isAr ? 'طرود' : 'Parcels', 2),
                  ],
                ),
              ),

              // Interactive Filter Dropdowns (Page 73 - Responsive Wrap)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDropdownFilter(
                    label: isAr ? 'المحافظة' : 'Governorate',
                    value: _selectedGov,
                    items: ['الكل', 'كفر الشيخ', 'الغربية', 'القاهرة', 'الإسكندرية'],
                    onChanged: (val) => setState(() => _selectedGov = val),
                  ),
                  _buildDropdownFilter(
                    label: isAr ? 'الحالة' : 'Status',
                    value: _selectedStatus,
                    items: ['الكل', 'منشورة', 'مكتملة الحجز', 'ملغاة', 'جارية'],
                    onChanged: (val) => setState(() => _selectedStatus = val),
                  ),
                  _buildDropdownFilter(
                    label: isAr ? 'التاريخ' : 'Date',
                    value: _selectedDate,
                    items: ['اليوم', 'آخر 7 أيام', 'آخر 30 يوم'],
                    onChanged: (val) => setState(() => _selectedDate = val),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppDimens.space16),

          // Main Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              border: Border.all(color: AppColors.borderDisabled),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedSubTab == 0) _buildRidesTable(context, admin, isAr),
                if (_selectedSubTab == 1) _buildBookingsTable(context, admin, isAr),
                if (_selectedSubTab == 2) _buildParcelsTable(context, admin, isAr),

                // Note at bottom of Page 73
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppDimens.radiusCard)),
                  ),
                  child: Center(
                    child: Text(
                      isAr
                          ? 'تعديل أي حالة يدوياً يتطلب كتابة السبب.'
                          : 'Manual state modifications require a mandatory documented reason.',
                      style: AppTypography.label(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesTable(BuildContext context, AdminProvider admin, bool isAr) {
    final filtered = admin.rides.where((r) {
      if (_selectedGov != 'الكل' && r.governorate != _selectedGov) return false;
      if (_selectedStatus != 'الكل' && r.status != _selectedStatus) return false;
      return true;
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 800),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.sand),
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
          columns: [
            DataColumn(label: Text(isAr ? 'الرقم' : 'ID', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'السائق' : 'Driver', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'المسار' : 'Route', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الموعد' : 'Date & Time', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الكراسي' : 'Seats', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الإجراء' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filtered.map((ride) {
            BadgeType bType = BadgeType.verified;
            if (ride.status == 'ملغاة') bType = BadgeType.rejected;
            if (ride.status == 'مكتملة الحجز') bType = BadgeType.pending;

            return DataRow(
              cells: [
                DataCell(Text(ride.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                DataCell(Text(ride.driver, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(ride.route)),
                DataCell(Text(ride.time)),
                DataCell(Text(ride.seats, style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(MashwarBadge(type: bType, customLabel: ride.status)),
                DataCell(
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.navy),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    onPressed: () => _showRideDetail(context, ride),
                    child: Text(isAr ? 'عرض' : 'View', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBookingsTable(BuildContext context, AdminProvider admin, bool isAr) {
    final filtered = admin.bookings.where((b) {
      if (_selectedGov != 'الكل' && b.governorate != _selectedGov) return false;
      return true;
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 800),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.sand),
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
          columns: [
            DataColumn(label: Text(isAr ? 'الرقم' : 'ID', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الراكب' : 'Passenger', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'السائق' : 'Driver', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'المسار' : 'Route', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الموعد' : 'Date & Time', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'المقاعد' : 'Seats', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'المبلغ' : 'Fare', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الإجراء' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filtered.map((b) {
            BadgeType bType = b.status == 'مؤكد' ? BadgeType.verified : (b.status == 'ملغى' ? BadgeType.rejected : BadgeType.pending);
            return DataRow(
              cells: [
                DataCell(Text(b.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                DataCell(Text(b.passenger, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(b.driver)),
                DataCell(Text(b.route)),
                DataCell(Text(b.time)),
                DataCell(Text('${b.seats}')),
                DataCell(Text('${b.fare.toStringAsFixed(0)} ${isAr ? "ج" : "EGP"}', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(MashwarBadge(type: bType, customLabel: b.status)),
                DataCell(
                  OutlinedButton(
                    onPressed: () => _showBookingDetail(context, b),
                    child: Text(isAr ? 'عرض' : 'View', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildParcelsTable(BuildContext context, AdminProvider admin, bool isAr) {
    final filtered = admin.parcels.where((p) {
      if (_selectedGov != 'الكل' && p.governorate != _selectedGov) return false;
      return true;
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 800),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.sand),
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
          columns: [
            DataColumn(label: Text(isAr ? 'الرقم' : 'ID', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'المرسل' : 'Sender', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'المستلم' : 'Receiver', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'السائق' : 'Driver', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'المسار' : 'Route', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الأجر' : 'Fee', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'كود التسليم' : 'PIN', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(isAr ? 'الإجراء' : 'Action', style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filtered.map((p) {
            BadgeType bType = p.status == 'تم التسليم' ? BadgeType.verified : (p.status == 'متنازع عليه' ? BadgeType.rejected : BadgeType.pending);
            return DataRow(
              cells: [
                DataCell(Text(p.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                DataCell(Text(p.sender)),
                DataCell(Text(p.receiver)),
                DataCell(Text(p.driver)),
                DataCell(Text(p.route)),
                DataCell(Text('${p.fee.toStringAsFixed(0)} ${isAr ? "ج" : "EGP"}', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(p.pin, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.teal))),
                DataCell(MashwarBadge(type: bType, customLabel: p.status)),
                DataCell(
                  OutlinedButton(
                    onPressed: () => _showParcelDetail(context, p),
                    child: Text(isAr ? 'عرض' : 'View', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDisabled),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.navy, size: 20),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text('$label: $item'));
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildSegment(String title, int index) {
    final isSel = _selectedSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSel ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
