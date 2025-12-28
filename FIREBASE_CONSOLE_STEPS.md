# 🔥 Firebase Console Setup Steps

## 📸 What I See in Your Firebase Console:

✅ **Current App:** `com.chamakz.app`  
❌ **Your App Now Uses:** `com.chamak.app`  
❌ **Missing:** Release SHA fingerprints

---

## ✅ Solution: Add New Android App

Since your app now uses `com.chamak.app` (for Play Console), you need to **add a NEW Android app** in Firebase with this package name.

### Step 1: Add New Android App

1. In Firebase Console, click the **"Add app"** button (top right, blue button)
2. Select **Android icon** (Android app)
3. Fill in:
   - **Android package name:** `com.chamak.app`
   - **App nickname (optional):** `Chamakz Release` or `Chamakz Production`
   - **Debug signing certificate SHA-1 (optional):** Leave empty for now
4. Click **"Register app"**

---

### Step 2: Add Release SHA Fingerprints

After creating the new app, you'll see the app settings page. Scroll down to **"SHA certificate fingerprints"** section.

1. Click **"Add fingerprint"** button
2. Add **SHA-1 (Release):**
   ```
   81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71
   ```
3. Click **"Add fingerprint"** again
4. Add **SHA-256 (Release):**
   ```
   11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB
   ```
5. Click **"Save"**

---

### Step 3: Download New google-services.json

1. On the same page, find **"SDK setup and configuration"** section
2. Click **"google-services.json"** button (download icon)
3. **Replace** the file at: `android/app/google-services.json` with the new downloaded file

---

### Step 4: Verify google-services.json

Open `android/app/google-services.json` and check it contains:

```json
"package_name": "com.chamak.app"
```

---

## 📋 Summary:

**Current Firebase App:**
- Package: `com.chamakz.app` ❌ (old, doesn't match your app)

**New Firebase App (Create This):**
- Package: `com.chamak.app` ✅ (matches your app)
- SHA-1: `81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71`
- SHA-256: `11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB`

---

## 🔄 After Setup:

1. **Rebuild your app:**
   ```powershell
   flutter clean
   flutter pub get
   flutter run --release
   ```

2. **The Firebase Authentication error should be fixed!** ✅

---

## ⚠️ Note:

You can keep both apps in Firebase:
- `com.chamakz.app` (old, for reference)
- `com.chamak.app` (new, active app)

This won't cause any issues. Firebase supports multiple apps in the same project.


















