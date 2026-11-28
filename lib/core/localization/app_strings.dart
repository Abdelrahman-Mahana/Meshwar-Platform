import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/settings_provider.dart';

class AppStrings {
  AppStrings._();

  // Qatar Municipalities, Cities & Key Logistics Hubs
  static const Map<String, String> _citiesArToEn = {
    'الدوحة': 'Doha',
    'الريان': 'Al Rayyan',
    'الوكرة': 'Al Wakrah',
    'الخور': 'Al Khor',
    'أم صلال': 'Umm Salal',
    'الضعاين': 'Al Daayen',
    'الشمال': 'Al Shamal',
    'الشيحانية': 'Al Shahaniya',
    'لوسيل': 'Lusail',
    'دخان': 'Dukhan',
    'مسيعيد': 'Mesaieed',
    'المنطقة الصناعية': 'Industrial Area',
    'رأس لفان': 'Ras Laffan',
    'اللؤلؤة': 'The Pearl',
    'كتارا': 'Katara',
    'مشيرب': 'Msheireb',
    'المدينة التعليمية': 'Education City',
    'مطار حمد الدولي': 'Hamad Int\'l Airport',
    'السد': 'Al Sadd',
    'الدفنة': 'West Bay',
    'الذخيرة': 'Al Thakhira',
    'أبو سمرة': 'Abu Samra',
    'بلدية الدوحة': 'Doha Municipality',
    'بلدية الريان': 'Al Rayyan Municipality',
    'بلدية الوكرة': 'Al Wakrah Municipality',
    'بلدية الخور والذخيرة': 'Al Khor & Al Thakhira',
    'بلدية أم صلال': 'Umm Salal Municipality',
    'بلدية الضعاين': 'Al Daayen Municipality',
    'بلدية الشمال': 'Al Shamal Municipality',
    'بلدية الشيحانية': 'Al Shahaniya Municipality',
    'مدينة': 'City',
    'منطقة': 'Area',
    'بلدية': 'Municipality',
  };

  static final Map<String, String> _citiesEnToAr = {
    for (final entry in _citiesArToEn.entries) entry.value.toLowerCase(): entry.key,
  };

  // Statuses & Badges
  static const Map<String, String> _statusArToEn = {
    'موثق': 'Verified',
    'غير موثق': 'Unverified',
    'قيد المراجعة': 'Under Review',
    'بانتظار الرد': 'Pending',
    'مؤكد': 'Confirmed',
    'مكتمل': 'Completed',
    'ملغى': 'Cancelled',
    'ملغاة': 'Cancelled',
    'في الطريق': 'In Transit',
    'تم التسليم': 'Delivered',
    'متنازع عليه': 'Disputed',
    'جديد': 'New',
    'موقوف': 'Suspended',
    'متاح': 'Available',
    'متاحة': 'Available',
    'مكتمل المقاعد': 'Full',
    'مكتملة': 'Full',
    'سيدات فقط': 'Ladies Only',
    'للسيدات فقط': 'Ladies Only',
    'حساب موثق': 'Verified Account',
    'حساب موثق بالبطاقة القطرية': 'QID Verified Account',
    'البطاقة قيد المراجعة': 'QID Under Review',
    'يرجى توثيق البطاقة الشخصية': 'Verify Qatar ID (QID)',
    'معتمدة': 'Approved',
    'مركبة معتمدة': 'Approved Vehicle',
    'مرفوعة وموثقة': 'Uploaded & Verified',
    'مطلوب الرفع': 'Upload Required',
    'تم الرفع': 'Uploaded',
    'أساسي': 'Default',
    'نشط': 'Active',
    'منتهي': 'Expired',
    'تم الاستلام': 'Picked Up',
    'مفتوح': 'Open',
    'محلول': 'Resolved',
    'محظور': 'Banned',
    'مرفوض': 'Rejected',
    'مرفوضة': 'Rejected',
    'مقبول': 'Accepted',
    'مقبولة': 'Accepted',
    'منشورة': 'Published',
    'مكتملة الحجز': 'Fully Booked',
    'جارية': 'In Progress',
    'ذروة عالية': 'High Peak',
    'متوقف مؤقتاً': 'Paused',
  };

  static final Map<String, String> _statusEnToAr = {
    for (final entry in _statusArToEn.entries) entry.value.toLowerCase(): entry.key,
  };

  // Common UI Buttons & Labels
  static const Map<String, String> _phrasesArToEn = {
    // Actions & Buttons
    'متابعة': 'Continue',
    'تأكيد': 'Confirm',
    'تأكيد الحجز': 'Confirm Booking',
    'إلغاء': 'Cancel',
    'إلغاء الحجز': 'Cancel Booking',
    'رجوع': 'Back',
    'حفظ': 'Save',
    'تعديل': 'Edit',
    'حذف': 'Delete',
    'إغلاق': 'Close',
    'تم': 'Done',
    'ابدأ': 'Start',
    'خطوة أخيرة وتبدأ': 'One last step to get started',
    'عرّفنا بنفسك': 'Tell us about yourself',
    'بحث': 'Search',
    'بحث عن رحلة': 'Search for a ride',
    'ابحث عن رحلة': 'Search for a ride',
    'ابحث عن مسافر لطردك': 'Find traveler for your parcel',
    'عرض الحجز': 'View Booking',
    'عرض الكل': 'View All',
    'احجز مقعد': 'Book Seat',
    'احجز رحلة أخرى': 'Book Another Ride',
    'إرسال طرد': 'Send Parcel',
    'أقدر أوصلها': 'I can deliver it',
    'أرسل العرض': 'Send Offer',
    'نشر الطلب': 'Post Request',
    'انشر طلبك': 'Post Your Request',
    '+ انشر إعلان': '+ Post Ad',
    'انشر إعلان': 'Post Ad',
    'اتصل بالسائق': 'Call Driver',
    'محادثة شات': 'Chat',
    'محادثة السائق': 'Chat with Driver',
    'محادثة الناقل': 'Chat with Carrier',
    'مشاركة الرحلة': 'Share Ride',
    'تسجيل الدخول': 'Sign In',
    'تسجيل الخروج': 'Log Out',
    'إنشاء حساب': 'Create Account',
    'شحن رصيد': 'Deposit',
    'سحب رصيد': 'Withdraw',
    'إرسال التقييم': 'Submit Review',
    'تقييم المشوار': 'Rate Trip',
    'تقييم السائق والمشوار': 'Rate Driver & Trip',
    'تقييم السائق والمشوار ★': 'Rate Driver & Trip ★',
    'تقييم الشحن': 'Rate Shipping',
    'إرسال وثائق الهوية': 'Submit ID Documents',
    'حفظ بيانات المركبة': 'Save Vehicle Data',
    'إعادة المحاولة': 'Retry',
    'تقديم بلاغ': 'Submit Report',
    'أبلّغ عن مشكلة': 'Report an issue',
    'تغيير': 'Change',
    'تغيير الرقم': 'Change Number',
    'إعادة إرسال': 'Resend',
    'إعادة إرسال الرمز': 'Resend Code',
    'إرسال الرمز': 'Send Code',
    'تطبيق': 'Apply',
    'استخدم موقعي الحالي': 'Use Current Location',
    'نقطة التقاء مخصصة': 'Custom Meeting Point',

    // General & Navigation
    'الرئيسية': 'Home',
    'اللوحة': 'Board',
    'طلباتي': 'My Requests',
    'الرسائل': 'Messages',
    'حسابي': 'Account',
    'رحلاتي': 'My Rides',
    'طرودي': 'My Parcels',
    'مشوار': 'MASHWAR',
    'حيّاك الله': 'Welcome',
    'أهلاً': 'Hello',
    'كراسي': 'Seats',
    'مقاعد': 'Seats',
    'طرود': 'Parcels',
    'قادمة': 'Upcoming',
    'سابقة': 'Past',
    'رحلة': 'Rides',
    'طرد': 'Parcels',
    'تقييم': 'Rating',
    'المحفظة': 'Wallet',
    'تنبيهاتي': 'My Alerts',
    'مسارات شائعة': 'Popular Routes',
    'عندك سيارة؟': 'Have a car?',
    'انشر رحلتك وحقق دخلاً من المقاعد الشاغرة': 'Publish your ride and earn from empty seats',
    'رحلتك القادمة': 'Your Upcoming Ride',
    'رحلتك وطردك في نفس الطريق': 'Your ride and parcel along the same path',
    'بالمتابعة أنت توافق على شروط الاستخدام وسياسة الخصوصية': 'By continuing you agree to Terms of Use & Privacy Policy',

    // Search & Filters
    'من': 'From',
    'إلى': 'To',
    'التاريخ': 'Date',
    'المقاعد': 'Seats',
    'الطرود': 'Parcels',
    'نقطة الانطلاق': 'Departure Point',
    'الوجهة': 'Destination',
    'موقعي الحالي': 'My Current Location',
    'اقتراحات سابقة': 'Recent Locations',
    'ابحث عن بلدية أو منطقة': 'Search municipality or district',
    'الأقرب وقتاً': 'Earliest',
    'الأرخص': 'Cheapest',
    'تقبل طرود': 'Accepts Parcels',
    'للسيدات فقط': 'Ladies Only',
    'الكل': 'All',
    'رحلات': 'Rides',
    'طلب مشوار': 'Ride Request',
    'طلب طرد': 'Parcel Request',
    'مقعد واحد': '1 Seat',
    'طرد واحد': '1 Parcel',
    'نطاق 50 كم': 'Within 50 km',
    'فلترة وترتيب': 'Filter & Sort',
    'ترتيب حسب': 'Sort By',
    'وقت الانطلاق': 'Departure Time',
    'أي وقت': 'Any time',
    'صباحاً (5 ص - 12 ظ)': 'Morning (5 AM - 12 PM)',
    'ظهراً (12 ظ - 5 م)': 'Afternoon (12 PM - 5 PM)',
    'مساءً (5 م - 11 م)': 'Evening (5 PM - 11 PM)',
    'خيارات إضافية': 'Additional Options',
    'سيارة مكيفة': 'AC Vehicle',
    'مساحة صندوق كبيرة': 'Large Trunk Space',
    'ما في رحلات مطابقة حالياً': 'No matching rides right now',
    'نبّهني عند إضافة رحلات': 'Alert me when rides are added',
    'تم إنشاء التنبيه بنجاح': 'Alert created successfully',

    // Ride Details & Booking
    'تفاصيل الرحلة': 'Ride Details',
    'سعر المقعد': 'Seat Price',
    'المقاعد المتبقية': 'Remaining Seats',
    'نقطة الركوب': 'Pickup Spot',
    'نقطة النزول': 'Dropoff Spot',
    'وقت الركوب': 'Pickup Time',
    'معلومات السائق': 'Driver Info',
    'سيارة السائق': 'Driver Vehicle',
    'مراجعة الحجز': 'Booking Review',
    'عدد المقاعد': 'Number of Seats',
    'سعر المقعد الواحد': 'Price per Seat',
    'المجموع الإجمالي': 'Total Price',
    'الدفع نقداً عند الركوب': 'Cash upon boarding',
    'بانتظار موافقة السائق': 'Waiting for driver approval',
    'تم إرسال طلبك للكابتن': 'Request sent to driver',
    'تم تأكيد الحجز!': 'Booking Confirmed!',
    'تم قبول طلبك، نتمنى لك رحلة آمنة وموفقة': 'Your booking was accepted, have a safe trip',
    'عذراً، الكابتن اعتذر عن الطلب': 'Unfortunately the driver declined',
    'تنطلق الرحلة خلال': 'Trip starts in',
    '45 دقيقة': '45 Minutes',
    'رحلتك الآن': 'Your Active Ride',
    'المسار': 'Route',
    'الإجمالي': 'Total',
    'ر.ق نقداً': 'QAR Cash',
    'ر.ق': 'QAR',

    // Parcels
    'محتوى الطرد': 'Parcel Content',
    'الوزن التقديري (كجم)': 'Estimated Weight (kg)',
    'القيمة التقديرية (ر.ق)': 'Estimated Value (QAR)',
    'اسم المستلم': 'Receiver Name',
    'رقم جوال المستلم': 'Receiver Mobile',
    'قائمة المواد المحظورة': 'Prohibited Items List',
    'أقر بأن الطرد لا يحتوي على أي مواد ممنوعة': 'I confirm the parcel contains no prohibited items',
    'رمز استلام الطرد': 'Parcel Pickup Code',
    'سلّم الرمز للناقل عند الاستلام': 'Give code to carrier upon pickup',
    'تتبع مسار الطرد': 'Track Parcel',
    'تفاصيل الشحنة': 'Shipment Details',
    'تم طلب الشحن': 'Shipping Requested',
    'في الطريق للمستلم': 'On the way to receiver',
    'تم تسليم الطرد بنجاح': 'Parcel Delivered Successfully',
    'نزاع على طرد': 'Parcel Dispute',
    'تقديم بلاغ عن شحنة': 'Report Parcel Issue',
    'أوراق رسمية': 'Official Documents',
    'ملابس': 'Clothes',
    'هدية': 'Gift',
    'صغير': 'Small',
    'متوسط': 'Medium',
    'كبير': 'Large',
    'ظرف': 'Envelope',

    // Qatar ID (QID) & Settings
    'توثيق البطاقة الشخصية القطرية (QID)': 'Qatar ID (QID) Verification',
    'توثيق الهوية بالبطاقة القطرية': 'Qatar ID Verification',
    'الرقم الشخصي القطري (11 رقم)': 'Qatar ID Number (11 digits)',
    'وجه البطاقة الشخصية': 'Front of ID Card',
    'ظهر البطاقة الشخصية': 'Back of ID Card',
    'صورة شخصية (سيلفي للتحقق)': 'Verification Selfie',
    'إعدادات التطبيق': 'App Settings',
    'إعدادات التطبيق واللغة': 'App Settings & Language',
    'لغة التطبيق': 'App Language',
    'اللغة والمنطقة': 'Language & Region',
    'محفظة مشوار': 'MASHWAR Wallet',
    'محفظة مشوار وطرق الدفع': 'Wallet & Payment Methods',
    'بيانات مركبتي ورخص القيادة': 'My Vehicle & Driver Licenses',
    'تنبيهات المسارات والمشاوير': 'Route Alerts',
    'تنبيهات الرحلات': 'Ride Alerts',
    'تحديثات الشحن والطرود': 'Parcel Updates',
    'عروض اللوحة المجتمعية القريبة': 'Nearby Community Board Offers',
    'مركز المساعدة والدعم الفني 24/7': 'Help & Support 24/7',
    'شروط الخدمة وسياسة الخصوصية': 'Terms of Service & Privacy Policy',
    'الترخيص والامتثال لوزارة المواصلات القطرية': 'MOT Qatar Compliance & License',

    // Dates & Times
    'اليوم': 'Today',
    'باكر': 'Tomorrow',
    'غداً': 'Tomorrow',
    'الحين': 'Now',
    'الآن': 'Now',
    'الجمعة': 'Friday',
    'السبت': 'Saturday',
    'الأحد': 'Sunday',
    'الإثنين': 'Monday',
    'الثلاثاء': 'Tuesday',
    'الأربعاء': 'Wednesday',
    'الخميس': 'Thursday',
  };

  static final Map<String, String> _phrasesEnToAr = {
    for (final entry in _phrasesArToEn.entries) entry.value.toLowerCase(): entry.key,
  };

  /// Translate City / Municipality name (e.g. الدوحة <-> Doha)
  static String translateCity(String city, {required bool isArabic}) {
    final trimmed = city.trim();
    if (isArabic) {
      return _citiesEnToAr[trimmed.toLowerCase()] ?? trimmed;
    } else {
      return _citiesArToEn[trimmed] ?? trimmed;
    }
  }

  /// Translate Route text (e.g. الدوحة ← الخور <-> Doha → Al Khor)
  static String translateRoute(String route, {required bool isArabic}) {
    if (route.contains('←')) {
      final parts = route.split('←').map((s) => s.trim()).toList();
      if (parts.length == 2) {
        final c1 = translateCity(parts[0], isArabic: isArabic);
        final c2 = translateCity(parts[1], isArabic: isArabic);
        return isArabic ? '$c1 ← $c2' : '$c1 → $c2';
      }
    } else if (route.contains('→')) {
      final parts = route.split('→').map((s) => s.trim()).toList();
      if (parts.length == 2) {
        final c1 = translateCity(parts[0], isArabic: isArabic);
        final c2 = translateCity(parts[1], isArabic: isArabic);
        return isArabic ? '$c1 ← $c2' : '$c1 → $c2';
      }
    }
    return translate(route, isArabic: isArabic);
  }

  /// Translate Status Badge label (e.g. مؤكد <-> Confirmed)
  static String translateStatus(String status, {required bool isArabic}) {
    final trimmed = status.trim();
    if (isArabic) {
      return _statusEnToAr[trimmed.toLowerCase()] ?? _phrasesEnToAr[trimmed.toLowerCase()] ?? trimmed;
    } else {
      return _statusArToEn[trimmed] ?? _phrasesArToEn[trimmed] ?? trimmed;
    }
  }

  static final RegExp _standaloneArabicAmRegex =
      RegExp(r'(?<![\u0600-\u06FF])ص(?![\u0600-\u06FF])');
  static final RegExp _standaloneArabicPmRegex =
      RegExp(r'(?<![\u0600-\u06FF])م(?![\u0600-\u06FF])');

  /// Translate Date & Time strings
  static String translateDate(String dateText, {required bool isArabic}) {
    var result = dateText;
    if (isArabic) {
      result = result
          .replaceAll(',', '،')
          .replaceAll(RegExp(r'\bToday\b'), 'اليوم')
          .replaceAll(RegExp(r'\bTomorrow\b'), 'غداً')
          .replaceAll(RegExp(r'\bFriday\b'), 'الجمعة')
          .replaceAll(RegExp(r'\bSaturday\b'), 'السبت')
          .replaceAll(RegExp(r'\bSunday\b'), 'الأحد')
          .replaceAll(RegExp(r'\bMonday\b'), 'الإثنين')
          .replaceAll(RegExp(r'\bTuesday\b'), 'الثلاثاء')
          .replaceAll(RegExp(r'\bWednesday\b'), 'الأربعاء')
          .replaceAll(RegExp(r'\bThursday\b'), 'الخميس')
          .replaceAll(RegExp(r'\bFri\b'), 'الجمعة')
          .replaceAll(RegExp(r'\bSat\b'), 'السبت')
          .replaceAll(RegExp(r'\bSun\b'), 'الأحد')
          .replaceAll(RegExp(r'\bMon\b'), 'الإثنين')
          .replaceAll(RegExp(r'\bTue\b'), 'الثلاثاء')
          .replaceAll(RegExp(r'\bWed\b'), 'الأربعاء')
          .replaceAll(RegExp(r'\bThu\b'), 'الخميس')
          .replaceAll(RegExp(r'\bJanuary\b'), 'يناير')
          .replaceAll(RegExp(r'\bFebruary\b'), 'فبراير')
          .replaceAll(RegExp(r'\bMarch\b'), 'مارس')
          .replaceAll(RegExp(r'\bApril\b'), 'أبريل')
          .replaceAll(RegExp(r'\bMay\b'), 'مايو')
          .replaceAll(RegExp(r'\bJune\b'), 'يونيو')
          .replaceAll(RegExp(r'\bJuly\b'), 'يوليو')
          .replaceAll(RegExp(r'\bAugust\b'), 'أغسطس')
          .replaceAll(RegExp(r'\bSeptember\b'), 'سبتمبر')
          .replaceAll(RegExp(r'\bOctober\b'), 'أكتوبر')
          .replaceAll(RegExp(r'\bNovember\b'), 'نوفمبر')
          .replaceAll(RegExp(r'\bDecember\b'), 'ديسمبر')
          .replaceAll(RegExp(r'\bJan\b'), 'يناير')
          .replaceAll(RegExp(r'\bFeb\b'), 'فبراير')
          .replaceAll(RegExp(r'\bMar\b'), 'مارس')
          .replaceAll(RegExp(r'\bApr\b'), 'أبريل')
          .replaceAll(RegExp(r'\bJun\b'), 'يونيو')
          .replaceAll(RegExp(r'\bJul\b'), 'يوليو')
          .replaceAll(RegExp(r'\bAug\b'), 'أغسطس')
          .replaceAll(RegExp(r'\bSep\b'), 'سبتمبر')
          .replaceAll(RegExp(r'\bOct\b'), 'أكتوبر')
          .replaceAll(RegExp(r'\bNov\b'), 'نوفمبر')
          .replaceAll(RegExp(r'\bDec\b'), 'ديسمبر')
          .replaceAll(RegExp(r'\bAM\b'), 'ص')
          .replaceAll(RegExp(r'\bPM\b'), 'م');
    } else {
      result = result
          .replaceAll('،', ',')
          .replaceAll('اليوم', 'Today')
          .replaceAll('باكر', 'Tomorrow')
          .replaceAll('غداً', 'Tomorrow')
          .replaceAll('الجمعة', 'Fri')
          .replaceAll('السبت', 'Sat')
          .replaceAll('الأحد', 'Sun')
          .replaceAll('الإثنين', 'Mon')
          .replaceAll('الثلاثاء', 'Tue')
          .replaceAll('الأربعاء', 'Wed')
          .replaceAll('الخميس', 'Thu')
          .replaceAll('يناير', 'Jan')
          .replaceAll('فبراير', 'Feb')
          .replaceAll('مارس', 'Mar')
          .replaceAll('أبريل', 'Apr')
          .replaceAll('ابريل', 'Apr')
          .replaceAll('مايو', 'May')
          .replaceAll('يونيو', 'Jun')
          .replaceAll('يوليو', 'Jul')
          .replaceAll('أغسطس', 'Aug')
          .replaceAll('اغسطس', 'Aug')
          .replaceAll('سبتمبر', 'Sep')
          .replaceAll('أكتوبر', 'Oct')
          .replaceAll('اكتوبر', 'Oct')
          .replaceAll('نوفمبر', 'Nov')
          .replaceAll('ديسمبر', 'Dec')
          .replaceAll(_standaloneArabicAmRegex, 'AM')
          .replaceAll(_standaloneArabicPmRegex, 'PM');
    }
    return result;
  }

  /// Smart translation for phrases, buttons, and titles
  static String translate(String text, {required bool isArabic}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    if (isArabic) {
      return _phrasesEnToAr[trimmed.toLowerCase()] ?? _statusEnToAr[trimmed.toLowerCase()] ?? _citiesEnToAr[trimmed.toLowerCase()] ?? trimmed;
    } else {
      return _phrasesArToEn[trimmed] ?? _statusArToEn[trimmed] ?? _citiesArToEn[trimmed] ?? trimmed;
    }
  }

  /// Direct key-value lookup
  static String get(String key, {bool isArabic = true}) {
    return translate(key, isArabic: isArabic);
  }
}

/// Formal Flutter Localizations class & delegate for Arabic ('ar') and English ('en').
/// Works seamlessly alongside SettingsProvider and MLocalize context helpers.
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  bool get isArabic => locale.languageCode == 'ar';

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ar', 'QA'),
    Locale('ar'),
    Locale('en', 'US'),
    Locale('en'),
  ];

  String translate(String text) => AppStrings.translate(text, isArabic: isArabic);
  String translateCity(String city) => AppStrings.translateCity(city, isArabic: isArabic);
  String translateRoute(String route) => AppStrings.translateRoute(route, isArabic: isArabic);
  String translateDate(String dateStr) => AppStrings.translateDate(dateStr, isArabic: isArabic);
  String translateStatus(String status) => AppStrings.translateStatus(status, isArabic: isArabic);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Convenient BuildContext extension for reactive localization anywhere
extension MLocalize on BuildContext {
  bool get isArabic {
    try {
      return watch<SettingsProvider>().isArabic;
    } catch (_) {
      return AppLocalizations.of(this)?.isArabic ?? true;
    }
  }

  String tr(String text) => AppStrings.translate(text, isArabic: isArabic);
  String trCity(String city) => AppStrings.translateCity(city, isArabic: isArabic);
  String trRoute(String route) => AppStrings.translateRoute(route, isArabic: isArabic);
  String trStatus(String status) => AppStrings.translateStatus(status, isArabic: isArabic);
  String trDate(String dateStr) => AppStrings.translateDate(dateStr, isArabic: isArabic);
}
