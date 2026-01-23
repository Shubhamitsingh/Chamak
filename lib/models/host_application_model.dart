import 'package:cloud_firestore/cloud_firestore.dart';

enum HostApplicationStatus {
  pending,
  reviewing,
  approved,
  rejected,
}

class HostApplicationModel {
  final String applicationId;
  final String userId;
  final String userDisplayId; // 7-digit ID
  final String username;
  final String phoneNumber;
  final String? email;
  final DateTime dateOfBirth;
  final String bio;
  final Map<String, String>? socialMediaLinks;
  final String? profilePhotoUrl;
  final HostApplicationStatus status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin user ID
  final DateTime? approvedAt;
  final bool termsAccepted;
  final DateTime termsAcceptedAt;

  HostApplicationModel({
    required this.applicationId,
    required this.userId,
    required this.userDisplayId,
    required this.username,
    required this.phoneNumber,
    this.email,
    required this.dateOfBirth,
    required this.bio,
    this.socialMediaLinks,
    this.profilePhotoUrl,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.approvedAt,
    required this.termsAccepted,
    required this.termsAcceptedAt,
  });

  // Convert Firestore document to HostApplicationModel
  factory HostApplicationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse status
    HostApplicationStatus parseStatus(String? statusStr) {
      switch (statusStr) {
        case 'pending':
          return HostApplicationStatus.pending;
        case 'reviewing':
          return HostApplicationStatus.reviewing;
        case 'approved':
          return HostApplicationStatus.approved;
        case 'rejected':
          return HostApplicationStatus.rejected;
        default:
          return HostApplicationStatus.pending;
      }
    }

    // Parse Timestamp to DateTime
    DateTime parseTimestamp(dynamic timestamp, DateTime fallback) {
      if (timestamp == null) return fallback;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return fallback;
    }

    // Parse dateOfBirth (can be Timestamp or String)
    DateTime parseDateOfBirth(dynamic dob) {
      if (dob == null) return DateTime.now().subtract(const Duration(days: 365 * 18));
      if (dob is Timestamp) return dob.toDate();
      if (dob is DateTime) return dob;
      if (dob is String) {
        try {
          return DateTime.parse(dob);
        } catch (e) {
          return DateTime.now().subtract(const Duration(days: 365 * 18));
        }
      }
      return DateTime.now().subtract(const Duration(days: 365 * 18));
    }

    final now = DateTime.now();

    return HostApplicationModel(
      applicationId: doc.id,
      userId: data['userId'] ?? '',
      userDisplayId: data['userDisplayId'] ?? '',
      username: data['username'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      dateOfBirth: parseDateOfBirth(data['dateOfBirth']),
      bio: data['bio'] ?? '',
      socialMediaLinks: data['socialMediaLinks'] != null
          ? Map<String, String>.from(data['socialMediaLinks'])
          : null,
      profilePhotoUrl: data['profilePhotoUrl'],
      status: parseStatus(data['status']),
      rejectionReason: data['rejectionReason'],
      submittedAt: parseTimestamp(data['submittedAt'], now),
      reviewedAt: data['reviewedAt'] != null
          ? parseTimestamp(data['reviewedAt'], now)
          : null,
      reviewedBy: data['reviewedBy'],
      approvedAt: data['approvedAt'] != null
          ? parseTimestamp(data['approvedAt'], now)
          : null,
      termsAccepted: data['termsAccepted'] ?? false,
      termsAcceptedAt: parseTimestamp(data['termsAcceptedAt'], now),
    );
  }

  // Convert HostApplicationModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userDisplayId': userDisplayId,
      'username': username,
      'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'bio': bio,
      if (socialMediaLinks != null) 'socialMediaLinks': socialMediaLinks,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      'status': status.name,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'submittedAt': Timestamp.fromDate(submittedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      'termsAccepted': termsAccepted,
      'termsAcceptedAt': Timestamp.fromDate(termsAcceptedAt),
    };
  }

  // Helper method to get status as string
  String get statusString => status.name;

  // Helper method to check if application is pending
  bool get isPending => status == HostApplicationStatus.pending;

  // Helper method to check if application is approved
  bool get isApproved => status == HostApplicationStatus.approved;

  // Helper method to check if application is rejected
  bool get isRejected => status == HostApplicationStatus.rejected;
}
