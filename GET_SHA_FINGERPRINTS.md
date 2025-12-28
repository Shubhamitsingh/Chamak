# 🔑 Get SHA-1 and SHA-256 Fingerprints for Release Keystore

## 📋 Commands to Run:

### Option 1: Get Both SHA-1 and SHA-256 (Recommended)

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "C:\Users\Shubham Singh\upload-keystore.jks" -alias upload -storepass Shubham@18
```

This will show **ALL** certificate information including SHA-1 and SHA-256.

---

### Option 2: Get Only SHA-1

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "C:\Users\Shubham Singh\upload-keystore.jks" -alias upload -storepass Shubham@18 | Select-String -Pattern "SHA1" -Context 0,1
```

---

### Option 3: Get Only SHA-256

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "C:\Users\Shubham Singh\upload-keystore.jks" -alias upload -storepass Shubham@18 | Select-String -Pattern "SHA256" -Context 0,1
```

---

### Option 4: Get Both in One Command (Clean Output)

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "C:\Users\Shubham Singh\upload-keystore.jks" -alias upload -storepass Shubham@18 | Select-String -Pattern "SHA1|SHA256" -Context 0,1
```

---

## 📝 Your Current Fingerprints:

**SHA-1 (Release):**
```
81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71
```

**SHA-256 (Release):**
```
11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB
```

---

## 🔍 What to Look For in Output:

When you run the command, look for lines like:

```
Certificate fingerprints:
     SHA1: 81:12:99:24:87:DD:92:9A:AB:B4:A3:D4:FC:C4:3A:88:5D:BA:D1:71
     SHA256: 11:A8:7F:44:79:42:7E:F3:E0:EB:0A:F4:B0:63:14:FD:3F:9A:EE:CD:B0:A5:7D:5C:64:CA:37:8A:78:EE:53:AB
```

---

## ⚠️ If Command Doesn't Work:

If the keytool path is different, find it using:

```powershell
flutter doctor -v
```

Look for the Java path, then use:
```powershell
& "YOUR_JAVA_PATH\bin\keytool.exe" -list -v -keystore "C:\Users\Shubham Singh\upload-keystore.jks" -alias upload -storepass Shubham@18
```


















