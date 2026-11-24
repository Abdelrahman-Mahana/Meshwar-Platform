# Security Architecture & Data Governance — MASHWAR Platform
## Zero-Trust Controls, Firestore/Storage Rules, Cryptographic Handover & Qatar Compliance

### 1. Defense-in-Depth Security Model
The MASHWAR Qatar Worksite Supply MVP enforces five security boundaries across client, network, database, and cloud storage layers:

1. **Fail-Closed Client Environment (`AppEnvironment`):**
   - `AuthProvider` defaults to `AuthStatus.unauthenticated` with `UserModel.empty` (`isVerified: false`, `idVerificationStatus: unverified`, `nationalId: null`, `walletBalance: 0.0`, `rating: 0.0`).
   - `USE_DEV_MOCKS` is cryptographically/logically barred outside `APP_ENV == 'development' && !USE_FIREBASE`. Arbitrary 6-digit OTP acceptance, prefilled demo credentials, and sample seed repositories cannot activate in `staging`, `production`, or Firebase-enabled runs.
2. **Server-Authoritative Privileged Transitions (`functions/`):**
   - Offer acceptance, handover secret generation, constant-time handover verification, completion counters, ratings aggregation, payment settlement verification, and provider approvals run inside transactional Node.js 20 Cloud Functions (`europe-west1`).
3. **Deterministic Firestore Rules (`firestore.rules` — 2,475 lines):**
   - Default-deny root matcher (`allow read, write: if false`), strict field whitelisting (`hasOnlyAllowedFields`), immutable field guards (`areImmutableFieldsUnchanged`), and cross-document ownership/approval checks.
4. **Scoped Cloud Storage Rules (`storage.rules`):**
   - Default-deny, authenticated-only reads/writes, `<= 10 MB` file size limit, and `image/*` content-type enforcement.
5. **Authenticated Staff RBAC & Immutable Audit Logging:**
   - `AdminProvider` defaults `_isLoggedIn = false`, blocks `/admin` behind `AdminLoginScreen`, authenticates via Firebase Auth, resolves roles strictly from active `admin_staff/{uid}` (`isActive == true`), hides local role switchers outside dev-mock mode, and writes append-only `admin_audit_logs`.

---

### 2. Firestore Security Rules Matrix (Worksite Supply MVP + Core Governance)

| Collection | Create | Read (`get` / `list`) | Update | Delete |
| :--- | :--- | :--- | :--- | :--- |
| `users/{uid}` | Owner (`isVerified == false`, `walletBalance == 0`, zero stats) | Owner, Admin, or non-sensitive profile `get` (`list` Admin only) | Owner (non-privileged fields only; cannot self-verify or edit balance/stats) or Admin | Owner or Admin |
| `business_profiles/{uid}` | Owner (`ratingAvg == 0`, `ratingCount == 0`) | `get`: Owner, Admin, or Approved Provider; `list`: Owner or Admin | Owner (cannot alter `ratingAvg`/`ratingCount`) or Admin | Admin only |
| `provider_profiles/{uid}` | Owner (`approvalStatus == 'pending'`, zero stats) | Signed-in users (contains no QID PII) | Owner (cannot alter `approvalStatus`, stats, or review fields) or Admin | Admin only |
| `provider_verifications/{uid}` | Owner (`11-digit QID`, `status` in `pending`/`underReview`) | **Owner or Admin only** (protects QID & KYC URLs) | Owner (resubmit when `pending`/`underReview`/`rejected` without touching review metadata) or Admin | Admin only |
| `work_requests/{requestId}` | Signed-in requester (`status == 'open'`, `budgetMinor > 0` int, `paymentStatus == 'unpaid'`) | Signed-in users | Admin or validated requester/assigned-provider transitions (never client `completed` or financial tampering) | **Forbidden (`false`)** |
| `work_offers/{offerId}` | Approved provider (`requesterId != uid`, `status == 'pending'`, int minor amounts) | Offer provider, request owner, or Admin | Provider (`pending -> withdrawn` only, pricing immutable) or Admin | **Forbidden (`false`)** |
| `work_request_secrets/{requestId}` | **Forbidden (`false`)** | **Forbidden (`false`)** | **Forbidden (`false`)** | **Forbidden (`false`)** |
| `work_request_handover_view/{requestId}` | **Forbidden (`false`)** | **Requester only** (`requesterId == auth.uid`) | **Forbidden (`false`)** | **Forbidden (`false`)** |
| `request_events/{eventId}` | Validated participant or Admin | Request requester, assigned provider, or Admin | **Forbidden (`false`)** | **Forbidden (`false`)** |
| `ratings/{ratingId}` | Participant on `completed` request (`${requestId}_${uid}`) | Signed-in users | **Forbidden (`false`)** | **Forbidden (`false`)** |
| `notifications/{notificationId}` | Admin / Cloud Functions only | Owner (`userId == auth.uid`) or Admin | Owner (`isRead` bool only) or Admin | Admin only |
| `admin_staff/{staffId}` | SuperAdmin / Admin | Staff owner or Admin | SuperAdmin / Admin | SuperAdmin / Admin |
| `admin_audit_logs/{logId}` | Admin / Cloud Functions | Admin only | **Forbidden (`false`)** | **Forbidden (`false`)** |
| `wallet_transactions/{txId}` | Admin / Backend only | Owner or Admin | **Forbidden (`false`)** | **Forbidden (`false`)** |

---

### 3. Cryptographic Handover Protocol (`handoverCrypto.ts`)

To prevent premature or fraudulent order completion without physical worksite delivery:
- **CSPRNG Code Generation:** 6 characters drawn from a 32-symbol unambiguous alphabet (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789` — omitting `0/O/1/I`) using `crypto.randomBytes(6)` (`32` divides `256` evenly -> zero modulo bias).
- **Salted Hashing:** Per-request 128-bit random salt (`crypto.randomBytes(16).toString('hex')`); stored digest is `SHA-256("${salt}:${normalizedCode}")`.
- **Constant-Time Verification:** `verifyHandoverCodeHash` compares digest buffers using `crypto.timingSafeEqual` to prevent timing side-channels.
- **Brute-Force, Replay & Expiry Defenses:**
  - Maximum **5 attempts** (`attemptsRemaining` decremented transactionally on every wrong code before returning `failed-precondition`).
  - **24-hour TTL** (`expiresAtUtc`).
  - **Single-use enforcement** (`usedAtUtc` stamped atomically upon completion).
  - Secret isolation: providers have **zero** read access to either `work_request_secrets` or `work_request_handover_view`.

---

### 4. Financial & Settlement Integrity
1. **Integer Minor Units Only:** `MoneyMinor` (`1 QAR = 100 dirhams`) eliminates IEEE-754 floating-point rounding discrepancies across budgets, service fees, and invoice totals.
2. **Settlement Immutability:** New requests always initialize `paymentStatus: 'unpaid'`. Requesters may only transition `unpaid -> transfer_proof_submitted` (when `paymentMethod == 'bank_transfer_manual'`). Only an active administrator can mark `verified_settled`, and once `paymentStatus == 'verified_settled'`, `assertPaymentStatusTransition` blocks all further modifications or overwrites.
3. **Wallet Mutation Lockout:** While `AppEnvironment.enableDigitalWallet == false`, local wallet mutation methods (`depositWalletFunds` / `withdrawWalletFunds`) are blocked in `AuthProvider`.

---

### 5. Qatar PII Protection & Cloud Storage ACLs (`storage.rules`)
- **Qatar ID (`QID`) & KYC Documents:** Validated as 11 numeric digits (`^[0-9]{11}$`). Stored in `provider_verifications/{uid}` and `/provider_verifications/{uid}/{file}` where only the submitting user and active administrators can read. Public `provider_profiles/{uid}` never exposes `qidNumber` or ID image URLs.
- **Phone Formatting:** Validated for Qatar 8-digit mobile numbers (`+974` `[3567]xxxxxxx`).
- **Worksite Invoices & Payment Proofs:** `/work_requests/{requestId}/invoices/{file}` (uploadable only by the assigned approved provider) and `/work_requests/{requestId}/payment_proofs/{file}` (uploadable only by the requester) are readable strictly by the request's requester, assigned provider, or active admin (`<= 10 MB`, `image/*` only).

---

### 6. Regulatory & Trademark Compliance Boundaries
- **Ministry of Transport (MoT) Boundary:** Passenger ride-hailing, paid carpooling, and commercial freight modules are disabled (`false` in `AppEnvironment`) so the Phase 1 pilot operates strictly within B2B/worksite supply procurement coordination without making unlicensed passenger-transport claims.
- **Qatar Central Bank (QCB) Boundary:** In-app stored-value wallets and custodial escrow claims are disabled (`false`); Phase 1 records non-custodial `cash_on_delivery` and `bank_transfer_manual` settlement states only.
- **Trademark Governance:** Independent trademark clearance in Qatar is required for the `MASHWAR / مشوار` brand prior to public commercial rollout.
