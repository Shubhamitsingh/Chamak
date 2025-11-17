# Firebase Cloud Functions for Chamak

This directory contains Firebase Cloud Functions for sending push notifications in the Chamak app.

## 🚀 Quick Start

### Prerequisites

- Node.js 16 or higher
- Firebase CLI installed
- Firebase project configured

### Setup

1. **Install Firebase CLI** (if not already installed):
```bash
npm install -g firebase-tools
```

2. **Login to Firebase**:
```bash
firebase login
```

3. **Initialize Firebase** (first time only):
```bash
firebase init functions
```

Select:
- Your Firebase project
- JavaScript (NOT TypeScript)
- Yes to install dependencies

4. **Install Dependencies**:
```bash
npm install
```

### Deploy

Deploy all functions:
```bash
firebase deploy --only functions
```

Deploy specific function:
```bash
firebase deploy --only functions:sendMessageNotification
```

### Test Locally

Run functions emulator:
```bash
npm run serve
```

## 📋 Available Functions

### 1. sendMessageNotification
**Trigger:** Firestore onCreate
**Path:** `notificationRequests/{requestId}`
**Purpose:** Sends push notification when a new message is sent

**Input:**
```json
{
  "token": "fcm_token_here",
  "notification": {
    "title": "User Name",
    "body": "Message text"
  },
  "data": {
    "type": "message",
    "chatId": "chat_id",
    "senderId": "sender_id"
  }
}
```

### 2. cleanupOldNotifications
**Trigger:** Scheduled (every 24 hours)
**Purpose:** Deletes processed notification requests older than 7 days

### 3. sendFollowerNotification
**Trigger:** Firestore onCreate
**Path:** `users/{userId}/followers/{followerId}`
**Purpose:** Sends notification when someone follows a user

### 4. updateUserFCMToken
**Trigger:** Callable (HTTPS)
**Purpose:** Manually update user's FCM token
**Usage:**
```javascript
const updateToken = firebase.functions().httpsCallable('updateUserFCMToken');
await updateToken({ fcmToken: 'new_token' });
```

### 5. testNotification
**Trigger:** Callable (HTTPS)
**Purpose:** Send test notification for debugging
**Usage:**
```javascript
const sendTest = firebase.functions().httpsCallable('testNotification');
await sendTest({
  token: 'fcm_token',
  title: 'Test',
  body: 'This is a test'
});
```

## 🔍 Monitoring

View function logs:
```bash
firebase functions:log
```

View logs for specific function:
```bash
firebase functions:log --only sendMessageNotification
```

Stream logs in real-time:
```bash
firebase functions:log --follow
```

## 🧪 Testing

### Test with Firebase Emulator

1. Start emulator:
```bash
npm run serve
```

2. Your functions will be available at:
```
http://localhost:5001/YOUR_PROJECT_ID/us-central1/FUNCTION_NAME
```

### Test in Production

Use the test functions or Firebase Console:
1. Go to Firebase Console → Functions
2. Click on a function
3. View execution logs and metrics

## 📊 Performance

### Quotas (Free Tier)

- **Invocations:** 2M/month
- **GB-seconds:** 400,000/month
- **CPU-seconds:** 200,000/month
- **Outbound networking:** 5GB/month

### Optimization Tips

1. **Minimize cold starts:** Keep functions small
2. **Use batching:** Process multiple notifications at once
3. **Clean up resources:** Delete old data regularly
4. **Use efficient queries:** Index Firestore queries

## 🔒 Security

### Best Practices

1. **Validate input:** Always check data before processing
2. **Authenticate requests:** Use Firebase Auth where applicable
3. **Rate limiting:** Prevent abuse by limiting requests
4. **Error handling:** Catch and log all errors

### Security Rules Example

Add to `firestore.rules`:
```javascript
match /notificationRequests/{requestId} {
  // Only authenticated users can create
  allow create: if request.auth != null;
  // Only functions can read/update
  allow read, update: if false;
}
```

## 🐛 Troubleshooting

### Functions not deploying?

1. Check Node.js version:
```bash
node --version  # Should be 16+
```

2. Clear cache and reinstall:
```bash
rm -rf node_modules
npm install
```

3. Check Firebase CLI version:
```bash
firebase --version  # Should be latest
```

### Notifications not sending?

1. Check function logs:
```bash
firebase functions:log
```

2. Verify FCM token is valid
3. Check Firestore data structure
4. Ensure Firebase project has FCM enabled

### Function execution failing?

1. Check error logs
2. Verify Firebase Admin SDK is initialized
3. Check Firestore permissions
4. Verify environment variables

## 📈 Monitoring & Alerts

### Set up monitoring:

1. Go to Firebase Console → Functions
2. Click on function name
3. View metrics: invocations, errors, execution time
4. Set up alerts for failures

### Recommended Alerts:

- Function execution failures > 5%
- Average execution time > 5 seconds
- Invocation count spike (possible spam)

## 💡 Tips

1. **Log everything:** Use `console.log()` liberally
2. **Test locally first:** Use emulator before deploying
3. **Monitor costs:** Check Firebase Console regularly
4. **Update regularly:** Keep dependencies up to date
5. **Document changes:** Add comments for complex logic

## 📚 Resources

- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [FCM Server Setup](https://firebase.google.com/docs/cloud-messaging/server)
- [Node.js on Firebase](https://firebase.google.com/docs/functions/nodejs)

## 🆘 Support

If you encounter issues:
1. Check the logs: `firebase functions:log`
2. Review the documentation
3. Check Firebase Status: https://status.firebase.google.com
4. Check Stack Overflow: Tag `firebase` + `cloud-functions`

## 📝 Version History

- **v1.0.0** - Initial release
  - Message notifications
  - Follower notifications
  - Auto cleanup
  - Test functions

---

**Made with ❤️ for Chamak**



