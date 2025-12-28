# 🔥 Fix Firebase Authentication Error

## ❌ Error Message:
```
This app is not authorized to use Firebase Authentication. 
Please verify that the correct package name, SHA-1, and SHA-256 are configured in the Firebase Console.
[ A play_integrity_token was passed, but no matching SHA-256 was registered in the Firebase console. ]
```

## 🔍 Root Cause:
1. **Package name changed** from `com.chamakz.app` → `com.chamak.app`
2. **SHA-256 fingerprint** for release keystore is **NOT registered** in Firebase Console
3. Firebase Console still has old package name or missing SHA-256

---

## ✅ Solution: Add SHA Fingerprints to Firebase Console

### Step 1: Get Your SHA Fingerprints

**Release Keystore SHA-256:**
```
11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB
```

**Release Keystore SHA-1:**
```
81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71
```

**Debug Keystore SHA-1:**
```
CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC
```

---

### Step 2: Update Firebase Console

1. **Go to Firebase Console:**
   - https://console.firebase.google.com
   - Select project: **chamak-39472**

2. **Go to Project Settings:**
   - Click gear icon ⚙️ → **Project settings**

3. **Find Your Android App:**
   - Look for app with package name: `com.chamak.app`
   - If it doesn't exist, **add a new Android app**:
     - Click **"Add app"** → Android icon
     - Package name: `com.chamak.app`
     - App nickname: `Chamakz` (optional)
     - Click **"Register app"**

4. **Add SHA Fingerprints:**
   - Scroll down to **"Your apps"** section
   - Find the app with package name `com.chamak.app`
   - Click **"Add fingerprint"** button
   - Add **SHA-1** (release): `81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71`
   - Click **"Add fingerprint"** again
   - Add **SHA-256** (release): `11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB`
   - Click **"Add fingerprint"** again (optional, for debug builds)
   - Add **SHA-1** (debug): `CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC`
   - Click **"Save"**

5. **Download New google-services.json:**
   - After adding fingerprints, click **"Download google-services.json"**
   - Replace the file at: `android/app/google-services.json`

---

### Step 3: Verify Package Name

Make sure `google-services.json` has the correct package name:

1. Open `android/app/google-services.json`
2. Check that it contains:
   ```json
   "package_name": "com.chamak.app"
   ```
3. If it shows `com.chamakz.app`, update it or download the new file from Firebase Console

---

### Step 4: Rebuild and Test

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

Or for testing:
```powershell
flutter run --release
```

---

## 📝 Summary:

✅ **Package Name:** `com.chamak.app`  
✅ **SHA-256 (Release):** `11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB`  
✅ **SHA-1 (Release):** `81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71`  
✅ **SHA-1 (Debug):** `CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC`

**Action Required:** Add both SHA fingerprints to Firebase Console for package `com.chamak.app`

---

## ⚠️ Important Notes:

- **SHA-256 is REQUIRED** for Play Integrity (used in production/release builds)
- **SHA-1 is REQUIRED** for Firebase Authentication (used in debug builds)
- Both must be added to Firebase Console
- After adding, download new `google-services.json` and replace the old one
- Rebuild the app after updating Firebase configuration

