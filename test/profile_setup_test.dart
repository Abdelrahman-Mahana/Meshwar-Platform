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
        fullName: 'حمد ناصر الكواري',
        gender: UserGender.male,
        governorate: 'بلدية الدوحة',
        city: 'مشيرب',
        birthDate: '1998/05/14 (28 سنة)',
        email: 'hamad@mashwar.qa',
        emergencyContactName: 'ناصر الكواري (الوالد)',
        emergencyContactPhone: '55123456',
        occupation: 'مهندس برمجيات',
        smokingPreference: 'غير مدخن',
        tripVibe: 'هادئ ومريح',
        ladiesOnlyPreference: false,
      );

      final user = auth.user;
      expect(user.fullName, 'حمد ناصر الكواري');
      expect(user.gender, UserGender.male);
      expect(user.governorate, 'بلدية الدوحة');
      expect(user.city, 'مشيرب');
      expect(user.birthDate, contains('1998/05/14'));
      expect(user.email, 'hamad@mashwar.qa');
      expect(user.emergencyContactName, 'ناصر الكواري (الوالد)');
      expect(user.emergencyContactPhone, '55123456');
      expect(user.occupation, 'مهندس برمجيات');
      expect(user.smokingPreference, 'غير مدخن');
      expect(user.tripVibe, 'هادئ ومريح');
      expect(user.ladiesOnlyPreference, false);
      expect(auth.status, AuthStatus.authenticated);
    });

    test('Ladies-only preference saves true when selected for female users', () {
      auth.saveProfile(
        fullName: 'نورة علي المهندي',
        gender: UserGender.female,
        governorate: 'بلدية الوكرة',
        city: 'الوكرة',
        birthDate: '2001/03/10 (25 سنة)',
        ladiesOnlyPreference: true,
      );

      expect(auth.user.gender, UserGender.female);
      expect(auth.user.ladiesOnlyPreference, true);
      expect(auth.user.governorate, 'بلدية الوكرة');
      expect(auth.user.city, 'الوكرة');
    });

    test('Emergency Qatar phone number validation', () {
      expect(AuthProvider.validateQatarPhone('33123456'), isNull);
      expect(AuthProvider.validateQatarPhone('55123456'), isNull);
      expect(AuthProvider.validateQatarPhone('66123456'), isNull);
      expect(AuthProvider.validateQatarPhone('77123456'), isNull);

      // Invalid phones
      expect(AuthProvider.validateQatarPhone('44123456'), isNotNull);
      expect(AuthProvider.validateQatarPhone('5512345'), isNotNull); // 7 digits
      expect(AuthProvider.validateQatarPhone('551234567'), isNotNull); // 9 digits
      expect(AuthProvider.validateQatarPhone(''), isNotNull);
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

      // Check Clean Fields (First & Last Name, Email, Municipality)
      expect(find.text('الاسم الأول'), findsOneWidget);
      expect(find.text('اسم العائلة'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('البلدية / المنطقة'), findsOneWidget);

      // Check Clean Gender Pills without emojis
      expect(find.text('ذكر'), findsOneWidget);
      expect(find.text('أنثى'), findsOneWidget);

      // Check Continue Button (Uber style)
      expect(find.text('متابعة'), findsOneWidget);

      // Verify no exceptions thrown
      expect(tester.takeException(), isNull);
    });
  });
}
