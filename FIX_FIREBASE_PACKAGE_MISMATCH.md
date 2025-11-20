# 🔧 Fix Firebase Package Name Mismatch

## ❌ **Problem Found:**

Your Firebase Console shows:
- **Package Name:** `com.example.live_vibe` ❌

But your app uses:
- **Package Name:** `com.chamak.app` ✅

**This mismatch is causing the "missing-client-identifier" error!**

---

## ✅ **SOLUTION: Add New Android App in Firebase**

You need to **add a NEW Android app** with the correct package name `com.chamak.app`.

---

## 📝 **STEP-BY-STEP FIX:**

### **STEP 1: Add New Android App**

1. In Firebase Console (where you are now)
2. Click **"Add app"** button (top right corner)
3. Click **Android** icon (robot icon)
4. Fill in the form:
   - **Android package name:** `com.chamak.app` ✅
   - **App nickname (optional):** `Chamak App` or leave blank
   - **Debug signing certificate SHA-1:** `CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC`
5. Click **"Register app"**

### **STEP 2: Download google-services.json**

1. After registering, Firebase will show you the `google-services.json` file
2. Click **"Download google-services.json"** button
3. **Replace** the file at: `android/app/google-services.json` in your project

### **STEP 3: Add SHA-256 Fingerprint**

1. In Firebase Console, go to **Project Settings** → **Your apps**
2. Find the **NEW** app: `com.chamak.app` (should be listed now)
3. Click on it
4. Scroll to **"SHA certificate fingerprints"**
5. Click **"Add fingerprint"**
6. Paste SHA-256: `A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C`
7. Click **"Save"**

### **STEP 4: Download Updated google-services.json Again**

1. Still in the `com.chamak.app` app settings
2. Click **"Download google-services.json"** again (to get SHA-256 included)
3. **Replace** `android/app/google-services.json` in your project

### **STEP 5: Enable Phone Authentication**

1. Go to **Authentication** → **Sign-in method**
2. Click **Phone**
3. Toggle **"Enable"** to ON
4. Click **"Save"**

---

## 🔍 **Verify Everything:**

### **In Firebase Console:**
- ✅ You should see **TWO** Android apps:
  - `com.example.live_vibe` (old one - can ignore)
  - `com.chamak.app` (new one - this is the one you'll use) ✅
- ✅ `com.chamak.app` has both SHA-1 and SHA-256 fingerprints
- ✅ Phone Authentication is enabled

### **In Your Project:**
- ✅ `android/app/google-services.json` has `package_name: "com.chamak.app"`
- ✅ `android/app/build.gradle` has `applicationId = "com.chamak.app"`

---

## 🧪 **After Fixing:**

```powershell
flutter clean
flutter pub get
flutter run
```

Test phone authentication - it should work now! ✅

---

## ⚠️ **Important Notes:**

- **Keep the old app** (`com.example.live_vibe`) in Firebase - don't delete it
- **Use the new app** (`com.chamak.app`) for your current project
- Make sure you download `google-services.json` from the **NEW** app (`com.chamak.app`), not the old one

---

## 📋 **Quick Checklist:**

- [ ] Added new Android app with package name `com.chamak.app`
- [ ] Added SHA-1 fingerprint during registration
- [ ] Downloaded `google-services.json` from NEW app
- [ ] Added SHA-256 fingerprint to NEW app
- [ ] Downloaded updated `google-services.json` again
- [ ] Replaced `android/app/google-services.json` in project
- [ ] Enabled Phone Authentication
- [ ] Clean build: `flutter clean && flutter pub get`
- [ ] Test app

---

**Status:** Follow these steps and the error will be fixed! ✅

