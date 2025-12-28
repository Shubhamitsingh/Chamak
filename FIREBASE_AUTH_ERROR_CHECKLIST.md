# 🔍 Firebase Authentication Error - Troubleshooting Checklist

## ✅ What You've Done:
- ✅ Added SHA-1: `81:12:99:24:87:dd:92:9a:ab:b4:a3:d4:fc:c4:3a:88:5d:ba:d1:71`
- ✅ Added SHA-256: `11:a8:7f:44:79:42:7e:f3:e0:eb:0a:f4:b0:63:14:fd:3f:9a:ee:cd:b0:a5:7d:5c:64:ca:37:8a:78:ee:53:ab`

## ❌ Still Getting Error? Check These:

---

### 1. ⚠️ **Did You Download New google-services.json?**

After adding SHA fingerprints, you **MUST** download a new `google-services.json` file!

**Steps:**
1. Go to Firebase Console → Project Settings
2. Find app: `com.chamakz.app`
3. Click **"google-services.json"** button (download icon)
4. **Replace** `android/app/google-services.json` with the new file
5. **Rebuild** the app

---

### 2. ⚠️ **Did You Add Fingerprints to Correct App?**

Make sure you added fingerprints to:
- ✅ App with package name: `com.chamakz.app`
- ❌ NOT to `com.chamak.app` or any other app

**Check:**
- Firebase Console → Project Settings
- Look for app: `com.chamakz.app`
- Verify fingerprints are listed there

---

### 3. ⚠️ **Wait Time - Firebase Propagation**

Firebase changes can take **5-15 minutes** to propagate!

**Solution:**
- Wait 10-15 minutes after adding fingerprints
- Then rebuild and test again

---

### 4. ⚠️ **Are You Testing with Release Build?**

The SHA fingerprints you added are for **RELEASE** keystore!

**Make sure you're testing with:**
```powershell
flutter run --release
```

**NOT:**
```powershell
flutter run  # This uses debug keystore!
```

---

### 5. ⚠️ **Check google-services.json Package Name**

Open `android/app/google-services.json` and verify:

```json
"package_name": "com.chamakz.app"
```

If it shows `com.chamak.app` or anything else, that's the problem!

---

### 6. ⚠️ **Clean Rebuild Required**

After updating Firebase, you MUST do a clean rebuild:

```powershell
flutter clean
flutter pub get
flutter run --release
```

---

### 7. ⚠️ **Check Firebase Console - App Status**

In Firebase Console:
1. Go to Project Settings
2. Find app: `com.chamakz.app`
3. Check if there's any warning or error message
4. Verify the app is **active/enabled**

---

### 8. ⚠️ **Verify Fingerprint Format**

Make sure fingerprints in Firebase Console match exactly (case doesn't matter, but format does):

**SHA-1:**
```
81:12:99:24:87:dd:92:9a:ab:b4:a3:d4:fc:c4:3a:88:5d:ba:d1:71
```

**SHA-256:**
```
11:a8:7f:44:79:42:7e:f3:e0:eb:0a:f4:b0:63:14:fd:3f:9a:ee:cd:b0:a5:7d:5c:64:ca:37:8a:78:ee:53:ab
```

---

## 🔧 **Complete Fix Steps (Do All):**

1. ✅ Verify fingerprints in Firebase Console (app: `com.chamakz.app`)
2. ✅ Download NEW `google-services.json` from Firebase Console
3. ✅ Replace `android/app/google-services.json` with new file
4. ✅ Wait 10-15 minutes for Firebase propagation
5. ✅ Clean rebuild:
   ```powershell
   flutter clean
   flutter pub get
   flutter run --release
   ```

---

## 🎯 **Most Common Issue:**

**90% of the time, the problem is:**
- ❌ Not downloading new `google-services.json` after adding fingerprints
- ❌ Testing with debug build instead of release build
- ❌ Not waiting for Firebase propagation (5-15 minutes)

---

## 📸 **Quick Verification:**

Run this command to verify your current google-services.json:

```powershell
Get-Content "android\app\google-services.json" | Select-String "com.chamakz.app"
```

Should show: `"package_name": "com.chamakz.app"`


















