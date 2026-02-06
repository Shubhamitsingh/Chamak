import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import '../theme/app_colors.dart';

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
  String? _selectedLanguage;
  bool _isSubmitting = false;
  String? _nicknameError; // Store validation error

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

  // Update nickname error on change
  void _updateNicknameError() {
    final error = _validateNickname(_nicknameController.text);
    setState(() {
      _nicknameError = error;
    });
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
                  fontWeight: FontWeight.w700,
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
                            ? AppColors.secondaryAlt.withOpacity(0.1)
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
                                ? AppColors.secondaryAlt
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      lang,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.secondaryAlt : Colors.black87,
                      ),
                    ),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: AppColors.secondaryAlt)
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


  // Check if form is valid
  bool _isFormValid() {
    final nicknameNotEmpty = _nicknameController.text.isNotEmpty;
    final genderSelected = _selectedGender != null;
    final languageSelected = _selectedLanguage != null;
    final nicknameValid = _validateNickname(_nicknameController.text) == null;
    
    return nicknameNotEmpty &&
        genderSelected &&
        languageSelected &&
        nicknameValid;
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

      // Create or update user profile in Firestore
      // Note: 'language' is mother tongue (spoken language), NOT app UI language
      // App language is controlled from Settings and defaults to English
      // Using set() with merge: true to handle both new user creation and existing user updates
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'displayName': _nicknameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'gender': _selectedGender,
        'language': _selectedLanguage, // Mother tongue
        'profileCompleted': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          validator: _validateNickname,
                          onChanged: (_) {
                            _updateNicknameError();
                            setState(() {});
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ),
                      // Character counter and error message
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Error message
                            if (_nicknameError != null)
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, 
                                      size: 16, 
                                      color: Colors.red[700]),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _nicknameError!,
                                        style: TextStyle(
                                          color: Colors.red[700], 
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const Spacer(),
                            // Character counter
                            Text(
                              '${_nicknameController.text.length}/20',
                              style: TextStyle(
                                fontSize: 12,
                                color: _nicknameController.text.length > 20 
                                    ? Colors.red[700]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 2: Gender - Inline Dropdown Style
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Gender',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
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
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Male Option
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedGender = 'Male';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _selectedGender == 'Male'
                                            ? const Color(0xFF2196F3).withOpacity(0.15)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedGender == 'Male'
                                              ? const Color(0xFF2196F3)
                                              : Colors.grey[300]!,
                                          width: _selectedGender == 'Male' ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.male,
                                            color: _selectedGender == 'Male'
                                                ? const Color(0xFF2196F3)
                                                : Colors.grey[600],
                                            size: 40,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Male',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: _selectedGender == 'Male'
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: _selectedGender == 'Male'
                                                  ? const Color(0xFF2196F3)
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Female Option
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedGender = 'Female';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _selectedGender == 'Female'
                                            ? AppColors.secondaryPink.withOpacity(0.15)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedGender == 'Female'
                                              ? AppColors.secondaryPink
                                              : Colors.grey[300]!,
                                          width: _selectedGender == 'Female' ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.female,
                                            color: _selectedGender == 'Female'
                                                ? AppColors.secondaryPink
                                                : Colors.grey[600],
                                            size: 40,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Female',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: _selectedGender == 'Female'
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: _selectedGender == 'Female'
                                                  ? AppColors.secondaryPink
                                                  : Colors.grey[700],
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
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Field 3: Language Selection
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
                                          ? AppColors.secondary
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        _selectedLanguage ?? 'Select Mother Tongue',
                                        style: TextStyle(
                                          fontSize: 16,
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
                                    ? AppColors.secondary
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
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: 8,
                      shadowColor: AppColors.secondary.withValues(alpha: 0.4),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'By continuing, you agree to our ',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
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
                        child: Text(
                          'Terms',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        ' & ',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
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
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
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

