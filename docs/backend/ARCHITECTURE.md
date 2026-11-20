# MASHWAR Platform — Backend & Systems Architecture
## Production Architecture, Service Boundaries, and Integration Specification

### 1. Architectural Philosophy & Layered Separation
MASHWAR utilizes a strict **Clean Layered Architecture** separating user interaction, business logic, domain contracts, and cloud data sources:

```
┌────────────────────────────────────────────────────────┐
│           Presentation Layer (UI & Screens)            │
│   Flutter Mobile (Android/iOS) + Flutter Web (Customer) │
│   Separate Admin Web Dashboard (`lib/admin_main.dart`)  │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│      Application & State Layer (Provider ViewModels)   │
│   RidesProvider · BoardProvider · ParcelsProvider      │
│   AuthProvider · SettingsProvider · AdminProvider      │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│       Domain Layer (Contracts & Abstract Repositories) │
│   IAuthRepository · IRidesRepository · IBoardRepository│
│   IParcelsRepository · IMapsRepository · IChatRepository│
│   IWalletRepository · Business Validation Rules        │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│        Data Access Layer (Repository Implementations)  │
│   AuthRepositoryImpl · RidesRepositoryImpl · etc.      │
│   AppRepositories Service Locator Registry             │
└─────────────┬───────────────────────────┬──────────────┘
              │                           │
┌─────────────▼───────────────┐ ┌─────────▼──────────────┐
│  Cloud Infrastructure       │ │ External APIs          │
│  - Firebase Auth            │ │ - Google Maps Platform │
│  - Cloud Firestore          │ │   (Places, Geocoding,  │
│  - Firebase Storage         │ │    Directions API)     │
│  - Cloud Functions (Node)   │ │ - Egyptian Geo-Catalog │
│  - Cloud Messaging (FCM)    │ │   (Offline Fallback)   │
└─────────────────────────────┘ └────────────────────────┘
```

---

### 2. Core Service Components

#### A. Firebase Authentication & Identity
- **Dual Flow:**
  1. **Google Sign-In:** Direct OAuth token exchange with Firebase Auth.
  2. **Email Verification Code:** Secure 6-digit random verification code issued via Cloud Functions, with 10-minute expiry and 3-attempt throttling.
- **Custom Claims & RBAC:**
  - Administrative roles (`superadmin`, `compliance`, `operations`, `support`) are strictly enforced via `request.auth.token.role` claims, preventing any client-side privilege escalation.

#### B. Cloud Firestore (Scalable NoSQL Database)
- Multi-region database in `europe-west1` (Frankfurt) or `europe-west3` (Belgium) ensuring ultra-low latency for Egyptian traffic.
- **Atomic Operations:** Seat reservations, parcel OTP handovers, and wallet transfers use Firestore Transactions to eliminate race conditions and double-spending.
- **Composite Indexes:** Fully specified in [firestore.indexes.json](file:///d:/My_Projects/Meshwar-v1/Meshwar/firestore.indexes.json) supporting multi-criteria highway searches.

#### C. Firebase Storage (Private & Public Buckets)
- **Public:** User avatars (`avatars/{userId}.jpg`).
- **Private & Encrypted:**
  - National ID front & back (`users/{userId}/verification/id_front.jpg`).
  - Driver licenses and vehicle licenses (`drivers/{userId}/documents/`).
  - Payment transfer receipts (`receipts/{userId}/{txId}.jpg`).
  - Access restricted to document owner and authorized compliance staff via Storage Security Rules.

#### D. Trusted Cloud Functions (Server-Side Business Authority)
Sensitive financial and state-transition logic is handled exclusively on the backend:
1. `createBooking`: Verifies remaining seats and atomicity.
2. `cancelBooking`: Applies service-specific cancellation rules and restocks seats.
3. `verifyParcelOtp`: Hashes and compares OTPs for pickup and delivery.
4. `processWalletTransfer`: Double-entry ledger updating wallet balances.
5. `approveDriverVerification`: Updates verified captain status and creates audit log entry.
6. `sendFcmNotification`: Pushes real-time alerts to passengers and drivers.

#### E. Google Maps Platform & Egyptian Geocoding Engine
- **Places Autocomplete:** Real-time search with `components=country:eg` restriction.
- **Directions & Distance Matrix:** Calculates driving distance (km) and estimated travel duration (minutes/hours) over Egyptian highway networks (Alex Desert Road, Agri Road, International Coastal Road, Regional Ring Road).
- **Egyptian Geo-Catalog:** Offline-ready database with coordinates and highway heuristics covering all 27 Egyptian governorates and key logistics hubs.

---

### 3. Environment Strategy

| Environment | Database Target | Auth Provider | Maps API Key |
|---|---|---|---|
| **Development** | Firebase Local Emulator Suite (Ports 8080, 9099, 5001) | Emulator Auth | Mocked / Local Egyptian Geo Catalog |
| **Staging** | `meshwar-staging` Firebase project | Test phone / email OTPs | Staging API Key with HTTP Referrer / Package restrictions |
| **Production** | `meshwar-platform` Firebase project | Production Google OAuth & Mailgun | Production Google Maps Key with strict quotas and domain restrictions |
