import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Mock messages data
  final List<Map<String, dynamic>> messages = [
    {
      'name': 'Coin Reseller 1',
      'avatar': Icons.store,
      'lastMessage': 'Price list: 100 coins = \$0.99',
      'time': '2m ago',
      'unread': 2,
      'isReseller': true,
    },
    {
      'name': 'Sarah Johnson',
      'avatar': Icons.person,
      'lastMessage': 'Thanks for the gift!',
      'time': '10m ago',
      'unread': 0,
      'isReseller': false,
    },
    {
      'name': 'Coin Reseller 2',
      'avatar': Icons.store,
      'lastMessage': 'QR code sent. Please confirm payment.',
      'time': '1h ago',
      'unread': 1,
      'isReseller': true,
    },
    {
      'name': 'Mike Chen',
      'avatar': Icons.person,
      'lastMessage': 'See you in the next stream!',
      'time': '3h ago',
      'unread': 0,
      'isReseller': false,
    },
    {
      'name': 'Admin Support',
      'avatar': Icons.support_agent,
      'lastMessage': 'Your account has been verified',
      'time': '1d ago',
      'unread': 0,
      'isReseller': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            try {
              Navigator.pop(context);
            } catch (e) {
              debugPrint('Error navigating back: $e');
            }
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.messages,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Messages List
          Expanded(
            child: _buildMessagesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
            // TODO: Implement search functionality
          },
        ),
      ),
    );
  }

  // ========== MESSAGES LIST ==========
  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: _buildMessageTile(messages[index]),
        );
      },
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> message) {
    // Light purple color for unread messages (more visible purple tint)
    final Color lightPurple = const Color(0xFFE1BEE7); // More visible light purple
    final Color backgroundColor = message['unread'] > 0 ? lightPurple : Colors.white;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: backgroundColor, // Light purple for unread, white for read
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
        color: Colors.transparent, // Make Material transparent so Container color shows
        child: InkWell(
          onTap: () {
            // TODO: Open chat screen
            _showChatDialog(message['name']);
          },
          borderRadius: BorderRadius.circular(10),
          splashColor: const Color(0xFF9C27B0).withValues(alpha: 0.1), // Purple splash
          highlightColor: const Color(0xFF9C27B0).withValues(alpha: 0.05), // Purple highlight
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: message['isReseller']
                          ? Colors.purple.withValues(alpha: 0.1)
                          : const Color(0xFF9C27B0).withValues(alpha: 0.1),
                      child: Icon(
                        message['avatar'],
                        color: message['isReseller'] ? Colors.purple : const Color(0xFF9C27B0),
                        size: 20,
                      ),
                    ),
                    if (message['unread'] > 0)
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
                            message['unread'].toString(),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message['name'],
                              style: TextStyle(
                                fontWeight: message['unread'] > 0 ? FontWeight.bold : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (message['isReseller']) ...[
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.reseller.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        message['lastMessage'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: message['unread'] > 0 ? Colors.black87 : Colors.grey,
                          fontWeight: message['unread'] > 0 ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Time
                Text(
                  message['time'],
                  style: TextStyle(
                    fontSize: 10,
                    color: message['unread'] > 0 ? const Color(0xFF9C27B0) : Colors.grey,
                    fontWeight: message['unread'] > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChatDialog(String name) {
    if (!mounted) return;
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(context)!.chatWith(name)),
          content: Text(AppLocalizations.of(context)!.fullChatInterfaceComingSoon),
          actions: [
            TextButton(
              onPressed: () {
                try {
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('Error closing chat dialog: $e');
                }
              },
              child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: Color(0xFF9C27B0))),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error showing chat dialog: $e');
    }
  }
}

