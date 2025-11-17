class LiveStreamModel {
  final String streamId;
  final String channelName;
  final String hostId;
  final String hostName;
  final String? hostPhotoUrl;
  final String title;
  final int viewerCount;
  final DateTime startedAt;
  final bool isActive;
  final String? thumbnailUrl;

  LiveStreamModel({
    required this.streamId,
    required this.channelName,
    required this.hostId,
    required this.hostName,
    this.hostPhotoUrl,
    required this.title,
    this.viewerCount = 0,
    required this.startedAt,
    this.isActive = true,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'streamId': streamId,
      'channelName': channelName,
      'hostId': hostId,
      'hostName': hostName,
      'hostPhotoUrl': hostPhotoUrl,
      'title': title,
      'viewerCount': viewerCount,
      'startedAt': startedAt.toIso8601String(),
      'isActive': isActive,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory LiveStreamModel.fromMap(Map<String, dynamic> map) {
    return LiveStreamModel(
      streamId: map['streamId'] ?? '',
      channelName: map['channelName'] ?? '',
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      hostPhotoUrl: map['hostPhotoUrl'],
      title: map['title'] ?? '',
      viewerCount: map['viewerCount'] ?? 0,
      startedAt: DateTime.parse(map['startedAt']),
      isActive: map['isActive'] ?? true,
      thumbnailUrl: map['thumbnailUrl'],
    );
  }

  LiveStreamModel copyWith({
    String? streamId,
    String? channelName,
    String? hostId,
    String? hostName,
    String? hostPhotoUrl,
    String? title,
    int? viewerCount,
    DateTime? startedAt,
    bool? isActive,
    String? thumbnailUrl,
  }) {
    return LiveStreamModel(
      streamId: streamId ?? this.streamId,
      channelName: channelName ?? this.channelName,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostPhotoUrl: hostPhotoUrl ?? this.hostPhotoUrl,
      title: title ?? this.title,
      viewerCount: viewerCount ?? this.viewerCount,
      startedAt: startedAt ?? this.startedAt,
      isActive: isActive ?? this.isActive,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}




















