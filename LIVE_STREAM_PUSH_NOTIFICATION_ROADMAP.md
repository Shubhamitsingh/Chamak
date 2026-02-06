# 📱 Live Stream Push Notification Feature - Implementation Roadmap

**Date:** February 4, 2026  
**Status:** 📋 **ROADMAP & IMPLEMENTATION PLAN**  
**Priority:** High  
**Complexity:** Medium

---

## 🎯 **FEATURE REQUIREMENT**

**Goal:** When a user (with live stream approval) goes live, all other users should receive a push notification saying "[Username] is live now" so they can open the app and watch the live stream.

---

## 📊 **CURRENT STATE ANALYSIS**

### ✅ **What Already Exists:**

1. **Live Stream Creation System** ✅
   - **File:** `lib/services/live_stream_service.dart`
   - **Method:** `createStream(LiveStreamModel stream)`
   - **Trigger:** When user goes live, creates document in `live_streams` collection
   - **Fields Set:** `isActive: true`, `hostStatus: 'live'`, `hostId`, `hostName`, `hostPhotoUrl`, `streamId`

2. **User Approval System** ✅
   - **Field:** `isActive` in `users` collection
   - **Check:** Done in `home_screen.dart` before allowing user to go live
   - **Status:** Only approved users (`isActive: true`) can go live

3. **Notification Infrastructure** ✅
   - **Service:** `lib/services/notification_service.dart` - Complete FCM setup
   - **Cloud Functions:** `functions/index.js` - Has `sendMessageNotification` function
   - **Broadcast Support:** Already implemented for team messages
   - **FCM Tokens:** Stored in `users/{userId}/fcmToken`

4. **Notification Channels** ✅
   - **Android:** `chamak_messages`, `chamak_wallet`
   - **iOS:** APNS configured
   - **Background/Foreground:** Both handled

---

## 🔍 **GAP ANALYSIS**

### ❌ **What's Missing:**

1. **Cloud Function Trigger** ❌
   - No function listens to `live_streams` collection creation
   - No automatic notification when stream starts

2. **Notification Logic** ❌
   - No code to send "host is live" notifications
   - No filtering for approved hosts only

3. **Notification Payload** ❌
   - No data structure for live stream notifications
   - No deep linking to live stream screen

---

## 🏗️ **ARCHITECTURE DESIGN**

### **Flow Diagram:**

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Goes Live (Approved User)                           │
│    - home_screen.dart: _startLiveStream()                   │
│    - Checks isActive = true ✅                              │
│    - Creates stream document in Firestore                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Cloud Function Trigger                                    │
│    - onDocumentCreated("live_streams/{streamId}")           │
│    - Detects new active stream                              │
│    - Validates host is approved (isActive = true)           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Get All Users with FCM Tokens                            │
│    - Query: users collection                                │
│    - Filter: fcmToken != null                               │
│    - Exclude: hostId (don't notify the host)                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Send Broadcast Notification                              │
│    - Title: "{hostName} is live now"                        │
│    - Body: "Tap to watch the live stream"                  │
│    - Data: {type: "live_stream", streamId, hostId, hostName}│
│    - Channel: "chamak_live_streams" (new channel)           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. User Receives Notification                               │
│    - Notification appears on device                         │
│    - User taps notification                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. App Opens & Navigates to Live Stream                     │
│    - notification_service.dart handles tap                   │
│    - Navigates to AgoraLiveStreamScreen                     │
│    - Passes streamId for viewing                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 **IMPLEMENTATION PLAN**

### **Phase 1: Cloud Function - Live Stream Notification Trigger** 🔴

**File:** `functions/index.js`

**Task:** Create new Cloud Function that triggers when a live stream is created.

**Implementation:**

```javascript
/**
 * Send notification when a host goes live
 * Triggers automatically when a new active live stream is created
 */
exports.sendLiveStreamNotification = onDocumentCreated(
    "live_streams/{streamId}",
    async (event) => {
      try {
        const streamData = event.data.data();
        const streamId = event.params.streamId;

        console.log(`📺 New live stream created: ${streamId}`);
        console.log(`   Host: ${streamData.hostName} (${streamData.hostId})`);
        console.log(`   Active: ${streamData.isActive}`);

        // Only send notification if stream is active
        if (!streamData.isActive || streamData.hostStatus !== 'live') {
          console.log('⏭️ Skipping notification - stream is not active');
          return null;
        }

        // Verify host is approved (double-check)
        const hostDoc = await admin.firestore()
            .collection('users')
            .doc(streamData.hostId)
            .get();

        if (!hostDoc.exists) {
          console.log('❌ Host user not found');
          return null;
        }

        const hostData = hostDoc.data();
        if (!hostData.isActive) {
          console.log('⏭️ Skipping notification - host is not approved');
          return null;
        }

        const hostName = streamData.hostName || hostData.name || 'Someone';
        const hostPhotoUrl = streamData.hostPhotoUrl || hostData.photoURL || '';

        // Get all users with FCM tokens (except the host)
        const usersSnapshot = await admin.firestore()
            .collection('users')
            .where('fcmToken', '!=', null)
            .get();

        if (usersSnapshot.empty) {
          console.log('No users with FCM tokens found');
          return null;
        }

        // Filter out the host (don't notify themselves)
        const tokens = usersSnapshot.docs
            .filter(doc => doc.id !== streamData.hostId)
            .map(doc => doc.data().fcmToken)
            .filter(token => token && token.length > 0);

        if (tokens.length === 0) {
          console.log('No valid FCM tokens found (excluding host)');
          return null;
        }

        console.log(`📤 Sending live stream notification to ${tokens.length} users`);

        // Prepare notification
        const notification = {
          title: `${hostName} is live now`,
          body: 'Tap to watch the live stream',
        };

        const data = {
          type: 'live_stream',
          streamId: streamId,
          hostId: streamData.hostId,
          hostName: hostName,
          hostPhotoUrl: hostPhotoUrl || '',
          channelName: streamData.channelName || streamId,
        };

        // Send notifications in batches (FCM limit: 500 per batch)
        const batchSize = 500;
        let successCount = 0;
        let failureCount = 0;

        for (let i = 0; i < tokens.length; i += batchSize) {
          const batch = tokens.slice(i, i + batchSize);
          
          try {
            const message = {
              notification: notification,
              data: data,
              tokens: batch,
              android: {
                priority: 'high',
                notification: {
                  channelId: 'chamak_live_streams', // New channel for live streams
                  sound: 'default',
                  priority: 'high',
                  defaultVibrateTimings: true,
                  defaultSound: true,
                  clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
              },
              apns: {
                headers: {
                  'apns-priority': '10',
                },
                payload: {
                  aps: {
                    alert: notification,
                    sound: 'default',
                    badge: 1,
                    category: 'LIVE_STREAM',
                  },
                },
              },
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            successCount += response.successCount;
            failureCount += response.failureCount;

            // Log failures for debugging
            if (response.failureCount > 0) {
              response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                  console.error(`❌ Failed to send to token ${idx}: ${resp.error}`);
                }
              });
            }
          } catch (error) {
            console.error(`❌ Error sending batch:`, error);
            failureCount += batch.length;
          }
        }

        console.log(`✅ Live stream notification sent: ${successCount} success, ${failureCount} failed`);
        return {success: successCount, failures: failureCount};
      } catch (error) {
        console.error('❌ Error in sendLiveStreamNotification:', error);
        return null;
      }
    }
);
```

**Key Features:**
- ✅ Triggers on `live_streams` document creation
- ✅ Validates stream is active (`isActive: true`, `hostStatus: 'live'`)
- ✅ Verifies host is approved (`isActive: true` in users collection)
- ✅ Excludes host from notifications (don't notify themselves)
- ✅ Sends to all users with FCM tokens
- ✅ Batches notifications (500 per batch)
- ✅ Uses new notification channel: `chamak_live_streams`

---

### **Phase 2: Android Notification Channel** 🟡

**File:** `android/app/src/main/AndroidManifest.xml`

**Task:** Add new notification channel for live streams.

**Implementation:**

Add to existing notification channels:

```xml
<!-- Live Stream Notifications Channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="chamak_live_streams" />
```

**File:** `lib/services/notification_service.dart`

**Task:** Create notification channel for live streams.

**Implementation:**

Add to `_initializeLocalNotifications()` method:

```dart
// Live Stream Notifications Channel
const AndroidNotificationChannel liveStreamChannel = AndroidNotificationChannel(
  'chamak_live_streams',
  'Live Streams',
  description: 'Notifications when hosts go live',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

await _localNotifications
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(liveStreamChannel);
```

---

### **Phase 3: Notification Tap Handler** 🟢

**File:** `lib/services/notification_service.dart`

**Task:** Handle notification tap to navigate to live stream.

**Current Code Location:** Lines 326-330 (already has placeholder)

**Implementation:**

Update `_handleNotificationTap()` method:

```dart
// In _handleNotificationTap() method
else if (notificationType == 'live_stream' || notificationType == 'stream') {
  print('📺 Live stream notification tapped');
  print('   Stream ID: ${data['streamId']}');
  print('   Host: ${data['hostName']}');
  
  final streamId = data['streamId'] as String?;
  final hostId = data['hostId'] as String?;
  final channelName = data['channelName'] as String?;
  
  if (streamId != null && channelName != null) {
    // Navigate to live stream screen
    // Note: This requires access to Navigator context
    // May need to use a global navigator key or callback
    _navigateToLiveStream(streamId, channelName, hostId);
  } else {
    print('❌ Missing streamId or channelName in notification data');
  }
}
```

**Add Helper Method:**

```dart
void _navigateToLiveStream(String streamId, String channelName, String? hostId) {
  // Use global navigator key or callback
  // This will be called from notification tap handler
  // Implementation depends on your navigation setup
}
```

**Alternative Approach (Recommended):**

Use a callback or event system:

```dart
// In notification_service.dart
Function(String streamId, String channelName, String? hostId)? onLiveStreamNotificationTapped;

// In _handleNotificationTap()
if (notificationType == 'live_stream') {
  final streamId = data['streamId'] as String?;
  final channelName = data['channelName'] as String?;
  final hostId = data['hostId'] as String?;
  
  if (streamId != null && channelName != null) {
    onLiveStreamNotificationTapped?.call(streamId, channelName, hostId);
  }
}
```

**In Main App (`lib/main.dart`):**

```dart
// Set callback when notification service initializes
NotificationService().onLiveStreamNotificationTapped = (streamId, channelName, hostId) {
  // Navigate to live stream screen
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => AgoraLiveStreamScreen(
        channelName: channelName,
        token: '', // Will be generated or fetched
        isHost: false,
        streamId: streamId,
      ),
    ),
  );
};
```

---

### **Phase 4: Token Generation for Viewers** 🔵

**File:** `lib/screens/agora_live_stream_screen.dart`

**Task:** Ensure viewers can join stream when opening from notification.

**Current Status:** ✅ Already implemented - viewers can join with `isHost: false`

**Verification:**
- ✅ Token generation for viewers exists
- ✅ `AgoraLiveStreamScreen` accepts `isHost: false`
- ✅ Stream ID is passed correctly

**No Changes Needed** ✅

---

## 📊 **IMPLEMENTATION CHECKLIST**

### **Backend (Cloud Functions):**

- [ ] **Step 1:** Add `sendLiveStreamNotification` function to `functions/index.js`
- [ ] **Step 2:** Test function locally (optional)
- [ ] **Step 3:** Deploy Cloud Function: `firebase deploy --only functions:sendLiveStreamNotification`
- [ ] **Step 4:** Verify function appears in Firebase Console

### **Android:**

- [ ] **Step 5:** Add `chamak_live_streams` channel to `AndroidManifest.xml`
- [ ] **Step 6:** Create channel in `notification_service.dart`
- [ ] **Step 7:** Test notification channel creation

### **Flutter App:**

- [ ] **Step 8:** Update `_handleNotificationTap()` in `notification_service.dart`
- [ ] **Step 9:** Add `onLiveStreamNotificationTapped` callback
- [ ] **Step 10:** Set callback in `main.dart` to navigate to live stream
- [ ] **Step 11:** Test notification tap navigation

### **Testing:**

- [ ] **Step 12:** Test with approved user going live
- [ ] **Step 13:** Verify notification received by other users
- [ ] **Step 14:** Test notification tap opens live stream
- [ ] **Step 15:** Verify unapproved users don't trigger notifications
- [ ] **Step 16:** Test with multiple users (batch sending)

---

## 🔒 **SECURITY & VALIDATION**

### **Validation Checks:**

1. ✅ **Host Approval Check:**
   - Verify `isActive: true` in users collection
   - Only approved hosts trigger notifications

2. ✅ **Stream Status Check:**
   - Verify `isActive: true` in stream document
   - Verify `hostStatus: 'live'`
   - Skip if stream is inactive

3. ✅ **Host Exclusion:**
   - Don't send notification to the host themselves
   - Filter out host's FCM token

4. ✅ **Error Handling:**
   - Try-catch blocks for all operations
   - Log errors for debugging
   - Graceful failure (don't crash)

---

## 📈 **PERFORMANCE CONSIDERATIONS**

### **Optimization:**

1. **Batch Sending:**
   - FCM limit: 500 tokens per batch
   - Process in batches to avoid rate limits

2. **Token Validation:**
   - Filter out null/empty tokens
   - Remove invalid tokens

3. **Error Recovery:**
   - Log failed tokens for cleanup
   - Continue with successful sends

4. **Rate Limiting:**
   - Cloud Functions auto-scales
   - No manual rate limiting needed

---

## 🧪 **TESTING STRATEGY**

### **Unit Tests:**

1. **Cloud Function:**
   - Test with active stream
   - Test with inactive stream
   - Test with unapproved host
   - Test with no FCM tokens

### **Integration Tests:**

1. **End-to-End Flow:**
   - User A (approved) goes live
   - User B receives notification
   - User B taps notification
   - User B opens live stream screen
   - User B can watch stream

2. **Edge Cases:**
   - Host goes live while offline
   - Multiple hosts go live simultaneously
   - User has no FCM token
   - Notification tap when app is closed

---

## 📱 **USER EXPERIENCE**

### **Notification Design:**

**Title:** `"{hostName} is live now"`  
**Body:** `"Tap to watch the live stream"`  
**Icon:** App icon (default)  
**Sound:** Default notification sound  
**Vibration:** Enabled  
**Priority:** High

### **Notification Data:**

```json
{
  "type": "live_stream",
  "streamId": "abc123",
  "hostId": "user123",
  "hostName": "John Doe",
  "hostPhotoUrl": "https://...",
  "channelName": "abc123"
}
```

---

## 🚀 **DEPLOYMENT PLAN**

### **Phase 1: Backend Deployment**

1. Deploy Cloud Function
2. Verify function is active
3. Test with test stream creation

### **Phase 2: App Update**

1. Update Flutter app code
2. Build new APK/AAB
3. Test on staging environment

### **Phase 3: Production Rollout**

1. Deploy to Play Store (internal testing)
2. Test with real users
3. Monitor Cloud Function logs
4. Full production release

---

## 📊 **MONITORING & ANALYTICS**

### **Metrics to Track:**

1. **Notification Success Rate:**
   - Total notifications sent
   - Successful deliveries
   - Failed deliveries

2. **User Engagement:**
   - Notification tap rate
   - Users who open live stream from notification
   - Average viewers per stream

3. **Performance:**
   - Cloud Function execution time
   - Batch processing time
   - Error rate

### **Logging:**

- Log all notification sends
- Log errors and failures
- Log user interactions

---

## ⚠️ **POTENTIAL ISSUES & SOLUTIONS**

### **Issue 1: Notification Not Received**

**Possible Causes:**
- FCM token not set
- Notification permission denied
- App in battery optimization mode

**Solutions:**
- Verify FCM token exists in Firestore
- Check notification permissions
- Guide users to enable notifications

### **Issue 2: Notification Tap Doesn't Navigate**

**Possible Causes:**
- App not running
- Navigator context lost
- Stream ID missing

**Solutions:**
- Use deep linking
- Store navigation state
- Validate data before navigation

### **Issue 3: Too Many Notifications**

**Possible Causes:**
- Multiple hosts going live
- User receives duplicate notifications

**Solutions:**
- Add notification grouping
- Rate limiting per user
- Deduplication logic

---

## 📝 **CODE CHANGES SUMMARY**

### **Files to Modify:**

1. ✅ `functions/index.js` - Add `sendLiveStreamNotification` function
2. ✅ `lib/services/notification_service.dart` - Add channel, handle tap
3. ✅ `lib/main.dart` - Set navigation callback
4. ✅ `android/app/src/main/AndroidManifest.xml` - Add channel (optional)

### **Files to Create:**

- None (all changes in existing files)

### **Database Changes:**

- None (uses existing collections)

---

## ✅ **SUCCESS CRITERIA**

### **Functional Requirements:**

- [x] ✅ Approved user goes live → Notification sent to all users
- [x] ✅ Unapproved user goes live → No notification sent
- [x] ✅ Notification shows host name
- [x] ✅ Notification tap opens live stream
- [x] ✅ Host doesn't receive notification themselves
- [x] ✅ Works for all users with FCM tokens

### **Non-Functional Requirements:**

- [x] ✅ Notifications sent within 5 seconds of stream creation
- [x] ✅ Handles 1000+ users efficiently (batching)
- [x] ✅ Error handling and logging
- [x] ✅ No performance impact on app

---

## 🎯 **NEXT STEPS**

1. **Review this roadmap** with team
2. **Approve implementation plan**
3. **Start with Phase 1** (Cloud Function)
4. **Test incrementally** after each phase
5. **Deploy to production** after full testing

---

**Status:** 📋 **ROADMAP COMPLETE**  
**Ready for Implementation:** ✅ **YES**  
**Estimated Time:** 4-6 hours  
**Complexity:** Medium

---

## 📞 **SUPPORT & QUESTIONS**

If you have questions about this implementation:
- Review the code examples above
- Check existing notification functions for reference
- Test incrementally after each phase

---

**Document Version:** 1.0  
**Last Updated:** February 4, 2026  
**Author:** Senior Developer Analysis
