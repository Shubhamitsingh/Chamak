import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage user online/offline status tracking
/// 
/// This service:
/// - Updates lastActive and lastSeen timestamps when user is active
/// - Checks if user is online (within 5 minutes)
/// - Checks if user is live (isLive field)
/// - Provides streams for real-time status updates
class OnlineStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Timer? _statusUpdateTimer;
  static const Duration _updateInterval = Duration(minutes: 2); // Update every 2 minutes
  static const int _onlineThresholdMinutes = 5; // Consider online if seen within 5 minutes

  /// Initialize status tracking for current user
  /// Call this when app starts or user logs in
  Future<void> initializeStatusTracking() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Update immediately on init
    await updateLastActive(userId);

    // Start periodic updates
    _startPeriodicUpdates(userId);
  }

  /// Start periodic status updates
  void _startPeriodicUpdates(String userId) {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(_updateInterval, (timer) async {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == userId) {
        await updateLastActive(userId);
      } else {
        timer.cancel();
      }
    });
  }

  /// Stop status tracking (call when app goes to background or user logs out)
  void stopStatusTracking() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;
  }

  /// Update lastActive timestamp for current user
  /// Also updates lastSeen for backward compatibility
  Future<void> updateLastActive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(), // Keep for backward compatibility
      });
    } catch (e) {
      // Silently handle errors (network issues, permissions, etc.)
      debugPrint('⚠️ Failed to update lastActive for $userId: $e');
    }
  }

  /// Update lastSeen timestamp for current user (deprecated - use updateLastActive)
  /// Kept for backward compatibility
  @Deprecated('Use updateLastActive instead')
  Future<void> updateLastSeen(String userId) async {
    await updateLastActive(userId);
  }

  /// Check if a user is currently online
  /// Returns true if lastSeen is within the threshold (default 5 minutes)
  bool isUserOnline(DateTime? lastSeen) {
    if (lastSeen == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes < _onlineThresholdMinutes;
  }

  /// Get online status from Firestore document snapshot
  bool getOnlineStatusFromSnapshot(DocumentSnapshot? userDoc) {
    if (userDoc == null || !userDoc.exists) return false;
    
    final data = userDoc.data();
    if (data == null) return false;

    // Get lastSeen timestamp
    DateTime? lastSeen;
    final lastSeenField = (data as Map<String, dynamic>)['lastSeen'];
    if (lastSeenField != null) {
      if (lastSeenField is Timestamp) {
        lastSeen = lastSeenField.toDate();
      } else if (lastSeenField is DateTime) {
        lastSeen = lastSeenField;
      }
    }

    return isUserOnline(lastSeen);
  }

  /// Check if user is currently live streaming
  /// Only returns true if stream is ACTUALLY live (recent, active, not ended)
  Future<bool> isUserLive(String userId) async {
    try {
      final now = DateTime.now();
      
      // First try to find stream by hostId (userId)
      final querySnapshot = await _firestore
          .collection('live_streams')
          .where('hostId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Check ALL matching streams and find a valid one
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        // CRITICAL: Check all conditions
        final isActive = data['isActive'] == true;
        final hostStatus = data['hostStatus'] as String?;
        final endedAt = data['endedAt'];
        final startedAtStr = data['startedAt'] as String?;
        
        // Skip if hostStatus is 'ended' (even if isActive is somehow true)
        if (hostStatus == 'ended') {
          debugPrint('⚠️ Stream ${doc.id} has hostStatus=ended, skipping');
          continue;
        }
        
        // Skip if endedAt exists (stream was ended)
        if (endedAt != null) {
          debugPrint('⚠️ Stream ${doc.id} has endedAt timestamp, skipping');
          continue;
        }
        
        // Skip if isActive is false (shouldn't happen due to query, but double-check)
        if (!isActive) {
          debugPrint('⚠️ Stream ${doc.id} has isActive=false, skipping');
          continue;
        }
        
        // CRITICAL: Check if stream started recently (within last 24 hours)
        // This filters out old/stale streams
        if (startedAtStr != null) {
          try {
            final startedAt = DateTime.parse(startedAtStr);
            final duration = now.difference(startedAt);
            
            // If stream is older than 24 hours, it's stale (host likely crashed/force closed)
            if (duration.inHours > 24) {
              debugPrint('⚠️ Stream ${doc.id} is too old (${duration.inHours} hours), marking as stale');
              // Auto-end stale stream in background (don't block)
              _autoEndStaleStream(doc.id);
              continue;
            }
            
            // If startedAt is in the future (timezone issue), skip it
            if (startedAt.isAfter(now)) {
              debugPrint('⚠️ Stream ${doc.id} has future startedAt (timezone issue), skipping');
              continue;
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing startedAt for stream ${doc.id}: $e, skipping');
            continue;
          }
        } else {
          // If startedAt is missing, it's an invalid stream - skip it
          debugPrint('⚠️ Stream ${doc.id} missing startedAt field, skipping');
          continue;
        }
        
        // ALL VALIDATION PASSED - User is actually live!
        if (hostStatus == 'live') {
          debugPrint('✅ User $userId is LIVE (stream: ${doc.id})');
          return true;
        } else {
          debugPrint('⚠️ Stream ${doc.id} has hostStatus=$hostStatus (not "live"), skipping');
          continue;
        }
      }
      
      // No valid live streams found
      debugPrint('❌ No valid live streams found for user: $userId');
      return false;
    } catch (e) {
      debugPrint('⚠️ Error checking live status for $userId: $e');
      return false;
    }
  }

  /// Stream to listen to user's online status changes
  /// Returns true if online, false if offline
  Stream<bool> getUserOnlineStatusStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => getOnlineStatusFromSnapshot(snapshot));
  }

  /// Stream to listen to user's live status changes
  /// Returns true if live, false if not live
  /// Only returns true if stream is ACTUALLY live (recent, active, not ended)
  Stream<bool> getUserLiveStatusStream(String userId) {
    // Use hostId query (more reliable - matches how streams are stored)
    return _firestore
        .collection('live_streams')
        .where('hostId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            debugPrint('🔍 No active streams found for user: $userId');
            return false;
          }
          
          final now = DateTime.now();
          
          // Check ALL matching streams and find the most recent valid one
          for (var doc in snapshot.docs) {
            final data = doc.data();
            
            // CRITICAL: Check all conditions
            final isActive = data['isActive'] == true;
            final hostStatus = data['hostStatus'] as String?;
            final endedAt = data['endedAt'];
            final startedAtStr = data['startedAt'] as String?;
            final lastHeartbeat = data['lastHeartbeat']; // Real-time heartbeat check
            
            // Skip if hostStatus is 'ended' (even if isActive is somehow true)
            if (hostStatus == 'ended') {
              debugPrint('⚠️ Stream ${doc.id} has hostStatus=ended, skipping');
              continue;
            }
            
            // Skip if endedAt exists (stream was ended)
            if (endedAt != null) {
              debugPrint('⚠️ Stream ${doc.id} has endedAt timestamp, skipping');
              continue;
            }
            
            // Skip if isActive is false (shouldn't happen due to query, but double-check)
            if (!isActive) {
              debugPrint('⚠️ Stream ${doc.id} has isActive=false, skipping');
              continue;
            }
            
            // 🔴 CRITICAL: Check heartbeat - if older than 2 minutes, stream is not live
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
                  // If heartbeat is older than 2 minutes, stream is not live
                  if (heartbeatAge.inMinutes > 2) {
                    debugPrint('⚠️ Stream ${doc.id} has old heartbeat (${heartbeatAge.inMinutes} min ago) - NOT LIVE');
                    continue; // Skip this stream - not live
                  }
                  debugPrint('✅ Stream ${doc.id} has recent heartbeat (${heartbeatAge.inMinutes} min ago) - LIVE');
                }
              } catch (e) {
                debugPrint('⚠️ Error parsing lastHeartbeat for stream ${doc.id}: $e');
                // If can't parse heartbeat, continue with other checks (fallback)
              }
            } else {
              // No heartbeat - check startedAt with 2-minute window (same as stream list)
              debugPrint('⚠️ Stream ${doc.id} has no heartbeat - checking startedAt (2 min window)');
              
              if (startedAtStr != null) {
                try {
                  final startedAt = DateTime.parse(startedAtStr);
                  final duration = now.difference(startedAt);
                  
                  // If stream started more than 2 minutes ago with no heartbeat, it's not live
                  if (duration.inMinutes > 2) {
                    debugPrint('⚠️ Stream ${doc.id} started ${duration.inMinutes} min ago with no heartbeat - NOT LIVE');
                    continue; // Skip this stream - not live
                  }
                  
                  // If startedAt is in the future (timezone issue), skip it
                  if (startedAt.isAfter(now)) {
                    debugPrint('⚠️ Stream ${doc.id} has future startedAt (timezone issue), skipping');
                    continue;
                  }
                  
                  debugPrint('✅ Stream ${doc.id} started ${duration.inMinutes} min ago (no heartbeat, within 2 min) - LIVE');
                } catch (e) {
                  debugPrint('⚠️ Error parsing startedAt for stream ${doc.id}: $e, skipping');
                  continue;
                }
              } else {
                // If no heartbeat AND no startedAt, it's an invalid stream - skip it
                debugPrint('⚠️ Stream ${doc.id} has no heartbeat and no startedAt - invalid stream, skipping');
                continue;
              }
            }
            
            // CRITICAL: Additional check - if stream is older than 24 hours, it's stale (host likely crashed/force closed)
            // This is a safety check for very old streams that somehow passed the heartbeat/startedAt checks
            if (startedAtStr != null) {
              try {
                final startedAt = DateTime.parse(startedAtStr);
                final duration = now.difference(startedAt);
                
                // If stream is older than 24 hours, it's stale (host likely crashed/force closed)
                if (duration.inHours > 24) {
                  debugPrint('⚠️ Stream ${doc.id} is too old (${duration.inHours} hours), marking as stale');
                  // Auto-end stale stream in background (don't block)
                  _autoEndStaleStream(doc.id);
                  continue;
                }
              } catch (e) {
                debugPrint('⚠️ Error parsing startedAt for final check on stream ${doc.id}: $e');
                // Don't skip here - already passed heartbeat/startedAt checks
              }
            }
            
            // ALL VALIDATION PASSED - User is actually live!
            if (hostStatus == 'live') {
              debugPrint('✅ User $userId is LIVE (stream: ${doc.id})');
              return true;
            } else {
              debugPrint('⚠️ Stream ${doc.id} has hostStatus=$hostStatus (not "live"), skipping');
              continue;
            }
          }
          
          // No valid live streams found
          debugPrint('❌ No valid live streams found for user: $userId');
          return false;
        });
  }
  
  /// Auto-end stale stream in background (non-blocking)
  void _autoEndStaleStream(String streamId) {
    // Don't await - run in background
    _firestore.collection('live_streams').doc(streamId).update({
      'isActive': false,
      'hostStatus': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    }).catchError((e) {
      debugPrint('⚠️ Error auto-ending stale stream $streamId: $e');
    });
  }

  /// Combined stream: Returns status string ('online', 'offline')
  /// Only checks online/offline status (live indicator removed)
  Stream<String> getUserStatusStream(String userId) {
    return getUserOnlineStatusStream(userId).map((isOnline) {
      return isOnline ? 'online' : 'offline';
    });
  }

  /// Get current status synchronously (one-time check)
  /// Returns 'online' or 'offline' (live indicator removed)
  Future<String> getUserStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (getOnlineStatusFromSnapshot(userDoc)) {
        return 'online';
      }
      return 'offline';
    } catch (e) {
      debugPrint('⚠️ Error getting user status: $e');
      return 'offline';
    }
  }

  /// Dispose resources
  void dispose() {
    stopStatusTracking();
  }
}

// StreamZip implementation for combining multiple streams
class StreamZip<T> extends Stream<List<T>> {
  final List<Stream<T>> _streams;

  StreamZip(this._streams);

  @override
  StreamSubscription<List<T>> listen(
    void Function(List<T>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (_streams.isEmpty) {
      return Stream<List<T>>.value([]).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    }

    final subscriptions = <StreamSubscription<T>>[];
    final latestValues = List<T?>.filled(_streams.length, null);
    var completedCount = 0;

    for (var i = 0; i < _streams.length; i++) {
      final index = i;
      subscriptions.add(_streams[i].listen(
        (value) {
          latestValues[index] = value;
          // Check if all streams have emitted at least one value
          if (latestValues.every((v) => v != null)) {
            onData?.call(List<T>.from(latestValues));
          }
        },
        onError: onError,
        onDone: () {
          completedCount++;
          if (completedCount == _streams.length) {
            onDone?.call();
          }
        },
        cancelOnError: cancelOnError,
      ));
    }

    return _StreamZipSubscription(subscriptions);
  }
}

class _StreamZipSubscription<T> implements StreamSubscription<List<T>> {
  final List<StreamSubscription<T>> _subscriptions;

  _StreamZipSubscription(this._subscriptions);

  @override
  Future<void> cancel() async {
    await Future.wait(_subscriptions.map((s) => s.cancel()));
  }

  @override
  void onData(void Function(List<T>)? handleData) {
    // Already handled in listen
  }

  @override
  void onError(Function? handleError) {
    // Already handled in listen
  }

  @override
  void onDone(void Function()? handleDone) {
    // Already handled in listen
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    for (var sub in _subscriptions) {
      sub.pause(resumeSignal);
    }
  }

  @override
  void resume() {
    for (var sub in _subscriptions) {
      sub.resume();
    }
  }

  @override
  bool get isPaused => _subscriptions.any((s) => s.isPaused);

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    return Future.value(futureValue as E);
  }
}
