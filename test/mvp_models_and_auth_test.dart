import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mashwar/core/config/app_environment.dart';
import 'package:mashwar/data/mock_data.dart';
import 'package:mashwar/data/models/user_model.dart';
import 'package:mashwar/data/models/worksite_models.dart';
import 'package:mashwar/data/repositories/contracts/i_auth_repository.dart';
import 'package:mashwar/data/repositories/contracts/i_provider_repository.dart';
import 'package:mashwar/data/repositories/contracts/i_worksite_repository.dart';
import 'package:mashwar/data/repositories/implementations/auth_repository_impl.dart';
import 'package:mashwar/data/repositories/implementations/firebase/firebase_auth_repository.dart';
import 'package:mashwar/state/auth_provider.dart';

class _FakeUser implements fb_auth.User {
  @override
  final String uid;
  @override
  final String? email;
  String? _displayName;

  _FakeUser({
    required this.uid,
    this.email,
    String? displayName,
  }) : _displayName = displayName;

  @override
  String? get displayName => _displayName;

  @override
  String? get phoneNumber => null;

  @override
  Future<void> updateDisplayName(String? displayName) async {
    _displayName = displayName;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements fb_auth.UserCredential {
  @override
  final fb_auth.User? user;

  _FakeUserCredential(this.user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements fb_auth.FirebaseAuth {
  _FakeUser? _currentUser;
  final Map<String, ({String uid, String password, String? displayName})>
      _accounts = {};
  final List<String> passwordResetEmailsSent = [];
  int signOutCallCount = 0;

  void seedUser({
    required String uid,
    required String email,
    required String password,
    String? displayName,
    bool signedIn = false,
  }) {
    _accounts[email] = (uid: uid, password: password, displayName: displayName);
    if (signedIn) {
      _currentUser = _FakeUser(
        uid: uid,
        email: email,
        displayName: displayName,
      );
    }
  }

  @override
  fb_auth.User? get currentUser => _currentUser;

  @override
  Future<fb_auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw fb_auth.FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Invalid email or password',
      );
    }
    _currentUser = _FakeUser(
      uid: account.uid,
      email: email,
      displayName: account.displayName,
    );
    return _FakeUserCredential(_currentUser);
  }

  @override
  Future<fb_auth.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_accounts.containsKey(email)) {
      throw fb_auth.FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Email already registered',
      );
    }
    final uid = 'fb_uid_${_accounts.length + 1}';
    _accounts[email] = (uid: uid, password: password, displayName: null);
    _currentUser = _FakeUser(uid: uid, email: email);
    return _FakeUserCredential(_currentUser);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    fb_auth.ActionCodeSettings? actionCodeSettings,
  }) async {
    passwordResetEmailsSent.add(email);
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    _currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryFirebaseAuthUserStore implements FirebaseAuthUserStore {
  final Map<String, Map<String, dynamic>> users = {};
  final Map<String, Map<String, dynamic>> providerVerifications = {};
  FirebaseException? getError;
  FirebaseException? setError;

  @override
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    if (getError != null) throw getError!;
    final doc = users[uid];
    return doc == null ? null : Map<String, dynamic>.from(doc);
  }

  @override
  Future<void> setUserDoc(
    String uid,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    if (setError != null) throw setError!;
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
    if (merge && providerVerifications.containsKey(uid)) {
      providerVerifications[uid] = {...providerVerifications[uid]!, ...data};
    } else {
      providerVerifications[uid] = Map<String, dynamic>.from(data);
    }
  }
}

void main() {
  group('AppEnvironment & MVP Phase 1 Feature Flags', () {
    test('defaults to development flavor with Firebase and dev mocks disabled',
        () {
      expect(AppEnvironment.flavor, AppFlavor.development);
      expect(AppEnvironment.useFirebase, isFalse);
      expect(AppEnvironment.useDevMocks, isFalse);

      expect(AppEnvironment.enableWorksiteSupply, isTrue);
      expect(AppEnvironment.enablePassengerRides, isTrue);
      expect(AppEnvironment.enableCarpooling, isTrue);
      expect(AppEnvironment.enableCommercialCargo, isFalse);
      expect(AppEnvironment.enableDigitalWallet, isFalse);
      expect(AppEnvironment.enableEscrowClaims, isFalse);
    });

    test('USE_DEV_MOCKS is ONLY allowed in development when !useFirebase', () {
      final devAllowed = AppEnvironmentConfig.resolve(
        rawAppEnv: 'development',
        useFirebase: false,
        requestedDevMocks: true,
      );
      expect(devAllowed.flavor, AppFlavor.development);
      expect(devAllowed.useDevMocks, isTrue);

      final devWithFirebase = AppEnvironmentConfig.resolve(
        rawAppEnv: 'development',
        useFirebase: true,
        requestedDevMocks: true,
      );
      expect(devWithFirebase.useDevMocks, isFalse);

      final stagingDenied = AppEnvironmentConfig.resolve(
        rawAppEnv: 'staging',
        useFirebase: false,
        requestedDevMocks: true,
      );
      expect(stagingDenied.flavor, AppFlavor.staging);
      expect(stagingDenied.useDevMocks, isFalse);

      final prodDenied = AppEnvironmentConfig.resolve(
        rawAppEnv: 'production',
        useFirebase: false,
        requestedDevMocks: true,
      );
      expect(prodDenied.flavor, AppFlavor.production);
      expect(prodDenied.useDevMocks, isFalse);
    });

    test('provides bilingual legal & regulatory disclaimers for 3-service platform',
        () {
      final enDisclaimers = AppEnvironment.allLegalDisclaimers(isArabic: false);
      final arDisclaimers = AppEnvironment.allLegalDisclaimers(isArabic: true);

      expect(enDisclaimers, hasLength(4));
      expect(arDisclaimers, hasLength(4));
      expect(enDisclaimers.join(' '), contains('Shared Trips'));
      expect(enDisclaimers.join(' '), contains('Parcels'));
      expect(enDisclaimers.join(' '), contains('OTP'));
      expect(enDisclaimers.join(' '), contains('Trademark'));
      expect(arDisclaimers.join(' '), contains('الرحلات المشتركة'));
      expect(arDisclaimers.join(' '), contains('الطرود'));
      expect(arDisclaimers.join(' '), contains('OTP'));
    });
  });

  group('UserModel Neutral Defaults & MockData Separation', () {
    test('UserModel constructor & fromJson have production-safe neutral defaults',
        () {
      const freshUser = UserModel(
        id: 'u_fresh',
        fullName: 'Tariq Al-Malki',
        phone: '55110022',
        gender: UserGender.male,
      );

      expect(freshUser.isVerified, isFalse);
      expect(freshUser.idVerificationStatus, IdVerificationStatus.unverified);
      expect(freshUser.nationalId, isNull);
      expect(freshUser.walletBalance, 0.0);
      expect(freshUser.rating, 0.0);
      expect(freshUser.completedRides, 0);
      expect(freshUser.completedParcels, 0);

      final fromEmptyJson = UserModel.fromJson({});
      expect(fromEmptyJson.gender, UserGender.preferNotToSay);
      expect(fromEmptyJson.isVerified, isFalse);
      expect(fromEmptyJson.idVerificationStatus, IdVerificationStatus.unverified);
      expect(fromEmptyJson.nationalId, isNull);
      expect(fromEmptyJson.walletBalance, 0.0);
      expect(fromEmptyJson.rating, 0.0);
      expect(fromEmptyJson.completedRides, 0);
      expect(fromEmptyJson.completedParcels, 0);
    });

    test('MockData.currentUser explicitly supplies dev fixture fields', () {
      expect(MockData.currentUser.isVerified, isTrue);
      expect(MockData.currentUser.nationalId, '29663401842');
      expect(MockData.currentUser.walletBalance, 450.0);
      expect(MockData.currentUser.rating, 4.9);
    });
  });

  group('MoneyMinor & Worksite Supply Domain Models', () {
    test('MoneyMinor integer arithmetic and QAR formatting', () {
      const amount = MoneyMinor(15000);
      expect(amount.wholeQar, 150);
      expect(amount.remainderMinor, 0);
      expect(amount.formatQar(forceDecimals: true), '150.00 QAR');
      expect(amount.format(), '150 QAR');
      expect(amount.formatArabic(), '150 ر.ق');
      expect(amount.formatArabic(forceDecimals: true), '150.00 ر.ق');

      const fractional = MoneyMinor(15050);
      expect(fractional.format(), '150.50 QAR');
      expect(fractional.formatArabic(), '150.50 ر.ق');

      expect(MoneyMinor.fromMajorQar(180), const MoneyMinor(18000));
      expect(MoneyMinor.fromDecimalString('180.75'), const MoneyMinor(18075));
      expect(MoneyMinor.fromDecimalString('180.5'), const MoneyMinor(18050));
      expect(MoneyMinor.fromDecimalString('-25.05'), const MoneyMinor(-2505));

      expect(amount + const MoneyMinor(2500), const MoneyMinor(17500));
      expect(amount - const MoneyMinor(2500), const MoneyMinor(12500));
      expect(amount.toJson(), 15000);
      expect(amount.toJson(), isA<int>());
    });

    test('WorkRequestStatus preserves exact snake_case DB strings', () {
      const expectedStatuses = [
        'open',
        'offer_received',
        'offer_selected',
        'accepted',
        'in_progress',
        'picked_up',
        'in_transit',
        'delivered_pending_confirmation',
        'completed',
        'cancelled',
        'disputed',
      ];

      expect(
        WorkRequestStatus.values.map((s) => s.value).toList(),
        expectedStatuses,
      );
      for (final raw in expectedStatuses) {
        expect(WorkRequestStatusMachine.isValidStatusString(raw), isTrue);
        expect(WorkRequestStatus.fromString(raw).value, raw);
      }
      expect(WorkRequestStatusMachine.isValidStatusString('مكتمل'), isFalse);
      expect(
        () => WorkRequestStatus.fromString('invalid_status'),
        throwsArgumentError,
      );
    });

    test('WorkRequestStatusMachine enforces requester, provider, and admin rules',
        () {
      // Requester CANNOT mark completed directly
      expect(
        WorkRequestStatusMachine.canTransition(
          WorkRequestStatus.deliveredPendingConfirmation,
          WorkRequestStatus.completed,
          actorRole: 'requester',
          actorId: 'req_1',
          requesterId: 'req_1',
        ),
        isFalse,
      );

      // Provider CANNOT accept another provider's selected job
      expect(
        WorkRequestStatusMachine.canTransition(
          WorkRequestStatus.offerSelected,
          WorkRequestStatus.accepted,
          actorRole: 'provider',
          actorId: 'prov_other',
          selectedOfferProviderId: 'prov_selected',
          isProviderApproved: true,
        ),
        isFalse,
      );

      // Unapproved provider CANNOT submit offers or accept
      expect(
        WorkRequestStatusMachine.canTransition(
          WorkRequestStatus.open,
          WorkRequestStatus.offerReceived,
          actorRole: 'provider',
          actorId: 'prov_pending',
          isProviderApproved: false,
        ),
        isFalse,
      );
      expect(
        WorkRequestStatusMachine.canTransition(
          WorkRequestStatus.offerSelected,
          WorkRequestStatus.accepted,
          actorRole: 'provider',
          actorId: 'prov_1',
          selectedOfferProviderId: 'prov_1',
          isProviderApproved: false,
        ),
        isFalse,
      );

      // Selected approved provider CAN accept and progress through fulfillment
      expect(
        WorkRequestStatusMachine.canTransition(
          WorkRequestStatus.offerSelected,
          WorkRequestStatus.accepted,
          actorRole: 'provider',
          actorId: 'prov_1',
          selectedOfferProviderId: 'prov_1',
          isProviderApproved: true,
        ),
        isTrue,
      );
      expect(
        WorkRequestStatusMachine.canTransition(
          WorkRequestStatus.accepted,
          WorkRequestStatus.inProgress,
          actorRole: 'provider',
          actorId: 'prov_1',
          assignedProviderId: 'prov_1',
        ),
        isTrue,
      );

      // Provider cannot mark completed without verified handover code
      expect(
        WorkRequestStatusMachine.canTransition(
          WorkRequestStatus.deliveredPendingConfirmation,
          WorkRequestStatus.completed,
          actorRole: 'provider',
          actorId: 'prov_1',
          assignedProviderId: 'prov_1',
          handoverCodeVerified: false,
        ),
        isFalse,
      );
      expect(
        WorkRequestStatusMachine.canTransition(
          WorkRequestStatus.deliveredPendingConfirmation,
          WorkRequestStatus.completed,
          actorRole: 'provider',
          actorId: 'prov_1',
          assignedProviderId: 'prov_1',
          handoverCodeVerified: true,
        ),
        isTrue,
      );

      // Terminal states cannot transition even for admin
      expect(
        WorkRequestStatusMachine.canTransition(
          WorkRequestStatus.completed,
          WorkRequestStatus.disputed,
          actorRole: 'admin',
        ),
        isFalse,
      );
    });

    test('All Worksite Supply models serialize UTC ISO & integer minor units',
        () {
      final now = DateTime.utc(2026, 11, 24, 18, 30, 0);

      final req = WorkRequest(
        id: 'wr_1',
        requesterId: 'req_1',
        requesterName: 'Eng. Fahad',
        title: 'Electrical breakers',
        description: '32A breakers from Industrial Area St 10',
        pickupLocation: 'Industrial Area St 10',
        dropoffWorksite: 'Lusail Marina Plot 42',
        municipality: 'Al Daayen',
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(180),
        maxItemsCapMinor: MoneyMinor.fromMajorQar(220),
        deliveryFeeBudgetMinor: MoneyMinor.fromMajorQar(45),
        agreedFeeMinor: MoneyMinor.fromMajorQar(40),
        status: WorkRequestStatus.inTransit,
        paymentMethod: PaymentMethod.bankTransferManual,
        paymentSettlementStatus: PaymentSettlementStatus.transferProofSubmitted,
        assignedProviderId: 'prov_1',
        createdAt: now,
        updatedAt: now,
      );

      final reqJson = req.toJson();
      expect(reqJson['estimatedItemsCostMinor'], 18000);
      expect(reqJson['maxItemsCapMinor'], 22000);
      expect(reqJson['deliveryFeeBudgetMinor'], 4500);
      expect(reqJson['agreedFeeMinor'], 4000);
      expect(reqJson['status'], 'in_transit');
      expect(reqJson['paymentMethod'], 'bank_transfer_manual');
      expect(reqJson['paymentSettlementStatus'], 'transfer_proof_submitted');
      expect(reqJson['createdAt'], '2026-11-24T18:30:00.000Z');
      expect(reqJson['estimatedItemsCostMinor'], isA<int>());
      expect(reqJson['deliveryFeeBudgetMinor'], isA<int>());

      final restoredReq = WorkRequest.fromJson(reqJson);
      expect(restoredReq.effectiveTotalMinor, const MoneyMinor(22000));
      expect(restoredReq.status, WorkRequestStatus.inTransit);
      expect(restoredReq.createdAt.isUtc, isTrue);

      final offer = WorkOffer(
        id: 'off_1',
        requestId: 'wr_1',
        providerId: 'prov_1',
        providerName: 'Khalid',
        proposedFeeMinor: MoneyMinor.fromMajorQar(40),
        estimatedItemsCostMinor: MoneyMinor.fromMajorQar(180),
        estimatedEtaMinutes: 35,
        createdAt: now,
        updatedAt: now,
      );
      final restoredOffer = WorkOffer.fromJson(offer.toJson());
      expect(restoredOffer.proposedFeeMinor, const MoneyMinor(4000));
      expect(restoredOffer.estimatedEtaMinutes, 35);

      final event = RequestEvent(
        id: 'evt_1',
        requestId: 'wr_1',
        actorId: 'prov_1',
        actorRole: 'provider',
        eventType: 'status_changed',
        fromStatus: WorkRequestStatus.pickedUp,
        toStatus: WorkRequestStatus.inTransit,
        createdAt: now,
      );
      final restoredEvent = RequestEvent.fromJson(event.toJson());
      expect(restoredEvent.fromStatus, WorkRequestStatus.pickedUp);
      expect(restoredEvent.toStatus, WorkRequestStatus.inTransit);

      final provider = ProviderProfile(
        id: 'prov_1',
        userId: 'prov_1',
        fullName: 'Khalid Al-Mannai',
        phone: '55123456',
        qidNumber: '29663401842',
        approvalStatus: ProviderApprovalStatus.approved,
        serviceMunicipalities: const ['Doha', 'Al Daayen'],
        createdAt: now,
        updatedAt: now,
      );
      final restoredProvider = ProviderProfile.fromJson(provider.toJson());
      expect(restoredProvider.canAcceptWorksiteJobs, isTrue);
      expect(restoredProvider.approvalStatus, ProviderApprovalStatus.approved);

      final business = BusinessProfile(
        id: 'biz_1',
        ownerUserId: 'req_1',
        companyName: 'Lusail Builders WLL',
        contactPhone: '44001122',
        createdAt: now,
        updatedAt: now,
      );
      expect(
        BusinessProfile.fromJson(business.toJson()).companyName,
        'Lusail Builders WLL',
      );

      final site = SavedWorksite(
        id: 'site_1',
        ownerUserId: 'req_1',
        label: 'Marina Plot 42',
        municipality: 'Al Daayen',
        zoneOrStreet: 'Zone 69, Street 210',
        siteContactName: 'Site Foreman',
        siteContactPhone: '55009988',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      );
      expect(SavedWorksite.fromJson(site.toJson()).isDefault, isTrue);

      final rating = RequestRating(
        id: 'wr_1_req_1',
        requestId: 'wr_1',
        raterUserId: 'req_1',
        raterRole: 'requester',
        targetUserId: 'prov_1',
        score: 5,
        comment: 'Delivered with original receipt',
        createdAt: now,
      );
      expect(RequestRating.fromJson(rating.toJson()).score, 5);

      final handover = HandoverVerificationResult(
        verified: true,
        requestId: 'wr_1',
        resultingStatus: WorkRequestStatus.completed,
        message: 'Handover confirmed',
        verifiedAt: now,
        verifiedByProviderId: 'prov_1',
      );
      final restoredHandover =
          HandoverVerificationResult.fromJson(handover.toJson());
      expect(restoredHandover.verified, isTrue);
      expect(restoredHandover.resultingStatus, WorkRequestStatus.completed);
    });

    test('Worksite contracts compile cleanly as repository interfaces', () {
      IAuthRepository? authContract;
      IProviderRepository? providerContract;
      IWorksiteRepository? worksiteContract;
      expect(authContract, isNull);
      expect(providerContract, isNull);
      expect(worksiteContract, isNull);
    });
  });

  group('FirebaseAuthRepository & DevMockAuthRepository Security', () {
    test('FirebaseAuthRepository rejects phone OTP bypass and validates QID',
        () async {
      final fakeAuth = _FakeFirebaseAuth();
      final fakeStore = _InMemoryFirebaseAuthUserStore();
      final repo = FirebaseAuthRepository.withUserStore(
        firebaseAuth: fakeAuth,
        userStore: fakeStore,
      );

      await expectLater(
        () => repo.sendPhoneOtp('55123456'),
        throwsUnsupportedError,
      );
      await expectLater(
        () => repo.verifyPhoneOtp('55123456', '482911'),
        throwsUnsupportedError,
      );

      // Register creates neutral Firestore user doc and signed-in session
      final registered = await repo.registerWithEmail(
        email: 'engineer@site.qa',
        password: 'StrongPassword123',
        fullName: 'Fahad Al-Marri',
        phone: '55112233',
      );
      expect(registered.isVerified, isFalse);
      expect(registered.walletBalance, 0.0);
      expect(registered.idVerificationStatus, IdVerificationStatus.unverified);
      expect(await repo.isSignedIn(), isTrue);
      expect(await repo.currentUid(), registered.id);

      // Invalid QID (<11 or non-numeric) throws ArgumentError
      await expectLater(
        () => repo.submitNationalId(
          nationalId: '12345',
          idFrontImage: 'front.jpg',
          idBackImage: 'back.jpg',
          selfieImage: 'selfie.jpg',
        ),
        throwsArgumentError,
      );

      // Valid 11-digit Qatar QID writes provider_verifications & users
      final ok = await repo.submitNationalId(
        nationalId: '29663401842',
        idFrontImage: 'front.jpg',
        idBackImage: 'back.jpg',
        selfieImage: 'selfie.jpg',
      );
      expect(ok, isTrue);
      expect(
        fakeStore.providerVerifications[registered.id]?['qidNumber'],
        '29663401842',
      );
      expect(
        fakeStore.users[registered.id]?['idVerificationStatus'],
        'underReview',
      );

      // updateProfile never escalates verification or wallet balance
      final updated = await repo.updateProfile(
        registered.copyWith(
          city: 'Lusail',
          isVerified: true,
          walletBalance: 9999.0,
        ),
      );
      expect(updated.city, 'Lusail');
      expect(updated.isVerified, isFalse);
      expect(updated.walletBalance, 0.0);

      // Password reset & signOut & session restore
      await repo.sendPasswordReset('engineer@site.qa');
      expect(fakeAuth.passwordResetEmailsSent, ['engineer@site.qa']);

      await repo.signOut();
      expect(await repo.isSignedIn(), isFalse);
      expect(await repo.getCurrentUser(), isNull);

      // Login restores existing Firestore doc
      final loggedIn = await repo.loginWithEmail(
        'engineer@site.qa',
        'StrongPassword123',
      );
      expect(loggedIn.id, registered.id);
      expect(loggedIn.nationalId, '29663401842');
      expect(loggedIn.idVerificationStatus, IdVerificationStatus.underReview);
      expect(loggedIn.isVerified, isFalse);
    });

    test('FirebaseAuthRepository session restore creates users/{uid} if absent',
        () async {
      final fakeAuth = _FakeFirebaseAuth();
      final fakeStore = _InMemoryFirebaseAuthUserStore();
      fakeAuth.seedUser(
        uid: 'legacy_uid_99',
        email: 'ops@doha.qa',
        password: 'pw',
        displayName: 'Ops User',
        signedIn: true,
      );

      final repo = FirebaseAuthRepository.withUserStore(
        firebaseAuth: fakeAuth,
        userStore: fakeStore,
      );
      final restored = await repo.getCurrentUser();
      expect(restored, isNotNull);
      expect(restored!.id, 'legacy_uid_99');
      expect(restored.isVerified, isFalse);
      expect(restored.walletBalance, 0.0);
      expect(fakeStore.users['legacy_uid_99']?['email'], 'ops@doha.qa');
    });

    test('DevMockAuthRepository is gated when dev mocks are disabled', () async {
      final disabledRepo = AuthRepositoryImpl();
      expect(disabledRepo.isDevMockActive, isFalse);
      expect(await disabledRepo.isSignedIn(), isFalse);
      expect(await disabledRepo.getCurrentUser(), isNull);
      await expectLater(
        () => disabledRepo.sendPhoneOtp('55123456'),
        throwsUnsupportedError,
      );
      await expectLater(
        () => disabledRepo.verifyPhoneOtp('55123456', '482911'),
        throwsUnsupportedError,
      );
      await expectLater(
        () => disabledRepo.loginWithEmail('a@b.qa', 'pass'),
        throwsStateError,
      );

      final devRepo = DevMockAuthRepository(allowDevMocks: true);
      expect(devRepo.isDevMockActive, isTrue);
      final devUser = await devRepo.registerWithEmail(
        email: 'dev@mashwar.qa',
        password: 'password123',
      );
      expect(devUser.isVerified, isFalse);
      expect(devUser.walletBalance, 0.0);
      await expectLater(
        () => devRepo.verifyPhoneOtp('55123456', '000000'),
        throwsStateError,
      );
    });
  });

  group('AuthProvider Production Boundaries & Session Lifecycle', () {
    test(
        'defaults unauthenticated with neutral user, empty wallet history, and blocked local wallet ops',
        () async {
      final auth = AuthProvider();

      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.isDevMockAuthEnabled, isFalse);
      expect(auth.user.isVerified, isFalse);
      expect(auth.user.walletBalance, 0.0);
      expect(auth.user.nationalId, isNull);
      expect(auth.user.rating, 0.0);
      expect(auth.phoneNumber, isEmpty);
      expect(auth.walletTransactions, isEmpty);

      // Never accepts arbitrary 6-digit OTPs (or even 482911) outside dev-mock mode
      expect(await auth.verifyOtp('123456'), isFalse);
      expect(await auth.verifyOtp('482911'), isFalse);
      expect(auth.status, AuthStatus.unauthenticated);

      // Wallet deposit/withdraw blocked when AppEnvironment.enableDigitalWallet == false
      expect(
        auth.depositWalletFunds(
          amount: 200,
          methodAr: 'فوراً',
          methodEn: 'Fawran',
        ),
        isFalse,
      );
      expect(
        auth.withdrawWalletFunds(
          amount: 50,
          destinationAr: 'IBAN',
          destinationEn: 'IBAN',
        ),
        isFalse,
      );
      auth.updateWalletBalance(999.0);
      expect(auth.user.walletBalance, 0.0);
      expect(auth.walletTransactions, isEmpty);

      // Cannot elevate unauthenticated user via saveProfile or approveIdVerification
      auth.saveProfile(fullName: 'Hacker', gender: UserGender.male);
      expect(auth.status, AuthStatus.unauthenticated);
      auth.approveIdVerification();
      expect(auth.user.isVerified, isFalse);

      auth.dispose();
    });

    test('registerWithEmail, loginWithEmail, restoreSession, and await logout',
        () async {
      final fakeAuth = _FakeFirebaseAuth();
      final fakeStore = _InMemoryFirebaseAuthUserStore();
      final repo = FirebaseAuthRepository.withUserStore(
        firebaseAuth: fakeAuth,
        userStore: fakeStore,
      );

      final auth = AuthProvider(authRepository: repo);

      final regOk = await auth.registerWithEmail(
        email: 'contractor@doha.qa',
        password: 'password123',
        fullName: 'Nasser Al-Thani',
        phone: '55443322',
      );
      expect(regOk, isTrue);
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.user.email, 'contractor@doha.qa');
      expect(auth.user.isVerified, isFalse);
      expect(auth.user.walletBalance, 0.0);

      // New AuthProvider instance restores active session cleanly
      final restoredProvider = AuthProvider(authRepository: repo);
      expect(await restoredProvider.restoreSession(), isTrue);
      expect(restoredProvider.status, AuthStatus.authenticated);
      expect(restoredProvider.user.email, 'contractor@doha.qa');

      // logout() awaits repository signOut() and resets state
      await restoredProvider.logout();
      expect(fakeAuth.signOutCallCount, 1);
      expect(restoredProvider.status, AuthStatus.unauthenticated);
      expect(restoredProvider.user.id, isEmpty);
      expect(restoredProvider.user.isVerified, isFalse);
      expect(await repo.isSignedIn(), isFalse);

      // Re-login with email works
      expect(
        await restoredProvider.loginWithEmail(
          'contractor@doha.qa',
          'password123',
        ),
        isTrue,
      );
      expect(restoredProvider.status, AuthStatus.authenticated);

      auth.dispose();
      restoredProvider.dispose();
    });

    test(
        'FirebaseAuthRepository maps email auth errors to bilingual AuthExceptions and tolerates Firestore permission-denied on user doc hydration',
        () async {
      final fakeAuth = _FakeFirebaseAuth();
      final fakeStore = _InMemoryFirebaseAuthUserStore()
        ..setError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        );
      final repo = FirebaseAuthRepository.withUserStore(
        firebaseAuth: fakeAuth,
        userStore: fakeStore,
      );

      // Register without explicit fullName succeeds even if Firestore setUserDoc throws permission-denied
      final registered = await repo.registerWithEmail(
        email: 'engineer.lusail@mashwar.qa',
        password: 'StrongPassword123',
      );
      expect(registered.id, isNotEmpty);
      expect(registered.email, 'engineer.lusail@mashwar.qa');
      expect(registered.fullName, 'engineer.lusail');
      expect(registered.phone, isEmpty);

      // Duplicate registration maps email-already-in-use cleanly
      await expectLater(
        () => repo.registerWithEmail(
          email: 'engineer.lusail@mashwar.qa',
          password: 'StrongPassword123',
        ),
        throwsA(
          isA<AuthException>()
              .having((e) => e.code, 'code', 'email-already-in-use')
              .having((e) => e.suggestEmailFallback, 'suggestEmailFallback', isFalse)
              .having((e) => e.messageAr, 'messageAr', contains('مسجل مسبقاً')),
        ),
      );

      // Wrong password login maps invalid-credential cleanly
      await expectLater(
        () => repo.loginWithEmail(
          'engineer.lusail@mashwar.qa',
          'WrongPassword!',
        ),
        throwsA(
          isA<AuthException>()
              .having((e) => e.code, 'code', 'invalid-credential')
              .having((e) => e.suggestEmailFallback, 'suggestEmailFallback', isFalse)
              .having((e) => e.messageAr, 'messageAr', contains('غير صحيحة')),
        ),
      );

      // Valid login succeeds even when getUserDoc & setUserDoc throw permission-denied
      fakeStore.getError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );
      final loggedIn = await repo.loginWithEmail(
        'engineer.lusail@mashwar.qa',
        'StrongPassword123',
      );
      expect(loggedIn.id, registered.id);
      expect(loggedIn.fullName, 'engineer.lusail');

      // operation-not-allowed differs cleanly for email vs phone flow
      final emailOpDisabled = FirebaseAuthRepository.mapFirebaseAuthException(
        fb_auth.FirebaseAuthException(code: 'operation-not-allowed'),
        isEmailFlow: true,
      );
      expect(emailOpDisabled.suggestEmailFallback, isFalse);
      expect(emailOpDisabled.messageEn, contains('Email/Password'));

      final phoneOpDisabled = FirebaseAuthRepository.mapFirebaseAuthException(
        fb_auth.FirebaseAuthException(code: 'operation-not-allowed'),
        isEmailFlow: false,
      );
      expect(phoneOpDisabled.suggestEmailFallback, isTrue);
      expect(phoneOpDisabled.messageEn, contains('Phone authentication'));
    });

    test(
        'FirebaseAuthRepository.mapFirebaseAuthException handles configuration-not-found, internal-error CONFIGURATION_NOT_FOUND, and unauthorized-domain cleanly',
        () {
      for (final isEmail in [false, true]) {
        final configNotFound =
            FirebaseAuthRepository.mapFirebaseAuthException(
          fb_auth.FirebaseAuthException(code: 'configuration-not-found'),
          isEmailFlow: isEmail,
        );
        expect(configNotFound.code, 'configuration-not-found');
        expect(configNotFound.suggestEmailFallback, isFalse);
        expect(configNotFound.messageAr, contains('Firebase Authentication'));
        expect(configNotFound.messageEn, contains('not initialized'));
        expect(
          configNotFound.messageAr,
          isNot(contains('تعذّر إتمام التحقق عبر الجوال')),
        );

        final internalConfigNotFound =
            FirebaseAuthRepository.mapFirebaseAuthException(
          fb_auth.FirebaseAuthException(
            code: 'internal-error',
            message:
                'An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]',
          ),
          isEmailFlow: isEmail,
        );
        expect(internalConfigNotFound.code, 'configuration-not-found');
        expect(internalConfigNotFound.suggestEmailFallback, isFalse);
        expect(
          internalConfigNotFound.messageAr,
          isNot(contains('تعذّر إتمام التحقق عبر الجوال')),
        );

        final unauthorizedDomain =
            FirebaseAuthRepository.mapFirebaseAuthException(
          fb_auth.FirebaseAuthException(code: 'unauthorized-domain'),
          isEmailFlow: isEmail,
        );
        expect(unauthorizedDomain.code, 'unauthorized-domain');
        expect(unauthorizedDomain.suggestEmailFallback, isFalse);
        expect(unauthorizedDomain.messageAr, contains('Authorized Domains'));
        expect(unauthorizedDomain.messageEn, contains('Authorized Domains'));
        expect(
          unauthorizedDomain.messageAr,
          isNot(contains('تعذّر إتمام التحقق عبر الجوال')),
        );
      }
    });
  });
}
