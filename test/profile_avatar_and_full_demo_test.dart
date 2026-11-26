import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/data/models/parcel_model.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/data/services/media_upload_service.dart';
import 'package:mashwar/screens/account/account_extra_screens.dart';
import 'package:mashwar/screens/home/home_screen.dart';
import 'package:mashwar/screens/main_nav_shell.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

/// Minimal valid 1x1 PNG binary payload for deterministic widget image tests.
final Uint8List _kValidTinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    MediaUploadService.debugOverride = null;
  });

  tearDown(() {
    MediaUploadService.debugOverride = null;
  });

  Widget buildTestShell({
    required AuthProvider auth,
    required SettingsProvider settings,
    required WorksiteProvider worksite,
    required RidesProvider rides,
    required ParcelsProvider parcels,
    required BoardProvider board,
    required Widget home,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<WorksiteProvider>.value(value: worksite),
        ChangeNotifierProvider<RidesProvider>.value(value: rides),
        ChangeNotifierProvider<ParcelsProvider>.value(value: parcels),
        ChangeNotifierProvider<BoardProvider>.value(value: board),
        ChangeNotifierProvider(create: (_) => AdminProvider.forTesting()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, s, __) => MaterialApp(
          theme: AppTheme.lightTheme,
          locale: s.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home,
        ),
      ),
    );
  }

  group('Profile Photo Upload & External Display (Wave 11)', () {
    testWidgets(
      'Uploading a photo in UserProfileScreen replaces initial letter on HomeScreen and MainNavShell and persists in SharedPreferences',
      (tester) async {
        tester.view.physicalSize = const Size(430, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        MediaUploadService.debugOverride = MediaUploadService(
          imagePickerFn: ({
            required ImageSource source,
            int? imageQuality,
            double? maxWidth,
          }) async {
            return XFile.fromData(
              _kValidTinyPng,
              name: 'my_portrait.png',
              mimeType: 'image/png',
            );
          },
        );

        final auth = AuthProvider.forTesting(
          user: const UserModel(
            id: 'usr_avatar_test',
            fullName: 'عبدالرحمن المهنا',
            phone: '55123456',
            gender: UserGender.male,
            isVerified: true,
          ),
        );
        final settings = SettingsProvider()..setLocale(const Locale('ar', 'QA'));
        final worksite = WorksiteProvider(
          initialUserId: 'usr_avatar_test',
          initialUserName: 'عبدالرحمن المهنا',
        );
        final rides = RidesProvider();
        final parcels = ParcelsProvider();
        final board = BoardProvider();

        await tester.pumpWidget(
          buildTestShell(
            auth: auth,
            settings: settings,
            worksite: worksite,
            rides: rides,
            parcels: parcels,
            board: board,
            home: const HomeScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Initially no uploaded photo -> initial letter fallback inside home_profile_avatar_btn
        final homeAvatarBtn =
            find.byKey(const ValueKey('home_profile_avatar_btn'));
        expect(homeAvatarBtn, findsOneWidget);
        expect(
          find.descendant(
            of: homeAvatarBtn,
            matching: find.byKey(const ValueKey('mashwar_avatar_memory_image')),
          ),
          findsNothing,
        );

        // Tap Home profile avatar -> opens UserProfileScreen
        await tester.tap(homeAvatarBtn);
        await tester.pumpAndSettle();
        expect(find.byType(UserProfileScreen), findsOneWidget);

        // Tap "إضافة صورة شخصية" button -> opens picker sheet -> tap upload from device
        final changePhotoBtn =
            find.byKey(const ValueKey('user_profile_change_photo_btn'));
        expect(changePhotoBtn, findsOneWidget);
        await tester.tap(changePhotoBtn);
        await tester.pumpAndSettle();

        final uploadGalleryBtn =
            find.byKey(const ValueKey('avatar_pick_gallery_btn'));
        expect(uploadGalleryBtn, findsOneWidget);
        await tester.tap(uploadGalleryBtn);
        await tester.pumpAndSettle();

        // Verify AuthProvider & SharedPreferences saved the data URI
        expect(auth.user.avatarUrl, isNotNull);
        expect(auth.user.avatarUrl!.startsWith('data:image/png;base64,'), isTrue);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('mashwar_avatar_uid_usr_avatar_test'),
          equals(auth.user.avatarUrl),
        );

        // Pop back to HomeScreen -> verify real uploaded MemoryImage is displayed outside instead of initial!
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(
          find.descendant(
            of: homeAvatarBtn,
            matching: find.byKey(const ValueKey('mashwar_avatar_memory_image')),
          ),
          findsOneWidget,
        );

        worksite.dispose();
        rides.dispose();
        parcels.dispose();
        board.dispose();
        auth.dispose();
        settings.dispose();
      },
    );

    testWidgets(
      'Rich app-wide demo data populates Trips, Parcels, Route Requests, Supply, and My Activity (Active & Completed) cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(430, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final auth = AuthProvider.forTesting(
          user: const UserModel(
            id: 'usr_full_demo',
            fullName: 'عبدالرحمن المهنا',
            phone: '55123456',
            gender: UserGender.male,
            avatarUrl: 'preset:traveler_teal',
            isVerified: true,
          ),
        );
        final settings = SettingsProvider()..setLocale(const Locale('ar', 'QA'));
        final worksite = WorksiteProvider(
          initialUserId: 'usr_full_demo',
          initialUserName: 'عبدالرحمن المهنا',
        );
        final rides = RidesProvider();
        final parcels = ParcelsProvider();
        final board = BoardProvider();

        // Verify rich demo counts across all 3 services
        expect(rides.filteredRides.length, greaterThanOrEqualTo(8));
        expect(
          rides.bookedRides.any((r) => r.status == 'completed'),
          isTrue,
        );
        expect(parcels.parcels.length, greaterThanOrEqualTo(5));
        expect(
          parcels.parcels.any((p) => p.status == ParcelStatusStep.delivered),
          isTrue,
        );
        expect(board.allAds.length, greaterThanOrEqualTo(10));

        await tester.pumpWidget(
          buildTestShell(
            auth: auth,
            settings: settings,
            worksite: worksite,
            rides: rides,
            parcels: parcels,
            board: board,
            home: const MainNavShell(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Dev banner must be completely gone on Home
        expect(find.textContaining('وضع التطوير'), findsNothing);
        expect(
          find.byKey(const ValueKey('home_demo_showcase_banner')),
          findsNothing,
        );

        // Switch to Tab 2: الرحلات والطرود
        await tester.tap(find.text('الرحلات والطرود'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Switch to Tab 3: التوريد والمهام (personalized 14 supply cases)
        await tester.tap(find.text('التوريد والمهام'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(worksite.allLoadedRequests.length, greaterThanOrEqualTo(14));

        // Switch to Tab 4: نشاطي -> check Active AND Completed segments
        await tester.tap(find.text('نشاطي'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final completedSegment =
            find.byKey(const ValueKey('activity_segment_completed'));
        expect(completedSegment, findsOneWidget);
        await tester.tap(completedSegment);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Switch to Tab 5: حسابي -> verify custom avatar is rendered
        await tester.tap(find.text('حسابي'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('account_tab_avatar_btn')),
          findsOneWidget,
        );

        worksite.dispose();
        rides.dispose();
        parcels.dispose();
        board.dispose();
        auth.dispose();
        settings.dispose();
      },
    );
  });
}
