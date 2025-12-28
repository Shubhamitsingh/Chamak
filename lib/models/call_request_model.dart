import 'package:cloud_firestore/cloud_firestore.dart';

class CallRequestModel {
  final String requestId;
  final String streamId;
  final String callerId;
  final String callerName;
  final String? callerImage;
  final String hostId;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled', 'ended'
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? callChannelName; // Agora channel for private call
  final String? callToken; // Agora token for private call

  CallRequestModel({
    required this.requestId,
    required this.streamId,
    required this.callerId,
    required this.callerName,
    this.callerImage,
    required this.hostId,
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
    this.callChannelName,
    this.callToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'streamId': streamId,
      'callerId': callerId,
      'callerName': callerName,
      'callerImage': callerImage,
      'hostId': hostId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'callChannelName': callChannelName,
      'callToken': callToken,
    };
  }

  factory CallRequestModel.fromMap(Map<String, dynamic> map) {
    return CallRequestModel(
      requestId: map['requestId'] ?? '',
      streamId: map['streamId'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerImage: map['callerImage'],
      hostId: map['hostId'] ?? '',
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
      streamId: data['streamId'] ?? '',
      callerId: data['callerId'] ?? '',
      callerName: data['callerName'] ?? '',
      callerImage: data['callerImage'],
      hostId: data['hostId'] ?? '',
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
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      callChannelName: callChannelName ?? this.callChannelName,
      callToken: callToken ?? this.callToken,
    );
  }
}
