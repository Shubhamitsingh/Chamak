# ✅ Production Setup Checklist

## 🎯 **Quick Checklist - Follow in Order**

### **Step 1: Get SHA Fingerprints** ⏱️ 5 minutes
- [ ] Open Android Studio
- [ ] Open project: `chamak/android`
- [ ] Gradle → `app` → `Tasks` → `android` → `signingReport`
- [ ] Copy **SHA-1**: `XX:XX:XX:...`
- [ ] Copy **SHA-256**: `XX:XX:XX:...`

### **Step 2: Add to Firebase** ⏱️ 3 minutes
- [ ] Go to: https://console.firebase.google.com/
- [ ] Select project: **chamak-39472**
- [ ] Settings → Project settings
- [ ] Scroll to **Your apps** → Android app
- [ ] Click **Add fingerprint** → Paste SHA-1 → Save
- [ ] Click **Add fingerprint** → Paste SHA-256 → Save

### **Step 3: Download Config** ⏱️ 1 minute
- [ ] In Firebase Console → Project settings
- [ ] Click **Download google-services.json**
- [ ] Replace file: `android/app/google-services.json`

### **Step 4: Verify Package Name** ⏱️ 1 minute
- [ ] Check `android/app/build.gradle`: `applicationId = "com.chamak.app"`
- [ ] Check `google-services.json`: `"package_name": "com.chamak.app"`
- [ ] ✅ Both match exactly

### **Step 5: Rebuild** ⏱️ 2 minutes
- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter run`

### **Step 6: Test** ⏱️ 2 minutes
- [ ] Enter real phone number
- [ ] Click "Send OTP"
- [ ] ✅ Receive SMS with OTP code
- [ ] Enter OTP → ✅ Login successful!

---

## 🎉 **Total Time: ~15 minutes**

---

## 📋 **For Release Builds (Later):**

### **Step 7: Create Release Keystore** ⏱️ 5 minutes
- [ ] Run: `keytool -genkey -v -keystore chamak-release-key.jks ...`
- [ ] Get release SHA fingerprints
- [ ] Add release SHA to Firebase Console

### **Step 8: Configure Release** ⏱️ 5 minutes
- [ ] Update `build.gradle` with signing config
- [ ] Build release APK: `flutter build apk --release`
- [ ] Test release build

---

## ✅ **Done!**

Your app is now production-ready for phone authentication! 🚀

---

**See `PRODUCTION_SETUP_COMPLETE_GUIDE.md` for detailed instructions.**


