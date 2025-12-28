# 🚀 Run Release Build - Step by Step

## ✅ **Commands That Work:**

I've run the first commands for you. Here's what to do next:

---

## 📋 **COMPLETED:**

✅ **Step 1:** `flutter clean` - Done!  
✅ **Step 2:** `cd android && .\gradlew.bat clean` - Running...  
✅ **Step 3:** `flutter pub get` - Running...  

---

## 🎯 **NEXT STEP: Run Release Build**

**After the commands above finish, run:**

```powershell
flutter run --release
```

**Or if you want to build APK first:**

```powershell
flutter build apk --release
```

**Then install the APK:**
- Location: `build\app\outputs\flutter-apk\app-release.apk`
- Install on your device

---

## 💡 **IF COMMANDS DON'T WORK:**

### **Run Commands One by One:**

**1. Navigate to project:**
```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
```

**2. Clean Flutter:**
```powershell
flutter clean
```

**3. Clean Android:**
```powershell
cd android
.\gradlew.bat clean
cd ..
```

**4. Get dependencies:**
```powershell
flutter pub get
```

**5. Run release build:**
```powershell
flutter run --release
```

---

## ⚠️ **COMMON ISSUES:**

### **Issue 1: gradlew not found**
**Use:** `.\gradlew.bat clean` instead of `.\gradlew clean`

### **Issue 2: Execution policy error**
**Run:** `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### **Issue 3: Path issues**
**Use full path:** `cd "C:\Users\Shubham Singh\Desktop\chamak"`

---

## ✅ **QUICK COMMANDS (Copy These):**

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter clean
cd android
.\gradlew.bat clean
cd ..
flutter pub get
flutter run --release
```

**Run each command separately and wait for it to finish!**


















