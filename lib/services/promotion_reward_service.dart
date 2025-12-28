import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
import 'coin_service.dart';

class PromotionRewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();
  final CoinService _coinService = CoinService();

  // Base reward amounts
  static const int baseUrlShareReward = 10;
  static const int baseQrCodeSaveReward = 15;
  static const int referralReward = 50;

  /// Calculate reward for sharing
  Future<int> calculateReward({
    required String userId,
    required String shareType, // 'url' or 'qr_code'
    int? downlineGameRate,
    int? downlineGiftRate,
  }) async {
    try {
      // Get user level for multiplier
      final user = await _databaseService.getUserData(userId);
      final userLevel = user?.level ?? 1;

      // Base reward based on share type
      int baseReward = shareType == 'qr_code' 
          ? baseQrCodeSaveReward 
          : baseUrlShareReward;

      // Level multiplier (higher level = more reward)
      double levelMultiplier = 1.0 + (userLevel * 0.05); // 5% per level

      // Downline rate multiplier (if rates are set)
      double rateMultiplier = 1.0;
      if (downlineGameRate != null && downlineGiftRate != null) {
        final avgRate = (downlineGameRate + downlineGiftRate) / 2;
        rateMultiplier = 1.0 + (avgRate / 100); // Convert percentage to multiplier
      }

      // Calculate final reward
      final finalReward = (baseReward * levelMultiplier * rateMultiplier).round();

      return finalReward;
    } catch (e) {
      debugPrint('Error calculating reward: $e');
      // Return base reward on error
      return shareType == 'qr_code' ? baseQrCodeSaveReward : baseUrlShareReward;
    }
  }

  /// Award reward to user
  Future<void> awardReward({
    required String userId,
    required int rewardAmount,
    required String shareType,
    required String appLink,
    String? referralCode,
  }) async {
    try {
      // Update user's uCoins balance
      await _coinService.addCoins(
        userId: userId,
        coins: rewardAmount,
        description: 'Promotion share reward ($shareType)',
      );

      // Update share tracking with reward
      final shareTrackingQuery = await _firestore
          .collection('share_tracking')
          .where('userId', isEqualTo: userId)
          .where('appLink', isEqualTo: appLink)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (shareTrackingQuery.docs.isNotEmpty) {
        await shareTrackingQuery.docs.first.reference.update({
          'rewardGiven': rewardAmount,
        });
      }

      // Log reward transaction
      await _firestore.collection('reward_transactions').add({
        'userId': userId,
        'type': 'promotion_share',
        'shareType': shareType,
        'amount': rewardAmount,
        'referralCode': referralCode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Reward awarded: $rewardAmount coins to user $userId');
    } catch (e) {
      debugPrint('Error awarding reward: $e');
      rethrow;
    }
  }

  /// Get user's downline rates
  Future<Map<String, int>> getDownlineRates(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        return {
          'gameRate': (data?['downlineGameRate'] as int?) ?? 70,
          'giftRate': (data?['downlineGiftRate'] as int?) ?? 70,
        };
      }

      // Default rates
      return {
        'gameRate': 70,
        'giftRate': 70,
      };
    } catch (e) {
      debugPrint('Error getting downline rates: $e');
      return {
        'gameRate': 70,
        'giftRate': 70,
      };
    }
  }

  /// Check if user has already shared today (prevent spam)
  Future<bool> hasSharedToday(String userId, String shareType) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final query = await _firestore
          .collection('share_tracking')
          .where('userId', isEqualTo: userId)
          .where('shareType', isEqualTo: shareType)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking share limit: $e');
      return false;
    }
  }
}















