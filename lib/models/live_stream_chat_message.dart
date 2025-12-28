import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStreamChatMessage {
  final String messageId;
  final String streamId; // The live stream ID
  final String userId; // Sender's user ID
  final String userName; // Sender's display name
  final String? userPhotoUrl; // Sender's photo URL
  final String message; // Message content
  final DateTime timestamp; // When message was sent
  final bool isHost; // Whether sender is the host

  LiveStreamChatMessage({
    required this.messageId,
    required this.streamId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.message,
    required this.timestamp,
    this.isHost = false,
  });

  // Create from Firestore document
  factory LiveStreamChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiveStreamChatMessage(
      messageId: doc.id,
      streamId: data['streamId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'],
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isHost: data['isHost'] ?? false,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'streamId': streamId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isHost': isHost,
    };
  }

  // Create a copy with updated fields
  LiveStreamChatMessage copyWith({
    String? messageId,
    String? streamId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? message,
    DateTime? timestamp,
    bool? isHost,
  }) {
    return LiveStreamChatMessage(
      messageId: messageId ?? this.messageId,
      streamId: streamId ?? this.streamId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isHost: isHost ?? this.isHost,
    );
  }
}




































