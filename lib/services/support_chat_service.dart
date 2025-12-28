import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class SupportChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Generate support chat ID from user ID (one chat per user)
  String getSupportChatId(String userId) {
    return 'support_$userId';
  }

  // Create or get existing support chat for a user
  Future<String> createOrGetSupportChat(
    String userId, 
    String userName, 
    String? userPhone,
    String? numericUserId, // Numeric user ID for easy admin identification
  ) async {
    try {
      final chatId = getSupportChatId(userId);
      final chatRef = _firestore.collection('supportChats').doc(chatId);
      final chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        // Create new support chat
        await chatRef.set({
          'userId': userId,
          'numericUserId': numericUserId ?? '', // Store numeric ID for admin identification
          'userName': userName,
          'userPhone': userPhone ?? '',
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {
            userId: 0, // User's unread count
            'admin': 0, // Admin's unread count
          },
          'status': 'open', // open, closed, pending
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Created new support chat: $chatId (Numeric ID: $numericUserId)');
      } else {
        // Update existing chat with numericUserId if missing
        final existingData = chatDoc.data();
        if (existingData is Map<String, dynamic> && 
            (existingData['numericUserId'] == null || existingData['numericUserId'] == '') && 
            numericUserId != null && 
            numericUserId.isNotEmpty) {
          await chatRef.update({
            'numericUserId': numericUserId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Updated support chat with numeric ID: $numericUserId');
          debugPrint('✅ Updated support chat with numeric ID: $numericUserId');
        }
      }

      return chatId;
    } catch (e) {
      debugPrint('❌ Error creating/getting support chat: $e');
      rethrow;
    }
  }

  // Send a message in support chat
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    MessageType type = MessageType.text,
    String? mediaUrl,
    required bool isAdmin, // True if admin is sending, false if user
  }) async {
    try {
      final messageRef = _firestore
          .collection('supportChats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final messageModel = MessageModel(
        messageId: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        receiverId: isAdmin ? 'user' : 'admin', // Admin sends to 'user', user sends to 'admin'
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
      final chatRef = _firestore.collection('supportChats').doc(chatId);
      final updateData = <String, dynamic>{
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update unread count for receiver
      if (isAdmin) {
        // Admin sent message, increment user's unread count
        updateData['unreadCount.$senderId'] = FieldValue.increment(1);
      } else {
        // User sent message, increment admin's unread count
        updateData['unreadCount.admin'] = FieldValue.increment(1);
      }

      batch.update(chatRef, updateData);

      await batch.commit();
      debugPrint('✅ Support message sent successfully');

      // Send push notification to receiver (admin or user)
      try {
        if (isAdmin) {
          // Admin sent message to user - get user info for notification
          final chatDoc = await chatRef.get();
          if (chatDoc.exists) {
            final chatData = chatDoc.data();
            final userId = chatData?['userId'] as String?;
            if (userId != null) {
              await _notificationService.sendMessageNotification(
                receiverUserId: userId,
                senderName: 'Support Team',
                messageText: message,
                chatId: chatId,
              );
            }
          }
        } else {
          // User sent message to admin - notify all admins
          // You can implement admin notification logic here
          debugPrint('📢 User message sent, admin should be notified');
        }
      } catch (notificationError) {
        debugPrint('⚠️ Failed to send notification: $notificationError');
        // Don't fail the message send if notification fails
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error sending support message: $e');
      return false;
    }
  }

  // Get messages for a specific support chat (real-time)
  Stream<List<MessageModel>> getSupportChatMessages(String chatId) {
    return _firestore
        .collection('supportChats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100) // Load last 100 messages
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Get all support chats (for admin dashboard) - real-time
  Stream<List<Map<String, dynamic>>> getAllSupportChats() {
    try {
      return _firestore
          .collection('supportChats')
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'chatId': doc.id,
            'userId': data['userId'] ?? '',
            'numericUserId': data['numericUserId'] ?? '', // Numeric user ID for admin identification
            'userName': data['userName'] ?? 'Unknown User',
            'userPhone': data['userPhone'] ?? '',
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTime': (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'unreadCount': data['unreadCount'] ?? {'admin': 0},
            'status': data['status'] ?? 'open',
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ Error getting support chats: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  // Get user's support chat (for user side)
  Stream<Map<String, dynamic>?> getUserSupportChat(String userId) {
    try {
      final chatId = getSupportChatId(userId);
      return _firestore
          .collection('supportChats')
          .doc(chatId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) {
          return null;
        }
        final data = doc.data();
        return {
          'chatId': doc.id,
          'userId': data?['userId'] ?? '',
          'numericUserId': data?['numericUserId'] ?? '', // Numeric user ID for admin identification
          'userName': data?['userName'] ?? 'Unknown User',
          'lastMessage': data?['lastMessage'] ?? '',
          'lastMessageTime': (data?['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'unreadCount': data?['unreadCount'] ?? {userId: 0},
          'status': data?['status'] ?? 'open',
        };
      });
    } catch (e) {
      debugPrint('❌ Error getting user support chat: $e');
      return Stream.value(null);
    }
  }

  // Mark messages as read in support chat
  Future<void> markMessagesAsRead(String chatId, bool isAdmin, [String? specificUserId]) async {
    try {
      final chatRef = _firestore.collection('supportChats').doc(chatId);
      
      // Reset unread count
      if (isAdmin) {
        await chatRef.update({
          'unreadCount.admin': 0,
        });
        
        // When admin reads, mark all unread messages sent by the user (where receiverId == 'admin') as read
        // Since each support chat is unique per user (chatId = support_$userId), 
        // we only need to filter by receiverId == 'admin'
        // This will show double ticks (✓✓) to users when admin reads their messages
        final userMessagesSnapshot = await _firestore
            .collection('supportChats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', isEqualTo: 'admin')
            .where('isRead', isEqualTo: false)
            .get();

        if (userMessagesSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in userMessagesSnapshot.docs) {
            batch.update(doc.reference, {'isRead': true});
          }
          await batch.commit();
          debugPrint('✅ Marked ${userMessagesSnapshot.docs.length} user messages as read by admin - users will see double ticks');
        }
      } else {
        // Get user ID from chat
        final chatDoc = await chatRef.get();
        if (chatDoc.exists) {
          final userId = chatDoc.data()?['userId'] as String?;
          if (userId != null) {
            await chatRef.update({
              'unreadCount.$userId': 0,
            });
            
            // When user reads, mark all messages sent by admin (where receiverId == userId) as read
            final adminMessagesSnapshot = await _firestore
                .collection('supportChats')
                .doc(chatId)
                .collection('messages')
                .where('receiverId', isEqualTo: userId)
                .where('isRead', isEqualTo: false)
                .get();

            if (adminMessagesSnapshot.docs.isNotEmpty) {
              final batch = _firestore.batch();
              for (var doc in adminMessagesSnapshot.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
              debugPrint('✅ Marked ${adminMessagesSnapshot.docs.length} admin messages as read by user');
            }
          }
        }
      }

      debugPrint('✅ Support messages marked as read');
    } catch (e) {
      debugPrint('❌ Error marking support messages as read: $e');
    }
  }

  // Get total unread count for admin (for badge)
  Stream<int> getAdminUnreadCount() {
    try {
      return _firestore
          .collection('supportChats')
          .snapshots()
          .map((snapshot) {
        int total = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
          total += (unreadCount?['admin'] as int?) ?? 0;
        }
        return total;
      });
    } catch (e) {
      debugPrint('❌ Error getting admin unread count: $e');
      return Stream.value(0);
    }
  }

  // Get user's unread count for support chat
  Stream<int> getUserSupportUnreadCount(String userId) {
    try {
      final chatId = getSupportChatId(userId);
      return _firestore
          .collection('supportChats')
          .doc(chatId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) {
          return 0;
        }
        final data = doc.data();
        final unreadCount = data?['unreadCount'] as Map<String, dynamic>?;
        return (unreadCount?[userId] as int?) ?? 0;
      });
    } catch (e) {
      debugPrint('❌ Error getting user support unread count: $e');
      return Stream.value(0);
    }
  }

  // Update chat status (admin only)
  Future<bool> updateChatStatus(String chatId, String status) async {
    try {
      await _firestore.collection('supportChats').doc(chatId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Support chat status updated to: $status');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating chat status: $e');
      return false;
    }
  }
}

