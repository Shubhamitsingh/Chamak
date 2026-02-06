import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../models/chat_model.dart';
import '../models/team_message_model.dart';
import '../services/chat_service.dart';
import '../services/database_service.dart';
import '../services/team_message_service.dart';
import 'chat_screen.dart';
import 'team_messages_screen.dart';

class MessagesScreen extends StatefulWidget {
  final bool hideSearchBar;
  final bool hideFloatingButton;
  final bool hideAppBarActions;
  
  const MessagesScreen({
    super.key,
    this.hideSearchBar = false,
    this.hideFloatingButton = false,
    this.hideAppBarActions = false,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final DatabaseService _databaseService = DatabaseService();
  final TeamMessageService _teamMessageService = TeamMessageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // keep flat on scroll
        surfaceTintColor: Colors.transparent, // remove grey tint
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        automaticallyImplyLeading: !widget.hideAppBarActions,
        leading: widget.hideAppBarActions
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  try {
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Error navigating back: $e');
                  }
                },
              ),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.messages,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: widget.hideAppBarActions
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: () {},
                ),
              ],
      ),
      body: Column(
        children: [
          // Search Bar (only if not hidden)
          if (!widget.hideSearchBar) _buildSearchBar(),
          
          // Messages List (includes Chamakz Team container as first item)
          Expanded(
            child: _buildMessagesList(),
          ),
        ],
      ),
      floatingActionButton: widget.hideFloatingButton
          ? null
          : FloatingActionButton(
              onPressed: () {
                // TODO: New message functionality
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.newMessageFeatureComingSoon)),
                );
              },
              backgroundColor: const Color(0xFF9C27B0),
              child: const Icon(Icons.edit),
            ),
    );
  }

  // ========== CHAMAKZ TEAM CHAT ITEM ==========
  Widget _buildChamakzTeamChatItem() {
    // Same structure as chat list items with unread count badge
    return StreamBuilder<int>(
      stream: _teamMessageService.getUnreadTeamMessagesCount(),
      builder: (context, snapshot) {
        // Handle errors
        if (snapshot.hasError) {
          debugPrint('❌ [CHAMAKZ TEAM] Error getting unread count: ${snapshot.error}');
          debugPrint('❌ [CHAMAKZ TEAM] Error details: ${snapshot.error.toString()}');
          
          // Show error state but still allow navigation
          return _buildChamakzTeamItem(
            unreadCount: 0,
            hasUnread: false,
            lastMessage: 'Error loading messages',
            hasError: true,
          );
        }
        
        // Handle loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChamakzTeamItem(
            unreadCount: 0,
            hasUnread: false,
            lastMessage: 'Loading...',
            hasError: false,
          );
        }
        
        final unreadCount = snapshot.data ?? 0;
        final hasUnread = unreadCount > 0;
        
        // Get last message preview
        return StreamBuilder<TeamMessageModel?>(
          stream: _teamMessageService.getTeamMessagesStream().map((messages) => messages.isNotEmpty ? messages.first : null),
          builder: (context, messageSnapshot) {
            String lastMessageText = 'Official messages from team';
            if (messageSnapshot.hasData && messageSnapshot.data != null) {
              final message = messageSnapshot.data!.message;
              lastMessageText = message.length > 40 ? '${message.substring(0, 40)}...' : message;
            }
            
            return _buildChamakzTeamItem(
              unreadCount: unreadCount,
              hasUnread: hasUnread,
              lastMessage: lastMessageText,
              hasError: false,
            );
          },
        );
      },
    );
  }
  
  Widget _buildChamakzTeamItem({
    required int unreadCount,
    required bool hasUnread,
    required String lastMessage,
    required bool hasError,
  }) {

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
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasError 
                                      ? Colors.red[600]
                                      : hasUnread 
                                          ? Colors.black87 
                                          : Colors.grey[600],
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
  }

  // ========== SEARCH BAR ==========
  Widget _buildSearchBar() {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchMessages,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
    );
  }

  // ========== MESSAGES LIST ==========
  Widget _buildMessagesList() {
    if (_currentUserId == null) {
      return const Center(
        child: Text('Please login to view messages'),
      );
    }

    return StreamBuilder<List<ChatModel>>(
      stream: _chatService.getUserChats(_currentUserId!),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF69B4),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          debugPrint('❌ MessagesScreen Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Get chats
        final chats = snapshot.data ?? [];
        
        // Filter by search query
        final filteredChats = _searchQuery.isEmpty
            ? chats
            : chats.where((chat) {
                final otherUserId = chat.participants.firstWhere(
                  (id) => id != _currentUserId,
                  orElse: () => '',
                );
                final otherUserName = chat.participantNames[otherUserId] ?? '';
                final lastMessage = chat.lastMessage.toLowerCase();
                return otherUserName.toLowerCase().contains(_searchQuery) ||
                       lastMessage.contains(_searchQuery);
              }).toList();

        // Check if there are team messages from admin
        // Chamakz Team should ALWAYS show if admin has sent messages (official messages)
        return StreamBuilder<List<TeamMessageModel>>(
          stream: _teamMessageService.getTeamMessagesStream(),
          builder: (context, teamMessagesSnapshot) {
            // Check if team messages exist (handle loading state)
            final hasTeamMessages = teamMessagesSnapshot.hasData && 
                                    teamMessagesSnapshot.data != null && 
                                    teamMessagesSnapshot.data!.isNotEmpty;
            
            // If still loading team messages and no chats, show loading or Chamakz Team
            final isLoadingTeamMessages = teamMessagesSnapshot.connectionState == ConnectionState.waiting;
            
            final hasChats = filteredChats.isNotEmpty;
            
            // ✅ ALWAYS show Chamakz Team if admin has sent messages (official messages)
            // Even if there are no other user chats, Chamakz Team should be visible
            // Show Chamakz Team if: team messages exist OR if there are chats OR while loading (to avoid flicker)
            final showChamakzTeam = hasTeamMessages || hasChats || (isLoadingTeamMessages && !hasChats);
            
            // Only show empty state if we're sure there are NO team messages AND NO chats
            if (!hasChats && !hasTeamMessages && !isLoadingTeamMessages) {
              // No chats AND no team messages (and not loading) - show empty state
              if (_searchQuery.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/chat.png',
                          width: 64,
                          height: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
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
                  ],
                ),
              );
            }
            
            // ✅ Show Chamakz Team if there are team messages OR if there are chats
            // Calculate total items: Chamakz Team (always show if team messages exist or while loading) + chats
            final totalItems = (showChamakzTeam ? 1 : 0) + filteredChats.length;
            
            return ListView.builder(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                // First item (index 0) is Chamakz Team chat item (if should show)
                if (showChamakzTeam && index == 0) {
                  return _buildChamakzTeamChatItem();
                }
                
                // Other items are regular chat messages (adjust index by -1 if Chamakz Team is shown)
                final chatIndex = showChamakzTeam ? index - 1 : index;
                final chat = filteredChats[chatIndex];
                return _buildMessageTileFromChat(chat);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessageTileFromChat(ChatModel chat) {
    if (_currentUserId == null) return const SizedBox.shrink();
    
    // Get other user's ID using helper method
    final otherUserId = chat.getOtherParticipantId(_currentUserId!);
    
    if (otherUserId.isEmpty) return const SizedBox.shrink();
    
    final unreadCount = chat.unreadCount[_currentUserId] ?? 0;
    final lastMessageTime = chat.lastMessageTime;
    
    // Fetch latest user data from Firestore to get current name (not stale cached name)
    return StreamBuilder<DocumentSnapshot>(
      key: ValueKey('user_level_$otherUserId'), // Ensure proper real-time updates
      stream: _firestore.collection('users').doc(otherUserId).snapshots(),
      builder: (context, userSnapshot) {
        // Get fresh name from Firestore, fallback to cached name
        String otherUserName = 'Unknown User';
        String? otherUserImage;
        
        // Initialize level values
        int userLevel = 1;
        int hostLevel = 1;
        bool isHost = false;
        
        // Real-time update: StreamBuilder automatically rebuilds when Firestore data changes
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          otherUserName = userData?['displayName'] ?? 
                         userData?['name'] ?? 
                         chat.participantNames[otherUserId] ?? 
                         'Unknown User';
          otherUserImage = userData?['photoURL'] ?? 
                          chat.participantImages[otherUserId];
          // Get levels - updates in real-time when Firestore data changes
          userLevel = (userData?['userLevel'] ?? userData?['level'] ?? 1) as int;
          hostLevel = (userData?['hostLevel'] ?? userData?['level'] ?? 1) as int;
          isHost = userData?['isHost'] ?? false;
        } else {
          // Fallback to cached data if Firestore fetch fails
          otherUserName = chat.participantNames[otherUserId] ?? 'Unknown User';
          otherUserImage = chat.participantImages[otherUserId];
        }
        
        // Show level for all users: hostLevel if host, userLevel if regular user
        // This value updates automatically when Firestore stream emits new data
        final displayLevel = isHost ? hostLevel : userLevel;
        // Always show level badge (for all users) - real-time updates
        final shouldShowLevel = true;
    
    // Clean design - NO containers, NO borders, NO backgrounds
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: () async {
          // Get other user's full data
          try {
            final otherUser = await _databaseService.getUserData(otherUserId);
            if (otherUser != null && mounted) {
              // Mark messages as read
              await _chatService.markMessagesAsRead(chat.chatId, _currentUserId!);
              
              // Navigate to chat screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    otherUser: otherUser,
                    chatId: chat.chatId,
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error opening chat: $e');
          }
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
          children: [
            // Avatar - Compact size
            Stack(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFFF1B7C).withValues(alpha: 0.1),
                  backgroundImage: otherUserImage != null && otherUserImage.isNotEmpty
                      ? NetworkImage(otherUserImage)
                      : null,
                  child: otherUserImage == null || otherUserImage.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Color(0xFFFF1B7C),
                          size: 14,
                        )
                      : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF1B7C),
                        shape: BoxShape.circle,
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
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and Message - Compact
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
                          otherUserName,
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                            fontSize: 16,
                            color: unreadCount > 0 ? const Color(0xFFFF1B7C) : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (shouldShowLevel) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1B7C), Color(0xFFE91E63)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(4),
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
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.lastMessage.isNotEmpty ? chat.lastMessage : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time - Compact
            Text(
              _formatTimestamp(lastMessageTime),
              style: TextStyle(
                fontSize: 11,
                color: unreadCount > 0 ? const Color(0xFFFF1B7C) : Colors.grey[600],
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
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

}
