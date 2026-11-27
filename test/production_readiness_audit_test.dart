import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mashwar/core/config/app_environment.dart';
import 'package:mashwar/data/models/board_ad_model.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/data/repositories/app_repositories.dart';
import 'package:mashwar/data/repositories/contracts/i_auth_repository.dart';
import 'package:mashwar/data/repositories/implementations/provider_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/worksite_repository_impl.dart';
import 'package:mashwar/screens/account/account_extra_screens.dart';
import 'package:mashwar/screens/auth/profile_setup_screen.dart';
import 'package:mashwar/screens/home/home_screen.dart';
import 'package:mashwar/screens/permissions/location_permission_screen.dart';
import 'package:mashwar/screens/settings/settings_screen.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

class _InMemoryMultiAccountAuthRepo implements IAuthRepository {
  final Map<String, UserModel> _usersByEmail;
  UserModel? _current;

  _InMemoryMultiAccountAuthRepo(List<UserModel> seedUsers)
      : _usersByEmail = {
          for (final u in seedUsers)
            if (u.email != null) u.email!.toLowerCase(): u,
        };

  @override
  bool get isPhoneOtpSupported => false;

  @override
  Future<bool> sendPhoneOtp(String phone) async => false;

  @override
  Future<UserModel> verifyPhoneOtp(String phone, String code) async {
    throw UnsupportedError('Phone OTP disabled in stub');
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    final user = _usersByEmail[email.trim().toLowerCase()];
    if (user == null) {
      throw const AuthException(
        code: 'user-not-found',
        messageAr: 'غير موجود',
        messageEn: 'Not found',
      );
    }
    _current = user;
    return user;
  }

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final user = UserModel(
      id: 'uid_${email.hashCode.abs()}',
      fullName: fullName ?? '',
      phone: phone ?? '',
      gender: UserGender.preferNotToSay,
      email: email.trim(),
    );
    _usersByEmail[email.trim().toLowerCase()] = user;
    _current = user;
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<bool> isSignedIn() async => _current != null;

  @override
  Future<String?> currentUid() async => _current?.id;

  @override
  Future<UserModel?> getCurrentUser() async => _current;

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    _current = user;
    if (user.email != null) {
      _usersByEmail[user.email!.toLowerCase()] = user;
    }
    return user;
  }

  @override
  Future<bool> submitNationalId({
    required String nationalId,
    required String idFrontImage,
    required String idBackImage,
    required String selfieImage,
  }) async =>
      true;

  @override
  Future<void> deleteAccount({String? reason}) async {
    _current = null;
  }

  @override
  Future<void> signOut() async {
    _current = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Production Clean-State Invariants (Firebase Runtime Active)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      AppEnvironment.setFirebaseRuntimeActive(true);
      AppRepositories.instance.useLocalMocks(
        allowDevMocks: false,
        seedSampleData: false,
      );
    });

    tearDown(() {
      AppEnvironment.setFirebaseRuntimeActive(false);
      AppRepositories.instance.useLocalMocks();
    });

    test(
      'WorksiteProvider starts with 0 notifications/unread and does NOT auto-hydrate demo catalog',
      () async {
        final providerRepo = ProviderRepositoryImpl(
          allowDevMocks: false,
          seedSampleData: false,
        );
        final worksiteRepo = WorksiteRepositoryImpl(
          providerRepository: providerRepo,
          allowDevMocks: false,
          seedSampleData: false,
        );
        final ws = WorksiteProvider(
          worksiteRepository: worksiteRepo,
          providerRepository: providerRepo,
        );
        addTearDown(ws.dispose);

        expect(ws.notifications, isEmpty);
        expect(ws.unreadNotificationsCount, 0);
        expect(ws.allLoadedRequests, isEmpty);
        expect(ws.savedWorksites, isEmpty);

        ws.syncAuthSession(uid: 'live_new_user_01', fullName: 'سالم القحطاني');
        await ws.loadRequests();
        await ws.loadNotifications();
        await ws.loadSavedWorksites('live_new_user_01');

        expect(ws.notifications, isEmpty);
        expect(ws.unreadNotificationsCount, 0);
        expect(
          ws.allLoadedRequests.where((r) => r.id.startsWith('demo_wr_')),
          isEmpty,
        );
        expect(ws.allLoadedRequests, isEmpty);
        expect(ws.savedWorksites, isEmpty);

        // Also confirm default-constructed WorksiteProvider (no injected repos)
        // never auto-hydrates MashwarDemoCasesCatalog while Firebase runtime is active.
        final defaultWs = WorksiteProvider();
        addTearDown(defaultWs.dispose);
        defaultWs.syncAuthSession(
          uid: 'live_new_user_02',
          fullName: 'سالم القحطاني',
        );
        await defaultWs.loadRequests();
        await defaultWs.loadNotifications();
        expect(defaultWs.notifications, isEmpty);
        expect(defaultWs.unreadNotificationsCount, 0);
        expect(
          defaultWs.allLoadedRequests.where((r) => r.id.startsWith('demo_wr_')),
          isEmpty,
        );
        expect(defaultWs.savedWorksites, isEmpty);
      },
    );

    test(
      'RidesProvider starts empty in live mode and clears cleanly on syncAuthSession(uid: null)',
      () {
        final rides = RidesProvider();
        addTearDown(rides.dispose);

        expect(rides.allRides, isEmpty);
        expect(rides.bookedRides, isEmpty);
        expect(rides.myPublishedRides, isEmpty);
        expect(rides.activeBooking, isNull);

        rides.syncAuthSession(uid: 'live_driver_a');
        final published = rides.publishRide(
          driverId: 'live_driver_a',
          driverName: 'سالم القحطاني',
          driverCar: 'لاندكروزر 2025',
          driverPhone: '55998877',
          fromCity: 'الدوحة',
          toCity: 'لوسيل',
          departureTime: '08:00 ص',
          departureDate: 'اليوم',
          availableSeats: 3,
          pricePerSeat: 25,
        );
        rides.bookRide(published);
        expect(rides.myPublishedRides.length, 1);
        expect(rides.bookedRides.length, 1);
        expect(rides.activeBooking, isNotNull);

        rides.syncAuthSession(uid: null);
        expect(rides.myPublishedRides, isEmpty);
        expect(rides.bookedRides, isEmpty);
        expect(rides.activeBooking, isNull);
        expect(rides.rideRatings, isEmpty);
      },
    );

    test(
      'ParcelsProvider, BoardProvider, and AlertsProvider start empty and isolate strictly per uid',
      () async {
        final parcels = ParcelsProvider();
        final board = BoardProvider();
        final alerts = AlertsProvider();
        addTearDown(() {
          parcels.dispose();
          board.dispose();
          alerts.dispose();
        });

        // Clean initial state: 0 fake parcels, 0 fake 'عبدالرحمن المهنا' ads, 0 fake alerts
        expect(parcels.parcels, isEmpty);
        expect(parcels.activeTrackingParcel, isNull);
        expect(board.allAds, isEmpty);
        expect(board.myAds, isEmpty);
        expect(
          board.myAds.where((a) => a.authorName.contains('عبدالرحمن')),
          isEmpty,
        );
        expect(alerts.alerts, isEmpty);
        expect(alerts.activeAlertsCount, 0);

        // User A creates personal records
        parcels.syncAuthSession(uid: 'live_user_a');
        board.syncAuthSession(uid: 'live_user_a');
        alerts.syncAuthSession(uid: 'live_user_a');

        parcels.sendParcel(
          senderId: 'live_user_a',
          senderName: 'أحمد المري',
          fromCity: 'الدوحة',
          toCity: 'الخور',
          description: 'وثائق رسمية',
          receiverName: 'راشد',
          receiverPhone: '55443322',
        );
        final adA = board.postAd(
          type: BoardAdType.rideRequest,
          fromCity: 'الدوحة',
          toCity: 'لوسيل',
          timeText: 'اليوم 5:00 م',
          description: 'طلب مقعد لوسيل',
          priceOrBudget: 30,
          authorId: 'live_user_a',
          authorName: 'أحمد المري',
        );
        expect(adA.isVerified, isFalse);
        expect(adA.tripCount, 0);

        final addedAlert = alerts.addAlert(
          fromCity: 'الدوحة',
          toCity: 'لوسيل',
          dateRange: 'اليوم',
          category: 'رحلة',
        );
        expect(addedAlert, isTrue);
        expect(parcels.parcels.length, 1);
        expect(board.myAds.length, 1);
        expect(alerts.alerts.length, 1);

        // Switch to User B -> complete isolation (0 items from User A)
        parcels.syncAuthSession(uid: 'live_user_b');
        board.syncAuthSession(uid: 'live_user_b');
        alerts.syncAuthSession(uid: 'live_user_b');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(parcels.parcels, isEmpty);
        expect(board.myAds, isEmpty);
        expect(board.allAds, isEmpty);
        expect(alerts.alerts, isEmpty);

        // Sign out -> all remain cleanly empty
        parcels.syncAuthSession(uid: null);
        board.syncAuthSession(uid: null);
        alerts.syncAuthSession(uid: null);
        expect(parcels.parcels, isEmpty);
        expect(board.myAds, isEmpty);
        expect(alerts.alerts, isEmpty);
      },
    );

    test(
      'AuthProvider isolates avatars strictly by uid and resets driver vehicle defaults cleanly',
      () async {
        const userA = UserModel(
          id: 'uid_alpha_1',
          fullName: 'أحمد المري',
          phone: '55110011',
          gender: UserGender.male,
          email: 'alpha@mashwar.qa',
          governorate: 'بلدية الدوحة',
        );
        const userB = UserModel(
          id: 'uid_beta_2',
          fullName: 'سالم القحطاني',
          phone: '55220022',
          gender: UserGender.male,
          email: 'beta@mashwar.qa',
          governorate: 'بلدية الوكرة',
        );
        final stubRepo = _InMemoryMultiAccountAuthRepo([userA, userB]);
        final auth = AuthProvider(authRepository: stubRepo, useDevMockAuth: false);
        addTearDown(auth.dispose);

        // Fresh live driver defaults must be empty (no fake Camry / 482910)
        expect(auth.driverCarModel, isEmpty);
        expect(auth.driverCarColor, isEmpty);
        expect(auth.driverPlateNumbers, isEmpty);
        expect(auth.driverFormattedCar, isEmpty);

        // Sign in User A, set avatar & vehicle
        final okA = await auth.loginWithEmail('alpha@mashwar.qa', 'Pass1234!');
        expect(okA, isTrue);
        await auth.updateAvatar('data:image/png;base64,USER_A_ONLY_AVATAR');
        auth.updateDriverVehicle(
          model: 'تويوتا برادو 2025',
          color: 'أبيض',
          plateNumbers: '991122',
        );
        expect(auth.user.avatarUrl, 'data:image/png;base64,USER_A_ONLY_AVATAR');
        expect(auth.driverCarModel, 'تويوتا برادو 2025');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('mashwar_avatar_active'), isNull);
        expect(
          prefs.getString('mashwar_avatar_uid_uid_alpha_1'),
          'data:image/png;base64,USER_A_ONLY_AVATAR',
        );

        // Logout resets vehicle defaults and clears active user
        await auth.logout();
        expect(auth.driverCarModel, isEmpty);
        expect(auth.driverPlateNumbers, isEmpty);
        expect(auth.user.avatarUrl, isNull);

        // Sign in User B -> MUST NOT inherit User A's cached avatar or vehicle
        final okB = await auth.loginWithEmail('beta@mashwar.qa', 'Pass1234!');
        expect(okB, isTrue);
        expect(auth.user.id, 'uid_beta_2');
        expect(auth.user.avatarUrl, isNull);
        expect(auth.driverCarModel, isEmpty);
        expect(auth.driverPlateNumbers, isEmpty);

        // Sign back into User A -> User A's own avatar restores cleanly
        await auth.logout();
        final okA2 = await auth.loginWithEmail('alpha@mashwar.qa', 'Pass1234!');
        expect(okA2, isTrue);
        expect(auth.user.avatarUrl, 'data:image/png;base64,USER_A_ONLY_AVATAR');
      },
    );
  });

  group('Production Onboarding UX & Hardening UI Invariants', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      AppEnvironment.setFirebaseRuntimeActive(true);
      AppRepositories.instance.useLocalMocks(
        allowDevMocks: false,
        seedSampleData: false,
      );
    });

    tearDown(() {
      AppEnvironment.setFirebaseRuntimeActive(false);
      AppRepositories.instance.useLocalMocks();
    });

    testWidgets(
      'ProfileSetupScreen has zero hardcoded personal defaults, shows welcome banner, and validates/saves profile cleanly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = AuthProvider.forTesting(
          status: AuthStatus.authenticated,
          useDevMockAuth: false,
          user: const UserModel(
            id: 'uid_fresh_qa',
            fullName: 'سالم القحطاني',
            phone: '',
            gender: UserGender.preferNotToSay,
            email: 'prodqa.user@mashwar.qa',
          ),
        );
        final settings = SettingsProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ],
            child: const MaterialApp(
              locale: Locale('ar', 'QA'),
              home: ProfileSetupScreen(isNewRegistration: true),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Zero hardcoded legacy personal defaults
        expect(find.textContaining('عبدالرحمن'), findsNothing);
        expect(find.textContaining('المهنا'), findsNothing);
        expect(find.textContaining('abdelrahman@mashwar.qa'), findsNothing);

        // Welcome banner present and personalized to سالم
        expect(
          find.byKey(const ValueKey('profile_setup_welcome_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('سالم'), findsWidgets);

        // Validation catches invalid Qatar mobile number
        await tester.enterText(
          find.byKey(const ValueKey('profile_setup_phone_input')),
          '12345',
        );
        await tester.tap(find.byKey(const ValueKey('profile_setup_save_btn')));
        await tester.pumpAndSettle();
        expect(find.byType(LocationPermissionScreen), findsNothing);
        expect(
          find.textContaining('الرقم يجب أن يتكون من 8 أرقام'),
          findsOneWidget,
        );

        // Fill valid Qatar mobile + municipality + emergency contact and save
        final phoneField =
            find.byKey(const ValueKey('profile_setup_phone_input'));
        await tester.ensureVisible(phoneField);
        await tester.enterText(phoneField, '55998877');

        final govDropdown =
            find.byKey(const ValueKey('profile_setup_gov_dropdown'));
        await tester.ensureVisible(govDropdown);
        await tester.pumpAndSettle();
        await tester.tap(govDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('بلدية الضعاين (لوسيل)').last);
        await tester.pumpAndSettle();

        final emergencyNameField =
            find.byKey(const ValueKey('profile_setup_emergency_name_input'));
        await tester.ensureVisible(emergencyNameField);
        await tester.pumpAndSettle();
        await tester.enterText(emergencyNameField, 'ناصر القحطاني');

        final emergencyPhoneField =
            find.byKey(const ValueKey('profile_setup_emergency_phone_input'));
        await tester.ensureVisible(emergencyPhoneField);
        await tester.pumpAndSettle();
        await tester.enterText(emergencyPhoneField, '55112233');

        await tester.tap(find.byKey(const ValueKey('profile_setup_save_btn')));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(auth.user.fullName, 'سالم القحطاني');
        expect(auth.user.phone, '55998877');
        expect(auth.user.governorate, 'بلدية الضعاين (لوسيل)');
        expect(auth.user.emergencyContactName, 'ناصر القحطاني');
        expect(auth.user.emergencyContactPhone, '55112233');
        expect(find.byType(LocationPermissionScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'HomeScreen renders home_onboarding_checklist_card for brand-new user and dismisses cleanly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = AuthProvider.forTesting(
          status: AuthStatus.authenticated,
          useDevMockAuth: false,
          user: const UserModel(
            id: 'uid_brand_new_home',
            fullName: 'سالم القحطاني',
            phone: '',
            gender: UserGender.preferNotToSay,
            email: 'salem.home@mashwar.qa',
          ),
        );
        final settings = SettingsProvider();
        final rides = RidesProvider(initialUserId: 'uid_brand_new_home');
        final board = BoardProvider(initialUserId: 'uid_brand_new_home');
        final parcels = ParcelsProvider(initialUserId: 'uid_brand_new_home');
        final worksite = WorksiteProvider(
          initialUserId: 'uid_brand_new_home',
          initialUserName: 'سالم القحطاني',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<SettingsProvider>.value(value: settings),
              ChangeNotifierProvider<RidesProvider>.value(value: rides),
              ChangeNotifierProvider<BoardProvider>.value(value: board),
              ChangeNotifierProvider<ParcelsProvider>.value(value: parcels),
              ChangeNotifierProvider<WorksiteProvider>.value(value: worksite),
            ],
            child: const MaterialApp(
              locale: Locale('ar', 'QA'),
              home: HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final checklistFinder =
            find.byKey(const ValueKey('home_onboarding_checklist_card'));
        expect(checklistFinder, findsOneWidget);

        final dismissBtn =
            find.byKey(const ValueKey('home_onboarding_dismiss_btn'));
        await tester.ensureVisible(dismissBtn);
        await tester.tap(dismissBtn);
        await tester.pumpAndSettle();

        expect(checklistFinder, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'NotificationsCenterScreen renders notifications_empty_welcome_card with 0 fake notifications',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final settings = SettingsProvider();
        final worksite = WorksiteProvider(
          initialUserId: 'uid_clean_notif',
          initialUserName: 'سالم القحطاني',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsProvider>.value(value: settings),
              ChangeNotifierProvider<WorksiteProvider>.value(value: worksite),
            ],
            child: const MaterialApp(
              locale: Locale('ar', 'QA'),
              home: NotificationsCenterScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(worksite.notifications, isEmpty);
        expect(worksite.unreadNotificationsCount, 0);
        expect(
          find.byKey(const ValueKey('notifications_empty_welcome_card')),
          findsOneWidget,
        );
        expect(find.text('الكل (0)'), findsOneWidget);
        expect(find.text('غير مقروءة (0)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SettingsScreen has zero fictional CR 849201 text and displays compliant Qatar regulatory copy',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = AuthProvider.forTesting(
          status: AuthStatus.authenticated,
          useDevMockAuth: false,
          user: const UserModel(
            id: 'uid_settings_clean',
            fullName: 'سالم القحطاني',
            phone: '',
            gender: UserGender.preferNotToSay,
            email: 'salem.settings@mashwar.qa',
          ),
        );
        final settings = SettingsProvider();
        final alerts = AlertsProvider(initialUserId: 'uid_settings_clean');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<SettingsProvider>.value(value: settings),
              ChangeNotifierProvider<AlertsProvider>.value(value: alerts),
            ],
            child: const MaterialApp(
              locale: Locale('ar', 'QA'),
              home: SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('849201'), findsNothing);
        expect(
          find.text('الامتثال التنظيمي وحماية البيانات (قطر)'),
          findsOneWidget,
        );
        expect(find.text('مشوار MASHWAR v2.5.0'), findsOneWidget);
        expect(find.text('salem.settings@mashwar.qa'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
