import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_screen.dart';
import 'splash_screen.dart';
import '../generated/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';
  
  bool _isLoading = false;
  int _digitCount = 0;

  // Available countries
  final List<Map<String, String>> _countries = [
    {'flag': '🇮🇳', 'name': 'India', 'code': '+91'},
    {'flag': '🇺🇸', 'name': 'USA', 'code': '+1'},
    {'flag': '🇬🇧', 'name': 'UK', 'code': '+44'},
    {'flag': '🇨🇦', 'name': 'Canada', 'code': '+1'},
    {'flag': '🇦🇺', 'name': 'Australia', 'code': '+61'},
    {'flag': '🇦🇪', 'name': 'UAE', 'code': '+971'},
    {'flag': '🇸🇬', 'name': 'Singapore', 'code': '+65'},
    {'flag': '🇲🇾', 'name': 'Malaysia', 'code': '+60'},
    {'flag': '🇵🇰', 'name': 'Pakistan', 'code': '+92'},
    {'flag': '🇧🇩', 'name': 'Bangladesh', 'code': '+880'},
  ];

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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Country',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    return ListTile(
                      leading: Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        country['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        country['code']!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = country['code']!;
                          _selectedCountryFlag = country['flag']!;
                        });
                        try {
                          Navigator.pop(context);
                        } catch (e) {
                          debugPrint('Error closing country picker: $e');
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
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
      _showErrorSnackBar(AppLocalizations.of(context)!.pleaseEnterYourMobileNumber);
      return;
    }

    if (!_isValidPhoneNumber(_phoneController.text)) {
      _showErrorSnackBar(AppLocalizations.of(context)!.pleaseEnterValidMobileNumber);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String rawNumber = _phoneController.text;
    final String fullNumber = '$_selectedCountryCode$rawNumber';

    debugPrint('📱 Starting Phone Auth for: $fullNumber');

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
                    countryCode: _selectedCountryCode,
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Terms & Conditions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Welcome to Chamak!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '1. By using this app, you agree to our terms and conditions.\n\n'
                  '2. We collect and use your phone number for authentication purposes.\n\n'
                  '3. Your data will be kept secure and confidential.\n\n'
                  '4. You must be 13 years or older to use this service.\n\n'
                  '5. We reserve the right to modify these terms at any time.\n\n'
                  '6. You are responsible for maintaining the confidentiality of your account.\n\n'
                  '7. We do not share your personal information with third parties without consent.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                try {
                  Navigator.of(context).pop();
                } catch (e) {
                  debugPrint('Error closing dialog: $e');
                }
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF04B104),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '1. We collect only necessary information to provide our services.\n\n'
                  '2. Your phone number is used solely for authentication.\n\n'
                  '3. We use industry-standard security measures.\n\n'
                  '4. Your data is stored securely and encrypted.\n\n'
                  '5. We do not sell your personal information.\n\n'
                  '6. You can request data deletion at any time.\n\n'
                  '7. We comply with applicable data protection laws.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF736EFE),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
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
                                  _selectedCountryFlag,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _selectedCountryCode,
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
                    onTap: _showTermsDialog,
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
                    onTap: _showPrivacyDialog,
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
