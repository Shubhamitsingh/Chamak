import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import '../models/follower_model.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';
import 'user_profile_view_screen.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../widgets/cached_avatar_widget.dart';

class FollowersListScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
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
          AppLocalizations.of(context)?.followers ?? 'Followers',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<FollowerModel>>(
        stream: _followService.getFollowers(widget.userId),
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
                    isHindi ? 'फ़ॉलोअर्स लोड करने में त्रुटि' : 'Error loading followers',
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

          final followers = snapshot.data ?? [];

          // Empty state
          if (followers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isHindi ? 'अभी कोई फ़ॉलोअर नहीं' : 'No followers yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isHindi
                        ? 'जब कोई आपको फ़ॉलो करेगा, तो वह यहाँ दिखेगा'
                        : 'When someone follows you, they\'ll appear here',
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

          // Followers list
          return Column(
            children: [
              // Count display on left side
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${isHindi ? 'कुल' : 'Total'}: ${followers.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // List of followers
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: followers.length,
                  itemBuilder: (context, index) {
                    final follower = followers[index];
                    return _buildFollowerCard(follower, isOwnProfile);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFollowerCard(FollowerModel follower, bool isOwnProfile) {
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
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF1B7C), Color(0xFFE91E63)],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF1B7C).withValues(alpha: 0.2),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Lv. $level',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
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
                // Follow/Unfollow button
                StreamBuilder<DocumentSnapshot>(
                  stream: _auth.currentUser != null
                      ? _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .collection('following')
                          .doc(follower.followerId)
                          .snapshots()
                      : null,
                  builder: (context, followingSnapshot) {
                    final isFollowing = followingSnapshot.hasData && followingSnapshot.data!.exists;
                    final currentUserId = _auth.currentUser?.uid;
                    
                    // Don't show button if viewing own profile and the follower is yourself
                    if (isOwnProfile && follower.followerId == currentUserId) {
                      return const SizedBox.shrink();
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: TextButton(
                        onPressed: () {
                          if (isFollowing) {
                            // Unfollow
                            _handleUnfollow(follower.followerId);
                          } else {
                            // Follow
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
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          backgroundColor: isFollowing ? Colors.grey[100] : const Color(0xFFFF69B4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          minimumSize: const Size(0, 32),
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
        // UI will update automatically via StreamBuilder
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
        // UI will update automatically via StreamBuilder
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

  Widget _buildDefaultAvatar(String numericId) {
    return CachedAvatarWidget(
      userId: numericId,
      radius: 22,
      style: 'avataaars',
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}
