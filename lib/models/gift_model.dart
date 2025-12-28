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
    return [
      GiftModel(id: 'h1', name: 'Rose', cost: 29999, category: 'Hot', emoji: '🌹'),
      GiftModel(id: 'h2', name: 'Luxury Cake', cost: 69999, category: 'Hot', emoji: '🎂'),
      GiftModel(id: 'h3', name: 'Heart Fly', cost: 99999, category: 'Hot', emoji: '💝'),
      GiftModel(id: 'h4', name: 'Golden Watch', cost: 199999, category: 'Hot', emoji: '⌚'),
      GiftModel(id: 'h5', name: 'Kiss', cost: 19999, category: 'Hot', emoji: '💋'),
      GiftModel(id: 'h6', name: 'Love Letter', cost: 39999, category: 'Hot', emoji: '💌'),
      GiftModel(id: 'h7', name: 'Ring', cost: 149999, category: 'Hot', emoji: '💍'),
      GiftModel(id: 'h8', name: 'Bouquet', cost: 49999, category: 'Hot', emoji: '💐'),
      GiftModel(id: 'h9', name: 'Sparkles', cost: 89999, category: 'Hot', emoji: '✨'),
      GiftModel(id: 'h10', name: 'Fire', cost: 129999, category: 'Hot', emoji: '🔥'),
      GiftModel(id: 'h11', name: 'Red Heart', cost: 59999, category: 'Hot', emoji: '❤️'),
      GiftModel(id: 'h12', name: 'Lipstick', cost: 79999, category: 'Hot', emoji: '💄'),
      GiftModel(id: 'h13', name: 'Chocolate', cost: 34999, category: 'Hot', emoji: '🍫'),
      GiftModel(id: 'h14', name: 'Wine', cost: 89999, category: 'Hot', emoji: '🍷'),
      GiftModel(id: 'h15', name: 'Diamond', cost: 249999, category: 'Hot', emoji: '💎'),
      GiftModel(id: 'h16', name: 'Butterfly', cost: 44999, category: 'Hot', emoji: '🦋'),
    ];
  }

  static List<GiftModel> getLuckyGifts() {
    return [
      GiftModel(id: 'l1', name: 'Lucky Lock', cost: 1777, category: 'Lucky', emoji: '🔒'),
      GiftModel(id: 'l2', name: 'Lucky Win', cost: 3777, category: 'Lucky', emoji: '🔨'),
      GiftModel(id: 'l3', name: 'Lucky Candy', cost: 5777, category: 'Lucky', emoji: '🍬'),
      GiftModel(id: 'l4', name: 'Lucky Star', cost: 7777, category: 'Lucky', emoji: '⭐'),
      GiftModel(id: 'l5', name: 'Four Leaf', cost: 2777, category: 'Lucky', emoji: '🍀'),
      GiftModel(id: 'l6', name: 'Horseshoe', cost: 4777, category: 'Lucky', emoji: '🧲'),
      GiftModel(id: 'l7', name: 'Rainbow', cost: 6777, category: 'Lucky', emoji: '🌈'),
      GiftModel(id: 'l8', name: 'Clover', cost: 8777, category: 'Lucky', emoji: '☘️'),
      GiftModel(id: 'l9', name: 'Dice', cost: 5777, category: 'Lucky', emoji: '🎲'),
      GiftModel(id: 'l10', name: 'Magic Wand', cost: 9777, category: 'Lucky', emoji: '🪄'),
      GiftModel(id: 'l11', name: 'Crystal Ball', cost: 12777, category: 'Lucky', emoji: '🔮'),
      GiftModel(id: 'l12', name: 'Treasure', cost: 15777, category: 'Lucky', emoji: '💎'),
      GiftModel(id: 'l13', name: 'Coin', cost: 1777, category: 'Lucky', emoji: '🪙'),
      GiftModel(id: 'l14', name: 'Key', cost: 3777, category: 'Lucky', emoji: '🗝️'),
      GiftModel(id: 'l15', name: 'Wishbone', cost: 5777, category: 'Lucky', emoji: '🦴'),
      GiftModel(id: 'l16', name: 'Lucky Cat', cost: 10777, category: 'Lucky', emoji: '🐱'),
    ];
  }

  static List<GiftModel> getFunnyGifts() {
    return [
      GiftModel(id: 'f1', name: 'Party Popper', cost: 1999, category: 'Funny', emoji: '🎉'),
      GiftModel(id: 'f2', name: 'Clown Face', cost: 3999, category: 'Funny', emoji: '🤡'),
      GiftModel(id: 'f3', name: 'Rocket', cost: 5999, category: 'Funny', emoji: '🚀'),
      GiftModel(id: 'f4', name: 'Trophy', cost: 9999, category: 'Funny', emoji: '🏆'),
      GiftModel(id: 'f5', name: 'Balloon', cost: 2999, category: 'Funny', emoji: '🎈'),
      GiftModel(id: 'f6', name: 'Party Hat', cost: 4999, category: 'Funny', emoji: '🎊'),
      GiftModel(id: 'f7', name: 'Confetti', cost: 3999, category: 'Funny', emoji: '🎊'),
      GiftModel(id: 'f8', name: 'Fireworks', cost: 7999, category: 'Funny', emoji: '🎆'),
      GiftModel(id: 'f9', name: 'Banana', cost: 1999, category: 'Funny', emoji: '🍌'),
      GiftModel(id: 'f10', name: 'Pizza', cost: 5999, category: 'Funny', emoji: '🍕'),
      GiftModel(id: 'f11', name: 'Burger', cost: 4999, category: 'Funny', emoji: '🍔'),
      GiftModel(id: 'f12', name: 'Ice Cream', cost: 3999, category: 'Funny', emoji: '🍦'),
      GiftModel(id: 'f13', name: 'Popcorn', cost: 2999, category: 'Funny', emoji: '🍿'),
      GiftModel(id: 'f14', name: 'Doughnut', cost: 2999, category: 'Funny', emoji: '🍩'),
      GiftModel(id: 'f15', name: 'Cookie', cost: 1999, category: 'Funny', emoji: '🍪'),
      GiftModel(id: 'f16', name: 'Cake Slice', cost: 4999, category: 'Funny', emoji: '🍰'),
    ];
  }

  static List<GiftModel> getLuxuryGifts() {
    return [
      GiftModel(id: 'x1', name: 'Diamond Ring', cost: 149999, category: 'Luxury', emoji: '💍'),
      GiftModel(id: 'x2', name: 'Crown', cost: 299999, category: 'Luxury', emoji: '👑'),
      GiftModel(id: 'x3', name: 'Money Bag', cost: 399999, category: 'Luxury', emoji: '💰'),
      GiftModel(id: 'x4', name: 'Yacht', cost: 499999, category: 'Luxury', emoji: '🛥️'),
      GiftModel(id: 'x5', name: 'Private Jet', cost: 599999, category: 'Luxury', emoji: '✈️'),
      GiftModel(id: 'x6', name: 'Sports Car', cost: 449999, category: 'Luxury', emoji: '🏎️'),
      GiftModel(id: 'x7', name: 'Diamond', cost: 349999, category: 'Luxury', emoji: '💎'),
      GiftModel(id: 'x8', name: 'Gold Bar', cost: 249999, category: 'Luxury', emoji: '🥇'),
      GiftModel(id: 'x9', name: 'Luxury Bag', cost: 199999, category: 'Luxury', emoji: '👜'),
      GiftModel(id: 'x10', name: 'Rolex Watch', cost: 399999, category: 'Luxury', emoji: '⌚'),
      GiftModel(id: 'x11', name: 'Champagne', cost: 149999, category: 'Luxury', emoji: '🍾'),
      GiftModel(id: 'x12', name: 'Villa', cost: 699999, category: 'Luxury', emoji: '🏰'),
      GiftModel(id: 'x13', name: 'Pearl', cost: 199999, category: 'Luxury', emoji: '🪸'),
      GiftModel(id: 'x14', name: 'Luxury Car', cost: 549999, category: 'Luxury', emoji: '🚗'),
      GiftModel(id: 'x15', name: 'Helicopter', cost: 649999, category: 'Luxury', emoji: '🚁'),
      GiftModel(id: 'x16', name: 'Castle', cost: 799999, category: 'Luxury', emoji: '🏯'),
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
