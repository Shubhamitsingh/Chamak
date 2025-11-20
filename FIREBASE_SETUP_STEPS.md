# 🚀 Firebase Setup - Step-by-Step (I'll Help You!)

## ✅ **What I Can Do For You:**

1. ✅ Created script to get SHA fingerprints (`get-sha-fingerprints.ps1`)
2. ✅ Verified your package name: `com.chamak.app` ✅
3. ✅ Verified your Firebase project: `chamak-39472` ✅
4. ✅ Created complete guides

## ⚠️ **What You Need to Do (Manual Steps):**

I can't access Firebase Console directly, but I'll guide you through it!

---

## 📋 **Step-by-Step Process:**

### **STEP 1: Get SHA Fingerprints** ⏱️ 2 minutes

**Option A: Run the script I created**
```powershell
# In PowerShell, run:
.\get-sha-fingerprints.ps1
```

**Option B: Use Android Studio** (if you have it)
1. Open Android Studio
2. Open project: `chamak/android`
3. Gradle → `app` → `Tasks` → `android` → `signingReport`
4. Copy SHA-1 and SHA-256 from output

**Option C: Use Flutter Build**
```bash
flutter build apk --debug
# Look for SHA fingerprints in the output
```

---

### **STEP 2: Add to Firebase Console** ⏱️ 3 minutes

**I'll guide you through this:**

1. **Open Firebase Console:**
   - Go to: https://console.firebase.google.com/project/chamak-39472/settings/general
   - Sign in if needed

2. **Find Your Android App:**
   - Scroll down to **"Your apps"** section
   - Look for: `com.chamak.app`
   - If you don't see it, click **"Add app"** → **Android** → Package: `com.chamak.app`

3. **Add SHA-1:**
   - In **"SHA certificate fingerprints"** section
   - Click **"Add fingerprint"** button
   - Paste your **SHA-1** (from Step 1)
   - Click **"Save"**

4. **Add SHA-256:**
   - Click **"Add fingerprint"** button again
   - Paste your **SHA-256** (from Step 1)
   - Click **"Save"**

5. **Verify:**
   - You should see both SHA-1 and SHA-256 listed
   - ✅ Done!

---

### **STEP 3: Download google-services.json** ⏱️ 1 minute

1. **Still in Firebase Console → Project Settings**
2. **Find your Android app** (`com.chamak.app`)
3. **Click "Download google-services.json"**
4. **File downloads to your Downloads folder**

---

### **STEP 4: Replace the File** ⏱️ 1 minute

**I can help you with this!** Just tell me when you've downloaded it, and I'll help you replace it.

Or do it manually:
1. Go to: `C:\Users\Shubham Singh\Desktop\chamak\android\app\`
2. Delete old `google-services.json`
3. Copy new downloaded `google-services.json` here
4. Make sure it's named exactly: `google-services.json`

---

### **STEP 5: Rebuild App** ⏱️ 2 minutes

**I can run these commands for you!** Just say "rebuild" and I'll do it.

Or run manually:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🎯 **Quick Summary:**

1. ✅ **Get SHA fingerprints** → Run `get-sha-fingerprints.ps1` or use Android Studio
2. ⚠️ **Add to Firebase** → Manual step (I'll guide you)
3. ⚠️ **Download google-services.json** → Manual step (I'll guide you)
4. ✅ **Replace file** → I can help with this
5. ✅ **Rebuild** → I can run commands for you

---

## 💬 **Tell Me:**

1. **Do you have Java installed?** (for the script)
2. **Do you have Android Studio?** (easier method)
3. **Ready to start?** Say "yes" and I'll guide you step by step!

---

## 🚀 **Let's Start!**

**Run this command to get SHA fingerprints:**
```powershell
.\get-sha-fingerprints.ps1
```

Then share the output with me, and I'll guide you through adding them to Firebase!


