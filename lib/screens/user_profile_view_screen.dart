import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class UserProfileViewScreen extends StatefulWidget {
  final UserModel user;

  const UserProfileViewScreen({super.key, required this.user});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  final FollowService _followService = FollowService();
  final ChatService _chatService = ChatService();
  
  bool _isFollowing = false;
  bool _isLoading = true;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final isFollowing = await _followService.isFollowing(currentUserId, widget.user.uid);
      final followersCount = await _followService.getFollowersCount(widget.user.uid);
      final followingCount = await _followService.getFollowingCount(widget.user.uid);

      setState(() {
        _isFollowing = isFollowing;
        _followersCount = followersCount;
        _followingCount = followingCount;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading profile data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      if (_isFollowing) {
        await _followService.unfollowUser(currentUserId, widget.user.uid);
        setState(() {
          _isFollowing = false;
          _followersCount--;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unfollowed ${widget.user.name}'),
            backgroundColor: Colors.grey[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await _followService.followUser(currentUserId, widget.user);
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Following ${widget.user.name}'),
            backgroundColor: const Color(0xFF9C27B0), // purple
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF9C27B0)), // purple
      ),
    );

    try {
      // Get current user data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final currentUserModel = UserModel.fromFirestore(currentUserDoc);

      // Create or get chat
      final chatId = await _chatService.createOrGetChat(currentUserModel, widget.user);

      Navigator.pop(context); // Close loading

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUser: widget.user,
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open chat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Card - Modern Design
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Picture + Stats Row
                  Row(
                    children: [
                      // Smaller Profile Image
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF9C27B0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C27B0).withValues(alpha:0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFF9C27B0),
                            backgroundImage: widget.user.profileImage.isNotEmpty
                                ? NetworkImage(widget.user.profileImage)
                                : null,
                            child: widget.user.profileImage.isEmpty
                                ? Text(
                                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Stats - Compact
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCompactStat('Followers', _followersCount.toString()),
                            Container(
                              height: 35,
                              width: 1,
                              color: Colors.grey[300],
                            ),
                            _buildCompactStat('Following', _followingCount.toString()),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Name and ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.user.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'ID: ${widget.user.numericUserId.substring(0, 7)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      // Follow Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.grey[200] : const Color(0xFF9C27B0),
                            foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: _isFollowing ? 0 : 2,
                            shadowColor: _isFollowing ? null : const Color(0x809C27B0),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isFollowing ? Icons.check : Icons.person_add,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Message Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _openChat,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9C27B0),
                            side: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.message_outlined, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Message',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // User Info Section
            _buildUserInfoSection(),

            const SizedBox(height: 24),

            // Bio Section
            if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.user.bio!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ========== USER INFO SECTION - PROFESSIONAL & UNIQUE ==========
  Widget _buildUserInfoSection() {
    List<Map<String, dynamic>> infoItems = [];

    // Add language if available
    if (widget.user.language != null && widget.user.language!.isNotEmpty) {
      infoItems.add({
        'icon': Icons.translate,
        'label': 'Speaks',
        'value': widget.user.language!,
        'color': const Color(0xFF6366F1),
        'emoji': '🌐',
      });
    }

    // Add age if available
    if (widget.user.age != null) {
      infoItems.add({
        'icon': Icons.calendar_today,
        'label': 'Age',
        'value': '${widget.user.age}',
        'color': const Color(0xFFEC4899),
        'emoji': '🎂',
      });
    }

    // Add gender if available
    if (widget.user.gender != null && widget.user.gender!.isNotEmpty) {
      infoItems.add({
        'icon': widget.user.gender!.toLowerCase() == 'male' 
            ? Icons.person 
            : Icons.person_outline,
        'label': 'Gender',
        'value': widget.user.gender!,
        'color': widget.user.gender!.toLowerCase() == 'male'
            ? const Color(0xFF3B82F6)
            : const Color(0xFFF472B6),
        'emoji': widget.user.gender!.toLowerCase() == 'male' ? '👨' : '👩',
      });
    }

    // Add city and country if available
    if (widget.user.city != null && widget.user.city!.isNotEmpty) {
      String locationValue = widget.user.city!;
      if (widget.user.country != null && widget.user.country!.isNotEmpty) {
        locationValue += ', ${widget.user.country}';
      }
      infoItems.add({
        'icon': Icons.place,
        'label': 'From',
        'value': locationValue,
        'color': const Color(0xFFF59E0B),
        'emoji': '📍',
      });
    } else if (widget.user.country != null && widget.user.country!.isNotEmpty) {
      infoItems.add({
        'icon': Icons.public,
        'label': 'Country',
        'value': widget.user.country!,
        'color': const Color(0xFFF59E0B),
        'emoji': '🌍',
      });
    }

    // Don't show section if no info available
    if (infoItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple Header
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // All info items in rows
            ...infoItems.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> item = entry.value;
              return Column(
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item['color'] as Color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['value'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (index < infoItems.length - 1) ...[
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

}


