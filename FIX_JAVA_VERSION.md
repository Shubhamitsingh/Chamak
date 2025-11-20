# 🔧 Fix Java Version Issue

## ❌ **Current Problem:**
You have **Java 25.0.1** installed, but Gradle/Kotlin doesn't support it yet!

**Error:** `java.lang.IllegalArgumentException: 25.0.1`

## ✅ **Solution: Install Java 17 or 21 (LTS)**

You need to install **Java 17** or **Java 21** (Long Term Support versions).

---

## 📥 **STEP 1: Download Java 17** (Recommended)

### **1.1 Go to Download Page**
1. Open browser
2. Go to: **https://adoptium.net/temurin/releases/?version=17**
3. You'll see **"Eclipse Temurin 17 (LTS)"**

### **1.2 Select Options**
- **Version:** **17** (LTS) ✅
- **Operating System:** **Windows** ✅
- **Architecture:** **x64** ✅
- **Package Type:** **JDK** ✅

### **1.3 Download**
- Click **"Download JDK"** button
- File: `OpenJDK17U-jdk_x64_windows_hotspot_17.0.x.msi` (~150 MB)

---

## 💾 **STEP 2: Install Java 17**

### **2.1 Run Installer**
1. Go to **Downloads** folder
2. **Double-click** the `.msi` file
3. Click **"Yes"** if Windows asks for permission

### **2.2 Installation Steps**
1. **Welcome:** Click **"Next"**
2. **License:** Check "I accept..." → Click **"Next"**
3. **Installation Options:** Keep defaults → Click **"Next"**
4. **Ready to Install:** Click **"Install"**
5. **Wait 2-3 minutes** (progress bar)
6. **Complete:** Click **"Close"**

---

## 🔄 **STEP 3: Set JAVA_HOME to Java 17**

### **3.1 Find Java 17 Installation Path**
Java 17 is usually installed at:
```
C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot
```

### **3.2 Set JAVA_HOME (Temporary - For This Session)**
Open Terminal in Cursor AI and run:
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot"
```

**Replace `17.0.x` with your actual version number!**

### **3.3 Verify Java 17 is Active**
```powershell
java -version
```

**You should see:**
```
openjdk version "17.0.x" ...
```

**NOT** `25.0.1`!

---

## ✅ **STEP 4: Get SHA Fingerprints**

Once Java 17 is active, run:
```powershell
cd android
.\gradlew.bat signingReport
```

This should work now! ✅

---

## 🎯 **Alternative: Use Android Studio**

If you have Android Studio installed, you can use its built-in Gradle:

1. Open **Android Studio**
2. Open your project: `C:\Users\Shubham Singh\Desktop\chamak`
3. Wait for Gradle sync
4. Open **Terminal** in Android Studio (bottom panel)
5. Run: `.\gradlew signingReport`

Android Studio uses its own Java version, so this will work! ✅

---

## 📝 **Quick Summary**

1. ✅ Download Java 17 from: https://adoptium.net/temurin/releases/?version=17
2. ✅ Install it (run the .msi file)
3. ✅ Set JAVA_HOME to Java 17 path
4. ✅ Run `java -version` to verify
5. ✅ Run `.\gradlew.bat signingReport` to get SHA fingerprints

---

## ❓ **Need Help?**

- **Can't find Java 17 path?** Check: `C:\Program Files\Eclipse Adoptium\`
- **Still showing Java 25?** Close and reopen Cursor AI
- **Want to use Android Studio?** Follow the alternative method above

