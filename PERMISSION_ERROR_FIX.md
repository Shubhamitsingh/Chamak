# ✅ Permission Denied Error - Fix Guide

## 🔍 Problem Identified

**Error:**
```
❌ Error saving profile: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

**Location:** Profile update operation  
**Root Cause:** Firestore security rules in Firebase might be different from local file, or rules need to be deployed.

---

## ✅ Solution

### Step 1: Verify Rules Match

The local `firestore.rules` file has the correct rules, but they need to match what's deployed in Firebase.

**Option A: Deploy Local Rules to Firebase (RECOMMENDED)**

If you have Firebase CLI installed:

```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"
firebase deploy --only firestore:rules
```

**Option B: Copy Rules to Firebase Console (MANUAL)**

1. Open `firestore.rules` file (in your project root)
2. Copy ALL the content
3. Go to Firebase Console: https://console.firebase.google.com/project/chamak-39472/firestore/rules
4. Click "Edit rules"
5. Paste the rules
6. Click "Publish"

---

## 📋 Rules Verification

Your local `firestore.rules` file contains the correct rules:

**Users Collection - Update Rule (lines 17-18):**
```javascript
allow update: if request.auth != null 
  && request.auth.uid == userId
  && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['uCoins', 'coins', 'cCoins']);
```

This rule should allow:
- ✅ Authenticated users to update their own profile
- ✅ All fields EXCEPT coin fields (`uCoins`, `coins`, `cCoins`)
- ✅ Your code is correct (doesn't set coin fields)

---

## 🎯 What Should Happen After Fix

After deploying the rules:

1. ✅ User profile updates should work
2. ✅ User creation should work (already working based on code)
3. ✅ Coin fields remain protected (server-side only)
4. ✅ All other operations should work as expected

---

## 🔍 Debugging (If Issue Persists)

If the error persists after deploying rules:

### 1. Check Authentication

Verify user is authenticated before update:

```dart
// In database_service.dart - updateUserProfile method
print('🔐 Current user: ${_auth.currentUser?.uid}');
print('📝 Document ID: $currentUserId');
```

### 2. Check Document ID Match

Ensure document ID matches user UID:

```dart
if (_auth.currentUser?.uid != currentUserId) {
  print('❌ UID mismatch! User: ${_auth.currentUser?.uid}, Doc: $currentUserId');
}
```

### 3. Test Simple Update

Try a minimal update to isolate the issue:

```dart
// Test with only lastLogin
await _usersCollection.doc(currentUserId).update({
  'lastLogin': FieldValue.serverTimestamp(),
});
```

---

## 📝 Next Steps

1. ✅ **Deploy rules to Firebase** (using Firebase CLI or Console)
2. ✅ **Test profile update** in the app
3. ✅ **Verify error is resolved**
4. ✅ **If error persists**, check authentication and document ID

---

## 🎯 Summary

**Issue:** Permission denied when updating user profile  
**Root Cause:** Rules in Firebase might not match local file  
**Solution:** Deploy local `firestore.rules` to Firebase  
**Status:** Ready to fix - deploy rules and test

---

**Action Required:** Deploy the rules to Firebase using one of the methods above.
