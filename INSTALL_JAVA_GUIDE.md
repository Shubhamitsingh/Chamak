# ☕ Install Java to Get SHA Fingerprints

## ❌ **The Error:**
```
ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
```

This means **Java is not installed** or not configured properly.

---

## ✅ **SOLUTION 1: Install Java JDK** (10 minutes) ⭐ **RECOMMENDED**

### **Step 1: Download Java JDK**
1. Go to: **https://adoptium.net/**
2. Click **"Latest LTS Release"** (JDK 17 or 21)
3. Select:
   - **Version:** 17 or 21 (LTS)
   - **Operating System:** Windows
   - **Architecture:** x64 (64-bit)
4. Click **"Download JDK"**
5. File will download (about 150-200 MB)

### **Step 2: Install Java**
1. **Run the downloaded installer** (e.g., `OpenJDK17U-jdk_x64_windows_hotspot_17.0.x.msi`)
2. Click **"Next"** → **"Next"** → **"Install"**
3. **Wait for installation** (2-3 minutes)
4. Click **"Close"** when done

### **Step 3: Verify Installation**
1. **Close and reopen** your terminal/command prompt
2. Run:
   ```bash
   java -version
   ```
3. You should see:
   ```
   openjdk version "17.0.x" ...
   ```
4. ✅ **Java is installed!**

### **Step 4: Get SHA Fingerprints**
Now run:
```bash
cd android
.\gradlew.bat signingReport
```

You should see SHA fingerprints in the output!

---

## ✅ **SOLUTION 2: Use Android Studio** (5 minutes) ⚡ **EASIEST**

Android Studio has Java bundled, so you don't need to install it separately!

### **Step 1: Download Android Studio**
1. Go to: **https://developer.android.com/studio**
2. Click **"Download Android Studio"**
3. Run the installer
4. Follow installation wizard (default settings are fine)

### **Step 2: Open Your Project**
1. Open **Android Studio**
2. **File → Open**
3. Select: `C:\Users\Shubham Singh\Desktop\chamak\android`
4. Wait for Gradle sync

### **Step 3: Get SHA Fingerprints**
1. **Gradle Panel** (right side) → Click **Gradle** tab
2. Navigate: `chamak` → `android` → `app` → `Tasks` → `android` → **`signingReport`**
3. **Double-click** `signingReport`
4. Check **Run** tab → Copy SHA-1 and SHA-256

**That's it!** No Java installation needed!

---

## ✅ **SOLUTION 3: Check if Java is Already Installed** (2 minutes)

Sometimes Java is installed but not in PATH. Let's check:

### **Check Common Java Locations:**

Run these commands in PowerShell:

```powershell
# Check if Java is installed
Get-Command java -ErrorAction SilentlyContinue

# Check common Java locations
Test-Path "C:\Program Files\Java"
Test-Path "C:\Program Files (x86)\Java"
Test-Path "C:\Program Files\Eclipse Adoptium"
Test-Path "C:\Program Files\Microsoft\jdk-*"
```

If any of these return `True`, Java might be installed but not in PATH.

### **Add Java to PATH:**

1. **Find Java installation folder:**
   - Usually: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x.x-hotspot\bin`
   - Or: `C:\Program Files\Java\jdk-17.x.x\bin`

2. **Add to PATH:**
   - Right-click **This PC** → **Properties**
   - **Advanced system settings** → **Environment Variables**
   - Under **System variables**, find **Path** → Click **Edit**
   - Click **New** → Paste Java bin path
   - Click **OK** on all windows

3. **Restart terminal** and try again:
   ```bash
   cd android
   .\gradlew.bat signingReport
   ```

---

## 🎯 **My Recommendation:**

**Use SOLUTION 2 (Android Studio)** - It's the easiest and you'll need it for Android development anyway!

**Or use SOLUTION 1 (Install Java)** - If you prefer command line.

---

## 📋 **After Installing Java:**

Once Java is installed, run:

```bash
cd android
.\gradlew.bat signingReport
```

You'll see output like:
```
Variant: debug
Config: debug
Store: C:\Users\Shubham Singh\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**Copy both SHA-1 and SHA-256!**

---

## 🆘 **Quick Help:**

**Which solution should I use?**
- **Want it fast?** → Android Studio (Solution 2)
- **Prefer command line?** → Install Java (Solution 1)
- **Think Java might be installed?** → Check first (Solution 3)

**Tell me which solution you want, and I'll guide you through it step by step!**

---

## ⚡ **Quick Summary:**

1. ✅ **Install Java JDK** from https://adoptium.net/
2. ✅ **OR Install Android Studio** from https://developer.android.com/studio
3. ✅ **Run:** `cd android` → `.\gradlew.bat signingReport`
4. ✅ **Copy SHA-1 and SHA-256**
5. ✅ **Add to Firebase Console**

**Total time: 10-15 minutes!**


