# 🔐 Agora Production Token Setup Instructions

## ✅ What Has Been Completed

### Step 1: Firebase Cloud Functions Setup ✅
- ✅ Installed `agora-token` package in Firebase Functions
- ✅ Created `generateAgoraToken` Cloud Function
- ✅ Function is ready to generate tokens securely

### Step 2: Flutter App Integration ✅
- ✅ Created `AgoraTokenService` (`lib/services/agora_token_service.dart`)
- ✅ Added `cloud_functions` package to `pubspec.yaml`
- ✅ Updated `home_screen.dart` to use dynamic tokens:
  - ✅ Host starting stream (Go Live button)
  - ✅ Viewer joining from Live tab
  - ✅ Viewer joining from Explore tab
  - ✅ Viewer joining from New tab

### Step 3: Features Implemented ✅
- ✅ Token caching (reuses valid tokens)
- ✅ Automatic token refresh
- ✅ Error handling with user-friendly messages
- ✅ Loading indicators during token generation

---

## 🔧 What You Need to Do Now

### **STEP 1: Get Your Agora Credentials**

1. **Go to Agora Console:**
   - Visit: https://console.agora.io/
   - Login to your account

2. **Navigate to Your Project:**
   - Go to: **Projects** → Select your project
   - Your **App ID** is already visible: `43bb5e13c835444595c8cf087a0ccaa4`

3. **Enable App Certificate:**
   - In your project, go to: **App Certificate**
   - Click **Enable** (if not already enabled)
   - **Copy your App Certificate** (this is your App Secret)
   - ⚠️ **KEEP THIS SECRET SAFE** - Never share it publicly!

---

### **STEP 2: Set Firebase Functions Environment Variables**

You need to set your Agora credentials as environment variables in Firebase Functions.

**Option A: Using Firebase CLI (Recommended)**

1. **Open terminal/command prompt**

2. **Navigate to your project:**
   ```bash
   cd "C:\Users\Shubham Singh\Desktop\chamak"
   ```

3. **Set App ID:**
   ```bash
   firebase functions:secrets:set AGORA_APP_ID
   ```
   - When prompted, paste your App ID: `43bb5e13c835444595c8cf087a0ccaa4`
   - Press Enter

4. **Set App Certificate:**
   ```bash
   firebase functions:secrets:set AGORA_APP_CERTIFICATE
   ```
   - When prompted, paste your App Certificate (the secret you copied)
   - Press Enter

**Option B: Using Firebase Console (Alternative)**

1. Go to: https://console.firebase.google.com/
2. Select your project: **chamak-39472**
3. Go to: **Functions** → **Configuration** → **Secrets**
4. Click **Add Secret**
5. Add two secrets:
   - Name: `AGORA_APP_ID`, Value: `43bb5e13c835444595c8cf087a0ccaa4`
   - Name: `AGORA_APP_CERTIFICATE`, Value: `[Your App Certificate]`

---

### **STEP 3: Update Firebase Functions Code**

The function needs to access secrets. Update `functions/index.js`:

**Find this line (around line 280):**
```javascript
const appId = process.env.AGORA_APP_ID;
const appCertificate = process.env.AGORA_APP_CERTIFICATE;
```

**Replace with:**
```javascript
// For Firebase Functions v2, secrets are accessed via process.env
// Make sure secrets are set using: firebase functions:secrets:set
const appId = process.env.AGORA_APP_ID;
const appCertificate = process.env.AGORA_APP_CERTIFICATE;
```

**Note:** If using Firebase Functions v2 with secrets, you may need to update the function definition. Let me know if you encounter issues.

---

### **STEP 4: Deploy Firebase Functions**

After setting the secrets, deploy the function:

```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"
firebase deploy --only functions:generateAgoraToken
```

Or deploy all functions:
```bash
firebase deploy --only functions
```

---

### **STEP 5: Install Flutter Dependencies**

Install the new `cloud_functions` package:

```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter pub get
```

---

### **STEP 6: Test the Implementation**

1. **Run your Flutter app:**
   ```bash
   flutter run
   ```

2. **Test scenarios:**
   - ✅ Click "Go Live" button → Should generate token and start stream
   - ✅ Join a live stream as viewer → Should generate token and join
   - ✅ Check console logs for token generation messages

3. **Check Firebase Functions logs:**
   ```bash
   firebase functions:log
   ```
   - Look for `generateAgoraToken` function calls
   - Check for any errors

---

## 🐛 Troubleshooting

### **Error: "Agora credentials not configured"**
- **Solution:** Make sure you set `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` secrets
- Verify: `firebase functions:secrets:access AGORA_APP_ID`

### **Error: "User must be authenticated"**
- **Solution:** Make sure user is logged in before generating tokens
- The function requires Firebase Authentication

### **Error: "Failed to generate token"**
- **Solution:** 
  - Check App Certificate is enabled in Agora Console
  - Verify App Certificate secret is correct
  - Check Firebase Functions logs for detailed error

### **Error: "cloud_functions package not found"**
- **Solution:** Run `flutter pub get` to install dependencies

### **Token generation is slow**
- **Normal:** First token generation takes 1-2 seconds
- **Cached tokens:** Subsequent calls use cached token (instant)

---

## 📋 Checklist

Before testing, make sure:

- [ ] App Certificate is enabled in Agora Console
- [ ] App Certificate secret is copied
- [ ] `AGORA_APP_ID` secret is set in Firebase Functions
- [ ] `AGORA_APP_CERTIFICATE` secret is set in Firebase Functions
- [ ] Firebase Functions are deployed
- [ ] `flutter pub get` is run
- [ ] User is logged in to the app

---

## 🎯 Next Steps After Setup

Once everything is working:

1. **Test token expiration:** Tokens expire after 24 hours
2. **Monitor usage:** Check Firebase Functions logs regularly
3. **Optimize:** Consider caching tokens longer if needed
4. **Security:** Never expose App Certificate in client code

---

## 📞 Need Help?

If you encounter any issues:

1. Check Firebase Functions logs: `firebase functions:log`
2. Check Flutter console for error messages
3. Verify secrets are set correctly
4. Make sure App Certificate is enabled in Agora Console

---

**Ready to proceed?** Follow the steps above and let me know when you've completed them! 🚀
























