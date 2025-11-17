import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_ticket_model.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'supportTickets';

  // Create a new support ticket
  Future<String> createTicket({
    required String userId,
    required String userName,
    required String userPhone,
    required String category,
    required String description,
  }) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'category': category,
        'description': description,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'adminResponse': null,
        'assignedTo': null,
      });

      print('✅ Ticket created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating ticket: $e');
      rethrow;
    }
  }

  // Get all tickets for a specific user
  Stream<List<SupportTicket>> getUserTickets(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicket.fromFirestore(doc))
          .toList();
    });
  }

  // Get a single ticket by ID
  Future<SupportTicket?> getTicketById(String ticketId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(ticketId).get();
      if (doc.exists) {
        return SupportTicket.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching ticket: $e');
      return null;
    }
  }

  // Update ticket status (for admin)
  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
    String? adminResponse,
  }) async {
    try {
      await _firestore.collection(_collection).doc(ticketId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (adminResponse != null) 'adminResponse': adminResponse,
      });
      print('✅ Ticket status updated to: $status');
    } catch (e) {
      print('❌ Error updating ticket: $e');
      rethrow;
    }
  }

  // Assign ticket to an admin
  Future<void> assignTicket({
    required String ticketId,
    required String adminId,
  }) async {
    try {
      await _firestore.collection(_collection).doc(ticketId).update({
        'assignedTo': adminId,
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Ticket assigned to admin: $adminId');
    } catch (e) {
      print('❌ Error assigning ticket: $e');
      rethrow;
    }
  }

  // Delete ticket (for admin)
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _firestore.collection(_collection).doc(ticketId).delete();
      print('✅ Ticket deleted successfully');
    } catch (e) {
      print('❌ Error deleting ticket: $e');
      rethrow;
    }
  }

  // Get all tickets (for admin panel)
  Stream<List<SupportTicket>> getAllTickets({String? status}) {
    Query query = _firestore.collection(_collection);
    
    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicket.fromFirestore(doc))
          .toList();
    });
  }

  // Get ticket statistics (for admin dashboard)
  Future<Map<String, int>> getTicketStats() async {
    try {
      final allTickets = await _firestore.collection(_collection).get();
      
      int open = 0;
      int inProgress = 0;
      int resolved = 0;
      int closed = 0;

      for (var doc in allTickets.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'open':
            open++;
            break;
          case 'in_progress':
            inProgress++;
            break;
          case 'resolved':
            resolved++;
            break;
          case 'closed':
            closed++;
            break;
        }
      }

      return {
        'total': allTickets.size,
        'open': open,
        'in_progress': inProgress,
        'resolved': resolved,
        'closed': closed,
      };
    } catch (e) {
      print('❌ Error fetching ticket stats: $e');
      return {
        'total': 0,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };
    }
  }
}




