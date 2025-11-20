class CallRequestModel {
  final String requestId;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserPhotoUrl;
  final String toUserId;  // Host ID
  final String streamId;
  final DateTime requestedAt;
  final String status;  // 'pending', 'accepted', 'rejected', 'cancelled'
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;

  CallRequestModel({
    required this.requestId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhotoUrl,
    required this.toUserId,
    required this.streamId,
    required this.requestedAt,
    this.status = 'pending',
    this.acceptedAt,
    this.rejectedAt,
    this.cancelledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'toUserId': toUserId,
      'streamId': streamId,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }

  factory CallRequestModel.fromMap(Map<String, dynamic> map) {
    return CallRequestModel(
      requestId: map['requestId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      fromUserPhotoUrl: map['fromUserPhotoUrl'],
      toUserId: map['toUserId'] ?? '',
      streamId: map['streamId'] ?? '',
      requestedAt: DateTime.parse(map['requestedAt']),
      status: map['status'] ?? 'pending',
      acceptedAt: map['acceptedAt'] != null 
          ? DateTime.parse(map['acceptedAt']) 
          : null,
      rejectedAt: map['rejectedAt'] != null 
          ? DateTime.parse(map['rejectedAt']) 
          : null,
      cancelledAt: map['cancelledAt'] != null 
          ? DateTime.parse(map['cancelledAt']) 
          : null,
    );
  }

  CallRequestModel copyWith({
    String? requestId,
    String? fromUserId,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? toUserId,
    String? streamId,
    DateTime? requestedAt,
    String? status,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    DateTime? cancelledAt,
  }) {
    return CallRequestModel(
      requestId: requestId ?? this.requestId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserPhotoUrl: fromUserPhotoUrl ?? this.fromUserPhotoUrl,
      toUserId: toUserId ?? this.toUserId,
      streamId: streamId ?? this.streamId,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}



