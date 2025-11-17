# 🎯 THE REAL FIX - Patch Agora's CMakeLists.txt

## ❌ THE PROBLEM (Finally Identified!):

Agora's SDK has `-static-libstdc++` **hardcoded** in its CMakeLists.txt file.

```
File: agora_rtc_engine-6.x.x/android/CMakeLists.txt
Line: set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libstdc++")
```

This **cannot** be overridden from our build.gradle!

---

## ✅ THE SOLUTION: Patch Agora After Download

I've created a PowerShell script that automatically patches Agora's CMakeLists.txt files.

---

## 🚀 FOLLOW THESE STEPS:

### Step 1: Get Dependencies First

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter pub get
```

This downloads Agora SDK to your Pub cache.

---

### Step 2: Run the Fix Script

```powershell
.\fix_agora_cmake.ps1
```

This script:
- Finds Agora's CMakeLists.txt
- Removes `-static-libstdc++`
- Adds `set(ANDROID_STL c++_shared)`
- Fixes both agora_rtc_engine and iris_method_channel

---

### Step 3: Clean and Build

```powershell
flutter clean
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
flutter run
```

---

## 📋 ALL COMMANDS (Copy-Paste):

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter pub get
.\fix_agora_cmake.ps1
flutter clean
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
flutter run
```

---

## 🔍 What the Script Does:

### Before Patch:
```cmake
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libstdc++")
# ❌ This causes linking errors
```

### After Patch:
```cmake
set(ANDROID_STL c++_shared)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
# ✅ Uses shared C++ library
```

---

## 📊 Why This is the ONLY Solution:

| Approach | Works? | Why/Why Not |
|----------|--------|-------------|
| Change build.gradle | ❌ | Agora's CMake overrides it |
| Change gradle.properties | ❌ | Doesn't affect CMake |
| Downgrade Agora | ❌ | Old versions missing namespace |
| Downgrade NDK | ❌ | Conflicts with other plugins |
| **Patch CMakeLists.txt** | ✅ | **Fixes the source!** |

---

## ⚠️ IMPORTANT NOTE:

You need to run `fix_agora_cmake.ps1` **every time** you:
- Run `flutter pub get`
- Delete pub cache
- Update Agora version

Because it re-downloads the SDK and overwrites our patch.

---

## 🎉 EXPECTED RESULT:

```
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk
✓ Installing app...
✓ Installed!
```

**No more C++ errors!** 🚀

---

## 🆘 If Script Doesn't Work:

### Manual Patch:

1. Navigate to:
```
C:\Users\Shubham Singh\AppData\Local\Pub\Cache\hosted\pub.dev\agora_rtc_engine-6.2.4\android\
```

2. Open `CMakeLists.txt` in notepad

3. Find line with `-static-libstdc++`

4. Delete that line or change to:
```cmake
set(ANDROID_STL c++_shared)
```

5. Save file

6. Do same for iris_method_channel

---

**Run the script now! This is the proper fix!** 🚀












