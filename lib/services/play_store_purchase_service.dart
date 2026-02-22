import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PlayStorePurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  
  // Product IDs - must match Play Console exactly
  final Set<String> _productIds = {
    'coins_190', // ₹19 package - 190 coins
    'coins_550',
    'coins_1100',
    'coins_1700',
    'coins_2400',
    'coins_3500',
    'coins_7500',
    'coins_13000',
    'coins_28000',
    'coins_45000',
    'coins_80000',
    'coins_175000',
  };
  
  Map<String, ProductDetails> _products = {};
  
  // Callback for purchase status
  Function(String productId, bool success, String? error)? onPurchaseComplete;
  
  // Initialize purchase service
  Future<bool> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        debugPrint('❌ Play Store billing not available');
        return false;
      }
      
      debugPrint('✅ Play Store billing available');
      
      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          debugPrint('❌ Purchase stream error: $error');
          onPurchaseComplete?.call('', false, error.toString());
        },
      );
      
      // Load products
      await loadProducts();
      
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing Play Store: $e');
      return false;
    }
  }
  
  // Load available products
  Future<void> loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
      
      if (response.error != null) {
        debugPrint('❌ Error loading products: ${response.error}');
        return;
      }
      
      _products = {};
      for (var product in response.productDetails) {
        _products[product.id] = product;
        debugPrint('✅ Loaded product: ${product.id} - ${product.price}');
      }
      
      debugPrint('✅ Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('❌ Error querying products: $e');
    }
  }
  
  // Get product details
  ProductDetails? getProduct(String productId) {
    return _products[productId];
  }
  
  // Get all products
  Map<String, ProductDetails> getAllProducts() {
    return _products;
  }
  
  // Check if service is available
  bool get isAvailable => _isAvailable;
  
  // Purchase a product
  Future<Map<String, dynamic>> purchaseProduct(String productId) async {
    try {
      final product = _products[productId];
      
      if (product == null) {
        return {
          'success': false,
          'message': 'Product not found. Please try again.',
        };
      }
      
      debugPrint('🛒 Initiating purchase: ${product.id} - ${product.price}');
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      
      // Use buyConsumable for coins (users can buy multiple times)
      final bool success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );
      
      if (success) {
        debugPrint('✅ Purchase initiated successfully');
        return {
          'success': true,
          'message': 'Purchase initiated',
        };
      } else {
        debugPrint('❌ Failed to initiate purchase');
        return {
          'success': false,
          'message': 'Failed to initiate purchase',
        };
      }
    } catch (e) {
      debugPrint('❌ Error purchasing: $e');
      return {
        'success': false,
        'message': 'Purchase error: $e',
      };
    }
  }
  
  // Handle purchase updates
  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      debugPrint('📦 Purchase update: ${purchase.productID} - ${purchase.status}');
      
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('⏳ Purchase pending: ${purchase.productID}');
        // Purchase is pending - show loading
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('❌ Purchase error: ${purchase.error}');
        onPurchaseComplete?.call(purchase.productID, false, purchase.error?.message);
        
        // Complete the purchase even on error
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.purchased ||
                 purchase.status == PurchaseStatus.restored) {
        debugPrint('✅ Purchase successful: ${purchase.productID}');
        
        // Verify and process purchase FIRST
        final verified = await _verifyAndProcessPurchase(purchase);
        
        // Only complete/consume purchase AFTER successful verification
        if (verified) {
          debugPrint('✅ Purchase verified, completing purchase...');
          onPurchaseComplete?.call(purchase.productID, true, null);
          
          // Complete/consume the purchase (CRITICAL for consumables)
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
            debugPrint('✅ Purchase completed/consumed successfully');
          }
        } else {
          debugPrint('❌ Purchase verification failed, NOT completing purchase');
          onPurchaseComplete?.call(purchase.productID, false, 'Verification failed. Please contact support.');
          
          // Don't complete purchase if verification failed
          // This prevents coins being added without verification
        }
      }
    }
  }
  
  // Verify purchase with server
  Future<bool> _verifyAndProcessPurchase(PurchaseDetails purchase) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ User not authenticated');
        return false;
      }
      
      debugPrint('🔍 Starting purchase verification...');
      debugPrint('   Product ID: ${purchase.productID}');
      debugPrint('   User ID: ${currentUser.uid}');
      
      // Get purchase details
      String? purchaseToken;
      String? orderId;
      
      if (purchase is GooglePlayPurchaseDetails) {
        purchaseToken = purchase.billingClientPurchase.purchaseToken;
        orderId = purchase.billingClientPurchase.orderId;
        debugPrint('   Order ID: $orderId');
        debugPrint('   Purchase Token: ${purchaseToken != null && purchaseToken.length > 20 ? purchaseToken.substring(0, 20) + "..." : purchaseToken}');
      }
      
      if (purchaseToken == null || orderId == null) {
        debugPrint('❌ Invalid purchase details - Missing token or order ID');
        debugPrint('   Token: ${purchaseToken != null ? "Present" : "Missing"}');
        debugPrint('   Order ID: ${orderId != null ? "Present" : "Missing"}');
        return false;
      }
      
      debugPrint('🔍 Calling Cloud Function: verifyPlayStorePurchase');
      
      // Call cloud function to verify purchase
      final callable = _functions.httpsCallable('verifyPlayStorePurchase');
      final result = await callable.call({
        'productId': purchase.productID,
        'purchaseToken': purchaseToken,
        'orderId': orderId,
        'packageName': 'com.chamakz.app',
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('❌ Cloud Function timeout after 30 seconds');
          throw TimeoutException('Purchase verification timeout');
        },
      );
      
      final data = result.data as Map<String, dynamic>;
      
      debugPrint('📥 Cloud Function response: ${data.toString()}');
      
      if (data['success'] == true) {
        final coins = data['coins'] ?? 'unknown';
        debugPrint('✅ Purchase verified successfully!');
        debugPrint('   Coins added: $coins');
        debugPrint('   Payment ID: ${data['paymentId'] ?? 'N/A'}');
        return true;
      } else {
        final message = data['message'] ?? 'Unknown error';
        debugPrint('❌ Purchase verification failed: $message');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error verifying purchase: $e');
      debugPrint('   Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      debugPrint('🔄 Restoring purchases...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('❌ Error restoring purchases: $e');
    }
  }
  
  // Dispose
  void dispose() {
    _subscription?.cancel();
  }
}
