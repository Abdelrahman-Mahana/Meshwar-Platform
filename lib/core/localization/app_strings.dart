import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/settings_provider.dart';

class AppStrings {
  AppStrings._();

  // Egyptian Governorates & Cities
  static const Map<String, String> _citiesArToEn = {
    'القاهرة': 'Cairo',
    'الإسكندرية': 'Alexandria',
    'الجيزة': 'Giza',
    'طنطا': 'Tanta',
    'كفر الشيخ': 'Kafr El-Sheikh',
    'المنصورة': 'Mansoura',
    'الزقازيق': 'Zagazig',
    'بنها': 'Banha',
    'دمنهور': 'Damanhour',
    'أسيوط': 'Asyut',
    'سوهاج': 'Sohag',
    'بورسعيد': 'Port Said',
    'السويس': 'Suez',
    'الإسماعيلية': 'Ismailia',
    'دمياط': 'Damietta',
    'الفيوم': 'Fayoum',
    'بني سويف': 'Beni Suef',
    'المنيا': 'Minya',
    'قنا': 'Qena',
    'الأقصر': 'Luxor',
    'أسوان': 'Aswan',
    'كفر الدوار': 'Kafr El-Dawar',
    'كفر الزيات': 'Kafr El-Zayat',
    'المحلة الكبرى': 'El Mahalla El Kubra',
    'شبين الكوم': 'Shebin El Koum',
    'العريش': 'Arish',
    'الغردقة': 'Hurghada',
    'شرم الشيخ': 'Sharm El Sheikh',
    'مرسى مطروح': 'Marsa Matruh',
    'البحيرة': 'Beheira',
    'الغربية': 'Gharbia',
    'الدقهلية': 'Dakahlia',
    'الشرقية': 'Sharqia',
    'القليوبية': 'Qalyubia',
    'المنوفية': 'Menoufia',
    'مدينة': 'City',
    'محافظة': 'Governorate',
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
    'حساب موثق بالرقم القومي': 'National ID Verified',
    'الهوية قيد المراجعة': 'ID Under Review',
    'يرجى توثيق الهوية': 'Verify National ID',
    'معتمدة': 'Approved',
    'مركبة معتمدة': 'Approved Vehicle',
    'مرفوعة وموثقة': 'Uploaded & Verified',
    'مطلوب الرفع': 'Upload Required',
    'تم الرفع': 'Uploaded',
    'أساسي': 'Default',
    'نشط': 'Active',
    'منتهي': 'Expired',
    'تم الاستلام': 'Picked Up',
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
    'احجز رحلة تانية': 'Book Another Ride',
    'إرسال طرد': 'Send Parcel',
    'أقدر أوصّلها': 'I can deliver it',
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
    'حفظ بيانات السيارة': 'Save Vehicle Data',
    'إعادة المحاولة': 'Retry',
    'تقديم بلاغ': 'Submit Report',
    'أبلّغ عن مشكلة': 'Report an issue',
    'تغيير': 'Change',
    'تغيير الرقم': 'Change Number',
    'إعادة إرسال': 'Resend',
    'إعادة إرسال الكود': 'Resend Code',
    'إرسال الكود': 'Send Code',
    'تطبيق': 'Apply',
    'استخدم موقعي الحالي': 'Use Current Location',
    'مكان مقابلة مخصص': 'Custom Meeting Point',

    // General & Navigation
    'الرئيسية': 'Home',
    'اللوحة': 'Board',
    'رحلاتي': 'My Rides',
    'طرودي': 'My Parcels',
    'حسابي': 'Account',
    'مشوار': 'MASHWAR',
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
    'محاور شائعة': 'Popular Routes',
    'عندك عربية؟': 'Have a car?',
    'انشر رحلتك واكسب من الكراسي الفاضية': 'Publish your ride and earn from empty seats',
    'رحلتك القادمة': 'Your Upcoming Ride',
    'رحلتك وطردك في نفس الطريق': 'Your ride and parcel along the same path',
    'بالمتابعة أنت توافق على شروط الاستخدام وسياسة الخصوصية': 'By continuing you agree to Terms of Use & Privacy Policy',

    // Search & Filters
    'من': 'From',
    'إلى': 'To',
    'التاريخ': 'Date',
    'الكراسي': 'Seats',
    'الطرود': 'Parcels',
    'نقطة الانطلاق': 'Departure Point',
    'الوجهة': 'Destination',
    'موقعي الحالي': 'My Current Location',
    'اقتراحات سابقة': 'Recent Locations',
    'ابحث عن محافظة أو مدينة': 'Search governorate or city',
    'الأقرب وقتاً': 'Earliest',
    'الأرخص': 'Cheapest',
    'تقبل طرود': 'Accepts Parcels',
    'للسيدات فقط': 'Ladies Only',
    'الكل': 'All',
    'رحلات': 'Rides',
    'طلب مشوار': 'Ride Request',
    'طلب طرد': 'Parcel Request',
    'كرسي واحد': '1 Seat',
    'طرد واحد': '1 Parcel',
    'نطاق 50 كم': 'Within 50 km',
    'فلترة و ترتيب': 'Filter & Sort',
    'ترتيب حسب': 'Sort By',
    'وقت التحرك': 'Departure Time',
    'أي وقت': 'Any time',
    'صباحاً (5 ص - 12 ظ)': 'Morning (5 AM - 12 PM)',
    'ظهراً (12 ظ - 5 م)': 'Afternoon (12 PM - 5 PM)',
    'مساءً (5 م - 11 م)': 'Evening (5 PM - 11 PM)',
    'خيارات إضافية': 'Additional Options',
    'سيارة مكيفة': 'AC Vehicle',
    'مساحة شنطة كبيرة': 'Large Luggage Space',
    'مفيش رحلات مطابقة دلوقتي': 'No matching rides right now',
    'نبّهني لما تنزل رحلة': 'Alert me when rides are added',
    'تم إنشاء التنبيه بنجاح': 'Alert created successfully',

    // Ride Details & Booking
    'تفاصيل الرحلة': 'Ride Details',
    'سعر المقعد': 'Seat Price',
    'المقاعد المتبقية': 'Remaining Seats',
    'نقطة الصعود': 'Pickup Spot',
    'نقطة النزول': 'Dropoff Spot',
    'وقت الصعود': 'Pickup Time',
    'معلومات السائق': 'Driver Info',
    'سيارة السائق': 'Driver Vehicle',
    'مراجعة الحجز': 'Booking Review',
    'عدد المقاعد': 'Number of Seats',
    'سعر المقعد الواحد': 'Price per Seat',
    'المجموع الإجمالي': 'Total Price',
    'الدفع نقداً عند الصعود': 'Cash upon boarding',
    'بانتظار موافقة السائق': 'Waiting for driver approval',
    'طلبك اتبعت للكابتن': 'Request sent to driver',
    'تم تأكيد الحجز!': 'Booking Confirmed!',
    'تم قبول طلبك، نتمنى لك رحلة سعيدة': 'Your booking was accepted, have a safe trip',
    'للأسف الكابتن اعتذر': 'Unfortunately the driver declined',
    'الرحلة هتبدأ بعد': 'Trip starts in',
    '3 ساعات': '3 Hours',
    'رحلتك الآن': 'Your Active Ride',
    'المسار': 'Route',
    'الإجمالي': 'Total',
    'ج نقداً': 'EGP Cash',
    'ج': 'EGP',
    'ج.م': 'EGP',

    // Parcels
    'محتوى الطرد': 'Parcel Content',
    'الوزن التقديري (كجم)': 'Estimated Weight (kg)',
    'القيمة التقديرية (ج.م)': 'Estimated Value (EGP)',
    'اسم المستلم': 'Receiver Name',
    'رقم موبايل المستلم': 'Receiver Phone',
    'قائمة المواد المحظورة': 'Prohibited Items List',
    'أقر بأن الطرد لا يحتوي على أي مواد ممنوعة': 'I confirm the parcel contains no prohibited items',
    'كود استلام الطرد': 'Parcel Pickup Code',
    'سلّم الكود للناقل عند الاستلام': 'Give code to carrier upon pickup',
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

    // National ID & Settings
    'توثيق بطاقة الرقم القومي': 'National ID Verification',
    'توثيق الهوية بالرقم القومي': 'National ID Verification',
    'الرقم القومي (14 رقم)': 'National ID (14 digits)',
    'وجه البطاقة الشخصية': 'Front of ID Card',
    'ظهر البطاقة الشخصية': 'Back of ID Card',
    'صورة شخصية (سيلفي للتحقق)': 'Verification Selfie',
    'إعدادات التطبيق': 'App Settings',
    'إعدادات التطبيق واللغة': 'App Settings & Language',
    'لغة التطبيق': 'App Language',
    'اللغة والمنطقة': 'Language & Region',
    'محفظة مشوار': 'MASHWAR Wallet',
    'محفظة مشوار وطرق الدفع': 'Wallet & Payment Methods',
    'بيانات سيارتي ورخص القيادة': 'My Vehicle & Driver Licenses',
    'تنبيهات الخطوط والمشاوير': 'Route Alerts',
    'تنبيهات الرحلات': 'Ride Alerts',
    'تحديثات الشحن والطرود': 'Parcel Updates',
    'عروض اللوحة المجتمعية القريبة': 'Nearby Community Board Offers',
    'مركز المساعدة والدعم الفني 24/7': 'Help & Support 24/7',
    'شروط الخدمة وسياسة الخصوصية': 'Terms of Service & Privacy Policy',
    'الترخيص والامتثال لوزارة النقل المصرية': 'MoT Egypt Compliance & License',

    // Dates & Times
    'النهارده': 'Today',
    'اليوم': 'Today',
    'بكرة': 'Tomorrow',
    'غداً': 'Tomorrow',
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

  /// Translate City name (e.g. القاهرة <-> Cairo)
  static String translateCity(String city, {required bool isArabic}) {
    final trimmed = city.trim();
    if (isArabic) {
      return _citiesEnToAr[trimmed.toLowerCase()] ?? trimmed;
    } else {
      return _citiesArToEn[trimmed] ?? trimmed;
    }
  }

  /// Translate Route text (e.g. كفر الشيخ ← القاهرة <-> Kafr El-Sheikh → Cairo)
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

  /// Translate Date & Time strings
  static String translateDate(String dateText, {required bool isArabic}) {
    var result = dateText;
    if (isArabic) {
      result = result
          .replaceAll(',', '،')
          .replaceAll('Today', 'اليوم')
          .replaceAll('Tomorrow', 'غداً')
          .replaceAll('Fri', 'الجمعة')
          .replaceAll('Sat', 'السبت')
          .replaceAll('Sun', 'الأحد')
          .replaceAll('Mon', 'الإثنين')
          .replaceAll('Tue', 'الثلاثاء')
          .replaceAll('Wed', 'الأربعاء')
          .replaceAll('Thu', 'الخميس')
          .replaceAll('Nov', 'نوفمبر')
          .replaceAll('Oct', 'أكتوبر')
          .replaceAll('AM', 'ص')
          .replaceAll('PM', 'م');
    } else {
      result = result
          .replaceAll('،', ',')
          .replaceAll('النهارده', 'Today')
          .replaceAll('اليوم', 'Today')
          .replaceAll('بكرة', 'Tomorrow')
          .replaceAll('غداً', 'Tomorrow')
          .replaceAll('الجمعة', 'Fri')
          .replaceAll('السبت', 'Sat')
          .replaceAll('الأحد', 'Sun')
          .replaceAll('الإثنين', 'Mon')
          .replaceAll('الثلاثاء', 'Tue')
          .replaceAll('الأربعاء', 'Wed')
          .replaceAll('الخميس', 'Thu')
          .replaceAll('نوفمبر', 'Nov')
          .replaceAll('أكتوبر', 'Oct')
          .replaceAll('ص', 'AM')
          .replaceAll('م', 'PM');
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

/// Convenient BuildContext extension for reactive localization anywhere
extension MLocalize on BuildContext {
  bool get isArabic => watch<SettingsProvider>().isArabic;
  String tr(String text) => AppStrings.translate(text, isArabic: isArabic);
  String trCity(String city) => AppStrings.translateCity(city, isArabic: isArabic);
  String trRoute(String route) => AppStrings.translateRoute(route, isArabic: isArabic);
  String trStatus(String status) => AppStrings.translateStatus(status, isArabic: isArabic);
  String trDate(String date) => AppStrings.translateDate(date, isArabic: isArabic);
}
