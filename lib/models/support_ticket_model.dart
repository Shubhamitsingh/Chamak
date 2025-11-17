import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String category;
  final String description;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminResponse;
  final String? assignedTo;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.category,
    required this.description,
    this.status = 'open',
    required this.createdAt,
    this.updatedAt,
    this.adminResponse,
    this.assignedTo,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminResponse': adminResponse,
      'assignedTo': assignedTo,
    };
  }

  // Create from Firestore
  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicket(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPhone: data['userPhone'] ?? '',
      category: data['category'] ?? 'General',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      adminResponse: data['adminResponse'],
      assignedTo: data['assignedTo'],
    );
  }

  // Copy with method for updates
  SupportTicket copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? category,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminResponse,
    String? assignedTo,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}




