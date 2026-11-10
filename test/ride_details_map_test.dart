import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mashwar/data/models/ride_model.dart';
import 'package:mashwar/screens/ride_details/ride_details_screen.dart';
import 'package:mashwar/screens/ride_details/widgets/ride_route_map_view.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';

void main() {
  const testRide = RideModel(
    id: 'test_ride_01',
    driverName: 'محمد سعيد',
    driverCar: 'هيونداي إلنترا، أبيض',
    driverPhone: '0100 123 4567',
    fromCity: 'كفر الشيخ',
    toCity: 'القاهرة',
    pickupPoint: 'محطة وقود، مدخل كفر الشيخ',
    dropoffPoint: 'محطة المترو، القاهرة',
    departureTime: '7:30 ص',
    departureDate: 'الجمعة 6 نوفمبر',
    remainingSeats: 3,
    pricePerSeat: 65,
    acceptsParcels: true,
    parcelPrice: 40,
  );

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RidesProvider()),
      ],
      child: const MaterialApp(
        home: RideDetailsScreen(ride: testRide),
      ),
    );
  }

  testWidgets('RideDetailsScreen displays RideRouteMapView with Passenger and Driver perspectives', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify RideRouteMapView is present
    expect(find.byType(RideRouteMapView), findsOneWidget);

    // Verify Passenger View and Driver View tabs exist
    expect(find.text('منظور الراكب'), findsOneWidget);
    expect(find.text('منظور السائق'), findsOneWidget);

    // Initial state is Passenger perspective
    expect(find.text('إرشادات الراكب للوصول لمكان التجمع'), findsOneWidget);
    expect(find.textContaining('محطة وقود، مدخل كفر الشيخ'), findsWidgets);

    // Switch to Driver perspective
    await tester.tap(find.text('منظور السائق'));
    await tester.pumpAndSettle();

    // Verify Driver guidance card is displayed
    expect(find.text('إرشادات القيادة ومسار السائق'), findsOneWidget);
    expect(find.textContaining('الطريق الزراعي السريع'), findsWidgets);

    // Toggle back to Passenger perspective
    await tester.tap(find.text('منظور الراكب'));
    await tester.pumpAndSettle();
    expect(find.text('إرشادات الراكب للوصول لمكان التجمع'), findsOneWidget);
  });

  testWidgets('RideRouteMapView milestone details expand and collapse', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap "عرض التفاصيل" button to expand waypoints
    final detailsBtn = find.text('عرض التفاصيل');
    expect(detailsBtn, findsOneWidget);
    await tester.ensureVisible(detailsBtn);
    await tester.tap(detailsBtn);
    await tester.pumpAndSettle();

    // Verify intermediate highway milestones are now shown
    expect(find.text('محور العبور / الطريق الزراعي السريع'), findsOneWidget);
    expect(find.text('مدخل العاصمة والمحور الإقليمي'), findsOneWidget);

    // Tap "طي" to collapse
    final collapseBtn = find.text('طي');
    expect(collapseBtn, findsOneWidget);
    await tester.ensureVisible(collapseBtn);
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();

    // Verify collapsed
    expect(find.text('محور العبور / الطريق الزراعي السريع'), findsNothing);
  });

  testWidgets('Fullscreen route map modal opens, allows zooming, and closes cleanly', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find and tap the full-screen expand button
    final expandBtn = find.byIcon(Icons.fullscreen_rounded);
    expect(expandBtn, findsOneWidget);
    await tester.ensureVisible(expandBtn);
    await tester.tap(expandBtn);
    await tester.pumpAndSettle();

    // Verify fullscreen modal title & InteractiveViewer
    expect(find.text('الخريطة الكاملة للمسار'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('فتح الملاحة'), findsOneWidget);

    // Close the modal
    final closeBtn = find.byIcon(Icons.close_rounded);
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    // Back to ride details screen
    expect(find.byType(RideRouteMapView), findsOneWidget);
  });
}
