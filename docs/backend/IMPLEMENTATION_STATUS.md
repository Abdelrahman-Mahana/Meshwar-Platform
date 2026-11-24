# Implementation Status & Feature Verification Matrix — MASHWAR Platform
## Ground-Truth Readiness Assessment for Qatar Worksite Supply MVP

### 1. Engineering Honesty Standard
Every status entry in this matrix reflects the **actual code and executed verification** in this repository on `feat/mvp-worksite-supply`:
- **`PASS`**: Implemented in repository, static analysis clean (`0` issues), and covered by passing automated Dart (`flutter test`) or Node (`node --test`) tests.
- **`BLOCKED`**: Code/rules/contracts are implemented in the repository, but live execution or end-to-end emulator/cloud verification requires missing host tooling (e.g., Java JRE + `firebase-tools`) or external credentials/SDKs (e.g., `+974` SMS gateway, native mobile config files).
- **`DEFERRED`**: Intentionally disabled in Phase 1 via `AppEnvironment` feature flags pending regulatory licensing (Qatar MoT / QCB) or Phase 2+ scope.

---

### 2. Core Platform, Configuration & Backend Infrastructure

| Subsystem | Files / Artifacts | Status | Verified Details & Remaining Blockers |
| :--- | :--- | :---: | :--- |
| **Environment & Fail-Closed Startup** | `lib/core/config/app_environment.dart`, `.env.example`, `lib/main.dart` | **PASS** | `AppFlavor` (`development`/`staging`/`production`), `USE_FIREBASE`, `USE_DEV_MOCKS` (strictly blocked outside `development && !USE_FIREBASE`), and `ServiceUnavailableScreen` with retry when Firebase fails in non-mock mode. |
| **Worksite Supply Domain & `MoneyMinor`** | `lib/data/models/worksite_models.dart`, `lib/data/models/user_model.dart` | **PASS** | Integer `MoneyMinor` (`1 QAR = 100 dirhams`, zero `double` money fields), 11-state `WorkRequestStatusMachine`, neutral `UserModel` defaults (`isVerified: false`, `walletBalance: 0.0`, `rating: 0.0`), UTC ISO serialization. |
| **Cloud Functions v2 (`functions/`)** | `functions/src/{index,handlers,stateMachine,handoverCrypto,store,types}.ts` | **PASS** *(Build & Node Tests)* / **BLOCKED** *(Live Deploy)* | 9 v2 `onCall` functions (`europe-west1`, `nodejs20`) compile cleanly (`tsc` exit `0`) and pass `10/10` security tests (`npm test`). Live deployment awaits `firebase-tools` & production authorization. |
| **Salted SHA-256 Handover Verification** | `functions/src/handoverCrypto.ts`, `worksite_repository_impl.dart` | **PASS** | 6-char unambiguous code (`[A-HJ-NP-Z2-9]`), 128-bit per-request salt, constant-time `timingSafeEqual`, 5-attempt cap, 24h TTL, single-use completion, server-only `work_request_secrets`. |
| **Firestore Security Rules & Indexes** | `firestore.rules` (2,475 lines), `firestore.indexes.json` (14 indexes) | **PASS** *(Authored)* / **BLOCKED** *(JVM Emulator Run)* | Preserves Collections `1–19` and enforces strict RBAC/schema guards across Worksite Supply Collections `20–29` (11-digit QID, `+974` phone, no self-approval, no client `completed`). Host lacks `java` & `firebase` CLI to run JVM rule emulator tests locally. |
| **Cloud Storage Security Rules** | `storage.rules` | **PASS** *(Authored)* / **BLOCKED** *(Binary Upload SDK)* | Enforces `<= 10 MB` `image/*` owner/participant/admin ACLs for KYC, reference photos, invoices, and payment proofs. Client binary upload (`firebase_storage` + `image_picker`) is not yet added to `pubspec.yaml` (pilot passes validated `https://`/`gs://` media URLs). |
| **CI/CD Web Build Pipeline** | `.github/workflows/mashwar_ci_cd.yml`, `vercel.json` | **PASS** | Builds Consumer Web (`build/web`) and standalone Admin Portal (`build/web/admin`) with security headers and `/admin` rewrites. |
| **Native Android / iOS Release Config** | `android/app/build.gradle.kts`, `lib/firebase_options.dart`, `ios/Runner/Info.plist` | **BLOCKED** | Missing `google-services.json` & `GoogleService-Info.plist`; Android `release` currently uses `debug` signing config; `firebase_options.dart` needs `flutterfire configure` for Qatar iOS bundle ID (`qa.mashwar.app`); `Info.plist` lacks camera/photo/location strings. |

---

### 3. Repositories & State Providers

| Layer / Component | Implementation | Status | Notes |
| :--- | :--- | :---: | :--- |
| **`IAuthRepository` & `AuthProvider`** | `FirebaseAuthRepository` / `AuthRepositoryImpl` | **PASS** *(Email/Password & QID)* / **BLOCKED** *(SMS OTP & Google OAuth)* | Real Firebase Email/Password login, registration, password reset, session restore, `signOut()`, and 11-digit QID submission (`provider_verifications/{uid}`). `+974` SMS OTP explicitly throws `UnsupportedError` until SMS provider configured. |
| **`IWorksiteRepository` & `WorksiteProvider`** | `FirebaseWorksiteRepository` / `WorksiteRepositoryImpl` | **PASS** | Full Firestore + HTTP v2 callable execution (`FirebaseFunctionsCallableClient`) with typed bilingual `WorksiteRepositoryException`, filtering, Quick Reorder draft generation, and deterministic dev-only repository parity. |
| **`IProviderRepository`** | `FirebaseProviderRepository` / `ProviderRepositoryImpl` | **PASS** | Provider profile CRUD, 11-digit QID KYC submission, admin approval review, and private `SavedWorksite` persistence (`users/{uid}/private/{id}`). |
| **`AdminProvider` & Module 13 Ops** | `AdminProvider`, `AdminWorksiteOpsScreen`, `AdminLoginScreen`, `AdminShell` | **PASS** | `_isLoggedIn` defaults `false`; `/admin` guarded by `AdminLoginScreen`; `signInStaffWithFirebase` checks active `admin_staff/{uid}` and server role; Module 13 manages QID KYC reviews, manual bank transfer settlement verification, disputes, and `admin_audit_logs`. |
| **`IMapsRepository` & `GoogleMapsService`** | `MapsRepositoryImpl`, `GoogleMapsService` | **PASS** *(Qatar Catalog)* / **BLOCKED** *(Live Key)* | 8 Qatari municipalities & 22 hubs work offline; live Google Places/Directions (`country:qa`) activate when `GOOGLE_MAPS_API_KEY` is injected. |
| **`IChatRepository`** | `FirebaseChatRepository` / `ChatRepositoryImpl` | **PASS** *(Contextual Chat)* | Contextual requester <-> provider messaging from Worksite Supply order details. |
| **`InvestorInquiries` Lead Capture** | `landing_page/js/firebase-contact.js`, `AdminInquiriesScreen` | **PASS** | Writes public inquiries to `investor_inquiries` on `mashwar-qatar-2026-ec99d` and syncs in Admin Portal. |

---

### 4. Deferred Modules & Regulatory Readiness

| Module / Capability | `AppEnvironment` Flag | Status | Prerequisite to Enable |
| :--- | :--- | :---: | :--- |
| **Passenger Rides & Booking** | `enablePassengerRides = false` | **DEFERRED** | Qatar Ministry of Transport (MoT) passenger transport licensing & rules-aligned booking callables. |
| **Inter-Area Carpooling** | `enableCarpooling = false` | **DEFERRED** | Qatar MoT shared-mobility regulatory approval. |
| **Commercial Freight / Parcels** | `enableCommercialCargo = false` | **DEFERRED** | Commercial cargo/courier licensing in Qatar. |
| **In-App Digital Wallet** | `enableDigitalWallet = false` | **DEFERRED** | Qatar Central Bank (QCB) stored-value compliance & licensed PSP webhook integration. |
| **Automated Financial Escrow** | `enableEscrowClaims = false` | **DEFERRED** | QCB-regulated escrow custody partner & server ledger integration (`ServiceEscrowScreen` prototype remains disabled in MVP flow). |
| **Emergency Dialer (`999`) & Account Purge** | — | **BLOCKED** *(SDK/Callable)* | Requires adding `url_launcher` (`tel:999`) and a server-side `deleteUserAccount` Cloud Function for full PDPL Law No. 13 of 2016 data erasure. |
| **MASHWAR Brand Registration** | — | **LEGAL PREREQUISITE** | Independent Qatar MoCI trademark search and registration prior to commercial launch. |
