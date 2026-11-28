# Google Maps & Live In-App Map Engine — MASHWAR

## Overview

Location search, route metrics, and interactive maps inside MASHWAR are powered by two complementary layers:

1. **In-App Uber-Style Live Animated Map Engine (`web/maps/mashwar_uber_map.html`)**
   - Vendored **Leaflet 1.9.4** locally under [`web/maps/leaflet/`](../../web/maps/leaflet/) so maps never break due to external script CDNs.
   - Renders real **Google Maps Roads + Live Traffic tiles** (`mt{s}.google.com/vt/lyrs=m@221097413,traffic`), plus instant switching to **Uber Light (CartoDB Voyager 2x)**, **Google Satellite Hybrid (`lyrs=y`)**, and **Uber Night Dark (`dark_all`)**.
   - Fetches real road-following polylines across Qatar via **OSRM** (`router.project-osrm.org`) with an immediate curved highway fallback, multi-segment traffic coloring, and automatic **full-route `fitBounds`** framing so both origin and destination pins always sit inside the visible frame.
   - Animates service-specific SVG vehicles at 60fps along the road polyline with heading rotation:
     - `trip`: Top-down Uber sedan car + nearby cruising cars
     - `parcel`: Express parcel delivery van
     - `supply`: Worksite supply pickup truck
     - `place`: Pulsing radar pin for single-location preview
   - Wired across Flutter Web via [`MashwarEmbeddedGoogleMap`](../../lib/core/widgets/mashwar_embedded_google_map.dart), [`MashwarGoogleMapPanel`](../../lib/core/widgets/mashwar_google_map_panel.dart), and full-screen [`MashwarInAppMapScreen`](../../lib/core/widgets/mashwar_in_app_map_screen.dart) across 12 consumer screens plus the Admin Portal (`AdminLoginScreen`, `AdminDashboardScreen`, `AdminCorridorsGeoScreen`). On Dart VM tests and non-web targets, it renders a deterministic `QatarLiveMapCanvas` fallback so tests stay fast and `pumpAndSettle`-safe.

2. **Google Maps Platform Web Services & Offline Qatar/GCC Geo-Catalog (`GoogleMapsService`)**
   - [`GoogleMapsService`](../../lib/data/services/google_maps_service.dart) integrates Google Places API (New v1), Routes API v2, and Geocoding when `GOOGLE_MAPS_API_KEY` is provided at build/run time.
   - When running without an API key or offline, it falls back cleanly to a **38-hub bilingual Qatar & GCC geo-catalog** covering all 8 Qatar municipalities (Doha, Al Rayyan, Al Daayen/Lusail, Al Wakrah/Mesaieed, Al Khor/Ras Laffan, Umm Salal, Al Shahaniya/Dukhan, Al Shamal) plus nearby regional corridors.

---

## Passing `GOOGLE_MAPS_API_KEY` at Build Time

Never commit raw API keys to Git. Pass a domain-restricted key via `--dart-define` or the release build script:

```powershell
# Local run with .env (copied from .env.example)
flutter run -d chrome --dart-define-from-file=.env

# Production web build (Consumer + Admin)
powershell -ExecutionPolicy Bypass -File scripts/build_platform.ps1 -AppEnv production -GoogleMapsApiKey "YOUR_RESTRICTED_KEY"
```

### Recommended Key Restrictions (Google Cloud Console — `mashwar-qatar-2026-ec99d`)
- **Web Key:** Restrict by HTTP referrer (`https://mashwar.qa/*`, `https://mashwar-qatar-2026-ec99d.web.app/*`, `http://localhost:*`, `http://127.0.0.1:*`) and enable Places API (New), Routes API, and Geocoding API.
- **Android Key:** Restrict to package `com.mashwar.app.mashwar` + release/debug SHA-1 fingerprints.
- **iOS Key:** Restrict to bundle identifier `qa.mashwar.app`.
