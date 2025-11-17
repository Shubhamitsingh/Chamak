class CallModel {
  final String callId;
  final String channelName;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final CallStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  CallModel({
    required this.callId,
    required this.channelName,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'channelName': channelName,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callId: map['callId'] ?? '',
      channelName: map['channelName'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPhotoUrl: map['callerPhotoUrl'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverPhotoUrl: map['receiverPhotoUrl'],
      status: _statusFromString(map['status'] ?? 'pending'),
      createdAt: DateTime.parse(map['createdAt']),
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      endedAt: map['endedAt'] != null ? DateTime.parse(map['endedAt']) : null,
    );
  }

  static CallStatus _statusFromString(String status) {
    switch (status) {
      case 'CallStatus.pending':
        return CallStatus.pending;
      case 'CallStatus.accepted':
        return CallStatus.accepted;
      case 'CallStatus.rejected':
        return CallStatus.rejected;
      case 'CallStatus.ended':
        return CallStatus.ended;
      case 'CallStatus.missed':
        return CallStatus.missed;
      default:
        return CallStatus.pending;
    }
  }

  CallModel copyWith({
    String? callId,
    String? channelName,
    String? callerId,
    String? callerName,
    String? callerPhotoUrl,
    String? receiverId,
    String? receiverName,
    String? receiverPhotoUrl,
    CallStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      channelName: channelName ?? this.channelName,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhotoUrl: callerPhotoUrl ?? this.callerPhotoUrl,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}

enum CallStatus {
  pending,
  accepted,
  rejected,
  ended,
  missed,
}
















