import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_stream_model.dart';

class LiveStreamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'live_streams';
  
  /// Create new live stream from model
  Future<void> createStream(LiveStreamModel stream) async {
    try {
      print('📡 Creating live stream: ${stream.streamId}');
      
      await _firestore.collection(_collection).doc(stream.streamId).set(stream.toMap());
      
      print('✅ Live stream created: ${stream.streamId}');
    } catch (e) {
      print('❌ Error creating live stream: $e');
      rethrow;
    }
  }
  
  /// Create new live stream (legacy method)
  Future<String> createLiveStream({
    required String hostId,
    required String hostName,
    String? hostPhotoUrl,
    required String title,
  }) async {
    try {
      print('📡 Creating live stream...');
      
      final streamId = _firestore.collection(_collection).doc().id;
      final channelName = 'live_$streamId';
      
      final stream = LiveStreamModel(
        streamId: streamId,
        channelName: channelName,
        hostId: hostId,
        hostName: hostName,
        hostPhotoUrl: hostPhotoUrl,
        title: title,
        viewerCount: 0,
        startedAt: DateTime.now(),
        isActive: true,
      );
      
      await _firestore.collection(_collection).doc(streamId).set(stream.toMap());
      
      print('✅ Live stream created: $streamId');
      return streamId;
    } catch (e) {
      print('❌ Error creating live stream: $e');
      rethrow;
    }
  }
  
  /// Get all active live streams
  Stream<List<LiveStreamModel>> getActiveLiveStreams() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LiveStreamModel.fromMap(doc.data()))
          .toList();
    });
  }
  
  /// Get specific live stream
  Stream<LiveStreamModel?> getLiveStream(String streamId) {
    return _firestore
        .collection(_collection)
        .doc(streamId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return LiveStreamModel.fromMap(doc.data()!);
      }
      return null;
    });
  }
  
  /// Get live stream once (not a stream)
  Future<LiveStreamModel?> getLiveStreamOnce(String streamId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(streamId).get();
      
      if (doc.exists && doc.data() != null) {
        return LiveStreamModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting live stream: $e');
      return null;
    }
  }
  
  /// Update viewer count
  Future<void> updateViewerCount(String streamId, int count) async {
    try {
      await _firestore.collection(_collection).doc(streamId).update({
        'viewerCount': count,
      });
    } catch (e) {
      print('❌ Error updating viewer count: $e');
    }
  }
  
  /// Delete live stream
  Future<void> deleteStream(String streamId) async {
    try {
      print('🗑️ Deleting live stream: $streamId');
      
      await _firestore.collection(_collection).doc(streamId).delete();
      
      print('✅ Live stream deleted');
    } catch (e) {
      print('❌ Error deleting live stream: $e');
      rethrow;
    }
  }
  
  /// End live stream (mark as inactive)
  Future<void> endLiveStream(String streamId) async {
    try {
      print('🛑 Ending live stream: $streamId');
      
      await _firestore.collection(_collection).doc(streamId).update({
        'isActive': false,
        'endedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Live stream ended');
    } catch (e) {
      print('❌ Error ending live stream: $e');
      rethrow;
    }
  }
  
  /// Join stream (increment viewer count)
  Future<void> joinStream(String streamId) async {
    try {
      print('👋 Viewer joining stream: $streamId');
      
      await _firestore.collection(_collection).doc(streamId).update({
        'viewerCount': FieldValue.increment(1),
      });
      
      print('✅ Viewer count incremented');
    } catch (e) {
      print('❌ Error joining stream: $e');
    }
  }
  
  /// Leave stream (decrement viewer count)
  Future<void> leaveStream(String streamId) async {
    try {
      print('👋 Viewer leaving stream: $streamId');
      
      await _firestore.collection(_collection).doc(streamId).update({
        'viewerCount': FieldValue.increment(-1),
      });
      
      print('✅ Viewer count decremented');
    } catch (e) {
      print('❌ Error leaving stream: $e');
    }
  }
  
  /// Increment viewer count (alias for joinStream)
  Future<void> incrementViewerCount(String streamId) async {
    return joinStream(streamId);
  }
  
  /// Decrement viewer count (alias for leaveStream)
  Future<void> decrementViewerCount(String streamId) async {
    return leaveStream(streamId);
  }
  
  /// Delete old inactive streams (cleanup)
  Future<void> cleanupOldStreams({int daysOld = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: false)
          .where('startedAt', isLessThan: cutoffDate.toIso8601String())
          .get();
      
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Cleaned up ${querySnapshot.docs.length} old streams');
    } catch (e) {
      print('❌ Error cleaning up streams: $e');
    }
  }
  
  /// Get host's active stream (if any)
  Future<LiveStreamModel?> getHostActiveStream(String hostId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('hostId', isEqualTo: hostId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return LiveStreamModel.fromMap(querySnapshot.docs.first.data());
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting host active stream: $e');
      return null;
    }
  }
}


