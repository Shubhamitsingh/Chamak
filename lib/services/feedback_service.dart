import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for handling user feedback
class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _feedbackCollection => _firestore.collection('feedback');

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Save feedback to Firestore
  Future<bool> submitFeedback({
    required String category,
    required int rating,
    required String feedbackText,
    String? userId,
    String? userName,
    String? userPhone,
  }) async {
    try {
      final userIdToUse = userId ?? currentUserId ?? 'anonymous';
      
      // Get user info if available
      String? finalUserName = userName;
      String? finalUserPhone = userPhone;
      
      if (userIdToUse != 'anonymous' && (finalUserName == null || finalUserPhone == null)) {
        try {
          final userDoc = await _firestore.collection('users').doc(userIdToUse).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>?;
            finalUserName ??= userData?['displayName'] ?? userData?['name'];
            finalUserPhone ??= userData?['phoneNumber'] ?? userData?['phone'];
          }
        } catch (e) {
          debugPrint('⚠️ Could not fetch user info: $e');
        }
      }

      // Create feedback document
      await _feedbackCollection.add({
        'userId': userIdToUse,
        'userName': finalUserName ?? 'Anonymous',
        'userPhone': finalUserPhone ?? 'N/A',
        'category': category,
        'rating': rating,
        'feedback': feedbackText,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new', // new, reviewed, resolved
        'adminNotes': null,
      });

      debugPrint('✅ Feedback submitted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      return false;
    }
  }

  /// Get all feedback (for admin)
  Stream<QuerySnapshot> getAllFeedback({String? status}) {
    Query query = _feedbackCollection.orderBy('timestamp', descending: true);
    
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.snapshots();
  }

  /// Get feedback by status
  Future<List<Map<String, dynamic>>> getFeedbackByStatus(String status) async {
    try {
      final querySnapshot = await _feedbackCollection
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching feedback: $e');
      return [];
    }
  }

  /// Update feedback status (for admin)
  Future<bool> updateFeedbackStatus({
    required String feedbackId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
      };
      
      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      await _feedbackCollection.doc(feedbackId).update(updateData);
      debugPrint('✅ Feedback status updated: $status');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating feedback status: $e');
      return false;
    }
  }

  /// Get feedback count by status
  Future<Map<String, int>> getFeedbackCounts() async {
    try {
      final snapshot = await _feedbackCollection.get();
      final counts = <String, int>{
        'total': snapshot.docs.length,
        'new': 0,
        'reviewed': 0,
        'resolved': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'new';
        if (counts.containsKey(status)) {
          counts[status] = (counts[status] ?? 0) + 1;
        }
      }

      return counts;
    } catch (e) {
      debugPrint('❌ Error getting feedback counts: $e');
      return {'total': 0, 'new': 0, 'reviewed': 0, 'resolved': 0};
    }
  }
}

