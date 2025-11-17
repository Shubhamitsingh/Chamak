import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Mark announcement as seen by user
  Future<void> markAsSeen(String announcementId) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('seenAnnouncements')
          .doc(announcementId)
          .set({
        'seenAt': FieldValue.serverTimestamp(),
        'announcementId': announcementId,
      });

      print('✅ Marked announcement as seen: $announcementId');
    } catch (e) {
      print('❌ Error marking announcement as seen: $e');
    }
  }

  // Mark multiple announcements as seen
  Future<void> markMultipleAsSeen(List<String> announcementIds) async {
    if (_userId == null) return;

    try {
      final batch = _firestore.batch();

      for (final id in announcementIds) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('seenAnnouncements')
            .doc(id);

        batch.set(docRef, {
          'seenAt': FieldValue.serverTimestamp(),
          'announcementId': id,
        });
      }

      await batch.commit();
      print('✅ Marked ${announcementIds.length} announcements as seen');
    } catch (e) {
      print('❌ Error marking announcements as seen: $e');
    }
  }

  // Dismiss/Hide announcement for this user
  Future<void> dismissAnnouncement(String announcementId) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dismissedAnnouncements')
          .doc(announcementId)
          .set({
        'dismissedAt': FieldValue.serverTimestamp(),
        'announcementId': announcementId,
      });

      print('✅ Dismissed announcement: $announcementId');
    } catch (e) {
      print('❌ Error dismissing announcement: $e');
    }
  }

  // Check if announcement is seen by user
  Future<bool> isSeen(String announcementId) async {
    if (_userId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('seenAnnouncements')
          .doc(announcementId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Error checking if seen: $e');
      return false;
    }
  }

  // Check if announcement is dismissed by user
  Future<bool> isDismissed(String announcementId) async {
    if (_userId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dismissedAnnouncements')
          .doc(announcementId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Error checking if dismissed: $e');
      return false;
    }
  }

  // Get list of seen announcement IDs
  Future<Set<String>> getSeenAnnouncementIds() async {
    if (_userId == null) return {};

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('seenAnnouncements')
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print('❌ Error getting seen announcements: $e');
      return {};
    }
  }

  // Get list of dismissed announcement IDs
  Future<Set<String>> getDismissedAnnouncementIds() async {
    if (_userId == null) return {};

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dismissedAnnouncements')
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print('❌ Error getting dismissed announcements: $e');
      return {};
    }
  }

  // Stream of seen announcement IDs (real-time)
  Stream<Set<String>> getSeenAnnouncementIdsStream() {
    if (_userId == null) return Stream.value({});

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('seenAnnouncements')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  // Stream of dismissed announcement IDs (real-time)
  Stream<Set<String>> getDismissedAnnouncementIdsStream() {
    if (_userId == null) return Stream.value({});

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('dismissedAnnouncements')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  // ===== EVENT TRACKING =====

  // Mark event as seen by user
  Future<void> markEventAsSeen(String eventId) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('seenEvents')
          .doc(eventId)
          .set({
        'seenAt': FieldValue.serverTimestamp(),
        'eventId': eventId,
      });

      print('✅ Marked event as seen: $eventId');
    } catch (e) {
      print('❌ Error marking event as seen: $e');
    }
  }

  // Mark multiple events as seen
  Future<void> markMultipleEventsAsSeen(List<String> eventIds) async {
    if (_userId == null) return;

    try {
      final batch = _firestore.batch();

      for (final id in eventIds) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('seenEvents')
            .doc(id);

        batch.set(docRef, {
          'seenAt': FieldValue.serverTimestamp(),
          'eventId': id,
        });
      }

      await batch.commit();
      print('✅ Marked ${eventIds.length} events as seen');
    } catch (e) {
      print('❌ Error marking events as seen: $e');
    }
  }

  // Stream of seen event IDs (real-time)
  Stream<Set<String>> getSeenEventIdsStream() {
    if (_userId == null) return Stream.value({});

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('seenEvents')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }
}


