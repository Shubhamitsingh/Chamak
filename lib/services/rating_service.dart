import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle Play Store rating functionality with hybrid approach
/// Uses Google's native In-App Review API when available, falls back to custom popup
class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InAppReview _inAppReview = InAppReview.instance;
  
  // Keys for SharedPreferences (rate limiting)
  static const String _lastReviewRequestKey = 'last_review_request_date';
  static const String _reviewRequestCountKey = 'review_request_count';
  
  // Rate limiting: Show max once per 3 months, max 3 times total
  static const int _minDaysBetweenRequests = 90; // 3 months
  static const int _maxRequestCount = 3;

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

  /// Check if review request should be shown (rate limiting)
  /// Returns true if eligible, false otherwise
  Future<bool> shouldShowReviewRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user already rated
      final hasRated = await hasUserRated();
      if (hasRated) {
        debugPrint('ℹ️ User already rated - skipping review request');
        return false;
      }
      
      // Check request count
      final requestCount = prefs.getInt(_reviewRequestCountKey) ?? 0;
      if (requestCount >= _maxRequestCount) {
        debugPrint('ℹ️ Review request limit reached ($requestCount/$_maxRequestCount)');
        return false;
      }
      
      // Check time since last request
      final lastRequestDate = prefs.getString(_lastReviewRequestKey);
      if (lastRequestDate != null) {
        final lastDate = DateTime.parse(lastRequestDate);
        final daysSince = DateTime.now().difference(lastDate).inDays;
        if (daysSince < _minDaysBetweenRequests) {
          debugPrint('ℹ️ Too soon since last request ($daysSince days, need $_minDaysBetweenRequests)');
          return false;
        }
      }
      
      return true; // ✅ Eligible to show review request
    } catch (e) {
      debugPrint('Error checking review request eligibility: $e');
      return false; // Fail safe: don't show if error
    }
  }

  /// Request In-App Review (shows native Play Store dialog)
  /// This is the primary method - uses Google's native dialog
  Future<bool> requestReview() async {
    try {
      // Check if should show
      final shouldShow = await shouldShowReviewRequest();
      if (!shouldShow) {
        debugPrint('ℹ️ Review request not eligible at this time');
        return false;
      }
      
      // Check availability
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        debugPrint('⚠️ In-App Review API not available');
        return false; // Will fallback to custom popup
      }
      
      // Show native In-App Review dialog
      await _inAppReview.requestReview();
      
      // Mark as requested (don't mark as rated - user might cancel)
      await markReviewRequested();
      
      debugPrint('✅ Native In-App Review dialog shown');
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting review: $e');
      return false; // Will fallback to custom popup
    }
  }

  /// Open Play Store as fallback (if In-App Review not available)
  Future<void> openPlayStoreFallback() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: 'com.chamakz.app',
      );
      debugPrint('✅ Play Store opened as fallback');
    } catch (e) {
      debugPrint('❌ Error opening Play Store: $e');
    }
  }

  /// Mark review as requested (for rate limiting)
  /// Public method for use in RatingPopupDialog
  Future<void> markReviewRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update last request date
      await prefs.setString(
        _lastReviewRequestKey,
        DateTime.now().toIso8601String(),
      );
      
      // Increment request count
      final currentCount = prefs.getInt(_reviewRequestCountKey) ?? 0;
      await prefs.setInt(_reviewRequestCountKey, currentCount + 1);
      
      debugPrint('✅ Review request marked (count: ${currentCount + 1})');
    } catch (e) {
      debugPrint('Error marking review request: $e');
    }
  }

  /// Mark user as having rated the app (called when user submits review)
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
      
      debugPrint('✅ User marked as rated in Firestore');
    } catch (e) {
      debugPrint('Error marking user as rated: $e');
      // Don't throw - allow user to continue even if update fails
    }
  }

  /// Check if In-App Review API is available
  /// Returns true if native dialog can be shown
  Future<bool> isInAppReviewAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (e) {
      debugPrint('Error checking In-App Review availability: $e');
      return false;
    }
  }
}
