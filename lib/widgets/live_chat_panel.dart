import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_chat_message_model.dart';
import '../services/live_chat_service.dart';

class LiveChatPanel extends StatefulWidget {
  final String liveStreamId;
  final bool isHost;
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserImage;
  final VoidCallback? onChatIconTap; // Callback for chat icon tap

  const LiveChatPanel({
    super.key,
    required this.liveStreamId,
    required this.isHost,
    this.currentUserId,
    this.currentUserName,
    this.currentUserImage,
    this.onChatIconTap,
  });

  @override
  State<LiveChatPanel> createState() => _LiveChatPanelState();
}

class _LiveChatPanelState extends State<LiveChatPanel> with TickerProviderStateMixin {
  // Ensure entry/exit notifications are sent only once per widget lifecycle
  bool _entryNotificationSent = false;
  bool _exitNotificationSent = false;
  // Method to toggle input field (called from parent)
  void toggleInputField() {
    setState(() {
      _showInputField = !_showInputField;
      if (_showInputField) {
        // Focus on text field to open keyboard
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _messageFocusNode.requestFocus();
          }
        });
      } else {
        // Unfocus keyboard
        _messageFocusNode.unfocus();
      }
    });
  }
  final LiveChatService _chatService = LiveChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode(); // Focus node for text field
  bool _containsNumbersWarning = false;
  bool _hasText = false;
  int _previousMessageCount = 0; // Track message count for auto-scroll
  bool _isUserScrolling = false; // Track if user is manually scrolling
  bool _showInputField = true; // For viewers: hide input field by default, show when user wants to chat
  final List<OverlayEntry> _activeNotifications = []; // Track active notification overlays
  final Set<String> _shownNotifications = {}; // Track which notifications have been shown
  final Set<String> _animatedMessages = {}; // Track which messages have been animated to prevent re-animation
  bool _adminMessageShown = false; // Track if admin welcome message has been shown
  OverlayEntry? _adminMessageOverlay; // Track admin message overlay

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    
    // For viewers: hide input field completely (it will be shown separately when chat icon is clicked)
    // For host: always show input field
    _showInputField = widget.isHost;
    
    // Listen for chat icon tap callback
    if (widget.onChatIconTap != null) {
      // This will be handled by the parent widget
    }
    
    // Don't send welcome message to Firestore - it's shown as static floating bubble
    // _sendWelcomeMessage(); // Removed - using static floating bubble instead
    
    // Show admin welcome message popup when user joins (every time)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAdminWelcomePopup();
      }
    });
    
    // Load current user info if not provided, then send entry notification once
    if (_currentUserId != null && widget.currentUserName == null) {
      _loadCurrentUserInfo().whenComplete(() {
        _sendEntryNotificationOnce();
      });
    } else {
      _sendEntryNotificationOnce();
    }

    // Listen for numbers while typing and update UI
    _messageController.addListener(() {
      final hasNumbers = _containsAnyNumbers(_messageController.text);
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasNumbers != _containsNumbersWarning || hasText != _hasText) {
        if (mounted) {
          setState(() {
            _containsNumbersWarning = hasNumbers;
            _hasText = hasText;
          });
        }
      }
    });

    // Track scroll position to detect user scrolling
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        try {
        final isAtBottom = _scrollController.position.pixels >= 
              (_scrollController.position.maxScrollExtent - 50);
        _isUserScrolling = !isAtBottom;
        } catch (e) {
          // Ignore errors during scroll tracking
        }
      }
    });
  }


  // Send entry notification ONCE per session with a non-empty user name
  Future<void> _sendEntryNotificationOnce() async {
    if (_entryNotificationSent) return;
    final resolvedName = (widget.currentUserName ?? _currentUserName ?? '').trim();
    final userName = resolvedName.isEmpty ? 'User' : resolvedName;
    try {
      await _chatService.sendUserEntryNotification(
        liveStreamId: widget.liveStreamId,
        userName: userName,
      );
      _entryNotificationSent = true;
    } catch (e) {
      // Swallow errors silently to avoid UI disruption
    }
  }

  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserImage;

  Future<void> _loadCurrentUserInfo() async {
    if (_currentUserId == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        setState(() {
          _currentUserName = data['displayName'] ?? 'User';
          _currentUserImage = data['photoURL'];
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  // Show entry/exit notifications as popups from left side
  void _showEntryExitNotifications(List<LiveChatMessageModel> messages) {
    final overlay = Overlay.of(context);
    
    for (final message in messages) {
      if (_shownNotifications.contains(message.messageId)) continue;
      _shownNotifications.add(message.messageId);
      
      // Create overlay entry for notification
      final overlayEntry = OverlayEntry(
        builder: (context) => _buildEntryExitNotification(message, overlay),
      );
      
      _activeNotifications.add(overlayEntry);
      overlay.insert(overlayEntry);
      
      // Auto-dismiss after 30 seconds (changed from 3 to match admin message)
      Future.delayed(const Duration(seconds: 30), () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
          _activeNotifications.remove(overlayEntry);
        }
      });
    }
  }
  
  // Show admin welcome message popup from left side
  void _showAdminWelcomePopup() {
    if (_adminMessageShown) return; // Don't show multiple times in same session
    
    final overlay = Overlay.of(context);
    
    _adminMessageOverlay = OverlayEntry(
      builder: (context) => _buildAdminWelcomePopup(overlay),
    );
    
    overlay.insert(_adminMessageOverlay!);
    _adminMessageShown = true;
    
    // Auto-dismiss after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (_adminMessageOverlay != null && _adminMessageOverlay!.mounted) {
        _adminMessageOverlay!.remove();
        _adminMessageOverlay = null;
      }
    });
  }
  
  // Build admin welcome message popup from left side
  Widget _buildAdminWelcomePopup(OverlayState overlay) {
    final inputFieldHeight = widget.isHost ? 60.0 : 0.0;
    final bottomOffset = inputFieldHeight + 24; // Position above input field or bottom icons
    
    return Positioned(
      left: 0,
      bottom: bottomOffset,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: -300.0, end: 0.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(value, 0), // Slide in from left
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  // Allow manual close on tap
                  if (_adminMessageOverlay != null && _adminMessageOverlay!.mounted) {
                    _adminMessageOverlay!.remove();
                    _adminMessageOverlay = null;
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.95),
                        Colors.orange.withValues(alpha: 0.95),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Admin badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[800],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Close button
                          GestureDetector(
                            onTap: () {
                              if (_adminMessageOverlay != null && _adminMessageOverlay!.mounted) {
                                _adminMessageOverlay!.remove();
                                _adminMessageOverlay = null;
                              }
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Welcome message
                      const Text(
                        'Welcome to Chamakz!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please don\'t share inappropriate content like pornography or violence as it\'s strictly against our policies. Our AI system continuously monitors content to ensure compliance.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Build entry/exit notification popup from left side (just above chat input field)
  Widget _buildEntryExitNotification(LiveChatMessageModel message, OverlayState overlay) {
    final isEntry = message.type == LiveChatMessageType.userEntry;
    final inputFieldHeight = widget.isHost ? 60.0 : 0.0; // Input field height (only for host)
    final notificationIndex = _activeNotifications.length;
    // Position from bottom: input field + spacing + stack notifications (just above input field)
    final bottomOffset = inputFieldHeight + 24 + (notificationIndex * 55.0); // 24px spacing above input field
    
    return Positioned(
      left: 0,
      bottom: bottomOffset, // Position from bottom, just above chat input field
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: -200.0, end: 0.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(value, 0), // Slide in from left
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEntry 
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.red.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Icon(
                      isEntry ? Icons.person_add : Icons.person_remove,
                      color: isEntry ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    // Text
                    Flexible(
                      child: Text(
                        '${message.senderName} ${isEntry ? "joined" : "left"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Remove all active notifications
    for (final entry in _activeNotifications) {
      if (entry.mounted) {
        entry.remove();
      }
    }
    _activeNotifications.clear();
    
    // Remove admin message overlay if exists
    if (_adminMessageOverlay != null && _adminMessageOverlay!.mounted) {
      _adminMessageOverlay!.remove();
      _adminMessageOverlay = null;
    }
    
    // Send exit notification when leaving chat (only if an entry was sent)
    if (_entryNotificationSent && !_exitNotificationSent) {
      _sendExitNotification();
    }
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }
  
  // Send exit notification
  Future<void> _sendExitNotification() async {
    try {
      final resolvedName = (widget.currentUserName ?? _currentUserName ?? '').trim();
      final userName = resolvedName.isEmpty ? 'User' : resolvedName;
      await _chatService.sendUserExitNotification(
        liveStreamId: widget.liveStreamId,
        userName: userName,
      );
      _exitNotificationSent = true;
    } catch (e) {
      print('Error sending exit notification: $e');
    }
  }

  // Check if message contains digits (phone numbers)
  bool _containsDigits(String text) {
    return RegExp(r'\d').hasMatch(text);
  }

  // Check if message contains number words (zero, one, two, etc.)
  bool _containsNumberWords(String text) {
    final lowerText = text.toLowerCase();
    final numberWords = [
      'zero', 'one', 'two', 'three', 'four',
      'five', 'six', 'seven', 'eight', 'nine'
    ];
    
    for (String word in numberWords) {
      final pattern = '\\b$word\\b';
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerText)) {
        return true;
      }
    }
    
    return false;
  }

  // Check if message contains any numbers (digits OR words)
  bool _containsAnyNumbers(String text) {
    return _containsDigits(text) || _containsNumberWords(text);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) return;

    final message = _messageController.text.trim();

    // Security: Block messages containing digits or number words
    if (_containsAnyNumbers(message)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ Cannot send numbers! Phone numbers (including in word form) are not allowed for your safety.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Sending message...'),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF9C27B0),
        ),
      );
    }

    print('📤 Attempting to send message...');
    print('   Stream ID: ${widget.liveStreamId}');
    print('   User ID: $_currentUserId');
    print('   User Name: ${_currentUserName ?? "User"}');
    print('   Message: $message');
    print('   Is Host: ${widget.isHost}');
    
    final success = await _chatService.sendLiveChatMessage(
      liveStreamId: widget.liveStreamId,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'User',
      senderImage: _currentUserImage,
      message: message,
      isHost: widget.isHost,
    );

    if (success) {
      print('✅ Message sent successfully to Firestore, clearing input');
      _messageController.clear();
      // Update state to show phone icon again
      if (mounted) {
        setState(() {
          _hasText = false;
        });
      }
      // Auto-scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients && mounted) {
          try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          } catch (e) {
            // Fallback to jump if animate fails
            try {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            } catch (e2) {
              debugPrint('Error scrolling after send: $e2');
            }
          }
        }
      });
    } else {
      print('❌ Failed to send message to Firestore');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please check your connection and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return DateFormat('HH:mm').format(timestamp);
    }
  }

  // Build input field widget
  Widget _buildInputField() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8), // Add bottom padding for perfect display
      child: Material(
        color: Colors.transparent,
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
              children: [
          // Text Input - More Compact with Send Icon Inside
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 28, // More compact input height
                      maxHeight: 72,
                    ),
                    decoration: BoxDecoration(
                color: Colors.transparent, // Transparent background
                borderRadius: BorderRadius.circular(18),
                      border: _containsNumbersWarning
                          ? Border.all(color: Colors.red, width: 1.5)
                    : Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Padding(
                    padding: const EdgeInsets.only(left: 10, right: 4),
                          child: _containsNumbersWarning 
                              ? Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red[300],
                                  size: 16,
                                )
                              : Image.asset(
                                  'assets/images/chat.png',
                                  width: 16,
                                  height: 16,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode, // Add focus node
                      enabled: true, // Explicitly enable the text field
                      readOnly: false, // Explicitly make it editable
                      autofocus: false,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9C27B0), // Purple text color
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      cursorColor: const Color(0xFF9C27B0), // Purple cursor
                      cursorWidth: 2.0,
                      cursorRadius: const Radius.circular(1),
                            decoration: InputDecoration(
                        filled: false, // Explicitly disable fill
                        fillColor: Colors.transparent, // Transparent fill
                              hintText: _containsNumbersWarning 
                                  ? 'Numbers blocked!' 
                            : 'Type a message...',
                              hintStyle: TextStyle(
                                color: _containsNumbersWarning 
                              ? Colors.red[300] 
                              : const Color(0xFF9C27B0).withValues(alpha: 0.5), // Light purple hint
                          fontSize: 12,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2, // Minimal vertical padding for compact layout
                              ),
                            ),
                      maxLines: 3,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                      onChanged: (text) {
                        // Ensure state updates when text changes
                        final hasNumbers = _containsAnyNumbers(text);
                        final hasText = text.trim().isNotEmpty;
                        if (mounted) {
                          setState(() {
                            _containsNumbersWarning = hasNumbers;
                            _hasText = hasText;
                          });
                        }
                      },
                    ),
                        ),
                  // Emoji button (only for viewers)
                  if (!widget.isHost)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Open emoji picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Emoji picker coming soon'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  // Send Button - Only show when text is entered
                  if (_hasText && !_containsNumbersWarning)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _sendMessage,
                            borderRadius: BorderRadius.circular(16),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
                            ),
                          ],
                        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Ensure touch events work properly
      child: Container(
        color: Colors.transparent, // Explicitly transparent
        constraints: BoxConstraints(
          maxHeight: double.infinity, // Let parent control height
        ),
        padding: EdgeInsets.only(
          bottom: widget.isHost ? 8.0 : 0.0, // Add bottom padding for host screen
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use min to prevent overflow
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start, // Align to start, no space-between
          children: [
          // Header - Only show for host, hide for viewers (they have bottom icons)
          if (widget.isHost)
            Transform.translate(
              offset: const Offset(0, -16), // Move up by 16px using negative offset
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0), // Removed bottom padding to reduce space
                child: const Text(
                  'Live Chat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

          // Messages List - Only messages, no input field for viewers
          Expanded( // Use Expanded to fill available space
            child: StreamBuilder<List<LiveChatMessageModel>>(
              key: ValueKey('chat_stream_${widget.liveStreamId}'),
                stream: _chatService.getLiveChatMessages(widget.liveStreamId),
                builder: (context, snapshot) {
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9C27B0),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  print('❌ StreamBuilder error: ${snapshot.error}');
                  print('   Stream ID: ${widget.liveStreamId}');
                  print('   Error details: ${snapshot.error.toString()}');
                  // Show user-friendly error message instead of crashing
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[300],
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Unable to load chat messages',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please check your connection',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                
                // Filter out system welcome messages and entry/exit messages (entry/exit shown as popups)
                // Use cached filtered messages to prevent unnecessary rebuilds
                final filteredMessages = messages.where((m) => 
                  !(m.type == LiveChatMessageType.system && 
                    m.message.contains('Welcome to Chamakz')) &&
                  m.type != LiveChatMessageType.userEntry &&
                  m.type != LiveChatMessageType.userExit
                ).toList();
                
                // Early return if no messages - show empty list
                if (filteredMessages.isEmpty && _previousMessageCount == 0) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 0),
                    shrinkWrap: false,
                    itemCount: 0, // No messages
                    itemBuilder: (context, index) => const SizedBox.shrink(),
                  );
                }
                
                // Show entry/exit messages as popup notifications from left side
                final entryExitMessages = messages.where((m) => 
                  (m.type == LiveChatMessageType.userEntry || 
                   m.type == LiveChatMessageType.userExit) &&
                  !_shownNotifications.contains(m.messageId)
                ).toList();
                
                // Display popup notifications for entry/exit messages
                if (entryExitMessages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showEntryExitNotifications(entryExitMessages);
                    }
                  });
                }
                
                print('📬 Filtered messages count: ${filteredMessages.length}');

                // Auto-scroll to bottom only when new messages arrive and user is at bottom
                final currentMessageCount = filteredMessages.length;
                final hasNewMessages = currentMessageCount > _previousMessageCount;
                
                // Improved auto-scroll logic
                if (hasNewMessages && _scrollController.hasClients) {
                  // Check if user is near bottom (within 100px)
                  final isNearBottom = _scrollController.position.pixels >= 
                      (_scrollController.position.maxScrollExtent - 100);
                  
                  // Only auto-scroll if user is near bottom or hasn't scrolled manually
                  if ((isNearBottom || !_isUserScrolling)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients && mounted) {
                        try {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                        } catch (e) {
                          // Fallback to jump if animate fails
                          try {
                            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                          } catch (e2) {
                            debugPrint('Error scrolling chat: $e2');
                          }
                        }
                    }
                  });
                  }
                }
                
                _previousMessageCount = currentMessageCount;

                // Show only chat messages (admin message shown as popup, not in chat panel)
                final itemCount = filteredMessages.length; // Only chat messages
                
                // Auto-scroll to bottom on initial load when messages exist
                if (filteredMessages.isNotEmpty && _previousMessageCount == 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients && mounted) {
                      try {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                      } catch (e) {
                        debugPrint('Error jumping to bottom on initial load: $e');
                      }
                    }
                  });
                }
                
                return ListView.builder(
                  key: const ValueKey('chat_messages_list'),
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 4, // Small top padding
                    bottom: 0, // Removed bottom padding to eliminate gap
                  ),
                  shrinkWrap: false, // Don't shrink wrap - fill available space
                  physics: const AlwaysScrollableScrollPhysics(), // Always allow scrolling
                  itemCount: itemCount,
                  cacheExtent: 500, // Cache more items for smoother scrolling
                  addAutomaticKeepAlives: false, // Disable keep alive for better performance
                  addRepaintBoundaries: true, // Add repaint boundaries for better performance
                  itemBuilder: (context, index) {
                    // Show chat messages only (admin message shown as popup, not here)
                    if (index >= 0 && index < filteredMessages.length) {
                      final message = filteredMessages[index];
                      final isSentByMe = message.senderId == _currentUserId;
                      return RepaintBoundary(
                        key: ValueKey('message_${message.messageId}'),
                        child: _buildMessageBubble(message, isSentByMe),
                      );
                    }
                    // Fallback - should not happen
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),

          // Spacing between chat messages and input field
          if (_showInputField && widget.isHost)
            const SizedBox(height: 24), // More space between chat and input field

          // Message Input - Only show for host, viewers have separate input field
          if (_showInputField && widget.isHost)
            Padding(
              padding: const EdgeInsets.only(bottom: 24), // Bottom padding to move input field up
              child: _buildInputField(),
            ),
          
        ],
      ),
      ),
    );
  }

  // Build welcome message (cached widget for better performance)
  Widget _buildWelcomeMessage() {
    return RepaintBoundary(
      key: const ValueKey('welcome_message'),
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 20), // Small top padding to ensure visibility
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.yellow.withValues(alpha: 0.1), // Lighter transparent yellow background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.yellow.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Text(
            'Admin: Welcome to Chamakz!\nPlease don\'t share inappropriate content like pornography or violence as it\'s strictly against our policies. Our AI system continuously monitors content to ensure compliance.',
            style: TextStyle(
              color: Colors.amber[600], // Golden yellow
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.bold, // More bold
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(LiveChatMessageModel message, bool isSentByMe) {
    // Handle system/admin messages - Always show prominently on both host and user screens
    if (message.type == LiveChatMessageType.system) {
      return Padding(
        key: ValueKey(message.messageId),
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.4), // More visible background
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.8),
              width: 2, // Thicker border for visibility
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.senderName,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                message.message,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Handle gift messages
    if (message.type == LiveChatMessageType.gift) {
      return Padding(
        key: ValueKey(message.messageId),
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gift emoji/icon (large)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Text(
                message.message.split(' ').first, // Get emoji from message
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 8),
            // Gift message
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.3),
                      Colors.orange.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Entry/exit messages are now shown as popup notifications, not in chat list
    // This should not be reached, but kept as fallback
    if (message.type == LiveChatMessageType.userEntry || 
        message.type == LiveChatMessageType.userExit) {
      return const SizedBox.shrink();
    }

    // Regular user messages - Professional design with glassmorphism and animations
    final isHostMessage = message.isHost;
    final hasAnimated = _animatedMessages.contains(message.messageId);
    
    // Mark message as animated if not already animated
    if (!hasAnimated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animatedMessages.add(message.messageId);
        }
      });
    }
    
    // Build message bubble content (extracted to avoid rebuilding animation)
    Widget messageContent = Padding(
              key: ValueKey(message.messageId),
              padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Message bubble with optimized glassmorphism (avatar removed)
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Message bubble - Removed expensive BackdropFilter, using simpler gradient
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                      // Dark semi-transparent background with gradient (removed BackdropFilter for performance)
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.80),
                          Colors.grey[900]!.withValues(alpha: 0.75),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Username with HOST badge (always show username, especially on host screen)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // HOST badge for host messages (only show on viewer screen, not host's own messages)
                                  if (isHostMessage && !isSentByMe)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9C27B0),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        'HOST',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  if (isHostMessage && !isSentByMe) const SizedBox(width: 4),
                                  // Username - Always show, especially important on host screen to identify viewers
                                  Text(
                                    isSentByMe 
                                        ? (_currentUserName ?? 'You') 
                                        : (message.senderName.isNotEmpty 
                                            ? message.senderName 
                                            : 'Anonymous'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isHostMessage 
                                          ? const Color(0xFFFB923C) // Orange for hosts
                                          : const Color(0xFFFCD34D), // Yellow/gold for users
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              // Message text
                              Text(
                                message.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Timestamp below bubble
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
    
    // Only animate if message hasn't been animated yet
    if (!hasAnimated) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('anim_${message.messageId}'),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)), // Slide up from bottom
            child: Opacity(
              opacity: value, // Fade in
              child: messageContent,
          ),
        );
      },
    );
    }
    
    // Return content directly without animation for already-animated messages
    return messageContent;
  }
}











