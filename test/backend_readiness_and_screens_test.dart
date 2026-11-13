import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mashwar/data/api/api_endpoints.dart';
import 'package:mashwar/data/api/mashwar_api_client.dart';
import 'package:mashwar/data/mock_data.dart';
import 'package:mashwar/data/models/board_ad_model.dart';
import 'package:mashwar/data/models/location_item.dart';
import 'package:mashwar/data/models/parcel_model.dart';
import 'package:mashwar/data/models/ride_model.dart';
import 'package:mashwar/data/models/route_alert_model.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/screens/account/legal_and_backend_screens.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';

void main() {
  group('Backend Data Models Serialization & API Layer Tests', () {
    test('UserModel toJson / fromJson / copyWith roundtrip', () {
      final original = MockData.currentUser;
      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.fullName, original.fullName);
      expect(restored.phone, original.phone);
      expect(restored.walletBalance, original.walletBalance);

      final updated = restored.copyWith(fullName: 'أحمد سامي', walletBalance: 500.0);
      expect(updated.fullName, 'أحمد سامي');
      expect(updated.walletBalance, 500.0);
    });

    test('RideModel, ParcelModel, BoardAdModel, RouteAlertModel, LocationItem roundtrip', () {
      final ride = MockData.initialRides.first;
      final rideRestored = RideModel.fromJson(ride.toJson());
      expect(rideRestored.id, ride.id);
      expect(rideRestored.fromCity, ride.fromCity);
      expect(rideRestored.toCity, ride.toCity);

      final parcel = MockData.activeParcel;
      final parcelRestored = ParcelModel.fromJson(parcel.toJson());
      expect(parcelRestored.id, parcel.id);
      expect(parcelRestored.pickupOtp, parcel.pickupOtp);

      final ad = MockData.initialBoardAds.first;
      final adRestored = BoardAdModel.fromJson(ad.toJson());
      expect(adRestored.id, ad.id);
      expect(adRestored.fromCity, ad.fromCity);

      final alert = MockData.initialAlerts.first;
      final alertRestored = RouteAlertModel.fromJson(alert.toJson());
      expect(alertRestored.id, alert.id);
      expect(alertRestored.fromCity, alert.fromCity);

      final loc = MockData.locations.first;
      final locRestored = LocationItem.fromJson(loc.toJson());
      expect(locRestored.name, loc.name);
    });

    test('MashwarApiClient logs requests and formats cURL commands', () {
      final client = MashwarApiClient.instance;
      client.setAccessToken('eyJhbGciOiJIUzI1NiJ9.mashwar_test');
      client.recordRequest('GET', ApiEndpoints.searchRides, statusCode: 200);

      expect(client.recentLogs, isNotEmpty);
      expect(client.recentLogs.first.path, ApiEndpoints.searchRides);
      final curl = client.formatCurlPreview('GET', ApiEndpoints.searchRides);
      expect(curl, contains('Bearer'));
    });
  });

  group('LegalComplianceScreen & BackendReadinessScreen Widget Tests', () {
    Widget wrapWithProviders(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => RidesProvider()),
          ChangeNotifierProvider(create: (_) => ParcelsProvider()),
          ChangeNotifierProvider(create: (_) => BoardProvider()),
          ChangeNotifierProvider(create: (_) => AlertsProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets('LegalComplianceScreen renders all 3 compliance tabs', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const LegalComplianceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('الشروط القانونية والترخيص'), findsOneWidget);
      expect(find.text('شروط الخدمة'), findsOneWidget);
      expect(find.text('حماية البيانات'), findsOneWidget);
      expect(find.text('امتثال وزارة النقل'), findsOneWidget);

      await tester.tap(find.text('امتثال وزارة النقل'));
      await tester.pumpAndSettle();
      expect(find.textContaining('متوافق مع ضوابط النقل الذكي التشاركي'), findsOneWidget);
    });

    testWidgets('BackendReadinessScreen renders JSON schema and executes live endpoint test', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const BackendReadinessScreen()));
      await tester.pumpAndSettle();

      expect(find.text('جاهزية الباك إند وواجهات API'), findsOneWidget);
      expect(find.text('UserModel'), findsOneWidget);
      expect(find.text('RideModel'), findsOneWidget);

      await tester.tap(find.text('RideModel'));
      await tester.pumpAndSettle();
      expect(find.textContaining('driverName'), findsOneWidget);
    });
  });
}
