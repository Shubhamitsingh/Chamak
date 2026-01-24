=['# ANDROID FIXES ACTION PLAN
## Production-Grade QA Checklist - Implementation Guide

**Platform:** Android Only  
**Version:** 1.0.8+20  
**Priority:** Critical Fixes Required Before Production

---

## 🔴 CRITICAL FIXES (MUST DO BEFORE PRODUCTION)

### 1. LIVE STREAMING HEARTBEAT MECHANISM

#### **Problem:**
- Streams disappear after 2 minutes because `keepStreamAlive()` function exists but is **NEVER CALLED**
- Code checks for `lastHeartbeat` but it's never updated, so streams get filtered out

#### **What Needs to Be Done:**
Add a periodic timer in `AgoraLiveStreamScreen` that calls `keepStreamAlive()` every 60 seconds while host is streaming.

#### **Where to Fix:**
**File:** `lib/screens/agora_live_stream_screen.dart`

**Add this code in `initState()` when `widget.isHost == true`:**
```dart
Timer? _heartbeatTimer;

@override
void initState() {
  super.initState();
  // ... existing code ...
  
  // Start heartbeat timer for host
  if (widget.isHost && widget.streamId != null) {
    _startHeartbeatTimer();
  }
}

void _startHeartbeatTimer() {
  _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
    if (mounted && widget.isHost && widget.streamId != null) {
      _liveStreamService.keepStreamAlive(widget.streamId!);
      debugPrint('💓 Heartbeat sent: ${widget.streamId}');
    } else {
      timer.cancel();
    }
  });
}

@override
void dispose() {
  _heartbeatTimer?.cancel();
  // ... existing dispose code ...
}
```

#### **What This Function Will Do After Implementation:**
- ✅ Every 60 seconds, updates `lastHeartbeat` timestamp in Firestore
- ✅ Keeps stream visible in home page listings (streams with heartbeat < 3 minutes show)
- ✅ Prevents streams from disappearing after 2 minutes
- ✅ Automatically stops when host leaves or stream ends

#### **Expected Behavior:**
- **Before:** Stream disappears after 2 minutes → Users can't find live hosts
- **After:** Stream stays visible as long as host is actively streaming → Users always see real-time live hosts

---

### 2. VIEWER COUNT UPDATES (FIRESTORE RULES FIX)

#### **Problem:**
- Firestore rules only allow host to update `live_streams` document
- Viewers cannot increment/decrement viewer count → Count stays at 0 or wrong number
- Code tries to update but fails silently due to permission denied

#### **What Needs to Be Done:**
Create a Cloud Function to handle viewer count updates, OR adjust Firestore rules to allow viewers to update only the `viewerCount` field.

#### **Option 1: Cloud Function (RECOMMENDED - More Secure)**

**Create new Cloud Function in `functions/index.js`:**
```javascript
exports.updateViewerCount = onCall({}, async (request) => {
  if (!request.auth) {
    throw new Error("User must be authenticated");
  }

  const { streamId, action } = request.data; // action: 'join' or 'leave'
  
  if (!streamId || !action) {
    throw new Error("streamId and action are required");
  }

  const streamRef = admin.firestore().collection('live_streams').doc(streamId);
  
  if (action === 'join') {
    await streamRef.update({
      'viewerCount': admin.firestore.FieldValue.increment(1),
    });
  } else if (action === 'leave') {
    await streamRef.update({
      'viewerCount': admin.firestore.FieldValue.increment(-1),
    });
  }
  
  return { success: true };
});
```

**Update `lib/services/live_stream_service.dart`:**
```dart
Future<void> joinStream(String streamId, {String? viewerId}) async {
  try {
    // ... existing viewer subcollection code ...
    
    // Call Cloud Function instead of direct Firestore update
    final callable = FirebaseFunctions.instance.httpsCallable('updateViewerCount');
    await callable.call({
      'streamId': streamId,
      'action': 'join',
    });
    
    // ... rest of code ...
  }
}

Future<void> leaveStream(String streamId, {String? viewerId}) async {
  try {
    // ... existing viewer subcollection code ...
    
    // Call Cloud Function instead of direct Firestore update
    final callable = FirebaseFunctions.instance.httpsCallable('updateViewerCount');
    await callable.call({
      'streamId': streamId,
      'action': 'leave',
    });
    
    // ... rest of code ...
  }
}
```

#### **Option 2: Firestore Rules Fix (QUICKER BUT LESS SECURE)**

**Update `firestore.rules`:**
```javascript
match /live_streams/{streamId} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update: if request.auth != null 
    && resource.data != null
    && (
      // Host can update everything
      request.auth.uid == resource.data.hostId
      ||
      // Viewers can ONLY update viewerCount field
      (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['viewerCount'])
       && request.resource.data.viewerCount is int
       && request.resource.data.viewerCount >= 0)
    );
  // ... rest of rules ...
}
```

#### **What This Function Will Do After Implementation:**
- ✅ Viewers can join stream and count increments correctly
- ✅ Viewers can leave stream and count decrements correctly
- ✅ Real-time viewer count displayed accurately to host
- ✅ No more permission denied errors

#### **Expected Behavior:**
- **Before:** Viewer count always shows 0 or wrong number → Host doesn't know how many viewers
- **After:** Viewer count updates in real-time → Host sees accurate viewer count

---

### 3. MANUAL UTR PAYMENT BYPASS (CRITICAL - FINANCIAL)

#### **Problem:**
- `PaymentService.submitUTR()` allows users to enter ANY UTR number
- Coins are credited **IMMEDIATELY** without any verification
- Users can get free coins by entering fake UTR numbers

#### **What Needs to Be Done:**
**REMOVE** the manual UTR flow entirely, OR require admin approval before crediting coins.

#### **Option 1: Remove Manual UTR (RECOMMENDED)**

**File:** `lib/services/payment_service.dart`

**Remove or disable `submitUTR()` method:**
```dart
// DISABLE THIS METHOD - DO NOT USE
@Deprecated('Manual UTR payment disabled - use PayPrime gateway only')
Future<Map<String, dynamic>> submitUTR({
  required String utrNumber,
  required int coins,
  required int amount,
  required String packageId,
}) async {
  // Return error - manual UTR disabled
  return {
    'success': false,
    'message': 'Manual UTR payment is disabled. Please use PayPrime payment gateway.',
  };
}
```

**Update UI to remove UTR input option** - Only show PayPrime payment gateway.

#### **Option 2: Require Admin Approval (IF YOU MUST KEEP UTR)**

**Update `submitUTR()` to create PENDING payment:**
```dart
Future<Map<String, dynamic>> submitUTR({
  required String utrNumber,
  required int coins,
  required int amount,
  required String packageId,
}) async {
  // ... validation code ...
  
  // Create payment record with PENDING status
  final paymentRef = _firestore.collection('payments').doc();
  await paymentRef.set({
    'userId': currentUser.uid,
    'packageId': packageId,
    'coins': coins,
    'amount': amount,
    'utrNumber': utrNumber.trim().toUpperCase(),
    'status': 'PENDING', // ⚠️ DO NOT AUTO-COMPLETE
    'createdAt': FieldValue.serverTimestamp(),
    'requiresAdminApproval': true, // Flag for admin
  });

  // ⚠️ DO NOT ADD COINS HERE - Wait for admin approval
  return {
    'success': true,
    'message': 'Payment submitted. Coins will be added after admin verification.',
    'paymentId': paymentRef.id,
    'status': 'PENDING',
  };
}
```

**Admin must manually verify UTR and approve payment** before coins are added.

#### **What This Function Will Do After Implementation:**
- ✅ No more free coins from fake UTR numbers
- ✅ All payments go through verified gateway (PayPrime)
- ✅ Financial security maintained
- ✅ Revenue protected

#### **Expected Behavior:**
- **Before:** User enters fake UTR → Gets coins immediately → Free coins exploit
- **After:** User must use PayPrime gateway → Payment verified → Coins added only after confirmation

---

### 4. NOTIFICATION DEEP LINKING

#### **Problem:**
- `_onNotificationTapped()` only logs the notification, doesn't navigate
- `_checkInitialMessage()` checks for notification but doesn't navigate
- Users tap notification → Nothing happens → Bad user experience

#### **What Needs to Be Done:**
Implement navigation logic to open correct screen based on notification type.

#### **File:** `lib/services/notification_service.dart`

**Add navigation key in `main.dart`:**
```dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // ... existing code ...
  
  runApp(
    MaterialApp(
      navigatorKey: navigatorKey, // Add this
      // ... rest of app ...
    ),
  );
}
```

**Update `_onNotificationTapped()`:**
```dart
void _onNotificationTapped(NotificationResponse response) {
  print('🔔 Notification tapped: ${response.payload}');
  
  if (response.payload != null) {
    try {
      final data = json.decode(response.payload!);
      final notificationType = data['type'] as String?;
      
      // Navigate based on notification type
      if (notificationType == 'coin_addition') {
        // Navigate to wallet screen
        navigatorKey.currentState?.pushNamed('/wallet');
      } else if (notificationType == 'message') {
        // Navigate to chat screen
        final chatId = data['chatId'] as String?;
        if (chatId != null) {
          navigatorKey.currentState?.pushNamed('/chat', arguments: {'chatId': chatId});
        }
      } else if (notificationType == 'live_stream') {
        // Navigate to live stream
        final streamId = data['streamId'] as String?;
        if (streamId != null) {
          navigatorKey.currentState?.pushNamed('/live', arguments: {'streamId': streamId});
        }
      }
    } catch (e) {
      print('❌ Error parsing notification payload: $e');
    }
  }
}
```

**Update `_checkInitialMessage()`:**
```dart
Future<void> _checkInitialMessage() async {
  RemoteMessage? initialMessage = await _messaging.getInitialMessage();
  
  if (initialMessage != null) {
    print('🔔 App opened from terminated state via notification');
    // Wait for app to initialize
    await Future.delayed(const Duration(milliseconds: 500));
    _handleNotificationTap(initialMessage.data);
  }
}
```

#### **What This Function Will Do After Implementation:**
- ✅ User taps notification → Opens correct screen (wallet/chat/live)
- ✅ App killed → Opens from notification → Navigates to correct screen
- ✅ Better user experience
- ✅ Users can quickly access content from notifications

#### **Expected Behavior:**
- **Before:** User taps notification → Nothing happens → User confused
- **After:** User taps notification → Opens wallet/chat/live screen → User happy

---

### 5. FIRESTORE SECURITY RULES FIXES

#### **Problem 1: Call Transactions Readable by All Users**

**Current Rule (INSECURE):**
```javascript
match /callTransactions/{transactionId} {
  allow read: if request.auth != null && (isAdmin() || true); // ⚠️ ALL USERS CAN READ
}
```

**Fix:**
```javascript
match /callTransactions/{transactionId} {
  // Users can only read their own transactions (as caller or host)
  allow read: if request.auth != null 
    && (isAdmin() 
        || (resource.data != null && (
            resource.data.callerId == request.auth.uid 
            || resource.data.hostId == request.auth.uid
          )));
  // ... rest of rules ...
}
```

#### **Problem 2: Live Chat Messages Deletable by Any User**

**Current Rule (INSECURE):**
```javascript
match /chat/{messageId} {
  allow delete: if request.auth != null; // ⚠️ ANY USER CAN DELETE
}
```

**Fix:**
```javascript
match /chat/{messageId} {
  // Only host can delete messages in their stream
  allow delete: if request.auth != null 
    && resource.data != null
    && request.auth.uid == get(/databases/$(database)/documents/live_streams/$(streamId)).data.hostId;
  // OR use Cloud Function to delete (more secure)
}
```

#### **What This Will Do After Implementation:**
- ✅ Call transaction history private (only caller/host can see)
- ✅ Chat messages protected (only host can delete)
- ✅ User privacy protected
- ✅ No data leakage

#### **Expected Behavior:**
- **Before:** Any user can read all call transactions → Privacy breach
- **After:** Users can only see their own transactions → Privacy protected

---

### 6. REMOVE SENSITIVE DATA FROM LOGS

#### **Problem:**
- Extensive `print()` and `debugPrint()` statements include:
  - User IDs
  - Phone numbers
  - Payment data
  - UTR numbers
- This data can be extracted from device logs

#### **What Needs to Be Done:**
Create a logger utility that redacts sensitive data in production builds.

#### **Create `lib/utils/production_logger.dart`:**
```dart
import 'package:flutter/foundation.dart';

class ProductionLogger {
  static void log(String message, {Object? data}) {
    if (kDebugMode) {
      // Full logging in debug mode
      print('$message ${data ?? ''}');
    } else {
      // Redacted logging in production
      print('$message [REDACTED]');
    }
  }
  
  static void logUser(String message, String userId) {
    if (kDebugMode) {
      print('$message User: $userId');
    } else {
      print('$message User: [REDACTED]');
    }
  }
  
  static void logPayment(String message, Map<String, dynamic> paymentData) {
    if (kDebugMode) {
      print('$message Payment: $paymentData');
    } else {
      // Redact sensitive fields
      final redacted = Map<String, dynamic>.from(paymentData);
      redacted['utrNumber'] = '[REDACTED]';
      redacted['userId'] = '[REDACTED]';
      print('$message Payment: $redacted');
    }
  }
}
```

**Replace all `print()` statements with `ProductionLogger.log()`**

#### **What This Will Do After Implementation:**
- ✅ Sensitive data not logged in production builds
- ✅ User privacy protected
- ✅ Payment data not exposed
- ✅ GDPR compliant

#### **Expected Behavior:**
- **Before:** Logs contain user IDs, phone numbers, UTR numbers → Privacy risk
- **After:** Logs redact sensitive data → Privacy protected

---

## ⚠️ HIGH PRIORITY FIXES (DO AFTER CRITICAL)

### 7. ADD BLOCK USER FUNCTIONALITY

#### **What Needs to Be Done:**
Create a block user feature that prevents blocked users from:
- Viewing your profile
- Sending messages
- Joining your live streams
- Seeing your content

#### **Implementation:**
1. Add `blockedUsers` array to user document
2. Create `BlockService` to handle block/unblock
3. Update Firestore rules to filter blocked users
4. Add UI in profile screen to block/unblock users

#### **What This Will Do:**
- ✅ Users can block abusive users
- ✅ Blocked users cannot interact with you
- ✅ Better user safety
- ✅ Content moderation support

---

### 8. IMAGE UPLOAD VALIDATION

#### **What Needs to Be Done:**
Add validation for profile image uploads:
- Maximum file size: 5MB
- Allowed formats: JPG, PNG, WebP
- Image dimensions validation
- Virus scanning (optional)

#### **Implementation:**
```dart
Future<String?> uploadProfileImage(File imageFile) async {
  // Validate file size
  final fileSize = await imageFile.length();
  if (fileSize > 5 * 1024 * 1024) { // 5MB
    throw Exception('Image size must be less than 5MB');
  }
  
  // Validate file type
  final extension = imageFile.path.split('.').last.toLowerCase();
  if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
    throw Exception('Only JPG, PNG, and WebP images are allowed');
  }
  
  // Validate image dimensions (optional)
  // ... image processing ...
  
  // Upload to Firebase Storage
  // ...
}
```

#### **What This Will Do:**
- ✅ Prevents large file uploads
- ✅ Only allows valid image formats
- ✅ Protects storage costs
- ✅ Better performance

---

## 📊 EXPECTED RESULTS AFTER ALL FIXES

### Live Streaming
- ✅ Streams stay visible as long as host is active
- ✅ Viewer count updates correctly in real-time
- ✅ No ghost streams after crashes
- ✅ Better user experience

### Payments
- ✅ No free coins exploit
- ✅ All payments verified
- ✅ Financial security maintained
- ✅ Revenue protected

### Notifications
- ✅ Deep linking works
- ✅ Users can navigate from notifications
- ✅ Better engagement
- ✅ Improved user experience

### Security
- ✅ Privacy protected
- ✅ No data leakage
- ✅ Secure Firestore rules
- ✅ GDPR compliant

---

## 🎯 IMPLEMENTATION PRIORITY

### Phase 1: Critical (DO FIRST - 2-3 days)
1. ✅ Live streaming heartbeat mechanism
2. ✅ Viewer count updates fix
3. ✅ Manual UTR payment removal
4. ✅ Notification deep linking
5. ✅ Firestore security rules fixes

### Phase 2: High Priority (DO NEXT - 1-2 days)
6. ✅ Remove sensitive data from logs
7. ✅ Add block user functionality
8. ✅ Image upload validation

### Phase 3: Testing (AFTER FIXES - 1 day)
- Test all fixes
- Verify no regressions
- Performance testing
- Security audit

---

## ✅ FINAL CHECKLIST

After implementing all fixes, verify:

- [ ] Streams stay visible for active hosts
- [ ] Viewer count updates correctly
- [ ] No manual UTR payment option
- [ ] Notifications navigate correctly
- [ ] Firestore rules secure
- [ ] No sensitive data in logs
- [ ] Block user works
- [ ] Image upload validated
- [ ] All tests pass
- [ ] Production ready

---

**Status:** ❌ NOT PRODUCTION READY - Fix critical issues first  
**Estimated Time:** 3-5 days for all critical fixes  
**Next Steps:** Start with Phase 1 critical fixes
