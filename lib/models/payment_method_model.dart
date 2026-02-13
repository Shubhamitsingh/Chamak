import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for saved payment methods (UPI, Bank, Crypto)
/// Stored in: users/{userId}/payment_methods/{methodId}
class PaymentMethodModel {
  final String id;
  final String userId;
  final String type; // 'UPI', 'BANK', 'CRYPTO'
  final String displayName; // e.g., "UPI: user@paytm", "Bank: ****1234"
  final Map<String, dynamic> details; // Payment details (UPI ID, bank account, etc.)
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastUsed;

  PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.displayName,
    required this.details,
    this.isDefault = false,
    required this.createdAt,
    this.lastUsed,
  });

  /// Create from Firestore document
  factory PaymentMethodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethodModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      details: Map<String, dynamic>.from(data['details'] as Map? ?? {}),
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsed: (data['lastUsed'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'displayName': displayName,
      'details': details,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
    };
  }

  /// Create a copy with updated fields
  PaymentMethodModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? displayName,
    Map<String, dynamic>? details,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  /// Get masked display for privacy
  String getMaskedDisplay() {
    switch (type) {
      case 'UPI':
        final upiId = details['upiId'] as String? ?? '';
        if (upiId.contains('@')) {
          final parts = upiId.split('@');
          return '${parts[0]}@***';
        }
        return '***@***';
      case 'BANK':
        final accountNumber = details['accountNumber'] as String? ?? '';
        if (accountNumber.length >= 4) {
          return '****${accountNumber.substring(accountNumber.length - 4)}';
        }
        return '****';
      case 'CRYPTO':
        final address = details['walletAddress'] as String? ?? '';
        if (address.length >= 8) {
          return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
        }
        return '***';
      default:
        return displayName;
    }
  }
}
