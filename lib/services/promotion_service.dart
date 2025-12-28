import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/promotion_model.dart';
import 'database_service.dart';

class PromotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DatabaseService _databaseService = DatabaseService();

  // Google Play Store app URL
  static const String baseAppUrl = 'https://play.google.com/store/apps/details?id=com.chamakz.app&pcampaignid=web_share';

  /// Generate app share link with user referral code
  Future<String> generateAppLink(String userId) async {
    try {
      // Get user data to get referral code or numeric ID
      final user = await _databaseService.getUserData(userId);
      final referralCode = user?.numericUserId ?? userId.substring(0, 8);
      
      // Use Play Store link with referral code as parameter
      return '$baseAppUrl&referrer=ref_$referralCode';
    } catch (e) {
      debugPrint('Error generating app link: $e');
      // Return base Play Store link if error
      return baseAppUrl;
    }
  }

  /// Generate QR code data string
  Future<String> generateQRCodeData(String userId) async {
    return await generateAppLink(userId);
  }

  /// Get user's referral code
  Future<String> getUserReferralCode(String userId) async {
    try {
      final user = await _databaseService.getUserData(userId);
      return user?.numericUserId ?? userId.substring(0, 8);
    } catch (e) {
      debugPrint('Error getting referral code: $e');
      return userId.substring(0, 8);
    }
  }

  /// Upload promotional image to Firebase Storage
  Future<String> uploadPromotionalImage(String filePath, String userId) async {
    try {
      final fileName = 'promotions/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      
      final uploadTask = ref.putFile(
        File(filePath),
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading promotional image: $e');
      rethrow;
    }
  }

  /// Save promotion to Firestore
  Future<void> savePromotion(PromotionModel promotion) async {
    try {
      await _firestore
          .collection('promotions')
          .doc(promotion.id)
          .set(promotion.toFirestore());
    } catch (e) {
      debugPrint('Error saving promotion: $e');
      rethrow;
    }
  }

  /// Get user's promotional images
  Stream<List<PromotionModel>> getUserPromotions(String userId) {
    return _firestore
        .collection('promotions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get default promotional images (for new users)
  Future<List<PromotionModel>> getDefaultPromotions() async {
    try {
      final snapshot = await _firestore
          .collection('promotions')
          .where('isCustom', isEqualTo: false)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) {
        // Return empty list if no default promotions
        return [];
      }

      return snapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting default promotions: $e');
      return [];
    }
  }

  /// Track share event
  Future<void> trackShare({
    required String userId,
    required String shareType, // 'url' or 'qr_code'
    required String appLink,
    String? referralCode,
  }) async {
    try {
      await _firestore.collection('share_tracking').add({
        'userId': userId,
        'shareType': shareType,
        'appLink': appLink,
        'referralCode': referralCode,
        'timestamp': FieldValue.serverTimestamp(),
        'rewardGiven': 0, // Will be updated by reward service
      });
    } catch (e) {
      debugPrint('Error tracking share: $e');
    }
  }

  /// Update promotion share count
  Future<void> incrementShareCount(String promotionId) async {
    try {
      await _firestore
          .collection('promotions')
          .doc(promotionId)
          .update({
        'shareCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing share count: $e');
    }
  }
}















