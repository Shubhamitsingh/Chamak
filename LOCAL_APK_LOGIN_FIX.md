# 🔧 Local APK Login Issue - Fix Guide

## 🚨 The Problem:

- ❌ **Local APK (built from computer)** → Login doesn't work
- ✅ **Play Store APK** → Login works perfectly

## 🔍 Why This Happens:

### **The Issue:**

Firebase uses SHA fingerprints to verify your app:
- ✅ **Play Store SHA** → Already in Firebase → Play Store APK works
- ❌ **Local Keystore SHA** → **MISSING from Firebase** → Local APK doesn't work

### **Two Different Signing Keys:**

```
┌─────────────────────────────────────────┐
│ LOCAL APK (Your Computer)              │
│                                         │
│ Debug/Release Keystore                  │
│ SHA-1: [Your Local SHA]                │
│ SHA-256: [Your Local SHA]              │
│                                         │
│ ❌ NOT in Firebase                     │
│ ❌ Firebase rejects login              │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ PLAY STORE APK                          │
│                                         │
│ Google's Signing Key                    │
│ SHA-1: [Play Store SHA]                 │
│ SHA-256: [Play Store SHA]               │
│                                         │
│ ✅ Already in Firebase                 │
│ ✅ Login works perfectly                │
└─────────────────────────────────────────┘
```

---

## ✅ Solution: Add Local SHA Fingerprints to Firebase

### **Step 1: Get Your Local Keystore SHA Fingerprints**

#### **Option A: If Using Release Keystore**

```powershell
# Navigate to your keystore location
cd "C:\Users\Shubham Singh\Desktop\chamak"

# Get SHA fingerprints (replace with your keystore path and password)
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

**You'll see:**
```
Certificate fingerprints:
     SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
     SHA256: 12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF
```

#### **Option B: If Using Debug Keystore (Default)**

```powershell
# Get debug keystore SHA fingerprints
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Or on Windows:**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### **Option C: Get from Gradle (Easiest)**

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak\android"
.\gradlew signingReport
```

This will show SHA-1 and SHA-256 for both debug and release builds.

---

### **Step 2: Add SHA Fingerprints to Firebase**

1. **Go to Firebase Console:**
   - https://console.firebase.google.com/
   - Select project: **chamak-39472**

2. **Go to Project Settings:**
   - Click gear icon ⚙️ (top left)
   - Click **Project settings**

3. **Find Your Android App:**
   - Scroll to **Your apps** section
   - Find app: `com.chamakz.app`
   - Click on it

4. **Add SHA Fingerprint:**
   - Scroll to **SHA certificate fingerprints**
   - Click **Add fingerprint**
   - Paste **SHA-1** from Step 1
   - Click **Add**
   - Click **Add fingerprint** again
   - Paste **SHA-256** from Step 1
   - Click **Add**
   - Click **Save**

---

### **Step 3: Download Updated google-services.json**

1. **In Firebase Console:**
   - Still in Project Settings
   - Scroll to **Your apps** section
   - Find `com.chamakz.app`
   - Click **Download google-services.json**

2. **Replace in Project:**
   - Replace `android/app/google-services.json` with the new file
   - Make sure it's in the correct location

---

### **Step 4: Rebuild Your App**

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter clean
flutter pub get
flutter build apk --release
```

Or for debug:
```powershell
flutter build apk --debug
```

---

## 🔍 How to Find Your Keystore Location

### **Check build.gradle for Keystore Path:**

```powershell
# Check if you have signing config
Get-Content android/app/build.gradle | Select-String "signingConfigs"
```

### **Common Keystore Locations:**

1. **Debug Keystore (Default):**
   - Windows: `C:\Users\YourName\.android\debug.keystore`
   - Password: `android`
   - Alias: `androiddebugkey`

2. **Release Keystore (Custom):**
   - Usually in: `android/app/upload-keystore.jks`
   - Or: `android/app/release.keystore`
   - Check `android/app/build.gradle` for path

---

## 📋 Quick Checklist

- [ ] Get local SHA-1 fingerprint
- [ ] Get local SHA-256 fingerprint
- [ ] Add SHA-1 to Firebase Console
- [ ] Add SHA-256 to Firebase Console
- [ ] Download updated google-services.json
- [ ] Replace google-services.json in project
- [ ] Rebuild app
- [ ] Test login with local APK

---

## 🎯 Expected Result

After adding local SHA fingerprints:

- ✅ **Local APK** → Login works
- ✅ **Play Store APK** → Login works (already working)

---

## ⚠️ Important Notes

1. **You Need BOTH:**
   - Local keystore SHA (for local builds)
   - Play Store SHA (already added, that's why Play Store works)

2. **Different Build Types:**
   - Debug build → Uses debug keystore
   - Release build → Uses release keystore
   - You may need to add SHA for both

3. **After Adding SHA:**
   - Must download new google-services.json
   - Must rebuild app
   - Old APK won't work until rebuilt

---

## 🚀 Quick Command to Get SHA (All Methods)

### **Method 1: Gradle (Recommended)**
```powershell
cd android
.\gradlew signingReport
```

### **Method 2: Keytool (Debug)**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### **Method 3: Keytool (Release)**
```powershell
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

---

## ✅ After Fix

Your Firebase Console should have:
- ✅ Play Store SHA-1 (already there)
- ✅ Play Store SHA-256 (already there)
- ✅ Local Debug SHA-1 (add this)
- ✅ Local Debug SHA-256 (add this)
- ✅ Local Release SHA-1 (add this if using release keystore)
- ✅ Local Release SHA-256 (add this if using release keystore)

---

**This will fix your local APK login issue!** 🔐








