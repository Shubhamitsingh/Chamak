import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_request_model.dart';

class CallRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'call_requests';

  /// Create a new call request
  Future<String> createCallRequest({
    required String fromUserId,
    required String fromUserName,
    String? fromUserPhotoUrl,
    required String toUserId,
    required String streamId,
  }) async {
    try {
      final requestId = _firestore.collection(_collection).doc().id;
      
      final request = CallRequestModel(
        requestId: requestId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        fromUserPhotoUrl: fromUserPhotoUrl,
        toUserId: toUserId,
        streamId: streamId,
        requestedAt: DateTime.now(),
      );

      await _firestore.collection(_collection).doc(requestId).set(request.toMap());
      
      print('✅ Call request created: $requestId');
      return requestId;
    } catch (e) {
      print('❌ Error creating call request: $e');
      rethrow;
    }
  }

  /// Accept a call request
  Future<void> acceptCallRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'accepted',
        'acceptedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Call request accepted: $requestId');
    } catch (e) {
      print('❌ Error accepting call request: $e');
      rethrow;
    }
  }

  /// Reject a call request
  Future<void> rejectCallRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Call request rejected: $requestId');
    } catch (e) {
      print('❌ Error rejecting call request: $e');
      rethrow;
    }
  }

  /// Cancel a call request
  Future<void> cancelCallRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'cancelled',
        'cancelledAt': DateTime.now().toIso8601String(),
      });
      print('✅ Call request cancelled: $requestId');
    } catch (e) {
      print('❌ Error cancelling call request: $e');
      rethrow;
    }
  }

  /// Get a specific call request
  Future<CallRequestModel?> getCallRequest(String requestId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      
      if (doc.exists && doc.data() != null) {
        return CallRequestModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting call request: $e');
      return null;
    }
  }

  /// Listen to call request status changes
  Stream<CallRequestModel?> listenToCallRequest(String requestId) {
    return _firestore
        .collection(_collection)
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return CallRequestModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Get pending requests for a host
  Stream<List<CallRequestModel>> getPendingRequests(String hostId) {
    return _firestore
        .collection(_collection)
        .where('toUserId', isEqualTo: hostId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CallRequestModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Get active call request for a user (if any)
  Future<CallRequestModel?> getActiveCallRequest(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return CallRequestModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Error getting active call request: $e');
      return null;
    }
  }
}



