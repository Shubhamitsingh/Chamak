import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/follower_model.dart';
import '../models/user_model.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to retry Firestore operations with exponential backoff
  Future<T> _retryFirestoreOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        // Check if it's a transient error that should be retried
        final errorString = e.toString().toLowerCase();
        final isTransientError = errorString.contains('unavailable') ||
            errorString.contains('deadline exceeded') ||
            errorString.contains('internal error') ||
            errorString.contains('resource exhausted');

        if (isTransientError && attempt < maxRetries) {
          print('⚠️ Transient Firestore error (attempt $attempt/$maxRetries): $e');
          print('⏳ Retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
          // Exponential backoff: double the delay for next retry
          delay = Duration(milliseconds: delay.inMilliseconds * 2);
        } else {
          // Not a transient error or max retries reached
          rethrow;
        }
      }
    }
    
    throw Exception('Max retries ($maxRetries) reached');
  }

  // Follow a user
  Future<bool> followUser(String currentUserId, UserModel targetUser) async {
    try {
      // Get current user info first (with retry)
      final currentUserDoc = await _retryFirestoreOperation(
        () => _firestore.collection('users').doc(currentUserId).get(),
      );
      
      if (!currentUserDoc.exists) {
        print('❌ Current user document not found');
        return false;
      }
      
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final batch = _firestore.batch();

      // Add to current user's following collection
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUser.uid);

      batch.set(followingRef, {
        'userId': targetUser.uid,
        'userName': targetUser.name,
        'userImage': targetUser.profileImage,
        'userNumericId': targetUser.numericUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Add to target user's followers collection
      final followersRef = _firestore
          .collection('users')
          .doc(targetUser.uid)
          .collection('followers')
          .doc(currentUserId);

      batch.set(followersRef, {
        'userId': currentUserId,
        'userName': currentUserData['name'] ?? '',
        'userImage': currentUserData['profileImage'] ?? '',
        'userNumericId': currentUserData['numericUserId'] ?? '',
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Update follower/following counts
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'followingCount': FieldValue.increment(1),
      });

      batch.update(_firestore.collection('users').doc(targetUser.uid), {
        'followersCount': FieldValue.increment(1),
      });

      await _retryFirestoreOperation(() => batch.commit());
      print('✅ Successfully followed user: ${targetUser.name}');
      return true;
    } catch (e) {
      print('❌ Error following user after retries: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Remove from current user's following collection
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      batch.delete(followingRef);

      // Remove from target user's followers collection
      final followersRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      batch.delete(followersRef);

      // Update follower/following counts
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'followingCount': FieldValue.increment(-1),
      });

      batch.update(_firestore.collection('users').doc(targetUserId), {
        'followersCount': FieldValue.increment(-1),
      });

      await _retryFirestoreOperation(() => batch.commit());
      print('✅ Successfully unfollowed user');
      return true;
    } catch (e) {
      print('❌ Error unfollowing user after retries: $e');
      return false;
    }
  }

  // Check if current user is following target user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await _retryFirestoreOperation(
        () => _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(targetUserId)
            .get(),
      );

      return doc.exists;
    } catch (e) {
      print('❌ Error checking following status after retries: $e');
      // Return false as safe default (assume not following if we can't check)
      return false;
    }
  }

  // Get followers list
  Stream<List<FollowerModel>> getFollowers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FollowerModel.fromFirestore(doc))
            .toList());
  }

  // Get following list
  Stream<List<FollowerModel>> getFollowing(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FollowerModel.fromFirestore(doc))
            .toList());
  }

  // Get followers count
  Future<int> getFollowersCount(String userId) async {
    try {
      final snapshot = await _retryFirestoreOperation(
        () => _firestore
            .collection('users')
            .doc(userId)
            .collection('followers')
            .count()
            .get(),
      );

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting followers count after retries: $e');
      return 0;
    }
  }

  // Get following count
  Future<int> getFollowingCount(String userId) async {
    try {
      // First try to get from user document field (more reliable)
      final userDoc = await _retryFirestoreOperation(
        () => _firestore.collection('users').doc(userId).get(),
      );

      if (userDoc.exists) {
        final followingCount = userDoc.data()?['followingCount'] as int?;
        if (followingCount != null) {
          return followingCount;
        }
      }

      // Fallback: Count subcollection if field doesn't exist
      final snapshot = await _retryFirestoreOperation(
        () => _firestore
            .collection('users')
            .doc(userId)
            .collection('following')
            .count()
            .get(),
      );

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting following count after retries: $e');
      return 0;
    }
  }
}


























