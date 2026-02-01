import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized service for all coin operations
/// SINGLE SOURCE OF TRUTH: users collection uCoins field
/// Wallets collection is deprecated and will be removed
class CoinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's coin balance (U Coins)
  /// SINGLE SOURCE OF TRUTH: users collection uCoins field
  Future<int> getCurrentUserBalance() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      // Read from users collection (single source of truth)
      final userDoc = await _firestore.collection('users').doc(userId).get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (userDoc.exists) {
        final userData = userDoc.data();
        final uCoins = (userData?['uCoins'] as int?) ?? 0;
        final coins = (userData?['coins'] as int?) ?? 0;

        // Use uCoins as primary, fallback to coins for legacy data migration
        return uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
      }

      return 0;
    } catch (e) {
      print('❌ CoinService: Error getting balance: $e');
      return 0;
    }
  }

  /// Stream current user's coin balance (real-time updates)
  /// SINGLE SOURCE OF TRUTH: users collection uCoins field
  Stream<int> streamCurrentUserBalance() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    // Listen to users collection (single source of truth)
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data();
        final uCoins = (userData?['uCoins'] as int?) ?? 0;
        final coins = (userData?['coins'] as int?) ?? 0;

        // Use uCoins as primary, fallback to coins for legacy data
        return uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
      }
      return 0;
    });
  }

  /// Add coins to user
  /// SINGLE SOURCE OF TRUTH: users collection uCoins field
  /// Used for: Purchases, rewards, bonuses
  Future<bool> addCoins({
    required String userId,
    required int coins,
    String? transactionId,
    String? description,
  }) async {
    try {
      // Use batch write for atomic operations
      final batch = _firestore.batch();

      // Update users collection (single source of truth)
      batch.update(
        _firestore.collection('users').doc(userId),
        {
          'uCoins': FieldValue.increment(coins),
        },
      );

      // Record transaction if transactionId provided
      if (transactionId != null) {
        batch.set(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .doc(transactionId),
          {
            'type': 'credit',
            'coins': coins,
            'description': description ?? 'Coins added',
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      }

      // Commit all changes atomically
      await batch.commit();

      print('✅ CoinService: Added $coins coins. Updated users.uCoins (single source of truth)');
      return true;
    } catch (e) {
      print('❌ CoinService: Error adding coins: $e');
      return false;
    }
  }

  /// Deduct coins from user
  /// SINGLE SOURCE OF TRUTH: users collection uCoins field
  /// Used for: Gift sending, call charges, purchases
  Future<bool> deductCoins({
    required String userId,
    required int coins,
    String? transactionId,
    String? description,
  }) async {
    try {
      // Check balance before deducting
      final balance = await getCurrentUserBalance();
      if (balance < coins) {
        print('❌ CoinService: Insufficient balance: $balance < $coins');
        return false;
      }

      // Use batch write for atomic operations
      final batch = _firestore.batch();

      // Deduct from users collection (single source of truth)
      batch.update(
        _firestore.collection('users').doc(userId),
        {
          'uCoins': FieldValue.increment(-coins),
        },
      );

      // Record transaction if transactionId provided
      if (transactionId != null) {
        batch.set(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .doc(transactionId),
          {
            'type': 'debit',
            'coins': coins,
            'description': description ?? 'Coins deducted',
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      }

      // Commit all changes atomically
      await batch.commit();

      print('✅ CoinService: Deducted $coins coins. Remaining balance: ${balance - coins}');
      return true;
    } catch (e) {
      print('❌ CoinService: Error deducting coins: $e');
      return false;
    }
  }

  /// Check if user has enough coins
  Future<bool> hasEnoughCoins(int requiredCoins) async {
    final balance = await getCurrentUserBalance();
    return balance >= requiredCoins;
  }

  /// Migrate legacy coins field to uCoins (one-time migration helper)
  /// This helps migrate old data where coins field was used instead of uCoins
  Future<bool> migrateLegacyCoins(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final uCoins = (userData?['uCoins'] as int?) ?? 0;
      final coins = (userData?['coins'] as int?) ?? 0;

      // If coins has value but uCoins is 0, migrate
      if (coins > 0 && uCoins == 0) {
        await _firestore.collection('users').doc(userId).update({
          'uCoins': coins,
          'coins': FieldValue.delete(), // Remove legacy field
        });
        print('✅ CoinService: Migrated $coins legacy coins to uCoins');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ CoinService: Error migrating legacy coins: $e');
      return false;
    }
  }
}











