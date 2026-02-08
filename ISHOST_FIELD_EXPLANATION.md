# 📚 **`isHost` Field - Complete Explanation**

## 🎯 **What is `isHost`?**

`isHost` is a **boolean field** in the `users` collection that indicates whether a user is a **host** (content creator who can go live).

---

## 🔍 **Purpose of `isHost`:**

### **1. Identifies Host Users**
- `isHost: true` = User is a host (can go live)
- `isHost: false` = User is a regular viewer (cannot go live)

### **2. Different from `isActive`**
- **`isHost`** = User is a host (has applied and been approved as host)
- **`isActive`** = User has permission to go live (admin approval status)

### **3. Both Required for Live Streaming**
- To go live, user needs: `isHost: true` AND `isActive: true`
- `isHost: true` = User is a host
- `isActive: true` = User has permission to go live

---

## 📋 **Where `isHost` is Used:**

### **1. Cloud Functions (Backend)**

#### **File:** `functions/index.js`

**Purpose:** Auto-sync approved hosts to `approvedHosts` collection

**Usage:**
```javascript
// When new user is created
if (userData.isHost === true && userData.isActive === true) {
  // Add to approvedHosts collection
}

// When user is updated
if (!before.isActive && after.isActive && after.isHost) {
  // Host approved - add to approvedHosts
}

if (!before.isHost && after.isHost && after.isActive) {
  // User became host - add to approvedHosts
}
```

**Lines:** 1774, 1777, 1824, 1825, 1829, 1830, 1832, 1862, 1864, 1870, 1887, 1889, 1917, 2140, 2148

---

### **2. Home Screen - Host Queries**

#### **File:** `lib/screens/home_screen.dart`

**Purpose:** Filter and display only host profiles in Explore/Following/New tabs

**Usage:**
```dart
// Query only hosts
FirebaseFirestore.instance
  .collection('users')
  .where('isHost', isEqualTo: true)  // ← Only get hosts
  .snapshots()
```

**Lines:** 2653, 3077

**What it does:**
- Shows only users with `isHost: true` in the grid
- Regular users (`isHost: false`) are not shown

---

### **3. Chat Screens - Level Badge Display**

#### **Files:** 
- `lib/screens/chat_screen.dart`
- `lib/screens/messages_screen.dart`
- `lib/screens/chat_list_screen.dart`

**Purpose:** Show level badge only for hosts

**Usage:**
```dart
// Get isHost from user data
bool isHost = userData?['isHost'] ?? false;

// Show level badge only if user is host
if (isHost) {
  // Display level badge
}
```

**Lines:**
- `chat_screen.dart`: 249, 255, 258, 259
- `messages_screen.dart`: 558, 572, 581
- `chat_list_screen.dart`: 716, 724, 729

**What it does:**
- Hosts see their level badge in chat
- Regular users don't see level badge

---

### **4. Call Requests - Coin Deduction Logic**

#### **Files:**
- `lib/screens/chat_screen.dart`
- `lib/screens/user_profile_view_screen.dart`
- `lib/screens/chat_list_screen.dart`

**Purpose:** Hosts don't pay coins for video calls (only viewers pay)

**Usage:**
```dart
// When sending call request
CallRequestModel(
  callerId: currentUser.uid,
  receiverId: receiverId,
  isHost: false,  // Caller is not host (pays coins)
  // ...
)

// When receiving call request
CallRequestModel(
  receiverId: receiverId,
  isHost: true,  // Receiver is host (doesn't pay coins)
  // ...
)
```

**Lines:**
- `chat_screen.dart`: 1320, 1350, 1462, 1711
- `user_profile_view_screen.dart`: 543, 573, 685, 934
- `chat_list_screen.dart`: 331

**What it does:**
- Viewers pay coins to call hosts
- Hosts don't pay coins (they receive calls)

---

### **5. Host Application Service**

#### **File:** `lib/services/host_application_service.dart`

**Purpose:** Set `isHost: true` when admin approves host application

**Usage:**
```dart
// When admin approves host application
await _firestore.collection('users').doc(application.userId).update({
  'isHost': true,        // ← Sets isHost to true
  'isActive': true,      // ← Sets isActive to true
  'hostApprovedAt': FieldValue.serverTimestamp(),
  'hostApplicationId': applicationId,
});
```

**What it does:**
- When admin approves a host application, sets `isHost: true`
- This makes the user a host

---

### **6. Migration Scripts**

#### **Files:**
- `functions/migrateApprovedHosts.js`
- `functions/index.js` (migrateApprovedHosts function)

**Purpose:** Find all approved hosts for migration

**Usage:**
```javascript
// Find all users with isHost=true AND isActive=true
.where('isHost', '==', true)
.where('isActive', '==', true)
```

**What it does:**
- Migrates only users who are hosts AND approved
- Regular users are not migrated

---

### **7. Home Screen - Default Values**

#### **File:** `lib/screens/home_screen.dart`

**Purpose:** Set default `isHost: false` for new users

**Usage:**
```dart
// When creating user data
isHost: false,  // Default: user is not a host
```

**Lines:** 1724, 1967, 2784, 2977, 3186, 3379, 3449, 3953

**What it does:**
- New users are created with `isHost: false`
- They become hosts only after admin approval

---

## 🔄 **How `isHost` is Set:**

### **1. Default Value:**
- New users: `isHost: false` (not a host)

### **2. When Admin Approves Host Application:**
- Admin approves application → `isHost: true`
- Location: `lib/services/host_application_service.dart`

### **3. When Admin Manually Sets:**
- Admin can manually set `isHost: true` in Firestore
- (Not common, usually done through host application)

---

## 📊 **Relationship: `isHost` vs `isActive`:**

| Field | Purpose | When Set |
|-------|---------|----------|
| **`isHost`** | User is a host (content creator) | When admin approves host application |
| **`isActive`** | User has permission to go live | When admin approves account for live streaming |

### **Combinations:**

| `isHost` | `isActive` | Meaning |
|----------|------------|---------|
| `false` | `false` | Regular user, not approved |
| `false` | `true` | Regular user, approved (but not a host) |
| `true` | `false` | Host, but not approved to go live |
| `true` | `true` | ✅ **Host approved to go live** |

**To go live:** User needs BOTH `isHost: true` AND `isActive: true`

---

## 🎯 **Summary:**

### **Why `isHost` is Used:**
1. ✅ **Identify hosts** - Separate hosts from regular users
2. ✅ **Filter queries** - Show only hosts in Explore menu
3. ✅ **Display features** - Show level badges for hosts
4. ✅ **Coin logic** - Hosts don't pay for calls
5. ✅ **Auto-sync** - Add approved hosts to `approvedHosts` collection

### **Where It's Used:**
1. ✅ **Cloud Functions** - Auto-sync logic
2. ✅ **Home Screen** - Host queries and filtering
3. ✅ **Chat Screens** - Level badge display
4. ✅ **Call Requests** - Coin deduction logic
5. ✅ **Host Application** - Set when approved
6. ✅ **Migration Scripts** - Find approved hosts

---

## 💡 **Key Points:**

1. **`isHost`** = User is a host (content creator)
2. **`isActive`** = User has permission to go live
3. **Both required** = User can go live
4. **Set automatically** = When admin approves host application
5. **Used everywhere** = To identify and filter hosts

---

## ✅ **Conclusion:**

`isHost` is a **critical field** that:
- Identifies which users are hosts
- Controls what features hosts can access
- Determines who appears in host listings
- Affects coin payment logic
- Triggers auto-sync to `approvedHosts` collection

**Without `isHost: true`, a user cannot:**
- Appear in Explore menu as a host
- Have their level badge shown
- Be added to `approvedHosts` collection
- Be treated as a host in the system

**It's the foundation of the host system!** 🎯
