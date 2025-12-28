import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';

class SetProfileScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const SetProfileScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  State<SetProfileScreen> createState() => _SetProfileScreenState();
}

class _SetProfileScreenState extends State<SetProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  String? _selectedLanguage;
  bool _isReferralExpanded = false;
  bool _isReferralVerified = false;
  bool _isLoading = false;
  bool _isSubmitting = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mother tongue languages (spoken language, NOT app language)
  final List<String> _languages = [
    'Hindi',
    'English',
    'Bengali',
    'Telugu',
    'Marathi',
    'Tamil',
    'Gujarati',
    'Kannada',
    'Odia',
    'Malayalam',
    'Punjabi',
    'Assamese',
    'Maithili',
    'Sanskrit',
    'Konkani',
    'Nepali',
    'Sindhi',
    'Dogri',
    'Kashmiri',
    'Manipuri',
    'Santali',
    'Bodo',
    'Other',
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  // Validate nickname
  String? _validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nick-name is required';
    }
    if (value.trim().length < 3) {
      return 'Nick-name must be at least 3 characters';
    }
    if (value.length > 20) {
      return 'Nick-name must be maximum 20 characters';
    }
    // Allow all characters - no restriction
    return null;
  }

  // Validate age (18+ and max 100)
  bool _isValidAge(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    int age = now.year - date.year;
    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
      age--;
    }
    if (age < 18) return false;
    if (age > 100) return false;
    return true;
  }

  // Show gender selection bottom sheet
  void _showGenderBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Gender',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            // Horizontal Gender Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  // Male Container - Blue
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGender = 'Male';
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2196F3),
                            width: _selectedGender == 'Male' ? 2 : 1,
                          ),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.male,
                              color: Color(0xFF2196F3),
                              size: 36,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Male',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Female Container - Pink
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGender = 'Female';
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE91E63),
                            width: _selectedGender == 'Female' ? 2 : 1,
                          ),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.female,
                              color: Color(0xFFE91E63),
                              size: 36,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Female',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Show language selection bottom sheet (Mother Tongue)
  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select Mother Tongue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = _selectedLanguage == lang;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFFFF1744).withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          lang.isNotEmpty ? lang.substring(0, 1) : '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? const Color(0xFFFF1744)
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      lang,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? const Color(0xFFFF1744) : Colors.black87,
                      ),
                    ),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: Color(0xFFFF1744))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLanguage = lang;
                      });
                      Navigator.pop(dialogContext);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Show date picker
  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF1744),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  // Verify referral code
  Future<void> _verifyReferralCode() async {
    final code = _referralCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showErrorSnackBar('Please enter referral code');
      return;
    }
    if (code.length < 6 || code.length > 8) {
      _showErrorSnackBar('Referral code must be 6-8 characters');
      return;
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
      _showErrorSnackBar('Referral code must be alphanumeric');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement actual referral code verification API
    // For now, simulate verification
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _isReferralVerified = true;
    });

    _showSuccessSnackBar('Referral code verified');
  }

  // Check if form is valid
  bool _isFormValid() {
    final nicknameNotEmpty = _nicknameController.text.isNotEmpty;
    final genderSelected = _selectedGender != null;
    final dobSelected = _selectedDateOfBirth != null;
    final languageSelected = _selectedLanguage != null;
    final nicknameValid = _validateNickname(_nicknameController.text) == null;
    final ageValid = _isValidAge(_selectedDateOfBirth);
    
    // Debug: uncomment to see validation status
    // debugPrint('Form validation: nickname=$nicknameNotEmpty, gender=$genderSelected, dob=$dobSelected, language=$languageSelected, nicknameValid=$nicknameValid, ageValid=$ageValid');
    
    return nicknameNotEmpty &&
        genderSelected &&
        dobSelected &&
        languageSelected &&
        nicknameValid &&
        ageValid;
  }

  // Submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isFormValid()) {
      _showErrorSnackBar('Please fill all required fields correctly');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _showErrorSnackBar('User not authenticated');
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Format date of birth and calculate age
      final dobFormatted = DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!);
      final now = DateTime.now();
      int age = now.year - _selectedDateOfBirth!.year;
      if (now.month < _selectedDateOfBirth!.month || 
          (now.month == _selectedDateOfBirth!.month && now.day < _selectedDateOfBirth!.day)) {
        age--;
      }

      // Update user profile in Firestore
      // Note: 'language' is mother tongue (spoken language), NOT app UI language
      // App language is controlled from Settings and defaults to English
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'displayName': _nicknameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': dobFormatted,
        'age': age, // Also save calculated age for edit_profile_screen
        'language': _selectedLanguage, // Mother tongue
        'referralCode': _referralCodeController.text.trim().toUpperCase().isNotEmpty
            ? _referralCodeController.text.trim().toUpperCase()
            : null,
        'profileCompleted': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            phoneNumber: '${widget.countryCode}${widget.phoneNumber}',
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to save profile. Please try again.');
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF04B104),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation - this screen is mandatory
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Title - compact at top
                        const Text(
                          'Set Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 20),

                      // Field 1: Nick-name
                      TextFormField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          hintText: 'Nick-name',
                          hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF1744), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: _validateNickname,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Field 2: Gender
                      GestureDetector(
                        onTap: _showGenderBottomSheet,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedGender ?? 'Who are you?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedGender != null
                                      ? Colors.black87
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                              const Text(
                                'Select',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFF1744),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 3: Date of Birth
                      GestureDetector(
                        onTap: _selectDateOfBirth,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDateOfBirth != null
                                    ? DateFormat('dd MMM yyyy').format(_selectedDateOfBirth!)
                                    : 'Date of Birth',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDateOfBirth != null
                                      ? Colors.black87
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                              const Text('🎂', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedDateOfBirth != null && !_isValidAge(_selectedDateOfBirth))
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 16),
                          child: Text(
                            'You must be 18+ years old',
                            style: TextStyle(color: Colors.red[700], fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Field 4: Language Selection
                      GestureDetector(
                        onTap: _showLanguageBottomSheet,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedLanguage ?? 'Mother Tongue',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedLanguage != null
                                      ? Colors.black87
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                              const Text(
                                'Select',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFF1744),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Field 5: Referral Code (Optional)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isReferralExpanded = !_isReferralExpanded;
                          });
                        },
                        child: Text(
                          'I have referral code',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFF1744),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_isReferralExpanded) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _referralCodeController,
                                decoration: InputDecoration(
                                  hintText: 'Enter referral code',
                                  hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFFF1744), width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                style: const TextStyle(fontSize: 16),
                                textCapitalization: TextCapitalization.characters,
                                onChanged: (value) {
                                  setState(() {
                                    _isReferralVerified = false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            _isLoading
                                ? const SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _isReferralVerified
                                    ? Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF04B104),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white),
                                      )
                                    : ElevatedButton(
                                        onPressed: _verifyReferralCode,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF1744),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(56, 56),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Verify'),
                                      ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isFormValid() && !_isSubmitting ? _submitForm : null,
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: _isFormValid()
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFF1744), Color(0xFFFF5252)],
                                    )
                                  : null,
                              color: _isFormValid() ? null : const Color(0xFFBDBDBD),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: _isFormValid()
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF1744).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Terms Text
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                        children: [
                          const TextSpan(text: 'By proceeding I accept the '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsConditionsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Community Guidelines',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ', '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Terms of use',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
      ),
    );
  }
}

