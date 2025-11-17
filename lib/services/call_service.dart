import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_model.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'calls';

  /// Create a new call request
  Future<String> createCall({
    required String callerId,
    required String callerName,
    String? callerPhotoUrl,
    required String receiverId,
    required String receiverName,
    String? receiverPhotoUrl,
  }) async {
    try {
      print('📞 Creating call request...');
      
      final callId = _firestore.collection(_collection).doc().id;
      final channelName = 'call_$callId';
      
      final call = CallModel(
        callId: callId,
        channelName: channelName,
        callerId: callerId,
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
        status: CallStatus.pending,
        createdAt: DateTime.now(),
      );
      
      await _firestore.collection(_collection).doc(callId).set(call.toMap());
      
      print('✅ Call request created: $callId');
      return callId;
    } catch (e) {
      print('❌ Error creating call: $e');
      rethrow;
    }
  }

  /// Get call by ID
  Stream<CallModel?> getCall(String callId) {
    return _firestore
        .collection(_collection)
        .doc(callId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return CallModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Accept call
  Future<void> acceptCall(String callId) async {
    try {
      print('✅ Accepting call: $callId');
      
      await _firestore.collection(_collection).doc(callId).update({
        'status': CallStatus.accepted.toString(),
        'startedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Call accepted');
    } catch (e) {
      print('❌ Error accepting call: $e');
      rethrow;
    }
  }

  /// Reject call
  Future<void> rejectCall(String callId) async {
    try {
      print('❌ Rejecting call: $callId');
      
      await _firestore.collection(_collection).doc(callId).update({
        'status': CallStatus.rejected.toString(),
        'endedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Call rejected');
    } catch (e) {
      print('❌ Error rejecting call: $e');
      rethrow;
    }
  }

  /// End call
  Future<void> endCall(String callId) async {
    try {
      print('🛑 Ending call: $callId');
      
      await _firestore.collection(_collection).doc(callId).update({
        'status': CallStatus.ended.toString(),
        'endedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Call ended');
    } catch (e) {
      print('❌ Error ending call: $e');
      rethrow;
    }
  }

  /// Mark call as missed
  Future<void> markCallMissed(String callId) async {
    try {
      await _firestore.collection(_collection).doc(callId).update({
        'status': CallStatus.missed.toString(),
        'endedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error marking call as missed: $e');
    }
  }

  /// Delete call
  Future<void> deleteCall(String callId) async {
    try {
      await _firestore.collection(_collection).doc(callId).delete();
      print('✅ Call deleted: $callId');
    } catch (e) {
      print('❌ Error deleting call: $e');
    }
  }

  /// Listen for incoming calls for a user
  Stream<List<CallModel>> listenForIncomingCalls(String userId) {
    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: CallStatus.pending.toString())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CallModel.fromMap(doc.data()))
          .toList();
    });
  }
}
















