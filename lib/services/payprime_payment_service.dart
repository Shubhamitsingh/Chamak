import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// PayPrime Payment Service
/// Handles payment initiation through Firebase Cloud Functions
class PayPrimePaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initiate a payment with PayPrime
  /// 
  /// Parameters:
  /// - amount: Payment amount in INR (number)
  /// - coins: Number of coins user is purchasing (number)
  /// - currency: Currency code (default: "INR")
  /// 
  /// Returns:
  /// - Map with success status, orderId, paymentId, and paymentUrl
  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required int coins,
    String currency = "INR",
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not authenticated. Please login again.',
        };
      }

      // Validate inputs
      if (amount <= 0) {
        return {
          'success': false,
          'message': 'Invalid payment amount',
        };
      }

      if (coins <= 0) {
        return {
          'success': false,
          'message': 'Invalid coin amount',
        };
      }

      debugPrint('📞 Calling initiatePayment Cloud Function...');
      debugPrint('   Amount: ₹$amount');
      debugPrint('   Coins: $coins');
      debugPrint('   Currency: $currency');

      // Call Cloud Function to initiate payment
      final callable = _functions.httpsCallable('initiatePayment');
      final result = await callable.call({
        'amount': amount,
        'coins': coins,
        'currency': currency,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        debugPrint('✅ Payment initiated successfully');
        debugPrint('   Order ID: ${data['orderId']}');
        debugPrint('   Payment ID: ${data['paymentId']}');
        debugPrint('   Payment URL: ${data['paymentUrl']}');

        return {
          'success': true,
          'orderId': data['orderId'],
          'paymentId': data['paymentId'],
          'paymentUrl': data['paymentUrl'],
          'upiUrls': data['upiUrls'] ?? {}, // All available UPI URLs
          'amount': data['amount'],
          'coins': data['coins'],
          'currency': data['currency'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to initiate payment',
        };
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Firebase Functions Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getErrorMessage(e.code, e.message ?? 'Unknown error'),
      };
    } catch (e) {
      debugPrint('❌ Error initiating payment: $e');
      return {
        'success': false,
        'message': 'Failed to initiate payment: ${e.toString()}',
      };
    }
  }

  /// Get user-friendly error message from Firebase Functions error code
  String _getErrorMessage(String code, String message) {
    switch (code) {
      case 'unauthenticated':
        return 'Please login again to continue';
      case 'permission-denied':
        return 'You do not have permission to perform this action';
      case 'invalid-argument':
        return 'Invalid payment details. Please check and try again';
      case 'deadline-exceeded':
        return 'Payment request timed out. Please try again';
      case 'not-found':
        return 'Payment service not available. Please try again later';
      case 'already-exists':
        return 'A payment is already in progress';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again';
      case 'failed-precondition':
        return 'Payment service is temporarily unavailable';
      case 'aborted':
        return 'Payment was cancelled. Please try again';
      case 'out-of-range':
        return 'Invalid payment amount';
      case 'unimplemented':
        return 'Payment feature is not available yet';
      case 'internal':
        return 'Internal server error. Please try again later';
      case 'unavailable':
        return 'Payment service is unavailable. Please try again later';
      case 'data-loss':
        return 'Data error. Please try again';
      default:
        return message.isNotEmpty ? message : 'An error occurred. Please try again';
    }
  }
}
