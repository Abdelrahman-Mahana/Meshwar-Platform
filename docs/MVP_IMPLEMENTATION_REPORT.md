# MASHWAR — Qatar Worksite Supply MVP Implementation & Verification Report

**Date:** 2026-11-25  
**Branch:** `feat/mvp-worksite-supply`  
**Firebase Project:** `mashwar-qatar-2026-ec99d` (`europe-west1`)  
**Registered Apps:** Web (`1:820084343406:web:ad6ce9779a06584bd35c7f`), Android (`com.mashwar.app.mashwar` — `1:820084343406:android:a9e464e38a988eddd35c7f`), iOS (`qa.mashwar.app` — `1:820084343406:ios:5073f983643cc020d35c7f`)  
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

Across Waves 0–5 on `feat/mvp-worksite-supply`, the repository was re-engineered into an honest, security-hardened **Qatar Worksite Supply MVP**:
- **Wave 0 — Repo Hygiene & Baseline Audit:** Untracked generated `node_modules/`, hardened `.gitignore` (`functions/node_modules/`, `functions/lib/`, `.env*`, keystores), and recorded the baseline audit (`docs/MVP_BASELINE_AUDIT.md`).
- **Wave 1 — Backend Authority, Security Rules & Indexes:**
  - Created `functions/` (TypeScript, Node.js 20, Firebase Cloud Functions v2 `onCall` in `europe-west1`) implementing transactional handlers, an 11-state `WorkRequest` state machine, constant-time salted SHA-256 6-char handover verification (`5` attempts max, `24h` TTL, single-use), and a `node:test` security suite.
  - Added `storage.rules` (`<= 10 MB`, `image/*`, private KYC & participant-scoped invoice/proof ACLs), wired `firebase.json` (`firestore`, `functions`, `storage`, local `emulators`), expanded `firestore.indexes.json` to 14 composite indexes, and extended `firestore.rules` (`2,344` lines after Wave 5 AST expression-budget optimization) with Worksite Supply Collections `20–29` while preserving Collections `1–19` with Qatar QID/`+974` compatibility.
- **Wave 2 — Environment, Domain Models & Auth Hardening:**
  - Implemented `AppEnvironment` (`lib/core/config/app_environment.dart`) and `.env.example` with strict `USE_DEV_MOCKS` isolation and MVP feature flags (`enableWorksiteSupply = true`; passenger rides, carpooling, commercial cargo, digital wallet, and escrow claims `false`).
  - Built `lib/data/models/worksite_models.dart` (`MoneyMinor` integer QAR minor units, `WorkRequestStatusMachine`, and 8 immutable UTC models) and neutralized `UserModel` + `AuthProvider` defaults (`AuthStatus.unauthenticated`, `UserModel.empty`, real Firebase Email/Password auth + 11-digit QID verification).
- **Wave 3A — Worksite Repositories, `WorksiteProvider`, Startup Guard & Admin Ops:**
  - Implemented `FirebaseFunctionsCallableClient` (`package:http` + Bearer Firebase ID token), `FirebaseWorksiteRepository`, `FirebaseProviderRepository`, deterministic dev-gated `WorksiteRepositoryImpl` / `ProviderRepositoryImpl`, `WorksiteProvider`, and fail-closed `initializeMashwarStartup()` (`ServiceUnavailableScreen` on non-mock startup failure).
  - Hardened `AdminProvider`, `AdminLoginScreen`, `AdminShell`, and `admin_main.dart` (`_isLoggedIn = false`, `/admin` route guard, Firebase Auth + active `admin_staff/{uid}` server role resolution, `admin_audit_logs`), and built **Module 13 (`AdminWorksiteOpsScreen`)** for 11-digit QID KYC review, manual bank transfer settlement verification, dispute moderation, and audit export.
- **Wave 3B — Focused 4-Tab Customer & Provider Journey:**
  - Built `CreateWorkRequestScreen` (3-step validated form + Quick Reorder prefill), `WorkRequestsFeedScreen` (Qatar municipality/status/budget filters + skeleton/error/empty states), `WorkRequestDetailsScreen` (timeline, offer comparison/acceptance, requester handover code card, approved-provider offer & stage controls, invoice attachment, 6-char handover modal, manual transfer proof, mutual rating, dispute modal, contextual `ChatScreen`), and `ProviderProfileScreen` (11-digit QID KYC, approval badge, saved worksites, real stats).
  - Updated `MainNavShell` (4 focused MVP tabs: `Home`, `Requests`, `My Activity`, `Account`), `HomeScreen` (`"شنو تحتاج ينجز اليوم؟"` / `"What do you need done today?"` with zero fake counters/balances/cars), `WelcomeScreen`, and `EmailInputScreen`.
- **Wave 3C & Wave 4 — Qatar Documentation Alignment & Baseline Verification:**
  - Aligned `README.md` and all 9 `docs/backend/*.md` specifications with the Qatar Worksite Supply MVP (zero stale Egypt references).
- **Wave 5 — Live Emulator Rules Suite, Binary Storage Uploads, `+974` Phone Auth, `url_launcher`, `deleteUserAccount` & Native Release Readiness:**
  - **Live Firebase Emulators & AST Rule Optimization:** Provisioned OpenJDK `21.0.13.1` LTS + `firebase-tools` `15.37.0`, optimized `firestore.rules` (`2,344` lines) to keep max-schema `work_requests` updates well below Firestore's 1,000 AST expression cap, and added `functions/test/emulator_rules.test.mjs` + `scripts/run_emulators_tests.ps1` (`9/9` live Cloud Firestore `v1.22.0` + Storage `v1.1.3` rule suites passing).
  - **Firebase Storage Media Uploads, `+974` Phone Auth, `url_launcher` & Account Erasure:** Added cross-platform `MediaUploadService` (`firebase_storage` + `image_picker`, `<= 10 MB`, `image/*`, zero `dart:io`) across 4 KYC/worksite upload screens; implemented real Qatar `+974` (`[3567]xxxxxxx`) Firebase Phone Auth (`signInWithPhoneNumber` on Web, `verifyPhoneNumber` on Mobile) with bilingual error mapping and Email+Password fallback CTAs; wired `url_launcher` (`tel:999`, `tel:`, `mailto:`, console URLs); and added server-side `deleteUserAccount` (`10`th callable handler in `functions/`) + `DeleteAccountScreen` enforcing active-order guards, profile/KYC purging, audit logging, and Firebase Auth deletion (`11/11` functions unit tests & `136/136` Flutter tests passing).
  - **Native App Registration, Signing & Qatar PDPL Compliance:** Registered native Firebase apps (`mashwar-qatar-android` `1:820084343406:android:a9e464e38a988eddd35c7f`, `mashwar-qatar-ios` `1:820084343406:ios:5073f983643cc020d35c7f`) in `lib/firebase_options.dart`, aligned iOS `qa.mashwar.app` bundle IDs & camera/photo `Info.plist` purpose strings, configured Android release signing (`key.properties` + R8/ProGuard `proguard-rules.pro`), added `scripts/fetch_firebase_configs.ps1` & `scripts/generate_upload_keystore.ps1` (provisioned locally and verified 100% gitignored), rewrote `LegalComplianceScreen` for Qatar PDPL Law No. 13 of 2016, and authored `docs/QATAR_COMPLIANCE_AND_RELEASE_PLAYBOOK.md`.

---

## 4. Architecture Changes

1. **Compile-Time Environment Resolution (`AppEnvironment`):**
   - Resolves `AppFlavor` (`development`, `staging`, `production`), `USE_FIREBASE`, and `USE_DEV_MOCKS`.
   - Enforces `resolveUseDevMocks`: dev mocks are **mathematically impossible** to enable when `APP_ENV != 'development'` or `USE_FIREBASE == true`.
2. **Fail-Closed Application Boot (`lib/main.dart` & `lib/admin_main.dart` & `lib/screens/splash_screen.dart`):**
   - `initializeMashwarStartup()` and `admin_main.dart` connect to Firebase by default (`!env.useDevMocks && (!AppEnvironment.hasExplicitUseFirebase || env.useFirebase)`), marking `AppEnvironment.setFirebaseRuntimeActive(true)` and wiring `AppRepositories.instance.useFirebase()` (with lazy Firebase SDK instance resolution across all 9 Firebase repositories). Passing `USE_DEV_MOCKS=true` in `development` opts into local mocks, whereas `USE_FIREBASE=false` without `USE_DEV_MOCKS=true` or non-development builds without Firebase fail closed with `ServiceUnavailableScreen` and Retry.
   - `SplashScreen` restores Firebase sessions via `AuthProvider.restoreSession()` and routes unauthenticated users to `WelcomeScreen`.
3. **Web-Safe Cloud Functions v2 Bridge (`FirebaseFunctionsCallableClient`):**
   - Located in `lib/data/services/firebase_firestore_service.dart`, invoking `europe-west1` v2 `onCall` endpoints via `package:http` with `Authorization: Bearer <ID_TOKEN>` and mapping server errors into bilingual `WorksiteRepositoryException` objects (avoiding `dart:io` Web incompatibilities).
4. **Deferred Regulated Capabilities:**
   - `enablePassengerRides`, `enableCarpooling`, `enableCommercialCargo`, `enableDigitalWallet`, and `enableEscrowClaims` remain `false` in `AppEnvironment`, keeping legacy prototype modules out of the active customer MVP navigation while preserving source compatibility.

---

## 5. Database Collections

Defined and enforced in [`firestore.rules`](../firestore.rules) (`2,552` lines, AST-optimized well below Firestore's 1,000-expression evaluation limit and live-tested in Cloud Firestore Emulator `v1.22.0`) with `14` composite indexes in [`firestore.indexes.json`](../firestore.indexes.json):

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
| 23 | `work_requests/{requestId}` | Worksite supply order (`budgetMinor` int `> 0`, 11 snake_case statuses, `cash_on_delivery` / `bank_transfer_manual`); client `delete` forbidden; client direct `completed` forbidden; AST-guarded updates for max-schema location maps & 5-URL arrays. |
| 24 | `work_offers/{offerId}` | Quotes from approved providers (`requesterId != providerId`, positive int minor amounts); readable by offer provider, request owner, or admin. |
| 25 | `work_request_secrets/{requestId}` | Salted SHA-256 handover hash, salt, `attemptsRemaining` (`5`), `expiresAtUtc` (`+24h`), `usedAtUtc` — **`allow read, write: if false;`** (Admin SDK / Cloud Functions only). |
| 26 | `work_request_handover_view/{requestId}` | Requester-only plaintext handover code projection (`requesterId == auth.uid`; **`allow write: if false;`**). |
| 27 | `request_events/{eventId}` | Append-only lifecycle event timeline readable by request participants or admin (`allow update, delete: if false`). |
| 28 | `ratings/{ratingId}` | Post-completion mutual 1–5 star rating keyed by `${requestId}_${fromUserId}` (`allow update, delete: if false`). |
| 29 | `notifications/{notificationId}` | Server-created user notifications; owner can update **only** `isRead`. |

---

## 6. Authentication Configuration

1. **Customer & Provider Authentication (`FirebaseAuthRepository` + `AuthProvider`):**
   - **Email + Password (`Active`):** `signInWithEmailAndPassword`, `createUserWithEmailAndPassword`, `sendPasswordResetEmail`, `signOut`, automatic session restoration (`restoreSession()`), and neutral Firestore `users/{uid}` initialization.
   - **Real `+974` Firebase Phone Auth (`Wired & Guarded`):** Validates Qatar E.164 mobile numbers (`+974` + `[3567]xxxxxxx`) and invokes `FirebaseAuth.signInWithPhoneNumber` + `ConfirmationResult.confirm` on Web and `verifyPhoneNumber` + `PhoneAuthProvider.credential` + `signInWithCredential` on Android/iOS. Rejects arbitrary 6-digit codes outside dev-mock mode and maps `billing-not-enabled`, `operation-not-allowed`, `quota-exceeded`, `invalid-verification-code`, and `too-many-requests` into clear bilingual `AuthException` messages with 1-tap Email + Password fallback CTAs across `WelcomeScreen`, `PhoneInputScreen`, and `OtpVerificationScreen`.
   - **Provider KYC (`11-Digit QID` + Binary Uploads):** `submitNationalId` / `submitProviderVerification` validates 11-digit Qatar QID (`^[0-9]{11}$`), uploads QID front/back/selfie images via `MediaUploadService` to private `/provider_verifications/{uid}/{docType}_{ts}.{ext}`, and writes pending verification records without granting `isVerified` or `approved` client-side.
   - **Permanent Account Deletion (`deleteUserAccount`):** `AuthProvider.deleteAccount()` + `DeleteAccountScreen` call the `deleteUserAccount` Cloud Function, blocking deletion when active/disputed worksite orders exist, auto-cancelling open unassigned requests, purging `users/{uid}`, `provider_profiles/{uid}`, `provider_verifications/{uid}`, and `business_profiles/{uid}`, writing an `admin_audit_logs` record, and deleting the Firebase Auth user.
2. **Admin Staff Authentication (`AdminProvider` + `AdminLoginScreen` + `AdminShell`):**
   - `AdminProvider._isLoggedIn` defaults to `false`; navigating to `/admin` (embedded or `lib/admin_main.dart`) renders `AdminLoginScreen` until authenticated.
   - `signInStaffWithFirebase(email, password)` signs in via `FirebaseAuth`, verifies an active document in `admin_staff/{uid}` (`isActive == true`), binds `_activeRole` strictly from the server-stored `role` (`superAdmin`, `reviewAdmin`, `supportAdmin`, `compliance`, `operations`), and logs `admin_audit_logs`.
   - Hardcoded `admin@mashwar.example` / `12345678` credentials were removed; demo role quick-fill and role-switcher controls are hidden unless `AppEnvironment.useDevMocks` is `true`.
3. **Dev-Only Mock Separation:**
   - Unit/widget tests use explicit `@visibleForTesting` constructors (`AuthProvider.forTesting(...)`, `AdminProvider.forTesting(...)`), keeping production defaults unauthenticated.

---

## 7. Security Changes

- **Server-Enforced State Machine & Account Erasure (`functions/src/stateMachine.ts` & `handlers.ts`):**
  - `10` transactional callable handlers enforce `open -> offer_received -> offer_selected -> accepted -> in_progress -> picked_up -> in_transit -> delivered_pending_confirmation -> completed` (plus guarded `cancelled` before `picked_up`, `disputed` during active fulfillment, and `deleteUserAccount` active-order precondition guards).
  - Blocks unauthenticated access, self-bidding, unapproved providers, foreign-request tampering, and requester self-completion.
- **Salted Constant-Time SHA-256 Handover Verification (`functions/src/handoverCrypto.ts`):**
  - Mints 6-character codes from unambiguous 32-char alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` via `crypto.randomBytes(6)` (zero modulo bias) with a 128-bit hex salt (`SHA-256(salt + ':' + code)`).
  - Verifies via `crypto.timingSafeEqual`, persists `attemptsRemaining - 1` on mismatch (`maxAttempts: 5`), enforces 24-hour expiry (`expiresAtUtc`), and stamps `usedAtUtc` atomically so codes are strictly single-use.
- **AST-Optimized `firestore.rules` & Live Emulator Verification:**
  - Role checks (`prev.requesterId == request.auth.uid` / `prev.assignedProviderId == request.auth.uid`) short-circuit before CEL `let` bindings, `isValidMvpUrl` uses a single `^(https?|gs)://.*` match, and unchanged `pickupLocation` / `deliveryLocation` maps bypass redundant re-validation, keeping max-schema `work_requests` updates well below Firestore's 1,000 AST expression cap (verified live across `9/9` suites in `functions/test/emulator_rules.test.mjs`).
- **Integer QAR `MoneyMinor` & Payment Settlement Immutability:**
  - Zero `double` currency fields in MVP models or Cloud Functions (`1 QAR = 100 dirhams`).
  - `recordPaymentStatus` and `firestore.rules` enforce `unpaid -> transfer_proof_submitted -> verified_settled`, forbidding forged initial payment states and blocking any overwrite once `verified_settled`.
  - `AuthProvider` blocks local `depositWalletFunds` / `withdrawWalletFunds` while `enableDigitalWallet == false`.
- **Cloud Storage Rules (`storage.rules`) & Cross-Platform `MediaUploadService`:**
  - Default-deny root rule, authenticated access, `<= 10 MB` cap, `image/*` MIME validation, owner/admin-only `/provider_verifications/{uid}/{file}`, and participant-scoped `/work_requests/{requestId}/{reference|invoices|payment_proofs}/{file}`, enforced both client-side (`MediaUploadService`, Web-safe `XFile.readAsBytes()`) and server-side (verified in Cloud Storage Emulator `v1.1.3`).
- **Secret & Artifact Hygiene:**
  - `.gitignore` and `android/.gitignore` strictly ignore `.env`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `android/upload-keystore.jks`, `android/key.properties`, `*.jks`, `*.keystore`, `node_modules/`, and `functions/lib/`, while keeping sanitized `.example` templates tracked.

---

## 8. Screens Changed

### Newly Created Screens (`5` screens)
- `lib/screens/worksite/create_work_request_screen.dart` — 3-step validated QAR supply request wizard + binary reference image upload (`MediaUploadService`) + saved worksite picker + Quick Reorder draft prefill.
- `lib/screens/worksite/work_requests_feed_screen.dart` — Filterable Qatar worksite supply feed (municipality/area, status, budget) with skeleton, retry, and empty states.
- `lib/screens/worksite/work_request_details_screen.dart` — Request timeline, offer comparison/acceptance, requester handover code view, binary manual bank transfer proof upload, approved-provider offer & fulfillment controls, binary store invoice photo upload, 6-char handover verification modal, `tel:` contact launcher, mutual rating modal, dispute modal, and contextual `ChatScreen` launch.
- `lib/screens/worksite/provider_profile_screen.dart` — Provider/business profile editor, 11-digit QID verification with front/back/selfie binary image uploads, real approval status badge, saved worksites manager, and completed job metrics.
- `lib/screens/admin/admin_worksite_ops_screen.dart` — Enterprise Admin Module `13` (Tab A: 11-digit QID KYC review; Tab B: payment settlement verification & dispute moderation; Tab C: privileged `admin_audit_logs` filter & JSON export).

### Modified Entrypoints & Existing Screens (`15` files)
- `lib/main.dart` — `initializeMashwarStartup()`, `ServiceUnavailableScreen` fail-closed error UI with Retry, `WorksiteProvider` registration, and `AuthProvider.restoreSession()` wiring.
- `lib/admin_main.dart` — Guarded standalone admin web entrypoint (`admin.isLoggedIn ? AdminShell() : AdminLoginScreen()`).
- `lib/screens/splash_screen.dart` — Real session restoration routing (`WelcomeScreen` when unauthenticated; `MainNavShell` only when authenticated) and Qatar Worksite Supply branding.
- `lib/screens/main_nav_shell.dart` — Focused 4-tab MVP navigation (`Home`, `Requests`, `My Activity` backed by real `WorksiteProvider` data, `Account` with Provider Profile/Legal/Logout) when `enablePassengerRides == false`.
- `lib/screens/home/home_screen.dart` — Task-first `"شنو تحتاج ينجز اليوم؟"` / `"What do you need done today?"` hub with primary Create/Browse CTAs, saved worksite selector, real active/recent requests, and 1-tap Quick Reorder (zero fake live counters, balances, or moving cars).
- `lib/screens/auth/welcome_screen.dart`, `lib/screens/auth/phone_input_screen.dart` & `lib/screens/auth/otp_verification_screen.dart` — Real Email+Password entry + `+974` Firebase Phone Auth flow with bilingual SMS error handling, Email fallback CTAs, and `AppEnvironment.useDevMocks`-gated demo shortcut.
- `lib/screens/auth/email_input_screen.dart` — Real `loginWithEmail`, `registerWithEmail`, and `sendPasswordReset` form with validation and error feedback.
- `lib/screens/auth/id_verification_screen.dart` — Binary QID front/back/selfie upload integration via `MediaUploadService` with `Image.memory` previews and size/MIME validation.
- `lib/screens/account/account_extra_screens.dart` — Real `DeleteAccountScreen` (`AuthProvider.deleteAccount()` + `WorksiteProvider` active-order guard) and `url_launcher` support links in `HelpSupportScreen`.
- `lib/screens/account/legal_and_backend_screens.dart` — Honest bilingual `LegalComplianceScreen` covering Worksite Supply pilot terms (`cash_on_delivery` / `bank_transfer_manual`), Qatar PDPL Law No. 13 of 2016 data rights & erasure, and MoT/QCB/MoCI trademark disclosures.
- `lib/screens/safety/safety_screens.dart` — Real `launchUrl(Uri(scheme: 'tel', path: '999'))` emergency SOS action in `EmergencySosSheet` with honest dialer-absent fallback.
- `lib/screens/admin/admin_login_screen.dart`, `lib/screens/admin/admin_shell.dart` & `lib/screens/admin/admin_inquiries_screen.dart` — Removed prefilled `admin@mashwar.example`/`12345678`, enforced `AdminShell` login guard, hid client role switchers outside dev-mock mode, wired Module `13` routing + `pendingVerificationsCount` badge, and added `mailto:` / Firestore Console `url_launcher` actions.

---

## 9. Files Created

Verified directly from `git diff --diff-filter=A --name-only c444e6d..HEAD` on `feat/mvp-worksite-supply` (`42` new files created across configuration, native release tooling, backend, domain, repositories, services, state, UI, tests, and compliance/report documentation):

### Configuration, Native Provisioning Scripts, Security Rules & Cloud Functions (`18` files)
- `.env.example`
- `android/app/google-services.json.example`
- `android/app/proguard-rules.pro`
- `android/key.properties.example`
- `ios/Runner/GoogleService-Info.plist.example`
- `scripts/fetch_firebase_configs.ps1`
- `scripts/generate_upload_keystore.ps1`
- `scripts/run_emulators_tests.ps1`
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

### Flutter Config, Domain Models, Repositories, Services & State (`10` files)
- `lib/core/config/app_environment.dart`
- `lib/data/models/worksite_models.dart`
- `lib/data/repositories/contracts/i_worksite_repository.dart`
- `lib/data/repositories/contracts/i_provider_repository.dart`
- `lib/data/repositories/implementations/worksite_repository_impl.dart`
- `lib/data/repositories/implementations/provider_repository_impl.dart`
- `lib/data/repositories/implementations/firebase/firebase_worksite_repository.dart`
- `lib/data/repositories/implementations/firebase/firebase_provider_repository.dart`
- `lib/data/services/media_upload_service.dart`
- `lib/state/worksite_provider.dart`

### Flutter Customer & Admin UI Screens (`5` files)
- `lib/screens/worksite/create_work_request_screen.dart`
- `lib/screens/worksite/work_requests_feed_screen.dart`
- `lib/screens/worksite/work_request_details_screen.dart`
- `lib/screens/worksite/provider_profile_screen.dart`
- `lib/screens/admin/admin_worksite_ops_screen.dart`

### Automated Test Suites, Playbooks & Implementation Reports (`9` files)
- `functions/test/backend_security.test.mjs`
- `functions/test/emulator_rules.test.mjs`
- `test/mvp_models_and_auth_test.dart`
- `test/mvp_worksite_provider_and_repo_test.dart`
- `test/mvp_worksite_ui_test.dart`
- `test/mvp_media_phone_and_account_test.dart`
- `docs/MVP_BASELINE_AUDIT.md`
- `docs/MVP_IMPLEMENTATION_REPORT.md`
- `docs/QATAR_COMPLIANCE_AND_RELEASE_PLAYBOOK.md`

*(Note: Comparing further back to `b76cbaa..HEAD` additionally encompasses earlier repository additions such as `.firebaserc`, `.github/workflows/mashwar_ci_cd.yml`, `vercel.json`, `web/health.json`, `lib/firebase_options.dart`, `docs/backend/*.md`, `lib/screens/admin/admin_{corridors_geo,devops_sre,escrow_finance,inquiries,services_catalog}_screen.dart`, and `test/{admin_enterprise_devops,firebase_repositories,uber_live_map_and_onboarding,universal_services_and_escrow}_test.dart`, while removing tracked root `node_modules/`.)*

---

## 10. Tests Actually Executed

All metrics below were executed and verified on Windows PowerShell 5.1 (`Flutter 3.47.9`, `Node.js v24.19.0`, `OpenJDK 21.0.13.1 LTS`, `firebase-tools 15.37.0`, Cloud Firestore Emulator `v1.22.0`, Cloud Storage Rules Runtime `v1.1.3`) on `feat/mvp-worksite-supply`:

| Check / Suite | Exact Command | Exit Code | Observed Result |
| :--- | :--- | :---: | :--- |
| **Live Firebase Firestore & Storage Emulator Rules Suite** | `powershell -ExecutionPolicy Bypass -File scripts/run_emulators_tests.ps1` | `0` | **`10 / 10` live suites passed (`100%`, `0` failed)** via `@firebase/rules-unit-testing@6.0.0` against live `firestore.rules` (`2,552` lines) & `storage.rules` (unauth denials, `users/{uid}` empty-phone Email / empty-name Phone OTP create + invalid-phone/verify blocks, `work_request_secrets` lockdown, `work_request_handover_view` requester ACL, `provider_profiles`, `provider_verifications`, `work_requests`, `work_offers`, `ratings`, and `storage.rules`). |
| **Cloud Functions TypeScript Build** | `npm run build` (`tsc` in `functions/`) | `0` | Compiled cleanly (`0` tracked artifacts in `functions/lib/` or `node_modules/`). |
| **Cloud Functions Security & Erasure Suite** | `npm test` (`node --test test/backend_security.test.mjs`) | `0` | **`11 / 11` passed (`0` failed)** covering crypto, auth, state machine, handover attempts/TTL/reuse, settlement immutability, ratings, admin RBAC/audits, and `deleteUserAccount` active-order guards & full purge. |
| **Dart Static Analysis** | `flutter analyze` | `0` | **`No issues found!`** (`0` errors, `0` warnings). |
| **Flutter Unit, Repo, Media, Phone Auth & Widget Suite** | `flutter test` | `0` | **`139 / 139` passed (`0` failed)** (`All tests passed!`), including default-Firebase `initializeMashwarStartup()`, bilingual Email+Password error mapping, Firestore `permission-denied` doc tolerance, and `EmailInputScreen` phone switch / Arabic error rendering. |
| **Production Web Release Builds (Consumer & Admin)** | `flutter build web --release; flutter build web --release -t lib/admin_main.dart --base-href /admin/ -o build/web/admin` | `0` | Both `build/web` and `build/web/admin` compiled cleanly (`--dart-define=APP_ENV=production --dart-define=USE_FIREBASE=true` configured in `.github/workflows/mashwar_ci_cd.yml`). |

*(Note: On Windows hosts where Windows Developer Mode symlink support is disabled, `flutter pub get` still downloads and resolves all Dart/Web packages cleanly (`Got dependencies!`), then emits exit `1` only for Windows desktop `.plugin_symlinks` creation; `flutter analyze --no-pub`, `flutter test --no-pub`, and `flutter build web --release` execute cleanly with exit `0`.)*

---

## 11. Build & Native Release Provisioning Results

### Production Web Release Bundle (`flutter build web --release`)
- **Command:** `flutter build web --release`
- **Exit Code:** `0` (`√ Built build\web`, MaterialIcons tree-shaken `97.0%`).
- **Verified Output Artifacts:** `build/web/index.html` (`1,737 B`), `build/web/main.dart.js` (`4,821,001 B`), `flutter_bootstrap.js`, `manifest.json`, `health.json`, `vercel.json`. (`build/` remains untracked per `.gitignore`.)

### Android & iOS Release Configuration + Local Gitignored Provisioning Audit
- **Registered Native Firebase Apps (`mashwar-qatar-2026-ec99d`):**
  - `lib/firebase_options.dart` configured with real registered app IDs for Android (`com.mashwar.app.mashwar` -> `1:820084343406:android:a9e464e38a988eddd35c7f`), iOS (`qa.mashwar.app` -> `1:820084343406:ios:5073f983643cc020d35c7f`), and Web (`1:820084343406:web:ad6ce9779a06584bd35c7f`).
- **Android Release Signing & R8 Hardening:**
  - `android/app/src/main/AndroidManifest.xml`: Declares `INTERNET` and `ACCESS_NETWORK_STATE`; uses `flutterEmbedding="2"`.
  - `android/settings.gradle.kts` & `android/app/build.gradle.kts`: Conditional `com.google.gms.google-services` (`4.4.2`) application when `google-services.json` exists, `signingConfigs.create("release")` loading `android/key.properties` + `upload-keystore.jks` (with debug fallback only for local dev builds), R8 `isMinifyEnabled = true`, `isShrinkResources = true`, and [`android/app/proguard-rules.pro`](../android/app/proguard-rules.pro).
- **iOS Bundle Alignment & Privacy Purpose Strings:**
  - `ios/Runner.xcodeproj/project.pbxproj`: `PRODUCT_BUNDLE_IDENTIFIER` aligned to `qa.mashwar.app` (`qa.mashwar.app.RunnerTests`).
  - `ios/Runner/Info.plist`: Declares `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, and `LSApplicationQueriesSchemes` (`tel`, `mailto`, `https`).
- **Verified Local Gitignored Provisioning (`scripts/fetch_firebase_configs.ps1` & `scripts/generate_upload_keystore.ps1`):**
  - `android/app/google-services.json` (`701 B`, `project_id == mashwar-qatar-2026-ec99d`) — ignored via `.gitignore:69`.
  - `ios/Runner/GoogleService-Info.plist` (`894 B`, `qa.mashwar.app`) — ignored via `.gitignore:71`.
  - `android/upload-keystore.jks` (`2,760 B`, 2048-bit RSA PKCS12 generated via OpenJDK 21 `keytool.exe`) — ignored via `android/.gitignore:14`.
  - `android/key.properties` (`211 B`) — ignored via `android/.gitignore:12`.

---

## 12. Remaining External / Non-Code Operational Gates

All in-repository engineering blockers identified in Wave 4 (Java/Firebase CLI emulator tooling, `firestore.rules` AST cap, `firebase_storage`/`image_picker` media uploads, `+974` Phone Auth SDK wiring, `url_launcher`, `deleteUserAccount`, native Firebase app registration, Gradle release signing, and iOS `Info.plist` permissions) have been resolved in code. Only external console, build-host, and legal/regulatory gates remain (detailed in [`docs/QATAR_COMPLIANCE_AND_RELEASE_PLAYBOOK.md`](QATAR_COMPLIANCE_AND_RELEASE_PLAYBOOK.md)):

1. **Firebase Console SMS Billing, App Attestation & Physical `+974` Device Verification:** Upgrade `mashwar-qatar-2026-ec99d` to Firebase Blaze, enable Phone Auth with a Qatar-only (`+974`) SMS region allowlist, register Android Upload + Play App Signing SHA-1/SHA-256 fingerprints, upload an Apple APNs `.p8` key, enable App Check / reCAPTCHA Enterprise, and verify live OTP delivery on physical Ooredoo/Vodafone Qatar SIMs (Email + Password sign-in is active out of the box).
2. **Signed Store Artifact Compilation & Store Review:** Build signed Android `.aab` (`flutter build appbundle --release` on an Android SDK release machine with vault-backed `upload-keystore.jks`) for Google Play Console and build signed iOS `.ipa` (`flutter build ipa --release` on a macOS/Xcode build host with Apple Developer provisioning) for App Store Connect.
3. **Qatar MoCI Trademark Clearance:** Complete prior-art search and Nice Classes 35, 39, and 42 trademark registration for **MASHWAR / مشوار** via Qatar Single Window (`investor.sw.gov.qa`) prior to public commercial promotion.
4. **Qatar MoT & QCB Regulatory Licensing (Deferred Modules):** Keep `enablePassengerRides`, `enableCarpooling`, `enableCommercialCargo`, `enableDigitalWallet`, and `enableEscrowClaims` set to `false` until formal Ministry of Transport (MoT) permits and Qatar Central Bank (QCB) licensed-PSP/escrow authorizations are obtained.

---

## 13. Required Environment Variables

Defined in [`.env.example`](../.env.example) and read via `--dart-define` / `--dart-define-from-file` in [`lib/core/config/app_environment.dart`](../lib/core/config/app_environment.dart) and [`lib/data/services/firebase_firestore_service.dart`](../lib/data/services/firebase_firestore_service.dart):

| Variable | Required | Default | Description |
| :--- | :---: | :--- | :--- |
| `APP_ENV` | Yes | `development` | Runtime flavor: `development` \| `staging` \| `production`. |
| `USE_FIREBASE` | Optional | Omitted (`default` connects to Firebase) | Real entrypoints (`main.dart`, `admin_main.dart`) connect to Firebase by default unless `USE_DEV_MOCKS=true` in `development`; set `USE_FIREBASE=true` explicitly in CI/staging/production. Passing `USE_FIREBASE=false` without `USE_DEV_MOCKS=true` fails closed. |
| `USE_DEV_MOCKS` | No | `false` | Enables dev-only mock auth, deterministic media uploads & sample Qatar data (**only** honored when `APP_ENV=development` and Firebase is disabled). |
| `FIREBASE_PROJECT_ID` | Yes (Cloud) | `mashwar-qatar-2026-ec99d` | Target Firebase project ID. |
| `FIREBASE_REGION` | Yes (Cloud) | `europe-west1` | Cloud Functions v2 deployment region. |
| `FIREBASE_WEB_API_KEY` | Yes (Web) | Configured SDK key | Restricted Firebase Web client API key. |
| `FIREBASE_ANDROID_API_KEY` | Yes (Android) | Configured SDK key | Restricted Firebase Android client API key (`1:820084343406:android:a9e464e38a988eddd35c7f`). |
| `FIREBASE_IOS_API_KEY` | Yes (iOS) | Configured SDK key | Restricted Firebase iOS client API key (`1:820084343406:ios:5073f983643cc020d35c7f`). |
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

# 2. Run Live Firestore & Storage Emulator Rules Suite (OpenJDK 21 + firebase-tools)
powershell -ExecutionPolicy Bypass -File scripts/run_emulators_tests.ps1

# 3. Provision Gitignored Native Firebase Configs & Upload Keystore (for local Android/iOS builds)
powershell -ExecutionPolicy Bypass -File scripts/fetch_firebase_configs.ps1
powershell -ExecutionPolicy Bypass -File scripts/generate_upload_keystore.ps1

# 4. Run Customer App (connects to Firebase by default; pass USE_DEV_MOCKS=true for offline mocks)
flutter run -d chrome
flutter run -d chrome --dart-define=APP_ENV=development --dart-define=USE_FIREBASE=false --dart-define=USE_DEV_MOCKS=true

# 5. Run Standalone Admin Portal (connects to Firebase by default; pass USE_DEV_MOCKS=true for local queue)
flutter run -t lib/admin_main.dart -d chrome
flutter run -t lib/admin_main.dart -d chrome --dart-define=APP_ENV=development --dart-define=USE_FIREBASE=false --dart-define=USE_DEV_MOCKS=true

# 6. Run Interactive Local Firebase Emulators
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
2. **Verify Live Emulator Rules, Build & Deploy Backend Rules, Indexes, Storage & Cloud Functions v2:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/run_emulators_tests.ps1
   Push-Location functions; npm ci; npm run build; npm test; Pop-Location
   firebase deploy --only firestore:rules,firestore:indexes,storage,functions
   ```
3. **Provision Initial Admin Staff Record:**
   - Create staff account in Firebase Authentication, set custom claim `{ "admin": true, "role": "superAdmin" }`, and create `admin_staff/{uid}` (`isActive: true`, `role: "superAdmin"`).
4. **Configure Storage Bucket CORS:**
   - Apply `cors.json` to `gs://mashwar-qatar-2026-ec99d.firebasestorage.app` allowing staging/production web origins for browser `MediaUploadService` `putData` uploads.
5. **Compile Staging Web Bundles (Fail-Closed Mode, Zero Dev Mocks):**
   ```powershell
   flutter build web --release --base-href / --dart-define=APP_ENV=staging --dart-define=USE_FIREBASE=true --dart-define-from-file=.env.staging
   flutter build web --release -t lib/admin_main.dart --base-href /admin/ -o build/web/admin --dart-define=APP_ENV=staging --dart-define=USE_FIREBASE=true --dart-define-from-file=.env.staging
   ```

---

## 16. Remaining Work Before Public Release & Evidence Matrix

### Pre-Launch Operational & Legal Checklist
- [x] Install OpenJDK 21 LTS + `firebase-tools` and verify `10/10` live `firestore.rules` + `storage.rules` emulator test suites (`scripts/run_emulators_tests.ps1`).
- [x] Register native Firebase apps (`com.mashwar.app.mashwar` & `qa.mashwar.app`), add Android release keystore signing (`key.properties` + `proguard-rules.pro`), populate iOS `Info.plist` permission strings, and author Qatar PDPL compliance screens + release playbook (`docs/QATAR_COMPLIANCE_AND_RELEASE_PLAYBOOK.md`).
- [x] Add `firebase_storage` + `image_picker` (`MediaUploadService`) for direct KYC/invoice/proof uploads, `+974` Firebase Phone Auth, `url_launcher` (`tel:999`), and server-side `deleteUserAccount` callable + `DeleteAccountScreen`.
- [ ] Enable Firebase Blaze billing, `+974`-only SMS region allowlist, Android SHA-1/SHA-256 + iOS APNs `.p8` + reCAPTCHA Enterprise in Firebase Console, and verify OTP delivery on physical Qatar SIMs.
- [ ] Build signed `.aab` / `.ipa` store artifacts on Android SDK / macOS Xcode release hosts and submit to Google Play Console & App Store Connect.
- [ ] Complete Qatar MoCI Single Window (`investor.sw.gov.qa`) trademark search and registration (Nice Classes 35, 39, 42) for **MASHWAR / مشوار**.
- [ ] Keep `enablePassengerRides`, `enableCarpooling`, `enableCommercialCargo`, `enableDigitalWallet`, and `enableEscrowClaims` set to `false` until respective Qatar MoT and QCB licenses/partnerships are obtained.

### Feature-to-Code-&-Test Evidence Matrix

| MVP Capability / Invariant | Implementation Files | Server / Security Enforcement | Automated Test Evidence |
| :--- | :--- | :--- | :--- |
| **Environment Flavors & Fail-Closed Startup** | `lib/core/config/app_environment.dart`, `lib/main.dart`, `.env.example` | `resolveUseDevMocks` blocks mocks in staging/prod/Firebase; `ServiceUnavailableScreen` | `test/mvp_models_and_auth_test.dart`, `test/mvp_worksite_provider_and_repo_test.dart` |
| **Neutral User Defaults, Email Auth & `+974` Phone Auth** | `lib/data/models/user_model.dart`, `lib/state/auth_provider.dart`, `lib/data/repositories/implementations/firebase/firebase_auth_repository.dart`, `lib/screens/auth/{welcome,email_input,phone_input,otp_verification}_screen.dart` | `firestore.rules` (`users/{uid}` blocks self-verify & balance edits); `+974` E.164 validation & Firebase Phone Auth error mapping | `test/mvp_models_and_auth_test.dart`, `test/email_auth_test.dart`, `test/mvp_media_phone_and_account_test.dart` |
| **Integer QAR `MoneyMinor` (`1 QAR = 100 dirhams`)** | `lib/data/models/worksite_models.dart` | `functions/src/handlers.ts` (`requirePositiveInt` / `requireNonNegativeInt`), `firestore.rules` (`is int`) | `test/mvp_models_and_auth_test.dart`, `functions/test/backend_security.test.mjs`, `functions/test/emulator_rules.test.mjs` |
| **3-Step Worksite Request Creation, Media Upload & Quick Reorder** | `lib/screens/worksite/create_work_request_screen.dart`, `lib/data/services/media_upload_service.dart`, `lib/state/worksite_provider.dart` | `functions/src/handlers.ts` (`createWorkRequest`), `firestore.rules` (`work_requests` create rule), `storage.rules` (`<= 10 MB`, `image/*`) | `test/mvp_worksite_ui_test.dart`, `test/mvp_media_phone_and_account_test.dart`, `functions/test/emulator_rules.test.mjs` |
| **Qatar Feed Filtering & Empty/Error/Retry States** | `lib/screens/worksite/work_requests_feed_screen.dart`, `lib/state/worksite_provider.dart`, `firestore.indexes.json` | `firestore.rules` (`work_requests` signed-in read; unauth denied) | `test/mvp_worksite_ui_test.dart`, `test/mvp_worksite_provider_and_repo_test.dart`, `functions/test/emulator_rules.test.mjs` |
| **Approved-Provider Offer Submission & Selection** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/state/worksite_provider.dart` | `functions/src/handlers.ts` (`submitWorkOffer`, `acceptWorkOffer`), `firestore.rules` (`isApprovedProvider`, no self-bid) | `test/mvp_worksite_ui_test.dart`, `functions/test/backend_security.test.mjs`, `functions/test/emulator_rules.test.mjs` |
| **Linear Fulfillment Stages & Binary Store Invoice Proof** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/data/services/media_upload_service.dart`, `lib/data/models/worksite_models.dart` | `functions/src/stateMachine.ts`, `handlers.ts` (`transitionWorkRequestStatus`), AST-optimized `firestore.rules`, `storage.rules` (`/invoices/`) | `test/mvp_worksite_ui_test.dart`, `test/mvp_media_phone_and_account_test.dart`, `functions/test/emulator_rules.test.mjs` |
| **6-Char Salted SHA-256 Single-Use Handover** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/data/repositories/implementations/worksite_repository_impl.dart` | `functions/src/handoverCrypto.ts`, `handlers.ts` (`verifyHandoverAndComplete`), `firestore.rules` (`work_request_secrets` `false`, `work_request_handover_view` owner-only) | `functions/test/backend_security.test.mjs`, `functions/test/emulator_rules.test.mjs`, `test/mvp_worksite_ui_test.dart` |
| **11-Digit Qatar QID Provider Onboarding & Private KYC Storage** | `lib/screens/worksite/provider_profile_screen.dart`, `lib/screens/auth/id_verification_screen.dart`, `lib/data/services/media_upload_service.dart` | `firestore.rules` (`provider_profiles` `pending` create, `provider_verifications` owner/admin read), `storage.rules` (`/provider_verifications/{uid}/`) | `test/mvp_models_and_auth_test.dart`, `test/mvp_media_phone_and_account_test.dart`, `functions/test/emulator_rules.test.mjs` |
| **Post-Completion Mutual Ratings & Disputes** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/state/worksite_provider.dart` | `functions/src/handlers.ts` (`submitRequestRating`, `transitionWorkRequestStatus`), `firestore.rules` (`ratings/${requestId}_${uid}`) | `functions/test/backend_security.test.mjs`, `functions/test/emulator_rules.test.mjs`, `test/mvp_worksite_provider_and_repo_test.dart` |
| **Manual Bank Transfer Proof & Settlement Immutability** | `lib/screens/worksite/work_request_details_screen.dart`, `lib/screens/admin/admin_worksite_ops_screen.dart`, `lib/data/services/media_upload_service.dart` | `functions/src/stateMachine.ts` (`assertPaymentStatusTransition`), `handlers.ts` (`recordPaymentStatus`, `adminModerateWorkRequest`), `storage.rules` (`/payment_proofs/`) | `functions/test/backend_security.test.mjs`, `test/mvp_media_phone_and_account_test.dart`, `test/admin_enterprise_devops_test.dart` |
| **Permanent Account Deletion (`deleteUserAccount`) & OS Dialers** | `lib/screens/account/account_extra_screens.dart`, `lib/screens/safety/safety_screens.dart`, `lib/state/auth_provider.dart` | `functions/src/handlers.ts` (`deleteUserAccount` active-order block, profile/KYC purge, `admin_audit_logs`, `getAuth().deleteUser`), `url_launcher` (`tel:999`) | `functions/test/backend_security.test.mjs`, `test/mvp_media_phone_and_account_test.dart` |
| **Guarded Admin Portal & Module 13 Worksite Ops** | `lib/admin_main.dart`, `lib/screens/admin/{admin_login_screen,admin_shell,admin_worksite_ops_screen}.dart`, `lib/state/admin_provider.dart` | `admin_staff/{uid}` server role lookup, `functions/src/handlers.ts` (`adminReviewProvider`, `adminModerateWorkRequest`), `admin_audit_logs` | `test/admin_enterprise_devops_test.dart`, `test/admin_web_test.dart`, `functions/test/backend_security.test.mjs` |
| **Qatar PDPL Legal Screen, Native Configs & Deferred MoT/QCB Flags** | `lib/screens/account/legal_and_backend_screens.dart`, `lib/firebase_options.dart`, `android/app/build.gradle.kts`, `ios/Runner/Info.plist`, `docs/QATAR_COMPLIANCE_AND_RELEASE_PLAYBOOK.md` | Feature flags (`enablePassengerRides = false`, `enableDigitalWallet = false`, `enableEscrowClaims = false`), `.gitignore` secret guards | `test/backend_readiness_and_screens_test.dart`, `test/mvp_worksite_ui_test.dart`, `test/universal_services_and_escrow_test.dart` |
