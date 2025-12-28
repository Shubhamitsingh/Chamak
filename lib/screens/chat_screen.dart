import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import 'user_profile_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  bool _containsDigitsWarning = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Mark messages as read when opening chat
    if (_currentUserId != null) {
      _chatService.markMessagesAsRead(widget.chatId, _currentUserId!);
    }

    // Listen for numbers (digits or words) while typing
    _messageController.addListener(() {
      final hasNumbers = _containsAnyNumbers(_messageController.text);
      if (hasNumbers != _containsDigitsWarning) {
        setState(() {
          _containsDigitsWarning = hasNumbers;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      // Use word boundaries to avoid false positives (e.g., "someone", "phone")
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

    // Security: Block messages containing digits or number words (prevent phone number sharing)
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
      return; // Don't send the message
    }

    _messageController.clear();

    final success = await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: _currentUserId!,
      receiverId: widget.otherUser.uid,
      message: message,
    );

    if (success) {
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      // Older - show date and time
      return DateFormat('dd/MM/yy HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileViewScreen(user: widget.otherUser),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                // Soft pink-purple so header avatar matches chat theme
                backgroundColor: const Color(0xFFCE93D8),
                backgroundImage: widget.otherUser.profileImage.isNotEmpty
                    ? NetworkImage(widget.otherUser.profileImage)
                    : null,
                child: widget.otherUser.profileImage.isEmpty
                    ? Text(
                        widget.otherUser.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                      widget.otherUser.name,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Verified Badge (Starburst)
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF1DA1F2),
                          size: 18,
                        ),
                      ],
                    ),
                    // Online status (you can implement later)
                    // Text(
                    //   'Online',
                    //   style: TextStyle(
                    //     color: Colors.green,
                    //     fontSize: 12,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Video Call Button with Container
          GestureDetector(
            onTap: () {
              // Video call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Image.asset('assets/images/video.png', width: 20, height: 20, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('Video call with ${widget.otherUser.name}'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF9C27B0), // solid purple
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x809C27B0),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/video.png',
                    width: 18,
                    height: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Video Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // More options - 3-dot menu opens bottom sheet
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87, size: 22),
            onPressed: () => _showOptionsBottomSheet(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      // Light pink to match app theme
                      color: Color(0xFFFF69B4),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/chat.png', width: 60, height: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start chatting',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest messages at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSentByMe = message.senderId == _currentUserId;
                    return _buildMessageBubble(message, isSentByMe);
                  },
                );
              },
            ),
          ),

          // Message Input - Compact & Dynamic Design
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text Input - Compact Design
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxHeight: 100, // Dynamic height limit
                      ),
                      decoration: BoxDecoration(
                        color: _containsDigitsWarning ? Colors.red[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: _containsDigitsWarning
                            ? Border.all(color: Colors.red, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Padding(
                            padding: const EdgeInsets.only(left: 12, right: 4),
                            child: Icon(
                              _containsDigitsWarning 
                                  ? Icons.warning_amber_rounded 
                                  : Icons.shield_outlined,
                              color: _containsDigitsWarning ? Colors.red : Colors.grey[500],
                              size: 18,
                            ),
                          ),
                          // TextField
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: _containsDigitsWarning 
                                    ? 'Numbers blocked!' 
                                    : 'Message...',
                                hintStyle: TextStyle(
                                  color: _containsDigitsWarning 
                                      ? Colors.red[700] 
                                      : Colors.grey[500],
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 10,
                                ),
                              ),
                              maxLines: 4,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button - Compact & Modern
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: _containsDigitsWarning 
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFFFF1B7C), Color(0xFF9C27B0)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      color: _containsDigitsWarning ? Colors.grey[400] : null,
                      shape: BoxShape.circle,
                      boxShadow: _containsDigitsWarning 
                          ? null
                          : const [
                              BoxShadow(
                                color: Color(0x809C27B0),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _containsDigitsWarning ? null : _sendMessage,
                        borderRadius: BorderRadius.circular(20),
                        child: Icon(
                          _containsDigitsWarning ? Icons.block : Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
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
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isSentByMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                // Use a slightly darker purple for my messages, keep others white
                color: isSentByMe ? const Color(0xFFFF69B4) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
                  bottomRight: Radius.circular(isSentByMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isSentByMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          color: isSentByMe ? Colors.white70 : Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                      if (isSentByMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead ? Colors.white : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 280,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact Icon and Title Section
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Clear Chat?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Delete this conversation permanently?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(height: 1, color: Colors.grey[300]),

              // Compact Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    width: 1,
                    height: 45,
                    color: Colors.grey[300],
                  ),

                  // Delete Button
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to chat list
                        
                        await _chatService.deleteChat(widget.chatId);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  SizedBox(width: 10),
                                  Text('Chat deleted'),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show options bottom sheet
  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // View Profile Option
              _buildBottomSheetOption(
                icon: Icons.person_outline,
                iconColor: const Color(0xFFF48FB1),
                title: 'View Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileViewScreen(user: widget.otherUser),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // Block and Report Option
              _buildBottomSheetOption(
                icon: Icons.block_outlined,
                iconColor: Colors.red,
                title: 'Block and Report',
                onTap: () {
                  Navigator.pop(context);
                  _showBlockAndReportOptions(context);
                },
              ),
              const SizedBox(height: 4),
              // Clear Chat Option
              _buildBottomSheetOption(
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.red,
                title: 'Clear Chat',
                onTap: () {
                  Navigator.pop(context);
                  _showClearChatDialog();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Build bottom sheet option widget
  Widget _buildBottomSheetOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show block and report options
  void _showBlockAndReportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Block User Option
              _buildBottomSheetOption(
                icon: Icons.block_outlined,
                iconColor: Colors.red,
                title: 'Block User',
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(context);
                },
              ),
              const SizedBox(height: 4),
              // Report User Option
              _buildBottomSheetOption(
                icon: Icons.flag_outlined,
                iconColor: Colors.orange,
                title: 'Report User',
                onTap: () {
                  Navigator.pop(context);
                  _reportUser(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Block User
  Future<void> _blockUser(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${widget.otherUser.name}? You won\'t be able to see their profile or receive messages from them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final firestore = FirebaseFirestore.instance;
                // Add user to blocked list
                await firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('blocked')
                    .doc(widget.otherUser.uid)
                    .set({
                  'blockedAt': FieldValue.serverTimestamp(),
                  'blockedUserId': widget.otherUser.uid,
                  'blockedUserName': widget.otherUser.name,
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.otherUser.name} has been blocked'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  // Navigate back after blocking
                  Navigator.pop(context);
                }
              } catch (e) {
                debugPrint('Error blocking user: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to block user. Please try again.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Report User
  Future<void> _reportUser(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ReportUserScreen(
          reportedUserId: widget.otherUser.uid,
          reportedUserName: widget.otherUser.name,
        ),
      ),
    );
  }
}

// Report User Screen
class _ReportUserScreen extends StatelessWidget {
  final String reportedUserId;
  final String reportedUserName;

  const _ReportUserScreen({
    required this.reportedUserId,
    required this.reportedUserName,
  });

  final List<String> _reportReasons = const [
    'I just don\'t like it',
    'Sexual Content',
    'Harassment or threats',
    'Spam',
    'Illegal goods or services',
    'Underage presence',
    'Terrorist offences',
    'Animal cruelty',
    'Child Abuse',
  ];

  void _submitReport(BuildContext context, String reason) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Save report to Firestore
      await FirebaseFirestore.instance.collection('reports').add({
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reporterId': currentUser.uid,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. Our team will review this.'),
            backgroundColor: Color(0xFFFF69B4),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Why are you reporting this?',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Report Reasons List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _reportReasons.length,
              itemBuilder: (context, index) {
                final reason = _reportReasons[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _submitReport(context, reason);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


