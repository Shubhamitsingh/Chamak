import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/team_message_model.dart';

class TeamMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get team messages stream (sorted by timestamp descending - newest first)
  Stream<List<TeamMessageModel>> getTeamMessagesStream() {
    try {
      return _firestore
          .collection('team_messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
        debugPrint('❌ Error in team messages stream: $error');
        debugPrint('❌ Error type: ${error.runtimeType}');
        if (error.toString().contains('index')) {
          debugPrint('⚠️ Index error detected. Messages may still exist but query needs index.');
        }
        // Return empty stream on error
        return Stream.value(<QueryDocumentSnapshot>[]);
      })
          .map((snapshot) {
        debugPrint('📨 Team messages snapshot: ${snapshot.docs.length} messages');
        if (snapshot.docs.isNotEmpty) {
          debugPrint('✅ First message ID: ${snapshot.docs.first.id}');
          debugPrint('✅ First message data: ${snapshot.docs.first.data()}');
        }
        return snapshot.docs
            .map((doc) {
              try {
                final model = TeamMessageModel.fromFirestore(doc);
                debugPrint('✅ Parsed message: ${model.messageId} - ${model.message.substring(0, model.message.length > 20 ? 20 : model.message.length)}...');
                return model;
              } catch (e) {
                debugPrint('❌ Error parsing message ${doc.id}: $e');
                debugPrint('❌ Document data: ${doc.data()}');
                return null;
              }
            })
            .whereType<TeamMessageModel>()
            .toList();
      });
    } catch (e) {
      debugPrint('❌ Error creating team messages stream: $e');
      return Stream.value(<TeamMessageModel>[]);
    }
  }

  // Get unread team messages count for current user
  Stream<int> getUnreadTeamMessagesCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('team_messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Check if user has read this message
        final readBy = data['readBy'] as Map<String, dynamic>? ?? {};
        if (!readBy.containsKey(userId) || readBy[userId] != true) {
          unreadCount++;
        }
      }
      return unreadCount;
    });
  }

  // Get last message for preview
  Future<TeamMessageModel?> getLastMessage() async {
    try {
      final snapshot = await _firestore
          .collection('team_messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      return TeamMessageModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting last team message: $e');
      return null;
    }
  }

  // Mark team message as read
  Future<void> markMessageAsRead(String messageId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('team_messages')
          .doc(messageId)
          .update({
        'readBy.$userId': true,
      });
    } catch (e) {
      debugPrint('Error marking team message as read: $e');
    }
  }

  // Mark all team messages as read
  Future<void> markAllMessagesAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Get all unread messages
      final snapshot = await _firestore
          .collection('team_messages')
          .get();

      // Batch update all messages
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final readBy = doc.data()['readBy'] as Map<String, dynamic>? ?? {};
        if (!readBy.containsKey(userId) || readBy[userId] != true) {
          batch.update(doc.reference, {
            'readBy.$userId': true,
          });
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all team messages as read: $e');
    }
  }
}
