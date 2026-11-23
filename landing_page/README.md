# MASHWAR (مشوار — Qatar) Lean Investor Landing Page

Self-contained, bilingual (**Arabic RTL / English LTR**) investor & Startup Qatar landing page tailored for VC due diligence and Qatar corridor economics.

## Architecture (8 Executive Chapters)
1. **Hero & Business Proof Strip** — Animated Qatar corridor network SVG, floating iPhone mockup, and business metrics (`4-in-1`, `2–3h` delivery, `75%` savings, `M21` EBITDA breakeven, `100%` in-house code).
2. **Interactive Qatar Corridor Economics** — 4 clickable Qatar routes (`Doha ↔ Al Khor`, `Doha ↔ Mesaieed`, `Industrial Area ↔ Al Wakrah`, `Doha ↔ Dukhan`) comparing shared fares, same-day OTP parcel speed, and driver payouts.
3. **4-in-1 Asset-Light Services** — Carpooling (`11%`), Same-Day OTP Parcels (`18%`), Dual-Intent Community Board (`18%`), and B2B SME SaaS (`$79/mo`).
4. **Interactive Mobile & RBAC Admin Console** — 5+2 tab mobile showcase plus live consumer web and Admin RBAC (`KPIs`, `24h QID KYC`) viewer.
5. **Competitive Positioning Matrix & Technical Due Diligence** — Head-to-head comparison vs Uber/Karwa, Aramex/Q-Post, and informal groups + cursor-spotlight engineering & security cards (`Fawran`, `QPay`, `SkipCash`, `Apple Pay`).
6. **Investor Data Room (36-Month Operating Model)** — Scenario (`Base` / `Stress -30%`) and Currency (`USD` / `QAR @ 3.64`) switches driving TAM/SAM/SOM cards, 3 interactive SVG charts, interactive Corridor Simulator, 3-Year P&L table, and QDB tranches (`$450K`).
7. **Founder Spotlight & Doha Hiring Roadmap** — Abdelrahman Mahana's solo engineering track record + Tranche 1–3 Doha core hires.
8. **Cross-Platform App Access & Investor Inquiry Form** — TestFlight / Android APK / environment-aware Web preview & direct investor inquiry form.

## Local Preview
Run `run_landing_page.bat` from the repository root, or run:
```bash
npx serve -l tcp://127.0.0.1:8088 -l tcp://[::1]:8088 --no-port-switching -n landing_page
```
Then open `http://localhost:8088`.
