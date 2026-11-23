import 'package:flutter/material.dart';

enum AdminRole {
  superAdmin,  // مشرف أول: كل شيء + الإعدادات والموظفون
  reviewAdmin, // مشرف مراجعة: توثيق السائقين فقط
  supportAdmin // مشرف دعم: المستخدمون والبلاغات والنزاعات
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
  });
}

class AdminDisputeItem {
  final String id;
  final String type; // 'طرد', 'مستخدم', 'رحلة'
  final String category; // 'وصل تالف', 'قيادة متهورة', 'احتيال'
  final String complainantName;
  final String againstName;
  final String parcelOrRideDetails;
  String status; // 'مفتوح', 'قيد المراجعة', 'محلول'
  String? assignedTo;
  final List<String> timeline;
  String? resolutionDecision;
  String? internalNote;

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

  AdminSystemSetting({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.value,
    required this.unitAr,
    required this.unitEn,
    required this.descriptionAr,
    required this.descriptionEn,
  });
}

class AdminProvider extends ChangeNotifier {
  bool _isLoggedIn = true;
  String _currentPeriod = '7 أيام'; // 'اليوم', '7 أيام', '30 يوم'
  AdminRole _activeRole = AdminRole.superAdmin; // For permission simulation

  bool get isLoggedIn => _isLoggedIn;
  String get currentPeriod => _currentPeriod;
  AdminRole get activeRole => _activeRole;

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

  bool canAccessMenu(int index) {
    // 0: لوحة الأرقام, 1: توثيق السائقين, 2: المستخدمون, 3: الرحلات والطرود, 4: البلاغات والنزاعات, 5: الإعدادات, 6: الموظفون, 7: سجل التدقيق
    if (_activeRole == AdminRole.superAdmin) return true;
    if (_activeRole == AdminRole.reviewAdmin) {
      return index == 0 || index == 1; // Dashboard and Driver Verifications only
    }
    if (_activeRole == AdminRole.supportAdmin) {
      return index == 0 || index == 2 || index == 3 || index == 4; // Dashboard, Users, Rides/Parcels, Disputes
    }
    return true;
  }

  // Dynamic KPI Stats by Period (Page 69)
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

  // Driver Verifications (Pages 70-71)
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
      status: 'مرفوضة',
      rejectionReason: 'صورة غير واضحة',
      rejectionNote: 'صورة رخصة القيادة القطرية غير واضحة، يرجى إعادة التصوير في إضاءة جيدة.',
    ),
  ];

  List<AdminDriverVerificationRequest> get driverRequests => _driverRequests;

  void acceptDriver(String reqId) {
    final req = _driverRequests.firstWhere((r) => r.id == reqId);
    req.status = 'مقبولة';
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        time: 'الآن',
        actor: 'مشرف أول: مدير النظام',
        action: 'قبول سائق',
        target: 'سائق: ${req.driverName}',
        beforeAfter: 'قيد المراجعة ← مقبولة',
      ),
    );
    notifyListeners();
  }

  void rejectDriver(String reqId, String reason, String note) {
    final req = _driverRequests.firstWhere((r) => r.id == reqId);
    req.status = 'مرفوضة';
    req.rejectionReason = reason;
    req.rejectionNote = note;
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        time: 'الآن',
        actor: 'مشرف أول: مدير النظام',
        action: 'رفض توثيق سائق',
        target: 'سائق: ${req.driverName}',
        beforeAfter: 'قيد المراجعة ← مرفوضة ($reason)',
      ),
    );
    notifyListeners();
  }

  // Users List (Page 72)
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
    ),
  ];

  List<AdminUserItem> get users => _users;

  void banUser(String userId, String reason) {
    final user = _users.firstWhere((u) => u.id == userId);
    final prev = user.status;
    user.status = 'محظور';
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        time: 'الآن',
        actor: 'مشرف أول: مدير النظام',
        action: 'حظر مستخدم',
        target: 'مستخدم: ${user.fullName}',
        beforeAfter: '$prev ← محظور ($reason)',
      ),
    );
    notifyListeners();
  }

  void unbanUser(String userId) {
    final user = _users.firstWhere((u) => u.id == userId);
    user.status = 'نشط';
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        time: 'الآن',
        actor: 'مشرف أول: مدير النظام',
        action: 'رفع الإيقاف',
        target: 'مستخدم: ${user.fullName}',
        beforeAfter: 'موقوف ← نشط',
      ),
    );
    notifyListeners();
  }

  // Rides & Parcels Operations (Page 73)
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

  void manualUpdateRideStatus(String rideId, String newStatus, String reason) {
    final ride = _rides.firstWhere((r) => r.id == rideId);
    final prev = ride.status;
    ride.status = newStatus;
    ride.statusOverrideReason = reason;
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        time: 'الآن',
        actor: 'مشرف أول: مدير النظام',
        action: 'تعديل حالة رحلة يدوياً',
        target: 'رحلة $rideId',
        beforeAfter: '$prev ← $newStatus (السبب: $reason)',
      ),
    );
    notifyListeners();
  }

  // Disputes & Reports (Page 74)
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
      timeline: [
        '7 نوفمبر 7:35 ص: استلم السائق الطرد (صورة مرفقة)',
        '7 نوفمبر 9:50 ص: تسليم برمز صحيح للمستلم',
        '8 نوفمبر 10:12 ص: المستلم أبلغ عن تلف بالظرف',
      ],
      internalNote: 'الصور تؤكد التلف الجزئي للمستندات.',
    ),
    AdminDisputeItem(
      id: '#5126',
      type: 'مستخدم',
      category: 'قيادة متهورة',
      complainantName: 'نورة السليطي',
      againstName: 'جاسم المري',
      parcelOrRideDetails: 'رحلة الدوحة ← الوكرة',
      status: 'قيد المراجعة',
      assignedTo: 'راشد (دعم)',
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
      assignedTo: 'راشد (دعم)',
      resolutionDecision: 'تم حظر الحساب وتعويض الراكبة',
      timeline: [
        '1 نوفمبر: تم تقديم الشكوى والتحقق من التحويل البنكي',
        '2 نوفمبر: تم إيقاف الحساب وتعويض الراكبة',
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
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        time: 'الآن',
        actor: 'مشرف أول: مدير النظام',
        action: 'إسناد بلاغ لموظف',
        target: 'بلاغ $disputeId',
        beforeAfter: '$prev ← $staffName',
      ),
    );
    notifyListeners();
  }

  void resolveDispute(String disputeId, String decision, String note) {
    final d = _disputes.firstWhere((item) => item.id == disputeId);
    d.status = 'محلول';
    d.resolutionDecision = decision;
    d.internalNote = note;
    d.timeline.add('الآن: اعتماد القرار الإداري ($decision)');
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        time: 'الآن',
        actor: 'مشرف أول: مدير النظام',
        action: 'حل نزاع وبلاغ',
        target: 'بلاغ $disputeId',
        beforeAfter: 'مفتوح ← محلول ($decision)',
      ),
    );
    notifyListeners();
  }

  // System Settings (Page 75)
  final List<AdminSystemSetting> _settingsList = [
    AdminSystemSetting(
      key: 'match_radius_m',
      nameAr: 'نصف قطر المطابقة',
      nameEn: 'Match Radius',
      value: '3000',
      unitAr: 'م',
      unitEn: 'm',
      descriptionAr: 'أقصى بُعد عن مسار الرحلة لاقتراح الركاب والطرود',
      descriptionEn: 'Max distance from route for smart suggestions',
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
    ),
    AdminSystemSetting(
      key: 'price_margin_pct',
      nameAr: 'هامش تعديل السعر',
      nameEn: 'Price Margin',
      value: '25',
      unitAr: '%',
      unitEn: '%',
      descriptionAr: 'النسبة المسموح بها حول السعر المقترح لتكلفة البنزين',
      descriptionEn: 'Allowed percentage above or below gas cost estimate',
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
    ),
    AdminSystemSetting(
      key: 'parcel_max_declared_value',
      nameAr: 'أقصى قيمة مصرّحة',
      nameEn: 'Max Declared Value',
      value: '2000',
      unitAr: 'ر.ق',
      unitEn: 'QAR',
      descriptionAr: 'القيمة المالية القصوى للتغطية التعويضية للطرد بالريال القطري',
      descriptionEn: 'Max valuation in QAR covered under passenger shipping insurance',
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
    ),
  ];

  List<AdminSystemSetting> get settingsList => _settingsList;

  void updateSetting(String key, String newValue) {
    final s = _settingsList.firstWhere((item) => item.key == key);
    final oldVal = s.value;
    s.value = newValue;
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        time: 'الآن',
        actor: 'مشرف أول: مدير النظام',
        action: 'تعديل إعداد',
        target: key,
        beforeAfter: '$oldVal ← $newValue',
      ),
    );
    notifyListeners();
  }

  // Audit Logs (Page 76)
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

  // Staff (Page 77)
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
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        time: 'الآن',
        actor: 'مشرف أول: مدير النظام',
        action: 'إضافة موظف جديد',
        target: name,
        beforeAfter: 'جديد ← نشط',
      ),
    );
    notifyListeners();
  }

  void editStaff(String staffId, {required AdminRole newRole, required bool isActive}) {
    final index = _staff.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      final prev = _staff[index];
      _staff[index] = prev.copyWith(role: newRole, isActive: isActive);
      _auditLogs.insert(
        0,
        AdminAuditLogEntry(
          time: 'الآن',
          actor: 'مشرف أول: مدير النظام',
          action: 'تعديل صلاحيات موظف',
          target: prev.name,
          beforeAfter: '${prev.roleTitleAr} ← ${_staff[index].roleTitleAr}',
        ),
      );
      notifyListeners();
    }
  }
}
