# 🗄️ Database Setup Roadmap - Unique User ID System

## 📌 Overview

When a user logs in with phone authentication, Firebase automatically creates a **unique User ID (UID)**. We'll use this UID to create and manage user profiles in Cloud Firestore.

---

## 🎯 **What You'll Build**

```
User Login Flow:
1. User enters phone number → OTP sent
2. User enters OTP → Firebase Auth verifies
3. Firebase creates unique UID (e.g., "kJ3mD9xP2QaW...")
4. Check if user exists in Firestore
5. If NEW user → Create user profile in database
6. If EXISTING user → Load their profile
7. Navigate to Home Screen
```

---

## 🛠️ **Step-by-Step Roadmap**

### ✅ **Step 1: Firebase Console Setup** (5 minutes)

#### 1.1 Enable Cloud Firestore
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **chamak-39472**
3. Click **Firestore Database** in left menu
4. Click **Create database**
5. Select **Start in test mode** (for development)
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.time < timestamp.date(2025, 12, 1);
       }
     }
   }
   ```
6. Choose location: **asia-south1** (closest to India)
7. Click **Enable**

#### 1.2 Create Firestore Collections Structure
```
Firestore Structure:
├── users (collection)
│   ├── [UID] (document)
│   │   ├── userId: "kJ3mD9xP2QaW..."
│   │   ├── phoneNumber: "+919876543210"
│   │   ├── countryCode: "+91"
│   │   ├── displayName: null
│   │   ├── photoURL: null
│   │   ├── createdAt: Timestamp
│   │   ├── lastLogin: Timestamp
│   │   ├── isActive: true
│   │   └── metadata: {...}
```

---

### ✅ **Step 2: Update Dependencies** (Already Done! ✅)

Your `pubspec.yaml` already has:
```yaml
firebase_core: ^4.2.0      ✅
firebase_auth: ^6.1.1      ✅
cloud_firestore: ^6.0.3    ✅
```

If not, run:
```bash
flutter pub get
```

---

### ✅ **Step 3: Create User Model** (2 minutes)

Create a Dart class to represent user data:

**File:** `lib/models/user_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String phoneNumber;
  final String countryCode;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;

  UserModel({
    required this.userId,
    required this.phoneNumber,
    required this.countryCode,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      countryCode: data['countryCode'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isActive': isActive,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return UserModel(
      userId: userId,
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}
```

---

### ✅ **Step 4: Create Database Service** (5 minutes)

Create a service to handle all database operations:

**File:** `lib/services/database_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Get current user UID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create or Update User in Firestore
  Future<void> createOrUpdateUser({
    required String phoneNumber,
    required String countryCode,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ No authenticated user found');
        return;
      }

      print('📝 Creating/Updating user: $userId');

      // Check if user already exists
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();

      if (userDoc.exists) {
        // User exists → Update last login
        print('✅ User exists, updating last login');
        await _usersCollection.doc(userId).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      } else {
        // New user → Create profile
        print('✨ New user, creating profile');
        await _usersCollection.doc(userId).set({
          'userId': userId,
          'phoneNumber': phoneNumber,
          'countryCode': countryCode,
          'displayName': null,
          'photoURL': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        print('✅ User profile created successfully');
      }
    } catch (e) {
      print('❌ Error creating/updating user: $e');
      rethrow;
    }
  }

  // Get User Data
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Get Current User Data
  Future<UserModel?> getCurrentUserData() async {
    if (currentUserId == null) return null;
    return getUserData(currentUserId!);
  }

  // Update User Profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (currentUserId == null) return;

      Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;

      await _usersCollection.doc(currentUserId).update(updates);
      print('✅ Profile updated successfully');
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  // Stream User Data (real-time updates)
  Stream<UserModel?> streamUserData(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  // Delete User
  Future<void> deleteUser() async {
    try {
      if (currentUserId == null) return;
      
      // Soft delete (mark as inactive)
      await _usersCollection.doc(currentUserId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      // Or hard delete
      // await _usersCollection.doc(currentUserId).delete();
      
      print('✅ User deleted successfully');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }
}
```

---

### ✅ **Step 5: Update OTP Screen to Save User** (3 minutes)

After successful OTP verification, create the user in Firestore.

**Update:** `lib/screens/otp_screen.dart`

Add these imports at the top:
```dart
import '../services/database_service.dart';
```

Update the `_verifyOTP` method:
```dart
Future<void> _verifyOTP() async {
  if (_otpController.text.length != 6) {
    _showErrorSnackBar('Please enter 6-digit OTP');
    return;
  }

  setState(() { _isVerifying = true; });

  try {
    print('🔐 Verifying OTP: ${_otpController.text}');
    
    // Create credential
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: _otpController.text,
    );

    // Sign in with credential
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    
    print('✅ OTP verified successfully!');
    print('👤 User ID: ${userCredential.user?.uid}');
    
    // Create or update user in Firestore
    final dbService = DatabaseService();
    await dbService.createOrUpdateUser(
      phoneNumber: widget.phoneNumber,
      countryCode: widget.countryCode,
    );
    
    if (!mounted) return;
    
    _showSuccessSnackBar('Login successful!');
    
    // Navigate to home
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
    
  } on FirebaseAuthException catch (e) {
    print('❌ OTP verification failed: ${e.code} - ${e.message}');
    String errorMessage = 'Invalid OTP';
    if (e.code == 'invalid-verification-code') {
      errorMessage = 'Invalid OTP. Please try again';
    } else if (e.code == 'session-expired') {
      errorMessage = 'OTP expired. Please request a new one';
    }
    _showErrorSnackBar(errorMessage);
  } catch (e) {
    print('❌ Unexpected error: $e');
    _showErrorSnackBar('Something went wrong. Please try again');
  } finally {
    if (mounted) {
      setState(() { _isVerifying = false; });
    }
  }
}
```

---

### ✅ **Step 6: Update Account Security Screen** (2 minutes)

Similar update for the "Update Phone Number" flow.

**Update:** `lib/screens/account_security_screen.dart`

Add import:
```dart
import '../services/database_service.dart';
```

In the `codeSent` callback of `_showUpdatePhoneDialog`:
```dart
codeSent: (String verificationId, int? resendToken) async {
  print('✅ OTP sent for phone update!');
  Navigator.pop(context); // Close the dialog
  
  // Navigate to OTP screen
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OtpScreen(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        verificationId: verificationId,
        resendToken: resendToken,
      ),
    ),
  );
  
  // After OTP verification, update user in database
  if (result == true) {
    final dbService = DatabaseService();
    await dbService.updateUserProfile(); // Updates lastLogin
    
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }
},
```

---

### ✅ **Step 7: Security Rules** (IMPORTANT!)

Before going to production, update Firestore security rules:

**Firebase Console → Firestore Database → Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      // Users can read their own data
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Users can create their own profile
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Users can update their own profile
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Users can delete their own profile
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public profiles (optional - for viewing other users)
    match /users/{userId}/public/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

**Test mode expires on the date you set. Switch to production rules before launch!**

---

## 🎯 **Complete Implementation Checklist**

- [ ] Step 1: Enable Cloud Firestore in Firebase Console
- [ ] Step 2: Verify dependencies in pubspec.yaml
- [ ] Step 3: Create `lib/models/user_model.dart`
- [ ] Step 4: Create `lib/services/database_service.dart`
- [ ] Step 5: Update `lib/screens/otp_screen.dart`
- [ ] Step 6: Update `lib/screens/account_security_screen.dart`
- [ ] Step 7: Update Firestore security rules (before production)
- [ ] Test: Login with new phone number → Check Firestore
- [ ] Test: Login with existing number → Verify lastLogin updates

---

## 📊 **Firestore Structure Example**

After implementation, your Firestore will look like:

```
users/
├── kJ3mD9xP2QaW1234567890
│   ├── userId: "kJ3mD9xP2QaW1234567890"
│   ├── phoneNumber: "+919876543210"
│   ├── countryCode: "+91"
│   ├── displayName: null
│   ├── photoURL: null
│   ├── createdAt: October 31, 2025 at 10:30:00 AM
│   ├── lastLogin: October 31, 2025 at 11:45:00 AM
│   └── isActive: true
│
├── xY9zK4mP7QbV0987654321
│   ├── userId: "xY9zK4mP7QbV0987654321"
│   ├── phoneNumber: "+919123456789"
│   ├── countryCode: "+91"
│   ├── displayName: "Shubham"
│   ├── photoURL: "https://..."
│   ├── createdAt: October 30, 2025 at 9:00:00 AM
│   ├── lastLogin: October 31, 2025 at 11:50:00 AM
│   └── isActive: true
```

---

## 🔍 **How to Verify It's Working**

### Test Flow:
1. **Login with new number**
2. **After OTP verification**, open Firebase Console
3. Go to **Firestore Database**
4. You should see:
   - Collection: `users`
   - Document ID: (long random string - this is the UID)
   - Fields: userId, phoneNumber, createdAt, etc.

### Console Logs:
Look for these in your terminal:
```
📝 Creating/Updating user: kJ3mD9xP2QaW...
✨ New user, creating profile
✅ User profile created successfully
```

---

## 🚀 **Future Enhancements**

### Phase 2: User Profiles
- Add username field
- Add bio/description
- Add profile picture upload
- Add followers/following counts

### Phase 3: Streams Data
```
streams/
├── [streamId]
│   ├── hostUserId: "..."
│   ├── title: "..."
│   ├── viewerCount: 123
│   ├── startedAt: Timestamp
│   └── isLive: true
```

### Phase 4: Analytics
```
analytics/
├── dailyLogins/
├── activeUsers/
└── streamStats/
```

---

## 💡 **Best Practices**

1. ✅ **Use Firebase Auth UID** - Already unique, no need to generate custom IDs
2. ✅ **Server Timestamps** - Use `FieldValue.serverTimestamp()` for consistency
3. ✅ **Security Rules** - Always protect user data
4. ✅ **Error Handling** - Catch and log all database errors
5. ✅ **Indexes** - Create indexes for frequently queried fields
6. ✅ **Batch Operations** - Use batch writes for multiple operations
7. ✅ **Offline Persistence** - Enable for better UX

---

## 📚 **Additional Resources**

- [Firebase Auth UID Documentation](https://firebase.google.com/docs/auth/users)
- [Cloud Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Data Modeling](https://firebase.google.com/docs/firestore/manage-data/structure-data)

---

## ✅ **Ready to Implement?**

Just say **"Let's implement database integration"** and I'll:
1. Create all the files
2. Update existing screens
3. Test the implementation
4. Show you how to verify in Firebase Console

Your unique user ID system will be ready in 10 minutes! 🚀





























































