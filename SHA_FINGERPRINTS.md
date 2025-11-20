# 🔑 Your SHA Fingerprints

## ✅ **SHA-1 Fingerprint:**
```
CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC
```

## ✅ **SHA-256 Fingerprint:**
```
A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C
```

---

## 📝 **How to Add These to Firebase:**

### **Step 1: Go to Firebase Console**
1. Open: https://console.firebase.google.com/
2. Select your project: **Chamak**

### **Step 2: Add SHA Fingerprints**
1. Click **⚙️ Project Settings** (gear icon)
2. Scroll down to **"Your apps"** section
3. Find your **Android app** (`com.chamak.app`)
4. Click **"Add fingerprint"** button
5. Paste **SHA-1**: `CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC`
6. Click **"Save"**
7. Click **"Add fingerprint"** again
8. Paste **SHA-256**: `A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C`
9. Click **"Save"**

### **Step 3: Download Updated google-services.json**
1. Still in **Project Settings**
2. Scroll to **"Your apps"** → **Android app**
3. Click **"Download google-services.json"**
4. Replace the file in: `android/app/google-services.json`

---

## 🔄 **How to Get SHA Fingerprints Again (If Needed):**

### **Method 1: Using keytool (Easiest)**
Open Terminal in Cursor AI and run:
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Look for:
- **SHA1:** (your SHA-1 fingerprint)
- **SHA256:** (your SHA-256 fingerprint)

### **Method 2: Using Gradle (If Java 17 is installed)**
```powershell
cd android
.\gradlew.bat signingReport
```

Look for:
```
Variant: debug
Config: debug
Store: C:\Users\...\.android\debug.keystore
Alias: androiddebugkey
SHA1: CA:7E:7C:98:4C:D9:F0:91:A7:31:70:3F:6D:82:5B:18:15:95:3E:EC
SHA256: A8:18:05:C6:CB:60:98:90:55:C6:09:20:EE:AE:F3:04:33:F7:D6:FD:15:3B:58:6A:B4:46:2C:93:15:DF:AD:3C
```

### **Method 3: Using Android Studio**
1. Open Android Studio
2. Open your project
3. Open **Gradle** panel (right side)
4. Navigate: **app** → **Tasks** → **android** → **signingReport**
5. Double-click **signingReport**
6. Check **Run** tab at bottom for SHA fingerprints

---

## ⚠️ **Important Notes:**

- **Debug Keystore:** These fingerprints are from your **debug keystore** (for development/testing)
- **Release Keystore:** For production, you'll need to create a release keystore and get its fingerprints
- **Multiple Devices:** Each developer's debug keystore has different fingerprints
- **Firebase:** You can add multiple SHA fingerprints to Firebase (one per developer/keystore)

---

## 🎯 **Next Steps:**

1. ✅ Copy SHA-1 fingerprint above
2. ✅ Copy SHA-256 fingerprint above
3. ✅ Add both to Firebase Console
4. ✅ Download updated `google-services.json`
5. ✅ Replace `android/app/google-services.json` in your project
6. ✅ Test Firebase Phone Authentication

---

## 📞 **Need Help?**

- **Can't find Firebase Console?** Go to: https://console.firebase.google.com/
- **Don't see "Add fingerprint" button?** Make sure you're in Project Settings → Your apps → Android app
- **Need release keystore fingerprints?** Create release keystore first, then use same methods above

