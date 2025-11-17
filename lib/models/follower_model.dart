import 'package:cloud_firestore/cloud_firestore.dart';

class FollowerModel {
  final String followerId;
  final String followerName;
  final String followerImage;
  final String followerNumericId;
  final DateTime followedAt;

  FollowerModel({
    required this.followerId,
    required this.followerName,
    required this.followerImage,
    required this.followerNumericId,
    required this.followedAt,
  });

  // Create from Firestore document
  factory FollowerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FollowerModel(
      followerId: doc.id,
      followerName: data['followerName'] ?? '',
      followerImage: data['followerImage'] ?? '',
      followerNumericId: data['followerNumericId'] ?? '',
      followedAt: (data['followedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'followerName': followerName,
      'followerImage': followerImage,
      'followerNumericId': followerNumericId,
      'followedAt': Timestamp.fromDate(followedAt),
    };
  }

  FollowerModel copyWith({
    String? followerId,
    String? followerName,
    String? followerImage,
    String? followerNumericId,
    DateTime? followedAt,
  }) {
    return FollowerModel(
      followerId: followerId ?? this.followerId,
      followerName: followerName ?? this.followerName,
      followerImage: followerImage ?? this.followerImage,
      followerNumericId: followerNumericId ?? this.followerNumericId,
      followedAt: followedAt ?? this.followedAt,
    );
  }
}


























