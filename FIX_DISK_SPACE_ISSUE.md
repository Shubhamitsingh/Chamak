# 🔧 Fix Disk Space Issue

## ❌ **Error:**
```
There is not enough space on the disk
Error while merging dex archives
```

## ✅ **Solution Steps:**

### **Step 1: Clean Flutter Build Files**
```bash
flutter clean
```

### **Step 2: Clean Gradle Cache**
```bash
cd android
.\gradlew clean
cd ..
```

### **Step 3: Clean Gradle Cache (Global)**
```bash
# Windows PowerShell
Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\caches
```

### **Step 4: Clean Flutter Cache**
```bash
flutter pub cache clean
flutter pub get
```

### **Step 5: Free Up More Space**

**Delete unnecessary files:**
1. **Android Build Cache:**
   - `android\.gradle\`
   - `android\app\build\`
   - `android\build\`

2. **Flutter Build Files:**
   - `build\` folder
   - `.dart_tool\` folder (optional)

3. **Temporary Files:**
   - Windows Temp folder
   - Recycle Bin

### **Step 6: Check Disk Space**
```bash
# Check available space
Get-PSDrive C
```

### **Step 7: After Cleaning, Rebuild**
```bash
flutter pub get
flutter run
```

---

## 🎯 **Quick Fix Commands:**

Run these in order:

```powershell
# 1. Clean Flutter
flutter clean

# 2. Clean Android
cd android
.\gradlew clean
cd ..

# 3. Clean Gradle cache (if needed)
Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\caches

# 4. Get dependencies
flutter pub get

# 5. Try building again
flutter run
```

---

## 💡 **Prevention:**

1. **Regular Cleanup:** Run `flutter clean` regularly
2. **Disk Space:** Keep at least 5-10 GB free
3. **Gradle Cache:** Clean periodically if low on space

---

## ⚠️ **If Still Not Enough Space:**

1. **Free up disk space:**
   - Delete old projects
   - Empty Recycle Bin
   - Clear browser cache
   - Uninstall unused programs

2. **Move project to drive with more space**

3. **Use external drive for build cache**

---

**After cleaning, try building again!** 🚀

