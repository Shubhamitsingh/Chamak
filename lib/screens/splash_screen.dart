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
        print('✅ User already logged in: ${currentUser.phoneNumber}');
        print('👤 User UID: ${currentUser.uid}');
        
        // Minimal delay before navigating (reduced for faster startup)
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                phoneNumber: currentUser.phoneNumber!,
              ),
            ),
          );
        }
      }
      // If not logged in, don't auto-navigate - wait for user to click button
    } catch (e) {
      print('❌ Error checking auth state: $e');
      // On error, just stay on splash screen - user can click button
    }
  }

  void _navigateToLogin() {
    // Navigate to login when user clicks "Continue with Phone" button
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black, // Set black background to prevent cream flash
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black, // Ensure black background before image loads
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/backgroungim.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
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
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // Logo - Full HD Quality
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Error loading logo: $error');
                    print('❌ Stack trace: $stackTrace');
                    // Return a transparent placeholder instead of green icon
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
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
                const SizedBox(height: 30),
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
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToLogin,
                        icon: const Icon(
                          Icons.phone_android,
                          size: 32,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Continue with Phone',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF04B104),
                          foregroundColor: Colors.white,
                          elevation: 8,
                        shadowColor: const Color.fromARGB(255, 237, 237, 240),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                        ),
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
                        color: Colors.white.withOpacity(0.8),
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
      ),
    );
  }
}
