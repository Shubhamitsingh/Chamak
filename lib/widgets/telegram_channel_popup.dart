import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/telegram_popup_service.dart';

class TelegramChannelPopup extends StatefulWidget {
  final String telegramChannelUrl;
  final String appName;
  final TelegramPopupService popupService;
  
  const TelegramChannelPopup({
    super.key,
    required this.telegramChannelUrl,
    required this.appName,
    required this.popupService,
  });

  @override
  State<TelegramChannelPopup> createState() => _TelegramChannelPopupState();
}

class _TelegramChannelPopupState extends State<TelegramChannelPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _soundWaveController;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    // Animation for sound waves
    _soundWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _soundWaveController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinTelegram() async {
    if (_isJoining) return;
    
    setState(() => _isJoining = true);
    
    try {
      // Mark as joined
      await widget.popupService.markAsJoined();
      
      // Open Telegram link
      final uri = Uri.parse(widget.telegramChannelUrl);
      
      // First, try to open in Telegram app (if installed)
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        
        if (launched) {
          debugPrint('✅ Telegram opened in app');
          // Close popup after short delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop(true); // true = user joined
          }
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Telegram app not found, trying browser: $e');
      }
      
      // Fallback: Open in browser (if Telegram app not installed)
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        
        if (launched) {
          debugPrint('✅ Telegram opened in browser');
          // Close popup after short delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop(true); // true = user joined
          }
          return;
        }
      } catch (e) {
        debugPrint('❌ Error opening in browser: $e');
      }
      
      // If both fail, show error message
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Telegram. Please install Telegram app or try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening Telegram: $e');
      if (mounted) {
        setState(() => _isJoining = false);
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

  Future<void> _handleSkip() async {
    await widget.popupService.recordDismissal();
    if (mounted) {
      Navigator.of(context).pop(false); // false = user skipped
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
              // Header with gradient and megaphone
              _buildHeader(),
              
              // Content box
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Icon on the left
          Align(
            alignment: Alignment.centerLeft,
            child: _buildMegaphoneIcon(),
          ),
          // "Notice" text - truly centered
          const Text(
            'Notice',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMegaphoneIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Sound waves animation
        AnimatedBuilder(
          animation: _soundWaveController,
          builder: (context, child) {
            return CustomPaint(
              painter: SoundWavePainter(
                progress: _soundWaveController.value,
              ),
              size: const Size(40, 40),
            );
          },
        ),
        // Announcement icon (custom image)
        Image.asset(
          'assets/images/announcement.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
      ],
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message with bell icon
          _buildWelcomeMessage(),
          
          const SizedBox(height: 12),
          
          // Call to action text
          _buildCallToAction(),
          
          const SizedBox(height: 14),
          
          // Benefits list
          _buildBenefitsList(),
          
          const SizedBox(height: 16),
          
          // Join button
          _buildJoinButton(),
          
          const SizedBox(height: 8),
          
          // Skip button
          _buildSkipButton(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Row(
      children: [
        Image.asset(
          'assets/images/bell.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Welcome to ${widget.appName}!',
            style: const TextStyle(
              fontSize: 18,
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
      'Stay updated and enjoy exclusive benefits by joining our official Telegram channel:',
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[700],
        height: 1.4,
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {'emoji': '🎁', 'text': 'Special user rewards'},
      {'emoji': '🎉', 'text': 'Priority access to events'},
      {'emoji': '🧧', 'text': 'Lucky draws & bonus activities'},
    ];

    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
                    fontSize: 13,
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

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isJoining ? null : _handleJoinTelegram,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3), // Blue
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: _isJoining
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
                  Text('👍', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Join the Official Telegram Channel',
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

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _handleSkip,
        child: Text(
          'Skip',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Custom painter for sound waves animation
class SoundWavePainter extends CustomPainter {
  final double progress;

  SoundWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 3 sound wave arcs
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.3) % 1.0;
      final waveRadius = radius + (waveProgress * 15);
      final opacity = 1.0 - waveProgress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: waveRadius),
        -0.5,
        1.0,
        false,
        paint..color = Colors.white.withOpacity(opacity * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(SoundWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
