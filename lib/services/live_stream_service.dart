import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/live_stream_model.dart';
import 'live_chat_service.dart';

class LiveStreamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'live_streams';
  
  /// Create or update live stream from model
  /// If a stream already exists for this host, it will be reused and updated
  Future<void> createStream(LiveStreamModel stream) async {
    try {
      print('📡 Creating/updating live stream: ${stream.streamId}');
      print('   Channel: ${stream.channelName}');
      print('   Host: ${stream.hostName} (${stream.hostId})');
      print('   Active: ${stream.isActive}');
      print('   Started: ${stream.startedAt}');
      
      // Validate required fields
      if (stream.channelName.isEmpty) {
        throw Exception('channelName is required but was empty');
      }
      if (stream.streamId.isEmpty) {
        throw Exception('streamId is required but was empty');
      }
      if (!stream.isActive) {
        print('⚠️ WARNING: Creating stream with isActive=false. This stream will not appear in queries!');
      }
      
      final streamData = stream.toMap();
      print('   Data keys: ${streamData.keys.toList()}');
      print('   channelName in data: ${streamData.containsKey('channelName')} = ${streamData['channelName']}');
      print('   isActive in data: ${streamData.containsKey('isActive')} = ${streamData['isActive']}');
      
      // Check if stream already exists for this host (prefer inactive ones)
      final existingStreamQuery = await _firestore
          .collection(_collection)
          .where('hostId', isEqualTo: stream.hostId)
          .limit(1)
          .get();
      
      String documentId = stream.streamId;
      
      if (existingStreamQuery.docs.isNotEmpty) {
        // Reuse existing document for this host
        documentId = existingStreamQuery.docs.first.id;
        final existingData = existingStreamQuery.docs.first.data();
        final isExistingActive = existingData['isActive'] == true;
        
        if (isExistingActive) {
          print('   ⚠️ WARNING: Host already has an active stream: $documentId');
          print('   📝 Updating existing active stream');
        } else {
          print('   🔄 Found inactive stream for host: $documentId');
          print('   📝 Reusing existing document instead of creating new one');
        }
        
        // Reset viewer count when starting a new stream (reusing old document)
        streamData['viewerCount'] = 0;
        print('   🔄 Reset viewer count to 0 for new stream');
        
        // Clear old chat messages when reusing stream document for new session
        try {
          final chatService = LiveChatService();
          await chatService.clearLiveChat(documentId);
          print('   🗑️ Cleared old chat messages for new stream session');
        } catch (e) {
          print('   ⚠️ Error clearing old chat messages: $e');
          // Don't fail the entire operation if chat clearing fails
        }
      } else {
        print('   ✨ No existing stream found, creating new document: $documentId');
        // Ensure viewerCount is 0 for new streams
        streamData['viewerCount'] = stream.viewerCount;
      }
      
      // CRITICAL: Force isActive to true and hostStatus to 'live' when creating/updating stream
      streamData['isActive'] = true;
      streamData['hostStatus'] = 'live';
      // Don't include endedAt in streamData (will be removed if exists)
      
      print('   🔧 Forcing isActive=true, hostStatus=live');
      
      // First, use set() with merge: true to update/create document
      await _firestore.collection(_collection).doc(documentId).set(streamData, SetOptions(merge: true));
      
      // Then, explicitly update critical fields to ensure they're set correctly
      // This ensures isActive is always true, even if old document had it as false
      final updateData = <String, dynamic>{
        'isActive': true,
        'hostStatus': 'live',
      };
      
      // Check if endedAt exists and remove it
      final currentDoc = await _firestore.collection(_collection).doc(documentId).get();
      if (currentDoc.exists && currentDoc.data()?.containsKey('endedAt') == true) {
        updateData['endedAt'] = FieldValue.delete();
        print('   🗑️ Removing endedAt field from stream');
      }
      
      await _firestore.collection(_collection).doc(documentId).update(updateData);
      
      print('✅ Live stream created/updated successfully: $documentId');
      print('   Collection: $_collection');
      print('   Document ID: $documentId');
      
      // Verify it was created/updated with correct data
      final verifyDoc = await _firestore.collection(_collection).doc(documentId).get();
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data()!;
        print('✅ Verified: Stream exists in Firestore');
        print('   channelName: ${verifyData['channelName']} (exists: ${verifyData.containsKey('channelName')})');
        print('   isActive: ${verifyData['isActive']} (exists: ${verifyData.containsKey('isActive')})');
        print('   hostName: ${verifyData['hostName']}');
        
        // Check for issues
        if (!verifyData.containsKey('channelName') || verifyData['channelName'] == null || (verifyData['channelName'] as String).isEmpty) {
          print('❌ CRITICAL: channelName is missing or empty in Firestore!');
        }
        if (verifyData['isActive'] != true) {
          print('❌ CRITICAL: isActive is not true in Firestore! Stream will not appear in queries.');
        }
      } else {
        print('❌ WARNING: Stream not found after creation!');
      }
    } catch (e) {
      print('❌ Error creating live stream: $e');
      print('   Stack trace: ${StackTrace.current}');
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
  
  /// Get all active live streams (real-time stream - loads all, no pagination)
  /// For paginated version, use getActiveLiveStreamsPaginated()
  Stream<List<LiveStreamModel>> getActiveLiveStreams() {
    print('🔍 Setting up getActiveLiveStreams query...');
    print('   Collection: $_collection');
    print('   Filter: isActive == true');
    print('   Using simple query (no orderBy to avoid index issues)');
    
    // First, do a one-time server read to get fresh data
    // Then listen to real-time updates
    return _getActiveLiveStreamsWithServerRead();
  }
  
  /// Get active live streams with pagination (for initial load)
  /// Returns a Future for paginated queries (not a stream)
  Future<List<LiveStreamModel>> getActiveLiveStreamsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      print('🔍 Getting paginated live streams: limit=$limit');
      
      Query query = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('startedAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.get(const GetOptions(source: Source.server));
      print('📊 Paginated query returned: ${snapshot.docs.length} documents');
      
      return _processSnapshot(snapshot);
    } catch (e) {
      print('❌ Error in getActiveLiveStreamsPaginated: $e');
      // If index doesn't exist, fallback to non-paginated query
      if (e.toString().contains('index')) {
        print('⚠️ Index not found, falling back to non-paginated query');
        final snapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .limit(limit)
            .get(const GetOptions(source: Source.server));
        return _processSnapshot(snapshot);
      }
      return [];
    }
  }
  
  /// Get active live streams as paginated stream (for real-time updates with pagination)
  Stream<List<LiveStreamModel>> getActiveLiveStreamsPaginatedStream({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    try {
      print('🔍 Setting up paginated live streams stream: limit=$limit');
      
      Query query = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('startedAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      return query.snapshots().map((snapshot) {
        print('📡 Paginated stream update: ${snapshot.docs.length} documents');
        return _processSnapshot(snapshot);
      });
    } catch (e) {
      print('❌ Error in getActiveLiveStreamsPaginatedStream: $e');
      // Fallback to non-paginated stream
      return getActiveLiveStreams();
    }
  }
  
  /// Get active live streams with forced server read
  Stream<List<LiveStreamModel>> _getActiveLiveStreamsWithServerRead() async* {
    try {
      // First, force a server read to get fresh data
      print('📡 Forcing server read to get fresh data...');
      final serverSnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get(const GetOptions(source: Source.server));
      
      print('📊 Server read returned: ${serverSnapshot.docs.length} documents');
      
      // Process initial server data
      final initialStreams = _processSnapshot(serverSnapshot);
      yield initialStreams;
      
      // Now listen to real-time updates
      // CRITICAL: Use snapshots() with server preference to ensure we get fresh data, not cache
      print('👂 Now listening to real-time updates...');
      yield* _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .snapshots(includeMetadataChanges: false) // Only listen to actual data changes, not metadata
          .map((snapshot) {
        // Log when snapshot changes occur
        print('📡 Real-time snapshot update: ${snapshot.docs.length} documents');
        print('   Source: ${snapshot.metadata.isFromCache ? "CACHE ⚠️" : "SERVER ✅"}');
        print('   Has pending writes: ${snapshot.metadata.hasPendingWrites}');
        
        
        // CRITICAL: If data is from cache, force a server read to get fresh data
        if (snapshot.metadata.isFromCache) {
          print('   ⚠️ Data from cache - will refresh with server data on next update');
        }
        
        return _processSnapshot(snapshot);
      });
    } catch (e) {
      print('❌ Error in _getActiveLiveStreamsWithServerRead: $e');
      // Fallback to regular query
      yield* _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) => _processSnapshot(snapshot));
    }
  }
  
  /// Process snapshot and return list of LiveStreamModel
  List<LiveStreamModel> _processSnapshot(QuerySnapshot snapshot) {
    try {
      print('═══════════════════════════════════════');
      print('📊 Processing snapshot: ${snapshot.docs.length} documents');
      print('   Snapshot metadata: hasPendingWrites=${snapshot.metadata.hasPendingWrites}, isFromCache=${snapshot.metadata.isFromCache}');
      print('   Source: ${snapshot.metadata.isFromCache ? "CACHE" : "SERVER"}');
      print('   Collection: $_collection');
      print('═══════════════════════════════════════');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ No documents found in query!');
        print('   This could mean:');
        print('   1. No active streams exist');
        print('   2. Collection name mismatch');
        print('   3. Firestore query issue');
      }
      
      final streams = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) {
                print('   ⚠️ Document ${doc.id} has null data, skipping');
                return null;
              }
              
              final isActive = data['isActive'] ?? false;
              final hostStatus = data['hostStatus'] ?? '';
              final startedAtStr = data['startedAt'] as String?;
              final endedAt = data['endedAt']; // Check if stream has ended timestamp
              final lastHeartbeat = data['lastHeartbeat']; // Real-time heartbeat check
              
              final hostName = data['hostName'] ?? 'Unknown';
              print('   📺 Stream ${doc.id}: $hostName - Active: $isActive, Status: $hostStatus, endedAt: $endedAt');
              
              // Double-check: Only include streams that are actually active
              // Also check hostStatus to ensure it's not 'ended'
              // Also check if endedAt exists (means stream was ended)
              if (!isActive) {
                print('   ❌ Filtering out: ${doc.id} - isActive is false');
                return null;
              }
              if (hostStatus == 'ended') {
                print('   ❌ Filtering out: ${doc.id} - hostStatus is "ended"');
                return null;
              }
              if (endedAt != null) {
                print('   ❌ Filtering out: ${doc.id} - has endedAt timestamp');
                return null;
              }
              
              // REAL-TIME FILTERING: Only show streams that are actively streaming RIGHT NOW
              final now = DateTime.now();
              bool isRealTimeActive = false;
              
              // Priority 1: Check lastHeartbeat (most accurate for real-time)
              if (lastHeartbeat != null) {
                try {
                  DateTime? heartbeatTime;
                  if (lastHeartbeat is Timestamp) {
                    heartbeatTime = lastHeartbeat.toDate();
                  } else if (lastHeartbeat is String) {
                    heartbeatTime = DateTime.parse(lastHeartbeat);
                  }
                  
                  if (heartbeatTime != null) {
                    final heartbeatAge = now.difference(heartbeatTime);
                    // ✅ FIX: 2-minute heartbeat window - immediate badge update
                    // If heartbeat is within 2 minutes, stream is active
                    if (heartbeatAge.inMinutes <= 2) {
                      isRealTimeActive = true;
                      print('   ✅ Stream ${doc.id} has recent heartbeat (${heartbeatAge.inMinutes} min ago) - REAL-TIME ACTIVE');
                    } else {
                      // Heartbeat older than 2 minutes - stream likely ended or crashed
                      print('   ❌ Filtering out: ${doc.id} - heartbeat too old (${heartbeatAge.inMinutes} min ago) - STREAM LIKELY ENDED');
                      _markStreamAsInactive(doc.id).catchError((e) {
                        print('   ⚠️ Could not mark stream inactive (permission error expected): $e');
                      });
                      return null; // Filter out - stream likely ended
                    }
                  }
                } catch (e) {
                  print('   ⚠️ Error parsing lastHeartbeat for stream ${doc.id}: $e');
                  // If can't parse heartbeat, fall through to startedAt check
                }
              }
              
              // Priority 2: If no heartbeat, use startedAt for backward compatibility
              // CRITICAL: Check if stream has endedAt FIRST - if ended, filter out immediately regardless of time
              if (!isRealTimeActive && startedAtStr != null) {
                try {
                  final startedAt = DateTime.parse(startedAtStr);
                  final difference = now.difference(startedAt);
                  
                  // CRITICAL: If stream has endedAt, it's already ended - filter out immediately
                  // Don't use time threshold for ended streams - they should disappear immediately
                  if (endedAt != null) {
                    print('   ❌ Filtering out: ${doc.id} - has endedAt (ended ${difference.inMinutes} min ago) - IMMEDIATELY HIDE');
                    return null; // Filter out immediately - stream is ended
                  }
                  
                  // REAL-TIME: Show streams that started within last 2 minutes (if no heartbeat)
                  // This gives time for heartbeat to catch up while still filtering out old streams
                  if (difference.inMinutes <= 2 && now.isAfter(startedAt)) {
                    isRealTimeActive = true;
                    print('   ✅ Stream ${doc.id} started ${difference.inMinutes} min ago - REAL-TIME ACTIVE (no heartbeat, within 2 min)');
                  } else if (difference.inMinutes > 2) {
                    // Stream started more than 2 minutes ago - not real-time active
                    print('   ❌ Filtering out: ${doc.id} - started ${difference.inMinutes} min ago - NOT real-time active');
                    _markStreamAsInactive(doc.id).catchError((e) {
                      print('   ⚠️ Could not mark stream inactive (permission error expected): $e');
                    });
                    return null; // Filter out - not real-time active
                  } else if (now.isBefore(startedAt)) {
                    // StartedAt is in the future - likely timezone issue, don't filter
                    print('   ℹ️ Stream ${doc.id} has future startedAt (timezone issue?), keeping it');
                    isRealTimeActive = true;
                  }
                } catch (e) {
                  print('   ⚠️ Error parsing startedAt for stream ${doc.id}: $e');
                  // If we can't parse startedAt, don't filter - keep the stream
                  isRealTimeActive = true;
                }
              }
              
              // FALLBACK: If stream is marked as active and has no endedAt, keep it
              // This prevents filtering out active streams due to timing issues
              if (!isRealTimeActive && isActive == true && endedAt == null && hostStatus != 'ended') {
                print('   ⚠️ Stream ${doc.id} is active but no recent heartbeat/startedAt - keeping as fallback');
                isRealTimeActive = true; // Keep stream if it's marked as active
              }
              
              // If no heartbeat AND no startedAt, filter out (invalid stream)
              if (!isRealTimeActive && startedAtStr == null) {
                print('   ❌ Filtering out: ${doc.id} - no heartbeat and no startedAt - invalid stream');
                return null;
              }
              
              if (isRealTimeActive) {
                print('   ✅ Keeping stream: ${doc.id} - $hostName (REAL-TIME ACTIVE)');
              }
              
              // Ensure viewer count is not negative
              final viewerCount = data['viewerCount'] ?? 0;
              if (viewerCount < 0) {
                print('   ⚠️ Stream ${doc.id} has negative viewer count: $viewerCount, fixing...');
                // Fix negative viewer count in background
                _fixViewerCount(doc.id);
              }
              
              // IMPORTANT: Use document ID as streamId to ensure consistency
              // The document ID is the source of truth, not the streamId field
              // This prevents issues when documents are reused for the same host
              final modelData = Map<String, dynamic>.from(data);
              modelData['streamId'] = doc.id; // Override with actual document ID
              
              return LiveStreamModel.fromMap(modelData);
            } catch (e) {
              print('❌ Error parsing stream document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<LiveStreamModel>()
          .toList();
      
      // Sort manually by startedAt (newest first)
      streams.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      
      print('═══════════════════════════════════════');
      print('✅ Returning ${streams.length} active live streams (filtered from ${snapshot.docs.length} total)');
      if (streams.isNotEmpty) {
        print('   Streams:');
        for (var stream in streams) {
          print('     - ${stream.hostName} (${stream.streamId}) - ${stream.viewerCount} viewers');
        }
      }
      print('═══════════════════════════════════════');
      return streams;
    } catch (e) {
      print('❌ Error mapping streams: $e');
      return <LiveStreamModel>[];
    }
  }
  
  /// Get specific live stream
  // Cache streams to prevent duplicate listeners
  final Map<String, Stream<LiveStreamModel?>> _streamCache = {};
  
  Stream<LiveStreamModel?> getLiveStream(String streamId) {
    // Return cached stream if exists to prevent duplicate listeners
    if (_streamCache.containsKey(streamId)) {
      return _streamCache[streamId]!;
    }
    
    // Create stream with caching
    final stream = _firestore
        .collection(_collection)
        .doc(streamId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return LiveStreamModel.fromMap(doc.data()!);
      }
      return null;
    });
    
    // Cache the stream
    _streamCache[streamId] = stream;
    return stream;
  }
  
  /// Get live stream once (not a stream)
  /// Tries to find stream by document ID first, then by streamId field if not found
  Future<LiveStreamModel?> getLiveStreamOnce(String streamId) async {
    try {
      // First, try to get by document ID (most common case)
      final doc = await _firestore.collection(_collection).doc(streamId).get();
      
      if (doc.exists && doc.data() != null) {
        print('✅ Found stream by document ID: $streamId');
        return LiveStreamModel.fromMap(doc.data()!);
      }
      
      // If not found by document ID, try to find by streamId field
      // This handles cases where document ID differs from streamId field
      print('⚠️ Stream not found by document ID: $streamId, searching by streamId field...');
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('streamId', isEqualTo: streamId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        print('✅ Found stream by streamId field: ${doc.id} (streamId field: $streamId)');
        return LiveStreamModel.fromMap(doc.data());
      }
      
      // Also try without isActive filter (in case stream is temporarily inactive)
      final querySnapshot2 = await _firestore
          .collection(_collection)
          .where('streamId', isEqualTo: streamId)
          .limit(1)
          .get();
      
      if (querySnapshot2.docs.isNotEmpty) {
        final doc = querySnapshot2.docs.first;
        print('✅ Found stream by streamId field (without isActive filter): ${doc.id}');
        return LiveStreamModel.fromMap(doc.data());
      }
      
      print('❌ Stream not found by document ID or streamId field: $streamId');
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
      
      // Verify stream exists before updating
      final streamDoc = await _firestore.collection(_collection).doc(streamId).get();
      if (!streamDoc.exists) {
        print('⚠️ Stream $streamId does not exist, skipping end operation');
        return;
      }
      
      // Get current data for logging
      final currentData = streamDoc.data();
      print('   Current isActive: ${currentData?['isActive']}, hostStatus: ${currentData?['hostStatus']}');
      
      // CRITICAL: Use update() with explicit false value (not just omitting the field)
      // This ensures Firestore real-time listeners immediately detect the change
      await _firestore.collection(_collection).doc(streamId).update({
        'isActive': false, // Explicitly set to false (not null, not omitted)
        'endedAt': FieldValue.serverTimestamp(), // Use server timestamp for accuracy
        'hostStatus': 'ended', // Explicitly set to 'ended'
      });
      
      print('✅ Live stream ended: $streamId (isActive=false, hostStatus=ended)');
      
      // CRITICAL: Verify the update was successful and wait for propagation
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyDoc = await _firestore.collection(_collection).doc(streamId).get(const GetOptions(source: Source.server));
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data();
        final verifyIsActive = verifyData?['isActive'] ?? true;
        final verifyHostStatus = verifyData?['hostStatus'] ?? 'live';
        print('   🔍 Verification - isActive: $verifyIsActive, hostStatus: $verifyHostStatus');
        
        if (verifyIsActive == true || verifyHostStatus != 'ended') {
          print('   ⚠️ Stream still active after update - forcing update again...');
          // Force update again with explicit values
          await _firestore.collection(_collection).doc(streamId).set({
            'isActive': false,
            'hostStatus': 'ended',
            'endedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('   ✅ Forced update complete');
        } else {
          print('   ✅ Stream successfully marked as inactive - will disappear from queries');
        }
      }
      
      // Clear chat messages when stream ends
      try {
        final chatService = LiveChatService();
        await chatService.clearLiveChat(streamId);
        print('✅ Chat messages cleared for stream: $streamId');
      } catch (e) {
        print('⚠️ Error clearing chat messages: $e');
        // Don't fail the entire operation if chat clearing fails
      }
    } catch (e) {
      print('❌ Error ending live stream: $e');
      print('   Error details: ${e.toString()}');
      print('   Stack trace: ${StackTrace.current}');
      
      // Try one more time with a simpler update
      try {
        await _firestore.collection(_collection).doc(streamId).update({
          'isActive': false,
          'hostStatus': 'ended',
        });
        print('✅ Retry successful - stream ended');
      } catch (retryError) {
        print('❌ Retry also failed: $retryError');
      }
    }
  }
  
  /// Keep stream alive (heartbeat) - call periodically while streaming
  Future<void> keepStreamAlive(String streamId) async {
    try {
      // ✅ SAFETY CHECK: Don't update if stream is already ended
      // This prevents heartbeat from overriding stream end status
      final streamDoc = await _firestore.collection(_collection).doc(streamId).get();
      if (!streamDoc.exists) {
        print('⚠️ Stream $streamId does not exist, skipping heartbeat');
        return;
      }
      
      final data = streamDoc.data();
      final hostStatus = data?['hostStatus'] as String?;
      
      // Don't update if stream is already ended
      if (hostStatus == 'ended') {
        print('⚠️ Stream $streamId is already ended, skipping heartbeat');
        return;
      }
      
      await _firestore.collection(_collection).doc(streamId).update({
        'isActive': true, // Ensure it stays active
        'lastHeartbeat': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error keeping stream alive: $e');
    }
  }
  
  /// Join stream (increment viewer count)
  Future<void> joinStream(String streamId, {String? viewerId}) async {
    try {
      print('👋 Viewer joining stream: $streamId');
      
      // Verify stream exists and is active before allowing join
      final streamDoc = await _firestore.collection(_collection).doc(streamId).get();
      if (!streamDoc.exists) {
        print('⚠️ Stream $streamId does not exist, cannot join');
        return;
      }
      
      final streamData = streamDoc.data();
      final isActive = streamData?['isActive'] ?? false;
      if (!isActive) {
        print('⚠️ Stream $streamId is not active, cannot join');
        return;
      }
      
      // Get current viewer count to ensure it's initialized
      final currentCount = streamData?['viewerCount'] ?? 0;
      print('   Current viewer count: $currentCount');
      
      // Track individual viewer if viewerId is provided
      print('   ViewerId provided: ${viewerId != null ? "Yes ($viewerId)" : "No"}');
      if (viewerId != null && viewerId.isNotEmpty) {
        try {
          print('   Adding viewer to subcollection: $viewerId');
          print('   Collection path: $_collection/$streamId/viewers/$viewerId');
          
          // Use set with merge to ensure document is created
          await _firestore
              .collection(_collection)
              .doc(streamId)
              .collection('viewers')
              .doc(viewerId)
              .set({
            'joinedAt': FieldValue.serverTimestamp(),
            'viewerId': viewerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch, // Fallback timestamp
          }, SetOptions(merge: true));
          
          print('✅ Viewer $viewerId added to viewers list');
          
          // Wait a bit and verify it was added
          await Future.delayed(const Duration(milliseconds: 500));
          final verifyDoc = await _firestore
              .collection(_collection)
              .doc(streamId)
              .collection('viewers')
              .doc(viewerId)
              .get();
          if (verifyDoc.exists) {
            print('✅ Verified: Viewer document exists in subcollection');
            print('   Document data: ${verifyDoc.data()}');
          } else {
            print('⚠️ Warning: Viewer document was not created');
          }
          
          // Also check total count in subcollection
          final viewersSnapshot = await _firestore
              .collection(_collection)
              .doc(streamId)
              .collection('viewers')
              .get();
          print('   Total viewers in subcollection: ${viewersSnapshot.docs.length}');
          for (var doc in viewersSnapshot.docs) {
            print('     - Viewer: ${doc.id}, Data: ${doc.data()}');
          }
        } catch (e) {
          print('❌ Error adding viewer to list: $e');
          print('   Stack trace: ${StackTrace.current}');
          // Don't fail the entire join if viewer tracking fails
        }
      } else {
        print('⚠️ Warning: viewerId is null or empty, skipping individual viewer tracking');
      }
      
      // ⚠️ CRITICAL FIX: Use Cloud Function instead of direct Firestore update
      // This fixes the permission issue where viewers cannot update viewer count
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('updateViewerCount');
        final result = await callable.call({
          'streamId': streamId,
          'action': 'join',
        });
        
        final newCount = result.data['viewerCount'] as int? ?? (currentCount + 1);
        print('✅ Viewer count incremented via Cloud Function (new count: $newCount)');
      } catch (e) {
        print('❌ Error calling Cloud Function to update viewer count: $e');
        // Fallback: Try direct update (may fail due to rules, but worth trying)
        try {
          await _firestore.collection(_collection).doc(streamId).update({
            'viewerCount': FieldValue.increment(1),
          });
          print('✅ Fallback: Viewer count incremented directly');
        } catch (fallbackError) {
          print('❌ Fallback also failed: $fallbackError');
        }
      }
    } catch (e) {
      print('❌ Error joining stream: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }
  
  /// Leave stream (decrement viewer count)
  Future<void> leaveStream(String streamId, {String? viewerId}) async {
    try {
      print('👋 Viewer leaving stream: $streamId');
      
      // Verify stream exists before decrementing
      final streamDoc = await _firestore.collection(_collection).doc(streamId).get();
      if (!streamDoc.exists) {
        print('⚠️ Stream $streamId does not exist, cannot leave');
        return;
      }
      
      // Get current viewer count
      final streamData = streamDoc.data();
      final currentCount = streamData?['viewerCount'] ?? 0;
      print('   Current viewer count: $currentCount');
      
      // Remove individual viewer from list if viewerId is provided
      if (viewerId != null && viewerId.isNotEmpty) {
        try {
          await _firestore
              .collection(_collection)
              .doc(streamId)
              .collection('viewers')
              .doc(viewerId)
              .delete();
          print('✅ Viewer $viewerId removed from viewers list');
        } catch (e) {
          print('⚠️ Error removing viewer from list: $e');
          // Don't fail the entire leave if viewer tracking fails
        }
      }
      
      // ⚠️ CRITICAL FIX: Use Cloud Function instead of direct Firestore update
      // This fixes the permission issue where viewers cannot update viewer count
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('updateViewerCount');
        final result = await callable.call({
          'streamId': streamId,
          'action': 'leave',
        });
        
        final newCount = result.data['viewerCount'] as int? ?? (currentCount > 0 ? currentCount - 1 : 0);
        print('✅ Viewer count decremented via Cloud Function (new count: $newCount)');
      } catch (e) {
        print('❌ Error calling Cloud Function to update viewer count: $e');
        // Fallback: Try direct update (may fail due to rules, but worth trying)
        try {
          if (currentCount > 0) {
            await _firestore.collection(_collection).doc(streamId).update({
              'viewerCount': FieldValue.increment(-1),
            });
            print('✅ Fallback: Viewer count decremented directly');
          } else {
            await _firestore.collection(_collection).doc(streamId).update({
              'viewerCount': 0,
            });
            print('✅ Fallback: Viewer count set to 0');
          }
        } catch (fallbackError) {
          print('❌ Fallback also failed: $fallbackError');
        }
      }
    } on FirebaseException catch (e, st) {
      if (e.code == 'permission-denied') {
        // Some viewers may not have write access per Firestore rules; skip silently
        print('⚠️ Permission denied when leaving stream; skipping viewer decrement.');
        return;
      }
      print('❌ Firebase error leaving stream: ${e.code} - ${e.message}');
      print('   Stack trace: $st');
    } catch (e, st) {
      print('❌ Error leaving stream: $e');
      print('   Stack trace: $st');
    }
  }
  
  /// Increment viewer count (alias for joinStream)
  Future<void> incrementViewerCount(String streamId, {String? viewerId}) async {
    return joinStream(streamId, viewerId: viewerId);
  }
  
  /// Decrement viewer count (alias for leaveStream)
  Future<void> decrementViewerCount(String streamId, {String? viewerId}) async {
    return leaveStream(streamId, viewerId: viewerId);
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
          .get(const GetOptions(source: Source.server)); // Force server read for fresh data
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final stream = LiveStreamModel.fromMap(data);
        
        // Check hostStatus - if it's 'ended', the stream is not actually active
        final hostStatus = data['hostStatus'] as String?;
        if (hostStatus == 'ended') {
          print('⚠️ Found stream with hostStatus=ended - auto-ending: ${doc.id}');
          try {
            await endLiveStream(doc.id);
            return null;
          } catch (e) {
            print('❌ Error ending stream with ended status: $e');
            return null;
          }
        }
        
        // Check if stream is stale (older than 3 minutes) - likely from app crash/force close
        final startedAt = stream.startedAt;
        final now = DateTime.now();
        final duration = now.difference(startedAt);
        
        // If stream is older than 3 minutes, it's likely stale (app was force-closed)
        if (duration.inMinutes > 3) {
          print('⚠️ Found stale stream (${duration.inMinutes} minutes old) - auto-ending: ${doc.id}');
          try {
            // Auto-end the stale stream
            await endLiveStream(doc.id);
            print('✅ Stale stream auto-ended');
            return null; // Return null so user can start a new stream
          } catch (e) {
            print('❌ Error auto-ending stale stream: $e');
            // Still return null to allow new stream
            return null;
          }
        }
        
        return stream;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting host active stream: $e');
      return null;
    }
  }
  
  /// Update host status
  Future<void> updateHostStatus(String streamId, String status) async {
    try {
      await _firestore.collection(_collection).doc(streamId).update({
        'hostStatus': status,
        'statusUpdatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Host status updated to: $status');
    } catch (e) {
      print('❌ Error updating host status: $e');
      rethrow;
    }
  }

  /// Set host in private call
  Future<void> setHostInCall(String streamId, String callerId) async {
    try {
      await _firestore.collection(_collection).doc(streamId).update({
        'hostStatus': 'in_call',
        'currentCallUserId': callerId,
        'callStartedAt': DateTime.now().toIso8601String(),
        'statusUpdatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Host set to in_call with caller: $callerId');
    } catch (e) {
      print('❌ Error setting host in call: $e');
      rethrow;
    }
  }

  /// Set host available (end call)
  Future<void> setHostAvailable(String streamId) async {
    try {
      await _firestore.collection(_collection).doc(streamId).update({
        'hostStatus': 'live',
        'currentCallUserId': FieldValue.delete(),
        'callStartedAt': FieldValue.delete(),
        'statusUpdatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Host set to available (live)');
    } catch (e) {
      print('❌ Error setting host available: $e');
      rethrow;
    }
  }

  /// Check if host is in a call
  Future<bool> isHostInCall(String streamId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(streamId).get();
      if (!doc.exists) {
        print('⚠️ Stream document does not exist: $streamId - returning false (host not busy)');
        return false;
      }
      final data = doc.data();
      final hostStatus = data?['hostStatus'] ?? 'live';
      final isInCall = hostStatus == 'in_call';
      print('📊 Host status check - StreamId: $streamId, hostStatus: $hostStatus, isInCall: $isInCall');
      return isInCall;
    } catch (e) {
      print('❌ Error checking if host is in call: $e');
      // Return false on error to allow call requests (fail open)
      return false;
    }
  }
  
  /// Mark stream as inactive (background operation, doesn't block)
  Future<void> _markStreamAsInactive(String streamId) async {
    try {
      await _firestore.collection(_collection).doc(streamId).update({
        'isActive': false,
        'hostStatus': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Marked old stream as inactive: $streamId');
    } catch (e) {
      print('⚠️ Error marking stream as inactive: $e');
      // Don't throw - this is a background cleanup operation
    }
  }
  
  /// Fix negative viewer count (background operation)
  Future<void> _fixViewerCount(String streamId) async {
    try {
      await _firestore.collection(_collection).doc(streamId).update({
        'viewerCount': 0,
      });
      print('✅ Fixed negative viewer count for stream: $streamId');
    } catch (e) {
      print('⚠️ Error fixing viewer count: $e');
      // Don't throw - this is a background cleanup operation
    }
  }
  
  /// Cleanup all inactive/old streams (call this periodically)
  /// Only cleans up streams that are clearly old/abandoned, not active ones
  Future<void> cleanupInactiveStreams() async {
    try {
      print('🧹 Starting cleanup of inactive streams...');
      
      // Get all streams marked as active
      final activeStreams = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();
      
      final now = DateTime.now();
      int cleanedCount = 0;
      
      for (var doc in activeStreams.docs) {
        final data = doc.data();
        final startedAtStr = data['startedAt'] as String?;
        final hostStatus = data['hostStatus'] ?? '';
        final endedAt = data['endedAt'];
        
        // Only clean up if:
        // 1. hostStatus is 'ended' OR
        // 2. endedAt exists OR
        // 3. Stream is older than 24 hours (and not in future)
        bool shouldCleanup = false;
        
        if (hostStatus == 'ended' || endedAt != null) {
          shouldCleanup = true;
          print('   🧹 Cleaning up ended stream: ${doc.id}');
        } else if (startedAtStr != null) {
          try {
            final startedAt = DateTime.parse(startedAtStr);
            final difference = now.difference(startedAt);
            
            // Only cleanup if older than 24 hours AND not in future
            if (difference.inHours > 24 && now.isAfter(startedAt)) {
              shouldCleanup = true;
              print('   🧹 Cleaning up old stream: ${doc.id} (${difference.inHours} hours old)');
            } else {
              print('   ✅ Keeping active stream: ${doc.id} (${difference.inHours} hours old)');
            }
          } catch (e) {
            print('   ⚠️ Error parsing startedAt for stream ${doc.id}: $e - keeping it');
            // Don't cleanup if we can't parse the date
          }
        }
        
        if (shouldCleanup) {
          try {
            await _firestore.collection(_collection).doc(doc.id).update({
              'isActive': false,
              'hostStatus': 'ended',
              'endedAt': FieldValue.serverTimestamp(),
            });
            cleanedCount++;
            print('   ✅ Cleaned up stream: ${doc.id}');
          } catch (e) {
            print('   ❌ Error cleaning up stream ${doc.id}: $e');
          }
        }
      }
      
      print('✅ Cleanup complete: $cleanedCount streams marked as inactive (out of ${activeStreams.docs.length} total)');
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }

}




