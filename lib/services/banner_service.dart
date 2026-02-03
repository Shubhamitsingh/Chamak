import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';
import '../screens/wallet_screen.dart';
import '../screens/event_screen.dart';

class BannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for banners to show immediately on subsequent loads
  static List<BannerModel>? _cachedBanners;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidityDuration = Duration(minutes: 5); // Cache for 5 minutes

  // Get active banners stream (real-time updates)
  Stream<List<BannerModel>> getActiveBannersStream({
    required int userLevel,
    required String userType,
    required String? userCountry,
  }) {
    debugPrint('🔍 Fetching banners - userLevel: $userLevel, userType: $userType, country: $userCountry');
    
    // Check if we have valid cached banners
    final hasValidCache = _cachedBanners != null && 
                          _cacheTimestamp != null &&
                          DateTime.now().difference(_cacheTimestamp!) < _cacheValidityDuration;
    
    // Create a stream that emits cached data immediately, then updates with fresh data
    Stream<List<BannerModel>> stream = _firestore
        .collection('banners')
        .snapshots()
        .handleError((error) {
          debugPrint('❌ Error in banner stream: $error');
        })
        .map((snapshot) {
      debugPrint('📊 Banner query result: ${snapshot.docs.length} documents found');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No banners found! Check:');
        debugPrint('   1. Collection name is "banners" (lowercase, plural)');
        debugPrint('   2. Banner document exists in Firestore');
      }
      
      // Parse all banners first
      final allBanners = snapshot.docs
          .map((doc) {
            try {
              final banner = BannerModel.fromFirestore(doc);
              debugPrint('✅ Parsed banner: ${doc.id} - isActive: ${banner.isActive}, priority: ${banner.priority}, imageUrl: ${banner.imageUrl.isNotEmpty ? banner.imageUrl.substring(0, banner.imageUrl.length > 50 ? 50 : banner.imageUrl.length) + "..." : "EMPTY"}');
              return banner;
            } catch (e) {
              debugPrint('❌ Error parsing banner ${doc.id}: $e');
              debugPrint('   Document data: ${doc.data()}');
              return null;
            }
          })
          .whereType<BannerModel>()
          .toList();
      
      // Filter active banners
      // IMPORTANT: Since admin panel might save isActive: false incorrectly,
      // we'll show banners even if isActive is false (to prevent admin panel issues)
      // But still check for explicit filtering
      final activeBanners = allBanners.where((banner) {
        // For now, show ALL banners regardless of isActive status
        // Admin panel might not be setting isActive correctly
        // You can uncomment below if you want to filter by isActive:
        // if (!banner.isActive) {
        //   debugPrint('❌ Banner ${banner.id} filtered: isActive is false');
        //   return false;
        // }
        
        // Filter by date range
        // NOTE: Date filtering temporarily disabled to debug admin panel issues
        // Uncomment below if you want to enable date filtering:
        // if (banner.startDate != null && now.isBefore(banner.startDate!)) {
        //   debugPrint('⏰ Banner ${banner.id} filtered: startDate is in future');
        //   return false;
        // }
        // if (banner.endDate != null && now.isAfter(banner.endDate!)) {
        //   debugPrint('⏰ Banner ${banner.id} filtered: endDate is in past');
        //   return false;
        // }
        
        // Filter by target audience
        // NOTE: Target audience filtering temporarily disabled to debug admin panel issues
        // Uncomment below if you want to enable targeting:
        // final shouldShow = banner.shouldShowToUser(
        //   userLevel: userLevel,
        //   userType: userType,
        //   userCountry: userCountry,
        // );
        // if (!shouldShow) {
        //   debugPrint('👤 Banner ${banner.id} filtered: doesn\'t match user targeting');
        //   return false;
        // }
        
        // For now, show ALL banners (no filtering)
        return true;
      }).toList();
      
      // Sort by priority (descending), then createdAt (descending)
      activeBanners.sort((a, b) {
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority); // Descending
        }
        return b.createdAt.compareTo(a.createdAt); // Descending
      });
      
      debugPrint('🎯 Final banners after filtering: ${activeBanners.length}');
      if (activeBanners.isNotEmpty) {
        activeBanners.forEach((b) => debugPrint('   - ${b.id}: ${b.title ?? "No title"} (priority: ${b.priority})'));
      } else {
        debugPrint('⚠️ No active banners found after filtering!');
      }
      
      // Update cache
      _cachedBanners = activeBanners;
      _cacheTimestamp = DateTime.now();
      
      return activeBanners;
    });
    
    // If we have valid cache, emit it immediately, then continue with the stream
    if (hasValidCache && _cachedBanners != null) {
      debugPrint('⚡ Using cached banners (${_cachedBanners!.length} banners)');
      return Stream.value(_cachedBanners!).asyncExpand((_) => stream);
    }
    
    return stream;
  }

  // Get active banners (one-time fetch)
  Future<List<BannerModel>> getActiveBanners({
    required int userLevel,
    required String userType,
    required String? userCountry,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('banners')
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      final now = DateTime.now();
      
      return snapshot.docs
          .map((doc) {
            try {
              return BannerModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('❌ Error parsing banner ${doc.id}: $e');
              return null;
            }
          })
          .whereType<BannerModel>()
          .where((banner) {
            if (banner.startDate != null && now.isBefore(banner.startDate!)) {
              return false;
            }
            if (banner.endDate != null && now.isAfter(banner.endDate!)) {
              return false;
            }
            
            return banner.shouldShowToUser(
              userLevel: userLevel,
              userType: userType,
              userCountry: userCountry,
            );
          })
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching banners: $e');
      return [];
    }
  }

  // Track banner impression (view)
  Future<void> trackImpression(String bannerId) async {
    try {
      await _firestore
          .collection('banners')
          .doc(bannerId)
          .update({
        'impressions': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ Error tracking impression: $e');
    }
  }

  // Track banner click
  Future<void> trackClick(String bannerId) async {
    try {
      await _firestore
          .collection('banners')
          .doc(bannerId)
          .update({
        'clicks': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ Error tracking click: $e');
    }
  }

  // Handle banner action (navigation, external link, etc.)
  Future<void> handleBannerAction(
    BuildContext context,
    BannerModel banner,
    String phoneNumber,
  ) async {
    // Track click
    await trackClick(banner.id);

    switch (banner.actionType) {
      case 'navigate':
        if (banner.actionTarget != null) {
          _navigateToScreen(context, banner.actionTarget!, phoneNumber);
        }
        break;
      
      case 'external_link':
        if (banner.actionTarget != null) {
          // Open URL in browser - requires url_launcher package
          debugPrint('🔗 External link: ${banner.actionTarget}');
          // TODO: Implement with url_launcher if needed
          // await launchUrl(Uri.parse(banner.actionTarget!));
        }
        break;
      
      case 'deep_link':
        if (banner.actionTarget != null) {
          // Handle deep link
          debugPrint('🔗 Deep link: ${banner.actionTarget}');
          // TODO: Implement deep linking if needed
        }
        break;
      
      case 'none':
      default:
        // No action
        break;
    }
  }

  void _navigateToScreen(BuildContext context, String screenName, String phoneNumber) {
    // Map screen names to actual screens
    switch (screenName) {
      case 'wallet_screen':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WalletScreen(
              phoneNumber: phoneNumber,
              isHost: false,
            ),
          ),
        );
        break;
      case 'event_screen':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EventScreen(),
          ),
        );
        break;
      default:
        debugPrint('⚠️ Unknown screen: $screenName');
        break;
    }
  }
}
