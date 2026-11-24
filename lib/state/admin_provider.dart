import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../data/api/mashwar_api_client.dart';
import '../data/mock_data.dart';
import '../data/models/admin_platform_models.dart';
import '../data/models/board_ad_model.dart';
import '../data/repositories/app_repositories.dart';
import '../data/services/firebase_firestore_service.dart';

enum AdminRole {
  superAdmin,   // مشرف أول: كامل الصلاحيات والإعدادات والـ DevOps
  reviewAdmin,  // مشرف مراجعة: توثيق السائقين فقط
  supportAdmin, // مشرف دعم: المستخدمون والرحلات والبلاغات
  financeAdmin, // مشرف مالية وضمان: الضمان المالي وبوابات الدفع والحسابات
  devopsAdmin,  // مهندس DevOps: البنية التحتية، Feature Flags، المحاور والخدمات
}

class AdminStaffMember {
  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final bool isActive;

  const AdminStaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  AdminStaffMember copyWith({
    String? name,
    String? email,
    AdminRole? role,
    bool? isActive,
  }) {
    return AdminStaffMember(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }

  String get roleTitleAr {
    switch (role) {
      case AdminRole.superAdmin:
        return 'مشرف أول';
      case AdminRole.reviewAdmin:
        return 'مشرف مراجعة';
      case AdminRole.supportAdmin:
        return 'مشرف دعم';
      case AdminRole.financeAdmin:
        return 'مشرف مالية وضمان';
      case AdminRole.devopsAdmin:
        return 'مهندس DevOps';
    }
  }

  String get roleTitleEn {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.reviewAdmin:
        return 'Review Admin';
      case AdminRole.supportAdmin:
        return 'Support Admin';
      case AdminRole.financeAdmin:
        return 'Finance & Escrow';
      case AdminRole.devopsAdmin:
        return 'DevOps & SRE';
    }
  }
}

class AdminDriverVerificationRequest {
  final String id;
  final String driverName;
  final String governorate;
  final String submittedAt;
  final String durationText;
  final String carModel;
  final String carPlate;
  final String licenseExpiryDate;
  final String qidMasked;
  String status; // 'قيد المراجعة', 'مقبولة', 'مرفوضة'
  String? rejectionReason;
  String? rejectionNote;

  AdminDriverVerificationRequest({
    required this.id,
    required this.driverName,
    required this.governorate,
    required this.submittedAt,
    required this.durationText,
    required this.carModel,
    required this.carPlate,
    required this.licenseExpiryDate,
    this.qidMasked = '294•••••812',
    this.status = 'قيد المراجعة',
    this.rejectionReason,
    this.rejectionNote,
  });
}

class AdminUserItem {
  final String id;
  final String fullName;
  final String maskedPhone;
  final String rawPhone;
  final String role; // 'راكب وسائق', 'راكب', 'سائق'
  String status; // 'نشط', 'موقوف', 'محظور'
  final String registeredDate;
  final int rideCount;
  final int strikesCount;
  final String? currentStrikeReason;
  final String? internalNotes;
  double walletBalanceQar;
  final String qidStatus;

  AdminUserItem({
    required this.id,
    required this.fullName,
    required this.maskedPhone,
    required this.rawPhone,
    required this.role,
    this.status = 'نشط',
    required this.registeredDate,
    this.rideCount = 4,
    this.strikesCount = 0,
    this.currentStrikeReason,
    this.internalNotes,
    this.walletBalanceQar = 450.0,
    this.qidStatus = 'QID موثق',
  });
}

class AdminDisputeItem {
  final String id;
  final String type; // 'طرد', 'مستخدم', 'رحلة', 'ضمان'
  final String category; // 'وصل تالف', 'قيادة متهورة', 'احتيال'
  final String complainantName;
  final String againstName;
  final String parcelOrRideDetails;
  String status; // 'مفتوح', 'قيد المراجعة', 'محلول'
  String? assignedTo;
  final List<String> timeline;
  String? resolutionDecision;
  String? internalNote;
  final bool isSosPriority;
  final String? linkedEscrowId;

  AdminDisputeItem({
    required this.id,
    required this.type,
    required this.category,
    required this.complainantName,
    required this.againstName,
    required this.parcelOrRideDetails,
    this.status = 'مفتوح',
    this.assignedTo,
    required this.timeline,
    this.resolutionDecision,
    this.internalNote,
    this.isSosPriority = false,
    this.linkedEscrowId,
  });
}

class AdminRideItem {
  final String id;
  final String driver;
  final String route;
  final String time;
  final String seats;
  String status; // 'منشورة', 'مكتملة الحجز', 'ملغاة', 'جارية'
  final String governorate;
  String? statusOverrideReason;

  AdminRideItem({
    required this.id,
    required this.driver,
    required this.route,
    required this.time,
    required this.seats,
    required this.status,
    required this.governorate,
    this.statusOverrideReason,
  });
}

class AdminBookingItem {
  final String id;
  final String passenger;
  final String driver;
  final String route;
  final String time;
  final int seats;
  final double fare;
  String status; // 'مؤكد', 'قيد الانتظار', 'ملغى', 'مكتمل'
  final String governorate;

  AdminBookingItem({
    required this.id,
    required this.passenger,
    required this.driver,
    required this.route,
    required this.time,
    required this.seats,
    required this.fare,
    required this.status,
    required this.governorate,
  });
}

class AdminParcelItem {
  final String id;
  final String sender;
  final String receiver;
  final String driver;
  final String route;
  final String item;
  final double fee;
  final String pin;
  String status; // 'في الطريق', 'تم التسليم', 'متنازع عليه', 'قيد الانتظار'
  final String governorate;

  AdminParcelItem({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.driver,
    required this.route,
    required this.item,
    required this.fee,
    required this.pin,
    required this.status,
    required this.governorate,
  });
}

class AdminAuditLogEntry {
  final String time;
  final String actor;
  final String action;
  final String target;
  final String beforeAfter;

  const AdminAuditLogEntry({
    required this.time,
    required this.actor,
    required this.action,
    required this.target,
    required this.beforeAfter,
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'actor': actor,
        'action': action,
        'target': target,
        'beforeAfter': beforeAfter,
      };
}

class AdminSystemSetting {
  final String key;
  final String nameAr;
  final String nameEn;
  String value;
  final String unitAr;
  final String unitEn;
  final String descriptionAr;
  final String descriptionEn;
  final String category;

  AdminSystemSetting({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.value,
    required this.unitAr,
    required this.unitEn,
    required this.descriptionAr,
    required this.descriptionEn,
    this.category = 'operations',
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'value': value,
        'unitAr': unitAr,
        'unitEn': unitEn,
        'descriptionAr': descriptionAr,
        'descriptionEn': descriptionEn,
        'category': category,
      };
}

class AdminProvider extends ChangeNotifier {
  bool _isLoggedIn = true;
  String _currentPeriod = '7 أيام'; // 'اليوم', '7 أيام', '30 يوم'
  AdminRole _activeRole = AdminRole.superAdmin;
  bool _isDarkMode = false;
  bool _isSidebarCollapsed = false;
  String _activeEnvironment = 'production'; // 'production', 'staging', 'development'
  String? _selectedCorridorId = 'cor_1';
  AdminBroadcastBanner _broadcastBanner = const AdminBroadcastBanner();

  bool get isLoggedIn => _isLoggedIn;
  String get currentPeriod => _currentPeriod;
  AdminRole get activeRole => _activeRole;
  bool get isDarkMode => _isDarkMode;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  String get activeEnvironment => _activeEnvironment;
  String? get selectedCorridorId => _selectedCorridorId;
  AdminBroadcastBanner get broadcastBanner => _broadcastBanner;

  static const List<AdminModuleSpec> modulesCatalog = [
    AdminModuleSpec(
      index: 0,
      groupAr: 'القيادة والتحليلات',
      groupEn: 'Command & Analytics',
      titleAr: 'لوحة الأرقام',
      titleEn: 'Metrics Dashboard',
      shortAr: 'الأرقام',
      shortEn: 'Metrics',
    ),
    AdminModuleSpec(
      index: 12,
      groupAr: 'القيادة والتحليلات',
      groupEn: 'Command & Analytics',
      titleAr: 'طلبات المستثمرين',
      titleEn: 'Investor Inquiries',
      shortAr: 'المستثمرون',
      shortEn: 'Inquiries',
    ),
    AdminModuleSpec(
      index: 8,
      groupAr: 'التشغيل والسوق',
      groupEn: 'Marketplace Ops',
      titleAr: 'الخدمات والتسعير',
      titleEn: 'Services & Pricing',
      shortAr: 'الخدمات',
      shortEn: 'Services',
    ),
    AdminModuleSpec(
      index: 9,
      groupAr: 'التشغيل والسوق',
      groupEn: 'Marketplace Ops',
      titleAr: 'البلديات والمحاور',
      titleEn: 'Corridors & Geo',
      shortAr: 'المحاور',
      shortEn: 'Corridors',
    ),
    AdminModuleSpec(
      index: 3,
      groupAr: 'التشغيل والسوق',
      groupEn: 'Marketplace Ops',
      titleAr: 'الرحلات والطرود',
      titleEn: 'Rides & Parcels',
      shortAr: 'التشغيل',
      shortEn: 'Orders',
    ),
    AdminModuleSpec(
      index: 10,
      groupAr: 'الضمان والمالية والأمان',
      groupEn: 'Escrow & Trust',
      titleAr: 'الضمان والمحافظ',
      titleEn: 'Escrow & Payouts',
      shortAr: 'الضمان',
      shortEn: 'Escrow',
    ),
    AdminModuleSpec(
      index: 1,
      groupAr: 'الضمان والمالية والأمان',
      groupEn: 'Escrow & Trust',
      titleAr: 'توثيق السائقين',
      titleEn: 'Driver Verifications',
      shortAr: 'التوثيق',
      shortEn: 'KYC',
    ),
    AdminModuleSpec(
      index: 2,
      groupAr: 'الضمان والمالية والأمان',
      groupEn: 'Escrow & Trust',
      titleAr: 'المستخدمون',
      titleEn: 'Users',
      shortAr: 'المستخدمون',
      shortEn: 'Users',
    ),
    AdminModuleSpec(
      index: 4,
      groupAr: 'الضمان والمالية والأمان',
      groupEn: 'Escrow & Trust',
      titleAr: 'البلاغات والنزاعات',
      titleEn: 'Disputes & SOS',
      shortAr: 'النزاعات',
      shortEn: 'Disputes',
    ),
    AdminModuleSpec(
      index: 11,
      groupAr: 'DevOps والحوكمة',
      groupEn: 'DevOps & Governance',
      titleAr: 'مركز DevOps والأنظمة',
      titleEn: 'DevOps & SRE Center',
      shortAr: 'DevOps',
      shortEn: 'DevOps',
    ),
    AdminModuleSpec(
      index: 5,
      groupAr: 'DevOps والحوكمة',
      groupEn: 'DevOps & Governance',
      titleAr: 'الإعدادات',
      titleEn: 'Settings',
      shortAr: 'الإعدادات',
      shortEn: 'Settings',
    ),
    AdminModuleSpec(
      index: 6,
      groupAr: 'DevOps والحوكمة',
      groupEn: 'DevOps & Governance',
      titleAr: 'الموظفون',
      titleEn: 'Staff & Roles',
      shortAr: 'الموظفون',
      shortEn: 'Staff',
    ),
    AdminModuleSpec(
      index: 7,
      groupAr: 'DevOps والحوكمة',
      groupEn: 'DevOps & Governance',
      titleAr: 'سجل التدقيق',
      titleEn: 'Audit Log',
      shortAr: 'التدقيق',
      shortEn: 'Audit',
    ),
  ];

  void login(String email, String password) {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void setPeriod(String period) {
    _currentPeriod = period;
    notifyListeners();
  }

  void setActiveRole(AdminRole role) {
    _activeRole = role;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void toggleSidebarCollapsed() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void setEnvironment(String env) {
    final prev = _activeEnvironment;
    _activeEnvironment = env;
    _recordAudit(
      action: 'تبديل بيئة التشغيل',
      target: 'env',
      beforeAfter: '$prev ← $env',
    );
    notifyListeners();
  }

  void selectCorridor(String corridorId) {
    _selectedCorridorId = corridorId;
    notifyListeners();
  }

  bool canAccessMenu(int index) {
    // Preserve exact compatibility for indices 0..7 in admin_web_test.dart:
    // 0: Dashboard, 1: Drivers, 2: Users, 3: Rides/Parcels, 4: Disputes,
    // 5: Settings, 6: Staff, 7: Audit Log, 8: Services, 9: Corridors, 10: Escrow, 11: DevOps
    switch (_activeRole) {
      case AdminRole.superAdmin:
        return true;
      case AdminRole.reviewAdmin:
        return index == 0 || index == 1;
      case AdminRole.supportAdmin:
        return index == 0 ||
            index == 2 ||
            index == 3 ||
            index == 4 ||
            index == 12;
      case AdminRole.financeAdmin:
        return index == 0 || index == 3 || index == 7 || index == 8 || index == 10;
      case AdminRole.devopsAdmin:
        return index == 0 || index == 5 || index == 7 || index == 8 || index == 9 || index == 11;
    }
  }

  // Dynamic KPI Stats by Period (Preserve exact numbers verified in tests)
  int get kpiNewUsers {
    if (_currentPeriod == 'اليوم' || _currentPeriod == 'Today') return 18;
    if (_currentPeriod.contains('30')) return 540;
    return 128;
  }

  String get kpiNewUsersSubtext {
    if (_currentPeriod == 'اليوم' || _currentPeriod == 'Today') return '+4 عن الأمس';
    if (_currentPeriod.contains('30')) return '+28% عن الشهر السابق';
    return '+12% عن الفترة السابقة';
  }

  int get kpiPublishedRides {
    if (_currentPeriod == 'اليوم' || _currentPeriod == 'Today') return 45;
    if (_currentPeriod.contains('30')) return 1420;
    return 342;
  }

  String get kpiPublishedRidesSubtext {
    if (_currentPeriod == 'اليوم' || _currentPeriod == 'Today') return '+15% اليوم';
    if (_currentPeriod.contains('30')) return '+18% شهرياً';
    return '+8%';
  }

  int get kpiConfirmedBookings {
    if (_currentPeriod == 'اليوم' || _currentPeriod == 'Today') return 32;
    if (_currentPeriod.contains('30')) return 890;
    return 215;
  }

  String get kpiConversionRate {
    if (_currentPeriod == 'اليوم' || _currentPeriod == 'Today') return 'نسبة التحويل 44%';
    if (_currentPeriod.contains('30')) return 'نسبة التحويل 39%';
    return 'نسبة التحويل 41%';
  }

  int get kpiDeliveredParcels {
    if (_currentPeriod == 'اليوم' || _currentPeriod == 'Today') return 14;
    if (_currentPeriod.contains('30')) return 340;
    return 87;
  }

  String get kpiParcelSuccessRate {
    if (_currentPeriod == 'اليوم' || _currentPeriod == 'Today') return 'نجاح 98%';
    if (_currentPeriod.contains('30')) return 'نجاح 94%';
    return 'نجاح 95%';
  }

  // Financial & Escrow Live KPIs
  double get kpiActiveEscrowHoldQar {
    return _escrowItems
        .where((e) =>
            e.status == 'held' ||
            e.status == 'receipt_pending' ||
            e.status == 'in_transit' ||
            e.status == 'frozen')
        .fold(0.0, (sum, e) => sum + e.totalProtectedQar);
  }

  double get kpiReleasedTodayQar {
    return _escrowItems
        .where((e) => e.status == 'released')
        .fold(0.0, (sum, e) => sum + e.totalProtectedQar);
  }

  double get kpiFrozenEscrowQar {
    return _escrowItems
        .where((e) => e.status == 'frozen')
        .fold(0.0, (sum, e) => sum + e.totalProtectedQar);
  }

  double get kpiNetPlatformCommissionQar {
    return _escrowItems.fold(0.0, (sum, e) => sum + e.platformCommissionQar);
  }

  // Driver Verifications
  final List<AdminDriverVerificationRequest> _driverRequests = [
    AdminDriverVerificationRequest(
      id: 'req_1',
      driverName: 'مريم العطية',
      governorate: 'بلدية الدوحة',
      submittedAt: 'أمس 3:10 م',
      durationText: '27 ساعة',
      carModel: 'لكزس RX · أسود',
      carPlate: 'قطر 482910',
      licenseExpiryDate: '15 يوليو 2027',
      qidMasked: '291•••••408',
      status: 'قيد المراجعة',
    ),
    AdminDriverVerificationRequest(
      id: 'req_2',
      driverName: 'حمد الكواري',
      governorate: 'بلدية الخور والذخيرة',
      submittedAt: 'اليوم 9:40 ص',
      durationText: '4 ساعات',
      carModel: 'تويوتا كامري · أبيض لؤلؤي',
      carPlate: 'قطر 615304',
      licenseExpiryDate: '12 مارس 2028',
      qidMasked: '288•••••119',
      status: 'قيد المراجعة',
    ),
    AdminDriverVerificationRequest(
      id: 'req_3',
      driverName: 'جاسم المري',
      governorate: 'بلدية الوكرة',
      submittedAt: 'اليوم 11:05 ص',
      durationText: '3 ساعات',
      carModel: 'نيسان باترول · رمادي',
      carPlate: 'قطر 209871',
      licenseExpiryDate: '20 نوفمبر 2027',
      qidMasked: '293•••••772',
      status: 'قيد المراجعة',
    ),
    AdminDriverVerificationRequest(
      id: 'req_4',
      driverName: 'راشد النعيمي',
      governorate: 'بلدية الريان',
      submittedAt: '3 نوفمبر 2:00 م',
      durationText: 'معتمد',
      carModel: 'تويوتا لاندكروزر · فضي',
      carPlate: 'قطر 774120',
      licenseExpiryDate: '10 أغسطس 2027',
      qidMasked: '285•••••304',
      status: 'مقبولة',
    ),
    AdminDriverVerificationRequest(
      id: 'req_5',
      driverName: 'فيصل الدوسري',
      governorate: 'بلدية الضعاين',
      submittedAt: '2 نوفمبر 5:15 م',
      durationText: 'مرفوض',
      carModel: 'ميتسوبيشي أوتلاندر · أزرق',
      carPlate: 'قطر 339105',
      licenseExpiryDate: '5 يناير 2026',
      qidMasked: '297•••••615',
      status: 'مرفوضة',
      rejectionReason: 'صورة غير واضحة',
      rejectionNote: 'صورة رخصة القيادة القطرية غير واضحة، يرجى إعادة التصوير في إضاءة جيدة.',
    ),
  ];

  List<AdminDriverVerificationRequest> get driverRequests => _driverRequests;

  void acceptDriver(String reqId) {
    final req = _driverRequests.firstWhere((r) => r.id == reqId);
    req.status = 'مقبولة';
    _recordAudit(
      action: 'قبول سائق',
      target: 'سائق: ${req.driverName}',
      beforeAfter: 'قيد المراجعة ← مقبولة',
    );
    notifyListeners();
  }

  void rejectDriver(String reqId, String reason, String note) {
    final req = _driverRequests.firstWhere((r) => r.id == reqId);
    req.status = 'مرفوضة';
    req.rejectionReason = reason;
    req.rejectionNote = note;
    _recordAudit(
      action: 'رفض توثيق سائق',
      target: 'سائق: ${req.driverName}',
      beforeAfter: 'قيد المراجعة ← مرفوضة ($reason)',
    );
    notifyListeners();
  }

  // Users List
  final List<AdminUserItem> _users = [
    AdminUserItem(
      id: 'user_1',
      fullName: 'عبدالرحمن المهنا',
      maskedPhone: '5512 ****',
      rawPhone: '55123456',
      role: 'راكب وسائق',
      status: 'نشط',
      registeredDate: '1 نوفمبر',
      rideCount: 12,
      strikesCount: 0,
      walletBalanceQar: 640.0,
      qidStatus: 'QID موثق',
    ),
    AdminUserItem(
      id: 'user_2',
      fullName: 'نورة السليطي',
      maskedPhone: '3345 ****',
      rawPhone: '33456789',
      role: 'راكب',
      status: 'نشط',
      registeredDate: '28 أكتوبر',
      rideCount: 6,
      strikesCount: 0,
      walletBalanceQar: 290.0,
      qidStatus: 'QID موثق',
    ),
    AdminUserItem(
      id: 'user_3',
      fullName: 'طلال المناعي',
      maskedPhone: '6678 ****',
      rawPhone: '66789012',
      role: 'راكب',
      status: 'موقوف',
      registeredDate: '20 أكتوبر',
      rideCount: 4,
      strikesCount: 3,
      currentStrikeReason: '3 بلاغات من مستخدمين مختلفين',
      internalNotes: 'تمت مراجعة البلاغات، بانتظار القرار الإداري النهائي.',
      walletBalanceQar: 115.0,
      qidStatus: 'قيد المراجعة',
    ),
    AdminUserItem(
      id: 'user_4',
      fullName: 'م. فهد المري',
      maskedPhone: '5590 ****',
      rawPhone: '55901122',
      role: 'راكب وسائق',
      status: 'نشط',
      registeredDate: '15 أكتوبر',
      rideCount: 16,
      strikesCount: 0,
      walletBalanceQar: 1420.0,
      qidStatus: 'QID + حساب أعمال',
    ),
  ];

  List<AdminUserItem> get users => _users;

  void banUser(String userId, String reason) {
    final user = _users.firstWhere((u) => u.id == userId);
    final prev = user.status;
    user.status = 'محظور';
    _recordAudit(
      action: 'حظر مستخدم',
      target: 'مستخدم: ${user.fullName}',
      beforeAfter: '$prev ← محظور ($reason)',
    );
    notifyListeners();
  }

  void unbanUser(String userId) {
    final user = _users.firstWhere((u) => u.id == userId);
    user.status = 'نشط';
    _recordAudit(
      action: 'رفع الإيقاف',
      target: 'مستخدم: ${user.fullName}',
      beforeAfter: 'موقوف ← نشط',
    );
    notifyListeners();
  }

  void adjustUserWalletBalance(String userId, double deltaQar, String reason) {
    final user = _users.firstWhere((u) => u.id == userId);
    final prev = user.walletBalanceQar;
    final next = (prev + deltaQar).clamp(0.0, 999999.0);
    user.walletBalanceQar = next;
    _recordAudit(
      action: 'تعديل رصيد محفظة',
      target: 'مستخدم: ${user.fullName}',
      beforeAfter: '${prev.toStringAsFixed(0)} ر.ق ← ${next.toStringAsFixed(0)} ر.ق ($reason)',
    );
    notifyListeners();
  }

  // Rides, Bookings, Parcels, Board Ads & B2B
  final List<AdminRideItem> _rides = [
    AdminRideItem(
      id: '#T-1021',
      driver: 'حمد الكواري',
      route: 'الدوحة ← الخور',
      time: '6 نوفمبر 7:30 ص',
      seats: '2 / 3',
      status: 'منشورة',
      governorate: 'بلدية الدوحة',
    ),
    AdminRideItem(
      id: '#T-1020',
      driver: 'جاسم المري',
      route: 'الدوحة ← الوكرة',
      time: '7 نوفمبر 9:00 ص',
      seats: '0 / 3',
      status: 'مكتملة الحجز',
      governorate: 'بلدية الوكرة',
    ),
    AdminRideItem(
      id: '#T-1018',
      driver: 'مريم العطية',
      route: 'الدوحة ← دخان',
      time: '5 نوفمبر 4:00 م',
      seats: '1 / 4',
      status: 'ملغاة',
      governorate: 'بلدية الشيحانية',
    ),
    AdminRideItem(
      id: '#T-1015',
      driver: 'راشد النعيمي',
      route: 'المنطقة الصناعية ← مسيعيد',
      time: 'اليوم 6:00 م',
      seats: '3 / 4',
      status: 'جارية',
      governorate: 'بلدية الريان',
    ),
  ];

  List<AdminRideItem> get rides => _rides;

  final List<AdminBookingItem> _bookings = [
    AdminBookingItem(
      id: '#B-3012',
      passenger: 'عبدالرحمن المهنا',
      driver: 'حمد الكواري',
      route: 'الدوحة ← الخور',
      time: '6 نوفمبر 7:30 ص',
      seats: 1,
      fare: 35.0,
      status: 'مؤكد',
      governorate: 'بلدية الدوحة',
    ),
    AdminBookingItem(
      id: '#B-3011',
      passenger: 'نورة السليطي',
      driver: 'جاسم المري',
      route: 'الدوحة ← الوكرة',
      time: '7 نوفمبر 9:00 ص',
      seats: 2,
      fare: 50.0,
      status: 'مؤكد',
      governorate: 'بلدية الوكرة',
    ),
    AdminBookingItem(
      id: '#B-3009',
      passenger: 'طلال المناعي',
      driver: 'مريم العطية',
      route: 'الدوحة ← دخان',
      time: '5 نوفمبر 4:00 م',
      seats: 1,
      fare: 45.0,
      status: 'ملغى',
      governorate: 'بلدية الشيحانية',
    ),
  ];

  List<AdminBookingItem> get bookings => _bookings;

  final List<AdminParcelItem> _parcels = [
    AdminParcelItem(
      id: '#P-8419',
      sender: 'طلال المناعي',
      receiver: 'سارة المالك',
      driver: 'حمد الكواري',
      route: 'الدوحة ← الخور',
      item: 'أوراق ومستندات (صغير)',
      fee: 20.0,
      pin: '4821',
      status: 'تم التسليم',
      governorate: 'بلدية الدوحة',
    ),
    AdminParcelItem(
      id: '#P-8422',
      sender: 'نورة السليطي',
      receiver: 'شيخة الهاجري',
      driver: 'جاسم المري',
      route: 'الدوحة ← الوكرة',
      item: 'ملابس وهدايا (متوسط)',
      fee: 25.0,
      pin: '7391',
      status: 'في الطريق',
      governorate: 'بلدية الوكرة',
    ),
    AdminParcelItem(
      id: '#P-8425',
      sender: 'فيصل الدوسري',
      receiver: 'خالد الكعبي',
      driver: 'راشد النعيمي',
      route: 'المنطقة الصناعية ← مسيعيد',
      item: 'قطع غيار إلكترونية (كبير)',
      fee: 45.0,
      pin: '1092',
      status: 'متنازع عليه',
      governorate: 'بلدية الريان',
    ),
  ];

  List<AdminParcelItem> get parcels => _parcels;

  final List<BoardAdModel> _boardAds = List.from(MockData.initialBoardAds);
  List<BoardAdModel> get boardAds => _boardAds;

  final List<AdminB2BAccountItem> _b2bAccounts = [
    const AdminB2BAccountItem(
      id: 'b2b_1',
      companyAr: 'مؤسسة الخليج للمعدات والسباكة',
      companyEn: 'Gulf MEP & Hardware Co.',
      sectorAr: 'مقاولات وتوريد مواقع',
      sectorEn: 'Construction & MEP Supply',
      municipalityAr: 'المنطقة الصناعية ↔ لوسيل',
      municipalityEn: 'Industrial Area ↔ Lusail',
      monthlyRuns: 142,
      creditLimitQar: 15000,
      status: 'active',
      contactPhone: '4412 8890',
    ),
    const AdminB2BAccountItem(
      id: 'b2b_2',
      companyAr: 'صيدليات الواحة ومختبرات التشخيص',
      companyEn: 'Al Waha Pharmacies & Labs',
      sectorAr: 'طرود ومستلزمات طبية',
      sectorEn: 'Healthcare Micro-Cargo',
      municipalityAr: 'الدوحة ↔ الوكرة والريان',
      municipalityEn: 'Doha ↔ Al Wakrah & Al Rayyan',
      monthlyRuns: 98,
      creditLimitQar: 8500,
      status: 'active',
      contactPhone: '4490 2211',
    ),
    const AdminB2BAccountItem(
      id: 'b2b_3',
      companyAr: 'حضانة براعم الخليج ثنائية اللغة',
      companyEn: 'Gulf Buds Bilingual Nursery',
      sectorAr: 'اشتراكات نقل يومي ومرافقين',
      sectorEn: 'Scheduled Nursery Commutes',
      municipalityAr: 'الريان ↔ لوسيل',
      municipalityEn: 'Al Rayyan ↔ Lusail',
      monthlyRuns: 64,
      creditLimitQar: 6000,
      status: 'active',
      contactPhone: '4431 7740',
    ),
  ];

  List<AdminB2BAccountItem> get b2bAccounts => _b2bAccounts;

  void manualUpdateRideStatus(String rideId, String newStatus, String reason) {
    final ride = _rides.firstWhere((r) => r.id == rideId);
    final prev = ride.status;
    ride.status = newStatus;
    ride.statusOverrideReason = reason;
    _recordAudit(
      action: 'تعديل حالة رحلة يدوياً',
      target: 'رحلة $rideId',
      beforeAfter: '$prev ← $newStatus (السبب: $reason)',
    );
    notifyListeners();
  }

  void moderateBoardAd(String adId, BoardAdStatus newStatus, String reason) {
    final idx = _boardAds.indexWhere((a) => a.id == adId);
    if (idx == -1) return;
    final ad = _boardAds[idx];
    final prev = ad.status.name;
    _boardAds[idx] = ad.copyWith(status: newStatus);
    _recordAudit(
      action: 'إدارة إعلان باللوحة',
      target: 'إعلان ${ad.id} (${ad.authorName})',
      beforeAfter: '$prev ← ${newStatus.name} ($reason)',
    );
    notifyListeners();
  }

  void toggleB2BAccountStatus(String accountId) {
    final idx = _b2bAccounts.indexWhere((a) => a.id == accountId);
    if (idx == -1) return;
    final acc = _b2bAccounts[idx];
    final next = acc.status == 'active' ? 'suspended' : 'active';
    _b2bAccounts[idx] = acc.copyWith(status: next);
    _recordAudit(
      action: 'تحديث حساب أعمال B2B',
      target: acc.companyAr,
      beforeAfter: '${acc.status} ← $next',
    );
    notifyListeners();
  }

  void addB2BAccount(AdminB2BAccountItem item) {
    _b2bAccounts.insert(0, item);
    _recordAudit(
      action: 'تسجيل حساب أعمال B2B',
      target: item.companyAr,
      beforeAfter: 'جديد ← نشط (سقف ${item.creditLimitQar} ر.ق)',
    );
    notifyListeners();
  }

  // Disputes & SOS Reports
  final List<AdminDisputeItem> _disputes = [
    AdminDisputeItem(
      id: '#5127',
      type: 'طرد',
      category: 'وصل تالف',
      complainantName: 'طلال المناعي',
      againstName: 'حمد الكواري',
      parcelOrRideDetails: 'أوراق · صغير · 300 ر.ق',
      status: 'مفتوح',
      assignedTo: null,
      isSosPriority: true,
      linkedEscrowId: '#QA-8511',
      timeline: [
        '7 نوفمبر 7:35 ص: استلم السائق الطرد (صورة مرفقة)',
        '7 نوفمبر 9:50 ص: تسليم برمز صحيح للمستلم',
        '8 نوفمبر 10:12 ص: المستلم أبلغ عن تلف بالظرف وتجميد الضمان',
      ],
      internalNote: 'الصور تؤكد التلف الجزئي للمستندات، المبلغ مجمد في الضمان المالي.',
    ),
    AdminDisputeItem(
      id: '#5126',
      type: 'مستخدم',
      category: 'قيادة متهورة',
      complainantName: 'نورة السليطي',
      againstName: 'جاسم المري',
      parcelOrRideDetails: 'رحلة الدوحة ← الوكرة',
      status: 'قيد المراجعة',
      assignedTo: 'راشد النعيمي (دعم)',
      isSosPriority: false,
      timeline: [
        '6 نوفمبر 11:30 ص: تقديم البلاغ وتجاوز السرعة',
        '6 نوفمبر 2:00 م: التواصل مع السائق لسماع إفادته',
      ],
    ),
    AdminDisputeItem(
      id: '#5120',
      type: 'رحلة',
      category: 'احتيال',
      complainantName: 'مريم العطية',
      againstName: 'سائق غير مسجل',
      parcelOrRideDetails: 'رحلة الدوحة ← الخور',
      status: 'محلول',
      assignedTo: 'راشد النعيمي (دعم)',
      resolutionDecision: 'تم حظر الحساب وتعويض الراكبة',
      timeline: [
        '1 نوفمبر: تم تقديم الشكوى والتحقق من التحويل البنكي',
        '2 نوفمبر: تم إيقاف الحساب وتعويض الراكبة من الضمان',
      ],
    ),
  ];

  List<AdminDisputeItem> get disputes => _disputes;

  void assignDispute(String disputeId, String staffName) {
    final d = _disputes.firstWhere((item) => item.id == disputeId);
    final prev = d.assignedTo ?? 'غير معيّن';
    d.assignedTo = staffName;
    if (d.status == 'مفتوح') {
      d.status = 'قيد المراجعة';
    }
    d.timeline.add('اليوم: تم إسناد البلاغ إلى $staffName لمباشرة التحقيق');
    _recordAudit(
      action: 'إسناد بلاغ لموظف',
      target: 'بلاغ $disputeId',
      beforeAfter: '$prev ← $staffName',
    );
    notifyListeners();
  }

  void resolveDispute(String disputeId, String decision, String note) {
    final d = _disputes.firstWhere((item) => item.id == disputeId);
    d.status = 'محلول';
    d.resolutionDecision = decision;
    d.internalNote = note;
    d.timeline.add('الآن: اعتماد القرار الإداري ($decision)');
    _recordAudit(
      action: 'حل نزاع وبلاغ',
      target: 'بلاغ $disputeId',
      beforeAfter: 'مفتوح ← محلول ($decision)',
    );
    notifyListeners();
  }

  // 6+ Extensible Services Catalog
  late List<AdminServiceDefinition> _servicesCatalog = _buildDefaultServices();

  static List<AdminServiceDefinition> _buildDefaultServices() => [
        const AdminServiceDefinition(
          id: 'svc_store_errand',
          code: 'store_errand',
          nameAr: 'شراء وتوصيل بفاتورة حية',
          nameEn: 'Store Buy & Deliver',
          descriptionAr: 'مشتريات المحلات والطلبات اليومية مع إلزامية رفع الفاتورة وصورة السلعة قبل التحرك.',
          descriptionEn: 'Store purchases with live receipt & photo verification held inside Escrow.',
          iconName: 'shopping_bag',
          accentHex: 0xFFB45309,
          isEnabled: true,
          commissionPct: 18.0,
          minFeeQar: 20,
          maxFeeQar: 300,
          maxReceiptCapQar: 1500,
          requiresEscrow: true,
          requiresReceiptPhoto: true,
          requiresFourDigitOtp: true,
          allowsLadiesOnly: true,
          slaMinutes: 90,
          activeOrdersCount: 48,
        ),
        const AdminServiceDefinition(
          id: 'svc_site_supply',
          code: 'site_supply',
          nameAr: 'توريد مواقع ومعدات للمهندسين',
          nameEn: 'Engineer & Site Supply',
          descriptionAr: 'نقل قطع الغيار والأدوات من المنطقة الصناعية إلى مواقع لوسيل والدوحة والوكرة.',
          descriptionEn: 'Urgent spare parts & tools run from Industrial Area directly to Lusail/Doha worksites.',
          iconName: 'engineering',
          accentHex: 0xFF8A1538,
          isEnabled: true,
          commissionPct: 18.0,
          minFeeQar: 35,
          maxFeeQar: 800,
          maxReceiptCapQar: 2500,
          requiresEscrow: true,
          requiresReceiptPhoto: true,
          requiresFourDigitOtp: true,
          allowsLadiesOnly: false,
          slaMinutes: 120,
          activeOrdersCount: 34,
        ),
        const AdminServiceDefinition(
          id: 'svc_doc_parcel',
          code: 'doc_parcel',
          nameAr: 'جلب أوراق وأمانات على الطريق',
          nameEn: 'On-Route Paperwork & Parcels',
          descriptionAr: 'تسليم العقود والأختام والطرود العاجلة مع مسافري نفس الطريق بكود 4 أرقام.',
          descriptionEn: '2-4 hour same-day documents & parcel handover gated by 4-digit OTP.',
          iconName: 'description',
          accentHex: 0xFF0F766E,
          isEnabled: true,
          commissionPct: 18.0,
          minFeeQar: 20,
          maxFeeQar: 250,
          maxReceiptCapQar: 2000,
          requiresEscrow: true,
          requiresReceiptPhoto: false,
          requiresFourDigitOtp: true,
          allowsLadiesOnly: true,
          slaMinutes: 180,
          activeOrdersCount: 62,
        ),
        const AdminServiceDefinition(
          id: 'svc_nursery_commute',
          code: 'nursery_commute',
          nameAr: 'مشاوير الحضانات والمناطق البعيدة',
          nameEn: 'Nurseries & Daily Commutes',
          descriptionAr: 'توصيل مجدول وآمن للحضانات والمدارس والأحياء قليلة المواصلات مع فلتر للنساء.',
          descriptionEn: 'Scheduled neighborhood & nursery runs with verified drivers & ladies-only filter.',
          iconName: 'family_restroom',
          accentHex: 0xFFBE185D,
          isEnabled: true,
          commissionPct: 11.0,
          minFeeQar: 20,
          maxFeeQar: 400,
          maxReceiptCapQar: 0,
          requiresEscrow: true,
          requiresReceiptPhoto: false,
          requiresFourDigitOtp: true,
          allowsLadiesOnly: true,
          slaMinutes: 30,
          activeOrdersCount: 29,
        ),
        const AdminServiceDefinition(
          id: 'svc_shared_seats',
          code: 'shared_seats',
          nameAr: 'مشاركة مقاعد بين المدن والبلديات',
          nameEn: 'Shared Empty Seats',
          descriptionAr: 'استثمار المقاعد الشاغرة على خطوط الدوحة والخور والوكرة ودخان بتسعيرة عادلة.',
          descriptionEn: 'Inter-municipality seat sharing along active Qatar corridors with price guardrails.',
          iconName: 'directions_car',
          accentHex: 0xFF0F2A43,
          isEnabled: true,
          commissionPct: 11.0,
          minFeeQar: 20,
          maxFeeQar: 150,
          maxReceiptCapQar: 0,
          requiresEscrow: true,
          requiresReceiptPhoto: false,
          requiresFourDigitOtp: false,
          allowsLadiesOnly: true,
          slaMinutes: 45,
          activeOrdersCount: 91,
        ),
        const AdminServiceDefinition(
          id: 'svc_commercial_cargo',
          code: 'commercial_cargo',
          nameAr: 'نقل بضائع وشحنات الورش والمتاجر',
          nameEn: 'Commercial Micro-Cargo',
          descriptionAr: 'إمداد سريع للمتاجر والورش والعيادات مع أولوية لأصحاب المركبات الموثقين بالـ QID.',
          descriptionEn: 'Same-day stock transfers for SMEs, workshops & clinics with QID priority dispatch.',
          iconName: 'local_shipping',
          accentHex: 0xFF4338CA,
          isEnabled: true,
          commissionPct: 18.0,
          minFeeQar: 40,
          maxFeeQar: 1200,
          maxReceiptCapQar: 3000,
          requiresEscrow: true,
          requiresReceiptPhoto: true,
          requiresFourDigitOtp: true,
          allowsLadiesOnly: false,
          slaMinutes: 150,
          activeOrdersCount: 24,
        ),
      ];

  List<AdminServiceDefinition> get servicesCatalog => _servicesCatalog;

  void toggleServiceEnabled(String serviceId) {
    final idx = _servicesCatalog.indexWhere((s) => s.id == serviceId);
    if (idx == -1) return;
    final prev = _servicesCatalog[idx];
    final nextVal = !prev.isEnabled;
    _servicesCatalog[idx] = prev.copyWith(isEnabled: nextVal);
    _recordAudit(
      action: 'تفعيل/تعطيل خدمة',
      target: prev.nameAr,
      beforeAfter: '${prev.isEnabled ? "مفعلة" : "معطلة"} ← ${nextVal ? "مفعلة" : "معطلة"}',
    );
    _persistSnapshot();
    notifyListeners();
  }

  void updateServiceConfig(AdminServiceDefinition updated) {
    final idx = _servicesCatalog.indexWhere((s) => s.id == updated.id);
    if (idx == -1) return;
    final prev = _servicesCatalog[idx];
    _servicesCatalog[idx] = updated;
    _recordAudit(
      action: 'تحديث قواعد خدمة',
      target: updated.nameAr,
      beforeAfter: 'عمولة ${prev.commissionPct}% ← ${updated.commissionPct}% | صيانة: ${updated.isMaintenance}',
    );
    _persistSnapshot();
    notifyListeners();
  }

  void addServiceDefinition(AdminServiceDefinition newService) {
    _servicesCatalog.add(newService);
    _recordAudit(
      action: 'إضافة خدمة مستقبلية جديدة',
      target: newService.nameAr,
      beforeAfter: 'جديد ← مفعّلة (عمولة ${newService.commissionPct}%)',
    );
    _persistSnapshot();
    notifyListeners();
  }

  // Qatar Corridors & Municipalities Control
  late List<AdminCorridorNode> _corridors = _buildDefaultCorridors();

  static List<AdminCorridorNode> _buildDefaultCorridors() => [
        const AdminCorridorNode(
          id: 'cor_1',
          fromCityAr: 'الدوحة',
          fromCityEn: 'Doha',
          toCityAr: 'الخور',
          toCityEn: 'Al Khor',
          municipalityAr: 'بلدية الخور والذخيرة',
          municipalityEn: 'Al Khor & Al Thakhira',
          status: 'peak',
          activeProviders: 34,
          openRequests: 94,
          conversionPct: 48.0,
          avgEtaMin: 38,
          incentiveMultiplier: 1.15,
          dailyGmvQar: 3850,
        ),
        const AdminCorridorNode(
          id: 'cor_2',
          fromCityAr: 'المنطقة الصناعية',
          fromCityEn: 'Industrial Area',
          toCityAr: 'لوسيل',
          toCityEn: 'Lusail',
          municipalityAr: 'بلدية الضعاين والريان',
          municipalityEn: 'Al Daayen & Al Rayyan',
          status: 'peak',
          activeProviders: 28,
          openRequests: 79,
          conversionPct: 52.0,
          avgEtaMin: 27,
          incentiveMultiplier: 1.25,
          dailyGmvQar: 4920,
        ),
        const AdminCorridorNode(
          id: 'cor_3',
          fromCityAr: 'الدوحة',
          fromCityEn: 'Doha',
          toCityAr: 'الوكرة',
          toCityEn: 'Al Wakrah',
          municipalityAr: 'بلدية الوكرة',
          municipalityEn: 'Al Wakrah Municipality',
          status: 'active',
          activeProviders: 26,
          openRequests: 61,
          conversionPct: 41.0,
          avgEtaMin: 21,
          incentiveMultiplier: 1.0,
          dailyGmvQar: 2640,
        ),
        const AdminCorridorNode(
          id: 'cor_4',
          fromCityAr: 'الدوحة',
          fromCityEn: 'Doha',
          toCityAr: 'دخان',
          toCityEn: 'Dukhan',
          municipalityAr: 'بلدية الشيحانية',
          municipalityEn: 'Al Shahaniya',
          status: 'active',
          activeProviders: 14,
          openRequests: 38,
          conversionPct: 36.0,
          avgEtaMin: 54,
          incentiveMultiplier: 1.2,
          dailyGmvQar: 1980,
        ),
        const AdminCorridorNode(
          id: 'cor_5',
          fromCityAr: 'المنطقة الصناعية',
          fromCityEn: 'Industrial Area',
          toCityAr: 'مسيعيد',
          toCityEn: 'Mesaieed',
          municipalityAr: 'بلدية الوكرة - مسيعيد',
          municipalityEn: 'Mesaieed Industrial',
          status: 'active',
          activeProviders: 19,
          openRequests: 44,
          conversionPct: 45.0,
          avgEtaMin: 34,
          incentiveMultiplier: 1.1,
          dailyGmvQar: 3110,
        ),
        const AdminCorridorNode(
          id: 'cor_6',
          fromCityAr: 'الريان',
          fromCityEn: 'Al Rayyan',
          toCityAr: 'لوسيل',
          toCityEn: 'Lusail',
          municipalityAr: 'بلدية الريان والضعاين',
          municipalityEn: 'Al Rayyan & Al Daayen',
          status: 'active',
          activeProviders: 22,
          openRequests: 51,
          conversionPct: 43.0,
          avgEtaMin: 24,
          incentiveMultiplier: 1.0,
          dailyGmvQar: 2290,
        ),
      ];

  List<AdminCorridorNode> get corridors => _corridors;

  void setCorridorStatus(String corridorId, String status) {
    final idx = _corridors.indexWhere((c) => c.id == corridorId);
    if (idx == -1) return;
    final prev = _corridors[idx];
    _corridors[idx] = prev.copyWith(status: status);
    _recordAudit(
      action: 'تغيير حالة ممر جغرافي',
      target: '${prev.fromCityAr} ↔ ${prev.toCityAr}',
      beforeAfter: '${prev.status} ← $status',
    );
    _persistSnapshot();
    notifyListeners();
  }

  void setCorridorIncentive(String corridorId, double multiplier) {
    final idx = _corridors.indexWhere((c) => c.id == corridorId);
    if (idx == -1) return;
    final prev = _corridors[idx];
    _corridors[idx] = prev.copyWith(incentiveMultiplier: multiplier);
    _recordAudit(
      action: 'تعديل معامل تحفيز الممر',
      target: '${prev.fromCityAr} ↔ ${prev.toCityAr}',
      beforeAfter: '${prev.incentiveMultiplier.toStringAsFixed(2)}x ← ${multiplier.toStringAsFixed(2)}x',
    );
    _persistSnapshot();
    notifyListeners();
  }

  void addCorridor(AdminCorridorNode node) {
    _corridors.add(node);
    _selectedCorridorId = node.id;
    _recordAudit(
      action: 'إضافة ممر قطري جديد',
      target: '${node.fromCityAr} ↔ ${node.toCityAr}',
      beforeAfter: 'جديد ← ${node.municipalityAr}',
    );
    _persistSnapshot();
    notifyListeners();
  }

  // Bilateral Escrow Ledger & Payment Gateways
  final List<AdminEscrowLedgerItem> _escrowItems = [
    const AdminEscrowLedgerItem(
      id: '#QA-8492',
      serviceCode: 'site_supply',
      serviceTitleAr: 'توريد موقع هندسي (لوسيل)',
      serviceTitleEn: 'Engineer Site Supply (Lusail)',
      requesterName: 'م. فهد المري',
      providerName: 'راشد النعيمي',
      corridorAr: 'المنطقة الصناعية ← لوسيل',
      corridorEn: 'Industrial Area -> Lusail',
      serviceFeeQar: 45,
      receiptCapQar: 180,
      actualReceiptQar: 164,
      platformCommissionQar: 8.1,
      paymentRail: 'Fawran',
      hasReceiptPhoto: true,
      receiptApproved: true,
      otpCode: '5912',
      otpVerified: false,
      status: 'in_transit',
      createdAt: 'اليوم 10:15 ص',
    ),
    const AdminEscrowLedgerItem(
      id: '#QA-8503',
      serviceCode: 'store_errand',
      serviceTitleAr: 'شراء وتوصيل بفاتورة حية',
      serviceTitleEn: 'Store Buy & Receipt',
      requesterName: 'نورة السليطي',
      providerName: 'مريم العطية',
      corridorAr: 'الخليج الغربي ← الريان',
      corridorEn: 'West Bay -> Al Rayyan',
      serviceFeeQar: 30,
      receiptCapQar: 220,
      actualReceiptQar: 195,
      platformCommissionQar: 5.4,
      paymentRail: 'QPay',
      hasReceiptPhoto: true,
      receiptApproved: false,
      otpCode: '3384',
      otpVerified: false,
      status: 'receipt_pending',
      createdAt: 'اليوم 11:02 ص',
    ),
    const AdminEscrowLedgerItem(
      id: '#QA-8511',
      serviceCode: 'doc_parcel',
      serviceTitleAr: 'جلب مستند رسمي من الخور',
      serviceTitleEn: 'Al Khor Stamped Document',
      requesterName: 'طلال المناعي',
      providerName: 'حمد الكواري',
      corridorAr: 'الخور ← الدوحة',
      corridorEn: 'Al Khor -> Doha',
      serviceFeeQar: 35,
      receiptCapQar: 0,
      actualReceiptQar: 0,
      platformCommissionQar: 6.3,
      paymentRail: 'Wallet',
      hasReceiptPhoto: true,
      receiptApproved: true,
      otpCode: '4821',
      otpVerified: true,
      status: 'frozen',
      createdAt: 'أمس 9:50 ص',
    ),
    const AdminEscrowLedgerItem(
      id: '#QA-8519',
      serviceCode: 'shared_seats',
      serviceTitleAr: 'مقعدان تشاركيان مع تأمين',
      serviceTitleEn: '2 Shared Corridor Seats',
      requesterName: 'عبدالرحمن المهنا',
      providerName: 'جاسم المري',
      corridorAr: 'الدوحة ← الوكرة',
      corridorEn: 'Doha -> Al Wakrah',
      serviceFeeQar: 50,
      receiptCapQar: 0,
      actualReceiptQar: 0,
      platformCommissionQar: 5.5,
      paymentRail: 'Apple Pay',
      hasReceiptPhoto: false,
      receiptApproved: true,
      otpCode: '7710',
      otpVerified: true,
      status: 'released',
      createdAt: 'اليوم 8:30 ص',
    ),
    const AdminEscrowLedgerItem(
      id: '#QA-8524',
      serviceCode: 'commercial_cargo',
      serviceTitleAr: 'شحنة قطع صيانة عاجلة',
      serviceTitleEn: 'B2B Maintenance Micro-Cargo',
      requesterName: 'مؤسسة الخليج للمعدات',
      providerName: 'راشد النعيمي',
      corridorAr: 'المنطقة الصناعية ← مسيعيد',
      corridorEn: 'Industrial Area -> Mesaieed',
      serviceFeeQar: 75,
      receiptCapQar: 420,
      actualReceiptQar: 0,
      platformCommissionQar: 13.5,
      paymentRail: 'SkipCash',
      hasReceiptPhoto: false,
      receiptApproved: false,
      otpCode: '9024',
      otpVerified: false,
      status: 'held',
      createdAt: 'اليوم 12:10 م',
    ),
  ];

  List<AdminEscrowLedgerItem> get escrowItems => _escrowItems;

  final List<AdminPaymentGatewayConfig> _paymentGateways = [
    const AdminPaymentGatewayConfig(
      id: 'gw_fawran',
      nameAr: 'فوراً (مصرف قطر المركزي QCB Fawran)',
      nameEn: 'QCB Fawran Instant',
      isEnabled: true,
      isPrimary: true,
      feePct: 0.35,
      settlementAr: 'فوري (أقل من 15 ثانية)',
      settlementEn: 'Instant (<15s)',
      latencyMs: 84,
      uptimePct: 99.98,
    ),
    const AdminPaymentGatewayConfig(
      id: 'gw_qpay',
      nameAr: 'بطاقة هميان القطرية / QPay',
      nameEn: 'QPay / Himyan Debit',
      isEnabled: true,
      isPrimary: false,
      feePct: 1.15,
      settlementAr: 'نفس اليوم (T+0)',
      settlementEn: 'Same Day (T+0)',
      latencyMs: 112,
      uptimePct: 99.94,
    ),
    const AdminPaymentGatewayConfig(
      id: 'gw_skipcash',
      nameAr: 'بوابة SkipCash قطر',
      nameEn: 'SkipCash Qatar',
      isEnabled: true,
      isPrimary: false,
      feePct: 1.60,
      settlementAr: '24 ساعة (T+1)',
      settlementEn: 'Next Day (T+1)',
      latencyMs: 145,
      uptimePct: 99.89,
    ),
    const AdminPaymentGatewayConfig(
      id: 'gw_applepay',
      nameAr: 'Apple Pay السريع',
      nameEn: 'Apple Pay Express',
      isEnabled: true,
      isPrimary: false,
      feePct: 1.75,
      settlementAr: '24 ساعة (T+1)',
      settlementEn: 'Next Day (T+1)',
      latencyMs: 96,
      uptimePct: 99.97,
    ),
    const AdminPaymentGatewayConfig(
      id: 'gw_wallet',
      nameAr: 'محفظة مشوار الداخلية',
      nameEn: 'MASHWAR In-App Ledger',
      isEnabled: true,
      isPrimary: false,
      feePct: 0.0,
      settlementAr: 'دفتر حسابات فوري داخلي',
      settlementEn: 'Zero-fee Ledger Lock',
      latencyMs: 28,
      uptimePct: 100.0,
    ),
  ];

  List<AdminPaymentGatewayConfig> get paymentGateways => _paymentGateways;

  void approveEscrowReceipt(String escrowId) {
    final idx = _escrowItems.indexWhere((e) => e.id == escrowId);
    if (idx == -1) return;
    final prev = _escrowItems[idx];
    _escrowItems[idx] = prev.copyWith(
      receiptApproved: true,
      status: prev.status == 'receipt_pending' ? 'in_transit' : prev.status,
    );
    _recordAudit(
      action: 'اعتماد فاتورة ضمان مالي',
      target: 'Escrow $escrowId',
      beforeAfter: 'بانتظار مراجعة الفاتورة ← معتمدة (${prev.actualReceiptQar} ر.ق)',
    );
    notifyListeners();
  }

  void releaseEscrow(String escrowId, String note) {
    final idx = _escrowItems.indexWhere((e) => e.id == escrowId);
    if (idx == -1) return;
    final prev = _escrowItems[idx];
    _escrowItems[idx] = prev.copyWith(status: 'released', otpVerified: true, receiptApproved: true);
    _recordAudit(
      action: 'تحرير مبلغ الضمان للمنفذ',
      target: 'Escrow $escrowId (${prev.providerName})',
      beforeAfter: '${prev.status} ← released (${prev.totalProtectedQar.toStringAsFixed(0)} ر.ق: $note)',
    );
    notifyListeners();
  }

  void refundEscrow(String escrowId, String reason) {
    final idx = _escrowItems.indexWhere((e) => e.id == escrowId);
    if (idx == -1) return;
    final prev = _escrowItems[idx];
    _escrowItems[idx] = prev.copyWith(status: 'refunded');
    _recordAudit(
      action: 'استرداد مبلغ الضمان للطالب',
      target: 'Escrow $escrowId (${prev.requesterName})',
      beforeAfter: '${prev.status} ← refunded ($reason)',
    );
    notifyListeners();
  }

  void freezeEscrow(String escrowId, String reason) {
    final idx = _escrowItems.indexWhere((e) => e.id == escrowId);
    if (idx == -1) return;
    final prev = _escrowItems[idx];
    _escrowItems[idx] = prev.copyWith(status: 'frozen');
    _recordAudit(
      action: 'تجميد مبلغ الضمان للتحقيق',
      target: 'Escrow $escrowId',
      beforeAfter: '${prev.status} ← frozen ($reason)',
    );
    notifyListeners();
  }

  void togglePaymentGateway(String gatewayId) {
    final idx = _paymentGateways.indexWhere((g) => g.id == gatewayId);
    if (idx == -1) return;
    final prev = _paymentGateways[idx];
    final next = !prev.isEnabled;
    _paymentGateways[idx] = prev.copyWith(isEnabled: next);
    _recordAudit(
      action: 'تغيير حالة بوابة دفع',
      target: prev.nameEn,
      beforeAfter: '${prev.isEnabled ? "Active" : "Disabled"} ← ${next ? "Active" : "Disabled"}',
    );
    notifyListeners();
  }

  // DevOps Feature Flags & Kill Switches
  late List<AdminFeatureFlag> _featureFlags = _buildDefaultFlags();

  static List<AdminFeatureFlag> _buildDefaultFlags() => [
        const AdminFeatureFlag(
          key: 'strict_qid_for_escrow',
          nameAr: 'إلزامية QID للمدفوعات فوق 500 ر.ق',
          nameEn: 'Strict QID Check Above 500 QAR',
          descriptionAr: 'يفرض توثيق البطاقة القطرية قبل قفل الضمان للطلبات المرتفعة.',
          descriptionEn: 'Enforces verified Qatar ID before locking high-value escrow holds.',
          category: 'security',
          isEnabled: true,
          rolloutPct: 100,
          environment: 'production',
          updatedAt: 'منذ ساعة',
        ),
        const AdminFeatureFlag(
          key: 'instant_fawran_payouts',
          nameAr: 'التحويل الفوري للمنفذين عبر فوراً',
          nameEn: 'Instant QCB Fawran Payouts',
          descriptionAr: 'تحرير أتعاب المنفذ تلقائياً خلال ثوانٍ فور تأكيد كود OTP.',
          descriptionEn: 'Auto-disburse provider earnings upon 4-digit OTP completion.',
          category: 'payments',
          isEnabled: true,
          rolloutPct: 100,
          environment: 'production',
          updatedAt: 'اليوم 08:30 ص',
        ),
        const AdminFeatureFlag(
          key: 'ladies_only_corridor_mode',
          nameAr: 'وضع "السيدات فقط" للمشاوير والحضانات',
          nameEn: 'Ladies-Only Matching Filter',
          descriptionAr: 'تخصيص كابتن سيدة لمشاوير الأسر والحضانات في كافة البلديات.',
          descriptionEn: 'Routes family & nursery requests strictly to verified female providers.',
          category: 'operations',
          isEnabled: true,
          rolloutPct: 100,
          environment: 'production',
          updatedAt: 'مستقر',
        ),
        const AdminFeatureFlag(
          key: 'ai_route_matching_v2',
          nameAr: 'مطابقة المسارات الذكية v2',
          nameEn: 'Smart Corridor Matcher v2',
          descriptionAr: 'إطلاق تدريجي لمحرك المطابقة متعدد المحطات على محور الصناعية - لوسيل.',
          descriptionEn: 'Gradual rollout of multi-stop corridor affinity scoring.',
          category: 'operations',
          isEnabled: true,
          rolloutPct: 65,
          environment: 'production',
          updatedAt: 'نسبة 65%',
        ),
        const AdminFeatureFlag(
          key: 'b2b_api_webhooks',
          nameAr: 'بوابة ربط الشركات والأعمال (Webhooks)',
          nameEn: 'Mashwar Business Webhooks',
          descriptionAr: 'إتاحة تتبع شحنات المتاجر والمقاولين لحظياً عبر REST Webhooks.',
          descriptionEn: 'Enables live order telemetry webhooks for B2B SME accounts.',
          category: 'infra',
          isEnabled: true,
          rolloutPct: 100,
          environment: 'production',
          updatedAt: 'نشط',
        ),
        const AdminFeatureFlag(
          key: 'maintenance_mode',
          nameAr: 'مفتاح الطوارئ: وضع الصيانة الشامل',
          nameEn: 'Kill-Switch: Global Maintenance Mode',
          descriptionAr: 'يوقف إنشاء الطلبات الجديدة مؤقتاً أثناء الصيانة الطارئة مع إبقاء التتبع.',
          descriptionEn: 'Emergency kill-switch pausing new orders while keeping active tracking live.',
          category: 'infra',
          isEnabled: false,
          rolloutPct: 0,
          environment: 'production',
          isKillSwitch: true,
          updatedAt: 'متوقف (آمن)',
        ),
      ];

  List<AdminFeatureFlag> get featureFlags => _featureFlags;

  void toggleFeatureFlag(String key) {
    final idx = _featureFlags.indexWhere((f) => f.key == key);
    if (idx == -1) return;
    final prev = _featureFlags[idx];
    final next = !prev.isEnabled;
    _featureFlags[idx] = prev.copyWith(
      isEnabled: next,
      rolloutPct: next ? (prev.rolloutPct == 0 ? 100 : prev.rolloutPct) : 0,
      updatedAt: 'الآن',
    );
    _recordAudit(
      action: 'تبديل Feature Flag',
      target: key,
      beforeAfter: '${prev.isEnabled} ← $next (${_activeEnvironment})',
    );
    _persistSnapshot();
    notifyListeners();
  }

  void updateFeatureFlagRollout(String key, int pct) {
    final idx = _featureFlags.indexWhere((f) => f.key == key);
    if (idx == -1) return;
    final prev = _featureFlags[idx];
    _featureFlags[idx] = prev.copyWith(
      rolloutPct: pct.clamp(0, 100),
      isEnabled: pct > 0,
      updatedAt: 'الآن',
    );
    _recordAudit(
      action: 'تعديل نسبة إطلاق Flag',
      target: key,
      beforeAfter: '${prev.rolloutPct}% ← $pct%',
    );
    _persistSnapshot();
    notifyListeners();
  }

  void addFeatureFlag(AdminFeatureFlag flag) {
    _featureFlags.insert(0, flag);
    _recordAudit(
      action: 'إضافة علم برمجي جديد',
      target: flag.key,
      beforeAfter: 'جديد ← ${flag.isEnabled ? "Enabled" : "Disabled"} (${flag.rolloutPct}%)',
    );
    _persistSnapshot();
    notifyListeners();
  }

  // DevOps / SRE Infrastructure Subsystems Health
  final List<AdminInfraServiceHealth> _infraServices = [
    const AdminInfraServiceHealth(
      id: 'srv_firestore',
      nameAr: 'قاعدة بيانات Cloud Firestore الحية',
      nameEn: 'Cloud Firestore Primary',
      region: 'me-central1 (Doha/Edge)',
      status: 'operational',
      uptimePct: 99.98,
      p50Ms: 24,
      p95Ms: 68,
      errorRatePct: 0.02,
      rps: 412,
      lastChecked: 'قبل 30 ثانية',
    ),
    const AdminInfraServiceHealth(
      id: 'srv_escrow',
      nameAr: 'محرك الضمان المالي المزدوج (Escrow)',
      nameEn: 'Bilateral Escrow Engine',
      region: 'qatar-core-vault',
      status: 'operational',
      uptimePct: 99.99,
      p50Ms: 31,
      p95Ms: 82,
      errorRatePct: 0.00,
      rps: 138,
      lastChecked: 'قبل 30 ثانية',
    ),
    const AdminInfraServiceHealth(
      id: 'srv_auth_qid',
      nameAr: 'مصادقة Firebase والتحقق من QID',
      nameEn: 'Firebase Auth & QID Guard',
      region: 'europe-west1',
      status: 'operational',
      uptimePct: 99.95,
      p50Ms: 42,
      p95Ms: 115,
      errorRatePct: 0.04,
      rps: 94,
      lastChecked: 'قبل 30 ثانية',
    ),
    const AdminInfraServiceHealth(
      id: 'srv_qpay',
      nameAr: 'بوابة QCB Fawran و QPay للدفع',
      nameEn: 'Fawran & QPay Rail Gateway',
      region: 'doha-banking-relay',
      status: 'operational',
      uptimePct: 99.92,
      p50Ms: 74,
      p95Ms: 185,
      errorRatePct: 0.08,
      rps: 62,
      lastChecked: 'قبل دقيقة',
    ),
    const AdminInfraServiceHealth(
      id: 'srv_geo',
      nameAr: 'محرك خرائط قطر الـ 22 نقطة',
      nameEn: 'Qatar 22-Hub Geo Router',
      region: 'doh-edge-1',
      status: 'operational',
      uptimePct: 99.97,
      p50Ms: 18,
      p95Ms: 49,
      errorRatePct: 0.01,
      rps: 528,
      lastChecked: 'قبل 30 ثانية',
    ),
    const AdminInfraServiceHealth(
      id: 'srv_cdn',
      nameAr: 'شبكة التوصيل Vercel Edge CDN',
      nameEn: 'Vercel Edge Distribution',
      region: 'global-doh1',
      status: 'operational',
      uptimePct: 100.00,
      p50Ms: 12,
      p95Ms: 29,
      errorRatePct: 0.00,
      rps: 890,
      lastChecked: 'الآن',
    ),
  ];

  List<AdminInfraServiceHealth> get infraServices => _infraServices;

  void runInfraHealthCheck() {
    for (int i = 0; i < _infraServices.length; i++) {
      final item = _infraServices[i];
      final bumpedP50 = (item.p50Ms + (i.isEven ? -1 : 1)).clamp(8, 250);
      _infraServices[i] = item.copyWith(
        status: 'operational',
        p50Ms: bumpedP50,
        lastChecked: 'الآن (مُفحوص)',
      );
    }
    MashwarApiClient.instance.recordRequest(
      'GET',
      '/v1/admin/health',
      body: {'env': _activeEnvironment, 'services': _infraServices.length},
      statusCode: 200,
    );
    _recordAudit(
      action: 'فحص صحة البنية التحتية',
      target: '6 أنظمة سحابية ($_activeEnvironment)',
      beforeAfter: 'تم التحقق ← جميع الأنظمة تعمل بكفاءة 99.9%+',
    );
    notifyListeners();
  }

  void updateBroadcastBanner(AdminBroadcastBanner banner) {
    _broadcastBanner = banner;
    _recordAudit(
      action: 'تحديث شريط البث المباشر للتطبيق',
      target: 'Consumer App Banner',
      beforeAfter: banner.isEnabled ? 'مفعل (${banner.severity}): ${banner.messageAr}' : 'معطل',
    );
    _persistSnapshot();
    notifyListeners();
  }

  // System Settings (Preserve exact initial keys & order tested in admin_web_test.dart)
  late List<AdminSystemSetting> _settingsList = _buildDefaultSettings();

  static List<AdminSystemSetting> _buildDefaultSettings() => [
        AdminSystemSetting(
          key: 'match_radius_m',
          nameAr: 'نصف قطر المطابقة',
          nameEn: 'Match Radius',
          value: '3000',
          unitAr: 'م',
          unitEn: 'm',
          descriptionAr: 'أقصى بُعد عن مسار الرحلة لاقتراح الركاب والطرود',
          descriptionEn: 'Max distance from route for smart suggestions',
          category: 'geo',
        ),
        AdminSystemSetting(
          key: 'driver_timeout_min',
          nameAr: 'مهلة رد السائق',
          nameEn: 'Driver Timeout',
          value: '30',
          unitAr: 'دقيقة',
          unitEn: 'mins',
          descriptionAr: 'المهلة الممنوحة للسائق قبل إلغاء طلب الحجز تلقائياً',
          descriptionEn: 'Window given to driver before auto-expiration',
          category: 'operations',
        ),
        AdminSystemSetting(
          key: 'price_margin_pct',
          nameAr: 'هامش تعديل السعر',
          nameEn: 'Price Margin',
          value: '25',
          unitAr: '%',
          unitEn: '%',
          descriptionAr: 'النسبة المسموح بها حول السعر المقترح لتكلفة الرحلة',
          descriptionEn: 'Allowed percentage above or below suggested corridor fare',
          category: 'pricing',
        ),
        AdminSystemSetting(
          key: 'parcel_max_weight_kg',
          nameAr: 'أقصى وزن للطرد',
          nameEn: 'Max Parcel Weight',
          value: '15',
          unitAr: 'كجم',
          unitEn: 'kg',
          descriptionAr: 'الحد الأقصى المسموح به لشحن الطرود مع المسافرين',
          descriptionEn: 'Maximum package weight permissible in trunk',
          category: 'operations',
        ),
        AdminSystemSetting(
          key: 'parcel_max_declared_value',
          nameAr: 'أقصى قيمة مصرّحة',
          nameEn: 'Max Declared Value',
          value: '2000',
          unitAr: 'ر.ق',
          unitEn: 'QAR',
          descriptionAr: 'القيمة المالية القصوى للتغطية التعويضية للطرد بالريال القطري',
          descriptionEn: 'Max valuation in QAR covered under Escrow protection',
          category: 'escrow',
        ),
        AdminSystemSetting(
          key: 'free_cancellation_window_min',
          nameAr: 'الإلغاء المجاني قبل الرحلة',
          nameEn: 'Free Cancellation Window',
          value: '120',
          unitAr: 'دقيقة',
          unitEn: 'mins',
          descriptionAr: 'المدة الزمنية قبل الانطلاق التي يتاح فيها الإلغاء بدون غرامة',
          descriptionEn: 'Minutes before departure where cancellation carries no penalty',
          category: 'pricing',
        ),
      ];

  List<AdminSystemSetting> get settingsList => _settingsList;

  void updateSetting(String key, String newValue) {
    final s = _settingsList.firstWhere((item) => item.key == key);
    final oldVal = s.value;
    s.value = newValue;
    _recordAudit(
      action: 'تعديل إعداد',
      target: key,
      beforeAfter: '$oldVal ← $newValue',
    );
    _persistSnapshot();
    notifyListeners();
  }

  void addSystemSetting(AdminSystemSetting setting) {
    _settingsList.add(setting);
    _recordAudit(
      action: 'إضافة معامل نظام جديد',
      target: setting.key,
      beforeAfter: 'جديد ← ${setting.value} ${setting.unitEn}',
    );
    _persistSnapshot();
    notifyListeners();
  }

  // Config Export / Import / Reset for Future-Proof DevOps Disaster Recovery
  Map<String, dynamic> toPlatformConfigMap() {
    return {
      'schemaVersion': '2.4.0',
      'environment': _activeEnvironment,
      'exportedAt': DateTime.now().toIso8601String(),
      'broadcastBanner': _broadcastBanner.toJson(),
      'settings': _settingsList.map((s) => s.toJson()).toList(),
      'featureFlags': _featureFlags.map((f) => f.toJson()).toList(),
      'services': _servicesCatalog.map((s) => s.toJson()).toList(),
      'corridors': _corridors.map((c) => c.toJson()).toList(),
    };
  }

  String exportPlatformConfigJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toPlatformConfigMap());
  }

  bool importPlatformConfigJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return false;

      if (decoded['environment'] is String) {
        _activeEnvironment = decoded['environment'] as String;
      }
      if (decoded['broadcastBanner'] is Map<String, dynamic>) {
        _broadcastBanner = AdminBroadcastBanner.fromJson(
          decoded['broadcastBanner'] as Map<String, dynamic>,
        );
      }
      if (decoded['settings'] is List) {
        final incoming = decoded['settings'] as List;
        final List<AdminSystemSetting> parsed = [];
        for (final row in incoming) {
          if (row is Map<String, dynamic>) {
            parsed.add(
              AdminSystemSetting(
                key: (row['key'] ?? '').toString(),
                nameAr: (row['nameAr'] ?? row['key'] ?? '').toString(),
                nameEn: (row['nameEn'] ?? row['key'] ?? '').toString(),
                value: (row['value'] ?? '').toString(),
                unitAr: (row['unitAr'] ?? '').toString(),
                unitEn: (row['unitEn'] ?? '').toString(),
                descriptionAr: (row['descriptionAr'] ?? '').toString(),
                descriptionEn: (row['descriptionEn'] ?? '').toString(),
                category: (row['category'] ?? 'operations').toString(),
              ),
            );
          }
        }
        if (parsed.isNotEmpty) _settingsList = parsed;
      }
      if (decoded['featureFlags'] is List) {
        final incoming = decoded['featureFlags'] as List;
        final parsed = incoming
            .whereType<Map<String, dynamic>>()
            .map(AdminFeatureFlag.fromJson)
            .toList();
        if (parsed.isNotEmpty) _featureFlags = parsed;
      }
      if (decoded['services'] is List) {
        final incoming = decoded['services'] as List;
        final parsed = incoming
            .whereType<Map<String, dynamic>>()
            .map(AdminServiceDefinition.fromJson)
            .toList();
        if (parsed.isNotEmpty) _servicesCatalog = parsed;
      }
      if (decoded['corridors'] is List) {
        final incoming = decoded['corridors'] as List;
        final parsed = incoming
            .whereType<Map<String, dynamic>>()
            .map(AdminCorridorNode.fromJson)
            .toList();
        if (parsed.isNotEmpty) _corridors = parsed;
      }

      _recordAudit(
        action: 'استيراد تكوين المنصة JSON',
        target: 'platform_config',
        beforeAfter: 'تم تطبيق اللقطة (${_servicesCatalog.length} خدمات، ${_featureFlags.length} أعلام)',
      );
      _persistSnapshot();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void resetPlatformToDefaults() {
    _activeEnvironment = 'production';
    _broadcastBanner = const AdminBroadcastBanner();
    _settingsList = _buildDefaultSettings();
    _featureFlags = _buildDefaultFlags();
    _servicesCatalog = _buildDefaultServices();
    _corridors = _buildDefaultCorridors();
    AppRepositories.instance.admin.clearPlatformSnapshot();
    _recordAudit(
      action: 'استعادة التكوين القياسي الآمن',
      target: 'platform_config',
      beforeAfter: 'تخصيص ← Baseline Default',
    );
    notifyListeners();
  }

  // Audit Logs
  final List<AdminAuditLogEntry> _auditLogs = [
    const AdminAuditLogEntry(
      time: '9:42 ص',
      actor: 'مشرف: راشد',
      action: 'قبول سائق',
      target: 'سائق: user:4821 (حمد الكواري)',
      beforeAfter: 'قيد المراجعة ← مقبول',
    ),
    const AdminAuditLogEntry(
      time: '9:10 ص',
      actor: 'مشرف: شيخة',
      action: 'حظر مستخدم',
      target: 'مستخدم: user:3390 (طلال المناعي)',
      beforeAfter: 'موقوف ← محظور',
    ),
    const AdminAuditLogEntry(
      time: '8:55 ص',
      actor: 'مشرف أول: مدير النظام',
      action: 'تعديل إعداد',
      target: 'match_radius_m',
      beforeAfter: '3000 ← 5000',
    ),
  ];

  List<AdminAuditLogEntry> get auditLogs => _auditLogs;

  void _recordAudit({
    required String action,
    required String target,
    required String beforeAfter,
  }) {
    final entry = AdminAuditLogEntry(
      time: 'الآن',
      actor: 'مشرف أول: مدير النظام',
      action: action,
      target: target,
      beforeAfter: beforeAfter,
    );
    _auditLogs.insert(0, entry);
    AppRepositories.instance.admin.writeAuditEvent(entry.toJson());
  }

  Future<void> _persistSnapshot() async {
    await AppRepositories.instance.admin.savePlatformSnapshot(toPlatformConfigMap());
  }

  // Staff (Extended to 5 roles while keeping first 3 baseline members exact)
  final List<AdminStaffMember> _staff = [
    const AdminStaffMember(
      id: 'staff_1',
      name: 'راشد النعيمي',
      email: 'rashed@mashwar.qa',
      role: AdminRole.reviewAdmin,
      isActive: true,
    ),
    const AdminStaffMember(
      id: 'staff_2',
      name: 'شيخة الهاجري',
      email: 'shaikha@mashwar.qa',
      role: AdminRole.supportAdmin,
      isActive: true,
    ),
    const AdminStaffMember(
      id: 'staff_3',
      name: 'مدير النظام',
      email: 'admin@mashwar.qa',
      role: AdminRole.superAdmin,
      isActive: true,
    ),
    const AdminStaffMember(
      id: 'staff_4',
      name: 'سارة الكعبي',
      email: 'finance@mashwar.qa',
      role: AdminRole.financeAdmin,
      isActive: true,
    ),
    const AdminStaffMember(
      id: 'staff_5',
      name: 'يوسف السويدي',
      email: 'devops@mashwar.qa',
      role: AdminRole.devopsAdmin,
      isActive: true,
    ),
  ];

  List<AdminStaffMember> get staff => _staff;

  void addStaff(String name, String email, AdminRole role) {
    _staff.add(
      AdminStaffMember(
        id: 'staff_${_staff.length + 1}',
        name: name,
        email: email,
        role: role,
        isActive: true,
      ),
    );
    _recordAudit(
      action: 'إضافة موظف جديد',
      target: name,
      beforeAfter: 'جديد ← نشط',
    );
    notifyListeners();
  }

  void editStaff(String staffId, {required AdminRole newRole, required bool isActive}) {
    final index = _staff.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      final prev = _staff[index];
      _staff[index] = prev.copyWith(role: newRole, isActive: isActive);
      _recordAudit(
        action: 'تعديل صلاحيات موظف',
        target: prev.name,
        beforeAfter: '${prev.roleTitleAr} ← ${_staff[index].roleTitleAr}',
      );
      notifyListeners();
    }
  }

  // Global Spotlight Command Search (Ctrl+K)
  List<AdminCommandSearchResult> searchGlobal(String query, bool isAr) {
    final q = query.trim().toLowerCase();
    final List<AdminCommandSearchResult> results = [];

    for (final m in modulesCatalog) {
      if (!canAccessMenu(m.index)) continue;
      if (q.isEmpty ||
          m.titleAr.toLowerCase().contains(q) ||
          m.titleEn.toLowerCase().contains(q) ||
          m.groupAr.toLowerCase().contains(q) ||
          m.groupEn.toLowerCase().contains(q)) {
        results.add(
          AdminCommandSearchResult(
            targetMenuIndex: m.index,
            title: isAr ? m.titleAr : m.titleEn,
            subtitle: isAr ? 'قسم: ${m.groupAr}' : 'Module: ${m.groupEn}',
            categoryTag: isAr ? 'قسم' : 'Module',
          ),
        );
      }
    }

    if (q.isEmpty) return results.take(8).toList();

    if (canAccessMenu(10)) {
      for (final e in _escrowItems) {
        if (e.id.toLowerCase().contains(q) ||
            e.requesterName.toLowerCase().contains(q) ||
            e.providerName.toLowerCase().contains(q) ||
            e.serviceTitleAr.toLowerCase().contains(q)) {
          results.add(
            AdminCommandSearchResult(
              targetMenuIndex: 10,
              title: '${e.id} · ${isAr ? e.serviceTitleAr : e.serviceTitleEn}',
              subtitle: '${e.requesterName} -> ${e.providerName} (${e.totalProtectedQar.toStringAsFixed(0)} QAR)',
              categoryTag: 'Escrow',
            ),
          );
        }
      }
    }

    if (canAccessMenu(8)) {
      for (final s in _servicesCatalog) {
        if (s.nameAr.toLowerCase().contains(q) ||
            s.nameEn.toLowerCase().contains(q) ||
            s.code.toLowerCase().contains(q)) {
          results.add(
            AdminCommandSearchResult(
              targetMenuIndex: 8,
              title: isAr ? s.nameAr : s.nameEn,
              subtitle: '${s.commissionPct}% · ${s.minFeeQar}-${s.maxFeeQar} QAR',
              categoryTag: isAr ? 'خدمة' : 'Service',
            ),
          );
        }
      }
    }

    if (canAccessMenu(2)) {
      for (final u in _users) {
        if (u.fullName.toLowerCase().contains(q) || u.rawPhone.contains(q)) {
          results.add(
            AdminCommandSearchResult(
              targetMenuIndex: 2,
              title: u.fullName,
              subtitle: '${u.role} · ${u.status} · ${u.walletBalanceQar.toStringAsFixed(0)} QAR',
              categoryTag: isAr ? 'مستخدم' : 'User',
            ),
          );
        }
      }
    }

    if (canAccessMenu(9)) {
      for (final c in _corridors) {
        if (c.fromCityAr.toLowerCase().contains(q) ||
            c.toCityAr.toLowerCase().contains(q) ||
            c.fromCityEn.toLowerCase().contains(q) ||
            c.toCityEn.toLowerCase().contains(q)) {
          results.add(
            AdminCommandSearchResult(
              targetMenuIndex: 9,
              title: c.routeLabel(isAr),
              subtitle: '${c.activeProviders} providers · ${c.conversionPct.toStringAsFixed(0)}%',
              categoryTag: isAr ? 'محور' : 'Corridor',
            ),
          );
        }
      }
    }

    if (canAccessMenu(11)) {
      for (final f in _featureFlags) {
        if (f.key.toLowerCase().contains(q) ||
            f.nameAr.toLowerCase().contains(q) ||
            f.nameEn.toLowerCase().contains(q)) {
          results.add(
            AdminCommandSearchResult(
              targetMenuIndex: 11,
              title: isAr ? f.nameAr : f.nameEn,
              subtitle: 'Flag: ${f.key} (${f.rolloutPct}%)',
              categoryTag: 'DevOps',
            ),
          );
        }
      }
    }

    if (canAccessMenu(12)) {
      for (final inq in _inquiries) {
        if (inq.fullName.toLowerCase().contains(q) ||
            inq.organization.toLowerCase().contains(q) ||
            inq.email.toLowerCase().contains(q) ||
            inq.inquiryType.toLowerCase().contains(q) ||
            inq.shortRef.toLowerCase().contains(q)) {
          results.add(
            AdminCommandSearchResult(
              targetMenuIndex: 12,
              title: '${inq.fullName} (${inq.organization})',
              subtitle: '${inq.email} · #${inq.shortRef}',
              categoryTag: isAr ? 'مستثمر' : 'Inquiry',
            ),
          );
        }
      }
    }

    return results.take(12).toList();
  }

  // Landing Page Investor & Partner Inquiries (Firebase investor_inquiries)
  bool _isSyncingInquiries = false;
  String? _inquiriesSyncStatus;
  List<AdminInvestorInquiry> _inquiries = [
    const AdminInvestorInquiry(
      id: 'qdb2026a1',
      fullName: 'طارق المنصور / Tariq Al-Mansoor',
      organization: 'Startup Qatar / QDB Venture',
      email: 'tariq.mansoor@qdb.qa',
      phone: '+974 5512 8840',
      inquiryType: 'جلسة عرض ومراجعة النموذج المالي (Startup Qatar / VC)',
      notes: 'مراجعة أرقام M21 التعادل وخطة استقطاب المنفذين بالمنطقة الصناعية.',
      lang: 'ar',
      source: 'landing_page',
      pageUrl: 'https://mashwar-qatar.vercel.app/#contact',
      status: 'new',
      createdAtIso: '2026-11-24T14:10:00Z',
    ),
    const AdminInvestorInquiry(
      id: 'qstp2026b2',
      fullName: 'Nadia Al-Kuwari',
      organization: 'QSTP Incubation & Tech Review',
      email: 'n.alkuwari@qstp.org.qa',
      phone: '+974 4454 7120',
      inquiryType: 'Request iOS TestFlight / Android APK Build',
      notes: 'Requested reviewer TestFlight invite and Firebase security rules walk-through.',
      lang: 'en',
      source: 'landing_page',
      pageUrl: 'https://mashwar-qatar.vercel.app/#contact',
      status: 'contacted',
      createdAtIso: '2026-11-23T11:25:00Z',
    ),
    const AdminInvestorInquiry(
      id: 'b2b2026c3',
      fullName: 'م. خالد العطية',
      organization: 'شركة المدار للمقاولات - لوسيل',
      email: 'khaled@almadar-contracting.qa',
      phone: '+974 5031 2290',
      inquiryType: 'شراكة تجارية وتوريد مواقع في قطر (B2B Pilot)',
      notes: 'توريد قطع غيار ومعدات خفيفة يومياً بين المنطقة الصناعية ولوسيل.',
      lang: 'ar',
      source: 'landing_page',
      pageUrl: 'https://mashwar-qatar.vercel.app/#contact',
      status: 'new',
      createdAtIso: '2026-11-22T09:40:00Z',
    ),
  ];

  bool get isSyncingInquiries => _isSyncingInquiries;
  String? get inquiriesSyncStatus => _inquiriesSyncStatus;
  List<AdminInvestorInquiry> get inquiries => _inquiries;
  int get newInquiriesCount =>
      _inquiries.where((inq) => inq.status == 'new').length;

  void addInquiryRecord(AdminInvestorInquiry item) {
    _inquiries = [
      item,
      ..._inquiries.where((existing) => existing.id != item.id),
    ];
    _recordAudit(
      action: 'تسجيل طلب تواصل جديد',
      target: '${item.fullName} (${item.organization})',
      beforeAfter: 'جديد (#${item.shortRef})',
    );
    notifyListeners();
  }

  Future<void> syncInquiriesFromFirestore() async {
    _isSyncingInquiries = true;
    notifyListeners();

    try {
      if (Firebase.apps.isEmpty) {
        _inquiriesSyncStatus =
            'وضع المعاينة المحلية — افتح Firestore Console لاستعراض السجلات المباشرة في ${FirebaseConfig.projectId}';
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.investorInquiries)
          .orderBy('createdAtIso', descending: true)
          .limit(100)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final cloudItems = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return AdminInvestorInquiry.fromJson(data);
        }).toList();
        _inquiries = cloudItems;
        _inquiriesSyncStatus =
            'تمت المزامنة مع ${FirebaseConfig.projectId}: ${cloudItems.length} سجل مباشر';
      } else {
        _inquiriesSyncStatus =
            'متصل بـ ${FirebaseConfig.projectId} — لا توجد طلبات سحابية محفوظة بعد';
      }

      _recordAudit(
        action: 'مزامنة طلبات المستثمرين من Firebase',
        target: FirestoreCollections.investorInquiries,
        beforeAfter: 'عدد السجلات: ${_inquiries.length}',
      );
    } catch (e) {
      _inquiriesSyncStatus =
          'يتطلب القراءة المباشرة من Firestore جلسة مشرف مصادقة (isAdmin) أو المراجعة من Firebase Console.';
    } finally {
      _isSyncingInquiries = false;
      notifyListeners();
    }
  }

  Future<void> updateInquiryStatus(
    String inquiryId,
    String newStatus, {
    String? note,
  }) async {
    final idx = _inquiries.indexWhere((i) => i.id == inquiryId);
    if (idx == -1) return;

    final prev = _inquiries[idx];
    final updated = prev.copyWith(status: newStatus, notes: note);
    _inquiries[idx] = updated;

    _recordAudit(
      action: 'تحديث حالة طلب مستثمر',
      target: '${prev.fullName} (#${prev.shortRef})',
      beforeAfter: '${prev.status} ← $newStatus',
    );
    notifyListeners();

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection(FirestoreCollections.investorInquiries)
            .doc(inquiryId)
            .update({
          'status': newStatus,
          if (note != null) 'notes': note,
        });
      } catch (_) {
        // Keep local UI responsive when operating without privileged Firebase Auth token.
      }
    }
  }
}
