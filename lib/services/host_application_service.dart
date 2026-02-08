import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/host_application_model.dart';

class HostApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _applicationsCollection =>
      _firestore.collection('host_applications');

  /// Submit a new host application
  Future<String?> submitApplication({
    required String userId,
    required String userDisplayId,
    required String username,
    required String phoneNumber,
    required DateTime dateOfBirth,
    String? email,
    required String bio,
    Map<String, String>? socialMediaLinks,
    String? profilePhotoUrl,
    required bool termsAccepted,
  }) async {
    try {
      // Check if user already has a pending application
      final existingApplication = await _applicationsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        debugPrint('⚠️ User already has a pending application');
        return existingApplication.docs.first.id; // Return existing application ID
      }

      // Check if user already has an approved application
      final approvedApplication = await _applicationsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (approvedApplication.docs.isNotEmpty) {
        debugPrint('⚠️ User already has an approved application');
        return null; // User is already approved
      }

      // Create new application
      final applicationData = {
        'userId': userId,
        'userDisplayId': userDisplayId,
        'username': username,
        'phoneNumber': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'bio': bio,
        if (socialMediaLinks != null && socialMediaLinks.isNotEmpty)
          'socialMediaLinks': socialMediaLinks,
        if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
          'profilePhotoUrl': profilePhotoUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'termsAccepted': termsAccepted,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _applicationsCollection.add(applicationData);
      debugPrint('✅ Host application submitted: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error submitting host application: $e');
      return null;
    }
  }

  /// Get application status for current user
  Stream<DocumentSnapshot?> getApplicationStatus(String userId) {
    try {
      debugPrint('🔍 Fetching application status for user: $userId');
      
      return _applicationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
        debugPrint('📊 Query result: ${snapshot.docs.length} documents');
        if (snapshot.docs.isEmpty) {
          debugPrint('ℹ️ No application found for user: $userId');
          return null;
        }
        
        debugPrint('✅ Application found: ${snapshot.docs.first.id}');
        return snapshot.docs.first;
      }).handleError((error) {
        debugPrint('❌ Error in getApplicationStatus stream: $error');
        if (error.toString().contains('index')) {
          debugPrint('⚠️ Firestore index missing! Create composite index for host_applications');
          debugPrint('   Fields: userId (Ascending), submittedAt (Descending)');
          debugPrint('   Go to Firebase Console → Firestore → Indexes to create');
        } else if (error.toString().contains('permission') || error.toString().contains('PERMISSION_DENIED')) {
          debugPrint('⚠️ Permission denied! Check Firestore security rules');
          debugPrint('   Verify user can read their own applications');
        }
        return null;
      });
    } catch (e) {
      debugPrint('❌ Exception in getApplicationStatus: $e');
      return Stream<DocumentSnapshot?>.value(null);
    }
  }

  /// Get application by ID
  Future<HostApplicationModel?> getApplicationById(String applicationId) async {
    try {
      final doc = await _applicationsCollection.doc(applicationId).get();
      if (!doc.exists) return null;
      return HostApplicationModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error getting application: $e');
      return null;
    }
  }

  /// Get all applications (for admin)
  Stream<List<HostApplicationModel>> getAllApplications({
    String? statusFilter,
  }) {
    Query query = _applicationsCollection.orderBy('submittedAt', descending: true);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HostApplicationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Approve application (admin only)
  Future<bool> approveApplication(String applicationId, String adminId) async {
    try {
      debugPrint('🔍 [approveApplication] Starting approval for: $applicationId');
      debugPrint('👤 [approveApplication] Admin ID: $adminId');
      
      final application = await getApplicationById(applicationId);
      if (application == null) {
        debugPrint('❌ Application not found: $applicationId');
        return false;
      }

      debugPrint('📋 [approveApplication] Application found for user: ${application.userId}');
      debugPrint('📋 [approveApplication] Current status: ${application.status}');

      // Update application status
      debugPrint('🔄 [approveApplication] Updating host_applications document...');
      try {
        await _applicationsCollection.doc(applicationId).update({
          'status': 'approved',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminId,
          'approvedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ [approveApplication] Application document updated successfully');
      } catch (e) {
        debugPrint('❌ [approveApplication] Failed to update application document: $e');
        debugPrint('❌ [approveApplication] Error type: ${e.runtimeType}');
        if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
          debugPrint('⚠️ [approveApplication] PERMISSION DENIED - Check:');
          debugPrint('   1. Admin document exists in /admins/$adminId');
          debugPrint('   2. isAdmin field is boolean true (not string)');
          debugPrint('   3. User is authenticated with Firebase Auth');
        }
        rethrow;
      }

      // Update user document to set isActive = true (approved = host)
      debugPrint('🔄 [approveApplication] Updating users document for: ${application.userId}');
      try {
        await _firestore.collection('users').doc(application.userId).update({
          'isActive': true,
          'hostApprovedAt': FieldValue.serverTimestamp(),
          'hostApplicationId': applicationId,
        });
        debugPrint('✅ [approveApplication] User document updated successfully');
      } catch (e) {
        debugPrint('❌ [approveApplication] Failed to update user document: $e');
        debugPrint('❌ [approveApplication] Error type: ${e.runtimeType}');
        if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
          debugPrint('⚠️ [approveApplication] PERMISSION DENIED - Check:');
          debugPrint('   1. Admin document exists in /admins/$adminId');
          debugPrint('   2. isAdmin field is boolean true (not string)');
          debugPrint('   3. User is authenticated with Firebase Auth');
        }
        rethrow;
      }

      debugPrint('✅ [approveApplication] Application approved successfully: $applicationId');
      return true;
    } catch (e) {
      debugPrint('❌ [approveApplication] Error approving application: $e');
      debugPrint('❌ [approveApplication] Error details: ${e.toString()}');
      debugPrint('❌ [approveApplication] Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Reject application (admin only)
  Future<bool> rejectApplication(
    String applicationId,
    String adminId,
    String reason,
  ) async {
    try {
      final application = await getApplicationById(applicationId);
      if (application == null) {
        debugPrint('❌ Application not found: $applicationId');
        return false;
      }

      await _applicationsCollection.doc(applicationId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
      });

      debugPrint('✅ Application rejected: $applicationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error rejecting application: $e');
      return false;
    }
  }

  /// Check if user has pending application
  Future<bool> hasPendingApplication(String userId) async {
    try {
      final snapshot = await _applicationsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking pending application: $e');
      return false;
    }
  }

  /// Check if user has approved application (is already a host)
  Future<bool> hasApprovedApplication(String userId) async {
    try {
      final snapshot = await _applicationsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking approved application: $e');
      return false;
    }
  }
}
