# 🚨 Firestore Permission-Denied Error - Crashlytics Report & Solution

**Date:** Generated on Request  
**Error Type:** `cloud_firestore/permission-denied`  
**Location:** `EventChannelExtension.receiveGuardedBroadcastStream`  
**Affected Devices:** Tecno Pova Curve 5G (and potentially other devices)  
**Severity:** 🔴 **HIGH** - Production Issue

---

## 📋 Executive Summary

### Issue Overview

The application is experiencing **fatal crashes** due to Firestore permission-denied errors. This occurs when Firestore listeners (`.snapshots()`) attempt to access collections without proper authentication or when security rules deny access.

**Error Details:**
```
Fatal Exception: io.flutter.plugins.firebase.crashlytics.FlutterError
[cloud_firestore/permission-denied] 
The caller does not have permission to execute the specified operation.
Location: EventChannelExtension.receiveGuardedBroadcastStream
```

**Affected Devices:**
- Tecno Pova Curve 5G
- App Version: 1.0.9 (21)
- Occurrences: Multiple events

---

## 🔍 Root Cause Analysis

### **What is This Error?**

`cloud_firestore/permission-denied` means:
- The app is trying to read/write Firestore data
- But the security rules don't allow it
- OR the user is not authenticated
- OR the user doesn't have permission for that specific operation

### **Why It's Happening**

#### **Primary Cause: StreamBuilders Without Auth Checks**

**Problem Location:** `lib/screens/home_screen.dart`

Multiple `StreamBuilder` widgets are querying Firestore **without checking authentication first**:

1. **Line 1529-1533:** Querying `users` collection
   ```dart
   StreamBuilder<QuerySnapshot>(
     stream: FirebaseFirestore.instance
         .collection('users')
         .where('isHost', isEqualTo: true)
         .snapshots(),  // ❌ No auth check!
   ```

2. **Line 1975-1978:** Querying user document
   ```dart
   StreamBuilder<DocumentSnapshot>(
     stream: FirebaseFirestore.instance
         .collection('users')
         .doc(hostId)
         .snapshots(),  // ❌ No auth check!
   ```

3. **Line 2506-2510:** Same as #1
4. **Line 2837-2841:** Same as #1

**Firestore Security Rules:**
```javascript
match /users/{userId} {
  allow read: if request.auth != null;  // ✅ Requires authentication
}
```

**The Problem:**
- `StreamBuilder` executes in `build()` method
- If user is not authenticated → Permission denied
- Error propagates through event channel → **Fatal crash**

---

## 📍 Code Locations Causing Issues

### **1. Home Screen - Explore Tab**

**File:** `lib/screens/home_screen.dart` (Line 1529-1533)

**Problem Code:**
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .where('isHost', isEqualTo: true)
      .limit(200)
      .snapshots(),  // ❌ No auth check
  builder: (context, hostsSnapshot) {
    // ...
  },
)
```

**Issue:** Stream starts even if user is not authenticated.

### **2. Home Screen - Live Tab**

**File:** `lib/screens/home_screen.dart` (Line 2506-2510)

**Same issue** - Querying users without auth check.

### **3. Home Screen - Following Tab**

**File:** `lib/screens/home_screen.dart` (Line 2837-2841)

**Same issue** - Querying users without auth check.

### **4. Home Screen - Host Preview**

**File:** `lib/screens/home_screen.dart` (Line 1975-1978)

**Problem Code:**
```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(hostId)
      .snapshots(),  // ❌ No auth check
  builder: (context, userSnapshot) {
    // ...
  },
)
```

---

## ✅ Solution Implementation

### **Solution 1: Add Auth Checks to StreamBuilders (CRITICAL)**

#### **Fix for Home Screen - Explore Tab**

**File:** `lib/screens/home_screen.dart`

**Find (around line 1529):**
```dart
return StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .where('isHost', isEqualTo: true)
      .limit(200)
      .snapshots(),
  builder: (context, hostsSnapshot) {
```

**Replace with:**
```dart
// Check authentication before setting up stream
final currentUser = _auth.currentUser;
if (currentUser == null) {
  // User not authenticated - show login prompt or empty state
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'Please login to view content',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

return StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .where('isHost', isEqualTo: true)
      .limit(200)
      .snapshots(),
  builder: (context, hostsSnapshot) {
    // Handle errors gracefully
    if (hostsSnapshot.hasError) {
      final error = hostsSnapshot.error;
      if (error.toString().contains('permission-denied')) {
        // Permission denied - user might have logged out
        debugPrint('⚠️ Permission denied - user may have logged out');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Access denied. Please login again.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }
      // Other errors
      return Center(
        child: Text('Error: ${hostsSnapshot.error}'),
      );
    }
```

**Apply the same fix to:**
- Line 1975-1978 (Host preview)
- Line 2506-2510 (Live tab)
- Line 2837-2841 (Following tab)

---

### **Solution 2: Create Auth-Aware StreamBuilder Helper**

**File:** `lib/widgets/auth_stream_builder.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// StreamBuilder that checks authentication before setting up stream
/// Prevents permission-denied errors
class AuthStreamBuilder<T> extends StatelessWidget {
  final Stream<T>? stream;
  final Widget Function(BuildContext, AsyncSnapshot<T>) builder;
  final Widget? fallback; // Widget to show when not authenticated

  const AuthStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Check authentication
    if (currentUser == null) {
      return fallback ?? const SizedBox.shrink();
    }
    
    // Check if stream is null
    if (stream == null) {
      return fallback ?? const SizedBox.shrink();
    }
    
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        // Handle permission-denied errors
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          if (error.contains('permission-denied')) {
            debugPrint('⚠️ Permission denied in stream: $error');
            return fallback ?? const SizedBox.shrink();
          }
          // Other errors - show error widget
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        
        // Normal builder
        return builder(context, snapshot);
      },
    );
  }
}
```

---

### **Solution 3: Update All StreamBuilders**

**Replace all problematic StreamBuilders with AuthStreamBuilder:**

**Before:**
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .where('isHost', isEqualTo: true)
      .snapshots(),
  builder: (context, snapshot) {
    // ...
  },
)
```

**After:**
```dart
AuthStreamBuilder<QuerySnapshot>(
  stream: FirebaseAuth.instance.currentUser != null
      ? FirebaseFirestore.instance
          .collection('users')
          .where('isHost', isEqualTo: true)
          .snapshots()
      : null,
  builder: (context, snapshot) {
    // ...
  },
  fallback: Center(
    child: Text('Please login to view content'),
  ),
)
```

---

### **Solution 4: Add Error Handling to Existing Listeners**

**File:** `lib/screens/wallet_screen.dart` (Line 168-179)

**Already has error handling** ✅ - Good!

**File:** `lib/screens/agora_live_stream_screen.dart` (Line 2532-2534)

**Update to handle permission-denied:**
```dart
onError: (error) {
  debugPrint('❌ AgoraLiveStream: Error in balance listener: $error');
  
  // Handle permission-denied gracefully
  if (error.toString().contains('permission-denied')) {
    debugPrint('⚠️ Permission denied - user may have logged out');
    // Don't crash - just stop listening
    _balanceSubscription?.cancel();
    return;
  }
  
  // Other errors - log but don't crash
},
```

---

## 🎯 Implementation Priority

### **🔴 CRITICAL (Do Immediately):**
1. ✅ Add auth checks to Home Screen StreamBuilders
2. ✅ Add error handling for permission-denied
3. ✅ Test with unauthenticated users

### **🟡 HIGH PRIORITY (This Week):**
4. ✅ Create AuthStreamBuilder helper
5. ✅ Update all StreamBuilders across the app
6. ✅ Add error handling to all listeners

---

## 📊 Expected Results

### **Before Fix:**
- ❌ Fatal crashes on permission-denied
- ❌ StreamBuilders run without auth checks
- ❌ Poor error handling

### **After Fix:**
- ✅ Graceful handling of permission errors
- ✅ Auth checks before streams
- ✅ No crashes - app continues working
- ✅ Better user experience

---

## 🧪 Testing Checklist

### **Before Deployment:**
- [ ] Test with unauthenticated user (logout)
- [ ] Test with authenticated user
- [ ] Test with expired auth token
- [ ] Test network errors
- [ ] Verify no crashes in Crashlytics

### **After Deployment:**
- [ ] Monitor Crashlytics for permission-denied errors
- [ ] Check if errors are resolved
- [ ] Monitor user experience

---

## 📝 Summary

### **Root Cause:**
- StreamBuilders querying Firestore without auth checks
- Permission-denied errors causing fatal crashes
- No error handling for permission errors

### **Solution:**
1. Add auth checks before StreamBuilders ✅
2. Add error handling for permission-denied ✅
3. Create AuthStreamBuilder helper ✅
4. Update all StreamBuilders ✅

### **Timeline:**
- **Critical Fix:** 1-2 hours
- **Full Implementation:** 2-3 hours
- **Testing:** 1 hour
- **Total:** 4-6 hours

### **Status:**
🔴 **URGENT** - Fix immediately to prevent user churn

---

**Report Generated By:** Senior Application Developer  
**Date:** Generated on Request  
**Next Steps:** Implement Solution 1-2 immediately
