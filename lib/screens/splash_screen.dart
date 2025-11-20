import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Check if user is already logged in (only for auto-navigation)
    try {
      // Minimal delay to ensure screen is fully loaded
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null && currentUser.phoneNumber != null) {
        // User is logged in - navigate to home automatically
        debugPrint('✅ User already logged in: ${currentUser.phoneNumber}');
        debugPrint('👤 User UID: ${currentUser.uid}');
        
        // Minimal delay before navigating (reduced for faster startup)
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (mounted) {
          try {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  phoneNumber: currentUser.phoneNumber!,
                ),
              ),
            );
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

  void _navigateToLogin() {
    if (!mounted) return;
    
    try {
      // Navigate to login when user clicks "Continue with Phone" button
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Navigation error in _navigateToLogin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black, // Set black background to prevent cream flash
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/backgroungim3.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Container(
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
                    'Chamak',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _navigateToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFF9C27B0).withValues(alpha: 0.4),
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
      ),
    );
  }
}
