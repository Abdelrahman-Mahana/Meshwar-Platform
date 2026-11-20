# MASHWAR Platform — Cloud Firestore Database Schema Specification
## Document Models, Field Definitions, Permissions, Indexes, and Integrity Constraints

### 1. Architectural Standards & Design Invariants
1. **Financial Ledger Representation:** All currency amounts are stored as integer Egyptian piastres (1 EGP = 100 Piastres, e.g. 150 EGP is stored as `15000`) to guarantee zero floating-point rounding errors across transactions.
2. **Standardized Identifiers:** Stable, alphanumeric document IDs (`usr_...`, `rd_...`, `bk_...`, `ad_...`, `pcl_...`, `tx_...`).
3. **Temporal Values:** All dates stored as UTC timestamps (`FieldValue.serverTimestamp()` on write).
4. **Localization Decoupling:** Enums and database status codes are English slugs (`active`, `confirmed`, `completed`, `cancelled`). Arabic text is reserved strictly for presentation and user-entered descriptions.

---

### 2. Collection Schemas

#### 1. `users` (Collection)
- **Document ID:** Firebase Auth UID (`request.auth.uid`).
- **Purpose:** Authoritative user account profile, verification status, and safety contact.
- **Fields:**
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | String | Yes | Immutable, matches Auth UID | User ID |
  | `fullName` | String | Yes | 2–100 chars | Full legal name |
  | `phone` | String | Yes | 11 chars (regex: `^(010\|011\|012\|015)\d{8}$`) | Primary mobile number |
  | `email` | String | No | Valid email format | Contact email |
  | `gender` | String | Yes | Enum: `male`, `female`, `preferNotToSay` | Gender |
  | `avatarUrl` | String | No | HTTPS URL | Public avatar |
  | `isVerified` | Boolean | Yes | Default: `false`, Admin-writable only | Verified captain badge |
  | `idVerificationStatus` | String | Yes | Enum: `unverified`, `underReview`, `verified`, `rejected` | National ID state |
  | `nationalId` | String | No | 14 digits (Egyptian National ID) | Sensitive PII (Protected) |
  | `idFrontImage` | String | No | Storage URI | Encrypted ID front photo |
  | `idBackImage` | String | No | Storage URI | Encrypted ID back photo |
  | `selfieImage` | String | No | Storage URI | Verification selfie |
  | `walletBalancePiastres` | Integer | Yes | Default: `0`, Backend ledger-only | Wallet balance in piastres |
  | `rating` | Number | Yes | 1.0 to 5.0 (Default: `5.0`) | Average user rating |
  | `completedRides` | Integer | Yes | >= 0 | Lifetime completed trips |
  | `completedParcels` | Integer | Yes | >= 0 | Lifetime delivered parcels |
  | `emergencyContactName` | String | No | <= 100 chars | Emergency contact name |
  | `emergencyContactPhone` | String | No | 11 chars | Emergency contact phone |
  | `ladiesOnlyPreference` | Boolean | No | Default: `false` | Prefer women-only rides |
  | `createdAt` | Timestamp | Yes | Server timestamp | Account registration date |
  | `updatedAt` | Timestamp | Yes | Server timestamp | Last profile update |
- **Access Control:**
  - Read: Owner (`auth.uid == userId`) or Admin. Public reads of non-sensitive fields (`fullName`, `avatarUrl`, `rating`, `completedRides`) via mirror collection `users_public/{userId}`.
  - Write: Owner (can update non-privileged fields only; cannot alter balance, rating, or self-verify).

---

#### 2. `rides` (Collection)
- **Document ID:** Unique ride identifier (`rd_<uuid>`).
- **Purpose:** Intercity carpooling trips published by verified drivers.
- **Fields:**
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | String | Yes | Immutable | Ride identifier |
  | `driverId` | String | Yes | Must match `auth.uid` of driver | Driver User UID |
  | `driverName` | String | Yes | 2–100 chars | Display name of driver |
  | `driverCar` | String | Yes | 2–100 chars | Vehicle model & plate info |
  | `driverPhone` | String | Yes | 11 chars | Driver contact phone |
  | `fromCity` | String | Yes | Standard Egyptian hub name | Departure city/governorate |
  | `toCity` | String | Yes | Standard Egyptian hub name | Destination city/governorate |
  | `pickupPoint` | String | Yes | 1–200 chars | Meeting/pickup landmark |
  | `dropoffPoint` | String | Yes | 1–200 chars | Arrival/dropoff landmark |
  | `departureTime` | String | Yes | e.g. `07:30 ص` | Scheduled departure time |
  | `departureDate` | String | Yes | ISO Date / format | Scheduled departure date |
  | `remainingSeats` | Integer | Yes | 0 to 10 | Available seats for booking |
  | `pricePerSeatPiastres` | Integer | Yes | >= 0 | Seat price in piastres |
  | `acceptsParcels` | Boolean | Yes | Default: `true` | Allows crowd-shipping |
  | `parcelPricePiastres` | Integer | No | >= 0 | Standard parcel fee |
  | `isLadiesOnly` | Boolean | Yes | Default: `false` | Reserved for ladies only |
  | `isInstantBooking` | Boolean | Yes | Default: `false` | Auto-confirm bookings |
  | `driverRating` | Number | Yes | 1.0 to 5.0 | Driver rating score |
  | `status` | String | Yes | Enum: `active`, `inTransit`, `completed`, `cancelled` | Ride status |
  | `createdAt` | Timestamp | Yes | Server timestamp | Publication timestamp |
- **Composite Indexes:**
  - `(fromCity ASC, toCity ASC, departureDate ASC, remainingSeats DESC)`
  - `(fromCity ASC, toCity ASC, isLadiesOnly ASC, departureDate ASC)`

---

#### 3. `bookings` (Collection)
- **Document ID:** Unique booking identifier (`bk_<uuid>`).
- **Purpose:** Passenger seat reservations and trip verification tokens.
- **Fields:**
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | String | Yes | Immutable | Booking ID |
  | `rideId` | String | Yes | References `rides/{id}` | Target ride reference |
  | `passengerId` | String | Yes | References `users/{id}` | Passenger User UID |
  | `passengerName` | String | Yes | 2–100 chars | Passenger name |
  | `passengerPhone` | String | Yes | 11 chars | Passenger contact phone |
  | `seats` | Integer | Yes | 1 to 4 | Reserved seat count |
  | `totalPricePiastres` | Integer | Yes | > 0 | Total fare in piastres |
  | `status` | String | Yes | Enum: `pending`, `confirmed`, `active`, `completed`, `cancelled` | Booking lifecycle status |
  | `otpCode` | String | Yes | 4 alphanumeric chars | Boarding verification code |
  | `cancellationReason` | String | No | <= 500 chars | Mandatory if cancelled |
  | `createdAt` | Timestamp | Yes | Server timestamp | Booking creation time |

---

#### 4. `board_ads` (Collection) & `offers` (Subcollection)
- **Document ID:** `ad_<uuid>` and `board_ads/{adId}/offers/{offerId}`.
- **Purpose:** Community marketplace requests for shopping errands, official documents courier, store logistics, and carpooling.
- **Fields (`board_ads`):**
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | String | Yes | Immutable | Ad ID |
  | `authorId` | String | Yes | Matches `auth.uid` | Author User UID |
  | `type` | String | Yes | Enum: `rideOffer`, `rideRequest`, `localTrip`, `errandService`, `goodsDelivery`, `parcelRequest` | Service type |
  | `authorName` | String | Yes | 2–100 chars | Author display name |
  | `fromCity` | String | Yes | Hub name | Origin |
  | `toCity` | String | Yes | Hub name | Destination |
  | `timeText` | String | Yes | e.g. `اليوم · مساءً` | Schedule description |
  | `description` | String | Yes | <= 1000 chars | Errand / Trip requirements |
  | `budgetPiastres` | Integer | Yes | >= 0 | Offered / requested budget |
  | `status` | String | Yes | Enum: `active`, `offerSent`, `completed`, `expired` | Ad state |
  | `createdAt` | Timestamp | Yes | Server timestamp | Post date |
- **Fields (`board_ads/{adId}/offers/{offerId}`):**
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | String | Yes | Immutable | Offer ID |
  | `driverId` | String | Yes | Driver UID | Courier / Driver UID |
  | `driverName` | String | Yes | 2–100 chars | Driver name |
  | `offerPricePiastres` | Integer | Yes | > 0 | Counter-offer price |
  | `timeText` | String | Yes | Proposed arrival time | Proposed schedule |
  | `status` | String | Yes | Enum: `pending`, `accepted`, `rejected`, `withdrawn` | Offer state |
  | `createdAt` | Timestamp | Yes | Server timestamp | Submission time |

---

#### 5. `parcels` (Collection)
- **Document ID:** `pcl_<uuid>`.
- **Purpose:** Crowd-shipping packages and courier tracking.
- **Fields:**
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | String | Yes | Immutable | Parcel ID |
  | `senderId` | String | Yes | Sender UID | Sender User reference |
  | `driverId` | String | No | Driver UID | Assigned carrier reference |
  | `route` | String | Yes | e.g. `طنطا ← القاهرة` | Delivery route |
  | `description` | String | Yes | Parcel contents | Package description |
  | `size` | String | Yes | Enum: `envelope`, `small`, `medium`, `large` | Package volume |
  | `weightKg` | Number | Yes | > 0.0 (Max: 50.0) | Package weight |
  | `estimatedValuePiastres` | Integer | Yes | Max value for insurance | Declared value |
  | `receiverName` | String | Yes | Receiver legal name | Recipient name |
  | `receiverPhone` | String | Yes | 11 Egyptian digits | Recipient phone |
  | `feePiastres` | Integer | Yes | Delivery fee | Shipping cost |
  | `pickupOtpHash` | String | Yes | SHA-256 / Secure Hash | Handover verification token |
  | `deliveryOtpHash` | String | Yes | SHA-256 / Secure Hash | Delivery confirmation token |
  | `status` | String | Yes | Enum: `requested`, `accepted`, `handedOver`, `inTransit`, `delivered`, `disputed` | Parcel lifecycle state |
  | `createdAt` | Timestamp | Yes | Server timestamp | Creation timestamp |

---

#### 6. `wallet_transactions` (Collection)
- **Document ID:** `tx_<uuid>`.
- **Purpose:** Immutable double-entry financial transaction ledger.
- **Fields:**
  | Field | Type | Required | Constraints | Description |
  |---|---|---|---|---|
  | `id` | String | Yes | Immutable | Transaction ID |
  | `userId` | String | Yes | Owner UID | Target user account |
  | `amountPiastres` | Integer | Yes | Non-zero | Transaction value |
  | `type` | String | Yes | Enum: `deposit`, `withdraw`, `ridePayment`, `rideEarning`, `errandPayment`, `parcelPayment`, `commission` | Transaction type |
  | `method` | String | Yes | Enum: `vodafoneCash`, `instapay`, `fawry`, `creditCard`, `cash` | Payment channel |
  | `referenceNumber` | String | Yes | Unique reference (e.g. `IP-984210`) | External receipt / ref code |
  | `receiptImageUrl` | String | No | Storage URI | Transfer proof image |
  | `status` | String | Yes | Enum: `pending`, `success`, `failed`, `cancelled` | Processing status |
  | `createdAt` | Timestamp | Yes | Server timestamp | Ledger timestamp |

---

#### 7. `conversations` (Collection) & `messages` (Subcollection)
- **Document ID:** `conv_<uuid>` and `conversations/{convId}/messages/{msgId}`.
- **Fields (`conversations`):**
  - `participantIds`: Array of String (e.g. `[user1Id, user2Id]`).
  - `lastMessageText`: String.
  - `lastMessageTimestamp`: Timestamp.
- **Fields (`messages`):**
  - `senderId`: String (must match `auth.uid`).
  - `senderName`: String.
  - `text`: String (1 to 2000 chars).
  - `isRead`: Boolean.
  - `createdAt`: Timestamp.

---

#### 8. `admin_settings` (Collection) & `admin_audit_logs` (Collection)
- **`admin_settings/global`:** Authoritative business rules (commission percentages per service, cancellation thresholds, maximum parcel values).
- **`admin_audit_logs/{logId}`:** Immutable audit trail: `adminId`, `adminEmail`, `action`, `targetEntityId`, `reason`, `ipAddress`, `timestamp`. Direct updates and deletes are strictly prohibited by security rules (`if false;`).
