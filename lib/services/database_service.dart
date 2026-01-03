import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'avatar_service.dart';
import 'id_generator_service.dart';

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

      print('📝 Creating/Updating user in Firestore: $userId');

      // Check if user already exists with timeout
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Database operation timed out. Please check your internet connection.');
        },
      );

      if (userDoc.exists) {
        // User exists → Update last login
        print('✅ User exists, updating last login');
        final data = userDoc.data() as Map<String, dynamic>?;
        final String? existingPhoto = data != null ? (data['photoURL'] as String?) : null;
        final String? existingNumericId = data != null ? (data['numericUserId'] as String?) : null;

        // Generate numeric ID if missing (for existing users)
        String? numericIdToUpdate;
        if (existingNumericId == null || existingNumericId.isEmpty) {
          numericIdToUpdate = IdGeneratorService.generateNumericUserId();
          print('🆔 Generated numeric ID for existing user: $numericIdToUpdate');
        }

        // Check if coin fields exist, initialize if missing
        final hasUCoins = data != null && data.containsKey('uCoins');
        final hasCCoins = data != null && data.containsKey('cCoins');
        final hasCoins = data != null && data.containsKey('coins');
        
        Map<String, dynamic> updateData = {
          if (numericIdToUpdate != null) 'numericUserId': numericIdToUpdate,
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
        };
        
        // Initialize coin fields if missing
        if (!hasUCoins) {
          updateData['uCoins'] = 0;
          print('💰 Initializing uCoins = 0 for existing user');
        }
        if (!hasCCoins) {
          updateData['cCoins'] = 0;
          print('💰 Initializing cCoins = 0 for existing user');
        }
        if (!hasCoins) {
          updateData['coins'] = 0;
          print('💰 Initializing coins = 0 for existing user (legacy field)');
        }
        
        // If no photo set, generate and store a deterministic avatar
        if (existingPhoto == null || existingPhoto.isEmpty) {
          final generated = AvatarService.generateAvatarUrl(userId: userId);
          updateData['photoURL'] = generated;
        }
        
        await _usersCollection.doc(userId).update(updateData).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Database update timed out. Please check your internet connection.');
          },
        );
        print('✅ Last login updated successfully');
      } else {
        // New user → Create profile
        print('✨ New user detected, creating profile...');
        final generated = AvatarService.generateAvatarUrl(userId: userId);
        final numericId = IdGeneratorService.generateNumericUserId();
        print('🆔 Generated numeric ID for new user: $numericId');
        
        await _usersCollection.doc(userId).set({
          'userId': userId,
          'numericUserId': numericId, // Store numeric ID
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
          'coins': 0, // Legacy field (kept for compatibility)
          'uCoins': 0, // User Coins - initialized to 0
          'cCoins': 0, // Host Coins - initialized to 0
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Database creation timed out. Please check your internet connection.');
          },
        );
        print('✅ User profile created successfully in Firestore!');
        print('   Initialized: uCoins = 0, cCoins = 0');
      }
    } catch (e) {
      print('❌ Error creating/updating user in Firestore: $e');
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

  // Update User Profile (all fields)
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? coverURL,
    String? bio,
    int? age,
    String? gender,
    String? country,
    String? city,
    String? language,
  }) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user to update');
        return;
      }

      print('📝 Updating user profile: $currentUserId');

      Map<String, dynamic> updates = {
        'lastLogin': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (coverURL != null) updates['coverURL'] = coverURL;
      if (bio != null) updates['bio'] = bio;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (country != null) updates['country'] = country;
      if (city != null) updates['city'] = city;
      if (language != null) updates['language'] = language;

      await _usersCollection.doc(currentUserId).update(updates);
      print('✅ Profile updated successfully');
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  // Update only profile picture
  Future<void> updateProfilePicture(String photoURL) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user to update');
        return;
      }

      await _usersCollection.doc(currentUserId).update({
        'photoURL': photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      print('✅ Profile picture updated successfully');
    } catch (e) {
      print('❌ Error updating profile picture: $e');
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

  // Stream Current User Data
  Stream<UserModel?> streamCurrentUserData() {
    if (currentUserId == null) {
      return Stream.value(null);
    }
    return streamUserData(currentUserId!);
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

  // Update account approval status (admin only)
  Future<bool> updateAccountApproval({
    required String userId,
    required bool isApproved,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'isActive': isApproved,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('✅ Account approval updated: userId=$userId, isApproved=$isApproved');
      return true;
    } catch (e) {
      print('❌ Error updating account approval: $e');
      return false;
    }
  }

  // Delete User (Soft delete)
  Future<void> deleteUser() async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user to delete');
        return;
      }
      
      // Soft delete (mark as inactive)
      await _usersCollection.doc(currentUserId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ User marked as inactive');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }

  // Permanently delete user (Hard delete)
  Future<void> permanentlyDeleteUser() async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user to delete');
        return;
      }
      
      await _usersCollection.doc(currentUserId).delete();
      print('✅ User permanently deleted from Firestore');
    } catch (e) {
      print('❌ Error permanently deleting user: $e');
      rethrow;
    }
  }

  // Update phone number
  Future<void> updatePhoneNumber({
    required String phoneNumber,
    required String countryCode,
  }) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user to update');
        return;
      }

      await _usersCollection.doc(currentUserId).update({
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      print('✅ Phone number updated successfully');
    } catch (e) {
      print('❌ Error updating phone number: $e');
      rethrow;
    }
  }
}

