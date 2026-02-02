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
      debugPrint('⚠️ [BADGE COUNT] User ID is null, returning 0');
      return Stream.value(0);
    }

    return _firestore
        .collection('team_messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;
      debugPrint('🔔 [BADGE COUNT] Checking ${snapshot.docs.length} messages for user: $userId');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Check if user has read this message
        final readBy = data['readBy'] as Map<String, dynamic>? ?? {};
        
        // ✅ FIX: Handle type mismatches (string "true" vs boolean true vs int 1)
        final readValue = readBy[userId];
        final isRead = readValue == true || readValue == "true" || readValue == 1;
        
        if (!isRead) {
          unreadCount++;
          debugPrint('   ⚪ Unread: ${doc.id} (readBy[$userId] = $readValue)');
        } else {
          debugPrint('   ✅ Read: ${doc.id}');
        }
      }
      
      debugPrint('🔔 [BADGE COUNT] Final unread count: $unreadCount');
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
    if (userId == null) {
      debugPrint('⚠️ [TEAM MESSAGES] Cannot mark as read: User ID is null');
      return;
    }

    try {
      debugPrint('📖 [TEAM MESSAGES] Marking all messages as read for user: $userId');
      
      // ✅ FIX: Force server read to avoid cached data
      final snapshot = await _firestore
          .collection('team_messages')
          .get(const GetOptions(source: Source.server));
      
      if (snapshot.docs.isEmpty) {
        debugPrint('✅ [TEAM MESSAGES] No messages to mark as read');
        return;
      }

      // ✅ FIX: Update documents one-by-one instead of batch (more reliable with Firestore rules)
      int updateCount = 0;
      int successCount = 0;
      int failCount = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final readBy = data['readBy'] as Map<String, dynamic>? ?? {};
        
        // ✅ FIX: Handle type mismatches - check if already read
        final readValue = readBy[userId];
        final isRead = readValue == true || readValue == "true" || readValue == 1;
        
        if (!isRead) {
          updateCount++;
          try {
            // Update individually (more reliable with rules, better error handling)
            await doc.reference.update({
              'readBy.$userId': true,
            });
            successCount++;
            debugPrint('   ✅ Marked ${doc.id} as read');
          } catch (e) {
            failCount++;
            debugPrint('   ❌ Failed to mark ${doc.id} as read: $e');
            // Continue with other documents even if one fails
          }
        }
      }
      
      if (updateCount > 0) {
        if (successCount > 0) {
          debugPrint('✅ [TEAM MESSAGES] Successfully marked $successCount/$updateCount messages as read');
        }
        if (failCount > 0) {
          debugPrint('⚠️ [TEAM MESSAGES] Failed to mark $failCount messages (check Firestore rules)');
          // Don't throw error - partial success is better than total failure
        }
      } else {
        debugPrint('✅ [TEAM MESSAGES] All messages already read');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [TEAM MESSAGES] Error marking all messages as read: $e');
      debugPrint('❌ [TEAM MESSAGES] Stack trace: $stackTrace');
      // Re-throw to allow UI to handle
      rethrow;
    }
  }

  // Verify that messages were actually marked as read (for debugging)
  Future<bool> verifyMessagesMarkedAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('⚠️ [VERIFY] User ID is null');
      return false;
    }

    try {
      final snapshot = await _firestore
          .collection('team_messages')
          .get(const GetOptions(source: Source.server));
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final readBy = data['readBy'] as Map<String, dynamic>? ?? {};
        final readValue = readBy[userId];
        final isRead = readValue == true || readValue == "true" || readValue == 1;
        
        if (!isRead) {
          debugPrint('⚠️ [VERIFY] Message ${doc.id} is still unread (readBy[$userId] = $readValue)');
          return false;
        }
      }
      
      debugPrint('✅ [VERIFY] All messages are marked as read');
      return true;
    } catch (e) {
      debugPrint('❌ [VERIFY] Error verifying: $e');
      return false;
    }
  }
}
