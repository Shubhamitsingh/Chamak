# LiveVibe - Setup Guide (Windows)

## 🚀 Quick Start Guide

### Step 1: Verify Flutter Installation

Open PowerShell and check if Flutter is installed:

```powershell
flutter --version
```

If Flutter is not installed, download it from: https://flutter.dev/docs/get-started/install/windows

### Step 2: Install Dependencies

Navigate to the project directory and run:

```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter pub get
```

This will download all required packages listed in `pubspec.yaml`.

### Step 3: Check for Connected Devices

Connect your Android device via USB or start an Android emulator, then run:

```powershell
flutter devices
```

You should see at least one device listed.

### Step 4: Run the App

```powershell
flutter run
```

Or, if you have multiple devices:

```powershell
flutter run -d <device-id>
```

### ✅ Build Successfully Fixed!

The app is now working! The Android SDK 35 / jlink.exe error has been resolved by:
- Upgrading to Android Gradle Plugin 8.3.0
- Using Java 17
- Setting compileSdk to 35

**Expected first build time:** ~265 seconds  
**Subsequent builds:** ~10-30 seconds

See [BUILD_FIX_SUMMARY.md](BUILD_FIX_SUMMARY.md) for complete details.

### Step 5: Hot Reload (While App is Running)

- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

## 🛠️ Troubleshooting

### Issue: "Unable to find package"
**Solution:** Run `flutter pub get` again

### Issue: "No devices found"
**Solution:** 
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Reconnect the device

### Issue: Build fails
**Solution:**
```powershell
flutter clean
flutter pub get
flutter run
```

## 📱 Running on Android Emulator

1. Open Android Studio
2. Go to Tools > Device Manager
3. Create a new Virtual Device (if not exists)
4. Start the emulator
5. Run `flutter run`

## 🎨 Development Tips

### VS Code Extensions (Recommended)
- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets

### Android Studio Plugins
- Flutter plugin
- Dart plugin

## 📋 Project Commands

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run the app |
| `flutter clean` | Clean build files |
| `flutter doctor` | Check Flutter environment |
| `flutter build apk` | Build APK for Android |
| `flutter analyze` | Analyze code for issues |

## 🔍 File Structure Overview

```
chamak/
├── lib/
│   ├── main.dart              # App entry point
│   └── screens/
│       ├── splash_screen.dart # Splash screen
│       └── login_screen.dart  # Login screen
├── pubspec.yaml               # Dependencies
├── analysis_options.yaml      # Linting rules
└── README.md                  # Project documentation
```

## ✅ Current Features

1. **Splash Screen**
   - 3-second animated intro
   - Auto-navigation to login

2. **Login Screen**
   - International phone number input
   - OTP button (logic pending)
   - Gradient background
   - Terms & Privacy links

## 🔜 Next Steps

Ready to continue? Ask for:
- **Step 2:** OTP Verification Screen
- **Step 3:** Home Screen with Bottom Navigation
- And more...

## 📞 Support

If you encounter any issues:
1. Run `flutter doctor` to check your setup
2. Make sure all dependencies are installed
3. Check that your device/emulator is running

---

Happy Coding! 🎉

