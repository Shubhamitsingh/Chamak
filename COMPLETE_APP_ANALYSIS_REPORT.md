# Chamak — Complete App Report (Screens, Widgets, Database, Cloud Functions)

Generated: 2026-01-07  
Scope: Flutter app (`lib/`), Firestore Rules (`firestore.rules`), Cloud Functions (`functions/index.js`)

---

## 1) App entry + global setup (what starts first, and why)

### 1.1 `lib/main.dart`
- **Starts Firebase**: `Firebase.initializeApp(...)`
- **Locks portrait mode**: `SystemChrome.setPreferredOrientations(...)`
- **Sets global theme**: Material 3 + **Poppins** via `GoogleFonts.poppinsTextTheme(...)`
- **Localization**: `AppLocalizations` + `LanguageProvider` (multiple Indian languages)
- **Home widget**: `IntroLogoScreen` (first screen shown)
- **Notifications**: Initializes `NotificationService().initialize()` in a non-blocking way

Why: keeps startup fast, sets consistent UI and localization, and ensures Firebase is available for auth/db/payment.

---

## 2) Login + onboarding flow (step-by-step)

### Step 1 — `IntroLogoScreen` (`lib/screens/intro_logo_screen.dart`)
**Purpose**: Animated logo + decide where to go next.

Decision logic:
- If `FirebaseAuth.instance.currentUser` exists:
  - Reads `users/{uid}` and checks `profileCompleted`
  - If `profileCompleted == true` → go to **Home**
  - Else → go to **Set Profile**
- Else → go to **Splash**

Why: one place to decide “already logged in?” and “profile complete?”.

### Step 2 — `SplashScreen` (`lib/screens/splash_screen.dart`)
**Purpose**: Brand splash + “Continue with Phone” CTA.

Logic:
- If user already logged in, it repeats the same `profileCompleted` check and auto-navigates.
- If not logged in, user presses button → `LoginScreen`.

Why: good UX (auto-skip login for returning users).

### Step 3 — `LoginScreen` (`lib/screens/login_screen.dart`)
**Purpose**: Phone number input + Firebase Phone Auth.

Logic:
- Validates phone
- Calls `FirebaseAuth.instance.verifyPhoneNumber(...)`
- On `codeSent` → navigates to `OtpScreen(...)`

Why: secure login using SMS OTP (Firebase handles SMS + verification).

### Step 4 — `OtpScreen` (`lib/screens/otp_screen.dart`)
**Purpose**: OTP entry, sign-in, and create/update Firestore user.

Logic:
- Uses `PhoneAuthProvider.credential(...)`
- `FirebaseAuth.instance.signInWithCredential(...)`
- Calls `DatabaseService.createOrUpdateUser(...)` to create `users/{uid}` if missing
- Reads `users/{uid}.profileCompleted`
  - If true → **Home**
  - Else → **Set Profile**

Why: ensures every authenticated user has a Firestore profile document.

### Step 5 — `SetProfileScreen` (`lib/screens/set_profile_screen.dart`)
**Purpose**: Complete profile (nickname, gender, DOB, language).

Writes to Firestore:
- Updates `users/{uid}` and sets:
  - `displayName`, `nickname`, `gender`, `dateOfBirth`, `age`, `language`
  - `profileCompleted: true`, `profileCompletedAt`
- Then navigates to **Home**

Why: app needs profile fields for chat, live streams, display, etc.

---

## 3) Main user flow (high level)

### `HomeScreen` (`lib/screens/home_screen.dart`)
**Purpose**: Main hub.
- Shows live streams list (from Firestore `live_streams`)
- Opens live stream screen (`AgoraLiveStreamScreen`)
- Opens wallet (`WalletScreen`)
- Opens chats (`ChatListScreen`)
- Opens profile (`ProfileScreen`)
- Uses:
  - `LiveStreamService` (streams feed)
  - `AnnouncementPanel` (announcements drawer)
  - `CoinPurchasePopup` (promotional purchase bottom sheet)
  - `LiveStreamPreviewCard` (video preview cards)

### `ProfileScreen` (`lib/screens/profile_screen.dart`)
**Purpose**: Profile hub and navigation to account settings features.
- Opens edit profile, wallet, earnings, settings, security, support, etc.
- Reads real-time user info from Firestore.

---

## 4) Payments + Wallet flow (PayPrime)

### Step A — `WalletScreen` (`lib/screens/wallet_screen.dart`)
**Purpose**: Show U Coins balance, packages, and start recharge.

Key points:
- **Primary balance source**: `users/{uid}.uCoins`
- Starts PayPrime payment via `PayPrimePaymentService.initiatePayment(...)`
- Navigates to:
  - `UpiPaymentSelectionScreen` (if multiple UPI URLs)
  - OR `PayPrimePaymentWebViewScreen` (web redirect or single UPI URL)

### Step B — `UpiPaymentSelectionScreen` (`lib/screens/upi_payment_selection_screen.dart`)
**Purpose**: Choose UPI app (GPay + Generic UPI).
- Launches UPI intent via `url_launcher`
- Listens to Firestore `payments/{paymentId}`:
  - On `SUCCESS`: shows success dialog → auto return to wallet
  - On `FAILED`: shows failure → return
- Back/close shows **bottom exit confirmation** (Paytm-style slide up)

### Step C — `PayPrimePaymentWebViewScreen` (`lib/screens/payprime_payment_webview_screen.dart`)
**Purpose**: WebView for PayPrime checkout OR direct UPI intent launch.
- If URL is `upi://` / `gpay://` / `intent://` → launches external app
- Otherwise loads web page in WebView
- Listens to Firestore `payments/{paymentId}`:
  - On `SUCCESS`: shows success dialog → auto return to wallet

### Cloud side (important)
- `initiatePayment` Cloud Function creates `payments/{paymentId}` and calls PayPrime
- `payprimeWebhook` updates `payments/{paymentId}.status` and **increments**:
  - `users/{uid}.uCoins` (primary wallet field)
  - `users/{uid}.coinBalance` (legacy/compat)

---

## 5) Live streaming + calls (Agora)

### `AgoraLiveStreamScreen` (`lib/screens/agora_live_stream_screen.dart`)
**Purpose**: Live streaming host/viewer screen.
- Uses Agora RTC Engine
- Uses Firestore for:
  - `live_streams/{streamId}`
  - `live_streams/{streamId}/chat` (live chat messages)
  - `live_streams/{streamId}/viewers` (audience list)
- Uses:
  - `AgoraTokenService` → calls Cloud Function `generateAgoraToken`
  - `FollowService` → follow/unfollow
  - `CallRequestService` → private call requests
  - `CallCoinDeductionService` → coins deduction per minute (viewer side)
  - `GiftSelectionSheet` + `GiftService` for gifts
  - `LowCoinPopup` when user lacks coins
  - `ViewerListSheet` to show viewers
  - `CallRequestDialog` for host incoming calls
  - `CallStatusOverlay` to show host busy

Why: main real-time feature set (live video + chat + gifting + private calls).

---

## 6) Chat system (1-to-1)

### `ChatListScreen` (`lib/screens/chat_list_screen.dart`)
- Streams chats via `ChatService.getUserChats(userId)`
- Opens `ChatScreen`
- Can start new chat via `UserSearchScreen`

### `ChatScreen` (`lib/screens/chat_screen.dart`)
- Streams messages `chats/{chatId}/messages`
- Sends message via `ChatService.sendMessage(...)`
- **Safety**: blocks digits/number words to prevent phone number sharing

### `ChatService` (`lib/services/chat_service.dart`)
Firestore structure:
- `chats/{chatId}`:
  - `participants: [uid1, uid2]`
  - `unreadCount: { uid: number }`
  - `participantNames`, `participantImages`, `lastMessage`, etc.
- `chats/{chatId}/messages/{messageId}`

Notifications:
- Creates notification request via `NotificationService` → Cloud Function sends FCM.

---

## 7) All screens (what they are for)

### Authentication / onboarding
- `intro_logo_screen.dart`: decides next screen based on auth + profile
- `splash_screen.dart`: splash + continue to login
- `login_screen.dart`: phone auth (send OTP)
- `otp_screen.dart`: verify OTP + create Firestore user doc
- `set_profile_screen.dart`: complete profile

### Core navigation / discovery
- `home_screen.dart`: main hub (streams, profile, wallet, chats)
- `search_screen.dart`, `user_search_screen.dart`: search users
- `user_profile_view_screen.dart`: view another user profile

### Live / streaming / calls
- `agora_live_stream_screen.dart`: host/viewer live screen
- `private_call_screen.dart`: private video call UI
- `live_page.dart`: (live tab / live content wrapper)
- `live_stream_summary_screen.dart`: stream end summary
- `host_rules_screen.dart`: host rules
- `warning_screen.dart`: warnings/violations UI

### Wallet / payments
- `wallet_screen.dart`: balance + packages + recharge
- `coin_purchase_history_screen.dart`: payment history (reads `payments`)
- `transaction_history_screen.dart`: wallet/earnings transactions view
- `payment_success_screen.dart`: payment success UI (legacy/support)
- `upi_payment_selection_screen.dart`: UPI selection + listener
- `payprime_payment_webview_screen.dart`: WebView/UPI payment + listener

### Profile / settings / legal
- `profile_screen.dart`: profile hub
- `edit_profile_screen.dart`: edit profile (uses Storage + DB)
- `settings_screen.dart`: settings list
- `language_selection_screen.dart`: app UI language
- `notification_settings_screen.dart`: notification settings
- `account_security_screen.dart`: security settings
- `kyc_verification_screen.dart`: KYC UI
- `terms_conditions_screen.dart`, `privacy_policy_screen.dart`, `about_screen.dart`, `feedback_screen.dart`, `help_feedback_screen.dart`

### Admin
- `admin_panel_screen.dart`: admin tools (add coins, support chats, withdrawals)
- `admin_support_chat_screen.dart`: admin side support chat UI
- `contact_support_screen.dart`, `contact_support_chat_screen.dart`: user support UI

---

## 8) Widgets (where used and why)

- `AnnouncementPanel`: used in `HomeScreen` → shows announcements drawer
- `CoinPurchasePopup`: used in `HomeScreen` → promotional purchase offer bottom sheet
- `LiveStreamPreviewCard`: used in `HomeScreen` → shows live preview cards using Agora
- `GiftSelectionSheet`: used in `AgoraLiveStreamScreen` → select gifts and validate balance
- `LiveChatPanel`: live chat overlay widget (used by live stream UI)
- `LowCoinPopup`: used in `AgoraLiveStreamScreen` → prompts recharge if balance low
- `ViewerListSheet`: used in `AgoraLiveStreamScreen` → shows viewers list
- `CallRequestDialog`: used in `AgoraLiveStreamScreen` → host incoming call dialog
- `CallStatusOverlay`: used in `AgoraLiveStreamScreen` → host busy overlay
- `EndStreamConfirmationSheet`: used in `AgoraLiveStreamScreen` → confirm stream end
- `BouncyIconButton`: used in `AgoraLiveStreamScreen` → animated icon taps
- `LiveStreamChatWidget`: standalone UI-only live chat widget (not Firestore-based)

---

## 9) Database (Firestore) — collections, structure, and why

### 9.1 Collections used (from code + rules)

**User + wallet**
- `users/{userId}`: main user profile and **uCoins** balance
  - common fields: `displayName`, `photoURL`, `numericUserId`, `uCoins`, `profileCompleted`, `fcmToken`
- `wallets/{userId}`: legacy mirror / secondary storage of balance (read-only for normal users by rules)
- `users/{userId}/following/{targetUserId}` and `users/{userId}/followers/{followerId}`: follow system
- `users/{userId}/transactions/*`: legacy transaction records (rules: read-only to user)
- `users/{userId}/coinTransactions/*`: coin purchase logs (Cloud Functions writes)

**Payments**
- `payments/{paymentId}`: PayPrime payment state machine (PENDING → PROCESSING → SUCCESS/FAILED)
- `orders/{orderId}`: order tracking (limited user updates allowed by rules)

**Live**
- `live_streams/{streamId}`: live stream metadata
- `live_streams/{streamId}/chat/{messageId}`: live chat messages
- `live_streams/{streamId}/viewers/{viewerId}`: viewers list (note: rules currently do **not** include this subcollection explicitly)

**Chat**
- `chats/{chatId}`: 1-to-1 chat metadata
- `chats/{chatId}/messages/{messageId}`: chat messages

**Support**
- `supportChats/{chatId}` + `supportChats/{chatId}/messages/{messageId}`: support chat system
- `withdrawal_requests/{requestId}`: host withdrawals
- `earnings/{userId}`: host earnings (C-coins summary)
- `gifts/{giftId}`: gift transactions

**Admin/system**
- `admins/{uid}`: admin access control
- `adminActions/{actionId}`: audit log
- `notificationRequests/{requestId}`: queue for Cloud Function push notifications
- `reports/{reportId}`: user reports/abuse reports
- `announcements/{announcementId}` and `events/{eventId}`: admin content

### 9.2 Collections used in code but NOT present in `firestore.rules` (important)
These are referenced in Flutter code, but Firestore Rules default-deny unknown collections, so they will fail unless rules are added:
- `promotions/*`
- `share_tracking/*`
- `supportTickets/*` (used by `SupportService`)
- `calls/*` (used by `CallService`)
- `callRequests/*` (used by `CallRequestService`)
- `live_stream_chat/*` (used by `LiveStreamChatService`)
- `live_streams/{streamId}/viewers/*` (subcollection not explicitly allowed in rules)

---

## 10) Firestore security rules (what is allowed and why)

File: `firestore.rules`

High-level policy:
- **Users can read profiles** (`users/*`) because app needs public profile info for chat/search/live.
- **Users can only edit their own profile** and are blocked from directly writing coin fields.
- **Payments & coin transactions are server-controlled** (client cannot write `payments` / `coinTransactions`).
- **Chats**: only participants can read/write chat docs and messages.
- **Announcements/events**: public read, admin write.
- **SupportChats**: user can access their own support chat; admin can access all.
- **Default deny** for unknown collections.

---

## 11) Cloud Functions (backend) — what exists and how it’s used

File: `functions/index.js`

### 11.1 `sendMessageNotification` (Firestore trigger)
- Trigger: `notificationRequests/{requestId}` created
- Sends FCM using Admin SDK
- Marks request as processed

### 11.2 `cleanupOldNotifications` (scheduled)
- Runs daily
- Deletes processed notification requests older than 7 days

### 11.3 `sendFollowerNotification` (Firestore trigger)
- Trigger: `users/{userId}/followers/{followerId}` created
- Sends “New follower” notification to followed user

### 11.4 `testNotification` (callable)
- Manual test function to send FCM to a token

### 11.5 `generateAgoraToken` (callable)
- Called from Flutter `AgoraTokenService`
- Uses secrets `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE`
- Returns token + expiry

### 11.6 `initiatePayment` (callable)
- Called from Flutter `PayPrimePaymentService`
- Creates `payments/{paymentId}` in Firestore
- Calls PayPrime API (form-urlencoded)
- Returns `paymentUrl` + `upiUrls`

### 11.7 `payprimeWebhook` (HTTP endpoint)
- Called by PayPrime gateway (webhook/IPN)
- Validates signature (HMAC)
- Updates payment status in Firestore
- On success increments `users/{uid}.uCoins` and logs `users/{uid}/coinTransactions`

### 11.8 `reconcilePayments` (scheduled)
- Finds stuck payments, marks very old ones failed

---

## 12) Where login state is checked (and why)

- `IntroLogoScreen` and `SplashScreen`: reads `FirebaseAuth.currentUser` to auto-route.
- `WalletScreen`, `AgoraLiveStreamScreen`, chat screens: check `_auth.currentUser` to gate actions.
- `PayPrimePaymentService` and `AgoraTokenService` require authenticated user (Cloud Functions enforce it too).

Why: prevents unauthenticated writes/reads and ensures functions can trust `request.auth.uid`.

---

## 13) Suggested “single source of truth” notes (important for stability)

- **User coin balance**: `users/{uid}.uCoins` is the primary source (wallet screen listens to it).
- **Payment success**: `payments/{paymentId}.status` from webhook is the source of truth (client only listens).
- **Host earnings**: `earnings/{uid}.totalCCoins` (service code treats this as the source of truth).

---

## 14) Next step (optional)

If you want every feature to work fully (calls/promotions/supportTickets/live_stream_chat/viewers), we should add Firestore rules for:
- `promotions`, `share_tracking`, `supportTickets`, `calls`, `callRequests`, `live_stream_chat`, and `live_streams/{streamId}/viewers`.

