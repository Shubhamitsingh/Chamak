import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New message feature coming soon!')),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
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
      padding: const EdgeInsets.symmetric(horizontal: 15),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          // TODO: Open chat screen
          _showChatDialog(message['name']);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: message['isReseller']
                  ? Colors.purple.withOpacity(0.1)
                  : const Color(0xFF9C27B0).withOpacity(0.1),
              child: Icon(
                message['avatar'],
                color: message['isReseller'] ? Colors.purple : const Color(0xFF9C27B0),
                size: 30,
              ),
            ),
            if (message['unread'] > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    message['unread'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(
              message['name'],
              style: TextStyle(
                fontWeight: message['unread'] > 0 ? FontWeight.bold : FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (message['isReseller']) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'RESELLER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          message['lastMessage'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: message['unread'] > 0 ? Colors.black87 : Colors.grey,
            fontWeight: message['unread'] > 0 ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: Text(
          message['time'],
          style: TextStyle(
            fontSize: 12,
            color: message['unread'] > 0 ? const Color(0xFF9C27B0) : Colors.grey,
            fontWeight: message['unread'] > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showChatDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Chat with $name'),
        content: const Text('Full chat interface coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF9C27B0))),
          ),
        ],
      ),
    );
  }
}

