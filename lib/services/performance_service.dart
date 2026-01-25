import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/performance_metrics_model.dart';

class PerformanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get start date for time period filter
  DateTime _getStartDate(TimePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case TimePeriod.today:
        return DateTime(now.year, now.month, now.day);
      case TimePeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      case TimePeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case TimePeriod.allTime:
        return DateTime(1970); // Beginning of time
    }
  }

  /// Get total stream count for a user
  Future<int> getTotalStreamCount(String userId, {TimePeriod? period}) async {
    try {
      // Query only by hostId to avoid composite index requirement
      final snapshot = await _firestore
          .collection('live_streams')
          .where('hostId', isEqualTo: userId)
          .get();

      // Filter by date client-side if period is specified
      if (period != null && period != TimePeriod.allTime) {
        final startDate = _getStartDate(period);
        int count = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final startedAtField = data['startedAt'];
          if (startedAtField == null) continue;
          
          DateTime startedAt;
          if (startedAtField is Timestamp) {
            startedAt = startedAtField.toDate();
          } else if (startedAtField is String) {
            startedAt = DateTime.parse(startedAtField);
          } else {
            continue;
          }
          
          if (startedAt.isAfter(startDate) || startedAt.isAtSameMomentAs(startDate)) {
            count++;
          }
        }
        return count;
      }

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting stream count: $e');
      return 0;
    }
  }

  /// Get total streaming hours for a user
  Future<double> getTotalStreamingHours(String userId, {TimePeriod? period}) async {
    try {
      // Query only by hostId to avoid composite index requirement
      final snapshot = await _firestore
          .collection('live_streams')
          .where('hostId', isEqualTo: userId)
          .get();

      final now = DateTime.now();
      final startDate = period != null && period != TimePeriod.allTime 
          ? _getStartDate(period) 
          : DateTime(1970);
      double totalHours = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        final startedAtField = data['startedAt'];
        final endedAtField = data['endedAt'];

        if (startedAtField == null) continue;

        DateTime startedAt;
        if (startedAtField is Timestamp) {
          startedAt = startedAtField.toDate();
        } else if (startedAtField is String) {
          startedAt = DateTime.parse(startedAtField);
        } else {
          continue;
        }

        // Filter by date client-side if period is specified
        if (period != null && period != TimePeriod.allTime) {
          if (startedAt.isBefore(startDate)) continue;
        }

        DateTime endedAt;
        if (endedAtField != null) {
          if (endedAtField is Timestamp) {
            endedAt = endedAtField.toDate();
          } else if (endedAtField is String) {
            endedAt = DateTime.parse(endedAtField);
          } else {
            endedAt = now; // Use current time if parsing fails
          }
        } else {
          // Stream is still active or ended without timestamp
          // Check if stream is active
          final isActive = (data['isActive'] as bool?) ?? false;
          endedAt = isActive ? now : startedAt.add(const Duration(hours: 1)); // Default 1 hour if no end time
        }

        final duration = endedAt.difference(startedAt);
        if (duration.isNegative) continue; // Skip invalid durations

        totalHours += duration.inMinutes / 60.0;
      }

      return totalHours;
    } catch (e) {
      print('❌ Error getting streaming hours: $e');
      return 0.0;
    }
  }

  /// Get total earnings for a user (C Coins)
  Future<int> getTotalEarnings(String userId, {TimePeriod? period}) async {
    try {
      if (period == null || period == TimePeriod.allTime) {
        // Get from earnings collection (faster)
        final earningsDoc = await _firestore.collection('earnings').doc(userId).get();
        if (earningsDoc.exists) {
          return earningsDoc.data()?['totalCCoins'] ?? 0;
        }
        return 0;
      }

      // For time-filtered earnings, query gifts collection (filter client-side)
      final startDate = _getStartDate(period);
      final giftsSnapshot = await _firestore
          .collection('gifts')
          .where('receiverId', isEqualTo: userId)
          .get();

      int totalEarnings = 0;
      for (var doc in giftsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        // Filter by date client-side
        final timestampField = data['timestamp'];
        if (timestampField != null) {
          DateTime timestamp;
          if (timestampField is Timestamp) {
            timestamp = timestampField.toDate();
          } else if (timestampField is String) {
            timestamp = DateTime.parse(timestampField);
          } else {
            continue;
          }
          
          if (timestamp.isBefore(startDate)) continue;
        }
        
        final cCoins = data['cCoinsToGive'];
        if (cCoins is int) {
          totalEarnings += cCoins;
        } else if (cCoins is num) {
          totalEarnings += cCoins.toInt();
        }
      }

      return totalEarnings;
    } catch (e) {
      print('❌ Error getting earnings: $e');
      return 0;
    }
  }

  /// Check if user is currently live
  Future<bool> isUserLive(String userId) async {
    try {
      final activeStream = await _firestore
          .collection('live_streams')
          .where('hostId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return activeStream.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking live status: $e');
      return false;
    }
  }

  /// Get current viewers if user is live
  Future<int?> getCurrentViewers(String userId) async {
    try {
      final activeStream = await _firestore
          .collection('live_streams')
          .where('hostId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (activeStream.docs.isEmpty) return null;

      final data = activeStream.docs.first.data() as Map<String, dynamic>?;
      if (data == null) return null;
      return (data['viewerCount'] as int?) ?? 0;
    } catch (e) {
      print('❌ Error getting current viewers: $e');
      return null;
    }
  }

  /// Get peak viewers across all streams
  Future<int> getPeakViewers(String userId, {TimePeriod? period}) async {
    try {
      // Query only by hostId to avoid composite index requirement
      final snapshot = await _firestore
          .collection('live_streams')
          .where('hostId', isEqualTo: userId)
          .get();

      final startDate = period != null && period != TimePeriod.allTime 
          ? _getStartDate(period) 
          : DateTime(1970);
      int peakViewers = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        // Filter by date client-side if period is specified
        if (period != null && period != TimePeriod.allTime) {
          final startedAtField = data['startedAt'];
          if (startedAtField != null) {
            DateTime startedAt;
            if (startedAtField is Timestamp) {
              startedAt = startedAtField.toDate();
            } else if (startedAtField is String) {
              startedAt = DateTime.parse(startedAtField);
            } else {
              continue;
            }
            
            if (startedAt.isBefore(startDate)) continue;
          }
        }
        
        final viewerCount = (data['viewerCount'] as int?) ?? 0;
        if (viewerCount > peakViewers) {
          peakViewers = viewerCount;
        }
      }

      return peakViewers;
    } catch (e) {
      print('❌ Error getting peak viewers: $e');
      return 0;
    }
  }

  /// Get average viewers across all streams
  Future<int> getAverageViewers(String userId, {TimePeriod? period}) async {
    try {
      // Query only by hostId to avoid composite index requirement
      final snapshot = await _firestore
          .collection('live_streams')
          .where('hostId', isEqualTo: userId)
          .get();

      final startDate = period != null && period != TimePeriod.allTime 
          ? _getStartDate(period) 
          : DateTime(1970);
      
      int totalViewers = 0;
      int validStreams = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        // Filter by date client-side if period is specified
        if (period != null && period != TimePeriod.allTime) {
          final startedAtField = data['startedAt'];
          if (startedAtField != null) {
            DateTime startedAt;
            if (startedAtField is Timestamp) {
              startedAt = startedAtField.toDate();
            } else if (startedAtField is String) {
              startedAt = DateTime.parse(startedAtField);
            } else {
              continue;
            }
            
            if (startedAt.isBefore(startDate)) continue;
          }
        }
        
        final viewerCount = (data['viewerCount'] as int?) ?? 0;
        totalViewers += viewerCount;
        validStreams++;
      }

      if (validStreams == 0) return 0;
      return (totalViewers / validStreams).round();
    } catch (e) {
      print('❌ Error getting average viewers: $e');
      return 0;
    }
  }

  /// Get total gifts received
  Future<int> getTotalGiftsReceived(String userId, {TimePeriod? period}) async {
    try {
      // Query only by receiverId to avoid composite index requirement
      final snapshot = await _firestore
          .collection('gifts')
          .where('receiverId', isEqualTo: userId)
          .get();

      // Filter by date client-side if period is specified
      if (period != null && period != TimePeriod.allTime) {
        final startDate = _getStartDate(period);
        int count = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final timestampField = data['timestamp'];
          if (timestampField == null) continue;
          
          DateTime timestamp;
          if (timestampField is Timestamp) {
            timestamp = timestampField.toDate();
          } else if (timestampField is String) {
            timestamp = DateTime.parse(timestampField);
          } else {
            continue;
          }
          
          if (timestamp.isAfter(startDate) || timestamp.isAtSameMomentAs(startDate)) {
            count++;
          }
        }
        return count;
      }

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting gifts received: $e');
      return 0;
    }
  }

  /// Get all performance metrics
  Future<PerformanceMetrics> getPerformanceMetrics(
    String userId, {
    TimePeriod period = TimePeriod.allTime,
  }) async {
    try {
      // Fetch all metrics in parallel for better performance
      final results = await Future.wait([
        getTotalStreamCount(userId, period: period),
        getTotalStreamingHours(userId, period: period),
        getTotalEarnings(userId, period: period),
        isUserLive(userId),
        getPeakViewers(userId, period: period),
        getAverageViewers(userId, period: period),
        getTotalGiftsReceived(userId, period: period),
        getCurrentViewers(userId),
      ]);

      final totalStreams = results[0] as int;
      final totalHours = results[1] as double;
      final totalEarnings = results[2] as int;
      final isLive = results[3] as bool;
      final peakViewers = results[4] as int;
      final averageViewers = results[5] as int;
      final totalGifts = results[6] as int;
      final currentViewers = results[7] as int?;

      // Calculate average stream duration
      final averageDuration = totalStreams > 0 ? totalHours / totalStreams : 0.0;

      return PerformanceMetrics(
        userId: userId,
        totalStreams: totalStreams,
        totalStreamingHours: totalHours,
        totalEarnings: totalEarnings,
        isLive: isLive,
        peakViewers: peakViewers,
        averageViewers: averageViewers,
        period: period,
        lastUpdated: DateTime.now(),
        totalGiftsReceived: totalGifts,
        averageStreamDuration: averageDuration,
        currentViewers: currentViewers,
      );
    } catch (e) {
      print('❌ Error getting performance metrics: $e');
      // Return empty metrics on error
      return PerformanceMetrics(
        userId: userId,
        totalStreams: 0,
        totalStreamingHours: 0.0,
        totalEarnings: 0,
        isLive: false,
        peakViewers: 0,
        averageViewers: 0,
        period: period,
        lastUpdated: DateTime.now(),
        totalGiftsReceived: 0,
        averageStreamDuration: 0.0,
      );
    }
  }

  /// Get real-time stream of performance metrics
  Stream<PerformanceMetrics> getPerformanceMetricsStream(
    String userId, {
    TimePeriod period = TimePeriod.allTime,
  }) {
    // Combine streams from live_streams and gifts for real-time updates
    return Stream.periodic(const Duration(seconds: 10), (_) {
      return getPerformanceMetrics(userId, period: period);
    }).asyncMap((future) => future);
  }
}
