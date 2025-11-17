# Firebase Implementation for Chamak App

## 📊 Database Structure (Firestore)

### Recommended Collections:

```
firestore/
├── users/
│   ├── {userId}/
│   │   ├── name: string
│   │   ├── phoneNumber: string
│   │   ├── userId: string
│   │   ├── age: number
│   │   ├── gender: string
│   │   ├── country: string
│   │   ├── city: string
│   │   ├── bio: string
│   │   ├── coinBalance: number
│   │   ├── level: number
│   │   ├── followersCount: number
│   │   ├── followingCount: number
│   │   ├── isHost: boolean
│   │   ├── hostEarnings: number
│   │   ├── createdAt: timestamp
│   │   └── lastUpdated: timestamp
│
├── messages/
│   ├── {conversationId}/
│   │   ├── participants: array
│   │   ├── lastMessage: string
│   │   ├── lastMessageTime: timestamp
│   │   └── messages/ (subcollection)
│   │       ├── {messageId}/
│   │       │   ├── senderId: string
│   │       │   ├── receiverId: string
│   │       │   ├── text: string
│   │       │   ├── timestamp: timestamp
│   │       │   └── read: boolean
│
├── transactions/
│   ├── {transactionId}/
│   │   ├── userId: string
│   │   ├── type: string (recharge/withdrawal)
│   │   ├── amount: number
│   │   ├── coins: number
│   │   ├── status: string
│   │   └── timestamp: timestamp
│
├── resellers/
│   ├── {resellerId}/
│   │   ├── name: string
│   │   ├── rating: number
│   │   ├── verified: boolean
│   │   └── phoneNumber: string
│
└── support_tickets/
    ├── {ticketId}/
        ├── userId: string
        ├── category: string
        ├── description: string
        ├── status: string (open/closed)
        └── createdAt: timestamp
```

---

## 🔧 Implementation Examples

### 1. User Service (`lib/services/user_service.dart`)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Create/Update User Profile
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String phoneNumber,
    int age = 18,
    String gender = 'Male',
    String country = 'India',
    String city = '',
    String bio = '',
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'name': name,
        'phoneNumber': phoneNumber,
        'age': age,
        'gender': gender,
        'country': country,
        'city': city,
        'bio': bio,
        'coinBalance': 0,
        'level': 1,
        'followersCount': 0,
        'followingCount': 0,
        'isHost': false,
        'hostEarnings': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }
  
  // Get User Profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }
  
  // Update Coin Balance
  Future<void> updateCoinBalance(String userId, int coins) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'coinBalance': FieldValue.increment(coins),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update coin balance: $e');
    }
  }
  
  // Update Profile Fields
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['lastUpdated'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
  
  // Listen to User Profile Changes (Real-time)
  Stream<DocumentSnapshot> getUserProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
}
```

---

### 2. Wallet Service (`lib/services/wallet_service.dart`)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Add Coins (Recharge)
  Future<void> addCoins({
    required String userId,
    required int coins,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Start a batch write
      WriteBatch batch = _firestore.batch();
      
      // Update user coin balance
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'coinBalance': FieldValue.increment(coins),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Create transaction record
      DocumentReference transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'type': 'recharge',
        'coins': coins,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add coins: $e');
    }
  }
  
  // Withdraw Earnings (for hosts)
  Future<void> withdrawEarnings({
    required String userId,
    required double amount,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      // Update host earnings
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'hostEarnings': FieldValue.increment(-amount),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Create transaction record
      DocumentReference transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'type': 'withdrawal',
        'amount': amount,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to withdraw earnings: $e');
    }
  }
  
  // Get Transaction History
  Future<List<Map<String, dynamic>>> getTransactionHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get transaction history: $e');
    }
  }
}
```

---

### 3. Message Service (`lib/services/message_service.dart`)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Generate conversation ID (consistent for both users)
  String getConversationId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
  
  // Send Message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      String conversationId = getConversationId(senderId, receiverId);
      
      // Create/update conversation
      await _firestore.collection('messages').doc(conversationId).set({
        'participants': [senderId, receiverId],
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Add message to subcollection
      await _firestore
          .collection('messages')
          .doc(conversationId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
  
  // Get Messages Stream (Real-time)
  Stream<QuerySnapshot> getMessagesStream(String userId1, String userId2) {
    String conversationId = getConversationId(userId1, userId2);
    
    return _firestore
        .collection('messages')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Get All Conversations
  Stream<QuerySnapshot> getConversationsStream(String userId) {
    return _firestore
        .collection('messages')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
  
  // Mark Messages as Read
  Future<void> markAsRead(String userId1, String userId2) async {
    try {
      String conversationId = getConversationId(userId1, userId2);
      
      QuerySnapshot unreadMessages = await _firestore
          .collection('messages')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId1)
          .where('read', isEqualTo: false)
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }
}
```

---

### 4. Support Service (`lib/services/support_service.dart`)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Submit Support Ticket
  Future<String> submitSupportTicket({
    required String userId,
    required String category,
    required String description,
  }) async {
    try {
      DocumentReference ticketRef = await _firestore.collection('support_tickets').add({
        'userId': userId,
        'category': category,
        'description': description,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return ticketRef.id;
    } catch (e) {
      throw Exception('Failed to submit support ticket: $e');
    }
  }
  
  // Get User's Support Tickets
  Future<List<Map<String, dynamic>>> getUserTickets(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('support_tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get support tickets: $e');
    }
  }
}
```

---

## 📱 Usage in Your Screens

### Update Profile Screen:

```dart
import 'package:your_app/services/user_service.dart';

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        // Get current user ID (from Firebase Auth or your auth system)
        String userId = 'current_user_id'; // Replace with actual user ID
        
        await _userService.updateProfile(
          userId: userId,
          data: {
            'name': _nameController.text,
            'age': int.parse(_ageController.text),
            'gender': _selectedGender,
            'country': _selectedCountry,
            'city': _cityController.text,
            'bio': _bioController.text,
          },
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }
}
```

### Update Contact Support Screen:

```dart
import 'package:your_app/services/support_service.dart';

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final SupportService _supportService = SupportService();
  
  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        String userId = 'current_user_id'; // Replace with actual user ID
        
        String ticketId = await _supportService.submitSupportTicket(
          userId: userId,
          category: _selectedCategory,
          description: _concernController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ticket submitted! ID: $ticketId')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }
}
```

---

## 🔐 Security Rules (Production)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users Collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Messages Collection
    match /messages/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      
      match /messages/{messageId} {
        allow read: if request.auth != null && 
          (request.auth.uid == resource.data.senderId || 
           request.auth.uid == resource.data.receiverId);
        allow create: if request.auth != null;
      }
    }
    
    // Transactions Collection
    match /transactions/{transactionId} {
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    
    // Support Tickets Collection
    match /support_tickets/{ticketId} {
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    
    // Resellers Collection (Read-only for users)
    match /resellers/{resellerId} {
      allow read: if request.auth != null;
    }
  }
}
```

---

## ✅ Quick Implementation Checklist

- [ ] Install Firebase CLI and FlutterFire CLI
- [ ] Run `flutterfire configure`
- [ ] Add Firebase dependencies to `pubspec.yaml`
- [ ] Initialize Firebase in `main.dart`
- [ ] Create service files (user, wallet, message, support)
- [ ] Update screens to use Firebase services
- [ ] Test in development mode
- [ ] Set up security rules
- [ ] Test authentication flow
- [ ] Test all CRUD operations
- [ ] Deploy security rules to production

---

**Ready to start? Follow the FIREBASE_SETUP_GUIDE.md first!**
















































































