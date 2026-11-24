# MASHWAR — Qatar Worksite Supply MVP Implementation & Verification Report

**Date:** 2026-11-24  
**Branch:** `feat/mvp-worksite-supply`  
**Firebase Project:** `mashwar-qatar-2026-ec99d` (`europe-west1`)  
**Primary Launch Scope:** State of Qatar — B2B / Contractor **Worksite Supply & Field Material Coordination** (`QAR`, integer minor units `1 QAR = 100 dirhams`)

---

## 1. What Was Already Present

Prior to the `feat/mvp-worksite-supply` engineering waves (baseline audited in [`docs/MVP_BASELINE_AUDIT.md`](MVP_BASELINE_AUDIT.md)):
- **Bilingual Flutter UI Shell:** Responsive Arabic (`RTL`) and English (`LTR`) UI built with `Provider` state management, `AppColors` / `AppTypography` design tokens, `QatarLiveMapCanvas` visual corridors, and `91` passing widget/layout tests (`0` analyzer issues).
- **Initial Repository & Rules Skeleton:** `AppRepositories` service locator with 8 contracts (`auth`, `rides`, `board`, `parcels`, `maps`, `chat`, `wallet`, `admin`), 7 initial Firebase repository classes, a 19-collection `firestore.rules` file, 8 composite indexes in `firestore.indexes.json`, and `GoogleMapsService` with a 22-hub / 8-municipality Qatar offline catalog.
- **Standalone Admin Entrypoint & Landing Lead Capture:** `lib/admin_main.dart` web dashboard shell (12 modules), `.github/workflows/mashwar_ci_cd.yml`, `vercel.json` (`/admin` rewrites), and live Firestore `investor_inquiries` lead capture in `landing_page/js/firebase-contact.js`.

---

## 2. What Was Wrong

As documented in [`docs/MVP_BASELINE_AUDIT.md`](MVP_BASELINE_AUDIT.md), the pre-MVP codebase functioned as an interactive UI prototype rather than a production-safe MVP:
1. **No Server-Side Business Authority:** Zero Cloud Functions (`functions/` did not exist) and zero Cloud Storage security rules (`storage.rules` did not exist), despite documentation claiming server-enforced OTPs, wallets, and webhooks.
2. **Mock Leakage & Broken Startup Boundaries:** `FirebaseConfig.useFirebase` defaulted to `false`; `UserModel` defaulted every new user to `walletBalance: 450.0`, `rating: 4.9`, `isVerified: true`, and a hardcoded QID (`29663401842`); `AuthProvider` booted pre-authenticated as `MockData.currentUser` and accepted **any** 6-digit string in `verifyOtp`.
3. **Unprotected Admin Portal (`/admin`):** `AdminProvider._isLoggedIn` defaulted to `true`, `/admin` bypassed login, `AdminLoginScreen` prefilled `admin@mashwar.example` / `12345678`, and a client-side switcher allowed arbitrary `AdminRole` escalation.
4. **Simulated Escrow & Hardcoded Orders:** `ServiceEscrowScreen` toggled `_escrowLocked` / `_escrowReleased` via local `setState()` with a `'Fill 4829'` shortcut; `MainNavShell` rendered hardcoded sample order and chat lists; `AuthProvider` mutated wallet balances in RAM.
5. **Egypt vs. Qatar Split-Brain & Broken Rules:** `README.md`, `docs/backend/*.md`, and `firestore.rules` contained Egyptian constraints (`14..20` char National ID rejecting 11-digit Qatar QIDs, `+20` phones, `EGP`/piastres, `vodafoneCash`/`instapay`/`fawry`, 27 governorates), causing client Firebase repositories to fail rule validation when `USE_FIREBASE=true`.
6. **Floating-Point Money & Repo Hygiene Issues:** Financial balances used `double` instead of integer minor units, generated `node_modules/` files were tracked in Git, and UI/docs made unverified Qatar Ministry of Transport (MoT) and Qatar Central Bank (QCB) licensing claims.

---

## 3. What Was Implemented

Across Waves 0–4 on `feat/mvp-worksite-supply`, the repository was re-engineered into an honest, security-hardened **Qatar Worksite Supply MVP**:
- **Wave 0 — Repo Hygiene & Baseline Audit:** Untracked generated `node_modules/`, hardened `.gitignore` (`functions/node_modules/`, `functions/lib/`, `.env*`, keystores), and recorded the baseline audit (`docs/MVP_BASELINE_AUDIT.md`).
- **Wave 1 — Backend Authority, Security Rules & Indexes:**
  - Created `functions/` (TypeScript, Node.js 20, Firebase Cloud Functions v2 `onCall` in `europe-west1`) implementing 9 transactional handlers, an 11-state `WorkRequest` state machine, constant-time salted SHA-256 6-char handover verification (`5` attempts max, `24h` TTL, single-use), and a 10-scenario `node:test` security suite.
  - Added `storage.rules` (`<= 10 MB`, `image/*`, private KYC & participant-scoped invoice/proof ACLs), wired `firebase.json` (`firestore`, `functions`, `storage`, local `emulators`), expanded `firestore.indexes.json` to 14 composite indexes, and extended `firestore.rules` (2,475 lines) with Worksite Supply Collections `20–29` while preserving Collections `1–19` with Qatar QID/`+974` compatibility.
- **Wave 2 — Environment, Domain Models & Auth Hardening:**
  - Implemented `AppEnvironment` (`lib/core/config/app_environment.dart`) and `.env.example` with strict `USE_DEV_MOCKS` isolation and MVP feature flags (`enableWorksiteSupply = true`; passenger rides, carpooling, commercial cargo, digital wallet, and escrow claims `false`).
  - Built `lib/data/models/worksite_models.dart` (`MoneyMinor` integer QAR minor units, `WorkRequestStatusMachine`, and 8 immutable UTC models) and neutralized `UserModel` + `AuthProvider` defaults (`AuthStatus.unauthenticated`, `UserModel.empty`, real Firebase Email/Password auth + 11-digit QID verification, explicit `UnsupportedError` on unconfigured SMS OTP).
- **Wave 3A — Worksite Repositories, `WorksiteProvider`, Startup Guard & Admin Ops:**
  - Implemented `FirebaseFunctionsCallableClient` (`package:http` + Bearer Firebase ID token), `FirebaseWorksiteRepository`, `FirebaseProviderRepository`, deterministic dev-gated `WorksiteRepositoryImpl` / `ProviderRepositoryImpl`, `WorksiteProvider`, and fail-closed `initializeMashwarStartup()` (`ServiceUnavailableScreen` on non-mock startup failure).
  - Hardened `AdminProvider`, `AdminLoginScreen`, `AdminShell`, and `admin_main.dart` (`_isLoggedIn = false`, `/admin` route guard, Firebase Auth + active `admin_staff/{uid}` server role resolution, `admin_audit_logs`), and built **Module 13 (`AdminWorksiteOpsScreen`)** for 11-digit QID KYC review, manual bank transfer settlement verification, dispute moderation, and audit export.
- **Wave 3B — Focused 4-Tab Customer & Provider Journey:**
  - Built `CreateWorkRequestScreen` (3-step validated form + Quick Reorder prefill), `WorkRequestsFeedScreen` (Qatar municipality/status/budget filters + skeleton/error/empty states), `WorkRequestDetailsScreen` (timeline, offer comparison/acceptance, requester handover code card, approved-provider offer & stage controls, invoice attachment, 6-char handover modal, manual transfer proof, mutual rating, dispute modal, contextual `ChatScreen`), and `ProviderProfileScreen` (11-digit QID KYC, approval badge, saved worksites, real stats).
  - Updated `MainNavShell` (4 focused MVP tabs: `Home`, `Requests`, `My Activity`, `Account`), `HomeScreen` (`"شنو تحتاج ينجز اليوم؟"` / `"What do you need done today?"` with zero fake counters/balances/cars), `WelcomeScreen`, and `EmailInputScreen`.
- **Wave 3C & Wave 4 — Qatar Documentation Alignment & Independent Verification:**
  - Aligned `README.md` and all 9 `docs/backend/*.md` specifications with the Qatar Worksite Supply MVP (zero stale Egypt references) and executed full static analysis, unit/widget tests, Cloud Functions tests, production web release compilation, and Android release auditing.

---

## 4. Architecture Changes

1. **Compile-Time Environment Resolution (`AppEnvironment`):**
   - Resolves `AppFlavor` (`development`, `staging`, `production`), `USE_FIREBASE`, and `USE_DEV_MOCKS`.
   - Enforces `resolveUseDevMocks`: dev mocks are **mathematically impossible** to enable when `APP_ENV != 'development'` or `USE_FIREBASE == true`.
2. **Fail-Closed Application Boot (`lib/main.dart` & `lib/screens/splash_screen.dart`):**
   - `initializeMashwarStartup()` initializes Firebase and `AppRepositories.instance.useFirebase()` when `USE_FIREBASE=true`, and rejects non-development builds without Firebase by rendering `ServiceUnavailableScreen` with Retry.
   - `SplashScreen` restores Firebase sessions via `AuthProvider.restoreSession()` and routes unauthenticated users to `WelcomeScreen`.
3. **Web-Safe Cloud Functions v2 Bridge (`FirebaseFunctionsCallableClient`):**
   - Located in `lib/data/services/firebase_firestore_service.dart`, invoking `europe-west1` v2 `onCall` endpoints via `package:http` with `Authorization: Bearer <ID_TOKEN>` and mapping server errors into bilingual `WorksiteRepositoryException` objects (avoiding `dart:io` Web incompatibilities).
4. **Deferred Regulated Capabilities:**
   - `enablePassengerRides`, `enableCarpooling`, `enableCommercialCargo`, `enableDigitalWallet`, and `enableEscrowClaims` remain `false` in `AppEnvironment`, keeping legacy prototype modules out of the active customer MVP navigation while preserving source compatibility.

---

## 5. Database Collections

Defined and enforced in [`firestore.rules`](../firestore.rules) (`2,475` lines) with `14` composite indexes in [`firestore.indexes.json`](../firestore.indexes.json):

### Preserved Platform & Governance Collections (`1–19`)
| # | Collection | Phase 1 Status | Role |
| :---: | :--- | :---: | :--- |
| 1 | `users/{userId}` (+ `private/{docId}` & `users_public/{userId}`) | **Active** | User profiles (neutral zero defaults, 11-digit QID & `+974` support) + private `SavedWorksite` docs. |
| 2–6, 8–10, 15 | `rides`, `board_ads`, `offers`, `parcels`, `bookings`, `route_alerts`, `wallet_transactions`, `driver_verifications`, `escrow_holds` | Deferred | Preserved intact behind `AppEnvironment` MoT/QCB feature flags (`false`). |
| 7 | `conversations/{conversationId}` & `messages/{messageId}` | **Active** | Contextual participant-only chat between requester and assigned provider. |
| 11 | `admin_audit_logs/{logId}` | **Active** | Immutable append-only audit trail (`allow update, delete: if false`). |
| 12–14, 16–17 | `platform_config`, `service_catalog`, `corridors`, `disputes`, `feature_flags` | **Active (Admin)** | Operational configs, Qatar corridors, and dispute records. |
| 18 | `admin_staff/{staffId}` | **Active** | Server-side staff RBAC directory (`uid`, `email`, `role`, `isActive`). |
| 19 | `investor_inquiries/{inquiryId}` | **Active** | Public landing-page lead capture synced into Admin Portal. |

### New Worksite Supply MVP Collections (`20–29`)
| # | Collection | Purpose & Key Security Invariant |
| :---: | :--- | :--- |
| 20 | `business_profiles/{uid}` | Contractor/company requester profile; owner cannot modify `ratingAvg`/`ratingCount`; `list` restricted to owner/admin. |
| 21 | `provider_profiles/{uid}` | Supply runner profile (no QID PII); owner creates with `approvalStatus == 'pending'` and **cannot** self-approve or alter stats. |
| 22 | `provider_verifications/{uid}` | Private 11-digit QID & KYC media submission; readable **only** by `isOwner(uid) || isAdmin()`. |
| 23 | `work_requests/{requestId}` | Worksite supply order (`budgetMinor` int `> 0`, 11 snake_case statuses, `cash_on_delivery` / `bank_transfer_manual`); client `delete` forbidden; client direct `completed` forbidden. |
| 24 | `work_offers/{offerId}` | Quotes from approved providers (`requesterId != providerId`, positive int minor amounts); readable by offer provider, request owner, or admin. |
| 25 | `work_request_secrets/{requestId}` | Salted SHA-256 handover hash, salt, `attemptsRemaining` (`5`), `expiresAtUtc` (`+24h`), `usedAtUtc` — **`allow read, write: if false;`** (Admin SDK / Cloud Functions only). |
| 26 | `work_request_handover_view/{requestId}` | Requester-only plaintext handover code projection (`requesterId == auth.uid`; **`allow write: if false;`**). |
| 27 | `request_events/{eventId}` | Append-only lifecycle event timeline readable by request participants or admin (`allow update, delete: if false`). |
| 28 | `ratings/{ratingId}` | Post-completion mutual 1–5 star rating keyed by `${requestId}_${fromUserId}` (`allow update, delete: if false`). |
| 29 | `notifications/{notificationId}` | Server-created user notifications; owner can update **only** `isRead`. |

---

## 6. Authentication Configuration

1. **Customer & Provider Authentication (`FirebaseAuthRepository` + `AuthProvider`):**
   - Primary active flow: **Email + Password** (`signInWithEmailAndPassword`, `createUserWithEmailAndPassword`, `sendPasswordResetEmail`, `signOut`) with automatic session restoration (`restoreSession()`) and neutral Firestore `users/{uid}` initialization.
   - Provider KYC (`submitNationalId` / `submitProviderVerification`) validates **11-digit Qatar QID** (`^[0-9]{11}$`) and writes pending verification records without granting `isVerified` or `approved` client-side.
   - Phone SMS OTP (`sendPhoneOtp` / `verifyPhoneOtp`) explicitly throws `UnsupportedError('Phone OTP requires configured SMS provider')` outside dev-mock mode, and UI screens explain SMS unavailability honestly instead of faking OTP verification.
2. **Admin Staff Authentication (`AdminProvider` + `AdminLoginScreen` + `AdminShell`):**
   - `AdminProvider._isLoggedIn` defaults to `false`; navigating to `/admin` (embedded or `lib/admin_main.dart`) renders `AdminLoginScreen` until authenticated.
   - `signInStaffWithFirebase(email, password)` signs in via `FirebaseAuth`, verifies an active document in `admin_staff/{uid}` (`isActive == true`), binds `_activeRole` strictly from the server-stored `role` (`superAdmin`, `reviewAdmin`, `supportAdmin`, `compliance`, `operations`), and logs `admin_audit_logs`.
   - Hardcoded `admin@mashwar.example` / `12345678` credentials were removed; demo role quick-fill and role-switcher controls are hidden unless `AppEnvironment.useDevMocks` is `true`.
3. **Dev-Only Mock Separation:**
   - Unit/widget tests use explicit `@visibleForTesting` constructors (`AuthProvider.forTesting(...)`, `AdminProvider.forTesting(...)`), keeping production defaults unauthenticated.

---

## 7. Security Changes

- **Server-Enforced State Machine (`functions/src/stateMachine.ts` & `handlers.ts`):**
  - Enforces `open -> offer_received -> offer_selected -> accepted -> in_progress -> picked_up -> in_transit -> delivered_pending_confirmation -> completed` (plus guarded `cancelled` before `picked_up` and `disputed` during active fulfillment).
  - Blocks unauthenticated access, self-bidding, unapproved providers, foreign-request tampering, and requester self-completion.
- **Salted Constant-Time SHA-256 Handover Verification (`functions/src/handoverCrypto.ts`):**
  - Mints 6-character codes from unambiguous 32-char alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` via `crypto.randomBytes(6)` (zero modulo bias) with a 128-bit hex salt (`SHA-256(salt + ':' + code)`).
  - Verifies via `crypto.timingSafeEqual`, persists `attemptsRemaining - 1` on mismatch (`maxAttempts: 5`), enforces 24-hour expiry (`expiresAtUtc`), and stamps `usedAtUtc` atomically so codes are strictly single-use.
- **Integer QAR `MoneyMinor` & Payment Settlement Immutability:**
  - Zero `double` currency fields in MVP models or Cloud Functions (`1 QAR = 100 dirhams`).
  - `recordPaymentStatus` and `firestore.rules` enforce `unpaid -> transfer_proof_submitted -> verified_settled`, forbidding forged initial payment states and blocking any overwrite once `verified_settled`.
  - `AuthProvider` blocks local `depositWalletFunds` / `withdrawWalletFunds` while `enableDigitalWallet == false`.
- **Cloud Storage Rules (`storage.rules`):**
  - Default-deny root rule, authenticated access, `<= 10 MB` cap, `image/*` MIME validation, owner/admin-only `/provider_verifications/{uid}/{file}`, and participant-scoped `/work_requests/{requestId}/{reference|invoices|payment_proofs}/{file}`.
- **Secret & Artifact Hygiene:**
  - Verified zero `.env`, `google-services.json`, `GoogleService-Info.plist`, service-account keys, keystores, or `node_modules` / `functions/lib` build artifacts tracked in Git.

---

## 8. Screens Changed

### Newly Created Screens (`5` screens)
- `lib/screens/worksite/create_work_request_screen.dart` — 3-step validated QAR supply request wizard + saved worksite picker + Quick Reorder draft prefill.
- `lib/screens/worksite/work_requests_feed_screen.dart` — Filterable Qatar worksite supply feed (municipality/area, status, budget) with skeleton, retry, and empty states.
- `lib/screens/worksite/work_request_details_screen.dart` — Request timeline, offer comparison/acceptance, requester handover code view, manual bank transfer proof upload, approved-provider offer & fulfillment controls, invoice URL attachment, 6-char handover verification modal, mutual rating modal, dispute modal, and contextual `ChatScreen` launch.
- `lib/screens/worksite/provider_profile_screen.dart` — Provider/business profile editor, 11-digit QID verification submission, real approval status badge, saved worksites manager, and completed job metrics.
- `lib/screens/admin/admin_worksite_ops_screen.dart` — Enterprise Admin Module `13` (Tab A: 11-digit QID KYC review; Tab B: payment settlement verification & dispute moderation; Tab C: privileged `admin_audit_logs` filter & JSON export).

### Modified Entrypoints & Existing Screens (`8` files)
- `lib/main.dart` — `initializeMashwarStartup()`, `ServiceUnavailableScreen` fail-closed error UI with Retry, `WorksiteProvider` registration, and `AuthProvider.restoreSession()` wiring.
- `lib/admin_main.dart` — Guarded standalone admin web entrypoint (`admin.isLoggedIn ? AdminShell() : AdminLoginScreen()`).
- `lib/screens/splash_screen.dart` — Real session restoration routing (`WelcomeScreen` when unauthenticated; `MainNavShell` only when authenticated) and Qatar Worksite Supply branding.
- `lib/screens/main_nav_shell.dart` — Focused 4-tab MVP navigation (`Home`, `Requests`, `My Activity` backed by real `WorksiteProvider` data, `Account` with Provider Profile/Legal/Logout) when `enablePassengerRides == false`.
- `lib/screens/home/home_screen.dart` — Task-first `"شنو تحتاج ينجز اليوم؟"` / `"What do you need done today?"` hub with primary Create/Browse CTAs, saved worksite selector, real active/recent requests, and 1-tap Quick Reorder (zero fake live counters, balances, or moving cars).
- `lib/screens/auth/welcome_screen.dart` — Real Email+Password entry, `AppEnvironment.useDevMocks`-gated demo shortcut, and clear SMS-unavailable guidance.
- `lib/screens/auth/email_input_screen.dart` — Real `loginWithEmail`, `registerWithEmail`, and `sendPasswordReset` form with validation and error feedback.
- `lib/screens/admin/admin_login_screen.dart` & `lib/screens/admin/admin_shell.dart` — Removed prefilled `admin@mashwar.example`/`12345678`, enforced `AdminShell` login guard, hid client role switchers outside dev-mock mode, and wired Module `13` routing + `pendingVerificationsCount` badge.

---

## 9. Files Created

Verified directly from `git diff --name-status c444e6d..HEAD` on `feat/mvp-worksite-supply` (`31` new files created across configuration, backend, domain, repositories, state, UI, tests, and audit/report documentation):

### Configuration, Security Rules & Cloud Functions (`11` files)
- `.env.example`
- `storage.rules`
- `functions/package.json`
- `functions/package-lock.json`
- `functions/tsconfig.json`
- `functions/src/types.ts`
- `functions/src/stateMachine.ts`
- `functions/src/handoverCrypto.ts`
- `functions/src/store.ts`
- `functions/src/handlers.ts`
- `functions/src/index.ts`

### Flutter Config, Domain Models, Repositories & State (`9` files)
- `lib/core/config/app_environment.dart`
- `lib/data/models/worksite_models.dart`
- `lib/data/repositories/contracts/i_worksite_repository.dart`
- `lib/data/repositories/contracts/i_provider_repository.dart`
- `lib/data/repositories/implementations/worksite_repository_impl.dart`
- `lib/data/repositories/implementations/provider_repository_impl.dart`
- `lib/data/repositories/implementations/firebase/firebase_worksite_repository.dart`
- `lib/data/repositories/implementations/firebase/firebase_provider_repository.dart`
- `lib/state/worksite_provider.dart`

### Flutter Customer & Admin UI Screens (`5` files)
- `lib/screens/worksite/create_work_request_screen.dart`
- `lib/screens/worksite/work_requests_feed_screen.dart`
- `lib/screens/worksite/work_request_details_screen.dart`
- `lib/screens/worksite/provider_profile_screen.dart`
- `lib/screens/admin/admin_worksite_ops_screen.dart`

### Automated Test Suites & Audit/Implementation Reports (`6` files)
- `functions/test/backend_security.test.mjs`
- `test/mvp_models_and_auth_test.dart`
- `test/mvp_worksite_provider_and_repo_test.dart`
- `test/mvp_worksite_ui_test.dart`
- `docs/MVP_BASELINE_AUDIT.md`
- `docs/MVP_IMPLEMENTATION_REPORT.md`

*(Note: Comparing further back to `b76cbaa..HEAD` additionally encompasses earlier repository additions such as `.firebaserc`, `.github/workflows/mashwar_ci_cd.yml`, `vercel.json`, `web/health.json`, `lib/firebase_options.dart`, `docs/backend/*.md`, `lib/screens/admin/admin_{corridors_geo,devops_sre,escrow_finance,inquiries,services_catalog}_screen.dart`, and `test/{admin_enterprise_devops,firebase_repositories,uber_live_map_and_onboarding,universal_services_and_escrow}_test.dart`, while removing tracked root `node_modules/`.)*

---

## 10. Tests Actually Executed

All metrics below were independently executed and verified on Windows PowerShell 5.1 (`Flutter 3.47.9`, `Node.js v24.19.0`) against merged `HEAD 1338661`:

| Check / Suite | Exact Command | Exit Code | Wall / Runner Time | Observed Result |
| :--- | :--- | :---: | :---: | :--- |
| **Flutter Dependencies** | `flutter pub get` | `0` | `4.55s` | Resolved cleanly (`0` semantic diff). |
| **Dart Static Analysis** | `flutter analyze` | `0` | `15.45s` (`7.8s` analyzer) | **`No issues found!`** (`0` errors, `0` warnings). |
| **Flutter Unit, Repo & Widget Suite** | `flutter test` | `0` | `58.65s` (`00:43` runner) | **`129 / 129` passed, `0` failed** (`+129: All tests passed!`). |
| **Cloud Functions TypeScript Build** | `npm run build` (`tsc` in `functions/`) | `0` | `7.56s` | Compiled cleanly (`0` tracked artifacts in `functions/lib/` or `node_modules/`). |
| **Cloud Functions Security Suite** | `npm test` (`node --test test/backend_security.test.mjs`) | `0` | `7.76s` (`343.18ms` runner) | **`10 / 10` passed, `0` failed** covering crypto, auth, state machine, handover attempts/TTL/reuse, settlement immutability, ratings, and admin RBAC/audits. |
| **Firebase Local Emulator Rules Tests** | `firebase emulators:exec ...` | **NOT RUN** | — | **Blocked on host:** `java` (JRE/JDK) and global `firebase` CLI (`firebase-tools`) are absent in `PATH` on this workstation. |

---

## 11. Build Results

### Production Web Release Bundle (`flutter build web --release`)
- **Command:** `flutter build web --release`
- **Exit Code:** `0` (`98.21s` wall / `93.6s` compile — `√ Built build\web`, MaterialIcons tree-shaken `97.0%`).
- **Verified Output Artifacts:** `build/web/index.html` (`1,737 B`), `build/web/main.dart.js` (`4,725,265 B`), `flutter_bootstrap.js`, `manifest.json`, `health.json`, `vercel.json`. (`build/` remains untracked per `.gitignore`.)

### Android Release Configuration Audit
- **Verified Present:**
  - `android/app/src/main/AndroidManifest.xml`: Declares `android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE`; uses `flutterEmbedding="2"`.
  - `android/app/build.gradle.kts` & `android/settings.gradle.kts`: `namespace` and `applicationId = "com.mashwar.app.mashwar"`, `minSdk` / `targetSdk` / `compileSdk` bound to Flutter SDK versions, Java/Kotlin `JVM_17`, AGP `9.1.0`, Kotlin `2.4.0`.
- **Native Release Blockers Identified:**
  - `android/app/build.gradle.kts:36` still signs `release` builds with `signingConfigs.getByName("debug")` (`android/key.properties` and `android/app/proguard-rules.pro` are not yet present).
  - `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` are not yet provisioned (`lib/firebase_options.dart:73` still holds placeholder `iosBundleId: 'eg.mashwar.app'` until `flutterfire configure` is run for Qatar mobile).

---

## 12. Remaining Blockers

1. **Local JVM Firebase Emulator Execution:** Requires installing **Java 11+ (`Java 21 LTS`)** and global **`firebase-tools`** (`npm i -g firebase-tools`) on the host machine to execute live `firestore.rules` and `storage.rules` emulator integration tests (`firebase emulators:start` / `emulators:exec`).
2. **Phone SMS OTP Provider (`+974`):** `FirebaseAuthRepository.sendPhoneOtp` / `verifyPhoneOtp` intentionally throw `UnsupportedError` until Firebase Phone Auth billing/quota or a Qatar SMS gateway is configured (Email + Password authentication is fully operational).
3. **Native Binary Media Upload & OS Intents:** Adding `firebase_storage`, `image_picker`, and `url_launcher` (`tel:999`) to `pubspec.yaml`—plus a server-side `deleteUserAccount` Cloud Function—is required for native camera uploads, emergency phone dialing, and full server-side account erasure.
4. **Native Mobile Store Packaging:** Requires running `flutterfire configure` (`com.mashwar.app.mashwar` / `qa.mashwar.app`) to generate real `google-services.json` and `GoogleService-Info.plist`, configuring a production Android upload keystore (`key.properties`), and adding camera/photo usage descriptions to `ios/Runner/Info.plist`.
5. **Legal, Trademark & Regulatory Clearance:** Independent Qatar MoCI trademark clearance for **MASHWAR / مشوار** is required prior to commercial launch; Qatar MoT licensing and QCB licensed-PSP/escrow approval remain prerequisites before enabling any deferred mobility or wallet flags.

---

## 13. Required Environment Variables

Defined in [`.env.example`](../.env.example) and read via `--dart-define` / `--dart-define-from-file` in [`lib/core/config/app_environment.dart`](../lib/core/config/app_environment.dart) and [`lib/data/services/firebase_firestore_service.dart`](../lib/data/services/firebase_firestore_service.dart):

| Variable | Required | Default | Description |
| :--- | :---: | :--- | :--- |
| `APP_ENV` | Yes | `development` | Runtime flavor: `development` \| `staging` \| `production`. |
| `USE_FIREBASE` | Yes | `false` | Enables Firebase Auth, Cloud Firestore & Cloud Functions v2 repositories (`true` required in `staging`/`production`). |
| `USE_DEV_MOCKS` | No | `false` | Enables dev-only mock auth & sample Qatar data (**only** honored when `APP_ENV=development` and `USE_FIREBASE=false`). |
| `FIREBASE_PROJECT_ID` | Yes (Cloud) | `mashwar-qatar-2026-ec99d` | Target Firebase project ID. |
| `FIREBASE_REGION` | Yes (Cloud) | `europe-west1` | Cloud Functions v2 deployment region. |
| `FIREBASE_WEB_API_KEY` | Yes (Web) | Placeholder fallback | Restricted Firebase Web client API key. |
| `FIREBASE_ANDROID_API_KEY` | Yes (Android) | Placeholder fallback | Restricted Firebase Android client API key. |
| `FIREBASE_IOS_API_KEY` | Yes (iOS) | Placeholder fallback | Restricted Firebase iOS client API key. |
| `GOOGLE_MAPS_API_KEY` | Optional | `''` | Restricted Google Maps key (`country:qa`); falls back to 22-hub Qatar offline catalog when empty. |
| `FUNCTIONS_EMULATOR_HOST` | Optional | `''` | Local Functions Emulator host (`127.0.0.1:5001`). |
| `FUNCTIONS_BASE_URL` | Optional | `''` | Custom Cloud Functions v2 base URL override. |

---

## 14. Local Development Instructions

Using Windows PowerShell 5.1 (chain commands with `;`):

```powershell
# 1. Install Flutter & Cloud Functions dependencies
flutter pub get
Push-Location functions; npm install; npm run build; npm test; Pop-Location

# 2. Run Customer App in Local Dev-Mock Mode (deterministic Qatar pilot data)
flutter run -d chrome --dart-define=APP_ENV=development --dart-define=USE_FIREBASE=false --dart-define=USE_DEV_MOCKS=true

# 3. Run Standalone Admin Portal in Local Dev-Mock Mode (Module 13 Worksite Ops)
flutter run -t lib/admin_main.dart -d chrome --dart-define=APP_ENV=development --dart-define=USE_FIREBASE=false --dart-define=USE_DEV_MOCKS=true

# 4. Run against Local Firebase Emulators (once Java 21 LTS + firebase-tools are installed)
firebase emulators:start --only auth,firestore,functions,storage
flutter run -d chrome --dart-define=APP_ENV=development --dart-define=USE_FIREBASE=true --dart-define=FUNCTIONS_EMULATOR_HOST=127.0.0.1:5001
```

---

## 15. Staging Deployment Instructions

1. **Authenticate & Select Project:**
   ```powershell
   firebase login
   firebase use mashwar-qatar-2026-ec99d
   ```
2. **Build & Deploy Backend Rules, Indexes, Storage & Cloud Functions v2:**
   ```powershell
   Push-Location functions; npm ci; npm run build; npm test; Pop-Location
   firebase deploy --only firestore:rules,firestore:indexes,storage,functions
   ```
3. **Provision Initial Admin Staff Record:**
   - Create staff account in Firebase Authentication, set custom claim `{ "admin": true, "role": "superAdmin" }`, and create `admin_staff/{uid}` (`isActive: true`, `role: "superAdmin"`).
4. **Configure Storage Bucket CORS:**
   - Apply `cors.json` to `gs://mashwar-qatar-2026-ec99d.firebasestorage.app` allowing staging/production web origins.
5. **Compile Staging Web Bundles (Fail-Closed Mode, Zero Dev Mocks):**
   ```powershell
   flutter build web --release --base-href / --dart-define=APP_ENV=staging --dart-define=USE_FIREBASE=true --dart-define-from-file=.env.staging
   flutter build web --release -t lib/admin_main.dart --base-href /admin/ -o build/web/admin --dart-define=APP_ENV=staging --dart-define=USE_FIREBASE=true --dart-define-from-file=.env.staging
   ```

---

## 16. Remaining Work Before Public Release & Evidence Matrix

### Pre-Launch Release Checklist
- [ ] Install Java 21 LTS + `firebase-tools` in CI and run `firestore.rules` + `storage.rules` emulator test suites on every PR.
- [ ] Complete Qatar MoCI trademark search/registration for **MASHWAR / مشوار** and legal review of pilot Terms & Privacy Policy (Qatar PDPL Law No. 13 of 2016).
- [ ] Configure native Firebase apps via `flutterfire configure` (`com.mashwar.app.mashwar` & `qa.mashwar.app`), add Android release keystore signing (`key.properties`), and populate iOS `Info.plist` permission strings.
- [ ] Add `firebase_storage` + `image_picker` for direct device KYC/invoice uploads, `url_launcher` for `tel:999`, and a server-side `deleteUserAccount` callable.
- [ ] Provision a `+974` SMS OTP provider (if phone sign-in is desired alongside Email/Password).
- [ ] Keep `enablePassengerRides`, `enableCarpooling`, `enableCommercialCargo`, `enableDigitalWallet`, and `enableEscrowClaims` set to `false` until respective Qatar MoT and QCB licenses/partnerships are obtained.

### Feature-to-Code-&-Test Evidence Matrix

| MVP Capability / Invariant | Implementation Files | Server / Security Enforcement | Automated Test Evidence |
| :--- | :--- | :--- | :--- |
| **Environment Flavors & Fail-Closed Startup** | `lib/core/config/app_environment.dart`, `lib/main.dart`, `.env.example` | `resolveUseDevMocks` blocks mocks in staging/prod/Firebase; `ServiceUnavailableScreen` | `test/mvp_models_and_auth_test.dart`, `test/mvp_worksite_provider_and_repo_test.dart` |
| **Neutral User Defaults & Email/Password Auth** | `lib/data/models/user_model.dart`, `lib/state/auth_provider.dart`, `lib/data/repositories/implementations/firebase/firebase_auth_repository.dart`, `lib/screens/auth/{welcome,email_input}_screen.dart` | `firestore.rules` (`users/{uid}` blocks self-verify & balance edits); `sendPhoneOtp` throws `UnsupportedError` | `test/mvp_models_and_auth_test.dart`, `test/email_auth_test.dart`, `test/mvp_worksite_ui_test.dart` |
| **Integer QAR `MoneyMinor` (`1 QAR = 100 dirhams`)** | `lib/data/models/worksite_models.dart` | `functions/src/handlers.ts` (`requirePositiveInt` / `requireNonNegativeInt`), `firestore.rules` (`is int`) | `test/mvp_models_and_auth_test.dart`, `functions/test/backend_security.test.mjs` |
| **3-Step Worksite Request Creation & Quick Reorder** | `lib/screens/worksite/create_work_request_screen.dart`, `lib/state/worksite_provider.dart`, `lib/data/repositories/implementations/{worksite_repository_impl,firebase/firebase_worksite_repository}.dart` | `functions/src/handlers.ts` (`createWorkRequest`), `firestore.rules` (`work_requests` create rule) | `test/mvp_worksite_ui_test.dart`, `test/mvp_worksite_provider_and_repo_test.dart`, `functions/test/backend_security.test.mjs` |
| **Qatar Feed Filtering & Empty/Error/Retry States** | `lib/screens/worksite/work_requests_feed_screen.dart`, `lib/state/worksite_provider.dart`, `firestore.indexes.json` | `firestore.rules` (`work_requests` signed-in read) | `test/mvp_worksite_ui_test.dart`, `test/mvp_worksite_provider_and_repo_test.dart` |
| **Approved-Provider Offer Submission & Selection** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/state/worksite_provider.dart` | `functions/src/handlers.ts` (`submitWorkOffer`, `acceptWorkOffer`), `firestore.rules` (`isApprovedProvider`, no self-bid) | `test/mvp_worksite_ui_test.dart`, `test/mvp_worksite_provider_and_repo_test.dart`, `functions/test/backend_security.test.mjs` |
| **Linear Fulfillment Stages & Store Invoice Proof** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/data/models/worksite_models.dart` (`WorkRequestStatusMachine`) | `functions/src/stateMachine.ts`, `handlers.ts` (`transitionWorkRequestStatus`), `storage.rules` (`/invoices/`) | `test/mvp_worksite_ui_test.dart`, `test/mvp_models_and_auth_test.dart`, `functions/test/backend_security.test.mjs` |
| **6-Char Salted SHA-256 Single-Use Handover** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/data/repositories/implementations/worksite_repository_impl.dart` | `functions/src/handoverCrypto.ts`, `handlers.ts` (`verifyHandoverAndComplete`), `firestore.rules` (`work_request_secrets` `false`, `work_request_handover_view` owner-only) | `functions/test/backend_security.test.mjs`, `test/mvp_worksite_provider_and_repo_test.dart`, `test/mvp_worksite_ui_test.dart` |
| **11-Digit Qatar QID Provider Onboarding & Saved Worksites** | `lib/screens/worksite/provider_profile_screen.dart`, `lib/data/repositories/implementations/firebase/firebase_provider_repository.dart` | `firestore.rules` (`provider_profiles` `pending` create, `provider_verifications` owner/admin read), `storage.rules` | `test/mvp_models_and_auth_test.dart`, `test/mvp_worksite_provider_and_repo_test.dart`, `test/mvp_worksite_ui_test.dart` |
| **Post-Completion Mutual Ratings & Disputes** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/state/worksite_provider.dart` | `functions/src/handlers.ts` (`submitRequestRating`, `transitionWorkRequestStatus`), `firestore.rules` (`ratings/${requestId}_${uid}`) | `functions/test/backend_security.test.mjs`, `test/mvp_worksite_provider_and_repo_test.dart` |
| **Manual Bank Transfer Proof & Settlement Immutability** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/screens/admin/admin_worksite_ops_screen.dart` | `functions/src/stateMachine.ts` (`assertPaymentStatusTransition`), `handlers.ts` (`recordPaymentStatus`, `adminModerateWorkRequest`) | `functions/test/backend_security.test.mjs`, `test/admin_enterprise_devops_test.dart` |
| **Guarded Admin Portal & Module 13 Worksite Ops** | `lib/admin_main.dart`, `lib/screens/admin/{admin_login_screen,admin_shell,admin_worksite_ops_screen}.dart`, `lib/state/admin_provider.dart` | `admin_staff/{uid}` server role lookup, `functions/src/handlers.ts` (`adminReviewProvider`, `adminModerateWorkRequest`), `admin_audit_logs` | `test/admin_enterprise_devops_test.dart`, `test/admin_web_test.dart`, `functions/test/backend_security.test.mjs` |
| **Focused 4-Tab MVP UI & Deferred MoT/QCB Services** | `lib/screens/main_nav_shell.dart`, `lib/screens/home/home_screen.dart`, `lib/core/config/app_environment.dart` | Feature flags (`enablePassengerRides = false`, `enableDigitalWallet = false`, `enableEscrowClaims = false`) | `test/mvp_worksite_ui_test.dart`, `test/backend_readiness_and_screens_test.dart`, `test/universal_services_and_escrow_test.dart` |
