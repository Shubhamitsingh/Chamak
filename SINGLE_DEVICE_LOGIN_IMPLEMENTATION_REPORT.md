# 🔐 SINGLE DEVICE LOGIN - IMPLEMENTATION REPORT

## 📋 **REQUIREMENT**

**Feature:** When a user logs in on one device, any other device where the same account is logged in should be automatically logged out.

**Current Behavior:**
- ❌ User can login on multiple devices simultaneously
- ❌ Same account can be active on 2+ phones at the same time
- ❌ No automatic logout on other devices

**Expected Behavior:**
- ✅ User can only be logged in on ONE device at a time
- ✅ When user logs in on new device → Old device automatically logged out
- ✅ Similar to WhatsApp, Instagram, etc.

---

## 🔍 **CURRENT IMPLEMENTATION ANALYSIS**

### **Current Login Flow:**

**Location:** `lib/screens/otp_screen.dart` - Line 104

**Code:**
```dart
UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
```

**What Happens:**
1. User enters OTP
2. Firebase Auth verifies OTP
3. `signInWithCredential()` authenticates user
4. User data created/updated in Firestore
5. User navigates to home screen

**Current Behavior:**
- ✅ User authenticated successfully
- ✅ Session stored locally on device
- ❌ **NO check for existing sessions on other devices**
- ❌ **NO logout of other devices**

---

### **Current Auth State Listener:**

**Location:** `lib/main.dart` - Line 142-153

**Code:**
```dart
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user == null) {
    debugPrint('🔐 Auth state changed: User logged out');
    CrashlyticsService.clearUserId();
  } else {
    debugPrint('🔐 Auth state changed: User logged in - ${user.uid}');
    CrashlyticsService.setUserId(user.uid);
  }
});
```

**What It Does:**
- ✅ Listens to auth state changes
- ✅ Updates Crashlytics user ID
- ❌ **Does NOT handle multi-device logout**

---

### **Current User Data Storage:**

**Location:** `lib/services/database_service.dart` - Line 87-104

**Code:**
```dart
await _usersCollection.doc(userId).set({
  'userId': userId,
  'phoneNumber': phoneNumber,
  'lastLogin': FieldValue.serverTimestamp(),
  // ... other fields
});
```

**What's Stored:**
- ✅ User ID
- ✅ Phone number
- ✅ Last login timestamp
- ❌ **NO device ID or session tracking**
- ❌ **NO current device information**

---

## 🎯 **IMPLEMENTATION APPROACH**

### **Option 1: Firestore-Based Session Tracking (RECOMMENDED)**

**How It Works:**
1. Store current device ID in Firestore when user logs in
2. When user logs in on new device, check Firestore for existing device
3. If different device found → Revoke old session via Cloud Function
4. Listen to Firestore changes to detect logout on other device

**Pros:**
- ✅ Real-time updates via Firestore listeners
- ✅ Works even if app is closed
- ✅ No need to track tokens manually
- ✅ Simple implementation

**Cons:**
- ⚠️ Requires Cloud Function to revoke tokens
- ⚠️ Requires device ID package

---

### **Option 2: Firebase Auth Token Revocation**

**How It Works:**
1. Get device ID when user logs in
2. Store device ID + Firebase token in Firestore
3. When user logs in on new device → Call Cloud Function
4. Cloud Function revokes old token using Firebase Admin SDK
5. Old device detects token revoked → Auto logout

**Pros:**
- ✅ Uses Firebase built-in token revocation
- ✅ Secure and reliable
- ✅ Works automatically

**Cons:**
- ⚠️ Requires Cloud Function
- ⚠️ More complex implementation

---

## ✅ **RECOMMENDED IMPLEMENTATION (Option 1)**

### **Step 1: Add Device Info Package**

**File:** `pubspec.yaml`

**Add:**
```yaml
dependencies:
  device_info_plus: ^10.1.0  # Get device ID
```

**Install:**
```bash
flutter pub get
```

---

### **Step 2: Create Device Service**

**New File:** `lib/services/device_service.dart`

**Code:**
```dart
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// Get unique device ID
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use Android ID (unique per app installation)
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use identifierForVendor (unique per app)
        return iosInfo.identifierForVendor ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      debugPrint('❌ Error getting device ID: $e');
      return 'unknown';
    }
  }
  
  /// Get device name/model
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }
}
```

---

### **Step 3: Update User Model**

**File:** `lib/models/user_model.dart`

**Add Fields:**
```dart
final String? currentDeviceId;      // Current device ID
final DateTime? currentDeviceLoginAt; // When logged in on current device
```

**Update `fromFirestore()`:**
```dart
currentDeviceId: data['currentDeviceId']?.toString(),
currentDeviceLoginAt: (data['currentDeviceLoginAt'] as Timestamp?)?.toDate(),
```

---

### **Step 4: Update Login Flow**

**File:** `lib/screens/otp_screen.dart` - After line 104

**Add After Login:**
```dart
UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

// ✅ NEW: Check for existing session on other device
final deviceId = await DeviceService.getDeviceId();
final userId = userCredential.user?.uid;

if (userId != null) {
  await _handleSingleDeviceLogin(userId, deviceId);
}
```

**Add New Method:**
```dart
Future<void> _handleSingleDeviceLogin(String userId, String deviceId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      final data = userDoc.data();
      final existingDeviceId = data?['currentDeviceId'] as String?;
      
      // If different device is logged in, revoke old session
      if (existingDeviceId != null && existingDeviceId != deviceId) {
        debugPrint('⚠️ User logged in on different device: $existingDeviceId');
        debugPrint('🔄 Revoking old session...');
        
        // Call Cloud Function to revoke old token
        final functions = FirebaseFunctions.instance;
        final callable = functions.httpsCallable('revokeOldSession');
        await callable.call({
          'userId': userId,
          'oldDeviceId': existingDeviceId,
        });
        
        debugPrint('✅ Old session revoked');
      }
    }
    
    // Update current device info
    await firestore.collection('users').doc(userId).update({
      'currentDeviceId': deviceId,
      'currentDeviceLoginAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
    
    debugPrint('✅ Current device registered: $deviceId');
  } catch (e) {
    debugPrint('❌ Error handling single device login: $e');
    // Continue with login even if this fails
  }
}
```

---

### **Step 5: Create Cloud Function to Revoke Old Session**

**File:** `functions/index.js`

**Add:**
```javascript
/**
 * Revoke old session when user logs in on new device
 * This logs out the user on the old device
 */
exports.revokeOldSession = onCall({}, async (request) => {
  // Require authentication
  if (!request.auth) {
    throw new Error("User must be authenticated");
  }

  const { userId, oldDeviceId } = request.data;
  
  // Validate
  if (!userId || !oldDeviceId) {
    throw new Error("userId and oldDeviceId are required");
  }
  
  // Verify user is revoking their own session
  if (request.auth.uid !== userId) {
    throw new Error("Unauthorized");
  }

  try {
    // Get user's current Firebase Auth tokens
    // Note: Firebase Admin SDK can revoke refresh tokens
    const userRecord = await admin.auth().getUser(userId);
    
    // Revoke all refresh tokens (logs out all devices)
    // Then user will need to login again on new device
    await admin.auth().revokeRefreshTokens(userId);
    
    console.log(`✅ Revoked all sessions for user: ${userId}`);
    console.log(`   Old device: ${oldDeviceId}`);
    
    return { 
      success: true,
      message: 'Old session revoked'
    };
  } catch (error) {
    console.error("❌ Error revoking old session:", error);
    throw new Error(`Failed to revoke old session: ${error.message}`);
  }
});
```

**Alternative (More Granular):**
If you want to keep track of which device to revoke:
```javascript
// Store device tokens in Firestore
// When revoking, only revoke that specific device's token
// This requires more complex token management
```

---

### **Step 6: Listen for Session Revocation**

**File:** `lib/main.dart` - Update auth state listener

**Update:**
```dart
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user == null) {
    debugPrint('🔐 Auth state changed: User logged out');
    CrashlyticsService.clearUserId();
    
    // ✅ NEW: Check if logout was due to new device login
    _checkIfLoggedOutOnOtherDevice();
  } else {
    debugPrint('🔐 Auth state changed: User logged in - ${user.uid}');
    CrashlyticsService.setUserId(user.uid);
  }
});
```

**Add Method:**
```dart
Future<void> _checkIfLoggedOutOnOtherDevice() async {
  try {
    final deviceId = await DeviceService.getDeviceId();
    final firestore = FirebaseFirestore.instance;
    
    // Check if user document exists and has different device ID
    // This means user logged in on another device
    // Note: This check happens after logout, so user doc might be updated
    // You might want to show a message: "You've been logged out because you logged in on another device"
  } catch (e) {
    debugPrint('❌ Error checking logout reason: $e');
  }
}
```

**Better Approach - Listen to Firestore:**
```dart
// In home screen or main app widget
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final data = snapshot.data?.data();
      final currentDeviceId = data?['currentDeviceId'];
      final myDeviceId = await DeviceService.getDeviceId();
      
      // If device ID changed, user logged in on another device
      if (currentDeviceId != null && currentDeviceId != myDeviceId) {
        // Show message and logout
        _handleLoggedOutOnOtherDevice();
      }
    }
    return YourWidget();
  },
)
```

---

### **Step 7: Handle Logout on Other Device**

**File:** `lib/screens/home_screen.dart` or `lib/main.dart`

**Add Listener:**
```dart
void _setupDeviceSessionListener() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;   
  
  FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .listen((snapshot) async {
    if (!snapshot.exists) return;
    
    final data = snapshot.data();
    final currentDeviceId = data?['currentDeviceId'] as String?;
    final myDeviceId = await DeviceService.getDeviceId();
    
    // If device ID changed, user logged in on another device
    if (currentDeviceId != null && currentDeviceId != myDeviceId) {
      debugPrint('⚠️ User logged in on another device: $currentDeviceId');
      
      // Show message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have been logged out because you logged in on another device.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Logout current device
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  });
}
```

---

## 📊 **IMPLEMENTATION SUMMARY**

### **Files to Create:**
1. ✅ `lib/services/device_service.dart` - Get device ID

### **Files to Modify:**
1. ✅ `pubspec.yaml` - Add `device_info_plus` package
2. ✅ `lib/screens/otp_screen.dart` - Add single device login check
3. ✅ `lib/models/user_model.dart` - Add device tracking fields
4. ✅ `lib/services/database_service.dart` - Update user creation/update
5. ✅ `lib/main.dart` or `lib/screens/home_screen.dart` - Add device session listener
6. ✅ `functions/index.js` - Add `revokeOldSession` Cloud Function

---

## 🔄 **COMPLETE FLOW**

### **Scenario: User Logs In on New Device**

```
1. User enters phone number on Device B
   ↓
2. OTP verified → signInWithCredential()
   ↓
3. Get Device B ID: "device_b_123"
   ↓
4. Check Firestore: currentDeviceId = "device_a_456"
   ↓
5. Different device found!
   ↓
6. Call Cloud Function: revokeOldSession()
   ↓
7. Cloud Function revokes all Firebase tokens for user
   ↓
8. Device A detects token revoked → Auto logout
   ↓
9. Update Firestore: currentDeviceId = "device_b_123"
   ↓
10. Device B continues with login ✅
```

---

### **Scenario: User Already Logged In (Same Device)**

```
1. User enters phone number on Device A
   ↓
2. OTP verified → signInWithCredential()
   ↓
3. Get Device A ID: "device_a_456"
   ↓
4. Check Firestore: currentDeviceId = "device_a_456"
   ↓
5. Same device! ✅
   ↓
6. Update lastLogin timestamp
   ↓
7. Continue with login ✅
```

---

## 🧪 **TESTING SCENARIOS**

### **Test 1: Login on First Device**
- [ ] User logs in on Device A
- [ ] Check Firestore: `currentDeviceId` = Device A ID
- [ ] User can use app normally

### **Test 2: Login on Second Device**
- [ ] User logs in on Device B (same account)
- [ ] Check Firestore: `currentDeviceId` = Device B ID
- [ ] Device A should be logged out automatically
- [ ] Device B can use app normally

### **Test 3: Login Back on First Device**
- [ ] User logs in on Device A again
- [ ] Device B should be logged out
- [ ] Device A can use app normally

### **Test 4: Same Device Re-login**
- [ ] User logs in on Device A
- [ ] User logs out
- [ ] User logs in again on Device A
- [ ] Should work normally (same device)

---

## ⚠️ **IMPORTANT CONSIDERATIONS**

### **1. Device ID Uniqueness**
- Android: `androidInfo.id` - Unique per app installation
- iOS: `identifierForVendor` - Unique per app
- **Note:** If user uninstalls and reinstalls app, device ID changes
- **Result:** User will need to login again (this is acceptable)

### **2. Token Revocation**
- Revoking tokens logs out ALL devices
- User needs to login again on new device
- This is the expected behavior for single-device login

### **3. Network Issues**
- If network is slow, old device might not logout immediately
- Firestore listener will detect change when network available
- User will be logged out within 1-2 seconds

### **4. User Experience**
- Show message: "You've been logged out because you logged in on another device"
- Don't show error - this is expected behavior
- User can login again if they want

---

## 📝 **ALTERNATIVE APPROACH (Simpler)**

### **Option: Just Update Device ID (No Token Revocation)**

**Simpler Implementation:**
1. Store `currentDeviceId` in Firestore when user logs in
2. Listen to Firestore changes on all devices
3. If `currentDeviceId` changes → Logout current device
4. No Cloud Function needed!

**Pros:**
- ✅ Simpler - no Cloud Function
- ✅ Real-time via Firestore listeners
- ✅ Works automatically

**Cons:**
- ⚠️ Old device stays logged in until it checks Firestore
- ⚠️ Might have brief period where both devices are logged in

**Code:**
```dart
// In home screen or main widget
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final data = snapshot.data?.data();
      final currentDeviceId = data?['currentDeviceId'];
      final myDeviceId = await DeviceService.getDeviceId();
      
      if (currentDeviceId != null && currentDeviceId != myDeviceId) {
        // Logout
        FirebaseAuth.instance.signOut();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
    return YourWidget();
  },
)
```

---

## ✅ **RECOMMENDED IMPLEMENTATION PLAN**

### **Phase 1: Basic Implementation (Simpler)**
1. ✅ Add `device_info_plus` package
2. ✅ Create `DeviceService` to get device ID
3. ✅ Update login flow to store device ID
4. ✅ Add Firestore listener to detect device change
5. ✅ Auto logout when device ID changes

**Time:** ~2-3 hours

### **Phase 2: Enhanced (With Cloud Function)**
1. ✅ Add Cloud Function to revoke tokens
2. ✅ Call Cloud Function when new device logs in
3. ✅ Immediate logout on old device

**Time:** ~1-2 hours

---

## 📊 **CURRENT vs AFTER IMPLEMENTATION**

### **Current:**
```
❌ User can login on multiple devices
❌ Same account active on 2+ phones
❌ No automatic logout
```

### **After Implementation:**
```
✅ User can only login on ONE device
✅ New login → Old device automatically logged out
✅ Real-time detection via Firestore
✅ Clear user feedback
```

---

## 🚀 **NEXT STEPS**

1. **Review this report** - Understand the approach
2. **Decide on approach** - Simple (Firestore only) or Enhanced (with Cloud Function)
3. **Implement Phase 1** - Basic single device login
4. **Test thoroughly** - Multiple devices, network issues
5. **Add Phase 2** - Cloud Function for immediate logout (optional)

---

**Status:** 📋 **REPORT COMPLETE - READY FOR IMPLEMENTATION**

**Recommendation:** Start with **Phase 1 (Simpler Approach)** - It's easier and works well. Add Cloud Function later if needed.
