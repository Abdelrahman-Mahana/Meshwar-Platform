import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/core/theme/app_theme.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/data/models/worksite_models.dart';
import 'package:mashwar/data/repositories/implementations/firebase/firebase_auth_repository.dart';
import 'package:mashwar/data/repositories/implementations/provider_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/worksite_repository_impl.dart';
import 'package:mashwar/data/services/firebase_firestore_service.dart';
import 'package:mashwar/data/services/media_upload_service.dart';
import 'package:mashwar/screens/account/account_extra_screens.dart';
import 'package:mashwar/screens/admin/admin_inquiries_screen.dart';
import 'package:mashwar/screens/auth/email_input_screen.dart';
import 'package:mashwar/screens/auth/id_verification_screen.dart';
import 'package:mashwar/screens/auth/otp_verification_screen.dart';
import 'package:mashwar/screens/auth/phone_input_screen.dart';
import 'package:mashwar/screens/auth/welcome_screen.dart';
import 'package:mashwar/screens/safety/safety_screens.dart';
import 'package:mashwar/screens/worksite/create_work_request_screen.dart';
import 'package:mashwar/screens/worksite/provider_profile_screen.dart';
import 'package:mashwar/screens/worksite/work_request_details_screen.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/alerts_provider.dart';
import 'package:mashwar/state/auth_provider.dart';
import 'package:mashwar/state/board_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';
import 'package:mashwar/state/rides_provider.dart';
import 'package:mashwar/state/settings_provider.dart';
import 'package:mashwar/state/worksite_provider.dart';

// -----------------------------------------------------------------------------
// Fakes for Firebase Phone Auth (Web & Mobile), Firestore UserStore & Storage
// -----------------------------------------------------------------------------

class _FakePhoneUser implements fb_auth.User {
  @override
  final String uid;
  @override
  final String? phoneNumber;
  @override
  final String? email;
  @override
  String? get displayName => null;

  _FakePhoneUser({
    required this.uid,
    this.phoneNumber,
    this.email,
  });

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'token_for_$uid';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePhoneUserCredential implements fb_auth.UserCredential {
  @override
  final fb_auth.User? user;

  _FakePhoneUserCredential(this.user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePhoneAuthCredential implements fb_auth.PhoneAuthCredential {
  final String verificationId;
  @override
  final String smsCode;

  _FakePhoneAuthCredential({
    required this.verificationId,
    required this.smsCode,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConfirmationResult implements fb_auth.ConfirmationResult {
  final String phoneE164;
  final String expectedCode;
  final void Function(_FakePhoneUser user) onConfirmed;

  @override
  final String verificationId;

  _FakeConfirmationResult({
    required this.phoneE164,
    required this.expectedCode,
    required this.verificationId,
    required this.onConfirmed,
  });

  @override
  Future<fb_auth.UserCredential> confirm(String verificationCode) async {
    if (verificationCode != expectedCode) {
      throw fb_auth.FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'The SMS verification code used is invalid.',
      );
    }
    final user = _FakePhoneUser(
      uid: 'web_phone_${phoneE164.replaceAll('+', '')}',
      phoneNumber: phoneE164,
    );
    onConfirmed(user);
    return _FakePhoneUserCredential(user);
  }
}

class _FakePhoneFirebaseAuth implements fb_auth.FirebaseAuth {
  fb_auth.User? _currentUser;
  String expectedOtpCode;
  fb_auth.FirebaseAuthException? errorToThrowOnSend;
  final List<String> sentPhoneNumbersE164 = [];
  int signOutCount = 0;

  _FakePhoneFirebaseAuth({
    this.expectedOtpCode = '654321',
    fb_auth.User? initialUser,
  }) : _currentUser = initialUser;

  @override
  fb_auth.User? get currentUser => _currentUser;

  @override
  Future<fb_auth.ConfirmationResult> signInWithPhoneNumber(
    String phoneNumber, [
    fb_auth.RecaptchaVerifier? verifier,
  ]) async {
    if (errorToThrowOnSend != null) {
      throw errorToThrowOnSend!;
    }
    sentPhoneNumbersE164.add(phoneNumber);
    return _FakeConfirmationResult(
      phoneE164: phoneNumber,
      expectedCode: expectedOtpCode,
      verificationId: 'web_ver_${sentPhoneNumbersE164.length}',
      onConfirmed: (u) => _currentUser = u,
    );
  }

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    fb_auth.PhoneMultiFactorInfo? multiFactorInfo,
    required fb_auth.PhoneVerificationCompleted verificationCompleted,
    required fb_auth.PhoneVerificationFailed verificationFailed,
    required fb_auth.PhoneCodeSent codeSent,
    required fb_auth.PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    fb_auth.MultiFactorSession? multiFactorSession,
  }) async {
    if (errorToThrowOnSend != null) {
      verificationFailed(errorToThrowOnSend!);
      return;
    }
    final phone = phoneNumber ?? '';
    sentPhoneNumbersE164.add(phone);
    codeSent('mob_ver_${sentPhoneNumbersE164.length}', 42);
  }

  @override
  Future<fb_auth.UserCredential> signInWithCredential(
    fb_auth.AuthCredential credential,
  ) async {
    final phoneCred = credential as _FakePhoneAuthCredential;
    if (phoneCred.smsCode != expectedOtpCode) {
      throw fb_auth.FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'Invalid SMS verification code.',
      );
    }
    final e164 = sentPhoneNumbersE164.isNotEmpty
        ? sentPhoneNumbersE164.last
        : '+97455123456';
    final user = _FakePhoneUser(
      uid: 'mob_phone_${e164.replaceAll('+', '')}',
      phoneNumber: e164,
    );
    _currentUser = user;
    return _FakePhoneUserCredential(user);
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    _currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryUserStore implements FirebaseAuthUserStore {
  final Map<String, Map<String, dynamic>> users = {};
  final Map<String, Map<String, dynamic>> verifications = {};

  @override
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final d = users[uid];
    return d == null ? null : Map<String, dynamic>.from(d);
  }

  @override
  Future<void> setUserDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    if (merge && users.containsKey(uid)) {
      users[uid] = {...users[uid]!, ...data};
    } else {
      users[uid] = Map<String, dynamic>.from(data);
    }
  }

  @override
  Future<void> setProviderVerificationDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    if (merge && verifications.containsKey(uid)) {
      verifications[uid] = {...verifications[uid]!, ...data};
    } else {
      verifications[uid] = Map<String, dynamic>.from(data);
    }
  }
}

class _RecordingStorageGateway implements MediaStorageGateway {
  final List<({String path, int size, String contentType})> uploads = [];
  FirebaseException? firebaseErrorToThrow;

  @override
  Future<String> putBytes({
    required String storagePath,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  }) async {
    if (firebaseErrorToThrow != null) {
      throw firebaseErrorToThrow!;
    }
    uploads.add((
      path: storagePath,
      size: bytes.lengthInBytes,
      contentType: contentType,
    ));
    return 'https://firebasestorage.googleapis.com/v0/b/mashwar-qatar-2026-ec99d.appspot.com/o${Uri.encodeComponent(storagePath)}?alt=media';
  }
}

// Minimal valid 1x1 transparent PNG bytes so Image.memory decodes cleanly too
final Uint8List _samplePngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  tearDown(() {
    MediaUploadService.debugOverride = null;
    EmergencySosSheet.debugUrlLauncher = null;
    WorkRequestDetailsScreen.debugUrlLauncher = null;
    AdminInquiriesScreen.debugUrlLauncher = null;
  });

  Widget wrapScreen({
    required Widget home,
    AuthProvider? auth,
    WorksiteProvider? worksite,
    AdminProvider? admin,
    SettingsProvider? settings,
  }) {
    final s = settings ?? (SettingsProvider()..setLocale(const Locale('en', 'US')));
    final a = auth ??
        AuthProvider.forTesting(
          user: const UserModel(
            id: 'usr_fahad_1',
            fullName: 'Eng. Fahad Al-Marri',
            phone: '55112233',
            email: 'fahad@mashwar.qa',
            gender: UserGender.male,
          ),
        );
    final ws = worksite ??
        WorksiteProvider(
          initialUserId: a.user.id,
          initialUserName: a.user.fullName,
        );
    final adm = admin ?? AdminProvider.forTesting();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: s),
        ChangeNotifierProvider<AuthProvider>.value(value: a),
        ChangeNotifierProvider<WorksiteProvider>.value(value: ws),
        ChangeNotifierProvider<AdminProvider>.value(value: adm),
        ChangeNotifierProvider(create: (_) => RidesProvider()),
        ChangeNotifierProvider(create: (_) => ParcelsProvider()),
        ChangeNotifierProvider(create: (_) => BoardProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, settingsState, __) => MaterialApp(
          key: UniqueKey(),
          theme: AppTheme.lightTheme,
          locale: settingsState.locale,
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

  group('1. MediaUploadService Binary Validation, Paths & Storage Modes', () {
    test(
      'enforces <= 10 MB limit, image/* MIME validation, exact storage.rules paths, fail-closed default, dev-mock, and Firebase Storage gateway',
      () async {
        final fixedTime = DateTime.utc(2026, 11, 24, 15, 0, 0);
        final ts = fixedTime.millisecondsSinceEpoch;

        // 1. Canonical storage.rules paths
        expect(
          MediaUploadService.buildWorkRequestReferencePath(
            requestId: 'req_101',
            fileName: 'cable_spec.png',
          ),
          '/work_requests/req_101/reference/cable_spec.png',
        );
        expect(
          MediaUploadService.buildWorkRequestInvoicePath(
            requestId: 'req_101',
            fileName: 'store_receipt.jpg',
          ),
          '/work_requests/req_101/invoices/store_receipt.jpg',
        );
        expect(
          MediaUploadService.buildWorkRequestPaymentProofPath(
            requestId: 'req_101',
            fileName: 'fawran_transfer.webp',
          ),
          '/work_requests/req_101/payment_proofs/fawran_transfer.webp',
        );
        expect(
          MediaUploadService.buildProviderVerificationPath(
            uid: 'prov_77',
            docType: 'qid_front',
            timestampMs: ts,
            extension: 'jpeg',
          ),
          '/provider_verifications/prov_77/qid_front_$ts.jpg',
        );

        // 2. Rejects empty bytes, > 10 MB payloads, and non-image MIME types
        final failClosedService = MediaUploadService(
          useFirebaseOverride: false,
          allowDevMocksOverride: false,
          clock: () => fixedTime,
        );

        await expectLater(
          () => failClosedService.uploadWorkRequestReference(
            requestId: 'req_1',
            bytes: Uint8List(0),
            fileName: 'empty.png',
          ),
          throwsA(
            isA<MediaUploadException>().having((e) => e.code, 'code', 'empty-file'),
          ),
        );

        final overTenMb = Uint8List(MediaUploadService.maxUploadBytes + 1);
        await expectLater(
          () => failClosedService.uploadWorkRequestInvoice(
            requestId: 'req_1',
            bytes: overTenMb,
            fileName: 'huge_invoice.jpg',
            mimeType: 'image/jpeg',
          ),
          throwsA(
            isA<MediaUploadException>()
                .having((e) => e.code, 'code', 'file-too-large'),
          ),
        );

        await expectLater(
          () => failClosedService.uploadWorkRequestPaymentProof(
            requestId: 'req_1',
            bytes: _samplePngBytes,
            fileName: 'statement.pdf',
            mimeType: 'application/pdf',
          ),
          throwsA(
            isA<MediaUploadException>()
                .having((e) => e.code, 'code', 'invalid-mime-type'),
          ),
        );

        // 3. Fail-closed when neither Firebase nor dev mocks are active
        await expectLater(
          () => failClosedService.uploadWorkRequestReference(
            requestId: 'req_1',
            bytes: _samplePngBytes,
            fileName: 'spec.png',
          ),
          throwsA(
            isA<MediaUploadException>()
                .having((e) => e.code, 'code', 'storage-not-configured'),
          ),
        );

        // 4. Explicit dev-mock mode returns deterministic metadata
        final devMockService = MediaUploadService(
          useFirebaseOverride: false,
          allowDevMocksOverride: true,
          clock: () => fixedTime,
        );
        final mockRes = await devMockService.uploadProviderVerificationDoc(
          uid: 'usr_9',
          docType: 'qid_front',
          bytes: _samplePngBytes,
          fileName: 'qid_front.png',
        );
        expect(mockRes.isDevMock, isTrue);
        expect(
          mockRes.storagePath,
          '/provider_verifications/usr_9/qid_front_$ts.png',
        );
        expect(
          mockRes.downloadUrl,
          'https://storage.mashwar.qa/provider_verifications/usr_9/qid_front_$ts.png',
        );

        // 5. Real Firebase Storage gateway uploads bytes + contentType and maps FirebaseException
        final gateway = _RecordingStorageGateway();
        final firebaseService = MediaUploadService(
          storageGateway: gateway,
          useFirebaseOverride: true,
          clock: () => fixedTime,
        );

        final realInvoice = await firebaseService.uploadWorkRequestInvoice(
          requestId: 'req_88',
          bytes: _samplePngBytes,
          fileName: 'al_mana_invoice.png',
        );
        expect(realInvoice.isDevMock, isFalse);
        expect(gateway.uploads, hasLength(1));
        expect(
          gateway.uploads.single.path,
          '/work_requests/req_88/invoices/${ts}_al_mana_invoice.png',
        );
        expect(gateway.uploads.single.contentType, 'image/png');
        expect(realInvoice.downloadUrl, startsWith('https://firebasestorage.googleapis.com/'));

        gateway.firebaseErrorToThrow = FirebaseException(
          plugin: 'firebase_storage',
          code: 'unauthorized',
          message: 'User is not authorized',
        );
        await expectLater(
          () => firebaseService.uploadWorkRequestInvoice(
            requestId: 'req_88',
            bytes: _samplePngBytes,
            fileName: 'blocked.png',
          ),
          throwsA(
            isA<MediaUploadException>()
                .having((e) => e.code, 'code', 'permission-denied'),
          ),
        );
      },
    );

    testWidgets(
      'CreateWorkRequestScreen, WorkRequestDetailsScreen, ProviderProfileScreen, and IdVerificationScreen wire binary image uploads with preview pills and error feedback',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final gateway = _RecordingStorageGateway();
        var pickCounter = 0;
        MediaUploadService.debugOverride = MediaUploadService(
          storageGateway: gateway,
          useFirebaseOverride: true,
          imagePickerFn: ({
            required ImageSource source,
            int? imageQuality,
            double? maxWidth,
          }) async {
            pickCounter++;
            return XFile.fromData(
              _samplePngBytes,
              path: 'picked_doc_$pickCounter.png',
              name: 'picked_doc_$pickCounter.png',
              mimeType: 'image/png',
            );
          },
        );

        // A. CreateWorkRequestScreen reference photo upload
        await tester.pumpWidget(
          wrapScreen(home: const CreateWorkRequestScreen()),
        );
        await tester.pumpAndSettle();

        final uploadRefBtn =
            find.byKey(const ValueKey('upload_reference_photo_btn'));
        await tester.ensureVisible(uploadRefBtn);
        await tester.pumpAndSettle();
        await tester.tap(uploadRefBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('reference_photo_uploaded_pill')),
          findsOneWidget,
        );
        expect(find.text('picked_doc_1.png'), findsOneWidget);
        final refField = tester.widget<TextField>(
          find.byKey(const ValueKey('create_step1_photo')),
        );
        expect(refField.controller!.text, contains('firebasestorage.googleapis.com'));

        // B. WorkRequestDetailsScreen: requester manual bank transfer proof upload
        final provRepo = ProviderRepositoryImpl(allowDevMocks: true);
        final wsRepo = WorksiteRepositoryImpl(
          providerRepository: provRepo,
          allowDevMocks: true,
        );
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: 'usr_fahad_1',
          initialUserName: 'Eng. Fahad Al-Marri',
        );
        final bankReq = await worksite.createRequest(
          requesterId: 'usr_fahad_1',
          requesterName: 'Eng. Fahad Al-Marri',
          title: 'Copper Pipes 22mm',
          description: '10 lengths copper pipes',
          pickupLocation: 'Industrial Area St 14',
          dropoffWorksite: 'Lusail Plot 9',
          municipality: 'لوسيل',
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(300),
          deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(50),
          paymentMethod: PaymentMethod.bankTransferManual,
          siteContactName: 'Foreman Ali',
          siteContactPhone: '55998877',
        );
        expect(bankReq, isNotNull);

        await tester.pumpWidget(
          wrapScreen(
            home: WorkRequestDetailsScreen(requestId: bankReq!.id),
            worksite: worksite,
          ),
        );
        await tester.pumpAndSettle();

        final openTransferModalBtn =
            find.byKey(const ValueKey('upload_transfer_proof_btn'));
        await tester.ensureVisible(openTransferModalBtn);
        await tester.tap(openTransferModalBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('pick_transfer_proof_image_btn')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('transfer_proof_uploaded_pill')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm_transfer_proof_btn')),
        );
        await tester.pumpAndSettle();
        expect(
          worksite.selectedRequest?.paymentSettlementStatus,
          PaymentSettlementStatus.transferProofSubmitted,
        );

        // B2. WorkRequestDetailsScreen: assigned provider store invoice upload
        final offer = await worksite.submitOffer(
          requestId: bankReq.id,
          providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
          providerName: 'Khalid Approved Supply',
          proposedFeeMinor: MoneyMinor.fromMajorQar(45),
        );
        await worksite.acceptOffer(
          requestId: bankReq.id,
          offerId: offer!.id,
          requesterId: 'usr_fahad_1',
        );
        await worksite.advanceStatus(
          requestId: bankReq.id,
          nextStatus: WorkRequestStatus.inProgress,
          actorId: ProviderRepositoryImpl.pilotApprovedProviderId,
          actorRole: 'provider',
        );

        final providerWorksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: ProviderRepositoryImpl.pilotApprovedProviderId,
          initialUserName: 'Khalid Approved Supply',
        );
        await providerWorksite.selectAndLoadRequest(bankReq.id);

        await tester.pumpWidget(
          wrapScreen(
            home: WorkRequestDetailsScreen(requestId: bankReq.id),
            worksite: providerWorksite,
            auth: AuthProvider.forTesting(
              user: const UserModel(
                id: ProviderRepositoryImpl.pilotApprovedProviderId,
                fullName: 'Khalid Approved Supply',
                phone: '55234567',
                gender: UserGender.male,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final advancePickedUpBtn =
            find.byKey(const ValueKey('advance_stage_picked_up'));
        await tester.ensureVisible(advancePickedUpBtn);
        await tester.tap(advancePickedUpBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('upload_stage_invoice_btn')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('stage_invoice_uploaded_pill')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm_stage_update_btn')),
        );
        await tester.pumpAndSettle();
        expect(
          providerWorksite.selectedRequest?.status,
          WorkRequestStatus.pickedUp,
        );
        expect(
          providerWorksite.selectedRequest?.receiptImageUrl,
          contains('invoices'),
        );
        providerWorksite.dispose();

        // C. ProviderProfileScreen QID front/back/selfie binary uploads
        await tester.pumpWidget(
          wrapScreen(
            home: const ProviderProfileScreen(),
            worksite: worksite,
          ),
        );
        await tester.pumpAndSettle();

        final frontBtn =
            find.byKey(const ValueKey('upload_provider_qid_front_btn'));
        await tester.ensureVisible(frontBtn);
        await tester.tap(frontBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('provider_qid_front_pill')),
          findsOneWidget,
        );

        final backBtn =
            find.byKey(const ValueKey('upload_provider_qid_back_btn'));
        await tester.ensureVisible(backBtn);
        await tester.tap(backBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('provider_qid_back_pill')),
          findsOneWidget,
        );

        // D. IdVerificationScreen requires real uploaded front/back photos & submits download URLs
        final idAuth = AuthProvider.forTesting(
          user: const UserModel(
            id: 'usr_kyc_1',
            fullName: 'Hamad Al-Kuwari',
            phone: '66112233',
            gender: UserGender.male,
          ),
        );
        await tester.pumpWidget(
          wrapScreen(
            home: const IdVerificationScreen(),
            auth: idAuth,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('id_verif_qid_input')),
          '29663401842',
        );
        final submitIdBtn = find.byKey(const ValueKey('id_verif_submit_btn'));
        await tester.ensureVisible(submitIdBtn);
        await tester.tap(submitIdBtn);
        await tester.pumpAndSettle();

        // Blocked before uploading front & back photos
        expect(
          find.byKey(const ValueKey('id_verif_upload_error')),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('id_verif_upload_qid_front_btn')),
        );
        await tester.tap(
          find.byKey(const ValueKey('id_verif_upload_qid_front_btn')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('id_verif_upload_qid_back_btn')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(submitIdBtn);
        await tester.tap(submitIdBtn);
        await tester.pumpAndSettle();

        expect(idAuth.user.nationalId, '29663401842');
        expect(
          idAuth.user.idFrontImage,
          contains('provider_verifications%2Fusr_kyc_1%2Fqid_front_'),
        );
        expect(
          idAuth.user.idBackImage,
          contains('provider_verifications%2Fusr_kyc_1%2Fqid_back_'),
        );
        expect(tester.takeException(), isNull);

        worksite.dispose();
        idAuth.dispose();
      },
    );
  });

  group('2. Real +974 Firebase Phone Auth (Web & Mobile) & Bilingual Fallbacks', () {
    test(
      'validates Qatar +974 E.164, runs Web ConfirmationResult & Mobile verifyPhoneNumber flows, rejects arbitrary codes, and maps Firebase billing/quota errors',
      () async {
        // E.164 Qatar validation
        expect(
          FirebaseAuthRepository.normalizeQatarE164('55123456'),
          '+97455123456',
        );
        expect(
          FirebaseAuthRepository.normalizeQatarE164('٦٦٩٨٧٦٥٤'),
          '+97466987654',
        );
        expect(
          FirebaseAuthRepository.normalizeQatarE164('+974 7700-1122'),
          '+97477001122',
        );
        expect(
          () => FirebaseAuthRepository.normalizeQatarE164('44123456'),
          throwsA(
            isA<AuthException>()
                .having((e) => e.code, 'code', 'invalid-phone-number'),
          ),
        );

        // Web flow: signInWithPhoneNumber('+97455123456') -> ConfirmationResult.confirm
        final webFbAuth = _FakePhoneFirebaseAuth(expectedOtpCode: '918273');
        final webStore = _InMemoryUserStore();
        final webRepo = FirebaseAuthRepository.withUserStore(
          firebaseAuth: webFbAuth,
          userStore: webStore,
          isWebOverride: true,
        );

        expect(await webRepo.sendPhoneOtp('55123456'), isTrue);
        expect(webFbAuth.sentPhoneNumbersE164, ['+97455123456']);

        // Arbitrary 6-digit code (including dev code 482911) MUST fail
        await expectLater(
          () => webRepo.verifyPhoneOtp('55123456', '482911'),
          throwsA(
            isA<AuthException>()
                .having((e) => e.code, 'code', 'invalid-verification-code'),
          ),
        );

        final webUser = await webRepo.verifyPhoneOtp('55123456', '918273');
        expect(webUser.id, 'web_phone_97455123456');
        expect(webUser.phone, '55123456');
        expect(webStore.users['web_phone_97455123456']?['phone'], '55123456');

        // Mobile flow: verifyPhoneNumber -> Completer -> credentialFactory -> signInWithCredential
        final mobFbAuth = _FakePhoneFirebaseAuth(expectedOtpCode: '334455');
        final mobStore = _InMemoryUserStore();
        final mobRepo = FirebaseAuthRepository.withUserStore(
          firebaseAuth: mobFbAuth,
          userStore: mobStore,
          isWebOverride: false,
          credentialFactory: ({
            required String verificationId,
            required String smsCode,
          }) =>
              _FakePhoneAuthCredential(
            verificationId: verificationId,
            smsCode: smsCode,
          ),
        );

        expect(await mobRepo.sendPhoneOtp('33112233'), isTrue);
        expect(mobFbAuth.sentPhoneNumbersE164, ['+97433112233']);

        final mobUser = await mobRepo.verifyPhoneOtp('33112233', '334455');
        expect(mobUser.id, 'mob_phone_97433112233');
        expect(mobUser.phone, '33112233');

        // Firebase error code mapping (billing-not-enabled, operation-not-allowed, quota-exceeded, too-many-requests)
        for (final code in [
          'billing-not-enabled',
          'operation-not-allowed',
          'quota-exceeded',
          'too-many-requests',
        ]) {
          mobFbAuth.errorToThrowOnSend = fb_auth.FirebaseAuthException(
            code: code,
            message: 'Firebase error: $code',
          );
          await expectLater(
            () => mobRepo.sendPhoneOtp('55123456'),
            throwsA(
              isA<AuthException>()
                  .having((e) => e.code, 'code', code)
                  .having((e) => e.suggestEmailFallback, 'suggestEmailFallback', isTrue),
            ),
          );
        }
      },
    );

    testWidgets(
      'WelcomeScreen enables +974 Phone CTA with FirebaseAuthRepository, and PhoneInputScreen / OtpVerificationScreen surface SMS billing fallback to EmailInputScreen',
      (tester) async {
        final fbAuth = _FakePhoneFirebaseAuth()
          ..errorToThrowOnSend = fb_auth.FirebaseAuthException(
            code: 'billing-not-enabled',
            message: 'SMS billing not enabled',
          );
        final repo = FirebaseAuthRepository.withUserStore(
          firebaseAuth: fbAuth,
          userStore: _InMemoryUserStore(),
          isWebOverride: true,
        );
        final auth = AuthProvider(authRepository: repo, useDevMockAuth: false);

        await tester.pumpWidget(
          wrapScreen(home: const WelcomeScreen(), auth: auth),
        );
        await tester.pumpAndSettle();

        final phoneBtn = find.byKey(const ValueKey('welcome_phone_btn'));
        expect(phoneBtn, findsOneWidget);
        await tester.ensureVisible(phoneBtn);
        await tester.tap(phoneBtn);
        await tester.pumpAndSettle();
        expect(find.byType(PhoneInputScreen), findsOneWidget);

        // Attempt sending OTP -> surfaces Blaze SMS billing warning + direct Email+Password button
        await tester.tap(find.text('Send Code'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('phone_auth_error_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('Blaze'), findsOneWidget);

        final emailFallbackBtn =
            find.byKey(const ValueKey('phone_fallback_email_btn'));
        expect(emailFallbackBtn, findsOneWidget);
        await tester.ensureVisible(emailFallbackBtn);
        await tester.tap(emailFallbackBtn);
        await tester.pumpAndSettle();
        expect(find.byType(EmailInputScreen), findsOneWidget);

        // Also verify OtpVerificationScreen direct Email+Password fallback link
        await tester.pumpWidget(
          wrapScreen(home: const OtpVerificationScreen(), auth: auth),
        );
        await tester.pumpAndSettle();
        final otpToEmailBtn =
            find.byKey(const ValueKey('otp_switch_to_email_btn'));
        await tester.ensureVisible(otpToEmailBtn);
        await tester.tap(otpToEmailBtn);
        await tester.pumpAndSettle();
        expect(find.byType(EmailInputScreen), findsOneWidget);

        auth.dispose();
      },
    );
  });

  group('3. url_launcher Real OS Actions (Emergency 999, Order Contact, Admin Inquiries)', () {
    testWidgets(
      'EmergencySosSheet dials tel:999 and shows honest fallback when device lacks dialer; Details & AdminInquiries launch tel:, mailto:, and Firestore Console URLs',
      (tester) async {
        final launchedUris = <Uri>[];

        // 1. EmergencySosSheet when dialer is unavailable -> shows honest fallback banner
        EmergencySosSheet.debugUrlLauncher = (uri) async {
          launchedUris.add(uri);
          return false;
        };

        await tester.pumpWidget(
          wrapScreen(
            home: const Scaffold(body: EmergencySosSheet()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('sos_call_police_999_btn')));
        await tester.pumpAndSettle();

        expect(launchedUris, [Uri(scheme: 'tel', path: '999')]);
        expect(
          find.byKey(const ValueKey('sos_dialer_fallback_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('Calling Qatar MOI'), findsNothing);

        // 2. WorkRequestDetailsScreen launches tel:+974... and mailto:ops@mashwar.qa
        WorkRequestDetailsScreen.debugUrlLauncher =
            (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUris.add(uri);
          return true;
        };

        final provRepo = ProviderRepositoryImpl(allowDevMocks: true);
        final wsRepo = WorksiteRepositoryImpl(
          providerRepository: provRepo,
          allowDevMocks: true,
        );
        final worksite = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: 'usr_fahad_1',
          initialUserName: 'Eng. Fahad Al-Marri',
        );
        final created = await worksite.createRequest(
          requesterId: 'usr_fahad_1',
          title: 'Safety Helmets',
          description: '15 yellow PPE helmets',
          pickupLocation: 'Salwa Road',
          dropoffWorksite: 'West Bay Tower',
          municipality: 'الدوحة',
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(400),
          deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(60),
          siteContactName: 'Supervisor Tariq',
          siteContactPhone: '55443322',
        );

        await tester.pumpWidget(
          wrapScreen(
            home: WorkRequestDetailsScreen(requestId: created!.id),
            worksite: worksite,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('details_call_contact_btn')));
        await tester.pumpAndSettle();
        expect(launchedUris.last, Uri(scheme: 'tel', path: '+97455443322'));

        await tester.tap(
          find.byKey(const ValueKey('details_email_support_btn')),
        );
        await tester.pumpAndSettle();
        expect(launchedUris.last.scheme, 'mailto');
        expect(launchedUris.last.path, 'ops@mashwar.qa');

        // 3. AdminInquiriesScreen launches Firestore Console URL + inquiry mailto: & tel:
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        AdminInquiriesScreen.debugUrlLauncher =
            (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUris.add(uri);
          return true;
        };

        await tester.pumpWidget(
          wrapScreen(
            home: const Scaffold(body: AdminInquiriesScreen()),
            admin: AdminProvider.forTesting(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('admin_open_firestore_console_btn')),
        );
        await tester.pumpAndSettle();
        expect(
          launchedUris.last.toString(),
          contains('console.firebase.google.com'),
        );

        await tester.tap(find.text('View / Reply').first);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('admin_inquiry_mailto_btn')));
        await tester.pumpAndSettle();
        expect(launchedUris.last.scheme, 'mailto');

        worksite.dispose();
      },
    );
  });

  group('4. deleteUserAccount Callable & DeleteAccountScreen Active-Request Guards', () {
    testWidgets(
      'DeleteAccountScreen blocks deletion when WorksiteProvider or server reports active requests, and deletes account cleanly when clear',
      (tester) async {
        var serverShouldRejectPrecondition = true;
        final calledEndpoints = <String>[];

        final mockHttp = MockClient((http.Request req) async {
          calledEndpoints.add(req.url.path);
          if (serverShouldRejectPrecondition) {
            return http.Response(
              jsonEncode({
                'error': {
                  'status': 'FAILED_PRECONDITION',
                  'message':
                      'Cannot delete account while 1 active worksite request(s) exist (in_progress).',
                },
              }),
              400,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'result': {
                'uid': 'usr_del_1',
                'deletedCollections': [
                  'users',
                  'provider_profiles',
                  'provider_verifications',
                  'business_profiles',
                ],
                'auditLogId': 'aud_1',
                'authUserDeleted': true,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final fbAuth = _FakePhoneFirebaseAuth(
          initialUser: _FakePhoneUser(
            uid: 'usr_del_1',
            email: 'del@mashwar.qa',
          ),
        );
        final callable = FirebaseFunctionsCallableClient(
          projectId: 'mashwar-qatar-2026-ec99d',
          region: 'europe-west1',
          httpClient: mockHttp,
          idTokenProvider: () async => 'test_jwt_token',
        );
        final repo = FirebaseAuthRepository.withUserStore(
          firebaseAuth: fbAuth,
          userStore: _InMemoryUserStore(),
          callableClient: callable,
        );
        final auth = AuthProvider.forTesting(
          authRepository: repo,
          useDevMockAuth: false,
          user: const UserModel(
            id: 'usr_del_1',
            fullName: 'Rashed Al-Sulaiti',
            phone: '55001122',
            email: 'del@mashwar.qa',
            gender: UserGender.male,
          ),
        );

        // Case A: WorksiteProvider already holds an active ('accepted') request for usr_del_1
        final provRepo = ProviderRepositoryImpl(
          allowDevMocks: true,
          seedSampleData: true,
        );
        final wsRepo = WorksiteRepositoryImpl(
          providerRepository: provRepo,
          allowDevMocks: true,
          seedSampleData: false,
        );
        final worksiteWithActive = WorksiteProvider(
          worksiteRepository: wsRepo,
          providerRepository: provRepo,
          initialUserId: 'usr_del_1',
          initialUserName: 'Rashed Al-Sulaiti',
        );
        final createdReq = await worksiteWithActive.createRequest(
          requesterId: 'usr_del_1',
          title: 'Active Rebar Delivery',
          description: '2 tons steel rebar',
          pickupLocation: 'Industrial Area',
          dropoffWorksite: 'Al Wakrah Site',
          municipality: 'الوكرة',
          estimatedItemsCostMinor: MoneyMinor.fromMajorQar(1200),
          deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(150),
        );
        final offer = await worksiteWithActive.submitOffer(
          requestId: createdReq!.id,
          providerId: ProviderRepositoryImpl.pilotApprovedProviderId,
          providerName: 'Approved Runner',
          proposedFeeMinor: MoneyMinor.fromMajorQar(140),
        );
        await worksiteWithActive.acceptOffer(
          requestId: createdReq.id,
          offerId: offer!.id,
          requesterId: 'usr_del_1',
        );

        await tester.pumpWidget(
          wrapScreen(
            home: const DeleteAccountScreen(),
            auth: auth,
            worksite: worksiteWithActive,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('delete_account_blocker_card')),
          findsOneWidget,
        );
        expect(find.text('Active Rebar Delivery'), findsOneWidget);
        expect(find.text('الدوحة ← الخور'), findsNothing);

        // Case B: Empty local WorksiteProvider, but server callable returns FAILED_PRECONDITION
        final emptyWorksite = WorksiteProvider(
          worksiteRepository: WorksiteRepositoryImpl(
            providerRepository: provRepo,
            allowDevMocks: true,
            seedSampleData: false,
          ),
          providerRepository: provRepo,
          initialUserId: 'usr_del_1',
        );

        await tester.pumpWidget(
          wrapScreen(
            home: const DeleteAccountScreen(),
            auth: auth,
            worksite: emptyWorksite,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('delete_account_confirm_input')),
          'delete',
        );
        await tester.tap(
          find.byKey(const ValueKey('delete_account_submit_btn')),
        );
        await tester.pumpAndSettle();

        expect(calledEndpoints, ['/deleteUserAccount']);
        expect(auth.isAuthenticated, isTrue);
        expect(
          find.byKey(const ValueKey('delete_account_blocker_card')),
          findsOneWidget,
        );

        // Case C: Server allows deletion -> calls deleteUserAccount, signs out, navigates to WelcomeScreen
        serverShouldRejectPrecondition = false;
        await tester.pumpWidget(
          wrapScreen(
            home: const DeleteAccountScreen(),
            auth: auth,
            worksite: emptyWorksite,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('delete_account_confirm_input')),
          'delete',
        );
        await tester.tap(
          find.byKey(const ValueKey('delete_account_submit_btn')),
        );
        await tester.pumpAndSettle();

        expect(calledEndpoints.length, 2);
        expect(auth.isAuthenticated, isFalse);
        expect(auth.user.id, isEmpty);
        expect(fbAuth.signOutCount, 1);
        expect(find.byType(WelcomeScreen), findsOneWidget);

        worksiteWithActive.dispose();
        emptyWorksite.dispose();
        auth.dispose();
      },
    );
  });
}
