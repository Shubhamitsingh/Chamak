import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/withdrawal_request_model.dart';

class WithdrawalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a new withdrawal request
  Future<String?> submitWithdrawalRequest({
    required String userId,
    required int amount,
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
  Future<bool> markAsPaid(String requestId, String adminId, String paymentProofURL, {String? adminNotes}) async {
    try {
      await _firestore.collection('withdrawal_requests').doc(requestId).update({
        'status': 'paid',
        'paidDate': FieldValue.serverTimestamp(),
        'paymentProofURL': paymentProofURL,
        'adminNotes': adminNotes,
        'approvedBy': adminId, // Ensure approvedBy is set if not already
      });
      return true;
    } catch (e) {
      print('Error marking withdrawal request as paid: $e');
      return false;
    }
  }
}

