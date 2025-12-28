import 'package:cloud_firestore/cloud_firestore.dart';

class CallTransactionModel {
  final String transactionId;
  final String callRequestId;
  final String callerId;
  final String hostId;
  final int uCoinsDeducted;
  final int cCoinsCredited;
  final int durationSeconds; // Duration in seconds for this transaction
  final DateTime timestamp;
  final String? streamId;

  CallTransactionModel({
    required this.transactionId,
    required this.callRequestId,
    required this.callerId,
    required this.hostId,
    required this.uCoinsDeducted,
    required this.cCoinsCredited,
    required this.durationSeconds,
    required this.timestamp,
    this.streamId,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'callRequestId': callRequestId,
      'callerId': callerId,
      'hostId': hostId,
      'uCoinsDeducted': uCoinsDeducted,
      'cCoinsCredited': cCoinsCredited,
      'durationSeconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
      'streamId': streamId,
    };
  }

  factory CallTransactionModel.fromMap(Map<String, dynamic> map) {
    return CallTransactionModel(
      transactionId: map['transactionId'] ?? '',
      callRequestId: map['callRequestId'] ?? '',
      callerId: map['callerId'] ?? '',
      hostId: map['hostId'] ?? '',
      uCoinsDeducted: map['uCoinsDeducted'] ?? 0,
      cCoinsCredited: map['cCoinsCredited'] ?? 0,
      durationSeconds: map['durationSeconds'] ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      streamId: map['streamId'],
    );
  }

  factory CallTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallTransactionModel.fromMap(data);
  }
}
























