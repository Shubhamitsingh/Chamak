# 🚀 Build Release AAB - Final Steps

## Step 1: Update key.properties

Make sure `android/key.properties` has your actual password:

```properties
storePassword=YOUR_ACTUAL_PASSWORD
keyPassword=YOUR_ACTUAL_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\Shubham Singh\\upload-keystore.jks
```

## Step 2: Clean and Build

Run these commands in order:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

## Step 3: Find Your AAB File

After building, your AAB file will be at:
```
build\app\outputs\bundle\release\app-release.aab
```

## Step 4: Upload to Play Console

1. Go to https://play.google.com/console
2. Select your app
3. Go to Production → Create new release
4. Upload `app-release.aab`
5. Add release notes
6. Submit for review

✅ **Your AAB will now be signed in release mode!**






















