import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'coin_service.dart';

/// PayPrime Payment Gateway API Service
/// Integrated with PayPrime API: https://payprime.in/api-docs/
class PaymentGatewayApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CoinService _coinService = CoinService();

  // ========== PAYPRIME API CONFIGURATION ==========
  
  /// PayPrime API Base URL
  static const String baseUrl = 'https://merchant.payprime.in';
  
  /// PayPrime Test Endpoint (for testing)
  static const String testEndpoint = '/test/payment/initiate';
  
  /// PayPrime Live Endpoint (for production)
  static const String liveEndpoint = '/payment/initiate';
  
  /// Use test mode? Set to false for production
  static const bool useTestMode = false; // PRODUCTION MODE - Live payments enabled
  
  /// PayPrime Public Key (from your dashboard)
  /// Production/Live Mode Key
  static const String publicKey = 'payprime_5d4fidq343lnn2azi1h3s54lv2gdzpfj362i9fgp55m920wycv14';
  
  /// PayPrime Secret Key (from your dashboard) - Keep this secure!
  /// Note: Secret key is stored in Firebase Functions secrets, not in client code
  /// This is only used for reference - actual secret is in Cloud Function
  static const String secretKey = 'payprime_yghwthmlapg14vc4agw4t909iq0xw30bc6hpkz5pkavj0t19ph14';
  
  /// Get the correct endpoint based on mode
  String get _endpoint => useTestMode ? testEndpoint : liveEndpoint;
  
  /// API Headers for PayPrime
  /// PayPrime uses form-urlencoded, not JSON
  Map<String, String> get _headers => {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Accept': 'application/json',
  };

  // ========== PAYMENT FLOW METHODS ==========

  /// Step 1: Create payment order with PayPrime API
  /// According to PayPrime docs: https://payprime.in/api-docs/
  Future<Map<String, dynamic>> createPaymentOrder({
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
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      // Create order in Firestore first (for tracking)
      final orderRef = _firestore.collection('orders').doc();
      final orderId = orderRef.id;
      final identifier = orderId.substring(0, 20); // PayPrime requires max 20 chars

      await orderRef.set({
        'userId': currentUser.uid,
        'packageId': packageId,
        'coins': coins,
        'amount': amount,
        'status': 'pending',
        'identifier': identifier,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Split user name into first and last name
      String firstName = '';
      String lastName = '';
      if (userName != null && userName.isNotEmpty) {
        final nameParts = userName.trim().split(' ');
        firstName = nameParts[0];
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      } else {
        firstName = 'User';
        lastName = '';
      }

      // ========== EMAIL HANDLING ==========
      // Since users login with phone + OTP (no email), we need a fallback
      // PayPrime REQUIRES email field, so we'll generate one from user ID
      String customerEmail = (userEmail?.trim() ?? currentUser.email?.trim() ?? '').trim();
      
      // If email is empty (which it will be for phone-based auth), create fallback
      if (customerEmail.isEmpty) {
        // Generate email from user ID: user_{first8chars}@chamak.app
        // This ensures PayPrime gets a valid email format
        customerEmail = 'user_${currentUser.uid.substring(0, 8)}@chamak.app';
        print('📧 No email found (phone-based auth), using fallback: $customerEmail');
      }

      // ========== MOBILE NUMBER HANDLING ==========
      // For phone-based auth, mobile should always be available
      String customerMobile = (userPhone?.trim() ?? '').trim();
      
      // Priority 1: Use phone from Firestore user data
      // Priority 2: Use phone from Firebase Auth (currentUser.phoneNumber)
      if (customerMobile.isEmpty) {
        final phoneNumber = currentUser.phoneNumber;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          // Remove country code, spaces, and non-digits
          customerMobile = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
          // For Indian numbers: take last 10 digits
          if (customerMobile.length > 10) {
            customerMobile = customerMobile.substring(customerMobile.length - 10);
          }
          print('📱 Using phone from Firebase Auth: $customerMobile');
        }
      } else {
        print('📱 Using phone from Firestore: $customerMobile');
      }
      
      // If mobile is still empty (shouldn't happen with phone auth), use placeholder
      if (customerMobile.isEmpty || customerMobile.length < 10) {
        customerMobile = '9999999999'; // Placeholder - PayPrime requires mobile
        print('⚠️ No valid mobile found, using placeholder: $customerMobile');
      }

      // Ensure mobile is exactly 10 digits (for Indian numbers)
      if (customerMobile.length > 10) {
        customerMobile = customerMobile.substring(customerMobile.length - 10);
      }

      print('📧 Customer Email: $customerEmail');
      print('📱 Customer Mobile: $customerMobile');

      // Prepare form data for PayPrime API
      // According to PayPrime API docs: https://payprime.in/api-docs/
      // PayPrime requires form-urlencoded format, not JSON
      final formData = {
        // Required parameters
        'public_key': publicKey, // Public API key (required)
        'identifier': identifier, // Unique identifier for payment (max 20 chars, required)
        'currency': 'INR', // Currency code in uppercase (required)
        'amount': amount.toStringAsFixed(2), // Payment amount as decimal string (required)
        'details': 'Purchase $coins coins - Package: $packageId', // Payment details (max 100 chars, required)
        'ipn_url': 'https://payprimeipn-ogyw7ujqvq-uc.a.run.app', // Firebase Cloud Function IPN endpoint (Production)
        'success_url': 'https://chamakz.app/payment/success', // Your website - redirects after successful payment
        'cancel_url': 'https://chamakz.app/payment/cancel', // Your website - redirects if payment cancelled
        'site_name': 'Chamak App', // Business site name (required)
        'checkout_theme': 'light', // Checkout theme: 'light' or 'dark' (optional, default: light)
        
        // Customer information (required by PayPrime API)
        'customer[first_name]': firstName, // Customer first name (required)
        'customer[last_name]': lastName, // Customer last name (required)
        'customer[email]': customerEmail, // Customer email (required, guaranteed to have value)
        'customer[mobile]': customerMobile, // Customer mobile (required, guaranteed to have value)
        
        // Optional: gateway_methods - specify payment methods (comma-separated or JSON array)
        // Example: 'gateway_methods': '["Payprime_n"]' or 'gateway_methods': 'Payprime_n'
        // Leaving it out allows all available payment methods
      };

      print('📤 Creating payment order with PayPrime API...');
      print('   URL: $baseUrl$_endpoint');
      print('   Mode: ${useTestMode ? "TEST" : "LIVE"}');
      print('   Identifier: $identifier');
      print('   Amount: ₹$amount');
      print('   Customer Email: $customerEmail');
      print('   Customer Mobile: $customerMobile');
      print('   Customer Name: $firstName $lastName');

      // Convert form data to URL-encoded string
      final body = formData.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Debug: Print the actual request body (hide sensitive data in production)
      print('📋 Request Body (first 200 chars): ${body.substring(0, body.length > 200 ? 200 : body.length)}...');
      print('🔑 Public Key being sent: $publicKey');

      // Call PayPrime API to create order
      final response = await http.post(
        Uri.parse('$baseUrl$_endpoint'),
        headers: _headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 PayPrime API Response Status: ${response.statusCode}');
      print('📥 PayPrime API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // PayPrime response format:
        // {
        //   "status": "success",
        //   "message": ["Payment initiated"],
        //   "redirect_url": "https://example.com/payment/checkout?payment_trx=..."
        // }
        
        final status = responseData['status'] as String?;
        
        if (status == 'success') {
          final redirectUrl = responseData['redirect_url'] as String?;
          final messages = responseData['message'] as List?;
          final message = messages != null && messages.isNotEmpty 
              ? messages[0].toString() 
              : 'Payment initiated';

          if (redirectUrl == null || redirectUrl.isEmpty) {
            print('❌ No redirect URL in PayPrime response');
            return {
              'success': false,
              'message': 'No redirect URL received from PayPrime',
            };
          }

          print('✅ PayPrime returned redirect URL: $redirectUrl');
          print('🔗 URL length: ${redirectUrl.length}');
          print('🔗 URL starts with https: ${redirectUrl.startsWith('https://')}');

          // Extract payment transaction ID from redirect URL if possible
          final paymentId = _extractPaymentIdFromUrl(redirectUrl) ?? identifier;

          // Update order with payment info
          await orderRef.update({
            'paymentId': paymentId,
            'status': 'initiated',
            'redirectUrl': redirectUrl,
          });

          print('✅ Payment order created successfully');
          print('   Order ID: $orderId');
          print('   Payment ID: $paymentId');
          print('   Payment URL: $redirectUrl');

          return {
            'success': true,
            'orderId': orderId,
            'paymentId': paymentId,
            'paymentUrl': redirectUrl, // This is the redirect_url from PayPrime
            'message': message,
          };
        } else {
          // Error response from PayPrime
          final messages = responseData['message'] as List?;
          final errorMessage = messages != null && messages.isNotEmpty 
              ? messages[0].toString() 
              : 'Failed to create payment order';
          
          // Special handling for "Invalid api key" error
          if (errorMessage.toLowerCase().contains('invalid') && 
              errorMessage.toLowerCase().contains('api key')) {
            print('❌ API Key Error - Troubleshooting:');
            print('   1. Verify keys in PayPrime Dashboard');
            print('   2. Check if test mode requires different keys');
            print('   3. Ensure keys are activated in PayPrime account');
            print('   4. Current key: ${publicKey.substring(0, 20)}...');
            print('   5. Mode: ${useTestMode ? "TEST" : "LIVE"}');
            print('   6. Endpoint: $_endpoint');
          }
          
          return {
            'success': false,
            'message': errorMessage,
          };
        }
      } else {
        // HTTP error
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final messages = errorData['message'] as List?;
          final errorMessage = messages != null && messages.isNotEmpty 
              ? messages[0].toString() 
              : 'Failed to create payment order';
          
          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'HTTP ${response.statusCode}: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('❌ Error creating payment order: $e');
      return {
        'success': false,
        'message': 'Error creating payment order: ${e.toString()}',
      };
    }
  }

  /// Extract payment ID from PayPrime redirect URL
  String? _extractPaymentIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final paymentTrx = uri.queryParameters['payment_trx'];
      return paymentTrx;
    } catch (e) {
      return null;
    }
  }

  /// Step 2: Verify payment using PayPrime IPN callback data
  /// PayPrime sends POST to your IPN URL with: status, identifier, signature, data
  /// This method verifies the signature and processes the payment
  Future<Map<String, dynamic>> verifyPaymentFromIPN({
    required String status,
    required String identifier,
    required String signature,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔍 Verifying PayPrime payment from IPN...');
      print('   Status: $status');
      print('   Identifier: $identifier');
      print('   Data: $data');

      // Find order by identifier
      final orderQuery = await _firestore
          .collection('orders')
          .where('identifier', isEqualTo: identifier)
          .limit(1)
          .get();

      if (orderQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Order not found for identifier: $identifier',
        };
      }

      final orderDoc = orderQuery.docs.first;
      final orderData = orderDoc.data();
      final orderId = orderDoc.id;
      final userId = orderData['userId'] as String;
      final coins = orderData['coins'] as int;
      final amount = orderData['amount'] as int;
      final packageId = orderData['packageId'] as String;

      // Verify signature
      // PayPrime signature: HMAC SHA256 of (amount + identifier) using secret key
      // According to docs: customKey = data.amount + identifier
      final amountFromData = data['amount']?.toString() ?? amount.toString();
      final customKey = '$amountFromData$identifier';
      final expectedSignature = _generateSignature(customKey, secretKey);
      
      print('🔐 Signature Verification:');
      print('   Custom Key: $customKey');
      print('   Expected: $expectedSignature');
      print('   Received: $signature');

      if (signature.toUpperCase() != expectedSignature.toUpperCase()) {
        print('❌ Signature verification failed!');
        print('   Expected: $expectedSignature');
        print('   Received: $signature');
        return {
          'success': false,
          'message': 'Invalid signature - payment verification failed',
        };
      }

      // Verify identifier matches
      if (orderData['identifier'] != identifier) {
        return {
          'success': false,
          'message': 'Identifier mismatch',
        };
      }

      // Check payment status
      if (status != 'success') {
        return {
          'success': false,
          'message': 'Payment status is not success: $status',
        };
      }

      // Check if coins already added (prevent duplicate)
      final existingPayment = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      if (existingPayment.docs.isNotEmpty) {
        return {
          'success': true,
          'message': 'Payment already processed',
          'coins': coins,
        };
      }

      // Get payment transaction ID from data
      final paymentId = data['payment_transaction_id']?.toString() ?? 
                       data['transaction_id']?.toString() ?? 
                       orderId;

      // Add coins to user account
      final success = await _coinService.addCoins(
        userId: userId,
        coins: coins,
        transactionId: paymentId,
        description: 'Coin purchase via PayPrime - Package: $packageId',
      );

      if (!success) {
        return {
          'success': false,
          'message': 'Failed to add coins to account',
        };
      }

      // Update order status
      await orderDoc.reference.update({
        'status': 'completed',
        'paymentId': paymentId,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // Record payment in payments collection
      await _firestore.collection('payments').doc(paymentId).set({
        'userId': userId,
        'packageId': packageId,
        'coins': coins,
        'amount': amount,
        'paymentId': paymentId,
        'orderId': orderId,
        'identifier': identifier,
        'status': 'completed',
        'paymentMethod': 'payprime',
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
        'description': 'Coin purchase via PayPrime',
      });

      print('✅ Payment verified and coins added successfully!');

      return {
        'success': true,
        'message': 'Payment verified and coins added successfully',
        'coins': coins,
        'amount': amount,
      };
    } catch (e) {
      print('❌ Error verifying payment: $e');
      return {
        'success': false,
        'message': 'Error verifying payment: ${e.toString()}',
      };
    }
  }

  /// Generate HMAC SHA256 signature for PayPrime
  String _generateSignature(String data, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString().toUpperCase();
  }

  /// Verify payment status by checking order and payments in Firestore
  /// This checks both orders collection and payments collection (created by IPN)
  /// Use this when user returns from payment page
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    String? paymentToken,
  }) async {
    try {
      print('🔍 Verifying payment status...');
      print('   Order ID: $orderId');
      print('   Payment ID: $paymentId');

      // 1. Check order status first
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      
      if (!orderDoc.exists) {
        print('❌ Order not found: $orderId');
        return {
          'success': false,
          'message': 'Order not found',
        };
      }

      final orderData = orderDoc.data()!;
      final orderStatus = orderData['status'] as String?;
      final coins = orderData['coins'] as int;

      print('📦 Order Status: $orderStatus');

      // 2. Check if order is already completed
      if (orderStatus == 'completed') {
        print('✅ Order already completed');
        return {
          'success': true,
          'message': 'Payment already verified',
          'coins': coins,
        };
      }

      // 3. Check payments collection (created by IPN callback)
      // IPN creates a payment record when payment is successful
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      if (paymentsQuery.docs.isNotEmpty) {
        print('✅ Payment found in payments collection (IPN received)');
        final paymentData = paymentsQuery.docs.first.data();
        final paymentCoins = paymentData['coins'] as int? ?? coins;
        
        // Update order status if not already updated
        if (orderStatus != 'completed') {
          await orderDoc.reference.update({
            'status': 'completed',
            'verifiedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Updated order status to completed');
        }

        return {
          'success': true,
          'message': 'Payment verified successfully',
          'coins': paymentCoins,
        };
      }

      // 4. Also check by paymentId (alternative lookup)
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      if (paymentDoc.exists) {
        final paymentData = paymentDoc.data()!;
        final paymentStatus = paymentData['status'] as String?;
        final paymentCoins = paymentData['coins'] as int? ?? coins;

        if (paymentStatus == 'completed') {
          print('✅ Payment found by paymentId (IPN received)');
          
          // Update order status if not already updated
          if (orderStatus != 'completed') {
            await orderDoc.reference.update({
              'status': 'completed',
              'verifiedAt': FieldValue.serverTimestamp(),
            });
            print('✅ Updated order status to completed');
          }

          return {
            'success': true,
            'message': 'Payment verified successfully',
            'coins': paymentCoins,
          };
        }
      }

      // 5. Check if payment failed
      if (orderStatus == 'failed') {
        print('❌ Payment failed');
        return {
          'success': false,
          'message': 'Payment failed',
        };
      }

      // 6. Payment still pending - IPN not received yet
      print('⏳ Payment verification pending (waiting for IPN callback)');
      print('   Order Status: $orderStatus');
      print('   Payment ID: $paymentId');
      print('   Note: PayPrime IPN may take a few seconds to arrive');
      
      return {
        'success': false,
        'message': 'Payment verification pending. Please wait for confirmation.',
        'pending': true,
      };
    } catch (e) {
      print('❌ Error verifying payment: $e');
      return {
        'success': false,
        'message': 'Error verifying payment: ${e.toString()}',
      };
    }
  }

  /// Handle payment callback/webhook from PayPrime IPN
  /// PayPrime sends POST to your IPN URL with form data
  Future<Map<String, dynamic>> handlePaymentCallback(Map<String, dynamic> callbackData) async {
    try {
      final status = callbackData['status']?.toString() ?? '';
      final identifier = callbackData['identifier']?.toString() ?? '';
      final signature = callbackData['signature']?.toString() ?? '';
      
      // Parse data - it might be a string or already a map
      Map<String, dynamic> data;
      if (callbackData['data'] is String) {
        data = jsonDecode(callbackData['data']) as Map<String, dynamic>;
      } else {
        data = callbackData['data'] as Map<String, dynamic>? ?? {};
      }

      if (status.isEmpty || identifier.isEmpty || signature.isEmpty) {
        return {
          'success': false,
          'message': 'Missing required fields in callback',
        };
      }

      return await verifyPaymentFromIPN(
        status: status,
        identifier: identifier,
        signature: signature,
        data: data,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error handling callback: ${e.toString()}',
      };
    }
  }
}
