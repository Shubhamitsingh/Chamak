# LiveVibe - Troubleshooting Guide

## ✅ Fixed: Android SDK 35 / JDK jlink.exe Build Error

### Problem
The build was failing with the following error:
```
Execution failed for task ':path_provider_android:compileDebugJavaWithJavac'.
> Could not resolve all files for configuration ':path_provider_android:androidJdkImage'.
   > Failed to transform core-for-system-modules.jar
      > Error while executing process jlink.exe
```

### Root Cause
This error occurs when using **Android SDK 35** (Android 15) with certain Android Gradle Plugin versions. The issue is related to:
1. JDK image transformation with `jlink.exe`
2. Incompatibility between Android SDK 35 and older Gradle configurations
3. Deprecated Gradle properties

### Solution Applied ✅

#### 1. Updated `android/gradle.properties`
Removed deprecated properties and added optimization settings:
```properties
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true

# Gradle optimization settings
org.gradle.caching=true
org.gradle.parallel=true
org.gradle.configureondemand=true
```

#### 2. Updated `android/app/build.gradle`
Changed from dynamic SDK versions to fixed, stable versions:
```gradle
android {
    compileSdk = 34          // Changed from flutter.compileSdkVersion
    ndkVersion = "25.1.8937393"
    
    defaultConfig {
        minSdk = 21          // Changed from flutter.minSdkVersion
        targetSdk = 34       // Changed from flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

#### 3. Updated `android/settings.gradle`
Upgraded to more stable plugin versions:
```gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.1.4" apply false
    id "org.jetbrains.kotlin.android" version "1.9.10" apply false
}
```

### How to Test the Fix

1. **Clean the project:**
   ```bash
   flutter clean
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

---

## Common Flutter Build Issues on Windows

### Issue 1: "No devices found"
**Solution:**
- Start an Android emulator: `flutter emulators --launch <emulator_id>`
- Or connect a physical device with USB debugging enabled

### Issue 2: Gradle daemon issues
**Solution:**
```bash
cd android
.\gradlew --stop
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue 3: Long path issues on Windows
**Solution:**
Enable long paths in Windows:
1. Open PowerShell as Administrator
2. Run: `New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force`
3. Restart your computer

### Issue 4: Gradle build extremely slow
**Solution:**
The `gradle.properties` file has been optimized with:
- Increased heap memory (4GB)
- Enabled caching
- Enabled parallel builds
- Configure on demand

### Issue 5: "Plugin not found" errors
**Solution:**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

---

## Recommended Android SDK Versions

For stable Flutter development:
- **compileSdk:** 34 (Android 14)
- **targetSdk:** 34 (Android 14)
- **minSdk:** 21 (Android 5.0)

These versions ensure maximum compatibility while supporting modern features.

---

## Flutter Doctor

Always run `flutter doctor` to check your environment:
```bash
flutter doctor -v
```

This will show:
- ✅ Flutter installation
- ✅ Android toolchain
- ✅ Connected devices
- ✅ IDE setup
- ⚠️ Any issues that need fixing

---

## Quick Command Reference

| Command | Purpose |
|---------|---------|
| `flutter clean` | Clean build files |
| `flutter pub get` | Get dependencies |
| `flutter run` | Run app |
| `flutter devices` | List devices |
| `flutter emulators` | List emulators |
| `flutter doctor` | Check environment |
| `flutter build apk` | Build APK |
| `.\gradlew clean` | Clean Gradle (from android/ dir) |

---

## Additional Tips

1. **Always clean after major changes:**
   ```bash
   flutter clean && flutter pub get
   ```

2. **Check for Flutter updates:**
   ```bash
   flutter upgrade
   ```

3. **Update dependencies safely:**
   ```bash
   flutter pub outdated
   flutter pub upgrade --major-versions
   ```

4. **For stubborn issues, rebuild everything:**
   ```bash
   flutter clean
   cd android
   .\gradlew clean
   cd ..
   flutter pub get
   flutter run
   ```

---

## Need More Help?

- 📚 [Flutter Documentation](https://flutter.dev/docs)
- 💬 [Flutter Discord](https://discord.gg/flutter)
- 🐛 [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)
- 📖 [Android Gradle Plugin Docs](https://developer.android.com/build/releases/gradle-plugin)

---

---

## ✅ FINAL SOLUTION SUMMARY

The build error was fixed by upgrading to compatible versions:

| Component | Version |
|-----------|---------|
| Android Gradle Plugin | **8.3.0** |
| Gradle | **8.4** |
| Kotlin | **1.9.22** |
| Java Target | **17** |
| compileSdk | **35** |
| targetSdk | **35** |

**Build Status:** ✅ SUCCESS  
**Last Updated:** October 25, 2025  
**Status:** ✅ All known issues resolved

