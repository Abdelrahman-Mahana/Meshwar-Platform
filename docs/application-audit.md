# Application Audit — MASHWAR | تدقيق التطبيق — مشوار

| | English | العربية |
|---|---|---|
| **Document** | Application audit (checkpoint 1 of 3) | تدقيق التطبيق (المرحلة 1 من 3) |
| **Audited commit** | `467430e` on `main` | الإصدار `467430e` على الفرع `main` |
| **Audit date** | 17 November 2026 | 17 نوفمبر 2026 |
| **Scope** | Passenger/driver mobile app and admin panel | تطبيق الراكب والسائق ولوحة الإدارة |
| **Method** | Static review of the source code. The app was **not run** (see §12). | مراجعة ساكنة للكود المصدري. **لم يتم تشغيل التطبيق** (انظر §12). |

All `file:line` references point to the audited commit. Line numbers will shift once the code changes.

جميع الإحالات بصيغة `ملف:سطر` تخص الإصدار المُدقَّق، وستتغير أرقام الأسطر بعد تعديل الكود.

---

## Contents | المحتويات

1. Executive summary | الملخص التنفيذي
2. Confirmed decisions and assumptions | القرارات المؤكدة والافتراضات
3. Project profile | ملف المشروع
4. Screen inventory | جرد الشاشات
5. User journeys as built | رحلات المستخدم كما هي مبنية
6. Findings | الملاحظات
7. State coverage matrix | مصفوفة تغطية الحالات
8. Backend-integration blockers | عوائق الربط مع الخادم
9. Branding pack and design references | حزمة الهوية والمراجع التصميمية
10. Proposed packages | الحزم المقترحة
11. Recommended fix order | ترتيب المعالجة المقترح
12. Verification status and limits | حالة التحقق وحدوده

---

## 1. Executive summary | الملخص التنفيذي

**English**

MASHWAR is a Flutter app (about 32,800 lines of Dart in 84 files) for inter-city carpooling, parcel crowd-shipping and a community request board in Egypt, plus an admin panel in the same codebase. The visual design is consistent and close to the branding pack: the three brand colours and the logo geometry in code match the pack exactly.

The app is a clickable prototype, not yet a product. Every screen reads in-memory mock data, nothing is sent over the network, and several flows are driven by on-screen simulation controls instead of real events. Seventy-seven screens, sheets and dialogs exist; eight of them cannot be reached by a user.

This audit records **60 findings: 10 Critical, 20 High, 18 Medium, 12 Low.** The Critical ones fall into four groups:

- **Nothing is real behind the UI.** No data layer, simulated sign-in, search that does not filter, verification that only toggles a flag (C-01, C-02, C-07, C-08).
- **Actions that report success without doing anything.** Emergency calls, wallet top-ups and parcel handover all show a success message with no effect (C-03, C-05, C-10).
- **Demo data leaks into real accounts.** A newly created user starts with a 450 EGP balance, a 4.9 rating and a fixed national ID (C-04).
- **Release and security gaps.** The Android release build has no internet permission, and the admin panel is protected only in the UI (C-06, C-09).

None of this requires a rebuild. The screens, components and visual language can be kept; the work is to put a real data layer and real device actions underneath them.

**العربية**

«مشوار» تطبيق مبني بـ Flutter (نحو 32,800 سطر بلغة Dart في 84 ملفًا) للسفر التشاركي بين المحافظات ونقل الطرود عبر المسافرين ولوحة طلبات مجتمعية في مصر، ومعه لوحة إدارة ضمن نفس الكود. التصميم البصري متسق وقريب من حزمة الهوية: ألوان العلامة الثلاثة وشكل الشعار في الكود مطابقة للحزمة تمامًا.

التطبيق حاليًا نموذج تفاعلي وليس منتجًا جاهزًا. كل الشاشات تقرأ بيانات تجريبية من الذاكرة، ولا يُرسَل أي شيء عبر الشبكة، وعدة مسارات تُدار بأزرار محاكاة ظاهرة على الشاشة بدل أحداث حقيقية. يوجد 77 شاشة ونافذة سفلية وحوار، ثمانٍ منها لا يستطيع المستخدم الوصول إليها.

يوثّق هذا التدقيق **60 ملاحظة: 10 حرجة، 20 عالية، 18 متوسطة، 12 منخفضة.** وتنقسم الملاحظات الحرجة إلى أربع مجموعات:

- **لا شيء حقيقي خلف الواجهة.** لا توجد طبقة بيانات، والدخول مُحاكى، والبحث لا يُرشِّح النتائج، والتوثيق مجرد تبديل قيمة (C-01، C-02، C-07، C-08).
- **إجراءات تُظهر نجاحًا دون تنفيذ.** اتصالات الطوارئ وشحن المحفظة وتسليم الطرد كلها تعرض رسالة نجاح بلا أثر فعلي (C-03، C-05، C-10).
- **تسرّب بيانات تجريبية إلى الحسابات الحقيقية.** المستخدم الجديد يبدأ برصيد 450 جنيهًا وتقييم 4.9 ورقم قومي ثابت (C-04).
- **ثغرات في الإصدار والأمان.** نسخة الإصدار على Android بلا صلاحية إنترنت، ولوحة الإدارة محمية في الواجهة فقط (C-06، C-09).

لا يستلزم أيٌّ من ذلك إعادة البناء. يمكن الإبقاء على الشاشات والمكوّنات واللغة البصرية، والعمل المطلوب هو وضع طبقة بيانات حقيقية وإجراءات فعلية على الجهاز تحتها.

---

## 2. Confirmed decisions and assumptions | القرارات المؤكدة والافتراضات

These come from the product owner's answers on 17 November 2026. Later documents (backend requirements, database, API) will build on them.

هذه القرارات مأخوذة من إجابات مالك المنتج بتاريخ 17 نوفمبر 2026، وستُبنى عليها الوثائق اللاحقة (متطلبات الخادم، قاعدة البيانات، الواجهات البرمجية).

### 2.1 Decisions | القرارات

| ID | Topic · الموضوع | Decision (EN) | القرار (AR) |
|---|---|---|---|
| D-01 | Delivery · التسليم | Work is delivered on a feature branch. | يُسلَّم العمل على فرع مستقل. |
| D-02 | Verification · التحقق | `flutter analyze` and `flutter test` are run through Claude Code on a machine that has Flutter. | يُشغَّل الفحص والاختبارات عبر Claude Code على جهاز مثبَّت عليه Flutter. |
| D-03 | Phasing · المراحل | Three checkpoints: audit, frontend, backend docs with sprint plan. | ثلاث مراحل: التدقيق، ثم الواجهة، ثم وثائق الخادم مع خطة السبرنتات. |
| D-04 | Scope · النطاق | The admin panel is in scope. Product targets are Android and iOS, not web. | لوحة الإدارة ضمن النطاق. المنصات المستهدفة Android و iOS وليس الويب. |
| D-05 | Packages · الحزم | Add the packages the app needs, stability first, including offline detection and skeleton loading. | تُضاف الحزم اللازمة مع أولوية الاستقرار، وتشمل اكتشاف انقطاع الاتصال وهياكل التحميل. |
| D-06 | Design · التصميم | Upgrade the existing design using the branding pack and reference boards. Do not discard the current design. | تطوير التصميم الحالي بالاستعانة بحزمة الهوية واللوحات المرجعية دون إلغاء التصميم القائم. |
| D-07 | Backend · الخادم | The stack is to be recommended from the app's needs. Managed platforms such as Firebase or Supabase are acceptable. | تُقترح التقنية بناءً على احتياج التطبيق، والمنصات المُدارة مثل Firebase أو Supabase مقبولة. |
| D-08 | Commission · العمولة | Dynamic per service category. The percentage is assigned by the admin. | متغيّرة حسب فئة الخدمة، والنسبة تحددها الإدارة. |
| D-09 | Payment · الدفع | Cash, and digital transfer with proof of payment (receipt image). A local payment gateway may be integrated. | نقدًا، أو تحويل رقمي مع إثبات الدفع (صورة الإيصال). ويمكن ربط بوابة دفع محلية. |
| D-10 | Cancellation · الإلغاء | Policy depends on the service type. Some services allow free cancellation at any time; others deduct part of the fee. | السياسة حسب نوع الخدمة: بعضها يسمح بالإلغاء المجاني في أي وقت، وبعضها يخصم جزءًا من الرسوم. |
| D-11 | Codes · الأكواد | Codes are alphanumeric (letters and digits). | الأكواد تتكون من حروف وأرقام. |
| D-12 | Ladies-only · خدمة السيدات | A sensitive service in which women serve women. | خدمة حساسة تقدمها السيدات للسيدات. |
| D-13 | Sign-in · الدخول | Email-based: Google Sign-In and a code sent by email. | عبر البريد: الدخول بحساب Google ورمز يُرسَل بالبريد الإلكتروني. |
| D-14 | Team · الفريق | Three developers, open-ended sprints, delivery as soon as possible. | ثلاثة مطورين، سبرنتات مفتوحة، والتسليم في أقرب وقت. |
| D-15 | Language · اللغة | Documents are bilingual, Arabic and English side by side. | الوثائق ثنائية اللغة، عربي وإنجليزي جنبًا إلى جنب. |

### 2.2 Assumptions that need your confirmation | افتراضات تحتاج تأكيدك

| ID | Assumption (EN) | الافتراض (AR) |
|---|---|---|
| A-01 | The admin panel stays an internal web build for staff. "Not web" in D-04 applies to the customer app. Today the admin panel only runs as a web target (`run_admin_web.bat`). | تبقى لوحة الإدارة نسخة ويب داخلية للموظفين، وعبارة «ليس الويب» في D-04 تخص تطبيق العملاء. اللوحة حاليًا لا تعمل إلا كهدف ويب. |
| A-02 | D-11 covers two things: parcel handover codes become alphanumeric, and vehicle plate fields accept Egyptian plates (Arabic letters with digits) and other formats. | القرار D-11 يشمل أمرين: أكواد تسليم الطرود تصبح حروفًا وأرقامًا، وحقول لوحة المركبة تقبل اللوحات المصرية (حروف عربية وأرقام) وغيرها. |
| A-03 | For D-12, a ladies-only ride requires a verified female driver and accepts only female passengers. Gender is confirmed from the national ID during verification, not from the self-declared profile field. | في D-12 تتطلب رحلة السيدات سائقة موثَّقة وتقبل راكبات فقط. يُؤكَّد النوع من الرقم القومي أثناء التوثيق لا من الحقل المُدخَل ذاتيًا. |
| A-04 | For D-13, no SMS provider is used in the first release. The phone number is still collected in the profile because calls and parcel receivers need it, but phone-OTP sign-in is switched off until an SMS provider is chosen. | في D-13 لا يُستخدم مزوّد رسائل نصية في الإصدار الأول. يبقى رقم الهاتف مطلوبًا في الملف الشخصي لأن الاتصال ومستلمي الطرود يحتاجونه، ويُوقَف الدخول برمز الهاتف إلى حين اختيار مزوّد. |
| A-05 | Code changes are made with Claude Code using these documents as context. Checkpoint 2 therefore delivers an implementation specification that Claude Code executes, not hand-written code from this audit workspace. | تُنفَّذ تعديلات الكود عبر Claude Code اعتمادًا على هذه الوثائق. لذلك تُسلِّم المرحلة 2 مواصفة تنفيذ ينفّذها Claude Code، لا كودًا مكتوبًا من بيئة التدقيق. |
| A-06 | The tip option on the rating screen (0, 10, 20, 50 EGP) is kept as a planned feature and specified in the backend documents. | يُحتفظ بخيار الإكرامية في شاشة التقييم (0، 10، 20، 50 جنيهًا) كميزة مخططة وتُوثَّق في مستندات الخادم. |

---

## 3. Project profile | ملف المشروع

| Item · البند | Value · القيمة |
|---|---|
| Framework · الإطار | Flutter, Dart SDK `>=3.0.0 <4.0.0`, Material 3 |
| Package name · اسم الحزمة | `mashwar`, version `1.0.0+1` |
| State management · إدارة الحالة | `provider` with seven `ChangeNotifier` classes · سبعة مزوّدات حالة |
| Runtime dependencies · الاعتماديات | `provider`, `shared_preferences`, `google_fonts`, `intl` (declared, never imported · معلنة وغير مستخدمة) |
| Entry points · نقاط الدخول | `lib/main.dart` (customer app · تطبيق العملاء), `lib/admin_main.dart` (admin panel · لوحة الإدارة) |
| Size · الحجم | 84 Dart files, about 32,800 lines · 84 ملفًا ونحو 32,800 سطر |
| Navigation · التنقل | 117 inline `MaterialPageRoute` pushes, no route table · 117 انتقالًا مباشرًا بلا جدول مسارات |
| Persistence · التخزين | Language and notification preferences only · اللغة وتفضيلات الإشعارات فقط |
| Tests · الاختبارات | 12 files, 60 tests · 12 ملفًا و60 اختبارًا |
| Platform folders · مجلدات المنصات | `android`, `ios`, `web`, `windows` |
| Languages · اللغات | Arabic (default, RTL) and English · العربية (الافتراضية) والإنجليزية |

**Folder layout | هيكل المجلدات**

```
lib/
├── core/          constants, theme, localization, 6 shared widgets
├── data/          6 models, mock_data.dart, api/ (endpoints + client stub)
├── state/         7 providers
├── screens/       19 feature folders, 55 files
├── main.dart      customer app
└── admin_main.dart admin panel
```

**What already works in favour of the next phases | ما يخدم المراحل القادمة**

- **EN:** Design tokens exist (`AppColors`, `AppDimens`, `AppTypography`). Six shared widgets are in use. Every model has `fromJson`, `toJson` and `copyWith`. Many screens have a wide layout (most switch at 840 px). An endpoint list of about 50 paths already sketches the API surface.
- **AR:** توجد رموز تصميم جاهزة (`AppColors` و`AppDimens` و`AppTypography`). ستة مكوّنات مشتركة مستخدمة فعلًا. كل نموذج بيانات يحوي `fromJson` و`toJson` و`copyWith`. شاشات كثيرة لها تخطيط عريض (معظمها يتحول عند 840 بكسل). وقائمة تضم نحو 50 مسارًا ترسم مبدئيًا شكل الواجهة البرمجية.

---

## 4. Screen inventory | جرد الشاشات

**Legend | مفتاح الحالة**

| Code | Meaning (EN) | المعنى (AR) |
|---|---|---|
| **M** | Works on mock data held in memory | تعمل على بيانات تجريبية في الذاكرة |
| **S** | Contains simulation controls or hardcoded content inside the screen | تحتوي أزرار محاكاة أو محتوى ثابتًا داخل الشاشة |
| **U** | Unreachable by a user | لا يمكن للمستخدم الوصول إليها |

### 4.1 Sign-in and onboarding | الدخول والتهيئة

| # | Screen · الشاشة | File | Reached from · الوصول من | State |
|---|---|---|---|---|
| 1 | `SplashScreen` · شاشة البداية | `screens/splash_screen.dart` | App start · بدء التطبيق | M |
| 2 | `WelcomeScreen` · الترحيب | `screens/auth/welcome_screen.dart` | Splash, logout · البداية، تسجيل الخروج | S |
| 3 | `PhoneInputScreen` · إدخال الهاتف | `screens/auth/phone_input_screen.dart` | Welcome, Email | M |
| 4 | `EmailInputScreen` · إدخال البريد | `screens/auth/email_input_screen.dart` | Welcome, Phone | M |
| 5 | `OtpVerificationScreen` · رمز التحقق | `screens/auth/otp_verification_screen.dart` | Phone, Email | M |
| 6 | `ProfileSetupScreen` · إنشاء الملف | `screens/auth/profile_setup_screen.dart` | OTP, Google sheet | M |
| 7 | `IdVerificationScreen` · توثيق الهوية | `screens/auth/id_verification_screen.dart` | Account, Profile, Settings | S |
| 8 | `LocationPermissionScreen` · إذن الموقع | `screens/permissions/location_permission_screen.dart` | ID verification in onboarding mode only | **U** |
| 9 | `NotificationPermissionScreen` · إذن الإشعارات | `screens/permissions/notification_permission_screen.dart` | Location permission only | **U** |

### 4.2 Main shell, search and booking | الهيكل الرئيسي والبحث والحجز

| # | Screen · الشاشة | File | Reached from · الوصول من | State |
|---|---|---|---|---|
| 10 | `MainNavShell` · الهيكل الرئيسي (5 tabs: Home, Board, My Rides, My Parcels, Account) | `screens/main_nav_shell.dart` | Profile setup | S |
| 11 | `HomeScreen` · الرئيسية | `screens/home/home_screen.dart` | Tab 1 | M |
| 12 | `CitySearchModal` · اختيار المدينة | `screens/home/city_search_modal.dart` | Home, Post ad, Publish ride | M |
| 13 | `DateTimePickerSheet` · اختيار الموعد | `screens/home/date_time_picker_sheet.dart` | Home, Publish ride | S |
| 14 | `SearchResultsScreen` · نتائج البحث | `screens/search/search_results_screen.dart` | Home | M |
| 15 | `SearchFiltersSheet` · فلاتر البحث | `screens/search/search_filters_sheet.dart` | Search results | M |
| 16 | `RideDetailsScreen` · تفاصيل الرحلة | `screens/ride_details/ride_details_screen.dart` | Search results | S |
| 17 | `RideRouteMapView` · خريطة المسار | `screens/ride_details/widgets/ride_route_map_view.dart` | Inside ride details | S |
| 18 | `BookingReviewScreen` · مراجعة الحجز | `screens/booking/booking_review_screen.dart` | Ride details | M |
| 19 | `BookingWaitingScreen` · انتظار الموافقة | `screens/booking/booking_waiting_screen.dart` | Booking review, My Rides | S |
| 20 | `BookingResultScreen` · نتيجة الحجز | `screens/booking/booking_result_screen.dart` | Booking waiting | M |
| 21 | `BookingConfirmationScreen` · تأكيد الحجز | `screens/booking/booking_confirmation_screen.dart` | Home upcoming-ride card | M |
| 22 | `CancellationSheet` · الإلغاء | `screens/booking/cancellation_sheet.dart` | Active trip | M |
| 23 | `ActiveTripScreen` · الرحلة الجارية | `screens/trip/active_trip_screen.dart` | Booking result, My Rides | S |
| 24 | `RateTripScreen` · التقييم | `screens/trip/rate_trip_screen.dart` | Active trip, My Rides, My Parcels | M |
| 25 | `ChatScreen` · المحادثة | `screens/chat/chat_screen.dart` | Trip, My Rides, My Parcels, Board | S |

### 4.3 Parcels, board and alerts | الطرود واللوحة والتنبيهات

| # | Screen · الشاشة | File | Reached from · الوصول من | State |
|---|---|---|---|---|
| 26 | `SendParcelScreen` · إرسال طرد | `screens/parcel/send_parcel_screen.dart` | Ride details | M |
| 27 | `ProhibitedItemsSheet` · الممنوعات | `screens/parcel/prohibited_items_sheet.dart` | Send parcel | M |
| 28 | `ParcelTrackingScreen` · تتبع الطرد | `screens/parcel/parcel_tracking_screen.dart` | Send parcel, My Parcels | S |
| 29 | `PickupCodeDialog` · كود الاستلام | `screens/parcel/pickup_code_dialog.dart` | Parcel tracking | S |
| 30 | `ParcelDisputeScreen` · نزاع الطرد | `screens/parcel/parcel_dispute_screen.dart` | Parcel tracking, My Parcels | S |
| 31 | `BoardScreen` · لوحة الطلبات | `screens/board/board_screen.dart` | Tab 2 | M |
| 32 | `PostAdScreen` · نشر إعلان | `screens/board/post_ad_screen.dart` | Board, My ads | M |
| 33 | `MakeOfferSheet` · تقديم عرض | `screens/board/make_offer_sheet.dart` | Board, My ads | M |
| 34 | `MyBoardAdsScreen` · إعلاناتي | `screens/board/board_extra_screens.dart` | Board, Account, Profile | M |
| 35 | `BoardAdOffersScreen` · عروض الإعلان | `screens/board/board_extra_screens.dart` | Board, My ads | S |
| 36 | `RescheduleRideScreen` · إعادة الجدولة | `screens/board/board_extra_screens.dart` | Driver rides | S |
| 37 | `MyAlertsScreen` · تنبيهاتي | `screens/alerts/my_alerts_screen.dart` | Home, Account | M |

### 4.4 Driver | السائق

| # | Screen · الشاشة | File | Reached from · الوصول من | State |
|---|---|---|---|---|
| 38 | `DriverOnboardingScreen` · انضم كسائق | `screens/driver/driver_onboarding_screens.dart` | Home, Account | M |
| 39 | `DriverVerificationStepsScreen` · خطوات التوثيق | same file | Driver onboarding | S |
| 40 | `DriverCarDetailsScreen` · بيانات السيارة | same file | Verification steps | M |
| 41 | `DriverStatusScreen` · حالة الطلب | same file | Verification steps | S |
| 42 | `VehicleRegistrationScreen` · تسجيل المركبة | `screens/vehicle/vehicle_registration_screen.dart` | Account, Settings | S |
| 43 | `PublishRideScreen` · نشر رحلة | `screens/driver/publish_ride_screen.dart` | Driver rides, Driver status | M |
| 44 | `DriverRidesScreen` · رحلاتي كسائق | `screens/driver/driver_rides_management_screens.dart` | Account | S |
| 45 | `DriverRequestsScreen` · طلبات الحجز | same file | Driver rides | S |
| 46 | `DriverPreTripScreen` · قبل الانطلاق | same file | Driver requests | S |
| 47 | `DriverInTransitScreen` · أثناء الرحلة | same file | Driver pre-trip | S |

### 4.5 Wallet, safety and account | المحفظة والسلامة والحساب

| # | Screen · الشاشة | File | Reached from · الوصول من | State |
|---|---|---|---|---|
| 48 | `WalletScreen` · المحفظة | `screens/wallet/wallet_screen.dart` | Home, Account, Profile, Settings | S |
| 49 | `LiveTripTrackingScreen` · التتبع الحي | `screens/safety/safety_screens.dart` | Account | S |
| 50 | `ShareTripSheet` · مشاركة الرحلة | same file | Active trip, Live tracking | S |
| 51 | `EmergencySosSheet` · الطوارئ | same file | Active trip, Live tracking, Driver in transit | S |
| 52 | `OffRouteAlertSheet` · تنبيه الخروج عن المسار | same file | A demo button on Live tracking only | S |
| 53 | `ReportIssueScreen` · الإبلاغ عن مشكلة | same file | Active trip | M |
| 54 | `EmergencyContactsScreen` · جهات الطوارئ | same file | Account, Settings | M |
| 55 | `UserProfileScreen` · الملف الشخصي | `screens/account/account_extra_screens.dart` | Home avatar | M |
| 56 | `EditProfileScreen` · تعديل الملف | same file | Account, Profile, Settings | M |
| 57 | `NotificationsCenterScreen` · الإشعارات | same file | Home, Account | S |
| 58 | `SettingsScreen` · الإعدادات | `screens/settings/settings_screen.dart` | Account, Profile | M |
| 59 | `HelpSupportScreen` · المساعدة | `screens/account/account_extra_screens.dart` | Account, Settings | S |
| 60 | `LegalComplianceScreen` · الشروط والخصوصية | `screens/account/legal_and_backend_screens.dart` | Account, Settings | S |
| 61 | `DeleteAccountScreen` · حذف الحساب | `screens/account/account_extra_screens.dart` | Account, Settings | M |
| 62 | `BackendReadinessScreen` · جاهزية الخادم | `screens/account/legal_and_backend_screens.dart` | Tests only | **U** |

### 4.6 System states | حالات النظام

| # | Screen · الشاشة | File | Reached from · الوصول من | State |
|---|---|---|---|---|
| 63 | `ForceUpdateScreen` · تحديث إجباري | `screens/system/system_screens.dart` | Nowhere | **U** |
| 64 | `MaintenanceScreen` · صيانة | same file | Nowhere | **U** |
| 65 | `OfflineScreen` · لا يوجد اتصال | same file | Nowhere | **U** |
| 66 | `GeneralErrorScreen` · خطأ عام | same file | Nowhere | **U** |
| 67 | `SessionExpiredScreen` · انتهاء الجلسة | same file | Nowhere | **U** |

### 4.7 Admin panel | لوحة الإدارة

| # | Screen · الشاشة | File | Reached from · الوصول من | State |
|---|---|---|---|---|
| 68 | `AdminLoginScreen` · دخول الإدارة | `screens/admin/admin_login_screen.dart` | After admin logout | S |
| 69 | `AdminShell` · هيكل اللوحة | `screens/admin/admin_shell.dart` | Admin app start | S |
| 70 | `AdminDashboardScreen` · لوحة الأرقام | `screens/admin/admin_dashboard_screen.dart` | Menu 0 | S |
| 71 | `AdminDriverVerificationsScreen` · توثيق السائقين | `screens/admin/admin_driver_verifications_screen.dart` | Menu 1 | M |
| 72 | `AdminUsersScreen` · المستخدمون | `screens/admin/admin_users_screen.dart` | Menu 2 | M |
| 73 | `AdminRidesParcelsScreen` · الرحلات والطرود | `screens/admin/admin_rides_parcels_screen.dart` | Menu 3 | M |
| 74 | `AdminDisputesScreen` · البلاغات والنزاعات | `screens/admin/admin_disputes_screen.dart` | Menu 4 | M |
| 75 | `AdminSettingsScreen` · الإعدادات | `screens/admin/admin_settings_screen.dart` | Menu 5 | M |
| 76 | `AdminStaffScreen` · الموظفون | `screens/admin/admin_staff_screen.dart` | Menu 6 | M |
| 77 | `AdminAuditLogScreen` · سجل التدقيق | `screens/admin/admin_audit_log_screen.dart` | Menu 7 | M |

**Totals | الإجمالي:** 77 screens, sheets and dialogs · 8 unreachable · 32 with simulation controls or hardcoded content.

77 شاشة ونافذة وحوارًا · 8 لا يمكن الوصول إليها · 32 تحتوي أزرار محاكاة أو محتوى ثابتًا.

---

## 5. User journeys as built | رحلات المستخدم كما هي مبنية

Each journey lists the steps that exist and the point where it stops being real.

كل رحلة تسرد الخطوات الموجودة والنقطة التي تتوقف عندها عن كونها حقيقية.

### J-1 Sign-in | الدخول

`Splash → Welcome → (Phone | Email | Google) → OTP → Profile setup → Main shell`

- **EN:** Any six digits pass the code check. Every sign-in ends at profile setup, including returning users. ID verification and the two permission screens are skipped. Closing the app loses the session. See C-02, H-06, H-07.
- **AR:** أي ستة أرقام تُقبل كرمز تحقق. كل دخول ينتهي بشاشة إنشاء الملف حتى للمستخدم العائد. تُتخطّى شاشة توثيق الهوية وشاشتا الأذونات. إغلاق التطبيق يُفقد الجلسة. انظر C-02 وH-06 وH-07.

### J-2 Find and book a ride | البحث عن رحلة وحجزها

`Home → Search results → Ride details → Booking review → Waiting → Result → Active trip → Rating`

- **EN:** The result list is the same for every query. The passenger approves their own booking from the waiting screen and starts and ends the trip from the app bar. No booking record is created and seats are not reduced. The rating is discarded. See C-07, H-01, H-05, H-13.
- **AR:** قائمة النتائج واحدة لكل بحث. الراكب يوافق على حجزه بنفسه من شاشة الانتظار ويبدأ الرحلة وينهيها من شريط العنوان. لا يُنشأ سجل حجز ولا تُخصم المقاعد. التقييم لا يُحفظ. انظر C-07 وH-01 وH-05 وH-13.

### J-3 Send a parcel | إرسال طرد

`Ride details → Send parcel → Tracking → Pickup code → Tracking → (Dispute)`

- **EN:** The form accepts an empty receiver and a zero weight. Every parcel gets the same code. The sender marks the handover themselves, and the tracking status is changed from a menu on the screen. See C-10, H-01, H-10.
- **AR:** النموذج يقبل مستلمًا فارغًا ووزنًا صفريًا. كل الطرود تحصل على الكود نفسه. المرسِل يؤكد التسليم بنفسه، وحالة التتبع تُغيَّر من قائمة على الشاشة. انظر C-10 وH-01 وH-10.

### J-4 Community board | لوحة الطلبات

`Board → Post ad → My ads → Offers → Accept → Chat` and `Board → Make offer → My sent offers`

- **EN:** Posted ads carry a hardcoded author name. The offers shown on an ad are three fixed cards. An offer is stored by changing the ad itself, and a withdrawn offer keeps its price. See M-01, M-02, M-03.
- **AR:** الإعلانات المنشورة تحمل اسم ناشر ثابتًا. العروض الظاهرة على الإعلان ثلاث بطاقات ثابتة. العرض يُخزَّن بتعديل الإعلان نفسه، والعرض المسحوب يحتفظ بسعره. انظر M-01 وM-02 وM-03.

### J-5 Become a driver and run a trip | الانضمام كسائق وتنفيذ رحلة

`Driver onboarding → Verification steps → Car details → Status → Publish ride → Driver rides → Requests → Pre-trip → In transit`

- **EN:** Document capture is simulated. Any user can publish a ride without completing verification. Booking requests are a fixed list. Ending the trip announces that earnings were credited, but the wallet does not change. See C-05, C-08, H-19.
- **AR:** التقاط المستندات مُحاكى. أي مستخدم يستطيع نشر رحلة دون إكمال التوثيق. طلبات الحجز قائمة ثابتة. إنهاء الرحلة يعلن إضافة الأرباح لكن المحفظة لا تتغير. انظر C-05 وC-08 وH-19.

### J-6 Wallet | المحفظة

`Wallet → Add funds | Withdraw | Choose payment method`

- **EN:** Tapping "add" raises the balance immediately with no payment. Withdrawal lowers it immediately. The proof-of-payment flow from D-09 does not exist yet. See C-05.
- **AR:** الضغط على «إضافة» يرفع الرصيد فورًا بلا دفع، والسحب يخفضه فورًا. مسار إثبات الدفع المذكور في D-09 غير موجود بعد. انظر C-05.

### J-7 Safety | السلامة

`Active trip → SOS | Share trip | Report issue`, `Account → Live tracking | Emergency contacts`

- **EN:** Emergency call buttons only show a message. Sharing is marked as sent to a hardcoded contact. Emergency contacts are lost when the screen closes. See C-03, M-04.
- **AR:** أزرار اتصال الطوارئ تعرض رسالة فقط. المشاركة تُعلَّم كمُرسلة إلى جهة اتصال ثابتة. جهات الطوارئ تُفقد عند إغلاق الشاشة. انظر C-03 وM-04.

### J-8 Admin | الإدارة

`Admin shell → Dashboard | Verifications | Users | Rides and parcels | Disputes | Settings | Staff | Audit log`

- **EN:** The panel opens already signed in. Roles are switched from a menu in the header. All actions change in-memory lists and nothing reaches the customer app. See C-09, M-11.
- **AR:** اللوحة تفتح والدخول مُسجَّل مسبقًا. الأدوار تُبدَّل من قائمة في الترويسة. كل الإجراءات تعدّل قوائم في الذاكرة ولا يصل شيء منها إلى تطبيق العملاء. انظر C-09 وM-11.

---

## 6. Findings | الملاحظات

Priority definitions | تعريف الأولويات

| Priority · الأولوية | Meaning (EN) | المعنى (AR) |
|---|---|---|
| **Critical · حرجة** | Unsafe, misleading to the user, or blocks any production release | غير آمنة أو مضللة للمستخدم أو تمنع أي إصدار إنتاجي |
| **High · عالية** | Breaks a core journey or blocks backend integration | تعطل رحلة أساسية أو تمنع الربط مع الخادم |
| **Medium · متوسطة** | Incorrect or inconsistent behaviour, or maintainability cost | سلوك خاطئ أو غير متسق أو كلفة صيانة |
| **Low · منخفضة** | Hygiene and polish | نظافة المستودع والتحسينات الشكلية |

### 6.1 Critical | الحرجة

#### C-01 · No data layer | لا توجد طبقة بيانات

**Where · الموقع:** `lib/data/api/mashwar_api_client.dart`, `lib/state/*.dart`, `pubspec.yaml`

- **EN —** The project has no HTTP package. `MashwarApiClient` builds headers and keeps a log but never sends a request, and the `_useMockAdapter` flag (line 60) is never used. Providers read `MockData` directly and hold all data in memory. **Impact:** nothing persists and no feature can be connected to a server. **Fix:** introduce repository interfaces per domain, a mock implementation behind them, and a real HTTP client. Providers depend on the interfaces only.
- **AR —** لا يحتوي المشروع على حزمة HTTP. الصنف `MashwarApiClient` يجهّز الترويسات ويحتفظ بسجل لكنه لا يرسل أي طلب، والعلم `_useMockAdapter` (السطر 60) غير مستخدم في أي مكان. المزوّدات تقرأ `MockData` مباشرة وتحتفظ بكل البيانات في الذاكرة. **الأثر:** لا شيء يُحفظ ولا يمكن ربط أي ميزة بخادم. **الحل:** إضافة واجهات مستودعات لكل مجال، وتنفيذ تجريبي خلفها، وعميل HTTP حقيقي، على أن تعتمد المزوّدات على الواجهات فقط.

#### C-02 · Sign-in is simulated and always on | الدخول مُحاكى ومفعَّل دائمًا

**Where · الموقع:** `lib/state/auth_provider.dart:15`, `:151`; `lib/screens/splash_screen.dart:19-25`; `lib/screens/auth/otp_verification_screen.dart:103-106`

- **EN —** The provider starts in the `authenticated` state. Any six-digit code is accepted. No token is stored and the splash screen always opens the welcome screen. Every successful code check opens profile setup, so a returning user is treated as new. **Impact:** there is no real identity, and sessions do not survive a restart. **Fix:** start unauthenticated, store tokens in secure storage, restore the session on launch, and branch new versus returning users from the server response.
- **AR —** المزوّد يبدأ بحالة «مُسجَّل الدخول». أي رمز من ستة أرقام يُقبل. لا يُخزَّن أي رمز جلسة، وشاشة البداية تفتح شاشة الترحيب دائمًا. كل تحقق ناجح يفتح إنشاء الملف، فيُعامَل المستخدم العائد كمستخدم جديد. **الأثر:** لا توجد هوية حقيقية والجلسة لا تبقى بعد إعادة التشغيل. **الحل:** البدء بحالة غير مُسجَّل، وتخزين الرموز في تخزين آمن، واستعادة الجلسة عند التشغيل، والتفريق بين المستخدم الجديد والعائد من رد الخادم.

#### C-03 · Emergency actions report success without acting | إجراءات الطوارئ تُظهر نجاحًا دون تنفيذ

**Where · الموقع:** `lib/screens/safety/safety_screens.dart:335`, `:349`, `:388`, `:406`, `:425`, `:259`, `:273`

- **EN —** "Call police 122" and "Call ambulance 123" only display a message saying the call is in progress. "Send to contacts" and "Share" set a local flag and show a sent state. **Impact:** a user in danger is told help was contacted when it was not. This is the most serious defect in the app. **Fix:** dial through the device dialler, send the alert through the server, and show a sent state only after confirmation. Until then, the buttons must open the dialler or be removed.
- **AR —** زرّا «الاتصال بالنجدة 122» و«الاتصال بالإسعاف 123» يعرضان فقط رسالة تفيد بأن الاتصال جارٍ. وزرّا «إرسال لجهات الاتصال» و«مشاركة» يغيّران قيمة محلية ويعرضان حالة «تم الإرسال». **الأثر:** يُبلَّغ مستخدم في خطر بأن النجدة أُبلغت وهي لم تُبلَّغ. هذا أخطر عيب في التطبيق. **الحل:** الاتصال عبر تطبيق الهاتف في الجهاز، وإرسال التنبيه عبر الخادم، وعدم إظهار حالة الإرسال إلا بعد التأكيد. وإلى أن يتم ذلك يجب أن تفتح الأزرار تطبيق الهاتف أو تُزال.

#### C-04 · New accounts inherit demo data | الحسابات الجديدة ترث بيانات تجريبية

**Where · الموقع:** `lib/data/models/user_model.dart:54`, `:67`, `:68`, `:73-76`; `lib/state/auth_provider.dart:165-203`, `:120-124`

- **EN —** `UserModel` defaults are demo values: verified, national ID `29810150102934`, wallet 450 EGP, rating 4.9, 14 rides, 6 parcels. `saveProfile` builds a new user without overriding most of them. Google sign-in copies the new name onto the demo user. **Impact:** every new account shows money, history and an identity number that are not its own. **Fix:** make the defaults neutral (unverified, zero balance, no rating, null ID) and build users only from server data.
- **AR —** القيم الافتراضية في `UserModel` تجريبية: موثَّق، رقم قومي `29810150102934`، محفظة 450 جنيهًا، تقييم 4.9، 14 رحلة، 6 طرود. الدالة `saveProfile` تنشئ مستخدمًا جديدًا دون تغيير معظمها. والدخول بـ Google ينسخ الاسم الجديد فوق المستخدم التجريبي. **الأثر:** كل حساب جديد يعرض رصيدًا وسجلًا ورقم هوية ليست له. **الحل:** جعل القيم الافتراضية محايدة (غير موثَّق، رصيد صفر، بلا تقييم، بلا رقم هوية) وإنشاء المستخدمين من بيانات الخادم فقط.

#### C-05 · Wallet moves money with no payment | المحفظة تحرّك الأموال بلا دفع

**Where · الموقع:** `lib/screens/wallet/wallet_screen.dart:222`, `:91`; `lib/state/auth_provider.dart:315-353`; `lib/screens/driver/driver_rides_management_screens.dart:1071`

- **EN —** "Add funds" increases the balance the moment it is tapped. Withdrawal decreases it the same way. Ending a driver trip shows "earnings credited" while no balance changes. **Impact:** balances are fiction, and the success messages are misleading. **Fix:** implement D-09: a top-up creates a pending transaction with an uploaded receipt, an admin approves it, and only the server changes the balance. The client displays the ledger and never computes it.
- **AR —** زر «إضافة رصيد» يرفع الرصيد لحظة الضغط، والسحب يخفضه بالطريقة نفسها. وإنهاء رحلة السائق يعرض «تم تسجيل الأرباح» دون أي تغيير في الرصيد. **الأثر:** الأرصدة وهمية ورسائل النجاح مضللة. **الحل:** تنفيذ القرار D-09: الشحن ينشئ عملية معلّقة مع إيصال مرفوع، ثم تعتمدها الإدارة، والخادم وحده يغيّر الرصيد. التطبيق يعرض كشف الحركات ولا يحسبه.

#### C-06 · Release build cannot reach the network | نسخة الإصدار لا تصل إلى الشبكة

**Where · الموقع:** `android/app/src/main/AndroidManifest.xml`; `ios/Runner/Info.plist`; `lib/core/constants/app_typography.dart:16`

- **EN —** The `INTERNET` permission exists only in the debug and profile manifests, not in the main one. A release APK therefore has no network access. The Cairo font is downloaded at run time by `google_fonts`, so it would also fail to load. `Info.plist` has no usage descriptions for camera, photos or location. **Impact:** the app works in debug and breaks in release. Once camera or location plugins are added, iOS ends the app on the first request that has no usage description. **Fix:** add the permission to the main manifest, bundle the Cairo font as an asset, and add the iOS usage descriptions together with the plugins that need them.
- **AR —** صلاحية `INTERNET` موجودة في ملفي debug وprofile فقط وليست في الملف الرئيسي، فنسخة الإصدار بلا اتصال بالشبكة. وخط Cairo يُحمَّل وقت التشغيل عبر `google_fonts` فسيفشل تحميله أيضًا. وملف `Info.plist` خالٍ من نصوص طلب الكاميرا والصور والموقع. **الأثر:** التطبيق يعمل في وضع التطوير ويتعطل في الإصدار. وبعد إضافة إضافات الكاميرا أو الموقع يُنهي iOS التطبيق عند أول طلب ليس له نص إذن. **الحل:** إضافة الصلاحية للملف الرئيسي، وتضمين خط Cairo ضمن الأصول، وإضافة نصوص الأذونات في iOS مع الإضافات التي تحتاجها.

#### C-07 · Search does not filter | البحث لا يُرشِّح النتائج

**Where · الموقع:** `lib/state/rides_provider.dart:110-129`; `lib/screens/search/search_results_screen.dart:25-26`

- **EN —** `filteredRides` ignores the origin, destination, date, seat count, time slot and ride/parcel mode. It only applies three toggles and moves exact route matches to the top. **Impact:** a search from Aswan to Alexandria lists Kafr El-Sheikh to Cairo rides. The core journey gives wrong answers. **Fix:** search becomes a repository call with all criteria. The mock implementation must filter the same way the server will.
- **AR —** الدالة `filteredRides` تتجاهل نقطة الانطلاق والوجهة والتاريخ وعدد المقاعد والفترة الزمنية ونوع الخدمة. تطبّق ثلاثة مفاتيح فقط وترفع الرحلات المطابقة للمسار إلى الأعلى. **الأثر:** البحث من أسوان إلى الإسكندرية يعرض رحلات كفر الشيخ إلى القاهرة، أي أن الرحلة الأساسية تعطي نتائج خاطئة. **الحل:** يصبح البحث استدعاءً للمستودع بكل المعايير، ويجب أن يُرشِّح التنفيذ التجريبي بالطريقة التي سيعمل بها الخادم.

#### C-08 · Verification is cosmetic and gates nothing | التوثيق شكلي ولا يقيّد شيئًا

**Where · الموقع:** `lib/screens/auth/id_verification_screen.dart:389-417`, `:154-156`; `lib/screens/vehicle/vehicle_registration_screen.dart:314`, `:321`; `lib/screens/driver/publish_ride_screen.dart:126-151`

- **EN —** Tapping a photo slot toggles a boolean. The submitted "files" are fixed names such as `front_id_scanned.jpg`. No camera or gallery is opened. Publishing a ride never checks verification status. **Impact:** the trust feature the product is built on does not exist, and unverified users can offer rides. **Fix:** real capture and upload, a server-side review state, and a guard that blocks publishing and accepting parcels until the driver is approved.
- **AR —** الضغط على خانة الصورة يبدّل قيمة منطقية فقط. و«الملفات» المُرسلة أسماء ثابتة مثل `front_id_scanned.jpg`. لا تُفتح الكاميرا ولا المعرض. ونشر الرحلة لا يتحقق من حالة التوثيق إطلاقًا. **الأثر:** ميزة الثقة التي يقوم عليها المنتج غير موجودة، والمستخدم غير الموثَّق يستطيع عرض رحلات. **الحل:** التقاط ورفع حقيقيان، وحالة مراجعة على الخادم، وقيد يمنع النشر وقبول الطرود حتى اعتماد السائق.

#### C-09 · Admin panel is protected only in the UI | لوحة الإدارة محمية في الواجهة فقط

**Where · الموقع:** `lib/state/admin_provider.dart:257`, `:285-295`; `lib/screens/admin/admin_login_screen.dart:20-21`, `:47`; `lib/screens/admin/admin_shell.dart:701`

- **EN —** The panel starts signed in. The login form is pre-filled, and the accepted email is written in the client code with any password of six characters. A header menu lets the current user switch role. Permissions are checked by menu index in the client. **Impact:** anyone who opens the panel is a super admin. **Fix:** real staff authentication, roles and permissions issued and enforced by the server, and removal of the pre-filled credentials and the role switcher.
- **AR —** اللوحة تبدأ والدخول مُسجَّل. نموذج الدخول معبأ مسبقًا، والبريد المقبول مكتوب في كود العميل مع أي كلمة مرور من ستة أحرف. وقائمة في الترويسة تتيح للمستخدم تبديل دوره. والصلاحيات تُفحص برقم القائمة داخل العميل. **الأثر:** كل من يفتح اللوحة يصبح مشرفًا أول. **الحل:** مصادقة حقيقية للموظفين، وأدوار وصلاحيات يصدرها الخادم ويفرضها، وحذف بيانات الدخول المعبأة مسبقًا وقائمة تبديل الدور.

#### C-10 · Parcel handover code is fixed and unverified | كود تسليم الطرد ثابت وغير متحقَّق منه

**Where · الموقع:** `lib/state/parcels_provider.dart:33`; `lib/screens/driver/driver_rides_management_screens.dart:964`; `lib/screens/parcel/pickup_code_dialog.dart:104`

- **EN —** Every parcel receives the code `4 8 2 1`. The driver screen compares the input with the literal `4821`. The sender can mark the parcel as handed over from their own screen. **Impact:** the anti-fraud control described in the README offers no protection. **Fix:** the server generates a unique alphanumeric code per handover step (D-11), stores only a hash, verifies it, limits attempts, and is the only party that advances the parcel status.
- **AR —** كل طرد يحصل على الكود `4 8 2 1`. وشاشة السائق تقارن المُدخل بالقيمة الثابتة `4821`. والمرسِل يستطيع تعليم الطرد كمُسلَّم من شاشته. **الأثر:** وسيلة منع الاحتيال المذكورة في ملف README لا توفر أي حماية. **الحل:** يولّد الخادم كودًا فريدًا من حروف وأرقام لكل خطوة تسليم (D-11)، ويخزّن بصمته فقط، ويتحقق منه، ويحدّ عدد المحاولات، ويكون الجهة الوحيدة التي تغيّر حالة الطرد.

### 6.2 High | العالية

#### H-01 · Simulation controls are part of user screens | أزرار المحاكاة جزء من شاشات المستخدم

**Where · الموقع:** `ride_details_screen.dart:79-90`; `booking_waiting_screen.dart:73`, `:87`; `active_trip_screen.dart:63`, `:216`; `parcel_tracking_screen.dart:58`; `parcel_dispute_screen.dart:137`, `:162`; `board_extra_screens.dart:917`, `:923`; `safety_screens.dart:42`, `:176`

- **EN —** A menu on ride details switches between five states. The passenger sees "Confirm" and "Decline" on their own pending booking and "Start trip" and "End ride" on the trip. Parcel status, dispute phase and reschedule result are changed the same way. **Impact:** users can drive flows that belong to the other party or to the server. **Fix:** remove these controls from the screens and drive the states from repository data. Keep a debug-only developer menu if previews are still needed.
- **AR —** قائمة في تفاصيل الرحلة تبدّل بين خمس حالات. والراكب يرى زرّي «تأكيد» و«اعتذار» على حجزه المعلّق، و«بدء الرحلة» و«إنهاء الرحلة» على رحلته. وحالة الطرد ومرحلة النزاع ونتيجة إعادة الجدولة تُغيَّر بالطريقة نفسها. **الأثر:** المستخدم يتحكم في مسارات تخص الطرف الآخر أو الخادم. **الحل:** إزالة هذه الأزرار من الشاشات وربط الحالات ببيانات المستودع، مع إبقاء قائمة للمطورين في وضع التطوير فقط إن لزمت المعاينة.

#### H-02 · Models are shaped for display, not for a backend | النماذج مصممة للعرض لا للخادم

**Where · الموقع:** `lib/data/models/*.dart`; `lib/state/admin_provider.dart:63-232`; `lib/state/auth_provider.dart:274-311`

- **EN —** Dates and times are localized strings such as `الجمعة 6 نوفمبر`. Admin statuses are Arabic strings. A ride embeds the driver as a name, a car description and a phone. Wallet transactions are raw maps. There are no models for booking, offer, message, vehicle, transaction, notification, dispute, rating or emergency contact. **Impact:** nothing can be sorted, compared, validated or mapped to tables. **Fix:** typed models with identifiers, `DateTime` in UTC, integer money in piastres, enum status codes, and references between entities.
- **AR —** التواريخ والأوقات نصوص مترجمة مثل `الجمعة 6 نوفمبر`. حالات الإدارة نصوص عربية. الرحلة تحتوي السائق كاسم ووصف سيارة ورقم هاتف. حركات المحفظة خرائط خام. ولا توجد نماذج للحجز والعرض والرسالة والمركبة والحركة المالية والإشعار والنزاع والتقييم وجهة الطوارئ. **الأثر:** لا يمكن الترتيب أو المقارنة أو التحقق أو الربط بجداول. **الحل:** نماذج مُحدَّدة الأنواع بمعرّفات، وتواريخ `DateTime` بتوقيت UTC، ومبالغ صحيحة بالقرش، وحالات على شكل رموز، وروابط بين الكيانات.

#### H-03 · Localization works by matching Arabic text | الترجمة تعمل بمطابقة النص العربي

**Where · الموقع:** `lib/core/localization/app_strings.dart:9-403`; `lib/core/widgets/mashwar_button.dart:40`; `lib/state/auth_provider.dart:54`, `:58`

- **EN —** Arabic strings are the data keys. English is produced by looking the Arabic text up in phrase maps. Screens contain about 1,440 inline `isAr ? … : …` expressions, and providers return Arabic error messages. **Impact:** any text the maps do not contain appears in Arabic in the English UI, and a server cannot return localized display strings as identifiers. **Fix:** move UI text to ARB files with `flutter gen-l10n`, store codes in data, and translate codes at the edge.
- **AR —** النصوص العربية هي مفاتيح البيانات، والإنجليزية تُستخرج بالبحث عن النص العربي في خرائط عبارات. الشاشات تحوي نحو 1,440 تعبيرًا من نوع `isAr ? … : …`، والمزوّدات تعيد رسائل خطأ بالعربية. **الأثر:** أي نص غير موجود في الخرائط يظهر بالعربية في الواجهة الإنجليزية، ولا يستطيع الخادم إرجاع نصوص عرض مترجمة كمعرّفات. **الحل:** نقل نصوص الواجهة إلى ملفات ARB عبر `flutter gen-l10n`، وتخزين رموز في البيانات، وترجمة الرموز عند العرض.

#### H-04 · No real date or time selection | لا يوجد اختيار حقيقي للتاريخ والوقت

**Where · الموقع:** `lib/screens/home/date_time_picker_sheet.dart:29-33`

- **EN —** The picker offers fixed chips: Today, Tomorrow, "Fri 6", "Sat 7" and "Other date". "Other date" selects that literal text. No calendar or time picker is used anywhere, and `intl` is never imported. **Impact:** a driver cannot publish for a real date and a passenger cannot search one. **Fix:** a real date and time picker producing `DateTime`, formatted for display with `intl` in both languages.
- **AR —** نافذة الاختيار تعرض خيارات ثابتة: النهارده، بكرة، «الجمعة 6»، «السبت 7»، و«تاريخ تاني». وخيار «تاريخ تاني» يختار هذا النص حرفيًا. لا يُستخدم تقويم ولا منتقي وقت في أي مكان، وحزمة `intl` غير مستوردة. **الأثر:** السائق لا يستطيع النشر لتاريخ فعلي والراكب لا يستطيع البحث عنه. **الحل:** منتقي تاريخ ووقت حقيقي ينتج `DateTime` ويُنسَّق للعرض عبر `intl` باللغتين.

#### H-05 · Booking creates no booking | الحجز لا ينشئ حجزًا

**Where · الموقع:** `lib/screens/booking/booking_review_screen.dart:59-73`; `lib/state/rides_provider.dart:131-153`

- **EN —** Submitting the review waits 700 ms and opens the waiting screen without calling a provider. A ride is added to "booked rides" only after the passenger presses the simulated confirm. Seats are never reduced, and no payment method is chosen at booking. **Impact:** there is no entity to approve, cancel, pay for or rate. **Fix:** a `Booking` model with seats, price breakdown, payment method and status, created through the repository and updated by the driver's decision.
- **AR —** إرسال المراجعة ينتظر 700 ميلي ثانية ثم يفتح شاشة الانتظار دون استدعاء أي مزوّد. تُضاف الرحلة إلى «الرحلات المحجوزة» فقط بعد ضغط الراكب على زر التأكيد المُحاكى. المقاعد لا تُخصم، ولا تُختار وسيلة دفع عند الحجز. **الأثر:** لا يوجد كيان يمكن الموافقة عليه أو إلغاؤه أو دفعه أو تقييمه. **الحل:** نموذج `Booking` يضم المقاعد وتفصيل السعر ووسيلة الدفع والحالة، يُنشأ عبر المستودع ويُحدَّث بقرار السائق.

#### H-06 · Google sign-in is an imitation account chooser | الدخول بـ Google نافذة اختيار حساب مقلَّدة

**Where · الموقع:** `lib/screens/auth/welcome_screen.dart:82-94`, `:176-187`

- **EN —** The sheet draws a Google-style chooser with two hardcoded accounts. Selecting one signs the user in as that name. **Impact:** it looks like the real Google dialog and is not. D-13 makes Google the primary sign-in. **Fix:** the official Google Sign-In flow, with the ID token verified by the server.
- **AR —** النافذة ترسم واجهة اختيار حساب على طريقة Google بحسابين ثابتين، واختيار أحدهما يسجّل الدخول باسمه. **الأثر:** تبدو كنافذة Google الحقيقية وليست كذلك، والقرار D-13 يجعل Google وسيلة الدخول الأساسية. **الحل:** استخدام مسار الدخول الرسمي من Google مع تحقق الخادم من رمز الهوية.

#### H-07 · Onboarding steps are unreachable | خطوات التهيئة لا يمكن الوصول إليها

**Where · الموقع:** `lib/screens/auth/profile_setup_screen.dart:166-169`; `lib/screens/auth/id_verification_screen.dart:461`; `lib/screens/permissions/location_permission_screen.dart:81-99`

- **EN —** Profile setup goes straight to the main shell. `isOnboarding: true` is never passed, so the ID step and both permission screens are skipped. On the location screen, "allow" moves on without requesting any operating-system permission. **Fix:** define one onboarding sequence, request real permissions at the moment they are needed, and record the result.
- **AR —** شاشة إنشاء الملف تنتقل مباشرة إلى الهيكل الرئيسي. القيمة `isOnboarding: true` لا تُمرَّر أبدًا، فتُتخطّى خطوة الهوية وشاشتا الأذونات. وفي شاشة الموقع ينتقل زر «السماح» إلى الخطوة التالية دون طلب أي إذن من نظام التشغيل. **الحل:** تحديد تسلسل تهيئة واحد، وطلب الأذونات الفعلية لحظة الحاجة إليها، وتسجيل النتيجة.

#### H-08 · Calls, sharing and external apps are faked | الاتصال والمشاركة والتطبيقات الخارجية مُحاكاة

**Where · الموقع:** Calls: `booking_confirmation_screen.dart:108`, `active_trip_screen.dart:134`, `:303`, `chat_screen.dart:171`, `parcel_tracking_screen.dart:240`, `safety_screens.dart:138`, `board_extra_screens.dart:546`, `account_extra_screens.dart:705`. Sharing: `post_ad_screen.dart:464`, `ride_details_screen.dart:717`, `parcel_tracking_screen.dart:255`, `:470`, `publish_ride_screen.dart:200`, `booking_confirmation_screen.dart:125`, `safety_screens.dart:287`. Other: `ride_route_map_view.dart:1134`, `account_extra_screens.dart:685`, `system_screens.dart:34`, `:177`

- **EN —** These buttons show "Calling…", "Link copied", "Opening WhatsApp…" or "Sent to Google Maps / Waze" and do nothing else. The clipboard is written only in the developer screen. **Impact:** about twenty misleading messages across the main flows. **Fix:** launch the dialler, share sheet, WhatsApp and map apps for real, copy to the clipboard when the message says so, and report failure when the target app is missing.
- **AR —** هذه الأزرار تعرض «جاري الاتصال…» أو «تم نسخ الرابط» أو «جاري فتح واتساب…» أو «تم الإرسال إلى خرائط Google / Waze» دون أي إجراء آخر. والنسخ إلى الحافظة يحدث فقط في شاشة المطورين. **الأثر:** نحو عشرين رسالة مضللة في المسارات الرئيسية. **الحل:** فتح تطبيق الهاتف ونافذة المشاركة وواتساب وتطبيقات الخرائط فعليًا، والنسخ إلى الحافظة عندما تقول الرسالة ذلك، وإظهار الفشل عند غياب التطبيق المطلوب.

#### H-09 · Chat is scripted | المحادثة مكتوبة مسبقًا

**Where · الموقع:** `lib/screens/chat/chat_screen.dart:30`, `:171`

- **EN —** Messages live in the screen's state and begin with a fixed conversation. Replies are generated on a timer. The same thread appears for every counterpart, and the call button shows a fixed number. **Fix:** conversation and message models, a messaging repository with real-time delivery, and no generated replies.
- **AR —** الرسائل محفوظة في حالة الشاشة وتبدأ بمحادثة ثابتة، والردود تُولَّد بمؤقّت. تظهر المحادثة نفسها مع أي طرف، وزر الاتصال يعرض رقمًا ثابتًا. **الحل:** نماذج للمحادثة والرسالة، ومستودع مراسلة بتسليم لحظي، ودون ردود مولَّدة.

#### H-10 · Forms are not validated | النماذج بلا تحقق من المدخلات

**Where · الموقع:** `send_parcel_screen.dart:46-75`; `publish_ride_screen.dart:111`, `:141-142`; `safety_screens.dart:731`; `admin_staff_screen.dart:108`; `profile_setup_screen.dart:143`

- **EN —** No screen uses `Form` or a `validator`. Send parcel accepts an empty description, receiver name and phone, and a weight of zero. Publish ride uses 120 EGP when the price is blank and invents the pickup and drop-off points. Emergency contact phones and staff emails are not checked. Profile email is checked only for an `@`. **Fix:** shared validators (Egyptian phone, email, required text, numeric ranges, national ID), inline error text, and disabled submit until the form is valid.
- **AR —** لا تستخدم أي شاشة `Form` أو `validator`. نموذج إرسال الطرد يقبل وصفًا فارغًا واسم مستلم ورقمًا فارغين ووزنًا صفريًا. ونشر الرحلة يعتمد 120 جنيهًا إذا تُرك السعر فارغًا ويختلق نقطتي الركوب والنزول. وأرقام جهات الطوارئ وبريد الموظفين لا تُفحص، وبريد الملف الشخصي يُفحص بوجود `@` فقط. **الحل:** أدوات تحقق مشتركة (هاتف مصري، بريد، نص إلزامي، نطاقات رقمية، رقم قومي)، ورسائل خطأ داخل الحقول، وتعطيل زر الإرسال حتى اكتمال النموذج.

#### H-11 · Business limits are hardcoded and contradictory | حدود العمل مكتوبة في الكود ومتعارضة

**Where · الموقع:** `publish_ride_screen.dart:112-119`; `send_parcel_screen.dart:51-52`; `lib/state/admin_provider.dart:750-809`; `legal_and_backend_screens.dart:100-104`

- **EN —** Seat price is forced between 90 and 150 EGP for every route. Parcel limits of 15 kg and 2,000 EGP are written in the screen and again in admin settings. The legal text states a 10% fee while admin settings hold a 25% price margin. **Impact:** changing a setting in the admin panel changes nothing in the app. **Fix:** per D-08 and D-10, limits, commission and cancellation rules come from server configuration per service category. The legal text is generated from the same values.
- **AR —** سعر المقعد مُقيَّد بين 90 و150 جنيهًا لكل المسارات. حدّا الطرد (15 كجم و2,000 جنيه) مكتوبان في الشاشة ومكرران في إعدادات الإدارة. والنص القانوني يذكر رسومًا 10% بينما إعدادات الإدارة تحوي هامش سعر 25%. **الأثر:** تغيير الإعداد في لوحة الإدارة لا يغيّر شيئًا في التطبيق. **الحل:** وفق D-08 وD-10 تأتي الحدود والعمولة وقواعد الإلغاء من إعدادات الخادم لكل فئة خدمة، ويُولَّد النص القانوني من القيم نفسها.

#### H-12 · Loading, error and offline states are not wired | حالات التحميل والخطأ والانقطاع غير مربوطة

**Where · الموقع:** `search_results_screen.dart:25-26`; `lib/screens/system/system_screens.dart`

- **EN —** `_isOffline` and `_hasError` are constants set to `false`, so the error and offline views on search can never appear. The five system screens are never shown. There are no skeleton loaders, no pull-to-refresh and no pagination anywhere. **Fix:** one async-state type used by every provider (loading, data, empty, error, offline), shared skeleton, empty and error widgets, a connectivity listener, and the system screens driven by server signals.
- **AR —** المتغيران `_isOffline` و`_hasError` ثابتان بقيمة `false`، فلا يمكن أن تظهر واجهتا الخطأ والانقطاع في البحث. وشاشات النظام الخمس لا تُعرض أبدًا. ولا توجد هياكل تحميل ولا سحب للتحديث ولا تقسيم للصفحات في أي مكان. **الحل:** نوع واحد للحالة غير المتزامنة تستخدمه كل المزوّدات (تحميل، بيانات، فارغ، خطأ، انقطاع)، ومكوّنات مشتركة للهيكل والفراغ والخطأ، ومستمع لحالة الاتصال، وربط شاشات النظام بإشارات الخادم.

#### H-13 · Ratings, reports and alerts are discarded | التقييمات والبلاغات والتنبيهات لا تُحفظ

**Where · الموقع:** `rate_trip_screen.dart:71-86`; `safety_screens.dart:625`; `ride_details_screen.dart:413`; `parcel_dispute_screen.dart` (report id `#4821`)

- **EN —** Submitting a rating waits, thanks the user and closes. Reporting an issue sets a local flag. "Alert me if a seat frees up" shows a confirmation and stores nothing. Disputes use one fixed report number. **Fix:** each of these becomes a repository call with a stored record, and the confirmation appears only after the call succeeds.
- **AR —** إرسال التقييم ينتظر ثم يشكر المستخدم ويغلق. والإبلاغ عن مشكلة يغيّر قيمة محلية. و«نبّهني إذا توفر مقعد» يعرض تأكيدًا ولا يخزّن شيئًا. والنزاعات تستخدم رقم بلاغ ثابتًا. **الحل:** يصبح كل منها استدعاءً للمستودع بسجل محفوظ، ولا يظهر التأكيد إلا بعد نجاح الاستدعاء.

#### H-14 · Ladies-only rides are not enforced | رحلات السيدات غير مُلزِمة فعليًا

**Where · الموقع:** `ride_details_screen.dart:58`; `publish_ride_screen.dart:521`; `post_ad_screen.dart:309`; `id_verification_screen.dart:57-110`

- **EN —** The only check compares the self-declared gender on ride details. Any driver can mark a ride as ladies-only. The national-ID decoder reads birth date and governorate but not the gender digit. **Impact:** the service described in D-12 as sensitive has no control behind it. **Fix:** per A-03, the server enforces a verified female driver and female passengers, the option is hidden from accounts that do not qualify, and the gender digit is read during verification.
- **AR —** الفحص الوحيد يقارن النوع المُدخَل ذاتيًا في شاشة تفاصيل الرحلة. وأي سائق يستطيع تعليم رحلته «للسيدات فقط». ومحلّل الرقم القومي يقرأ تاريخ الميلاد والمحافظة دون خانة النوع. **الأثر:** الخدمة الموصوفة في D-12 بأنها حساسة بلا أي ضابط. **الحل:** وفق A-03 يفرض الخادم سائقة موثَّقة وراكبات فقط، ويُخفى الخيار عن الحسابات غير المؤهلة، وتُقرأ خانة النوع أثناء التوثيق.

#### H-15 · Deleting an account only signs out | حذف الحساب يسجّل الخروج فقط

**Where · الموقع:** `account_extra_screens.dart:898`; `lib/state/auth_provider.dart:393-396`

- **EN —** Confirming deletion calls `logout()`. Logout changes one status field and leaves user, wallet, rides and parcels in memory for the next person who signs in. **Impact:** app stores require working account deletion, and the next session sees the previous user's data. **Fix:** a deletion request handled by the server, and a full state reset on logout.
- **AR —** تأكيد الحذف يستدعي `logout()`. وتسجيل الخروج يغيّر حقل حالة واحدًا ويترك بيانات المستخدم والمحفظة والرحلات والطرود في الذاكرة لمن يدخل بعده. **الأثر:** متاجر التطبيقات تشترط حذفًا فعليًا للحساب، والجلسة التالية ترى بيانات المستخدم السابق. **الحل:** طلب حذف يعالجه الخادم، وتصفير كامل للحالة عند تسجيل الخروج.

#### H-16 · Branding is not applied to the builds | الهوية غير مطبَّقة على نسخ التطبيق

**Where · الموقع:** `android/app/src/main/res/mipmap-*/ic_launcher.png`; `ios/Runner/Assets.xcassets/AppIcon.appiconset/`; `android/app/src/main/AndroidManifest.xml` (`android:label="mashwar"`)

- **EN —** Launcher icons on both platforms are the default Flutter icon, and the native launch screen is unbranded. The project has no `assets` folder, so none of the pack's files are in the app. The Android label is lowercase `mashwar`. The in-app logo is not affected: `MashwarPinIcon` draws the same geometry as the pack's pin SVG. **Fix:** generate launcher icons and the native splash from the pack's app icon, keep the in-code logo painter, and set the display name to "مشوار" / "Mashwar".
- **AR —** أيقونة التطبيق على المنصتين هي أيقونة Flutter الافتراضية، وشاشة الإقلاع الأصلية بلا هوية. ولا يحتوي المشروع على مجلد `assets`، فلا يوجد أي ملف من الحزمة داخل التطبيق. واسم التطبيق على Android مكتوب `mashwar` بحروف صغيرة. أما الشعار داخل التطبيق فسليم: المكوّن `MashwarPinIcon` يرسم الشكل الهندسي نفسه الموجود في ملف SVG للدبوس في الحزمة. **الحل:** توليد الأيقونات وشاشة الإقلاع من أيقونة التطبيق في الحزمة، والإبقاء على رسم الشعار بالكود، وضبط الاسم الظاهر إلى «مشوار» / "Mashwar".

#### H-17 · Typography depends on a run-time download | الخطوط تعتمد على تنزيل وقت التشغيل

**Where · الموقع:** `lib/core/theme/app_theme.dart:24`; `lib/core/constants/app_typography.dart:16`; `pubspec.yaml`

- **EN —** The theme sets `fontFamily: 'Cairo'`, but no font is declared in `pubspec.yaml`. `google_fonts` registers Cairo under its own family names, so the 349 `TextStyle` uses that do not go through `AppTypography` are expected to fall back to the system font. Cairo itself is fetched over the network on first use. **Impact:** mixed fonts and a wrong font when offline. This needs confirmation on a device. **Fix:** bundle Cairo as an asset under the family name `Cairo` and route text through the theme's text styles.
- **AR —** السمة تحدد `fontFamily: 'Cairo'` لكن لا يوجد خط معلن في `pubspec.yaml`. حزمة `google_fonts` تسجّل Cairo بأسماء خاصة بها، فيُتوقع أن تعود الاستخدامات الـ349 لـ`TextStyle` التي لا تمر عبر `AppTypography` إلى خط النظام. وخط Cairo نفسه يُجلب من الشبكة عند أول استخدام. **الأثر:** خطوط مختلطة وخط خاطئ عند انقطاع الاتصال، ويحتاج ذلك تأكيدًا على جهاز. **الحل:** تضمين Cairo ضمن الأصول باسم العائلة `Cairo` وتوجيه النصوص عبر أنماط السمة.

#### H-18 · Accessibility gaps | ثغرات إمكانية الوصول

**Where · الموقع:** `lib/core/theme/app_theme.dart:38`; `lib/core/widgets/mashwar_button.dart:49`; `AppColors.gold` as a foreground colour in 45 places under `lib/screens`

- **EN —** Measured contrast ratios against the WCAG AA minimum of 4.5:1: hint text `#E5E5EA` on white is 1.26:1; the disabled primary button (white on `#E5E5EA`) is 1.26:1; gold `#F5A524` on white is 2.04:1, below the 4.5:1 text minimum and the 3:1 minimum for meaningful icons, and gold is used as a foreground colour for icons and some text. Only 24 semantic labels or tooltips exist for 97 icon buttons and 53 gesture detectors. **Fix:** darker hint and disabled colours, gold reserved for fills with navy on top (7.18:1, as most gold surfaces already do), labels on every icon-only control, and a check at large text scale.
- **AR —** نسب التباين المقيسة مقارنة بالحد الأدنى 4.5:1 في معيار WCAG AA: نص التلميح `#E5E5EA` على الأبيض 1.26:1، والزر الأساسي المعطَّل (أبيض على `#E5E5EA`) 1.26:1، والذهبي `#F5A524` على الأبيض 2.04:1 أي دون حد النص 4.5:1 ودون حد الأيقونات ذات المعنى 3:1، والذهبي مستخدم كلون أمامي لأيقونات وبعض النصوص. ويوجد 24 وصفًا دلاليًا فقط مقابل 97 زر أيقونة و53 كاشف لمس. **الحل:** ألوان أغمق للتلميح والحالة المعطَّلة، وحصر الذهبي في التعبئة مع الكحلي فوقه (7.18:1 كما في معظم الأسطح الذهبية حاليًا)، ووصف لكل عنصر تحكم بأيقونة فقط، واختبار عند تكبير الخط.

#### H-19 · Mock content is written inside screens | المحتوى التجريبي مكتوب داخل الشاشات

**Where · الموقع:** `driver_rides_management_screens.dart:439`, `:462`; `account_extra_screens.dart:930`; `main_nav_shell.dart:386`, `:402`, `:423`, `:457`, `:714`; `board_extra_screens.dart:650-688`; `lib/state/admin_provider.dart:297-330`

- **EN —** Driver booking requests, notifications, past rides and parcels, the offers on an ad and the admin KPIs are literals in widget code. Four screen files import `MockData` directly. **Impact:** these screens cannot be switched to real data without rewriting them. **Fix:** move all sample content behind the mock repositories so that screens receive data only from providers.
- **AR —** طلبات الحجز لدى السائق، والإشعارات، والرحلات والطرود السابقة، والعروض على الإعلان، ومؤشرات لوحة الإدارة كلها قيم مكتوبة داخل كود الواجهة. وأربعة ملفات شاشات تستورد `MockData` مباشرة. **الأثر:** لا يمكن تحويل هذه الشاشات إلى بيانات حقيقية دون إعادة كتابتها. **الحل:** نقل كل المحتوى التجريبي خلف المستودعات التجريبية لتستقبل الشاشات بياناتها من المزوّدات فقط.

#### H-20 · No route table, guards or deep links | لا يوجد جدول مسارات ولا حماية ولا روابط عميقة

**Where · الموقع:** 117 `MaterialPageRoute` pushes under `lib/screens`; `lib/main.dart:50`; `lib/state/auth_provider.dart` (405 lines)

- **EN —** Screens construct each other directly. Nothing prevents opening an authenticated screen without a session, and a notification or a tracking link cannot open a specific screen. `AuthProvider` also owns the wallet, payment method and vehicle. **Fix:** a central route table with an auth guard and deep-link paths for ride, booking, parcel tracking and ad. Split wallet and vehicle state into their own providers.
- **AR —** الشاشات تنشئ بعضها مباشرة. لا شيء يمنع فتح شاشة تتطلب دخولًا دون جلسة، ولا يستطيع إشعار أو رابط تتبع فتح شاشة محددة. والمزوّد `AuthProvider` يدير أيضًا المحفظة ووسيلة الدفع والمركبة. **الحل:** جدول مسارات مركزي مع حماية للدخول وروابط عميقة للرحلة والحجز وتتبع الطرد والإعلان، وفصل حالة المحفظة والمركبة في مزوّدات مستقلة.

### 6.3 Medium | المتوسطة

| ID | Finding and fix (EN) | الملاحظة والحل (AR) | Where · الموقع |
|---|---|---|---|
| M-01 | `copyWith` cannot set a field to null because it uses `??`. Withdrawing an offer therefore keeps the old price. Fix: allow explicit clearing of nullable fields. | الدالة `copyWith` لا تستطيع تصفير حقل لأنها تستخدم `??`، فسحب العرض يُبقي السعر القديم. الحل: السماح بتصفير الحقول الاختيارية صراحةً. | `board_provider.dart:132`, all models |
| M-02 | An offer is stored by changing the ad's status and overwriting its notes. One user's offer changes the ad for everyone. Fix: a separate `Offer` entity linked to the ad. | العرض يُخزَّن بتغيير حالة الإعلان والكتابة فوق ملاحظاته، فعرض مستخدم واحد يغيّر الإعلان للجميع. الحل: كيان `Offer` مستقل مرتبط بالإعلان. | `board_provider.dart:111-125` |
| M-03 | Posted ads use the hardcoded author `عبدالرحمن أحمد` with 14 trips. Fix: take the author from the session. | الإعلانات المنشورة تستخدم اسم الناشر الثابت «عبدالرحمن أحمد» و14 رحلة. الحل: أخذ الناشر من الجلسة. | `board_provider.dart:93` |
| M-04 | Emergency contacts are kept in the screen's state and vanish when it closes. The user model holds one contact in two flat fields. Fix: a contacts list in the profile, saved through the repository. | جهات الطوارئ محفوظة في حالة الشاشة وتختفي عند إغلاقها، ونموذج المستخدم يحوي جهة واحدة في حقلين. الحل: قائمة جهات في الملف الشخصي تُحفظ عبر المستودع. | `safety_screens.dart:644-760` |
| M-05 | The same account menu exists three times: the Account tab, the profile screen and settings. Fix: one menu component with a single source of items. | قائمة الحساب نفسها مكررة ثلاث مرات: تبويب الحساب وشاشة الملف والإعدادات. الحل: مكوّن قائمة واحد بمصدر عناصر واحد. | `main_nav_shell.dart:805-1060`, `account_extra_screens.dart:17-400`, `settings_screen.dart` |
| M-06 | Several files hold many screens: `main_nav_shell.dart` (1,383 lines, three tabs built inline), `driver_rides_management_screens.dart` (1,106, four screens), `account_extra_screens.dart` (1,039, five screens). Private helpers such as `_buildRow` are repeated in nine files. Fix: one screen per file and shared row, section and card widgets. | عدة ملفات تضم شاشات كثيرة: `main_nav_shell.dart` (1,383 سطرًا وثلاثة تبويبات داخله)، و`driver_rides_management_screens.dart` (1,106 وأربع شاشات)، و`account_extra_screens.dart` (1,039 وخمس شاشات). ودوال خاصة مثل `_buildRow` مكررة في تسعة ملفات. الحل: شاشة واحدة لكل ملف ومكوّنات مشتركة للصف والقسم والبطاقة. | `lib/screens` |
| M-07 | Governorate and city lists are defined in six files with different contents. The national-ID map omits several governorate codes. Fix: one locations source served by the backend, cached on the device. | قوائم المحافظات والمدن معرَّفة في ستة ملفات بمحتوى مختلف، وخريطة الرقم القومي ينقصها عدد من رموز المحافظات. الحل: مصدر واحد للمواقع يقدمه الخادم ويُخزَّن مؤقتًا على الجهاز. | `mock_data.dart`, `app_strings.dart`, `profile_setup_screen.dart`, `id_verification_screen.dart`, `admin_provider.dart`, `admin_dashboard_screen.dart` |
| M-08 | Screens contain 403 literal `Color(0x…)` values next to `AppColors`. The theme background is sand while most screens set white. Fix: extend the token set and replace literals. | الشاشات تحوي 403 قيمة لونية مباشرة `Color(0x…)` بجانب `AppColors`، وخلفية السمة رملية بينما معظم الشاشات تضبط الأبيض. الحل: توسيع الرموز اللونية واستبدال القيم المباشرة. | `lib/screens` |
| M-09 | System screens are Arabic only. The session-expired button defaults to an empty handler. Fix: localize them and require the callback. | شاشات النظام بالعربية فقط، وزر انتهاء الجلسة ينفّذ افتراضيًا دالة فارغة. الحل: ترجمتها وجعل الدالة إلزامية. | `system_screens.dart:220` |
| M-10 | The notification centre is a fixed list of three items that cannot be opened or marked read. Notification preferences are saved on the device only. Fix: a notification model, read state, navigation to the related item, and preferences synced to the server. | مركز الإشعارات قائمة ثابتة من ثلاثة عناصر لا تُفتح ولا تُعلَّم كمقروءة، وتفضيلات الإشعارات محفوظة على الجهاز فقط. الحل: نموذج للإشعار، وحالة قراءة، وانتقال للعنصر المرتبط، ومزامنة التفضيلات مع الخادم. | `account_extra_screens.dart:923-1040`, `settings_provider.dart` |
| M-11 | Admin filters compare Arabic status text. Tables have no pagination. KPIs are constants chosen by period name. The audit log lives in memory. `AdminProvider` is also loaded into the customer app. Fix: status codes, paged server queries, server-computed KPIs, a persistent audit log, and removing the admin provider from `main.dart`. | فلاتر الإدارة تقارن نصوص الحالة العربية. الجداول بلا تقسيم صفحات. المؤشرات ثوابت تُختار باسم الفترة. سجل التدقيق في الذاكرة. و`AdminProvider` محمَّل أيضًا في تطبيق العملاء. الحل: رموز للحالات، واستعلامات مقسَّمة من الخادم، ومؤشرات يحسبها الخادم، وسجل تدقيق دائم، وإزالة مزوّد الإدارة من `main.dart`. | `admin_*_screen.dart`, `admin_provider.dart:297-330`, `main.dart:34` |
| M-12 | Unused code: `BackendReadinessScreen`, `ApiResponse`, and 14 provider and API-client members that no screen calls, including `approveIdVerification`, `updateParcelStatus` and `toggleDarkMode`. A dark-mode preference is saved but no dark theme exists. Fix: remove or connect each one. | كود غير مستخدم: `BackendReadinessScreen` و`ApiResponse` و14 عضوًا في المزوّدات وعميل الواجهة البرمجية لا تستدعيها أي شاشة، منها `approveIdVerification` و`updateParcelStatus` و`toggleDarkMode`. وتفضيل الوضع الداكن يُحفظ دون وجود سمة داكنة. الحل: حذف كل عنصر أو ربطه. | `lib/state`, `lib/data/api` |
| M-13 | The 60 tests are mostly render and smoke tests tied to mock text. None covers a flow through a repository. Fix: unit tests for repositories and providers, and flow tests for sign-in, booking and parcel handover. | الاختبارات الستون معظمها اختبارات عرض مرتبطة بالنصوص التجريبية، ولا يغطي أيٌّ منها مسارًا عبر مستودع. الحل: اختبارات وحدة للمستودعات والمزوّدات، واختبارات مسار للدخول والحجز وتسليم الطرد. | `test/` |
| M-14 | The API base URL defaults to the production host in code. There are no environments. The client header says `v1.2` while the app version is `1.0.0`. Fix: dev, staging and production configuration supplied at build time, and a header built from the real version. | عنوان الخادم الافتراضي في الكود هو عنوان الإنتاج، ولا توجد بيئات. وترويسة العميل تذكر `v1.2` بينما إصدار التطبيق `1.0.0`. الحل: إعدادات للتطوير والاختبار والإنتاج تُمرَّر وقت البناء، وترويسة مبنية من الإصدار الفعلي. | `api_endpoints.dart:6-13`, `mashwar_api_client.dart:100` |
| M-15 | The client user model carries the national ID number and document image fields and serializes them. The parcel model carries the handover code. Admin items hold the unmasked phone. Fix: the client receives only masked values and status; sensitive data stays on the server. | نموذج المستخدم في العميل يحمل الرقم القومي وحقول صور المستندات ويحوّلها إلى JSON. ونموذج الطرد يحمل كود التسليم. وعناصر الإدارة تحوي رقم الهاتف غير المحجوب. الحل: يستقبل العميل قيمًا محجوبة وحالة فقط، وتبقى البيانات الحساسة على الخادم. | `user_model.dart:38-41`, `parcel_model.dart:27`, `admin_provider.dart:94` |
| M-16 | The parcel model has no dimensions, type, pickup or delivery address, time window or tracking number. `currentTrackingParcel` reads the first list item and would throw on an empty list. Fix: complete the model and select parcels by identifier. | نموذج الطرد بلا أبعاد أو نوع أو عنوان استلام وتسليم أو نافذة زمنية أو رقم تتبع. و`currentTrackingParcel` يقرأ أول عنصر في القائمة وسيتوقف إذا كانت فارغة. الحل: استكمال النموذج واختيار الطرد بالمعرّف. | `parcel_model.dart`, `parcels_provider.dart:9` |
| M-17 | The rating screen offers tips of 0, 10, 20 or 50 EGP that go nowhere. The booking review has a simulated price increase of 10 EGP. Fix: specify tips as a wallet transaction (A-06) and drive price changes from the server. | شاشة التقييم تعرض إكرامية 0 أو 10 أو 20 أو 50 جنيهًا لا تذهب إلى أي مكان، ومراجعة الحجز فيها زيادة سعر مُحاكاة بمقدار 10 جنيهات. الحل: توصيف الإكرامية كحركة محفظة (A-06) وربط تغيّر السعر بالخادم. | `rate_trip_screen.dart:226-229`, `booking_review_screen.dart:37` |
| M-18 | The cancellation sheet collects a reason and shows no policy or fee. Fix: per D-10, show the fee that applies to this service type before the user confirms. | نافذة الإلغاء تجمع السبب ولا تعرض السياسة أو الرسوم. الحل: وفق D-10 عرض الرسوم المطبقة على نوع الخدمة قبل تأكيد المستخدم. | `cancellation_sheet.dart` |

### 6.4 Low | المنخفضة

| ID | Finding and fix (EN) | الملاحظة والحل (AR) | Where · الموقع |
|---|---|---|---|
| L-01 | `node_modules` is committed (1,007 files) and not ignored. Fix: remove it from git and add it to `.gitignore`. | مجلد `node_modules` مرفوع إلى المستودع (1,007 ملفات) وغير مُستثنى. الحل: حذفه من git وإضافته إلى `.gitignore`. | repo root |
| L-02 | `package.json`, `.npmrc`, `public/assets/aistudio` and `.idx` are scaffolding from a hosted preview tool. The `build` script deletes `pubspec.lock`, which is committed. Fix: remove what the team does not use and keep the lock file. | الملفات `package.json` و`.npmrc` و`public/assets/aistudio` و`.idx` من مخلفات أداة معاينة مستضافة، وسكربت `build` يحذف `pubspec.lock` وهو مرفوع إلى المستودع. الحل: حذف ما لا يستخدمه الفريق والإبقاء على ملف القفل. | repo root |
| L-03 | A `windows` platform folder exists though Windows is not a target. Fix: remove it. | يوجد مجلد منصة `windows` رغم أن Windows ليس هدفًا. الحل: حذفه. | `windows/` |
| L-04 | The web manifest still has template values ("A new Flutter project", colour `#0175C2`). Fix: update if the admin panel remains a web build (A-01). | ملف تعريف الويب ما زال بقيم القالب ("A new Flutter project" واللون `#0175C2`). الحل: تحديثه إذا بقيت لوحة الإدارة نسخة ويب (A-01). | `web/manifest.json`, `web/index.html` |
| L-05 | The Android application ID is `com.mashwar.app.mashwar`. Fix: settle the final ID before the first store upload, because it cannot change afterwards. | معرّف تطبيق Android هو `com.mashwar.app.mashwar`. الحل: اعتماد المعرّف النهائي قبل أول رفع للمتجر لأنه لا يتغير بعده. | `android/app/build.gradle.kts:19` |
| L-06 | The README badges state 52 passing tests and zero analyzer issues. The repository has 60 tests and no CI to back either claim. Fix: add CI and generate the badges from it. | شارات README تذكر 52 اختبارًا ناجحًا وصفر ملاحظات تحليل، بينما المستودع يحوي 60 اختبارًا ولا يوجد CI يدعم أيًّا من الادعاءين. الحل: إضافة CI وتوليد الشارات منه. | `README.md` |
| L-07 | `analysis_options.yaml` silences `deprecated_member_use`, and `flutter_lints` is on version 3. Fix: update the lints and remove the suppression. | ملف `analysis_options.yaml` يُسكت تحذير `deprecated_member_use`، و`flutter_lints` على الإصدار 3. الحل: تحديث القواعد وإزالة الإسكات. | `analysis_options.yaml`, `pubspec.yaml` |
| L-08 | The splash screen waits a fixed 1.8 seconds and its loading text is Arabic only. Fix: wait for session restore instead and localize the text. | شاشة البداية تنتظر 1.8 ثانية ثابتة ونص التحميل فيها بالعربية فقط. الحل: انتظار استعادة الجلسة بدلًا من ذلك وترجمة النص. | `splash_screen.dart:19`, `:40` |
| L-09 | `RescheduleRideScreen`, a driver screen, is defined in the board file. Fix: move it to the driver folder. | شاشة السائق `RescheduleRideScreen` معرَّفة في ملف اللوحة. الحل: نقلها إلى مجلد السائق. | `board_extra_screens.dart:807` |
| L-10 | Support numbers (`19884`, `+201000019999`) and the legal texts, including the licence wording, are placeholders shown as real. Fix: replace with reviewed content served from the backend. | أرقام الدعم (`19884` و`+201000019999`) والنصوص القانونية، ومنها صياغة الترخيص، قيم مؤقتة معروضة كأنها حقيقية. الحل: استبدالها بمحتوى مُراجَع يقدمه الخادم. | `account_extra_screens.dart:689`, `:709`, `legal_and_backend_screens.dart` |
| L-11 | The repository is named Meshwar while the code, package and branding use Mashwar. Fix: choose one spelling for public material. | اسم المستودع Meshwar بينما الكود والحزمة والهوية تستخدم Mashwar. الحل: اعتماد تهجئة واحدة للمواد المنشورة. | repo |
| L-12 | The publish-ride stopover button toggles the fixed city `طنطا`. Fix: use the city picker. | زر محطة التوقف في نشر الرحلة يبدّل المدينة الثابتة «طنطا». الحل: استخدام منتقي المدن. | `publish_ride_screen.dart:319` |

---

## 7. State coverage matrix | مصفوفة تغطية الحالات

Based on a static search for progress indicators, loading flags, empty-state and error-state builders in each module. "Simulated" means a timed delay stands in for a real request.

تستند المصفوفة إلى بحث ساكن عن مؤشرات التحميل وأعلامه وواجهات الفراغ والخطأ في كل وحدة. «مُحاكى» تعني أن تأخيرًا زمنيًا يحل محل طلب حقيقي.

| Module · الوحدة | Loading · تحميل | Empty · فارغ | Error · خطأ | Offline · انقطاع | Validation · تحقق |
|---|---|---|---|---|---|
| Sign-in · الدخول | Simulated · مُحاكى | n/a | Partial · جزئي | None · لا يوجد | Manual · يدوي |
| Home · الرئيسية | None | None | None | None | n/a |
| Search · البحث | None | Yes · نعم | Built, unreachable · مبني وغير موصول | Built, unreachable | n/a |
| Ride details · تفاصيل الرحلة | None | n/a | Via simulation menu · عبر قائمة المحاكاة | None | n/a |
| Booking · الحجز | Simulated | n/a | None | None | Seats only · المقاعد فقط |
| Trip and rating · الرحلة والتقييم | Simulated | n/a | None | None | None |
| Parcels · الطرود | None | None | None | None | Weight and value limits only · حدّا الوزن والقيمة فقط |
| Board · اللوحة | None | Yes | None | None | Required fields and price · الحقول الإلزامية والسعر |
| Alerts · التنبيهات | None | Yes | None | None | Different cities only · اختلاف المدينتين فقط |
| Chat · المحادثة | None | None | None | None | None |
| Driver · السائق | Simulated capture · التقاط مُحاكى | Yes | None | None | Price range only · نطاق السعر فقط |
| Wallet · المحفظة | None | None | None | None | Withdraw amount only · مبلغ السحب فقط |
| Safety · السلامة | None | None | None | None | None |
| Account · الحساب | Simulated | None | None | None | Partial |
| Admin · الإدارة | Login only · الدخول فقط | Partial | Login only | None | Reason required on overrides · اشتراط السبب عند التعديل اليدوي |

---

## 8. Backend-integration blockers | عوائق الربط مع الخادم

| # | Blocker (EN) | العائق (AR) | Findings · الملاحظات |
|---|---|---|---|
| B-1 | No repository boundary: providers and screens read mock data directly. | لا يوجد حد فاصل للمستودعات: المزوّدات والشاشات تقرأ البيانات التجريبية مباشرة. | C-01, H-19 |
| B-2 | Models cannot map to tables: no identifiers, string dates, string statuses, missing entities. | النماذج لا تقبل الربط بالجداول: بلا معرّفات، وتواريخ وحالات نصية، وكيانات ناقصة. | H-02, M-02, M-16 |
| B-3 | Display text is used as data, so the API cannot be language-neutral. | نص العرض مستخدم كبيانات، فلا يمكن أن تكون الواجهة البرمجية محايدة لغويًا. | H-03, M-07, M-11 |
| B-4 | No session: no token storage, no restore, no guard, no reset on logout. | لا توجد جلسة: لا تخزين للرموز ولا استعادة ولا حماية ولا تصفير عند الخروج. | C-02, H-15, H-20 |
| B-5 | State changes that belong to the server are made in the client. | تغييرات حالة تخص الخادم تُنفَّذ داخل العميل. | C-05, C-10, H-01, H-05 |
| B-6 | No shared handling for loading, error and offline. | لا توجد معالجة مشتركة للتحميل والخطأ والانقطاع. | H-12 |
| B-7 | Business rules are literals in screens instead of server configuration. | قواعد العمل قيم مكتوبة في الشاشات بدل إعدادات الخادم. | H-11, M-18 |
| B-8 | The release build has no network permission and no environment configuration. | نسخة الإصدار بلا صلاحية شبكة وبلا إعدادات بيئات. | C-06, M-14 |
| B-9 | No device capabilities: camera, files, location, dialler, sharing, push. | لا توجد قدرات جهاز: كاميرا، ملفات، موقع، اتصال، مشاركة، إشعارات. | C-08, H-07, H-08 |
| B-10 | Admin identity and permissions exist only in the client. | هوية الإدارة وصلاحياتها موجودة في العميل فقط. | C-09 |

---

## 9. Branding pack and design references | حزمة الهوية والمراجع التصميمية

### 9.1 Branding pack | حزمة الهوية

The pack contains ten files: the primary logo and a white version (SVG), the pin icon in dark and light (SVG) with a 512 px PNG, the app icon (SVG, 512 px and 1024 px PNG), and the logo on white and on navy (PNG).

تحتوي الحزمة على عشرة ملفات: الشعار الأساسي ونسخة بيضاء (SVG)، وأيقونة الدبوس بنسختين داكنة وفاتحة (SVG) مع نسخة PNG بمقاس 512، وأيقونة التطبيق (SVG ونسختا PNG بمقاس 512 و1024)، والشعار على خلفية بيضاء وعلى خلفية كحلية (PNG).

| Check · الفحص | Result (EN) | النتيجة (AR) |
|---|---|---|
| Colours · الألوان | `#0F2A43`, `#1B7F79` and `#F5A524` in the pack are identical to `AppColors.navy`, `teal` and `gold`. | الألوان `#0F2A43` و`#1B7F79` و`#F5A524` في الحزمة مطابقة لـ`AppColors.navy` و`teal` و`gold`. |
| Logo · الشعار | Matches. `MashwarPinIcon` in `brand_logo.dart` draws the same circle and path as the pack's pin SVG. | مطابق. المكوّن `MashwarPinIcon` في `brand_logo.dart` يرسم الدائرة والمسار نفسيهما في ملف SVG للدبوس. |
| App icon · أيقونة التطبيق | Not applied. Both platforms ship the default Flutter icon (H-16). | غير مطبَّقة، والمنصتان تستخدمان أيقونة Flutter الافتراضية (H-16). |
| Font · الخط | Cairo in both. The logo SVGs use live text and import Cairo from the web, so no font file comes with the pack. | Cairo في الاثنين. ملفات SVG للشعار تستخدم نصًا حيًّا وتستورد Cairo من الويب، فلا يوجد ملف خط مرفق بالحزمة. |

### 9.2 Reference boards compared with the app | مقارنة اللوحات المرجعية بالتطبيق

Per D-06 these are additions to the current design, not replacements.

وفق D-06 هذه إضافات على التصميم الحالي وليست بدائل له.

| Area · المجال | In the boards (EN) | In the app today (EN) | Suggested upgrade (EN) | الترقية المقترحة (AR) |
|---|---|---|---|---|
| Home · الرئيسية | Two large service cards (ride, parcel) under a greeting, then recent trips | Greeting, a seats/parcels toggle and the search form | Add the two service cards above the existing search form and keep the form | إضافة بطاقتي الخدمة فوق نموذج البحث الحالي مع الإبقاء عليه |
| Results · النتائج | Driver photo, rating with count, car model, verified mark, ladies-only tag | Name, rating, car, badges, no photo or rating count | Add avatar and rating count to the card | إضافة صورة السائق وعدد التقييمات إلى البطاقة |
| Ride details · التفاصيل | Plate chip, co-passenger avatars, price on the booking button | Map, co-passengers, trust card | Add the plate chip and show the price on the button | إضافة شريحة رقم اللوحة وإظهار السعر على زر الحجز |
| Send parcel · إرسال طرد | Three-step form, parcel type, length, width and height, delivery window | One form with size, weight and value | Split into three steps and add type and dimensions | تقسيم النموذج إلى ثلاث خطوات وإضافة النوع والأبعاد |
| Driver home · واجهة السائق | Dashboard with earnings, trips, rating, availability switch and request counters | Driver rides list with an earnings sheet | Add a driver dashboard as the entry to the existing driver screens | إضافة لوحة للسائق كمدخل لشاشات السائق الحالية |
| Tracking · التتبع | Tracking number (`MSH-7842`), three-step timeline, handover code | Five-step timeline, code dialog | Add the tracking number and keep the five steps | إضافة رقم التتبع والإبقاء على الخطوات الخمس |
| Safety · السلامة | One safety centre: emergency call, live sharing, support, guidelines, report | Separate sheets and screens | Add a safety centre page that links the existing parts | إضافة صفحة مركز سلامة تربط الأجزاء الموجودة |
| Navigation · التنقل | Four or five tabs, one variant with a central action button | Five tabs | Keep five tabs. The central button is optional. | الإبقاء على خمسة تبويبات، والزر المركزي اختياري |

One conflict to note: the boards show a four-digit handover code, while D-11 makes codes alphanumeric. The decision takes precedence.

تعارض واحد جدير بالذكر: اللوحات تعرض كود تسليم من أربعة أرقام بينما القرار D-11 يجعل الأكواد حروفًا وأرقامًا، والقرار هو المعتمد.

---

## 10. Proposed packages | الحزم المقترحة

Proposals for checkpoint 2, each tied to a finding. Versions are not listed because they could not be checked from the audit workspace: add each with `flutter pub add` so the resolver picks a release compatible with the project's SDK, then run the test suite.

مقترحات للمرحلة 2، كل منها مرتبط بملاحظة. لم تُذكر الإصدارات لتعذر التحقق منها من بيئة التدقيق: تُضاف كل حزمة بأمر `flutter pub add` ليختار المحلِّل إصدارًا متوافقًا مع SDK المشروع، ثم تُشغَّل الاختبارات.

| Purpose (EN) | الغرض (AR) | Package · الحزمة | Findings |
|---|---|---|---|
| HTTP client with interceptors | عميل HTTP مع معترضات | `dio` | C-01 |
| Secure token storage | تخزين آمن للرموز | `flutter_secure_storage` | C-02 |
| Google Sign-In | الدخول بحساب Google | `google_sign_in` | H-06 |
| Camera and gallery for ID, licence and receipts | الكاميرا والمعرض للهوية والرخصة والإيصالات | `image_picker` | C-08, C-05 |
| Dialler, WhatsApp and map apps | الاتصال وواتساب وتطبيقات الخرائط | `url_launcher` | C-03, H-08 |
| Native share sheet | نافذة المشاركة الأصلية | `share_plus` | H-08 |
| Connectivity detection | اكتشاف حالة الاتصال | `connectivity_plus` | H-12 |
| Skeleton loading | هياكل التحميل | `skeletonizer` or `shimmer` | H-12 |
| Cached images with placeholders | صور مخزَّنة مؤقتًا مع بدائل | `cached_network_image` | 9.2 |
| Launcher icons and native splash (dev) | أيقونات التطبيق وشاشة البداية (تطوير) | `flutter_launcher_icons`, `flutter_native_splash` | H-16 |
| Route table, guards, deep links | جدول المسارات والحماية والروابط العميقة | `go_router` | H-20 |
| Runtime permissions and location | الأذونات والموقع | `permission_handler`, `geolocator` | H-07 |
| Dates, numbers and currency | التواريخ والأرقام والعملة | `intl` (already declared · معلنة مسبقًا) | H-04 |

Push notifications and real-time messaging depend on the backend recommendation in checkpoint 3 and are chosen there. `google_fonts` can be dropped once Cairo is bundled (H-17).

الإشعارات الفورية والمراسلة اللحظية تعتمد على توصية الخادم في المرحلة 3 وتُختار هناك. ويمكن الاستغناء عن `google_fonts` بعد تضمين خط Cairo (H-17).

---

## 11. Recommended fix order | ترتيب المعالجة المقترح

| Step · الخطوة | Work (EN) | العمل (AR) | Findings |
|---|---|---|---|
| 0 | Repository hygiene and CI that runs analyze and tests on every push | نظافة المستودع و CI يشغّل التحليل والاختبارات عند كل رفع | L-01 to L-07 |
| 1 | Data foundation: typed models, repository interfaces, mock implementations, async-state type, environment configuration | أساس البيانات: نماذج مُحدَّدة الأنواع، واجهات مستودعات، تنفيذ تجريبي، نوع الحالة غير المتزامنة، إعدادات البيئات | C-01, C-04, H-02, H-19, M-14 |
| 2 | App shell: route table, session restore, auth guard, onboarding sequence, logout reset | هيكل التطبيق: جدول المسارات، استعادة الجلسة، حماية الدخول، تسلسل التهيئة، تصفير الخروج | C-02, H-07, H-15, H-20 |
| 3 | Design-system pass: bundled font, tokens, shared states, accessibility, branding assets, ARB localization | مرور على نظام التصميم: الخط المضمَّن، الرموز، الحالات المشتركة، إمكانية الوصول، أصول الهوية، الترجمة بملفات ARB | C-06, H-03, H-12, H-16, H-17, H-18, M-08 |
| 4 | Safety first, then the passenger journey: real calls and sharing, search, date picker, booking entity, rating | السلامة أولًا ثم رحلة الراكب: اتصال ومشاركة فعليان، البحث، منتقي التاريخ، كيان الحجز، التقييم | C-03, C-07, H-04, H-05, H-08, H-13 |
| 5 | Parcels and board: validation, handover codes, offers as entities | الطرود واللوحة: التحقق، أكواد التسليم، العروض ككيانات | C-10, H-10, M-01 to M-03, M-16 |
| 6 | Driver: real document capture, verification gate, requests from data, ladies-only rules | السائق: التقاط حقيقي للمستندات، قيد التوثيق، الطلبات من البيانات، قواعد خدمة السيدات | C-08, H-14 |
| 7 | Wallet and payments: ledger display, top-up with receipt, configuration-driven fees | المحفظة والدفع: عرض كشف الحركات، الشحن بإيصال، رسوم من الإعدادات | C-05, H-11, M-17, M-18 |
| 8 | Admin panel: sign-in, server roles, status codes, paging | لوحة الإدارة: الدخول، الأدوار من الخادم، رموز الحالات، تقسيم الصفحات | C-09, M-11 |
| 9 | Remove simulation controls, delete dead code, split large files, extend tests | إزالة أزرار المحاكاة، حذف الكود غير المستخدم، تقسيم الملفات الكبيرة، توسيع الاختبارات | H-01, M-05, M-06, M-12, M-13 |

Steps 1 to 3 unblock everything else and can be shared between the three developers (D-14). Steps 4 to 8 can then run in parallel by feature.

الخطوات من 1 إلى 3 تفتح الطريق لكل ما بعدها ويمكن توزيعها على المطورين الثلاثة (D-14)، ثم تُنفَّذ الخطوات من 4 إلى 8 بالتوازي حسب الميزة.

---

## 12. Verification status and limits | حالة التحقق وحدوده

| Item · البند | Status (EN) | الحالة (AR) |
|---|---|---|
| Source review · مراجعة الكود | All 84 Dart files were covered by scripted extraction of handlers, navigation, forms and state. Models, the API layer, six of the seven providers, the theme files and both entry points were read in full; screen logic was read wherever a finding depends on it. The 12 test files were inventoried by test name. | شملت المراجعة ملفات Dart الـ84 كلها عبر استخراج آلي للمعالجات والتنقل والنماذج والحالة. وقُرئت بالكامل نماذج البيانات وطبقة الواجهة البرمجية وستة من المزوّدات السبعة وملفات السمة ونقطتا الدخول، وقُرئ منطق الشاشات حيثما اعتمدت عليه ملاحظة. وجُردت ملفات الاختبار الـ12 بأسماء الاختبارات. |
| Counts and line references · الأعداد والإحالات | Produced by scripted searches on the audited commit and re-checked before publishing. | استُخرجت ببحث آلي على الإصدار المُدقَّق وأُعيد فحصها قبل النشر. |
| Contrast ratios · نسب التباين | Computed with the WCAG relative-luminance formula from the colour values in code. | حُسبت بمعادلة السطوع النسبي في WCAG من قيم الألوان في الكود. |
| `flutter analyze`, `flutter test` | **Not run.** The Flutter SDK could not be installed in the audit workspace. | **لم تُشغَّل.** تعذر تثبيت Flutter SDK في بيئة التدقيق. |
| Visual review on a device · المراجعة البصرية على جهاز | **Not done.** Layout, overflow, RTL rendering and the font fallback in H-17 need a device or emulator. | **لم تتم.** التخطيط وتجاوز الحدود وعرض RTL وسلوك الخط في H-17 تحتاج جهازًا أو محاكيًا. |
| Runtime behaviour · السلوك وقت التشغيل | Inferred from code paths. Findings that depend on it are marked "expected" or "needs confirmation". | مُستنتَج من مسارات الكود، والملاحظات المعتمدة عليه مُعلَّمة بعبارة «متوقع» أو «يحتاج تأكيدًا». |

**First action for Claude Code | أول إجراء لـ Claude Code**

Run `flutter pub get`, `flutter analyze` and `flutter test` on the audited commit and record the results here, so that later changes are measured against a known baseline.

تشغيل `flutter pub get` و`flutter analyze` و`flutter test` على الإصدار المُدقَّق وتسجيل النتائج هنا، لتُقاس التعديلات اللاحقة على أساس معروف.
