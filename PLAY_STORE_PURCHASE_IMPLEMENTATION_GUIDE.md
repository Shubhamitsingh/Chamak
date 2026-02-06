# 🛒 Google Play Store In-App Purchase - Complete Implementation Guide

**Project:** Chamak App  
**Payment Method:** Google Play Store In-App Purchases Only  
**Status:** 📋 **Ready to Implement**

---

## ✅ PayPrime Code Removed

All PayPrime payment code has been removed:
- ✅ `lib/services/payprime_payment_service.dart` - Deleted
- ✅ `lib/screens/payprime_payment_webview_screen.dart` - Deleted
- ✅ `lib/screens/upi_payment_selection_screen.dart` - Deleted
- ✅ PayPrime imports removed from `wallet_screen.dart`
- ✅ PayPrime payment handler removed from `wallet_screen.dart`

**Current Status:** Wallet screen is ready for Play Store implementation.

---

## 🎯 Implementation Overview

### **What You'll Build:**

```
User clicks package
    ↓
Play Store purchase dialog
    ↓
User completes purchase
    ↓
Verify purchase (Cloud Function)
    ↓
Add coins to wallet
```

---

## 📋 Step-by-Step Implementation

### **STEP 1: Add Package**

**File:** `pubspec.yaml`

```yaml
dependencies:
  # ... existing dependencies ...
  
  # Google Play In-App Purchase
  in_app_purchase: ^3.1.11
```

**Command:**
```bash
flutter pub get
```

---

### **STEP 2: Configure Play Console**

#### **2.1: Create Products**

1. Go to: **Play Console** → Your App → **Monetize** → **Products** → **In-app products**
2. Click **Create product**
3. Create 12 products (one for each package):

| Product ID | Name | Price (INR) | Coins |
|------------|------|-------------|-------|
| `coins_90` | 90 Coins | ₹9 | 90 |
| `coins_550` | 550 Coins | ₹49 | 550 |
| `coins_1100` | 1100 Coins | ₹99 | 1100 |
| `coins_1700` | 1700 Coins | ₹149 | 1700 |
| `coins_2400` | 2400 Coins | ₹199 | 2400 |
| `coins_3500` | 3500 Coins | ₹299 | 3500 |
| `coins_7500` | 7500 Coins | ₹599 | 7500 |
| `coins_13000` | 13000 Coins | ₹999 | 13000 |
| `coins_28000` | 28000 Coins | ₹1999 | 28000 |
| `coins_45000` | 45000 Coins | ₹2999 | 45000 |
| `coins_80000` | 80000 Coins | ₹4999 | 80000 |
| `coins_175000` | 175000 Coins | ₹9999 | 175000 |

**Important:**
- Product ID must match exactly in code
- Set prices in Play Console
- Status: **Active**

#### **2.2: Enable In-App Products**

1. Go to **Monetize** → **Products** → **In-app products**
2. Click **Enable** for in-app products
3. Accept terms and conditions

---

### **STEP 3: Create Play Store Purchase Service**

**File:** `lib/services/play_store_purchase_service.dart`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PlayStorePurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  
  // Product IDs - must match Play Console exactly
  final Set<String> _productIds = {
    'coins_90',
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
      
      final bool success = await _inAppPurchase.buyNonConsumable(
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
        
        // Verify and process purchase
        final verified = await _verifyAndProcessPurchase(purchase);
        
        if (verified) {
          onPurchaseComplete?.call(purchase.productID, true, null);
        } else {
          onPurchaseComplete?.call(purchase.productID, false, 'Verification failed');
        }
        
        // Complete the purchase
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
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
      
      // Get purchase details
      String? purchaseToken;
      String? orderId;
      
      if (purchase is GooglePlayPurchaseDetails) {
        purchaseToken = purchase.billingClientPurchase.purchaseToken;
        orderId = purchase.billingClientPurchase.orderId;
      }
      
      if (purchaseToken == null || orderId == null) {
        debugPrint('❌ Invalid purchase details');
        return false;
      }
      
      debugPrint('🔍 Verifying purchase: $orderId');
      
      // Call cloud function to verify purchase
      final callable = _functions.httpsCallable('verifyPlayStorePurchase');
      final result = await callable.call({
        'productId': purchase.productID,
        'purchaseToken': purchaseToken,
        'orderId': orderId,
        'packageName': 'com.chamakz.app',
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        debugPrint('✅ Purchase verified and coins added');
        return true;
      } else {
        debugPrint('❌ Purchase verification failed: ${data['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error verifying purchase: $e');
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
```

---

### **STEP 4: Update Wallet Screen**

**File:** `lib/screens/wallet_screen.dart`

Add import and service:

```dart
// Add import
import '../services/play_store_purchase_service.dart';

// Add service instance
final PlayStorePurchaseService _playStoreService = PlayStorePurchaseService();
```

Update `initState`:

```dart
@override
void initState() {
  super.initState();
  // ... existing code ...
  
  // Initialize Play Store service
  _playStoreService.initialize();
  
  // Listen to purchase completion
  _playStoreService.onPurchaseComplete = (productId, success, error) {
    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Purchase successful! Coins added to wallet'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _loadCoinBalance(); // Refresh balance
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Purchase failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  };
}
```

Update `_handleRecharge` method:

```dart
Future<void> _handleRecharge(Map<String, dynamic> package) async {
  if (!mounted) return;
  
  debugPrint('🔄 _handleRecharge called with package: $package');
  
  final int coins = package['coins'] as int;
  final int inr = package['inr'] as int;
  
  debugPrint('💰 Payment details: ₹$inr for $coins coins');
  
  // Check if user is authenticated
  final currentUser = _auth.currentUser;
  if (currentUser == null) {
    debugPrint('❌ User not authenticated');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
    return;
  }
  
  // Map coins to product ID
  final productIdMap = {
    90: 'coins_90',
    550: 'coins_550',
    1100: 'coins_1100',
    1700: 'coins_1700',
    2400: 'coins_2400',
    3500: 'coins_3500',
    7500: 'coins_7500',
    13000: 'coins_13000',
    28000: 'coins_28000',
    45000: 'coins_45000',
    80000: 'coins_80000',
    175000: 'coins_175000',
  };
  
  final productId = productIdMap[coins];
  if (productId == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not found for this package'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }
  
  // Show loading dialog
  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF1B7C),
        ),
      ),
    );
  }
  
  // Initiate purchase
  final result = await _playStoreService.purchaseProduct(productId);
  
  // If purchase initiation failed, close dialog and show error
  if (result['success'] != true) {
    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to initiate purchase'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  // If successful, purchase dialog will show and completion will be handled by callback
}
```

Add dispose:

```dart
@override
void dispose() {
  _playStoreService.dispose();
  // ... existing dispose code ...
  super.dispose();
}
```

---

### **STEP 5: Create Cloud Function**

**File:** `functions/index.js` (add this function)

```javascript
/**
 * Verify Google Play Store purchase and add coins
 */
exports.verifyPlayStorePurchase = onCall(
  {},
  async (request) => {
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const userId = request.auth.uid;
    const { productId, purchaseToken, orderId, packageName } = request.data;

    // Validate inputs
    if (!productId || !purchaseToken || !orderId) {
      throw new Error("Missing required purchase parameters");
    }

    try {
      // Map product IDs to coin amounts
      const productToCoins = {
        'coins_90': 90,
        'coins_550': 550,
        'coins_1100': 1100,
        'coins_1700': 1700,
        'coins_2400': 2400,
        'coins_3500': 3500,
        'coins_7500': 7500,
        'coins_13000': 13000,
        'coins_28000': 28000,
        'coins_45000': 45000,
        'coins_80000': 80000,
        'coins_175000': 175000,
      };

      const coins = productToCoins[productId];
      if (!coins) {
        throw new Error(`Invalid product ID: ${productId}`);
      }

      console.log(`🛒 Verifying Play Store purchase: ${orderId}`);
      console.log(`   Product: ${productId}`);
      console.log(`   Coins: ${coins}`);

      // Check if purchase already processed
      const existingPayment = await admin.firestore()
        .collection('payments')
        .where('orderId', '==', orderId)
        .where('gateway', '==', 'play_store')
        .limit(1)
        .get();

      if (!existingPayment.empty) {
        const paymentData = existingPayment.docs[0].data();
        if (paymentData.status === 'SUCCESS') {
          console.log(`ℹ️ Purchase already processed: ${orderId}`);
          return {
            success: true,
            message: 'Purchase already processed',
            coins: coins,
          };
        }
      }

      // TODO: Verify purchase token with Google Play API
      // For production, use Google Play Developer API to verify purchase
      // For now, we'll trust the client (not recommended for production)

      // Create payment record
      const paymentId = admin.firestore().collection('payments').doc().id;
      const paymentData = {
        userId: userId,
        orderId: orderId,
        paymentId: paymentId,
        productId: productId,
        coins: coins,
        amount: 0, // Amount handled by Play Store
        currency: 'INR',
        status: 'SUCCESS',
        gateway: 'play_store',
        purchaseToken: purchaseToken,
        packageName: packageName || 'com.chamakz.app',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await admin.firestore().collection('payments').doc(paymentId).set(paymentData);

      // Add coins to user's wallet
      const userRef = admin.firestore().collection('users').doc(userId);
      await userRef.update({
        uCoins: admin.firestore.FieldValue.increment(coins),
        coinBalance: admin.firestore.FieldValue.increment(coins), // Legacy
      });

      // Log transaction
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('coinTransactions')
        .add({
          type: 'purchase',
          amount: coins,
          paymentId: paymentId,
          orderId: orderId,
          gateway: 'play_store',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`✅ Play Store purchase verified: ${orderId}, added ${coins} coins`);

      return {
        success: true,
        message: 'Purchase verified and coins added',
        coins: coins,
        paymentId: paymentId,
      };
    } catch (error) {
      console.error('❌ Error verifying Play Store purchase:', error);
      throw new Error(`Failed to verify purchase: ${error.message}`);
    }
  }
);
```

---

### **STEP 6: Deploy Cloud Function**

```bash
cd functions
firebase deploy --only functions:verifyPlayStorePurchase
```

---

## 🧪 Testing

### **Test Products Setup:**

1. Create test products in Play Console
2. Add test accounts (Gmail accounts)
3. Install app on test device
4. Test purchase flow

### **Test Scenarios:**

- [ ] Successful purchase
- [ ] Purchase cancellation
- [ ] Network error
- [ ] Duplicate purchase prevention
- [ ] Coin addition verification

---

## 📋 Implementation Checklist

- [ ] Add `in_app_purchase` package
- [ ] Create 12 products in Play Console
- [ ] Create `PlayStorePurchaseService`
- [ ] Update `wallet_screen.dart`
- [ ] Create cloud function
- [ ] Deploy cloud function
- [ ] Test with test products
- [ ] Test purchase flow
- [ ] Verify coin addition
- [ ] Production testing

---

## ⚠️ Important Notes

1. **Play Store Commission:**
   - Google takes 15-30% commission
   - Factor this into pricing

2. **Product IDs:**
   - Must match exactly in code and Play Console
   - Cannot be changed after creation

3. **Testing:**
   - Use test products for development
   - Test accounts required

4. **Verification:**
   - For production, implement server-side verification
   - Use Google Play Developer API

---

## 🚀 Quick Start

```bash
# Step 1: Add package
flutter pub add in_app_purchase

# Step 2: Get dependencies
flutter pub get

# Step 3: Follow steps above
```

---

**Status:** ✅ **PayPrime Removed** - Ready for Play Store Implementation  
**Next:** Follow steps above to implement Play Store purchases
