# Firebase Setup, Emulators & Deployment Guide — MASHWAR Platform
## Configuration Guide for Qatar Worksite Supply MVP (`mashwar-qatar-2026-ec99d`)

### 1. Overview
The MASHWAR Qatar Worksite Supply MVP uses Firebase (`europe-west1`) as its backend infrastructure, configured via [`.firebaserc`](../../.firebaserc) and [`firebase.json`](../../firebase.json):

- **Project ID:** `mashwar-qatar-2026-ec99d`
- **Primary Region:** `europe-west1`
- **Firebase Authentication:** Email + Password sign-in, registration, and password reset (`FirebaseAuthRepository`), plus staff authentication verified against Firestore `admin_staff/{uid}`. *(Note: `+974` Phone SMS OTP is intentionally disabled in code until an SMS provider / Firebase Phone Auth quota is configured.)*
- **Cloud Firestore:** 2,475-line [`firestore.rules`](../../firestore.rules) (Collections `1–19` preserved + Worksite Supply MVP Collections `20–29`) and 14 composite indexes in [`firestore.indexes.json`](../../firestore.indexes.json).
- **Cloud Functions v2 (`functions/`):** Node.js 20 TypeScript HTTPS `onCall` handlers for Worksite Supply lifecycle, salted SHA-256 handover verification, ratings, payment settlement tracking, and admin moderation.
- **Cloud Storage:** [`storage.rules`](../../storage.rules) enforcing `<= 10 MB` `image/*` ACLs for private 11-digit QID KYC media, reference photos, store invoices, and manual bank transfer proofs.

---

### 2. Prerequisites

| Tool | Required Version | Purpose | Current Workstation Status |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | `3.x+` | Customer & Admin Web/Mobile builds | Installed (`3.47.9`) |
| **Node.js & npm** | `20+` | Building & unit-testing `functions/` | Installed (`v24.19.0`) |
| **Firebase CLI** | `firebase-tools` (`npm i -g firebase-tools`) | Rules/Functions deployment & Emulator Suite | **Not installed in host `PATH`** |
| **Java Runtime (JRE/JDK)** | `Java 11+` (`Java 21 LTS` recommended) | Required by Firestore & Storage local JVM emulators | **Not installed in host `PATH`** |
| **FlutterFire CLI** | `dart pub global activate flutterfire_cli` | Regenerating native Android/iOS Firebase configs | Optional until native mobile build |

---

### 3. Environment Defines (`.env.example`)

Copy [`.env.example`](../../.env.example) to a local untracked `.env` file (never commit `.env` or real keys):

```dotenv
APP_ENV=development
USE_FIREBASE=false
USE_DEV_MOCKS=false
FIREBASE_PROJECT_ID=mashwar-qatar-2026-ec99d
FIREBASE_REGION=europe-west1
FIREBASE_WEB_API_KEY=REPLACE_WITH_FIREBASE_WEB_API_KEY
FIREBASE_ANDROID_API_KEY=REPLACE_WITH_FIREBASE_ANDROID_API_KEY
FIREBASE_IOS_API_KEY=REPLACE_WITH_FIREBASE_IOS_API_KEY
GOOGLE_MAPS_API_KEY=REPLACE_WITH_GOOGLE_MAPS_API_KEY
```

Pass values at compile/run time:
```powershell
flutter run -d chrome --dart-define-from-file=.env
```
Optional Cloud Functions endpoint overrides supported by `FirebaseConfig` ([`lib/data/services/firebase_firestore_service.dart`](../../lib/data/services/firebase_firestore_service.dart)):
- `--dart-define=FUNCTIONS_EMULATOR_HOST=127.0.0.1:5001`
- `--dart-define=FUNCTIONS_BASE_URL=https://europe-west1-mashwar-qatar-2026-ec99d.cloudfunctions.net`

> **Fail-Closed Safety:** `USE_DEV_MOCKS=true` is honored **only** when `APP_ENV=development` and `USE_FIREBASE=false`. Running `staging` or `production` without `USE_FIREBASE=true` displays `ServiceUnavailableScreen`.

---

### 4. Platform Provisioning (`flutterfire configure`)
When preparing native Android and iOS builds for Qatar, regenerate platform configuration against `mashwar-qatar-2026-ec99d`:

```powershell
flutterfire configure --project=mashwar-qatar-2026-ec99d --platforms=web,android,ios --ios-bundle-id=qa.mashwar.app --android-package-name=com.mashwar.app.mashwar
```
This provisions:
- `lib/firebase_options.dart` (updating native app IDs and replacing any legacy iOS bundle identifier with your Qatar bundle ID)
- `android/app/google-services.json` (ensure `com.google.gms.google-services` plugin and release keystore are configured in `android/app/build.gradle.kts`)
- `ios/Runner/GoogleService-Info.plist` (plus `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` in `ios/Runner/Info.plist` once native image picking is enabled)

---

### 5. Provisioning Initial Admin Staff (`admin_staff/{uid}`)
The Admin Operations Portal (`lib/admin_main.dart` / `/admin`) denies client-selected roles in Firebase mode. To authorize an administrator:
1. Create the staff user in **Firebase Console -> Authentication** (Email/Password) and copy their `UID`.
2. Create document `admin_staff/{UID}` in **Cloud Firestore**:
   ```json
   {
     "id": "<UID>",
     "uid": "<UID>",
     "name": "Qatar Ops Lead",
     "email": "ops@mashwar.qa",
     "role": "superAdmin",
     "isActive": true
   }
   ```
   *(Allowed roles in `functions/src/types.ts`: `superAdmin`, `reviewAdmin`, `supportAdmin`, `compliance`, `operations`.)*
3. For direct Firestore admin reads/writes governed by `isAdmin()` in `firestore.rules`, also set custom claim `{ "admin": true, "role": "superAdmin" }` on the staff user's Firebase Auth token via the Firebase Admin SDK.

---

### 6. Building & Testing Cloud Functions v2 (`functions/`)
```powershell
Push-Location functions
npm install
npm run build
npm test
Pop-Location
```
- Keep `functions/node_modules/` and `functions/lib/` untracked in Git (enforced via `.gitignore`).

---

### 7. Deploying Rules, Indexes & Functions (When Authorized)
Once authenticated via `firebase login` on a workstation with `firebase-tools` installed:
```powershell
# Deploy Firestore rules, composite indexes, and Cloud Storage rules
firebase deploy --only firestore:rules,firestore:indexes,storage

# Deploy Cloud Functions v2 (nodejs20, europe-west1)
firebase deploy --only functions
```

### 8. Storage Bucket CORS (Flutter Web Image Rendering)
To render invoice and receipt images directly in Flutter Web from `mashwar-qatar-2026-ec99d.firebasestorage.app`, apply a restricted `cors.json`:
```json
[
  {
    "origin": ["https://mashwar.qa", "http://localhost:8080", "http://localhost:8081"],
    "method": ["GET", "HEAD", "PUT", "POST"],
    "responseHeader": ["Content-Type", "Authorization", "Content-Length", "X-Goog-Upload-Protocol"],
    "maxAgeSeconds": 3600
  }
]
```
```powershell
gcloud storage buckets update gs://mashwar-qatar-2026-ec99d.firebasestorage.app --cors-file=cors.json
```

---

### 9. Local Firebase Emulator Suite
Configured in [`firebase.json`](../../firebase.json) (`singleProjectMode: true`):
- **Auth Emulator:** `127.0.0.1:9099`
- **Cloud Functions Emulator:** `127.0.0.1:5001`
- **Cloud Firestore Emulator:** `127.0.0.1:8085`
- **Cloud Storage Emulator:** `127.0.0.1:9199`
- **Emulator UI:** `http://127.0.0.1:4000`

After installing **Java 21 LTS** and **`firebase-tools`**:
```powershell
firebase emulators:start --only auth,firestore,functions,storage
```
