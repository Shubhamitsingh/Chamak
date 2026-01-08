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
      
      // Check all possible coin fields (uCoins is primary, coins is legacy fallback)
      final uCoins = (userData['uCoins'] as int?) ?? 0;
      final legacyCoins = (userData['coins'] as int?) ?? 0;
      
      print('💰 Balance check - uCoins: $uCoins, legacy coins: $legacyCoins');
      
      // Also check wallet collection (with timeout)
      int walletBalance = 0;
      try {
        final walletDoc = await _firestore.collection('wallets').doc(userId)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
        
        if (walletDoc.exists) {
          final walletData = walletDoc.data() ?? {};
          walletBalance = (walletData['balance'] as int?) ?? 
                         (walletData['coins'] as int?) ?? 0;
          print('💰 Wallet balance: $walletBalance');
        }
      } catch (e) {
        print('⚠️ Could not read wallet collection (non-critical): $e');
        // Continue without wallet balance - not critical
      }
      
      // Use the highest value found (prioritize uCoins, then legacy coins, then wallet)
      final balance = [uCoins, legacyCoins, walletBalance].reduce((a, b) => a > b ? a : b);
      
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
      
      // Check all possible coin fields (uCoins is primary, coins is legacy fallback)
      final uCoins = (userData['uCoins'] as int?) ?? 0;
      final legacyCoins = (userData['coins'] as int?) ?? 0;
      
      // Also check wallet collection (with timeout)
      int walletBalance = 0;
      try {
        final walletDoc = await _firestore.collection('wallets').doc(userId)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
        
        if (walletDoc.exists) {
          final walletData = walletDoc.data() ?? {};
          walletBalance = (walletData['balance'] as int?) ?? 
                         (walletData['coins'] as int?) ?? 0;
        }
      } catch (e) {
        print('⚠️ Could not read wallet collection (non-critical): $e');
        // Continue without wallet balance - not critical
      }
      
      // Use the highest value found (prioritize uCoins, then legacy coins, then wallet)
      final balance = [uCoins, legacyCoins, walletBalance].reduce((a, b) => a > b ? a : b);
      
      print('💰 getUserBalance: uCoins=$uCoins, legacyCoins=$legacyCoins, wallet=$walletBalance, final=$balance');
      
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
      
      // Get caller's wallet document (to check if it exists)
      final callerWalletRef = _firestore.collection('wallets').doc(callerId);
      final callerWalletDoc = await callerWalletRef.get();
      
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
      
      // 2. Deduct U Coins from caller's users collection (PRIMARY UPDATE - ATOMIC)
      batch.update(
        callerUserRef,
        {
          'uCoins': FieldValue.increment(-COINS_PER_MINUTE),
        },
      );
      
      // 2. Update or create caller's wallet collection (SYNC WITH USERS COLLECTION - ATOMIC)
      if (callerWalletDoc.exists) {
        // Update existing wallet document using atomic increment (stays in sync)
        batch.update(
          callerWalletRef,
          {
            'balance': FieldValue.increment(-COINS_PER_MINUTE),
            'coins': FieldValue.increment(-COINS_PER_MINUTE),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      } else {
        // Create wallet document if it doesn't exist
        // First get current balance to set initial value
        final currentUCoins = (callerUserDoc.data()?['uCoins'] as int?) ?? 0;
        final callerNewUCoinsBalance = currentUCoins - COINS_PER_MINUTE;
        final callerName = callerUserDoc.data()?['displayName'] as String? ?? '';
        batch.set(
          callerWalletRef,
          {
            'userId': callerId,
            'userName': callerName,
            'balance': callerNewUCoinsBalance,
            'coins': callerNewUCoinsBalance,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      
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
      
      // Get caller's wallet document (to check if it exists)
      final callerWalletRef = _firestore.collection('wallets').doc(callerId);
      final callerWalletDoc = await callerWalletRef.get();
      
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
      
      // 2. Deduct from caller's users collection (PRIMARY UPDATE - ATOMIC)
      batch.update(
        callerUserRef,
        {
          'uCoins': FieldValue.increment(-coinsToDeduct),
        },
      );
      
      // 2. Update or create caller's wallet collection (SYNC WITH USERS COLLECTION - ATOMIC)
      if (callerWalletDoc.exists) {
        // Update existing wallet document using atomic increment (stays in sync)
        batch.update(
          callerWalletRef,
          {
            'balance': FieldValue.increment(-coinsToDeduct),
            'coins': FieldValue.increment(-coinsToDeduct),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      } else {
        // Create wallet document if it doesn't exist
        // First get current balance to set initial value
        final currentUCoins = (callerUserDoc.data()?['uCoins'] as int?) ?? 0;
        final callerNewUCoinsBalance = currentUCoins - coinsToDeduct;
        final callerName = callerUserDoc.data()?['displayName'] as String? ?? '';
        batch.set(
          callerWalletRef,
          {
            'userId': callerId,
            'userName': callerName,
            'balance': callerNewUCoinsBalance,
            'coins': callerNewUCoinsBalance,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      
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


