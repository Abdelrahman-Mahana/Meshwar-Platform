# MASHWAR Platform — Principal Engineering Audit

**Audit Baseline Commit:** `b86e8cb` (`b86e8cbe8468b1f6cf4ed0b56643575e93bc1e67`)  
**Post-Hardening Verified Commit:** `851d22d` (`851d22d7045dc59363512534b044d27f82f75e9c`)  
**Branch:** `main`  
**Audit Scope:** Full-stack audit across Flutter Consumer Web/Mobile App (`lib/`), Standalone Admin & DevOps Command Center (`lib/admin_main.dart`), TypeScript Cloud Functions v2 (`functions/`), Firestore & Cloud Storage Security Rules (`firestore.rules`, `storage.rules`), Firestore Indexes (`firestore.indexes.json`), Embedded Map Engine (`web/maps/`, `landing_page/maps/`), Qatar Marketing Landing Page (`landing_page/`), Vercel Routing/Headers (`vercel.json`), and GitHub Actions CI/CD (`.github/workflows/mashwar_ci_cd.yml`).

---

## 1. Executive Summary & Product Understanding

**MASHWAR (مشوار)** is a bilingual (Arabic RTL / English LTR) Qatar inter-city mobility and worksite logistics platform structured around three operational pillars:

1. **Worksite Supply (Primary MVP Pillar):** Connects requesters (contractors, site engineers, households) with QID-verified providers for same-day materials/equipment delivery under a **Direct Settlement** model (Cash on Delivery or verified bank transfer proof — zero platform escrow custody) secured by a server-issued 6-character salted SHA-256 handover verification code.
2. **Inter-City Rides (Carpooling):** Connects Qatar commuters across 8 municipalities, 38 geo-hubs, and 14 inter-city corridors (including Ladies-Only trip filters).
3. **Same-Day Crowd-Shipping (Parcels & Service Board):** Enables peer-to-peer parcel transport with dual pickup/delivery OTP handover and an open request/offer marketplace board.

### Technology Stack & Repository Footprint (at `851d22d`)

| Layer | Technology / Runtime | Measured Footprint |
| --- | --- | --- |
| **Consumer & Admin Frontend** | Flutter Web / Mobile (Dart SDK `>=3.0.0 <4.0.0`), Provider (`^6.1.2`), Google Fonts (`^6.2.1`) | 150 Dart files in `lib/`, 29 test suites in `test/` |
| **Backend Compute** | Firebase Cloud Functions v2 (`europe-west1`), Node.js 20, TypeScript `5.7.2`, `firebase-admin` `^12.7.0`, `firebase-functions` `^6.1.1` | 11 callable functions in `functions/src/index.ts`, 2 test suites in `functions/test/` |
| **Database & Storage** | Cloud Firestore + Cloud Storage | `firestore.rules` (2,732 lines), `storage.rules` (163 lines), `firestore.indexes.json` (194 lines) |
| **Map Engine** | Self-hosted Leaflet + custom HTML/JS bridge (`mashwar_uber_map.html`) | Embedded via same-origin `<iframe>` in Flutter Web and Landing Page |
| **Marketing Landing Page** | Static HTML5 / Vanilla JS (`landing_page/index.html`, `js/app.js`, `js/i18n.js`, `js/firebase-contact.js`) | 256 AR/EN i18n keys, live Firestore `investor_inquiries` integration |
| **Hosting & CI/CD** | Vercel (`vercel.json`), GitHub Actions (`.github/workflows/mashwar_ci_cd.yml`) | Consumer `/`, Admin `/admin/`, Health `/health.json` |

### Baseline Condition at `b86e8cb`

At baseline commit `b86e8cb`, static analysis passed (`flutter analyze`: 0 issues) and Cloud Functions unit tests passed (11/11), creating a surface impression of readiness. Deep code, rules, repository, and runtime inspection uncovered **critical production-blocking failures** across every layer:

- **Deployment blocker:** `vercel.json` emitted a global `X-Frame-Options: DENY` header that broke every same-origin `/maps/mashwar_uber_map.html` iframe in production.
- **Security bypasses:** `firestore.rules` allowed carriers to transition parcels `accepted -> handedOver` without submitting `pickupOtp`, skipped `deliveryOtp` checks entirely on `inTransit -> delivered`, left `admin_audit_logs` unvalidated, and permitted `image/svg+xml` uploads in `storage.rules` (stored XSS vector).
- **Schema & index breakage:** Live writes from `FirebaseAuthRepository.submitNationalId()`, `AdminProvider._persistSnapshot()`, and Cloud Functions (`handlers.ts`) conflicted with `firestore.rules` field whitelists and timestamp expectations, while 8 active Firestore queries lacked required composite indexes.
- **Silent data fabrication & client-side simulations:** `BookingWaitingScreen` auto-confirmed after 4.5s regardless of driver response; `ReportIssueScreen` showed a hardcoded fake ticket `#5127`; `ServiceEscrowScreen` unlocked on any 4 digits; `FirebaseRidesRepository.bookRide()` never decremented seats for passengers and fabricated confirmed bookings on error; `FirebaseWalletRepository` returned `true` on `PERMISSION_DENIED`; `AdminProvider` displayed hardcoded mock KPIs and fake seed records in live mode.
- **Localization & memory hygiene defects:** `AppStrings.translateDate()` corrupted Arabic words containing `ص`/`م` (`صباحاً` → `AMباحاً`), Admin portal leaked Arabic strings across English KPIs/filters, and 48 modal/bottom-sheet `TextEditingController`s leaked without disposal.

All P0 blockers and the majority of P1/P2 defects were remediated in commits `c227960` through `851d22d` and verified against live emulators and headless Edge CDP (see `TESTING_REPORT.md`). Remaining architectural and external blockers are explicitly tracked below.

---

## 2. Domain-by-Domain Technical Audit

### 2.1 Functional & Product Consistency Audit
- **Direct Settlement vs. Legacy Escrow Contradiction:** Legal disclosures (`lib/screens/account/legal_and_backend_screens.dart`) explicitly state MASHWAR operates with no prepaid wallets and no escrow custody. At `b86e8cb`, `settings_screen.dart`, `booking_confirmation_screen.dart`, `chat_screen.dart`, `service_escrow_screen.dart`, `web/health.json`, and `landing_page/index.html` contradicted this by advertising "6 Services", "12 Admin Modules", and active "Bilateral Escrow". **Status:** Resolved across consumer UI, `health.json`, and landing page SSR/JS; legacy Admin Escrow tab copy remains partially retained for historical/test compatibility.
- **Consumer Flow Integrity:** Live consumer screens (`BookingWaitingScreen`, `ReportIssueScreen`, `EmergencyContactsScreen`, `DriverRequestsScreen`, `DriverPreTripScreen`, `BoardAdOffersScreen`, `ParcelDisputeScreen`) contained hardcoded mock arrays, fake timers, or boolean-toggle uploads. **Status:** All P0 live simulations replaced with live provider/Firestore bindings and real `MediaUploadService` uploads.

### 2.2 Frontend & UI/UX Audit
- **Localization (AR RTL / EN LTR):** `AppStrings.translateDate()` lacked word boundaries on `ص`/`م` and covered only 2 of 12 months. Admin screens stored localized Arabic display labels (`'الكل'`) as filter state, breaking filters on language switch, and hardcoded Arabic KPI subtexts (`'7 أيام'`, `'نسبة التحويل'`, `'نجاح'`, `'ر.ق'`). **Status:** Fixed with regex lookarounds, 12-month support, canonical filter keys, and `AdminProvider.periodLabelFor` / `kpi*For(isAr)` helpers (verified 0 Arabic leaks in live English Admin portal).
- **Admin Portal Entry & Dark NOC Mode:** `lib/admin_main.dart` omitted `AppLocalizations.delegate`, dropped Cairo typography in `darkTheme`, and silently swallowed Firebase startup failures. Multiple Admin dialogs hardcoded `Colors.white` / `Color(0xFFF8FAFC)`. **Status:** Fixed (`ServiceUnavailableScreen` gate, Cairo dark theme, `AdminThemeTokens` adoption).
- **Accessibility & Forms:** 124+ `IconButton`s lacked `tooltip:`, only 7 `Semantics()` widgets existed across `lib/`, and several consumer forms pre-filled fake Arabic sample values (`'55123456'`, `'نورة الكواري'`). **Status:** Live-mode prefills cleared; bilingual tooltips added to touched screens; full app-wide `Semantics` audit remains P2 backlog.

### 2.3 Backend & Cloud Functions v2 Audit
- **Worksite Supply State Machine & Crypto (`functions/src/stateMachine.ts`, `handoverCrypto.ts`):** Sound design. Unambiguous 32-symbol 6-char alphabet (zero modulo bias), 128-bit per-request hex salt, SHA-256 hash, constant-time `crypto.timingSafeEqual`, 24h TTL, 5-attempt cap, strict linear fulfillment transitions, immutable `verified_settled` state.
- **Schema & Feature Completeness (`functions/src/handlers.ts`):** At `b86e8cb`, `createWorkRequest`, `recordPaymentStatus`, `submitRequestRating`, and `transitionWorkRequestStatus` dropped extended worksite fields; `adminReviewProvider` wrote invalid status `'suspended'` to `provider_verifications`; `withdrawWorkOffer` had no callable; `AdminRole` lacked `financeAdmin`/`devopsAdmin`. **Status:** Fixed and covered by 13/13 passing Cloud Functions unit tests (`148d4b5`).
- **Remaining Backend Gaps:**
  - `deleteUserAccount` (`handlers.ts`) runs deletes outside a single atomic transaction and does not purge `users/{uid}/private/*`, `work_offers`, `route_alerts`, `notifications`, `driver_verifications`, or Firebase Storage KYC prefixes.
  - Ride booking/cancellation, board offer parent sync, and non-worksite Admin mutations are not yet backed by transactional Cloud Functions.

### 2.4 Database & Storage Architecture Audit
- **Schema Alignment:** `firestore.rules` rejected valid writes from `FirebaseAuthRepository.submitNationalId()` (wrong keys), `AdminProvider._persistSnapshot()` (dumping nested maps into `platform_config/global`), and Cloud Functions (`paymentVerifiedBy`, `paymentVerifiedAtUtc`, `moderationNotes`, `completedAtUtc`, ISO timestamps). **Status:** Fixed in `c227960` and `29553b8`; validated against live Firestore Emulator (10/10 PASS).
- **Composite Indexes (`firestore.indexes.json`):** 8 live queries lacked composite indexes across `work_requests`, `board_ads` (3), `rides` (2), `users/{uid}/private`, and `work_offers`. **Status:** All 8 composite indexes added in `148d4b5`.
- **Storage Rules (`storage.rules`):** Wildcard `image/.*` allowed `image/svg+xml`, and avatars/driver licenses/chat attachments were blocked by default-deny. **Status:** Replaced with explicit raster MIME allowlist (`jpeg`, `png`, `webp`, `gif`, `heic`, `heif`) and added scoped `users/{uid}/avatar/{file}`, `driver_verifications/{uid}/{file}`, and `conversations/{convId}/{file}` rules (`<= 10 MB`).

### 2.5 Security & AppSec Audit
- **Closed Vulnerabilities:**
  1. Parcel pickup OTP bypass (`!('submittedOtp' in ...)` omitted check) and missing delivery OTP verification in `firestore.rules` — **Closed (`c227960`)**.
  2. Fail-open `verifyDeliveryOtp()` in `FirebaseParcelsRepository` — **Closed (`29553b8`)**.
  3. Stored XSS via `image/svg+xml` in `storage.rules` & `MediaUploadService` — **Closed (`148d4b5`, `29553b8`)**.
  4. IDOR in `FirebaseBoardRepository.getMySentOffers()` returning other users' `board_ads` — **Closed (`29553b8`)**.
  5. Unvalidated `admin_audit_logs` writes and dead unrestricted `users_public` collection in `firestore.rules` — **Closed (`c227960`)**.
  6. Missing HSTS and frame-blocking `X-Frame-Options: DENY` on map routes in `vercel.json` — **Closed (`148d4b5`)**.
  7. Inverted `enableDigitalWallet` guard in `AuthProvider` allowing authenticated users to bypass disabled wallet flag — **Closed (`29553b8`)**.
- **Open Security Risks (Tracked in Roadmap & Production Readiness):**
  1. **Three-Way Admin RBAC Split:** `firestore.rules` checks Auth Custom Claims only; `functions/src/handlers.ts` checks `admin_staff/{uid}` only; `storage.rules` checks both.
  2. **No Firebase App Check / Rate Limiting:** Unconfigured on Flutter clients and Cloud Functions (`enforceAppCheck: true` absent); public `investor_inquiries` Firestore writes and `formsubmit.co` remain unthrottled.
  3. **Committed Client API Keys in `lib/firebase_options.dart`:** CI builds with `USE_FIREBASE=true` without injecting `--dart-define=FIREBASE_WEB_API_KEY` from GitHub Secrets (while Firebase Web API keys are public identifiers, key restriction/rotation hygiene should move them to Secrets + HTTP referrer restrictions).
  4. **Missing Top-Level CSP:** `vercel.json` sets `Content-Security-Policy: frame-ancestors 'self'` on `/maps/(.*)` and `/admin/maps/(.*)`, but does not yet enforce a full root CSP on `/(.*)`.

### 2.6 Performance & Resource Hygiene Audit
- **Fixed in Hardening:**
  - Disposed all 48 leaked modal/bottom-sheet `TextEditingController`s across 15 files (`fc400af`).
  - Removed root `Consumer2<SettingsProvider, AdminProvider>` wrapper in `lib/main.dart`, preventing every `AdminProvider` notify from rebuilding `MaterialApp` (`fc400af`).
  - Fixed `_TelemetryChartPainter.shouldRepaint` unconditionally returning `true` (`fc400af`).
  - Paused 60fps `requestAnimationFrame` vehicle animation in `mashwar_uber_map.html` on `document.hidden` and `prefers-reduced-motion: reduce` (`148d4b5`).
  - Added `StreamController` eviction and `dispose()` to `FirebaseChatRepository` (`29553b8`).
  - Reused `FirebaseFunctionsCallableClient` with timeouts in `_FirebaseAdminBackendGateway` (`29553b8`).
  - Deleted 21 unused image assets (~5.55 MB dead weight across `assets/images/` and `landing_page/assets/`).
- **Remaining Performance Optimizations:**
  - `assets/images/` still totals ~7.48 MB (several unoptimized 700–870 KB JPEGs should be converted to WebP `<150 KB`).
  - 87 occurrences of raw `fontFamily: 'Cairo'` across 18 files without bundled `fonts:` in `pubspec.yaml` risk system-font FOUT before `google_fonts` registers the family.
  - `FirebaseFirestoreService` and `GoogleMapsService` instantiate `http.Client()` without an explicit `.close()` lifecycle.

### 2.7 Code Quality & Maintainability Audit
- **Cleaned Up:** Deleted orphan `lib/data/services/api_client.dart`, unreachable `_buildResolvedView` (`parcel_dispute_screen.dart`), dead `OffRouteAlertSheet` (`safety_screens.dart`), dead `users_public` matcher (`firestore.rules`), and consolidated duplicated 14-city Qatar matching logic from 3 providers into `lib/data/services/qatar_city_matcher.dart`.
- **Remaining Tech Debt:**
  - Monolithic screen files remain large (`home_screen.dart` ~3,865 L, `work_request_details_screen.dart` ~2,914 L, `account_extra_screens.dart` ~2,639 L, `main_nav_shell.dart` ~2,626 L, `driver_rides_management_screens.dart` ~2,544 L).
  - Byte-identical map engine (`web/maps/mashwar_uber_map.html` and `landing_page/maps/mashwar_uber_map.html`, plus duplicated `leaflet.js`/`leaflet.css`) should be generated from a single source in the build script.
  - `lib/data/api/mashwar_api_client.dart` still serves static mock telemetry logs for `AdminDevOpsSreScreen`.
  - `AlertsProvider` accesses `FirebaseFirestore.instance` directly rather than through an `IAlertsRepository`.

---

## 3. Six-Category Principal Gap Analysis

### Category 1: Correct & Complete

| Area | Location | Verification Evidence |
| --- | --- | --- |
| Salted SHA-256 Handover Crypto | `functions/src/handoverCrypto.ts` | 32-symbol alphabet, 128-bit hex salt, `timingSafeEqual`, 24h TTL, 5-attempt cap; `backend_security.test.mjs` PASS |
| Worksite Supply State Machine | `functions/src/stateMachine.ts` | Strict linear transitions; `completed` gated to `verifyHandoverAndComplete`; `verified_settled` immutable |
| Secret & Handover View Isolation | `firestore.rules` | `work_request_secrets` locked `if false`; `work_request_handover_view` requester-read-only; live Emulator PASS |
| Production Mock Environment Guard | `lib/core/config/app_environment.dart` | `useDevMocks` strictly denied in `staging`/`production` or when `isFirebaseRuntimeActive == true` |
| Map Parameter XSS Hygiene | `web/maps/mashwar_uber_map.html` | `mode`/`style` whitelisted; pin labels escaped via `escapeHtml()`; HUD uses `.textContent` |
| Admin Shell Auth Gate | `lib/screens/admin/admin_shell.dart` | Unauthenticated users redirected to `AdminLoginScreen` |
| Worksite Ops Admin Screen | `lib/screens/admin/admin_worksite_ops_screen.dart` | Mandatory reject/suspend reasons, live loading states, state-machine guards, Firebase sync feedback |
| Self-Service Account Deletion UI | `lib/screens/account/account_extra_screens.dart` | Active-request blocking, explicit `"حذف"/"delete"` confirmation, calls `auth.deleteAccount(...)` |
| Landing Page i18n Key Parity | `landing_page/index.html`, `landing_page/js/i18n.js` | 256/256 AR/EN keys aligned, 0 broken images (12/12 loaded in headless Edge QA) |

---

### Category 2: Exists but Needs Improvement

| ID | Priority | Finding & Location | Root Cause | Impact | Recommended Solution | Dependencies | Status & Verification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GAP-2.1 | **P1** | **Three-Way Admin RBAC Split** (`firestore.rules`, `storage.rules`, `functions/src/handlers.ts`) | Rules trust Auth Custom Claims; Functions trust `admin_staff/{uid}`; Storage trusts both | Staff doc without claims fails Firestore reads; claim without staff doc fails Cloud Functions | Atomic admin provisioning callable/script syncing claims + `admin_staff/{uid}`; align `isAdmin()` across all 3 layers | Firebase Admin SDK + Blaze | **Open** — Requires admin provisioning tooling & emulator test |
| GAP-2.2 | **P1** | **`image/svg+xml` Allowed in Storage & Client** (`storage.rules`, `media_upload_service.dart`) | Wildcard `image/.*` MIME check | Stored XSS if uploaded SVG opened in browser | Explicit raster MIME allowlist (`jpeg`, `png`, `webp`, `gif`, `heic`, `heif`) | None | **Fixed** (`148d4b5`, `29553b8`); verified via `principal_audit_regression_test.dart` & live Emulator |
| GAP-2.3 | **P1** | **Missing Security Headers in `vercel.json`** | Only basic headers configured; HSTS/CSP omitted | Downgrade/SSL-strip & framing exposure | Add HSTS (`max-age=63072000; includeSubDomains; preload`) + scoped CSP | Vercel deploy | **Partially Fixed** (`148d4b5`: HSTS + map `frame-ancestors 'self'` added; full root CSP remains P2) |
| GAP-2.4 | **P1** | **Unlocalized / Mixed AR-EN Strings in Admin Portal** | Arabic display literals stored as KPI/period/filter values | English Admin UI leaked Arabic text (`"Period: 7 أيام"`, `"ر.ق"`) | Canonical keys + `periodLabelFor`/`kpi*For(isAr)` + expanded `AppStrings._statusArToEn` | None | **Fixed** (`29553b8`, `fc400af`, `851d22d`); verified 0 Arabic leaks in live Edge QA |
| GAP-2.5 | **P1** | **Pre-filled Fake Demo Values in Consumer Forms** | Sample text left in `TextEditingController(text: ...)` | Production users risk submitting fake Arabic demo data | Clear prefills in live mode; rely on localized `hintText` | None | **Fixed** (`fc400af`); verified in widget tests |
| GAP-2.6 | **P1** | **Stale "6 Services / Bilateral Escrow / 12 Modules" Copy & Personal Contact Leakage** | Copy lagged behind 3-pillar Direct Settlement pivot; founder personal Gmail & `+20` phone left in code | Legal/product contradiction; personal PII exposure | Sync consumer UI, `health.json`, landing SSR, and replace personal contacts with `ops@mashwar.qa` / `+974 4400 9999` | None | **Fixed** (`148d4b5`, `fc400af`); verified in Edge QA & `health.json` |
| GAP-2.7 | **P2** | **Unofficial Google Tile URLs & Public Demo OSRM Server** (`mashwar_uber_map.html`) | Undocumented `mt{s}.google.com` tiles and public `router.project-osrm.org` demo endpoint | ToS violation, HTTP 403 tile blackout, public OSRM rate-limit/ban under production load | Route tiles/directions through licensed Maps/Mapbox key or self-hosted Qatar OSRM behind a backend proxy | Paid Maps/Mapbox/VPS infra | **Open** — External infrastructure prerequisite |
| GAP-2.8 | **P2** | **Admin Dark NOC Mode Visual Breakage** (`admin_main.dart`, 5 Admin screens) | `darkTheme` omitted Cairo font; dialogs hardcoded `Colors.white` | Unreadable light surfaces in dark mode | Apply `GoogleFonts.cairoTextTheme` and `AdminThemeTokens` | None | **Fixed** (`fc400af`) |
| GAP-2.9 | **P2** | **Unclosed `http.Client` & `StreamController` Leaks** (`firebase_chat_repository.dart`, `admin_provider.dart`, `firebase_firestore_service.dart`, `google_maps_service.dart`) | Long-lived controllers/clients created without eviction/disposal | Memory growth in long web sessions | Add `StreamController` eviction + reuse `FirebaseFunctionsCallableClient` with timeout; add `.close()` to remaining services | None | **Partially Fixed** (`29553b8`: chat & admin gateway fixed; `firebase_firestore_service`/`google_maps_service` open) |
| GAP-2.10 | **P2** | **Public `investor_inquiries` & `formsubmit.co` Abuse Vector** | Unauthenticated writes without App Check/rate limit; `_captcha: "false"` | Spam flooding of Firestore & email inbox | Proxy inquiries via App-Check/rate-limited Cloud Function + server-side SMTP/SendGrid | Blaze + App Check + SMTP | **Open** — External service integration |
| GAP-2.11 | **P2** | **Duplicate Admin Audit Log Writes** (`admin_provider.dart`) | Client wrote second audit log after Cloud Function already wrote one | Duplicated audit entries | Write client audit log only on Spark fallback when Cloud Function did not execute | None | **Fixed** (`29553b8`) |
| GAP-2.12 | **P2** | **`deleteUserAccount` Non-Atomic & Incomplete Purge** (`functions/src/handlers.ts`) | Deletes run outside transaction; subcollections & Storage KYC prefixes skipped | Residual PII under Qatar Law No. 13 of 2016 (PDPPL) | Add `tx.delete()` to `StoreTransaction`, purge subcollections/auxiliary docs + Admin Storage prefix delete | Blaze deploy | **Open** — P1/P2 pre-launch compliance task |
| GAP-2.13 | **P2** | **Rendering & Asset Performance** (`main.dart`, `admin_ui_kit.dart`, `mashwar_uber_map.html`, `assets/images/`) | Root `Consumer2` rebuilds, unconditional `shouldRepaint`, always-on 60fps map rAF, 7.48 MB JPEGs, 87 raw `fontFamily: 'Cairo'` | Excess CPU/battery use and heavy initial web load | Fixed root Consumer, `shouldRepaint`, map rAF pause (`148d4b5`, `fc400af`); image WebP compression & `AppTypography` sweep remain | Asset pipeline | **Partially Fixed** |
| GAP-2.14 | **P2** | **Accessibility Coverage** | Only 7 `Semantics()` widgets; ~124 unlabeled `IconButton`s | Poor screen-reader usability | Add bilingual `tooltip:` and `Semantics` labels across all interactive controls | None | **Partially Fixed** (`fc400af` on touched screens; full sweep open) |

---

### Category 3: Exists but Is Broken

| ID | Priority | Finding & Location | Root Cause | Impact | Recommended Solution | Dependencies | Status & Verification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GAP-3.1 | **P0** | **`vercel.json` `X-Frame-Options: DENY` Blocks Map Iframe** | Global `DENY` applied to `/maps/*` | Every in-app map broken on Vercel production | Override `/maps/(.*)` & `/admin/maps/(.*)` with `SAMEORIGIN` + `frame-ancestors 'self'` | None | **Fixed** (`148d4b5`); verified by regression test & Edge QA |
| GAP-3.2 | **P0** | **Parcel Pickup & Delivery OTP Bypasses** (`firestore.rules`, `firebase_parcels_repository.dart`) | Optional `submittedOtp` check; zero `deliveryOtp` check in rules; fail-open `verifyDeliveryOtp()` | Carriers could hijack parcel transitions without OTP | Require `submittedOtp == prev.pickupOtp` & `submittedDeliveryOtp == prev.deliveryOtp` in rules; fail closed in repo | Rules deploy | **Fixed** (`c227960`, `29553b8`) |
| GAP-3.3 | **P0** | **`FirebaseAuthRepository.submitNationalId()` Schema Mismatch** | Emitted legacy keys forbidden by `hasOnlyAllowedFields` | 100% `PERMISSION_DENIED` on live KYC upload | Emit exact `isValidProviderVerification` schema (`id`, `providerId`, `fullName`, `qidNumber`, `qidFrontUrl`, `qidBackUrl`, `selfieUrl`, `status: 'pending'`) | None | **Fixed** (`29553b8`) |
| GAP-3.4 | **P0** | **`AdminProvider._persistSnapshot()` Violates `platform_config` Rules** | Wrote nested maps (`settings`, `services`, `corridors`, `featureFlags`, Map `broadcastBanner`) to `platform_config/global` | Every Admin config save silently failed in Firestore | Write split schema-valid docs across `platform_config/global`, `service_catalog`, `corridors`, `feature_flags` | None | **Fixed** (`29553b8`) |
| GAP-3.5 | **P0** | **Cloud Functions `handlers.ts` Schema & Timestamp Drift** | Wrote unwhitelisted fields + ISO strings to `work_requests` and `'suspended'` to `provider_verifications` | Permanent `PERMISSION_DENIED` on subsequent client updates | Whitelist CF fields + accept Timestamp/ISO in `firestore.rules`; map `suspended -> rejected` in `handlers.ts` | Rules + CF deploy | **Fixed** (`c227960`, `148d4b5`); verified in CF tests & Emulator |
| GAP-3.6 | **P0** | **8 Missing Composite Firestore Indexes** (`firestore.indexes.json`) | Multi-field queries lacked index entries | Live Firestore queries crash with `FAILED_PRECONDITION` | Add all 8 composite indexes across `work_requests`, `board_ads`, `rides`, `private`, `work_offers` | Index deploy | **Fixed** (`148d4b5`) |
| GAP-3.7 | **P0** | **Ride Booking Seat Leak & Error Fabrication** (`firebase_rides_repository.dart`, `rides_provider.dart`) | `driverId == passengerId` inverted check; `catch (_)` returned fake confirmed booking; `cancelBooking` passed `rideId`; `completeRide`/`submitRideRating` overwrote immutable `createdAt`; `publishRide` hardcoded `isVerified: true` | Infinite overbooking, phantom bookings, broken cancellation/completion/reschedule | Atomic seat decrement, error propagation, track real `bookingId`, `.update()` mutable fields, remove hardcoded trust badges | CF migration (P1 follow-up) | **Fixed in Client Repo/Provider** (`29553b8`); server CF migration tracked in Roadmap |
| GAP-3.8 | **P0** | **Wallet Silent Failures & Inverted Feature Flag Guard** (`firebase_wallet_repository.dart`, `auth_provider.dart`) | Caught `PERMISSION_DENIED` and returned `true`; `if (!enableDigitalWallet && !isAuthenticated)` inverted | Fake balance mutations; bypassed disabled-wallet flag | Fix guard to `if (!enableDigitalWallet) return false;`; return `false` on repo error; never mutate balance on failure | None | **Fixed** (`29553b8`) |
| GAP-3.9 | **P0** | **Multi-User Chat Broken (`firebase_chat_repository.dart`)** | Overwrote immutable `participantIds` with `'peer_$cleanId'` on every message | Message #2+ failed rules; real recipients could not read chat | Create conversation once with real participants; patch only mutable metadata on subsequent messages | None | **Fixed** (`29553b8`) |
| GAP-3.10 | **P0** | **Live Consumer Fake Simulations** (`booking_waiting_screen.dart`, `safety_screens.dart`, `service_escrow_screen.dart`, `driver_rides_management_screens.dart`, `board_extra_screens.dart`) | Prototype timers, hardcoded lists, fake ticket `#5127`, any-4-digit OTP unlock | False bookings, dropped safety reports, fake driver offers & SOS contacts | Bind to real providers/Firestore streams, enforce exact OTP, persist real `disputes` docs | None | **Fixed** (`fc400af`) |
| GAP-3.11 | **P0** | **Landing Page Hardcoded `http://localhost:8080/` CTAs** (`landing_page/index.html`) | Local dev URL hardcoded in 6 links | All portal buttons broken for remote visitors | Dynamic portal URL resolver (`/` & `/admin/` in prod, `:8080` on local `:8088`) | None | **Fixed** (`148d4b5`); verified in Edge QA |
| GAP-3.12 | **P0** | **`AppStrings.translateDate` Corrupts Arabic Words** (`app_strings.dart`) | Unbounded `.replaceAll('ص', 'AM').replaceAll('م', 'PM')` | Garbled UI text (`AMباحاً`, `الخPMيس`) + missing 10 months | Arabic-letter negative lookaround regex + all 12 months | None | **Fixed** (`29553b8`); verified by `principal_audit_regression_test.dart` |
| GAP-3.13 | **P0** | **Production Admin Portal Hardcoded Fake KPIs & Mock Data** (`admin_provider.dart`) | Only worksite lists gated behind `isDevMockMode`; other tabs seeded fake RAM arrays and never persisted mutations | Operators see fake metrics/records in live production | Inquiries cleared on 0 docs, live-derived KPIs & platform config persisted (`29553b8`); remaining secondary Admin tab persistence tracked in Roadmap | Backend Admin callables | **Partially Fixed** (Worksite Ops, Inquiries, Platform Config, Audit Logs live; secondary tabs still require full Firestore/CF persistence) |
| GAP-3.14 | **P1** | **IDOR & Rule Mismatches in `FirebaseBoardRepository`** | `getMySentOffers` queried all users' ads; `makeOffer`/`withdrawOffer` wrote parent ad | Cross-user data exposure & silent failures | Scope via `collectionGroup('offers').where('driverId', isEqualTo: uid)`; surface write errors | CF for parent-ad sync (P2) | **Fixed IDOR & Error Surfacing** (`29553b8`) |
| GAP-3.15 | **P1** | **`ParcelsProvider` Leaks `MockData.activeParcel` & Drops Mutations** | Fallback to `MockData.activeParcel`; missing `driverId`, RAM-only cancel, `set()` on dispute | Fake parcel shown to live users; lost assignments/disputes/cancellations | Return `null` in live mode; persist `driverId`, `cancelled` status, and `disputes` docs | None | **Fixed** (`29553b8`); verified by `principal_audit_regression_test.dart` |
| GAP-3.16 | **P1** | **`work_offers` Query Fails for Providers** (`firebase_worksite_repository.dart`) | Queried `work_offers` without `providerId == uid` filter | `PERMISSION_DENIED` when provider views own offer | Add `FirebaseScopedWorkOfferStore` filtering by `providerId == uid` + matching composite index | Index deploy | **Fixed** (`148d4b5`, `29553b8`) |
| GAP-3.17 | **P1** | **Admin Filter Reset on Language Switch, Empty-List/Dropdown Crashes, Entry Bugs & Stale 12-Module RBAC Matrix** | Localized filter strings, unguarded `.first` & `DropdownButton`, missing `AppLocalizations.delegate`, stuck login counter, stale switch | Crashes, 0-row filter bugs, false RBAC lockouts | Canonical keys, guards, `AppLocalizations.delegate`, 30s lockout, unified `AdminProvider.roleHasMenuAccess` (14 modules) | None | **Fixed** (`29553b8`, `fc400af`, `851d22d`) |
| GAP-3.18 | **P1** | **`ParcelDisputeScreen` Fake Photo Toggle** | Toggled `bool _hasAttachedPhoto` without picking/uploading | Claimed evidence attached when no file existed | Wired `MediaUploadService.pickAndUploadWorkRequestReference` with thumbnail & remove UI | Storage deploy | **Fixed** (`fc400af`) |

---

### Category 4: Partially Implemented

| ID | Priority | Finding & Location | Root Cause | Impact | Recommended Solution | Dependencies | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GAP-4.1 | **P1** | **Cloud Functions Dropped Extended Worksite Fields & Lacked `withdrawWorkOffer`** | Callable payloads lagged behind Spark fallback schema | Data loss on Blaze vs Spark parity; stale `offerCount` on withdrawal | Persist all fields in `handlers.ts`, pass from repo, add transactional `withdrawWorkOffer` | Blaze CF deploy | **Fixed** (`148d4b5`, `29553b8`); 13/13 CF tests PASS |
| GAP-4.2 | **P1** | **Admin Role Taxonomy Mismatch** (`admin_provider.dart` vs `firestore.rules` & `functions/src/types.ts`) | Client had `financeAdmin`/`devopsAdmin`, backend omitted them | Role writes rejected by rules/CF | Align all 5+ roles across client, rules, and CF types | Rules + CF deploy | **Fixed** (`c227960`, `148d4b5`) |
| GAP-4.3 | **P1** | **Admin KYC Image Previews (`admin_driver_verifications_screen.dart`, `admin_worksite_ops_screen.dart`)** | Static placeholder icons / raw URL text instead of image viewer | Operators cannot inspect QID/receipt images inline | Render `Image.network` thumbnails + tap-to-zoom lightbox with error fallback | Storage auth | **Open** — Planned post-MVP UX upgrade |
| GAP-4.4 | **P1** | **Admin Dashboard & SRE Charts Hardcoded** (`admin_dashboard_screen.dart`, `admin_devops_sre_screen.dart`, `admin_shell.dart`) | Static arrays (`[1850..4420]`, `[44..28]`, `'99.9% Healthy'`) | Telemetry/charts do not reflect live traffic or real health probes | Compute series from Firestore aggregations and run real `/health.json` + Firestore ping checks | Firestore aggregation / Cloud Monitoring | **Open** — Tracked in Roadmap |
| GAP-4.5 | **P1** | **`ChatScreen` Non-Realtime & Silent Send Failures** | One-shot `initState` load; `catch` faked local bubble | Messages missed without refresh; silent data loss | Subscribe to `chat.streamMessages(...)` + show error banner & Retry CTA; responsive `Wrap` header | None | **Fixed** (`fc400af`, `851d22d`) |
| GAP-4.6 | **P2** | **`AuthProvider.updateDriverVehicle` RAM-Only** | Never persisted vehicle details | Vehicle data lost on refresh | Persist to uid-scoped prefs + `provider_profiles` | None | **Fixed** (`29553b8`) |
| GAP-4.7 | **P2** | **`WorksiteProvider.activateDemoShowcase()` Callable in Production** | No `AppFlavor.production` guard | Risk of live user entering demo overlay | Guard behind `AppEnvironment.flavor != AppFlavor.production` | None | **Fixed** (`29553b8`) |
| GAP-4.8 | **P2** | **`AlertsProvider` Direct Firestore Access & Admin Form Validation Drops** | Direct `FirebaseFirestore.instance` with `catch (_) {}`; silent `return` in Admin forms | Untestable persistence; poor error UX | Extract `IAlertsRepository`; add `Form`/`TextFormField` bilingual validators | None | **Open** — Backlog |

---

### Category 5: Missing

| ID | Priority | Finding & Location | Impact | Recommended Solution | Dependencies | Status |
| --- | --- | --- | --- | --- | --- | --- |
| GAP-5.1 | **P1** | **CI/CD Missing Cloud Functions & Rules Gate** (`.github/workflows/mashwar_ci_cd.yml`) | Broken TypeScript Functions or rules regressions could merge unnoticed | Add `test-functions` job gating builds (`148d4b5`); add Firebase Emulator `test:rules` job in CI | Java/Firebase CLI in GH runner | **Partially Fixed** (`test-functions` added in `148d4b5`; emulator rules job in CI remains P2) |
| GAP-5.2 | **P1** | **Missing Storage Rules for Avatars, Driver Licenses & Chat** (`storage.rules`) | Uploads blocked by default-deny; base64 avatars fell back to `SharedPreferences` | Add scoped `users/{uid}/avatar/*`, `driver_verifications/{uid}/*`, `conversations/{convId}/*` | Storage deploy | **Fixed** (`148d4b5`); verified in live Emulator |
| GAP-5.3 | **P1** | **No Schema Validation on `admin_audit_logs`** (`firestore.rules`) | Arbitrary payload injection; timestamp mismatch (`serverTimestamp` vs `createdAt`) dropped client logs | Add `isValidAdminAuditLog` + standardize `createdAt` across CF & client | Rules deploy | **Fixed** (`c227960`, `29553b8`) |
| GAP-5.4 | **P1** | **48 Undisposed Modal/BottomSheet `TextEditingController`s** (15 files) | Memory leaks in long-running Admin & Consumer web sessions | Dispose via `.whenComplete(() => addPostFrameCallback(...))` | None | **Fixed** (`fc400af`) |
| GAP-5.5 | **P1** | **No Confirmation Dialog on Destructive `"Reset Defaults"`** (`admin_devops_sre_screen.dart`) | Single accidental click wipes platform config | Gate behind explicit bilingual `AlertDialog` | None | **Fixed** (`fc400af`) |
| GAP-5.6 | **P2** | **Missing Firebase App Check & Rate Limiting** | Public Firestore/callable abuse & billing exhaustion risk | Enable `firebase_app_check` + `enforceAppCheck: true` on callables | Blaze + reCAPTCHA Enterprise / Play Integrity / App Attest | **Open** — Pre-scale security gate |
| GAP-5.7 | **P2** | **Missing Startup Failure Gate in `admin_main.dart`** | Admin portal booted broken when Firebase init failed | Mirror `ServiceUnavailableScreen` gate from `main.dart` | None | **Fixed** (`fc400af`) |

---

### Category 6: Unnecessary / Duplicated

| ID | Priority | Finding & Location | Impact | Recommended Solution | Status |
| --- | --- | --- | --- | --- | --- |
| GAP-6.1 | **P2** | **Dead / Orphan Code** (`lib/data/services/api_client.dart`, `OffRouteAlertSheet`, `_buildResolvedView`, `users_public` matcher) | Dead attack surface & maintenance drag | Delete unused code/matchers (`api_client.dart`, `OffRouteAlertSheet`, `_buildResolvedView`, `users_public` removed; `board_screen.dart` & `driver_onboarding_screens.dart` retained only for legacy widget tests) | **Largely Fixed** (`c227960`, `29553b8`, `fc400af`) |
| GAP-6.2 | **P2** | **21 Unused Image Assets (~5.55 MB)** (`assets/images/service_cargo.jpg` + 20 files in `landing_page/assets/`) | Bloated git/deploy footprint | Delete all verified unreferenced assets | **Fixed** (`148d4b5`); 12/12 remaining landing images verified loaded |
| GAP-6.3 | **P2** | **Byte-Identical Duplicated Map Engine & Leaflet Assets** (`web/maps/` vs `landing_page/maps/`) | Drift risk when editing map engine | Single canonical source copied during build script | **Open** — Both kept byte-identical in `148d4b5`; build-step dedup pending |
| GAP-6.4 | **P3** | **Duplicated 14-City Qatar Alias Matching** (3 providers) | Drift across Rides, Board, and Alerts filtering | Extract shared `QatarCityMatcher` utility | **Fixed** (`29553b8`); unit-tested |
| GAP-6.5 | **P3** | **Oversized Monolithic Screen Files** (5 files >2,500 lines) | High review friction & rebuild blast radius | Split into modular sub-widgets/screens in post-MVP refactor | **Open** — Refactor backlog |
