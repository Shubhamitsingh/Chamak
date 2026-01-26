import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';
import '../services/chat_service.dart';
import 'user_profile_view_screen.dart';
import 'chat_screen.dart';

class NearbyUsersScreen extends StatefulWidget {
  const NearbyUsersScreen({super.key});

  @override
  State<NearbyUsersScreen> createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends State<NearbyUsersScreen> {
  final FollowService _followService = FollowService();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleFollow(UserModel targetUser) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Check if already following
    final alreadyFollowing = await _followService.isFollowing(currentUserId, targetUser.uid);
    if (alreadyFollowing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already following this user'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
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
        child: CircularProgressIndicator(
          color: Color(0xFFFF1B7C),
        ),
      ),
    );

    try {
      final success = await _followService.followUser(currentUserId, targetUser);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Now following ${targetUser.displayName ?? targetUser.name}'),
              backgroundColor: const Color(0xFFFF1B7C),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to follow. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleUnfollow(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

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
      final success = await _followService.unfollowUser(currentUserId, targetUserId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unfollowed successfully'),
              backgroundColor: Color(0xFFFF1B7C),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to unfollow. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _startChat(UserModel otherUser) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get current user data
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!currentUserDoc.exists) return;

      final currentUserModel = UserModel.fromFirestore(currentUserDoc);

      // Create or get chat
      final chatId = await _chatService.createOrGetChat(currentUserModel, otherUser);

      if (!mounted) return;

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUser: otherUser,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Keep white when scrolling (no gray overlay)
        scrolledUnderElevation: 0, // No elevation shadow when scrolling
        automaticallyImplyLeading: false, // Remove back button since screen is swipeable
        toolbarHeight: 48, // Reduced height for less space
        title: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4), // Slight left padding
            child: Text(
              isHindi ? 'सभी उपयोगकर्ता' : 'All Users',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        centerTitle: false, // Left align title
      ),
      body: _buildHostsList(),
    );
  }

  Widget _buildHostsList() {
    final currentUserId = _auth.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF1B7C),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading users',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1B7C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new users',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Get all users and sort by location
        final users = <UserModel>[];
        debugPrint('📊 Total documents from query: ${snapshot.data!.docs.length}');
        
        for (var doc in snapshot.data!.docs) {
          // Skip current user
          if (doc.id == currentUserId) {
            debugPrint('⏭️ Skipping current user: ${doc.id}');
            continue;
          }

          try {
            final user = UserModel.fromFirestore(doc);
            users.add(user);
            debugPrint('✅ Added user: ${user.displayName ?? user.name} (${user.country ?? 'No country'})');
          } catch (e) {
            debugPrint('❌ Error parsing user: ${doc.id}, $e');
            continue;
          }
        }
        
        debugPrint('📋 Final users count: ${users.length}');

        // Sort by location (country first, then city)
        users.sort((a, b) {
          final countryA = (a.country ?? '').toLowerCase();
          final countryB = (b.country ?? '').toLowerCase();
          if (countryA != countryB) {
            return countryA.compareTo(countryB);
          }
          final cityA = (a.city ?? '').toLowerCase();
          final cityB = (b.city ?? '').toLowerCase();
          return cityA.compareTo(cityB);
        });

        // Users list - starts from top
        return ListView.builder(
          padding: EdgeInsets.zero, // No padding - starts from top
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildHostCard(user);
          },
        );
      },
    );
  }

  Widget _buildHostCard(UserModel user) {
    // Get country flag
    String? countryFlag;
    final countryCode = user.countryCode;
    if (countryCode.isNotEmpty) {
      try {
        countryFlag = Country.parse(countryCode).flagEmoji;
      } catch (e) {
        final country = user.country;
        if (country != null && country.isNotEmpty) {
          try {
            countryFlag = Country.parse(country).flagEmoji;
          } catch (_) {
            countryFlag = null;
          }
        }
      }
    } else {
      final country = user.country;
      if (country != null && country.isNotEmpty) {
        try {
          countryFlag = Country.parse(country).flagEmoji;
        } catch (_) {
          countryFlag = null;
        }
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileViewScreen(user: user),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            // Avatar
            user.photoURL != null && user.photoURL!.isNotEmpty
                ? CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(user.photoURL!),
                    onBackgroundImageError: (_, __) {},
                  )
                : _buildDefaultAvatar(user.numericUserId),
            const SizedBox(width: 11),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username
                  Text(
                    user.displayName ?? user.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Level, Language, Country - more compact
                  Row(
                    children: [
                      if (user.userLevel > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1B7C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(0xFFFF1B7C).withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'Lv.${user.userLevel}',
                            style: const TextStyle(
                              color: Color(0xFFFF1B7C),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (user.language != null && user.language!.isNotEmpty) ...[
                        if (user.userLevel > 0) const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            user.language!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (user.country != null && user.country!.isNotEmpty) ...[
                        if ((user.userLevel > 0) || (user.language != null && user.language!.isNotEmpty))
                          const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (countryFlag != null) ...[
                                Text(
                                  countryFlag,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 3),
                              ],
                              Flexible(
                                child: Text(
                                  user.country!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 13,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.city != null && user.city!.isNotEmpty
                              ? '${user.city}, ${user.country ?? ''}'
                              : user.country ?? 'Unknown location',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
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
            // Action Buttons (Horizontal Row)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Follow/Unfollow button
                StreamBuilder<DocumentSnapshot>(
                  stream: _auth.currentUser != null
                      ? _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .collection('following')
                          .doc(user.uid)
                          .snapshots()
                      : null,
                  builder: (context, followingSnapshot) {
                    final isFollowing = followingSnapshot.hasData && followingSnapshot.data!.exists;

                    return TextButton(
                      onPressed: () {
                        if (isFollowing) {
                          _handleUnfollow(user.uid);
                        } else {
                          _handleFollow(user);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        backgroundColor: isFollowing ? Colors.grey[100] : const Color(0xFFFF1B7C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        minimumSize: const Size(0, 44), // Fixed: Changed from Size.zero to meet 44px minimum touch target
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isFollowing ? 'Unfollow' : 'Follow',
                        style: TextStyle(
                          color: isFollowing ? Colors.grey[800] : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 7),
                // Chat button
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 19),
                  color: const Color(0xFFFF1B7C),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _startChat(user),
                  tooltip: 'Chat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String numericId) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFFF5F5F5),
      backgroundImage: NetworkImage(
        'https://api.dicebear.com/7.x/avataaars/png?seed=$numericId&backgroundColor=b6e3f4,c0aede,d1d4f9&size=52&randomizeIds=true',
      ),
      onBackgroundImageError: (_, __) {},
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFF1B7C),
        ),
        child: const Icon(
          Icons.person,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}
