import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/host_application_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/id_generator_service.dart';
import '../models/user_model.dart';
import '../models/host_application_model.dart';
import 'terms_and_conditions_screen.dart';
import 'creator_application_status_screen.dart';
import '../generated/l10n/app_localizations.dart';

class BecomeCreatorScreen extends StatefulWidget {
  final String phoneNumber;

  const BecomeCreatorScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<BecomeCreatorScreen> createState() => _BecomeCreatorScreenState();
}

class _BecomeCreatorScreenState extends State<BecomeCreatorScreen> {
  final HostApplicationService _applicationService = HostApplicationService();
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  File? _selfieFile;
  bool _isSubmitting = false;
  bool _termsAccepted = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      final userData = await _databaseService.getUserData(currentUser.uid);
      if (mounted) setState(() => _currentUser = userData);
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (image != null && mounted) {
        setState(() => _selfieFile = File(image.path));
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorLoadingProfile),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (_selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take or upload a selfie first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseAcceptTermsAndConditions),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final photoUrl = await _storageService.uploadHostApplicationSelfie(_selfieFile!);
      if (photoUrl == null || !mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload selfie. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final applicationId = await _applicationService.submitApplication(
        userId: currentUser.uid,
        userDisplayId: IdGeneratorService.getDisplayId(_currentUser!.numericUserId),
        username: _currentUser!.displayName ?? 'User',
        phoneNumber: _currentUser!.phoneNumber,
        dateOfBirth: DateTime(DateTime.now().year - 18, 1, 1),
        email: null,
        bio: '',
        socialMediaLinks: null,
        profilePhotoUrl: photoUrl,
        termsAccepted: _termsAccepted,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (applicationId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreatorApplicationStatusScreen(
                applicationId: applicationId,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToSubmitApplication),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error submitting application: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.pleaseLoginAgain),
        ),
      );
    }

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
          'Become a Creator',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot?>(
        stream: _applicationService.getApplicationStatus(currentUser.uid),
        builder: (context, appSnapshot) {
          if (appSnapshot.connectionState == ConnectionState.waiting && !appSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
            );
          }
          if (appSnapshot.hasError) {
            return _buildSelfieForm();
          }
          final hasApplication = appSnapshot.hasData && appSnapshot.data != null && appSnapshot.data!.exists;
          if (hasApplication) {
            try {
              final application = HostApplicationModel.fromFirestore(appSnapshot.data!);
              final applicationId = appSnapshot.data!.id;
              if (application.isApproved || application.isPending || application.status == HostApplicationStatus.reviewing) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatorApplicationStatusScreen(
                          applicationId: applicationId,
                          phoneNumber: widget.phoneNumber,
                        ),
                      ),
                    );
                  }
                });
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
                );
              }
              if (application.isRejected) {
                return _buildSelfieForm(showRejectedMessage: true, rejectionReason: application.rejectionReason);
              }
            } catch (e) {
              debugPrint('Error parsing application: $e');
            }
          }
          return _buildSelfieForm();
        },
      ),
    );
  }

  Widget _buildSelfieForm({bool showRejectedMessage = false, String? rejectionReason}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        children: [
          if (showRejectedMessage) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: Colors.red, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.applicationRejected,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rejectionReason ?? AppLocalizations.of(context)!.applicationNotApprovedCanReapply,
                          style: TextStyle(fontSize: 12, color: Colors.red[800], height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            'Take a selfie for verification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: GestureDetector(
                    onTap: _selfieFile == null ? null : () {},
                    child: ClipOval(
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        width: 280,
                        height: 280,
                        color: Colors.grey[200],
                        child: _selfieFile != null
                            ? Image.file(
                                _selfieFile!,
                                fit: BoxFit.cover,
                                width: 280,
                                height: 280,
                              )
                            : Image.asset(
                                'assets/images/face-verification.png',
                                width: 280,
                                height: 280,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 280,
                                  height: 280,
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 80,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.38,
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _takeSelfie,
                      icon: const Icon(Icons.camera_alt, size: 20, color: Color(0xFFFF1B7C)),
                      label: const Text('Take selfie', style: TextStyle(color: Color(0xFFFF1B7C), fontWeight: FontWeight.w600, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF1B7C)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 112),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                      activeColor: const Color(0xFFFF1B7C),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, right: 8),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.3),
                            children: [
                              TextSpan(text: '${AppLocalizations.of(context)!.iAcceptThe} '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TermsAndConditionsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.termsConditions,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFF1B7C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(text: ' ${AppLocalizations.of(context)!.andAgreeToPlatformRules}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_selfieFile != null && _termsAccepted && !_isSubmitting)
                        ? _submitApplication
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1B7C),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(context)!.submitApplication,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                  ),
                ),
        ],
      ),
    );
  }
}
