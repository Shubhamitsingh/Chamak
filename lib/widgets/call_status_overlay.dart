import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class CallStatusOverlay extends StatelessWidget {
  const CallStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated phone icon with busy indicator
            FadeIn(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing ring
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      // Restart animation
                    },
                  ),
                  // Phone icon container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF9800), // Orange
                          Color(0xFFFF5722), // Deep Orange
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_in_talk,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Message
            FadeIn(
              delay: const Duration(milliseconds: 200),
              child: const Text(
                'Host is Busy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 400),
              child: Text(
                'Host is currently in a private video call.\nPlease wait...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

