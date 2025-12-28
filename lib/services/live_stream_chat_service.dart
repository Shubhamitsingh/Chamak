import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_stream_chat_message.dart';

class LiveStreamChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'live_stream_chat';

  /// Send a message to a live stream chat
  Future<bool> sendMessage({
    required String streamId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String message,
    required bool isHost,
  }) async {
    try {
      if (message.trim().isEmpty) {
        return false;
      }

      final messageRef = _firestore
          .collection(_collection)
          .doc(streamId)
          .collection('messages')
          .doc();

      final chatMessage = LiveStreamChatMessage(
        messageId: messageRef.id,
        streamId: streamId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        message: message.trim(),
        timestamp: DateTime.now(),
        isHost: isHost,
      );

      await messageRef.set(chatMessage.toFirestore());
      
      print('✅ Live stream chat message sent: $streamId');
      return true;
    } catch (e) {
      print('❌ Error sending live stream chat message: $e');
      return false;
    }
  }

  /// Get real-time stream of messages for a live stream
  Stream<List<LiveStreamChatMessage>> getMessages(String streamId) {
    try {
      print('📥 Listening to messages for streamId: $streamId');
      return _firestore
          .collection(_collection)
          .doc(streamId)
          .collection('messages')
          .orderBy('timestamp', descending: false) // Oldest first for chat
          .limit(100) // Load last 100 messages
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs
            .map((doc) => LiveStreamChatMessage.fromFirestore(doc))
            .toList();
        print('📨 Received ${messages.length} messages for streamId: $streamId');
        return messages;
      });
    } catch (e) {
      print('❌ Error getting live stream chat messages: $e');
      return Stream.value([]);
    }
  }

  /// Delete all messages for a stream (cleanup when stream ends)
  Future<void> deleteStreamMessages(String streamId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection(_collection)
          .doc(streamId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Deleted all messages for stream: $streamId');
    } catch (e) {
      print('❌ Error deleting stream messages: $e');
    }
  }

  /// Get message count for a stream
  Future<int> getMessageCount(String streamId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(streamId)
          .collection('messages')
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting message count: $e');
      return 0;
    }
  }
}




































