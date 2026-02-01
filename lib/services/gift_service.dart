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
        
        // Get sender's user document (for name)
        final senderUserDoc = await transaction.get(
          _firestore.collection('users').doc(senderId),
        );
        final senderNameValue = senderUserDoc.data()?['displayName'] as String? ?? '';
        
        // 1. Deduct U Coins from sender's users collection (single source of truth)
        transaction.update(
          _firestore.collection('users').doc(senderId),
          {
            'uCoins': FieldValue.increment(-uCoinCost),
          },
        );
        
        print('💰 Gift: Deducting $uCoinCost U Coins from users.uCoins (single source of truth)');
        
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
  
  /// Get user's gift history (sent gifts - real-time stream, loads 50)
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
  
  /// Get user's sent gifts with pagination (for loading more)
  Future<List<GiftModel>> getUserSentGiftsPaginated({
    required String userId,
    DocumentSnapshot? lastGift,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('gifts')
          .where('senderId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (lastGift != null) {
        query = query.startAfterDocument(lastGift);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => GiftModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting paginated sent gifts: $e');
      return [];
    }
  }
  
  /// Get host's gift history (received gifts - real-time stream, loads 50)
  Stream<List<GiftModel>> getHostReceivedGifts(String hostId) {
    return _firestore
        .collection('gifts')
        .where('receiverId', isEqualTo: hostId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GiftModel.fromFirestore(doc))
            .toList())
        .handleError((error) {
          // Log error but let it propagate to UI for handling
          print('Error fetching gifts: $error');
          throw error;
        });
  }
  
  /// Get host's received gifts with pagination (for loading more)
  Future<List<GiftModel>> getHostReceivedGiftsPaginated({
    required String hostId,
    DocumentSnapshot? lastGift,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('gifts')
          .where('receiverId', isEqualTo: hostId)
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (lastGift != null) {
        query = query.startAfterDocument(lastGift);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => GiftModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting paginated received gifts: $e');
      return [];
    }
  }
  
  /// Fallback method: Get gifts without orderBy (no index needed)
  Stream<List<GiftModel>> getHostReceivedGiftsFallback(String hostId) {
    return _firestore
        .collection('gifts')
        .where('receiverId', isEqualTo: hostId)
        .limit(100) // Fetch more to sort, then limit
        .snapshots()
        .map((snapshot) {
          final gifts = snapshot.docs
              .map((doc) => GiftModel.fromFirestore(doc))
              .toList();
          // Sort in memory by timestamp descending
          gifts.sort((a, b) {
            if (a.timestamp == null && b.timestamp == null) return 0;
            if (a.timestamp == null) return 1;
            if (b.timestamp == null) return -1;
            return b.timestamp!.compareTo(a.timestamp!);
          });
          // Return only first 50
          return gifts.take(50).toList();
        });
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




