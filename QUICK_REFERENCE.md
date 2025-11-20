# ⚡ Quick Reference - Android Studio SHA Fingerprints

## 🎯 **5-Minute Quick Guide**

### **1. Android Studio** (2 min)
```
Open Android Studio
→ File → Open → Select: chamak/android
→ Wait for Gradle sync
→ Gradle Panel (right side)
→ chamak → android → app → Tasks → android → signingReport
→ Double-click signingReport
→ Check Run tab → Copy SHA-1 and SHA-256
```

### **2. Firebase Console** (2 min)
```
https://console.firebase.google.com/project/chamak-39472/settings/general
→ Scroll to "Your apps" → com.chamak.app
→ Click "Add fingerprint" → Paste SHA-1 → Save
→ Click "Add fingerprint" → Paste SHA-256 → Save
→ Click "Download google-services.json"
```

### **3. Replace File** (1 min)
```
Downloads folder → google-services.json
→ Copy to: chamak/android/app/
→ Replace old file
```

### **4. Rebuild** (1 min)
```bash
flutter clean
flutter pub get
flutter run
```

### **5. Test**
```
Enter real phone number → Send OTP → Receive SMS → Enter OTP → ✅ Done!
```

---

## 📍 **Key Locations**

- **Android Studio Project:** `C:\Users\Shubham Singh\Desktop\chamak\android`
- **Gradle Panel:** Right side → Gradle tab
- **signingReport:** `app → Tasks → android → signingReport`
- **Firebase Console:** https://console.firebase.google.com/project/chamak-39472/settings/general
- **google-services.json:** `android/app/google-services.json`

---

## ✅ **What You'll Copy**

**SHA-1:**
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**SHA-256:**
```
SHA-256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

---

## 🆘 **Quick Help**

**Can't find signingReport?**
- Make sure you expanded: `app → Tasks → android`

**No SHA in output?**
- Check the "Run" tab at bottom
- Scroll through all output

**Still getting error?**
- Wait 5-10 minutes after adding SHA
- Make sure you downloaded new google-services.json

---

**See `ANDROID_STUDIO_SHA_GUIDE.md` for detailed instructions!**


