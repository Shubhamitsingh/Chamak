# 🔧 Step-by-Step Fix - Complete Guide

## 📋 **YOUR SHA FINGERPRINTS:**

### **DEBUG Keystore (for testing):**
- **SHA-1:** `CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC`
- **SHA-256:** `A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C`

### **RELEASE Keystore (for production):**
- **SHA-1:** `81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71`
- **SHA-256:** `11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB`

---

## ✅ **STEP 1: Open Firebase Console**

1. Go to: https://console.firebase.google.com/
2. Select your project: **chamak-39472**

---

## ✅ **STEP 2: Go to Project Settings**

1. Click **⚙️ Settings** (gear icon) in the top left
2. Click **Project settings**

---

## ✅ **STEP 3: Find Your Android App**

1. Scroll down to **"Your apps"** section
2. Find **Android app: com.chamakz.app**
3. Click on it

---

## ✅ **STEP 4: Add DEBUG SHA Fingerprints**

**You're running debug builds, so you NEED these!**

1. Scroll to **"SHA certificate fingerprints"** section
2. Click **"Add fingerprint"** button
3. Paste: `CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC`
4. Click **Save**

5. Click **"Add fingerprint"** again
6. Paste: `A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C`
7. Click **Save**

---

## ✅ **STEP 5: Add RELEASE SHA Fingerprints**

**For production builds:**

1. Click **"Add fingerprint"** button
2. Paste: `81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71`
3. Click **Save**

4. Click **"Add fingerprint"** again
5. Paste: `11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB`
6. Click **Save**

---

## ✅ **STEP 6: Download NEW google-services.json**

**CRITICAL - DO THIS AFTER ADDING ALL FINGERPRINTS!**

1. In the same page, find **"google-services.json"** file
2. Click the **download icon** (⬇️) next to it
3. The file will download to your computer

---

## ✅ **STEP 7: Replace Old google-services.json**

1. Open File Explorer
2. Go to: `C:\Users\Shubham Singh\Desktop\chamak\android\app\`
3. **Delete** the old `google-services.json` file
4. **Copy** the new downloaded `google-services.json` file
5. **Paste** it in: `C:\Users\Shubham Singh\Desktop\chamak\android\app\`

---

## ✅ **STEP 8: Clean and Rebuild**

**Open PowerShell and run:**

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter clean
flutter pub get
flutter run
```

---

## ✅ **STEP 9: Wait for Firebase Propagation**

**IMPORTANT:**
- After adding fingerprints, wait **10-30 minutes**
- Firebase needs time to propagate changes globally
- Don't test immediately!

---

## 📋 **CHECKLIST:**

- [ ] ✅ Opened Firebase Console
- [ ] ✅ Went to Project Settings
- [ ] ✅ Found Android app: com.chamakz.app
- [ ] ✅ Added DEBUG SHA-1: `CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC`
- [ ] ✅ Added DEBUG SHA-256: `A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C`
- [ ] ✅ Added RELEASE SHA-1: `81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71`
- [ ] ✅ Added RELEASE SHA-256: `11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB`
- [ ] ✅ Downloaded NEW google-services.json
- [ ] ✅ Replaced old google-services.json
- [ ] ✅ Ran `flutter clean`
- [ ] ✅ Ran `flutter pub get`
- [ ] ✅ Waited 10-30 minutes
- [ ] ✅ Ran `flutter run`

---

## 🎯 **WHY IT WAS FAILING:**

**You were running debug builds (`flutter run`) but only had RELEASE SHA fingerprints in Firebase!**

- **Debug builds** use debug keystore → Need DEBUG SHA fingerprints
- **Release builds** use release keystore → Need RELEASE SHA fingerprints
- **You need BOTH** in Firebase Console!

---

## ✅ **SUMMARY:**

1. Add **all 4 SHA fingerprints** to Firebase Console
2. Download **NEW google-services.json**
3. Replace old file
4. Clean and rebuild
5. Wait 10-30 minutes
6. Test again

**This will fix the error!** 🚀

















