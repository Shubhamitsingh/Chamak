# 🔍 Notification Not Working - Debug Checklist

## ❓ Notification Not Showing Up?

Follow this checklist to find the issue:

---

## ✅ Step 1: Check Firebase Cloud Functions (MOST IMPORTANT)

**This is the #1 reason notifications don't work!**

### Check if Functions are Deployed:

```bash
firebase functions:list
```

**Expected Output:**
```
✔ functions list
┌───────────────────────────────┬────────────────────────┐
│ Name                          │ Trigger                │
├───────────────────────────────┼────────────────────────┤
│ sendMessageNotification       │ Firestore              │
│ cleanupOldNotifications       │ Pub/Sub                │
│ sendFollowerNotification      │ Firestore              │
│ testNotification              │ HTTP                   │
└───────────────────────────────┴────────────────────────┘
```

### If Functions NOT Deployed:

```bash
# Step 1: Install Firebase CLI
npm install -g firebase-tools

# Step 2: Login
firebase login

# Step 3: Initialize (first time only)
firebase init functions
# Select JavaScript, install dependencies

# Step 4: Install dependencies
cd functions
npm install
cd ..

# Step 5: Deploy
firebase deploy --only functions
```

Wait for deployment to complete (1-2 minutes).

---

## ✅ Step 2: Check FCM Token in Firestore

1. Open **Firebase Console** → **Firestore Database**
2. Navigate to: `users` collection
3. Find your user document
4. Check if `fcmToken` field exists

**Should look like:**
```
users/
  └─ {userId}/
      ├─ displayName: "User Name"
      ├─ fcmToken: "dXi8KGh3R5e..." ← This should exist
      └─ ... other fields
```

### If fcmToken is MISSING:

The app isn't requesting permissions or saving the token.

**Fix:**
1. Uninstall the app completely
2. Reinstall: `flutter run`
3. Grant notification permission when prompted
4. Check Firestore again - token should appear

---

## ✅ Step 3: Check Notification Permission

### On Android 13+:

1. Go to **Settings** → **Apps** → **Chamak**
2. Tap **Notifications**
3. Ensure **Allow notifications** is ON

### Test in App:

Add this temporarily to `lib/main.dart` after line 27:

```dart
// Test: Check notification permission
await NotificationService().initialize();
final token = NotificationService().fcmToken;
print('🔔 FCM Token: $token');
if (token != null) {
  print('✅ Notifications are configured correctly!');
} else {
  print('❌ No FCM token - check permissions!');
}
```

Run the app and check the console output.

---

## ✅ Step 4: Check Notification Requests in Firestore

After sending a message, check Firestore:

1. Open **Firebase Console** → **Firestore Database**
2. Look for: `notificationRequests` collection
3. Check if documents are being created

**Should look like:**
```
notificationRequests/
  └─ {requestId}/
      ├─ token: "dXi8KGh3R5e..."
      ├─ notification: {
      │    title: "Sender Name"
      │    body: "Message text"
      │  }
      ├─ processed: false → true (after function runs)
      └─ createdAt: timestamp
```

### If NO documents appear:
- The app isn't creating notification requests
- Check ChatService integration

### If documents exist but `processed: false`:
- Cloud Functions aren't running
- Go back to Step 1 and deploy functions

---

## ✅ Step 5: Check Cloud Function Logs

```bash
firebase functions:log
```

**Look for:**
- ✅ "Successfully sent message"
- ❌ Any error messages

**Common errors:**
- "Invalid FCM token" - User needs to restart app
- "Permission denied" - Check Firebase project settings
- "Function not found" - Functions not deployed

---

## ✅ Step 6: Test with Firebase Console

Send a test notification directly from Firebase:

1. Go to **Firebase Console** → **Cloud Messaging**
2. Click **Send your first message**
3. Enter:
   - Title: "Test"
   - Text: "Hello"
4. Click **Send test message**
5. Paste the FCM token from Step 2
6. Click **Test**

**If this works:** Your setup is correct, issue is with Cloud Functions
**If this doesn't work:** Check device permissions and token

---

## ✅ Step 7: Verify App State

Notifications work in ALL states:
- ✅ Foreground (app open)
- ✅ Background (app minimized)
- ✅ Terminated (app closed)

**Test all three:**
1. Keep app open → Send message → Should see notification
2. Minimize app → Send message → Should see notification
3. Close app completely → Send message → Should see notification

---

## 🔧 Quick Fix Commands

### Rebuild Everything:
```bash
flutter clean
flutter pub get
flutter run
```

### Re-deploy Functions:
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Check Firebase Status:
```bash
firebase projects:list
firebase use YOUR_PROJECT_ID
```

---

## 🐛 Common Issues & Solutions

### Issue 1: "No FCM token"
**Solution:**
- Check notification permissions
- Restart the app
- Check internet connection

### Issue 2: "Functions not deploying"
**Solution:**
```bash
# Check Node.js version (needs 16+)
node --version

# Update Firebase CLI
npm install -g firebase-tools@latest

# Try again
firebase deploy --only functions
```

### Issue 3: "Notification shows but doesn't open chat"
**Solution:**
- This is normal for now - tap handling can be added later
- The notification system is working!

### Issue 4: "Works on one device but not another"
**Solution:**
- Each device needs to grant permissions separately
- Check FCM token exists in Firestore for both users

---

## 📱 Test Procedure

**Device 1 (Sender):**
1. Login as User A
2. Open chat with User B
3. Send message: "Hello"

**Device 2 (Receiver):**
1. Login as User B
2. **Close the app** or **minimize it**
3. Should receive notification!

**Important:** Close or minimize the receiver's app to see the notification!

---

## 🎯 Most Likely Issues (In Order):

1. ⚠️ **Cloud Functions not deployed** (90% of cases)
   - Run: `firebase deploy --only functions`

2. ⚠️ **Notification permissions not granted**
   - Check Settings → Apps → Chamak → Notifications

3. ⚠️ **FCM token not saved to Firestore**
   - Restart app, check Firestore

4. ⚠️ **Testing wrong way**
   - Receiver must have app closed/minimized to see notification

5. ⚠️ **Internet connection issues**
   - Check both devices have internet

---

## 📞 Still Not Working?

Run these commands and send me the output:

```bash
# Check Firebase project
firebase use

# List functions
firebase functions:list

# Check function logs
firebase functions:log --limit 50

# Check Flutter doctor
flutter doctor -v
```

Also check:
1. Firebase Console → Firestore → users → check fcmToken exists
2. Firebase Console → Firestore → notificationRequests → check documents exist
3. Firebase Console → Cloud Messaging → Ensure FCM is enabled

---

**Good luck! 🚀**



