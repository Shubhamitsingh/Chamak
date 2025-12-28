# 🔑 Get All SHA Fingerprints - Step by Step

## 📋 **WHAT YOU NEED:**

You need **TWO sets** of SHA fingerprints:
1. **DEBUG keystore** (for testing with `flutter run`)
2. **RELEASE keystore** (for production builds)

---

## ✅ **STEP 1: Get DEBUG SHA Fingerprints**

**Run this command in PowerShell:**
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Look for:**
- **SHA1:** (copy the full value)
- **SHA256:** (copy the full value)

---

## ✅ **STEP 2: Get RELEASE SHA Fingerprints**

**Run this command in PowerShell:**
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "C:\Users\Shubham Singh\upload-keystore.jks" -alias upload -storepass Shubham@18 -keypass Shubham@18
```

**Look for:**
- **SHA1:** (copy the full value)
- **SHA256:** (copy the full value)

---

## ✅ **STEP 3: Add Both to Firebase Console**

1. Go to **Firebase Console**
2. Select your project: **chamak-39472**
3. Click **⚙️ Settings** → **Project settings**
4. Scroll down to **Your apps**
5. Click on **Android app: com.chamakz.app**
6. Scroll to **SHA certificate fingerprints**
7. Click **Add fingerprint**
8. Add **DEBUG SHA-1**
9. Click **Add fingerprint**
10. Add **DEBUG SHA-256**
11. Click **Add fingerprint**
12. Add **RELEASE SHA-1** (if not already there)
13. Click **Add fingerprint**
14. Add **RELEASE SHA-256** (if not already there)

---

## ✅ **STEP 4: Download NEW google-services.json**

**CRITICAL:**
1. After adding all fingerprints, click **"google-services.json"** (download icon)
2. **Replace** `android/app/google-services.json` with the new file
3. **Verify** file was updated

---

## ✅ **STEP 5: Clean and Rebuild**

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter clean
flutter pub get
flutter run
```

---

## 📋 **CHECKLIST:**

- [ ] ✅ Got DEBUG SHA-1
- [ ] ✅ Got DEBUG SHA-256
- [ ] ✅ Got RELEASE SHA-1
- [ ] ✅ Got RELEASE SHA-256
- [ ] ✅ Added all 4 to Firebase Console
- [ ] ✅ Downloaded NEW google-services.json
- [ ] ✅ Replaced old google-services.json
- [ ] ✅ Cleaned and rebuilt

---

## 🎯 **IMPORTANT:**

- **Debug builds** use debug keystore → Need DEBUG SHA fingerprints
- **Release builds** use release keystore → Need RELEASE SHA fingerprints
- **You need BOTH** in Firebase Console!

















