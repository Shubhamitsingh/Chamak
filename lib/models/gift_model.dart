import 'package:cloud_firestore/cloud_firestore.dart';

class GiftModel {
  // Core properties (for chat and live stream gifts)
  final String id;
  final String name;
  final String emoji;
  final int cost;
  final String? category; // 'Hot', 'Lucky', 'Funny', 'Luxury'
  final String? giftImageUrl; // Optional image URL for future use

  // For earnings/received gifts (from Firestore)
  final DateTime? timestamp;
  final int? cCoinsEarned;
  final String? senderName;
  final String? senderId;
  final String? receiverId;
  final String? streamId;

  // Legacy properties (for backward compatibility with chat)
  String get giftId => id;
  String get giftName => name;
  String get giftEmoji => emoji;
  int get giftCost => cost;

  GiftModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    this.category,
    this.giftImageUrl,
    // For earnings
    this.timestamp,
    this.cCoinsEarned,
    this.senderName,
    this.senderId,
    this.receiverId,
    this.streamId,
  });

  // Create from Firestore document (for earnings)
  factory GiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return GiftModel(
      id: data['id']?.toString() ?? data['giftId']?.toString() ?? '',
      name: data['name']?.toString() ?? data['giftName']?.toString() ?? '',
      emoji: data['emoji']?.toString() ?? data['giftEmoji']?.toString() ?? '🎁',
      cost: (data['cost'] is int ? data['cost'] : (data['cost'] as num?)?.toInt()) ?? 
            (data['giftCost'] is int ? data['giftCost'] : (data['giftCost'] as num?)?.toInt()) ?? 0,
      category: data['category']?.toString(),
      giftImageUrl: data['giftImageUrl']?.toString(),
      // Earnings fields
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      cCoinsEarned: data['cCoinsEarned'] is int ? data['cCoinsEarned'] : (data['cCoinsEarned'] as num?)?.toInt(),
      senderName: data['senderName']?.toString(),
      senderId: data['senderId']?.toString(),
      receiverId: data['receiverId']?.toString(),
      streamId: data['streamId']?.toString(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'cost': cost,
      if (category != null) 'category': category,
      if (giftImageUrl != null) 'giftImageUrl': giftImageUrl,
      // Legacy compatibility
      'giftId': id,
      'giftName': name,
      'giftEmoji': emoji,
      'giftCost': cost,
      // Earnings fields
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
      if (cCoinsEarned != null) 'cCoinsEarned': cCoinsEarned,
      if (senderName != null) 'senderName': senderName,
      if (senderId != null) 'senderId': senderId,
      if (receiverId != null) 'receiverId': receiverId,
      if (streamId != null) 'streamId': streamId,
    };
  }

  // Create from Map (backward compatibility)
  factory GiftModel.fromMap(Map<String, dynamic> map) {
    return GiftModel(
      id: map['id']?.toString() ?? map['giftId']?.toString() ?? '',
      name: map['name']?.toString() ?? map['giftName']?.toString() ?? '',
      emoji: map['emoji']?.toString() ?? map['giftEmoji']?.toString() ?? '🎁',
      cost: (map['cost'] is int ? map['cost'] : (map['cost'] as num?)?.toInt()) ?? 
            (map['giftCost'] is int ? map['giftCost'] : (map['giftCost'] as num?)?.toInt()) ?? 0,
      category: map['category']?.toString(),
      giftImageUrl: map['giftImageUrl']?.toString(),
      timestamp: map['timestamp'] is Timestamp ? (map['timestamp'] as Timestamp).toDate() : null,
      cCoinsEarned: map['cCoinsEarned'] is int ? map['cCoinsEarned'] : (map['cCoinsEarned'] as num?)?.toInt(),
      senderName: map['senderName']?.toString(),
      senderId: map['senderId']?.toString(),
      receiverId: map['receiverId']?.toString(),
      streamId: map['streamId']?.toString(),
    );
  }

  // Default list of gifts for chat
  static List<GiftModel> getDefaultGifts() {
    return [
      GiftModel(
        id: 'rose',
        name: 'Rose',
        emoji: '🌹',
        cost: 50,
      ),
      GiftModel(
        id: 'heart',
        name: 'Heart',
        emoji: '❤️',
        cost: 100,
      ),
      GiftModel(
        id: 'cake',
        name: 'Cake',
        emoji: '🎂',
        cost: 150,
      ),
      GiftModel(
        id: 'star',
        name: 'Star',
        emoji: '⭐',
        cost: 200,
      ),
      GiftModel(
        id: 'fire',
        name: 'Fire',
        emoji: '🔥',
        cost: 250,
      ),
      GiftModel(
        id: 'diamond',
        name: 'Diamond',
        emoji: '💎',
        cost: 300,
      ),
      GiftModel(
        id: 'rocket',
        name: 'Rocket',
        emoji: '🚀',
        cost: 400,
      ),
      GiftModel(
        id: 'crown',
        name: 'Crown',
        emoji: '👑',
        cost: 500,
      ),
    ];
  }

  // Hot gifts (for live streams)
  static List<GiftModel> getHotGifts() {
    return [
      GiftModel(id: 'ganesha', name: 'Ganesha', cost: 500, category: 'Hot', emoji: '🕉️'),
      GiftModel(id: 'sunflowers', name: 'Sunflowers', cost: 600, category: 'Hot', emoji: '🌻'),
      GiftModel(id: 'star', name: 'Star', cost: 700, category: 'Hot', emoji: '⭐'),
      GiftModel(id: 'fire', name: 'Fire', cost: 250, category: 'Hot', emoji: '🔥'),
      GiftModel(id: 'rocket', name: 'Rocket', cost: 400, category: 'Hot', emoji: '🚀'),
    ];
  }

  // Lucky gifts (for live streams)
  static List<GiftModel> getLuckyGifts() {
    return [
      GiftModel(id: 'clover', name: 'Clover', cost: 350, category: 'Lucky', emoji: '🍀'),
      GiftModel(id: 'diamond', name: 'Diamond', cost: 300, category: 'Lucky', emoji: '💎'),
      GiftModel(id: 'star', name: 'Star', cost: 200, category: 'Lucky', emoji: '⭐'),
      GiftModel(id: 'gem', name: 'Gem', cost: 450, category: 'Lucky', emoji: '💠'),
    ];
  }

  // Funny gifts (for live streams)
  static List<GiftModel> getFunnyGifts() {
    return [
      GiftModel(id: 'donut', name: 'Donut', cost: 800, category: 'Funny', emoji: '🍩'),
      GiftModel(id: 'pacman', name: 'Pac-Man', cost: 900, category: 'Funny', emoji: '👾'),
      GiftModel(id: 'party', name: 'Party', cost: 550, category: 'Funny', emoji: '🎉'),
      GiftModel(id: 'balloon', name: 'Balloon', cost: 650, category: 'Funny', emoji: '🎈'),
    ];
  }

  // Luxury gifts (for live streams)
  static List<GiftModel> getLuxuryGifts() {
    return [
      GiftModel(id: 'throne', name: 'Throne', cost: 1000, category: 'Luxury', emoji: '👑'),
      GiftModel(id: 'crown', name: 'Crown', cost: 500, category: 'Luxury', emoji: '👑'),
      GiftModel(id: 'diamond', name: 'Diamond', cost: 300, category: 'Luxury', emoji: '💎'),
      GiftModel(id: 'trophy', name: 'Trophy', cost: 950, category: 'Luxury', emoji: '🏆'),
    ];
  }
}
