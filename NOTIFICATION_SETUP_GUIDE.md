# 🔔 Firebase Cloud Messaging (FCM) Notification Setup Guide

## ✅ What Has Been Implemented

Your **Chamak** app now has a complete push notification system! Here's what was added:

### 1. **Dependencies Added** (`pubspec.yaml`)
- `firebase_messaging: ^15.1.5` - For receiving push notifications
- `flutter_local_notifications: ^18.0.1` - For displaying notifications on device

### 2. **New Service Created** (`lib/services/notification_service.dart`)
- Handles FCM token generation and storage
- Manages notification permissions
- Shows notifications in foreground and background
- Handles notification taps
- Sends notification requests to Firestore

### 3. **User Model Updated** (`lib/models/user_model.dart`)
- Added `fcmToken` field to store user's device token
- Token is automatically saved when user logs in

### 4. **Chat Service Enhanced** (`lib/services/chat_service.dart`)
- Automatically sends notifications when a message is sent
- Gets receiver's FCM token from Firestore
- Creates notification request in database

### 5. **Main App Initialized** (`lib/main.dart`)
- FCM initialized on app startup
- Background message handler registered
- Notification service started automatically

### 6. **Android Configuration** (`android/app/src/main/AndroidManifest.xml`)
- Added notification permissions
- Configured Firebase Messaging service
- Set default notification channel and icon

### 7. **Cloud Functions Created** (`functions/index.js`)
- Server-side function to send actual push notifications
- Automatic cleanup of old notification requests
- Follower notifications support
- Test notification function

---

## 🚀 How to Complete the Setup

### Step 1: Install Dependencies

Run this command in your project root:

```bash
flutter pub get
```

### Step 2: Setup Firebase Cloud Functions

#### A. Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
```

#### B. Login to Firebase

```bash
firebase login
```

#### C. Initialize Firebase Functions

```bash
firebase init functions
```

When prompted:
- Select your Firebase project
- Choose **JavaScript** (not TypeScript)
- Install dependencies with npm: **Yes**

#### D. Replace the functions code

The `functions/index.js` and `functions/package.json` files are already created for you.

#### E. Install dependencies

```bash
cd functions
npm install
```

#### F. Deploy Cloud Functions

```bash
firebase deploy --only functions
```

This will deploy:
- `sendMessageNotification` - Sends notifications for new messages
- `cleanupOldNotifications` - Cleans up old notification requests
- `sendFollowerNotification` - Sends notifications for new followers
- `updateUserFCMToken` - Updates user FCM token
- `testNotification` - Test notification function

### Step 3: Test the Notification System

#### A. Run your app

```bash
flutter run
```

#### B. Login with two different users

- User A on Device/Emulator 1
- User B on Device/Emulator 2

#### C. Send a message

- User A sends a message to User B
- User B should receive a push notification!

---

## 🎯 How It Works

### Message Flow

1. **User A** sends a message to **User B**
2. `ChatService.sendMessage()` is called
3. Message is saved to Firestore
4. Notification request is created in `notificationRequests` collection
5. Cloud Function `sendMessageNotification` is triggered
6. Function retrieves User B's FCM token
7. Function sends push notification via FCM
8. User B receives notification on their device!

### Notification Types

#### 1. **Foreground Notifications**
- App is open and active
- Shows local notification with sound and vibration

#### 2. **Background Notifications**
- App is minimized but running
- Shows system notification automatically

#### 3. **Terminated State Notifications**
- App is completely closed
- Notification wakes up the app when tapped

---

## 🔧 Troubleshooting

### Notifications Not Working?

#### 1. Check Firebase Console
- Go to Firebase Console → Cloud Messaging
- Verify FCM is enabled

#### 2. Check Permissions
```dart
// Check if permission is granted
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Permission status: ${settings.authorizationStatus}');
```

#### 3. Check FCM Token
```dart
// Print FCM token
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

#### 4. Check Cloud Functions Logs
```bash
firebase functions:log
```

#### 5. Test Notification Manually

You can send a test notification from Firebase Console:
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Select your app
5. Send test message

### Android 13+ Not Showing Notifications?

Make sure the user grants notification permission:
```dart
await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

---

## 📱 Features Included

### ✅ Real-time Notifications
- Instant delivery when messages are sent
- Works in foreground, background, and terminated states

### ✅ Sound & Vibration
- Custom notification sounds (can be configured)
- Vibration on notification arrival

### ✅ Notification Tap Handling
- Opens the app and navigates to chat screen
- Includes chat metadata in notification payload

### ✅ Badge Count Support
- Shows unread message count (iOS)
- Can be customized per user

### ✅ Automatic Token Management
- FCM tokens automatically refreshed
- Tokens stored in Firestore
- Old tokens cleaned up on logout

### ✅ Notification Channels (Android)
- Separate channel for message notifications
- User can customize notification settings

---

## 🎨 Customization Options

### Change Notification Sound

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_sound"
    android:resource="@raw/notification_sound" />
```

Add your sound file to: `android/app/src/main/res/raw/notification_sound.mp3`

### Change Notification Icon

Replace the icon in `android/app/src/main/res/mipmap-*/ic_launcher.png`

Or create a custom notification icon:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
```

### Customize Notification Content

Edit `functions/index.js`:
```javascript
const message = {
  notification: {
    title: '💬 ' + notification.title,  // Add emoji
    body: notification.body,
  },
  // ... rest of the configuration
};
```

---

## 🔐 Security Best Practices

### 1. **Secure FCM Tokens**
- Tokens are stored securely in Firestore
- Only accessible by authenticated users
- Tokens are deleted on logout

### 2. **Validate Notification Requests**
- Cloud Functions verify user authentication
- Only valid users can trigger notifications
- Rate limiting can be added if needed

### 3. **Prevent Spam**
```javascript
// Add to Cloud Functions
const recentNotifications = await admin.firestore()
  .collection('notificationRequests')
  .where('senderId', '==', senderId)
  .where('createdAt', '>', Date.now() - 60000) // Last minute
  .get();

if (recentNotifications.size > 10) {
  throw new Error('Too many notifications sent');
}
```

---

## 📊 Monitoring & Analytics

### View Notification Delivery

Firebase Console → Cloud Messaging → Reports:
- Delivery rate
- Open rate
- Errors and failures

### Add Custom Analytics

```dart
// Track notification received
await FirebaseAnalytics.instance.logEvent(
  name: 'notification_received',
  parameters: {'type': 'message'},
);
```

---

## 🆘 Need Help?

### Common Issues

**Issue**: "Permission denied" when deploying functions
**Solution**: Run `firebase login` again

**Issue**: Notifications not appearing on iOS
**Solution**: Ensure APNs is configured in Firebase Console

**Issue**: Background notifications not working
**Solution**: Verify background message handler is registered in `main.dart`

---

## 🎉 You're All Set!

Your app now has a complete notification system that:
- ✅ Sends notifications for new messages
- ✅ Works in all app states (foreground, background, terminated)
- ✅ Handles notification taps
- ✅ Manages FCM tokens automatically
- ✅ Cleans up old data
- ✅ Scales to millions of users

### Next Steps

1. Run `flutter pub get`
2. Deploy Cloud Functions: `firebase deploy --only functions`
3. Test with two devices
4. Customize notification appearance
5. Add more notification types (likes, comments, etc.)

**Happy Coding! 🚀**



