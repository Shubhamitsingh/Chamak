import 'package:flutter/material.dart';

/// Chat Toggle Button Widget
/// 
/// Floating button to open/close chat overlay
/// Shows unread count badge when chat is closed
class ChatToggleButton extends StatelessWidget {
  final bool isChatOpen;
  final VoidCallback onTap;
  final int? unreadCount; // Optional: Show unread message count

  const ChatToggleButton({
    super.key,
    required this.isChatOpen,
    required this.onTap,
    this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    // Reference app style: White circular icon with speech bubble
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white, // White background like reference
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                isChatOpen ? Icons.close : Icons.chat_bubble_outline,
                color: Colors.black87, // Dark icon on white background
                size: 24,
              ),
            ),
            // Unread count badge
            if (unreadCount != null && unreadCount! > 0 && !isChatOpen)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount! > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
