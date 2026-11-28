# MASHWAR (مشوار) — Landing Page & Investor Preview

Bilingual (**Arabic RTL / English LTR**) product & investor landing page for **MASHWAR**, updated to reflect the live 3-pillar platform, the embedded Uber-style live Qatar route map, fresh Retina app & admin screenshots, and the live Firebase inquiry form.

## What's Inside
1. **Hero & Live Proof Strip** — Plain-spoken overview of MASHWAR's 3 services (Shared Trips, Route Parcels with dual 4-digit OTPs, and Smart Worksite Supply with live receipts & 6-char SHA-256 handover codes) backed by verified engineering stats (`200/200` Flutter tests, `11/11` Cloud Functions security tests, `10/10` live Emulator rules tests, `14` Admin modules).
2. **Interactive Qatar Corridors + Live Uber-Style Map (`maps/mashwar_uber_map.html`)** — Click any of the 5 key corridors (`Doha ↔ Al Khor`, `Industrial Area ↔ Lusail`, `Doha ↔ Mesaieed`, `Industrial Area ↔ Al Wakrah`, `Doha ↔ Dukhan`) to watch the embedded map auto-fit the full route on live Google Maps + traffic tiles with an animated vehicle icon alongside real time and cost benchmarks.
3. **3 Core Services + Direct Settlement & Safety Flow** — Clear breakdown of how Shared Trips, Route Parcels, and Worksite Supply work day-to-day, plus the 4-step verification loop (QID check, live store receipt photo, 6-char SHA-256 / 4-digit OTP handover, direct Cash or verified Bank Transfer proof).
4. **Live App & 14-Module Admin Walkthrough** — Fresh Retina screenshots from the actual running Consumer Web App (Home Uber map, Full-Screen Traffic Map, Ride Details, Worksite Supply) and the newly updated Operations Admin Portal, with direct local preview buttons.
5. **Comparison Matrix, Technical Readiness & 36-Month Investor Model** — Interactive `Base` / `Stress (-30%)` and `USD` / `QAR` financial charts, corridor economics simulator, founder roadmap, and the live Firebase contact form (`js/firebase-contact.js` -> `investor_inquiries` in `mashwar-qatar-2026-ec99d`).

## Local Preview
Run `run_landing_page.bat` from the repository root, or serve directly:
```powershell
npx serve -l tcp://127.0.0.1:8088 --no-port-switching -n landing_page
```
Then open `http://127.0.0.1:8088`.
