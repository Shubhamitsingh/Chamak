import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequestModel {
  final String id;
  final String userId;
  final String? userName; // Host/User name
  final String? displayId; // Formatted user ID for display
  final double amount; // Amount in INR (Payment Amount) - NOT C Coins
  final String withdrawalMethod; // UPI, Bank Transfer, Crypto
  final Map<String, dynamic> paymentDetails;
  final String status; // pending, approved, paid
  final DateTime requestDate;
  final DateTime? approvedDate;
  final DateTime? paidDate;
  final String? paymentProofURL;
  final String? adminNotes;
  final String? approvedBy; // Admin user ID

  WithdrawalRequestModel({
    required this.id,
    required this.userId,
    this.userName,
    this.displayId,
    required this.amount, // double - INR amount
    required this.withdrawalMethod,
    required this.paymentDetails,
    this.status = 'pending',
    required this.requestDate,
    this.approvedDate,
    this.paidDate,
    this.paymentProofURL,
    this.adminNotes,
    this.approvedBy,
  });

  factory WithdrawalRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalRequestModel(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String?,
      displayId: data['displayId'] as String?,
      // Handle backward compatibility: old records have int (C Coins), new ones have double (INR)
      amount: (data['amount'] is int) 
          ? (data['amount'] as int).toDouble() * 0.04  // Convert old C Coins to INR
          : (data['amount'] as num).toDouble(),  // New format: already in INR
      withdrawalMethod: data['withdrawalMethod'] as String,
      paymentDetails: data['paymentDetails'] as Map<String, dynamic>,
      status: data['status'] as String? ?? 'pending',
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      approvedDate: (data['approvedDate'] as Timestamp?)?.toDate(),
      paidDate: (data['paidDate'] as Timestamp?)?.toDate(),
      paymentProofURL: data['paymentProofURL'] as String?,
      adminNotes: data['adminNotes'] as String?,
      approvedBy: data['approvedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'displayId': displayId,
      'amount': amount,
      'withdrawalMethod': withdrawalMethod,
      'paymentDetails': paymentDetails,
      'status': status,
      'requestDate': Timestamp.fromDate(requestDate),
      'approvedDate': approvedDate != null ? Timestamp.fromDate(approvedDate!) : null,
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'paymentProofURL': paymentProofURL,
      'adminNotes': adminNotes,
      'approvedBy': approvedBy,
    };
  }
}








