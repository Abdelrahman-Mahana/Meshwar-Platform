import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/screens/auth/profile_setup_screen.dart';

void main() {
  group('Profile Setup Extended Data Tests (Future-Ready Data Collection)', () {
    late AuthProvider auth;

    setUp(() {
      auth = AuthProvider();
    });

    test('AuthProvider saves and preserves extended future profile fields', () {
      auth.saveProfile(
        fullName: 'أحمد محمود علي',
        gender: UserGender.male,
        governorate: 'كفر الشيخ',
        city: 'دسوق',
        birthDate: '1998/05/14 (28 سنة)',
        email: 'ahmed@mashwar.example',
        emergencyContactName: 'محمود علي (الوالد)',
        emergencyContactPhone: '01012345678',
        occupation: 'مهندس برمجيات',
        smokingPreference: 'غير مدخن',
        tripVibe: 'هادئ ومريح',
        ladiesOnlyPreference: false,
      );

      final user = auth.user;
      expect(user.fullName, 'أحمد محمود علي');
      expect(user.gender, UserGender.male);
      expect(user.governorate, 'كفر الشيخ');
      expect(user.city, 'دسوق');
      expect(user.birthDate, contains('1998/05/14'));
      expect(user.email, 'ahmed@mashwar.example');
      expect(user.emergencyContactName, 'محمود علي (الوالد)');
      expect(user.emergencyContactPhone, '01012345678');
      expect(user.occupation, 'مهندس برمجيات');
      expect(user.smokingPreference, 'غير مدخن');
      expect(user.tripVibe, 'هادئ ومريح');
      expect(user.ladiesOnlyPreference, false);
      expect(auth.status, AuthStatus.authenticated);
    });

    test('Ladies-only preference saves true when selected for female users', () {
      auth.saveProfile(
        fullName: 'سارة إبراهيم حسن',
        gender: UserGender.female,
        governorate: 'القاهرة',
        city: 'المعادي',
        birthDate: '2001/03/10 (25 سنة)',
        ladiesOnlyPreference: true,
      );

      expect(auth.user.gender, UserGender.female);
      expect(auth.user.ladiesOnlyPreference, true);
      expect(auth.user.governorate, 'القاهرة');
      expect(auth.user.city, 'المعادي');
    });

    test('Emergency Egyptian phone number validation', () {
      expect(AuthProvider.validateEgyptianPhone('01012345678'), isNull);
      expect(AuthProvider.validateEgyptianPhone('01123456789'), isNull);
      expect(AuthProvider.validateEgyptianPhone('01234567890'), isNull);
      expect(AuthProvider.validateEgyptianPhone('01555555555'), isNull);

      // Invalid phones
      expect(AuthProvider.validateEgyptianPhone('01312345678'), isNotNull);
      expect(AuthProvider.validateEgyptianPhone('0101234567'), isNotNull); // 10 digits
      expect(AuthProvider.validateEgyptianPhone('010123456789'), isNotNull); // 12 digits
      expect(AuthProvider.validateEgyptianPhone(''), isNotNull);
    });
  });

  group('ProfileSetupScreen UI Rendering & Fields Test (Uber/inDrive Style)', () {
    testWidgets('ProfileSetupScreen mounts with clean, minimalist Uber-style UI', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const MaterialApp(
            home: ProfileSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header
      expect(find.text('ما اسمك؟'), findsOneWidget);

      // Check Clean Fields (First & Last Name, Email, Governorate)
      expect(find.text('الاسم الأول'), findsOneWidget);
      expect(find.text('اسم العائلة'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('المحافظة'), findsOneWidget);

      // Check Clean Gender Pills without emojis
      expect(find.text('رجل'), findsOneWidget);
      expect(find.text('سيدة'), findsOneWidget);

      // Check Continue Button (Uber style)
      expect(find.text('متابعة'), findsOneWidget);

      // Verify no exceptions thrown
      expect(tester.takeException(), isNull);
    });
  });
}
