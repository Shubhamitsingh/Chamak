import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';

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
    // Listen to language provider to force rebuild when locale changes
    final languageProvider = Provider.of<LanguageProvider>(context, listen: true);
    final currentLocale = languageProvider.locale;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
          key: ValueKey('messages_title_${currentLocale.languageCode}'),
          style: const TextStyle(
            color: Color(0xFF9C27B0),
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
          
          // Messages List
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

        // Empty state
        if (filteredChats.isEmpty) {
          return Center(
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
                  _searchQuery.isEmpty
                      ? 'No messages yet'
                      : 'No messages found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        // Build list
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chat = filteredChats[index];
            return FadeInUp(
              delay: Duration(milliseconds: 100 * index),
              child: _buildMessageTileFromChat(chat),
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
      stream: _firestore.collection('users').doc(otherUserId).snapshots(),
      builder: (context, userSnapshot) {
        // Get fresh name from Firestore, fallback to cached name
        String otherUserName = 'Unknown User';
        String? otherUserImage;
        
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          otherUserName = userData?['displayName'] ?? 
                         userData?['name'] ?? 
                         chat.participantNames[otherUserId] ?? 
                         'Unknown User';
          otherUserImage = userData?['photoURL'] ?? 
                          chat.participantImages[otherUserId];
        } else {
          // Fallback to cached data if Firestore fetch fails
          otherUserName = chat.participantNames[otherUserId] ?? 'Unknown User';
          otherUserImage = chat.participantImages[otherUserId];
        }
    
    // Light pink color for unread messages (matching app theme)
    final Color lightPink = const Color(0xFFFFD6E8); // Light pink background (visible pink tint)
    final Color backgroundColor = unreadCount > 0 ? lightPink : Colors.white;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
          borderRadius: BorderRadius.circular(10),
          splashColor: const Color(0xFF9C27B0).withValues(alpha: 0.1),
          highlightColor: const Color(0xFF9C27B0).withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                      backgroundImage: otherUserImage != null && otherUserImage.isNotEmpty
                          ? NetworkImage(otherUserImage)
                          : null,
                      child: otherUserImage == null || otherUserImage.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Color(0xFF9C27B0),
                              size: 20,
                            )
                          : null,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                // Name and Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        otherUserName,
                        style: TextStyle(
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                          color: unreadCount > 0 ? const Color(0xFFFF1B7C) : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        chat.lastMessage.isNotEmpty ? chat.lastMessage : 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Time
                Text(
                  _formatTimestamp(lastMessageTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: unreadCount > 0 ? const Color(0xFFFF1B7C) : Colors.grey,
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

}
