import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gift_model.dart';
import '../services/coin_conversion_service.dart';

/// Service to handle gift sending and coin transactions
class GiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Send a gift from user to host
  /// Returns true if successful, false if insufficient balance
  /// Uses Firestore transaction to prevent race conditions
  Future<bool> sendGift({
    required String senderId,
    required String receiverId,
    required String giftType,
    required int uCoinCost,
    String? senderName,
    String? receiverName,
  }) async {
    try {
      // Use Firestore transaction to check balance and deduct atomically
      // This prevents race conditions from concurrent transactions
      return await _firestore.runTransaction((transaction) async {
        // Get sender's current U Coins within transaction (prevents race condition)
        final senderDoc = await transaction.get(
          _firestore.collection('users').doc(senderId),
        );
        final senderUCoins = senderDoc.data()?['uCoins'] ?? 0;
        
        // Check if user has enough U Coins
        if (senderUCoins < uCoinCost) {
          return false; // Insufficient balance
        }
        
        // Convert U Coins to C Coins for the host
        final cCoinsToGive = CoinConversionService.convertUtoC(uCoinCost);
        
        // Get sender's wallet document
        final senderWalletRef = _firestore.collection('wallets').doc(senderId);
        final senderWalletDoc = await transaction.get(senderWalletRef);
        
        // Get sender's user document (for name if creating wallet)
        final senderUserDoc = await transaction.get(
          _firestore.collection('users').doc(senderId),
        );
        final senderNameValue = senderUserDoc.data()?['displayName'] as String? ?? '';
        
        // 1. Deduct U Coins from sender's users collection
        transaction.update(
          _firestore.collection('users').doc(senderId),
          {
            'uCoins': FieldValue.increment(-uCoinCost),
          },
        );
        
        // 2. Update or create sender's wallet collection
        if (senderWalletDoc.exists) {
          transaction.update(
            senderWalletRef,
            {
              'balance': FieldValue.increment(-uCoinCost),
              'coins': FieldValue.increment(-uCoinCost),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        } else {
          final currentUCoins = (senderUserDoc.data()?['uCoins'] as int?) ?? 0;
          final senderNewUCoinsBalance = currentUCoins - uCoinCost;
          transaction.set(
            senderWalletRef,
            {
              'userId': senderId,
              'userName': senderNameValue,
              'balance': senderNewUCoinsBalance,
              'coins': senderNewUCoinsBalance,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
        
        print('💰 Gift: Deducting $uCoinCost U Coins atomically from both users and wallets collections');
        
        // 3. Add C Coins to receiver's earnings (SINGLE SOURCE OF TRUTH)
        final earningsRef = _firestore.collection('earnings').doc(receiverId);
        transaction.set(
          earningsRef,
          {
            'userId': receiverId,
            'totalCCoins': FieldValue.increment(cCoinsToGive),
            'totalGiftsReceived': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        
        print('💰 Gift: Adding $cCoinsToGive C Coins to receiver\'s earnings (single source of truth)');
        
        // 4. Create gift transaction record
        final giftRef = _firestore.collection('gifts').doc();
        transaction.set(giftRef, {
          'senderId': senderId,
          'receiverId': receiverId,
          'giftType': giftType,
          'uCoinsSpent': uCoinCost,
          'cCoinsEarned': cCoinsToGive,
          'timestamp': FieldValue.serverTimestamp(),
          'senderName': senderName ?? senderNameValue,
          'receiverName': receiverName,
        });
        
        return true;
      });
    } catch (e) {
      print('Error sending gift: $e');
      return false;
    }
  }
  
  /// Get user's gift history (sent gifts)
  Stream<List<GiftModel>> getUserSentGifts(String userId) {
    return _firestore
        .collection('gifts')
        .where('senderId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GiftModel.fromFirestore(doc))
            .toList());
  }
  
  /// Get host's gift history (received gifts)
  Stream<List<GiftModel>> getHostReceivedGifts(String hostId) {
    return _firestore
        .collection('gifts')
        .where('receiverId', isEqualTo: hostId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GiftModel.fromFirestore(doc))
            .toList());
  }
  
  /// Get total C Coins earned by host
  Future<int> getHostTotalCCoins(String hostId) async {
    try {
      final earningsDoc = await _firestore.collection('earnings').doc(hostId).get();
      return earningsDoc.data()?['totalCCoins'] ?? 0;
    } catch (e) {
      print('Error getting host C Coins: $e');
      return 0;
    }
  }
  
  /// Get host earnings summary
  /// SINGLE SOURCE OF TRUTH: earnings collection only
  Future<Map<String, dynamic>> getHostEarningsSummary(String hostId) async {
    try {
      // Read from earnings collection (single source of truth)
      final earningsDoc = await _firestore.collection('earnings').doc(hostId).get();
      
      int totalCCoins = 0;
      int totalGiftsReceived = 0;
      
      if (earningsDoc.exists) {
        final data = earningsDoc.data()!;
        totalCCoins = data['totalCCoins'] ?? 0;
        totalGiftsReceived = data['totalGiftsReceived'] ?? 0;
      }
      
      final withdrawableAmount = CoinConversionService.calculateHostWithdrawal(totalCCoins);
      
      return {
        'totalCCoins': totalCCoins,
        'totalGiftsReceived': totalGiftsReceived,
        'withdrawableAmount': withdrawableAmount,
      };
    } catch (e) {
      print('Error getting earnings summary: $e');
      return {
        'totalCCoins': 0,
        'totalGiftsReceived': 0,
        'withdrawableAmount': 0.0,
      };
    }
  }
  
  /// Add U Coins to user (after purchase)
  Future<void> addUCoinsToUser(String userId, int uCoins) async {
    await _firestore.collection('users').doc(userId).update({
      'uCoins': FieldValue.increment(uCoins),
    });
  }
  
  /// Get user's U Coin balance
  Future<int> getUserUCoins(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['uCoins'] ?? 0;
    } catch (e) {
      print('Error getting U Coins: $e');
      return 0;
    }
  }
  
  /// Get user's C Coin balance (for hosts)
  /// SINGLE SOURCE OF TRUTH: Reads from earnings collection
  Future<int> getUserCCoins(String userId) async {
    try {
      final earningsDoc = await _firestore.collection('earnings').doc(userId).get();
      return earningsDoc.data()?['totalCCoins'] ?? 0;
    } catch (e) {
      print('Error getting C Coins: $e');
      return 0;
    }
  }
}




