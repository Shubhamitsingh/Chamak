import 'package:flutter/material.dart';
import '../models/live_chat_message_model.dart';
import '../services/realtime_chat_service.dart';

/// Real-Time Chat Overlay Widget
/// 
/// Displays a semi-transparent chat overlay on top of live video
/// Positioned at bottom-left with real-time message updates
class RealtimeChatOverlay extends StatefulWidget {
  final String streamId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserImage;
  final bool isHost;
  final VoidCallback? onClose;

  const RealtimeChatOverlay({
    super.key,
    required this.streamId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserImage,
    required this.isHost,
    this.onClose,
  });

  @override
  State<RealtimeChatOverlay> createState() => _RealtimeChatOverlayState();
}

class _RealtimeChatOverlayState extends State<RealtimeChatOverlay>
    with SingleTickerProviderStateMixin {
  final RealtimeChatService _chatService = RealtimeChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;
  bool _isInputVisible = false; // Track if input field should be visible
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  
  // Store listener references for proper cleanup
  VoidCallback? _focusNodeListener;
  VoidCallback? _messageControllerListener;

  @override
  void initState() {
    super.initState();
    
    // Setup slide animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0), // Start from left
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    
    // Show input field immediately when overlay opens (user clicked chat icon)
    // Set visible right away so host can see input field
    _isInputVisible = true;
    
    // Small delay before auto-focus to allow animation
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        // Auto-focus input when chat opens
        _focusNode.requestFocus();
      }
    });
    
    // Listen to keyboard visibility
    _focusNodeListener = () {
      if (!mounted) return; // Check if widget is still mounted
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      if (keyboardVisible != _isKeyboardVisible) {
        if (mounted) {
          setState(() {
            _isKeyboardVisible = keyboardVisible;
            _isInputVisible = keyboardVisible; // Show input when keyboard appears
          });
          // Auto-scroll when keyboard appears
          if (keyboardVisible) {
            _scrollToBottom();
          }
        }
      }
    };
    _focusNode.addListener(_focusNodeListener!);
    
    // Listen to message controller for input visibility
    _messageControllerListener = () {
      if (!mounted) return; // Check if widget is still mounted
      if (_messageController.text.isNotEmpty && !_isInputVisible) {
        if (mounted) {
          setState(() {
            _isInputVisible = true;
          });
        }
      }
    };
    _messageController.addListener(_messageControllerListener!);
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    if (_focusNodeListener != null) {
      _focusNode.removeListener(_focusNodeListener!);
    }
    if (_messageControllerListener != null) {
      _messageController.removeListener(_messageControllerListener!);
    }
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // Validate user ID - prevent sending if user is not authenticated
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

    // Validate stream ID
    if (widget.streamId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream ID is missing. Cannot send message.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    // Get user level from Firestore (if needed)
    int? userLevel;
    try {
      // You can fetch user level here if needed
      // For now, default to 1
      userLevel = 1;
    } catch (e) {
      userLevel = 1;
    }

    final success = await _chatService.sendMessage(
      streamId: widget.streamId,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      senderImage: widget.currentUserImage,
      message: message,
      isHost: widget.isHost,
      senderLevel: userLevel,
    );

    if (success) {
      // Hide input field after sending
      setState(() {
        _isInputVisible = false;
      });
      _focusNode.unfocus();
      // Auto-scroll to bottom after sending
      _scrollToBottom();
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = _isKeyboardVisible ? keyboardHeight + 20 : 100.0;

    // NO CONTAINER - Messages float independently on screen
    // Messages are positioned individually from bottom-left
    // IgnorePointer allows video to remain interactive
    return IgnorePointer(
      ignoring: false, // Allow interaction with input field
      child: Stack(
        children: [
          // Floating message bubbles (positioned individually)
          _buildFloatingMessages(bottomPadding),
          
          // Input field - always show when chat overlay is open
          // Position at bottom, adjust for keyboard
          Positioned(
            left: 8,
            right: 8,
            bottom: _isKeyboardVisible ? keyboardHeight + 8 : (MediaQuery.of(context).padding.bottom + 80),
            child: _buildInputField(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingMessages(double bottomPadding) {
    return StreamBuilder<List<LiveChatMessageModel>>(
      stream: _chatService.getVisibleMessages(widget.streamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Don't show loading, just empty
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // No messages - show nothing
        }

        final messages = snapshot.data!;
        final maxMessages = 10; // Show max 10 messages to avoid clutter
        final visibleMessages = messages.length > maxMessages 
            ? messages.sublist(messages.length - maxMessages)
            : messages;

        // Position messages from bottom-left, stacking upward
        return Stack(
          children: [
            for (int i = 0; i < visibleMessages.length; i++)
              Positioned(
                left: 8,
                bottom: bottomPadding + (visibleMessages.length - i - 1) * 45.0, // Stack from bottom
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildMessageBubble(visibleMessages[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(LiveChatMessageModel message) {
    final isCurrentUser = message.senderId == widget.currentUserId;
    
    // Handle different message types
    switch (message.type) {
      case LiveChatMessageType.gift:
        return _buildGiftMessage(message);
      case LiveChatMessageType.system:
        return _buildSystemMessage(message);
      case LiveChatMessageType.userEntry:
      case LiveChatMessageType.userExit:
        return _buildUserActionMessage(message);
      default:
        return _buildTextMessage(message, isCurrentUser);
    }
  }

  Widget _buildTextMessage(LiveChatMessageModel message, bool isCurrentUser) {
    // Reference app style: [Pink Icon] ⭐ Username 🦋 : message text 🎉
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7, // Max 70% width
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.7), // Dark grey bubble
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pink user icon (small circle)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFFF69B4), // Pink color
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          // Yellow star emoji
          const Text('⭐', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          // Username (yellow text)
          Flexible(
            child: Text(
              message.senderName,
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          // Butterfly emoji
          const Text('🦋', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          // Message text
          Flexible(
            child: Text(
              ': ${message.message}',
              style: TextStyle(
                color: Colors.grey[300]!,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftMessage(LiveChatMessageModel message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.message, // Gift emoji + name
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'from ${message.senderName}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(LiveChatMessageModel message) {
    // Reference app style: Large, prominent with colored text
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.8), // Darker background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          message.message,
          style: TextStyle(
            color: Colors.blue[300]!, // Colored text like reference (blue/pink)
            fontSize: 13, // Larger font
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildUserActionMessage(LiveChatMessageModel message) {
    // Reference app style: White bubble, yellow border, blue badge with crown, yellow text
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // White background like reference
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.yellow, // Yellow border like reference
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blue badge with white crown icon
          if (message.senderLevel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue, // Blue background
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star, // Crown/star icon
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Lv${message.senderLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          // Yellow text message
          Flexible(
            child: Text(
              '${message.senderName} ${message.message}',
              style: const TextStyle(
                color: Colors.yellow, // Yellow text like reference
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // White background like reference
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
        ],
      ),
    );
  }

}
