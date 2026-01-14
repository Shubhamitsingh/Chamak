import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle Play Store rating functionality
class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user has already rated the app
  /// Returns true if user has rated, false otherwise
  Future<bool> hasUserRated() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data();
      return data?['hasRatedApp'] == true;
    } catch (e) {
      // If error occurs, return false to allow popup (better UX)
      debugPrint('Error checking rating status: $e');
      return false;
    }
  }

  /// Mark user as having rated the app
  Future<void> markUserAsRated() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'hasRatedApp': true,
        'ratedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking user as rated: $e');
      // Don't throw - allow user to continue even if update fails
    }
  }
}
