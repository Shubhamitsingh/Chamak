# Profile Settings Page - Quick Implementation Guide

## 🎯 Objective
Add a Profile Settings Page between Profile Page and Edit Profile Page to improve app organization and user experience.

---

## 📋 Current vs Proposed Flow

### Current Flow
```
Profile Page → Edit Profile Page
```

### Proposed Flow
```
Profile Page → Profile Settings Page → Edit Profile Page
```

---

## 🚀 Quick Implementation Steps

### Step 1: Create Profile Settings Screen
**File**: `lib/screens/profile_settings_screen.dart` (NEW)

**Key Components:**
- AppBar with back button
- Profile preview (picture, name, ID)
- Settings list with "Edit Profile" option
- Navigation to EditProfileScreen

### Step 2: Update Profile Screen Navigation
**File**: `lib/screens/profile_screen.dart` (MODIFY)

**Location**: Line 533  
**Change**: Replace `EditProfileScreen` with `ProfileSettingsScreen`

**Before:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditProfileScreen(
      phoneNumber: widget.phoneNumber,
    ),
  ),
);
```

**After:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProfileSettingsScreen(
      phoneNumber: widget.phoneNumber,
    ),
  ),
);
```

### Step 3: Add Import
**File**: `lib/screens/profile_screen.dart`

Add at top:
```dart
import 'profile_settings_screen.dart';
```

---

## 📁 Files Summary

### Files to Create: 1
- ✅ `lib/screens/profile_settings_screen.dart`

### Files to Modify: 1
- ✅ `lib/screens/profile_screen.dart` (line 533 + import)

### Files Unchanged: 1
- ✅ `lib/screens/edit_profile_screen.dart` (NO CHANGES)

---

## 💻 Minimal Code Template

### Profile Settings Screen Structure
```dart
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String phoneNumber;
  
  const ProfileSettingsScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _databaseService.getCurrentUserData();
      if (mounted) {
        setState(() {
          _user = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF1B7C),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfilePreview(),
                  _buildSettingsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfilePreview() {
    if (_user == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: _user!.photoURL != null && _user!.photoURL!.isNotEmpty
                ? NetworkImage(_user!.photoURL!)
                : null,
            child: _user!.photoURL == null || _user!.photoURL!.isEmpty
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            _user!.displayName ?? 'User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${_user!.numericUserId}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        _buildSettingItem(
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  phoneNumber: widget.phoneNumber,
                ),
              ),
            ).then((_) {
              _loadUserData(); // Refresh after returning
            });
          },
        ),
        const Divider(height: 1),
        // Add more settings items here as needed
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700], size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: Colors.grey[600],
      ),
      onTap: onTap,
    );
  }
}
```

---

## ✅ Checklist

### Implementation
- [ ] Create `profile_settings_screen.dart`
- [ ] Update `profile_screen.dart` navigation (line 533)
- [ ] Add import statement
- [ ] Test navigation flow

### Testing
- [ ] Profile → Settings navigation works
- [ ] Settings → Edit Profile navigation works
- [ ] Back navigation works correctly
- [ ] Data refreshes after editing
- [ ] Loading states work
- [ ] Error handling works

---

## 🎨 UI Requirements

### Colors
- Background: White
- Accent: Pink (`Color(0xFFFF1B7C)`)
- Text: Black87
- Secondary Text: Grey600

### Layout
- Profile preview at top (centered)
- Settings list below
- Dividers between sections
- Icons on left, arrows on right

---

## 📊 What Changes vs What Stays

### ✅ Changes
- Navigation path: Profile → Settings → Edit
- New screen: ProfileSettingsScreen
- Profile screen navigation code

### ✅ Stays the Same
- Edit Profile Screen (no changes)
- All Edit Profile functionality
- All data handling
- All form validation
- All save operations

---

## 🔍 Key Code Locations

### Current Edit Navigation
**File**: `lib/screens/profile_screen.dart`  
**Line**: 533  
**Method**: Inside `_buildProfileHeader()`

### Edit Profile Screen
**File**: `lib/screens/edit_profile_screen.dart`  
**Status**: No changes needed

---

## 🚨 Important Notes

1. **No Breaking Changes**: All existing functionality remains intact
2. **Same Parameters**: Continue using `phoneNumber` parameter
3. **Refresh Callbacks**: Implement refresh after returning from Edit Profile
4. **Error Handling**: Handle null user data gracefully
5. **Loading States**: Show loading indicator while fetching data

---

## 📚 Related Documentation

- **Full Report**: `PROFILE_SETTINGS_PAGE_IMPLEMENTATION_REPORT.md`
- **Flow Diagrams**: `PROFILE_SETTINGS_FLOW_DIAGRAM.md`
- **This Guide**: `PROFILE_SETTINGS_QUICK_IMPLEMENTATION_GUIDE.md`

---

## 🎯 Success Criteria

✅ Navigation works correctly  
✅ No breaking changes  
✅ UI looks professional  
✅ Data refreshes properly  
✅ All existing features work  

---

**Quick Reference Guide**  
**Created**: February 17, 2026  
**Status**: Ready for Implementation
