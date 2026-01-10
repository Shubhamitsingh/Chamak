import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../models/call_request_model.dart';

class CallRequestDialog extends StatefulWidget {
  final CallRequestModel callRequest;
  final Function() onAccept;
  final Function() onReject;

  const CallRequestDialog({
    super.key,
    required this.callRequest,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<CallRequestDialog> createState() => _CallRequestDialogState();
}

class _CallRequestDialogState extends State<CallRequestDialog> with TickerProviderStateMixin {
  bool _isResponding = false;
  late AnimationController _phonePulseController;
  late AnimationController _ringingTextController;
  late AnimationController _acceptButtonController;
  late AnimationController _rejectButtonController;
  int _remainingSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Haptic feedback on call incoming
    HapticFeedback.mediumImpact();
    
    // Initialize phone pulse animation (ringing effect)
    _phonePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    
    // Initialize ringing text animation (blinking effect)
    _ringingTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Initialize button scale animations
    _acceptButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _rejectButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    // Start countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isResponding) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
            widget.onReject();
            Navigator.of(context).pop();
          }
        });
      } else {
        timer.cancel();
      }
    });
    
    // Auto-reject after 60 seconds if no response
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted && !_isResponding) {
        widget.onReject();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _phonePulseController.dispose();
    _ringingTextController.dispose();
    _acceptButtonController.dispose();
    _rejectButtonController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _handleAccept() {
    if (_isResponding) return;
    HapticFeedback.lightImpact();
    _acceptButtonController.forward().then((_) {
      _acceptButtonController.reverse();
    });
    setState(() => _isResponding = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        widget.onAccept();
        Navigator.of(context).pop();
      }
    });
  }

  void _handleReject() {
    if (_isResponding) return;
    HapticFeedback.mediumImpact();
    _rejectButtonController.forward().then((_) {
      _rejectButtonController.reverse();
    });
    setState(() => _isResponding = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        widget.onReject();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent dismissing by back button - must accept or reject
        if (!_isResponding) {
          _handleReject();
        }
        return true;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF9C27B0), // Purple
                Color(0xFFE91E63), // Pink
                Color(0xFFFF1744), // Red-Pink
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 8,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: -5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Compact animated phone icon
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Expanding ripple rings (compact)
                          ...List.generate(3, (index) {
                            return AnimatedBuilder(
                              animation: _phonePulseController,
                              builder: (context, child) {
                                final delay = index * 0.33;
                                double animationValue = (_phonePulseController.value + delay) % 1.0;
                                
                                final scale = 1.0 + (animationValue * 0.8);
                                final opacity = (1.0 - animationValue) * 0.5;
                                
                                return Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                          // Phone icon (compact)
                          AnimatedBuilder(
                            animation: _phonePulseController,
                            builder: (context, child) {
                              final scale = 0.94 + (0.12 * (_phonePulseController.value * 2 - 1).abs());
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.3),
                                        Colors.white.withValues(alpha: 0.15),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.videocam_rounded,
                                    color: Colors.white,
                                    size: 44,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Compact title
                    FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 500),
                      child: const Text(
                        'Incoming Call',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Compact caller info section
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        children: [
                          // Profile picture (slightly larger than original but not too big)
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                              image: widget.callRequest.callerImage != null &&
                                      widget.callRequest.callerImage!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(widget.callRequest.callerImage!),
                                      fit: BoxFit.cover,
                                      onError: (exception, stackTrace) {},
                                    )
                                  : null,
                              color: widget.callRequest.callerImage == null ||
                                      widget.callRequest.callerImage!.isEmpty
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : null,
                            ),
                            child: widget.callRequest.callerImage == null ||
                                    widget.callRequest.callerImage!.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 45,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          
                          // Caller name
                          Text(
                            widget.callRequest.callerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          
                          // Compact animated "Ringing..." status
                          AnimatedBuilder(
                            animation: _ringingTextController,
                            builder: (context, child) {
                              final opacity = 0.5 + (0.5 * (_ringingTextController.value * 2 - 1).abs());
                              return Opacity(
                                opacity: opacity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.phone_in_talk_rounded,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ringing...',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          
                          // Compact timer
                          Text(
                            '$_remainingSeconds${_remainingSeconds == 1 ? 's' : 's'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Compact action buttons
                    FadeInDown(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Reject button
                          ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                              CurvedAnimation(
                                parent: _rejectButtonController,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: GestureDetector(
                              onTapDown: (_) => _rejectButtonController.forward(),
                              onTapUp: (_) => _rejectButtonController.reverse(),
                              onTapCancel: () => _rejectButtonController.reverse(),
                              onTap: _isResponding ? null : _handleReject,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE53935),
                                      Color(0xFFD32F2F),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.call_end_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                          
                          // Accept button
                          ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                              CurvedAnimation(
                                parent: _acceptButtonController,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: GestureDetector(
                              onTapDown: (_) => _acceptButtonController.forward(),
                              onTapUp: (_) => _acceptButtonController.reverse(),
                              onTapCancel: () => _acceptButtonController.reverse(),
                              onTap: _isResponding ? null : _handleAccept,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF388E3C),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withValues(alpha: 0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.call_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Compact loading indicator
                    if (_isResponding)
                      FadeIn(
                        duration: const Duration(milliseconds: 300),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
