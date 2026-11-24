# MASHWAR — MVP Baseline Audit & Worksite Supply Readiness Report

**Audit Date:** 2026-11-24  
**Branch:** `feat/mvp-worksite-supply`  
**Repository:** `d:\My_Projects\Meshwar-v1\Meshwar`  
**Firebase Target Project (`.firebaserc`):** `mashwar-qatar-2026-ec99d`  
**Target MVP Focus:** Qatar **Worksite Supply** (material & hardware procurement runs from Industrial Area / supply hubs to worksites with bilateral escrow, receipt proof, and OTP-gated release)

---

## Executive Verdict

The Flutter client presents a polished, responsive bilingual (Arabic/English) UI shell with zero static analysis issues and all 91 widget/state unit tests passing. An initial architectural skeleton for Firebase integration also exists (`AppRepositories` DI switching, 8 repository contracts, 7 Firebase repository implementations, a 1,600-line `firestore.rules` file, and a standalone web admin entrypoint `lib/admin_main.dart`).

**However, the application is currently an interactive prototype rather than a backend-backed MVP:**
1. **Firebase is off by default** (`FirebaseConfig.useFirebase` defaults to `false`), and even when enabled, Providers seed themselves from synchronous `MockData`, mutate local RAM state, and discard or skip repository persistence.
2. **No backend deployment code exists:** the `functions/` directory and `storage.rules` do not exist despite documentation claiming live Cloud Functions and Storage workflows.
3. **Every Firebase client repository write currently collides with `firestore.rules`** due to omitted required fields (`driverId`, `senderId`), wrong field names (`lastMessageText` vs `lastMessage`), Egypt-only regex/length constraints (`nationalId` 14–20 chars vs Qatar 11-digit QID; `+20` phones; `vodafoneCash`/`instapay`/`fawry` enums), and client-side attempts to write admin-only `wallet_transactions` or `isVerified: true`.
4. **Authentication, Admin RBAC, Wallet, and Bilateral Escrow are simulated locally:** `AuthProvider` boots authenticated as `MockData.currentUser` (450.0 QAR, 4.9 rating, verified QID `29663401842`), accepts any 6-digit OTP, and `AdminProvider` defaults `_isLoggedIn = true` with `/admin` bypassing `AdminLoginScreen` and exposing a client-side role switcher.
5. **Local Firebase Emulator Suite cannot run in this environment yet:** `Node v24.19.0` is present, but `java` and global `firebase` CLI are not installed in `PATH`.

---

## 1. Measured Toolchain & Verification Baseline

Executed cleanly on Windows PowerShell 5.1 against `feat/mvp-worksite-supply` (`Flutter 3.47.9` / `Dart 3.13.7`):

| Check / Tool | Command | Exit Code | Duration | Measured Result |
| :--- | :--- | :---: | :---: | :--- |
| Dependencies | `flutter pub get` | `0` | `7.24s` | Resolved cleanly (`17 packages have newer versions incompatible with dependency constraints`) |
| Static Analysis | `flutter analyze` | `0` | `34.18s` | `No issues found! (ran in 24.5s)` |
| Test Suite | `flutter test` | `0` | `74.37s` | `00:59 +91: All tests passed!` across 16 test files (`test/*.dart`) |
| Node.js | `node -v` | `0` | — | `v24.19.0` (compatible with Cloud Functions Node 20/22+ tooling) |
| Java Runtime | `java -version` | Not found | — | `CommandNotFoundException` (`java` not recognized in `PATH`) |
| Firebase CLI | `firebase --version` | Not found | — | `CommandNotFoundException` (`firebase` not recognized in `PATH`) |

### What the 91 Passing Tests Actually Verify (and Do Not Verify)
- **Covered (2,520 lines across 16 files in `test/`):** Responsive layout/zero-overflow checks across mobile/desktop viewports (`backend_readiness_and_screens_test.dart`, `admin_enterprise_devops_test.dart`), bilingual RTL/LTR switching (`dynamic_language_switcher_test.dart`, `localization_test.dart`), UI smoke tests (`widget_test.dart`, `uber_live_map_and_onboarding_test.dart`, `universal_services_and_escrow_test.dart`), and in-memory `AdminProvider` mutations (`admin_web_test.dart`).
- **Not Covered:** `test/firebase_repositories_test.dart` (75 lines) only asserts that `AppRepositories.instance` satisfies contracts and exercises `useLocalMocks()`. **Zero tests run against Firebase Auth, Firestore rules, Firebase Emulator Suite, Cloud Functions, or live Worksite Supply escrow state transitions.**
- **Emulator Feasibility Impact:** Because `java` is missing from `PATH` (and `firebase` CLI is absent), the Firebase Local Emulator Suite (`firestore`, `storage`, `pubsub`) **cannot start** until a JRE/JDK (Java 11+ / Java 21 LTS) and `firebase-tools` are installed.

---

## 2. Existing Architecture Assessment

### Entrypoints, Routing & Providers
- **Consumer + Embedded Admin Entrypoint (`lib/main.dart`):**
  - Checks `FirebaseConfig.useFirebase`; only calls `Firebase.initializeApp(...)` and `AppRepositories.instance.useFirebase()` when `USE_FIREBASE=true`.
  - Registers 7 `ChangeNotifierProvider` instances: `SettingsProvider`, `AuthProvider`, `RidesProvider`, `ParcelsProvider`, `BoardProvider`, `AlertsProvider`, `AdminProvider`.
  - Inspects `Uri.base` query/fragment/path to auto-open `AdminShell()` if `/admin` or `?admin=true` is requested, and defines routes `/admin` -> `const AdminShell()` and `/admin-login` -> `const AdminLoginScreen()`. Default `home` is `SplashScreen`.
- **Dedicated Admin Web Entrypoint (`lib/admin_main.dart`):**
  - `MashwarAdminWebApp` initializes Firebase when `FirebaseConfig.useFirebase` is true and selects `home: admin.isLoggedIn ? const AdminShell() : const AdminLoginScreen()`.
  - Built separately in `.github/workflows/mashwar_ci_cd.yml` and served via `vercel.json` (`/admin` -> `/admin/index.html`).

### Dependency Injection & Feature Flagging
- **`lib/data/repositories/app_repositories.dart`:** Singleton `AppRepositories.instance` defaults to 8 local mock implementations (`AuthRepositoryImpl`, `RidesRepositoryImpl`, `BoardRepositoryImpl`, `ParcelsRepositoryImpl`, `ChatRepositoryImpl`, `WalletRepositoryImpl`, `MapsRepositoryImpl`, `AdminRepositoryImpl`). Calling `useFirebase()` swaps 7 of them to `Firebase*Repository`, leaving `maps` on `MapsRepositoryImpl`.
- **`lib/data/services/firebase_firestore_service.dart:42`:** `FirebaseConfig.useFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: false)`, `projectId = 'mashwar-qatar-2026-ec99d'`, `region = 'europe-west1'`.
- **No Repository Abstraction for Key MVP Domains:**
  - `AlertsProvider` has no repository contract or Firestore implementation (`lib/data/mock_data.dart` only).
  - `ServiceEscrowScreen` (`lib/screens/escrow/service_escrow_screen.dart`) has **no provider and no repository** (`i_escrow_repository.dart` does not exist).
- **Providers Bypass Repositories:** `AuthProvider`, `RidesProvider`, `ParcelsProvider`, `BoardProvider`, and `AdminProvider` read synchronous `MockData` lists at construction time, mutate local lists directly, and fire `.ignore()` calls to repositories without `await`ing errors or hydrating from live Firestore streams.
- **Broken HTTP Layer (`lib/data/services/api_client.dart`, `mashwar_api_client.dart`, `lib/data/api/api_endpoints.dart`):**
  - `ApiClient` imports `dart:io` (`HttpHeaders`, `SocketException`), which is incompatible with Flutter Web compilation if instantiated/invoked in web builds.
  - `ApiEndpoints.baseUrl` points to a non-existent `https://api.mashwar.qa/api/v1`; `MashwarApiClient` only logs requests to memory.

---

## 3. Genuinely Working vs. Simulated / Mocked Features

| Feature Area | Actual Status | Code Evidence & Behavior Observed |
| :--- | :--- | :--- |
| **Bilingual AR/EN UI, RTL/LTR & Theme** | **Working** | `SettingsProvider` + `SharedPreferences` + `AppStrings` dynamically flip locale and `Directionality`. |
| **Responsive Layouts & Maps Visuals** | **Working (Local)** | `QatarLiveMapCanvas` animates Qatar map styles locally; `GoogleMapsService` uses a 22-city Qatar catalog fallback when `GOOGLE_MAPS_API_KEY` is empty (note `_estimateQatarRoute` sums `dLat.abs() + dLng.abs()` Manhattan heuristic rather than geodesic distance). |
| **Landing Page Investor Lead Capture** | **Working (Live Firestore)** | `landing_page/js/firebase-contact.js` writes `investor_inquiries` via Firestore SDK to `mashwar-qatar-2026-ec99d` (allowed unauthenticated by `firestore.rules:1579-1588`) alongside `formsubmit.co` email fallback. `AdminProvider.syncInquiriesFromFirestore()` (`:2422`) reads this collection if authenticated as admin. |
| **Onboarding & Phone / Email Auth** | **Simulated** | `AuthProvider` (`lib/state/auth_provider.dart:16-17`) starts as `AuthStatus.authenticated` with `MockData.currentUser`. `SplashScreen` routes to `WelcomeScreen` regardless. `verifyOtp` (`:151-155`) accepts **any 6-digit string**. `signInWithGoogle` (`:110-130`) copies name/email/avatar onto `MockData.currentUser`. `saveProfile` (`:166-204`) and `submitIdVerification` do not call `AppRepositories.instance.auth`, and `logout()` (`:395`) does not sign out of Firebase Auth. |
| **New User Profile Defaults** | **Mock Leakage** | `UserModel` (`lib/data/models/user_model.dart:54,67-68,73-76`) defaults every constructed user (unless overridden) to `isVerified: true`, `idVerificationStatus: IdVerificationStatus.verified`, `nationalId: '29663401842'`, `walletBalance: 450.0`, `rating: 4.9`, `completedRides: 14`, `completedParcels: 6`. |
| **Wallet & Payments (Fawran / QPay / SkipCash / Apple Pay)** | **Simulated** | `AuthProvider` (`:276-355`) holds 4 hardcoded QAR transactions. `depositWalletFunds` and `withdrawWalletFunds` directly adjust `_user.walletBalance` in memory with no PSP SDK, webhook verification, or `AppRepositories.instance.wallet` persistence. |
| **Bilateral Supply Escrow (`ServiceEscrowScreen`)** | **Simulated** | `lib/screens/escrow/service_escrow_screen.dart` manages `_escrowLocked` (`:38`), `_receiptApproved` (`:39`), and `_escrowReleased` (`:40`) solely via widget `setState()`. Includes a `'Fill 4829'` / `'تعبئة 4829'` quick-fill button (`:1180, :1191`); entering `4829` sets `_escrowReleased = true` (`:68`) without locking/releasing any funds or creating Firestore escrow/transaction records. |
| **Orders & Messages Tabs (`MainNavShell`)** | **Mostly Hardcoded** | `MainNavShell._buildActiveOrdersList` (`:599-826`) renders 4 hardcoded active cards (including a hardcoded `ServiceEscrowScreen` card for `45 QAR + 180 QAR`) alongside `rides.bookedRides` (pre-seeded with `MockData.initialRides.first`) and `parcels.parcels` (pre-seeded with `MockData.activeParcel`). `_buildPastOrdersList` (`:895-1002`) renders 4 static history cards. `_buildMessagesTab` (`:1226-1279`) builds 4 static chat maps (`chat_1`..`chat_4`). |
| **Admin Portal Auth & RBAC** | **Bypassed / Mocked** | `AdminProvider._isLoggedIn` defaults to `true` (`lib/state/admin_provider.dart:308`). `lib/main.dart:87-91` routes `/admin` straight to `AdminShell()` bypassing `AdminLoginScreen`. `AdminLoginScreen` (`lib/screens/admin/admin_login_screen.dart:20-21,47-51,63-70`) prefills `'admin@mashwar.example'` / `'12345678'`, validates `email == 'admin@mashwar.example' && password.length >= 6` locally, and provides `_fillDemoRole` + header switcher calling `AdminProvider.setActiveRole(role)` (`:461`). KPIs, disputes, verifications, escrow ledger, and audit logs use local mock data. |
| **Driver Ride Publish, End Trip, Rating & KYC** | **Simulated** | `PublishRideScreen` does not check `user.isVerified`. `DriverRidesScreen` (`lib/screens/driver/driver_rides_management_screens.dart:1219-1229`) pops the sheet with a SnackBar (`"Trip ended & earnings credited"`) without updating rides/wallet. `RateTripScreen` (`lib/screens/trip/rate_trip_screen.dart:72-88`) simulates a 700ms delay and SnackBar without storing ratings or tips. `IdVerificationScreen` submits string literals (e.g., `'front_id_scanned.jpg'`) with no `image_picker` or `firebase_storage` upload. |
| **Emergency SOS & Account Deletion** | **Simulated** | `EmergencySosSheet` (`lib/screens/safety/safety_screens.dart:364-456`) shows SnackBars (`Calling Qatar MOI Emergency 999...`) without `url_launcher` `tel:` calls or server SOS logs. `DeleteAccountScreen` (`lib/screens/account/account_extra_screens.dart:730-935`) hardcodes `_hasUpcomingRide = false` (`:739`) and calls `AuthProvider.logout()` without deleting Auth or Firestore data. |

---

## 4. Backend & Infrastructure Readiness

### Missing Infrastructure & Packages
1. **No `functions/` directory:** Although `docs/backend/API_AND_FUNCTIONS.md`, `ARCHITECTURE.md`, and `FIREBASE_SETUP.md` specify Cloud Functions (`createRideBooking`, `acceptBoardAdOffer`, `completeRideTrip`, `verifyDriverDocuments`, payment webhook, custom-claim minting), **zero server-side Cloud Functions exist** in the repository.
2. **No `storage.rules` & No Storage SDK:** `storage.rules` is absent; `pubspec.yaml` does not include `firebase_storage` or `cloud_functions` (nor `image_picker`, `url_launcher`, `share_plus`, `geolocator`, `firebase_messaging`, `google_sign_in`).
3. **Minimal `firebase.json`:** Contains only `firestore.rules` and `firestore.indexes.json` — missing `functions`, `storage`, `hosting`, and `emulators` definitions.
4. **Native Firebase & Build Configuration Gaps:**
   - No `android/app/google-services.json` or `ios/Runner/GoogleService-Info.plist` exists.
   - `android/app/build.gradle.kts` does not apply `com.google.gms.google-services` and sets release builds to `signingConfigs.getByName("debug")`.
   - `lib/firebase_options.dart` defines `projectId: 'mashwar-qatar-2026-ec99d'`, commits fallback Web/Android API key `AIzaSyB-wPAJ3Dy4cMkuyaRcnYCh6kn6kk5vzTc`, and contains synthetic-looking native app IDs (`1:820084343406:android:629482019482def`, `1:820084343406:ios:839482019482ghi`, `iosBundleId: 'eg.mashwar.app'`).
   - `ios/Runner/Info.plist` lacks `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and `NSLocation*UsageDescription` keys required by App Store review once KYC/receipt upload/GPS are added.
   - `AppTypography` (`lib/core/constants/app_typography.dart`) downloads `Cairo` fonts at runtime via `google_fonts` with no bundled TTF assets in `pubspec.yaml`.

### Firestore Rules vs. Client Repository Drift (Fails When `USE_FIREBASE=true`)
Even though `firestore.rules` is 1,600 lines covering 19 collections, current Firebase repository implementations will be rejected on real Firestore writes:

1. **`firebase_auth_repository.dart` (`:18-44`):** `sendPhoneOtp` unconditionally returns `true`; `verifyPhoneOtp` skips Firebase Auth OTP verification and directly writes `isVerified: true` via `updateProfile` (rejected by `firestore.rules` because user is unauthenticated and users cannot self-grant `isVerified: true`). Moreover, `firestore.rules:423` & `:694` require `nationalId` length `14..20` (Egypt 14-digit ID), rejecting 11-digit Qatar QIDs (`29663401842`).
2. **`firebase_rides_repository.dart` (`:96-98`):** `bookRide` hardcodes `passengerId: 'usr_me_01'`, `passengerName: 'مستخدم مشوار'`, `passengerPhone: '55123456'` instead of `FirebaseAuth.instance.currentUser?.uid`, and `BookingModel.toJson()` omits required `driverId` (failing `isValidBooking`). `getMyBookedRides` and `getMyDriverRides` ignore user scoping and query `.limit(10)` globally.
3. **`firebase_board_repository.dart` (`:60-74`):** `makeOffer` omits required `driverId` (failing `isValidBoardOffer`), uses hardcoded driver name in `BoardProvider`, and updates `board_ads/{adId}` (`status`, `myOfferPrice`), which `firestore.rules:1113` restricts to `authorId` or `isAdmin()`.
4. **`firebase_parcels_repository.dart` (`:32-66`):** `createParcel` uses `ParcelModel.toJson()` omitting required `senderId` (and `ParcelsProvider` hardcodes `pickupOtp: '4 8 2 1'`). `verifyDeliveryOtp` updates parcel status without validating the OTP; additionally `firestore.rules:723` checks `"+20" + resource.data.receiverPhone`, breaking Qatar `+974` phone numbers.
5. **`firebase_chat_repository.dart` (`:48-51`):** Writes `lastMessageText` on `conversations/{id}`, while `firestore.rules:593` whitelists `lastMessage` (`hasOnlyAllowedFields` denies the write).
6. **`firebase_wallet_repository.dart` (`:16-20, :58, :86`):** `deposit`/`withdraw` attempt direct `.set()` on `wallet_transactions`, forbidden by `firestore.rules:1394` (`allow create, update, delete: if isAdmin()`), and client `PaymentMethodType` (`fawran`, `qpay`, `skipCash`, `applePay`, `cash`) is rejected by `firestore.rules:665` (`['vodafoneCash', 'instapay', 'fawry', 'creditCard', 'cash']`).

### Missing Composite Indexes (`firestore.indexes.json`)
`firestore.indexes.json` defines only **8** indexes (`rides` x2, `board_ads`, `parcels` x2, `bookings`, `wallet_transactions`, `route_alerts`). Missing indexes needed for production queries include:
- `investor_inquiries` (`orderBy('createdAtIso', descending: true)` used in `AdminProvider.syncInquiriesFromFirestore`)
- `conversations` (`participantIds` `array-contains` + `updatedAt` `DESC`)
- `board_ads` (`status` + `type` + `createdAt` `DESC` without city filters)
- `escrow_holds`, `disputes`, `driver_verifications`, `admin_audit_logs` status/time admin queues

### Money Precision Defect
- Backend design docs (`DATABASE_SCHEMA.md`, `API_AND_FUNCTIONS.md`) mandate integer minor units (`*Piastres`), whereas `UserModel.walletBalance`, `WalletTransactionModel.amount`, `AdminEscrowLedgerItem`, and `firestore.rules` store floating-point `double`/`number`, while `RideModel` / `BoardAdModel` / `ParcelModel` store integer QAR.
- **Worksite Supply Requirement:** Standardize strictly on **integer Dirhams/Halalas (`1 QAR = 100 Halalas`, e.g., `*Halalas` / `*Minor`)** across Firestore, Cloud Functions, Escrow ledger, and Dart models to avoid floating-point rounding discrepancies on platform fees and partial refunds.

---

## 5. Market, Documentation & Legal/Compliance Inconsistencies

### 1. Egypt vs. Qatar Split-Brain Across Repository
| Layer | Egypt Artifacts Present | Qatar Artifacts Present |
| :--- | :--- | :--- |
| **Docs (`README.md`, `docs/application-audit.md`, `docs/backend/*.md`)** | 27 governorates, `+20` phones, `EGP`/`Piastres`, `InstaPay`/`Vodafone Cash`/`Fawry`, 14-digit National ID, `components=country:eg`, `Kafr El-Sheikh` | None in root `README.md` or `docs/backend/` |
| **Security Rules (`firestore.rules`)** | `nationalId` length `14..20` (`:423, :694`), `"+20" + receiverPhone` (`:723`), `'vodafoneCash', 'instapay', 'fawry'` (`:665`) | Comments/collections added for escrow/admin corridors |
| **App / Firebase / Identifiers** | `lib/firebase_options.dart` `iosBundleId: 'eg.mashwar.app'`; founder phone `+201007938491` in `landing_page/js/firebase-contact.js`; `GOOGLE_MAPS_SETUP.md` mentions `com.meshwar.mashwar` | `.firebaserc` (`mashwar-qatar-2026-ec99d`), `MockData` & `GoogleMapsService` (8 municipalities / 22 hubs), `QAR`, `+974`, 11-digit QID, `Fawran`/`QPay`/`SkipCash`/`Apple Pay`, Android `applicationId = "com.mashwar.app.mashwar"` |

### 2. Overstated Readiness Documentation
- `docs/backend/IMPLEMENTATION_STATUS.md` marks `firestore.rules`, `DATABASE_SCHEMA.md`, and all 6 Firebase repos as **`PASS`** even though `firestore.rules` has breaking Egypt constraints and repos omit required rule fields.
- `docs/backend/INTERACTIVE_CONTROLS_MATRIX.md` claims mocked controls (`EmergencySosSheet`, `ShareTripSheet`, `WalletScreen`, `ServiceEscrowScreen`) execute live Firestore/Cloud Functions/Storage/`tel:` calls.

### 3. Regulatory, Financial & Trademark Risks
- **Unverified Transport Licensing Claims:** `LegalComplianceScreen` (`lib/screens/account/legal_and_backend_screens.dart:160-167`) states MASHWAR is *"Licensed for inter-area peer-to-peer travel cost sharing in Qatar"* / *"متوافق مع ضوابط النقل الذكي التشاركي"*. Publishing unverified Qatar Ministry of Transport (MoT) licensing claims creates legal/store-rejection exposure. Positioning MVP around **Worksite Supply / B2B material errands & logistics** rather than passenger carpooling reduces passenger-transport licensing risk, provided UI copy removes false licensing claims.
- **Unverified Escrow, Insurance & PSP Claims:** Multiple screens advertise active QCB-regulated payment integrations (`Fawran`, `QPay`, `Himyan`, `SkipCash`, `Apple Pay`), AES-256 encryption, escrow custody, and 2,000 QAR parcel protection before PSP contracts, Qatar Central Bank compliance checks, or backend custody exist.
- **Missing Brand/Trademark Disclaimers:** Code and UI reference third-party brands (`WOQOD`, `Fawran`, `QPay`, `Himyan`, `SkipCash`, `Apple Pay`, `Google`, and `Uber`/`inDrive` in comments) without trademark attribution/non-affiliation notices.
- **Privacy Law Representation Gap:** `DeleteAccountScreen` cites Qatar Personal Data Privacy Law No. 13 of 2016 while performing only a local logout.

---

## 6. Prioritized Security Risk Register

| Severity | Finding | Impact |
| :---: | :--- | :--- |
| **P0** | **Admin Portal Open by Default & Client-Controlled Roles** (`lib/state/admin_provider.dart:308`, `lib/main.dart:87-91`, `admin_login_screen.dart:47-51`) | Anyone hitting `/admin` or using hardcoded `admin@mashwar.example` enters `AdminShell` and can switch `AdminRole` client-side. |
| **P0** | **Auth & OTP Bypass + Demo Verified Balance** (`lib/state/auth_provider.dart:16-17,151-155`, `UserModel` defaults, `firebase_auth_repository.dart:18-44`) | Any 6 digits authenticate; new profiles inherit `450.0` QAR balance, verified status, and fake QID without server verification. |
| **P0** | **Client-Side Wallet & Escrow State Mutation** (`auth_provider.dart:276-355`, `service_escrow_screen.dart:38-68,1180`) | Users can inflate wallet balance and release escrow via UI state or `'Fill 4829'` without server verification or atomic ledger writes. |
| **P0** | **Missing Cloud Functions & Storage Rules** (no `functions/`, no `storage.rules`) | No trusted server enforcement for payments, webhooks, OTP hash checks, custom claims, or QID/receipt image ACLs. |
| **P1** | **Broken Firestore Rules Coverage Across Repos** (`firestore.rules:423,593,665,694,723,1113,1394`) | Real Firestore usage rejects QID (`11` digits), `+974` parcel OTP checks, Qatar PSP methods, chat metadata, board offers, and bookings. |
| **P1** | **Unverified SOS & Driver Verification Gates** (`safety_screens.dart:364-456`, `publish_ride_screen.dart`) | Emergency SOS only shows SnackBars; unverified users can publish driver offers/rides without KYC approval. |
| **P2** | **Committed Firebase Keys, Debug Release Signing & Missing iOS Privacy Keys** (`lib/firebase_options.dart`, `landing_page/js/firebase-contact.js`, `android/app/build.gradle.kts`, `ios/Runner/Info.plist`) | Android release uses debug keystore; Firebase config lacks real native `google-services.json`/`GoogleService-Info.plist` and iOS permissions. |

---

## 7. Recommended MVP Implementation Order (Worksite Supply)

1. **Phase 0 — Environment, Truth & Repo Hygiene**
   - Merge `.gitignore` & untrack `node_modules/` cleanly.
   - Install **Java 21 LTS (or 11+)** and global **`firebase-tools`** (`npm i -g firebase-tools`) so `firebase emulators:start` (`auth`, `firestore`, `functions`, `storage`) runs locally in CI and dev.
   - Archive/update Egypt docs and remove inaccurate `PASS` / MoT-license / active-PSP / insurance assertions from docs and UI copy; align bundle IDs (`com.mashwar.app.mashwar` / iOS Qatar bundle ID) and configure real native Firebase app files if targeting mobile.
2. **Phase 1 — Hardened Auth, QID KYC & Admin Custom Claims**
   - Disable `AuthProvider` auto-authentication (`AuthStatus.unauthenticated`), remove accept-any-6-digits bypass, remove `UserModel` demo defaults (`walletBalanceMinor: 0`, `isVerified: false`, `rating: 0`, empty `nationalId`), and wire real Firebase Phone Auth (`+974`) + `signOut()`.
   - Set `AdminProvider._isLoggedIn = false`, enforce auth guard on `/admin` in `lib/main.dart`, remove hardcoded `'admin@mashwar.example'` / `'12345678'` and client `setActiveRole` switching; gate admin portal strictly behind Firebase Auth ID token custom claims (`request.auth.token.admin == true` / `role`).
   - Add `firebase_storage` + `storage.rules` + `image_picker` so QID uploads and Worksite Supply store receipts upload to private Storage paths with owner/counterparty/admin ACLs.
3. **Phase 2 — Schema, Integer Money (`Halalas`), Rules & Indexes Reconciliation**
   - Migrate all currency fields to integer minor units (`1 QAR = 100 Halalas`, e.g., `walletBalanceHalalas`, `goodsBudgetHalalas`, `deliveryFeeHalalas`, `escrowAmountHalalas`).
   - Update `firestore.rules` for Qatar: 11-digit QID validation (`^[0-9]{11}$`), `+974` phone normalization, Qatar PSP enums (`fawran`, `qpay`, `skipCash`, `applePay`, `cash`), Worksite Supply request/offer/escrow schemas, and `lastMessage` chat rules.
   - Expand `firestore.indexes.json` to cover every active consumer & admin query (`investor_inquiries`, `conversations`, `board_ads`, `escrow_holds`, `disputes`, `driver_verifications`, `admin_audit_logs`).
4. **Phase 3 — `functions/` Server Authority & Bilateral Worksite Supply Escrow**
   - Scaffold `functions/` (Node/TypeScript) with Firestore Emulator integration tests covering:
     - `createWorksiteSupplyOrder` / `acceptSupplyOffer` (locks buyer goods + delivery escrow atomically from verified balance or pending PSP payment intent).
     - `submitPurchaseReceipt` (attaches Storage receipt URL + actual invoice total <= cap, transitions to buyer review / receipt approval).
     - `confirmDeliveryWithOtp` (server-side salted/hashed OTP verification, releases goods cost + delivery fee minus platform commission to courier ledger, writes immutable `wallet_transactions` & `escrow_holds` transition).
     - `openSupplyDispute` & admin resolution callable, plus `adminVerifyDriver` custom-claim & KYC transition.
5. **Phase 4 — Client Wiring & Removal of Hardcoded Prototype Paths**
   - Add `IEscrowRepository` + `FirebaseEscrowRepository` (and Cloud Functions client via `cloud_functions`) and refactor `ServiceEscrowScreen` from widget `setState` to live stream/callable execution.
   - Replace hardcoded active/past order cards and `allChats` in `MainNavShell` with real Firestore-backed Providers; enforce verified-courier gate before accepting Worksite Supply runs; replace `DriverRidesScreen` / `RateTripScreen` / `DeleteAccountScreen` SnackBar mocks with real repository/function calls.
6. **Phase 5 — Regulated PSP, Real Safety & Release Hardening**
   - Integrate a licensed Qatar PSP (e.g., SkipCash / QPay) with server-side webhook signature verification for deposits/escrow funding and compliant payout workflows.
   - Wire `url_launcher` for real `tel:999` SOS & driver calling, bundle `Cairo` TTF fonts for offline/sandbox stability, replace debug release signing in `android/app/build.gradle.kts`, and add `Info.plist` privacy permissions.
