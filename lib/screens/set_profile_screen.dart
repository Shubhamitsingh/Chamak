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
  
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  String? _selectedLanguage;
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
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      helpText: 'Select Date of Birth',
      cancelText: 'CANCEL',
      confirmText: 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF1744), // Pink/Red primary color
              onPrimary: Colors.white, // White text on primary
              onSurface: Colors.black87, // Dark text on surface
              surface: Colors.white, // White background
              secondary: Color(0xFFFF1744), // Secondary color for selection
              onSecondary: Colors.white, // White text on secondary
              error: Color(0xFFFF1744), // Error color
            ),
            dialogBackgroundColor: Colors.white,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: const Color(0xFFFF1744), // Pink header
              headerForegroundColor: Colors.white, // White text in header
              headerHeadlineStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              headerHelpStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              dayStyle: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
              weekdayStyle: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              yearStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF1744), // Pink cancel text
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF1744), // Pink confirm text
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                        const SizedBox(height: 20),
                        // Title - compact at top
                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please fill in your details to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 32),

                      // Field 1: Nick-name
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            hintText: 'Nick-name',
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          validator: _validateNickname,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 2: Gender
                      GestureDetector(
                        onTap: _showGenderBottomSheet,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: _selectedGender != null
                                          ? const Color(0xFFFF1B7C)
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        _selectedGender ?? 'Select Gender',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                          color: _selectedGender != null
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: _selectedGender != null
                                    ? const Color(0xFFFF1B7C)
                                    : Colors.grey[600],
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
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 20,
                                      color: _selectedDateOfBirth != null
                                          ? const Color(0xFFFF1B7C)
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        _selectedDateOfBirth != null
                                            ? DateFormat('dd MMM yyyy').format(_selectedDateOfBirth!)
                                            : 'Date of Birth',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                          color: _selectedDateOfBirth != null
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: _selectedDateOfBirth != null
                                    ? const Color(0xFFFF1B7C)
                                    : Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedDateOfBirth != null && !_isValidAge(_selectedDateOfBirth))
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 16),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                              const SizedBox(width: 6),
                              Text(
                                'You must be 18+ years old',
                                style: TextStyle(color: Colors.red[700], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Field 4: Language Selection
                      GestureDetector(
                        onTap: _showLanguageBottomSheet,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.language_outlined,
                                      size: 20,
                                      color: _selectedLanguage != null
                                          ? const Color(0xFFFF1B7C)
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        _selectedLanguage ?? 'Select Mother Tongue',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                          color: _selectedLanguage != null
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: _selectedLanguage != null
                                    ? const Color(0xFFFF1B7C)
                                    : Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Submit Button at Bottom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isFormValid() && !_isSubmitting ? _submitForm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1B7C), // Pink
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: 8,
                      shadowColor: const Color(0xFFFF1B7C).withValues(alpha: 0.4), // Pink shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Terms Text at Bottom
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'By continuing, you agree to our ',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsConditionsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Terms',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF04B104),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ' & ',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF04B104),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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
}

