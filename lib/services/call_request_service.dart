import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_request_model.dart';
import 'live_stream_service.dart';
import 'call_coin_deduction_service.dart';

class CallRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LiveStreamService _liveStreamService = LiveStreamService();
  final CallCoinDeductionService _coinDeductionService = CallCoinDeductionService();
  static const String _collection = 'callRequests';

  /// Send a call request from viewer to host
  Future<String> sendCallRequest({
    required String streamId,
    required String callerId,
    required String callerName,
    String? callerImage,
    required String hostId,
  }) async {
    try {
      // Check if user has enough coins (1000 coins per minute minimum)
      final hasEnoughCoins = await _coinDeductionService.hasEnoughCoins(callerId);
      if (!hasEnoughCoins) {
        final balance = await _coinDeductionService.getUserBalance(callerId);
        throw Exception('Insufficient balance. You need at least 1000 coins to start a call. Your balance: $balance coins');
      }
      
      // Check if host is already in a call
      final isHostBusy = await _liveStreamService.isHostInCall(streamId);
      if (isHostBusy) {
        throw Exception('Host is currently busy in a private call');
      }

      // Check for existing pending request from this caller
      final existingRequest = await _firestore
          .collection(_collection)
          .where('streamId', isEqualTo: streamId)
          .where('callerId', isEqualTo: callerId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        // Request already exists
        return existingRequest.docs.first.id;
      }

      // Create new call request
      final requestId = _firestore.collection(_collection).doc().id;
      final request = CallRequestModel(
        requestId: requestId,
        streamId: streamId,
        callerId: callerId,
        callerName: callerName,
        callerImage: callerImage,
        hostId: hostId,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).doc(requestId).set(request.toMap());
      print('✅ Call request sent: $requestId');
      
      // Auto-cleanup: Delete request after 5 minutes if not responded
      Future.delayed(const Duration(minutes: 5), () async {
        final doc = await _firestore.collection(_collection).doc(requestId).get();
        if (doc.exists) {
          final data = doc.data();
          if (data?['status'] == 'pending') {
            await _firestore.collection(_collection).doc(requestId).update({
              'status': 'cancelled',
              'respondedAt': DateTime.now().toIso8601String(),
            });
            print('⏰ Call request auto-cancelled after timeout: $requestId');
          }
        }
      });

      return requestId;
    } catch (e) {
      print('❌ Error sending call request: $e');
      rethrow;
    }
  }

  /// Host accepts call request
  Future<void> acceptCallRequest({
    required String requestId,
    required String streamId,
    required String callerId,
    required String callChannelName,
    required String callToken,
  }) async {
    try {
      // Update call request status
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'accepted',
        'respondedAt': DateTime.now().toIso8601String(),
        'callChannelName': callChannelName,
        'callToken': callToken,
      });

      // Update live stream status
      await _liveStreamService.setHostInCall(streamId, callerId);
      
      print('✅ Call request accepted: $requestId');
    } catch (e) {
      print('❌ Error accepting call request: $e');
      rethrow;
    }
  }

  /// Host rejects call request
  Future<void> rejectCallRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'rejected',
        'respondedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Call request rejected: $requestId');
    } catch (e) {
      print('❌ Error rejecting call request: $e');
      rethrow;
    }
  }

  /// Viewer cancels call request
  Future<void> cancelCallRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'cancelled',
        'respondedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Call request cancelled: $requestId');
    } catch (e) {
      print('❌ Error cancelling call request: $e');
      rethrow;
    }
  }

  /// End call (update request status and make host available)
  Future<void> endCall({
    required String requestId,
    required String streamId,
  }) async {
    try {
      // Update call request status
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'ended',
        'respondedAt': DateTime.now().toIso8601String(),
      });

      // Make host available again
      await _liveStreamService.setHostAvailable(streamId);
      
      print('✅ Call ended: $requestId');
    } catch (e) {
      print('❌ Error ending call: $e');
      rethrow;
    }
  }

  /// Listen to incoming call requests for host
  Stream<List<CallRequestModel>> listenToIncomingCallRequests(String hostId) {
    print('🔔 Setting up listener for incoming call requests - hostId: $hostId');
    return _firestore
        .collection(_collection)
        .where('hostId', isEqualTo: hostId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          print('📞 Call request snapshot received: ${snapshot.docs.length} pending requests');
          final requests = snapshot.docs
              .map((doc) {
                try {
                  return CallRequestModel.fromFirestore(doc);
                } catch (e) {
                  print('❌ Error parsing call request ${doc.id}: $e');
                  return null;
                }
              })
              .where((request) => request != null)
              .cast<CallRequestModel>()
              .toList();
          
          // Sort by createdAt descending (most recent first)
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return requests;
        })
        .handleError((error) {
          print('❌ Error in call request stream: $error');
        });
  }

  /// Listen to call request status for viewer
  Stream<CallRequestModel?> listenToCallRequestStatus(String requestId) {
    return _firestore
        .collection(_collection)
        .doc(requestId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return CallRequestModel.fromFirestore(doc);
        });
  }

  /// Get call request by ID
  Future<CallRequestModel?> getCallRequest(String requestId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      if (!doc.exists) return null;
      return CallRequestModel.fromFirestore(doc);
    } catch (e) {
      print('❌ Error getting call request: $e');
      return null;
    }
  }

  /// Cleanup old call requests (background task)
  Future<void> cleanupOldCallRequests() async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      final oldRequests = await _firestore
          .collection(_collection)
          .where('createdAt', isLessThan: fiveMinutesAgo.toIso8601String())
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      for (var doc in oldRequests.docs) {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'respondedAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
      print('✅ Cleaned up ${oldRequests.docs.length} old call requests');
    } catch (e) {
      print('❌ Error cleaning up old call requests: $e');
    }
  }
}
