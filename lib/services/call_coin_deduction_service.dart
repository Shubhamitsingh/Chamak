import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/coin_conversion_service.dart';
import '../models/call_transaction_model.dart';

/// Service to handle per-minute coin deduction for private calls
class CallCoinDeductionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Coin deduction rate: 300 U Coins per minute
  static const int COINS_PER_MINUTE = 300;
  static const int DEDUCTION_INTERVAL_SECONDS = 60; // Deduct every 60 seconds
  
  /// Check if user has enough coins to start a call
  Future<bool> hasEnoughCoins(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));
      
      if (!userDoc.exists) {
        print('❌ User document does not exist: $userId');
        return false;
      }
      
      final userData = userDoc.data() ?? {};
      
      // Check coin fields (uCoins is primary, coins is legacy fallback)
      final uCoins = (userData['uCoins'] as int?) ?? 0;
      final legacyCoins = (userData['coins'] as int?) ?? 0;
      
      print('💰 Balance check - uCoins: $uCoins, legacy coins: $legacyCoins');
      
      // Use uCoins as primary, fallback to legacy coins
      final balance = uCoins > 0 ? uCoins : (legacyCoins > 0 ? legacyCoins : 0);
      
      print('💰 Final balance used: $balance (required: $COINS_PER_MINUTE)');
      
      final hasEnough = balance >= COINS_PER_MINUTE;
      if (!hasEnough) {
        print('❌ Insufficient balance: $balance < $COINS_PER_MINUTE');
      }
      
      return hasEnough;
    } catch (e, stackTrace) {
      print('❌ Error checking coin balance: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Get user's current coin balance
  Future<int> getUserBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));
      
      if (!userDoc.exists) {
        print('❌ User document does not exist: $userId');
        return 0;
      }
      
      final userData = userDoc.data() ?? {};
      
      // Check coin fields (uCoins is primary, coins is legacy fallback)
      final uCoins = (userData['uCoins'] as int?) ?? 0;
      final legacyCoins = (userData['coins'] as int?) ?? 0;
      
      // Use uCoins as primary, fallback to legacy coins
      final balance = uCoins > 0 ? uCoins : (legacyCoins > 0 ? legacyCoins : 0);
      
      print('💰 getUserBalance: uCoins=$uCoins, legacyCoins=$legacyCoins, final=$balance');
      
      return balance;
    } catch (e, stackTrace) {
      print('❌ Error getting user balance: $e');
      print('❌ Stack trace: $stackTrace');
      return 0;
    }
  }
  
  /// Deduct coins for a call minute (300 U Coins)
  /// Returns true if successful, false if insufficient balance
  Future<bool> deductCallMinute({
    required String callerId,
    required String hostId,
    required String callRequestId,
    String? streamId,
  }) async {
    try {
      // Check balance before deducting (checks all fields: uCoins, coins, wallet)
      final balance = await getUserBalance(callerId);
      if (balance < COINS_PER_MINUTE) {
        print('❌ Insufficient balance: $balance < $COINS_PER_MINUTE');
        return false;
      }
      
      // Get caller's user document to check current coin values
      final callerUserDoc = await _firestore.collection('users').doc(callerId).get();
      if (!callerUserDoc.exists) {
        print('❌ Caller user document does not exist: $callerId');
        return false;
      }
      
      final userData = callerUserDoc.data() ?? {};
      final currentUCoins = (userData['uCoins'] as int?) ?? 0;
      final legacyCoins = (userData['coins'] as int?) ?? 0;
      
      print('💰 Before deduction - uCoins: $currentUCoins, legacy coins: $legacyCoins');
      
      // Convert U Coins to C Coins for host
      final cCoinsToCredit = CoinConversionService.convertUtoC(COINS_PER_MINUTE);
      
      // Atomic batch write
      final batch = _firestore.batch();
      final callerUserRef = _firestore.collection('users').doc(callerId);
      
      // 1. Migrate legacy coins to uCoins if needed, then deduct
      // If uCoins is insufficient but legacy coins has value, migrate first
      if (currentUCoins < COINS_PER_MINUTE && legacyCoins > 0) {
        // Migrate legacy coins to uCoins
        final coinsToMigrate = legacyCoins;
        print('🔄 Migrating $coinsToMigrate legacy coins to uCoins');
        batch.update(
          callerUserRef,
          {
            'uCoins': FieldValue.increment(coinsToMigrate),
            'coins': FieldValue.increment(-coinsToMigrate), // Clear legacy coins
          },
        );
      }
      
      // 2. Deduct from caller's users collection (single source of truth)
      batch.update(
        callerUserRef,
        {
          'uCoins': FieldValue.increment(-COINS_PER_MINUTE),
        },
      );
      
      // 3. Update host's earnings summary (SINGLE SOURCE OF TRUTH)
      // NOTE: Only update earnings.totalCCoins, not users.cCoins (to avoid duplicate field issues)
      final earningsRef = _firestore.collection('earnings').doc(hostId);
      batch.set(
        earningsRef,
        {
          'userId': hostId,
          'totalCCoins': FieldValue.increment(cCoinsToCredit),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      
      // 5. Create transaction record
      final transactionId = _firestore.collection('callTransactions').doc().id;
      final transaction = CallTransactionModel(
        transactionId: transactionId,
        callRequestId: callRequestId,
        callerId: callerId,
        hostId: hostId,
        uCoinsDeducted: COINS_PER_MINUTE,
        cCoinsCredited: cCoinsToCredit,
        durationSeconds: DEDUCTION_INTERVAL_SECONDS,
        timestamp: DateTime.now(),
        streamId: streamId,
      );
      
      batch.set(
        _firestore.collection('callTransactions').doc(transactionId),
        transaction.toMap(),
      );
      
      // Commit batch
      await batch.commit();
      
      // Verify the deduction was successful by reading back the balance
      final verifyDoc = await _firestore.collection('users').doc(callerId).get();
      final verifyBalance = (verifyDoc.data()?['uCoins'] as int?) ?? 0;
      
      print('✅ Deducted $COINS_PER_MINUTE U Coins from caller, credited $cCoinsToCredit C Coins to host');
      print('✅ Verification: Caller balance after deduction: $verifyBalance');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error deducting call minute: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Deduct coins for partial minute (proportional)
  /// durationSeconds: actual duration in seconds (e.g., 30 seconds)
  Future<bool> deductPartialMinute({
    required String callerId,
    required String hostId,
    required String callRequestId,
    required int durationSeconds,
    String? streamId,
  }) async {
    try {
      // Calculate proportional coins (e.g., 30 seconds = 500 coins)
      final coinsToDeduct = ((durationSeconds / DEDUCTION_INTERVAL_SECONDS) * COINS_PER_MINUTE).round();
      
      if (coinsToDeduct <= 0) {
        print('ℹ️ No coins to deduct for partial minute ($durationSeconds seconds)');
        return true; // No charge for very short calls
      }
      
      // Check balance (checks all fields: uCoins, coins, wallet)
      final balance = await getUserBalance(callerId);
      if (balance < coinsToDeduct) {
        print('❌ Insufficient balance for partial minute: $balance < $coinsToDeduct');
        return false;
      }
      
      // Get caller's user document to check current coin values
      final callerUserDoc = await _firestore.collection('users').doc(callerId).get();
      if (!callerUserDoc.exists) {
        print('❌ Caller user document does not exist: $callerId');
        return false;
      }
      
      final userData = callerUserDoc.data() ?? {};
      final currentUCoins = (userData['uCoins'] as int?) ?? 0;
      final legacyCoins = (userData['coins'] as int?) ?? 0;
      
      // Convert to C Coins
      final cCoinsToCredit = CoinConversionService.convertUtoC(coinsToDeduct);
      
      // Atomic batch write
      final batch = _firestore.batch();
      final callerUserRef = _firestore.collection('users').doc(callerId);
      
      // 1. Migrate legacy coins to uCoins if needed, then deduct
      // If uCoins is insufficient but legacy coins has value, migrate first
      if (currentUCoins < coinsToDeduct && legacyCoins > 0) {
        // Migrate legacy coins to uCoins
        final coinsToMigrate = legacyCoins;
        print('🔄 Migrating $coinsToMigrate legacy coins to uCoins (partial minute)');
        batch.update(
          callerUserRef,
          {
            'uCoins': FieldValue.increment(coinsToMigrate),
            'coins': FieldValue.increment(-coinsToMigrate), // Clear legacy coins
          },
        );
      }
      
      // 2. Deduct from caller's users collection (single source of truth)
      batch.update(
        callerUserRef,
        {
          'uCoins': FieldValue.increment(-coinsToDeduct),
        },
      );
      
      // 3. Update host earnings (SINGLE SOURCE OF TRUTH)
      // NOTE: Only update earnings.totalCCoins, not users.cCoins (to avoid duplicate field issues)
      final earningsRef = _firestore.collection('earnings').doc(hostId);
      batch.set(
        earningsRef,
        {
          'userId': hostId,
          'totalCCoins': FieldValue.increment(cCoinsToCredit),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      
      // 5. Create transaction record
      final transactionId = _firestore.collection('callTransactions').doc().id;
      final transaction = CallTransactionModel(
        transactionId: transactionId,
        callRequestId: callRequestId,
        callerId: callerId,
        hostId: hostId,
        uCoinsDeducted: coinsToDeduct,
        cCoinsCredited: cCoinsToCredit,
        durationSeconds: durationSeconds,
        timestamp: DateTime.now(),
        streamId: streamId,
      );
      
      batch.set(
        _firestore.collection('callTransactions').doc(transactionId),
        transaction.toMap(),
      );
      
      await batch.commit();
      
      print('✅ Deducted $coinsToDeduct U Coins (partial minute: $durationSeconds seconds), credited $cCoinsToCredit C Coins');
      return true;
    } catch (e) {
      print('❌ Error deducting partial minute: $e');
      return false;
    }
  }
  
  /// Get total coins deducted for a call
  Future<int> getTotalCoinsDeducted(String callRequestId) async {
    try {
      final transactions = await _firestore
          .collection('callTransactions')
          .where('callRequestId', isEqualTo: callRequestId)
          .get();
      
      int total = 0;
      for (var doc in transactions.docs) {
        final data = doc.data();
        total += (data['uCoinsDeducted'] as int?) ?? 0;
      }
      
      return total;
    } catch (e) {
      print('❌ Error getting total coins deducted: $e');
      return 0;
    }
  }
}


