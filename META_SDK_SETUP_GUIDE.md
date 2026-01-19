# Meta SDK (Meta Audience Network) Setup Guide for Chamak App
## Complete Step-by-Step Guide for Beginners

---

## 📋 **What is Meta SDK?**

Meta SDK (also called **Meta Audience Network** or **Facebook Audience Network**) allows you to show ads in your Android app. When users see or click these ads, you earn money.

**Important:** Google Play Store requires you to declare if you use Meta SDK for ads in your app.

---

## 🎯 **What You Need Before Starting**

✅ **Meta Account** (You said you already have this - Great!)  
✅ **Your App Package Name:** `com.chamakz.app` (I found this in your project)  
✅ **Your App Name:** Chamakz  
✅ **Google Play Console Account** (for publishing)

---

## 📝 **STEP 1: Create Your App in Meta Audience Network**

### **1.1 Go to Meta Audience Network Dashboard**

1. Open your browser and go to: **https://www.facebook.com/audiencenetwork**
2. Log in with your Meta account
3. Click on **"Get Started"** or **"Create App"**

### **1.2 Add Your Android App**

1. Click **"Add App"** or **"Create New App"**
2. Select **"Android"** as platform
3. Enter these details:
   - **App Name:** Chamakz
   - **Package Name:** `com.chamakz.app` (IMPORTANT: Use exactly this)
   - **Category:** Choose "Entertainment" or "Social"
4. Click **"Create App"**

### **1.3 Create Ad Placements**

After creating your app, you need to create **Ad Placements**. These are like "slots" where ads will appear.

**Types of Ads You Can Use:**
- **Banner Ads** - Small ads at top/bottom of screen
- **Interstitial Ads** - Full-screen ads between screens
- **Rewarded Video Ads** - Users watch video to get rewards (coins, etc.)

**How to Create Placements:**

1. In your app dashboard, click **"Placements"** tab
2. Click **"Create Placement"**
3. Choose ad type:
   - For **Banner:** Select "Banner"
   - For **Interstitial:** Select "Interstitial"
   - For **Rewarded Video:** Select "Rewarded Video"
4. Give it a name (e.g., "Home Banner", "Reward Video")
5. Click **"Create"**

### **1.4 Get Your Placement IDs**

After creating each placement, you'll see a **Placement ID** (looks like: `IMG_16_9_APP_INSTALL#1234567890123456`)

**⚠️ IMPORTANT:** Copy and save these Placement IDs. You'll need them in your code!

**Example:**
- Banner Placement ID: `IMG_16_9_APP_INSTALL#1234567890123456`
- Interstitial Placement ID: `IMG_16_9_APP_INSTALL#2345678901234567`
- Rewarded Video Placement ID: `VID_HD_16_9_46S_APP_INSTALL#3456789012345678`

### **1.5 Get Your Meta App ID**

1. In Meta dashboard, go to **"Settings"** → **"Basic"**
2. Find **"App ID"** (looks like: `1234567890123456`)
3. Copy this App ID - you'll need it too!

---

## 📝 **STEP 2: What Information I Need From You**

After you complete Step 1, please provide me:

1. **Meta App ID:** `_________________`
2. **Banner Placement ID:** `_________________` (if you want banner ads)
3. **Interstitial Placement ID:** `_________________` (if you want full-screen ads)
4. **Rewarded Video Placement ID:** `_________________` (if you want reward ads)

**Tell me which ad types you want:**
- [ ] Banner Ads
- [ ] Interstitial Ads  
- [ ] Rewarded Video Ads

---

## 📝 **STEP 3: I Will Integrate Meta SDK in Your App**

Once you provide the information above, I will:

1. ✅ Add Meta Audience Network Flutter plugin to your `pubspec.yaml`
2. ✅ Add Meta App ID to your `AndroidManifest.xml`
3. ✅ Initialize Meta SDK in your app
4. ✅ Create example code to show ads
5. ✅ Test the integration

**You don't need to do anything in this step - I'll handle it!**

---

## 📝 **STEP 4: Test Your Ads**

### **4.1 Use Test Mode First**

**⚠️ VERY IMPORTANT:** Always test with test ads before using real ads!

1. In Meta dashboard, go to your app settings
2. Enable **"Test Mode"**
3. Use test placement IDs for testing

**Test Placement IDs (Use these for testing):**
- Banner: `IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID`
- Interstitial: `IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID`
- Rewarded: `VID_HD_16_9_46S_APP_INSTALL#YOUR_PLACEMENT_ID`

### **4.2 Test on Real Device**

1. Build your app: `flutter build apk`
2. Install on your phone
3. Navigate to screens with ads
4. Check if ads appear correctly

---

## 📝 **STEP 5: Google Play Store Data Safety Declaration**

Google Play Store requires you to declare that you use ads.

### **5.1 In Google Play Console:**

1. Go to **Google Play Console** → Your App → **App Content**
2. Click **"Data Safety"**
3. Answer questions:
   - **"Does your app collect or share data?"** → Yes
   - **"Does your app use ads?"** → Yes
   - **"What ad SDKs do you use?"** → Select "Meta Audience Network"
4. Save and submit

---

## 🎯 **Summary - What You Need to Do Now**

1. ✅ **Go to:** https://www.facebook.com/audiencenetwork
2. ✅ **Create your app** with package name: `com.chamakz.app`
3. ✅ **Create ad placements** (Banner, Interstitial, or Rewarded Video)
4. ✅ **Copy your App ID and Placement IDs**
5. ✅ **Send me the IDs** and tell me which ad types you want
6. ✅ **I will integrate everything** in your code

---

## ❓ **Common Questions**

**Q: Do I need to pay Meta?**  
A: No! Meta pays YOU when users see/click ads.

**Q: Can I use multiple ad types?**  
A: Yes! You can use Banner, Interstitial, and Rewarded Video all together.

**Q: Will ads work immediately?**  
A: After integration, you need to wait 24-48 hours for Meta to review your app. Use test mode first.

**Q: What if I don't have Placement IDs yet?**  
A: Complete Step 1 first, then come back with the IDs.

---

## 🚀 **Next Steps**

**Right now, please:**
1. Complete **STEP 1** (Create app in Meta dashboard)
2. Get your **App ID** and **Placement IDs**
3. Tell me which ad types you want (Banner/Interstitial/Rewarded)
4. Send me the IDs

**Then I will:**
- Integrate everything in your Flutter app
- Add the code to show ads
- Test it with you

---

**Ready? Start with STEP 1 and let me know when you have your IDs!** 🎉
