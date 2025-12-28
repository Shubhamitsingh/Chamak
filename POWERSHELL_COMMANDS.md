# 💻 PowerShell Commands for Flutter

## ✅ **CORRECT POWERSHELL COMMANDS:**

### **Option 1: Run Commands One by One**

**Step 1: Clean Flutter**
```powershell
flutter clean
```

**Step 2: Clean Android Build**
```powershell
cd android
.\gradlew clean
cd ..
```

**Step 3: Get Dependencies**
```powershell
flutter pub get
```

**Step 4: Run Release Build**
```powershell
flutter run --release
```

---

### **Option 2: Run All in One (Using Semicolon)**

```powershell
flutter clean; cd android; .\gradlew clean; cd ..; flutter pub get; flutter run --release
```

---

### **Option 3: Run All in One (Using && - PowerShell 7+)**

```powershell
flutter clean && cd android && .\gradlew clean && cd .. && flutter pub get && flutter run --release
```

---

## 🔧 **IF COMMANDS DON'T WORK:**

### **Issue 1: gradlew Command Not Found**

**Try this instead:**
```powershell
cd android
.\gradlew.bat clean
cd ..
```

**Or:**
```powershell
cd android
gradlew clean
cd ..
```

---

### **Issue 2: PowerShell Execution Policy**

**If you get execution policy error:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Then try commands again**

---

### **Issue 3: Path Issues**

**Use full paths:**
```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter clean
cd "C:\Users\Shubham Singh\Desktop\chamak\android"
.\gradlew clean
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter pub get
flutter run --release
```

---

## 🎯 **RECOMMENDED: Run Commands One by One**

**Copy and paste each command separately:**

**1. First command:**
```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
```

**2. Second command:**
```powershell
flutter clean
```

**3. Third command:**
```powershell
cd android
```

**4. Fourth command:**
```powershell
.\gradlew clean
```

**5. Fifth command:**
```powershell
cd ..
```

**6. Sixth command:**
```powershell
flutter pub get
```

**7. Seventh command:**
```powershell
flutter run --release
```

---

## ⚠️ **COMMON ERRORS:**

### **Error: "gradlew is not recognized"**

**Solution:**
```powershell
cd android
.\gradlew.bat clean
```

**Or:**
```powershell
cd android
& .\gradlew clean
```

---

### **Error: "Execution policy"**

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### **Error: "Path not found"**

**Solution:**
```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
```

**Make sure you're in the correct directory!**

---

## ✅ **WORKING COMMANDS (Copy These):**

### **Complete Clean and Rebuild:**

```powershell
# Navigate to project
cd "C:\Users\Shubham Singh\Desktop\chamak"

# Clean Flutter
flutter clean

# Clean Android
cd android
.\gradlew.bat clean
cd ..

# Get dependencies
flutter pub get

# Run release build
flutter run --release
```

---

## 🚀 **QUICK ALTERNATIVE:**

**If commands still don't work, try this:**

**1. Open new PowerShell window**
**2. Navigate to project:**
```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
```

**3. Run each command separately:**
```powershell
flutter clean
```
```powershell
cd android
```
```powershell
.\gradlew.bat clean
```
```powershell
cd ..
```
```powershell
flutter pub get
```
```powershell
flutter run --release
```

---

## 💡 **TIPS:**

1. **Run commands one by one** (don't combine)
2. **Wait for each command to finish** before running next
3. **Check for errors** after each command
4. **Use `.\gradlew.bat`** instead of `.\gradlew` if it doesn't work
5. **Make sure you're in correct directory** (`C:\Users\Shubham Singh\Desktop\chamak`)

---

## ✅ **SUMMARY:**

**Best approach: Run commands one by one!**

1. `cd "C:\Users\Shubham Singh\Desktop\chamak"`
2. `flutter clean`
3. `cd android`
4. `.\gradlew.bat clean`
5. `cd ..`
6. `flutter pub get`
7. `flutter run --release`

**If any command fails, tell me the exact error message!**


















