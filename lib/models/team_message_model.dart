import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMessageModel {
  final String messageId;
  final String message;
  final String senderId; // Admin ID
  final String senderName; // "Chamakz Team" or admin name
  final DateTime timestamp;
  final String? imageUrl; // Optional image attachment
  final Map<String, bool> readBy; // {userId: true/false}

  TeamMessageModel({
    required this.messageId,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.imageUrl,
    required this.readBy,
  });

  // Create from Firestore document
  factory TeamMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return TeamMessageModel(
      messageId: doc.id,
      message: data['message']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? 'admin',
      senderName: data['senderName']?.toString() ?? 'Chamakz Team',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl']?.toString(),
      readBy: Map<String, bool>.from(data['readBy'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'readBy': readBy,
    };
  }

  TeamMessageModel copyWith({
    String? messageId,
    String? message,
    String? senderId,
    String? senderName,
    DateTime? timestamp,
    String? imageUrl,
    Map<String, bool>? readBy,
  }) {
    return TeamMessageModel(
      messageId: messageId ?? this.messageId,
      message: message ?? this.message,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      readBy: readBy ?? this.readBy,
    );
  }
}
