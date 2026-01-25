import 'package:flutter/material.dart';
import '../models/live_chat_message_model.dart';
import '../services/realtime_chat_service.dart';

/// Floating Chat Overlay Widget (Read-Only)
/// 
/// Production-grade chat overlay that displays floating message bubbles
/// - Always visible (not toggled)
/// - Read-only (no touch capture)
/// - Max 5-7 messages visible
/// - Auto-removes old messages
/// - Uses Align + Column (not multiple Positioned)
class FloatingChatOverlay extends StatelessWidget {
  final String roomId;
  final String currentUserId;
  final int maxMessages;

  const FloatingChatOverlay({
    super.key,
    required this.roomId,
    required this.currentUserId,
    this.maxMessages = 7, // ✅ PRODUCTION: Max 5-7 messages
  });

  @override
  Widget build(BuildContext context) {
    final chatService = RealtimeChatService();
    
    // ✅ FIX: Return StreamBuilder directly - Stack will handle Positioned
    return StreamBuilder<List<LiveChatMessageModel>>(
      stream: chatService.getVisibleMessages(roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final allMessages = snapshot.data!;
        // ✅ PRODUCTION: Show only last 7 messages
        final visibleMessages = allMessages.length > maxMessages
            ? allMessages.sublist(allMessages.length - maxMessages)
            : allMessages;

        // ✅ FIX: Return SizedBox.shrink if no messages (don't render anything)
        if (visibleMessages.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // ✅ FIX: Return positioned widget - will be used in Stack
        return Positioned(
          left: 8,
          bottom: 100,
          child: IgnorePointer(
            ignoring: true, // ✅ PRODUCTION: Read-only, no touch capture
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: visibleMessages.map((message) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildMessageBubble(context, message),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, LiveChatMessageModel message) {
    final isCurrentUser = message.senderId == currentUserId;
    
    // Handle different message types
    switch (message.type) {
      case LiveChatMessageType.gift:
        return _buildGiftMessage(context, message);
      case LiveChatMessageType.system:
        return _buildSystemMessage(context, message);
      case LiveChatMessageType.userEntry:
      case LiveChatMessageType.userExit:
        return _buildUserActionMessage(context, message);
      default:
        return _buildTextMessage(context, message, isCurrentUser);
    }
  }

  Widget _buildTextMessage(BuildContext context, LiveChatMessageModel message, bool isCurrentUser) {
    // ✅ PRODUCTION: Reference app style: [Pink Icon] ⭐ Username 🦋 : message text
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pink user icon (small circle)
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFFFF69B4), // Pink color
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          // Yellow star emoji
          const Text('⭐', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          // Username (yellow text)
          Flexible(
            child: Text(
              message.senderName,
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          // Butterfly emoji
          const Text('🦋', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          // Message text
          Flexible(
            child: Text(
              ': ${message.message}',
              style: TextStyle(
                color: Colors.grey[300]!,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftMessage(BuildContext context, LiveChatMessageModel message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.message, // Gift emoji + name
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'from ${message.senderName}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context, LiveChatMessageModel message) {
    // ✅ PRODUCTION: Large, prominent with colored text
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        message.message,
        style: TextStyle(
          color: Colors.blue[300]!,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildUserActionMessage(BuildContext context, LiveChatMessageModel message) {
    // ✅ PRODUCTION: White bubble, yellow border, blue badge with crown, yellow text
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.yellow,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blue badge with white crown icon
          if (message.senderLevel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star, // Crown/star icon
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Lv${message.senderLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          // Yellow text message
          Flexible(
            child: Text(
              '${message.senderName} ${message.message}',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
