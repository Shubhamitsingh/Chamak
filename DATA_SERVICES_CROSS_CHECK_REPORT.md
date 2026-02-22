# Data Services Cross-Check Report
## All Data & Firebase Configuration Verified

**Date:** Generated  
**Project:** Chamak (com.chamakz.app)  
**Firebase Project:** chamak-39472 (old project – kept as per your choice)

---

## 1. Firebase configuration – consistent

| File | Project ID | Status |
|------|------------|--------|
| `lib/firebase_options.dart` | chamak-39472 | OK |
| `android/app/google-services.json` | chamak-39472 | OK |
| `lib/main.dart` | Uses `DefaultFirebaseOptions.currentPlatform` | OK |

- App uses a single Firebase project: **chamak-39472**.
- Android and web options both point to the same project.
- No mix of old/new project IDs in app code.

---

## 2. Firebase initialization – correct

**Location:** `lib/main.dart` (lines 64–66)

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

- Runs before `runApp()`.
- Uses platform-specific options (Android/Web).
- All services (Auth, Firestore, Storage, etc.) use this default app.

---

## 3. Authentication – wired correctly

| Auth type | Where used | Service / API |
|-----------|------------|----------------|
| Phone OTP | `login_screen.dart`, `otp_screen.dart`, `account_security_screen.dart` | `FirebaseAuth.instance.verifyPhoneNumber` / `signInWithCredential` |
| Email/Password | `email_login_screen.dart` | `FirebaseAuth.instance.signInWithEmailAndPassword` / `createUserWithEmailAndPassword` |
| Google Sign-In | `splash_screen.dart` | `FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(...))` |
| Current user | All screens/services | `FirebaseAuth.instance.currentUser` |

- All use `FirebaseAuth.instance` (default app) → same project chamak-39472.
- No hardcoded project or auth config elsewhere.

---

## 4. Firestore (database) – consistent

**Default instance:** All code uses `FirebaseFirestore.instance` (no secondary app).

| Service / file | Collection(s) / usage | Status |
|----------------|------------------------|--------|
| `database_service.dart` | `users` (create/update, get) | OK |
| `coin_service.dart` | `users` (uCoins, balance) | OK |
| `chat_service.dart` | `chats`, `chats/{id}/messages` | OK |
| `live_stream_service.dart` | `live_streams` | OK |
| `payment_service.dart` | payments/orders related | OK |
| `gift_service.dart` | gifts | OK |
| `follow_service.dart` | `users/{id}/following`, `users/{id}/followers` | OK |
| `notification_service.dart` | `users` (FCM token) | OK |
| `wallet_screen.dart`, `transaction_history_screen.dart` | `users`, transactions | OK |
| `admin_service.dart`, `admin_panel_screen.dart` | `admins`, multiple admin collections | OK |
| Others (feedback, support, banners, etc.) | As per design | OK |

- Single Firestore instance → all data goes to **chamak-39472** Firestore.
- No alternate project or database name in code.

---

## 5. Firebase Storage – correct

**Location:** `lib/services/storage_service.dart`

- Uses `FirebaseStorage.instance` and `FirebaseAuth.instance`.
- Paths used:
  - `profile_pictures/{userId}/`
  - `cover_photos/{userId}/`
  - `chat_images/{userId}/`
  - Other paths as in your `storage.rules`.

Storage is tied to the default app → **chamak-39472** Storage bucket. No conflicting config found.

---

## 6. Realtime Database (live stream chat) – matches project

**Location:** `lib/services/realtime_chat_service.dart` (line 21)

```dart
final databaseURL = 'https://chamak-39472-default-rtdb.asia-southeast1.firebasedatabase.app';
```

- URL is for project **chamak-39472** and region **asia-southeast1**.
- Matches the Realtime Database URL for the same project (e.g. in `google-services.json`).
- If you ever switch Firebase project, this URL would need to be updated to the new project’s Realtime Database URL.

---

## 7. User creation (phone vs email/Google) – both paths covered

| Flow | Method | Called from |
|------|--------|-------------|
| Phone OTP | `DatabaseService.createOrUpdateUser(phoneNumber, countryCode)` | `otp_screen.dart`, `user_profile_view_screen.dart` |
| Email / Google | `DatabaseService.createOrUpdateUserWithEmail(email, displayName, photoURL)` | `email_login_screen.dart`, `splash_screen.dart` (Google) |

- New users get a document in `users` with correct fields.
- Existing users get last login (and missing fields) updated.
- Single source of truth for profile/coins is `users` (and `coin_service` reads from there). No conflicting logic found.

---

## 8. Critical data flows – summary

| Flow | Data path | Status |
|------|-----------|--------|
| Login (phone) | Auth → `createOrUpdateUser` → `users` | OK |
| Login (email/Google) | Auth → `createOrUpdateUserWithEmail` → `users` | OK |
| Coins / balance | `CoinService` → `users/{uid}` (uCoins/coins) | OK |
| Profile read/update | `DatabaseService` → `users/{uid}` | OK |
| Live streams | `live_stream_service` / Firestore `live_streams` | OK |
| Live chat | `RealtimeChatService` → Realtime DB (chamak-39472 URL) | OK |
| Chats (1:1) | `chat_service` → Firestore `chats` + `messages` | OK |
| Gifts / payments | Respective services → Firestore | OK |
| Notifications | FCM + `users` (FCM token) | OK |
| Admin | `admins` + admin-only collections | OK |

All of these use the same Firebase project (chamak-39472).

---

## 9. What to verify in Firebase Console (chamak-39472)

Do a quick check in the Firebase Console for project **chamak-39472**:

- **Authentication**
  - Sign-in methods: Phone, Email/Password, Google – enabled as you use them.
  - No unexpected “disabled” providers.
- **Firestore**
  - Rules: Published and not in “test mode” unless intended.
  - At least collections: `users`, `live_streams`, `chats`, `admins` (and any other you use).
- **Storage**
  - Rules: Published; paths match `profile_pictures`, `cover_photos`, `chat_images`, etc.
- **Realtime Database**
  - Exists in region **asia-southeast1**.
  - URL matches: `https://chamak-39472-default-rtdb.asia-southeast1.firebasedatabase.app`.
  - Rules: Published and allow only what you need.

---

## 10. Summary

- **Firebase project:** All app code and config point to **one** project: **chamak-39472**.
- **Auth:** Phone, Email, Google all use the same Firebase Auth.
- **Firestore:** Single instance; all collections in the same project.
- **Storage:** Single bucket for the app.
- **Realtime DB:** Explicit URL matches chamak-39472.
- **User creation:** Both phone and email/Google paths create/update `users` correctly.
- **Coins / profile:** Read/write from `users` only; no conflicting sources.

No configuration or “data connection” errors were found in code. If something still fails (e.g. “quota exceeded”, permission denied), it will be due to Firebase Console (rules, quotas, or project state), not a wrong project or missing link in the app.

---

## 11. If you change Firebase project later

- Run `flutterfire configure --project=<new_project_id>` and replace `google-services.json`.
- Update the Realtime Database URL in `lib/services/realtime_chat_service.dart` to the new project’s URL.
- Redeploy Firestore and Storage rules to the new project.
- Re-test Auth, Firestore, Storage, and live stream chat.

For your current setup (keeping old Firebase), no code or config changes are required for “data working correctly”; everything is aligned to **chamak-39472**.
