# FIREBASE SETUP & DEPLOYMENT GUIDE — MASHWAR PLATFORM

## 1. Overview
The MASHWAR (مشوار) platform uses Firebase as its backend cloud infrastructure, supporting:
- **Firebase Authentication**: Phone SMS OTP authentication, custom claims for roles (`is_admin`, `is_driver`), and anonymous auth for browsing.
- **Cloud Firestore**: Real-time NoSQL database structured around Rides, Parcels, Board Ads, Chats, Transactions, and Audits.
- **Cloud Storage**: Secure media uploads (profile pictures, vehicle inspection documents, national IDs, parcel photos).
- **Cloud Functions**: Privileged server-side mutations (booking acceptance, ride completion, wallet settlement, notifications).
- **Firebase Cloud Messaging (FCM)**: Push notifications for trip updates, messages, and offer responses.

---

## 2. Prerequisites
1. **Node.js** v18+ and `npm` installed.
2. **Firebase CLI** installed globally:
   ```bash
   npm install -g firebase-tools
   ```
3. **Flutter SDK** v3.19+ with `flutterfire_cli` activated:
   ```bash
   dart pub global activate flutterfire_cli
   ```

---

## 3. Firebase Project Creation
1. Navigate to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and name it `meshwar-platform` (or your chosen project ID).
3. (Optional) Enable Google Analytics according to project requirements.
4. Upgrade project to the **Blaze (Pay as you go)** plan to support Cloud Functions and external Google Maps API requests.

---

## 4. Platform Provisioning (FlutterFire CLI)
Run the automated configuration wizard from the root of the Flutter project:
```bash
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID>
```
Select the target platforms:
- `web`
- `android`
- `ios`

This command generates and populates:
- `lib/firebase_options.dart` with platform-specific client API keys and identifiers.
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

---

## 5. Security Rules & Index Deployment
Deploy the Firestore security rules and composite indexes defined in this repository:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### Verification:
Ensure the deployment output displays:
```
✔  firestore: released rules firestore.rules to cloud.firestore
✔  firestore: indexes deployed successfully
```

---

## 6. Cloud Functions Deployment
The Cloud Functions source code is located under `functions/`.

1. Navigate to the functions directory:
   ```bash
   cd functions
   npm install
   ```
2. Build TypeScript source (if applicable) and deploy:
   ```bash
   firebase deploy --only functions
   ```

---

## 7. Storage Bucket & CORS Setup
For Flutter Web to display images directly from Firebase Storage, configure CORS on the Google Cloud Storage bucket:

Create `cors.json`:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "HEAD"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
```

Apply via Google Cloud SDK (`gsutil` or `gcloud storage`):
```bash
gcloud storage buckets update gs://<YOUR_STORAGE_BUCKET> --cors-file=cors.json
```

---

## 8. Local Emulator Suite Setup (For Testing)
To run automated tests and offline development without consuming cloud quotas:
```bash
firebase emulators:start --only auth,firestore,functions,storage
```
Default ports:
- Auth: `9099`
- Firestore: `8080` / `8085`
- Functions: `5001`
- Storage: `9199`
- Emulator UI: `4000`
