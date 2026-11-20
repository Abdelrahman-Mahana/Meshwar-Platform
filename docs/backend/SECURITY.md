# SECURITY ARCHITECTURE & DATA GOVERNANCE — MASHWAR PLATFORM

## 1. Threat Model & Security Principles
The MASHWAR security architecture enforces defense-in-depth across five distinct tiers:
1. **Zero-Trust Client Boundary**: The Flutter application is treated as an untrusted client. No business-critical state (balances, verification badges, booking confirmations) is decided client-side.
2. **Deterministic Firestore Security Rules**: Enforced at the cloud engine layer prior to any document mutation or read.
3. **Privileged Cloud Functions Gateway**: Financial settlements, ride completions, and administrative audits execute exclusively in authenticated, sandboxed Node.js runtimes.
4. **Integer Piastre Financial Precision**: Floating point representations (`double`) are prohibited for financial calculations to eliminate rounding exploits.
5. **Role-Based Access Control (RBAC)**: Custom JWT claims (`admin`, `driver`, `verified`) issued only via verified Firebase Admin SDK calls.

---

## 2. Firestore Security Rules Matrix
All database access is constrained by the 1,098-line rule set in `firestore.rules`.

| Collection | Create Rule | Read Rule | Update Rule | Delete Rule |
| :--- | :--- | :--- | :--- | :--- |
| `users` | Auth UID == docId | Public / Authenticated profile | Owner only (cannot modify `wallet_balance_piastres`, `is_driver`, `is_verified`) | Admin only |
| `rides` | Verified Drivers only | Public (status: `scheduled`) | Driver only (status, pickup details); System functions | Driver before booking / Admin |
| `bookings` | Authenticated Passengers | Passenger, Driver, or Admin | Status transitions enforced via state machine | System / Admin only |
| `board_ads` | Authenticated Users | Public (status: `open`) | Ad Creator only | Ad Creator or Admin |
| `board_offers` | Authenticated Users | Ad Creator & Offer Submitter | Status transitions (accept/reject) | Offer Submitter (if pending) |
| `parcels` | Authenticated Senders | Sender, Accepted Courier, Admin | Status transitions | Sender before courier assignment |
| `chats` | Chat Participants only | Participants only | Participants (messages append) | Forbidden |
| `wallet_transactions` | **Deny All Client Writes** | Owner (`userId == auth.uid`) | **Deny All Client Writes** | **Deny All Client Writes** |
| `admin_logs` | **Deny All Client Writes** | Admins only | **Deny All Client Writes** | **Deny All Client Writes** |

---

## 3. Financial Security Invariants
1. **Wallet Balance Immutability**:
   ```javascript
   // firestore.rules
   function cannotMutateFinancialFields() {
     return !request.resource.data.diff(resource.data).affectedKeys()
       .hasAny(['wallet_balance_piastres', 'is_verified', 'is_driver']);
   }
   ```
2. **Transaction Ledger Integrity**:
   - `wallet_transactions` documents are append-only.
   - Balances are updated via Cloud Functions using atomic Firestore batch transactions that simultaneously write a ledger record and update the user's aggregate balance.
   - Any transaction without a cryptographic server timestamp is rejected.

---

## 4. Personally Identifiable Information (PII) Protection
- **Phone Numbers**: Stored with E.164 formatting (`+2010xxxxxxxx`). Only visible to matched drivers and passengers after a booking has transitioned to `confirmed`.
- **National IDs & Driving Licenses**: Uploaded to private Cloud Storage bucket path `gs://<bucket>/verification_documents/{userId}/` with read access restricted to admins.
- **Location Privacy**: Passenger live coordinates are only shared with the driver during an active, in-progress trip (`status == 'in_progress'`).

---

## 5. Security Incident Response & Audit Trail
- Every administrative action (blocking a user, manually crediting a balance, modifying ride statuses) logs an immutable entry to `/admin_logs/{logId}` containing:
  - `adminUid`
  - `actionType`
  - `targetEntityId`
  - `timestamp`
  - `ipAddress` (where available via callable functions)
  - `reason`
