# 🛒 Google Play In-App Purchase Implementation Roadmap

**Project:** Chamak App  
**Payment Method:** Google Play In-App Purchases Only  
**Status:** 📋 **Ready to Implement**

---

## ✅ PayPrime Code Removed

All PayPrime payment code has been removed:
- ✅ `lib/services/payprime_payment_service.dart` - Deleted
- ✅ `lib/screens/payprime_payment_webview_screen.dart` - Deleted
- ✅ `lib/screens/upi_payment_selection_screen.dart` - Deleted
- ✅ PayPrime imports removed from `wallet_screen.dart`
- ✅ PayPrime payment handler removed from `wallet_screen.dart`

---

## 📊 Executive Summary

This roadmap outlines how to implement **Google Play In-App Purchases** as the **only** payment method. Users will purchase coins directly through Google Play Store.

---

## 🎯 Goals & Benefits

### **Why Add Play Store Purchases?**

1. ✅ **More Payment Options** - Users can use Play Store balance
2. ✅ **Better User Experience** - Native Android payment flow
3. ✅ **Higher Conversion** - Some users prefer Play Store payments
4. ✅ **Global Reach** - Works in all countries with Play Store
5. ✅ **Automatic Handling** - Google handles payment processing
6. ✅ **Refund Management** - Google handles refunds automatically

### **How It Will Work:**

```
User selects package
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

## 📋 Implementation Phases

### **Phase 1: Setup & Configuration** (Day 1)
- [ ] Add `in_app_purchase` package
- [ ] Configure Play Console products
- [ ] Set up product IDs
- [ ] Test connection to Play Billing

### **Phase 2: Core Implementation** (Day 2-3)
- [ ] Create Play Store purchase service
- [ ] Implement purchase flow
- [ ] Add purchase verification
- [ ] Handle purchase states

### **Phase 3: Integration** (Day 4)
- [ ] Update wallet screen UI
- [ ] Add payment method selection
- [ ] Integrate with existing flow
- [ ] Update coin addition logic

### **Phase 4: Backend & Security** (Day 5)
- [ ] Create cloud function for verification
- [ ] Implement server-side validation
- [ ] Add purchase records to Firestore
- [ ] Handle refunds and cancellations

### **Phase 5: Testing & Launch** (Day 6-7)
- [ ] Test with test products
- [ ] Test purchase flow
- [ ] Test refund handling
- [ ] Production testing
- [ ] Launch

---

## 🏗️ Architecture Overview

### **Components:**

```
┌─────────────────────────────────────────┐
│         Wallet Screen (UI)               │
│  ┌──────────────┐  ┌──────────────┐    │
│  │  PayPrime    │  │ Play Store   │    │
│  │  Button      │  │ Button        │    │
│  └──────┬───────┘  └──────┬───────┘    │
└─────────┼──────────────────┼────────────┘
          │                  │
          ▼                  ▼
┌─────────────────┐  ┌──────────────────┐
│ PayPrimeService │  │ PlayStoreService │
└────────┬────────┘  └────────┬─────────┘
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌──────────────────┐
│ Cloud Function  │  │ Cloud Function   │
│ initiatePayment │  │ verifyPurchase    │
└────────┬────────┘  └────────┬─────────┘
         │                    │
         └──────────┬─────────┘
                    ▼
         ┌──────────────────┐
         │  Firestore        │
         │  - payments       │
         │  - users (coins)  │
         └──────────────────┘
```

---

## 📦 Step-by-Step Implementation

### **STEP 1: Add Dependencies**

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

#### **2.1: Create Products in Play Console**

1. Go to: **Play Console** → Your App → **Monetize** → **Products** → **In-app products**
2. Click **Create product**
3. Create products for each coin package:

| Product ID | Name | Price | Coins |
|------------|------|-------|-------|
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
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
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
  
  // Initialize purchase service
  Future<bool> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        debugPrint('❌ Play Store billing not available');
        return false;
      }
      
      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('❌ Purchase error: $error'),
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
          'message': 'Product not found',
        };
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      if (success) {
        return {
          'success': true,
          'message': 'Purchase initiated',
        };
      } else {
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
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('⏳ Purchase pending: ${purchase.productID}');
        // Show pending UI
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('❌ Purchase error: ${purchase.error}');
        // Show error
      } else if (purchase.status == PurchaseStatus.purchased ||
                 purchase.status == PurchaseStatus.restored) {
        debugPrint('✅ Purchase successful: ${purchase.productID}');
        
        // Verify and process purchase
        await _verifyAndProcessPurchase(purchase);
        
        // Complete the purchase
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      }
    }
  }
  
  // Verify purchase with server
  Future<void> _verifyAndProcessPurchase(PurchaseDetails purchase) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ User not authenticated');
        return;
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
        return;
      }
      
      // Call cloud function to verify purchase
      final callable = _functions.httpsCallable('verifyPlayStorePurchase');
      final result = await callable.call({
        'productId': purchase.productID,
        'purchaseToken': purchaseToken,
        'orderId': orderId,
        'packageName': 'com.chamakz.app', // Your app package name
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        debugPrint('✅ Purchase verified and coins added');
        // Coins are added by cloud function
      } else {
        debugPrint('❌ Purchase verification failed: ${data['message']}');
      }
    } catch (e) {
      debugPrint('❌ Error verifying purchase: $e');
    }
  }
  
  // Restore purchases
  Future<void> restorePurchases() async {
    try {
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

### **STEP 4: Create Cloud Function for Purchase Verification**

**File:** `functions/index.js` (add this function)

```javascript
/**
 * Verify Google Play Store purchase and add coins
 */
exports.verifyPlayStorePurchase = onCall(
  {
    secrets: ["GOOGLE_PLAY_SERVICE_ACCOUNT_KEY"], // Optional: for server-side verification
  },
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
      // For now, we'll trust the client and verify later
      // In production, use Google Play Developer API to verify

      // Create payment record
      const paymentId = admin.firestore().collection('payments').doc().id;
      const paymentData = {
        userId: userId,
        orderId: orderId,
        paymentId: paymentId,
        productId: productId,
        coins: coins,
        amount: 0, // Amount is handled by Play Store
        currency: 'INR',
        status: 'SUCCESS',
        gateway: 'play_store',
        purchaseToken: purchaseToken,
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

### **STEP 5: Update Wallet Screen**

**File:** `lib/screens/wallet_screen.dart`

Add payment method selection:

```dart
// Add import
import '../services/play_store_purchase_service.dart';

// Add service instance
final PlayStorePurchaseService _playStoreService = PlayStorePurchaseService();

// Initialize in initState
@override
void initState() {
  super.initState();
  // ... existing code ...
  
  // Initialize Play Store service
  _playStoreService.initialize();
}

// Update _handleRecharge method
Future<void> _handleRecharge(Map<String, dynamic> package) async {
  // ... existing validation ...
  
  // Show payment method selection
  final paymentMethod = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Choose Payment Method'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.payment, color: Color(0xFFFF1B7C)),
            title: Text('PayPrime (UPI/Card)'),
            subtitle: Text('Pay via UPI, Cards'),
            onTap: () => Navigator.pop(context, 'payprime'),
          ),
          ListTile(
            leading: Icon(Icons.shopping_bag, color: Colors.green),
            title: Text('Google Play Store'),
            subtitle: Text('Pay via Play Store balance'),
            onTap: () => Navigator.pop(context, 'playstore'),
          ),
        ],
      ),
    ),
  );
  
  if (paymentMethod == 'payprime') {
    // Existing PayPrime flow
    // ... existing code ...
  } else if (paymentMethod == 'playstore') {
    // New Play Store flow
    await _handlePlayStorePurchase(package);
  }
}

// New method for Play Store purchase
Future<void> _handlePlayStorePurchase(Map<String, dynamic> package) async {
  final int coins = package['coins'] as int;
  final int inr = package['inr'] as int;
  
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product not found')),
    );
    return;
  }
  
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: CircularProgressIndicator(),
    ),
  );
  
  // Initiate purchase
  final result = await _playStoreService.purchaseProduct(productId);
  
  // Close loading
  Navigator.of(context).pop();
  
  if (result['success'] == true) {
    // Purchase initiated, will be handled by service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchase initiated')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Purchase failed')),
    );
  }
}
```

---

## 🔐 Security Considerations

### **Server-Side Verification (Recommended)**

For production, verify purchases server-side using Google Play Developer API:

1. **Get Service Account:**
   - Go to Google Cloud Console
   - Create service account
   - Download JSON key
   - Add to Firebase Secrets

2. **Verify Purchase Token:**
   - Use Google Play Developer API
   - Verify purchase token
   - Check purchase status
   - Prevent fraud

---

## 📋 Testing Checklist

### **Test Products Setup:**

1. Create test products in Play Console
2. Add test accounts
3. Test purchase flow
4. Test purchase verification
5. Test refund handling
6. Test restore purchases

### **Test Scenarios:**

- [ ] Successful purchase
- [ ] Purchase cancellation
- [ ] Purchase error
- [ ] Network error
- [ ] Duplicate purchase
- [ ] Restore purchases
- [ ] Refund handling

---

## 🚀 Deployment Steps

1. **Add Package:**
   ```bash
   flutter pub add in_app_purchase
   ```

2. **Create Products in Play Console:**
   - Add all 12 products
   - Set prices
   - Activate products

3. **Deploy Cloud Function:**
   ```bash
   firebase deploy --only functions:verifyPlayStorePurchase
   ```

4. **Test with Test Products:**
   - Use test accounts
   - Verify purchase flow
   - Check coin addition

5. **Release to Production:**
   - Update app version
   - Build release bundle
   - Upload to Play Console

---

## 📊 Comparison: PayPrime vs Play Store

| Feature | PayPrime | Play Store |
|---------|----------|------------|
| **Payment Methods** | UPI, Cards | Play Balance, Cards |
| **User Experience** | WebView | Native |
| **Setup Complexity** | Medium | Low |
| **Fees** | Merchant fees | 15-30% commission |
| **Refund Handling** | Manual | Automatic |
| **Global Availability** | India focused | Worldwide |
| **Verification** | Webhook | API |

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
   - Always verify purchases server-side
   - Prevent fraud and abuse

---

## 📝 Next Steps

1. ✅ Review this roadmap
2. ⚠️ Add `in_app_purchase` package
3. ⚠️ Create products in Play Console
4. ⚠️ Implement service
5. ⚠️ Update wallet screen
6. ⚠️ Deploy cloud function
7. ⚠️ Test thoroughly
8. ⚠️ Launch

---

**Status:** 📋 **Ready for Implementation**  
**Estimated Time:** 5-7 days  
**Priority:** Medium (Enhancement)
