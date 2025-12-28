import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_screen.dart';
import 'home_screen.dart';
import 'set_profile_screen.dart';

class IntroLogoScreen extends StatefulWidget {
  const IntroLogoScreen({super.key});

  @override
  State<IntroLogoScreen> createState() => _IntroLogoScreenState();
}

class _IntroLogoScreenState extends State<IntroLogoScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _typewriterController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<int> _typewriterAnimation;
  
  final String _fullText = "Chamakz";

  @override
  void initState() {
    super.initState();
    
    // Rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutBack,
    );
    
    // Scale/Popup animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    // Typewriter animation for text
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _typewriterAnimation = IntTween(begin: 0, end: _fullText.length).animate(
      CurvedAnimation(parent: _typewriterController, curve: Curves.easeIn),
    );
    
    // Start animations
    _scaleController.forward();
    _rotationController.forward();
    
    // Start typewriter animation after logo appears
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _typewriterController.forward();
    });
    
    _decideNext();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  Future<void> _decideNext() async {
    try {
      // Show logo with animations - reduced delay for faster app startup
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // Check auth state once
      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
      } catch (e) {
        debugPrint('Error getting current user: $e');
        // Fallback: navigate to splash screen
        if (mounted) {
          try {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );
          } catch (navError) {
            debugPrint('Navigation error: $navError');
          }
        }
        return;
      }

      if (currentUser != null && currentUser.phoneNumber != null) {
        // Already logged in → check profile completion
        if (mounted) {
          try {
            // Check if profile is completed
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();
            
            final profileCompleted = userDoc.data()?['profileCompleted'] ?? false;
            final phoneNumber = currentUser.phoneNumber!;
            // Extract country code and phone number
            // Phone format: +919876543210 (country code + phone)
            String countryCode = '+91'; // Default
            String phoneOnly = phoneNumber;
            if (phoneNumber.startsWith('+')) {
              // Try to extract country code (usually 1-3 digits after +)
              final match = RegExp(r'^\+(\d{1,3})(\d+)$').firstMatch(phoneNumber);
              if (match != null) {
                countryCode = '+${match.group(1)}';
                phoneOnly = match.group(2)!;
              }
            }
            
            if (profileCompleted) {
              // Profile completed → Go to Home
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    phoneNumber: phoneNumber,
                  ),
                ),
              );
            } else {
              // Profile not completed → Go to Set Profile
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => SetProfileScreen(
                    phoneNumber: phoneOnly,
                    countryCode: countryCode,
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('Navigation error: $e');
            // Fallback: navigate to splash screen
            if (mounted) {
              try {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                );
              } catch (navError) {
                debugPrint('Fallback navigation error: $navError');
              }
            }
          }
        }
      } else {
        // Not logged in → go to Splash (then user taps Continue to Login)
        if (mounted) {
          try {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );
          } catch (e) {
            debugPrint('Navigation error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _decideNext: $e');
      // Fallback navigation
      if (mounted) {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        } catch (navError) {
          debugPrint('Fallback navigation error: $navError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: Image.asset(
                  'assets/images/pinklogo.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ Error loading logo: $error');
                    debugPrint('❌ Stack trace: $stackTrace');
                    // Return a neutral placeholder instead of green phone icon
                    return Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _typewriterAnimation,
              builder: (context, child) {
                String displayText = _fullText.substring(
                  0,
                  _typewriterAnimation.value.clamp(0, _fullText.length),
                );
                return ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFE91E63), // Pink
                      Color(0xFF9C27B0), // Purple
                      Color(0xFFFFA500), // Orange
                      Color(0xFFFFD700), // Gold
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                );
              },
            ),
            ],
          ),
        ),
    );
  }
}


