# 🚀 Meta App Events SDK - Quick Setup Guide

## ⚡ **Quick Answer to Your Questions**

### **Q: What is Meta App Events SDK?**
**A:** It's a tool that tracks when people install and use your app. Meta uses this data to optimize your ad campaigns.

### **Q: Is it compulsory for app install campaigns?**
**A:** **YES** - Without it, your campaigns won't work well. Meta strongly recommends it.

### **Q: What does it do?**
**A:** 
- ✅ Tracks app installs automatically
- ✅ Tracks app launches automatically  
- ✅ Tracks purchases automatically
- ✅ Sends data to Meta for campaign optimization

---

## 📋 **What You Need (Before I Can Help)**

### **Step 1: Get Your Meta App ID**

1. **Go to:** https://developers.facebook.com/
2. **Login** with your Meta account
3. **Click:** "My Apps" → "Create App" (or select existing app)
4. **Go to:** Settings → Basic
5. **Find:** "App ID" (looks like: `1234567890123456`)
6. **Copy it** and give it to me

**OR if you already have an app:**
- Go to your app dashboard
- Settings → Basic
- Copy the App ID

---

## 🔧 **What I Will Do (After You Give Me App ID)**

### **I will add to your app:**

1. ✅ **Facebook SDK dependency** in `android/app/build.gradle`
2. ✅ **Meta App ID** in `AndroidManifest.xml`
3. ✅ **SDK initialization** in your Flutter app
4. ✅ **Automatic event logging** (app install, app launch, purchases)

### **Files I will modify:**

- `android/app/build.gradle` - Add Facebook SDK
- `android/app/src/main/AndroidManifest.xml` - Add App ID
- `lib/main.dart` - Initialize SDK (optional, can be done in native code)

---

## 📝 **Step-by-Step Integration (What Happens)**

### **Step 1: Add Facebook SDK to build.gradle**

```gradle
dependencies {
    // ... existing dependencies ...
    
    // Facebook SDK for App Events
    implementation 'com.facebook.android:facebook-android-sdk:latest.release'
}
```

### **Step 2: Add Meta App ID to AndroidManifest.xml**

```xml
<application>
    <!-- ... existing code ... -->
    
    <!-- Meta App ID for App Events -->
    <meta-data
        android:name="com.facebook.sdk.ApplicationId"
        android:value="@string/facebook_app_id"/>
    
    <!-- Enable automatic event logging -->
    <meta-data
        android:name="com.facebook.sdk.AutoLogAppEventsEnabled"
        android:value="true"/>
    
    <!-- Enable automatic SDK initialization -->
    <meta-data
        android:name="com.facebook.sdk.AutoInitEnabled"
        android:value="true"/>
</application>
```

### **Step 3: Add App ID to strings.xml**

Create/update `android/app/src/main/res/values/strings.xml`:

```xml
<resources>
    <string name="facebook_app_id">YOUR_APP_ID_HERE</string>
</resources>
```

### **Step 4: Initialize SDK (Optional - Auto-init works too)**

If you want manual initialization (for consent handling):

```kotlin
// In MainActivity.kt
import com.facebook.FacebookSdk

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Facebook SDK
        FacebookSdk.setAutoInitEnabled(true)
        FacebookSdk.fullyInitialize()
    }
}
```

---

## ✅ **After Integration - What Happens**

### **Automatic Events (No Code Needed):**

1. **App Install Event**
   - Fires automatically when user first opens app
   - Sent to Meta Events Manager

2. **App Launch Event**
   - Fires automatically every time app opens
   - Helps measure engagement

3. **Purchase Event** (if using Google Play Billing)
   - Fires automatically when purchase completes
   - Tracks revenue from campaigns

### **You'll See in Meta Events Manager:**
- Real-time install events
- Launch events
- Purchase events
- Attribution data (which ads led to installs)

---

## 🧪 **Testing**

### **Test Mode:**

1. **Enable Test Mode in Meta Dashboard:**
   - Go to Events Manager
   - Select your app
   - Enable "Test Mode"

2. **Test on Device:**
   ```bash
   flutter run
   ```
   - Open app
   - Check Events Manager for events

3. **Verify Events:**
   - Go to Events Manager
   - Should see "App Install" and "App Launch" events

---

## 🔐 **Privacy & Consent (Important!)**

### **If You Need User Consent:**

**Option 1: Disable Auto-Init (Recommended for Privacy)**

In `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.facebook.sdk.AutoInitEnabled"
    android:value="false"/>
```

Then enable after consent in your Flutter code:
```dart
// After user accepts privacy policy
import 'package:flutter/services.dart';

await MethodChannel('your_channel').invokeMethod('initFacebookSDK');
```

**Option 2: Keep Auto-Init (Simpler)**

If you don't need consent, keep auto-init enabled (default).

---

## 📊 **What This Enables**

### **In Meta Ads Manager:**
- ✅ Optimize campaigns for app installs
- ✅ Lower cost per install (CPI)
- ✅ Better targeting
- ✅ Accurate install measurement

### **In Meta Events Manager:**
- ✅ See real-time install events
- ✅ Track which ads led to installs
- ✅ Measure campaign effectiveness
- ✅ View detailed analytics

---

## ⚠️ **Important Notes**

1. **Free to Use:** SDK is completely free
2. **No Personal Data:** Only collects event data, not personal info
3. **Can Disable:** You can disable anytime if needed
4. **Lightweight:** No noticeable impact on app performance
5. **Required for Best Results:** Without it, campaigns perform poorly

---

## 🎯 **Summary**

### **What You Need to Do:**
1. ✅ Get Meta App ID from developers.facebook.com
2. ✅ Give me the App ID
3. ✅ Tell me if you need user consent handling

### **What I Will Do:**
1. ✅ Add Facebook SDK to your app
2. ✅ Configure everything
3. ✅ Test it
4. ✅ Give you testing instructions

### **Result:**
- ✅ Your app will track installs automatically
- ✅ Meta campaigns will optimize better
- ✅ Lower cost per install
- ✅ Better campaign performance

---

## 🚀 **Ready?**

**Just give me your Meta App ID and I'll set everything up!**

**To get App ID:**
1. Go to: https://developers.facebook.com/
2. My Apps → Your App → Settings → Basic
3. Copy "App ID"
4. Give it to me

**That's it!** 🎉
