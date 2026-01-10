import 'dart:async';
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
      // Check if user has enough coins (300 coins per minute minimum) (with timeout)
      final hasEnoughCoins = await _coinDeductionService.hasEnoughCoins(callerId)
          .timeout(const Duration(seconds: 10));
      if (!hasEnoughCoins) {
        final balance = await _coinDeductionService.getUserBalance(callerId)
            .timeout(const Duration(seconds: 10));
        throw Exception('Insufficient balance. You need at least 300 coins to start a call. Your balance: $balance coins');
      }
      
      // Check if host is already in a call (with timeout)
      final isHostBusy = await _liveStreamService.isHostInCall(streamId)
          .timeout(const Duration(seconds: 10));
      if (isHostBusy) {
        throw Exception('Host is currently busy in a private call');
      }

      // Check for existing pending request from this caller (with timeout)
      final existingRequest = await _firestore
          .collection(_collection)
          .where('streamId', isEqualTo: streamId)
          .where('callerId', isEqualTo: callerId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      if (existingRequest.docs.isNotEmpty) {
        // Request already exists
        return existingRequest.docs.first.id;
      }

      // Create new call request (with timeout)
      final requestId = _firestore.collection(_collection).doc().id;
      final request = CallRequestModel(
        requestId: requestId,
        streamId: streamId, // Required for live stream calls
        callerId: callerId,
        callerName: callerName,
        callerImage: callerImage,
        hostId: hostId, // Required for live stream calls
        callType: 'live_stream', // Explicitly set for live stream calls
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).doc(requestId).set(request.toMap())
          .timeout(const Duration(seconds: 10));
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

  /// Send a call request from user to user (chat screen)
  Future<String> sendChatCallRequest({
    required String callerId,
    required String callerName,
    String? callerImage,
    required String receiverId,
  }) async {
    try {
      // Check if user has enough coins (300 coins per minute minimum)
      final hasEnoughCoins = await _coinDeductionService.hasEnoughCoins(callerId)
          .timeout(const Duration(seconds: 10));
      if (!hasEnoughCoins) {
        final balance = await _coinDeductionService.getUserBalance(callerId)
            .timeout(const Duration(seconds: 10));
        throw Exception('Insufficient balance. You need at least 300 coins to start a call. Your balance: $balance coins');
      }

      // Check for existing pending request from this caller to this receiver
      final existingRequest = await _firestore
          .collection(_collection)
          .where('receiverId', isEqualTo: receiverId)
          .where('callerId', isEqualTo: callerId)
          .where('status', isEqualTo: 'pending')
          .where('callType', isEqualTo: 'chat')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      if (existingRequest.docs.isNotEmpty) {
        // Request already exists
        return existingRequest.docs.first.id;
      }

      // Create new chat call request
      final requestId = _firestore.collection(_collection).doc().id;
      final request = CallRequestModel(
        requestId: requestId,
        streamId: null, // No streamId for chat calls
        callerId: callerId,
        callerName: callerName,
        callerImage: callerImage,
        hostId: null, // No hostId for chat calls
        receiverId: receiverId, // Use receiverId for chat calls
        callType: 'chat',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).doc(requestId).set(request.toMap())
          .timeout(const Duration(seconds: 10));
      print('✅ Chat call request sent: $requestId');
      
      // Auto-cleanup: Cancel request after 60 seconds if not responded
      Future.delayed(const Duration(seconds: 60), () async {
        final doc = await _firestore.collection(_collection).doc(requestId).get();
        if (doc.exists) {
          final data = doc.data();
          if (data?['status'] == 'pending') {
            await _firestore.collection(_collection).doc(requestId).update({
              'status': 'cancelled',
              'respondedAt': DateTime.now().toIso8601String(),
            });
            print('⏰ Chat call request auto-cancelled after timeout: $requestId');
          }
        }
      });

      return requestId;
    } catch (e) {
      print('❌ Error sending chat call request: $e');
      rethrow;
    }
  }

  /// Accept call request (works for both live stream and chat calls)
  Future<void> acceptCallRequest({
    required String requestId,
    String? streamId, // Optional - only for live stream calls
    required String callerId,
    required String callChannelName,
    required String callToken,
  }) async {
    try {
      // Get call request to check type
      final callRequest = await getCallRequest(requestId);
      if (callRequest == null) {
        throw Exception('Call request not found');
      }

      // Update call request status (with timeout)
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'accepted',
        'respondedAt': DateTime.now().toIso8601String(),
        'callChannelName': callChannelName,
        'callToken': callToken,
      }).timeout(const Duration(seconds: 10));

      // Update live stream status only if it's a live stream call
      if (callRequest.callType == 'live_stream' && streamId != null) {
        await _liveStreamService.setHostInCall(streamId, callerId)
            .timeout(const Duration(seconds: 10));
      }
      
      print('✅ Call request accepted: $requestId (type: ${callRequest.callType})');
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
      }).timeout(const Duration(seconds: 10));
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

  /// End call (update request status and make host available if live stream call)
  Future<void> endCall({
    required String requestId,
    String? streamId, // Optional - only for live stream calls
  }) async {
    try {
      // Get call request to check type
      final callRequest = await getCallRequest(requestId);
      
      // Update call request status (with timeout)
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'ended',
        'respondedAt': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));

      // Make host available again only if it's a live stream call
      if (callRequest?.callType == 'live_stream' && streamId != null) {
        await _liveStreamService.setHostAvailable(streamId)
            .timeout(const Duration(seconds: 10));
      }
      
      print('✅ Call ended: $requestId (type: ${callRequest?.callType ?? 'unknown'})');
    } catch (e) {
      print('❌ Error ending call: $e');
      rethrow;
    }
  }

  /// Listen to incoming call requests (for host during live stream)
  /// This listens for both live stream calls (by hostId) and chat calls (by receiverId)
  /// Uses StreamController to combine both streams in real-time
  Stream<List<CallRequestModel>> listenToIncomingCallRequests(String hostId) {
    print('🔔 Setting up listener for incoming call requests - hostId/receiverId: $hostId');
    
    final controller = StreamController<List<CallRequestModel>>();
    final allRequests = <String, CallRequestModel>{};
    StreamSubscription? liveStreamSubscription;
    StreamSubscription? chatSubscription;
    bool isClosed = false;
    
    void emitCombined() {
      if (isClosed) return;
      final combined = allRequests.values.toList();
      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) {
        controller.add(combined);
      }
    }
    
    // Listen to live stream calls by hostId
    liveStreamSubscription = _firestore
        .collection(_collection)
        .where('hostId', isEqualTo: hostId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
      (snapshot) {
        if (isClosed) return;
        // Update live stream calls
        for (var doc in snapshot.docs) {
          try {
            final request = CallRequestModel.fromFirestore(doc);
            allRequests[request.requestId] = request;
          } catch (e) {
            print('❌ Error parsing live stream call request ${doc.id}: $e');
          }
        }
        // Remove deleted calls
        final existingIds = snapshot.docs.map((d) => d.id).toSet();
        allRequests.removeWhere((id, _) => !existingIds.contains(id) && allRequests[id]?.hostId == hostId);
        emitCombined();
      },
      onError: (error) {
        print('❌ Error in live stream call request stream: $error');
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );
    
    // Listen to chat calls by receiverId
    chatSubscription = _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: hostId)
        .where('status', isEqualTo: 'pending')
        .where('callType', isEqualTo: 'chat')
        .snapshots()
        .listen(
      (snapshot) {
        if (isClosed) return;
        // Update chat calls
        for (var doc in snapshot.docs) {
          try {
            final request = CallRequestModel.fromFirestore(doc);
            allRequests[request.requestId] = request;
          } catch (e) {
            print('❌ Error parsing chat call request ${doc.id}: $e');
          }
        }
        // Remove deleted calls
        final existingIds = snapshot.docs.map((d) => d.id).toSet();
        allRequests.removeWhere((id, _) => !existingIds.contains(id) && allRequests[id]?.receiverId == hostId && allRequests[id]?.callType == 'chat');
        emitCombined();
      },
      onError: (error) {
        print('❌ Error in chat call request stream: $error');
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );
    
    // Cleanup when stream is cancelled
    controller.onCancel = () {
      isClosed = true;
      liveStreamSubscription?.cancel();
      chatSubscription?.cancel();
      allRequests.clear();
      if (!controller.isClosed) {
        controller.close();
      }
    };
    
    return controller.stream;
  }

  /// Listen to incoming chat call requests (for users in chat screen)
  Stream<List<CallRequestModel>> listenToIncomingChatCallRequests(String receiverId) {
    print('🔔 Setting up listener for incoming chat call requests - receiverId: $receiverId');
    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .where('callType', isEqualTo: 'chat')
        .snapshots()
        .map((snapshot) {
          print('📞 Chat call request snapshot received: ${snapshot.docs.length} pending requests');
          final requests = snapshot.docs
              .map((doc) {
                try {
                  return CallRequestModel.fromFirestore(doc);
                } catch (e) {
                  print('❌ Error parsing chat call request ${doc.id}: $e');
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
          print('❌ Error in chat call request stream: $error');
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
