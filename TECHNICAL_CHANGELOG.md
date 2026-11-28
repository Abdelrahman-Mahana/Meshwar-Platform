# MASHWAR Platform — Technical Changelog

**Range:** `b86e8cb..851d22d` (branch `main`)  
**Total Delta (Code & Assets):** `98 files changed, 5,375 insertions(+), 2,054 deletions(-)` (2 files created, 22 files deleted, 74 files modified)

---

## 1. Commit History on `main`

| Commit | Type / Scope | Summary |
| --- | --- | --- |
| `c227960` | `security(rules)` | Close parcel pickup/delivery OTP bypasses, align `work_requests` schema & Timestamp/ISO validators with Cloud Functions, add `isValidAdminAuditLog`, expand `admin_staff` roles, remove dead `users_public` matcher |
| `148d4b5` *(merged via `740f34a`)* | `fix(infra,functions,landing)` | Harden `vercel.json` headers, restrict `storage.rules` MIME allowlist & add scoped paths, add 8 composite indexes, complete Cloud Functions worksite fields + `withdrawWorkOffer`, add CI `test-functions` job, pause hidden map rAF loop, sync landing page SSR/portal URLs, delete 21 unused image assets |
| `29553b8` *(merged via `346a199`)* | `fix(core)` | Harden 8 Firebase repositories, 7 state providers, `app_strings.dart`, `media_upload_service.dart`, `worksite_models.dart`; create `qatar_city_matcher.dart`; delete orphan `api_client.dart` |
| `fc400af` *(merged via `69bb6cb`)* | `fix(ui)` | Eliminate live consumer simulations & hardcoded lists, wire real photo upload & live chat stream, harden `admin_main.dart` & all 14 Admin screens (i18n, crash guards, dark NOC mode, 14-module RBAC), dispose 48 leaked modal controllers, remove root `Consumer2` rebuild |
| `851d22d` | `test(audit)` | Unify `admin_dashboard_screen.dart` & `admin_staff_screen.dart` with `AdminProvider` helpers, fix narrow-viewport `RenderFlex` overflow in `chat_screen.dart`, add `test/principal_audit_regression_test.dart` (11 tests) |

---

## 2. Files Created (2)

- `lib/data/services/qatar_city_matcher.dart` — Centralized bilingual 14-city Qatar alias table and matching helpers (replacing duplicated copies in `rides_provider.dart`, `board_provider.dart`, and `alerts_provider.dart`).
- `test/principal_audit_regression_test.dart` — 11 targeted regression tests verifying date/month/Admin-status localization, SVG upload rejection + raster allowlist, 14-module Admin RBAC & English KPI helpers, `ParcelsProvider` live clean-slate behavior, `QatarCityMatcher`, `vercel.json` HSTS/`SAMEORIGIN` rules, and `web/health.json` metadata.

---

## 3. Files Deleted (22)

### Dead Code Removed (1)
- `lib/data/services/api_client.dart` — Orphan HTTP stub with zero callers anywhere in `lib/` or `test/`.

### Unused Image Assets Removed (21 files, ~5.55 MB)
- **Flutter App (1):** `assets/images/service_cargo.jpg`
- **Landing Page (20):**
  - `landing_page/assets/logos/mashwar_logo_dark_transparent.png`
  - `landing_page/assets/logos/mashwar_pin_icon.svg`
  - `landing_page/assets/logos/mashwar_pin_icon_light.svg`
  - `landing_page/assets/mobile/52_wallet_screen.png`
  - `landing_page/assets/mobile/67_service_escrow_screen.png`
  - `landing_page/assets/posters/poster_02_six_services_showcase_16x9.png`
  - `landing_page/assets/posters/poster_03_trust_and_safety_16x9.png`
  - `landing_page/assets/posters/poster_ai_intercity_qatar_wide.jpg`
  - `landing_page/assets/services/hero_qatar_services.jpg`
  - `landing_page/assets/services/service_cargo.jpg`
  - `landing_page/assets/services/service_errand.jpg`
  - `landing_page/assets/web/01_web_home_desktop.png`
  - `landing_page/assets/web/06_admin_dashboard_kpis.png`
  - `landing_page/assets/web/07_admin_driver_verifications.png`
  - `landing_page/assets/web/14_web_escrow_desktop.png`
  - `landing_page/assets/web/admin_v2_dashboard.png`
  - `landing_page/assets/web/admin_v2_devops_light.png`
  - `landing_page/assets/web/admin_v2_devops_noc.png`
  - `landing_page/assets/web/admin_v2_escrow.png`
  - `landing_page/assets/web/admin_v2_services.png`

---

## 4. Detailed Changes by Subsystem (74 Modified Files)

### 4.1 Security Rules, Database Indexes & Infrastructure (5 files)
- `firestore.rules`:
  - Enforced mandatory `submittedOtp == prev.pickupOtp` on parcel `accepted -> handedOver` and `submittedDeliveryOtp == prev.deliveryOtp` on `inTransit -> delivered` (when `deliveryOtp` is set).
  - Added `paymentVerifiedBy`, `paymentVerifiedAtUtc`, `moderationNotes`, `completedAtUtc` to `work_requests` allowed keys and added `isValidOptTimestampOrIsoString()` for Cloud Functions timestamp compatibility.
  - Added `isValidAdminAuditLog()` schema validation on immutable `admin_audit_logs` creates.
  - Expanded `admin_staff` allowed roles to include `financeAdmin` and `devopsAdmin`.
  - Removed unreferenced, unvalidated `users_public/{userId}` collection matcher.
- `storage.rules`:
  - Replaced wildcard `image/.*` with explicit raster MIME allowlist (`image/jpeg`, `image/png`, `image/webp`, `image/gif`, `image/heic`, `image/heif`), blocking `image/svg+xml`.
  - Added `<= 10 MB` scoped rules for `users/{uid}/avatar/{file}`, `driver_verifications/{uid}/{file}`, and `conversations/{convId}/{file}`.
- `firestore.indexes.json`:
  - Added 8 missing composite indexes: `work_requests (status, createdAt DESC)`, `board_ads (status, fromCity)`, `board_ads (status, toCity)`, `board_ads (status, type, toCity)`, `rides (fromCity, isLadiesOnly)`, `rides (toCity, isLadiesOnly)`, `private (docType, isDefault)` (`COLLECTION`), and `work_offers (requestId, providerId, createdAt DESC)`.
- `vercel.json`:
  - Added `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload` on `/(.*)`.
  - Added `X-Frame-Options: SAMEORIGIN` and `Content-Security-Policy: frame-ancestors 'self'` overrides on `/maps/(.*)` and `/admin/maps/(.*)`.
- `.github/workflows/mashwar_ci_cd.yml`:
  - Added `test-functions` job (`Node.js 20`, `npm ci`, `npm run build`, `npm test` in `functions/`) as a prerequisite (`needs: [analyze-and-test, test-functions]`) for `build-production-bundles`.
- `web/health.json`:
  - Updated `adminModules` from `12` to `14`; replaced `escrowProtection` with `settlementMode: "direct-cod-and-verified-bank-transfer"` and `handoverVerification: "salted-sha256-and-dual-otp"`.

### 4.2 Cloud Functions v2 (4 files)
- `functions/src/types.ts`: Added `financeAdmin` and `devopsAdmin` to `AdminRole`; added extended fields to worksite callable inputs and `WithdrawWorkOfferInput`.
- `functions/src/handlers.ts`:
  - Persisted `supplyCategory`, `siteContactName`, `siteContactPhone`, `itemNotes`, `estimatedItemsCostMinor`, `maxItemsCapMinor`, `deliveryFeeBudgetMinor`, `scheduledBy`, and `referenceImageUrls` in `createWorkRequest`.
  - Persisted `referenceNumber -> paymentReference` in `recordPaymentStatus`, `tags` in `submitRequestRating`, and `actualReceiptTotalMinor` in `transitionWorkRequestStatus`.
  - Mapped provider review status `suspended -> rejected` on `provider_verifications` documents to satisfy `firestore.rules`.
  - Implemented transactional `withdrawWorkOffer` (marks offer `withdrawn`, decrements `offerCount`, reverts request `status` from `offer_received` to `open` when 0 pending offers remain).
- `functions/src/index.ts`: Exported `withdrawWorkOffer` callable in `europe-west1`.
- `functions/test/backend_security.test.mjs`: Added 2 comprehensive security/functional tests covering extended worksite fields and transactional `withdrawWorkOffer` (total: 13/13 PASS).

### 4.3 Core Repositories, State Providers, Models & Services (21 files)
- `lib/core/localization/app_strings.dart`: Replaced unbounded `ص`/`م` replacements in `translateDate()` with Arabic-letter negative lookaround regexes; added all 12 AR↔EN months; added missing Admin status translations (`مفتوح`, `محلول`, `محظور`, `مرفوضة`, `مقبولة`, `منشورة`, `مكتملة الحجز`, `جارية`).
- `lib/data/services/media_upload_service.dart`: Restricted accepted image MIME types and extensions to raster formats (explicitly rejecting `image/svg+xml` and `.svg`).
- `lib/data/repositories/implementations/firebase/firebase_auth_repository.dart`: Aligned `submitNationalId()` payload with `isValidProviderVerification` schema (`id: uid`, `providerId: uid`, `fullName`, `qidNumber`, `qidFrontUrl`, `qidBackUrl`, `selfieUrl`, `status: 'pending'`).
- `lib/data/repositories/implementations/firebase/firebase_parcels_repository.dart` & `lib/state/parcels_provider.dart`: Fail-closed `verifyDeliveryOtp()` sending `submittedOtp`/`submittedDeliveryOtp`; returned `null` instead of `MockData.activeParcel` in live mode; persisted `driverId` on assignment, `cancelled` on cancellation, and real `disputes` docs on parcel dispute.
- `lib/data/repositories/implementations/firebase/firebase_rides_repository.dart` & `lib/state/rides_provider.dart`: Fixed passenger seat decrement in `bookRide()` and stopped fabricating confirmed bookings on errors; tracked real `bookingId` for `cancelBooking()`; migrated `completeRide()`, `submitRideRating()`, and `rescheduleRide()` to mutable-field `.update()`; removed hardcoded `isVerified: true` and `driverRating: 4.9` on `publishRide()`.
- `lib/data/repositories/implementations/firebase/firebase_wallet_repository.dart` & `lib/state/auth_provider.dart`: Fixed inverted `!enableDigitalWallet` guard; returned `false` on denied wallet Firestore writes without mutating `_user.walletBalance`; persisted `updateDriverVehicle()` to uid-scoped preferences and `provider_profiles`.
- `lib/data/repositories/implementations/firebase/firebase_chat_repository.dart`, `lib/data/repositories/contracts/i_chat_repository.dart`, `lib/data/repositories/implementations/chat_repository_impl.dart`: Created conversation doc once with real participants and patched only mutable metadata on subsequent messages; added `StreamController` eviction and `dispose()`.
- `lib/data/repositories/implementations/firebase/firebase_board_repository.dart` & `lib/state/board_provider.dart`: Fixed `getMySentOffers()` IDOR via `collectionGroup('offers').where('driverId', isEqualTo: uid)`; surfaced write failures in `createBoardAd()`; adopted `QatarCityMatcher`.
- `lib/data/repositories/implementations/firebase/firebase_worksite_repository.dart`, `lib/data/models/worksite_models.dart`, `lib/state/worksite_provider.dart`: Passed all extended worksite fields to Cloud Functions callables; wired `withdrawOffer` to `withdrawWorkOffer` callable with Spark fallback; added `FirebaseScopedWorkOfferStore` for provider-scoped offer queries; gated `activateDemoShowcase()` off in `AppFlavor.production`.
- `lib/data/repositories/implementations/firebase/firebase_admin_repository.dart` & `lib/state/admin_provider.dart`: Split `savePlatformSnapshot()` across schema-valid collections (`platform_config/global`, `service_catalog`, `corridors`, `feature_flags`); standardized `createdAt` on audit logs and eliminated duplicate client audit writes; added static `roleHasMenuAccess(role, index)` (modules `0..13`) and localized `periodLabelFor`/`kpi*For(bool isAr)` helpers; cleared fake seed inquiries on empty Firestore reads; reused `FirebaseFunctionsCallableClient` with timeout in `_FirebaseAdminBackendGateway`.
- `lib/state/alerts_provider.dart`: Adopted `QatarCityMatcher`.

### 4.4 Consumer & Admin Flutter UI (38 files)
- **App Entrypoints (`lib/main.dart`, `lib/admin_main.dart`):** Removed unused `AdminProvider` from root `Consumer` in `main.dart`; added `AppLocalizations.delegate`, Cairo dark `textTheme`, and `ServiceUnavailableScreen` startup gate to `admin_main.dart`.
- **Consumer Screens (15 files):**
  - `booking_waiting_screen.dart`: Removed blind 4.5s auto-confirm timer; bound to `RidesProvider` status with Refresh & Cancel actions.
  - `safety_screens.dart`: Wired `ReportIssueScreen` to persist real `disputes` docs (removed fake `#5127`); removed fake hardcoded contacts from `EmergencyContactsScreen`; removed dead `OffRouteAlertSheet`.
  - `service_escrow_screen.dart`: Enforced exact OTP verification (removed any-4-digit unlock) and Direct Settlement status in live mode without `MockData.initialBoardAds.first` fallback.
  - `driver_rides_management_screens.dart` & `board_extra_screens.dart`: Bound live mode exclusively to provider streams with clean empty states (gated mock fixtures to non-live mode).
  - `parcel_dispute_screen.dart`: Replaced fake photo boolean with real `MediaUploadService` upload + thumbnail/remove UI; removed dead `_buildResolvedView`.
  - `chat_screen.dart`: Subscribed to `streamMessages(...)`, added send-failure error banner + Retry CTA, updated Direct Settlement phrasing, and fixed narrow-viewport horizontal `RenderFlex` overflow (17px) via responsive `Wrap`.
  - `phone_input_screen.dart`, `send_parcel_screen.dart`, `post_ad_screen.dart`, `city_search_modal.dart`, `vehicle_registration_screen.dart`, `settings_screen.dart`, `booking_confirmation_screen.dart`, `my_alerts_screen.dart`, `wallet_screen.dart`, `provider_profile_screen.dart`, `work_request_details_screen.dart`, `mashwar_handover_qr_panel.dart`: Cleared live demo prefills, updated Direct Settlement copy, added bilingual tooltips, and disposed all 48 modal/bottom-sheet `TextEditingController`s safely post-frame.
- **Admin Screens & UI Kit (18 files):** `admin_shell.dart`, `admin_login_screen.dart`, `admin_dashboard_screen.dart`, `admin_users_screen.dart`, `admin_disputes_screen.dart`, `admin_audit_log_screen.dart`, `admin_corridors_geo_screen.dart`, `admin_rides_parcels_screen.dart`, `admin_driver_verifications_screen.dart`, `admin_escrow_finance_screen.dart`, `admin_worksite_ops_screen.dart`, `admin_inquiries_screen.dart`, `admin_staff_screen.dart`, `admin_services_catalog_screen.dart`, `admin_settings_screen.dart`, `admin_devops_sre_screen.dart`, `widgets/admin_ui_kit.dart`:
  - Canonical filter keys surviving AR↔EN language toggles; search `TextEditingController` in audit logs; empty-list & `DropdownButton` membership guards; unified 14-module RBAC matrix; `AlertDialog` confirmation before `"Reset Defaults"`; `onSubmitted` + 30s lockout on `AdminLoginScreen`; dark NOC `AdminThemeTokens` surfaces; fixed `_TelemetryChartPainter.shouldRepaint`; removed raw developer strings (`transfer_proof_submitted`, `landing_page -> Firestore`); localized currency (`QAR`/`ر.ق`), day labels, KPIs, periods, empty states, and role initials; replaced personal Gmail with `ops@mashwar.qa` / `+974 4400 9999`.

### 4.5 Map Engine & Marketing Landing Page (6 files)
- `web/maps/mashwar_uber_map.html` & `landing_page/maps/mashwar_uber_map.html`: Kept byte-identical; paused 60fps `requestAnimationFrame` vehicle animation when `document.hidden` or `prefers-reduced-motion: reduce`.
- `landing_page/index.html`, `landing_page/js/app.js`, `landing_page/js/i18n.js`, `landing_page/js/firebase-contact.js`: Synced SSR fallback copy to 3-pillar Direct Settlement & 14 Admin modules, resolved portal URLs dynamically, removed `67_service_escrow_screen.png` reference, and replaced `+201007938491` fallback contact with `ops@mashwar.qa` while preserving live Firestore `investor_inquiries` writes.

---

## 5. Key Architectural & Engineering Decisions

1. **Direct Settlement Over Custodial Escrow:** Standardized consumer UI, `health.json`, and landing copy on Direct Settlement (COD / verified bank transfer proof) + salted SHA-256 handover verification, matching Qatar legal disclosures (`no prepaid wallets / no escrow custody`).
2. **Fail-Closed Security Everywhere:** Converted fail-open patterns (`verifyDeliveryOtp()`, `FirebaseWalletRepository`, `storage.rules` `image/.*`, parcel pickup/delivery OTP rules, `enableDigitalWallet` flag guard) to strict fail-closed validation.
3. **Zero-Regression Preservation of Non-Live Widget Fixtures:** Gated prototype data strictly to non-live dev/test modes so all 200 existing Flutter tests continued passing alongside 11 new principal-audit regression tests (211/211 PASS) while guaranteeing zero mock leaks in live Firebase mode.
4. **Canonical Internal Keys for Bilingual UI State:** Decoupled filter/period/status state from localized display strings so AR↔EN runtime switching never resets filters or leaks untranslated text.
