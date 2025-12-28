import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized service for all coin operations
/// Ensures atomic updates to both users and wallets collections
class CoinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's coin balance (U Coins)
  /// PRIMARY SOURCE: users collection uCoins field
  /// FALLBACK: wallets collection balance field
  Future<int> getCurrentUserBalance() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      // PRIMARY: Read from users collection (source of truth)
      final userDoc = await _firestore.collection('users').doc(userId).get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (userDoc.exists) {
        final userData = userDoc.data();
        final uCoins = (userData?['uCoins'] as int?) ?? 0;
        final coins = (userData?['coins'] as int?) ?? 0;

        // ALWAYS use uCoins as primary (it's always updated during deductions)
        // Only use coins if uCoins is 0 and coins has value (legacy data)
        final balance = uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);

        if (balance > 0) {
          return balance;
        }
      }

      // FALLBACK: Read from wallets collection if users collection doesn't have balance
      final walletDoc = await _firestore.collection('wallets').doc(userId).get();
      if (walletDoc.exists) {
        final walletData = walletDoc.data();
        return (walletData?['balance'] as int?) ?? 
               (walletData?['coins'] as int?) ?? 0;
      }

      return 0;
    } catch (e) {
      print('❌ CoinService: Error getting balance: $e');
      return 0;
    }
  }

  /// Stream current user's coin balance (real-time updates)
  /// PRIMARY SOURCE: users collection uCoins field
  Stream<int> streamCurrentUserBalance() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    // Listen to users collection (PRIMARY SOURCE OF TRUTH)
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data();
        final uCoins = (userData?['uCoins'] as int?) ?? 0;
        final coins = (userData?['coins'] as int?) ?? 0;

        // ALWAYS use uCoins as primary
        // Only use coins if uCoins is 0 and coins has value (legacy data)
        return uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
      }
      return 0;
    });
  }

  /// Add coins to user (atomic update to both collections)
  /// Used for: Purchases, rewards, bonuses
  Future<bool> addCoins({
    required String userId,
    required int coins,
    String? transactionId,
    String? description,
  }) async {
    try {
      // Get user data to check current balance and create wallet if needed
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final currentUCoins = (userData?['uCoins'] as int?) ?? 0;
      final userName = userData?['displayName'] as String? ?? '';
      final newUCoinsBalance = currentUCoins + coins;

      // Check if wallet document exists
      final walletRef = _firestore.collection('wallets').doc(userId);
      final walletDoc = await walletRef.get();

      // Use batch write for atomic operations
      final batch = _firestore.batch();

      // 1. Update users collection (PRIMARY SOURCE OF TRUTH)
      batch.update(
        _firestore.collection('users').doc(userId),
        {
          'uCoins': FieldValue.increment(coins),
        },
      );

      // 2. Update or create wallets collection (SYNC WITH USERS COLLECTION)
      if (walletDoc.exists) {
        // Update existing wallet using atomic increment
        batch.update(
          walletRef,
          {
            'balance': FieldValue.increment(coins),
            'coins': FieldValue.increment(coins),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      } else {
        // Create wallet document if it doesn't exist
        batch.set(
          walletRef,
          {
            'userId': userId,
            'userName': userName,
            'balance': newUCoinsBalance,
            'coins': newUCoinsBalance,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      // 3. Record transaction if transactionId provided
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

      print('✅ CoinService: Added $coins coins atomically. New balance: $newUCoinsBalance');
      return true;
    } catch (e) {
      print('❌ CoinService: Error adding coins: $e');
      return false;
    }
  }

  /// Deduct coins from user (atomic update to both collections)
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

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userName = userData?['displayName'] as String? ?? '';

      // Check if wallet document exists
      final walletRef = _firestore.collection('wallets').doc(userId);
      final walletDoc = await walletRef.get();

      // Use batch write for atomic operations
      final batch = _firestore.batch();

      // 1. Deduct from users collection (PRIMARY UPDATE - ATOMIC)
      batch.update(
        _firestore.collection('users').doc(userId),
        {
          'uCoins': FieldValue.increment(-coins),
        },
      );

      // 2. Update or create wallets collection (SYNC WITH USERS COLLECTION - ATOMIC)
      if (walletDoc.exists) {
        // Update existing wallet using atomic increment (stays in sync)
        batch.update(
          walletRef,
          {
            'balance': FieldValue.increment(-coins),
            'coins': FieldValue.increment(-coins),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      } else {
        // Create wallet document if it doesn't exist
        final currentUCoins = (userData?['uCoins'] as int?) ?? 0;
        final newUCoinsBalance = currentUCoins - coins;
        batch.set(
          walletRef,
          {
            'userId': userId,
            'userName': userName,
            'balance': newUCoinsBalance,
            'coins': newUCoinsBalance,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      // 3. Record transaction if transactionId provided
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

      print('✅ CoinService: Deducted $coins coins atomically. Remaining balance: ${balance - coins}');
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

  /// Sync wallets collection with users collection (for legacy data)
  /// This ensures wallets collection is always in sync with users collection
  Future<bool> syncWalletWithUsers(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final uCoins = (userData?['uCoins'] as int?) ?? 0;
      final coins = (userData?['coins'] as int?) ?? 0;
      final userName = userData?['displayName'] as String? ?? '';

      // Use uCoins as primary, fallback to coins
      final balance = uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);

      final walletRef = _firestore.collection('wallets').doc(userId);
      final walletDoc = await walletRef.get();

      if (walletDoc.exists) {
        // Update existing wallet
        await walletRef.update({
          'balance': balance,
          'coins': balance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create wallet if it doesn't exist
        await walletRef.set({
          'userId': userId,
          'userName': userName,
          'balance': balance,
          'coins': balance,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ CoinService: Synced wallet with users collection. Balance: $balance');
      return true;
    } catch (e) {
      print('❌ CoinService: Error syncing wallet: $e');
      return false;
    }
  }
}











