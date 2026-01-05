# 🔍 Comprehensive Analysis - Permission Errors

## Current Errors

1. **FCM Token Save Error:** `users/{userId}` update blocked
2. **Profile Update Error:** `users/{userId}` update blocked

Both errors occur when trying to UPDATE the users collection.

---

## Rules Analysis

### Current Update Rule (Line 17-18):
```javascript
allow update: if request.auth != null 
  && request.auth.uid == userId
  && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['uCoins', 'coins', 'cCoins']);
```

### Code Operations:

**1. FCM Token Update:**
```dart
await _firestore.collection('users').doc(userId).update({
  'fcmToken': token,
  'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
});
```
- Fields: `fcmToken`, `fcmTokenUpdatedAt`
- ✅ Not coin fields
- ✅ Should be allowed

**2. Profile Update:**
```dart
await _usersCollection.doc(currentUserId).update({
  'lastLogin': FieldValue.serverTimestamp(),
  'displayName': displayName,  // optional
  'photoURL': photoURL,         // optional
  // ... other fields
});
```
- Fields: Various profile fields (NOT coin fields)
- ✅ Should be allowed

---

## Potential Issues

### Issue 1: Rule Syntax Problem

The rule uses:
```javascript
request.resource.data.diff(resource.data).affectedKeys()
```

**Problem:** If the document doesn't exist, `resource.data` might be null/undefined, causing the rule to fail.

**Solution:** Need to handle the case where document might not exist yet.

### Issue 2: Rules Not Actually Deployed

Even though user says rules are deployed, they might not be:
- Rules might have syntax errors
- Rules might not have been published successfully
- Rules might be cached

### Issue 3: User Not Authenticated

The rule requires `request.auth != null`, but maybe user isn't authenticated when the update happens?

---

## Next Steps to Diagnose

1. Check if rules actually deployed correctly
2. Check rule syntax for errors
3. Verify user authentication state
4. Test with simpler rules first
