# Implementation Status Matrix — MASHWAR Platform

A straightforward, ground-truth view of what is built and verified in the codebase today versus what remains gated behind external licensing or store infrastructure.

- **`READY`**: Implemented, `0` analyzer issues, covered by passing automated tests and live local/Firebase verification.
- **`EXTERNAL GATE`**: Code is ready in the repo, but activation requires an external billing plan, physical device/host, or third-party console approval.
- **`DEFERRED (REGULATORY)`**: Intentionally disabled via `AppEnvironment` flags until Qatar MoT / QCB licensing is secured.

---

## 1. Core Application & Backend Subsystems

| Subsystem | Key Files | Status | Ground-Truth Notes |
| :--- | :--- | :---: | :--- |
| **3-Pillar Consumer App** | `lib/features/`, `lib/screens/`, `lib/state/` | **READY** | Shared Trips, Route Parcels (dual 4-digit OTPs), and Smart Worksite Supply (receipt photos + 6-char SHA-256 handover). Clean new-user onboarding with zero fake notifications or prefilled defaults. |
| **Uber-Style In-App Live Map** | `web/maps/mashwar_uber_map.html`, `web/maps/leaflet/*`, `lib/core/widgets/mashwar_embedded_google_map*.dart`, `lib/data/services/google_maps_service.dart` | **READY** | Vendored Leaflet 1.9.4 + Google Maps/Traffic tiles + 4 style presets + OSRM polylines + automatic `fitBounds` + 60fps rotating Car/Parcel/Supply vehicle SVGs across 12 consumer screens and Admin Portal. |
| **Environment & Fail-Closed Boot** | `lib/core/config/app_environment.dart`, `lib/main.dart`, `lib/admin_main.dart` | **READY** | `USE_DEV_MOCKS` mathematically restricted to `development && !USE_FIREBASE`; staging/production fail closed to `ServiceUnavailableScreen` if Firebase is unreachable. |
| **Firestore & Storage Rules** | `firestore.rules`, `firestore.indexes.json`, `storage.rules` | **READY** | 29 Firestore collections + 14 composite indexes deployed to `mashwar-qatar-2026-ec99d` and verified `10/10` on local Firebase Emulators. |
| **Cloud Functions v2 (`functions/`)** | `functions/src/{index,handlers,stateMachine,handoverCrypto,store,types}.ts` | **READY** *(Code & Tests)* / **EXTERNAL GATE** *(Blaze Deploy)* | 10 v2 `onCall` handlers (incl. `deleteUserAccount`) pass `11/11` tests. Spark-safe Firestore fallbacks handle client-permitted actions until the project upgrades to Blaze. |
| **14-Module Admin Portal (`/admin/`)** | `lib/admin_main.dart`, `lib/screens/admin/*`, `lib/state/admin_provider.dart` | **READY** | Firebase Auth + active `admin_staff/{uid}` RBAC (5 roles), live Uber traffic map on Dashboard & Corridors, Worksite Ops (`Module 13`), Landing Inquiries (`Module 12`), and immutable audit logs. |
| **5-Account Live Demo Seeder** | `scripts/seed_multi_account_demo.mjs`, `scripts/seed_multi_account_demo.ps1` | **READY** | Idempotently provisions 5 real Firebase Auth accounts + 113 interconnected Firestore docs for hands-on role switching. |
| **Landing Page & Lead Capture** | `landing_page/index.html`, `landing_page/maps/`, `landing_page/js/firebase-contact.js` | **READY** | Bilingual AR/EN, live interactive corridor Uber map, fresh Retina app/admin screenshots, and live Firestore `investor_inquiries` capture. |

---

## 2. External Pre-Launch & Regulatory Gates

| Capability | Flag / Scope | Status | What's Needed |
| :--- | :--- | :---: | :--- |
| **Live `+974` SMS OTP** | `FirebaseAuthRepository` | **EXTERNAL GATE** | Upgrade `mashwar-qatar-2026-ec99d` to Firebase Blaze, configure Qatar `+974` SMS allowlist, and test on Ooredoo/Vodafone SIMs. |
| **Google Play & App Store Builds** | `android/`, `ios/` | **EXTERNAL GATE** | Build signed `.aab` / `.ipa` on Android release & macOS/Xcode hosts and submit for store review. |
| **Qatar Trademark Clearance** | MASHWAR / مشوار | **EXTERNAL GATE** | Prior-art search & Nice Classes 35/39/42 registration with Qatar MoCI. |
| **In-App Digital Wallet** | `enableDigitalWallet = false` | **DEFERRED (REGULATORY)** | Qatar Central Bank (QCB) e-money / PSP licensing. |
| **Automated Escrow Custody** | `enableEscrowClaims = false` | **DEFERRED (REGULATORY)** | Licensed QCB escrow partner integration (direct Cash / Bank Transfer proof active today). |
| **Commercial Heavy Cargo** | `enableCommercialCargo = false` | **DEFERRED (REGULATORY)** | Commercial freight licensing via Qatar MoT. |
