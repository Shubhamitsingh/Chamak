import 'package:flutter/material.dart';
import '../services/realtime_chat_service.dart';

/// Chat Input Overlay Widget (Separate, Toggled)
/// 
/// Production-grade input field for live chat
/// - Separate widget (not part of chat overlay)
/// - Toggled visibility (shown when chat icon clicked)
/// - Auto-focus when shown
/// - Hides after sending message
/// - Uses correct data model (senderRole, level)
class ChatInputOverlay extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserImage;
  final bool isHost;
  final VoidCallback? onSend; // Called after message is sent

  const ChatInputOverlay({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserImage,
    required this.isHost,
    this.onSend,
  });

  @override
  State<ChatInputOverlay> createState() => _ChatInputOverlayState();
}

class _ChatInputOverlayState extends State<ChatInputOverlay> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final RealtimeChatService _chatService = RealtimeChatService();

  @override
  void initState() {
    super.initState();
    // ✅ PRODUCTION: Auto-focus when shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // Validate user ID
    if (widget.currentUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to send messages.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Validate room ID
    if (widget.roomId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room ID is missing. Cannot send message.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    // Get user level (can be fetched from Firestore if needed)
    int? userLevel;
    try {
      // For now, default to 1
      // TODO: Fetch actual user level from Firestore
      userLevel = 1;
    } catch (e) {
      userLevel = 1;
    }

    // ✅ PRODUCTION: Send message with correct data model
    final success = await _chatService.sendMessage(
      streamId: widget.roomId, // Using roomId as streamId for now
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      senderImage: widget.currentUserImage,
      message: message,
      isHost: widget.isHost, // Will be converted to senderRole in service
      senderLevel: userLevel, // Will be converted to level in service
    );

    if (success) {
      // Hide input after sending
      _focusNode.unfocus();
      // Callback to hide input overlay
      widget.onSend?.call();
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Positioned(
      left: 8,
      right: 8,
      bottom: keyboardHeight > 0 ? keyboardHeight + 8 : (MediaQuery.of(context).padding.bottom + 80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type something...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Emoji button
            IconButton(
              icon: Icon(Icons.emoji_emotions, color: Colors.grey[700], size: 24),
              onPressed: () {
                _focusNode.requestFocus();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Send button
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue, size: 24),
              onPressed: _sendMessage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
