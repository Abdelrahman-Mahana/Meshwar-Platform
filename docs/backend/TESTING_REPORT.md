# Testing & Verification Report — MASHWAR Platform

This document tracks the real automated checks, emulator rule tests, and live browser QA runs executed against the repository.

---

## 1. Toolchain Used
- **Flutter SDK:** `3.47.9` (`stable`) / Dart `3.x`
- **Node.js:** `v24.19.0` (Cloud Functions v2 build & `node:test` suites)
- **OpenJDK:** `21.0.13.1` LTS + **Firebase CLI** (`15.37.0+`) for local Firestore & Storage Emulator runs
- **Live Browser QA:** Headless Microsoft Edge CDP at `1440×900 @ 2x` (Retina)

---

## 2. Automated Test Summary

| Suite | Command | Result | Coverage |
| :--- | :--- | :---: | :--- |
| **Flutter Static Analysis** | `flutter analyze --no-pub` | **0 issues** | Full `lib/` and `test/` tree |
| **Flutter Unit, Widget & E2E Tests** | `flutter test --no-pub` | **200 / 200 passed** | Models, `MoneyMinor`, state machines, clean new-user onboarding, 3-service E2E flows, Uber in-app map URLs/modes, 14-module Admin RBAC & multi-viewport zero-overflow checks |
| **Cloud Functions v2 Security Suite** | `Push-Location functions; npm run build; npm test; Pop-Location` | **11 / 11 passed** | Auth enforcement, self-bidding guard, approved-provider gate, linear status transitions, salted SHA-256 handover (wrong/exhausted/expired/reused), settlement lock, ratings, admin RBAC & `deleteUserAccount` |
| **Live Firestore & Storage Emulator Suite** | `powershell -File scripts/run_emulators_tests.ps1` | **10 / 10 passed** | Live rule evaluation across `firestore.rules` (Collections `1–29`) & `storage.rules` (`<= 10 MB` private KYC/invoice ACLs) |

---

## 3. Production Web Build & Live Browser Verification

Built cleanly via:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/build_platform.ps1 -AppEnv production
```
- **Consumer Web App (`build/web`):** Verified live at `http://127.0.0.1:8080/` across brand-new user signup (`0` fake notifications, `0.00 QAR` wallet, clean onboarding checklist), all 5 live Firebase demo accounts (`requester.demo@mashwar.qa`, `provider.demo@mashwar.qa`, `traveler.demo@mashwar.qa`, `fresh.demo@mashwar.qa`, `admin.demo@mashwar.qa`), and live Uber-style embedded maps (`HomeScreen`, full-screen map, `RideDetailsScreen`, `WorkRequestDetailsScreen`) with **0 console errors** and **0 external tabs opened**.
- **Admin Operations Portal (`build/web/admin`):** Verified live at `http://127.0.0.1:8080/admin/` with Firebase staff auth guard (`admin_staff/{uid}`), Cairo Arabic typography, live Uber corridor traffic map, Worksite Supply Ops (`Module 13`), and Landing Page Inquiries (`Module 12`).
- **Vendored Map Assets:** Verified `HTTP 200` on `/maps/mashwar_uber_map.html`, `/maps/leaflet/leaflet.js`, and `/maps/leaflet/leaflet.css` in both consumer and admin bundles.

---

## 4. Remaining External Pre-Launch Checks
1. **Physical `+974` SIM SMS OTP Verification:** Code is wired (`FirebaseAuthRepository`), pending Firebase Blaze upgrade and Qatar SMS region allowlist testing on live Ooredoo/Vodafone SIMs.
2. **Signed Native Store Binaries (`.aab` / `.ipa`):** Release configs and provisioning scripts are in place; store submission binaries require dedicated Android SDK & macOS/Xcode signing hosts.
