import 'package:cloud_firestore/cloud_firestore.dart';

class CallRequestModel {
  final String requestId;
  final String? streamId; // Optional - null for chat calls, required for live stream calls
  final String callerId;
  final String callerName;
  final String? callerImage;
  final String? hostId; // Optional - for live stream calls
  final String? receiverId; // Optional - for chat calls
  final String callType; // 'live_stream' or 'chat'
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled', 'ended'
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? callChannelName; // Agora channel for private call
  final String? callToken; // Agora token for private call

  CallRequestModel({
    required this.requestId,
    this.streamId, // Now optional
    required this.callerId,
    required this.callerName,
    this.callerImage,
    this.hostId, // Now optional
    this.receiverId, // New field for chat calls
    this.callType = 'live_stream', // Default to live_stream for backward compatibility
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
    this.callChannelName,
    this.callToken,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'requestId': requestId,
      'callerId': callerId,
      'callerName': callerName,
      'callerImage': callerImage,
      'callType': callType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'callChannelName': callChannelName,
      'callToken': callToken,
    };
    
    // Only include streamId if not null
    if (streamId != null) map['streamId'] = streamId!;
    if (hostId != null) map['hostId'] = hostId!;
    if (receiverId != null) map['receiverId'] = receiverId!;
    
    return map;
  }

  factory CallRequestModel.fromMap(Map<String, dynamic> map) {
    return CallRequestModel(
      requestId: map['requestId'] ?? '',
      streamId: map['streamId'], // Now optional
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerImage: map['callerImage'],
      hostId: map['hostId'], // Now optional
      receiverId: map['receiverId'], // New field
      callType: map['callType'] ?? 'live_stream', // Default for backward compatibility
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'])
          : null,
      callChannelName: map['callChannelName'],
      callToken: map['callToken'],
    );
  }

  factory CallRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallRequestModel(
      requestId: data['requestId'] ?? doc.id,
      streamId: data['streamId'], // Now optional
      callerId: data['callerId'] ?? '',
      callerName: data['callerName'] ?? '',
      callerImage: data['callerImage'],
      hostId: data['hostId'], // Now optional
      receiverId: data['receiverId'], // New field
      callType: data['callType'] ?? 'live_stream', // Default for backward compatibility
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? DateTime.parse(data['respondedAt'])
          : null,
      callChannelName: data['callChannelName'],
      callToken: data['callToken'],
    );
  }

  CallRequestModel copyWith({
    String? requestId,
    String? streamId,
    String? callerId,
    String? callerName,
    String? callerImage,
    String? hostId,
    String? receiverId,
    String? callType,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? callChannelName,
    String? callToken,
  }) {
    return CallRequestModel(
      requestId: requestId ?? this.requestId,
      streamId: streamId ?? this.streamId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerImage: callerImage ?? this.callerImage,
      hostId: hostId ?? this.hostId,
      receiverId: receiverId ?? this.receiverId,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      callChannelName: callChannelName ?? this.callChannelName,
      callToken: callToken ?? this.callToken,
    );
  }
}
