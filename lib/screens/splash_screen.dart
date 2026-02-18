import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'email_login_screen.dart';
import 'home_screen.dart';
import 'set_profile_screen.dart';
import '../services/database_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showMoreOptions = false;
  static const String _prefKeyShowMoreOptions = 'splash_show_more_options';

  @override
  void initState() {
    super.initState();
    _loadMoreOptionsState();
    _checkAuthState();
  }

  Future<void> _loadMoreOptionsState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedState = prefs.getBool(_prefKeyShowMoreOptions) ?? false;
      debugPrint('📱 Restoring more options state: $savedState');
      if (mounted) {
        setState(() {
          _showMoreOptions = savedState;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading more options state: $e');
    }
  }

  Future<void> _saveMoreOptionsState(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyShowMoreOptions, value);
      debugPrint('💾 Saved more options state: $value');
    } catch (e) {
      debugPrint('❌ Error saving more options state: $e');
    }
  }

  Future<void> _checkAuthState() async {
    // Check if user is already logged in (only for auto-navigation)
    try {
      // Minimal delay to ensure screen is fully loaded
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // User is logged in - check profile completion
        debugPrint('✅ User already logged in: ${currentUser.uid}');
        debugPrint('👤 User Email: ${currentUser.email}');
        debugPrint('👤 User Phone: ${currentUser.phoneNumber}');
        
        // Minimal delay before navigating (reduced for faster startup)
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (mounted) {
          try {
            // Check if profile is completed
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();
            
            final profileCompleted = userDoc.data()?['profileCompleted'] ?? false;
            final phoneNumber = currentUser.phoneNumber ?? '';
            // Extract country code and phone number
            // Phone format: +919876543210 (country code + phone)
            String countryCode = '+91'; // Default
            String phoneOnly = phoneNumber;
            if (phoneNumber.isNotEmpty && phoneNumber.startsWith('+')) {
              // Try to extract country code (usually 1-3 digits after +)
              final match = RegExp(r'^\+(\d{1,3})(\d+)$').firstMatch(phoneNumber);
              if (match != null) {
                countryCode = '+${match.group(1)}';
                phoneOnly = match.group(2)!;
              }
            }
            
            if (profileCompleted) {
              // Profile completed → Go to Home
              // ✅ FIX: Use pushAndRemoveUntil to clear navigation stack completely
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    userIdentifier: phoneNumber.isNotEmpty ? phoneNumber : (currentUser.email ?? ''),
                  ),
                ),
                (route) => false, // Clear all previous routes - prevent back navigation to auth screens
              );
            } else {
              // Profile not completed → Go to Set Profile
              // ✅ FIX: Use pushAndRemoveUntil to clear navigation stack completely
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => SetProfileScreen(
                    phoneNumber: phoneOnly.isNotEmpty ? phoneOnly : (currentUser.email ?? ''),
                    countryCode: countryCode,
                  ),
                ),
                (route) => false, // Clear all previous routes - prevent back navigation to auth screens
              );
            }
          } catch (e) {
            debugPrint('Navigation error: $e');
            // Stay on splash screen - user can click button
          }
        }
      }
      // If not logged in, don't auto-navigate - wait for user to click button
    } catch (e) {
      debugPrint('❌ Error checking auth state: $e');
      // On error, just stay on splash screen - user can click button
    }
  }

  void _navigateToPhoneLogin() {
    if (!mounted) return;
    
    try {
      // Navigate to phone login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Navigation error in _navigateToPhoneLogin: $e');
    }
  }

  void _navigateToEmailLogin() {
    if (!mounted) return;
    
    try {
      // Navigate to email login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const EmailLoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Navigation error in _navigateToEmailLogin: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    
    try {
      setState(() {
        // Show loading indicator
      });

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) {
          setState(() {});
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null && mounted) {
        debugPrint('✅ Google Sign-In successful: ${user.email}');
        
        // Create or update user in Firestore
        final dbService = DatabaseService();
        try {
          await dbService.createOrUpdateUserWithEmail(
            email: user.email ?? '',
            displayName: user.displayName,
            photoURL: user.photoURL,
          );
          
          if (mounted) {
            // Check if profile is completed
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            
            final profileCompleted = userDoc.data()?['profileCompleted'] ?? false;
            
            if (profileCompleted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    userIdentifier: user.email ?? '',
                  ),
                ),
                (route) => false,
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => SetProfileScreen(
                    phoneNumber: user.email ?? '',
                    countryCode: '',
                  ),
                ),
                (route) => false,
              );
            }
          }
        } catch (e) {
          debugPrint('❌ Error saving user to database: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black, // Set black background to prevent cream flash
      body: Stack(
        children: [
          // Background image with 15% zoom
          Transform.scale(
            scale: 1.15,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/Group-login-image.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          // Content overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.10),
                // Logo - Full HD Quality
                Image.asset(
                  'assets/images/splaslogo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ Error loading logo: $error');
                    debugPrint('❌ Stack trace: $stackTrace');
                    // Return a transparent placeholder instead of green icon
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 72,
                        color: Colors.white70,
                      ),
                    );
                  },
                ),
                SizedBox(height: size.height * 0.08),
                const Text(
                    'Chamakz',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                    'Stream Your Moments',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Google Login Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Semantics(
                      label: 'Continue with Google',
                      button: true,
                      child: ElevatedButton(
                        onPressed: _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Stack(
                          children: [
                            // Centered text in entire container
                            const Center(
                              child: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Google icon at left position
                            Positioned(
                              left: 12,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Image.asset(
                                  'assets/images/google.png',
                                  width: 28,
                                  height: 28,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.g_mobiledata,
                                      size: 28,
                                      color: Colors.black87,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Email Login Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Semantics(
                      label: 'Continue with Email',
                      button: true,
                      child: ElevatedButton(
                        onPressed: _navigateToEmailLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF1B7C),
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Stack(
                          children: [
                            // Centered text in entire container
                            const Center(
                              child: Text(
                                'Continue with Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Email icon at left position
                            Positioned(
                              left: 12,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: const Icon(
                                  Icons.email,
                                  size: 28,
                                  color: Color(0xFFFF1B7C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Simple Arrow Button for More Options
                Center(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _showMoreOptions = !_showMoreOptions;
                      });
                      _saveMoreOptionsState(_showMoreOptions);
                    },
                    icon: Icon(
                      _showMoreOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 32,
                    ),
                    tooltip: _showMoreOptions ? 'Hide Options' : 'More Options',
                  ),
                ),
                // Phone Login Button (shown when expanded)
                if (_showMoreOptions) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Semantics(
                        label: 'Continue with Phone Number',
                        button: true,
                        child: ElevatedButton(
                          onPressed: _navigateToPhoneLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF1B7C),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFFFF1B7C).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Stack(
                            children: [
                              // Centered text in entire container
                              const Center(
                                child: Text(
                                  'Continue with Phone',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Phone icon at left position
                              Positioned(
                                left: 12,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: const Icon(
                                    Icons.phone_android,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                SizedBox(height: size.height * 0.05),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}
