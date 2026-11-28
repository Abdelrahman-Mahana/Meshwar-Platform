# MASHWAR (مشوار — Qatar) Public-First Landing Page

Bilingual (**Arabic RTL / English LTR**) public-first website and executive partner room for **MASHWAR Qatar**, showcasing shared intercity rides, same-hour route parcels, and worksite supply across Qatar's flagship highway corridors.

## Architecture (10 Sections)
1. **Sticky Glassmorphic Header** — 5 navigation links (including subtle gold pill for Partners & Investors), AR/EN toggle, and live app launch CTA.
2. **Hero Section** — 5-second Qatar value proposition, dual CTAs, floating iPhone showcase (`assets/mobile/app_home_hero.png`), and 4 human business-proof cards.
3. **Interactive MASHWAR Live Map & Route Calculator (`#corridors`)** — Embeds `maps/mashwar_live_map.html` with 4 MASHWAR themes (`standard`, `light`, `satellite`, `night`), 5 flagship Qatar corridors, trips/month slider (`1–22`), and Rider/Contractor Savings vs. Driver/Runner Earnings toggle.
4. **3 Core Services (`#services`)** — Full-bleed editorial Qatar photography (`assets/services/service_{rides,parcels,worksite}.jpg`) with QAR pricing and benefit bullets.
5. **How MASHWAR Works (`#how-it-works`)** — 3-step visual timeline from 30-second posting to Dual-OTP handover.
6. **Everyday Qatar Stories (`#stories`)** — Grounded scenarios from Lusail, Al Khor, and Al Wakrah.
7. **Consumer App Walkthrough (`#showcase`)** — Interactive 5-screen consumer gallery (`app_home_hero`, `app_live_map_picker`, `app_ride_details`, `app_parcel_otp`, `app_worksite_supply`).
8. **Trust, Safety & Neutral Market Comparison (`#safety`)** — Inline SVG MASHWAR Trust Shield, 4 human safety pillars, neutral category comparison matrix, and Driver/Runner partner band.
9. **Executive Room (`#investors`)** — Tabbed dark-executive section with 36-Month Financial Model (`js/charts.js`), Operations Command Portal (`assets/web/admin_command_live.png`), and 12-Month Doha Launch Roadmap & Founder profile.
10. **Universal Live Firebase Contact Form (`#contact`)** — Connected to `js/firebase-contact.js` (`investor_inquiries` on `mashwar-qatar-2026-ec99d`) across 4 onboarding tracks.

## Local Preview
```powershell
npx serve -l tcp://127.0.0.1:8088 --no-port-switching -n landing_page
```
Then open `http://127.0.0.1:8088`.
