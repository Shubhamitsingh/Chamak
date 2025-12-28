import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/support_chat_service.dart';
import '../models/message_model.dart';

class AdminSupportChatScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String numericUserId; // Numeric user ID for easy identification
  final String userName;
  final String userPhone;

  const AdminSupportChatScreen({
    super.key,
    required this.chatId,
    required this.userId,
    required this.numericUserId,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<AdminSupportChatScreen> createState() => _AdminSupportChatScreenState();
}

class _AdminSupportChatScreenState extends State<AdminSupportChatScreen> {
  final SupportChatService _supportChatService = SupportChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _adminId;
  bool _containsDigitsWarning = false;

  @override
  void initState() {
    super.initState();
    _adminId = _auth.currentUser?.uid;
    
    // Mark messages as read when opening chat (pass userId so user sees double ticks)
    if (_adminId != null) {
      _supportChatService.markMessagesAsRead(widget.chatId, true, widget.userId); // true = admin side, pass userId
    }

    // Listen for numbers while typing
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

  // Check if message contains any numbers
  bool _containsAnyNumbers(String text) {
    if (RegExp(r'\d').hasMatch(text)) return true;
    
    final lowerText = text.toLowerCase();
    final numberWords = [
      'zero', 'one', 'two', 'three', 'four',
      'five', 'six', 'seven', 'eight', 'nine'
    ];
    
    for (String word in numberWords) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) {
        return true;
      }
    }
    
    return false;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _adminId == null) return;

    final message = _messageController.text.trim();

    // Block messages containing numbers
    if (_containsAnyNumbers(message)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ Cannot send numbers! Phone numbers are not allowed.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _messageController.clear();

    final success = await _supportChatService.sendMessage(
      chatId: widget.chatId,
      senderId: _adminId!,
      message: message,
      isAdmin: true, // Admin is sending
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to send message. Please try again.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd/MM/yy HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                if (widget.numericUserId.isNotEmpty) ...[
                  Icon(Icons.badge, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'ID: ${widget.numericUserId}',
                    style: TextStyle(
                      color: const Color(0xFF04B104),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 12, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.userPhone,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF04B104).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, size: 16, color: Color(0xFF04B104)),
                SizedBox(width: 4),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF04B104),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _supportChatService.getSupportChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF04B104),
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
                          'Start chatting with ${widget.userName}',
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
                    // Admin messages: senderId == adminId
                    // User messages: senderId == userId
                    final isSentByAdmin = message.senderId == _adminId;
                    return _buildMessageBubble(message, isSentByAdmin);
                  },
                );
              },
            ),
          ),

          // Message Input Section
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxHeight: 100,
                      ),
                      decoration: BoxDecoration(
                        color: _containsDigitsWarning 
                            ? Colors.red[50] 
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: _containsDigitsWarning
                            ? Border.all(color: Colors.red, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12, right: 4),
                            child: Icon(
                              _containsDigitsWarning 
                                  ? Icons.warning_amber_rounded 
                                  : Icons.shield_outlined,
                              color: _containsDigitsWarning 
                                  ? Colors.red 
                                  : Colors.grey[500],
                              size: 18,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: _containsDigitsWarning 
                                    ? 'Numbers blocked!' 
                                    : 'Type your reply...',
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _containsDigitsWarning 
                          ? Colors.grey[400] 
                          : const Color(0xFF04B104),
                      shape: BoxShape.circle,
                      boxShadow: _containsDigitsWarning 
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF04B104).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _containsDigitsWarning ? null : _sendMessage,
                        borderRadius: BorderRadius.circular(20),
                        child: Icon(
                          _containsDigitsWarning 
                              ? Icons.block 
                              : Icons.send_rounded,
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

  Widget _buildMessageBubble(MessageModel message, bool isSentByAdmin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSentByAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSentByAdmin) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue,
              child: Text(
                widget.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSentByAdmin
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF04B104),
                          Color(0xFF038C03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSentByAdmin ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isSentByAdmin ? 14 : 4),
                  bottomRight: Radius.circular(isSentByAdmin ? 4 : 14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isSentByAdmin ? Colors.white : Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          color: isSentByAdmin
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey[500],
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isSentByAdmin) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead ? Colors.white : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSentByAdmin) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF04B104),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

