enum UserGender {
  female, // سيدة
  male,   // رجل
  preferNotToSay, // أفضّل عدم الذكر
}

enum IdVerificationStatus {
  unverified,   // غير موثق
  underReview,  // قيد المراجعة
  verified,     // موثق بنجاح
  rejected,     // مرفوض
}

class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final UserGender gender;
  final String? avatarUrl;
  final bool isVerified;
  final bool hasActiveAlerts;
  final bool hasUpcomingBooking;

  // Key User Profile & Future Operations Data
  final String? governorate; // المحافظة السكنية الأساسية
  final String? city; // المدينة أو الحي
  final String? birthDate; // تاريخ الميلاد للتحقق القانوني (السن >= 18)
  final String? email; // البريد الإلكتروني للفواتير والإشعارات
  final String? emergencyContactName; // اسم جهة الاتصال للطوارئ
  final String? emergencyContactPhone; // رقم هاتف الطوارئ (11 رقم)
  final String? occupation; // المهنة أو جهة الدراسة (لزيادة الثقة والموثوقية)
  final String? smokingPreference; // تفضيل التدخين (غير مدخن / مسموح)
  final String? tripVibe; // جو الرحلة (هادئ / اجتماعي)
  final bool ladiesOnlyPreference; // تفضيل رحلات السيدات فقط

  // Egyptian National ID Verification fields
  final IdVerificationStatus idVerificationStatus;
  final String? nationalId; // 14-digit Egyptian National ID
  final String? idFrontImage;
  final String? idBackImage;
  final String? selfieImage;
  final String? idRejectionReason;
  final double walletBalance; // EGP
  final double rating;
  final int completedRides;
  final int completedParcels;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.gender,
    this.avatarUrl,
    this.isVerified = true,
    this.hasActiveAlerts = false,
    this.hasUpcomingBooking = false,
    this.governorate,
    this.city,
    this.birthDate,
    this.email,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.occupation,
    this.smokingPreference,
    this.tripVibe,
    this.ladiesOnlyPreference = false,
    this.idVerificationStatus = IdVerificationStatus.verified,
    this.nationalId = '29810150102934',
    this.idFrontImage,
    this.idBackImage,
    this.selfieImage,
    this.idRejectionReason,
    this.walletBalance = 450.0,
    this.rating = 4.9,
    this.completedRides = 14,
    this.completedParcels = 6,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    UserGender? gender,
    String? avatarUrl,
    bool? isVerified,
    bool? hasActiveAlerts,
    bool? hasUpcomingBooking,
    String? governorate,
    String? city,
    String? birthDate,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? occupation,
    String? smokingPreference,
    String? tripVibe,
    bool? ladiesOnlyPreference,
    IdVerificationStatus? idVerificationStatus,
    String? nationalId,
    String? idFrontImage,
    String? idBackImage,
    String? selfieImage,
    String? idRejectionReason,
    double? walletBalance,
    double? rating,
    int? completedRides,
    int? completedParcels,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      hasActiveAlerts: hasActiveAlerts ?? this.hasActiveAlerts,
      hasUpcomingBooking: hasUpcomingBooking ?? this.hasUpcomingBooking,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      occupation: occupation ?? this.occupation,
      smokingPreference: smokingPreference ?? this.smokingPreference,
      tripVibe: tripVibe ?? this.tripVibe,
      ladiesOnlyPreference: ladiesOnlyPreference ?? this.ladiesOnlyPreference,
      idVerificationStatus: idVerificationStatus ?? this.idVerificationStatus,
      nationalId: nationalId ?? this.nationalId,
      idFrontImage: idFrontImage ?? this.idFrontImage,
      idBackImage: idBackImage ?? this.idBackImage,
      selfieImage: selfieImage ?? this.selfieImage,
      idRejectionReason: idRejectionReason ?? this.idRejectionReason,
      walletBalance: walletBalance ?? this.walletBalance,
      rating: rating ?? this.rating,
      completedRides: completedRides ?? this.completedRides,
      completedParcels: completedParcels ?? this.completedParcels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'gender': gender.name,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'hasActiveAlerts': hasActiveAlerts,
      'hasUpcomingBooking': hasUpcomingBooking,
      'governorate': governorate,
      'city': city,
      'birthDate': birthDate,
      'email': email,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'occupation': occupation,
      'smokingPreference': smokingPreference,
      'tripVibe': tripVibe,
      'ladiesOnlyPreference': ladiesOnlyPreference,
      'idVerificationStatus': idVerificationStatus.name,
      'nationalId': nationalId,
      'idFrontImage': idFrontImage,
      'idBackImage': idBackImage,
      'selfieImage': selfieImage,
      'idRejectionReason': idRejectionReason,
      'walletBalance': walletBalance,
      'rating': rating,
      'completedRides': completedRides,
      'completedParcels': completedParcels,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      gender: UserGender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => UserGender.male,
      ),
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      hasActiveAlerts: json['hasActiveAlerts'] as bool? ?? false,
      hasUpcomingBooking: json['hasUpcomingBooking'] as bool? ?? false,
      governorate: json['governorate'] as String?,
      city: json['city'] as String?,
      birthDate: json['birthDate'] as String?,
      email: json['email'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      occupation: json['occupation'] as String?,
      smokingPreference: json['smokingPreference'] as String?,
      tripVibe: json['tripVibe'] as String?,
      ladiesOnlyPreference: json['ladiesOnlyPreference'] as bool? ?? false,
      idVerificationStatus: IdVerificationStatus.values.firstWhere(
        (e) => e.name == json['idVerificationStatus'],
        orElse: () => IdVerificationStatus.unverified,
      ),
      nationalId: json['nationalId'] as String?,
      idFrontImage: json['idFrontImage'] as String?,
      idBackImage: json['idBackImage'] as String?,
      selfieImage: json['selfieImage'] as String?,
      idRejectionReason: json['idRejectionReason'] as String?,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      completedRides: (json['completedRides'] as num?)?.toInt() ?? 0,
      completedParcels: (json['completedParcels'] as num?)?.toInt() ?? 0,
    );
  }
}

