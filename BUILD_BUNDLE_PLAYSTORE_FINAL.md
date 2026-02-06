# 📦 Build Bundle for Play Store - Final Steps

**Current Version:** `1.1.5+27`  
**Version Name:** `1.1.5`  
**Version Code:** `27`

---

## ✅ Version Updated

### **Files Updated:**
- ✅ `pubspec.yaml`: `1.1.4+26` → `1.1.5+27`
- ✅ `android/app/build.gradle`: `versionCode = 26` → `27`, `versionName = "1.1.4"` → `"1.1.5"`

---

## 🚀 Build Commands

### **Step 1: Install Dependencies**
```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter pub get
```

### **Step 2: Clean Previous Builds**
```powershell
flutter clean
```

### **Step 3: Build Release Bundle (AAB)**
```powershell
flutter build appbundle --release
```

**Output Location:**
```
build/app/outputs/bundle/release/app-release.aab
```

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
- Google Play Store in-app purchases
- Removed PayPrime payment gateway
- Improved payment experience
- Bug fixes and performance improvements

### **Step 6: Review and Release**
1. Click **Review release**
2. Review all information
3. Click **Start rollout to Production**

---

## 📋 After Upload - Create Products

**Important:** After uploading the bundle, you need to create products in Play Console:

### **Step 1: Go to Products**
Play Console → Your App → **Monetize** → **Products** → **In-app products**

### **Step 2: Create Products**
Create 12 products with these exact IDs:

| Product ID | Name | Price (INR) | Coins |
|------------|------|-------------|-------|
| `coins_90` | 90 Coins | ₹9 | 90 |
| `coins_550` | 550 Coins | ₹49 | 550 |
| `coins_1100` | 1100 Coins | ₹99 | 1100 |
| `coins_1700` | 1700 Coins | ₹149 | 1700 |
| `coins_2400` | 2400 Coins | ₹199 | 2400 |
| `coins_3500` | 3500 Coins | ₹299 | 3500 |
| `coins_7500` | 7500 Coins | ₹599 | 7500 |
| `coins_13000` | 13000 Coins | ₹999 | 13000 |
| `coins_28000` | 28000 Coins | ₹1999 | 28000 |
| `coins_45000` | 45000 Coins | ₹2999 | 45000 |
| `coins_80000` | 80000 Coins | ₹4999 | 80000 |
| `coins_175000` | 175000 Coins | ₹9999 | 175000 |

**Important:**
- Product ID must match exactly (case-sensitive)
- Set prices in Play Console
- Status: **Active**

### **Step 3: Enable In-App Products**
1. Go to **Monetize** → **Products** → **In-app products**
2. Click **Enable** for in-app products
3. Accept terms and conditions

---

## ✅ Pre-Build Checklist

Before building, ensure:

- [x] ✅ Version updated in `pubspec.yaml` (1.1.5+27)
- [x] ✅ Version updated in `android/app/build.gradle` (27, 1.1.5)
- [ ] ⚠️ **Check:** `key.properties` file exists (for signing)
- [ ] ⚠️ **Check:** Keystore file exists
- [ ] ⚠️ **Check:** All dependencies installed

---

## 🔐 App Signing

Your app is configured to use release signing from `key.properties` file.

**Required Files:**
- `android/key.properties` (should exist)
- Keystore file (path specified in `key.properties`)

---

## 📊 Version Information

| Component | Value |
|----------|-------|
| **Version Name** | `1.1.5` |
| **Version Code** | `27` |
| **Full Version** | `1.1.5+27` |
| **Bundle File** | `app-release.aab` |
| **File Location** | `build/app/outputs/bundle/release/` |

---

## ⚠️ Important Notes

1. **Version Code Must Always Increase:**
   - Play Console rejects uploads with same or lower version code
   - Current version code: **27** ✅
   - Next upload must be **28** or higher

2. **Products Must Be Created:**
   - After uploading bundle, create products in Play Console
   - Product IDs must match exactly: `coins_90`, `coins_550`, etc.
   - Products must be **Active** for purchases to work

3. **Testing:**
   - Add test accounts in Play Console
   - Test purchases before going live
   - Verify coins are added correctly

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

## 📋 Post-Upload Checklist

After uploading to Play Console:

- [ ] ✅ AAB uploaded successfully
- [ ] ✅ Release notes added
- [ ] ✅ Version code verified (27)
- [ ] ✅ Version name verified (1.1.5)
- [ ] ✅ Review completed
- [ ] ✅ Rollout started
- [ ] ⚠️ **Create 12 products in Play Console**
- [ ] ⚠️ **Enable in-app products**
- [ ] ⚠️ **Add test accounts**
- [ ] ⚠️ **Test purchase flow**

---

**Status:** ✅ **Version Updated** - Ready to Build  
**Version:** `1.1.5+27`  
**Next:** Run build commands above
