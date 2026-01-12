import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/gift_model.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Generate consistent chat ID from two user IDs
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Always same order
    return '${ids[0]}_${ids[1]}';
  }

  // Create or get existing chat
  Future<String> createOrGetChat(UserModel currentUser, UserModel otherUser) async {
    try {
      final chatId = getChatId(currentUser.uid, otherUser.uid);
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        // Create new chat
        await chatRef.set({
          'participants': [currentUser.uid, otherUser.uid],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {
            currentUser.uid: 0,
            otherUser.uid: 0,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'participantNames': {
            currentUser.uid: currentUser.name,
            otherUser.uid: otherUser.name,
          },
          'participantImages': {
            currentUser.uid: currentUser.profileImage,
            otherUser.uid: otherUser.profileImage,
          },
        });

        // Wait a moment to ensure document is fully committed
        // This helps prevent permission errors when immediately listening to the chat
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify the document was created successfully
        final verifyDoc = await chatRef.get();
        if (!verifyDoc.exists) {
          throw Exception('Failed to create chat document');
        }

        print('✅ Created new chat: $chatId');
      }

      return chatId;
    } catch (e) {
      print('❌ Error creating/getting chat: $e');
      rethrow;
    }
  }

  // Send a message
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final messageModel = MessageModel(
        messageId: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
        type: type,
        mediaUrl: mediaUrl,
      );

      // Use batch for atomic operations
      final batch = _firestore.batch();

      // Add message
      batch.set(messageRef, messageModel.toFirestore());

      // Update chat metadata
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });

      await batch.commit();
      print('✅ Message sent successfully');

      // Send push notification to receiver
      try {
        // Get sender's name
        final senderDoc = await _firestore.collection('users').doc(senderId).get();
        final senderName = senderDoc.data()?['displayName'] ?? 'Someone';
        
        // Send notification
        await _notificationService.sendMessageNotification(
          receiverUserId: receiverId,
          senderName: senderName,
          messageText: message,
          chatId: chatId,
        );
        print('✅ Notification sent to receiver');
      } catch (notificationError) {
        print('⚠️ Failed to send notification: $notificationError');
        // Don't fail the message send if notification fails
      }

      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  // Get all user chats (real-time)
  Stream<List<ChatModel>> getUserChats(String userId) {
    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .handleError((error) {
            print('❌ Error in getUserChats stream: $error');
            // Return empty list on error
            return const Stream.empty();
          })
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    try {
                      return ChatModel.fromFirestore(doc);
                    } catch (e) {
                      print('❌ Error parsing chat document: $e');
                      return null;
                    }
                  })
                  .whereType<ChatModel>() // Filter out null values
                  .toList();
            } catch (e) {
              print('❌ Error mapping chat documents: $e');
              return <ChatModel>[];
            }
          });
    } catch (e) {
      print('❌ Error setting up getUserChats stream: $e');
      // Return empty stream on error
      return Stream.value(<ChatModel>[]);
    }
  }

  // Get messages for a specific chat (real-time)
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100) // Load last 100 messages
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Mark all messages as read in a chat
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      await chatRef.update({
        'unreadCount.$userId': 0,
      });

      // Optional: Mark individual messages as read
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  // Delete a chat
  Future<bool> deleteChat(String chatId) async {
    try {
      // Delete all messages first
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete chat document
      batch.delete(_firestore.collection('chats').doc(chatId));

      await batch.commit();
      print('✅ Chat deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting chat: $e');
      return false;
    }
  }

  // Get total unread count for user (for badge)
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        total += (unreadCount?[userId] as int?) ?? 0;
      }
      return total;
    });
  }

  // Check if chat exists
  Future<bool> chatExists(String userId1, String userId2) async {
    try {
      final chatId = getChatId(userId1, userId2);
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      return chatDoc.exists;
    } catch (e) {
      print('❌ Error checking chat existence: $e');
      return false;
    }
  }

  // Send a gift message (deducts coins from sender)
  Future<bool> sendGift({
    required String chatId,
    required String senderId,
    required String receiverId,
    required GiftModel gift,
  }) async {
    try {
      // Check sender's coin balance
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      if (!senderDoc.exists) {
        throw Exception('User not found');
      }

      final senderData = senderDoc.data()!;
      final currentCoins = (senderData['uCoins'] as int? ?? senderData['coins'] as int? ?? 0);

      if (currentCoins < gift.cost) {
        throw Exception('Insufficient coins. You need ${gift.cost} coins to send this gift, but you only have $currentCoins coins.');
      }

      // Use batch for atomic operations
      final batch = _firestore.batch();

      // Deduct coins from sender
      final senderRef = _firestore.collection('users').doc(senderId);
      batch.update(senderRef, {
        'uCoins': FieldValue.increment(-gift.cost),
      });

      // Create gift message
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final giftMessage = MessageModel(
        messageId: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        message: 'Sent ${gift.name} ${gift.emoji}',
        timestamp: DateTime.now(),
        isRead: false,
        type: MessageType.gift,
        giftId: gift.id,
        giftName: gift.name,
        giftEmoji: gift.emoji,
        giftCost: gift.cost,
      );

      batch.set(messageRef, giftMessage.toFirestore());

      // Update chat metadata with gift message
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': '${gift.emoji} ${gift.name}',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });

      await batch.commit();
      print('✅ Gift sent successfully: ${gift.name}');

      // Send push notification to receiver
      try {
        final senderName = senderData['displayName'] ?? senderData['name'] ?? 'Someone';
        await _notificationService.sendMessageNotification(
          receiverUserId: receiverId,
          senderName: senderName,
          messageText: '${gift.emoji} ${gift.name}',
          chatId: chatId,
        );
        print('✅ Gift notification sent to receiver');
      } catch (notificationError) {
        print('⚠️ Failed to send gift notification: $notificationError');
      }

      return true;
    } catch (e) {
      print('❌ Error sending gift: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  // Check if user has enough coins for a gift
  Future<bool> hasEnoughCoins(String userId, int requiredCoins) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final currentCoins = (userData['uCoins'] as int? ?? userData['coins'] as int? ?? 0);
      
      return currentCoins >= requiredCoins;
    } catch (e) {
      print('❌ Error checking coin balance: $e');
      return false;
    }
  }

  // Get user's current coin balance
  Future<int> getUserCoinBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data()!;
      return (userData['uCoins'] as int? ?? userData['coins'] as int? ?? 0);
    } catch (e) {
      print('❌ Error getting coin balance: $e');
      return 0;
    }
  }
}


