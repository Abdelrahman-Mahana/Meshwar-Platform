# Interactive Controls Matrix — MASHWAR Platform
## Ground-Truth Inventory of Qatar Worksite Supply MVP Controls, Admin Ops & Deferred Modules

> **Truthfulness Policy:** Every row below distinguishes **genuinely wired backend/repository actions** (`Active MVP`), **dev-mock-only shortcuts** (`Dev-Mock Only`), **controls blocked on external SDKs/providers** (`Blocked`), and **legacy prototype screens gated off in Phase 1** (`Deferred`).

---

### 1. Startup, Session & Authentication Controls

| Screen / Component | Interactive Control | Actual Runtime Behavior | Backing Service / Repository | Access / Guard | Status | Verification Test |
| :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| **`MashwarApp` (`ServiceUnavailableScreen`)** | "Retry / إعادة المحاولة" Button | Re-runs `initializeMashwarStartup()` and `AuthProvider.restoreSession()` when Firebase init failed or staging/prod booted without Firebase | `Firebase.initializeApp` + `AppRepositories.useFirebase()` | Public (Fail-Closed Guard) | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`SplashScreen`** | Session Restore & Auto-Route | Calls `AuthProvider.restoreSession()`; routes to `MainNavShell` **only** if `AuthStatus.authenticated`, else `WelcomeScreen` | `AuthProvider` / `IAuthRepository` | Public | **Active MVP** | `test/uber_live_map_and_onboarding_test.dart` |
| **`WelcomeScreen`** | Language Toggle (`عربي` / `English`) | Toggles `SettingsProvider` locale (`ar_QA` RTL <-> `en_US` LTR) and persists preference | `SettingsProvider` (`SharedPreferences`) | Public | **Active MVP** | `test/dynamic_language_switcher_test.dart` |
| **`WelcomeScreen` / `EmailInputScreen`** | Email + Password Sign In & Create Account | Validates email & password (`>= 6` chars), calls `AuthProvider.loginWithEmail` / `registerWithEmail`, hydrates `users/{uid}` | `FirebaseAuthRepository` (`FirebaseAuth` + `users/{uid}`) | Public | **Active MVP** | `test/mvp_models_and_auth_test.dart`, `test/email_auth_test.dart` |
| **`EmailInputScreen`** | Password Reset Action | Dispatches `AuthProvider.sendPasswordReset(email)` | `FirebaseAuth.sendPasswordResetEmail` | Public | **Active MVP** | `test/mvp_models_and_auth_test.dart` |
| **`WelcomeScreen`** | Dev Quick-Demo Entry | Appears **only** when `AppEnvironment.useDevMocks == true` (`APP_ENV=development && !USE_FIREBASE`) | `AuthRepositoryImpl` (Dev-Gated) | Dev-Mock Only | **Dev-Mock Only** | `test/mvp_models_and_auth_test.dart` |
| **`PhoneInputScreen`** | `+974` Mobile Input & Request OTP | Validates 8-digit Qatar mobile (`^[3567][0-9]{7}$`); in real mode `sendPhoneOtp` throws `UnsupportedError` until SMS provider is configured | `AuthProvider.validateQatarPhone` / `FirebaseAuthRepository` | Public | **Blocked (SMS Provider)** | `test/phone_input_test.dart`, `test/mvp_models_and_auth_test.dart` |

---

### 2. Customer & Approved Provider Worksite Supply Controls (MVP Phase 1)

| Screen / Component | Interactive Control | Actual Runtime Behavior | Backing Service / Repository | Access / Guard | Status | Verification Test |
| :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| **`MainNavShell` (MVP Mode)** | 4-Tab Navigation (`Home`, `Requests`, `My Activity`, `Account`) | Switches focused Worksite Supply tabs when `enablePassengerRides == false` | `WorksiteProvider`, `AuthProvider` | Authenticated User | **Active MVP** | `test/mvp_worksite_ui_test.dart` |
| **`HomeScreen`** | "Create a Request" / "Browse Requests" / Quick Reorder | Launches 3-step request builder, opens Qatar worksite feed, or prefills `WorkRequestReorderDraft` via `buildReorderDraft()` | `WorksiteProvider` | Authenticated User | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`CreateWorkRequestScreen`** | 3-Step Supply Request Form & Publish CTA | Validates items, pickup store, Qatar municipality/worksite, QAR budget -> integer `MoneyMinor`, and `cash_on_delivery` / `bank_transfer_manual`; creates `work_requests` in `open` status | `WorksiteProvider.createRequest` -> `createWorkRequest` / Firestore | Authenticated Requester | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`WorkRequestsFeedScreen`** | Qatar Municipality, Status & Max-Budget Filters + Retry | Filters `work_requests` via `WorksiteProvider.applyFilters(...)` and handles empty/error retry states | `WorksiteProvider` / `IWorksiteRepository.listRequests` | Authenticated User | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`WorkRequestDetailsScreen`** | "Submit Offer" Sheet | Submits integer `proposedFeeMinor`, `estimatedItemsCostMinor`, and `etaMinutes` (`open -> offer_received`) | `WorksiteProvider.submitOffer` -> `submitWorkOffer` callable | **Approved Provider Only** (`approvalStatus == 'approved'`, `uid != requesterId`) | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`WorkRequestDetailsScreen`** | "Accept Offer" Button | Selects offer, rejects competing offers, locks agreed QAR minor amounts, and generates salted SHA-256 6-char handover code | `WorksiteProvider.acceptOffer` -> `acceptWorkOffer` callable | Request Owner (`requesterId == uid`) | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`WorkRequestDetailsScreen`** | Requester Handover Code Card | Reads and displays the 6-char `[A-HJ-NP-Z2-9]` handover code + expiry exclusively to the requester | `work_request_handover_view/{requestId}` | Request Owner Only (`allow write: if false`) | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`WorkRequestDetailsScreen`** | Provider Fulfillment Stage Controls & Invoice URL Attachment | Advances `accepted -> in_progress -> picked_up -> in_transit -> delivered_pending_confirmation` with store invoice URLs | `WorksiteProvider.advanceStatus` -> `transitionWorkRequestStatus` callable | Assigned Approved Provider | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`WorkRequestDetailsScreen`** | Provider 6-Char Handover Verification Modal | Submits 6-char code to `verifyHandoverCode`; enforces constant-time SHA-256 check, 5-attempt cap, 24h TTL, single-use -> `completed` | `WorksiteProvider.verifyHandoverCode` -> `verifyHandoverAndComplete` callable | Assigned Approved Provider | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`WorkRequestDetailsScreen`** | Manual Bank Transfer Proof Submission | Submits transfer receipt URL (`unpaid -> transfer_proof_submitted`) when `paymentMethod == 'bank_transfer_manual'` | `WorksiteProvider.submitTransferProof` -> `recordPaymentStatus` callable | Request Owner | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`WorkRequestDetailsScreen`** | Mutual Rating Modal (`1–5` Stars) | Submits single post-completion rating (`${requestId}_${uid}`) and updates running profile average | `WorksiteProvider.submitRating` -> `submitRequestRating` callable | Request Participant (`status == 'completed'`) | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`WorkRequestDetailsScreen`** | Dispute Reporting Modal & Contextual Chat Button | Flags active request as `disputed` (`reportDispute`) or opens participant `ChatScreen` | `WorksiteProvider` / `IChatRepository` | Request Participant | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`ProviderProfileScreen`** | Provider Profile, 11-Digit QID KYC & Saved Worksites | Saves `provider_profiles/{uid}`, submits 11-digit QID to `provider_verifications/{uid}` (`pending`), and manages `SavedWorksite` records | `WorksiteProvider` / `IProviderRepository` | Authenticated User | **Active MVP** | `test/mvp_worksite_provider_and_repo_test.dart` |
| **`SettingsScreen` / `Account`** | Sign Out Button | Calls `AuthProvider.logout()` -> `IAuthRepository.signOut()` and returns to `WelcomeScreen` | `FirebaseAuth.signOut()` | Authenticated User | **Active MVP** | `test/mvp_models_and_auth_test.dart`, `test/settings_screen_test.dart` |

---

### 3. Enterprise Admin Portal Controls (`lib/admin_main.dart` / `/admin`)

| Screen / Module | Interactive Control | Actual Runtime Behavior | Backing Service / Repository | Access / Guard | Status | Verification Test |
| :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| **`AdminShell` & `AdminLoginScreen`** | Staff Email + Password Login & Route Guard | Blocks unauthenticated `/admin` access; signs in via Firebase Auth, checks active `admin_staff/{uid}` (`isActive == true`), binds server `role`, logs `admin_audit_logs` (hides local role chips unless `useDevMocks`) | `AdminProvider.signInStaffWithFirebase` (`FirebaseAuth` + `admin_staff` + `admin_audit_logs`) | Active Staff Only | **Active MVP** | `test/admin_enterprise_devops_test.dart`, `test/admin_web_test.dart` |
| **Module `13`: `AdminWorksiteOpsScreen` (Tab A)** | Provider 11-Digit QID KYC Review (`Approve` / `Reject` / `Suspend`) | Reviews `provider_verifications` + `provider_profiles`, enforces mandatory reason on reject/suspend, invokes `adminReviewProvider`, appends `admin_audit_logs` | `adminReviewProvider` callable / Firestore | `superAdmin`, `reviewAdmin`, `compliance`, `operations` | **Active MVP** | `test/admin_enterprise_devops_test.dart` |
| **Module `13`: `AdminWorksiteOpsScreen` (Tab B)** | Payment Settlement Verification & Request Moderation | Verifies `transfer_proof_submitted -> verified_settled` (immutable thereafter) and resolves/cancels `disputed` requests via `adminModerateWorkRequest` | `adminModerateWorkRequest` callable / Firestore | Authorized Active Staff | **Active MVP** | `test/admin_enterprise_devops_test.dart` |
| **Module `13`: `AdminWorksiteOpsScreen` (Tab C) & `AdminAuditLogScreen`** | Privileged Audit Trail Filter & JSON Export | Filters and copies/exports immutable `admin_audit_logs` entries | Firestore `admin_audit_logs` | Active Staff | **Active MVP** | `test/admin_enterprise_devops_test.dart` |
| **`AdminInquiriesScreen`** | Sync Investor Inquiries | Reads live submissions written by `landing_page/js/firebase-contact.js` from `investor_inquiries` | Firestore `investor_inquiries` | Active Staff | **Active MVP** | `test/admin_web_test.dart` |

---

### 4. Deferred or SDK-Blocked Legacy Controls (Not Active in Phase 1 MVP)

| Screen / Area | Control | Actual State in Codebase | Status & Prerequisite |
| :--- | :--- | :--- | :--- |
| **`Rides`, `Carpooling`, `PublishRide`, `Booking*`** | Search/Publish/Book Passenger Rides | Preserved in codebase behind `AppEnvironment.enablePassengerRides = false` & `enableCarpooling = false` | **Deferred** (Pending Qatar MoT licensing) |
| **`SendParcelScreen`, `ParcelTrackingScreen`** | Inter-City Crowd-Shipping | Preserved behind `AppEnvironment.enableCommercialCargo = false` | **Deferred** (Pending cargo/courier licensing) |
| **`WalletScreen` & `ServiceEscrowScreen`** | Digital Wallet Top-Up/Withdraw & Bilateral Escrow UI | `AuthProvider` blocks wallet mutations while `enableDigitalWallet == false`; `ServiceEscrowScreen` is a local UI prototype gated behind `enableEscrowClaims = false` | **Deferred** (Pending QCB payment/escrow compliance & licensed PSP) |
| **`EmergencySosSheet`** | Qatar Emergency `999` Action | Displays UI feedback only; `url_launcher` (`tel:999`) is not yet added to `pubspec.yaml` | **Blocked (Pending `url_launcher` SDK)** |
| **`DeleteAccountScreen`** | Account Deletion Action | Signs out locally; requires server-side `deleteUserAccount` Cloud Function for full Auth + Firestore PII purge | **Blocked (Pending Server Purge Callable)** |
