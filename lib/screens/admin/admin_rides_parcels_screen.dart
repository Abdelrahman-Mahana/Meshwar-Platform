import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../data/models/admin_platform_models.dart';
import '../../data/models/board_ad_model.dart';
import '../../state/admin_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/admin_ui_kit.dart';

class AdminRidesParcelsScreen extends StatefulWidget {
  const AdminRidesParcelsScreen({super.key});

  @override
  State<AdminRidesParcelsScreen> createState() =>
      _AdminRidesParcelsScreenState();
}

class _AdminRidesParcelsScreenState extends State<AdminRidesParcelsScreen> {
  static const List<String> _validRideStatuses = [
    'منشورة',
    'مكتملة الحجز',
    'ملغاة',
    'جارية',
  ];

  int _selectedSubTab = 0; // 0: رحلات, 1: حجوزات, 2: طرود, 3: لوحة الخدمات, 4: حسابات B2B
  String _selectedGov = 'all';
  String _selectedStatus = 'all';

  String _localizeRideStatus(String raw, bool isAr) {
    if (isAr) return raw;
    switch (raw.trim()) {
      case 'منشورة':
        return 'Published';
      case 'مكتملة الحجز':
        return 'Fully Booked';
      case 'ملغاة':
        return 'Cancelled';
      case 'جارية':
        return 'In Progress';
      case 'مؤكد':
        return 'Confirmed';
      case 'تم التسليم':
        return 'Delivered';
      case 'متنازع عليه':
        return 'Disputed';
      default:
        return raw;
    }
  }

  String _localizeBoardStatus(BoardAdStatus status, bool isAr) {
    switch (status) {
      case BoardAdStatus.active:
        return isAr ? 'نشط' : 'Active';
      case BoardAdStatus.offerSent:
        return isAr ? 'عرض مرسل' : 'Offer Sent';
      case BoardAdStatus.completed:
        return isAr ? 'مكتمل' : 'Completed';
      case BoardAdStatus.expired:
        return isAr ? 'منتهي' : 'Expired';
      case BoardAdStatus.cancelled:
        return isAr ? 'ملغي' : 'Cancelled';
    }
  }

  void _showRideDetail(BuildContext context, AdminRideItem item, bool isAr) {
    final admin = context.read<AdminProvider>();
    String targetStatus = _validRideStatuses.contains(item.status)
        ? item.status
        : _validRideStatuses.first;
    final reasonController = TextEditingController(text: item.statusOverrideReason ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
          title: Text('${item.id} · ${item.route}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${isAr ? "السائق:" : "Driver:"} ${item.driver}'),
                Text('${isAr ? "الموعد:" : "Time:"} ${item.time}'),
                Text('${isAr ? "المقاعد:" : "Seats:"} ${item.seats}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: targetStatus,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الحالة' : 'Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _validRideStatuses
                      .map(
                        (st) => DropdownMenuItem(
                          value: st,
                          child: Text(_localizeRideStatus(st, isAr)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => targetStatus = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isAr ? 'سبب التعديل اليدوي (إجباري)' : 'Override Reason (Mandatory)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'يرجى إدخال سبب التعديل اليدوي' : 'Please enter an override reason',
                      ),
                      backgroundColor: AppColors.coral,
                    ),
                  );
                  return;
                }
                admin.manualUpdateRideStatus(item.id, targetStatus, reason);
                Navigator.of(ctx).pop();
              },
              child: Text(isAr ? 'تأكيد التعديل' : 'Save Override'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reasonController.dispose();
      });
    });
  }

  void _showAddB2BDialog(BuildContext context, bool isAr) {
    final admin = context.read<AdminProvider>();
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final sectorCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final creditCtrl = TextEditingController(text: '10000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAr ? 'إضافة حساب أعمال (Mashwar Business)' : 'Add Mashwar Business B2B Account'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameArCtrl,
                  decoration: InputDecoration(labelText: isAr ? 'اسم الشركة (عربي)' : 'Company (Arabic)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameEnCtrl,
                  decoration: InputDecoration(labelText: isAr ? 'اسم الشركة (إنجليزي)' : 'Company (English)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sectorCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'القطاع' : 'Sector',
                    hintText: isAr ? 'مقاولات وتوريد' : 'Contracting & Supply',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الهاتف' : 'Phone',
                          hintText: '+974 44XX XXXX',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: creditCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: isAr ? 'الحد الائتماني ر.ق' : 'Credit Limit (QAR)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
            onPressed: () {
              if (nameArCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(
                    content: Text(
                      isAr ? 'يرجى إدخال اسم الشركة' : 'Please enter company name',
                    ),
                    backgroundColor: AppColors.coral,
                  ),
                );
                return;
              }
              final sector = sectorCtrl.text.trim().isNotEmpty
                  ? sectorCtrl.text.trim()
                  : (isAr ? 'مقاولات وتوريد' : 'Contracting & Supply');
              admin.addB2BAccount(
                AdminB2BAccountItem(
                  id: 'b2b_${DateTime.now().millisecondsSinceEpoch}',
                  companyAr: nameArCtrl.text.trim(),
                  companyEn: nameEnCtrl.text.trim().isEmpty ? nameArCtrl.text.trim() : nameEnCtrl.text.trim(),
                  sectorAr: sector,
                  sectorEn: sector,
                  municipalityAr: 'الدوحة ↔ لوسيل',
                  municipalityEn: 'Doha ↔ Lusail',
                  monthlyRuns: 20,
                  creditLimitQar: int.tryParse(creditCtrl.text.trim()) ?? 10000,
                  contactPhone: phoneCtrl.text.trim(),
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: Text(isAr ? 'تسجيل الشركة' : 'Create B2B'),
          ),
        ],
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameArCtrl.dispose();
        nameEnCtrl.dispose();
        sectorCtrl.dispose();
        phoneCtrl.dispose();
        creditCtrl.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<SettingsProvider>().isArabic;
    final admin = context.watch<AdminProvider>();
    final t = AdminThemeTokens.of(context);

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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: t.border),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _segment(isAr ? 'رحلات (${admin.rides.length})' : 'Rides (${admin.rides.length})', 0, t),
                        _segment(isAr ? 'حجوزات (${admin.bookings.length})' : 'Bookings (${admin.bookings.length})', 1, t),
                        _segment(isAr ? 'طرود (${admin.parcels.length})' : 'Parcels (${admin.parcels.length})', 2, t),
                        _segment(isAr ? 'اللوحة (${admin.boardAds.length})' : 'Board (${admin.boardAds.length})', 3, t),
                        _segment(isAr ? 'أعمال B2B (${admin.b2bAccounts.length})' : 'B2B (${admin.b2bAccounts.length})', 4, t),
                      ],
                    ),
                  ),
                ),
                if (_selectedSubTab == 4)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.qatarMaroon, foregroundColor: Colors.white),
                    icon: const Icon(Icons.add_business_rounded, size: 17),
                    label: Text(isAr ? 'إضافة شركة B2B' : 'Add B2B Client'),
                    onPressed: () => _showAddB2BDialog(context, isAr),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _dropdownFilter(
                        label: isAr ? 'البلدية' : 'Gov',
                        value: _selectedGov,
                        items: const [
                          ('all', 'الكل', 'All'),
                          ('بلدية الدوحة', 'بلدية الدوحة', 'Doha Municipality'),
                          ('بلدية الوكرة', 'بلدية الوكرة', 'Al Wakrah'),
                          ('بلدية الريان', 'بلدية الريان', 'Al Rayyan'),
                          ('بلدية الخور والذخيرة', 'بلدية الخور والذخيرة', 'Al Khor & Al Thakhira'),
                          ('بلدية الشيحانية', 'بلدية الشيحانية', 'Al Shahaniya'),
                        ],
                        isAr: isAr,
                        t: t,
                        onChanged: (v) => setState(() => _selectedGov = v),
                      ),
                      if (_selectedSubTab == 0)
                        _dropdownFilter(
                          label: isAr ? 'الحالة' : 'Status',
                          value: _selectedStatus,
                          items: const [
                            ('all', 'الكل', 'All'),
                            ('منشورة', 'منشورة', 'Published'),
                            ('مكتملة الحجز', 'مكتملة الحجز', 'Fully Booked'),
                            ('ملغاة', 'ملغاة', 'Cancelled'),
                            ('جارية', 'جارية', 'In Progress'),
                          ],
                          isAr: isAr,
                          t: t,
                          onChanged: (v) => setState(() => _selectedStatus = v),
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
                if (_selectedSubTab == 0) _buildRidesView(context, admin, isAr, t),
                if (_selectedSubTab == 1) _buildBookingsView(context, admin, isAr, t),
                if (_selectedSubTab == 2) _buildParcelsView(context, admin, isAr, t),
                if (_selectedSubTab == 3) _buildBoardAdsView(context, admin, isAr, t),
                if (_selectedSubTab == 4) _buildB2BView(context, admin, isAr, t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesView(BuildContext context, AdminProvider admin, bool isAr, AdminThemeTokens t) {
    final filtered = admin.rides.where((r) {
      if (_selectedGov != 'all' && r.governorate != _selectedGov) return false;
      if (_selectedStatus != 'all' && r.status != _selectedStatus) return false;
      return true;
    }).toList();

    return AdminAdaptiveDataView<AdminRideItem>(
      items: filtered,
      minTableWidth: 820,
      columns: [
        DataColumn(label: Text(isAr ? 'الرقم' : 'ID')),
        DataColumn(label: Text(isAr ? 'السائق' : 'Driver')),
        DataColumn(label: Text(isAr ? 'المسار' : 'Route')),
        DataColumn(label: Text(isAr ? 'الموعد' : 'Time')),
        DataColumn(label: Text(isAr ? 'المقاعد' : 'Seats')),
        DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
        DataColumn(label: Text(isAr ? 'تحكم' : 'Action')),
      ],
      buildRow: (ride) {
        final bType = ride.status == 'ملغاة'
            ? BadgeType.rejected
            : (ride.status == 'مكتملة الحجز' ? BadgeType.pending : BadgeType.verified);
        return DataRow(
          cells: [
            DataCell(Text(ride.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
            DataCell(Text(ride.driver)),
            DataCell(Text(ride.route)),
            DataCell(Text(ride.time)),
            DataCell(Text(ride.seats, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(MashwarBadge(type: bType, customLabel: ride.status)),
            DataCell(
              OutlinedButton(
                onPressed: () => _showRideDetail(context, ride, isAr),
                child: Text(isAr ? 'تعديل' : 'Override', style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        );
      },
      buildMobileCard: (ctx, r) => _mobileOrderCard(
        t: t,
        id: r.id,
        title: r.route,
        subtitle: '${r.driver} · ${r.time} · ${r.seats}',
        status: r.status,
        actionLabel: isAr ? 'تعديل الحالة' : 'Override',
        onAction: () => _showRideDetail(context, r, isAr),
      ),
    );
  }

  Widget _buildBookingsView(BuildContext context, AdminProvider admin, bool isAr, AdminThemeTokens t) {
    final filtered = admin.bookings.where((b) => _selectedGov == 'all' || b.governorate == _selectedGov).toList();
    return AdminAdaptiveDataView<AdminBookingItem>(
      items: filtered,
      minTableWidth: 820,
      columns: [
        DataColumn(label: Text(isAr ? 'الرقم' : 'ID')),
        DataColumn(label: Text(isAr ? 'الراكب' : 'Passenger')),
        DataColumn(label: Text(isAr ? 'السائق' : 'Driver')),
        DataColumn(label: Text(isAr ? 'المسار' : 'Route')),
        DataColumn(label: Text(isAr ? 'المبلغ' : 'Fare')),
        DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
      ],
      buildRow: (b) => DataRow(
        cells: [
          DataCell(Text(b.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
          DataCell(Text(b.passenger)),
          DataCell(Text(b.driver)),
          DataCell(Text(b.route)),
          DataCell(Text('${b.fare.toStringAsFixed(0)} QAR', style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(MashwarBadge(type: b.status == 'مؤكد' ? BadgeType.verified : BadgeType.rejected, customLabel: b.status)),
        ],
      ),
      buildMobileCard: (ctx, b) => _mobileOrderCard(
        t: t,
        id: b.id,
        title: b.route,
        subtitle: '${b.passenger} -> ${b.driver} · ${b.fare.toStringAsFixed(0)} QAR',
        status: b.status,
      ),
    );
  }

  Widget _buildParcelsView(BuildContext context, AdminProvider admin, bool isAr, AdminThemeTokens t) {
    final filtered = admin.parcels.where((p) => _selectedGov == 'all' || p.governorate == _selectedGov).toList();
    return AdminAdaptiveDataView<AdminParcelItem>(
      items: filtered,
      minTableWidth: 860,
      columns: [
        DataColumn(label: Text(isAr ? 'الرقم' : 'ID')),
        DataColumn(label: Text(isAr ? 'المرسل / المستلم' : 'Parties')),
        DataColumn(label: Text(isAr ? 'المسار' : 'Route')),
        DataColumn(label: Text(isAr ? 'الأجر' : 'Fee')),
        DataColumn(label: Text('OTP')),
        DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
      ],
      buildRow: (p) => DataRow(
        cells: [
          DataCell(Text(p.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
          DataCell(Text('${p.sender} -> ${p.receiver}')),
          DataCell(Text(p.route)),
          DataCell(Text('${p.fee.toStringAsFixed(0)} QAR', style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(p.pin, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: t.accentTeal))),
          DataCell(MashwarBadge(type: p.status == 'تم التسليم' ? BadgeType.verified : (p.status == 'متنازع عليه' ? BadgeType.rejected : BadgeType.pending), customLabel: p.status)),
        ],
      ),
      buildMobileCard: (ctx, p) => _mobileOrderCard(
        t: t,
        id: p.id,
        title: '${p.route} (${p.item})',
        subtitle: '${p.sender} -> ${p.receiver} · OTP: ${p.pin}',
        status: p.status,
      ),
    );
  }

  Widget _buildBoardAdsView(BuildContext context, AdminProvider admin, bool isAr, AdminThemeTokens t) {
    return AdminAdaptiveDataView<BoardAdModel>(
      items: admin.boardAds,
      minTableWidth: 860,
      columns: [
        DataColumn(label: Text(isAr ? 'الخدمة' : 'Service')),
        DataColumn(label: Text(isAr ? 'الناشر' : 'Author')),
        DataColumn(label: Text(isAr ? 'المسار' : 'Route')),
        DataColumn(label: Text(isAr ? 'الأتعاب' : 'Fee')),
        DataColumn(label: Text(isAr ? 'الحالة' : 'Status')),
        DataColumn(label: Text(isAr ? 'رقابة' : 'Moderate')),
      ],
      buildRow: (ad) => DataRow(
        cells: [
          DataCell(Text(ad.typeTitle(isAr), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          DataCell(Text(ad.authorName)),
          DataCell(Text(ad.route)),
          DataCell(Text('${ad.priceOrBudget} ${isAr ? "ر.ق" : "QAR"}', style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(MashwarBadge(type: ad.status == BoardAdStatus.active ? BadgeType.verified : BadgeType.pending, customLabel: _localizeBoardStatus(ad.status, isAr))),
          DataCell(
            OutlinedButton(
              onPressed: () {
                final next = ad.status == BoardAdStatus.active ? BoardAdStatus.expired : BoardAdStatus.active;
                admin.moderateBoardAd(ad.id, next, 'إجراء إداري من اللوحة');
              },
              child: Text(ad.status == BoardAdStatus.active ? (isAr ? 'إيقاف' : 'Pause') : (isAr ? 'تفعيل' : 'Activate'), style: const TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
      buildMobileCard: (ctx, ad) => _mobileOrderCard(
        t: t,
        id: ad.typeTitle(isAr),
        title: ad.route,
        subtitle: '${ad.authorName} · ${ad.priceOrBudget} ${isAr ? "ر.ق" : "QAR"}',
        status: _localizeBoardStatus(ad.status, isAr),
        actionLabel: ad.status == BoardAdStatus.active ? (isAr ? 'إيقاف الإعلان' : 'Pause') : (isAr ? 'تفعيل' : 'Activate'),
        onAction: () {
          final next = ad.status == BoardAdStatus.active ? BoardAdStatus.expired : BoardAdStatus.active;
          admin.moderateBoardAd(ad.id, next, 'إجراء إداري من اللوحة');
        },
      ),
    );
  }

  Widget _buildB2BView(BuildContext context, AdminProvider admin, bool isAr, AdminThemeTokens t) {
    return AdminAdaptiveDataView<AdminB2BAccountItem>(
      items: admin.b2bAccounts,
      minTableWidth: 840,
      columns: [
        DataColumn(label: Text(isAr ? 'الشركة' : 'Company')),
        DataColumn(label: Text(isAr ? 'القطاع' : 'Sector')),
        DataColumn(label: Text(isAr ? 'الممر الأساسي' : 'Primary Corridor')),
        DataColumn(label: Text(isAr ? 'عمليات/شهر' : 'Monthly Runs')),
        DataColumn(label: Text(isAr ? 'الحد الائتماني' : 'Credit Cap')),
        DataColumn(label: Text(isAr ? 'التحكم' : 'Status')),
      ],
      buildRow: (b) => DataRow(
        cells: [
          DataCell(Text(isAr ? b.companyAr : b.companyEn, style: const TextStyle(fontWeight: FontWeight.w700))),
          DataCell(Text(isAr ? b.sectorAr : b.sectorEn, style: const TextStyle(fontSize: 12))),
          DataCell(Text(isAr ? b.municipalityAr : b.municipalityEn, style: const TextStyle(fontSize: 12))),
          DataCell(Text('${b.monthlyRuns}')),
          DataCell(Text('${b.creditLimitQar} QAR', style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(
            Switch(
              value: b.status == 'active',
              activeThumbColor: t.accentTeal,
              onChanged: (_) => admin.toggleB2BAccountStatus(b.id),
            ),
          ),
        ],
      ),
      buildMobileCard: (ctx, b) => _mobileOrderCard(
        t: t,
        id: b.id,
        title: isAr ? b.companyAr : b.companyEn,
        subtitle: '${isAr ? b.sectorAr : b.sectorEn} · ${b.creditLimitQar} QAR',
        status: b.status,
        actionLabel: b.status == 'active' ? (isAr ? 'تعليق' : 'Suspend') : (isAr ? 'تفعيل' : 'Activate'),
        onAction: () => admin.toggleB2BAccountStatus(b.id),
      ),
    );
  }

  Widget _mobileOrderCard({
    required AdminThemeTokens t,
    required String id,
    required String title,
    required String subtitle,
    required String status,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
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
              Expanded(child: Text(id, style: TextStyle(color: t.accentPrimary, fontWeight: FontWeight.w800, fontSize: 12))),
              Text(status, style: TextStyle(color: t.accentTeal, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: t.textSecondary, fontSize: 11)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton(onPressed: onAction, child: Text(actionLabel, style: const TextStyle(fontSize: 11))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dropdownFilter({
    required String label,
    required String value,
    required List<(String key, String ar, String en)> items,
    required bool isAr,
    required AdminThemeTokens t,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.any((item) => item.$1 == value)
        ? value
        : items.first.$1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: t.textPrimary),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item.$1,
                  child: Text('$label: ${isAr ? item.$2 : item.$3}'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _segment(String title, int index, AdminThemeTokens t) {
    final isSel = _selectedSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSel ? Colors.white : t.textPrimary),
        ),
      ),
    );
  }
}
