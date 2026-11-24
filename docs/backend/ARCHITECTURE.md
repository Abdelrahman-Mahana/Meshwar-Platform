# MASHWAR Platform — Backend & Systems Architecture
## Qatar Worksite Supply MVP Architecture, Service Boundaries & Runtime Governance

### 1. Architectural Overview & Layered Separation
MASHWAR is structured around a **Clean Layered Architecture** that separates Flutter presentation widgets, `Provider` state controllers, abstract domain contracts, and concrete data repositories. In Phase 1, runtime behavior is focused on the **Qatar Worksite Supply MVP** while keeping deferred mobility and wallet modules isolated behind compile-time feature flags in [`lib/core/config/app_environment.dart`](../../lib/core/config/app_environment.dart).

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                     Presentation Layer (Flutter UI)                      │
│  - Customer App (`lib/main.dart`): Auth, Home, Worksite Supply Flows     │
│  - Standalone Admin Portal (`lib/admin_main.dart`): Guarded `AdminShell` │
│    incl. Module 13 (`AdminWorksiteOpsScreen`: QID KYC, Settlements, Logs)│
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │
┌────────────────────────────────────▼─────────────────────────────────────┐
│               Application & State Layer (`ChangeNotifier`)               │
│  - Active MVP: `AppEnvironment` · `AuthProvider` · `WorksiteProvider`    │
│    `SettingsProvider` · `AdminProvider`                                  │
│  - Deferred (Flagged Off): `RidesProvider` · `ParcelsProvider`           │
│    `BoardProvider` · `AlertsProvider`                                    │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │
┌────────────────────────────────────▼─────────────────────────────────────┐
│                 Domain Layer (Models & Repository Contracts)             │
│  - Models: `MoneyMinor` (1 QAR = 100 dirhams) · `WorkRequest`            │
│    `WorkOffer` · `ProviderProfile` · `BusinessProfile` · `SavedWorksite` │
│    `RequestEvent` · `RequestRating` · `HandoverVerificationResult`       │
│  - Contracts: `IAuthRepository` · `IWorksiteRepository`                  │
│    `IProviderRepository` · `IChatRepository` · `IMapsRepository` · etc.  │
└────────────────────────────────────┬─────────────────────────────────────┘
                                     │
┌────────────────────────────────────▼─────────────────────────────────────┐
│             Data Access Layer (`AppRepositories` Service Locator)        │
│  - Production (`USE_FIREBASE=true`):                                     │
│    `FirebaseAuthRepository` · `FirebaseWorksiteRepository`               │
│    `FirebaseProviderRepository` · `FirebaseFunctionsCallableClient`      │
│  - Dev-Only (`APP_ENV=development && !USE_FIREBASE && USE_DEV_MOCKS`):   │
│    `AuthRepositoryImpl` · `WorksiteRepositoryImpl` · `ProviderRepoImpl`  │
└──────────────────┬───────────────────────────────────┬───────────────────┘
                   │                                   │
┌──────────────────▼──────────────────┐ ┌──────────────▼───────────────────┐
│ Firebase Cloud (`europe-west1`)     │ │ Maps & Qatar Geo Services        │
│ - Project: mashwar-qatar-2026-ec99d │ │ - `GoogleMapsService`            │
│ - Firebase Auth (Email/Password)    │ │   (`components=country:qa`)      │
│ - Cloud Firestore (Collections 1–29)│ │ - Offline Qatar Geo-Catalog      │
│ - Cloud Functions v2 (`nodejs20`)   │ │   (8 Municipalities / 22 Hubs)   │
│ - Cloud Storage (`storage.rules`)   │ │                                  │
└─────────────────────────────────────┘ └──────────────────────────────────┘
```

---

### 2. Runtime Environment & Fail-Closed Configuration (`AppEnvironment`)

Runtime configuration is resolved in [`lib/core/config/app_environment.dart`](../../lib/core/config/app_environment.dart) and documented in [`.env.example`](../../.env.example):

| Compile-Time Define | Values / Default | Architectural Behavior |
| :--- | :--- | :--- |
| `APP_ENV` | `development` (default) \| `staging` \| `production` | Selects `AppFlavor`. Non-development flavors **require** `USE_FIREBASE=true`. |
| `USE_FIREBASE` | `false` (default) \| `true` | Initializes `Firebase.initializeApp` (`DefaultFirebaseOptions.currentPlatform`) and switches `AppRepositories.instance.useFirebase()`. |
| `USE_DEV_MOCKS` | `false` (default) \| `true` | Permitted **only** when `APP_ENV == 'development'` and `USE_FIREBASE == false`. |
| `FIREBASE_PROJECT_ID` | `mashwar-qatar-2026-ec99d` | Target Firebase project identifier (matches `.firebaserc`). |
| `FIREBASE_REGION` | `europe-west1` | Target Cloud Functions v2 region (matches `functions/src/index.ts`). |
| `FUNCTIONS_BASE_URL` | `''` (optional) | Full callable base URL override in `FirebaseConfig`. |
| `FUNCTIONS_EMULATOR_HOST` | `''` (optional, e.g. `127.0.0.1:5001`) | Routes `FirebaseFunctionsCallableClient` to the local Functions Emulator. |
| `GOOGLE_MAPS_API_KEY` | `''` (optional) | Enables live Google Places/Directions/Geocoding (`country:qa`); falls back to local 22-hub Qatar catalog when empty. |

#### Fail-Closed Startup Guarantee (`initializeMashwarStartup`)
In [`lib/main.dart`](../../lib/main.dart):
1. If `USE_FIREBASE=true` and `Firebase.initializeApp` fails, or if `APP_ENV` is `staging`/`production` with `USE_FIREBASE=false`, the app renders **`ServiceUnavailableScreen`** with diagnostic details and a **Retry** action.
2. It **never** silently falls back to `MockData` or auto-authenticates a demo user in staging or production.
3. `SplashScreen` (`lib/screens/splash_screen.dart`) restores any persisted auth session via `AuthProvider.restoreSession()` and routes to `MainNavShell` **only** when `AuthStatus.authenticated`; otherwise it routes to `WelcomeScreen`.

---

### 3. MVP Phase 1 Feature Flags & Regulatory Scope

| Feature Flag | Value | Scope & Regulatory Prerequisite |
| :--- | :---: | :--- |
| `enableWorksiteSupply` | `true` | **Active MVP:** Qatar B2B/contractor material & hardware procurement runs priced in `QAR` (`MoneyMinor`). |
| `enablePassengerRides` | `false` | **Deferred:** Requires Qatar Ministry of Transport (MoT) passenger transport licensing. |
| `enableCarpooling` | `false` | **Deferred:** Requires Qatar MoT shared-mobility approval. |
| `enableCommercialCargo` | `false` | **Deferred:** Requires commercial freight transport licensing. |
| `enableDigitalWallet` | `false` | **Deferred:** Requires Qatar Central Bank (QCB) stored-value/PSP authorization (`AuthProvider` blocks `depositWalletFunds` / `withdrawWalletFunds`). |
| `enableEscrowClaims` | `false` | **Deferred:** Requires QCB-compliant financial escrow custody via a licensed PSP. |

> **Trademark & Licensing Notice:** The `MASHWAR / مشوار` brand requires independent trademark clearance in Qatar, and the repository owner holds no MoT transport license or QCB payment/escrow license. Phase 1 tracks only `cash_on_delivery` and `bank_transfer_manual` settlements.

---

### 4. Core Backend Subsystems

#### A. Firebase Authentication & Staff RBAC
- **Customer & Provider Auth (`FirebaseAuthRepository`):**
  - Email + Password registration (`createUserWithEmailAndPassword`), sign-in (`signInWithEmailAndPassword`), password reset (`sendPasswordResetEmail`), session hydration (`users/{uid}` with neutral zeroed defaults), and `signOut()`.
  - 11-digit Qatar ID (`QID`, regex `^[0-9]{11}$`) submission writes to `provider_verifications/{uid}` (`status: 'pending'`) and marks `users/{uid}.idVerificationStatus = 'underReview'`.
  - Phone SMS OTP (`sendPhoneOtp` / `verifyPhoneOtp`) explicitly throws `UnsupportedError('Phone OTP requires configured SMS provider')` until a `+974` SMS gateway is provisioned.
- **Admin Operations Auth (`AdminProvider` & `AdminLoginScreen`):**
  - `_isLoggedIn` defaults to `false`; `/admin` routes render `AdminLoginScreen` whenever unauthenticated.
  - `signInStaffWithFirebase(email, password)` authenticates with Firebase Auth, verifies an active document in `admin_staff/{uid}` (`isActive == true`), assigns the staff member's `AdminRole` strictly from the server-stored `role` (`superAdmin`, `reviewAdmin`, `supportAdmin`, `compliance`, `operations`), and writes an immutable entry to `admin_audit_logs`.

#### B. Cloud Firestore (`firestore.rules` & `firestore.indexes.json`)
- **Target Project:** `mashwar-qatar-2026-ec99d`.
- **Schema Preservation & Extension:** Preserves Collections `1–19` for platform compatibility and enforces strict schema/RBAC rules across Worksite Supply MVP Collections `20–29` (`business_profiles`, `provider_profiles`, `provider_verifications`, `work_requests`, `work_offers`, `work_request_secrets`, `work_request_handover_view`, `request_events`, `ratings`, `notifications`).
- **Composite Indexes:** 14 composite indexes defined in [`firestore.indexes.json`](../../firestore.indexes.json), including Worksite Supply feed, requester history, provider assignments, offers, timeline events, and ratings.

#### C. Cloud Functions v2 (`functions/`)
- **Runtime:** Node.js 20, TypeScript (`firebase-functions/v2/https` `onCall`, `firebase-admin`), deployed to `europe-west1`.
- **Authoritative Callables:** `createWorkRequest`, `submitWorkOffer`, `acceptWorkOffer`, `transitionWorkRequestStatus`, `verifyHandoverAndComplete`, `submitRequestRating`, `recordPaymentStatus`, `adminReviewProvider`, and `adminModerateWorkRequest`.
- **Client Transport (`FirebaseFunctionsCallableClient`):** Implemented in [`lib/data/services/firebase_firestore_service.dart`](../../lib/data/services/firebase_firestore_service.dart) over `package:http` using `Authorization: Bearer <Firebase ID Token>` so Web, Android, and iOS builds invoke v2 callables cleanly without `dart:io` or conflicting package constraints.

#### D. Cloud Storage (`storage.rules`)
- Default-deny ruleset enforcing authenticated access, `<= 10 MB` upload size cap, and `image/*` MIME validation across:
  - `/provider_verifications/{uid}/{file}` (owner upload; owner or admin read)
  - `/work_requests/{requestId}/reference/{file}` (requester upload; participant, admin, or approved provider on open requests read)
  - `/work_requests/{requestId}/invoices/{file}` (assigned approved provider upload; participant/admin read)
  - `/work_requests/{requestId}/payment_proofs/{file}` (requester upload; participant/admin read)

#### E. Google Maps & Qatar Offline Geo-Catalog (`GoogleMapsService`)
- Queries Google Places Autocomplete (`components=country:qa`), Directions (`region=qa`), and Reverse Geocoding when `GOOGLE_MAPS_API_KEY` is supplied.
- Falls back deterministically to `GoogleMapsService.qatarCitiesCatalog` covering **all 8 Qatari municipalities and 22 logistics/worksite hubs** (Doha, Industrial Area, Lusail, Al Rayyan, Al Wakrah, Al Khor, Mesaieed, Ras Laffan, Dukhan, Umm Salal, Al Daayen, Al Shamal, Al Shahaniya, The Pearl, Katara, Msheireb, Education City, Hamad International Airport, Al Sadd, West Bay/Dafna, Al Thakhira, Abu Samra).

---

### 5. Environment Matrix & Local Emulator Topology

Configured in [`firebase.json`](../../firebase.json) and [`.firebaserc`](../../.firebaserc):

| Environment | `APP_ENV` | `USE_FIREBASE` | `USE_DEV_MOCKS` | Backend Target |
| :--- | :---: | :---: | :---: | :--- |
| **Local Dev (Mock)** | `development` | `false` | `true` | In-memory deterministic Qatar Worksite Supply repo (`WorksiteRepositoryImpl`) |
| **Local Emulator** | `development` | `true` | `false` | Firebase Emulators (`auth:9099`, `functions:5001`, `firestore:8085`, `storage:9199`, `ui:4000`) |
| **Staging** | `staging` | `true` | `false` (forced) | Firebase project (`mashwar-qatar-2026-ec99d` or dedicated staging alias) |
| **Production** | `production` | `true` | `false` (forced) | `mashwar-qatar-2026-ec99d` (`europe-west1`) with restricted API keys |

> **Current Workstation Note:** `Node v24.19.0` and `Flutter 3.47.9` are active on the build machine, so `functions/` TypeScript compilation and `node --test` security suites run locally. Starting the JVM-based Firestore/Storage emulators requires installing a Java runtime (`Java 11+` / `Java 21 LTS`) and global `firebase-tools`.
