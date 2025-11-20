# ☕ Install Java - Quick Guide

## ❌ **Current Error:**
```
ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
```

**This means Java is not installed.** Let's fix this!

---

## ✅ **STEP 1: Download Java JDK** (2 minutes)

### **1.1 Go to Java Download Page**
1. Open your web browser
2. Go to: **https://adoptium.net/**
3. You'll see: **"Latest LTS Release"** (JDK 17 or 21)

### **1.2 Select Options**
- **Version:** 17 or 21 (LTS) - **Click on it**
- **Operating System:** **Windows** (should be auto-selected)
- **Architecture:** **x64** (64-bit) - should be auto-selected
- **Package Type:** **JDK** (should be selected)

### **1.3 Download**
- Click the big **"Download JDK"** button
- File will download (about 150-200 MB)
- File name will be like: `OpenJDK17U-jdk_x64_windows_hotspot_17.0.x.msi`

---

## ✅ **STEP 2: Install Java** (3 minutes)

### **2.1 Run Installer**
1. **Go to Downloads folder**
2. **Double-click** the downloaded file (`.msi` file)
3. Windows may ask: **"Do you want to allow this app to make changes?"**
   - Click **"Yes"**

### **2.2 Installation Wizard**
1. **Welcome Screen:** Click **"Next"**
2. **License Agreement:** Check "I accept the terms..." → Click **"Next"**
3. **Installation Options:** 
   - Keep default settings (don't change anything)
   - Click **"Next"**
4. **Ready to Install:** Click **"Install"**
5. **Wait for installation** (2-3 minutes)
   - You'll see progress bar
6. **Installation Complete:** Click **"Close"**

### **2.3 Verify Installation**
1. **Close Cursor AI completely** (File → Exit)
2. **Reopen Cursor AI**
3. **Open Terminal:** Press `Ctrl + ~`
4. **Run this command:**
   ```bash
   java -version
   ```
5. **You should see:**
   ```
   openjdk version "17.0.x" ...
   ```
6. ✅ **Java is installed!**

---

## ✅ **STEP 3: Get SHA Fingerprints** (2 minutes)

Now that Java is installed:

### **3.1 Open Terminal in Cursor**
- Press: **`Ctrl + ~`**
- Or: **Terminal → New Terminal**

### **3.2 Navigate to android folder**
```bash
cd android
```

### **3.3 Run signingReport**
```bash
.\gradlew.bat signingReport
```

### **3.4 Wait for Output**
- Takes about 30-60 seconds
- You'll see lots of text scrolling
- Wait until you see: **"BUILD SUCCESSFUL"**

### **3.5 Find SHA Fingerprints**
Scroll up through the terminal output and look for:

```
Variant: debug
Config: debug
Store: C:\Users\Shubham Singh\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
Valid until: ...
```

### **3.6 Copy SHA Fingerprints**
1. **Find the line starting with "SHA1:"**
   - Select the entire line (including "SHA1:")
   - Right-click → Copy (or Ctrl+C)

2. **Find the line starting with "SHA-256:"**
   - Select the entire line (including "SHA-256:")
   - Right-click → Copy (or Ctrl+C)

3. **Save them:**
   - Open Notepad
   - Paste both SHA-1 and SHA-256
   - Save as: `SHA_FINGERPRINTS.txt`

---

## 🎯 **What You'll Get:**

After running `signingReport`, you'll see something like:

**SHA-1:**
```
SHA1: A1:B2:C3:D4:E5:F6:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE
```

**SHA-256:**
```
SHA-256: A1:B2:C3:D4:E5:F6:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA
```

**Copy both!**

---

## 📋 **After Getting SHA Fingerprints:**

### **Step 1: Add to Firebase Console**
1. Go to: **https://console.firebase.google.com/project/chamak-39472/settings/general**
2. Scroll to **"Your apps"** → `com.chamak.app`
3. Click **"Add fingerprint"** → Paste **SHA-1** → Save
4. Click **"Add fingerprint"** → Paste **SHA-256** → Save

### **Step 2: Download google-services.json**
1. Still in Firebase Console
2. Click **"Download google-services.json"**
3. File downloads to Downloads folder

### **Step 3: Replace File**
1. Go to: `C:\Users\Shubham Singh\Desktop\chamak\android\app\`
2. Delete old `google-services.json`
3. Copy new downloaded `google-services.json` here

### **Step 4: Rebuild**
Tell me when done, and I'll run:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🆘 **Troubleshooting:**

### **Problem: Can't find Java download**
**Solution:**
- Go directly to: https://adoptium.net/temurin/releases/
- Select: Windows → x64 → JDK 17 or 21

### **Problem: Installation failed**
**Solution:**
- Make sure you're running as Administrator
- Close all other programs
- Try again

### **Problem: "java -version" not working after install**
**Solution:**
- **Close Cursor AI completely**
- **Reopen Cursor AI**
- Try again
- If still not working, restart your computer

### **Problem: Still getting "JAVA_HOME not set"**
**Solution:**
- After installing Java, **close and reopen Cursor AI**
- Or restart your computer
- Then try `.\gradlew.bat signingReport` again

---

## ⚡ **Quick Summary:**

1. ✅ **Download Java:** https://adoptium.net/
2. ✅ **Install Java** (run the .msi file)
3. ✅ **Close and reopen Cursor AI**
4. ✅ **Open Terminal** (`Ctrl + ~`)
5. ✅ **Run:** `cd android` → `.\gradlew.bat signingReport`
6. ✅ **Copy SHA-1 and SHA-256**
7. ✅ **Add to Firebase Console**

**Total time: 10-15 minutes!**

---

## 💡 **Pro Tips:**

1. **Save SHA fingerprints** - Keep them safe, you'll need them again
2. **Close Cursor AI** after installing Java - Important!
3. **Use JDK 17 or 21** - These are LTS (Long Term Support) versions
4. **Don't skip restarting** - Java needs to be in PATH

---

**Start with Step 1: Download Java from https://adoptium.net/**

**Tell me when you've installed Java, and I'll help you get the SHA fingerprints!** 🚀


