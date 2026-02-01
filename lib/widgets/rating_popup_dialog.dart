import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../services/rating_service.dart';

/// Modern Play Store rating popup dialog - Matching Telegram popup layout
/// Uses hybrid approach: Native In-App Review API when available, falls back to Play Store URL
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
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isRating = false;
  final RatingService _ratingService = RatingService();
  final InAppReview _inAppReview = InAppReview.instance;

  /// Play Store URL for the app
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.chamakz.app';

  @override
  void initState() {
    super.initState();
    // Rotation animation for achievement icon
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Handle rate now - Hybrid approach: Try native API first, fallback to Play Store URL
  Future<void> _handleRateNow() async {
    if (_isRating) return;
    
    setState(() => _isRating = true);
    
    try {
      // ✅ HYBRID APPROACH: Try native In-App Review API first
      final isAvailable = await _inAppReview.isAvailable();
      
      if (isAvailable) {
        // PATH A: Show native Play Store dialog (best UX)
        debugPrint('✅ Native In-App Review available - showing native dialog');
        
        // Mark as requested (for rate limiting)
        await _ratingService.markReviewRequested();
        
        // Show native dialog
        await _inAppReview.requestReview();
        
        // Mark as rated (user might have submitted)
        widget.onRated?.call();
        
        // Close popup after short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(true); // true = user rated
        }
        return;
      }
      
      // PATH B: Fallback to Play Store URL (if native API not available)
      debugPrint('⚠️ Native In-App Review not available - using Play Store URL fallback');
      await _openPlayStoreUrl();
      
    } catch (e) {
      debugPrint('❌ Error in hybrid review approach: $e');
      // Fallback to Play Store URL
      await _openPlayStoreUrl();
    }
  }

  /// Open Play Store URL (fallback method)
  Future<void> _openPlayStoreUrl() async {
    try {
      // Mark as rated
      widget.onRated?.call();
      
      // Open Play Store link
      final uri = Uri.parse(playStoreUrl);
      
      // Try to open in Play Store app first
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        
        if (launched) {
          debugPrint('✅ Play Store opened in app');
          // Close popup after short delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop(true); // true = user rated
          }
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Play Store app not found, trying browser: $e');
      }
      
      // Fallback: Open in browser
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        
        if (launched) {
          debugPrint('✅ Play Store opened in browser');
          // Close popup after short delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop(true); // true = user rated
          }
          return;
        }
      } catch (e) {
        debugPrint('❌ Error opening in browser: $e');
      }
      
      // If both fail, show error message
      if (mounted) {
        setState(() => _isRating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Play Store. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening Play Store: $e');
      if (mounted) {
        setState(() => _isRating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: FadeInDown(
        duration: const Duration(milliseconds: 400),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient and star icon (matching Telegram popup)
              _buildHeader(),
              
              // Content box (matching Telegram popup)
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B9D), // Pink
            Color(0xFFFF8E53), // Orange
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Star icon on the left (animated)
          Align(
            alignment: Alignment.centerLeft,
            child: _buildStarIcon(),
          ),
          // "Rate Us" text - truly centered
          const Text(
            'Rate Us',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          // Close icon on the right
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                widget.onClosed?.call();
                if (mounted) {
                  Navigator.of(context).pop(false);
                }
              },
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarIcon() {
    return RotationTransition(
      turns: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _rotationController,
          curve: Curves.linear,
        ),
      ),
      child: const Icon(
        Icons.star_rounded,
        color: Color(0xFFFFD700), // Golden color
        size: 32,
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message with star icon (matching Telegram popup)
          _buildWelcomeMessage(),
          
          const SizedBox(height: 8),
          
          // Call to action text (matching Telegram popup)
          _buildCallToAction(),
          
          const SizedBox(height: 10),
          
          // Benefits list (matching Telegram popup)
          _buildBenefitsList(),
          
          const SizedBox(height: 12),
          
          // Rate Now button (matching Telegram Join button)
          _buildRateButton(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFA726).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.star_rounded,
            color: Color(0xFFFFA726),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Love our app?',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallToAction() {
    return Text(
      'Your feedback helps us improve! Please rate us on the Play Store and enjoy exclusive rewards:',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[700],
        height: 1.3,
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {'emoji': '⭐', 'text': 'Help us grow and improve'},
      {'emoji': '🎁', 'text': 'Earn special rewards'},
      {'emoji': '💎', 'text': 'Get priority support'},
    ];

    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                benefit['emoji']!,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  benefit['text']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isRating ? null : _handleRateNow,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3), // Blue (matching Telegram)
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: _isRating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('⭐', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Rate on Play Store',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

}
