# MASHWAR: Exact 1-to-1 Answers for Startup Qatar Investment Program (F6S)

> **Synced Source of Truth:** Every financial figure, engineering metric, and product description below matches our 3 official upload documents in `STARTUP_QATAR_SUBMISSION_DOCS/` (`.pdf` + `.docx`), the live operating model in `landing_page/js/financial-data.js`, and HEAD commit `6520fb6`.
> **Writing Standard:** Direct engineering and product language written for QDB investment directors. Honest pre-revenue MVP disclosure (`$0` commercial revenue to date), **Direct Transparent Settlement** (zero frozen third-party custody balances during MVP launch), and strictly MASHWAR's **3 Core Pillars**.

---

## 4 Quick Pre-Submission Checks on F6S

| # | F6S Form Field | What to Verify | Exact Action |
| :-: | :--- | :--- | :--- |
| **1** | Top of form:<br>`Want to connect as a company, startup or team?` | Attach application to a startup profile | Click `Create new` and create the startup profile **`MASHWAR`** before submitting. |
| **2** | **`Where are you based? *`** | Honest current base | Enter **`Cairo, Egypt`** (your full-time Doha relocation commitment is explicitly answered in Q18, Q20, and Q21). |
| **3** | **`Skills *`** | Full-stack + AI + ops coverage | Add the exact tags listed in Section 1.3 below. |
| **4** | **Question 3 (`Sector`)** | Match real business category | Select **`Marketplaces`**, **`Supply Chain / Logistics`**, or **`Transportation / Mobility`** (not AI-only). |

---

## Section 1: Founding Team / Profile (`A bit about you`)

### 1. `Describe yourself *` *(154 characters)*
```text
Founder of MASHWAR (Qatar intercity rides, same-hour parcels & worksite supply platform) and Software/AI Engineer building Flutter, Firebase & Python systems.
```

### 2. `Where are you based? *`
```text
Cairo, Egypt
```

### 3. `Skills *`
`Flutter`, `Dart`, `Firebase`, `Cloud Firestore`, `Cloud Functions`, `TypeScript`, `System Architecture`, `RBAC Security`, `Python`, `FastAPI`, `Django`, `PyTorch`, `NLP`, `PostgreSQL`, `Redis`

### 4. `Tell us something amazing you built` *(867 characters)*
```text
I designed, engineered, and verified MASHWAR, a bilingual (Arabic RTL and English LTR) Qatar mobility and corridor logistics platform built from a single Flutter codebase (150 Dart files) serving Mobile, Consumer Web, and a standalone 14-module RBAC Operations Command Center (/admin/). MASHWAR unites three daily corridor workflows across Qatar's 8 municipalities and 38 geo-hubs: intercity shared rides, 35-90 minute route-based parcels with Dual-OTP pickup/delivery handshakes, and on-demand worksite supply for Lusail and Industrial Area contractors with live receipt checks and salted SHA-256 6-character handover codes. To stay compliant with QCB rules at launch, the MVP runs on Direct Transparent Settlement (zero frozen custody balances) backed by 2,732 lines of Firestore rules, Cloud Functions v2, 212 Flutter tests, 13 Functions tests, and 10 live Emulator rules tests passing with 0 analyzer warnings.

Earlier, I built an Arabic/English audio/video AI platform using Python, Django, FastAPI, PyTorch, and Hugging Face, plus n8n/PostgreSQL/Redis pipelines, and taught Python, SQL, and ML.
```

### 5. `Links *`
- **LinkedIn:** `https://www.linkedin.com/in/abdelrahman-mahana/`
- **GitHub:** `https://github.com/Abdelrahman-Mahana`
- **Website:** `[OPTIONAL: Add live deployed URL of the MASHWAR Landing Page / Web Staging if active at submission time]`

### 6. `Upload your CV *`
Open [02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx](file:///STARTUP_QATAR_SUBMISSION_DOCS/02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx), replace the `[VERIFY]` university degree line in Section 05 with your exact factual academic record, export to PDF, and upload the updated PDF. (A clean ready-to-review PDF is already generated at `STARTUP_QATAR_SUBMISSION_DOCS/02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.pdf`.)

---

## Section 2: Application Form Questions (`Q1 - Q26`) — Copy & Paste Verbatim

### **Question 1: Primary contact email address \***
```text
abdelrahmanmahana01@gmail.com
```

### **Question 2: How did you hear about us? \***
```text
Social Media
```
*(Or select the exact channel through which you discovered the program.)*

### **Question 3: What sector(s) and sub-sector(s) does your company operate in? \***
Select: **`Marketplaces`**, **`Supply Chain / Logistics`**, and/or **`Transportation / Mobility`**.

### **Question 4: Stage of Startup \***
```text
Pre-revenue
```

### **Question 5: Do you have a working prototype or an MVP at the moment? When was it launched? \***
```text
Yes. We have a working, verified pre-revenue MVP engineered across Mobile, Consumer Web (/), and a standalone 14-module RBAC Operations Command Center (/admin/), plus Cloud Functions v2 (TypeScript / Node 20), a 2,732-line Cloud Firestore security ruleset, strict raster-only Cloud Storage rules, an 8-municipality / 38-hub Qatar geo-catalog with our in-app live route map (mashwar_live_map.html), and a bilingual public landing page wired directly to Firestore. The staging build passed all automated verification gates in November 2026 (0 flutter analyze issues, 212/212 Flutter tests, 13/13 Cloud Functions tests, 10/10 live Emulator rules tests, and 0 browser console errors across Edge CDP QA). It is not yet commercially launched pending Doha incorporation (QFC/QSTP), MoCI/MoT/QCB clearances, Firebase Blaze production cutover, live +974 SMS OTP, and licensed map/routing APIs.
```

### **Question 6: How long have you been working on your solution? \***
```text
[CONFIRM EXACT START MONTH/YEAR]: Problem research on Qatar intercity commuting and Industrial Area-to-Lusail worksite supply friction began in [Month Year], followed by intensive full-stack engineering execution in 2026 delivering the complete Flutter Mobile/Web client, 14-module RBAC Admin portal, Cloud Functions v2 backend, cryptographic handover verification, 2,732-line Firestore ruleset, and 235 passing automated tests completed in November 2026.
```

### **Question 7: How many technical employees do you have in your team? \***
```text
1 full-time technical founder and chief architect (handling system architecture, Flutter Mobile/Web consumer and Admin portals, Cloud Functions v2, Firestore/Storage security rules, and automated QA). Under our $450,000 3-tranche budget, we plan to hire full-time Doha staff starting with a Senior Backend & Cloud Security Engineer in Month 1 (Tranche 1), followed by an Operations & QID/KYC Compliance Lead in Month 7 (Tranche 2) and a B2B Merchant Growth Lead in Month 13 (Tranche 3).
```

### **Question 8: Is your company's technology built in-house? \***
```text
Yes, 100% built in-house with zero outsourced agencies or white-label templates. Every component was written directly by the founder, including the single Flutter/Dart codebase (150 Dart files serving Mobile, Consumer Web, and the standalone 14-module RBAC Admin Command Center in lib/admin_main.dart), Cloud Functions v2 security handlers (salted SHA-256 6-character worksite handover codes verified with timingSafeEqual), 2,732 lines of Cloud Firestore security rules, strict raster-only Cloud Storage rules, our native in-app MASHWAR Live Map (mashwar_live_map.html across 8 Qatar municipalities and 38 geo-hubs), and 235 passing automated tests.
```

### **Question 9: In a few words, tell us about your company's business model.**
```text
Asset-light P2P and B2B2C marketplace uniting three corridor services in Qatar: Intercity Shared Rides (11% fee on $7.50 avg ticket), Route-Based Same-Hour Parcels (18% fee on $9.50 avg ticket), and On-Demand Worksite Supply & Errands (18% fee on $14.00 avg ticket, 0 QAR free request posting), plus Mashwar Business B2B SaaS ($79/month from Month 13). Members settle directly during MVP launch (zero frozen custody balances) with zero owned vehicles or warehouses.
```

### **Question 10: What's the size of your customer base? How do you intend to acquire customers in the new market? \***
```text
Existing Customer Base: 0 paying commercial customers today (pre-revenue tested MVP preparing Doha incorporation and pilot launch).

Bottom-Up Market Sizing (Synced 1:1 with Financial Plan Q24 & landing_page/js/financial-data.js):
- TAM ($272.50M / QAR 991.9M annual GMV): 18.0M annual inter-municipality & commuter trips ($7.50 avg) + 12.5M urgent SME parcels and worksite errands ($11.00 avg) across Qatar and GCC corridors.
- SAM ($59.95M / QAR 218.2M annual GMV): 22% digitally banked smartphone penetration across Doha industrial/suburban routes and Tier-1 GCC highway corridors.
- Target SOM (Year 3 Base): $3.02M ($3,015,799) annual GMV and $695,843 Net Platform Revenue across 14 active corridors, 330,162 annual completed orders, and 348 Mashwar Business B2B accounts (~5.0% of Tier-1 SAM), reaching monthly EBITDA breakeven in Month 21 on a $450,000 3-tranche budget.

Qatar Customer & Provider Acquisition Plan (Corridor-First Seeding):
1. Anchor 25 Repeat B2B Shippers (Months 7-9): Directly contract electrical and plumbing suppliers on Industrial Area Street 10, MEP contractors in Lusail, workshops, and clinics sending daily materials and documents so QID-vetted drivers see immediate paid orders from day one.
2. Activate Commuters & Pickups (Months 9-12): Enroll daily highway commuters and pickup owners along Doha <-> Lusail / Industrial Area and Doha <-> Al Khor using 11-digit QID verification, introductory commission rebates, and stacked multi-service earnings per trip.
3. Scale Mashwar Business & Unmet Route Alerts (Months 13-36): Convert repeat contractors and suppliers onto $79/mo Mashwar Business accounts (scaling to 348 accounts by Month 36) while routing unmet neighborhood searches directly into targeted driver onboarding across 14 corridors.
```

### **Question 11: List your direct competitors, both currently and in the future (with links). \***
```text
Current and Future Competitors by Category:

1. Urban Ride-Hailing (Full-Charter Pricing Overlap):
- Karwa / Mowasalat (Qatar public taxi & transit): https://www.mowasalat.com
- Uber: https://www.uber.com
- Careem: https://www.careem.com

2. Catalog Delivery & Hub-and-Spoke Couriers (Latency / Catalog Restriction Overlap):
- Snoonu (Qatar catalog marketplace & delivery): https://www.snoonu.com
- Talabat (Qatar food & grocery fleet): https://www.talabat.com
- Aramex (24-72h depot parcel courier): https://www.aramex.com

3. Global Intercity Carpooling Benchmark:
- BlaBlaCar (passenger carpooling; no worksite supply board or receipt verification): https://www.blablacar.com

4. Informal Market Alternative:
- Unverified WhatsApp and Facebook community groups where residents and site staff arrange intercity rides, parcel drops, and errands with zero QID vetting, no receipt verification, no GPS trail, and frequent no-shows.
```

### **Question 12: What is your Unique Selling Proposition and SWOT Analysis? \***
```text
Unique Selling Proposition (USP):
Urban taxi apps charge full-car charter fares inside central Doha, catalog apps only deliver listed menus, and couriers take 24 to 48 hours via sorting depots. MASHWAR combines three high-frequency Qatar corridor services on one verified bilingual network: Intercity Shared Rides (saving commuters up to 70%), Route-Based Same-Hour Parcels (35-90 min delivery via Dual-OTP pickup/delivery handshake), and On-Demand Worksite Supply & Errands (Lusail/Industrial Area supply runs with live receipt photo proof and salted SHA-256 6-character handover verification). Launching with Direct Transparent Settlement avoids unlicensed custody risk while our 14-module RBAC Admin Command Center enforces QID vetting and auditability.

SWOT Analysis:
- Strengths: 100% in-house Flutter Mobile/Web + 14-module Admin portal; 2,732-line Firestore ruleset; Cloud Functions v2 cryptographic handover security; 212 Flutter + 13 Functions + 10 live Emulator tests passing with 0 analyzer warnings; QCB-safe direct settlement live today.
- Weaknesses: Pre-revenue solo founder; initial corridor density requires focused route-by-route B2B seeding; Firebase Blaze production cutover, live +974 SMS OTP, licensed map/routing APIs, and Qatar legal setup await Tranche 1 funding.
- Opportunities: Daily Industrial Area-to-Lusail contractor supply downtime; high-cost intercity commutes to Al Khor, Al Wakrah, Mesaieed, and Dukhan; no unified verified corridor-plus-worksite platform in Qatar.
- Threats: Regulatory classification between cost-sharing rides and commercial logistics (mitigated via QFC/QSTP incorporation and MoCI/MoT/QCB clearances prior to public launch); off-platform cash leakage (mitigated via Mashwar Business B2B accounts, QID ratings, and verifiable handover records).
```

### **Question 13: What are some of your milestones over the past six months? \***
```text
Over the past six months, all milestones centered on end-to-end product engineering, security hardening, and Qatar localization (verified on main at commit 6520fb6):
- Three-Pillar Mobile & Web MVP: Built the bilingual Arabic (RTL) / English (LTR) Flutter application (150 Dart files) covering Intercity Shared Rides, Route-Based Same-Hour Parcels, and On-Demand Worksite Supply & Errands across Qatar's 8 municipalities and 38 geo-hubs, including our native in-app MASHWAR Live Map (mashwar_live_map.html).
- Cryptographic Handover & Direct Settlement Architecture: Engineered QCB-safe Direct Transparent Settlement (cash on delivery and verified manual bank transfer in exact integer dirhams, zero frozen custody balances), Dual-OTP parcel rules, and Cloud Functions v2 salted SHA-256 6-character worksite handover codes (timingSafeEqual, 24h TTL, 5-attempt cap, server-only secrets).
- 14-Module RBAC Admin Command Center: Built lib/admin_main.dart with 5 permission tiers for 11-digit QID vetting, worksite transfer review, live investor inquiry management from the public landing page, corridor monitoring, and schema-validated admin_audit_logs.
- Automated Verification & Security Hardening: Passed 0 flutter analyze warnings, 212/212 Flutter tests, 13/13 Cloud Functions v2 tests, 10/10 live Firestore/Storage Emulator rules tests (2,732-line firestore.rules + raster-only storage.rules blocking SVG), and 0 console/page errors in headless Edge CDP QA across Consumer, Admin, and Landing Page.
```

### **Question 14: What is your current or future revenue/monetization model? \***
```text
Asset-Light Transaction Commissions + Year-2 B2B SaaS:
- Free Request Posting (0 QAR): Residents and site engineers post ride, parcel, or worksite supply requests with zero upfront listing fee.
- Transactional Platform Fees (Configurable via Admin Console): 11.0% on Intercity Shared Rides ($7.50 avg ticket / QAR 27), 18.0% on Route-Based Same-Hour Parcels ($9.50 avg ticket / QAR 35), and 18.0% on On-Demand Worksite Supply & Errands ($14.00 avg ticket / QAR 51).
- Recurring B2B SaaS (Months 13-36): Mashwar Business monthly subscriptions ($79/mo, ~QAR 288/mo) for contracting firms, Industrial Area parts suppliers, workshops, and clinics needing multi-staff dispatch, consolidated monthly billing, and priority verified providers (scaling to 348 active accounts and $253.8K annual SaaS revenue by Year 3, 36.1% of Y3 gross revenue).
```

### **Question 15: If you are an established startup, what has been your month-over-month revenue growth in the past six months? \***
```text
N/A (Pre-revenue tested MVP). Commercial pilot launch is scheduled for Month 7 following Doha incorporation (QFC/QSTP), MoCI/MoT/QCB clearances, Firebase Blaze production provisioning, and anchor B2B shipper onboarding funded by Tranche 1.
```

### **Question 16: Have you raised any funding in the past? How much and from what sources? \***
```text
None ($0 raised to date). MASHWAR has been 100% funded and engineered directly by the founder with $0 outstanding debt or external equity. We are applying for our first institutional investment of $450,000 (QAR 1,638,000) across 3 milestone tranches ($135,000 Month 1 / $157,500 Month 7 / $157,500 Month 13) under the Startup Qatar Investment Program (START Track).
```

### **Question 17: What are your priorities for setting up in Qatar, specifically, and what do you intend to gain out of it? \***
```text
Setting up MASHWAR in Doha addresses three operational priorities directly:
1. Regulatory Clarity & IP Headquarters: Incorporating in QFC or QSTP via Startup Qatar anchors our software IP and GCC contracts in Qatar, enabling clean MoCI commercial registration, MoT transport/logistics clearance, Qatar Law No. 13 of 2016 (PDPPL) compliance, and phased QCB alignment prior to enabling licensed non-custodial PSP rails (QPay/Fawran/SkipCash).
2. High-Density Corridor Product-Market Fit: Qatar's compact geography linking Doha, Lusail, Industrial Area, Al Wakrah, Al Khor, Al Rayyan, Mesaieed, and Dukhan concentrates commuter traffic and urgent construction supply demand onto clear arteries where 35-90 minute fulfillment creates immediate daily value.
3. Ecosystem Access & Local Talent: Startup Qatar provides soft-landing incorporation support, Qatari B2B introductions to contracting and industrial clusters, and access to Doha engineering and operations talent for our 3 planned local core hires.
```

### **Question 18: Are you willing to set up operations in Qatar, and do your plans include hiring full time employees locally? \***
```text
Part 1 - Setting up operations in Qatar:
Yes. Upon approval, we will incorporate MASHWAR's parent company and engineering headquarters in Doha (QFC or QSTP), complete MoCI/MoT/QCB clearances, provision production cloud and licensed Qatar mapping/SMS infrastructure, and launch pilot corridors across Doha, Lusail, Industrial Area, and Al Khor in Months 7-12.

Part 2 - Hiring full-time employees locally in Qatar:
Yes. Our 36-month operating budget allocates $602,400 to Doha team payroll across three planned full-time local hires during Tranches 1-3: (1) a Senior Backend & Cloud Security Engineer (Month 1) to lead production cloud cutover, App Check, and security auditing; (2) an Operations & QID/KYC Compliance Lead (Month 7) to manage 24-hour QID provider vetting and corridor pilot operations; and (3) a B2B Merchant Growth Lead (Month 13) to onboard Industrial Area suppliers, Lusail contractors, and clinics onto Mashwar Business.
```

### **Question 19: How many founders do you have in your company? How long have you been working together? \***
```text
1 sole technical founder (Abdelrahman Mahana, AI & Full-Stack Software Engineer), who designed, coded, and verified the MASHWAR codebase, 14-module Admin Command Center, Cloud Functions v2 backend, 2,732-line Firestore security ruleset, and 235 automated tests independently. Upon Tranche 1 approval in Doha, we will recruit our local core team (Senior Backend/Security Engineer, QID Compliance Ops Lead, and B2B Growth Lead).
```

### **Question 20: Are any of the founder(s) or management team members planning to reside in Qatar? \***
Select: **`Yes`**

### **Question 21: If you manage to successfully secure funding, are you committed full-time or part-time during the initial 2 years? \***
```text
Yes, 100% full-time. Upon Startup Qatar START Track approval, I will relocate full-time to Doha for the initial two years and beyond to lead engineering delivery, Qatar regulatory compliance, corridor pilot operations, local hiring, and institutional follow-on fundraising.
```

---

## Section 3: Mandatory Document Uploads (`Q22 - Q26`, Each Strictly `< 30 MB`)

| Form Item | Required Upload | Ready Files (Both `.pdf` & `.docx` Provided) |
| :-: | :--- | :--- |
| **Q22** | Pitch Deck | [01_MASHWAR_Pitch_Deck_Startup_Qatar.pdf](file:///STARTUP_QATAR_SUBMISSION_DOCS/01_MASHWAR_Pitch_Deck_Startup_Qatar.pdf) (14 widescreen 16:9 slides, fresh 2x Retina app/admin captures & 300 DPI charts) + `.docx` |
| **Q23** | Founder(s) Profile | [02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx](file:///STARTUP_QATAR_SUBMISSION_DOCS/02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx) (fill `[VERIFY]` academic degree line, then re-export PDF) + ready preview `.pdf` |
| **Q24** | Historical & Projected Financials (3Y) | [03_MASHWAR_Historical_and_Projected_Financials_3Y.pdf](file:///STARTUP_QATAR_SUBMISSION_DOCS/03_MASHWAR_Historical_and_Projected_Financials_3Y.pdf) (5-page financial memorandum, Base + -30% Stress, 100% synced with `financial-data.js`) + `.docx` |
| **Q25** | Accuracy Declaration | Check after confirming city (`Cairo, Egypt`), Q6 exact start date, and Q23 academic degree line |
| **Q26** | 30-Day Submission Commitment | Check upon final F6S submission |
