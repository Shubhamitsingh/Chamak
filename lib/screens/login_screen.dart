import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_picker/country_picker.dart';
import 'otp_screen.dart';
import 'splash_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import '../generated/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  
  Country _selectedCountry = Country.parse('IN'); // Default to India
  
  bool _isLoading = false;
  int _digitCount = 0;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _digitCount = _phoneController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      favorite: ['IN', 'US', 'GB', 'CA', 'AU', 'AE', 'SG', 'MY', 'PK', 'BD'],
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        searchTextStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF9C27B0),
              width: 2,
            ),
          ),
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  // Validate phone number format
  bool _isValidPhoneNumber(String phone) {
    if (phone.isEmpty || phone.length != 10) {
      return false;
    }
    
    // Check if all digits are the same (e.g., 1111111111, 0000000000)
    if (phone.split('').toSet().length == 1) {
      return false;
    }
    
    // Check for sequential numbers (e.g., 1234567890, 0123456789)
    if (phone == '1234567890' || phone == '0123456789' || phone == '9876543210') {
      return false;
    }
    
    // Check if it starts with 0 (invalid for most countries)
    if (phone.startsWith('0')) {
      return false;
    }
    
    // Check if it's all numeric
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return false;
    }
    
    return true;
  }

  void _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context)?.pleaseEnterYourMobileNumber ?? 'Please enter your mobile number');
      return;
    }

    if (!_isValidPhoneNumber(_phoneController.text)) {
      _showErrorSnackBar(AppLocalizations.of(context)?.pleaseEnterValidMobileNumber ?? 'Please enter a valid mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Clean phone number: remove spaces, dashes, parentheses, and other non-digit characters
    String rawNumber = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    
    // Remove any non-digit characters (extra safety)
    rawNumber = rawNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Remove leading zero if present (Indian numbers shouldn't start with 0 in E.164)
    while (rawNumber.startsWith('0') && rawNumber.length > 1) {
      rawNumber = rawNumber.substring(1);
    }
    
    // Validate cleaned number length (Indian numbers should be 10 digits)
    if (rawNumber.length != 10) {
      _showErrorSnackBar('Please enter a valid 10-digit phone number');
      setState(() { _isLoading = false; });
      return;
    }
    
    // E.164 format: +[country code][subscriber number]
    // Example: +919876543210
    final String fullNumber = '+${_selectedCountry.phoneCode}$rawNumber';

    debugPrint('📱 Phone Number Details:');
    debugPrint('   Country: ${_selectedCountry.name}');
    debugPrint('   Country Code: +${_selectedCountry.phoneCode}');
    debugPrint('   Raw Number (cleaned): $rawNumber');
    debugPrint('   Full E.164 Format: $fullNumber');
    debugPrint('   E.164 Length: ${fullNumber.length} (should be 13 for India: +91 + 10 digits)');

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Verification completed automatically');
          // Auto-retrieval or instant verification
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            _showSuccessSnackBar('Verified automatically');
          } catch (e) {
            debugPrint('❌ Auto-verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
          if (!mounted) return;
          
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = '⚠️ SMS Quota Exceeded!\n\nUpgrade to Firebase Blaze Plan to send OTPs to real numbers.\n\nFor testing, add test numbers in Firebase Console → Authentication → Phone.';
          } else if (e.code == 'billing-not-enabled' || e.code == 'BILLING_NOT_ENABLED') {
            errorMessage = '⚠️ Billing Required!\n\nReal phone numbers need Firebase Blaze Plan.\n\nYou can:\n1. Upgrade to Blaze Plan (free tier available)\n2. Use test phone numbers for development';
          } else if (e.message != null && (e.message!.contains('quota') || e.message!.contains('billing') || e.message!.contains('Blaze'))) {
            errorMessage = '⚠️ Firebase Plan Issue!\n\nReal phone OTPs need Blaze Plan.\n\nUpgrade at: console.firebase.google.com\n\nOr add test numbers in Firebase Console → Authentication → Phone';
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
          
          _showErrorSnackBar(errorMessage);
          if (mounted) {
            setState(() { _isLoading = false; });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ OTP sent successfully! Verification ID: $verificationId');
          if (!mounted) return;
          if (mounted) {
            setState(() { _isLoading = false; });
          }
          _showSuccessSnackBar('OTP sent to $fullNumber');
          if (mounted) {
            try {
              Navigator.push(
                context,
                MaterialPageRoute(
                      builder: (context) => OtpScreen(
                    phoneNumber: rawNumber,
                    countryCode: '+${_selectedCountry.phoneCode}',
                    verificationId: verificationId,
                    resendToken: resendToken,
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Navigation error: $e');
            }
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏱️ Auto-retrieval timeout: $verificationId');
          if (!mounted) return;
          if (mounted) {
            setState(() { _isLoading = false; });
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Exception in verifyPhoneNumber: $e');
      if (!mounted) return;
      _showErrorSnackBar('Failed to start verification: $e');
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF9C27B0), // Purple
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              if (!mounted) return;
              try {
                // Navigate back to splash screen instead of pop
                // This prevents black screen when there's no route in stack
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const SplashScreen(),
                  ),
                );
              } catch (e) {
                debugPrint('Navigation error: $e');
              }
            },
          ),
        ),
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // Title
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: const Text(
                  'Phone Number Login',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Subtitle
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Simple, fast, and safe',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
                
                // Mobile Number Box with Country Selector
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    child: Row(
                      children: [
                        // Country Selector
                        InkWell(
                          onTap: _showCountryPicker,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Text(
                                  _selectedCountry.flagEmoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '+${_selectedCountry.phoneCode}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 5),
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey[300],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Phone Number Input
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_isLoading,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Mobile Number',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 14,
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Digit Counter
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Row(
                      children: [
                        Icon(
                          _digitCount >= 10
                              ? Icons.check_circle
                              : Icons.info_outline,
                          size: 16,
                          color: _digitCount >= 10
                              ? const Color(0xFF9C27B0) // Purple
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$_digitCount digits entered',
                          style: TextStyle(
                            fontSize: 13,
                            color: _digitCount >= 10
                                ? const Color(0xFF9C27B0) // Purple
                                : Colors.grey[600],
                            fontWeight: _digitCount >= 10
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (_digitCount >= 10 && _digitCount < 15)
                          Text(
                            ' ✓',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9C27B0), // Purple
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Send OTP Button at Bottom
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 600),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0), // #9C27B0
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 8,
                  shadowColor: const Color(0xFF9C27B0).withValues(alpha: 0.4), // #9C27B0 shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Send OTP',
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
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 700),
            child: Center(
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
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsConditionsScreen(),
                          ),
                        );
                      } catch (e) {
                        debugPrint('Error navigating to terms & conditions: $e');
                      }
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
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      } catch (e) {
                        debugPrint('Error navigating to privacy policy: $e');
                      }
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
          ),
        ],
      ),
    ),
  ),
      ),
    );
  }
}
