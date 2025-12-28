import 'package:cloud_firestore/cloud_firestore.dart';

enum LiveChatMessageType {
  text,        // Regular user message
  system,      // System/admin message (welcome, rules, etc.)
  userEntry,   // User entered the room
  userExit,    // User left the room
  gift,        // Gift sent by user
}

class LiveChatMessageModel {
  final String messageId;
  final String liveStreamId; // ID of the live stream
  final String senderId;
  final String senderName;
  final String? senderImage;
  final String message;
  final DateTime timestamp;
  final bool isHost; // Whether sender is the host
  final LiveChatMessageType type; // Message type
  final int? senderLevel; // User level for badge display

  LiveChatMessageModel({
    required this.messageId,
    required this.liveStreamId,
    required this.senderId,
    required this.senderName,
    this.senderImage,
    required this.message,
    required this.timestamp,
    this.isHost = false,
    this.type = LiveChatMessageType.text,
    this.senderLevel,
  });

  // Create from Firestore document
  factory LiveChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiveChatMessageModel(
      messageId: doc.id,
      liveStreamId: data['liveStreamId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonymous',
      senderImage: data['senderImage'],
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isHost: data['isHost'] ?? false,
      type: LiveChatMessageType.values.firstWhere(
        (e) => e.toString() == 'LiveChatMessageType.${data['type']}',
        orElse: () => LiveChatMessageType.text,
      ),
      senderLevel: data['senderLevel'] != null ? (data['senderLevel'] as num).toInt() : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'liveStreamId': liveStreamId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isHost': isHost,
      'type': type.toString().split('.').last, // Store as 'text', 'system', etc.
      'senderLevel': senderLevel,
    };
  }
}

