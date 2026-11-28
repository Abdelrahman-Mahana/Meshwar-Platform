# MASHWAR (مشوار): Master Startup Qatar Submission Kit & Readiness Checklist

> **Program:** Startup Qatar Investment Program (Qatar Development Bank — QDB / Invest Qatar via [f6s.com/sqinvestmentprogram](https://www.f6s.com/sqinvestmentprogram))
> **Track:** **START Track** (`$450,000` / `QAR 1,638,000` across 3 auditable milestone tranches)
> **Codebase Reference:** Verified `main` at HEAD `6520fb6` | Financial Source of Truth: [financial-data.js](file:///landing_page/js/financial-data.js)

---

## 1. Strategic Alignment with Startup Qatar (START Track)

| Dimension | MASHWAR Submission Position | Engineering & Commercial Ground Truth |
| :--- | :--- | :--- |
| **Track & Ask** | **START Track** — `$450,000` (`QAR 1.64M`) across 3 tranches (`$135K` M1 / `$157.5K` M7 / `$157.5K` M13) | Pre-revenue tested MVP (`$0` commercial revenue to date), 100% in-house built with `0` external debt or equity. |
| **Sectors** | **Marketplaces** + **Supply Chain / Logistics** + **Transportation / Mobility** | Asset-light P2P & B2B2C corridor marketplace uniting 3 core pillars across Qatar's 8 municipalities & 38 geo-hubs. |
| **3 Core Pillars** | 1) Intercity Shared Rides<br>2) Route-Based Same-Hour Parcels<br>3) On-Demand Worksite Supply & Errands | Up to 70% commuter savings, 35-90 min Dual-OTP parcel delivery, and Industrial Area -> Lusail receipt-verified supply runs with salted SHA-256 6-char handover codes. |
| **Settlement & QCB Posture** | **Direct Transparent Settlement** (MVP Launch) | Cash on delivery or verified direct bank transfer recorded in integer dirhams (`1 QAR = 100 dirhams`); **zero frozen third-party custody balances** during MVP launch. Licensed non-custodial PSP rails (QPay/Fawran/SkipCash) remain feature-flagged OFF until QCB clearance. |
| **Verified Engineering Proof** | Single Flutter codebase (150 Dart files) + 14-module RBAC Admin Portal (`/admin/`) + Cloud Functions v2 | `0` `flutter analyze` issues · **212/212** Flutter tests · **13/13** Cloud Functions tests · **10/10** live Firestore/Storage Emulator rules tests · **0** Edge CDP browser console errors. |
| **Qatar Localization** | Parent incorporation in **Doha (QFC / QSTP)** + 100% full-time founder relocation | 3 full-time Doha hires budgeted in Tranches 1-3 (Backend/Security Eng, QID Compliance Ops Lead, B2B Growth Lead) + Qatar Law No. 13 of 2016 (PDPPL) alignment. |

---

## 2. Complete Submission Package Inventory (All Files Strictly `< 30 MB`)

| # | Deliverable | Formats Included | Status & Founder Action |
| :-: | :--- | :--- | :--- |
| **1** | **Pitch Deck (14 Widescreen 16:9 Slides)** | [01_MASHWAR_Pitch_Deck_Startup_Qatar.pdf](file:///STARTUP_QATAR_SUBMISSION_DOCS/01_MASHWAR_Pitch_Deck_Startup_Qatar.pdf)<br>[01_MASHWAR_Pitch_Deck_Startup_Qatar.docx](file:///STARTUP_QATAR_SUBMISSION_DOCS/01_MASHWAR_Pitch_Deck_Startup_Qatar.docx) | **Upload-ready PDF + editable DOCX.** Visually QA'd page-by-page; embeds fresh 2x Retina captures (`app_home_hero`, `app_ride_details`, `app_parcel_otp`, `app_worksite_supply`, `app_live_map_picker`, `admin_command_live`) and 300 DPI Matplotlib charts. |
| **2** | **Founder Profile (2-Page A4 Dossier)** | [02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.pdf](file:///STARTUP_QATAR_SUBMISSION_DOCS/02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.pdf)<br>[02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx](file:///STARTUP_QATAR_SUBMISSION_DOCS/02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx) | **1 Manual Founder Edit Required:** Open `.docx`, replace the `[VERIFY]` University Degree & Certifications block in Section 05 with your exact factual details, and save/export to PDF before uploading to F6S Q23. |
| **3** | **3-Year Financials Memorandum (5-Page A4)** | [03_MASHWAR_Historical_and_Projected_Financials_3Y.pdf](file:///STARTUP_QATAR_SUBMISSION_DOCS/03_MASHWAR_Historical_and_Projected_Financials_3Y.pdf)<br>[03_MASHWAR_Historical_and_Projected_Financials_3Y.docx](file:///STARTUP_QATAR_SUBMISSION_DOCS/03_MASHWAR_Historical_and_Projected_Financials_3Y.docx) | **Upload-ready PDF + editable DOCX.** 100% reconciled with `landing_page/js/financial-data.js` (Historical `$0` disclosure, TAM/SAM/SOM, 3Y P&L, Q1-Q12 Cash Flow, Unit Economics, Tranches, -30% Stress Test). |
| **4** | **F6S Form Exact Copy-Paste Answers** | [F6S_STARTUP_QATAR_EXACT_ANSWERS.md](file:///F6S_STARTUP_QATAR_EXACT_ANSWERS.md) | **Ready for copy-paste** (confirm exact start month/year in Q6 before pasting). |
| **5** | **Bilingual Verbatim Reference Guide** | [00_READ_EVERY_WORD_VERBATIM_GUIDE_AR_EN.md](file:///STARTUP_QATAR_SUBMISSION_DOCS/00_READ_EVERY_WORD_VERBATIM_GUIDE_AR_EN.md) | Complete Arabic + English founder interview & verification guide covering every slide, table, and financial figure. |
| **6** | **Supporting Technical Due Diligence Docs** | [PRODUCTION_READINESS.md](file:///PRODUCTION_READINESS.md) · [TESTING_REPORT.md](file:///TESTING_REPORT.md) · [README.md](file:///README.md) | Keep handy for QDB technical diligence interviews (includes transparent disclosure of the 6 external production gates funded by Tranche 1). |

---

## 3. Unified Financial Summary (Interview Quick Reference — 1 USD = 3.64 QAR)

| Metric | Year 1 (M1-12) | Year 2 (M13-24) | Year 3 (M25-36) | 3-Year Cumulative | Stress Case Y3 (-30% Vol) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| **Active Corridors (End)** | 3 | 9 | 14 | 14 Corridors | 14 |
| **Completed Orders** | 13,048 | 125,134 | 330,162 | 468,344 | 231,112 |
| **B2B Accounts ($79/mo, End)** | 0 | 174 | 348 | 348 Accounts | 261 |
| **Gross Merchandise Value (GMV)** | $119,186 | $1,143,005 | $3,015,799 | $4,277,990 | $2,111,048 |
| **Net Platform Revenue** | $16,316 | $253,851 | $695,843 | $966,010 | $499,800 |
| **Gross Profit (Margin %)** | $13,724 (84.1%) | $228,992 (90.2%) | $630,254 (90.6%) | $872,970 (90.4%) | $453,888 (90.8%) |
| **Total Operating Expenses** | $150,000 | $300,000 | $386,400 | $836,400 | $303,600 |
| **Operating EBITDA** | -$136,276 | -$71,008 | +$243,854 | +$36,570 | +$150,288 |
| **QDB Tranches Received** | $292,500 | $157,500 | $0 | $450,000 | $0 (Y3) / $450K total |
| **Period-End Cash (USD / QAR)** | $156,224 / QAR 568.7K | $242,716 / QAR 883.5K | $486,570 / QAR 1.77M | $486,570 | $382,969 / QAR 1.39M |

- **Monthly EBITDA Breakeven:** **Month 21** (Base Case) | **Month 25** (Stress Case, +4 months)
- **Minimum Ending Cash (M1-M36):** **`$72,000`** in Month 6 (strictly positive across all 36 months in both Base and Stress scenarios)

---

## 4. Final Pre-Submit Checklist for Abdelrahman Mahana

- [ ] **Step 1 (Founder Profile Academic Line):** Open `STARTUP_QATAR_SUBMISSION_DOCS/02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx`, replace the `[VERIFY]` University Degree and Certifications lines with your exact factual academic credentials, and export/save as `02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.pdf`.
- [ ] **Step 2 (F6S Startup Profile):** On [f6s.com/sqinvestmentprogram](https://www.f6s.com/sqinvestmentprogram), create and attach startup profile **`MASHWAR`**, set base city to `Cairo, Egypt`, and select sectors `Marketplaces` / `Supply Chain / Logistics`.
- [ ] **Step 3 (Copy-Paste F6S Q1-Q21):** Copy verbatim answers from [F6S_STARTUP_QATAR_EXACT_ANSWERS.md](file:///F6S_STARTUP_QATAR_EXACT_ANSWERS.md), replacing `[Month Year]` in Q6 with your exact start month.
- [ ] **Step 4 (Upload 3 PDFs for Q22-Q24):** Upload `01_MASHWAR_Pitch_Deck_Startup_Qatar.pdf`, your finalized `02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.pdf`, and `03_MASHWAR_Historical_and_Projected_Financials_3Y.pdf` (each verified well under the 30 MB F6S limit).
- [ ] **Step 5 (Interview Prep):** Review [00_READ_EVERY_WORD_VERBATIM_GUIDE_AR_EN.md](file:///STARTUP_QATAR_SUBMISSION_DOCS/00_READ_EVERY_WORD_VERBATIM_GUIDE_AR_EN.md) and [PRODUCTION_READINESS.md](file:///PRODUCTION_READINESS.md) so you can speak cleanly to both verified code quality (`212/212` + `13/13` + `10/10` tests) and the 6 external production gates funded by Tranche 1.
