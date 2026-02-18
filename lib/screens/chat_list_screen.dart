import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/call_request_model.dart';
import '../models/team_message_model.dart';
import '../services/chat_service.dart';
import '../services/online_status_service.dart';
import '../services/call_request_service.dart';
import '../services/agora_token_service.dart';
import '../services/team_message_service.dart';
import '../widgets/call_request_dialog.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';
import 'private_call_screen.dart';
import '../services/search_service.dart';
import 'team_messages_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final SearchService _searchService = SearchService();
  final OnlineStatusService _onlineStatusService = OnlineStatusService();
  final CallRequestService _callRequestService = CallRequestService();
  final AgoraTokenService _tokenService = AgoraTokenService();
  final TeamMessageService _teamMessageService = TeamMessageService();
  String? _currentUserId;
  
  // Incoming call state
  StreamSubscription<List<CallRequestModel>>? _incomingCallSubscription;
  bool _isCallDialogShowing = false; // Track if call dialog is currently showing (prevent duplicates)

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Setup incoming call listener
    if (_currentUserId != null) {
      _setupIncomingCallListener();
    }
  }
  
  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    super.dispose();
  }

  // ========== CHAMAKZ TEAM CHAT ITEM ==========
  Widget _buildChamakzTeamChatItem() {
    // Same structure as chat list items with unread count badge
    return StreamBuilder<int>(
      stream: _teamMessageService.getUnreadTeamMessagesCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        final hasUnread = unreadCount > 0;

        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeamMessagesScreen(),
                ),
              );
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Avatar - Increased size
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFFF1B7C), // App theme color
                        backgroundImage: const AssetImage('assets/images/splaslogo.png'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Name and Message - Increased size
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Chamakz Team',
                                style: TextStyle(
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 16,
                                  color: hasUnread ? const Color(0xFFFF1B7C) : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Official messages from team',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasUnread ? Colors.black87 : Colors.grey[600],
                                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            // Unread Badge
                            if (hasUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF1B7C), Color(0xFFE0166C)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF1B7C).withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time - Empty (same structure as chat items)
                  Text(
                    '',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(timestamp);
    } else {
      // Older - show date
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }

  // Setup incoming call listener
  void _setupIncomingCallListener() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _incomingCallSubscription = _callRequestService
        .listenToIncomingChatCallRequests(currentUserId)
        .listen((requests) {
      if (requests.isNotEmpty && mounted && !_isCallDialogShowing) {
        final request = requests.first;
        _showIncomingCallDialog(request);
      }
    });
  }

  // Show incoming call dialog
  void _showIncomingCallDialog(CallRequestModel request) {
    if (!mounted || _isCallDialogShowing) return;
    
    setState(() {
      _isCallDialogShowing = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CallRequestDialog(
        callRequest: request,
        onAccept: () => _handleAcceptCall(request),
        onReject: () => _handleRejectCall(request.requestId),
      ),
    ).then((_) {
      // Reset flag when dialog is dismissed
      if (mounted) {
        setState(() {
          _isCallDialogShowing = false;
        });
      }
    });
  }

  // Handle accept call
  Future<void> _handleAcceptCall(CallRequestModel request) async {
    try {
      // Request permissions first
      if (!mounted) return;
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (cameraStatus.isDenied || micStatus.isDenied) {
        if (mounted) {
          // ✅ FIX: Check if we can pop before attempting to pop
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close dialog
          }
          // Reset flag
          setState(() {
            _isCallDialogShowing = false;
          });
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
          // ✅ FIX: Check if we can pop before attempting to pop
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close dialog
          }
          // Reset flag
          setState(() {
            _isCallDialogShowing = false;
          });
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
      
      // Close dialog before navigation
      // ✅ FIX: Check if we can pop before attempting to pop
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      // Reset flag
      setState(() {
        _isCallDialogShowing = false;
      });
      
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
            otherUserImage: request.callerImage ?? '',
            isHost: true, // Receiver is host (doesn't pay coins)
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      if (mounted) {
        // ✅ FIX: Check if we can pop before attempting to pop
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close dialog on error
        }
        // Reset flag
        setState(() {
          _isCallDialogShowing = false;
        });
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
      if (mounted) {
        // ✅ FIX: Check if we can pop before attempting to pop
        // This prevents "Bad state: No element" crash
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close dialog
        }
        // Reset flag even if dialog was already closed
        if (mounted) {
          setState(() {
            _isCallDialogShowing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error rejecting call: $e');
      if (mounted) {
        // ✅ FIX: Check if we can pop before attempting to pop
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close dialog on error
        }
        // Reset flag even if dialog was already closed
        if (mounted) {
          setState(() {
            _isCallDialogShowing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to view messages'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // New Chat Button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat List (includes Chamakz Team as first item)
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.getUserChats(_currentUserId!),
              builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF04B104),
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            print('❌ ChatListScreen Error: ${snapshot.error}');
            final errorMessage = snapshot.error.toString();
            final isIndexError = errorMessage.contains('index') || 
                                  errorMessage.contains('FAILED_PRECONDITION');
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isIndexError ? Icons.warning_amber_rounded : Icons.error_outline, 
                      size: 60, 
                      color: isIndexError ? Colors.orange[400] : Colors.red[400]
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isIndexError ? 'Database Index Required' : 'Something went wrong',
                      style: TextStyle(
                        fontSize: 18, 
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isIndexError 
                          ? 'The chat feature requires a database index.\n\n'
                            '1. Check the console/terminal for a link\n'
                            '2. Click the link to create the index\n'
                            '3. Wait 2-3 minutes\n'
                            '4. Refresh this page'
                          : 'Unable to load chats. Please try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (isIndexError) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Trigger a refresh by rebuilding
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF04B104),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          // Check for team messages - Chamakz Team should ALWAYS show if admin has sent messages
          final chats = snapshot.data ?? [];
          return StreamBuilder<List<TeamMessageModel>>(
            stream: _teamMessageService.getTeamMessagesStream(),
            builder: (context, teamMessagesSnapshot) {
              // Check if team messages exist (even if loading)
              final hasTeamMessages = teamMessagesSnapshot.hasData && 
                                      teamMessagesSnapshot.data != null && 
                                      teamMessagesSnapshot.data!.isNotEmpty;
              
              final hasChats = chats.isNotEmpty;
              
              // ✅ ALWAYS show Chamakz Team if admin has sent messages OR if there are chats
              // Only show empty state if NO team messages AND NO chats
              if (!hasChats && !hasTeamMessages) {
                // No chats AND no team messages - show empty state
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/chat.png', width: 80, height: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search for users to start chatting',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UserSearchScreen()),
                          );
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Find Users'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF04B104),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ✅ Show Chamakz Team if there are team messages OR if there are chats
              // Calculate total items: Chamakz Team (always show) + chats
              final showChamakzTeam = hasTeamMessages || hasChats;
              final totalItems = (showChamakzTeam ? 1 : 0) + chats.length;

              // Chat List with Chamakz Team as first item (scrollable)
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(), // ✅ Ensure scrolling is always enabled
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  // First item (index 0) is Chamakz Team chat item (if should show)
                  if (showChamakzTeam && index == 0) {
                    return _buildChamakzTeamChatItem();
                  }
                  
                  // Other items are regular chat messages (adjust index by -1 if Chamakz Team is shown)
                  final chatIndex = showChamakzTeam ? index - 1 : index;
                  final chat = chats[chatIndex];
                  return _buildChatItem(chat);
                },
              );
            },
          );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat) {
    final otherUserId = chat.getOtherParticipantId(_currentUserId!);
    final otherUserName = chat.getOtherParticipantName(_currentUserId!);
    final otherUserImage = chat.getOtherParticipantImage(_currentUserId!);
    final unreadCount = chat.getUnreadCount(_currentUserId!);
    final hasUnread = unreadCount > 0;

    // Safety check: If otherUserId is empty or null, return a fallback widget
    if (otherUserId.isEmpty) {
      return const SizedBox.shrink(); // Return empty widget if user ID is invalid
    }

    // Clean design - NO containers, NO borders, NO decorations
    return InkWell(
      onTap: () async {
        // Try to fetch user quickly; fall back to cached chat data to reduce lag
        UserModel? otherUser;

        try {
          otherUser = await _searchService
              .getUserById(otherUserId)
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          // ignore and use fallback
        }

        otherUser ??= UserModel(
          userId: otherUserId,
          numericUserId: '',
          phoneNumber: '',
          countryCode: '',
          displayName: otherUserName.isNotEmpty ? otherUserName : null,
          photoURL: otherUserImage.isNotEmpty ? otherUserImage : null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.chatId,
              otherUser: otherUser!,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
              // Profile Image - Real-time updates from Firestore
              Stack(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: otherUserId.isNotEmpty
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .snapshots()
                        : Stream<DocumentSnapshot>.empty(), // Empty stream if userId is invalid
                    builder: (context, userSnapshot) {
                      // Get real-time profile image from Firestore
                      String profileImage = otherUserImage; // Fallback to cached
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                        profileImage = userData?['photoURL'] ?? userData?['profileImage'] ?? otherUserImage;
                      }
                      
                      return CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : null,
                        child: profileImage.isEmpty
                            ? Text(
                                otherUserName.isNotEmpty 
                                    ? otherUserName[0].toUpperCase() 
                                    : 'U',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                  // Real-time status indicator (Live=red, Online=green, Offline=none)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: StreamBuilder<bool>(
                      stream: _onlineStatusService.getUserLiveStatusStream(otherUserId),
                      builder: (context, liveSnapshot) {
                        final isLive = liveSnapshot.data ?? false;
                        
                        return StreamBuilder<String>(
                          stream: _onlineStatusService.getUserStatusStream(otherUserId),
                          builder: (context, onlineSnapshot) {
                            final onlineStatus = onlineSnapshot.data ?? 'offline';
                            final isOnline = onlineStatus == 'online';
                            
                            // Priority: LIVE (red) > ONLINE (green) > OFFLINE (no indicator)
                            Color? indicatorColor;
                            
                            if (isLive) {
                              // LIVE - Red dot
                              indicatorColor = Colors.red;
                            } else if (isOnline) {
                              // ONLINE - Green dot
                              indicatorColor = const Color(0xFF04B104); // Green
                            } else {
                              // OFFLINE - No indicator
                              return const SizedBox.shrink();
                            }
                            
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: indicatorColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Chat Info - Dynamic Layout
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Timestamp Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name with Host Level (Lv.)
                        Expanded(
                          child: StreamBuilder<DocumentSnapshot>(
                            key: ValueKey('user_level_$otherUserId'), // Ensure proper real-time updates
                            stream: otherUserId.isNotEmpty
                                ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(otherUserId)
                                    .snapshots()
                                : Stream<DocumentSnapshot>.empty(), // Empty stream if userId is invalid
                            builder: (context, userSnapshot) {
                              // Initialize with defaults
                              int userLevel = 1;
                              int hostLevel = 1;
                              bool isActive = false;
                              
                              // Real-time update: Get level from Firestore stream
                              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                // Get both userLevel and hostLevel - updates in real-time
                                userLevel = (userData?['userLevel'] ?? userData?['level'] ?? 1) as int;
                                hostLevel = (userData?['hostLevel'] ?? userData?['level'] ?? 1) as int;
                                isActive = userData?['isActive'] ?? false;
                              }
                              
                              // Show level for all users: hostLevel if approved, userLevel if regular user
                              // This updates in real-time when Firestore data changes
                              final displayLevel = isActive ? hostLevel : userLevel;
                              // Always show level badge for all users (real-time)
                              final shouldShowLevel = true;
                              
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      otherUserName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
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
                                        'Lv.$displayLevel',
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
                        const SizedBox(width: 8),
                        // Timestamp Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasUnread 
                                ? const Color(0xFFFF1B7C).withValues(alpha:0.15)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatTimestamp(chat.lastMessageTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUnread ? const Color(0xFFFF1B7C) : Colors.grey[600],
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Last Message Row
                    Row(
                      children: [
                        // Message icon
                        Image.asset(
                          'assets/images/chat.png',
                          width: 14,
                          height: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 6),
                        // Last Message
                        Expanded(
                          child: Text(
                            chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: chat.lastMessage.isEmpty 
                                  ? Colors.grey[400] 
                                  : Colors.grey[600],
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        // Unread Badge
                        if (hasUnread) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF1B7C), Color(0xFFE0166C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF1B7C).withValues(alpha:0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

