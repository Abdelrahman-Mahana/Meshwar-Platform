import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mashwar/data/models/board_ad_model.dart';
import 'package:mashwar/data/models/parcel_model.dart';
import 'package:mashwar/data/models/ride_model.dart';
import 'package:mashwar/screens/board/make_offer_sheet.dart';
import 'package:mashwar/screens/home/city_search_modal.dart';
import 'package:mashwar/screens/parcel/parcel_tracking_screen.dart';
import 'package:mashwar/screens/ride_details/ride_details_screen.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';

void main() {
  testWidgets('RideDetailsScreen displays Co-Passengers preview and Safety Share card', (tester) async {
    const testRide = RideModel(
      id: 'ride_01',
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
      pricePerSeat: 65,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => RidesProvider()),
        ],
        child: const MaterialApp(
          home: RideDetailsScreen(ride: testRide),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Co-passengers card exists
    expect(find.text('من يسافر معك في نفس الرحلة؟'), findsOneWidget);
    expect(find.text('سارة م.'), findsOneWidget);
    expect(find.text('أحمد ك.'), findsOneWidget);

    // Verify Safety & Family Share card exists
    expect(find.text('الأمان وضمان السفر'), findsOneWidget);
    expect(find.text('مشاركة تفاصيل الرحلة مع عائلتك'), findsOneWidget);
  });

  testWidgets('MakeOfferSheet renders inDrive-style quick increment chips', (tester) async {
    const ad = BoardAdModel(
      id: 'ad_1',
      authorName: 'سارة أحمد',
      type: BoardAdType.rideRequest,
      fromCity: 'طنطا',
      toCity: 'القاهرة',
      timeText: 'الجمعة 8:00 ص',
      description: 'محتاجة كرسي الجمعة صباحاً',
      priceOrBudget: 70,
      postedAgo: 'منذ ساعتين',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => BoardProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MakeOfferSheet(ad: ad),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "قدّم عرض توصيل" button to enter offer mode
    await tester.tap(find.text('قدّم عرض توصيل'));
    await tester.pumpAndSettle();

    // Verify quick increment chips (-10, Listed, +10, +20)
    expect(find.text('-10 ج'), findsOneWidget);
    expect(find.text('+10 ج'), findsOneWidget);
    expect(find.text('+20 ج'), findsOneWidget);
    expect(find.textContaining('نطاق مشاركة التكلفة العادل لهذا المسار'), findsOneWidget);

    // Tap +20 chip and verify input is updated to 90
    await tester.tap(find.text('+20 ج'));
    await tester.pumpAndSettle();
    expect(find.text('90'), findsOneWidget);
  });

  testWidgets('CitySearchModal displays Egyptian landmark chips', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MaterialApp(
          home: CitySearchModal(title: 'نقطة الانطلاق'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify smart landmark chips exist
    expect(find.text('بوابات الرسوم (الكارتة)'), findsOneWidget);
    expect(find.text('محطة مصر / القطار'), findsOneWidget);
    expect(find.text('بنزينة وطنية / المدخل'), findsOneWidget);
    expect(find.text('موقف الأقاليم'), findsOneWidget);
  });

  testWidgets('ParcelTrackingScreen displays live recipient share card', (tester) async {
    const parcel = ParcelModel(
      id: '4821',
      driverName: 'محمد سعيد',
      route: 'كفر الشيخ ← القاهرة',
      description: 'أوراق هامة',
      size: ParcelSize.medium,
      weightKg: 1.5,
      estimatedValue: 200,
      receiverName: 'سارة أحمد',
      receiverPhone: '01098765432',
      fee: 50,
      pickupOtp: '4 8 2 1',
      status: ParcelStatusStep.inTransit,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MaterialApp(
          home: ParcelTrackingScreen(parcel: parcel),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify live recipient share card exists
    expect(find.text('مشاركة التتبع المباشر مع المستلم'), findsOneWidget);
    expect(find.text('إرسال رابط التتبع عبر واتساب'), findsOneWidget);
  });
}
