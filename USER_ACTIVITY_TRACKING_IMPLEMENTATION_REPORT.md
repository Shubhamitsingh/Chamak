# 📊 User Activity Tracking - Complete Implementation Report

**Date:** $(date)  
**Status:** 📝 **IMPLEMENTATION PLAN READY**

---

## 🔍 **Current Situation Analysis**

### **✅ What's Already Working:**

1. **OnlineStatusService Exists** (`lib/services/online_status_service.dart`)
   - ✅ Tracks `lastSeen` timestamp
   - ✅ Updates every 60 seconds while app is active
   - ✅ Updates on app resume (foreground)
   - ✅ Stops tracking when app goes to background
   - ✅ Has `isUserOnline()` method (checks if active within 5 minutes)

2. **App Lifecycle Tracking** (`lib/screens/home_screen.dart`)
   - ✅ Implements `WidgetsBindingObserver`
   - ✅ Updates `lastSeen` when app resumes
   - ✅ Initializes status tracking on app start

3. **Admin Panel Exists** (`lib/screens/admin_panel_screen.dart`)
   - ✅ Flutter-based admin panel
   - ✅ Can search and view users
   - ✅ Shows user details in dialog

### **❌ What's Missing:**

1. **Mobile App:**
   - ❌ Uses `lastSeen` field, but report mentions `lastActive` (need to standardize)
   - ❌ No `lastActive` field being updated
   - ❌ Update interval is 60 seconds (could be optimized to 2-3 minutes)

2. **Admin Panel:**
   - ❌ No users list/table view showing all users
   - ❌ No "Last Active" column display
   - ❌ No relative time formatting ("5 mins ago", "2 hours ago")
   - ❌ No online status indicators (green/gray dots)
   - ❌ No "Currently Active" display

---

## 🎯 **Implementation Requirements**

### **Phase 1: Mobile App Changes (CRITICAL)**

#### **1.1. Standardize Field Name: `lastActive`**

**Current:** App uses `lastSeen`  
**Required:** Use `lastActive` (or keep both for backward compatibility)

**Decision:** Add `lastActive` field alongside `lastSeen` for compatibility.

#### **1.2. Update OnlineStatusService**

**File:** `lib/services/online_status_service.dart`

**Changes Needed:**

1. **Add `lastActive` field update:**
```dart
/// Update lastActive timestamp for current user
Future<void> updateLastActive(String userId) async {
  try {
    await _firestore.collection('users').doc(userId).update({
      'lastActive': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(), // Keep for backward compatibility
    });
  } catch (e) {
    debugPrint('⚠️ Failed to update lastActive for $userId: $e');
  }
}
```

2. **Update method calls:**
   - Change `updateLastSeen()` calls to `updateLastActive()`
   - Or create wrapper that updates both

3. **Optimize update interval:**
   - Current: 60 seconds
   - Recommended: 2-3 minutes (120-180 seconds) to reduce Firebase writes

**Code Changes:**
```dart
// Line 18: Change update interval
static const Duration _updateInterval = Duration(minutes: 2); // Changed from 60 seconds

// Line 54-63: Update method to set both fields
Future<void> updateLastActive(String userId) async {
  try {
    await _firestore.collection('users').doc(userId).update({
      'lastActive': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(), // Backward compatibility
    });
  } catch (e) {
    debugPrint('⚠️ Failed to update lastActive for $userId: $e');
  }
}

// Line 28: Update initialization call
await updateLastActive(userId); // Changed from updateLastSeen

// Line 40: Update periodic update call
await updateLastActive(userId); // Changed from updateLastSeen
```

#### **1.3. Update Home Screen Lifecycle Handler**

**File:** `lib/screens/home_screen.dart`

**Changes Needed:**

**Line 238:** Update to use `updateLastActive()`:
```dart
case AppLifecycleState.resumed:
  // App came to foreground - update status immediately
  _onlineStatusService.updateLastActive(userId); // Changed from updateLastSeen
  _onlineStatusService.initializeStatusTracking();
  break;
```

#### **1.4. Update Database Service (Optional)**

**File:** `lib/services/database_service.dart`

**Add `lastActive` to user creation:**
```dart
// Line 85-102: Add lastActive to new user creation
await _usersCollection.doc(userId).set({
  'userId': userId,
  'numericUserId': numericId,
  'phoneNumber': phoneNumber,
  'countryCode': countryCode,
  'displayName': null,
  'photoURL': generated,
  'createdAt': FieldValue.serverTimestamp(),
  'lastLogin': FieldValue.serverTimestamp(),
  'lastActive': FieldValue.serverTimestamp(), // ✅ ADD THIS
  'isActive': false,
  // ... rest of fields
});
```

---

### **Phase 2: Admin Panel Improvements**

#### **2.1. Create Users List View**

**File:** `lib/screens/admin_panel_screen.dart`

**Add new tab or section for "Users List":**

```dart
// Add to TabBar (around line 330)
Tab(
  icon: const Icon(Icons.people, size: 20),
  child: const Text('Users'),
),
```

**Create Users List Widget:**

```dart
Widget _buildUsersListTab() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .orderBy('lastActive', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('No users found'));
      }
      
      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          final userDoc = snapshot.data!.docs[index];
          final userData = userDoc.data() as Map<String, dynamic>;
          final lastActive = userData['lastActive'] as Timestamp?;
          
          return _buildUserListTile(userDoc.id, userData, lastActive);
        },
      );
    },
  );
}
```

#### **2.2. Create User List Tile with Activity Display**

```dart
Widget _buildUserListTile(String userId, Map<String, dynamic> userData, Timestamp? lastActive) {
  final displayName = userData['displayName'] ?? 'No Name';
  final phoneNumber = userData['phoneNumber'] ?? 'N/A';
  final numericId = userData['numericUserId'] ?? 'N/A';
  final isActive = userData['isActive'] ?? false;
  
  // Get activity status
  final activityStatus = _getActivityStatus(lastActive);
  final activityDisplay = _getActivityDisplay(lastActive);
  
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: userData['photoURL'] != null
                ? NetworkImage(userData['photoURL'])
                : null,
            child: userData['photoURL'] == null
                ? Text(numericId.substring(0, 1))
                : null,
          ),
          // Online status indicator
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: activityStatus['color'],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: $numericId | Phone: $phoneNumber'),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                activityStatus['icon'],
                size: 14,
                color: activityStatus['color'],
              ),
              const SizedBox(width: 4),
              Text(
                activityDisplay,
                style: TextStyle(
                  color: activityStatus['color'],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: isActive
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.cancel, color: Colors.red),
      onTap: () {
        _selectUser(userData);
      },
    ),
  );
}
```

#### **2.3. Create Activity Status Helper Methods**

```dart
/// Get activity status (online, offline)
Map<String, dynamic> _getActivityStatus(Timestamp? lastActive) {
  if (lastActive == null) {
    return {
      'status': 'offline',
      'color': Colors.grey,
      'icon': Icons.circle_outlined,
    };
  }
  
  final now = DateTime.now();
  final lastActiveDate = lastActive.toDate();
  final difference = now.difference(lastActiveDate);
  final minutes = difference.inMinutes;
  
  if (minutes < 5) {
    // Currently Active (green)
    return {
      'status': 'online',
      'color': Colors.green,
      'icon': Icons.circle,
    };
  } else {
    // Not Active (gray)
    return {
      'status': 'offline',
      'color': Colors.grey,
      'icon': Icons.circle_outlined,
    };
  }
}

/// Get human-readable activity display
String _getActivityDisplay(Timestamp? lastActive) {
  if (lastActive == null) {
    return 'Never active';
  }
  
  final now = DateTime.now();
  final lastActiveDate = lastActive.toDate();
  final difference = now.difference(lastActiveDate);
  final minutes = difference.inMinutes;
  final hours = difference.inHours;
  final days = difference.inDays;
  
  if (minutes < 5) {
    return 'Currently Active';
  } else if (minutes < 60) {
    return '$minutes mins ago';
  } else if (hours < 24) {
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  } else if (days < 7) {
    return '$days ${days == 1 ? 'day' : 'days'} ago';
  } else {
    return 'Last seen: ${DateFormat('MM/dd/yyyy').format(lastActiveDate)}';
  }
}
```

#### **2.4. Add Import for DateFormat**

```dart
import 'package:intl/intl.dart'; // Add if not already imported
```

#### **2.5. Update Tab View**

**Find the TabBarView (around line 400-500):**

```dart
TabBarView(
  controller: _tabController,
  children: [
    _buildAddCoinsTab(), // Existing
    _buildSupportChatsTab(), // Existing
    _buildWithdrawalsTab(), // Existing
    _buildTeamMessagesTab(), // Existing
    _buildUsersListTab(), // ✅ ADD THIS NEW TAB
  ],
),
```

---

## 📋 **Step-by-Step Implementation Checklist**

### **Mobile App Changes:**

- [ ] **Step 1:** Update `OnlineStatusService.updateLastSeen()` to also update `lastActive`
- [ ] **Step 2:** Rename method to `updateLastActive()` or create wrapper
- [ ] **Step 3:** Change update interval from 60s to 2-3 minutes
- [ ] **Step 4:** Update `home_screen.dart` to call `updateLastActive()`
- [ ] **Step 5:** Add `lastActive` to new user creation in `database_service.dart`
- [ ] **Step 6:** Test that `lastActive` field updates in Firebase

### **Admin Panel Changes:**

- [ ] **Step 7:** Add "Users" tab to TabBar
- [ ] **Step 8:** Create `_buildUsersListTab()` method
- [ ] **Step 9:** Create `_buildUserListTile()` method
- [ ] **Step 10:** Create `_getActivityStatus()` helper method
- [ ] **Step 11:** Create `_getActivityDisplay()` helper method
- [ ] **Step 12:** Add Users tab to TabBarView
- [ ] **Step 13:** Test users list displays correctly
- [ ] **Step 14:** Test real-time updates when users become active
- [ ] **Step 15:** Test activity status indicators (green/gray)

---

## 🔧 **Technical Details**

### **Firebase Field Structure:**

```javascript
// User document in Firebase
{
  userId: string,
  displayName: string,
  phoneNumber: string,
  numericUserId: string,
  lastActive: Timestamp,  // ✅ NEW FIELD
  lastSeen: Timestamp,    // Keep for backward compatibility
  lastLogin: Timestamp,   // Existing
  isActive: boolean,
  // ... other fields
}
```

### **Time Thresholds:**

- **Currently Active (🟢 Green):** < 5 minutes
- **Not Active (⚪ Gray):** ≥ 5 minutes

### **Display Format:**

- **< 5 mins:** "Currently Active"
- **5-60 mins:** "X mins ago"
- **1-24 hours:** "X hours ago"
- **1-7 days:** "X days ago"
- **> 7 days:** "Last seen: MM/dd/yyyy"

### **Performance Considerations:**

- ✅ Update `lastActive` every 2-3 minutes (not on every action)
- ✅ Use Firebase `serverTimestamp()` for accuracy
- ✅ Use Firestore real-time listeners for admin panel
- ✅ Limit users list query (add pagination if needed)

---

## ✅ **Expected Results**

After implementation:

### **Mobile App:**
- ✅ `lastActive` field updates every 2-3 minutes while app is active
- ✅ `lastActive` updates immediately when app comes to foreground
- ✅ `lastActive` stops updating when app goes to background

### **Admin Panel:**
- ✅ Shows list of all users
- ✅ Displays "Currently Active" for users active in last 5 minutes
- ✅ Shows relative time ("5 mins ago", "2 hours ago")
- ✅ Visual indicators (green/gray dots)
- ✅ Real-time updates when users become active
- ✅ Sorted by `lastActive` (most recent first)

---

## 🚀 **Implementation Priority**

### **High Priority (Must Have):**
1. ✅ Add `lastActive` field updates in mobile app
2. ✅ Create users list view in admin panel
3. ✅ Add activity status display

### **Medium Priority (Should Have):**
1. ⚠️ Add activity status indicators (dots)
2. ⚠️ Optimize update interval (2-3 minutes)

### **Low Priority (Nice to Have):**
1. 📝 Add activity filters (Currently Active, Active Today, etc.)
2. 📝 Add pagination for users list
3. 📝 Add search/filter functionality

---

## 📝 **Files to Modify**

### **Mobile App:**
1. `lib/services/online_status_service.dart` - Add `lastActive` updates
2. `lib/screens/home_screen.dart` - Update lifecycle handler
3. `lib/services/database_service.dart` - Add `lastActive` to new users

### **Admin Panel:**
1. `lib/screens/admin_panel_screen.dart` - Add users list tab and display

---

## 🧪 **Testing Plan**

### **Mobile App Testing:**
1. Open app → Check Firebase: `lastActive` should be set
2. Wait 2-3 minutes → Check Firebase: `lastActive` should update
3. Put app in background → Check Firebase: `lastActive` should stop updating
4. Bring app to foreground → Check Firebase: `lastActive` should update immediately

### **Admin Panel Testing:**
1. Open admin panel → Users tab should show list
2. Check activity status → Should show correct status (green/gray)
3. Check activity display → Should show "Currently Active" or relative time
4. Open app on another device → Admin panel should update in real-time
5. Test with different time ranges → Verify status changes correctly

---

## 📊 **Summary**

### **What Needs to Be Done:**

**Mobile App (3 files):**
1. Update `OnlineStatusService` to track `lastActive`
2. Update `home_screen.dart` lifecycle handler
3. Add `lastActive` to new user creation

**Admin Panel (1 file):**
1. Add Users list tab
2. Create user list display with activity status
3. Add helper methods for activity formatting

### **Estimated Implementation Time:**
- Mobile App Changes: **1-2 hours**
- Admin Panel Changes: **2-3 hours**
- Testing: **1 hour**
- **Total: 4-6 hours**

---

## 🎯 **Next Steps**

1. **Review this report** and confirm approach
2. **Implement mobile app changes** first (Phase 1)
3. **Test mobile app** to verify `lastActive` updates
4. **Implement admin panel changes** (Phase 2)
5. **Test admin panel** to verify display and real-time updates
6. **Deploy and monitor** for any issues

---

**Status:** 📝 **READY FOR IMPLEMENTATION**  
**Date:** $(date)
