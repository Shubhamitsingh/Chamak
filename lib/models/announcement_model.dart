import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String type; // 'announcement' or 'general'
  final bool isNew;
  final int color; // Color value as int
  final String iconName; // Icon name as string
  final DateTime createdAt;
  final bool isActive;
  final String? userId; // Optional: For user-specific announcements (e.g., coin additions)

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.type = 'announcement',
    this.isNew = true,
    this.color = 0xFF3B82F6, // Default blue
    this.iconName = 'campaign',
    required this.createdAt,
    this.isActive = true,
    this.userId,
  });

  // Convert from Firestore
  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      type: data['type'] ?? 'announcement',
      isNew: data['isNew'] ?? true,
      color: data['color'] ?? 0xFF3B82F6,
      iconName: data['iconName'] ?? 'campaign',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      userId: data['userId'] as String?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'type': type,
      'isNew': isNew,
      'color': color,
      'iconName': iconName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      if (userId != null) 'userId': userId, // Include userId if present
    };
  }
}



