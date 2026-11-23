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
      driverName: 'جاسم الكواري',
      driverCar: 'تويوتا كامري، أبيض لؤلؤي',
      driverPhone: '5523 4567',
      fromCity: 'الدوحة',
      toCity: 'الخور',
      pickupPoint: 'محطة وقود (WOQOD)، مشيرب',
      dropoffPoint: 'مدخل الخور، بوابة المدينة',
      departureTime: '7:30 ص',
      departureDate: 'الجمعة 6 نوفمبر',
      remainingSeats: 2,
      pricePerSeat: 35,
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
    expect(find.text('نورة م.'), findsOneWidget);
    expect(find.text('حمد ك.'), findsOneWidget);

    // Verify Safety & Family Share card exists
    expect(find.text('الأمان وضمان السفر'), findsOneWidget);
    expect(find.text('مشاركة تفاصيل الرحلة مع عائلتك'), findsOneWidget);
  });

  testWidgets('MakeOfferSheet renders inDrive-style quick increment chips', (tester) async {
    const ad = BoardAdModel(
      id: 'test_ad_1',
      authorName: 'نورة الكواري',
      type: BoardAdType.rideRequest,
      fromCity: 'لوسيل',
      toCity: 'الدوحة',
      timeText: 'الجمعة 8:00 ص',
      description: 'أرغب في مقعد صباح الجمعة',
      priceOrBudget: 35,
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
    expect(find.text('-10 ر.ق'), findsOneWidget);
    expect(find.text('+10 ر.ق'), findsOneWidget);
    expect(find.text('+20 ر.ق'), findsOneWidget);
    expect(find.textContaining('نطاق مشاركة التكلفة العادل لهذا المسار'), findsOneWidget);

    // Tap +20 chip and verify input is updated to 55
    await tester.tap(find.text('+20 ر.ق'));
    await tester.pumpAndSettle();
    expect(find.text('55'), findsOneWidget);
  });

  testWidgets('CitySearchModal displays Qatari landmark chips', (tester) async {
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

    // Verify smart Qatari landmark chips exist
    expect(find.text('محطة وقود وقود (WOQOD)'), findsOneWidget);
    expect(find.text('محطة مترو الدوحة (الريل)'), findsOneWidget);
    expect(find.text('مطار حمد الدولي'), findsOneWidget);
    expect(find.text('بوابة المدينة التعليمية'), findsOneWidget);
    expect(find.text('شارع 10 · الصناعية'), findsOneWidget);
  });

  testWidgets('ParcelTrackingScreen displays live recipient share card', (tester) async {
    const parcel = ParcelModel(
      id: '4821',
      driverName: 'جاسم الكواري',
      route: 'الدوحة ← الخور',
      description: 'أوراق هامة',
      size: ParcelSize.medium,
      weightKg: 1.5,
      estimatedValue: 200,
      receiverName: 'نورة الكواري',
      receiverPhone: '66123456',
      fee: 35,
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
