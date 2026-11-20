# GOOGLE MAPS PLATFORM SETUP GUIDE — MASHWAR PLATFORM

## 1. Overview
The MASHWAR (مشوار) platform integrates Google Maps Platform to provide:
1. **Interactive Route Maps**: Route preview between origin and destination cities and stops.
2. **Places Autocomplete**: City, district, and pickup location search with debounced querying.
3. **Directions API**: Distance and duration matrix calculation for accurate pricing.
4. **Reverse Geocoding**: Converting GPS pin coordinates into readable Arabic/English street names.

---

## 2. Google Cloud Console Configuration
1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Select your Firebase project linked to Meshwar.
3. In the navigation menu, go to **APIs & Services** > **Library**.
4. Enable the following four required APIs:
   - **Maps JavaScript API** (required for Flutter Web & Admin Web Dashboard)
   - **Maps SDK for Android** (required for Android APK / AAB)
   - **Maps SDK for iOS** (required for iOS Runner)
   - **Places API (New)** & **Geocoding API**
   - **Directions API**

---

## 3. API Key Creation & Security Restrictions
Never leave API keys unrestricted in production. Create three distinct keys with proper restrictions:

### Key 1: Web Key (`MESHWAR_MAPS_WEB_KEY`)
- **API Restrictions**: Maps JavaScript API, Places API, Geocoding API, Directions API.
- **Application Restrictions**: HTTP referrers (websites).
  - Add your production domain: `https://meshwar.app/*`
  - Add staging domain: `https://meshwar-staging.web.app/*`
  - Add local development: `http://localhost:*`

### Key 2: Android Key (`MESHWAR_MAPS_ANDROID_KEY`)
- **API Restrictions**: Maps SDK for Android.
- **Application Restrictions**: Android apps.
  - Package name: `com.meshwar.mashwar` (or your registered package id).
  - SHA-1 fingerprint: Obtain via `gradlew signingReport` (debug and release keystores).

### Key 3: iOS Key (`MESHWAR_MAPS_IOS_KEY`)
- **API Restrictions**: Maps SDK for iOS.
- **Application Restrictions**: iOS apps.
  - Bundle identifier: `com.meshwar.mashwar`.

---

## 4. Injecting Keys into the Codebase

### Flutter Web (`web/index.html`)
In the `<head>` section of `web/index.html`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY&libraries=places"></script>
```

### Android (`android/app/src/main/AndroidManifest.xml`)
Inside the `<application>` tag:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY"/>
```

### iOS (`ios/Runner/AppDelegate.swift`)
```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 5. Environment Variables & CI/CD
To avoid committing API keys to Git, inject keys at compile time using `--dart-define`:
```bash
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY="AIzaSy..."
```
In Dart code (`lib/data/services/google_maps_service.dart`):
```dart
static const String apiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: '',
);
```
