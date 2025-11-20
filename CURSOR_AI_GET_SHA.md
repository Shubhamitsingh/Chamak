# 🔑 Get SHA Fingerprints in Cursor AI - Step-by-Step

## 📋 **You're Using Cursor AI (Not Android Studio)**

Since Cursor AI doesn't have a Gradle panel like Android Studio, here are **3 ways** to get SHA fingerprints:

---

## ✅ **METHOD 1: Install Java & Use Terminal** ⭐ **RECOMMENDED**

### **Step 1: Install Java JDK** (10 minutes)

1. **Download Java:**
   - Go to: **https://adoptium.net/**
   - Click **"Latest LTS Release"** (JDK 17 or 21)
   - Select: **Windows** → **x64**
   - Click **"Download JDK"**
   - File downloads (~150-200 MB)

2. **Install Java:**
   - Run the downloaded installer
   - Click **Next** → **Next** → **Install**
   - Wait 2-3 minutes
   - Click **Close**

3. **Verify Installation:**
   - **Close and reopen** Cursor AI
   - Open terminal in Cursor: **Terminal → New Terminal** (or `Ctrl + ~`)
   - Run:
     ```bash
     java -version
     ```
   - You should see Java version
   - ✅ **Java installed!**

### **Step 2: Get SHA Fingerprints** (2 minutes)

1. **Open Terminal in Cursor:**
   - Press: **`Ctrl + ~`** (or View → Terminal)
   - Or click **Terminal** menu → **New Terminal**

2. **Navigate to android folder:**
   ```bash
   cd android
   ```

3. **Run signingReport:**
   ```bash
   .\gradlew.bat signingReport
   ```

4. **Wait for output** (30-60 seconds)

5. **Find SHA Fingerprints:**
   Scroll through the terminal output and look for:
   ```
   Variant: debug
   Config: debug
   Store: C:\Users\Shubham Singh\.android\debug.keystore
   Alias: AndroidDebugKey
   MD5: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   SHA-256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   ```

6. **Copy SHA Fingerprints:**
   - **Copy the entire SHA1 line** (including "SHA1:")
   - **Copy the entire SHA-256 line** (including "SHA-256:")
   - Save in Notepad

---

## ✅ **METHOD 2: Use Android Studio** (5 minutes)

If you have Android Studio installed:

1. **Open Android Studio**
2. **File → Open** → Select: `C:\Users\Shubham Singh\Desktop\chamak\android`
3. **Gradle Panel** (right side) → `app` → `Tasks` → `android` → `signingReport`
4. **Double-click** `signingReport`
5. **Copy SHA-1 and SHA-256** from Run tab

---

## ✅ **METHOD 3: Use Flutter Build** (Alternative)

If Flutter is installed, you can try:

1. **Open Terminal in Cursor:**
   - Press: **`Ctrl + ~`**

2. **Run Flutter build:**
   ```bash
   flutter build apk --debug
   ```

3. **Look for SHA fingerprints** in the build output

**Note:** This method may or may not show SHA fingerprints depending on your Flutter version.

---

## 🎯 **Recommended: METHOD 1** (Install Java)

This is the **easiest and most reliable** method for Cursor AI.

---

## 📋 **After Getting SHA Fingerprints:**

### **Step 1: Add to Firebase Console**

1. Go to: **https://console.firebase.google.com/project/chamak-39472/settings/general**
2. Scroll to **"Your apps"** → `com.chamak.app`
3. Click **"Add fingerprint"** → Paste **SHA-1** → Save
4. Click **"Add fingerprint"** → Paste **SHA-256** → Save

### **Step 2: Download google-services.json**

1. Still in Firebase Console → Project Settings
2. Click **"Download google-services.json"**
3. File downloads to Downloads folder

### **Step 3: Replace File**

1. Go to: `C:\Users\Shubham Singh\Desktop\chamak\android\app\`
2. **Delete** old `google-services.json`
3. **Copy** new downloaded `google-services.json` here

### **Step 4: Rebuild**

Tell me when done, and I'll run:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🆘 **Quick Help:**

### **Don't have Java?**
- Download from: https://adoptium.net/
- Install JDK 17 or 21
- Restart Cursor AI

### **Can't find terminal in Cursor?**
- Press: **`Ctrl + ~`**
- Or: **View → Terminal**
- Or: **Terminal → New Terminal**

### **Getting "JAVA_HOME not set" error?**
- Install Java first (Method 1, Step 1)
- Close and reopen Cursor AI
- Try again

---

## ⚡ **Quick Summary:**

1. ✅ **Install Java JDK** from https://adoptium.net/
2. ✅ **Open Terminal in Cursor** (`Ctrl + ~`)
3. ✅ **Run:** `cd android` → `.\gradlew.bat signingReport`
4. ✅ **Copy SHA-1 and SHA-256** from output
5. ✅ **Add to Firebase Console**
6. ✅ **Download new google-services.json**
7. ✅ **Replace file** → Done!

---

## 💡 **Visual Guide - Cursor AI:**

```
┌─────────────────────────────────────┐
│  Cursor AI                          │
├─────────────────────────────────────┤
│  [File] [Edit] [View] [Terminal]   │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Terminal (Ctrl + ~)          │ │
│  │  ┌─────────────────────────┐  │ │
│  │  │ $ cd android            │  │ │
│  │  │ $ .\gradlew.bat          │  │ │
│  │  │    signingReport         │  │ │
│  │  │                          │  │ │
│  │  │ SHA1: XX:XX:XX:...       │  │ │
│  │  │ SHA-256: XX:XX:XX:...    │  │ │
│  │  └─────────────────────────┘  │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

**Tell me which method you want to use, and I'll guide you through it step by step!** 🚀


