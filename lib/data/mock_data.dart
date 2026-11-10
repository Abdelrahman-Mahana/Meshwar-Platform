import 'models/user_model.dart';
import 'models/ride_model.dart';
import 'models/parcel_model.dart';
import 'models/board_ad_model.dart';
import 'models/route_alert_model.dart';
import 'models/location_item.dart';

class MockData {
  MockData._();

  // Current logged in user (Page 6 & Page 9)
  static const UserModel currentUser = UserModel(
    id: 'user_01',
    fullName: 'عبدالرحمن أحمد',
    phone: '01012345678',
    gender: UserGender.male,
    governorate: 'كفر الشيخ',
    city: 'مدينة كفر الشيخ',
    birthDate: '1996-08-20',
    email: 'abdelrahman@mashwar.example',
    emergencyContactName: 'أحمد محمود (الوالد)',
    emergencyContactPhone: '01009876543',
    occupation: 'مهندس برمجيات',
    smokingPreference: 'غير مدخن',
    tripVibe: 'هادئ ومريح',
    ladiesOnlyPreference: false,
    isVerified: true,
    hasActiveAlerts: true,
    hasUpcomingBooking: true,
  );

  // Available Locations for Egypt
  static const List<LocationItem> locations = [
    LocationItem(name: 'القاهرة', region: 'محافظة', typeLabel: 'محافظة', isRecent: true),
    LocationItem(name: 'طنطا', region: 'الغربية', typeLabel: 'مدينة', isRecent: true),
    LocationItem(name: 'كفر الشيخ', region: 'كفر الشيخ', typeLabel: 'محافظة'),
    LocationItem(name: 'كفر الدوار', region: 'البحيرة', typeLabel: 'مدينة'),
    LocationItem(name: 'كفر الزيات', region: 'الغربية', typeLabel: 'مدينة'),
    LocationItem(name: 'الإسكندرية', region: 'الإسكندرية', typeLabel: 'محافظة'),
    LocationItem(name: 'المنصورة', region: 'الدقهلية', typeLabel: 'مدينة'),
    LocationItem(name: 'الزقازيق', region: 'الشرقية', typeLabel: 'مدينة'),
    LocationItem(name: 'بنها', region: 'القليوبية', typeLabel: 'مدينة'),
    LocationItem(name: 'دمنهور', region: 'البحيرة', typeLabel: 'مدينة'),
    LocationItem(name: 'أسيوط', region: 'أسيوط', typeLabel: 'محافظة'),
    LocationItem(name: 'سوهاج', region: 'سوهاج', typeLabel: 'محافظة'),
  ];

  // Rides based on Page 10, 11
  static final List<RideModel> initialRides = [
    const RideModel(
      id: 'ride_1',
      driverName: 'محمد سعيد',
      driverCar: 'هيونداي إلنترا، أبيض',
      driverPhone: '0100 123 4567',
      fromCity: 'كفر الشيخ',
      toCity: 'القاهرة',
      pickupPoint: 'محطة وقود، مدخل كفر الشيخ',
      dropoffPoint: 'محطة المترو، القاهرة',
      departureTime: '7:30 ص',
      departureDate: 'الجمعة 6 نوفمبر',
      remainingSeats: 2,
      pricePerSeat: 120,
      acceptsParcels: true,
      parcelPrice: 40,
      isVerified: true,
      isLadiesOnly: false,
      isInstantBooking: true,
    ),
    const RideModel(
      id: 'ride_2',
      driverName: 'أحمد علي',
      driverCar: 'كيا سيراتو، رمادي',
      driverPhone: '0112 345 6789',
      fromCity: 'كفر الشيخ',
      toCity: 'القاهرة',
      pickupPoint: 'موقف الجامعة، كفر الشيخ',
      dropoffPoint: 'ميدان رمسيس، القاهرة',
      departureTime: '9:00 ص',
      departureDate: 'الجمعة 6 نوفمبر',
      remainingSeats: 3,
      pricePerSeat: 110,
      acceptsParcels: true,
      parcelPrice: 45,
      isVerified: true,
      isLadiesOnly: false,
      isInstantBooking: false,
    ),
    const RideModel(
      id: 'ride_3',
      driverName: 'منى حسن',
      driverCar: 'تويوتا كورولا، أسود',
      driverPhone: '0123 456 7890',
      fromCity: 'كفر الشيخ',
      toCity: 'القاهرة',
      pickupPoint: 'مدخل المدينة الجديد',
      dropoffPoint: 'التجمع الخامس، القاهرة',
      departureTime: '1:15 م',
      departureDate: 'الجمعة 6 نوفمبر',
      remainingSeats: 1,
      pricePerSeat: 130,
      acceptsParcels: false,
      parcelPrice: 0,
      isVerified: true,
      isLadiesOnly: true,
      isInstantBooking: true,
    ),
  ];

  // Community Board Ads based on Page 21 & 22
  static final List<BoardAdModel> initialBoardAds = [
    const BoardAdModel(
      id: 'ad_1',
      type: BoardAdType.rideOffer,
      authorName: 'محمد سعيد',
      tripCount: 14,
      postedAgo: 'نُشر من ساعة',
      fromCity: 'كفر الشيخ',
      toCity: 'القاهرة',
      timeText: 'الجمعة 7:30 ص · 2 كراسي فاضية',
      description: 'تقبل طرود صغيرة ومتوسطة',
      priceOrBudget: 120,
      notes: 'التجمع عند محطة الوقود',
      status: BoardAdStatus.active,
    ),
    const BoardAdModel(
      id: 'ad_2',
      type: BoardAdType.rideRequest,
      authorName: 'ياسمين',
      tripCount: 6,
      postedAgo: 'نُشر من ساعتين',
      fromCity: 'طنطا',
      toCity: 'القاهرة',
      timeText: 'الجمعة بعد الظهر · كرسي واحد',
      description: 'الميزانية: حتى 80 ج',
      priceOrBudget: 80,
      notes: 'شنطة سفر واحدة',
      isLadiesOnly: false,
      status: BoardAdStatus.active,
    ),
    const BoardAdModel(
      id: 'ad_3',
      type: BoardAdType.parcelRequest,
      authorName: 'كريم',
      tripCount: 8,
      postedAgo: 'نُشر من 3 ساعات',
      fromCity: 'الإسكندرية',
      toCity: 'القاهرة',
      timeText: 'طرد صغير · 2 كجم · أوراق',
      description: 'المكافأة: 40 ج، المطلوب قبل الأحد',
      priceOrBudget: 40,
      notes: 'مستندات رسمية مغلقة',
      status: BoardAdStatus.active,
    ),
    const BoardAdModel(
      id: 'ad_4',
      type: BoardAdType.parcelRequest,
      authorName: 'منى',
      tripCount: 11,
      postedAgo: 'نُشر من 4 ساعات',
      fromCity: 'طنطا',
      toCity: 'الإسكندرية',
      timeText: 'طرد متوسط · 5 كجم · هدوم',
      description: 'المكافأة: 60 ج، المطلوب قبل السبت',
      priceOrBudget: 60,
      notes: 'ملابس جديدة معلبة',
      status: BoardAdStatus.active,
    ),
  ];

  // Route Alerts based on Page 20
  static final List<RouteAlertModel> initialAlerts = [
    const RouteAlertModel(
      id: 'alert_1',
      fromCity: 'كفر الشيخ',
      toCity: 'القاهرة',
      dateRange: '6 إلى 8 نوفمبر',
      category: 'ركاب',
      isActive: true,
      isExpired: false,
    ),
    const RouteAlertModel(
      id: 'alert_2',
      fromCity: 'القاهرة',
      toCity: 'الإسكندرية',
      dateRange: 'الجمعة 13 نوفمبر',
      category: 'طرد',
      isActive: true,
      isExpired: false,
    ),
    const RouteAlertModel(
      id: 'alert_3',
      fromCity: 'طنطا',
      toCity: 'القاهرة',
      dateRange: 'انتهى التنبيه',
      category: 'ركاب',
      isActive: false,
      isExpired: true,
    ),
  ];

  // Sample Parcel for Tracking (Page 14)
  static const ParcelModel activeParcel = ParcelModel(
    id: 'parcel_991',
    driverName: 'محمد سعيد',
    route: 'كفر الشيخ ← القاهرة · هدوم في كيس',
    description: 'هدوم في كيس',
    size: ParcelSize.small,
    weightKg: 3.0,
    estimatedValue: 500,
    receiverName: 'سارة أحمد',
    receiverPhone: '01155512345',
    fee: 40,
    pickupOtp: '4 8 2 1',
    status: ParcelStatusStep.accepted,
  );
}

