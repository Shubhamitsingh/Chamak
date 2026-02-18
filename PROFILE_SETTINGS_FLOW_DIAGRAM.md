# Profile Settings Page - Flow Diagram & Visual Guide

## 🔄 Navigation Flow Comparison

### BEFORE (Current Flow)
```
┌─────────────────────────────────────────────────────────────┐
│                    CURRENT FLOW                              │
└─────────────────────────────────────────────────────────────┘

    ┌─────────────────┐
    │  Profile Page    │
    │                 │
    │  [Profile Pic]  │
    │  Name           │
    │  ID: 1234567    │
    │  Location       │
    │            [→]  │ ← Edit Icon (arrow_forward_ios)
    └────────┬────────┘
             │
             │ User taps edit icon
             │
             ▼
    ┌─────────────────────┐
    │  Edit Profile Page   │
    │                     │
    │  Photo              │
    │  Name               │
    │  Gender             │
    │  Birthday           │
    │  Country/Region     │
    │  Bio                │
    │  Social Links       │
    │  Panels             │
    └─────────────────────┘
```

### AFTER (Proposed Flow)
```
┌─────────────────────────────────────────────────────────────┐
│                    PROPOSED FLOW                            │
└─────────────────────────────────────────────────────────────┘

    ┌─────────────────┐
    │  Profile Page    │
    │                 │
    │  [Profile Pic]  │
    │  Name           │
    │  ID: 1234567    │
    │  Location       │
    │            [→]  │ ← Edit Icon (arrow_forward_ios)
    └────────┬────────┘
             │
             │ User taps edit icon
             │
             ▼
    ┌──────────────────────────┐
    │ Profile Settings Page     │
    │                          │
    │  [Profile Preview]       │
    │  Name                    │
    │  ID: 12345665            │
    │                          │
    │  ──────────────────────  │
    │                          │
    │  ✏️ Edit Profile      →  │
    │  👤 Account Settings  →  │
    │  🔒 Privacy Settings  →  │
    │  🔔 Notifications     →  │
    │  🌐 Language          →  │
    │  ℹ️ About             →  │
    │  ❓ Help & Support    →  │
    │  🚪 Logout            →  │
    └────────┬─────────────────┘
             │
             │ User taps "Edit Profile"
             │
             ▼
    ┌─────────────────────┐
    │  Edit Profile Page   │
    │                     │
    │  Photo              │
    │  Name               │
    │  Gender             │
    │  Birthday           │
    │  Country/Region     │
    │  Bio                │
    │  Social Links       │
    │  Panels             │
    └─────────────────────┘
```

---

## 📱 Screen Layouts

### Profile Page (Current)
```
┌──────────────────────────────────────────────┐
│                                              │
│  ┌────────┐  Name                    [→]    │
│  │ Avatar │  ID: 1234567                    │
│  └────────┘  📍 City, Country               │
│              🌐 Language                     │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  👥 13 Followers  👤 10 Following  ⭐ Level │
│                                              │
│  [Banner Slider]                            │
│                                              │
│  [Menu Options]                              │
│                                              │
└──────────────────────────────────────────────┘
```

### Profile Settings Page (New)
```
┌──────────────────────────────────────────────┐
│ ← Profile Settings                           │
├──────────────────────────────────────────────┤
│                                              │
│            ┌─────────┐                      │
│            │ Profile │                      │
│            │ Picture │                      │
│            └─────────┘                      │
│                                              │
│            User Name                         │
│            ID: 12345665                      │
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  ✏️  Edit Profile                      →   │
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  👤 Account Settings                    →   │
│                                              │
│  🔒 Privacy Settings                    →   │
│                                              │
│  🔔 Notification Settings                →   │
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  🌐 Language                            →   │
│                                              │
│  ℹ️  About                              →   │
│                                              │
│  ❓ Help & Support                      →   │
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  🚪 Logout                              →   │
│                                              │
└──────────────────────────────────────────────┘
```

### Edit Profile Page (Unchanged)
```
┌──────────────────────────────────────────────┐
│ ← Edit Profile                               │
├──────────────────────────────────────────────┤
│                                              │
│  Photo                                      │
│  ┌────┐ ┌────┐ [+][+][+][+]                │
│  │Av  │ │Ph2 │                              │
│  └────┘ └────┘                              │
│                                              │
│  Profile Details                            │
│  ─────────────────────────────────────────  │
│                                              │
│  Name          RBS STREMRE              >   │
│                                              │
│  Gender        [Male Icon]              >   │
│                                              │
│  Birthday                            >   │
│                                              │
│  Country/Region [🇮🇳]                 >   │
│                                              │
│  Bio                                 >   │
│                                              │
│  Social Links                        >   │
│                                              │
│  Panels                              >   │
│                                              │
│  [Save Button]                              │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 🔀 Navigation State Diagram

```
                    ┌──────────────┐
                    │ Profile Page │
                    └──────┬───────┘
                           │
                           │ tap edit icon
                           │
                           ▼
            ┌──────────────────────────┐
            │ Profile Settings Page    │
            └──────┬───────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
        │          │          │
        ▼          ▼          ▼
    ┌──────┐  ┌──────┐  ┌──────┐
    │ Edit │  │ Acct │  │ Priv │
    │ Prof │  │ Set  │  │ Set  │
    └──┬───┘  └──────┘  └──────┘
       │
       │ tap "Edit Profile"
       │
       ▼
┌──────────────┐
│ Edit Profile │
│    Page      │
└──────────────┘
```

---

## 📊 Component Hierarchy

### Profile Settings Screen Structure
```
ProfileSettingsScreen
├── AppBar
│   ├── Back Button
│   └── Title: "Profile Settings"
│
├── Body (SingleChildScrollView)
│   ├── ProfilePreview Section
│   │   ├── CircleAvatar (Profile Picture)
│   │   ├── Text (User Name)
│   │   └── Text (User ID)
│   │
│   └── SettingsList Section
│       ├── EditProfileItem
│       │   ├── Icon (edit_outlined)
│       │   ├── Text ("Edit Profile")
│       │   └── Icon (arrow_forward_ios)
│       │
│       ├── Divider
│       │
│       ├── AccountSettingsItem
│       ├── PrivacySettingsItem
│       ├── NotificationSettingsItem
│       ├── Divider
│       ├── LanguageItem
│       ├── AboutItem
│       ├── HelpItem
│       ├── Divider
│       └── LogoutItem
```

---

## 🎨 UI Component Specifications

### Profile Preview Card
```
┌─────────────────────────────┐
│                             │
│        ┌─────────┐         │
│        │ Profile │         │
│        │ Picture │         │
│        └─────────┘         │
│                             │
│        User Name            │
│        ID: 12345665         │
│                             │
└─────────────────────────────┘

Properties:
- Padding: 20px all sides
- Profile Picture: 100x100px circle
- Name: 20px, Bold, Black
- ID: 14px, Regular, Grey
- Alignment: Center
```

### Settings List Item
```
┌─────────────────────────────────────┐
│  [Icon]  Setting Name            →  │
└─────────────────────────────────────┘

Properties:
- Height: 56px
- Padding: 16px horizontal, 12px vertical
- Icon Size: 24px
- Icon Color: Grey[700]
- Text: 16px, Medium, Black
- Arrow: 18px, Grey[600]
- Background: White
- Tap Effect: Ripple
```

### Divider
```
───────────────────────────────────────

Properties:
- Height: 1px
- Color: Grey[300]
- Margin: 8px vertical
```

---

## 🔄 Data Flow

### Loading User Data
```
ProfileSettingsScreen.initState()
    │
    ├─> _loadUserData()
    │       │
    │       ├─> DatabaseService.getCurrentUserData()
    │       │
    │       └─> setState({ _user = userData })
    │
    └─> build() → Display user data
```

### Navigation Flow
```
User Action: Tap Edit Icon
    │
    ├─> ProfileScreen._buildProfileHeader()
    │       │
    │       └─> Navigator.push(ProfileSettingsScreen)
    │
User Action: Tap "Edit Profile"
    │
    ├─> ProfileSettingsScreen._buildSettingsList()
    │       │
    │       └─> Navigator.push(EditProfileScreen)
    │
User Action: Save Changes
    │
    ├─> EditProfileScreen._saveProfile()
    │       │
    │       ├─> DatabaseService.updateUserProfile()
    │       │
    │       └─> Navigator.pop()
    │
User Action: Back Button
    │
    ├─> EditProfileScreen → ProfileSettingsScreen
    │       │
    │       └─> ProfileSettingsScreen._loadUserData() (refresh)
    │
    └─> ProfileSettingsScreen → ProfileScreen
            │
            └─> ProfileScreen.setState() (refresh)
```

---

## ✅ Implementation Checklist

### Phase 1: Create Profile Settings Screen
- [ ] Create `profile_settings_screen.dart`
- [ ] Implement AppBar with back button
- [ ] Add profile preview section
- [ ] Create settings list structure
- [ ] Add "Edit Profile" option
- [ ] Implement navigation to EditProfileScreen
- [ ] Add loading state
- [ ] Add error handling

### Phase 2: Update Profile Screen
- [ ] Import `profile_settings_screen.dart`
- [ ] Update navigation code (line 533)
- [ ] Test navigation flow
- [ ] Verify refresh callbacks

### Phase 3: Testing
- [ ] Test Profile → Settings navigation
- [ ] Test Settings → Edit Profile navigation
- [ ] Test back navigation
- [ ] Test data refresh
- [ ] Test loading states
- [ ] Test error handling

### Phase 4: Polish
- [ ] Add animations
- [ ] Improve UI spacing
- [ ] Add icons
- [ ] Test on different screen sizes
- [ ] Verify accessibility

---

## 🎯 Key Implementation Points

### 1. Navigation Update Location
**File**: `lib/screens/profile_screen.dart`  
**Line**: 533  
**Change**: Replace `EditProfileScreen` with `ProfileSettingsScreen`

### 2. Profile Settings Screen Location
**File**: `lib/screens/profile_settings_screen.dart`  
**Status**: NEW FILE  
**Purpose**: Intermediate screen between Profile and Edit Profile

### 3. Edit Profile Screen
**File**: `lib/screens/edit_profile_screen.dart`  
**Status**: NO CHANGES  
**Note**: All functionality remains exactly the same

---

## 📝 Code Snippets Reference

### Navigation from Profile Screen
```dart
// Location: lib/screens/profile_screen.dart, line 533
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProfileSettingsScreen(  // Changed from EditProfileScreen
      phoneNumber: widget.phoneNumber,
    ),
  ),
);
```

### Navigation from Profile Settings to Edit Profile
```dart
// Location: lib/screens/profile_settings_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditProfileScreen(
      phoneNumber: widget.phoneNumber,
    ),
  ),
).then((_) {
  _loadUserData(); // Refresh user data
});
```

---

**Document Created**: February 17, 2026  
**Purpose**: Visual guide for Profile Settings Page implementation  
**Status**: Ready for Development
