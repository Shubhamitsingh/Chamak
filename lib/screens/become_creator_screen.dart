import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/host_application_service.dart';
import '../services/database_service.dart';
import '../services/id_generator_service.dart';
import '../models/user_model.dart';
import 'terms_and_conditions_screen.dart';

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
  final _formKey = GlobalKey<FormState>();
  final HostApplicationService _applicationService = HostApplicationService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  // State variables
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _termsAccepted = false;
  DateTime? _selectedDateOfBirth;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final userData = await _databaseService.getUserData(currentUser.uid);
      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 100); // 100 years ago
    final DateTime lastDate = DateTime(now.year - 18); // Must be 18+

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF1B7C),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }


  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verify age (must be 18+)
    final age = DateTime.now().difference(_selectedDateOfBirth!).inDays ~/ 365;
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be at least 18 years old to become a creator'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare social media links
      Map<String, String>? socialMediaLinks;
      if (_instagramController.text.isNotEmpty ||
          _tiktokController.text.isNotEmpty ||
          _youtubeController.text.isNotEmpty) {
        socialMediaLinks = {};
        if (_instagramController.text.isNotEmpty) {
          socialMediaLinks['instagram'] = _instagramController.text.trim();
        }
        if (_tiktokController.text.isNotEmpty) {
          socialMediaLinks['tiktok'] = _tiktokController.text.trim();
        }
        if (_youtubeController.text.isNotEmpty) {
          socialMediaLinks['youtube'] = _youtubeController.text.trim();
        }
      }

      // Submit application
      final applicationId = await _applicationService.submitApplication(
        userId: currentUser.uid,
        userDisplayId: IdGeneratorService.getDisplayId(_currentUser!.numericUserId),
        username: _currentUser!.displayName ?? 'User',
        phoneNumber: _currentUser!.phoneNumber,
        dateOfBirth: _selectedDateOfBirth!,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        bio: '',
        socialMediaLinks: socialMediaLinks,
        profilePhotoUrl: null,
        termsAccepted: _termsAccepted,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (applicationId != null) {
          // Show success dialog
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit application. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error submitting application: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon with dark blue background
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E3A8A), // Dark blue
                            Color(0xFF3B82F6), // Medium blue
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      'Application Submitted!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A), // Dark blue
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      'Your application has been submitted successfully and is now under review. We will notify you once it has been processed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                        letterSpacing: 0.1,
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // OK Button with dark blue gradient
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Go back to profile
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A), // Dark blue
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF1B7C),
          ),
        ),
      );
    }

    if (_currentUser == null) {
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
        body: const Center(
          child: Text('Error loading user data'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),

              // User ID (Read-only)
              _buildReadOnlyField(
                label: 'User ID',
                value: IdGeneratorService.getDisplayId(_currentUser!.numericUserId),
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 10),

              // Username (Read-only)
              _buildReadOnlyField(
                label: 'Username',
                value: _currentUser!.displayName ?? 'Not set',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 10),

              // Phone Number (Read-only)
              _buildReadOnlyField(
                label: 'Phone Number',
                value: _currentUser!.phoneNumber,
                icon: Icons.phone_outlined,
              ),

              const SizedBox(height: 10),

              // Date of Birth
              GestureDetector(
                      onTap: _selectDateOfBirth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedDateOfBirth == null
                                ? Colors.grey[300]!
                                : const Color(0xFFFF1B7C),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFFFF1B7C),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date of Birth',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedDateOfBirth != null
                                        ? DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!)
                                        : 'Select your date of birth',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedDateOfBirth != null
                                          ? Colors.black87
                                          : Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 10),

              // Email (Optional)
              TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email (Optional)',
                        hintText: 'your@email.com',
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF1B7C), size: 20),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
              ),

              const SizedBox(height: 14),

              // Social Media Links (Optional)
              const Text(
                'Social Media Links (Optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Instagram
              TextFormField(
                      controller: _instagramController,
                      decoration: InputDecoration(
                        labelText: 'Instagram',
                        hintText: '@username',
                        prefixIcon: const Icon(Icons.camera_alt_outlined, color: Color(0xFFFF1B7C), size: 20),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
                        ),
                      ),
              ),

              const SizedBox(height: 8),

              // TikTok
              TextFormField(
                      controller: _tiktokController,
                      decoration: InputDecoration(
                        labelText: 'TikTok',
                        hintText: '@username',
                        prefixIcon: const Icon(Icons.music_note_outlined, color: Color(0xFFFF1B7C), size: 20),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
                        ),
                      ),
              ),

              const SizedBox(height: 8),

              // YouTube
              TextFormField(
                      controller: _youtubeController,
                      decoration: InputDecoration(
                        labelText: 'YouTube',
                        hintText: 'Channel URL',
                        prefixIcon: const Icon(Icons.play_circle_outline, color: Color(0xFFFF1B7C), size: 20),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
                        ),
                      ),
              ),

              const SizedBox(height: 14),

              // Benefits Section
              const Text(
                'Benefits of Becoming a Creator',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Earn 100% of your earnings\n'
                '• No middleman, no commission\n'
                '• Direct approval process\n'
                '• Start streaming immediately\n'
                '• No Broker • Full Earnings',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              // Terms & Conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFFFF1B7C),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        children: [
                          Text(
                            'I accept the ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TermsAndConditionsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFFFF1B7C),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Text(
                            ' and agree to the platform rules',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Submit Button
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.70, // 70% of screen width
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1B7C),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFFFF1B7C).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Application',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}