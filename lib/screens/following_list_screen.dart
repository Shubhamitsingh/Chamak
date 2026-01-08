import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import '../models/follower_model.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';
import 'user_profile_view_screen.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

class FollowingListScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const FollowingListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final FollowService _followService = FollowService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final currentUserId = _auth.currentUser?.uid;
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)?.following ?? 'Following',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<FollowerModel>>(
        stream: _followService.getFollowing(widget.userId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF69B4),
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
                  Text(
                    isHindi ? 'फ़ॉलोइंग लोड करने में त्रुटि' : 'Error loading following',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final following = snapshot.data ?? [];

          // Empty state
          if (following.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isHindi ? 'अभी किसी को फ़ॉलो नहीं किया' : 'Not following anyone yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isHindi
                        ? 'जब आप किसी को फ़ॉलो करेंगे, तो वे यहाँ दिखेंगे'
                        : 'When you follow someone, they\'ll appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Following list
          return Column(
            children: [
              // Count display on left side
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${isHindi ? 'कुल' : 'Total'}: ${following.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // List of following
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: following.length,
                  itemBuilder: (context, index) {
                    final user = following[index];
                    return _buildFollowingCard(user, isOwnProfile);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFollowingCard(FollowerModel follower, bool isOwnProfile) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(follower.followerId).get(),
      builder: (context, userSnapshot) {
        // Show loading indicator while fetching user data
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF69B4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Handle error state
        if (userSnapshot.hasError) {
          debugPrint('Error fetching user data: ${userSnapshot.error}');
        }

        UserModel? userModel;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          try {
            userModel = UserModel.fromFirestore(userSnapshot.data!);
          } catch (e) {
            debugPrint('Error parsing user model: $e');
          }
        }

        // Use actual user data if available, otherwise fallback to follower model data
        final displayName = userModel?.displayName ?? 
                          (follower.followerName.isNotEmpty ? follower.followerName : 'User');
        final profileImage = userModel?.photoURL ?? 
                           (follower.followerImage.isNotEmpty ? follower.followerImage : '');
        final numericId = userModel?.numericUserId ?? follower.followerNumericId;
        
        // Get additional user info
        final level = userModel?.level;
        final language = userModel?.language;
        final country = userModel?.country;
        final countryCode = userModel?.countryCode;
        
        // Get country flag emoji
        String? countryFlag;
        if (countryCode != null && countryCode.isNotEmpty) {
          try {
            countryFlag = Country.parse(countryCode).flagEmoji;
          } catch (e) {
            // If parsing fails, try to find by country name
            if (country != null && country.isNotEmpty) {
              try {
                final foundCountry = Country.parse(country);
                countryFlag = foundCountry.flagEmoji;
              } catch (_) {
                countryFlag = null;
              }
            }
          }
        } else if (country != null && country.isNotEmpty) {
          try {
            final foundCountry = Country.parse(country);
            countryFlag = foundCountry.flagEmoji;
          } catch (_) {
            countryFlag = null;
          }
        }

        return InkWell(
              onTap: () async {
                if (userModel != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileViewScreen(user: userModel!),
                    ),
                  );
                } else {
                  // If userModel is null, try to fetch it
                  try {
                    final userDoc = await _firestore.collection('users').doc(follower.followerId).get();
                    if (userDoc.exists && mounted) {
                      final fetchedUser = UserModel.fromFirestore(userDoc);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileViewScreen(user: fetchedUser),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error fetching user: $e');
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Avatar - smaller size
                    profileImage.isNotEmpty
                        ? CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(profileImage),
                            onBackgroundImageError: (_, __) {},
                          )
                        : _buildDefaultAvatar(numericId),
                    const SizedBox(width: 12),
                    // User Name and Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Level, Language, Country in separate containers
                          if (level != null || language != null || country != null)
                            Row(
                              children: [
                                if (level != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Lv. $level',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                                if (language != null && language.isNotEmpty) ...[
                                  if (level != null) const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      language,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                                if (country != null && country.isNotEmpty) ...[
                                  if ((level != null) || (language != null && language.isNotEmpty))
                                    const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
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
                                            country,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 8,
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
                        ],
                      ),
                    ),
                    // Button logic: Unfollow if own profile, Follow if other user's profile
                    FutureBuilder<bool>(
                      future: _auth.currentUser != null
                          ? _followService.isFollowing(_auth.currentUser!.uid, follower.followerId)
                          : Future.value(false),
                      builder: (context, followingSnapshot) {
                        // Show loading state for button
                        if (followingSnapshot.connectionState == ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 80,
                              height: 32,
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF69B4),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        // Handle error state - default to not following
                        if (followingSnapshot.hasError) {
                          debugPrint('Error checking follow status: ${followingSnapshot.error}');
                        }
                        
                        final isFollowing = followingSnapshot.data ?? false;
                        
                        // If viewing own profile, show Unfollow button
                        if (isOwnProfile) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: TextButton(
                              onPressed: () => _handleUnfollow(follower.followerId),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Unfollow',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        // If viewing other user's profile, show Follow button
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: TextButton(
                            onPressed: () {
                              if (userModel != null) {
                                _handleFollow(userModel);
                              } else {
                                // Fetch user model first
                                _firestore.collection('users').doc(follower.followerId).get().then((doc) {
                                  if (doc.exists && mounted) {
                                    final fetchedUser = UserModel.fromFirestore(doc);
                                    _handleFollow(fetchedUser);
                                  }
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              backgroundColor: isFollowing ? Colors.grey[100] : const Color(0xFFFF69B4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing ? Colors.grey[800] : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
      },
    );
  }

  Widget _buildDefaultAvatar(String numericId) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFF5F5F5),
      backgroundImage: NetworkImage(
        'https://api.dicebear.com/7.x/avataaars/png?seed=$numericId&backgroundColor=b6e3f4,c0aede,d1d4f9&size=44&randomizeIds=true',
      ),
      onBackgroundImageError: (_, __) {},
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF9C27B0),
        ),
        child: const Icon(
          Icons.person,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
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
          color: Color(0xFFFF69B4),
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
              backgroundColor: Color(0xFFFF69B4),
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
          color: Color(0xFFFF69B4),
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
              content: Text('Now following ${targetUser.name}'),
              backgroundColor: const Color(0xFFFF69B4),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        // Refresh the UI
        setState(() {});
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
}