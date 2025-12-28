import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';
import '../services/chat_service.dart';
import '../widgets/gift_selection_sheet.dart';
import 'chat_screen.dart';

class UserProfileViewScreen extends StatefulWidget {
  final UserModel user;

  const UserProfileViewScreen({super.key, required this.user});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> with SingleTickerProviderStateMixin {
  final FollowService _followService = FollowService();
  final ChatService _chatService = ChatService();
  
  bool _isFollowing = false;
  bool _isLoading = true;
  int _followersCount = 0;
  int _followingCount = 0;
  
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      debugPrint('❌ Error loading profile data: $e');
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
      } else {
        await _followService.followUser(currentUserId, widget.user);
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
      }
    } catch (e) {
      if (!mounted) return;
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
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final currentUserModel = UserModel.fromFirestore(currentUserDoc);

      // Create or get chat
      final chatId = await _chatService.createOrGetChat(currentUserModel, widget.user);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Navigate to chat screen
      if (!mounted) return;
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
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open chat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showGiftSelectionSheet() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GiftSelectionSheet(
        liveStreamId: '', // Empty for profile gifts (not in live stream)
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'User',
        senderImage: currentUser.photoURL,
        onGiftSelected: _sendGiftToProfile,
      ),
    );
  }

  Future<void> _sendGiftToProfile(String giftName, int giftCost, String giftEmoji) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Deduct coins from sender
      await _firestore.collection('users').doc(currentUser.uid).update({
        'uCoins': FieldValue.increment(-giftCost),
      });

      // Add C coins to recipient (host/user receiving gift)
      await _firestore.collection('users').doc(widget.user.uid).update({
        'cCoins': FieldValue.increment(giftCost),
      });

      // Update earnings for recipient
      final earningsRef = _firestore.collection('earnings').doc(widget.user.uid);
      await earningsRef.set({
        'totalCCoins': FieldValue.increment(giftCost),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create a notification or message about the gift
      // You can expand this to send a chat message or notification
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$giftEmoji $giftName sent to ${widget.user.name}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending gift: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send gift. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  String _formatCCoins(int cCoins) {
    if (cCoins >= 1000000) {
      return '${(cCoins / 1000000).toStringAsFixed(2)}M';
    } else if (cCoins >= 1000) {
      return '${(cCoins / 1000).toStringAsFixed(2)}K';
    }
    return cCoins.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF1B7C)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  
                  // Profile Section - Horizontal Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        // Profile Picture with Pink Gradient Border
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4), Color(0xFFFF1B7C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF1B7C).withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 42,
                          backgroundColor: Colors.grey[300],
                            backgroundImage: widget.user.profileImage.isNotEmpty
                                ? NetworkImage(widget.user.profileImage)
                                : null,
                            child: widget.user.profileImage.isEmpty
                                ? Text(
                                  widget.user.name.isNotEmpty 
                                      ? widget.user.name[0].toUpperCase() 
                                      : 'U',
                                    style: const TextStyle(
                                        color: Colors.black54,
                                    fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // User Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username + Verified Badge
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                widget.user.name,
                                style: const TextStyle(
                                        fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Verified Badge (Starburst)
                                  const Icon(
                                    Icons.verified,
                                    color: Color(0xFF1DA1F2),
                                    size: 20,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 6),
                              
                              // Age, Language, Country - Real Data Row
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  // Age
                                  if (widget.user.age != null)
                                    _buildInfoChip('${widget.user.age} yrs'),
                                  // Language
                                  if (widget.user.language != null && widget.user.language!.isNotEmpty)
                                    _buildInfoChip(widget.user.language!),
                                  // Country
                                  if (widget.user.country != null && widget.user.country!.isNotEmpty)
                                    _buildInfoChip(widget.user.country!),
                                ],
                              ),
                              
                              const SizedBox(height: 6),
                              
                              // Available Status
                              Row(
                                children: [
                                  // Green Available Dot
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Available',
                                    style: TextStyle(
                                    fontSize: 13,
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.w500,
                                  ),
                                ),
                                ],
                              ),
                              
                              // Bio
                              if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  widget.user.bio!.length > 80 
                                      ? '${widget.user.bio!.substring(0, 80)}...'
                                        : widget.user.bio!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                    color: Colors.black54,
                                    ),
                                  maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                ),
                              ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row (3 columns) - Earned, Followers, Following
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Real-time C Coins Earnings
                        StreamBuilder<DocumentSnapshot>(
                          stream: _firestore
                              .collection('earnings')
                              .doc(widget.user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int totalCCoins = 0;
                            
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              totalCCoins = (data?['totalCCoins'] as int?) ?? 0;
                            } else {
                              return StreamBuilder<DocumentSnapshot>(
                                stream: _firestore
                                    .collection('users')
                                    .doc(widget.user.uid)
                                    .snapshots(),
                                builder: (context, userSnapshot) {
                                  int userCCoins = 0;
                                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                    userCCoins = (userData?['cCoins'] as int?) ?? 0;
                                  }
                                  return _buildStatColumn(
                                    number: _formatCCoins(userCCoins),
                                    label: 'Earned',
                                  );
                                },
                              );
                            }
                            
                            return _buildStatColumn(
                              number: _formatCCoins(totalCCoins),
                              label: 'Earned',
                            );
                          },
                        ),
                        // Divider
                        Container(width: 1, height: 30, color: Colors.grey[300]),
                        // Real-time Followers Count
                        StreamBuilder<DocumentSnapshot>(
                          stream: _firestore
                              .collection('users')
                              .doc(widget.user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int followersCount = _followersCount;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              followersCount = (data?['followersCount'] as int?) ?? _followersCount;
                            }
                            return _buildStatColumn(
                              number: _formatNumber(followersCount.toDouble()),
                              label: 'Follower',
                            );
                          },
                        ),
                        // Divider
                        Container(width: 1, height: 30, color: Colors.grey[300]),
                        // Real-time Following Count
                        StreamBuilder<DocumentSnapshot>(
                          stream: _firestore
                              .collection('users')
                              .doc(widget.user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int followingCount = _followingCount;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              followingCount = (data?['followingCount'] as int?) ?? _followingCount;
                            }
                            return _buildStatColumn(
                              number: _formatNumber(followingCount.toDouble()),
                              label: 'Following',
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Start Video Chat Button (Full Width)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1B7C), // Solid pink (no gradient)
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF1B7C).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Video chat with ${widget.user.name}'),
                                backgroundColor: const Color(0xFFFF1B7C),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/video.png',
                                width: 20,
                                height: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Start Video Chat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Follow + Message Buttons Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                    children: [
                        // Follow/Followed Button
                      Expanded(
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseAuth.instance.currentUser != null
                                ? _firestore
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('following')
                                    .doc(widget.user.uid)
                                    .snapshots()
                                : Stream<DocumentSnapshot>.empty(),
                            builder: (context, snapshot) {
                              final isFollowingRealTime = snapshot.hasData && snapshot.data!.exists;
                              
                              return Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF1B7C), // Solid pink (no gradient)
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading ? null : _toggleFollow,
                                    borderRadius: BorderRadius.circular(21),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isFollowingRealTime ? Icons.check : Icons.favorite_border,
                                    color: Colors.white,
                                          size: 18,
                                  ),
                                        const SizedBox(width: 6),
                                                Text(
                                          isFollowingRealTime ? 'Followed' : 'Follow',
                                          style: const TextStyle(
                                            fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Message Button
                        Expanded(
                          child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                              borderRadius: BorderRadius.circular(21),
                            border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _openChat,
                              borderRadius: BorderRadius.circular(21),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/comment.png',
                                      width: 18,
                                      height: 18,
                                color: Colors.black,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Message',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ),
                  ),
                ],
              ),
            ),

                  const SizedBox(height: 24),

                  // Clips Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle_outline, size: 20, color: Colors.black),
                        const SizedBox(width: 6),
                        const Text(
                          'Clips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
                          builder: (context, snapshot) {
                            int clipCount = 0;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              final coverURL = data?['coverURL'] as String?;
                              if (coverURL != null && coverURL.isNotEmpty) {
                                clipCount = coverURL.split(',').where((url) => url.trim().isNotEmpty).length;
                              }
                            }
                            return Text(
                              '$clipCount',
                              style: TextStyle(
                      fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                          ],
                        ),
                      ),
                  
                  const SizedBox(height: 12),
                  
                  // Clips Horizontal Scroll
                  SizedBox(
                    height: 90,
                    child: _buildClipsHorizontalList(),
                  ),

                  const SizedBox(height: 20),

                  // Posts Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                        Image.asset(
                          'assets/images/comment.png',
                          width: 18,
                          height: 18,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Posts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
                          builder: (context, snapshot) {
                            int postCount = 0;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              final coverURL = data?['coverURL'] as String?;
                              if (coverURL != null && coverURL.isNotEmpty) {
                                postCount = coverURL.split(',').where((url) => url.trim().isNotEmpty).length;
                              }
                            }
                            return Text(
                              '$postCount',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Posts Grid
                  _buildPostsGrid(),

                  const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({required String number, required String label}) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  // Build info chip for Age, Language, Country
  Widget _buildInfoChip(String text) {
    return Container(
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
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Build clips horizontal list with pink border circles
  Widget _buildClipsHorizontalList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        List<String> coverImages = [];
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final coverURL = data?['coverURL'] as String?;
          
          if (coverURL != null && coverURL.isNotEmpty) {
            coverImages = coverURL.split(',').where((url) => url.trim().isNotEmpty).toList();
          }
        }
        
        if (coverImages.isEmpty) {
          return Center(
            child: Text(
              'No clips yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          );
        }
        
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: coverImages.length,
          itemBuilder: (context, index) {
            final imageUrl = coverImages[index].trim();
            return GestureDetector(
              onTap: () => _showFullScreenImage(context, coverImages, index),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4), Color(0xFFFF1B7C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(imageUrl),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build posts grid
  Widget _buildPostsGrid() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        List<String> coverImages = [];
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final coverURL = data?['coverURL'] as String?;
          
          if (coverURL != null && coverURL.isNotEmpty) {
            coverImages = coverURL.split(',').where((url) => url.trim().isNotEmpty).toList();
          }
        }
        
        if (coverImages.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: coverImages.length,
            itemBuilder: (context, index) {
              final imageUrl = coverImages[index].trim();
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, coverImages, index),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey[600],
                        size: 32,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF1B7C),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Build cover images grid
  Widget _buildCoverImagesGrid({required bool showAll}) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        List<String> coverImages = [];
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final coverURL = data?['coverURL'] as String?;
          
          if (coverURL != null && coverURL.isNotEmpty) {
            // Split comma-separated URLs
            coverImages = coverURL.split(',').where((url) => url.trim().isNotEmpty).toList();
          }
        }
        
        if (coverImages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Display images in grid with better quality
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: coverImages.length,
          itemBuilder: (context, index) {
            final imageUrl = coverImages[index].trim();
            return GestureDetector(
              onTap: () {
                _showFullScreenImage(context, coverImages, index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    filterQuality: FilterQuality.high, // High quality rendering
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                          size: 32,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build cards placeholder
  Widget _buildCardsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No cards yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Show full screen image viewer
  void _showFullScreenImage(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // Show options menu (Share Profile, Report User, Block User)
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
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
                // Share Profile Option
                _buildMenuOption(
                  icon: Icons.share,
                  title: 'Share Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _shareProfile();
                  },
                ),
                const SizedBox(height: 4),
                // Report User Option
                _buildMenuOption(
                  icon: Icons.flag_outlined,
                  title: 'Report user',
                  onTap: () {
                    Navigator.pop(context);
                    _reportUser(context);
                  },
                ),
                const SizedBox(height: 4),
                // Block User Option
                _buildMenuOption(
                  icon: Icons.block_outlined,
                  title: 'Block user',
                  onTap: () {
                    Navigator.pop(context);
                    _blockUser(context);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build menu option widget
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.black87,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Share Profile
  Future<void> _shareProfile() async {
    try {
      // Create shareable content
      final profileLink = 'https://chamak.app/profile/${widget.user.uid}'; // Replace with your actual app link
      final shareText = 'Check out ${widget.user.name}\'s profile on Chamakz!\n$profileLink';
      
      // Use native share dialog (includes WhatsApp, Messages, Email, etc.)
      final result = await Share.share(
        shareText,
        subject: '${widget.user.name}\'s Profile',
      );
      
      if (result.status == ShareResultStatus.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile shared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share profile. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Report User
  Future<void> _reportUser(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ReportUserScreen(
          reportedUserId: widget.user.uid,
          reportedUserName: widget.user.name,
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
        content: Text('Are you sure you want to block ${widget.user.name}? You won\'t be able to see their profile or receive messages from them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Add user to blocked list
                await _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('blocked')
                    .doc(widget.user.uid)
                    .set({
                  'blockedAt': FieldValue.serverTimestamp(),
                  'blockedUserId': widget.user.uid,
                  'blockedUserName': widget.user.name,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.user.name} has been blocked'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  // Navigate back after blocking
                  Navigator.pop(context);
                }
              } catch (e) {
                debugPrint('Error blocking user: $e');
                if (mounted) {
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
}

// Full Screen Image Viewer Widget
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index].trim(),
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
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
            backgroundColor: Color(0xFFFF69B4), // Purple color
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






































