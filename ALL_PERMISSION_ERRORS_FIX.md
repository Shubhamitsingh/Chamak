# ✅ All Permission Errors - Complete Fix Guide

## 🔍 Two Permission Errors Found

### Error 1: FCM Token Save
```
❌ Error saving FCM token to Firestore: [cloud_firestore/permission-denied] 
The caller does not have permission to execute the specified operation.
```

**Location:** `lib/services/notification_service.dart` line 175-178  
**Operation:** Updating `fcmToken` field in users collection  
**Code:**
```dart
await _firestore.collection('users').doc(userId).update({
  'fcmToken': token,
  'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
});
```

### Error 2: Profile Update
```
❌ Error saving profile: [cloud_firestore/permission-denied] 
The caller does not have permission to execute the specified operation.
```

**Location:** `lib/services/database_service.dart` - `updateUserProfile()` method  
**Operation:** Updating user profile fields (displayName, photoURL, bio, etc.)

---

## ✅ Root Cause

**The rules in Firebase Console are different from your local `firestore.rules` file!**

Your local `firestore.rules` file has the correct rules that should allow:
- ✅ FCM token updates (`fcmToken` is NOT a coin field)
- ✅ Profile updates (all fields except coin fields)

But the rules deployed in Firebase Console are blocking these operations.

---

## 🎯 Solution

### Deploy Local Rules to Firebase

Your local `firestore.rules` file has the correct rules. They just need to be deployed to Firebase.

#### Option 1: Using Firebase CLI (RECOMMENDED)

```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"
firebase deploy --only firestore:rules
```

#### Option 2: Manual Copy (If CLI Not Available)

1. **Open** `firestore.rules` file in your project root
2. **Copy ALL** the content (Ctrl+A, Ctrl+C)
3. **Go to Firebase Console:**
   - URL: https://console.firebase.google.com/project/chamak-39472/firestore/rules
4. **Click** "Edit rules" button
5. **Paste** the rules (Ctrl+V)
6. **Click** "Publish" button

---

## 📋 Rules Verification

Your local `firestore.rules` file contains the correct rules:

**Users Collection - Update Rule (lines 17-18):**
```javascript
allow update: if request.auth != null 
  && request.auth.uid == userId
  && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['uCoins', 'coins', 'cCoins']);
```

This rule allows:
- ✅ Authenticated users to update their own profile
- ✅ All fields EXCEPT coin fields (`uCoins`, `coins`, `cCoins`)
- ✅ FCM token updates (`fcmToken` is NOT a coin field)
- ✅ Profile updates (displayName, photoURL, bio, etc.)

---

## 🎯 What Will Be Fixed

After deploying the rules:

1. ✅ **FCM Token Updates** - Will work (token is saved on login)
2. ✅ **Profile Updates** - Will work (user can edit profile)
3. ✅ **User Creation** - Should already work (from login)
4. ✅ **Coin Fields** - Still protected (server-side only)

---

## 📝 Summary

| Error | Location | Operation | Fix |
|-------|----------|-----------|-----|
| FCM Token | `notification_service.dart:175` | Update `fcmToken` | Deploy rules |
| Profile Update | `database_service.dart:170` | Update profile | Deploy rules |

**Both errors have the same root cause:** Rules in Firebase don't match local file  
**Both errors have the same solution:** Deploy local rules to Firebase

---

## 🚀 Next Steps

1. ✅ **Deploy rules** using one of the methods above
2. ✅ **Test FCM token** - Check if it saves without error
3. ✅ **Test profile update** - Try editing profile
4. ✅ **Verify both work** - Both operations should succeed

---

**Status:** Ready to fix - Deploy rules to Firebase! 🎯
