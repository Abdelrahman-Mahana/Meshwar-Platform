# MASHWAR: الإجابات المطابقة 1-لـ-1 لاستمارة Startup Qatar على F6S

> هذا الملف محدّث بالكامل على آخر نسخة من التطبيق (**Qatar Community Services & On-the-Way Fulfillment Super-App**) بنظام الخدمات المجتمعية الست، ونظام الضمان المالي المزدوج (**Bilateral Escrow**)، وواجهة الهوية القطرية العنابية، ومتطابق حرفياً مع العرض التقديمي وملف المؤسس والخطة المالية لـ 3 سنوات (`STARTUP_QATAR_SUBMISSION_DOCS`).
> جميع النصوص الإنجليزية خضعت لفحص **Humanizer** صارم: بدون شرطة طويلة (`em-dash`) وبدون ألفاظ تسويقية آلية مكررة.

---

## ⚠️ 4 تصحيحات مهمة في نموذج F6S قبل الإرسال النهائي

| # | الحقل الحالي | ما يجب التأكد منه | التعديل المطلوب |
| :-: | :--- | :--- | :--- |
| **1** | أعلى الصفحة:<br>`Want to connect as a company, startup or team?` | ربط التقديم بملف شركة ناشئة | اضغط `Create new` وأنشئ ملف Startup باسم **`MASHWAR`** قبل الإرسال. |
| **2** | **`Where are you based? *`** | مطابقة مكان إقامتك الحالي بصدق | اختر مدينتك الحالية الفعلية (مثل `Cairo, Egypt`)، لأن الالتزام بالانتقال للدوحة يظهر في Q20 وQ21. |
| **3** | **`Skills *`** | إضافة مهارات البنية الكاملة | أضف المهارات التقنية المحددة أدناه (Flutter/Firebase/Python/AI/Operations). |
| **4** | **Question 3 (`Sector`)** | مطابقة قطاع المشروع الحقيقي | اختر **`Marketplaces`** أو **`Supply Chain / Logistics`** أو **`Transportation / Mobility`** (وليس AI فقط). |

---

## القسم الأول: بيانات الملف الشخصي (`A bit about you`)

### 1. `Describe yourself *` *(156 حرفاً)*
```text
Founder of MASHWAR (Qatar community services & on-the-way fulfillment app) and Software/AI Engineer building Flutter, Firebase, Python, FastAPI, and NLP systems.
```

### 2. `Where are you based? *`
`Cairo, Egypt` *(أو مدينتك الحالية الفعلية قبل الانتقال إلى الدوحة)*

### 3. `Skills *`
`Flutter`, `Dart`, `Firebase`, `Cloud Firestore`, `System Architecture`, `Google Maps Platform`, `Escrow Workflows`, `Python`, `FastAPI`, `Machine Learning`, `NLP`, `PostgreSQL`

### 4. `Tell us something amazing you built` *(835 حرفاً)*
```text
I designed and built MASHWAR, a bilingual (Arabic RTL and English LTR) community services and on-the-way fulfillment platform for Qatar across Android, iOS, and Web, plus a separate Role-Based Admin Web Console. Beyond ride-sharing, the app handles six daily needs on one corridor network: buy-and-deliver errands with live store receipt approval, engineer worksite supplies, on-route document runs, nursery and daily commutes, shared empty seats, and commercial cargo. To prevent fraud on both sides, I built ServiceEscrowScreen with Bilateral Escrow holds via Fawran, QPay, and Wallet, 4-digit OTP release, a 1,098-line Firestore ruleset, and 78 passing tests (0 analyzer issues).

Earlier, I built an Arabic/English audio/video AI platform using Python, Django, FastAPI, PyTorch, and Hugging Face, plus n8n/PostgreSQL pipelines, and taught Python, SQL, and ML.
```

### 5. `Links *`
* **LinkedIn:** `https://www.linkedin.com/in/abdelrahman-mahana/`
* **GitHub:** `https://github.com/Abdelrahman-Mahana`
* **Website:** `[OPTIONAL: ضع رابط نسخة الويب المباشرة على Vercel أو Firebase Hosting]`

### 6. `Upload your CV *`
صدّر ملف `[02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx](file:///d:/My_Projects/Meshwar-v1/Meshwar/STARTUP_QATAR_SUBMISSION_DOCS/02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx)` إلى **PDF** بعد استكمال سطر الشهادة الجامعية `[VERIFY]`.

---

## القسم الثاني: الأسئلة المرقمة 1 إلى 26 (`Questions`) للنسخ واللصق

### **Question 1: Primary contact email address \***
```text
abdelrahmanmahana01@gmail.com
```

### **Question 2: How did you hear about us? \***
`Social Media` *(أو المصدر الفعلي الذي عرفت منه البرنامج)*

### **Question 3: What sector(s) and sub-sector(s) does your company operate in? \***
اختر: **`Marketplaces`** أو **`Supply Chain / Logistics`** أو **`Transportation / Mobility`**

### **Question 4: Stage of Startup \***
`Pre-revenue`

### **Question 5: Do you have a working prototype or an MVP at the moment? When was it launched? \***
```text
Yes. We have a working, tested MVP built across Android, iOS, and Flutter Web alongside a standalone Admin Web Control Panel, 7 domain repository contracts, a 1,098-line Firestore security ruleset, an 8-municipality / 22-hub Qatar Geo-Catalog, and Bilateral MASHWAR Escrow workflows. The staging build was completed and verified (78/78 passing tests, 0 analyzer issues) in November 2026. It is not yet commercially launched pending QFC/QSTP setup, live SMS OTP gateways, and Fawran/QPay merchant credentials.
```

### **Question 6: How long have you been working on your solution? \***
```text
[CONFIRM DURATION, e.g., ~X months total]: problem discovery around corridor inefficiencies and community errand trust gaps began in [Month Year], followed by intensive full-stack engineering execution (Flutter UI, Bilateral Escrow workflow, Qatar localization, Firebase rules, Admin Web console, and 78 automated tests) completed in November 2026.
```

### **Question 7: How many technical employees do you have in your team? \***
```text
1 full-time technical founder / software engineer (handling architecture, Flutter mobile/web client, Firebase security rules, and test automation). We plan to hire 2 additional full-time engineers in Doha (Senior Backend/Cloud Security Engineer and Matching/Data Engineer) using Tranche 1-2 capital.
```

### **Question 8: Is your company's technology built in-house? \***
```text
Yes, 100% built in-house. Every component was written directly without agencies or white-label templates, including the cross-platform Flutter app (56 modular screen files with Arabic RTL and English LTR layouts), the Bilateral Escrow workflow (ServiceEscrowScreen), the standalone Admin Web Control Panel (lib/admin_main.dart), 7 domain repository contracts, a 1,098-line Firestore security ruleset, integer minor-unit wallet ledger logic, a 22-hub Qatar Geo-Catalog fallback, and 78 passing automated tests.
```

### **Question 9: In a few words, tell us about your company's business model. \***
```text
B2B2C and P2P Asset-Light Marketplace. Posting any service request is free (0 QAR). When an offer is accepted, MASHWAR takes a category commission (11% on shared rides and daily commutes; 18% on store receipt errands, site supplies, document runs, and cargo) and locks funds in Bilateral Escrow until 4-digit OTP handover, adding Mashwar Business monthly SaaS plans ($79/mo) in Year 2 with zero owned vehicles or warehouses.
```

### **Question 10: What's the size of your customer base? How do you intend to acquire customers in the new market? \***
```text
Existing Customer Base: 0 paying commercial customers (pre-revenue tested MVP preparing Doha launch).

Bottom-Up Market Sizing (Synced 1:1 with Financial Plan Q24):
- TAM ($272.5M / QAR 991.9M annual GMV): 18.0M annual inter-municipality & commuter trips ($7.50 avg) + 12.5M urgent SME errands, site parts, and parcels ($11.00 avg) across Qatar and GCC corridors.
- SAM ($59.95M / QAR 218.2M annual GMV): 22% digitally banked smartphone penetration across Doha industrial/suburban routes and Tier-1 GCC highway corridors.
- Target SOM (Year 3): $3.02M annual GMV ($695.8K Net Revenue across 14 active corridors, 330,162 annual orders, and 348 B2B Mashwar Business accounts; monthly EBITDA breakeven in Month 21 on a $450,000 3-tranche budget).

Qatar Customer & Provider Acquisition Plan (Corridor-by-Corridor):
1. B2B & Worksite Load Anchoring: Directly sign 25 repeat shippers in Doha and the Industrial Area (electrical/spare-parts stores, contracting offices, clinics, pharmacies) sending daily items to Lusail, Al Wakrah, Al Khor, and Mesaieed so providers see paid tasks waiting on day one.
2. Commuter & Pickup Activation: Recruit daily commuters and pickup drivers along Doha <-> Lusail / Industrial Area / Al Khor using 10-12% intro commissions, Fawran payouts, and free task posting for residents.
3. Unmet Route Alerts: Convert resident searches for underserved daily/nursery commutes or store errands into direct onboarding leads for nearby drivers.
```

### **Question 11: List your direct competitors, both currently and in the future (with links). \***
```text
Current and Future Competitors:

1. Urban Ride-Hailing (Full-Charter Pricing Overlap):
- Karwa / Mowasalat (Qatar public taxi and transit): https://www.mowasalat.com
- Uber: https://www.uber.com
- Careem: https://www.careem.com

2. On-Demand Delivery & Couriers (Store Catalog / Depot Latency Overlap):
- Snoonu (Qatar catalog marketplace and courier): https://www.snoonu.com
- Talabat (Qatar food and grocery delivery fleet): https://www.talabat.com
- Aramex (24-72h hub-and-spoke parcel courier): https://www.aramex.com

3. Corridor Mobility Benchmarks:
- BlaBlaCar (global passenger carpooling; no store-receipt escrow or construction supply board): https://www.blablacar.com

4. Informal Competition:
- Unverified WhatsApp and Facebook community groups where people arrange rides, nursery runs, and store favors with no QID vetting, phone privacy, receipt verification, or Escrow protection.
```

### **Question 12: What is your Unique Selling Proposition and SWOT Analysis? \***
```text
Unique Selling Proposition (USP):
Taxis charge dedicated charter fares inside Doha, food apps only deliver listed catalog menus, and couriers take 24 to 48 hours via sorting depots. MASHWAR combines six everyday community services on one verified Qatar network (store buy-and-deliver with receipt, engineer site supply, document runs, nursery/daily commutes, shared highway seats, and commercial cargo) backed by Bilateral Escrow. Requesters post for free (0 QAR). When accepted, both the service fee and store receipt cap sit in Escrow until the provider uploads live photo proof and the requester gives the 4-digit OTP at handover.

Brief SWOT Analysis:
- Strengths: Complete multi-platform MVP (Flutter Mobile/Web + Admin RBAC Console) built 100% in-house; Bilateral Escrow + live receipt approval + 4-digit OTP built in code; multi-task drivers earn more per trip; 78/78 automated tests passing with 0 analyzer issues.
- Weaknesses: Pre-revenue solo founder; corridor liquidity needs careful route-by-route seeding; live SMS OTP and Fawran/QPay keys require Tranche 1 funding.
- Opportunities: Frequent daily delays moving small tools/parts from Industrial Area to Lusail and outer sites; underserved nursery and family commutes; zero trusted community errand Escrow app in Qatar.
- Threats: Regulatory classification between personal favors/cost-sharing and commercial logistics (handled via QFC/QSTP legal counsel and price caps); off-platform cash leakage (blocked by prepaid provider wallet thresholds and Escrow protection).
```

### **Question 13: What are some of your milestones over the past six months? \***
```text
Over the past six months, all milestones focused on architecture, full-stack engineering, and trust verification:
- Six-Service Architecture & Qatar Localization: Expanded the platform into six equal-weight community services mapped across Qatar's 8 municipalities and 22 local hubs with an animated Qatar route map and bilingual Arabic RTL / English LTR UI (56 modular screen files).
- Bilateral MASHWAR Escrow Engine: Engineered ServiceEscrowScreen supporting 0 QAR free posting, fee + purchase-cap locks (Fawran, QPay/Himyan, SkipCash, Mashwar Wallet), in-store receipt and item photo approval, 4-digit OTP payout release, and 1-tap neutral dispute freezing.
- Governance Console & Zero-Trust Rules: Built a standalone Admin Web Control Panel (lib/admin_main.dart) for 11-digit QID verification, dispute arbitration, and audit trails alongside a 1,098-line Firestore security ruleset and integer minor-unit wallet ledgering.
- Automated Verification & Investor Package: Passed 78/78 automated unit, layout, escrow, and RBAC tests with 0 static analysis issues (flutter analyze), prepared technical documentation (docs/backend/), and compiled a 116-file Visual Media Kit.
```

### **Question 14: What is your current or future revenue/monetization model? \***
```text
Primary Model: Zero-Upfront Posting + Transactional Commission on Accepted Escrow Orders + Year-2 B2B SaaS.
- Posting Requests is Free (0 QAR): Any resident or engineer posts a request with zero upfront platform charge.
- Day-1 Transactional Commissions: Configurable take rates per service line (11% target on shared corridor seats and daily commutes; 18% target on store buy-and-deliver errands, engineer site supplies, document runs, and commercial cargo). Prepaid provider ledger thresholds block off-platform cash skipping.
- Year 2+ Recurring Expansion (Months 13+): Mashwar Business monthly subscriptions ($79/mo) for contracting firms, spare-parts dealers, clinics, and nurseries needing multi-staff dispatch, GST/VAT-ready invoicing, and priority Escrow coverage.
```

### **Question 15: If you are an established startup, what has been your month-over-month revenue growth in the past six months? \***
```text
N/A (Pre-revenue MVP). Completing legal incorporation in Doha, production cloud provisioning, and payment gateway onboarding prior to commercial pilot launch.
```

### **Question 16: Have you raised any funding in the past? How much and from what sources? \***
```text
None ($0 raised to date). MASHWAR has been 100% funded and built by the founder. We are applying for our first institutional investment ($450,000 across 3 milestone tranches) under the Startup Qatar START Track.
```

### **Question 17: What are your priorities for setting up in Qatar, specifically, and what do you intend to gain out of it? \***
```text
Establishing MASHWAR in Doha solves three operational needs directly:
1. Legal & Financial Rails for Escrow: Incorporating under QFC or QSTP provides clear IP governance and direct integration with QCB Fawran, QPay/Himyan, and SkipCash, making cashless Bilateral Escrow reliable from day one.
2. High-Need Corridor Geography: Qatar's active corridors linking Doha, Lusail, Industrial Area, Al Wakrah, Al Khor, Mesaieed, and Dukhan experience daily bottlenecks in urgent worksite supplies, paperwork runs, and underserved family commutes where MASHWAR delivers clear 2-hour to 4-hour value.
3. Ecosystem Soft-Landing & Talent: Startup Qatar provides regulatory clarity, incorporation waivers, Qatari B2B introductions, and access to local engineering and compliance talent as we anchor GCC expansion from Doha.
```

### **Question 18: Are you willing to set up operations in Qatar, and do your plans include hiring full time employees locally? \***
*(منقسم لجزئين بوضوح حسب طلب النموذج)*
```text
Part 1 - Setting up operations in Qatar:
Yes. Upon acceptance, we will incorporate MASHWAR's parent company and engineering headquarters in Doha (QFC or QSTP), complete Qatari corporate banking and Fawran/QPay Escrow integration, and operate our pilot corridors across Doha, Lusail, Industrial Area, and Al Khor during Months 1 to 12.

Part 2 - Hiring full-time employees locally in Qatar:
Yes. Our 18-month budget allocates Tranche 1 and Tranche 2 capital to hiring full-time Doha staff: (1) a Senior Backend & Cloud Security Engineer to co-locate core Escrow/API infrastructure in Qatar, (2) an Operations & QID/KYC Compliance Lead to manage 24-hour provider vetting and dispute arbitration, and (3) a B2B Growth Lead serving Industrial Area suppliers, contractors, clinics, and schools.
```

### **Question 19: How many founders do you have in your company? How long have you been working together? \***
```text
1 sole technical founder (Abdelrahman Mahana, AI & Software Engineer), having designed and built the MASHWAR codebase, Bilateral Escrow engine, Admin Control Panel, and 78 automated tests independently. During Tranche 1 setup in Doha, we will recruit a Qatar-based Operations & QID Compliance Lead and Senior Backend Engineer.
```

### **Question 20: Are any of the founder(s) or management team members planning to reside in Qatar? \***
اختر: **`Yes`**

### **Question 21: If you manage to successfully secure funding, are you committed full-time or part-time during the initial 2 years? \***
```text
Yes. I am committed 100% full-time to MASHWAR for the next two years and beyond. Upon Tranche 1 approval, I will relocate to Doha full-time to lead engineering delivery, Qatar pilot operations, local hiring, and institutional follow-on fundraising.
```

---

## القسم الثالث: المرفقات الرسمية (`Q22 - Q26`)

| السؤال | الملف المطلوب (`< 30 MB`) | الملف المحدّث والجاهز للتحويل إلى PDF |
| :-: | :--- | :--- |
| **Q22** | Pitch Deck | [01_MASHWAR_Pitch_Deck_Startup_Qatar.docx](file:///d:/My_Projects/Meshwar-v1/Meshwar/STARTUP_QATAR_SUBMISSION_DOCS/01_MASHWAR_Pitch_Deck_Startup_Qatar.docx) (12 شريحة 16:9 بالصور الجديدة والـ Escrow) |
| **Q23** | Founder(s) Profile | [02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx](file:///d:/My_Projects/Meshwar-v1/Meshwar/STARTUP_QATAR_SUBMISSION_DOCS/02_MASHWAR_Founder_Profile_Abdelrahman_Mahana.docx) (أكمل سطر `[VERIFY]` للشهادة الجامعية ثم صدّره PDF) |
| **Q24** | Historical & Projected Financials | [03_MASHWAR_Historical_and_Projected_Financials_3Y.docx](file:///d:/My_Projects/Meshwar-v1/Meshwar/STARTUP_QATAR_SUBMISSION_DOCS/03_MASHWAR_Historical_and_Projected_Financials_3Y.docx) (متطابق 100% مع Q10 وQ16 والدفعات الـ 3) |
| **Q25** | إقرار صحة البيانات | مفعّل بعد مراجعة حقل المدينة والـ `[VERIFY]` |
| **Q26** | الالتزام بالإرسال خلال 30 يوماً | مفعّل عند الإرسال النهائي |
