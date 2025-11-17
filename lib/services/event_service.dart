import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== ANNOUNCEMENTS =====

  // Get all active announcements (real-time)
  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    print('🔍 [EventService] Starting announcements stream...');
    
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('❌ [EventService] Stream error: $error');
      print('💡 Check Firestore Rules: Allow read on announcements collection');
      return null;
    })
        .map((snapshot) {
      print('📊 [EventService] Received snapshot with ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️  [EventService] No announcements found in Firestore!');
        print('💡 Check:');
        print('   1. Do documents exist in Firebase Console?');
        print('   2. Do they have isActive = true?');
        print('   3. Do they have createdAt field?');
      }
      
      final announcements = snapshot.docs
          .map((doc) {
            try {
              print('📄 [EventService] Processing doc: ${doc.id}');
              return AnnouncementModel.fromFirestore(doc);
            } catch (e) {
              print('❌ [EventService] Error parsing doc ${doc.id}: $e');
              print('   Data: ${doc.data()}');
              return null;
            }
          })
          .whereType<AnnouncementModel>()
          .where((announcement) => announcement.isActive)  // Filter in code instead
          .toList();
      
      print('✅ [EventService] Returning ${announcements.length} valid announcements');
      return announcements;
    });
  }

  // Get all active announcements (one-time)
  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isActive)  // Filter in code
          .toList();
    } catch (e) {
      print('❌ Error fetching announcements: $e');
      return [];
    }
  }

  // Create announcement (for admin)
  Future<String> createAnnouncement({
    required String title,
    required String description,
    required String date,
    required String time,
    String type = 'announcement',
    bool isNew = true,
    int color = 0xFF3B82F6,
    String iconName = 'campaign',
  }) async {
    try {
      final docRef = await _firestore.collection('announcements').add({
        'title': title,
        'description': description,
        'date': date,
        'time': time,
        'type': type,
        'isNew': isNew,
        'color': color,
        'iconName': iconName,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      print('✅ Announcement created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating announcement: $e');
      rethrow;
    }
  }

  // Update announcement
  Future<void> updateAnnouncement(
      String announcementId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update(data);
      print('✅ Announcement updated successfully');
    } catch (e) {
      print('❌ Error updating announcement: $e');
      rethrow;
    }
  }

  // Delete announcement (soft delete)
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(announcementId)
          .update({'isActive': false});
      print('✅ Announcement deleted successfully');
    } catch (e) {
      print('❌ Error deleting announcement: $e');
      rethrow;
    }
  }

  // ===== EVENTS =====

  // Get all active events (real-time)
  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) => event.isActive)  // Filter in code
          .toList();
    });
  }

  // Get all active events (one-time)
  Future<List<EventModel>> getEvents() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) => event.isActive)  // Filter in code
          .toList();
    } catch (e) {
      print('❌ Error fetching events: $e');
      return [];
    }
  }

  // Create event (for admin)
  Future<String> createEvent({
    required String title,
    required String description,
    required String date,
    required String time,
    String type = 'event',
    bool isNew = true,
    int color = 0xFF10B981,
    String participants = '0',
    String? imageURL, // Optional event poster image
  }) async {
    try {
      final docRef = await _firestore.collection('events').add({
        'title': title,
        'description': description,
        'date': date,
        'time': time,
        'type': type,
        'isNew': isNew,
        'color': color,
        'participants': participants,
        'imageURL': imageURL, // Include image URL
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      print('✅ Event created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating event: $e');
      rethrow;
    }
  }

  // Update event
  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('events').doc(eventId).update(data);
      print('✅ Event updated successfully');
    } catch (e) {
      print('❌ Error updating event: $e');
      rethrow;
    }
  }

  // Delete event (soft delete)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .update({'isActive': false});
      print('✅ Event deleted successfully');
    } catch (e) {
      print('❌ Error deleting event: $e');
      rethrow;
    }
  }
}

