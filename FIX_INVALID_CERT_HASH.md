# 🔧 Fix INVALID_CERT_HASH Error

## ❌ **Error in Logcat:**
```
E/FirebaseAuth: [GetAuthDomainTask] Error getting project config. Failed with INVALID_CERT_HASH 400
E/zzb: Failed to get reCAPTCHA token with error [There was an error while trying to get your package certificate hash.]
```

---

## 🔍 **Root Cause:**

Even though you added debug SHA-256, Firebase is still showing `INVALID_CERT_HASH`. This means:

1. **New google-services.json not downloaded** after adding SHA-256
2. **App not clean rebuilt** after updating
3. **Firebase propagation delay** (needs more time)
4. **Wrong SHA-256 added** (typo or wrong fingerprint)

---

## ✅ **COMPLETE FIX STEPS:**

### **Step 1: Verify SHA-256 in Firebase Console**

1. Go to **Firebase Console** → **Project Settings**
2. Find app: **`com.chamakz.app`**
3. Check **"SHA certificate fingerprints"**
4. **Verify you see TWO SHA-256 fingerprints:**
   - **Release SHA-256:** `11:a8:7f:44:79:42:7e:f3:e0:eb:0a:f4:b0:63:14:fd:3f:9a:ee:cd:b0:a5:7d:5c:64:ca:37:8a:78:ee:53:ab`
   - **Debug SHA-256:** `A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C`

**If debug SHA-256 is missing, add it again!**

---

### **Step 2: Download NEW google-services.json**

**CRITICAL:** You MUST download new `google-services.json` AFTER adding SHA-256!

1. In Firebase Console, click **"google-services.json"** (download icon)
2. **Replace** `android/app/google-services.json` with the NEW file
3. **Verify** the file was updated (check modification time)

---

### **Step 3: Delete Build Cache**

```powershell
flutter clean
cd android
.\gradlew clean
cd ..
```

**This removes ALL cached files!**

---

### **Step 4: Rebuild from Scratch**

```powershell
flutter pub get
flutter run
```

**Wait for full rebuild** (may take 2-3 minutes)

---

### **Step 5: Wait for Firebase Propagation**

**IMPORTANT:** After adding SHA-256 and downloading new `google-services.json`:
- Wait **15-20 minutes** for Firebase to propagate changes globally
- Firebase changes don't happen instantly
- Different servers update at different times

---

## 🔍 **VERIFICATION CHECKLIST:**

### **Check 1: Firebase Console**
- [ ] Debug SHA-256 is listed: `A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C`
- [ ] Release SHA-256 is listed: `11:a8:7f:44:79:42:7e:f3:e0:eb:0a:f4:b0:63:14:fd:3f:9a:ee:cd:b0:a5:7d:5c:64:ca:37:8a:78:ee:53:ab`

### **Check 2: google-services.json**
- [ ] File was downloaded AFTER adding debug SHA-256
- [ ] File contains: `"package_name": "com.chamakz.app"`
- [ ] File contains: `"mobilesdk_app_id": "1:228866341171:android:57f014e3dfc56f19b2a646"`

### **Check 3: Clean Rebuild**
- [ ] Ran `flutter clean`
- [ ] Ran `cd android && .\gradlew clean`
- [ ] Ran `flutter pub get`
- [ ] Ran `flutter run`

### **Check 4: Wait Time**
- [ ] Waited 15-20 minutes after adding SHA-256
- [ ] Waited 15-20 minutes after downloading google-services.json

---

## 🚨 **IF STILL NOT WORKING:**

### **Option A: Use Release Build Instead**

If debug build keeps failing, use release build:

```powershell
flutter clean
flutter pub get
flutter run --release
```

**Release build uses release keystore (SHA-256 already registered) ✅**

---

### **Option B: Double-Check SHA-256**

**Get Debug SHA-256 Again:**
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android | Select-String -Pattern "SHA256" -Context 0,1
```

**Verify it matches what you added in Firebase Console:**
- Should be: `A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C`

**If different:**
- Remove old SHA-256 from Firebase
- Add the correct one
- Download new google-services.json
- Clean rebuild

---

### **Option C: Remove and Re-add SHA-256**

1. **Remove** debug SHA-256 from Firebase Console
2. **Wait 5 minutes**
3. **Add** debug SHA-256 again (copy-paste carefully)
4. **Download** new google-services.json
5. **Clean rebuild**
6. **Wait 20 minutes**
7. **Test again**

---

## 💡 **MOST COMMON ISSUES:**

### **Issue 1: Didn't Download New google-services.json**
- **Problem:** Using old file from before adding SHA-256
- **Fix:** Download NEW file after adding SHA-256

### **Issue 2: Typo in SHA-256**
- **Problem:** Wrong characters when copying SHA-256
- **Fix:** Copy-paste carefully, verify character by character

### **Issue 3: Not Waiting Long Enough**
- **Problem:** Firebase needs 15-20 minutes to propagate
- **Fix:** Wait longer, then test again

### **Issue 4: Not Clean Rebuilt**
- **Problem:** App using cached old configuration
- **Fix:** `flutter clean` + `cd android && .\gradlew clean`

---

## 🎯 **RECOMMENDED ACTION PLAN:**

1. ✅ **Verify** debug SHA-256 is in Firebase Console
2. ✅ **Download** NEW google-services.json (if not done)
3. ✅ **Delete** build cache: `flutter clean && cd android && .\gradlew clean`
4. ✅ **Rebuild:** `flutter pub get && flutter run`
5. ✅ **Wait** 20 minutes
6. ✅ **Test** again

---

## ⚠️ **IF ERROR PERSISTS:**

**Try Release Build:**
```powershell
flutter run --release
```

**Or Build Release APK:**
```powershell
flutter build apk --release
```

**Release build should work** because release SHA-256 is already registered! ✅

---

## 📋 **QUICK CHECK:**

**Tell me:**
1. Did you download NEW `google-services.json` AFTER adding debug SHA-256?
2. Did you do `flutter clean` AND `cd android && .\gradlew clean`?
3. How long did you wait after adding SHA-256? (needs 15-20 min)
4. Can you verify debug SHA-256 in Firebase Console matches: `A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C`?

---

## ✅ **SUMMARY:**

The `INVALID_CERT_HASH` error means Firebase can't find your certificate. Most likely:
1. **New google-services.json not downloaded** ⚠️
2. **Not clean rebuilt** ⚠️
3. **Not waited long enough** ⚠️

**Follow the steps above and wait 20 minutes before testing again!**


















