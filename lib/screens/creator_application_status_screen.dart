import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/host_application_service.dart';
import '../models/host_application_model.dart';
import 'become_creator_screen.dart';

class CreatorApplicationStatusScreen extends StatefulWidget {
  final String? applicationId; // Optional - if null, will fetch latest
  final String phoneNumber;

  const CreatorApplicationStatusScreen({
    super.key,
    this.applicationId,
    required this.phoneNumber,
  });

  @override
  State<CreatorApplicationStatusScreen> createState() =>
      _CreatorApplicationStatusScreenState();
}

class _CreatorApplicationStatusScreenState
    extends State<CreatorApplicationStatusScreen> {
  final HostApplicationService _applicationService = HostApplicationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Application Status',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot?>(
        stream: widget.applicationId != null
            ? _firestore
                .collection('host_applications')
                .doc(widget.applicationId)
                .snapshots()
            : currentUser != null
                ? _applicationService.getApplicationStatus(currentUser.uid)
                : Stream<DocumentSnapshot?>.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF1B7C),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading application status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return _buildNoApplicationView();
          }

          final application = HostApplicationModel.fromFirestore(snapshot.data!);
          return _buildStatusView(application);
        },
      ),
    );
  }

  Widget _buildNoApplicationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 50,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Application Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t submitted an application yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BecomeCreatorScreen(
                      phoneNumber: widget.phoneNumber,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1B7C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Application',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView(HostApplicationModel application) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Icon
          _buildStatusIcon(application.status),
          
          const SizedBox(height: 20),
          
          // Status Title
          _buildStatusTitle(application.status),
          
          const SizedBox(height: 12),
          
          // Status Message
          _buildStatusMessage(application),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          _buildActionButtons(application),
          
          // Bottom spacing
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(HostApplicationStatus status) {
    IconData icon;
    Color color;
    List<Color> gradientColors;

    switch (status) {
      case HostApplicationStatus.pending:
        icon = Icons.pending_actions_rounded;
        color = const Color(0xFF6366F1);
        gradientColors = [
          const Color(0xFF6366F1),
          const Color(0xFF8B5CF6),
        ];
        break;
      case HostApplicationStatus.reviewing:
        icon = Icons.search_rounded;
        color = const Color(0xFF3B82F6);
        gradientColors = [
          const Color(0xFF3B82F6),
          const Color(0xFF2563EB),
        ];
        break;
      case HostApplicationStatus.approved:
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF10B981);
        gradientColors = [
          const Color(0xFF10B981),
          const Color(0xFF059669),
        ];
        break;
      case HostApplicationStatus.rejected:
        icon = Icons.cancel_rounded;
        color = const Color(0xFFEF4444);
        gradientColors = [
          const Color(0xFFEF4444),
          const Color(0xFFDC2626),
        ];
        break;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildStatusTitle(HostApplicationStatus status) {
    String title;
    switch (status) {
      case HostApplicationStatus.pending:
        title = 'Application Submitted!';
        break;
      case HostApplicationStatus.reviewing:
        title = 'Under Review';
        break;
      case HostApplicationStatus.approved:
        title = 'Application Approved!';
        break;
      case HostApplicationStatus.rejected:
        title = 'Application Rejected';
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.2,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatusMessage(HostApplicationModel application) {
    String message;
    
    switch (application.status) {
      case HostApplicationStatus.pending:
        message = 'Your request has been submitted successfully. Please wait 24-78 hours for review.';
        break;
      case HostApplicationStatus.reviewing:
        message = 'Your application is currently being reviewed by our team. We will notify you once a decision has been made.';
        break;
      case HostApplicationStatus.approved:
        message = 'Congratulations! Your application has been approved. You can now start streaming and earning!';
        break;
      case HostApplicationStatus.rejected:
        message = application.rejectionReason != null && application.rejectionReason!.isNotEmpty
            ? 'Your application was not approved at this time.\n\nReason: ${application.rejectionReason}'
            : 'Your application was not approved at this time. You can reapply after reviewing our guidelines.';
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }


  Widget _buildActionButtons(HostApplicationModel application) {
    switch (application.status) {
      case HostApplicationStatus.pending:
      case HostApplicationStatus.reviewing:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1B7C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ).copyWith(
                  backgroundColor: MaterialStateProperty.all(const Color(0xFFFF1B7C)),
                  overlayColor: MaterialStateProperty.all(
                    Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Text(
                  'Back to Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      
      case HostApplicationStatus.approved:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ).copyWith(
                  backgroundColor: MaterialStateProperty.all(const Color(0xFF10B981)),
                  overlayColor: MaterialStateProperty.all(
                    Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Text(
                  'Start Streaming',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      
      case HostApplicationStatus.rejected:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BecomeCreatorScreen(
                        phoneNumber: widget.phoneNumber,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1B7C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ).copyWith(
                  backgroundColor: MaterialStateProperty.all(const Color(0xFFFF1B7C)),
                  overlayColor: MaterialStateProperty.all(
                    Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Text(
                  'Reapply',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(
                    color: Color(0xFFFF1B7C),
                    width: 1.5,
                  ),
                ).copyWith(
                  overlayColor: MaterialStateProperty.all(
                    const Color(0xFFFF1B7C).withValues(alpha: 0.1),
                  ),
                ),
                child: const Text(
                  'Back to Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF1B7C),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
