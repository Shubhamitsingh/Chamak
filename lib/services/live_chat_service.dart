import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_chat_message_model.dart';

class LiveChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message to live stream chat
  // Simple and direct - just send the message
  Future<bool> sendLiveChatMessage({
    required String liveStreamId,
    required String senderId,
    required String senderName,
    String? senderImage,
    required String message,
    required bool isHost,
  }) async {
    try {
      print('📤 Sending message to stream: $liveStreamId');
      print('   Sender: $senderName ($senderId)');
      print('   Message: $message');
      
      // Fetch user level from Firestore
      int? userLevel;
      try {
        final userDoc = await _firestore.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          userLevel = userData?['level'] != null ? (userData!['level'] as num).toInt() : 1;
        } else {
          userLevel = 1; // Default level if user not found
        }
      } catch (e) {
        print('⚠️ Could not fetch user level: $e');
        userLevel = 1; // Default to level 1 on error
      }
      
      // Create message document directly
      final messageRef = _firestore
          .collection('live_streams')
          .doc(liveStreamId)
          .collection('chat')
          .doc();

      final now = DateTime.now();
      final chatMessage = LiveChatMessageModel(
        messageId: messageRef.id,
        liveStreamId: liveStreamId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        message: message,
        timestamp: now,
        isHost: isHost,
        type: LiveChatMessageType.text,
        senderLevel: userLevel,
      );

      // Send message to Firestore with explicit timestamp
      final messageData = chatMessage.toFirestore();
      print('📤 Writing message to Firestore: live_streams/$liveStreamId/chat/${messageRef.id}');
      print('   Data: $messageData');
      
      await messageRef.set(messageData);
      print('✅ Message sent successfully! Message ID: ${messageRef.id}');
      print('   Timestamp: $now');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error sending live chat message: $e');
      print('   Stack trace: $stackTrace');
      print('   Stream ID: $liveStreamId');
      print('   Sender: $senderName ($senderId)');
      return false;
    }
  }

  // Send gift message
  Future<bool> sendGiftMessage({
    required String liveStreamId,
    required String senderId,
    required String senderName,
    String? senderImage,
    required String giftName,
    required int giftCost,
    required String giftEmoji,
    required bool isHost,
  }) async {
    try {
      print('🎁 Sending gift to stream: $liveStreamId');
      print('   Sender: $senderName ($senderId)');
      print('   Gift: $giftEmoji $giftName (${giftCost} diamonds)');
      
      final messageRef = _firestore
          .collection('live_streams')
          .doc(liveStreamId)
          .collection('chat')
          .doc();

      final giftMessage = LiveChatMessageModel(
        messageId: messageRef.id,
        liveStreamId: liveStreamId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        message: '$giftEmoji $giftName', // Format: "🌹 Rose"
        timestamp: DateTime.now(),
        isHost: isHost,
        type: LiveChatMessageType.gift,
      );

      await messageRef.set(giftMessage.toFirestore());
      print('✅ Gift message sent successfully! Message ID: ${messageRef.id}');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error sending gift message: $e');
      print('   Stack trace: $stackTrace');
      return false;
    }
  }

  // Send system message (welcome, rules, etc.)
  Future<bool> sendSystemMessage({
    required String liveStreamId,
    required String message,
  }) async {
    try {
      final messageRef = _firestore
          .collection('live_streams')
          .doc(liveStreamId)
          .collection('chat')
          .doc();

      final systemMessage = LiveChatMessageModel(
        messageId: messageRef.id,
        liveStreamId: liveStreamId,
        senderId: 'system',
        senderName: 'Admin',
        message: message,
        timestamp: DateTime.now(),
        isHost: false,
        type: LiveChatMessageType.system,
      );

      await messageRef.set(systemMessage.toFirestore());
      print('✅ System message sent');
      return true;
    } catch (e) {
      print('❌ Error sending system message: $e');
      return false;
    }
  }

  // Send user entry notification
  Future<bool> sendUserEntryNotification({
    required String liveStreamId,
    required String userName,
  }) async {
    try {
      final messageRef = _firestore
          .collection('live_streams')
          .doc(liveStreamId)
          .collection('chat')
          .doc();

      final entryMessage = LiveChatMessageModel(
        messageId: messageRef.id,
        liveStreamId: liveStreamId,
        senderId: 'system',
        senderName: userName,
        message: 'has entered the room',
        timestamp: DateTime.now(),
        isHost: false,
        type: LiveChatMessageType.userEntry,
      );

      await messageRef.set(entryMessage.toFirestore());
      print('✅ User entry notification sent');
      return true;
    } catch (e) {
      print('❌ Error sending entry notification: $e');
      return false;
    }
  }

  // Send user exit notification
  Future<bool> sendUserExitNotification({
    required String liveStreamId,
    required String userName,
  }) async {
    try {
      final messageRef = _firestore
          .collection('live_streams')
          .doc(liveStreamId)
          .collection('chat')
          .doc();

      final exitMessage = LiveChatMessageModel(
        messageId: messageRef.id,
        liveStreamId: liveStreamId,
        senderId: 'system',
        senderName: userName,
        message: 'has left the room',
        timestamp: DateTime.now(),
        isHost: false,
        type: LiveChatMessageType.userExit,
      );

      await messageRef.set(exitMessage.toFirestore());
      print('✅ User exit notification sent');
      return true;
    } catch (e) {
      print('❌ Error sending exit notification: $e');
      return false;
    }
  }

  // Get live chat messages (real-time stream)
  // Simple and direct - just get messages from Firestore
  // Cache streams to prevent duplicate listeners
  final Map<String, Stream<List<LiveChatMessageModel>>> _streamCache = {};
  
  Stream<List<LiveChatMessageModel>> getLiveChatMessages(String liveStreamId) {
    // Return cached stream if it exists to prevent duplicate listeners
    if (_streamCache.containsKey(liveStreamId)) {
      print('📡 Using cached stream for: $liveStreamId');
      return _streamCache[liveStreamId]!;
    }
    
    try {
      print('📡 Creating new stream for: $liveStreamId');
      final streamRef = _firestore
          .collection('live_streams')
          .doc(liveStreamId)
          .collection('chat')
          .orderBy('timestamp', descending: false) // Oldest first for chat
          .limit(200); // Load last 200 messages
      
      // Create stream with error handling and logging
      final stream = streamRef.snapshots().map((snapshot) {
        try {
          if (snapshot.docs.isEmpty) {
            print('📭 No messages found in stream: $liveStreamId');
            return <LiveChatMessageModel>[];
          }
          
          final messages = snapshot.docs
              .map((doc) {
                try {
                  final message = LiveChatMessageModel.fromFirestore(doc);
                  return message;
                } catch (e) {
                  print('⚠️ Error parsing message ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<LiveChatMessageModel>()
              .toList();
          
          print('📬 Loaded ${messages.length} messages from stream: $liveStreamId');
          return messages;
        } catch (e) {
          print('❌ Error processing snapshot: $e');
          return <LiveChatMessageModel>[];
        }
      }).handleError((error, stackTrace) {
        print('❌ Stream error for $liveStreamId: $error');
        print('   Stack trace: $stackTrace');
        // Return empty list on error to prevent crashes
        return <LiveChatMessageModel>[];
      });
      
      // Cache the stream
      _streamCache[liveStreamId] = stream;
      return stream;
    } catch (e, stackTrace) {
      print('❌ Error creating stream for $liveStreamId: $e');
      print('   Stack trace: $stackTrace');
      final emptyStream = Stream.value(<LiveChatMessageModel>[]);
      _streamCache[liveStreamId] = emptyStream;
      return emptyStream;
    }
  }

  // Delete all chat messages when stream ends (optional cleanup)
  Future<void> clearLiveChat(String liveStreamId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('live_streams')
          .doc(liveStreamId)
          .collection('chat')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('✅ Live chat cleared');
    } catch (e) {
      print('❌ Error clearing live chat: $e');
    }
  }
}

