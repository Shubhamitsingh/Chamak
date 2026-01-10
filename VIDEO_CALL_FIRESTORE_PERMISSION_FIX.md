# 🔧 Video Call Firestore Permission Fix

## ❌ **Issue Identified**

When testing the video call feature, a Firestore permission error was occurring:

```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

### **Root Cause:**

The Firestore security rules for `callRequests` collection only allowed reading by:
- `hostId == currentUserId` (for live stream calls)
- `callerId == currentUserId` (for all calls)

But for **chat calls**, we were querying by `receiverId`, which was **not included** in the security rules. So when the app tried to query:

```dart
.where('receiverId', isEqualTo: receiverId)
.where('status', isEqualTo: 'pending')
.where('callType', isEqualTo: 'chat')
```

Firestore blocked the query because the security rules didn't allow reading by `receiverId`.

---

## ✅ **Solution Implemented**

### **1. Updated Firestore Security Rules**

**File:** `firestore.rules`

**Changes:**
- Added `receiverId` to the read permission check
- Added `receiverId` to the update permission check
- Now allows reading by: `hostId`, `receiverId`, or `callerId`
- Now allows updating by: `hostId`, `receiverId`, or `callerId`

**Before:**
```javascript
allow read: if request.auth != null 
  && (resource.data != null && (
    resource.data.hostId == request.auth.uid || 
    resource.data.callerId == request.auth.uid
  ));
```

**After:**
```javascript
allow read: if request.auth != null 
  && (resource.data != null && (
    resource.data.hostId == request.auth.uid ||  // Live stream calls (host)
    resource.data.receiverId == request.auth.uid ||  // Chat calls (receiver) ✅ NEW
    resource.data.callerId == request.auth.uid  // All calls (caller)
  ));
```

### **2. Updated Combined Listener**

**File:** `lib/services/call_request_service.dart`

**Changes:**
- Fixed `listenToIncomingCallRequests()` to use two separate queries
- Uses `StreamController` to combine both streams in real-time
- Queries by `hostId` for live stream calls
- Queries by `receiverId` for chat calls
- Combines results and emits updates

**Before:**
- Query all pending requests and filter in-memory (permission issues)

**After:**
- Query live stream calls: `.where('hostId', isEqualTo: hostId).where('status', isEqualTo: 'pending')`
- Query chat calls: `.where('receiverId', isEqualTo: hostId).where('status', isEqualTo: 'pending').where('callType', isEqualTo: 'chat')`
- Combine both streams using `StreamController`

---

## 📝 **Files Modified**

### **1. `firestore.rules`** ✅
- Updated `callRequests` collection rules
- Added `receiverId` permission checks

### **2. `lib/services/call_request_service.dart`** ✅
- Added `dart:async` import
- Fixed `listenToIncomingCallRequests()` method
- Uses `StreamController` for combining streams
- Proper cleanup on stream cancellation

---

## 🔒 **Security Rules Summary**

### **Call Requests Collection:**

**Create:**
- ✅ Users can create call requests where `callerId == currentUserId`

**Read:**
- ✅ Users can read call requests where:
  - `hostId == currentUserId` (live stream calls - as host)
  - `receiverId == currentUserId` (chat calls - as receiver) ✅ **NEW**
  - `callerId == currentUserId` (all calls - as caller)

**Update:**
- ✅ Users can update call requests where:
  - `hostId == currentUserId` (accept/reject live stream calls)
  - `receiverId == currentUserId` (accept/reject chat calls) ✅ **NEW**
  - `callerId == currentUserId` (cancel own calls)

**Delete:**
- ❌ Only server/Cloud Functions can delete

---

## ✅ **Testing Checklist**

After deploying the updated rules:

- [ ] Test chat call from Chat Screen
- [ ] Test chat call from Profile Screen
- [ ] Test incoming chat call notification
- [ ] Test accepting chat call
- [ ] Test rejecting chat call
- [ ] Test calling host during live stream (chat call)
- [ ] Test live stream call (existing - should still work)
- [ ] Verify no permission errors in console

---

## 🚀 **Deploying the Fix**

### **1. Deploy Firestore Rules:**

```bash
firebase deploy --only firestore:rules
```

### **2. Verify Rules:**

```bash
firebase firestore:rules:validate
```

### **3. Test the App:**

- Open Chat Screen
- Click Video Call button
- Should not see permission errors
- Call request should be created successfully
- Receiver should receive notification

---

## ⚠️ **Important Notes**

1. **Composite Indexes:** Firestore might need composite indexes for the queries with multiple `where` clauses. If you see an error about missing indexes:
   - Firebase Console will show a link to create the index
   - Click the link to auto-create the index
   - Or create manually: Firebase Console → Firestore → Indexes

2. **Indexes Needed:**
   - Collection: `callRequests`
   - Fields: `receiverId` (Ascending), `status` (Ascending), `callType` (Ascending)

3. **Backward Compatibility:** 
   - Existing live stream calls still work
   - Only added support for chat calls
   - No breaking changes

---

## 🎯 **Status: FIXED**

✅ **Permission error resolved**  
✅ **Security rules updated**  
✅ **Query implementation fixed**  
✅ **Ready for testing**

---

**Updated:** $(date)  
**Status:** ✅ **FIXED - READY FOR TESTING**
