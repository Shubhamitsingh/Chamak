import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String numericUserId; // New: Numeric-only ID for display
  final String phoneNumber;
  final String countryCode;
  final String? displayName;
  final String? photoURL;
  final String? coverURL;
  final String? bio;
  final int? age;
  final String? gender;
  final String? country;
  final String? city;
  final String? language;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  final int followersCount;
  final int followingCount;
  final int level;
  final int coins; // Legacy field (kept for compatibility)
  final int uCoins; // User Coins - what users buy and spend
  final int cCoins; // Host Coins (C Coins) - what hosts earn
  final String? fcmToken; // FCM token for push notifications

  UserModel({
    required this.userId,
    required this.numericUserId,
    required this.phoneNumber,
    required this.countryCode,
    this.displayName,
    this.photoURL,
    this.coverURL,
    this.bio,
    this.age,
    this.gender,
    this.country,
    this.city,
    this.language,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
    this.followersCount = 0,
    this.followingCount = 0,
    this.level = 1,
    this.coins = 0, // Default 0 coins for new users
    this.uCoins = 0, // Default 0 U Coins (user spends these)
    this.cCoins = 0, // Default 0 C Coins (hosts earn these)
    this.fcmToken,
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Safely handle Timestamp fields (might be null if not yet set by server)
    DateTime parseTimestamp(dynamic timestamp, DateTime fallback) {
      if (timestamp == null) return fallback;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return fallback;
    }
    
    final now = DateTime.now();
    
    return UserModel(
      userId: doc.id,
      numericUserId: data['numericUserId'] ?? '', // New numeric ID field
      phoneNumber: data['phoneNumber'] ?? '',
      countryCode: data['countryCode'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      coverURL: data['coverURL'],
      bio: data['bio'],
      age: data['age'],
      gender: data['gender'],
      country: data['country'],
      city: data['city'],
      language: data['language'],
      createdAt: parseTimestamp(data['createdAt'], now),
      lastLogin: parseTimestamp(data['lastLogin'], now),
      isActive: data['isActive'] ?? true,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      level: data['level'] ?? 1,
      coins: data['coins'] ?? 0, // Default 0 coins
      uCoins: data['uCoins'] ?? 0, // User Coins
      cCoins: data['cCoins'] ?? 0, // Host/Creator Coins
      fcmToken: data['fcmToken'],
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'numericUserId': numericUserId, // Store numeric ID
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'displayName': displayName,
      'photoURL': photoURL,
      'coverURL': coverURL,
      'bio': bio,
      'age': age,
      'gender': gender,
      'country': country,
      'city': city,
      'language': language,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isActive': isActive,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'level': level,
      'coins': coins, // Store coins balance
      'uCoins': uCoins, // User Coins
      'cCoins': cCoins, // Host Coins
      'fcmToken': fcmToken,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? numericUserId,
    String? displayName,
    String? photoURL,
    String? coverURL,
    String? bio,
    int? age,
    String? gender,
    String? country,
    String? city,
    String? language,
    DateTime? lastLogin,
    bool? isActive,
    int? followersCount,
    int? followingCount,
    int? level,
    int? coins,
    int? uCoins,
    int? cCoins,
    String? fcmToken,
  }) {
    return UserModel(
      userId: userId,
      numericUserId: numericUserId ?? this.numericUserId,
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      coverURL: coverURL ?? this.coverURL,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      city: city ?? this.city,
      language: language ?? this.language,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      uCoins: uCoins ?? this.uCoins,
      cCoins: cCoins ?? this.cCoins,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  // Convenience getters for compatibility
  String get uid => userId;
  String get name => displayName ?? 'User';
  String get profileImage => photoURL ?? '';

  @override
  String toString() {
    return 'UserModel(userId: $userId, phone: $countryCode$phoneNumber, name: $displayName)';
  }
}

