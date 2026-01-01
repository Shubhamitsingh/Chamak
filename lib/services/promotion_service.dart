import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
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

  /// Add watermark (app logo) to an image file before upload
  Future<Uint8List?> _addWatermarkToImageFile(String filePath) async {
    try {
      // Load the base image from file
      final File imageFile = File(filePath);
      final Uint8List baseImageBytes = await imageFile.readAsBytes();
      final ui.Codec baseCodec = await ui.instantiateImageCodec(baseImageBytes);
      final ui.FrameInfo baseFrameInfo = await baseCodec.getNextFrame();
      final ui.Image baseImage = baseFrameInfo.image;

      // Load the watermark logo from assets
      final ByteData logoData = await rootBundle.load('assets/images/logopink.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final ui.Codec logoCodec = await ui.instantiateImageCodec(logoBytes);
      final ui.FrameInfo logoFrameInfo = await logoCodec.getNextFrame();
      final ui.Image logoImage = logoFrameInfo.image;

      // Calculate watermark size (15% of image width, maintain aspect ratio)
      final double watermarkWidth = baseImage.width * 0.15;
      final double watermarkHeight = (logoImage.height / logoImage.width) * watermarkWidth;

      // Create a canvas to draw the watermarked image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      
      // Draw the base image
      canvas.drawImage(baseImage, Offset.zero, ui.Paint());
      
      // Draw watermark in top-left corner with padding
      const double padding = 12.0;
      final ui.Rect watermarkRect = ui.Rect.fromLTWH(
        padding,
        padding,
        watermarkWidth,
        watermarkHeight,
      );
      
      // Draw watermark
      canvas.drawImageRect(
        logoImage,
        ui.Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
        watermarkRect,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image watermarkedImage = await picture.toImage(
        baseImage.width,
        baseImage.height,
      );

      // Convert to bytes
      final ByteData? byteData = await watermarkedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Dispose images
      baseImage.dispose();
      logoImage.dispose();
      watermarkedImage.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error adding watermark to image: $e');
      return null;
    }
  }

  /// Upload promotional image to Firebase Storage (with watermark)
  Future<String> uploadPromotionalImage(String filePath, String userId) async {
    try {
      // Add watermark to the image before uploading
      final watermarkedBytes = await _addWatermarkToImageFile(filePath);
      
      if (watermarkedBytes == null) {
        debugPrint('Warning: Failed to add watermark, uploading original image');
        // Fallback to original image if watermarking fails
        return await _uploadImageFile(filePath, userId);
      }

      // Upload watermarked image
      final fileName = 'promotions/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      
      final uploadTask = ref.putData(
        watermarkedBytes,
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

  /// Upload image file without watermark (fallback)
  Future<String> _uploadImageFile(String filePath, String userId) async {
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
      debugPrint('Error uploading image file: $e');
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















