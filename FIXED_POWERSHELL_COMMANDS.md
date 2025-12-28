# ✅ Fixed PowerShell Commands

## 🎯 **WORKING COMMANDS:**

### **Step 1: Navigate to Project**
```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
```

### **Step 2: Clean Flutter (Already Done ✅)**
```powershell
flutter clean
```

### **Step 3: Get Dependencies (Already Done ✅)**
```powershell
flutter pub get
```

### **Step 4: Run Release Build**
```powershell
flutter run --release
```

---

## ⚠️ **Note About gradlew clean:**

The `gradlew clean` command failed because JAVA_HOME is not set, but **that's OK!**

**`flutter clean` is enough** - it cleans both Flutter and Android build cache.

**You can skip `gradlew clean` and just run:**
```powershell
flutter run --release
```

---

## 🚀 **COMPLETE WORKING COMMANDS:**

**Copy and run these one by one:**

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
```

```powershell
flutter clean
```

```powershell
flutter pub get
```

```powershell
flutter run --release
```

---

## 💡 **ALTERNATIVE: Build APK First**

**If `flutter run --release` doesn't work, build APK first:**

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter build apk --release
```

**Then install the APK manually:**
- Location: `build\app\outputs\flutter-apk\app-release.apk`
- Copy to your device and install

---

## ✅ **SUMMARY:**

**You've already done:**
- ✅ `flutter clean` - Done!
- ✅ `flutter pub get` - Done!

**Now just run:**
```powershell
flutter run --release
```

**Or build APK:**
```powershell
flutter build apk --release
```

**The release build should work because release SHA-256 is already registered!** ✅


















