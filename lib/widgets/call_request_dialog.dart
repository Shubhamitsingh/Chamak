import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize phone pulse animation (ringing effect)
    _phonePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    // Auto-reject after 60 seconds if no response (increased from 30s for better UX)
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
    super.dispose();
  }

  void _handleAccept() {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    widget.onAccept();
    Navigator.of(context).pop();
  }

  void _handleReject() {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    widget.onReject();
    Navigator.of(context).pop();
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
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated phone icon with ringing effect
                FadeInDown(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding ripple rings (ringing effect)
                      ...List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _phonePulseController,
                          builder: (context, child) {
                            // Staggered delay for each ring
                            final delay = index * 0.33;
                            double animationValue = (_phonePulseController.value + delay) % 1.0;
                            
                            // Ring expands and fades out
                            final scale = 1.0 + (animationValue * 0.8);
                            final opacity = 1.0 - animationValue;
                            
                            return Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity * 0.5,
                                child: Container(
                                  width: 88,
                                  height: 88,
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
                      // Phone icon (pulsing)
                      AnimatedBuilder(
                        animation: _phonePulseController,
                        builder: (context, child) {
                          // Pulsing scale animation (0.95 to 1.05)
                          final scale = 0.95 + ((_phonePulseController.value * 0.2).abs() - 0.1);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.phone,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: const Text(
                    'Incoming Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Caller info
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      // Profile picture
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          image: widget.callRequest.callerImage != null &&
                                  widget.callRequest.callerImage!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(widget.callRequest.callerImage!),
                                  fit: BoxFit.cover,
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
                                size: 40,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Caller name
                      Text(
                        widget.callRequest.callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam,
                            color: Colors.white70,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'wants to have a video call',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Action buttons
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reject button
                      GestureDetector(
                        onTap: _isResponding ? null : _handleReject,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Accept button
                      GestureDetector(
                        onTap: _isResponding ? null : _handleAccept,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Loading indicator if responding
                if (_isResponding)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
