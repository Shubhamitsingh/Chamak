import 'package:cloud_firestore/cloud_firestore.dart';

class GiftModel {
  // Catalog fields (for gift selection UI)
  final String id;
  final String? name;
  final int? cost; // Cost in diamonds/U Coins
  final String? category; // Hot, Lucky, Funny, Luxury
  final String? emoji; // Emoji representation of the gift
  final String? imageUrl; // Optional image URL

  // Transaction fields (for gift history/earnings)
  final String? senderId;
  final String? receiverId;
  final String? giftType;
  final int? uCoinsSpent;
  final int? cCoinsEarned;
  final DateTime? timestamp;
  final String? senderName;
  final String? receiverName;
  
  GiftModel({
    // Catalog fields
    required this.id,
    this.name,
    this.cost,
    this.category,
    this.emoji,
    this.imageUrl,
    // Transaction fields
    this.senderId,
    this.receiverId,
    this.giftType,
    this.uCoinsSpent,
    this.cCoinsEarned,
    this.timestamp,
    this.senderName,
    this.receiverName,
  });

  // Factory constructor for Firestore documents (gift transactions)
  factory GiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftModel(
      id: doc.id,
      senderId: data['senderId'] as String?,
      receiverId: data['receiverId'] as String?,
      giftType: data['giftType'] as String?,
      uCoinsSpent: data['uCoinsSpent'] as int?,
      cCoinsEarned: data['cCoinsEarned'] as int?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      senderName: data['senderName'] as String?,
      receiverName: data['receiverName'] as String?,
    );
  }

  // Sample gifts data for catalog
  static List<GiftModel> getHotGifts() {
    // Hot gifts with cost range 1000-2990, arranged logically
    return [
      // Lower range (1000-1500)
      GiftModel(id: 'h1', name: 'Kiss', cost: 1000, category: 'Hot', emoji: '💋'),
      GiftModel(id: 'h2', name: 'Red Heart', cost: 1100, category: 'Hot', emoji: '❤️'),
      GiftModel(id: 'h3', name: 'Rose', cost: 1200, category: 'Hot', emoji: '🌹'),
      GiftModel(id: 'h4', name: 'Chocolate', cost: 1300, category: 'Hot', emoji: '🍫'),
      GiftModel(id: 'h5', name: 'Butterfly', cost: 1400, category: 'Hot', emoji: '🦋'),
      GiftModel(id: 'h6', name: 'Love Letter', cost: 1500, category: 'Hot', emoji: '💌'),
      
      // Mid range (1600-2200)
      GiftModel(id: 'h7', name: 'Bouquet', cost: 1600, category: 'Hot', emoji: '💐'),
      GiftModel(id: 'h8', name: 'Lipstick', cost: 1700, category: 'Hot', emoji: '💄'),
      GiftModel(id: 'h9', name: 'Sparkles', cost: 1800, category: 'Hot', emoji: '✨'),
      GiftModel(id: 'h10', name: 'Fire', cost: 1900, category: 'Hot', emoji: '🔥'),
      GiftModel(id: 'h11', name: 'Wine', cost: 2000, category: 'Hot', emoji: '🍷'),
      GiftModel(id: 'h12', name: 'Luxury Cake', cost: 2100, category: 'Hot', emoji: '🎂'),
      GiftModel(id: 'h13', name: 'Heart Fly', cost: 2200, category: 'Hot', emoji: '💝'),
      
      // Higher range (2300-2990)
      GiftModel(id: 'h14', name: 'Ring', cost: 2300, category: 'Hot', emoji: '💍'),
      GiftModel(id: 'h15', name: 'Diamond', cost: 2500, category: 'Hot', emoji: '💎'),
      GiftModel(id: 'h16', name: 'Golden Watch', cost: 2990, category: 'Hot', emoji: '⌚'),
    ];
  }

  static List<GiftModel> getLuckyGifts() {
    // Lucky gifts with cost range 2000-3999, arranged logically
    return [
      // Lower range (2000-2500)
      GiftModel(id: 'l1', name: 'Coin', cost: 2000, category: 'Lucky', emoji: '🪙'),
      GiftModel(id: 'l2', name: 'Lucky Lock', cost: 2100, category: 'Lucky', emoji: '🔒'),
      GiftModel(id: 'l3', name: 'Key', cost: 2200, category: 'Lucky', emoji: '🗝️'),
      GiftModel(id: 'l4', name: 'Four Leaf', cost: 2300, category: 'Lucky', emoji: '🍀'),
      GiftModel(id: 'l5', name: 'Clover', cost: 2400, category: 'Lucky', emoji: '☘️'),
      GiftModel(id: 'l6', name: 'Wishbone', cost: 2500, category: 'Lucky', emoji: '🦴'),
      
      // Mid range (2600-3200)
      GiftModel(id: 'l7', name: 'Lucky Win', cost: 2600, category: 'Lucky', emoji: '🔨'),
      GiftModel(id: 'l8', name: 'Horseshoe', cost: 2700, category: 'Lucky', emoji: '🧲'),
      GiftModel(id: 'l9', name: 'Dice', cost: 2800, category: 'Lucky', emoji: '🎲'),
      GiftModel(id: 'l10', name: 'Lucky Candy', cost: 2900, category: 'Lucky', emoji: '🍬'),
      GiftModel(id: 'l11', name: 'Lucky Star', cost: 3000, category: 'Lucky', emoji: '⭐'),
      GiftModel(id: 'l12', name: 'Rainbow', cost: 3100, category: 'Lucky', emoji: '🌈'),
      GiftModel(id: 'l13', name: 'Lucky Cat', cost: 3200, category: 'Lucky', emoji: '🐱'),
      
      // Higher range (3300-3999)
      GiftModel(id: 'l14', name: 'Magic Wand', cost: 3500, category: 'Lucky', emoji: '🪄'),
      GiftModel(id: 'l15', name: 'Crystal Ball', cost: 3700, category: 'Lucky', emoji: '🔮'),
      GiftModel(id: 'l16', name: 'Treasure', cost: 3999, category: 'Lucky', emoji: '💎'),
    ];
  }

  static List<GiftModel> getFunnyGifts() {
    // Funny gifts with cost range 500-1999, arranged logically with playful/funny emojis
    return [
      // Lower range (500-800) - Food & Basic Fun
      GiftModel(id: 'f1', name: 'Cookie', cost: 500, category: 'Funny', emoji: '🍪'),
      GiftModel(id: 'f2', name: 'Banana', cost: 600, category: 'Funny', emoji: '🍌'),
      GiftModel(id: 'f3', name: 'Popcorn', cost: 700, category: 'Funny', emoji: '🍿'),
      GiftModel(id: 'f4', name: 'Lollipop', cost: 800, category: 'Funny', emoji: '🍭'),
      
      // Mid range (900-1300) - Party & Entertainment
      GiftModel(id: 'f5', name: 'Balloon', cost: 900, category: 'Funny', emoji: '🎈'),
      GiftModel(id: 'f6', name: 'Ice Cream', cost: 1000, category: 'Funny', emoji: '🍦'),
      GiftModel(id: 'f7', name: 'Cake Slice', cost: 1100, category: 'Funny', emoji: '🍰'),
      GiftModel(id: 'f8', name: 'Burger', cost: 1200, category: 'Funny', emoji: '🍔'),
      GiftModel(id: 'f9', name: 'Pizza', cost: 1300, category: 'Funny', emoji: '🍕'),
      
      // Higher range (1400-1999) - Comedy & Celebration
      GiftModel(id: 'f10', name: 'Party Popper', cost: 1400, category: 'Funny', emoji: '🎉'),
      GiftModel(id: 'f11', name: 'Confetti', cost: 1500, category: 'Funny', emoji: '🎊'),
      GiftModel(id: 'f12', name: 'Party Hat', cost: 1600, category: 'Funny', emoji: '🥳'), // Fixed emoji
      GiftModel(id: 'f13', name: 'Clown Face', cost: 1700, category: 'Funny', emoji: '🤡'),
      GiftModel(id: 'f14', name: 'Laughing', cost: 1800, category: 'Funny', emoji: '😂'),
      GiftModel(id: 'f15', name: 'Circus Tent', cost: 1900, category: 'Funny', emoji: '🎪'),
      GiftModel(id: 'f16', name: 'Trophy', cost: 1999, category: 'Funny', emoji: '🏆'),
    ];
  }

  static List<GiftModel> getLuxuryGifts() {
    // Luxury gifts with cost range 3000-4999, arranged logically
    return [
      // Lower range (3000-3500)
      GiftModel(id: 'x1', name: 'Champagne', cost: 3000, category: 'Luxury', emoji: '🍾'),
      GiftModel(id: 'x2', name: 'Pearl', cost: 3100, category: 'Luxury', emoji: '🪸'),
      GiftModel(id: 'x3', name: 'Luxury Bag', cost: 3200, category: 'Luxury', emoji: '👜'),
      GiftModel(id: 'x4', name: 'Gold Bar', cost: 3300, category: 'Luxury', emoji: '🥇'),
      GiftModel(id: 'x5', name: 'Diamond Ring', cost: 3400, category: 'Luxury', emoji: '💍'),
      GiftModel(id: 'x6', name: 'Diamond', cost: 3500, category: 'Luxury', emoji: '💎'),
      
      // Mid range (3600-4200)
      GiftModel(id: 'x7', name: 'Rolex Watch', cost: 3600, category: 'Luxury', emoji: '⌚'),
      GiftModel(id: 'x8', name: 'Money Bag', cost: 3700, category: 'Luxury', emoji: '💰'),
      GiftModel(id: 'x9', name: 'Sports Car', cost: 3800, category: 'Luxury', emoji: '🏎️'),
      GiftModel(id: 'x10', name: 'Luxury Car', cost: 3900, category: 'Luxury', emoji: '🚗'),
      GiftModel(id: 'x11', name: 'Yacht', cost: 4000, category: 'Luxury', emoji: '🛥️'),
      GiftModel(id: 'x12', name: 'Crown', cost: 4100, category: 'Luxury', emoji: '👑'),
      GiftModel(id: 'x13', name: 'Helicopter', cost: 4200, category: 'Luxury', emoji: '🚁'),
      
      // Higher range (4300-4999)
      GiftModel(id: 'x14', name: 'Private Jet', cost: 4500, category: 'Luxury', emoji: '✈️'),
      GiftModel(id: 'x15', name: 'Villa', cost: 4800, category: 'Luxury', emoji: '🏰'),
      GiftModel(id: 'x16', name: 'Castle', cost: 4999, category: 'Luxury', emoji: '🏯'),
    ];
  }

  static List<GiftModel> getAllGifts() {
    return [
      ...getHotGifts(),
      ...getLuckyGifts(),
      ...getFunnyGifts(),
      ...getLuxuryGifts(),
    ];
  }
}
