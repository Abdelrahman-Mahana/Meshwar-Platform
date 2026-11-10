# مشوار (MASHWAR) — تطبيق السفر التشاركي ونقل الطرود

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Tests-52%2F52%20Passing-success" alt="Tests" />
  <img src="https://img.shields.io/badge/Analysis-0%20Issues-brightgreen" alt="Analyzer" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
</p>

<p align="center">
  <b>"رحلتك وطردك في نفس الطريق"</b><br/>
  المنصة المصرية الأولى المتكاملة للسفر التشاركي بين المحافظات ونقل الطرود السريع عبر المسافرين.
</p>

---

## 🌟 نظرة عامة (Overview)

يعالج تطبيق **مشوار** الفجوة الحقيقية في منظومة النقل والسفر المصري بين المحافظات، من خلال الجمع بين:
1. **السفر التشاركي (Inter-city Carpooling):** توفير مقاعد مريحة وعادلة التكلفة في سيارات خاصة مع سائقين موثقين، لتقاسم تكاليف البنزين والكارتات، وحل أزمة السفر للطلاب والموظفين.
2. **شحن الطرود الذكي (Parcel Crowd-Shipping):** توصيل الطرود بين المحافظات خلال ساعات في نفس اليوم مع المسافرين، بالاعتماد على كود تحقق رقمي آمن (OTP من 4 أرقام).
3. **لوحة الطلبات التفاعلية (The Community Board):** إمكانية نشر الراكب لطلبه وتلقي عروض أسعار مباشرة من السائقين مع التفاوض المرن.

---

## 🚀 المميزات الرئيسية (Key Features)

### 🚗 للسفر التشاركي (Carpooling)
- **بحث سريع بمسار مباشر:** تحديد محافظات ومدن الانطلاق والوصول وتوقيت السفر.
- **رحلات مخصصة للسيدات (Ladies Only):** لتوفير أقصى درجات الخصوصية والأمان.
- **معرفة من يسافر معك (Co-Passengers Preview):** الشفافية الكاملة لمعرفة الركاب المحجوز لهم في نفس الرحلة قبل الحجز.
- **خريطة تفاعلية مزدوجة:**
  - **منظور الراكب:** يوضح نقطة الركوب، مسافة المشي، وإرشادات الانتظار.
  - **منظور السائق:** يوضح منطقة الركن الآمن ومسار الطريق السريع.
  - فتح المسار مباشرة في **Google Maps** و **Waze**.

### 📦 لشحن ونقل الطرود (Parcel Crowd-Shipping)
- **تسليم واستلام في نفس اليوم:** نقل الوثائق، الشنط، والأجهزة بين المحافظات بسرعة فائقة.
- **كود التسليم الرقمي (4-Digit Handover OTP):** لا يمكن إتمام التسليم إلا بمطابقة الكود بين السائق والمستلم لمنع أي احتيال.
- **تتبع حي:** تتبع مسار الطرد لحظياً ومشاركة رابط التتبع عبر WhatsApp.
- **قائمة الممنوعات المصورة:** قائمة واضحة لحماية السائق والركاب قانونياً.

### 📢 لوحة الإعلانات والطلبات (Community Board)
- إمكانية نشر المسافر إعلاناً بميزانيته وموعده المطلوب.
- تقديم عروض مباشرة من السائقين (`Make Offer`) والتفاوض السلس بنقرة واحدة.

### 🛡️ الأمان والتوثيق (Trust & Safety)
- **توثيق الرقم القومي ورخصة القيادة:** تدقيق ومراجعة بيانات السائقين عبر لوحة التحكم.
- **زر الطوارئ ومركز السلامة (SOS Safety Hub):** مشاركة خط السير الحي والاتصال الفوري بجهات الطوارئ.
- **تقييم ومراجعات متبادلة:** بعد كل رحلة لتعزيز الموثوقية والمجتمع الآمن.

### 🔐 تجربة الدخول الموحدة (Modern Dual Auth)
- **المتابعة برقم الموبايل:** مع كود تأكيد SMS وشارة علم مصر `🇪🇬 +20` وفلترة الرموز وعلامات الترقيم.
- **الدخول بـ Google بنقرة واحدة (1-Tap Google Sign-In):** اختيار الحساب فوراً وتعبئة الاسم والإيميل تلقائياً.
- **المتابعة بالبريد الإلكتروني:** إرسال كود التحقق (Email OTP) وإمكانية التبديل السلس بين الهاتف والإيميل في أي وقت.

### 🖥️ لوحة تحكم الإدارة الكاملة (MASHWAR Admin Dashboard)
- تطبيق ويب متكامل لمراجعة توثيق السائقين، مراقبة الرحلات والطرود، حل النزاعات، إدارة الحسابات، وتتبع الإحصائيات التشغيلية والمالية.

---

## 🏗️ الهيكلية المعمارية (Architecture)

تم بناء المشروع باتباع مبادئ **Clean Layered Architecture** لضمان فصل المسؤوليات وسهولة الصيانة والاختبار:

```text
lib/
├── core/                  # Constants, Theme, Design Tokens, Reusable Core Widgets
│   ├── constants/         # AppColors, AppTypography, AppDimens
│   ├── theme/             # AppTheme (Uber-style minimal design)
│   └── widgets/           # MashwarButton, MashwarTextField, BrandLogo, AlertBanner
├── data/                  # Models & Mock Repository
│   ├── models/            # UserModel, RideModel, ParcelModel, BoardAdModel
│   └── mock_data.dart     # Comprehensive Egyptian scenarios & seed data
├── state/                 # State Management (Provider)
│   ├── auth_provider.dart
│   ├── rides_provider.dart
│   ├── parcels_provider.dart
│   ├── board_provider.dart
│   ├── admin_provider.dart
│   └── settings_provider.dart
├── screens/               # Feature-based Screen Modules
│   ├── auth/              # Welcome, Phone, Email, OTP, ProfileSetup, ID Verification
│   ├── home/              # Main Ride & Parcel Search
│   ├── ride_details/      # Route Map, Co-passengers, Driver Trust Card
│   ├── parcel/            # Send Parcel, Tracking, Pickup Code Dialog
│   ├── board/             # Ad Board, Post Ad, Make Offer
│   ├── admin/             # Full Web Admin Control Panel & Audit Logs
│   ├── settings/          # Uber-style Sectioned Settings
│   └── trip/              # Active Trip, SOS Safety Hub, Rating
├── admin_main.dart        # Entrypoint for Admin Web App
└── main.dart              # Entrypoint for Passenger/Driver App
```

---

## 🎨 الهوية البصرية (Design System)

- **أسلوب أوبر ونقاء التصميم (Uber Minimal Standard):** أسطح بيضاء نقية (`#FFFFFF`) وحيادية ناعمة (`#F8F9FA`)، إطارات خفيفة (0.8px)، بدون بهرجة أو إيموجي مشتتة.
- **لوحة الألوان:**
  - 🔵 **كحلي ليلي (Night Navy):** `#0F2A43`
  - 🟢 **فيروزي (Teal):** `#1B7F79`
  - 🟡 **ذهبي تمييز (Golden Amber):** `#F5A524`
- **الخط:** خط **Cairo** المريح والمقروء بوضوح في كافة واجهات اللغة العربية مع دعم كامل للإنجليزية (RTL / LTR).

---

## 🚦 تشغيل المشروع (Getting Started)

### المتطلبات الأساسية
- Flutter SDK (3.x أو أحدث)
- متصفح ويب (Chrome أو Edge) أو محاكي Android / iOS

### 1. تثبيت الحزم
```bash
flutter pub get
```

### 2. تشغيل التطبيق الأساسي (الراكب والسائق)
```bash
flutter run -d web-server --web-port 8080
```
افتح المتصفح على: [http://localhost:8080](http://localhost:8080)

### 3. تشغيل لوحة تحكم الإدارة (Admin Panel)
```bash
flutter run -t lib/admin_main.dart -d web-server --web-port 8081
```
افتح المتصفح على: [http://localhost:8081](http://localhost:8081)

---

## 🧪 الاختبارات والجودة (Testing & Quality)

المشروع يحتوي على تغطية اختبارات شاملة لوظائف الأعمال، واجهات المستخدم، وتدفقات الأمان:

```bash
# تشغيل جميع الاختبارات الآلية (52 اختبار)
flutter test

# فحص جودة الكود والتحليل الساكن (0 أخطاء و 0 تحذيرات)
flutter analyze
```

---

## 📄 الترخيص (License)

هذا المشروع مرخص تحت رخصة **MIT**.
جميع الحقوق محفوظة © 2026 مشوار (MASHWAR).
