# 💳 Payment Gateway Integration - Complete Step-by-Step Roadmap

## 📋 **Executive Summary**

This document provides a **beginner-friendly, step-by-step guide** to integrate a payment gateway API into your wallet screen. After integration, users will be able to:
1. Click on any coin package
2. Pay using the payment gateway
3. Automatically receive coins in their account after successful payment

---

## 🔍 **Current Code Analysis**

### ✅ **What You Already Have:**

1. **Wallet Screen** (`lib/screens/wallet_screen.dart`)
   - 9 coin packages displayed in a 3-column grid
   - Each package shows: coins, INR amount, bonus percentage
   - Currently **NOT clickable** (no payment flow)

2. **Coin Service** (`lib/services/coin_service.dart`)
   - ✅ `addCoins()` method - Adds coins to user account
   - ✅ Updates both `users` and `wallets` collections in Firestore
   - ✅ Atomic transactions (safe and reliable)

3. **Payment Service** (`lib/services/payment_service.dart`)
   - ✅ Currently handles UTR-based manual payments
   - ✅ Can be extended for payment gateway integration

4. **Database Structure:**
   - Coins stored in: `users/{userId}/uCoins`
   - Also synced to: `wallets/{userId}/balance`
   - Transaction history: `users/{userId}/transactions`

### ❌ **What's Missing:**

1. Payment gateway SDK integration
2. Click handlers on deposit cards
3. Payment flow UI (loading, success, error)
4. Payment verification and webhook handling

---

## 🎯 **Step-by-Step Integration Roadmap**

### **PHASE 1: Choose & Setup Payment Gateway** (30 minutes)

#### **Step 1.1: Select Payment Gateway**

**Recommended: Razorpay** (Most popular in India, easy Flutter integration)

**Why Razorpay?**
- ✅ Easy Flutter SDK
- ✅ Supports UPI, Cards, Wallets, Net Banking
- ✅ Good documentation
- ✅ Low transaction fees
- ✅ Test mode available

**Alternatives:**
- PayU (also good for Flutter)
- PhonePe (limited Flutter support)
- Paytm (complex setup)

#### **Step 1.2: Create Razorpay Account**

1. Go to: https://razorpay.com/
2. Sign up for a **Business Account**
3. Complete KYC verification
4. Get your **API Keys**:
   - **Key ID** (Public Key)
   - **Key Secret** (Private Key - keep secret!)

#### **Step 1.3: Setup Test Mode**

1. In Razorpay Dashboard → Settings → API Keys
2. Copy **Test Key ID** and **Test Key Secret**
3. Use these for development/testing
4. Switch to **Live Keys** when going to production

---

### **PHASE 2: Install Payment Gateway SDK** (15 minutes)

#### **Step 2.1: Add Razorpay Package**

Open `pubspec.yaml` and add:

```yaml
dependencies:
  # ... existing dependencies ...
  
  # Payment Gateway
  razorpay_flutter: ^1.3.0  # Latest version
```

#### **Step 2.2: Install Package**

Run in terminal:
```bash
flutter pub get
```

#### **Step 2.3: Android Configuration**

**File: `android/app/build.gradle`**

Add to `android` section:
```gradle
android {
    defaultConfig {
        // ... existing config ...
        minSdkVersion 21  // Razorpay requires minimum 21
    }
}
```

**File: `android/app/src/main/AndroidManifest.xml`**

Add internet permission (if not already present):
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- ... other permissions ... -->
</manifest>
```

#### **Step 2.4: iOS Configuration** (if supporting iOS)

**File: `ios/Podfile`**

Ensure minimum iOS version:
```ruby
platform :ios, '12.0'
```

---

### **PHASE 3: Create Payment Gateway Service** (45 minutes)

#### **Step 3.1: Create New Service File**

**File: `lib/services/payment_gateway_service.dart`**

```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'coin_service.dart';

class PaymentGatewayService {
  final Razorpay _razorpay = Razorpay();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CoinService _coinService = CoinService();

  // Your Razorpay API Keys (from Step 1.2)
  static const String _razorpayKeyId = 'YOUR_TEST_KEY_ID'; // Replace with your key
  static const String _razorpayKeySecret = 'YOUR_TEST_KEY_SECRET'; // Replace with your secret

  // Payment success callback
  Function(Map<String, dynamic>)? onPaymentSuccess;
  Function(String)? onPaymentError;

  /// Initialize Razorpay
  void init({
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) {
    onPaymentSuccess = onSuccess;
    onPaymentError = onError;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('✅ Payment Success: ${response.paymentId}');

    try {
      // Extract payment details
      final paymentId = response.paymentId ?? '';
      final orderId = response.orderId ?? '';
      final signature = response.signature ?? '';

      // Verify payment (optional but recommended)
      final isValid = await _verifyPayment(paymentId, orderId, signature);
      
      if (!isValid) {
        onPaymentError?.call('Payment verification failed');
        return;
      }

      // Get payment details from Firestore (we'll store order details before payment)
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        onPaymentError?.call('Order not found');
        return;
      }

      final orderData = orderDoc.data()!;
      final userId = orderData['userId'] as String;
      final coins = orderData['coins'] as int;
      final amount = orderData['amount'] as int;
      final packageId = orderData['packageId'] as String;

      // Update order status
      await orderDoc.reference.update({
        'status': 'completed',
        'paymentId': paymentId,
        'signature': signature,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Add coins to user account
      final success = await _coinService.addCoins(
        userId: userId,
        coins: coins,
        transactionId: paymentId,
        description: 'Coin purchase via Razorpay - Package: $packageId',
      );

      if (success) {
        // Record payment in payments collection
        await _firestore.collection('payments').doc(paymentId).set({
          'userId': userId,
          'packageId': packageId,
          'coins': coins,
          'amount': amount,
          'paymentId': paymentId,
          'orderId': orderId,
          'status': 'completed',
          'paymentMethod': 'razorpay',
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Record transaction
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(paymentId)
            .set({
          'type': 'purchase',
          'coins': coins,
          'amount': amount,
          'paymentId': paymentId,
          'timestamp': FieldValue.serverTimestamp(),
          'description': 'Coin purchase via Razorpay',
        });

        // Call success callback
        onPaymentSuccess?.call({
          'paymentId': paymentId,
          'orderId': orderId,
          'coins': coins,
          'amount': amount,
        });
      } else {
        onPaymentError?.call('Failed to add coins to account');
      }
    } catch (e) {
      print('❌ Error processing payment: $e');
      onPaymentError?.call('Error processing payment: ${e.toString()}');
    }
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error: ${response.code} - ${response.message}');
    onPaymentError?.call(response.message ?? 'Payment failed');
  }

  /// Handle external wallet (optional)
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    // Handle external wallet flow if needed
  }

  /// Create order and open payment gateway
  Future<void> initiatePayment({
    required int coins,
    required int amount,
    required String packageId,
    String? userName,
    String? userEmail,
    String? userPhone,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Create order in Firestore
      final orderRef = _firestore.collection('orders').doc();
      final orderId = orderRef.id;

      await orderRef.set({
        'userId': currentUser.uid,
        'packageId': packageId,
        'coins': coins,
        'amount': amount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Prepare Razorpay options
      var options = {
        'key': _razorpayKeyId,
        'amount': amount * 100, // Amount in paise (multiply by 100)
        'name': 'Chamak App',
        'description': 'Purchase $coins coins',
        'prefill': {
          'contact': userPhone ?? '',
          'email': userEmail ?? currentUser.email ?? '',
        },
        'external': {
          'wallets': ['paytm'] // Optional: enable specific wallets
        },
        'order_id': orderId, // Use Firestore order ID
      };

      // Open Razorpay checkout
      _razorpay.open(options);
    } catch (e) {
      print('❌ Error initiating payment: $e');
      onPaymentError?.call('Error initiating payment: ${e.toString()}');
    }
  }

  /// Verify payment signature (recommended for security)
  Future<bool> _verifyPayment(String paymentId, String orderId, String signature) async {
    // TODO: Implement server-side verification
    // For now, return true (you should verify on your backend)
    // In production, call your backend API to verify signature
    return true;
  }

  /// Dispose Razorpay instance
  void dispose() {
    _razorpay.clear();
  }
}
```

---

### **PHASE 4: Update Wallet Screen** (30 minutes)

#### **Step 4.1: Add Click Handler to Deposit Cards**

**File: `lib/screens/wallet_screen.dart`**

1. **Add imports at top:**
```dart
import '../services/payment_gateway_service.dart';
```

2. **Add service instance in `_WalletScreenState` class:**
```dart
class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  // ... existing code ...
  final PaymentGatewayService _paymentGatewayService = PaymentGatewayService();
  bool _isProcessingPayment = false;
```

3. **Initialize payment gateway in `initState()`:**
```dart
@override
void initState() {
  super.initState();
  
  // Setup payment gateway
  _paymentGatewayService.init(
    onSuccess: _handlePaymentSuccess,
    onError: _handlePaymentError,
  );
  
  // ... existing code ...
}
```

4. **Add payment handlers:**
```dart
/// Handle successful payment
void _handlePaymentSuccess(Map<String, dynamic> response) {
  final coins = response['coins'] as int;
  
  setState(() {
    _isProcessingPayment = false;
  });
  
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Payment successful! $coins coins added to your wallet.',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
  
  // Refresh balance
  _loadCoinBalance();
}

/// Handle payment error
void _handlePaymentError(String error) {
  setState(() {
    _isProcessingPayment = false;
  });
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
```

5. **Update `_buildDepositCard` to make it clickable:**
```dart
Widget _buildDepositCard(Map<String, dynamic> package, int index) {
  final int coins = package['coins'];
  final int inr = package['inr'];
  final dynamic bonusValue = package['bonus'];
  final int bonus = (bonusValue is int) ? bonusValue : (bonusValue is String) ? int.tryParse(bonusValue) ?? 0 : 0;
  final bool showBadge = bonus > 0 && index > 1 && index != 3 && index != 5 && index != 7;
  final bool showBadgeText = (index == 3 || index == 5 || index == 7) && package['badge'] != null;
  
  return GestureDetector(
    onTap: _isProcessingPayment ? null : () => _handlePackageClick(package, index),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha:0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB800).withValues(alpha:0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ... rest of existing Container code ...
    ),
  );
}
```

6. **Add package click handler:**
```dart
/// Handle package click - initiate payment
Future<void> _handlePackageClick(Map<String, dynamic> package, int index) async {
  final int coins = package['coins'];
  final int inr = package['inr'];
  final String packageId = 'package_${index}_${coins}_${inr}';
  
  // Get user info
  final currentUser = _auth.currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please login to purchase coins'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // Show loading
  setState(() {
    _isProcessingPayment = true;
  });
  
  // Get user data for prefill
  try {
    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data();
    final userName = userData?['displayName'] as String? ?? '';
    final userPhone = userData?['phoneNumber'] as String? ?? '';
    final userEmail = currentUser.email ?? '';
    
    // Initiate payment
    await _paymentGatewayService.initiatePayment(
      coins: coins,
      amount: inr,
      packageId: packageId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
    );
  } catch (e) {
    setState(() {
      _isProcessingPayment = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

7. **Dispose payment gateway in `dispose()`:**
```dart
@override
void dispose() {
  _paymentGatewayService.dispose();
  // ... existing dispose code ...
  super.dispose();
}
```

---

### **PHASE 5: Testing** (30 minutes)

#### **Step 5.1: Test Payment Flow**

1. **Use Razorpay Test Cards:**
   - Card Number: `4111 1111 1111 1111`
   - CVV: Any 3 digits (e.g., `123`)
   - Expiry: Any future date (e.g., `12/25`)
   - Name: Any name

2. **Test Scenarios:**
   - ✅ Successful payment
   - ✅ Payment cancellation
   - ✅ Payment failure
   - ✅ Network error handling

#### **Step 5.2: Verify Coins Added**

1. After successful payment, check:
   - Wallet balance updated
   - Transaction recorded in Firestore
   - Payment record created

---

### **PHASE 6: Production Setup** (1 hour)

#### **Step 6.1: Switch to Live Keys**

1. In Razorpay Dashboard → Settings → API Keys
2. Copy **Live Key ID** and **Live Key Secret**
3. Update in `payment_gateway_service.dart`:
```dart
static const String _razorpayKeyId = 'YOUR_LIVE_KEY_ID';
static const String _razorpayKeySecret = 'YOUR_LIVE_KEY_SECRET';
```

#### **Step 6.2: Setup Webhook (Recommended)**

1. In Razorpay Dashboard → Settings → Webhooks
2. Add webhook URL: `https://your-backend.com/webhook/razorpay`
3. Select events: `payment.captured`, `payment.failed`
4. Verify webhook signature on your backend

#### **Step 6.3: Security Best Practices**

1. **Never store keys in app code** (use environment variables or backend)
2. **Verify payment signatures** on backend
3. **Use HTTPS** for all API calls
4. **Implement rate limiting** to prevent abuse

---

## 📊 **Database Structure**

### **Orders Collection** (New)
```
orders/{orderId}
  - userId: string
  - packageId: string
  - coins: number
  - amount: number
  - status: 'pending' | 'completed' | 'failed'
  - paymentId: string (after payment)
  - signature: string (after payment)
  - createdAt: timestamp
  - completedAt: timestamp
```

### **Payments Collection** (Updated)
```
payments/{paymentId}
  - userId: string
  - packageId: string
  - coins: number
  - amount: number
  - paymentId: string
  - orderId: string
  - status: 'completed' | 'failed'
  - paymentMethod: 'razorpay'
  - createdAt: timestamp
  - completedAt: timestamp
```

---

## 🎨 **UI/UX Enhancements (Optional)**

### **Loading State**
- Show loading indicator when payment is processing
- Disable package cards during payment

### **Success Animation**
- Show success animation after payment
- Confetti effect (optional)

### **Error Handling**
- User-friendly error messages
- Retry option for failed payments

---

## 🔒 **Security Checklist**

- [ ] API keys stored securely (not in code)
- [ ] Payment signature verification implemented
- [ ] HTTPS enabled for all API calls
- [ ] Rate limiting implemented
- [ ] Webhook verification on backend
- [ ] Transaction logging enabled
- [ ] Error logging setup

---

## 📝 **Code Files Summary**

### **Files to Create:**
1. `lib/services/payment_gateway_service.dart` - Payment gateway service

### **Files to Modify:**
1. `lib/screens/wallet_screen.dart` - Add click handlers and payment flow
2. `pubspec.yaml` - Add razorpay_flutter package
3. `android/app/build.gradle` - Update minSdkVersion

---

## 🚀 **Quick Start Checklist**

- [ ] Step 1: Create Razorpay account and get API keys
- [ ] Step 2: Add razorpay_flutter package
- [ ] Step 3: Create payment_gateway_service.dart
- [ ] Step 4: Update wallet_screen.dart with click handlers
- [ ] Step 5: Test with test cards
- [ ] Step 6: Switch to live keys for production

---

## 💡 **Common Issues & Solutions**

### **Issue 1: Payment not opening**
- **Solution:** Check API keys are correct, check internet connection

### **Issue 2: Coins not adding after payment**
- **Solution:** Check Firestore permissions, verify CoinService.addCoins() is called

### **Issue 3: Payment success but order not found**
- **Solution:** Ensure order is created before opening payment gateway

---

## 📞 **Support Resources**

- **Razorpay Docs:** https://razorpay.com/docs/payments/
- **Flutter Package:** https://pub.dev/packages/razorpay_flutter
- **Razorpay Support:** support@razorpay.com

---

## ✅ **Final Notes**

1. **Start with Test Mode** - Test thoroughly before going live
2. **Backend Verification** - Implement server-side payment verification
3. **Error Handling** - Handle all edge cases
4. **User Experience** - Make payment flow smooth and intuitive
5. **Security** - Never expose API keys in client code

---

**Good luck with your integration! 🎉**

If you need help with any specific step, let me know!
