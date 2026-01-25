import 'package:firebase_database/firebase_database.dart';
import '../models/live_chat_message_model.dart';
import 'dart:async';

/// Realtime Chat Service using Firebase Realtime Database
/// 
/// Provides real-time chat functionality for live streams with:
/// - WebSocket-based persistent connections
/// - Low latency (50-100ms)
/// - Automatic reconnection
/// - Rate limiting
class RealtimeChatService {
  // Configure database with correct region URL
  static FirebaseDatabase? _databaseInstance;
  
  static FirebaseDatabase get _database {
    if (_databaseInstance == null) {
      try {
        // Try to use the region-specific URL first
        // Update this URL to match your Firebase Realtime Database URL from Firebase Console
        final databaseURL = 'https://chamak-39472-default-rtdb.asia-southeast1.firebasedatabase.app';
        _databaseInstance = FirebaseDatabase.instanceFor(
          app: FirebaseDatabase.instance.app,
          databaseURL: databaseURL,
        );
        print('✅ Using Realtime Database URL: $databaseURL');
      } catch (e) {
        // Fallback to default instance if URL fails
        print('⚠️ Failed to use custom database URL, using default: $e');
        _databaseInstance = FirebaseDatabase.instance;
      }
    }
    return _databaseInstance!;
  }
  
  DatabaseReference get _databaseRef => _database.ref();
  
  // Rate limiting
  DateTime? _lastMessageTime;
  static const int _minMessageInterval = 1000; // 1 second between messages
  
  // Stream cache to prevent duplicate listeners
  final Map<String, Stream<List<LiveChatMessageModel>>> _streamCache = {};
  // Stream controllers for broadcast streams
  final Map<String, StreamController<List<LiveChatMessageModel>>> _streamControllers = {};

  /// Send a message to live stream chat
  /// 
  /// Returns true if message was sent successfully, false otherwise
  Future<bool> sendMessage({
    required String streamId,
    required String senderId,
    required String senderName,
    String? senderImage,
    required String message,
    required bool isHost,
    int? senderLevel,
  }) async {
    try {
      // Validate stream ID
      if (streamId.isEmpty) {
        print('❌ Cannot send message: Stream ID is empty');
        return false;
      }
      
      // Validate sender ID
      if (senderId.isEmpty) {
        print('❌ Cannot send message: Sender ID is empty (user not authenticated)');
        return false;
      }
      
      // Validate sender name
      if (senderName.isEmpty) {
        print('❌ Cannot send message: Sender name is empty');
        return false;
      }
      
      // Rate limiting check
      final now = DateTime.now();
      if (_lastMessageTime != null &&
          now.difference(_lastMessageTime!).inMilliseconds < _minMessageInterval) {
        print('⚠️ Rate limit: Please wait before sending another message');
        return false;
      }
      
      // Validate message
      if (message.trim().isEmpty) {
        print('⚠️ Cannot send empty message');
        return false;
      }
      
      if (message.length > 500) {
        print('⚠️ Message too long (max 500 characters)');
        return false;
      }
      
      print('📤 Sending message to Realtime Database: $streamId');
      print('   Sender: $senderName ($senderId)');
      print('   Message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
      
      // ✅ PRODUCTION: Correct database path structure
      // Path: live_rooms/{roomId}/messages/{messageId}
      final chatRef = _databaseRef
          .child('live_rooms')
          .child(streamId) // Using streamId as roomId for now (can be changed later)
          .child('messages')
          .push(); // Auto-generates unique key
      
      // ✅ PRODUCTION: Correct field names
      // senderRole: "host" | "user" (NOT isHost boolean)
      // level: number (NOT senderLevel)
      final messageData = {
        'senderId': senderId,
        'senderName': senderName,
        'senderImage': senderImage,
        'message': message.trim(),
        'timestamp': ServerValue.timestamp, // Server timestamp (prevents spoofing)
        'type': 'text',
        'senderRole': isHost ? 'host' : 'user', // ✅ CORRECT: String, not boolean
        'level': senderLevel ?? 1, // ✅ CORRECT: level, not senderLevel
        // Backward compatibility (will be removed later)
        'isHost': isHost,
        'senderLevel': senderLevel ?? 1,
      };
      
      // Send message
      await chatRef.set(messageData);
      
      _lastMessageTime = now;
      print('✅ Message sent successfully! Message ID: ${chatRef.key}');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error sending message to Realtime Database: $e');
      print('   Stack trace: $stackTrace');
      print('   Stream ID: $streamId');
      print('   Sender: $senderName ($senderId)');
      return false;
    }
  }

  /// Send gift message
  Future<bool> sendGiftMessage({
    required String streamId,
    required String senderId,
    required String senderName,
    String? senderImage,
    required String giftName,
    required int giftCost,
    required String giftEmoji,
    required bool isHost,
    int? senderLevel,
  }) async {
    try {
      print('🎁 Sending gift to Realtime Database: $streamId');
      print('   Sender: $senderName ($senderId)');
      print('   Gift: $giftEmoji $giftName (${giftCost} coins)');
      
      // ✅ PRODUCTION: Correct database path
      final chatRef = _databaseRef
          .child('live_rooms')
          .child(streamId)
          .child('messages')
          .push();
      
      final giftData = {
        'senderId': senderId,
        'senderName': senderName,
        'senderImage': senderImage,
        'message': '$giftEmoji $giftName',
        'timestamp': ServerValue.timestamp,
        'type': 'gift',
        'senderRole': isHost ? 'host' : 'user', // ✅ CORRECT
        'level': senderLevel ?? 1, // ✅ CORRECT
        'giftCost': giftCost,
        // Backward compatibility
        'isHost': isHost,
        'senderLevel': senderLevel ?? 1,
      };
      
      await chatRef.set(giftData);
      print('✅ Gift message sent successfully! Message ID: ${chatRef.key}');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error sending gift message: $e');
      print('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Send system message
  Future<bool> sendSystemMessage({
    required String streamId,
    required String message,
  }) async {
    try {
      // ✅ PRODUCTION: Correct database path
      final chatRef = _databaseRef
          .child('live_rooms')
          .child(streamId)
          .child('messages')
          .push();
      
      final systemData = {
        'senderId': 'system',
        'senderName': 'Admin',
        'message': message,
        'timestamp': ServerValue.timestamp,
        'type': 'system',
        'senderRole': 'system', // ✅ CORRECT
        'level': 0,
        // Backward compatibility
        'isHost': false,
      };
      
      await chatRef.set(systemData);
      print('✅ System message sent');
      return true;
    } catch (e) {
      print('❌ Error sending system message: $e');
      return false;
    }
  }

  /// Get real-time message stream
  /// 
  /// Returns a stream of chat messages that updates in real-time
  /// Uses broadcast stream to allow multiple listeners
  Stream<List<LiveChatMessageModel>> getMessages(String streamId) {
    // Return cached broadcast stream if it exists
    if (_streamCache.containsKey(streamId)) {
      print('📡 Using cached stream for: $streamId');
      return _streamCache[streamId]!;
    }
    
    try {
      print('📡 Creating new Realtime Database stream for: $streamId');
      
      // Create broadcast stream controller
      final controller = StreamController<List<LiveChatMessageModel>>.broadcast();
      _streamControllers[streamId] = controller;
      
      // ✅ PRODUCTION: Correct database path
      // ✅ PRODUCTION: Load only 10 messages (show 5-7 in UI)
      final chatRef = _databaseRef
          .child('live_rooms')
          .child(streamId)
          .child('messages')
          .orderByChild('timestamp')
          .limitToLast(10); // ✅ CORRECT: Load only 10, show 5-7
      
      // Listen to database changes and emit to broadcast stream
      chatRef.onValue.listen((event) {
        try {
          if (event.snapshot.value == null) {
            print('📭 No messages found in stream: $streamId');
            controller.add(<LiveChatMessageModel>[]);
            return;
          }
          
          final data = event.snapshot.value;
          
          // Handle different data structures
          List<LiveChatMessageModel> messages = [];
          
          if (data is Map) {
            messages = data.entries.map((entry) {
              try {
                final messageId = entry.key as String;
                final messageData = Map<String, dynamic>.from(entry.value as Map);
                
                // Convert timestamp - handle both int and long types
                int timestamp;
                final timestampValue = messageData['timestamp'];
                if (timestampValue is int) {
                  timestamp = timestampValue;
                } else if (timestampValue is num) {
                  // Handle Long (from Java/Kotlin) or other numeric types
                  timestamp = timestampValue.toInt();
                } else if (timestampValue is Map && timestampValue.containsKey('.sv')) {
                  // Server timestamp placeholder - use current time
                  timestamp = DateTime.now().millisecondsSinceEpoch;
                } else {
                  timestamp = DateTime.now().millisecondsSinceEpoch;
                }
                
                // Parse message type
                LiveChatMessageType messageType = LiveChatMessageType.text;
                final typeString = messageData['type'] as String? ?? 'text';
                try {
                  messageType = LiveChatMessageType.values.firstWhere(
                    (e) => e.toString().split('.').last == typeString,
                    orElse: () => LiveChatMessageType.text,
                  );
                } catch (e) {
                  messageType = LiveChatMessageType.text;
                }
                
                // ✅ PRODUCTION: Support both old and new field names (backward compatibility)
                final senderRole = messageData['senderRole'] as String?;
                final isHostValue = messageData['isHost'] as bool?;
                final isHost = senderRole == 'host' || (isHostValue ?? false);
                
                final levelValue = messageData['level'] as num?;
                final senderLevelValue = messageData['senderLevel'] as num?;
                final level = levelValue != null 
                    ? levelValue.toInt() 
                    : (senderLevelValue != null ? senderLevelValue.toInt() : null);
                
                return LiveChatMessageModel(
                  messageId: messageId,
                  liveStreamId: streamId,
                  senderId: messageData['senderId'] as String? ?? '',
                  senderName: messageData['senderName'] as String? ?? 'Anonymous',
                  senderImage: messageData['senderImage'] as String?,
                  message: messageData['message'] as String? ?? '',
                  timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
                  isHost: isHost, // Support both old and new format
                  type: messageType,
                  senderLevel: level, // Support both old and new format
                );
              } catch (e) {
                print('⚠️ Error parsing message ${entry.key}: $e');
                return null;
              }
            }).whereType<LiveChatMessageModel>().toList();
          }
          
          // Sort by timestamp (oldest first for chat)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          print('📬 Loaded ${messages.length} messages from Realtime Database: $streamId');
          controller.add(messages);
        } catch (e) {
          print('❌ Error processing snapshot: $e');
          controller.add(<LiveChatMessageModel>[]);
        }
      }, onError: (error, stackTrace) {
        print('❌ Stream error for $streamId: $error');
        print('   Stack trace: $stackTrace');
        controller.addError(error, stackTrace);
      });
      
      // Cache the broadcast stream
      _streamCache[streamId] = controller.stream;
      return controller.stream;
    } catch (e, stackTrace) {
      print('❌ Error creating stream for $streamId: $e');
      print('   Stack trace: $stackTrace');
      final emptyStream = Stream.value(<LiveChatMessageModel>[]);
      _streamCache[streamId] = emptyStream;
      return emptyStream;
    }
  }

  /// Get visible messages (last 7 for UI performance - production standard)
  Stream<List<LiveChatMessageModel>> getVisibleMessages(String streamId) {
    return getMessages(streamId).map((allMessages) {
      // ✅ PRODUCTION: Show only last 7 messages (max 5-7 per requirements)
      return allMessages.length > 7
          ? allMessages.sublist(allMessages.length - 7)
          : allMessages;
    });
  }

  /// Clear stream cache (call when leaving stream)
  void clearCache(String streamId) {
    // Close and remove stream controller
    _streamControllers[streamId]?.close();
    _streamControllers.remove(streamId);
    _streamCache.remove(streamId);
    print('🗑️ Cleared cache for stream: $streamId');
  }

  /// Clear all caches
  void clearAllCaches() {
    // Close all stream controllers
    for (var controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    _streamCache.clear();
    print('🗑️ Cleared all stream caches');
  }

  /// Delete all chat messages for a stream (cleanup)
  Future<void> clearLiveChat(String streamId) async {
    try {
      // ✅ PRODUCTION: Correct database path
      await _databaseRef
          .child('live_rooms')
          .child(streamId)
          .child('messages')
          .remove();
      print('✅ Live chat cleared for stream: $streamId');
    } catch (e) {
      print('❌ Error clearing live chat: $e');
    }
  }
}
