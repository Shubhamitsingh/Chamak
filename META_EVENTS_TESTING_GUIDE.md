f# 🧪 Meta App Events - Testing Guide

## 📊 **Current Status (From Your Events Manager)**

**App:** Chamakz-Live Video Chat&Dating  
**App ID:** `870685012329386`  
**Current Status:** "Never received events" ⚠️  
**Total Events:** 0

**This is NORMAL!** Events will appear after you build and run your app.

---

## ✅ **Why You See "Never received events"**

This is **expected** because:
1. ✅ SDK is integrated in code (DONE)
2. ✅ Dashboard is configured (DONE)
3. ⚠️ App hasn't been built/run yet (NEED TO DO THIS)

**Events only appear AFTER you:**
- Build the app with the new SDK
- Run it on a device
- Open the app (triggers App Install event)
- Use the app (triggers App Launch events)

---

## 🚀 **Step-by-Step Testing Instructions**

### **Step 1: Clean and Build Your App**

```bash
# Navigate to your project
cd "C:\Users\Shubham Singh\Desktop\chamak"

# Clean previous build
flutter clean

# Get dependencies (including new Facebook SDK)
flutter pub get

# Build and run on device
flutter run
```

**Important:** Make sure you're running on a **real device** (not emulator) for best results.

---

### **Step 2: Open Your App**

1. **Launch the app** on your device
2. **Wait for app to fully load**
3. **Navigate through a few screens** (home, profile, etc.)
4. **Keep app open for 1-2 minutes**

**What Happens:**
- First time opening → Triggers **"App Install"** event
- Every time opening → Triggers **"App Launch"** event

---

### **Step 3: Wait for Events (1-2 minutes)**

**Meta processes events in batches**, so:
- ⏱️ Events may take **1-2 minutes** to appear
- ⏱️ Sometimes up to **5 minutes** for first events
- ⏱️ This is **normal** - be patient!

---

### **Step 4: Check Events Manager Again**

1. **Go to:** https://business.facebook.com/events_manager2
2. **Select your app:** "Chamakz-Live Video Chat&Dating"
3. **Refresh the page** (F5 or Ctrl+R)
4. **Look for:**
   - ✅ "Total events" should show a number > 0
   - ✅ Graph should show activity
   - ✅ Status should change from "Never received events"

---

## 🔍 **What Events You Should See**

### **Automatic Events (No Code Needed):**

1. **App Install Event** 📱
   - Fires: First time user opens app
   - Should see: 1 event (if first time)

2. **App Launch Event** 🚀
   - Fires: Every time app opens
   - Should see: Multiple events (one per app open)

3. **App Activated Event** ✅
   - Fires: When app becomes active
   - Should see: Multiple events

---

## ⚠️ **Troubleshooting: If Events Still Don't Appear**

### **Check 1: Verify SDK is in Build**

```bash
# Check if Facebook SDK is downloaded
flutter pub get

# Check build.gradle has Facebook SDK
# Should see: implementation 'com.facebook.android:facebook-android-sdk:17.0.0'
```

### **Check 2: Verify App ID in Code**

**File:** `android/app/src/main/res/values/strings.xml`
```xml
<string name="facebook_app_id">870685012329386</string>
```

**File:** `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id"/>
```

### **Check 3: Check Android Logs**

```bash
# Run app and check logs
flutter run

# Look for Facebook SDK messages:
# Should see: "Facebook SDK initialized"
# Should see: "App Events logged"
```

### **Check 4: Verify Internet Connection**

- ✅ Device must have internet connection
- ✅ Events are sent to Meta servers
- ✅ No internet = No events

### **Check 5: Wait Longer**

- ⏱️ First events can take **5-10 minutes**
- ⏱️ Meta processes events in batches
- ⏱️ Be patient and refresh Events Manager

---

## 🎯 **Expected Results**

### **After Testing, You Should See:**

**In Events Manager:**
- ✅ Total events: > 0 (e.g., "5", "10", etc.)
- ✅ Event activity graph showing bars
- ✅ Status: "Receiving events" or similar
- ✅ Recent events list showing:
  - "App Install" (1 event)
  - "App Launch" (multiple events)

**Timeline:**
- **0-2 minutes:** Events may not appear yet
- **2-5 minutes:** Events should start appearing
- **5-10 minutes:** All events should be visible

---

## 📱 **Quick Test Checklist**

- [ ] ✅ Built app with `flutter clean && flutter pub get && flutter run`
- [ ] ✅ Opened app on real device
- [ ] ✅ Waited 2-5 minutes
- [ ] ✅ Refreshed Events Manager page
- [ ] ✅ Checked "Total events" number
- [ ] ✅ Verified events appear in graph

---

## 🔧 **If Events Still Don't Appear After 10 Minutes**

### **Option 1: Check App ID Match**

1. **In Events Manager:** App ID should be `870685012329386`
2. **In strings.xml:** Should be `870685012329386`
3. **In AndroidManifest.xml:** Should reference `@string/facebook_app_id`

**All three must match!**

### **Option 2: Rebuild App**

```bash
# Complete clean rebuild
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### **Option 3: Check Test Mode**

1. **In Events Manager:** Enable "Test Mode" toggle
2. **Run app again**
3. **Check for test events**

### **Option 4: Verify Package Name**

**In Meta Dashboard:**
- Package name: `com.chamakz.app`

**In build.gradle:**
- applicationId: `com.chamakz.app`

**Must match exactly!**

---

## ✅ **Success Indicators**

**You'll know it's working when:**

1. ✅ **Events Manager shows:**
   - Total events > 0
   - Event activity graph has bars
   - Status shows "Receiving events"

2. ✅ **Android logs show:**
   - "Facebook SDK initialized"
   - "App Events logged successfully"

3. ✅ **App runs normally:**
   - No crashes
   - No errors related to Facebook SDK

---

## 🎉 **Once Events Appear**

**Congratulations!** Your integration is working! 🎉

**Next Steps:**
1. ✅ Wait for more events to accumulate
2. ✅ Test different app actions
3. ✅ Verify events in Events Manager
4. ✅ Ready to run app install campaigns!

---

## 📋 **Quick Reference**

**Events Manager:** https://business.facebook.com/events_manager2  
**App Dashboard:** https://developers.facebook.com/apps/870685012329386  
**Test Your App:** `flutter run`  
**Wait Time:** 2-5 minutes for first events

---

**Status:** SDK Integrated ✅ | Ready to Test ⚠️  
**Next:** Build and run your app, then check Events Manager!
