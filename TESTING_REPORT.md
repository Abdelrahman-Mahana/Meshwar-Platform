# MASHWAR Platform — Principal Engineering Testing & Verification Report

**Verified Commit:** `851d22d` (`851d22d7045dc59363512534b044d27f82f75e9c`, branch `main`)  
**Environment:** Windows workstation (`d:\My_Projects\Meshwar-v1\Meshwar`), Node.js 20, Flutter Stable, Firebase Local Emulator Suite (Firestore + Storage), Microsoft Edge Headless CDP (`1440x900 @ 2x`).

---

## 1. Automated Verification Summary

Every automated gate executed on commit `851d22d` exited with code `0` and zero failures:

| Verification Gate | Command Executed | Result | Pass / Fail | Duration / Notes |
| --- | --- | --- | --- | --- |
| **Flutter Static Analysis** | `flutter analyze --no-pub` | **PASS** (exit `0`) | **0 issues** | 15.0s across 150 `lib/` + 29 `test/` Dart files |
| **Flutter Full Test Suite** | `flutter test --no-pub` | **PASS** (exit `0`) | **211 / 211 PASS** (0 failures) | 29 test files; includes 11 new tests in `principal_audit_regression_test.dart` |
| **Cloud Functions v2 Build & Unit Security Tests** | `functions`: `npm run build; npm test` | **PASS** (exit `0`) | **13 / 13 PASS** (0 failures) | `tsc` clean; up from 11/11 at baseline `b86e8cb` |
| **Live Firestore & Storage Emulator Rules Suite** | `scripts/run_emulators_tests.ps1` | **PASS** (exit `0`) | **10 / 10 PASS** (0 failures) | Executed `functions/test/emulator_rules.test.mjs` against live local Firestore + Storage emulators |
| **Production Dual-Portal Web Build** | `scripts/build_platform.ps1 -AppEnv production -SkipAnalyze -SkipTests` | **PASS** (exit `0`) | **2 / 2 Bundles** | Consumer build: 90.6s; Admin build: 79.9s; Wasm dry-run succeeded on both |

---

## 2. Suite-by-Suite Breakdown

### 2.1 Flutter Test Suites (`test/`, 29 files — 211/211 PASS)
- **New Principal Audit Regression Suite (`test/principal_audit_regression_test.dart` — 11 tests):**
  1. `translateDate` preserves `صباحاً`, `مساءً`, and `الخميس` without corrupting `ص`/`م` inside words.
  2. `translateDate` translates all 12 months in both AR → EN and EN → AR.
  3. `translateStatus` covers all Admin portal status badges in English mode.
  4. `MediaUploadService` rejects `image/svg+xml` by explicit MIME and by `.svg` extension.
  5. `MediaUploadService` allows raster `image/jpeg`, `image/png`, and `image/webp` via explicit MIME, extension, and magic bytes.
  6. `AdminProvider.roleHasMenuAccess` covers all 14 modules (`0..13`) across all 5 roles and denies out-of-range indices.
  7. `AdminProvider.periodLabelFor` and `kpi*For` helpers emit zero Arabic in English mode across all periods.
  8. `ParcelsProvider` does not leak `MockData.activeParcel` when live Firebase mode is active.
  9. `QatarCityMatcher` resolves bilingual Qatar hubs consistently.
  10. `vercel.json` includes HSTS and allows `SAMEORIGIN` framing on `/maps/(.*)` and `/admin/maps/(.*)`.
  11. `web/health.json` reports `14` `adminModules` and Direct Settlement metadata.
- **Existing 28 Regression, Widget, Repository & E2E Suites (200 tests, all passing):**
  `admin_enterprise_devops_test.dart`, `admin_web_test.dart`, `backend_readiness_and_screens_test.dart`, `demo_all_cases_and_spark_fallback_test.dart`, `dynamic_language_switcher_test.dart`, `email_auth_test.dart`, `firebase_repositories_test.dart`, `full_app_e2e_audit_test.dart`, `inapp_google_maps_test.dart`, `international_three_services_test.dart`, `localization_test.dart`, `mvp_media_phone_and_account_test.dart`, `mvp_models_and_auth_test.dart`, `mvp_worksite_provider_and_repo_test.dart`, `mvp_worksite_ui_test.dart`, `otp_verification_test.dart`, `phone_input_test.dart`, `production_readiness_audit_test.dart`, `profile_avatar_and_full_demo_test.dart`, `profile_setup_test.dart`, `ride_details_map_test.dart`, `settings_screen_test.dart`, `uber_live_map_and_onboarding_test.dart`, `uiux_upgrade_and_features_test.dart`, `ui_ux_innovations_test.dart`, `universal_services_and_escrow_test.dart`, `wave12_notifications_qr_and_other_test.dart`, `widget_test.dart`.

### 2.2 Cloud Functions v2 Security & Domain Suite (`functions/test/backend_security.test.mjs` — 13/13 PASS)
1. `handoverCrypto` generates `[A-HJ-NP-Z2-9]{6}` codes and verifies constant-time salted hashes.
2. Unauthenticated callers are denied across all callable handlers.
3. `createWorkRequest` validates positive integer `budgetMinor`, required fields, and initial state.
4. Self-bidding and unapproved providers are rejected for offers and stage transitions.
5. Requester cannot accept/modify another user's request or self-complete directly.
6. Invalid state transitions and late requester cancellations are rejected.
7. Handover verification rejects invalid, exhausted-attempts, expired, and reused codes.
8. Payment status cannot be forged or overwritten once `verified_settled`.
9. Ratings require completed request, enforce one rating per participant pair, and compute running average.
10. `adminReviewProvider` and `adminModerateWorkRequest` require active `admin_staff` and append audit logs.
11. `deleteUserAccount` blocks active `work_requests` across all active statuses, and deletes profiles + audit log + Firebase Auth user when clear.
12. *(New in `148d4b5`)* `createWorkRequest`, `transitionWorkRequestStatus`, `recordPaymentStatus`, and `submitRequestRating` persist extended worksite fields and validate inputs.
13. *(New in `148d4b5`)* `withdrawWorkOffer` atomically marks offer `withdrawn`, decrements `offerCount`, and reverts `status` to `open` when 0 pending offers remain.

### 2.3 Live Firestore & Storage Emulator Rules Suite (`functions/test/emulator_rules.test.mjs` — 10/10 PASS)
1. Denies unauthenticated read and write across `work_requests`, `work_offers`, `provider_profiles`, `provider_verifications`, and `business_profiles`.
2. Denies `work_request_secrets` read and write to all clients including requester, assigned provider, and admin claims.
3. Allows `work_request_handover_view` read only for `requesterId` and denies reads to provider/stranger and writes to all clients.
4. Enforces `provider_profiles` owner create with `pending` status & zero stats and blocks self-approval updates.
5. Restricts `provider_verifications` reads to owner/admin and enforces 11-digit QID regex.
6. Enforces `work_requests` creation guards, blocks direct completion/settled forgery, and permits approved assigned provider stage progression.
7. Denies `work_offers` creation by unapproved providers and self-bidders while allowing approved providers.
8. Allows `ratings/{requestId}_{uid}` creation once when `work_request` is completed and denies duplicates, updates, and deletes.
9. Enforces Cloud Storage rules for auth, size/MIME limits (blocking SVG), private KYC paths, and participant `work_request` invoices.
10. Allows `users/{uid}` create with empty phone (Email signup) or empty `fullName` (Phone OTP) while rejecting invalid phone or `isVerified=true`.

---

## 3. Live Runtime & Headless Edge CDP Browser QA (`1440x900 @ 2x`)

### 3.1 HTTP Endpoint Smoke Verification

| Endpoint | HTTP Status | Payload Size | Verified Metadata |
| --- | --- | --- | --- |
| `http://127.0.0.1:8080/` (Consumer Web) | `200 OK` | 2,406 B | Flutter production web bootstrap |
| `http://127.0.0.1:8080/admin/` (Admin Portal) | `200 OK` | 2,412 B | Standalone Admin web bootstrap |
| `http://127.0.0.1:8080/health.json` | `200 OK` | 519 B | `adminModules: 14`, `settlementMode: "direct-cod-and-verified-bank-transfer"` |
| `http://127.0.0.1:8080/maps/mashwar_uber_map.html` | `200 OK` | 54,144 B | Byte-identical with `landing_page/maps/mashwar_uber_map.html` |
| `http://127.0.0.1:8088/` (Qatar Landing Page) | `200 OK` | 73,940 B | Synced 3-pillar SSR HTML & dynamic portal links |

### 3.2 Visually & Runtime-Verified Workflows

- **Consumer App (`http://127.0.0.1:8080/`):**
  - Signed in as `requester.demo@mashwar.qa` (`6 Trips · 22 Open Requests`).
  - Verified 5-tab navigation shell, 3-pillar home layout, and live Qatar corridor map iframe (`1105x308`).
  - Telemetry: **0 console errors, 0 page errors, 0 failed local requests**.
  - Evidence screenshot: `01_verified_consumer_app.png` (recorded by `principal-verifier` in board post `#199`).
- **Admin Command Center (`http://127.0.0.1:8080/admin/`):**
  - Signed in as `admin.demo@mashwar.qa` (Super Admin, English mode).
  - Verified **0 Arabic text leaks** across KPIs (`28` Supply Orders, `3 KYC · 6 transfers`, `8 open requests`, `Conversion 75%`, `Success 50%`), Period switcher (`Today | 7 Days | 30 Days`, `Period: 7 Days`), and Weekly Chart (`Sat..Today`, `38.8 QAR Net`).
  - Verified live Qatar Corridor Traffic Map (`470x220`) rendered cleanly.
  - Telemetry: **0 console errors, 0 page errors, 0 failed local requests**.
  - Evidence screenshot: `02_verified_admin_dashboard_en.png` (recorded in `#199`).
- **Marketing Landing Page (`http://127.0.0.1:8088/`):**
  - Verified **12/12 images loaded (0 broken images)** after lazy-scroll verification following 20-image asset cleanup.
  - Verified live corridor map iframe ready (`490x306`).
  - Telemetry: **0 console errors, 0 page errors, 0 failed local requests**.
  - Evidence screenshot: `03_verified_landing_page.png` (recorded in `#199`).

---

## 4. Known Issues & Defects Caught During Integration

- **Caught & Fixed During Final Verification (`851d22d`):**
  1. Narrow-viewport horizontal `RenderFlex` overflow (17px) in `lib/screens/chat/chat_screen.dart` header strip — resolved using a responsive `Wrap` layout.
  2. Duplicated period/KPI and RBAC switch logic in `admin_dashboard_screen.dart` and `admin_staff_screen.dart` — unified onto `AdminProvider.periodLabelFor`, `kpi*For`, and `roleHasMenuAccess`.
- **Known Residual Limitations (Non-Failing, Documented):**
  - Secondary Admin portal modules outside Worksite Ops, Inquiries, Platform Config, and Audit Logs still display fixture data / RAM-only mutations until dedicated Firestore/Cloud Function admin handlers are added (tracked as `R-23`).
  - `emulator_rules.test.mjs` does not yet have explicit negative emulator tests for the newly closed parcel OTP bypass and `admin_audit_logs` validator (both are verified by rule inspection and passing emulator compilation, and should be added as explicit emulator assertions when wiring `test:rules` into CI).

---

## 5. Unverified External Areas

The following areas **could not be verified locally** and require external infrastructure, credentials, or physical hardware:

1. **Live `+974` Qatar SIM Phone OTP Delivery:** Requires Firebase Blaze billing + physical Qatar SIM/carrier SMS delivery.
2. **Production Firebase Cloud Functions v2 Deployment (`europe-west1`):** Verified via TypeScript unit tests (13/13) and local emulator rules (10/10), not yet deployed to a live Blaze project.
3. **Production Vercel Deployment & Real TLS/HSTS Header Inspection:** Verified via `vercel.json` assertions and local static server, not against a live Vercel edge URL.
4. **Physical iOS & Android Builds / Native Permissions:** Camera, geolocation, gallery picker, push notifications, and App Store / Google Play signing were not built or run on physical iOS/Android devices.
5. **High-Concurrency Load / Stress Testing:** Not executed against live Firestore quotas, OSRM routing endpoints, or tile servers.
