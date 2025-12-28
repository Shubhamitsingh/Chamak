# 🔑 Create Signing Key - Windows PowerShell Guide

## Method 1: Using Flutter's Java (Easiest)

Flutter comes with its own Java. Use this command:

```powershell
cd android
& "$env:USERPROFILE\.gradle\jdks\jdk-*\bin\keytool.exe" -genkey -v -keystore "$env:USERPROFILE\upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**OR** if that doesn't work, try finding Flutter's Java:

```powershell
$flutterJava = Get-ChildItem "$env:USERPROFILE\.gradle\jdks" -Recurse -Filter "keytool.exe" | Select-Object -First 1
& $flutterJava.FullName -genkey -v -keystore "$env:USERPROFILE\upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

---

## Method 2: Using System Java (If Installed)

If you have Java installed, find it first:

```powershell
# Find Java installation
Get-ChildItem "C:\Program Files\Java" -Recurse -Filter "keytool.exe" | Select-Object -First 1
```

Then use the full path:

```powershell
& "C:\Program Files\Java\jdk-XX\bin\keytool.exe" -genkey -v -keystore "$env:USERPROFILE\upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

---

## Method 3: Download Java JDK (If Not Found)

1. Download JDK 17 from: https://adoptium.net/
2. Install it
3. Add to PATH or use full path

---

## Method 4: Use Android Studio's Java

If you have Android Studio installed:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\jbr\bin\keytool.exe" -genkey -v -keystore "$env:USERPROFILE\upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

---

## What You'll Be Asked:

1. **Enter keystore password**: Create a strong password (remember it!)
2. **Re-enter password**: Type same password
3. **What is your first and last name?**: Your name or company
4. **What is the name of your organizational unit?**: (Press Enter)
5. **What is the name of your organization?**: Your company name
6. **What is the name of your City or Locality?**: Your city
7. **What is the name of your State or Province?**: Your state
8. **What is the two-letter country code?**: IN (for India) or your country code
9. **Is CN=... correct?**: Type `yes`
10. **Enter key password**: Press Enter (to use same as keystore)

---

## After Creating Key:

1. The keystore file will be saved at: `C:\Users\Shubham Singh\upload-keystore.jks`
2. Update `android/key.properties` with your password and this path

---

## Quick Test Command:

Try this to see if any Java is available:

```powershell
Get-Command java -ErrorAction SilentlyContinue
Get-Command keytool -ErrorAction SilentlyContinue
```






















