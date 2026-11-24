# Qatar Compliance, Trademark & Mobile Release Playbook — MASHWAR (`مشوار`)

## 1. Executive Summary & Pilot Scope

This playbook governs legal, regulatory, data-privacy, telecom, and mobile store release operations for **MASHWAR (`مشوار`)** in the **State of Qatar** against Firebase project `mashwar-qatar-2026-ec99d` (`europe-west1`).

### Active Phase 1 MVP Scope (`enableWorksiteSupply = true`)
- **Core Service:** On-demand B2B and site worksite supply & hardware material errand coordination across Qatar's 8 municipalities (`Doha`, `Industrial Area`, `Lusail`, `Al Wakrah`, `Al Khor`, `Al Rayyan`, `Mesaieed`, `Ras Laffan`).
- **Pricing & Settlement:** Integer QAR minor units (`1 QAR = 100 dirhams`) settled strictly off-platform via **Cash on Delivery (`cash_on_delivery`)** or **Manual Bank Transfer (`bank_transfer_manual`)** with uploaded receipt/proof tracking. MASHWAR does **not** hold stored-value wallet balances or act as a financial escrow custodian in Phase 1.
- **Handover Integrity:** Single-use 6-character alphanumeric handover verification codes (`[A-HJ-NP-Z2-9]{6}`) verified server-side via salted constant-time SHA-256 (`5` attempts max, `24h` TTL).

### Registered Firebase Apps (`mashwar-qatar-2026-ec99d`)

| Platform | Display Name | Package / Bundle ID | Registered Firebase App ID |
| :--- | :--- | :--- | :--- |
| **Web** | `mashwar-qatar-web` | `mashwar.qa` / Hosting | `1:820084343406:web:ad6ce9779a06584bd35c7f` |
| **Android** | `mashwar-qatar-android` | `com.mashwar.app.mashwar` | `1:820084343406:android:a9e464e38a988eddd35c7f` |
| **iOS** | `mashwar-qatar-ios` | `qa.mashwar.app` | `1:820084343406:ios:5073f983643cc020d35c7f` |

---

## 2. Qatar MoCI Single Window Trademark Search & Filing (`MASHWAR / مشوار`)

Before public commercial promotion or store listing publication in Qatar, complete formal trademark clearance and registration through the **Ministry of Commerce and Industry (MoCI)** Intellectual Property Protection Department via the **Qatar Single Window (`investor.sw.gov.qa`)**:

### Step 2.1 — Entity & Commercial Registration (CR) Prerequisites
1. Maintain an active Qatari **Commercial Registration (CR / السجل التجاري)** and **Trade License (الرخصة التجارية)** covering technology platform / delivery coordination / commercial brokerage activities.
2. Authenticate on Qatar Single Window (`investor.sw.gov.qa`) using NAS (National Authentication System / Tawtheeq) as an authorized signatory or registered Qatari IP agent.

### Step 2.2 — Prior-Art Clearance Search
Conduct an official trademark availability search across both Arabic and Latin scripts before filing:
- **Arabic Wordmark:** `مشوار` (including phonetic/orthographic variants such as `مشوار قطر`)
- **Latin Wordmark:** `MASHWAR` (and common transliteration `MESHWAR`)
- **Combined Logo Device:** Official MASHWAR app icon and bilingual logotype

### Step 2.3 — Nice Classification Classes to File
File separate trademark applications in Qatar under the **Nice Classification** for all three operational classes:

| Nice Class | Scope for MASHWAR Qatar |
| :--- | :--- |
| **Class 35** | Online marketplace operation for buyers and suppliers of worksite materials and hardware; commercial intermediary services; B2B procurement order coordination; business directory and supplier verification administration. |
| **Class 39** | Pickup, transport, courier, and worksite supply delivery coordination; logistics routing information and physical handover tracking (covering current worksite supply delivery coordination and future transport expansion). |
| **Class 42** | Software-as-a-Service (SaaS); design, hosting, and maintenance of mobile and web applications for logistics dispatch, cryptographic handover verification, and enterprise worksite operations. |

### Step 2.4 — Examination, Gazette Publication & Store Brand Protection
1. **Filing & Formal Examination:** Submit artwork, CR copy, and class specifications via MoCI IP portal and pay official search/filing fees per class.
2. **Official Gazette Publication:** Upon examiner acceptance, pay publication fees for the **MoCI Trademarks Gazette** statutory opposition window.
3. **Final Registration Certificate:** Pay final registration fees to obtain the **10-year Qatar Trademark Registration Certificate** and archive PDF copies for **Apple App Store Connect** and **Google Play Console** intellectual property verification.
4. **Third-Party Trademark Hygiene:** Never display logos or claim integration/endorsement with **QCB**, **Fawran**, **QPay**, **SkipCash**, or **Ministry of Transport (MoT)** unless a signed commercial/licensing agreement is active.

---

## 3. Firebase Phone Auth (`+974`) Blaze Plan & Qatar CRA SMS Rollout

Email + Password authentication is active today. Rolling out live `+974` SMS OTP (`FirebaseAuthRepository`) in production requires both Firebase billing/attestation setup and Qatar telecom compliance:

### Step 3.1 — Firebase Blaze Plan & SMS Fraud Controls
1. Upgrade `mashwar-qatar-2026-ec99d` to the **Firebase Blaze (Pay-as-you-go)** plan in Google Cloud / Firebase Console and configure budget alerts (e.g., 50%, 80%, 100% monthly spend thresholds).
2. In **Firebase Console -> Authentication -> Sign-in method -> Phone**, ensure **Phone** is enabled.
3. In **Authentication -> Settings -> SMS region policy**, set an **Allowlist** permitting **ONLY Qatar (`+974`)** to eliminate international SMS pumping fraud.
4. Configure per-IP/daily SMS verification quotas and enable **Firebase App Check** (Play Integrity on Android, App Attest / DeviceCheck on iOS, reCAPTCHA Enterprise on Web).

### Step 3.2 — Native App Attestation for Phone Auth
- **Android (`com.mashwar.app.mashwar`):**
  - Register **both** the local **Upload Keystore** SHA-1 / SHA-256 fingerprints **and** the **Google Play App Signing** certificate SHA-1 / SHA-256 fingerprints under `mashwar-qatar-android` in Firebase Project Settings.
  - Enable **Google Play Integrity API** in Google Cloud Console (`mashwar-qatar-2026-ec99d`).
  - Re-fetch `android/app/google-services.json` via `scripts/fetch_firebase_configs.ps1` after adding SHA fingerprints so `oauth_client` entries are populated.
- **iOS (`qa.mashwar.app`):**
  - Generate an **Apple Push Notification Authentication Key (`.p8`)** in Apple Developer Portal (`Keys -> Apple Push Notifications service (APNs)`), and upload the `.p8` file, **Key ID**, and **Apple Team ID** to **Firebase Console -> Project Settings -> Cloud Messaging -> Apple app configuration (`mashwar-qatar-ios`)**.
  - Re-fetch `ios/Runner/GoogleService-Info.plist` via `scripts/fetch_firebase_configs.ps1` and register its `REVERSED_CLIENT_ID` inside `CFBundleURLTypes` in `ios/Runner/Info.plist` for reCAPTCHA fallback when silent APNs is unavailable.

### Step 3.3 — Qatar CRA & Telecom Sender ID Registration (Custom SMS Gateway Option)
If migrating from default Firebase SMS routes to a custom branded alphanumeric Sender ID (`MASHWAR`) via an enterprise aggregator on **Ooredoo Qatar** and **Vodafone Qatar**:
1. Register the `MASHWAR` Sender ID under **Communications Regulatory Authority (CRA)** and operator anti-spam rules using the Qatari CR, signatory QID, and official NOC/Authorization Letter on company letterhead.
2. Pre-register transactional OTP templates (Arabic & English) with the telecom aggregator; never send promotional traffic over transactional OTP routes.

---

## 4. Android Release Signing & Google Play Store Deployment

### Step 4.1 — Fetch Native Config & Generate Upload Keystore
```powershell
# 1. Download gitignored android/app/google-services.json & ios/Runner/GoogleService-Info.plist
powershell -ExecutionPolicy Bypass -File scripts/fetch_firebase_configs.ps1

# 2. Generate gitignored android/upload-keystore.jks & android/key.properties
powershell -ExecutionPolicy Bypass -File scripts/generate_upload_keystore.ps1
```
- **Secret Hygiene:** `.gitignore` strictly blocks `android/key.properties`, `android/app/key.properties`, `*.jks`, `*.keystore`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist` while keeping `.example` templates tracked. Store `upload-keystore.jks` and `key.properties` in the organization's encrypted secret manager immediately.
- **Gradle Readiness:** `android/app/build.gradle.kts` automatically uses `signingConfigs.getByName("release")` when `android/key.properties` + `upload-keystore.jks` exist, enables R8 code shrinking + resource shrinking with [`android/app/proguard-rules.pro`](../android/app/proguard-rules.pro), and applies `com.google.gms.google-services` (`4.4.2`) when `android/app/google-services.json` is present.

### Step 4.2 — Extract SHA-1 & SHA-256 Fingerprints
```powershell
& "$env:LOCALAPPDATA\Programs\OpenJDK21\bin\keytool.exe" -list -v -keystore android/upload-keystore.jks -alias upload
```
Add both `SHA1` and `SHA256` fingerprints to Firebase Console (`mashwar-qatar-android`), then re-run `scripts/fetch_firebase_configs.ps1`.

### Step 4.3 — Build Signed Android App Bundle (`.aab`) & Play Console Checklist
```powershell
flutter build appbundle --release `
  --dart-define=APP_ENV=production `
  --dart-define=USE_FIREBASE=true `
  --dart-define=USE_DEV_MOCKS=false
```
1. Enroll `com.mashwar.app.mashwar` in **Google Play App Signing** and copy Google's **App signing key certificate** `SHA-1` & `SHA-256` back into Firebase Console.
2. Complete **Google Play Data Safety**:
   - Declare collection of **Name, Email, Phone Number (`+974`)**, **Personal Identifiers / Photos (11-digit QID KYC images for providers, invoice/receipt photos)**, and **Worksite Location Names/Coordinates**.
   - Declare encryption in transit (TLS) and **in-app + web Account Deletion** support (`DeleteAccountScreen` -> `deleteUserAccount` Cloud Function).

---

## 5. iOS Provisioning, Privacy Strings & App Store Connect Deployment

### Step 5.1 — Bundle ID, Capabilities & Privacy Purpose Strings
- **Bundle Identifier:** Aligned across `Runner` (`qa.mashwar.app`) and `RunnerTests` (`qa.mashwar.app.RunnerTests`) in [`ios/Runner.xcodeproj/project.pbxproj`](../ios/Runner.xcodeproj/project.pbxproj) and [`lib/firebase_options.dart`](../lib/firebase_options.dart).
- **Info.plist Declarations ([`ios/Runner/Info.plist`](../ios/Runner/Info.plist)):**
  - `NSCameraUsageDescription` — Capturing QID KYC documents, worksite material reference photos, store invoices, and payment receipts.
  - `NSPhotoLibraryUsageDescription` — Attaching QID KYC photos, worksite supply photos, store invoices, and manual transfer proofs.
  - `NSPhotoLibraryAddUsageDescription` — Saving receipts, invoices, and handover confirmation records.
  - `LSApplicationQueriesSchemes` — `tel`, `mailto`, `https` for emergency/support dialing and external links.

### Step 5.2 — Xcode Archive & App Store Review Checklist (macOS CI / Build Host)
1. Run `powershell -ExecutionPolicy Bypass -File scripts/fetch_firebase_configs.ps1` (or `firebase apps:sdkconfig IOS 1:820084343406:ios:5073f983643cc020d35c7f --out ios/Runner/GoogleService-Info.plist` on macOS) and verify `GoogleService-Info.plist` is copied into the `Runner` bundle target in Xcode.
2. Configure **Apple Developer Team**, **Push Notifications** capability, and **App Store Provisioning Profile** for `qa.mashwar.app`.
3. Build release archive on macOS:
   ```bash
   flutter build ipa --release \
     --dart-define=APP_ENV=production \
     --dart-define=USE_FIREBASE=true \
     --dart-define=USE_DEV_MOCKS=false
   ```
4. **App Review Guideline 5.1.1(v) (Account Deletion):** Provide reviewer demo credentials (requester & approved provider) and document the direct path: `Account -> Settings / Delete Account -> Confirm Permanent Deletion` (`deleteUserAccount` Cloud Function, which cleanly blocks deletion only when active/disputed worksite orders exist).

---

## 6. Qatar Personal Data Privacy Law (PDPL Law No. 13 of 2016) Compliance

MASHWAR enforces technical and operational controls aligned with **Qatar Law No. 13 of 2016 on Personal Data Privacy Protection (PDPL)** supervised by the **National Cyber Security Agency (NCSA)** — National Cyber Governance and Assurance Affairs:

1. **Lawful Purpose & Explicit Consent (Articles 4 & 9):** Personal data (name, `+974` phone, email) and sensitive KYC verification records (11-digit QID number and front/back/selfie images) are collected strictly for user authentication, worksite order fulfillment, and provider identity verification.
2. **Strict Access Control (`firestore.rules` & `storage.rules`):**
   - `provider_verifications/{uid}` documents and `/provider_verifications/{uid}/*` Storage objects (`<= 10 MB`, `image/*` only) are accessible **exclusively** to the owning user and active staff in `admin_staff/{uid}` — never readable by other customers or providers.
   - `work_request_secrets/{requestId}` is blocked from all client reads/writes; handover codes are stored only as salted SHA-256 hashes alongside requester-only `work_request_handover_view/{requestId}`.
3. **Data Subject Rights & Erasure (Articles 5–7):** Users can inspect/update their profile and invoke permanent account deletion (`deleteUserAccount`), removing `users/{uid}`, `provider_profiles/{uid}`, `provider_verifications/{uid}`, `business_profiles/{uid}`, and Firebase Auth credentials once active/disputed worksite requests are settled, while writing an immutable compliance entry to `admin_audit_logs`.
4. **Cross-Border Cloud Processing & Incident Escalation (Articles 14–15):** Disclose cloud hosting in `europe-west1` within the Privacy Policy (Tab 2 of `LegalComplianceScreen`), enforce least-privilege IAM + MFA on Google Cloud/Firebase, and report any personal data breach affecting individuals to NCSA and impacted users within **72 hours**.

---

## 7. Regulatory Licensing Gates Before Unflagging Phase 2 (`AppEnvironment`) Modules

All regulated transport and financial custody modules are hard-disabled (`false`) in [`lib/core/config/app_environment.dart`](../lib/core/config/app_environment.dart). **No engineering PR may set any flag below to `true`** until every corresponding legal and technical prerequisite is signed off:

| Feature Flag (`AppEnvironment`) | Default | Governing Qatar Authority | Mandatory Pre-Activation Gate |
| :--- | :---: | :--- | :--- |
| `enablePassengerRides` | `false` | **Ministry of Transport (MoT)** & General Directorate of Traffic | Obtain formal MoT Land Transport / Smart Mobility dispatch license, commercial passenger insurance framework, and licensed driver/vehicle permit integration. |
| `enableCarpooling` | `false` | **Ministry of Transport (MoT)** | Obtain explicit written MoT regulatory approval / sandbox exemption defining permissible inter-municipality peer cost-sharing caps and private vehicle rules. |
| `enableCommercialCargo` | `false` | **Ministry of Transport (MoT)** | Obtain MoT commercial freight / light goods transport operator licensing and vehicle fleet compliance verification. |
| `enableDigitalWallet` | `false` | **Qatar Central Bank (QCB)** | Obtain QCB Payment Services / FinTech Stored-Value authorization **or** integrate a QCB-licensed Payment Service Provider (PSP) where customer funds never sit in unlicensed MASHWAR ledger custody. |
| `enableEscrowClaims` | `false` | **Qatar Central Bank (QCB)** | Contract a QCB-licensed PSP / partner bank supporting regulated split-settlement or escrow accounts with audited reconciliation and dispute release rules. |
