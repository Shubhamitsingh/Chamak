import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/team_message_model.dart';

class AdminTeamMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send broadcast message to all users
  Future<Map<String, dynamic>> sendBroadcastMessage({
    required String message,
    String? imageUrl,
    String senderName = 'Chamakz Team',
  }) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) {
        return {
          'success': false,
          'message': 'Admin not authenticated',
        };
      }

      // Create message document
      final messageRef = await _firestore.collection('team_messages').add({
        'message': message,
        'senderId': adminId,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': <String, bool>{}, // Empty - no one has read it yet
        'imageUrl': imageUrl,
      });

      // Send push notifications to all users via Firestore trigger
      // This will be handled by Cloud Functions listening to team_messages collection
      // For now, we'll create a notification request document
      try {
        await _firestore.collection('notificationRequests').add({
          'type': 'broadcast',
          'notification': {
            'title': senderName,
            'body': message,
          },
          'data': {
            'type': 'team_message',
            'messageId': messageRef.id,
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Warning: Failed to create notification request: $e');
        // Don't fail the message sending if notification fails
      }

      return {
        'success': true,
        'message': 'Message sent to all users',
        'messageId': messageRef.id,
      };
    } catch (e) {
      debugPrint('Error sending broadcast message: $e');
      return {
        'success': false,
        'message': 'Failed to send message: $e',
      };
    }
  }

  // Get message history
  Stream<List<TeamMessageModel>> getMessageHistory() {
    return _firestore
        .collection('team_messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamMessageModel.fromFirestore(doc))
            .toList());
  }

  // Delete a team message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('team_messages').doc(messageId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }
}
