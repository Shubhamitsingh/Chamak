# 🧪 Quick Test - Are Notifications Set Up?

## Run These Commands:

### 1. Check if you're logged into Firebase:
```bash
firebase login:list
```

**Expected:** Should show your email

---

### 2. Check which Firebase project you're using:
```bash
firebase use
```

**Expected:** Should show your project name/ID

---

### 3. Check if Cloud Functions are deployed:
```bash
firebase functions:list
```

**Expected Result:**
```
✔ functions list
Function Name                   Trigger
sendMessageNotification         Firestore
cleanupOldNotifications         Scheduled
sendFollowerNotification        Firestore  
testNotification                HTTPS
```

**If you see "No functions deployed":**
```bash
# YOU NEED TO DEPLOY FUNCTIONS - This is the issue!
cd functions
npm install
cd ..
firebase deploy --only functions
```

---

### 4. Check recent function logs:
```bash
firebase functions:log --limit 10
```

**Expected:** Should show logs (or empty if no activity yet)

---

## 📱 App Test:

### Test 1: Check if FCM token is being generated

Add this to `lib/main.dart` temporarily (after line 27):

```dart
// TEMPORARY TEST CODE - Remove after testing
print('🔍 Testing Notification Setup...');
await NotificationService().initialize().then((_) {
  final token = NotificationService().fcmToken;
  print('📱 FCM Token: ${token ?? "NULL - NOT WORKING!"}');
  print(token != null ? '✅ Token exists' : '❌ Token missing - check permissions!');
});
```

**Run app and check console:**
- ✅ Should print the FCM token
- ❌ If null, notification permissions not granted

---

### Test 2: Check if token is saved to Firestore

1. Run your app
2. Login with a user
3. Open **Firebase Console** → **Firestore Database**
4. Go to: `users` → (your user ID)
5. Look for `fcmToken` field

**Should see:**
```
fcmToken: "dXi8KGh3R5eY7..." (long string)
fcmTokenUpdatedAt: (timestamp)
```

**If missing:** App isn't saving token - check permissions

---

### Test 3: Send a test message

1. **Device 1:** Login as User A
2. **Device 2:** Login as User B
3. **Device 2:** Close or minimize the app
4. **Device 1:** Send message to User B
5. **Device 2:** Should receive notification!

---

### Test 4: Check if notification request was created

After sending a message:

1. Open **Firebase Console** → **Firestore Database**
2. Look for: `notificationRequests` collection
3. Check if new document appeared

**If document exists with `processed: false`:**
- Cloud Functions not running
- Deploy functions!

**If document doesn't exist:**
- App isn't creating requests
- Check ChatService code

---

## 🎯 The #1 Issue: Functions Not Deployed

**90% of the time, the issue is that Cloud Functions aren't deployed!**

To fix:
```bash
# Navigate to your project
cd c:/Users/Shubham\ Singh/Desktop/chamak

# Deploy functions
firebase deploy --only functions
```

Wait 1-2 minutes for deployment.

Then test again!

---

## ✅ What Success Looks Like:

### In Console:
```bash
$ firebase functions:list
✔ sendMessageNotification (deployed)
✔ cleanupOldNotifications (deployed)
✔ sendFollowerNotification (deployed)
✔ testNotification (deployed)
```

### In App Console:
```
🔍 Testing Notification Setup...
📱 FCM Token: dXi8KGh3R5eY7s-abc123...
✅ Token exists
🔔 Notification Service Initialized
```

### In Firestore:
- `users/{userId}/fcmToken` exists
- `notificationRequests/{requestId}` created when message sent
- `processed: true` after function runs

### On Device:
- Notification appears when message is received
- Has sound and vibration
- Shows sender name and message

---

## 🚨 Most Common Mistake:

**Testing with BOTH devices having the app OPEN!**

For notifications to appear, the RECEIVER must have:
- App **minimized** (in background), OR
- App **completely closed**

If receiver has app open, they won't see a system notification (they'll just see the message in the chat).

---

## Need Help?

1. Run: `firebase functions:list`
2. Send me the output
3. Also send console output when you run the app

That will tell us exactly what's wrong!



