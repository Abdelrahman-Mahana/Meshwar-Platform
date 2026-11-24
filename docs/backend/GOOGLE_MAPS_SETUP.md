# Google Maps Platform & Qatar Geo-Catalog Setup — MASHWAR Platform
## Location Search, Corridor Routing & Offline Fallback for Qatar Worksite Supply

### 1. Overview
[`GoogleMapsService`](../../lib/data/services/google_maps_service.dart) powers pickup supplier search, worksite destination selection, distance/ETA estimation, and reverse geocoding across the **State of Qatar**:

1. **Live Google Maps Web Services (when `GOOGLE_MAPS_API_KEY` is provided):**
   - **Places Autocomplete API:** Restricted strictly to Qatar via `components=country:qa` (`language=ar`).
   - **Directions API:** Computes highway distance (`km`), duration (`minutes`), and route polyline across Qatar expressways (`region=qa`).
   - **Geocoding API:** Reverse-geocodes GPS coordinates into formatted Qatari street/zone addresses.
2. **Deterministic Offline Qatar Geo-Catalog Fallback (when `GOOGLE_MAPS_API_KEY` is empty or offline):**
   - Built-in `GoogleMapsService.qatarCitiesCatalog` covering **all 8 Qatari municipalities and 22 key industrial, residential, and worksite hubs**:
     - **Al Rayyan Municipality (`بلدية الريان`):** Industrial Area (`المنطقة الصناعية`), Al Rayyan (`الريان`), Education City (`المدينة التعليمية`), Abu Samra (`أبو سمرة`).
     - **Doha Municipality (`بلدية الدوحة`):** Doha (`الدوحة`), Msheireb (`مشيرب`), Al Sadd (`السد`), West Bay / Al Dafna (`الدفنة`), The Pearl (`اللؤلؤة`), Katara (`كتارا`), Hamad International Airport (`مطار حمد الدولي`).
     - **Al Daayen Municipality (`بلدية الضعاين`):** Lusail (`لوسيل`), Al Daayen (`الضعاين`).
     - **Al Wakrah Municipality (`بلدية الوكرة`):** Al Wakrah (`الوكرة`), Mesaieed (`مسيعيد`).
     - **Al Khor & Al Thakhira Municipality (`بلدية الخور والذخيرة`):** Al Khor (`الخور`), Ras Laffan (`رأس لفان`), Al Thakhira (`الذخيرة`).
     - **Umm Salal (`بلدية أم صلال`):** Umm Salal (`أم صلال`).
     - **Al Shahaniya (`بلدية الشيحانية`):** Al Shahaniya (`الشيحانية`), Dukhan (`دخان`).
     - **Al Shamal (`بلدية الشمال`):** Al Shamal (`الشمال`).
   - *Note:* When running without an API key, `_estimateQatarRoute` uses a lightweight coordinate heuristic (`dLat`/`dLng` road-factor approximation) suitable for offline UI previews rather than turn-by-turn navigation.

---

### 2. Google Cloud Console Setup (`mashwar-qatar-2026-ec99d`)
1. Open [Google Cloud Console](https://console.cloud.google.com/) and select project **`mashwar-qatar-2026-ec99d`**.
2. Navigate to **APIs & Services -> Library** and enable:
   - **Places API**
   - **Directions API**
   - **Geocoding API**
   - **Maps JavaScript API** *(if embedding interactive Google Map tiles on Web)*
   - **Maps SDK for Android** & **Maps SDK for iOS** *(when native map SDK widgets are added)*

---

### 3. API Key Creation & Restrictions
Never commit raw Google Maps API keys to Git. Provision separate, restricted keys per platform:

#### A. Web Key
- **Application Restrictions:** HTTP referrers:
  - `https://mashwar.qa/*`
  - `https://mashwar-qatar-2026-ec99d.web.app/*`
  - `http://localhost:*`
- **API Restrictions:** Maps JavaScript API, Places API, Directions API, Geocoding API.

#### B. Android Key
- **Application Restrictions:** Android apps:
  - Package name: `com.mashwar.app.mashwar` (matches [`android/app/build.gradle.kts`](../../android/app/build.gradle.kts))
  - Debug & production release keystore SHA-1 fingerprints.
- **API Restrictions:** Maps SDK for Android, Places API, Directions API, Geocoding API.

#### C. iOS Key
- **Application Restrictions:** iOS apps:
  - Qatar bundle identifier: `qa.mashwar.app` (align `ios/Runner` and `flutterfire configure` before App Store submission).
- **API Restrictions:** Maps SDK for iOS, Places API, Directions API, Geocoding API.

---

### 4. Supplying `GOOGLE_MAPS_API_KEY` at Build / Run Time

`AppEnvironment.googleMapsApiKey` ([`lib/core/config/app_environment.dart`](../../lib/core/config/app_environment.dart)) and `GoogleMapsService` ([`lib/data/services/google_maps_service.dart`](../../lib/data/services/google_maps_service.dart)) read `GOOGLE_MAPS_API_KEY` via `--dart-define`:

```powershell
# Using .env file (copied from .env.example)
flutter run -d chrome --dart-define-from-file=.env

# Or explicit flag
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY="YOUR_RESTRICTED_KEY"
```

> **Note on Current Visual Map Widget:** Inside the Flutter client, corridor visuals are rendered locally via `QatarLiveMapCanvas` (`lib/core/widgets/qatar_live_map_canvas.dart`) with zero external script tag in `web/index.html`, while `GoogleMapsService` handles HTTP Places/Directions/Geocoding queries when `GOOGLE_MAPS_API_KEY` is set.
