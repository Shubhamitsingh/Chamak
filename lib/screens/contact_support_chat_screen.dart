import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/support_chat_service.dart';
import '../services/database_service.dart';
import '../models/message_model.dart';

class ContactSupportChatScreen extends StatefulWidget {
  const ContactSupportChatScreen({super.key});

  @override
  State<ContactSupportChatScreen> createState() => _ContactSupportChatScreenState();
}

class _ContactSupportChatScreenState extends State<ContactSupportChatScreen> {
  final SupportChatService _supportChatService = SupportChatService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _currentUserId;
  String? _chatId;
  bool _isInitializing = true;
  bool _containsDigitsWarning = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _initializeChat();
    
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

  // Check if message contains any numbers (digits OR words)
  bool _containsAnyNumbers(String text) {
    // Check for digits
    if (RegExp(r'\d').hasMatch(text)) return true;
    
    // Check for number words
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

  // Initialize support chat - create or get existing
  Future<void> _initializeChat() async {
    if (_currentUserId == null) {
      setState(() {
        _isInitializing = false;
      });
      return;
    }

    try {
      // Get user data
      final userData = await _databaseService.getUserData(_currentUserId!);
      final userName = userData?.displayName ?? 
                      _auth.currentUser?.displayName ?? 
                      _auth.currentUser?.phoneNumber ?? 
                      'User';
      final userPhone = userData?.phoneNumber ?? 
                       _auth.currentUser?.phoneNumber ?? '';
      final numericUserId = userData?.numericUserId ?? '';

      // Create or get support chat (include numericUserId for admin identification)
      final chatId = await _supportChatService.createOrGetSupportChat(
        _currentUserId!,
        userName,
        userPhone,
        numericUserId, // Pass numeric user ID
      );

      setState(() {
        _chatId = chatId;
        _isInitializing = false;
      });

      // Mark messages as read when opening chat
      _supportChatService.markMessagesAsRead(chatId, false); // false = user side
    } catch (e) {
      debugPrint('❌ Error initializing support chat: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || 
        _currentUserId == null || 
        _chatId == null) return;

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
      return;
    }

    _messageController.clear();

    final success = await _supportChatService.sendMessage(
      chatId: _chatId!,
      senderId: _currentUserId!,
      message: message,
      isAdmin: false, // User is sending
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
          SnackBar(
            content: const Row(
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
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
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
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: 65,
        titleSpacing: 12,
        title: Row(
          children: [
            // Support Agent Avatar
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00BCD4),
                  width: 1.5,
                ),
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF00BCD4),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Support Agent Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Support Team',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.black87,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00BCD4),
              ),
            )
          : _chatId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Unable to initialize chat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please try again later.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _initializeChat();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00BCD4).withValues(alpha: 0.1),
                            const Color(0xFF00E5FF).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00BCD4),
                                  Color(0xFF00E5FF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/chat.png',
                              width: 22,
                              height: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'What is your question?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Our support team will reply shortly ⚡',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Messages List
                    Expanded(
                      child: StreamBuilder<List<MessageModel>>(
                        stream: _supportChatService.getSupportChatMessages(_chatId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00BCD4),
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
                                    'Start a conversation with our support team',
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _containsDigitsWarning 
                                    ? Colors.grey[400] 
                                    : const Color(0xFF00BCD4),
                                shape: BoxShape.circle,
                                boxShadow: _containsDigitsWarning 
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
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

  Widget _buildMessageBubble(MessageModel message, bool isSentByMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF00BCD4),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 14,
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
                gradient: isSentByMe
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF00BCD4),
                          Color(0xFF00E5FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSentByMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isSentByMe ? 14 : 4),
                  bottomRight: Radius.circular(isSentByMe ? 4 : 14),
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
                      color: isSentByMe ? Colors.white : Colors.black87,
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
                          color: isSentByMe
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey[500],
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isSentByMe) ...[
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
          if (isSentByMe) const SizedBox(width: 6),
        ],
      ),
    );
  }
}
