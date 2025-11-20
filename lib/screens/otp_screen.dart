import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'home_screen.dart';
import '../services/database_service.dart';
import '../generated/l10n/app_localizations.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _secondsRemaining = 30;
  Timer? _timer;
  late String _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length < 6) {
      _showErrorSnackBar(AppLocalizations.of(context)!.pleaseEnterCompleteOTP);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔐 Verifying OTP: ${_otpController.text}');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );
      
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      debugPrint('✅ OTP verified successfully!');
      debugPrint('👤 User ID: ${userCredential.user?.uid}');
      
      // Create or update user in Firestore
      debugPrint('💾 Saving user to database...');
      debugPrint('📱 Phone: ${widget.countryCode}${widget.phoneNumber}');
      debugPrint('👤 User UID: ${userCredential.user?.uid}');
      
      try {
      final dbService = DatabaseService();
      await dbService.createOrUpdateUser(
        phoneNumber: widget.phoneNumber,
        countryCode: widget.countryCode,
      );
      debugPrint('✅ User saved to database successfully!');
      } catch (dbError) {
        debugPrint('❌ Database save error: $dbError');
        debugPrint('❌ Error details: ${dbError.runtimeType}');
        // Continue to home screen even if database save fails
        // User is authenticated, just database save failed
      }

      if (!mounted) return;
      _showSuccessSnackBar('Login successful!');
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      try {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              phoneNumber: '${widget.countryCode}${widget.phoneNumber}',
            ),
          ),
        );
      } catch (e) {
        debugPrint('Navigation error: $e');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase OTP verification failed: ${e.code} - ${e.message}');
      if (!mounted) return;
      
      String errorMessage = 'Invalid OTP';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid OTP code. Please check and try again';
      } else if (e.code == 'session-expired') {
        errorMessage = 'OTP expired. Please request a new one';
      } else if (e.code == 'code-expired') {
        errorMessage = 'OTP has expired. Please resend';
      } else if (e.code == 'invalid-verification-id') {
        errorMessage = 'Verification session invalid. Please restart';
      } else if (e.message != null) {
        errorMessage = 'Error: ${e.message}';
      }
      
      _showErrorSnackBar(errorMessage);
      _otpController.clear();
    } on Exception catch (e) {
      debugPrint('❌ Database or other error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (!mounted) return;
      _showErrorSnackBar('Database error: ${e.toString()}');
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error during OTP verification: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (!mounted) return;
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() { _isLoading = true; });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '${widget.countryCode}${widget.phoneNumber}',
        forceResendingToken: _resendToken,
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            
            // Save user to database if auto-verified
            try {
              final dbService = DatabaseService();
              await dbService.createOrUpdateUser(
                phoneNumber: widget.phoneNumber,
                countryCode: widget.countryCode,
              );
              debugPrint('✅ Auto-verified and saved to database');
            } catch (dbError) {
              debugPrint('❌ Database error in auto-verification: $dbError');
              // Continue even if database save fails
            }
            
            // Navigate to home
            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                try {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        phoneNumber: '${widget.countryCode}${widget.phoneNumber}',
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint('Navigation error in auto-verification: $e');
                }
              }
            }
          } catch (e) {
            debugPrint('❌ Error in auto-verification: $e');
            if (mounted) {
              _showErrorSnackBar('Auto-verification failed');
              if (mounted) {
                setState(() { _isLoading = false; });
              }
            }
          }
        },
        verificationFailed: (e) {
          debugPrint('❌ Resend verification failed: ${e.message}');
          if (!mounted) return;
          _showErrorSnackBar('Failed to resend OTP: ${e.message ?? 'Unknown error'}');
          if (mounted) {
            setState(() { _isLoading = false; });
          }
        },
        codeSent: (newVerificationId, newResendToken) {
          if (mounted) {
            setState(() {
              _verificationId = newVerificationId;
              _resendToken = newResendToken;
            });
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
      if (mounted) {
        _showSuccessSnackBar('OTP resent successfully!');
        _startTimer();
        _otpController.clear();
      }
    } catch (_) {} finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF04B104),
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
    final size = MediaQuery.of(context).size;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF04B104), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04B104).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFF04B104).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF04B104)),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            try {
              Navigator.of(context).pop();
            } catch (e) {
              debugPrint('Error navigating back: $e');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.02),

                // Logo - Full HD Quality
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ Error loading logo: $error');
                      debugPrint('❌ Stack trace: $stackTrace');
                      // Return a neutral placeholder instead of green phone icon
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Title
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'We have sent a verification code to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    '${widget.countryCode} ${widget.phoneNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF04B104),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Change Number
                FadeInDown(
                  delay: const Duration(milliseconds: 500),
                  child: TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            try {
                              Navigator.of(context).pop();
                            } catch (e) {
                              debugPrint('Error navigating back: $e');
                            }
                          },
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.grey,
                    ),
                    label: const Text(
                      'Change Phone Number',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // OTP Input
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Pinput(
                    controller: _otpController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    enabled: !_isLoading,
                    onCompleted: (pin) {
                      // Auto-verify when all 6 digits are entered
                      _verifyOTP();
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),

                const SizedBox(height: 30),

                // Timer / Resend
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _canResend
                            ? "Didn't receive the code?"
                            : 'Resend OTP in $_secondsRemaining seconds',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_canResend) ...[
                        const SizedBox(width: 5),
                        TextButton(
                          onPressed: _isLoading ? null : _resendOTP,
                          child: const Text(
                            'Resend',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF04B104),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Verify Button at Bottom
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0), // #9C27B0
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF9C27B0).withValues(alpha: 0.4), // #9C27B0 shadow
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}







