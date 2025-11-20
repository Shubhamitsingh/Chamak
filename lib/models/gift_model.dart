import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for virtual gifts sent from users to hosts
class GiftModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String giftType; // 'rose', 'diamond', 'car', etc.
  final int uCoinsSpent; // User Coins spent
  final int cCoinsEarned; // Host Coins earned (after conversion)
  final DateTime timestamp;
  final String? senderName;
  final String? receiverName;
  
  GiftModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.giftType,
    required this.uCoinsSpent,
    required this.cCoinsEarned,
    required this.timestamp,
    this.senderName,
    this.receiverName,
  });

  // Convert from Firestore
  factory GiftModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GiftModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      giftType: data['giftType'] ?? 'rose',
      uCoinsSpent: data['uCoinsSpent'] ?? 0,
      cCoinsEarned: data['cCoinsEarned'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderName: data['senderName'],
      receiverName: data['receiverName'],
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'giftType': giftType,
      'uCoinsSpent': uCoinsSpent,
      'cCoinsEarned': cCoinsEarned,
      'timestamp': Timestamp.fromDate(timestamp),
      'senderName': senderName,
      'receiverName': receiverName,
    };
  }
}

/// Available gift types with their costs
class GiftType {
  final String id;
  final String name;
  final String emoji;
  final int uCoinCost; // Cost in User Coins
  final int cCoinValue; // Value in Host Coins (after conversion)
  
  const GiftType({
    required this.id,
    required this.name,
    required this.emoji,
    required this.uCoinCost,
    required this.cCoinValue,
  });
  
  // Predefined gift types
  static const List<GiftType> availableGifts = [
    GiftType(
      id: 'rose',
      name: 'Rose',
      emoji: '🌹',
      uCoinCost: 10,
      cCoinValue: 50, // 10 U → 50 C (5x conversion)
    ),
    GiftType(
      id: 'heart',
      name: 'Heart',
      emoji: '❤️',
      uCoinCost: 20,
      cCoinValue: 100, // 20 U → 100 C
    ),
    GiftType(
      id: 'diamond',
      name: 'Diamond',
      emoji: '💎',
      uCoinCost: 50,
      cCoinValue: 250, // 50 U → 250 C
    ),
    GiftType(
      id: 'crown',
      name: 'Crown',
      emoji: '👑',
      uCoinCost: 100,
      cCoinValue: 500, // 100 U → 500 C
    ),
    GiftType(
      id: 'car',
      name: 'Sports Car',
      emoji: '🏎️',
      uCoinCost: 500,
      cCoinValue: 2500, // 500 U → 2500 C
    ),
    GiftType(
      id: 'rocket',
      name: 'Rocket',
      emoji: '🚀',
      uCoinCost: 1000,
      cCoinValue: 5000, // 1000 U → 5000 C
    ),
  ];
  
  // Get gift by ID
  static GiftType? getGiftById(String id) {
    try {
      return availableGifts.firstWhere((gift) => gift.id == id);
    } catch (e) {
      return null;
    }
  }
}


































