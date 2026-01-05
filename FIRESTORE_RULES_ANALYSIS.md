# Firestore Rules Analysis - Problem Identified

## 🔍 Problem Found

Your **security rules are CORRECT** ✅, but your **code is trying to set coin fields** which the rules BLOCK ❌.

---

## ❌ Error 1: User Creation Blocked

### What Your Code Does (database_service.dart lines 112-114):
```dart
await _usersCollection.doc(userId).set({
  // ... other fields ...
  'coins': 0,        // ❌ BLOCKED BY RULES
  'uCoins': 0,       // ❌ BLOCKED BY RULES  
  'cCoins': 0,       // ❌ BLOCKED BY RULES
});
```

### What Your Rule Says (line 19-20):
```javascript
allow create: if request.auth != null 
  && request.auth.uid == userId
  && !request.resource.data.keys().hasAny(['uCoins', 'coins', 'cCoins']);
//                                      ↑ This BLOCKS if these fields exist!
```

**Result:** ❌ **Permission Denied** - Cannot create user with coin fields!

---

## ❌ Error 2: FCM Token Update (Secondary Issue)

The FCM token update should work, but it might fail if:
1. User document doesn't exist (because creation failed above)
2. Or there's a caching issue

The rule for update is:
```javascript
allow update: if request.auth != null 
  && request.auth.uid == userId
  && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['uCoins', 'coins', 'cCoins']);
```

This should allow FCM token updates since it's not touching coin fields. But if user creation failed, the document doesn't exist.

---

## ✅ Solution Options

### **Option 1: Fix the Code (RECOMMENDED - Secure)**

Remove coin fields from user creation/update. Let Cloud Functions or server-side code initialize them.

**Fix `lib/services/database_service.dart`:**

**Line 99-115 (CREATE):**
```dart
await _usersCollection.doc(userId).set({
  'userId': userId,
  'numericUserId': numericId,
  'phoneNumber': phoneNumber,
  'countryCode': countryCode,
  'displayName': null,
  'photoURL': generated,
  'createdAt': FieldValue.serverTimestamp(),
  'lastLogin': FieldValue.serverTimestamp(),
  'isActive': true,
  'followersCount': 0,
  'followingCount': 0,
  'level': 1,
  // REMOVE THESE THREE LINES:
  // 'coins': 0,
  // 'uCoins': 0,
  // 'cCoins': 0,
});
```

**Also check lines 63-77 (UPDATE) - Remove coin initialization there too.**

---

### **Option 2: Change the Rules (NOT RECOMMENDED - Less Secure)**

Allow coin fields to be set to 0 during creation only:

```javascript
allow create: if request.auth != null 
  && request.auth.uid == userId
  && (!request.resource.data.keys().hasAny(['uCoins', 'coins', 'cCoins'])
      || (request.resource.data.get('uCoins', 0) == 0
          && request.resource.data.get('cCoins', 0) == 0
          && request.resource.data.get('coins', 0) == 0));
```

**This is less secure** because it allows users to initialize coins, even if to 0.

---

## 🎯 Recommended Fix

**Option 1 is better** because:
- ✅ More secure (coin fields managed server-side only)
- ✅ Prevents users from manipulating coin values
- ✅ Aligns with your security rules
- ✅ CoinService already handles missing fields (defaults to 0)

---

## Summary

| Issue | Code Location | Rule Location | Solution |
|-------|--------------|---------------|----------|
| User creation sets coins | `database_service.dart:112-114` | Rules line 19-20 | Remove coin fields from `.set()` |
| User update sets coins | `database_service.dart:63-77` | Rules line 23-24 | Remove coin initialization from `.update()` |
| FCM token update fails | `notification_service.dart:175` | Rules line 23-24 | Should work once user creation succeeds |

---

## Quick Fix Command

Would you like me to:
1. ✅ **Fix the code** (remove coin fields from user creation/update) - RECOMMENDED
2. ❌ **Change the rules** (allow coin initialization) - NOT RECOMMENDED

Let me know which option you prefer!
