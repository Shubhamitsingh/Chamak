# 📦 How to Build AAB File for Play Store

## Prerequisites ✅

1. **Keystore File**: Make sure you have your keystore file at:
   ```
   C:\Users\Shubham Singh\upload-keystore.jks
   ```

2. **Key Properties**: Verify `android/key.properties` contains:
   ```properties
   storePassword=Shubham@18
   keyPassword=Shubham@18
   keyAlias=upload
   storeFile=C:\\Users\\Shubham Singh\\upload-keystore.jks
   ```

## Step-by-Step Instructions 🚀

### Step 1: Open Terminal/PowerShell
Navigate to your project directory:
```powershell
cd "C:\Users\Shubham Singh\Desktop\chamak"
```

### Step 2: Clean Previous Builds
```powershell
flutter clean
```

### Step 3: Get Dependencies
```powershell
flutter pub get
```

### Step 4: Build AAB File
```powershell
flutter build appbundle --release
```

**This command will:**
- Build your app in release mode
- Sign it with your keystore
- Generate an optimized AAB file for Play Store

### Step 5: Locate Your AAB File 📍

After building completes successfully, your AAB file will be located at:

```
build\app\outputs\bundle\release\app-release.aab
```

**Full path:**
```
C:\Users\Shubham Singh\Desktop\chamak\build\app\outputs\bundle\release\app-release.aab
```

## Upload to Play Store 🎯

### Step 1: Go to Play Console
Visit: https://play.google.com/console

### Step 2: Select Your App
- Choose your app from the dashboard

### Step 3: Navigate to Production
- Go to **Production** → **Create new release** (or **Create release**)

### Step 4: Upload AAB File
- Click **Upload** or drag and drop your `app-release.aab` file
- Wait for Google to process the file (may take a few minutes)

### Step 5: Add Release Notes
- Add **What's new in this version** notes
- This is required for new releases

### Step 6: Review and Submit
- Review all information
- Click **Save** then **Review release**
- Finally, click **Start rollout to Production**

## Troubleshooting 🔧

### Error: Keystore file not found
**Solution:** Make sure the keystore file exists at the path specified in `key.properties`

### Error: Invalid keystore password
**Solution:** Verify the password in `android/key.properties` matches your keystore password

### Error: Build failed
**Solution:** 
1. Run `flutter doctor` to check for issues
2. Make sure all dependencies are installed
3. Try `flutter clean` and rebuild

### AAB file too large
**Solution:** 
- The AAB format is optimized by Google Play
- Play Store will generate APKs for different device configurations
- This is normal and expected

## Quick Command Reference 📝

```powershell
# Full build process (run all commands)
flutter clean && flutter pub get && flutter build appbundle --release

# Check build configuration
flutter build appbundle --release --verbose

# Build with specific flavor (if configured)
flutter build appbundle --release --flavor production
```

## File Size Information 📊

- **AAB files** are typically smaller than APK files
- Google Play generates optimized APKs for each device
- Users download only what they need

## Important Notes ⚠️

1. **Never commit** `key.properties` or keystore files to Git
2. **Keep backups** of your keystore file in a secure location
3. **Version Code**: Make sure to increment `versionCode` in `build.gradle` for each release
4. **Version Name**: Update `versionName` for user-facing version numbers

## Current App Info ℹ️

- **Package Name**: `com.chamakz.app`
- **Version Code**: `2`
- **Version Name**: `1.0.1`

---

✅ **Your AAB file is ready for Play Store submission!**









