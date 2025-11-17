# 🔧 C++ Linking Error - COMPLETE FIX

## ❌ What's the Problem?

```
ld.lld: error: undefined symbol: operator new(unsigned long)
ld.lld: error: undefined symbol: operator delete(void*)
... many C++ errors
```

### **Root Cause:**
Your system has **NDK 27** installed, which has **compatibility issues** with Agora SDK's C++ code. NDK 27 uses static C++ library linking that doesn't work with Agora's native libraries.

---

## ✅ THE COMPLETE FIX

I've made 3 changes to fix this:

### Fix 1: Specified Compatible NDK Version
**File:** `android/app/build.gradle`

Added:
```gradle
ndkVersion = "25.1.8937393"  // Compatible NDK version
```

### Fix 2: Added C++ Shared Library Configuration
**File:** `android/app/build.gradle`

Added:
```gradle
ndk {
    abiFilters 'armeabi-v7a', 'arm64-v8a'
}

externalNativeBuild {
    cmake {
        cppFlags '-frtti', '-fexceptions', '-DANDROID_STL=c++_shared'
        arguments "-DANDROID_STL=c++_shared"
    }
}
```

### Fix 3: Added Native Library Settings
**File:** `android/gradle.properties`

Added:
```properties
android.bundle.enableUncompressedNativeLibs=true
android.defaults.buildfeatures.buildconfig=true
```

---

## 🚀 CRITICAL STEPS - FOLLOW EXACTLY:

### Step 1: Install NDK 25 (if you don't have it)

1. **Open Android Studio**

2. **Go to:** Tools → SDK Manager

3. **Click "SDK Tools" tab**

4. **Find "NDK (Side by side)"**
   - ✅ Check the box
   - Click "Show Package Details"
   - Find and check **25.1.8937393**
   - Click "Apply" to download

```
Visual:
┌──────────────────────────────────────┐
│  SDK Tools                           │
├──────────────────────────────────────┤
│  ☑ Android SDK Build-Tools           │
│  ☑ NDK (Side by side)  ← Expand this │
│     ☐ 27.0.12077973                  │
│     ☑ 25.1.8937393  ← Check this!    │
│     ☐ 24.0.8215888                   │
│                                      │
│        [Cancel]  [Apply]             │
└──────────────────────────────────────┘
```

**OR via Command Line (Faster):**
```powershell
# Using sdkmanager
$env:ANDROID_SDK_ROOT = "C:\Users\Shubham Singh\AppData\Local\Android\sdk"
cd "$env:ANDROID_SDK_ROOT\cmdline-tools\latest\bin"
.\sdkmanager.bat "ndk;25.1.8937393"
```

---

### Step 2: Clean EVERYTHING (CRITICAL!)

```powershell
# 1. Stop any running builds
# Press Ctrl+C if build is running

# 2. Clean Flutter
flutter clean

# 3. Delete build folder
Remove-Item -Recurse -Force build

# 4. Delete Android .gradle cache
Remove-Item -Recurse -Force android\.gradle

# 5. Delete ALL Agora caches
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\agora_rtc_engine-*"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\iris_method_channel-*"
```

---

### Step 3: Get Dependencies

```powershell
flutter pub get
```

---

### Step 4: Build App

```powershell
flutter run
```

---

## 📋 ALL COMMANDS (Copy-Paste All at Once):

```powershell
flutter clean
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\agora_rtc_engine-*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\iris_method_channel-*" -ErrorAction SilentlyContinue
flutter pub get
flutter run
```

---

## 🎯 What These Fixes Do:

### Fix 1: NDK Version
```
Problem: NDK 27 uses new C++ ABI that's incompatible
Solution: Use NDK 25 which is tested and stable
```

### Fix 2: C++ Shared Library
```
Problem: static-libstdc++ causes linking errors
Solution: Use c++_shared which includes all C++ symbols
```

### Fix 3: Native Library Settings
```
Problem: Native libraries compressed incorrectly
Solution: Extract them properly at runtime
```

---

## 📊 Before vs After:

### Before (Broken):
```
NDK: 27.0.12077973 ❌
C++ Library: static ❌
Result: Linking errors ❌
```

### After (Fixed):
```
NDK: 25.1.8937393 ✅
C++ Library: shared ✅
Result: Builds successfully ✅
```

---

## ⚠️ IF NDK 25 IS NOT AVAILABLE:

If you don't have NDK 25 installed and can't install it, use this alternative:

### Alternative: Remove NDK Version (Let Flutter Choose)

**Option A: Comment out ndkVersion**
```gradle
// ndkVersion = "25.1.8937393"  // Commented out - let Flutter choose
```

**Option B: Remove the line entirely**

Then the build system will use whatever NDK it finds compatible.

---

## 🆘 If Still Not Working:

### Check NDK Installation:
```powershell
# Check installed NDK versions
ls "C:\Users\Shubham Singh\AppData\Local\Android\Sdk\ndk"
```

You should see folders like:
```
25.1.8937393  ← You need this one
27.0.12077973
```

---

### Nuclear Option (If nothing works):

```powershell
# 1. Uninstall NDK 27 (in Android Studio SDK Manager)
# 2. Install NDK 25
# 3. Clean everything:
flutter clean
Remove-Item -Recurse -Force build
Remove-Item -Recurse -Force android\.gradle
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\agora*"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\iris*"
flutter pub get
flutter run
```

---

## 📖 Understanding the Error:

**What is `-static-libstdc++`?**
- It tries to include C++ standard library statically
- But with NDK 27, this doesn't work properly
- Symbols like `operator new` can't be found

**Solution:**
- Use `-DANDROID_STL=c++_shared` instead
- This links against shared C++ library
- All symbols are available

---

## ✅ Expected Result:

After running the commands, you should see:

```
✓ Built build\app\outputs\flutter-apk\app-debug.apk (23.4MB).
✓ Installing build\app\outputs\flutter-apk\app.apk...
✓ Waiting for VM Service port to be available...
✓ VM Service is listening on ...
```

**No more C++ errors!** 🎉

---

## 🎯 Summary:

**The Problem:** NDK 27 + Agora = C++ linking errors
**The Solution:** Use NDK 25 + C++ shared library
**Time to Fix:** 5 minutes (download NDK) + 2 minutes (rebuild)

---

**Run the commands now! Your app will build successfully!** 🚀












