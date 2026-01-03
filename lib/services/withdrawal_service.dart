import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/withdrawal_request_model.dart';

class WithdrawalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a new withdrawal request
  // amount: Payment amount in INR (NOT C Coins) - for admin to see pending payment amount
  Future<String?> submitWithdrawalRequest({
    required String userId,
    required double amount, // Changed from int to double - now stores INR
    required String withdrawalMethod,
    required Map<String, dynamic> paymentDetails,
    String? userName,
    String? displayId,
  }) async {
    try {
      final docRef = await _firestore.collection('withdrawal_requests').add({
        'userId': userId,
        'userName': userName,
        'displayId': displayId,
        'amount': amount,
        'withdrawalMethod': withdrawalMethod,
        'paymentDetails': paymentDetails,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'approvedDate': null,
        'paidDate': null,
        'paymentProofURL': null,
        'adminNotes': null,
        'approvedBy': null,
      });
      return docRef.id;
    } catch (e) {
      print('Error submitting withdrawal request: $e');
      return null;
    }
  }

  // Get a stream of user's withdrawal requests
  Stream<List<WithdrawalRequestModel>> getUserWithdrawalRequests(String userId) {
    return _firestore
        .collection('withdrawal_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalRequestModel.fromFirestore(doc))
            .toList())
        .handleError((error) {
          // Log error but let it propagate to UI for handling
          print('Error fetching withdrawal requests: $error');
          throw error;
        });
  }
  
  // Fallback method: Get withdrawal requests without orderBy (no index needed)
  Stream<List<WithdrawalRequestModel>> getUserWithdrawalRequestsFallback(String userId) {
    return _firestore
        .collection('withdrawal_requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => WithdrawalRequestModel.fromFirestore(doc))
              .toList();
          // Sort in memory by requestDate descending
          requests.sort((a, b) => b.requestDate.compareTo(a.requestDate));
          return requests;
        });
  }

  // Get a stream of all withdrawal requests for admin
  Stream<List<WithdrawalRequestModel>> getAllWithdrawalRequests() {
    return _firestore
        .collection('withdrawal_requests')
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalRequestModel.fromFirestore(doc))
            .toList());
  }

  // Approve a withdrawal request
  // NOTE: C Coins are deducted when marked as paid, not when approved
  Future<bool> approveWithdrawalRequest(String requestId, String adminId) async {
    try {
      await _firestore.collection('withdrawal_requests').doc(requestId).update({
        'status': 'approved',
        'approvedDate': FieldValue.serverTimestamp(),
        'approvedBy': adminId,
      });
      return true;
    } catch (e) {
      print('Error approving withdrawal request: $e');
      return false;
    }
  }

  // Mark a withdrawal request as paid and upload payment proof
  // Deducts C Coins from earnings.totalCCoins (SINGLE SOURCE OF TRUTH)
  Future<bool> markAsPaid(String requestId, String adminId, String paymentProofURL, {String? adminNotes}) async {
    try {
      // Get withdrawal request to get userId and amount
      final requestDoc = await _firestore.collection('withdrawal_requests').doc(requestId).get();
      if (!requestDoc.exists) {
        print('❌ Withdrawal request not found: $requestId');
        return false;
      }
      
      final requestData = requestDoc.data()!;
      final userId = requestData['userId'] as String;
      
      // Handle backward compatibility: old records have int (C Coins), new ones have double (INR)
      final storedAmount = requestData['amount'];
      double amountInINR;
      int cCoinsToDeduct;
      
      if (storedAmount is int) {
        // Old format: stored as C Coins (int)
        cCoinsToDeduct = storedAmount;
        amountInINR = storedAmount * 0.04; // Convert to INR for logging
      } else {
        // New format: stored as INR (double)
        amountInINR = (storedAmount as num).toDouble();
        // Convert INR to C Coins for deduction
        cCoinsToDeduct = (amountInINR / 0.04).round();
      }
      
      // Use batch write to atomically update withdrawal status and deduct C Coins
      final batch = _firestore.batch();
      
      // 1. Update withdrawal request status
      batch.update(
        _firestore.collection('withdrawal_requests').doc(requestId),
        {
          'status': 'paid',
          'paidDate': FieldValue.serverTimestamp(),
          'paymentProofURL': paymentProofURL,
          'adminNotes': adminNotes,
          'approvedBy': adminId, // Ensure approvedBy is set if not already
        },
      );
      
      // 2. Deduct C Coins from earnings collection (SINGLE SOURCE OF TRUTH)
      final earningsRef = _firestore.collection('earnings').doc(userId);
      batch.set(
        earningsRef,
        {
          'totalCCoins': FieldValue.increment(-cCoinsToDeduct), // Deduct C Coins (converted from INR)
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      
      // Commit batch (all updates atomic)
      await batch.commit();
      
      print('✅ Withdrawal marked as paid: ₹${amountInINR.toStringAsFixed(2)} - Deducted $cCoinsToDeduct C Coins from user $userId');
      return true;
    } catch (e) {
      print('❌ Error marking withdrawal request as paid: $e');
      return false;
    }
  }
}

