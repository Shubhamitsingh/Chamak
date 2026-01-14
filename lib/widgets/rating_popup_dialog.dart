import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modern Play Store rating popup dialog
class RatingPopupDialog extends StatefulWidget {
  final VoidCallback? onRated;
  final VoidCallback? onClosed;

  const RatingPopupDialog({
    super.key,
    this.onRated,
    this.onClosed,
  });

  @override
  State<RatingPopupDialog> createState() => _RatingPopupDialogState();
}

class _RatingPopupDialogState extends State<RatingPopupDialog>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _buttonController;
  late AnimationController _buttonTextController;
  late AnimationController _sparkleController1;
  late AnimationController _sparkleController2;
  late AnimationController _sparkleController3;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _buttonOpacityAnimation;
  late Animation<Offset> _buttonTextSlideAnimation;
  late Animation<double> _sparkleAnimation1;
  late Animation<double> _sparkleAnimation2;
  late Animation<double> _sparkleAnimation3;

  /// Play Store URL for the app
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.chamakz.app';

  @override
  void initState() {
    super.initState();
    // Rotation animation for star icon
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Button slide up animation (inside container)
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Start slightly down inside container
      end: Offset.zero, // End at normal position
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeOut,
      ),
    );

    _buttonOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeOut,
      ),
    );

    // Button text animation (inside button)
    _buttonTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _buttonTextSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Start below
      end: Offset.zero, // End at normal position
    ).animate(
      CurvedAnimation(
        parent: _buttonTextController,
        curve: Curves.easeOut,
      ),
    );

    // Sparkle animations (fade in/out)
    _sparkleController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _sparkleController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    
    _sparkleController3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _sparkleAnimation1 = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController1, curve: Curves.easeInOut),
    );
    
    _sparkleAnimation2 = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _sparkleController2, curve: Curves.easeInOut),
    );
    
    _sparkleAnimation3 = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _sparkleController3, curve: Curves.easeInOut),
    );

    // Start button animation
    _buttonController.forward();
    
    // Start button text animation with delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _buttonTextController.forward();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _buttonController.dispose();
    _buttonTextController.dispose();
    _sparkleController1.dispose();
    _sparkleController2.dispose();
    _sparkleController3.dispose();
    super.dispose();
  }

  /// Open Play Store rating page
  Future<void> _openPlayStore() async {
    try {
      final uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        // Callback to mark user as rated
        widget.onRated?.call();
      } else {
        debugPrint('Could not launch Play Store URL');
      }
    } catch (e) {
      debugPrint('Error opening Play Store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
          width: MediaQuery.of(context).size.width * 0.55, // 55% of screen width
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFFFF5F8), // Very subtle light pink tint
                Colors.white,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFE4E9).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Floating Sparkles around edges
              // Top-left sparkle
              Positioned(
                top: 5,
                left: 10,
                child: AnimatedBuilder(
                  animation: _sparkleAnimation1,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _sparkleAnimation1.value,
                      child: Transform.rotate(
                        angle: _sparkleAnimation1.value * 0.5,
                        child: const Text(
                          '✨',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Top-right sparkle
              Positioned(
                top: 8,
                right: 15,
                child: AnimatedBuilder(
                  animation: _sparkleAnimation2,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _sparkleAnimation2.value,
                      child: Transform.rotate(
                        angle: -_sparkleAnimation2.value * 0.5,
                        child: const Text(
                          '✨',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom-left sparkle
              Positioned(
                bottom: 5,
                left: 12,
                child: AnimatedBuilder(
                  animation: _sparkleAnimation3,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _sparkleAnimation3.value,
                      child: Transform.rotate(
                        angle: _sparkleAnimation3.value * 0.3,
                        child: const Text(
                          '✨',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star Icon with Gradient Background (like the image) - Moved to top with rotation animation
                  const SizedBox(height: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6C5CE7), // Light purple-blue
                              Color(0xFF4834D4), // Dark purple-blue
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4834D4).withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Large center star with rotation animation
                            Positioned(
                              child: RotationTransition(
                                turns: Tween<double>(begin: 0, end: 1).animate(
                                  CurvedAnimation(
                                    parent: _rotationController,
                                    curve: Curves.linear,
                                  ),
                                ),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: const Color(0xFFFFA726),
                                  size: 28,
                                ),
                              ),
                            ),
                            // Small star top-left
                            Positioned(
                              left: 6,
                              top: 10,
                              child: Icon(
                                Icons.star_rounded,
                                color: const Color(0xFFFFA726),
                                size: 14,
                              ),
                            ),
                            // Small star bottom-left
                            Positioned(
                              left: 8,
                              bottom: 12,
                              child: Icon(
                                Icons.star_rounded,
                                color: const Color(0xFFFFA726),
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Title
                  const Text(
                    'Rate Us on Play Store',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  // Star Rating Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Icon(
                          Icons.star_rounded,
                          color: const Color(0xFFFFA726),
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Message with emojis on sides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _sparkleAnimation1,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _sparkleAnimation1.value,
                            child: const Text(
                              '✨',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please rate our app on the Play Store and earn exciting rewards.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _sparkleAnimation2,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _sparkleAnimation2.value,
                            child: const Text(
                              '✨',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Rate Now Button (Primary - Blue) - Reduced Width with slide up animation (inside container)
                  SlideTransition(
                    position: _buttonSlideAnimation,
                    child: FadeTransition(
                      opacity: _buttonOpacityAnimation,
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _openPlayStore();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4834D4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ).copyWith(
                              backgroundColor: MaterialStateProperty.all(
                                const Color(0xFF4834D4),
                              ),
                              overlayColor: MaterialStateProperty.all(
                                Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: SlideTransition(
                              position: _buttonTextSlideAnimation,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Rate Now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),

              // Close Icon at Top Right Corner
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClosed?.call();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
      ),
    );
  }
}
