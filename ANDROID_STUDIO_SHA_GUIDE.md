# 🚀 Android Studio - Get SHA Fingerprints Guide

## 📋 **Complete Step-by-Step Instructions**

Follow these steps exactly to get your SHA fingerprints using Android Studio.

---

## ✅ **STEP 1: Open Project in Android Studio** (2 minutes)

### **1.1 Open Android Studio**
- Launch **Android Studio** on your computer
- If you don't have it, download from: https://developer.android.com/studio

### **1.2 Open Your Project**
1. Click **"Open"** or **"File → Open"**
2. Navigate to: `C:\Users\Shubham Singh\Desktop\chamak\android`
3. **Important:** Select the `android` folder, not the `chamak` folder
4. Click **"OK"**

### **1.3 Wait for Gradle Sync**
- Android Studio will start syncing Gradle files
- **First time:** This may take 5-10 minutes (downloading dependencies)
- **Subsequent times:** Usually 1-2 minutes
- Wait until you see: **"Gradle sync completed"** at the bottom

**If you see errors:**
- Don't worry, we're just getting SHA fingerprints
- Click **"Sync Now"** if prompted

---

## ✅ **STEP 2: Open Gradle Panel** (30 seconds)

### **2.1 Find Gradle Panel**
- Look at the **right side** of Android Studio
- You should see a panel with tabs like: **Project**, **Structure**, **Gradle**
- Click on the **"Gradle"** tab

**If you don't see Gradle tab:**
- Go to: **View → Tool Windows → Gradle**
- Or press: **Alt + 4** (Windows) / **Cmd + 4** (Mac)

### **2.2 Expand Project Structure**
In the Gradle panel, you'll see:
```
📁 chamak
  📁 android
    📁 app
      📁 Tasks
        📁 android
```

---

## ✅ **STEP 3: Run signingReport** (1 minute)

### **3.1 Navigate to signingReport**
1. In Gradle panel, expand: **chamak**
2. Expand: **android**
3. Expand: **app**
4. Expand: **Tasks**
5. Expand: **android**
6. Look for: **`signingReport`**

### **3.2 Run signingReport**
1. **Double-click** on **`signingReport`**
2. Or **right-click** → **Run**

### **3.3 Wait for Execution**
- Android Studio will run the task
- Takes about 10-30 seconds
- You'll see progress at the bottom

---

## ✅ **STEP 4: Get SHA Fingerprints** (1 minute)

### **4.1 Check Run Tab**
1. Look at the **bottom** of Android Studio
2. Find the **"Run"** tab (or **"Build"** tab)
3. Click on it to see the output

### **4.2 Find SHA Fingerprints**
Scroll through the output and look for:

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

### **4.3 Copy SHA Fingerprints**
1. **Find the line starting with "SHA1:"**
   - It will look like: `SHA1: A1:B2:C3:D4:E5:F6:...` (20 pairs of hex characters)
   - **Copy the entire line** including "SHA1:" and all the characters

2. **Find the line starting with "SHA-256:"**
   - It will look like: `SHA-256: A1:B2:C3:D4:E5:F6:...` (32 pairs of hex characters)
   - **Copy the entire line** including "SHA-256:" and all the characters

3. **Save them somewhere safe:**
   - Open Notepad
   - Paste both SHA-1 and SHA-256
   - Save the file (e.g., `SHA_FINGERPRINTS.txt`)

**Example of what you'll copy:**
```
SHA1: A1:B2:C3:D4:E5:F6:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE
SHA-256: A1:B2:C3:D4:E5:F6:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA
```

---

## ✅ **STEP 5: Add SHA Fingerprints to Firebase Console** (3 minutes)

### **5.1 Open Firebase Console**
1. Open your web browser
2. Go to: **https://console.firebase.google.com/**
3. Sign in with your Google account (if not already signed in)

### **5.2 Select Your Project**
1. Click on project: **chamak-39472**
2. If you don't see it, check you're using the correct Google account

### **5.3 Open Project Settings**
1. Click the **⚙️ Settings** icon (gear icon) in the top left
2. Click **"Project settings"** from the dropdown menu

### **5.4 Find Your Android App**
1. Scroll down to **"Your apps"** section
2. Look for your Android app with package name: **`com.chamak.app`**
3. If you don't see it:
   - Click **"Add app"** button
   - Select **Android** icon
   - Enter package name: **`com.chamak.app`**
   - Click **"Register app"**

### **5.5 Add SHA-1 Fingerprint**
1. In the **"SHA certificate fingerprints"** section
2. Click **"Add fingerprint"** button
3. A text field will appear
4. **Paste your SHA-1** fingerprint (the one you copied from Android Studio)
5. Click **"Save"** button
6. ✅ SHA-1 added!

### **5.6 Add SHA-256 Fingerprint**
1. Click **"Add fingerprint"** button again
2. **Paste your SHA-256** fingerprint (the one you copied from Android Studio)
3. Click **"Save"** button
4. ✅ SHA-256 added!

### **5.7 Verify**
- You should now see **both** SHA-1 and SHA-256 listed under "SHA certificate fingerprints"
- ✅ Both fingerprints are saved!

---

## ✅ **STEP 6: Download Updated google-services.json** (1 minute)

### **6.1 Download File**
1. **Still in Firebase Console → Project Settings**
2. Scroll to **"Your apps"** section
3. Find your Android app (`com.chamak.app`)
4. Click **"Download google-services.json"** button
5. File will download to your **Downloads** folder

### **6.2 Verify Download**
- Check your Downloads folder
- File should be named: **`google-services.json`**
- ✅ File downloaded!

---

## ✅ **STEP 7: Replace google-services.json** (1 minute)

### **7.1 Locate Old File**
1. Go to: `C:\Users\Shubham Singh\Desktop\chamak\android\app\`
2. Find the file: **`google-services.json`**

### **7.2 Replace File**
1. **Delete** or **rename** the old `google-services.json` (backup: rename to `google-services.json.old`)
2. **Copy** the new downloaded `google-services.json` from Downloads folder
3. **Paste** it into: `C:\Users\Shubham Singh\Desktop\chamak\android\app\`
4. Make sure it's named exactly: **`google-services.json`** (not `google-services (1).json`)

### **7.3 Verify Package Name**
1. Open the new `google-services.json` in a text editor (Notepad)
2. Search for: **`"package_name"`**
3. Verify it says: **`"package_name": "com.chamak.app"`**
4. ✅ Package name matches!

---

## ✅ **STEP 8: Clean and Rebuild App** (2 minutes)

### **8.1 Clean Project**
Open terminal/command prompt in your project:
```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter clean
```

### **8.2 Get Dependencies**
```bash
flutter pub get
```

### **8.3 Rebuild App**
```bash
flutter run
```

Or build APK:
```bash
flutter build apk --debug
```

---

## ✅ **STEP 9: Test with Real Phone Number** (2 minutes)

### **9.1 Run Your App**
- Launch the app on your device/emulator

### **9.2 Test Login**
1. Enter a **real phone number** (not a test number)
   - Format: `9876543210` (without country code, it will add +91 automatically)
2. Click **"Send OTP"**
3. **Wait for SMS** - You should receive an OTP code on your phone
4. Enter the **OTP code** from SMS
5. Click **"Verify OTP"**
6. ✅ **Login successful!**

---

## 🎉 **Success!**

If you received the OTP SMS and logged in successfully, **everything is working!**

---

## 🚨 **Troubleshooting**

### **Problem: Can't find signingReport in Gradle**
**Solution:**
- Make sure you expanded: `chamak` → `android` → `app` → `Tasks` → `android`
- Try refreshing Gradle: Right-click on project → **"Sync Project with Gradle Files"**

### **Problem: Gradle sync failed**
**Solution:**
- Check internet connection
- Try: **File → Invalidate Caches / Restart**
- Or: **Build → Clean Project**, then **Build → Rebuild Project**

### **Problem: No SHA fingerprints in output**
**Solution:**
- Make sure you're looking at the **"Run"** or **"Build"** tab
- Scroll through all the output
- Try running `signingReport` again

### **Problem: Can't add fingerprint in Firebase**
**Solution:**
- Make sure you copied the **entire** SHA fingerprint (including colons)
- Check you're in the correct Firebase project
- Try refreshing the Firebase Console page

### **Problem: Still getting "missing app identifier" error**
**Solution:**
- Wait **5-10 minutes** after adding SHA fingerprints (Firebase needs time to update)
- Make sure you downloaded **new** `google-services.json` after adding SHA
- Verify package name matches exactly: `com.chamak.app`
- Try: `flutter clean` and rebuild

### **Problem: OTP not received**
**Solution:**
- Check phone number format is correct
- Verify Firebase Phone Auth is enabled in Console
- Check Firebase Console → Usage → Phone Auth quota
- Make sure you're using a real phone number (not test number)

---

## 📋 **Quick Checklist**

- [ ] Opened project in Android Studio
- [ ] Gradle sync completed
- [ ] Found Gradle panel
- [ ] Ran signingReport
- [ ] Copied SHA-1 fingerprint
- [ ] Copied SHA-256 fingerprint
- [ ] Opened Firebase Console
- [ ] Added SHA-1 to Firebase
- [ ] Added SHA-256 to Firebase
- [ ] Downloaded new google-services.json
- [ ] Replaced old google-services.json
- [ ] Cleaned and rebuilt app
- [ ] Tested with real phone number
- [ ] Received OTP SMS
- [ ] Login successful!

---

## 💡 **Pro Tips**

1. **Save SHA fingerprints** - Keep them in a safe place, you'll need them again
2. **Take screenshots** - Screenshot the Firebase Console after adding fingerprints
3. **Wait 5-10 minutes** - After adding SHA, wait before testing
4. **Test immediately** - After rebuilding, test right away to verify it works

---

## 🎯 **What's Next?**

After completing these steps:
- ✅ Real users can use their phone numbers
- ✅ Real SMS OTP will be sent
- ✅ Production-ready authentication!

**Need help?** Tell me which step you're on and I'll guide you through it!

---

**Last Updated:** Today  
**Estimated Time:** 10-15 minutes  
**Difficulty:** Easy (just follow the steps!)


