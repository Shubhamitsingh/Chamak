import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String date; // For backward compatibility
  final String? startDate; // Event start date
  final String? endDate; // Event end date
  final String time;
  final String type; // 'event'
  final bool isNew;
  final int color; // Color value as int
  final String participants;
  final String? imageURL; // Event poster image URL
  final DateTime createdAt;
  final bool isActive;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.startDate,
    this.endDate,
    required this.time,
    this.type = 'event',
    this.isNew = true,
    this.color = 0xFF10B981, // Default green
    this.participants = '0',
    this.imageURL, // Optional image URL
    required this.createdAt,
    this.isActive = true,
  });

  // Convert from Firestore
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // DEBUG: Print all available fields
    print('📋 [EventModel] Parsing event: ${doc.id}');
    print('   Available fields: ${data.keys.toList()}');
    
    return EventModel(
      id: doc.id,
      // Support multiple field names for title
      title: data['title'] ?? data['name'] ?? '',
      // Support multiple field names for description
      description: data['description'] ?? data['details'] ?? '',
      // Support multiple field names for date (fallback to endDate if no date field)
      date: data['date'] ?? data['endDate'] ?? data['startDate'] ?? data['eventDate'] ?? '',
      // Separate start and end dates
      startDate: data['startDate'],
      endDate: data['endDate'],
      // Support multiple field names for time
      time: data['time'] ?? data['eventTime'] ?? '',
      type: data['type'] ?? 'event',
      isNew: data['isNew'] ?? data['new'] ?? true,
      color: data['color'] ?? 0xFF10B981,
      participants: data['participants']?.toString() ?? data['attendees']?.toString() ?? '0',
      // Support multiple field names for image
      imageURL: data['imageURL'] ?? 
                data['imageUrl'] ?? 
                data['bannerUrl'] ?? 
                data['banner'] ?? 
                data['image'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? data['active'] ?? true,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'startDate': startDate,
      'endDate': endDate,
      'time': time,
      'type': type,
      'isNew': isNew,
      'color': color,
      'participants': participants,
      'imageURL': imageURL, // Include image URL
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}


