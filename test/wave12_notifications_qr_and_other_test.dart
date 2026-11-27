import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mashwar/core/widgets/mashwar_handover_qr_panel.dart';
import 'package:mashwar/core/widgets/mashwar_worksite_icons.dart';
import 'package:mashwar/data/demo/demo_cases_catalog.dart';
import 'package:mashwar/data/models/parcel_model.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/screens/account/account_extra_screens.dart';
import 'package:mashwar/screens/board/post_ad_screen.dart';
import 'package:mashwar/screens/driver/publish_ride_screen.dart';
import 'package:mashwar/screens/parcel/parcel_tracking_screen.dart';
import 'package:mashwar/screens/parcel/pickup_code_dialog.dart';
import 'package:mashwar/screens/parcel/send_parcel_screen.dart';
import 'package:mashwar/screens/worksite/create_work_request_screen.dart';
import 'package:mashwar/screens/worksite/provider_profile_screen.dart';
import 'package:mashwar/screens/worksite/work_request_details_screen.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

Widget _wrapWithProviders(
  Widget child, {
  WorksiteProvider? worksite,
  BoardProvider? board,
  RidesProvider? rides,
  ParcelsProvider? parcels,
  AuthProvider? auth,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => auth ?? AuthProvider(),
      ),
      ChangeNotifierProvider<RidesProvider>(
        create: (_) => rides ?? RidesProvider(),
      ),
      ChangeNotifierProvider<BoardProvider>(
        create: (_) => board ?? BoardProvider(),
      ),
      ChangeNotifierProvider<ParcelsProvider>(
        create: (_) => parcels ?? ParcelsProvider(),
      ),
      ChangeNotifierProvider<WorksiteProvider>(
        create: (_) => worksite ?? WorksiteProvider(),
      ),
    ],
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets(
    '1. NotificationsCenterScreen marks an individual unread notification as read WITHOUT opening it',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final worksite = WorksiteProvider();
      await worksite.activateDemoShowcase();

      final initialUnread = worksite.unreadNotificationsCount;
      expect(initialUnread, greaterThanOrEqualTo(2));
      final firstUnread = worksite.notifications.firstWhere((n) => !n.isRead);

      await tester.pumpWidget(
        _wrapWithProviders(
          const NotificationsCenterScreen(),
          worksite: worksite,
        ),
      );
      await tester.pumpAndSettle();

      final markBtn = find.byKey(ValueKey('notif_mark_read_${firstUnread.id}'));
      expect(markBtn, findsOneWidget);

      await tester.tap(markBtn);
      await tester.pumpAndSettle();

      // Must decrement unread count & mark read WITHOUT navigating away!
      expect(worksite.unreadNotificationsCount, equals(initialUnread - 1));
      expect(
        worksite.notifications.firstWhere((n) => n.id == firstUnread.id).isRead,
        isTrue,
      );
      expect(find.byType(NotificationsCenterScreen), findsOneWidget);
      expect(find.byType(WorkRequestDetailsScreen), findsNothing);
      expect(
        find.byKey(ValueKey('notif_read_badge_${firstUnread.id}')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '2. Handover QR code renders alongside OTP/6-char code and dead-battery & broken-camera fallbacks work',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleParcel = ParcelModel(
        id: 'pcl_w12_1',
        driverName: 'سالم الدوسري',
        fromCity: 'الدوحة',
        toCity: 'لوسيل',
        route: 'الدوحة ← لوسيل',
        description: 'مستندات هندسية مختومة',
        size: ParcelSize.envelope,
        weightKg: 0.5,
        estimatedValue: 300,
        receiverName: 'م. حمد الكواري',
        receiverPhone: '+974 55112233',
        pickupOtp: '4 8 2 9',
        deliveryOtp: '7 3 1 5',
        fee: 30,
        status: ParcelStatusStep.accepted,
      );

      await tester.pumpWidget(
        _wrapWithProviders(PickupCodeDialog(parcel: sampleParcel)),
      );
      await tester.pumpAndSettle();

      // QR renders alongside 4-digit OTP
      expect(
        find.byKey(const ValueKey('pickup_dialog_qr_code')),
        findsOneWidget,
      );
      expect(find.byType(MashwarQrMatrixWidget), findsOneWidget);

      // Open real-world contingency fallback sheet
      final fallbackBtn =
          find.byKey(const ValueKey('pickup_dialog_contingency_btn'));
      await tester.ensureVisible(fallbackBtn);
      await tester.tap(fallbackBtn);
      await tester.pumpAndSettle();

      // Verify broken camera + dead battery + offline solutions exist
      expect(find.textContaining('الكاميرا معطّلة'), findsOneWidget);
      expect(find.textContaining('بطارية الموبايل فصلت'), findsOneWidget);
      expect(find.textContaining('انقطاع الإنترنت'), findsOneWidget);

      // Activate Dead-Battery Emergency Handover form and submit
      final deadBatteryBtn =
          find.byKey(const ValueKey('emergency_dead_battery_btn'));
      await tester.ensureVisible(deadBatteryBtn);
      await tester.tap(deadBatteryBtn);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('emergency_backup_name_input')),
        'م. خالد المنصوري',
      );
      await tester.enterText(
        find.byKey(const ValueKey('emergency_backup_phone_input')),
        '+974 55443322',
      );
      await tester.enterText(
        find.byKey(const ValueKey('emergency_qid_last4_input')),
        '9841',
      );

      final submitEmergencyBtn =
          find.byKey(const ValueKey('emergency_submit_fallback_btn'));
      await tester.ensureVisible(submitEmergencyBtn);
      await tester.tap(submitEmergencyBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('emergency_fallback_confirmed_card')),
        findsOneWidget,
      );
      expect(find.textContaining('EMG-'), findsOneWidget);

      // Verify ParcelTrackingScreen renders both Pickup & Delivery QR codes
      await tester.pumpWidget(
        _wrapWithProviders(ParcelTrackingScreen(parcel: sampleParcel)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('parcel_pickup_qr_code')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('parcel_delivery_qr_code')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('parcel_handover_contingency_btn')),
        findsOneWidget,
      );

      // Verify WorkRequestDetailsScreen renders QR alongside 6-char code
      final worksite = WorksiteProvider(
        initialUserId: MashwarDemoCasesCatalog.defaultOwnerUid,
        initialUserName: MashwarDemoCasesCatalog.defaultOwnerName,
      );
      await worksite.activateDemoShowcase();
      final handoverReq = worksite.requests.firstWhere(
        (r) => r.id == 'demo_wr_06_accepted',
      );
      final requesterAuth = AuthProvider.forTesting(
        user: UserModel(
          id: handoverReq.requesterId,
          fullName: handoverReq.requesterName,
          phone: '55112233',
          gender: UserGender.male,
          governorate: 'الدوحة',
        ),
      );
      await worksite.selectAndLoadRequest(handoverReq.id);
      await tester.pumpWidget(
        _wrapWithProviders(
          WorkRequestDetailsScreen(requestId: handoverReq.id),
          worksite: worksite,
          auth: requesterAuth,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('requester_handover_code_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('requester_handover_qr_code')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('requester_handover_code_value')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('requester_handover_contingency_btn')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '3. Universal "Other" custom options reveal custom fields across CreateWorkRequest, SendParcel, PublishRide, PostAd, and ProviderProfile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 3A. Canonical catalog includes `other`
      expect(
        mashwarWorksiteCategories.any((c) => c.id == 'other'),
        isTrue,
      );

      // 3B. CreateWorkRequestScreen -> Category Other reveals custom input
      await tester.pumpWidget(
        _wrapWithProviders(const CreateWorkRequestScreen()),
      );
      await tester.pumpAndSettle();

      final catOther = find.byKey(const ValueKey('create_category_other'));
      await tester.ensureVisible(catOther);
      await tester.tap(catOther);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_custom_category_input')),
        findsOneWidget,
      );

      // 3C. SendParcelScreen -> Step 2 Custom Size ("Other") + Custom Contents
      await tester.pumpWidget(
        _wrapWithProviders(const SendParcelScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('send_parcel_next_1')));
      await tester.pumpAndSettle();

      final sizeOther = find.byKey(const ValueKey('parcel_size_other'));
      await tester.ensureVisible(sizeOther);
      await tester.tap(sizeOther);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('parcel_custom_size_input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('parcel_content_other')),
        findsOneWidget,
      );

      // 3D. PublishRideScreen -> Step 1 Flex Other + Step 2 Parcel Size Other
      await tester.pumpWidget(
        _wrapWithProviders(const PublishRideScreen()),
      );
      await tester.pumpAndSettle();
      final flexOther = find.byKey(const ValueKey('publish_flex_other'));
      await tester.ensureVisible(flexOther);
      await tester.tap(flexOther);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('publish_custom_flex_input')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('publish_trip_next_1')));
      await tester.pumpAndSettle();
      final parcelOther =
          find.byKey(const ValueKey('publish_parcel_size_other'));
      await tester.ensureVisible(parcelOther);
      await tester.tap(parcelOther);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('publish_custom_parcel_size_input')),
        findsOneWidget,
      );

      // 3E. PostAdScreen -> Category Other reveals custom service input & posts cleanly
      final board = BoardProvider();
      final beforeCount = board.allAds.length;
      await tester.pumpWidget(
        _wrapWithProviders(const PostAdScreen(), board: board),
      );
      await tester.pumpAndSettle();
      final adOther = find.byKey(const ValueKey('post_ad_category_other'));
      await tester.ensureVisible(adOther);
      await tester.tap(adOther);
      await tester.pumpAndSettle();
      final customSrvField =
          find.byKey(const ValueKey('post_ad_custom_service_input'));
      expect(customSrvField, findsOneWidget);
      await tester.enterText(customSrvField, 'توصيل هدايا ومناسبات خاصة');

      final publishBtn = find.text('نشر الطلب أو العرض الآن');
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();
      expect(board.allAds.length, equals(beforeCount + 1));
      expect(
        board.allAds.first.serviceSubTagAr,
        equals('توصيل هدايا ومناسبات خاصة'),
      );

      // 3F. ProviderProfileScreen -> Custom Service Area ("Other")
      await tester.pumpWidget(
        _wrapWithProviders(const ProviderProfileScreen()),
      );
      await tester.pumpAndSettle();
      final areaOtherBtn = find.byKey(const ValueKey('provider_area_other_btn'));
      await tester.ensureVisible(areaOtherBtn);
      await tester.tap(areaOtherBtn);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('provider_custom_area_input')),
        'ميناء حمد',
      );
      await tester.tap(
        find.byKey(const ValueKey('provider_add_custom_area_btn')),
      );
      await tester.pumpAndSettle();
      expect(find.text('ميناء حمد'), findsOneWidget);
    },
  );
}
