import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  gift,
}

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? mediaUrl; // For images, videos, etc.
  
  // Gift-specific fields
  final String? giftId;
  final String? giftName;
  final String? giftEmoji;
  final int? giftCost;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.mediaUrl,
    this.giftId,
    this.giftName,
    this.giftEmoji,
    this.giftCost,
  });

  // Create from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse MessageType - handle both old and new format
    MessageType messageType = MessageType.text;
    final typeString = data['type']?.toString() ?? 'text';
    try {
      // Try to match by name first (e.g., "text", "gift", "image")
      messageType = MessageType.values.firstWhere(
        (e) => e.name == typeString.toLowerCase(),
        orElse: () => MessageType.text,
      );
    } catch (e) {
      // If name doesn't match, try parsing the old format
      try {
        messageType = MessageType.values.firstWhere(
          (e) => e.toString().split('.').last == typeString,
          orElse: () => MessageType.text,
        );
      } catch (e2) {
        messageType = MessageType.text;
      }
    }
    
    return MessageModel(
      messageId: doc.id,
      chatId: data['chatId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      receiverId: data['receiverId']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      type: messageType,
      mediaUrl: data['mediaUrl']?.toString(),
      giftId: data['giftId']?.toString(),
      giftName: data['giftName']?.toString(),
      giftEmoji: data['giftEmoji']?.toString(),
      giftCost: data['giftCost'] is int ? data['giftCost'] as int : (data['giftCost'] as num?)?.toInt(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final map = {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.name, // Use name instead of toString() for cleaner storage
      'mediaUrl': mediaUrl,
    };
    
    // Add gift fields only if message is gift type
    if (type == MessageType.gift) {
      map['giftId'] = giftId;
      map['giftName'] = giftName;
      map['giftEmoji'] = giftEmoji;
      map['giftCost'] = giftCost;
    }
    
    return map;
  }

  MessageModel copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    String? mediaUrl,
    String? giftId,
    String? giftName,
    String? giftEmoji,
    int? giftCost,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      giftId: giftId ?? this.giftId,
      giftName: giftName ?? this.giftName,
      giftEmoji: giftEmoji ?? this.giftEmoji,
      giftCost: giftCost ?? this.giftCost,
    );
  }
}


























