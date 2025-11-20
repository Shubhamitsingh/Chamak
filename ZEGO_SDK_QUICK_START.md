# 🚀 ZEGO Cloud SDK - Quick Start Commands

## ✅ **Step-by-Step Commands (Run in Order)**

### **Step 1: Get ZEGO Credentials**

1. Go to: https://console.zegocloud.com/
2. Sign up / Log in
3. Create project → Select "Live Streaming"
4. Copy **App ID** and **App Sign**

### **Step 2: Update Config File**

Open: `lib/config/zego_config.dart`

Replace:
- `appID` with YOUR App ID
- `appSign` with YOUR App Sign

### **Step 3: Install Package**

```bash
flutter clean
flutter pub get
```

### **Step 4: Build and Run**

```bash
flutter run
```

---

## 📋 **Complete Command List**

```bash
# 1. Clean project
flutter clean

# 2. Get packages
flutter pub get

# 3. Run app
flutter run
```

**That's it!** 🎉

---

## ⚠️ **If You Get Errors**

### **Error: Package not found**
```bash
flutter pub cache repair
flutter pub get
```

### **Error: Build fails**
```bash
cd android
.\gradlew.bat clean
cd ..
flutter clean
flutter pub get
flutter run
```

### **Error: Network timeout**
- Wait 10-15 minutes (first build downloads dependencies)
- Check internet connection
- Try VPN if ZEGO servers blocked

---

## ✅ **What's Already Done**

- ✅ Package added to `pubspec.yaml`
- ✅ Config file created (`lib/config/zego_config.dart`)
- ✅ Service file created (`lib/services/zego_live_service.dart`)
- ✅ Live page updated (`lib/screens/live_page.dart`)
- ✅ Android Maven repositories added
- ✅ Gradle properties configured

**You just need to:**
1. Update ZEGO credentials in `zego_config.dart`
2. Run the commands above

---

## 🎯 **Next Steps After Setup**

1. **Test Basic Streaming:**
   - Navigate to live page as host
   - Should see "You are live streaming!"

2. **Add Video Rendering:**
   - Current setup is basic (no video yet)
   - Need to add `ZegoCanvas` widgets for video
   - Let me know if you want the full video implementation!

---

**Ready! Just update credentials and run the commands!** 🚀

