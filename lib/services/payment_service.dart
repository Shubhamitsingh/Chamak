import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'coin_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ⚠️ NOTE: _coinService is kept for potential future use if UTR method is re-enabled with admin approval
  // final CoinService _coinService = CoinService();

  // UPI ID - Always use this UPI ID for all payments
  static const String upiId = 'hdfcshubit@axl';
  static const String merchantName = 'Ravindra Bahadur Singh';

  /// Submit UTR and automatically add coins
  /// ⚠️ CRITICAL FIX: This method has been disabled for security reasons
  /// Manual UTR submission bypasses payment verification and creates a financial vulnerability
  /// All payments must go through the secure PayPrime gateway
  Future<Map<String, dynamic>> submitUTR({
    required String utrNumber,
    required int coins,
    required int amount,
    required String packageId,
  }) async {
    // ⚠️ SECURITY FIX: Disable manual UTR payment to prevent financial fraud
    // This method previously allowed users to manually enter UTR numbers and get coins
    // without any verification, creating a critical security vulnerability
    return {
      'success': false,
      'message': 'Manual UTR payment is no longer available. Please use the secure payment gateway.',
    };
    
    /* DISABLED CODE - DO NOT USE
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Validate UTR format (basic validation)
      if (utrNumber.trim().isEmpty) {
        return {'success': false, 'message': 'Please enter UTR number'};
      }

      if (utrNumber.trim().length < 8) {
        return {'success': false, 'message': 'Invalid UTR number'};
      }

      // Check if UTR already exists (prevent duplicates)
      final existingPayment = await _firestore
          .collection('payments')
          .where('utrNumber', isEqualTo: utrNumber.trim().toUpperCase())
          .limit(1)
          .get();

      if (existingPayment.docs.isNotEmpty) {
        return {'success': false, 'message': 'This UTR number has already been used'};
      }

      // Create payment record
      final paymentRef = _firestore.collection('payments').doc();
      await paymentRef.set({
        'userId': currentUser.uid,
        'packageId': packageId,
        'coins': coins,
        'amount': amount,
        'utrNumber': utrNumber.trim().toUpperCase(),
        'status': 'completed', // Auto-complete since no verification needed
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Add coins using centralized CoinService (atomic update to both collections)
      final success = await _coinService.addCoins(
        userId: currentUser.uid,
        coins: coins,
        transactionId: paymentRef.id,
        description: 'Coin purchase via UPI - UTR: ${utrNumber.trim().toUpperCase()}',
      );

      if (!success) {
        return {'success': false, 'message': 'Error adding coins to wallet'};
      }

      // Record transaction
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('transactions')
          .add({
        'type': 'purchase',
        'coins': coins,
        'amount': amount,
        'paymentId': paymentRef.id,
        'utrNumber': utrNumber.trim().toUpperCase(),
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Coin purchase via UPI',
      });

      print('✅ Payment: Added $coins coins successfully via CoinService');

      return {
        'success': true,
        'message': 'Payment successful! $coins coins added to your wallet.',
        'paymentId': paymentRef.id,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error processing payment: ${e.toString()}'};
    }
    */
  }

  /// Get payment history for current user
  Stream<QuerySnapshot> getPaymentHistory() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

