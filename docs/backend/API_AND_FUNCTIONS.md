# API SPECIFICATIONS & CLOUD FUNCTIONS ARCHITECTURE — MASHWAR PLATFORM

## 1. Architecture Overview
MASHWAR utilizes a hybrid API strategy:
1. **Direct Firestore Real-Time Streams**: For reading public ride listings, parcel boards, in-app messaging, and status listeners.
2. **Callable Cloud Functions (HTTPS API)**: For high-integrity, atomic operations that involve financial balances, verification checks, or external push notifications.

---

## 2. Callable Cloud Functions Specification

### `createRideBooking`
- **Description**: Atomically reserves seats on an active ride, locks passenger wallet funds (if paying via in-app wallet), and sends push notifications to the driver.
- **Caller**: Authenticated passenger (`auth.uid != null`).
- **Request Payload**:
  ```json
  {
    "rideId": "ride_98231",
    "seatsCount": 2,
    "paymentMethod": "wallet", // "wallet" | "cash"
    "pickupNote": "Near Kafr El-Sheikh University gate"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "bookingId": "booking_04812",
    "status": "pending_driver_acceptance",
    "reservedSeats": 2,
    "totalAmountPiastres": 12000
  }
  ```
- **Error Codes**:
  - `failed-precondition`: Not enough seats available or ride has already started.
  - `insufficient-funds`: Passenger wallet balance is below `totalAmountPiastres`.
  - `already-exists`: Passenger already has an active booking on this ride.

---

### `acceptBoardAdOffer`
- **Description**: An advertiser accepts a submitted offer on their board request. Changes offer status to `accepted`, marks other offers as `declined`, and creates a shared direct chat.
- **Caller**: Authenticated owner of the board ad.
- **Request Payload**:
  ```json
  {
    "adId": "board_38210",
    "offerId": "offer_10293"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "chatId": "chat_84719",
    "agreedPricePiastres": 8000
  }
  ```

---

### `completeRideTrip`
- **Description**: Concludes an in-progress ride. Credits driver wallet (minus platform commission), debits passenger wallet (for non-cash trips), and marks the ride `completed`.
- **Caller**: Authenticated driver of the ride.
- **Request Payload**:
  ```json
  {
    "rideId": "ride_98231"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "completedAt": "2026-11-20T23:45:00Z",
    "totalEarningsPiastres": 24000,
    "commissionPiastres": 2400
  }
  ```

---

### `verifyDriverDocuments` (Admin Only)
- **Description**: Approves or rejects a driver's submitted identification and vehicle documents. Updates custom claims and document statuses.
- **Caller**: Admin (`auth.token.admin == true`).
- **Request Payload**:
  ```json
  {
    "userId": "user_49102",
    "status": "approved", // "approved" | "rejected"
    "rejectionReason": null
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "updatedAt": "2026-11-20T23:50:00Z"
  }
  ```

---

## 3. Webhook & Integration Endpoints

### Payment Gateway Webhook (`POST /webhooks/paymentGateway`)
- **Headers**:
  - `x-payment-signature`: HMAC-SHA256 signature for payload verification.
- **Payload**:
  ```json
  {
    "transactionId": "pay_984128",
    "userId": "user_19283",
    "amountPiastres": 50000,
    "currency": "EGP",
    "status": "captured"
  }
  ```
- **Action**: Verifies cryptographic signature, verifies against replay attacks, increments `user.wallet_balance_piastres`, and appends to `wallet_transactions`.
