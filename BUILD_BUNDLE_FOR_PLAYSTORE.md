# 📦 Build Bundle for Play Store - Step by Step Guide

**Current Version:** `1.1.4+26`  
**Version Name:** `1.1.4`  
**Version Code:** `26`

---

## ✅ Version Updated

### **Files Updated:**
- ✅ `pubspec.yaml`: `1.1.3+25` → `1.1.4+26`
- ✅ `android/app/build.gradle`: `versionCode = 25` → `26`, `versionName = "1.1.3"` → `"1.1.4"`

---

## 🚀 Build Commands

### **Step 1: Clean Previous Builds**
```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter clean
```

### **Step 2: Get Dependencies**
```powershell
flutter pub get
```

### **Step 3: Build Release Bundle (AAB) - RECOMMENDED for Play Store**
```powershell
flutter build appbundle --release
```

**Output Location:**
```
build/app/outputs/bundle/release/app-release.aab
```

### **Alternative: Build Release APK (For Testing)**
```powershell
flutter build apk --release
```

**Output Location:**
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📋 Pre-Build Checklist

Before building, ensure:

- [x] ✅ Version updated in `pubspec.yaml`
- [x] ✅ Version updated in `android/app/build.gradle`
- [ ] ⚠️ **Check:** `key.properties` file exists (for signing)
- [ ] ⚠️ **Check:** Keystore file exists
- [ ] ⚠️ **Check:** All dependencies installed (`flutter pub get`)

---

## 🔐 App Signing

Your app is configured to use release signing from `key.properties` file.

**Required Files:**
- `android/key.properties` (should exist)
- Keystore file (path specified in `key.properties`)

**If signing fails:**
1. Check `key.properties` file exists
2. Verify keystore file path is correct
3. Ensure keystore passwords are correct

---

## 📤 Upload to Play Console

### **Step 1: Go to Play Console**
https://play.google.com/console

### **Step 2: Select Your App**
- Select "Chamak" app

### **Step 3: Navigate to Release**
- Go to **Production** (or **Internal testing** / **Closed testing**)
- Click **Create new release**

### **Step 4: Upload AAB**
1. Click **Upload** button
2. Select file: `build/app/outputs/bundle/release/app-release.aab`
3. Wait for upload to complete

### **Step 5: Add Release Notes**
**What's new in this version:**
- Admin chat push notifications
- Banner loading optimizations
- UI improvements
- Bug fixes and performance improvements

### **Step 6: Review and Release**
1. Click **Review release**
2. Review all information
3. Click **Start rollout to Production**

---

## ✅ Post-Upload Checklist

After uploading:

- [ ] ✅ AAB uploaded successfully
- [ ] ✅ Release notes added
- [ ] ✅ Version code verified (26)
- [ ] ✅ Version name verified (1.1.4)
- [ ] ✅ Review completed
- [ ] ✅ Rollout started

---

## 📊 Version Information

| Component | Value |
|----------|-------|
| **Version Name** | `1.1.4` |
| **Version Code** | `26` |
| **Full Version** | `1.1.4+26` |
| **Bundle File** | `app-release.aab` |
| **File Location** | `build/app/outputs/bundle/release/` |

---

## ⚠️ Important Notes

1. **Version Code Must Always Increase:**
   - Play Console rejects uploads with same or lower version code
   - Current version code: **26** ✅
   - Next upload must be **27** or higher

2. **AAB vs APK:**
   - **AAB (App Bundle)** - Recommended for Play Store (smaller size, optimized)
   - **APK** - Use for testing or direct distribution

3. **Signing:**
   - Release builds are automatically signed using `key.properties`
   - Ensure keystore file is secure and backed up

---

## 🐛 Troubleshooting

### **Error: "key.properties not found"**
**Solution:**
- Create `android/key.properties` file
- Add keystore configuration

### **Error: "Keystore file not found"**
**Solution:**
- Check keystore path in `key.properties`
- Ensure keystore file exists at specified path

### **Error: "Version code already exists"**
**Solution:**
- Increment version code in `build.gradle`
- Update version in `pubspec.yaml`

---

## 🎯 Quick Build Command (All-in-One)

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter clean
flutter pub get
flutter build appbundle --release
```

**Then upload:** `build/app/outputs/bundle/release/app-release.aab`

---

**Status:** ✅ **Ready to Build**  
**Version:** `1.1.4+26`  
**Next Steps:** Run build commands above
