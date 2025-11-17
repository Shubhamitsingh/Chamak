import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'splash_screen.dart';
import 'home_screen.dart';

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
  
  final String _fullText = "Chamak";

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
    // Show logo with animations - reduced delay for faster app startup
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check auth state once
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.phoneNumber != null) {
      // Already logged in → go straight to Home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              phoneNumber: currentUser.phoneNumber!,
            ),
          ),
        );
      }
    } else {
      // Not logged in → go to Splash (then user taps Continue to Login)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white, // Explicitly set container color to prevent flash
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Error loading logo: $error');
                    print('❌ Stack trace: $stackTrace');
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
                String displayText = _fullText.substring(0, _typewriterAnimation.value);
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
      ),
    );
  }
}


