import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gift_model.dart';
import '../services/coin_conversion_service.dart';

/// Service to handle gift sending and coin transactions
class GiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Send a gift from user to host
  /// Returns true if successful, false if insufficient balance
  Future<bool> sendGift({
    required String senderId,
    required String receiverId,
    required String giftType,
    required int uCoinCost,
    String? senderName,
    String? receiverName,
  }) async {
    try {
      // Get sender's current U Coins
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderUCoins = senderDoc.data()?['uCoins'] ?? 0;
      
      // Check if user has enough U Coins
      if (senderUCoins < uCoinCost) {
        return false; // Insufficient balance
      }
      
      // Convert U Coins to C Coins for the host
      final cCoinsToGive = CoinConversionService.convertUtoC(uCoinCost);
      
      // Check sender's wallet balance before batch
      final senderWalletRef = _firestore.collection('wallets').doc(senderId);
      final senderWalletDoc = await senderWalletRef.get();
      int? senderNewWalletBalance;
      
      if (senderWalletDoc.exists) {
        final currentBalance = (senderWalletDoc.data()?['balance'] as int?) ?? 
                               (senderWalletDoc.data()?['coins'] as int?) ?? 0;
        senderNewWalletBalance = currentBalance - uCoinCost;
        print('💰 Gift: Deducting $uCoinCost from sender wallet: $currentBalance → $senderNewWalletBalance');
      }
      
      // Create gift transaction using batch write (atomic operation)
      final batch = _firestore.batch();
      
      // 1. Deduct U Coins from sender's wallet (users collection)
      final senderUserRef = _firestore.collection('users').doc(senderId);
      batch.update(
        senderUserRef,
        {
          'uCoins': FieldValue.increment(-uCoinCost),
        },
      );
      
      // Also update sender's wallet collection (if exists)
      if (senderWalletDoc.exists && senderNewWalletBalance != null) {
        batch.update(
          senderWalletRef,
          {
            'balance': senderNewWalletBalance,
            'coins': senderNewWalletBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      
      // 2. Add C Coins to receiver's My Earnings (NOT wallet - they earned it!)
      // Update receiver's cCoins in users collection
      batch.update(
        _firestore.collection('users').doc(receiverId),
        {
          'cCoins': FieldValue.increment(cCoinsToGive),
        },
      );
      
      print('💰 Gift: Adding $cCoinsToGive C Coins to receiver\'s My Earnings (NOT wallet)');
      
      // 3. Create gift transaction record
      final giftRef = _firestore.collection('gifts').doc();
      batch.set(giftRef, {
        'senderId': senderId,
        'receiverId': receiverId,
        'giftType': giftType,
        'uCoinsSpent': uCoinCost,
        'cCoinsEarned': cCoinsToGive,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': senderName,
        'receiverName': receiverName,
      });
      
      // 4. Update host's earnings summary
      final earningsRef = _firestore.collection('earnings').doc(receiverId);
      batch.set(
        earningsRef,
        {
          'userId': receiverId,
          'totalCCoins': FieldValue.increment(cCoinsToGive),
          'totalGiftsReceived': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      
      // Commit all changes atomically
      await batch.commit();
      
      return true;
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
  /// This reads from earnings collection (My Earnings screen)
  Future<Map<String, dynamic>> getHostEarningsSummary(String hostId) async {
    try {
      // First try earnings collection (primary source for My Earnings)
      final earningsDoc = await _firestore.collection('earnings').doc(hostId).get();
      
      int totalCCoins = 0;
      
      if (earningsDoc.exists) {
        final data = earningsDoc.data()!;
        totalCCoins = data['totalCCoins'] ?? 0;
      }
      
      // Also check users collection cCoins (in case earnings collection doesn't exist)
      final userDoc = await _firestore.collection('users').doc(hostId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final userCCoins = (userData?['cCoins'] as int?) ?? 0;
        
        // Use the higher value (in case they're different)
        if (userCCoins > totalCCoins) {
          totalCCoins = userCCoins;
          print('⚠️ Earnings: Using cCoins from users collection: $totalCCoins');
        }
      }
      
      final withdrawableAmount = CoinConversionService.calculateHostWithdrawal(totalCCoins);
      
      return {
        'totalCCoins': totalCCoins,
        'totalGiftsReceived': earningsDoc.exists ? (earningsDoc.data()?['totalGiftsReceived'] ?? 0) : 0,
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
  Future<int> getUserCCoins(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['cCoins'] ?? 0;
    } catch (e) {
      print('Error getting C Coins: $e');
      return 0;
    }
  }
}




