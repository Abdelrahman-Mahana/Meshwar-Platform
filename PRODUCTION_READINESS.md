# MASHWAR Platform — Production Readiness Assessment

**Assessed Commit:** `851d22d` (`main`)  
**Assessment Date:** 2026-11-28

---

## 1. Honest Production Readiness Verdict

> **VERDICT: CONDITIONALLY READY FOR CONTROLLED BETA / STAGING — NOT YET READY FOR UNRESTRICTED PUBLIC PRODUCTION LAUNCH**

### What Is Ready Now
The core **Worksite Supply MVP** architecture, dual web bundles (Consumer `/` and Admin `/admin/`), Qatar landing page, Cloud Functions v2 backend (`13/13` tests), Firestore/Storage security rules (`10/10` live emulator tests), and Flutter application (`0` analyze issues, `211/211` tests, `0` browser console/page errors in headless Edge QA) are clean, verified, and safe to deploy to a **controlled staging or invite-only pilot environment**.

### Why Unrestricted Public Production Is Blocked Today
Six concrete technical, operational, and legal gates remain outside or beyond the completed repository hardening:

1. **Three-Way Admin RBAC Sync (`R-21`):** `firestore.rules` authorizes admins via Auth Custom Claims, `functions/src/handlers.ts` checks `admin_staff/{uid}`, and `storage.rules` checks both. Without an atomic provisioning tool synchronizing both, live admin accounts can fail partial operations.
2. **Unofficial Map Tiles & Public Demo OSRM Server (`R-27`):** `mashwar_uber_map.html` fetches tiles from undocumented `mt{s}.google.com` URLs and routes via `router.project-osrm.org` (which explicitly prohibits production traffic and will throttle/ban under real load).
3. **Firebase App Check & Rate Limiting (`R-28`):** Not yet enabled in Flutter or Cloud Functions (`enforceAppCheck: true`); public `investor_inquiries` writes and `formsubmit.co` lack abuse protection.
4. **External Cloud Provisioning (`R-22`, `R-24`):** Firebase Blaze plan activation, deployment of rules/indexes/Cloud Functions v2 (`europe-west1`), GitHub Secrets injection, Vercel edge deploy, and live `+974` SIM SMS verification have not yet been executed against production cloud infrastructure.
5. **Secondary Admin Tabs & Complete PDPPL Account Purge (`R-23`, `R-29`):** Non-worksite Admin modules still need live Firestore persistence/telemetry, and `deleteUserAccount` needs atomic purging of `users/{uid}/private/*`, auxiliary docs, and Firebase Storage KYC prefixes to fully satisfy Qatar Law No. 13 of 2016 (PDPPL).
6. **Qatar Regulatory & Mobile Store Gates (`R-36`):** MoCI commercial registration, MoT transport/logistics licensing, QCB non-custodial payment confirmation, and physical iOS/Android App Store / Google Play builds remain external prerequisites.

---

## 2. Security Posture

| Security Control | Current State at `851d22d` | Production Gap |
| --- | --- | --- |
| **Handover Verification Crypto** | **Strong** — 6-char unambiguous alphabet, 128-bit hex salt, SHA-256, `timingSafeEqual`, 24h TTL, 5-attempt cap | None |
| **Firestore Security Rules** | **Hardened** — Secret isolation, parcel pickup/delivery OTP enforced, `admin_audit_logs` validated, CF worksite schema aligned, dead `users_public` removed; 10/10 Emulator PASS | Unify `isAdmin()` with `admin_staff` provisioning; add negative emulator tests for parcel OTP & audit logs |
| **Cloud Storage Rules & Upload Validation** | **Hardened** — Explicit raster MIME allowlist blocking `image/svg+xml`, 10 MB limit, magic-byte sniffing, scoped avatar/driver/chat/KYC/invoice paths | Ensure `deleteUserAccount` deletes `provider_verifications/{uid}/*` |
| **HTTP Security Headers (`vercel.json`)** | **Good** — HSTS (`2 years; includeSubDomains; preload`), `nosniff`, `Referrer-Policy`, `Permissions-Policy`, `DENY` root + `SAMEORIGIN`/`frame-ancestors 'self'` on `/maps/*` | Add scoped top-level `Content-Security-Policy` on `/(.*)` |
| **Abuse & Bot Protection** | **Insufficient for Public Scale** — Honeypot on landing form only | Enable Firebase App Check (`enforceAppCheck: true`) & server-side rate-limited inquiry callable |
| **Secrets & Key Management** | **Needs CI Hardening** — Fallback client config keys exist in `lib/firebase_options.dart` | Inject keys via GitHub Actions Secrets + restrict Firebase Web API key by HTTP referrer in GCP Console |
| **Privacy / Account Deletion (Qatar Law No. 13 of 2016)** | **Partial** — Active-request blocking + core doc & Auth user deletion implemented | Complete atomic purge of subcollections, auxiliary collections, and Storage KYC prefix |

---

## 3. Performance Posture

- **Build & Runtime Verified:**
  - Consumer production web bundle builds cleanly (`90.6s`, Wasm dry-run PASS).
  - Admin production web bundle builds cleanly (`79.9s`, Wasm dry-run PASS).
  - Zero console errors, zero page errors, and zero failed local requests across Consumer, Admin, and Landing Page in headless Edge QA (`1440x900 @ 2x`).
- **Completed Runtime Optimizations:**
  - Eliminated 48 modal/bottom-sheet `TextEditingController` leaks across 15 files.
  - Eliminated unnecessary root `MaterialApp` rebuilds (`lib/main.dart`).
  - Fixed `_TelemetryChartPainter.shouldRepaint` infinite repaint trigger.
  - Paused 60fps map animation when `document.hidden` or `prefers-reduced-motion: reduce`.
  - Added `StreamController` eviction/disposal in `FirebaseChatRepository` and timeouts on `_FirebaseAdminBackendGateway`.
  - Removed 21 unused image assets (~5.55 MB).
- **Remaining Performance Work:**
  - Compress remaining Flutter images (`assets/images/`, ~7.48 MB) to WebP `<150 KB` per image.
  - Replace 87 raw `fontFamily: 'Cairo'` references with `AppTypography` / `GoogleFonts.cairo` to eliminate web FOUT.
  - Add `.close()` lifecycles for `http.Client()` in `FirebaseFirestoreService` and `GoogleMapsService`.

---

## 4. Deployment & Environment Requirements

### 4.1 Firebase Project (Blaze Plan Required)
1. Upgrade Firebase project to **Blaze (Pay-as-you-go)** to enable Cloud Functions v2 (`europe-west1`) and live Phone Auth SMS.
2. Deploy security rules, indexes, and functions in order:
   ```powershell
   firebase deploy --only firestore:rules,firestore:indexes,storage
   Push-Location functions; npm ci; npm run build; npm test; Pop-Location
   firebase deploy --only functions
   ```
3. Provision initial Super Admin account with **both** Firebase Auth Custom Claim (`{ admin: true, role: "superAdmin" }`) **and** Firestore document `admin_staff/{uid}` (`isActive: true, role: "superAdmin"`).
4. Restrict the Firebase Web API key in Google Cloud Console to production domains (`mashwar.qa`, `*.mashwar.qa`, Vercel preview domains).

### 4.2 Vercel Hosting (`vercel.json`)
- Serve `build/web` from `scripts/build_platform.ps1 -AppEnv production` so `/` serves the Consumer App, `/admin/` serves the Admin Command Center, `/health.json` returns `200 OK` (`Cache-Control: no-cache, no-store, must-revalidate`), and `/maps/*` + `/admin/maps/*` emit `X-Frame-Options: SAMEORIGIN`.
- Verify live response headers after first production deploy (`HSTS`, `SAMEORIGIN` on `/maps/mashwar_uber_map.html`, `immutable` caching on `/assets/*` and `/canvaskit/*`).

### 4.3 GitHub Actions CI/CD (`.github/workflows/mashwar_ci_cd.yml`)
- Currently enforces: `analyze-and-test` (`flutter analyze` + `flutter test`) and `test-functions` (`npm ci`, `npm run build`, `npm test`), both gating `build-production-bundles`.
- Recommended Secrets to configure before public production: `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_PROJECT_ID`, `MAPS_TILE_API_KEY` (once licensed tiles replace unofficial URLs), and `VERCEL_TOKEN` / `FIREBASE_SERVICE_ACCOUNT` for automated deployments.

---

## 5. Operational Limitations & Remaining Risks

| Risk | Severity | Likelihood | Mitigation Required Before Public Launch |
| --- | --- | --- | --- |
| **Unofficial Google Tiles (`mt{s}.google.com`) Blocked / Public OSRM Rate-Limited** | High | High under real traffic | Migrate to licensed Google Maps / Mapbox tiles and self-hosted Qatar OSRM or commercial Directions API |
| **Admin RBAC Split Causes Partial `PERMISSION_DENIED`** | High | Medium | Ship atomic admin-provisioning CLI/callable setting Custom Claims + `admin_staff/{uid}` together |
| **Unprotected Public `investor_inquiries` & Callables Spam/Billing Abuse** | High | Medium | Enable Firebase App Check (`enforceAppCheck: true`) and move inquiry submission to a rate-limited Cloud Function |
| **Non-Worksite Admin Modules Displaying Seed Data / RAM-Only Actions** | Medium | High if operators use legacy tabs | Wire live Firestore persistence and disable/label any non-live secondary modules during Worksite MVP pilot |
| **Client-Driven Ride Booking Concurrency** | Medium | Medium under concurrent bookings | Move `bookRide` / `cancelBooking` into transactional Cloud Functions (`R-30`) |
| **Incomplete PDPPL Purge on Account Deletion** | Medium | Low-Medium | Extend `deleteUserAccount` to transactionally purge subcollections, auxiliary docs, and Storage KYC objects (`R-29`) |
| **Qatar Regulatory & Licensing Non-Compliance** | Critical (Legal) | N/A (Gate) | Obtain MoCI commercial registration, MoT transport/logistics clearance, and QCB non-custodial confirmation prior to public marketing |
| **Unverified Mobile Native Builds & Live `+974` SMS** | High (for Mobile) | N/A (Gate) | Execute physical iOS/Android test builds and live Qatar carrier SMS OTP tests on Blaze prior to store submission |

---

## 6. Recommended Go-Live Sequence

1. **Immediate (Controlled Beta / Pilot):** Upgrade Firebase to Blaze, deploy `firestore.rules`, `firestore.indexes.json`, `storage.rules`, and Cloud Functions v2, provision synced Admin accounts, deploy `build/web` to Vercel, and run live `+974` SMS OTP + end-to-end Worksite Supply pilot testing with invited users.
2. **Pre-Public Launch (Hard Gates):** Replace unofficial map tiles & public OSRM (`R-27`), enable App Check & rate-limited inquiries (`R-28`), finish atomic PDPPL deletion purge (`R-29`), unify Admin RBAC (`R-21`), and complete Qatar legal/regulatory clearances (`R-36`).
3. **Post-Launch Scale:** Wire remaining secondary Admin modules (`R-23`), move ride/board multi-doc mutations to Cloud Functions (`R-30`), add CI emulator rules gate (`R-31`), optimize image assets (`R-32`), and publish signed iOS/Android store builds.
