import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/gift_model.dart';
import '../models/call_request_model.dart';
import '../services/chat_service.dart';
import '../services/call_request_service.dart';
import '../services/agora_token_service.dart';
import '../services/database_service.dart';
import '../widgets/call_request_dialog.dart';
import 'user_profile_view_screen.dart';
import 'private_call_screen.dart';
import 'wallet_screen.dart';

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
  final CallRequestService _callRequestService = CallRequestService();
  final AgoraTokenService _tokenService = AgoraTokenService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  bool _containsDigitsWarning = false;
  
  // Call request state
  String? _currentCallRequestId;
  bool _isCallRequestPending = false; // Track if call request is pending
  bool _isCallRejected = false; // Track if call was rejected
  StreamSubscription<List<CallRequestModel>>? _incomingCallSubscription;
  StreamSubscription<CallRequestModel?>? _callStatusSubscription;

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

    // Setup incoming call listener
    _setupIncomingCallListener();

    // ✅ REMOVED: Immediate popup trigger
    // Review popup will now show after successful actions (calls, etc.)
  }


  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _incomingCallSubscription?.cancel();
    _callStatusSubscription?.cancel();
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        toolbarHeight: 52, // Reduced from default 56px
        leadingWidth: 40, // Reduced leading width for less space
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22), // Slightly smaller icon
          padding: EdgeInsets.zero, // Remove default padding
          constraints: const BoxConstraints(), // Remove default constraints
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
              // Real-time profile image updates from Firestore
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.otherUser.uid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  // Get real-time profile image from Firestore
                  String profileImage = widget.otherUser.profileImage; // Fallback to passed value
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    profileImage = userData?['photoURL'] ?? userData?['profileImage'] ?? widget.otherUser.profileImage;
                  }
                  
                  return CircleAvatar(
                    radius: 15, // Reduced from 18 to 15 (30px diameter instead of 36px)
                    // Soft pink-purple so header avatar matches chat theme
                    backgroundColor: const Color(0xFFCE93D8),
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage.isEmpty
                        ? Text(
                            widget.otherUser.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14, // Reduced from 16 to match smaller avatar
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 8), // Reduced from 10 to 8
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.otherUser.uid)
                                .snapshots(),
                            builder: (context, userSnapshot) {
                              int hostLevel = 1;
                              bool isHost = false;
                              
                              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                // Get hostLevel - try hostLevel first, then level, default to 1
                                hostLevel = userData?['hostLevel'] ?? userData?['level'] ?? 1;
                                isHost = userData?['isHost'] ?? false;
                              }
                              
                              // Show level badge if user is a host (isHost = true)
                              final shouldShowLevel = isHost;
                              
                              return Row(
                                mainAxisSize: MainAxisSize.min,
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
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (shouldShowLevel) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF1B7C), Color(0xFFE91E63)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Lv.$hostLevel',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
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
            onTap: _initiateVideoCall,
            child: Container(
              margin: const EdgeInsets.only(right: 6), // Reduced from 8 to 6
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Reduced from (12, 8) to (10, 6)
              decoration: BoxDecoration(
                color: const Color(0xFFFF1B7C), // App theme color
                borderRadius: BorderRadius.circular(18), // Slightly reduced from 20 to 18
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/video.png',
                    width: 16, // Reduced from 18 to 16
                    height: 16, // Reduced from 18 to 16
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5), // Reduced from 6 to 5
                  const Text(
                    'Video Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11, // Reduced from 12 to 11
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2, // Reduced from 0.3 to 0.2
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
      body: Stack(
        children: [
          // Main Content
          Column(
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

                  // Gift Icon Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB800), Color(0xFFFFD700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x80FFB800),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showGiftPopup,
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Image.asset(
                            'assets/images/gift-box.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.card_giftcard_rounded,
                                color: Colors.white,
                                size: 22,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button - Compact & Modern
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _containsDigitsWarning ? Colors.grey[400] : const Color(0xFFFF1B7C), // App theme color
                      shape: BoxShape.circle,
                      boxShadow: _containsDigitsWarning 
                          ? null
                          : const [
                              BoxShadow(
                                color: Color(0x80FF1B7C),
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
          
          // Call request popup (top-left side, similar to live stream screen)
          if (_isCallRequestPending)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 80,
              child: _buildCallRequestPopup(),
            ),
          
          // Call rejected popup (top-left, just below calling popup)
          if (_isCallRejected)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 130,
              child: _buildCallRejectedPopup(),
            ),
        ],
      ),
    );
  }

  // Build call request popup (shows "Calling" when request is pending)
  Widget _buildCallRequestPopup() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final callerPhotoUrl = currentUser?.photoURL;
    
    return SlideInLeft(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: FadeInLeft(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF9C27B0), // Purple
                Color(0xFFE91E63), // Pink
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Caller profile icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipOval(
                  child: callerPhotoUrl != null && callerPhotoUrl.isNotEmpty
                      ? Image.network(
                          callerPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withValues(alpha: 0.3),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 14,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.white.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // Text
              const Text(
                'Calling',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              // Receiver profile icon - Real-time updates
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.otherUser.uid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  // Get real-time profile image from Firestore
                  String profileImage = widget.otherUser.profileImage; // Fallback
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    profileImage = userData?['photoURL'] ?? userData?['profileImage'] ?? widget.otherUser.profileImage;
                  }
                  
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: ClipOval(
                      child: profileImage.isNotEmpty
                          ? Image.network(
                              profileImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.white.withValues(alpha: 0.3),
                              child: Text(
                                widget.otherUser.name.isNotEmpty 
                                    ? widget.otherUser.name[0].toUpperCase() 
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              // Cancel icon
              GestureDetector(
                onTap: () async {
                  if (_currentCallRequestId != null) {
                    try {
                      await _callRequestService.cancelCallRequest(_currentCallRequestId!);
                      setState(() {
                        _isCallRequestPending = false;
                        _currentCallRequestId = null;
                      });
                    } catch (e) {
                      debugPrint('❌ Error cancelling call request: $e');
                    }
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build call rejected popup (shows "User declined" when call is rejected)
  Widget _buildCallRejectedPopup() {
    return SlideInLeft(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: FadeInLeft(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE53935), // Red
                Color(0xFFD32F2F), // Darker red
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.call_end,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'User declined call',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildMessageBubble(MessageModel message, bool isSentByMe) {
    // Check if message is a gift
    final isGift = message.type == MessageType.gift;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble Container
          Row(
            mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isGift 
                        ? MediaQuery.of(context).size.width * 0.55 
                        : MediaQuery.of(context).size.width * 0.75, // Limited to 75% for regular messages
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: isGift ? 8 : 0,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isGift ? 12 : 12, // Reduced from 16 to 12
                    vertical: isGift ? 12 : 8,     // Reduced from 10 to 8
                  ),
                  decoration: BoxDecoration(
                    color: isGift
                        ? isSentByMe
                            ? const Color(0xFFFFB800).withValues(alpha: 0.15)
                            : Colors.white
                        : isSentByMe
                            ? const Color(0xFFFF1B7C)
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      topRight: const Radius.circular(8),
                      bottomLeft: Radius.circular(isSentByMe ? 8 : 2),
                      bottomRight: Radius.circular(isSentByMe ? 2 : 8),
                    ),
                    border: isGift
                        ? Border.all(
                            color: isSentByMe
                                ? const Color(0xFFFFB800).withValues(alpha: 0.5)
                                : const Color(0xFFFFB800).withValues(alpha: 0.3),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isGift
                            ? const Color(0xFFFFB800).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: isGift ? 8 : 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isGift
                      ? Center(
                          child: Column(
                            children: [
                              // Gift Icon/Emoji (compact size)
                              Text(
                                message.giftEmoji ?? '🎁',
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 6),
                              // Gift Name
                              Text(
                                '${message.giftEmoji ?? ''} ${message.giftName ?? 'Gift'}',
                                style: TextStyle(
                                  color: isSentByMe ? Colors.black87 : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (message.giftCost != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/coin3.png',
                                      width: 12,
                                      height: 12,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.monetization_on, size: 12, color: Color(0xFFFFB800));
                                      },
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${message.giftCost}',
                                      style: TextStyle(
                                        color: const Color(0xFFFFB800),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )
                      : Text(
                          message.message,
                          style: TextStyle(
                            color: isSentByMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
          // Time/Date OUTSIDE bubble
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isSentByMe ? 0 : 8,
              right: isSentByMe ? 8 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                if (isSentByMe && !isGift) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                ],
              ],
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

  // Setup incoming call listener for chat calls
  void _setupIncomingCallListener() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _incomingCallSubscription = _callRequestService
        .listenToIncomingChatCallRequests(currentUserId)
        .listen((requests) {
      if (requests.isNotEmpty && mounted) {
        final request = requests.first;
        _showIncomingCallDialog(request);
      }
    });
  }

  // Initiate video call from chat screen
  Future<void> _initiateVideoCall() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to start a video call'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if calling yourself
    if (currentUser.uid == widget.otherUser.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot call yourself'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Request permissions
    if (!mounted) return;
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied || micStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and microphone permissions are required for video calls'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enable camera and microphone permissions in app settings'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
      ),
    );

    try {
      // Get current user data
      final userData = await _databaseService.getUserData(currentUser.uid);
      final callerName = userData?.displayName ?? userData?.name ?? currentUser.displayName ?? 'User';
      final callerImage = userData?.photoURL ?? currentUser.photoURL;

      // Create call request
      final requestId = await _callRequestService.sendChatCallRequest(
        callerId: currentUser.uid,
        callerName: callerName,
        callerImage: callerImage,
        receiverId: widget.otherUser.uid,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      setState(() {
        _currentCallRequestId = requestId;
        _isCallRequestPending = true; // Show calling popup
        _isCallRejected = false; // Reset rejected state
      });

      // Listen for call request status (accepted/rejected)
      _callStatusSubscription?.cancel(); // Cancel previous subscription if any
      _callStatusSubscription = _callRequestService
          .listenToCallRequestStatus(requestId)
          .listen((callRequest) async {
        if (callRequest == null || !mounted) return;

        if (callRequest.status == 'accepted') {
          // Call accepted - navigate to call screen
          _callStatusSubscription?.cancel();
          
          if (!mounted) return;
          
          setState(() {
            _isCallRequestPending = false;
            _currentCallRequestId = null;
          });
          
          final callChannelName = callRequest.callChannelName ?? 'private_call_$requestId';
          final callToken = callRequest.callToken;
          
          if (callToken == null || callToken.isEmpty) {
            // Generate token if not available
            try {
              final generatedToken = await _tokenService.getHostToken(
                channelName: callChannelName,
              );
              
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivateCallScreen(
                      callChannelName: callChannelName,
                      callToken: generatedToken,
                      streamId: '', // Empty for chat calls
                      requestId: requestId,
                      otherUserId: widget.otherUser.uid,
                      otherUserName: widget.otherUser.name,
                      otherUserImage: widget.otherUser.profileImage,
                      isHost: false, // Caller is not host in chat calls
                    ),
                  ),
                );
              }
            } catch (e) {
              debugPrint('❌ Error generating token: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to start call. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // Token already available
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivateCallScreen(
                    callChannelName: callChannelName,
                    callToken: callToken,
                    streamId: '', // Empty for chat calls
                    requestId: requestId,
                    otherUserId: widget.otherUser.uid,
                    otherUserName: widget.otherUser.name,
                    otherUserImage: widget.otherUser.profileImage,
                    isHost: false, // Caller is not host in chat calls
                  ),
                ),
              );
            }
          }
        } else if (callRequest.status == 'rejected') {
          // Call rejected - show rejected popup
          _callStatusSubscription?.cancel();
          if (mounted) {
            setState(() {
              _isCallRequestPending = false;
              _isCallRejected = true;
              _currentCallRequestId = null;
            });
            // Auto-hide rejected popup after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _isCallRejected = false;
                });
              }
            });
          }
        } else if (callRequest.status == 'cancelled' || callRequest.status == 'ended') {
          // Call cancelled or ended
          _callStatusSubscription?.cancel();
          if (mounted) {
            setState(() {
              _isCallRequestPending = false;
              _isCallRejected = false;
              _currentCallRequestId = null;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error initiating video call: $e');
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      // Show themed dialog for insufficient balance
      if (e.toString().contains('Insufficient')) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        _showInsufficientBalanceDialog(errorMessage);
      } else if (e.toString().contains('timeout')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request timed out. Please check your connection.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start video call. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Show incoming call dialog
  void _showIncomingCallDialog(CallRequestModel request) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CallRequestDialog(
        callRequest: request,
        onAccept: () => _handleAcceptCall(request),
        onReject: () => _handleRejectCall(request.requestId),
      ),
    );
  }

  // Handle accept call
  Future<void> _handleAcceptCall(CallRequestModel request) async {
    try {
      // Generate call channel name and token
      final callChannelName = 'private_call_${request.requestId}';
      final callToken = await _tokenService.getHostToken(
        channelName: callChannelName,
      );

      // Accept call request
      await _callRequestService.acceptCallRequest(
        requestId: request.requestId,
        streamId: null, // No streamId for chat calls
        callerId: request.callerId,
        callChannelName: callChannelName,
        callToken: callToken,
      );

      if (!mounted) return;
      
      // Navigate to call screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrivateCallScreen(
            callChannelName: callChannelName,
            callToken: callToken,
            streamId: '', // Empty for chat calls
            requestId: request.requestId,
            otherUserId: request.callerId,
            otherUserName: request.callerName,
            otherUserImage: request.callerImage,
            isHost: true, // Receiver is host (doesn't pay coins)
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle reject call
  Future<void> _handleRejectCall(String requestId) async {
    try {
      await _callRequestService.rejectCallRequest(requestId);
    } catch (e) {
      debugPrint('❌ Error rejecting call: $e');
    }
  }

  // Show insufficient balance dialog - Matching Telegram/Play Store rating popup style
  void _showInsufficientBalanceDialog(String errorMessage) {
    if (!mounted) return;
    
    // Extract balance from error message
    final balanceMatch = RegExp(r'Your balance: (\d+) coins').firstMatch(errorMessage);
    final currentBalance = balanceMatch?.group(1) ?? '0';
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: FadeInDown(
          duration: const Duration(milliseconds: 400),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient and wallet icon (matching Telegram popup)
                _buildInsufficientBalanceHeader(),
                
                // Content box (matching Telegram popup)
                _buildInsufficientBalanceContent(currentBalance),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build header for insufficient balance dialog
  Widget _buildInsufficientBalanceHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF1B7C), // Pink
            Color(0xFF9C27B0), // Purple
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wallet icon on the left
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          // Title - truly centered
          const Text(
            'Insufficient Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          // Close icon on the right
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // Build content for insufficient balance dialog
  Widget _buildInsufficientBalanceContent(String currentBalance) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message with icon (matching Telegram popup)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1B7C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFFF1B7C),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Low Balance',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Description text
          Text(
            'You need at least 300 coins to start a video call.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Balance display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFFFF1B7C),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Balance: $currentBalance coins',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Benefits list (compact)
          _buildRechargeBenefits(),
          
          const SizedBox(height: 10),
          
          // Recharge button (matching Telegram Join button style)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to wallet screen
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WalletScreen(
                        phoneNumber: currentUser.phoneNumber ?? '',
                        isHost: false,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1B7C), // Pink (matching app theme)
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Recharge Wallet',
                    style: TextStyle(
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

  // Build recharge benefits list (compact)
  Widget _buildRechargeBenefits() {
    final benefits = [
      {'emoji': '💰', 'text': 'Instant recharge'},
      {'emoji': '🎁', 'text': 'Bonus offers'},
      {'emoji': '💎', 'text': 'Unlimited calls'},
    ];

    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(
                benefit['emoji']!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  benefit['text']!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
              const SizedBox(height: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    letterSpacing: 0.1,
                    height: 1.2,
                  ),
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

  // Show Gift Selection Popup
  void _showGiftPopup() {
    if (_currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GiftSelectionPopup(
        onGiftSelected: (gift) async {
          Navigator.pop(context); // Close popup
          await _sendGift(gift);
        },
        currentUserId: _currentUserId!,
        chatId: widget.chatId,
        receiverId: widget.otherUser.uid,
      ),
    );
  }

  // Send Gift
  Future<void> _sendGift(GiftModel gift) async {
    if (_currentUserId == null) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF1B7C),
        ),
      ),
    );

    try {
      final success = await _chatService.sendGift(
        chatId: widget.chatId,
        senderId: _currentUserId!,
        receiverId: widget.otherUser.uid,
        gift: gift,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        // Scroll to bottom after sending gift
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text('${gift.emoji} ${gift.name} sent!'),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                ],
              ),
              backgroundColor: const Color(0xFFFF1B7C),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Show themed dialog for insufficient balance
      if (e.toString().contains('Insufficient')) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        _showInsufficientBalanceDialog(errorMessage);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Failed to send gift. Please try again.')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }
}

// Gift Selection Popup Widget
class _GiftSelectionPopup extends StatefulWidget {
  final Function(GiftModel) onGiftSelected;
  final String currentUserId;
  final String chatId;
  final String receiverId;

  const _GiftSelectionPopup({
    required this.onGiftSelected,
    required this.currentUserId,
    required this.chatId,
    required this.receiverId,
  });

  @override
  State<_GiftSelectionPopup> createState() => _GiftSelectionPopupState();
}

class _GiftSelectionPopupState extends State<_GiftSelectionPopup> {
  final ChatService _chatService = ChatService();
  int _userCoinBalance = 0;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadCoinBalance();
  }

  Future<void> _loadCoinBalance() async {
    try {
      final balance = await _chatService.getUserCoinBalance(widget.currentUserId);
      if (mounted) {
        setState(() {
          _userCoinBalance = balance;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading coin balance: $e');
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  List<GiftModel> get _currentGifts {
    // Use default gifts for chat (simple gift selection)
    return GiftModel.getDefaultGifts();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title and Coin Balance
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Send Gift',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_isLoadingBalance)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/coin3.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.monetization_on, size: 18, color: Color(0xFFFFB800));
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCoinBalance(_userCoinBalance),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB800),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

              // Gift Grid
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _currentGifts.length,
                  itemBuilder: (context, index) {
                    final gift = _currentGifts[index];
                    final canAfford = _userCoinBalance >= gift.cost;
                    
                    return _buildGiftCard(gift, canAfford);
                  },
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCard(GiftModel gift, bool canAfford) {
    return GestureDetector(
      onTap: canAfford ? () => widget.onGiftSelected(gift) : null,
      child: Container(
        decoration: BoxDecoration(
          color: canAfford ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canAfford 
                ? const Color(0xFFFF1B7C).withValues(alpha: 0.3)
                : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: canAfford
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gift Emoji
            Text(
              gift.emoji,
              style: TextStyle(
                fontSize: 32,
                color: canAfford ? null : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            // Gift Name
            Text(
              gift.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: canAfford ? Colors.black87 : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Gift Cost
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/coin3.png',
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
                  color: canAfford ? null : Colors.grey[400],
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.monetization_on,
                      size: 12,
                      color: canAfford ? const Color(0xFFFFB800) : Colors.grey[400],
                    );
                  },
                ),
                const SizedBox(width: 2),
                Text(
                  '${gift.cost}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: canAfford ? const Color(0xFFFFB800) : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCoinBalance(int balance) {
    final balanceStr = balance.toString();
    final buffer = StringBuffer();
    
    for (int i = 0; i < balanceStr.length; i++) {
      if (i > 0 && (balanceStr.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(balanceStr[i]);
    }
    
    return buffer.toString();
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


