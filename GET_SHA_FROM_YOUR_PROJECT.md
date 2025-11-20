# 🔑 Get SHA Fingerprints from Your Project

## 📁 **Your Project Structure:**

I can see your project folder. Here's exactly how to get SHA fingerprints:

---

## ✅ **METHOD 1: Using Gradle Wrapper** (If Java is installed)

### **Step 1: Open Terminal in Your Project**
1. In your IDE (VS Code/Cursor), open terminal
2. Navigate to `android` folder:
   ```bash
   cd android
   ```

### **Step 2: Run signingReport**
```bash
.\gradlew.bat signingReport
```

**But this needs Java installed!** If you get "JAVA_HOME not set" error, use Method 2.

---

## ✅ **METHOD 2: Using Android Studio** ⭐ **RECOMMENDED**

Since you have the project structure, here's the easiest way:

### **Step 1: Open in Android Studio**
1. Open **Android Studio**
2. **File → Open**
3. Select: `C:\Users\Shubham Singh\Desktop\chamak\android`
   - **Important:** Select the `android` folder, not `chamak`
4. Click **OK**

### **Step 2: Wait for Gradle Sync**
- Android Studio will sync Gradle files
- First time: 5-10 minutes
- You'll see "Gradle sync completed" at bottom

### **Step 3: Open Gradle Panel**
1. Look at the **right side** of Android Studio
2. Click **Gradle** tab (if not visible: View → Tool Windows → Gradle)

### **Step 4: Navigate to signingReport**
In Gradle panel, expand:
```
📁 CHAMAK (or chamak)
  📁 android
    📁 app
      📁 Tasks
        📁 android
          🔍 signingReport  ← Double-click this!
```

### **Step 5: Get SHA Fingerprints**
1. **Double-click** `signingReport`
2. Wait 10-30 seconds
3. Check **Run** tab at bottom
4. Look for output like:
   ```
   Variant: debug
   Config: debug
   Store: C:\Users\Shubham Singh\.android\debug.keystore
   Alias: AndroidDebugKey
   MD5: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   SHA-256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   ```

### **Step 6: Copy SHA Fingerprints**
1. **Copy the entire SHA1 line:**
   ```
   SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   ```

2. **Copy the entire SHA-256 line:**
   ```
   SHA-256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   ```

3. **Save them** (copy to Notepad or save the file)

---

## ✅ **METHOD 3: Install Java JDK** (If you don't have Android Studio)

### **Step 1: Download Java**
1. Go to: **https://adoptium.net/**
2. Download **JDK 17** for Windows
3. Install it

### **Step 2: Set JAVA_HOME** (Optional, but recommended)
1. Right-click **This PC** → **Properties**
2. **Advanced system settings** → **Environment Variables**
3. Under **System variables**, click **New**
4. Variable name: `JAVA_HOME`
5. Variable value: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x.x-hotspot` (or wherever Java installed)
6. Click **OK**

### **Step 3: Run signingReport**
```bash
cd android
.\gradlew.bat signingReport
```

### **Step 4: Copy SHA Fingerprints**
- Same as Method 2, Step 6 above

---

## 🎯 **What You'll Get:**

After running signingReport, you'll see:

**SHA-1:**
```
SHA1: [20 pairs of hex characters]
Example: SHA1: A1:B2:C3:D4:E5:F6:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE
```

**SHA-256:**
```
SHA-256: [32 pairs of hex characters]
Example: SHA-256: A1:B2:C3:D4:E5:F6:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA
```

---

## 📋 **After You Get SHA Fingerprints:**

1. ✅ **Copy SHA-1** (entire line)
2. ✅ **Copy SHA-256** (entire line)
3. ✅ **Go to Firebase Console:**
   - https://console.firebase.google.com/project/chamak-39472/settings/general
4. ✅ **Add SHA-1:**
   - Scroll to "Your apps" → `com.chamak.app`
   - Click "Add fingerprint" → Paste SHA-1 → Save
5. ✅ **Add SHA-256:**
   - Click "Add fingerprint" → Paste SHA-256 → Save
6. ✅ **Download new google-services.json**
7. ✅ **Replace:** `android/app/google-services.json` (I can help with this!)

---

## 💡 **My Recommendation:**

**Use METHOD 2 (Android Studio)** - It's the easiest!

1. Open Android Studio
2. Open `android` folder
3. Gradle → `app` → `Tasks` → `android` → `signingReport`
4. Copy SHA-1 and SHA-256
5. Done!

---

## 🆘 **Quick Help:**

**Don't have Android Studio?**
- Download: https://developer.android.com/studio
- Or install Java JDK (Method 3)

**Can't find signingReport?**
- Make sure you expanded: `app` → `Tasks` → `android`
- Try refreshing Gradle: Right-click project → "Sync Project with Gradle Files"

**No SHA in output?**
- Check the "Run" tab at bottom of Android Studio
- Scroll through all the output
- Look for lines starting with "SHA1:" and "SHA-256:"

---

## ⚡ **Summary:**

1. ✅ Open Android Studio → Open `android` folder
2. ✅ Gradle Panel → `app` → `Tasks` → `android` → `signingReport`
3. ✅ Double-click `signingReport`
4. ✅ Copy SHA-1 and SHA-256 from Run tab
5. ✅ Add to Firebase Console
6. ✅ Done!

**Total time: 5 minutes!**

---

**Tell me when you have the SHA fingerprints, and I'll help you add them to Firebase!** 🚀


