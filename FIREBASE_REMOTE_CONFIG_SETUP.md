# 🔥 Firebase Remote Config Setup - Step by Step Guide

## 📋 Prerequisites
- Firebase project already set up (you have this)
- Access to Firebase Console
- Your app is connected to Firebase (already done)

---

## 🚀 Step-by-Step Setup

### **Step 1: Open Firebase Console**

1. Go to: https://console.firebase.google.com/
2. Select your project: **"chamak"** (or your project name)
3. Wait for the dashboard to load

---

### **Step 2: Navigate to Remote Config**

**IMPORTANT:** Remote Config is NOT in the "Build" section!

1. In the left sidebar, look for **"Engage"** section
   - Click on **"Engage"** to expand it
   - You'll see: **"Remote Config"** inside the Engage section

2. **OR** use the search bar:
   - Click the search icon at the top
   - Type: **"Remote Config"**
   - Click on it from search results

3. Click on **"Remote Config"**

**Note:** If you don't see "Engage" section or "Remote Config":
- It might need to be enabled first
- Look for it in the main menu (not under Build)
- It's usually between "Build" and "Analytics" sections

---

### **Step 3: Add Parameters**

You'll see a screen with "Add parameter" button. Click it and add these parameters one by one:

#### **Parameter 1: latest_version**

1. Click **"Add parameter"**
2. **Parameter key:** `latest_version`
3. **Default value:** `1.0.6` (your current app version)
4. **Description:** Latest available app version
5. Click **"Save"**

#### **Parameter 2: update_details_features**

1. Click **"Add parameter"** again
2. **Parameter key:** `update_details_features`
3. **Default value:** (leave empty or add: `Dark mode theme,Improved chat performance`)
4. **Description:** Comma-separated list of new features
5. Click **"Save"**

#### **Parameter 3: update_details_improvements**

1. Click **"Add parameter"**
2. **Parameter key:** `update_details_improvements`
3. **Default value:** (leave empty or add: `Faster app loading,Better battery optimization`)
4. **Description:** Comma-separated list of improvements
5. Click **"Save"**

#### **Parameter 4: update_details_bug_fixes**

1. Click **"Add parameter"**
2. **Parameter key:** `update_details_bug_fixes`
3. **Default value:** (leave empty or add: `Fixed crash issues,Resolved notification problems`)
4. **Description:** Comma-separated list of bug fixes
5. Click **"Save"**

#### **Parameter 5: update_details_force_update**

1. Click **"Add parameter"**
2. **Parameter key:** `update_details_force_update`
3. **Default value:** `false`
4. **Value type:** Select **"Boolean"** (not String)
5. **Description:** Force users to update (set to true for critical updates)
6. Click **"Save"**

#### **Parameter 6: update_details_message**

1. Click **"Add parameter"**
2. **Parameter key:** `update_details_message`
3. **Default value:** `A new version is available with exciting features and improvements!`
4. **Description:** Custom message shown to users
5. Click **"Save"**

---

### **Step 4: Publish Configuration**

After adding all parameters:

1. You'll see all 6 parameters listed
2. Click the **"Publish changes"** button (top right)
3. Review the changes
4. Click **"Publish"** to confirm
5. Wait for confirmation: "Published successfully"

---

### **Step 5: Test in Your App**

1. **Run your app:**
   ```bash
   flutter run
   ```

2. **Navigate to Update menu:**
   - Open Settings screen
   - Tap "Update" menu item

3. **Expected behavior:**
   - Shows loading indicator
   - Fetches data from Firebase
   - Shows "App is Up to Date" (since latest_version = 1.0.6, same as current)

---

## 🧪 Testing Update Available Scenario

### **To test if update is available:**

1. **Go back to Firebase Console**
2. **Edit `latest_version` parameter:**
   - Change value from `1.0.6` to `1.0.7`
   - Click **"Save"**
   - Click **"Publish changes"**

3. **Add some update details:**
   - Edit `update_details_features`: `Dark mode theme,Improved chat performance`
   - Edit `update_details_improvements`: `Faster app loading,Better battery`
   - Edit `update_details_bug_fixes`: `Fixed crash issues`
   - Click **"Publish changes"**

4. **Test in app:**
   - Open Update menu again
   - Should now show "Update Available" screen
   - Should display features, improvements, bug fixes
   - "Update Now" button should open Play Store

---

## 📸 Visual Guide (What You'll See)

### **Firebase Console - Remote Config Screen:**

```
┌─────────────────────────────────────────┐
│  Remote Config                          │
│  [Add parameter]  [Publish changes]     │
├─────────────────────────────────────────┤
│  Parameters:                             │
│                                          │
│  ✅ latest_version                       │
│     Default: 1.0.6                       │
│                                          │
│  ✅ update_details_features              │
│     Default: (empty)                     │
│                                          │
│  ✅ update_details_improvements          │
│     Default: (empty)                     │
│                                          │
│  ✅ update_details_bug_fixes             │
│     Default: (empty)                     │
│                                          │
│  ✅ update_details_force_update          │
│     Default: false                       │
│                                          │
│  ✅ update_details_message               │
│     Default: A new version...           │
└─────────────────────────────────────────┘
```

---

## 🔄 How to Update Version Info (When You Release New Version)

### **When you release version 1.0.7:**

1. **Update Firebase Remote Config:**
   - Change `latest_version` to `1.0.7`
   - Add new features to `update_details_features`
   - Add improvements to `update_details_improvements`
   - Add bug fixes to `update_details_bug_fixes`
   - Update `update_details_message` if needed
   - Click **"Publish changes"**

2. **Update App Version:**
   - Update `version` in `pubspec.yaml`: `1.0.7+13`
   - Update `versionName` and `versionCode` in `android/app/build.gradle`
   - Build new APK/AAB
   - Upload to Play Store

3. **Users will see update:**
   - When they open Update menu
   - App automatically compares versions
   - Shows update details if new version available

---

## ✅ Quick Checklist

- [ ] Opened Firebase Console
- [ ] Navigated to Remote Config
- [ ] Added `latest_version` parameter
- [ ] Added `update_details_features` parameter
- [ ] Added `update_details_improvements` parameter
- [ ] Added `update_details_bug_fixes` parameter
- [ ] Added `update_details_force_update` parameter
- [ ] Added `update_details_message` parameter
- [ ] Published all changes
- [ ] Tested in app (should show "Up to Date")
- [ ] Tested update scenario (changed version to 1.0.7)

---

## 🎯 Example Values for Testing

### **For Version 1.0.7 Update:**

```
latest_version: "1.0.7"

update_details_features: "Dark mode theme,Improved chat performance,Enhanced security features,New profile customization options"

update_details_improvements: "Faster app loading time,Better battery optimization,Smoother animations,Reduced app size by 20%"

update_details_bug_fixes: "Fixed crash on profile screen,Resolved notification delivery issues,Fixed payment gateway error,Corrected Hindi language translations"

update_details_force_update: false

update_details_message: "We've added exciting new features and improvements! Update now to enjoy the best experience."
```

---

## 🐛 Troubleshooting

### **Issue: Can't find Remote Config**
- **Solution:** Click "Build" in left sidebar, then "Remote Config"

### **Issue: Parameters not showing in app**
- **Solution:** Make sure you clicked "Publish changes" after adding parameters

### **Issue: App shows error**
- **Solution:** Check internet connection, Firebase is initialized correctly

### **Issue: Always shows "Up to Date"**
- **Solution:** Make sure `latest_version` in Firebase is higher than current app version (1.0.6)

---

## 📞 Need Help?

If you get stuck:
1. Check Firebase Console → Remote Config → Parameters are added
2. Verify "Publish changes" was clicked
3. Check app has internet connection
4. Look at debug console for error messages

---

**Ready to set up? Follow the steps above!** 🚀
