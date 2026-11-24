# MASHWAR Platform — Cloud Firestore Database Schema Specification
## Qatar Worksite Supply MVP (Collections 20–29) & Preserved Platform Schema (Collections 1–19)

### 1. Core Schema Standards & Invariants
All collections in [`firestore.rules`](../../firestore.rules) (2,475 lines) and [`functions/src/types.ts`](../../functions/src/types.ts) adhere to five strict invariants:

1. **Integer Minor-Unit Currency (`QAR` Dirhams):** Every MVP monetary field (`budgetMinor`, `totalAmountMinor`, `serviceFeeMinor`, `agreedAmountMinor`, `agreedFeeMinor`, `estimatedItemsCostMinor`, `maxItemsCapMinor`, `deliveryFeeBudgetMinor`, `actualReceiptTotalMinor`) is stored as a signed/positive **integer** in Qatari dirhams (`1 QAR = 100 minor units`, e.g., `150.00 QAR` = `15000`). Floating-point `double` money fields are prohibited in Worksite Supply models (`MoneyMinor`).
2. **Qatar Identity & Phone Standards:**
   - **Qatar ID (`qidNumber` / `nationalId`):** 11 numeric digits (`^[0-9]{11}$`).
   - **Qatar Mobile (`phone`):** 8 local digits starting with `3`, `5`, `6`, or `7` with optional `+974` / `974` prefix (`^(?:\+?974)?[3567][0-9]{7}$`), plus international numeric fallback (`^\+?[0-9\s-]{10,20}$`) where applicable.
3. **UTC Temporal Representation:** Server writes use UTC ISO-8601 strings (`2026-11-24T20:00:00.000Z`) or Firestore `FieldValue.serverTimestamp()`, normalized in Dart via `normalizeFirestoreDocument()`.
4. **Canonical English `snake_case` Status Slugs:** Database status and enum fields store canonical English slugs (`open`, `offer_received`, `delivered_pending_confirmation`, `cash_on_delivery`, `verified_settled`). Arabic (`ر.ق`) and English display labels live strictly in UI presentation extensions.
5. **Default-Deny Root Rule:** Unmatched paths fall through to `match /{document=**} { allow read, write: if false; }`.

---

### 2. Active Worksite Supply MVP Collections (Collections 20–29)

#### Collection 20: `business_profiles/{uid}`
- **Purpose:** Optional company / contractor profile for B2B worksite requesters.
- **Key Fields:**
  | Field | Type | Required | Constraints & Notes |
  | :--- | :--- | :---: | :--- |
  | `id` | `string` | Yes | Must match `{uid}` (immutable) |
  | `userId` / `ownerUserId` | `string` | Yes | Must match `{uid}` (immutable) |
  | `companyName` | `string` | Yes | `2..160` chars |
  | `commercialRegistrationNumber` | `string?` | No | Optional Qatar CR reference |
  | `contactName` / `contactPersonName` | `string?` | No | Site / procurement coordinator name |
  | `phone` / `contactPhone` | `string` | No/Yes | Valid Qatar mobile (`+974` `[3567]xxxxxxx`) |
  | `defaultWorksiteArea` / `municipality` | `string?` | No | e.g., `الدوحة`, `لوسيل`, `المنطقة الصناعية` |
  | `ratingAvg` | `number` | Yes | Initialized to `0`; updated only by Cloud Functions / Admin |
  | `ratingCount` | `int` | Yes | Initialized to `0`; updated only by Cloud Functions / Admin |
  | `createdAt`, `updatedAt` | `string` / `Timestamp` | Yes | UTC timestamp |
- **Access Control:** `get` by owner, admin, or approved provider; `list` restricted to owner or admin (protects contact phone PII); owner `create`/`update` cannot alter `ratingAvg` or `ratingCount`.

#### Collection 21: `provider_profiles/{uid}`
- **Purpose:** Public operational profile and approval state for supply runners / couriers (contains **no** QID or KYC image PII).
- **Key Fields:**
  | Field | Type | Required | Constraints & Notes |
  | :--- | :--- | :---: | :--- |
  | `id`, `userId` | `string` | Yes | Matches `{uid}` (immutable) |
  | `fullName` | `string` | Yes | `2..120` chars |
  | `phone` | `string?` | No | Valid Qatar mobile |
  | `vehicleType` | `string?` | No | Pickup, van, sedan, light truck |
  | `vehiclePlate` | `string?` | No | Qatari plate identifier |
  | `serviceAreas` / `serviceMunicipalities` | `string[]` | No | Max 15 Qatar municipalities/areas |
  | `supplySpecialties` | `string[]` | No | e.g., electrical, plumbing, PPE, fasteners |
  | `approvalStatus` | `string` | Yes | Enum: `pending` \| `approved` \| `rejected` \| `suspended` |
  | `completedTasksCount` | `int` | Yes | Initialized `0`; incremented atomically on handover completion |
  | `ratingAvg`, `ratingCount` | `number`, `int` | Yes | Server-maintained running average |
  | `reviewedBy`, `reviewedAtUtc`, `rejectionReason` | `string?` | No | Populated by `adminReviewProvider` |
- **Access Control:** `read` by any signed-in user; owner `create` **must** set `approvalStatus == 'pending'` and zero stats; owner `update` **cannot** modify `approvalStatus`, `completedTasksCount`, `ratingAvg`, `ratingCount`, or review metadata (prevents self-approval).

#### Collection 22: `provider_verifications/{uid}`
- **Purpose:** Private KYC submission holding the provider's 11-digit Qatar ID (QID) and private Storage media references.
- **Key Fields:** `id` (`{uid}`), `providerId` (`{uid}`), `fullName`, `qidNumber` (`^[0-9]{11}$`), `qidFrontUrl`, `qidBackUrl`, `selfieUrl`, `vehicleLicenseUrl`, `status` (`pending` \| `underReview` \| `approved` \| `rejected` \| `suspended`), `reviewedBy`, `reviewedAtUtc`, `rejectionReason`, `createdAt`, `updatedAt`.
- **Access Control:** `read` strictly restricted to `isOwner(uid) || isAdmin()`; owner may submit/resubmit only in `pending`/`underReview` states without altering review fields.

#### Collection 23: `work_requests/{requestId}`
- **Purpose:** Authoritative Worksite Supply procurement & delivery order document.
- **Key Fields:**
  | Field | Type | Constraints & Notes |
  | :--- | :--- | :--- |
  | `id` | `string` | Document ID (`req_<uuid>`) |
  | `requesterId`, `requesterName` | `string` | Authenticated requester UID (immutable) & display name |
  | `category` / `supplyCategory` | `string` | `'worksite_supply'` (or specific supply subtype in client metadata) |
  | `title`, `description` | `string` | `2..160` chars title; up to `2000` chars item specs/quantities |
  | `pickupLocation` | `string` | Store / supplier hub (e.g., Doha Industrial Area Street 15) |
  | `deliveryLocation` / `dropoffWorksite` | `string` | Target worksite gate / zone |
  | `deliveryArea` / `municipality` | `string` | Qatar municipality/area used for feed filtering |
  | `budgetMinor` | `int` | Positive integer minor units (`> 0`, `<= 100,000,000`) |
  | `estimatedItemsCostMinor`, `maxItemsCapMinor`, `deliveryFeeBudgetMinor` | `int` | Client breakdown fields serialized as integer minor units |
  | `paymentMethod` | `string` | Enum: `cash_on_delivery` \| `bank_transfer_manual` |
  | `paymentStatus` | `string` | Enum: `unpaid` \| `transfer_proof_submitted` \| `verified_settled` \| `disputed` |
  | `paymentProofUrl`, `paymentVerifiedBy`, `paymentVerifiedAtUtc` | `string?` | Manual bank transfer receipt URL & admin verification metadata |
  | `status` | `string` | 11-state enum: `open` \| `offer_received` \| `offer_selected` \| `accepted` \| `in_progress` \| `picked_up` \| `in_transit` \| `delivered_pending_confirmation` \| `completed` \| `cancelled` \| `disputed` |
  | `offerCount` | `int` | Number of submitted offers (`>= 0`) |
  | `selectedOfferId`, `assignedProviderId` | `string?` | Populated atomically on `acceptWorkOffer` |
  | `agreedAmountMinor`, `agreedFeeMinor` | `int?` | Locked offer pricing in QAR minor units |
  | `referenceImageUrls`, `invoiceImageUrls` | `string[]` | Up to 10 `https://` or `gs://` URLs (`invoiceImageUrls` attached during pickup/transit/delivery) |
  | `cancellationReason`, `disputeReason`, `moderationNotes`, `completedAtUtc` | `string?` | Lifecycle audit fields |
  | `createdAt`, `updatedAt` | `string` / `Timestamp` | UTC timestamps |
- **Access Control:** Signed-in `read`; owner `create` requires `status == 'open'`, `paymentStatus == 'unpaid'`, `offerCount == 0`, `assignedProviderId == null`; `delete` is `false` (immutable operational record); `completed` cannot be set directly by requester or unverified client writes.

#### Collection 24: `work_offers/{offerId}`
- **Purpose:** Quotes submitted by approved providers against open worksite supply requests.
- **Key Fields:** `id` (`off_<uuid>`), `requestId`, `providerId`, `providerName`, `totalAmountMinor` (`int > 0`), `serviceFeeMinor` (`int >= 0`), `etaMinutes` (`1..10080`), `notes`, `status` (`pending` \| `accepted` \| `rejected` \| `withdrawn`), `createdAt`, `updatedAt`.
- **Access Control:** `read` restricted to offer `providerId`, parent request `requesterId`, or `isAdmin()`; `create` requires `isApprovedProvider(request.auth.uid)` and forbids self-bidding (`requesterId != auth.uid`); client `update` allows only withdrawing a `pending` offer without altering pricing; `delete` is `false`.

#### Collection 25: `work_request_secrets/{requestId}`
- **Purpose:** Server-only cryptographic handover verification record.
- **Key Fields:** `requestId`, `codeHash` (hex `SHA-256(codeSalt + ':' + normalizedCode)`), `codeSalt` (32-char hex / 128-bit), `expiresAtUtc` (`+24h`), `attemptsRemaining` (`5` -> `0`), `maxAttempts` (`5`), `usedAtUtc` (`string | null`), `createdAt`, `updatedAt`.
- **Access Control:** **`allow read, write: if false;`** — accessible exclusively to Cloud Functions / Firebase Admin SDK.

#### Collection 26: `work_request_handover_view/{requestId}`
- **Purpose:** Requester-scoped projection allowing **only** the request owner to display the 6-character handover code to the worksite receiver.
- **Key Fields:** `requestId`, `requesterId`, `handoverCode` (6-char `[A-HJ-NP-Z2-9]`), `expiresAtUtc`, `createdAt`, `updatedAt`.
- **Access Control:** `read` allowed **only** when `requesterId == request.auth.uid`; **`allow write: if false;`** (written solely by `acceptWorkOffer` Cloud Function).

#### Collection 27: `request_events/{eventId}`
- **Purpose:** Immutable, append-only timeline and state-transition audit log for each `work_requests` document.
- **Key Fields:** `id` (`evt_<uuid>`), `requestId`, `actorId`, `actorRole` (`requester` \| `provider` \| `admin` \| `system`), `type` / `eventType`, `fromStatus`, `toStatus`, `note`, `metadata`, `createdAt`.
- **Access Control:** `read` by request participants (`requesterId` or `assignedProviderId`) or admin; `update, delete: if false`.

#### Collection 28: `ratings/{ratingId}`
- **Purpose:** Post-completion mutual 1–5 star ratings.
- **Document ID:** Deterministic `${requestId}_${fromUserId}` enforcing at most one rating per participant per completed request.
- **Key Fields:** `id`, `requestId`, `fromUserId`, `toUserId`, `fromRole` (`requester` \| `provider`), `stars` (`int 1..5`), `comment`, `createdAt`.
- **Access Control:** `read` by signed-in users; `create` once per participant after `request.status == 'completed'`; `update, delete: if false`.

#### Collection 29: `notifications/{notificationId}`
- **Purpose:** In-app operational alerts (new offer, offer accepted, status transitions, handover completed, provider KYC review).
- **Key Fields:** `id` (`ntf_<uuid>`), `userId`, `requestId`, `type`, `title`, `body`, `isRead` (`bool`), `createdAt`.
- **Access Control:** `read` by `userId == request.auth.uid` or admin; `create` by backend/admin only; owner `update` may toggle **only** `isRead`.

#### Subcollection: `users/{userId}/private/{worksiteId}` (`SavedWorksite`)
- **Purpose:** Stores requester saved worksites (`label`, `municipality`, `zoneOrStreet`, `landmark`, `gateInstructions`, `siteContactName`, `siteContactPhone`, `latitude`, `longitude`, `isDefault`) privately under owner-only access (`isOwner(userId) || isAdmin()`).

---

### 3. Preserved Platform & Admin Collections (Collections 1–19)

Preserved intact in [`firestore.rules`](../../firestore.rules) to maintain admin governance, messaging, lead capture, and future phased expansion:

| # | Collection Path | Phase 1 Role | Security Summary |
| :---: | :--- | :--- | :--- |
| 1 | `users/{userId}` (+ `users_public/{userId}`) | **Active** | User profile; neutral defaults (`isVerified: false`, `walletBalance: 0`, `rating: 0`); supports 11-digit QID & `+974` phone; owner cannot self-verify or edit balance/stats. |
| 2 | `rides/{rideId}` | Deferred (`enablePassengerRides=false`) | Inter-area rides schema preserved behind MoT licensing flag. |
| 3 | `board_ads/{adId}` | Deferred | Legacy community board requests/offers. |
| 4 | `board_ads/{adId}/offers/{offerId}` | Deferred | Subcollection offers for legacy board ads. |
| 5 | `parcels/{parcelId}` | Deferred (`enableCommercialCargo=false`) | Legacy parcel delivery records. |
| 6 | `bookings/{bookingId}` | Deferred (`enablePassengerRides=false`) | Seat reservations on deferred rides. |
| 7 | `conversations/{conversationId}` & `messages/{messageId}` | **Active (Contextual Chat)** | Participant-only direct messaging between requester and assigned provider. |
| 8 | `route_alerts/{alertId}` | Deferred | Corridor alert subscriptions. |
| 9 | `wallet_transactions/{txId}` | Deferred (`enableDigitalWallet=false`) | Client writes denied (`isAdmin()` / backend only). |
| 10 | `driver_verifications/{verificationId}` | Deferred | Legacy passenger-driver KYC collection (Worksite Supply uses `provider_verifications`). |
| 11 | `admin_audit_logs/{logId}` | **Active** | Append-only administrative audit log (`allow update, delete: if false`). |
| 12 | `platform_config/{configId}` | **Active (Admin)** | Global platform parameters managed by admins. |
| 13 | `service_catalog/{serviceId}` | **Active (Admin)** | Service definitions & enablement metadata. |
| 14 | `corridors/{corridorId}` | **Active (Admin)** | Qatar municipal & industrial logistics corridors. |
| 15 | `escrow_holds/{escrowId}` | Deferred (`enableEscrowClaims=false`) | Reserved for future QCB-licensed PSP escrow holds. |
| 16 | `disputes/{disputeId}` | **Active (Support)** | Participant dispute tickets & admin resolution records. |
| 17 | `feature_flags/{flagId}` | **Active (Admin)** | Runtime operational feature switches. |
| 18 | `admin_staff/{staffId}` | **Active** | Authorized staff directory (`uid`, `email`, `role`, `isActive`) checked by `AdminProvider` & Cloud Functions. |
| 19 | `investor_inquiries/{inquiryId}` | **Active** | Public lead-capture submissions from `landing_page/`, readable by admin staff. |

---

### 4. Composite Indexes (`firestore.indexes.json`)

[`firestore.indexes.json`](../../firestore.indexes.json) defines **14** composite indexes (6 Worksite Supply MVP indexes + 8 preserved legacy indexes):

| Collection Group | Indexed Fields & Sort Order | Primary Query Consumer |
| :--- | :--- | :--- |
| `work_requests` | `status ASC`, `deliveryArea ASC`, `createdAt DESC` | Provider feed filtered by status & Qatar municipality/area |
| `work_requests` | `requesterId ASC`, `createdAt DESC` | Requester "My Activity" & Quick Reorder history |
| `work_requests` | `assignedProviderId ASC`, `createdAt DESC` | Provider assigned & completed fulfillment jobs |
| `work_offers` | `requestId ASC`, `createdAt DESC` | Offer comparison list on `WorkRequestDetailsScreen` |
| `request_events` | `requestId ASC`, `createdAt ASC` | Chronological audit timeline per request |
| `ratings` | `toUserId ASC`, `createdAt DESC` | Provider / requester reputation feed |
| `rides` *(x2)*, `board_ads`, `parcels` *(x2)*, `bookings`, `wallet_transactions`, `route_alerts` | Preserved multi-field indexes | Deferred Phase 2+ modules |
