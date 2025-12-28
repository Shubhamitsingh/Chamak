import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String? qrCodeUrl;
  final String appLink;
  final String? referralCode;
  final DateTime createdAt;
  final int shareCount;
  final int rewardEarned;
  final bool isCustom; // true if user uploaded, false if default

  PromotionModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.qrCodeUrl,
    required this.appLink,
    this.referralCode,
    required this.createdAt,
    this.shareCount = 0,
    this.rewardEarned = 0,
    this.isCustom = false,
  });

  // Convert Firestore document to PromotionModel
  factory PromotionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return DateTime.now();
    }

    return PromotionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      qrCodeUrl: data['qrCodeUrl'],
      appLink: data['appLink'] ?? '',
      referralCode: data['referralCode'],
      createdAt: parseTimestamp(data['createdAt']),
      shareCount: data['shareCount'] ?? 0,
      rewardEarned: data['rewardEarned'] ?? 0,
      isCustom: data['isCustom'] ?? false,
    );
  }

  // Convert PromotionModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'qrCodeUrl': qrCodeUrl,
      'appLink': appLink,
      'referralCode': referralCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'shareCount': shareCount,
      'rewardEarned': rewardEarned,
      'isCustom': isCustom,
    };
  }

  // Create a copy with updated fields
  PromotionModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? qrCodeUrl,
    String? appLink,
    String? referralCode,
    DateTime? createdAt,
    int? shareCount,
    int? rewardEarned,
    bool? isCustom,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      appLink: appLink ?? this.appLink,
      referralCode: referralCode ?? this.referralCode,
      createdAt: createdAt ?? this.createdAt,
      shareCount: shareCount ?? this.shareCount,
      rewardEarned: rewardEarned ?? this.rewardEarned,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}















