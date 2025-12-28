import 'package:flutter/material.dart';
import 'dart:async';

// Message data structure
class ChatMessage {
  final String id;
  final String username;
  final String text;
  final DateTime timestamp;
  Timer? timer;

  ChatMessage({
    required this.id,
    required this.username,
    required this.text,
    required this.timestamp,
    this.timer,
  });
}

class LiveStreamChatWidget extends StatefulWidget {
  final Widget videoPlayer; // Video player widget passed from parent
  final String? currentUsername; // Current user's username

  const LiveStreamChatWidget({
    super.key,
    required this.videoPlayer,
    this.currentUsername,
  });

  @override
  State<LiveStreamChatWidget> createState() => _LiveStreamChatWidgetState();
}

class _LiveStreamChatWidgetState extends State<LiveStreamChatWidget> {
  // Controllers and nodes
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Message list
  final List<ChatMessage> _messages = [];
  static const int _maxMessages = 50;
  static const Duration _messageLifetime = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    // Focus node is created automatically, no need to initialize
  }

  @override
  void dispose() {
    // Dispose all controllers and cancel all timers
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    
    // Cancel all message timers
    for (var message in _messages) {
      message.timer?.cancel();
    }
    _messages.clear();
    
    super.dispose();
  }

  // Add new message
  void _addMessage(String text) {
    if (text.trim().isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: widget.currentUsername ?? 'User',
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    // Remove oldest message if limit exceeded
    if (_messages.length >= _maxMessages) {
      final oldestMessage = _messages.removeLast();
      oldestMessage.timer?.cancel();
    }

    // Insert at index 0 (bottom position in reverse list)
    _messages.insert(0, message);

    // Start timer to auto-remove message after 30 seconds
    message.timer = Timer(_messageLifetime, () {
      if (mounted) {
        _removeMessage(message.id);
      }
    });

    setState(() {});

    // Auto-scroll to bottom after adding message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Position 0 is at bottom in reverse list
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Remove message by ID
  void _removeMessage(String messageId) {
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      final message = _messages[messageIndex];
      message.timer?.cancel();
      setState(() {
        _messages.removeAt(messageIndex);
      });
    }
  }

  // Send message function
  void _sendMessage() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    _addMessage(text);
    _messageController.clear();
    // Keep keyboard open for next message
  }

  @override
  Widget build(BuildContext context) {
    // Detect keyboard state using MediaQuery
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      // Tap outside to close keyboard
      onTap: () {
        _focusNode.unfocus();
      },
      child: Stack(
        children: [
          // Layer 1: Video player (full screen)
          Positioned.fill(
            child: widget.videoPlayer,
          ),

          // Layer 2: Chat messages container (bottom-left)
          Positioned(
            left: 16,
            bottom: 80,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.5, // 50% of screen height
                maxWidth: screenWidth * 0.7, // 70% of screen width
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3), // 30% opacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _messages.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true, // Index 0 at bottom (newest)
                          shrinkWrap: true,
                          itemCount: _messages.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                              child: _buildMessageBubble(message),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),

          // Layer 3: Animated input field (slides up with keyboard)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            bottom: isKeyboardOpen ? keyboardHeight : -100, // Off-screen when closed
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Layer 4: Floating chat button (only when keyboard closed)
          if (!isKeyboardOpen)
            Positioned(
              bottom: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    // Open keyboard by requesting focus
                    _focusNode.requestFocus();
                  },
                  child: const Icon(Icons.chat),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build message bubble widget
  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

