import 'package:cloud_firestore/cloud_firestore.dart';

enum TimePeriod {
  today,
  thisWeek,
  thisMonth,
  allTime,
}

class PerformanceMetrics {
  final String userId;
  final int totalStreams;
  final double totalStreamingHours;
  final int totalEarnings; // C Coins
  final bool isLive;
  final int peakViewers;
  final int averageViewers;
  final TimePeriod period;
  final DateTime lastUpdated;
  
  // Additional engagement metrics
  final int totalGiftsReceived;
  final double averageStreamDuration; // in hours
  final int? currentViewers; // Current viewers if live
  
  PerformanceMetrics({
    required this.userId,
    required this.totalStreams,
    required this.totalStreamingHours,
    required this.totalEarnings,
    required this.isLive,
    required this.peakViewers,
    required this.averageViewers,
    required this.period,
    required this.lastUpdated,
    required this.totalGiftsReceived,
    required this.averageStreamDuration,
    this.currentViewers,
  });

  PerformanceMetrics copyWith({
    String? userId,
    int? totalStreams,
    double? totalStreamingHours,
    int? totalEarnings,
    bool? isLive,
    int? peakViewers,
    int? averageViewers,
    TimePeriod? period,
    DateTime? lastUpdated,
    int? totalGiftsReceived,
    double? averageStreamDuration,
    int? currentViewers,
  }) {
    return PerformanceMetrics(
      userId: userId ?? this.userId,
      totalStreams: totalStreams ?? this.totalStreams,
      totalStreamingHours: totalStreamingHours ?? this.totalStreamingHours,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      isLive: isLive ?? this.isLive,
      peakViewers: peakViewers ?? this.peakViewers,
      averageViewers: averageViewers ?? this.averageViewers,
      period: period ?? this.period,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalGiftsReceived: totalGiftsReceived ?? this.totalGiftsReceived,
      averageStreamDuration: averageStreamDuration ?? this.averageStreamDuration,
      currentViewers: currentViewers ?? this.currentViewers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalStreams': totalStreams,
      'totalStreamingHours': totalStreamingHours,
      'totalEarnings': totalEarnings,
      'isLive': isLive,
      'peakViewers': peakViewers,
      'averageViewers': averageViewers,
      'period': period.name,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'totalGiftsReceived': totalGiftsReceived,
      'averageStreamDuration': averageStreamDuration,
      'currentViewers': currentViewers,
    };
  }

  factory PerformanceMetrics.fromMap(Map<String, dynamic> map) {
    return PerformanceMetrics(
      userId: map['userId'] ?? '',
      totalStreams: map['totalStreams'] ?? 0,
      totalStreamingHours: (map['totalStreamingHours'] ?? 0).toDouble(),
      totalEarnings: map['totalEarnings'] ?? 0,
      isLive: map['isLive'] ?? false,
      peakViewers: map['peakViewers'] ?? 0,
      averageViewers: map['averageViewers'] ?? 0,
      period: TimePeriod.values.firstWhere(
        (e) => e.name == (map['period'] ?? 'allTime'),
        orElse: () => TimePeriod.allTime,
      ),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalGiftsReceived: map['totalGiftsReceived'] ?? 0,
      averageStreamDuration: (map['averageStreamDuration'] ?? 0).toDouble(),
      currentViewers: map['currentViewers'],
    );
  }
}
