import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'edit_profile_screen.dart';
import 'wallet_screen.dart';
import 'my_earning_screen.dart';
import 'account_security_screen.dart';
import 'settings_screen.dart';
import 'chat_list_screen.dart';
import 'level_screen.dart';
import 'contact_support_screen.dart';
import 'help_feedback_screen.dart';
import 'warning_screen.dart';
import 'event_screen.dart';
import 'promotion_screen.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';
import '../services/database_service.dart';
import '../services/id_generator_service.dart';
import '../services/chat_service.dart';
import '../services/event_service.dart';
import '../services/announcement_tracking_service.dart';
import '../services/banner_service.dart';
import '../services/host_application_service.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';
import '../models/event_model.dart';
import '../models/banner_model.dart';
import 'become_creator_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String phoneNumber;
  
  const ProfileScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ChatService _chatService = ChatService();
  final EventService _eventService = EventService();
  final AnnouncementTrackingService _trackingService = AnnouncementTrackingService();
  final BannerService _bannerService = BannerService();
  final HostApplicationService _hostApplicationService = HostApplicationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Image slider variables
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  bool _isSliderActive = false;
  List<BannerModel> _currentBanners = [];
  bool _isUserScrolling = false; // Track if user is manually scrolling
  
  // Cache user data to prevent unnecessary rebuilds
  UserModel? _cachedUser;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (_isSliderActive) return; // Prevent multiple timers
    
    _timer?.cancel(); // Cancel any existing timer
    _isSliderActive = true;
    
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_isSliderActive) {
        timer.cancel();
        _isSliderActive = false;
        return;
      }
      
      // Use current banners length instead of hardcoded
      final bannerCount = _currentBanners.length;
      
      // Only auto-scroll if we have more than 1 banner
      if (bannerCount <= 1) {
        // Don't cancel timer, just skip this iteration (banner might load later)
        return;
      }
      
      // Ensure current page is valid (in case it got out of sync)
      if (_currentPage >= bannerCount) {
        _currentPage = 0;
      }
      if (_currentPage < 0) {
        _currentPage = 0;
      }
      
      // Calculate next page
      int nextPage;
      if (_currentPage < bannerCount - 1) {
        nextPage = _currentPage + 1;
      } else {
        nextPage = 0; // Loop back to first banner
      }
      
      debugPrint('🔄 Auto-scrolling banner: page $_currentPage -> $nextPage (total: $bannerCount)');
      
      if (mounted && _pageController.hasClients) {
        // Only scroll if not already on that page (prevent duplicate scrolls)
        if (_currentPage != nextPage) {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }
  
  void _stopAutoScroll() {
    _timer?.cancel();
    _timer = null;
    _isSliderActive = false;
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  void deactivate() {
    // Pause slider when navigating away
    _stopAutoScroll();
    super.deactivate();
  }
  
  @override
  void activate() {
    // Resume slider when coming back (only if not already active)
    super.activate();
    if (mounted && !_isSliderActive) {
      _startAutoScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<UserModel?>(
        stream: _databaseService.streamCurrentUserData(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Use cached user if available while loading
            if (_cachedUser != null) {
              return _buildProfileContent(_cachedUser!);
            }
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF69B4),
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            // Use cached user if available on error
            if (_cachedUser != null) {
              return _buildProfileContent(_cachedUser!);
            }
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
                    AppLocalizations.of(context)!.errorLoadingProfile,
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

          // No data state
          if (!snapshot.hasData || snapshot.data == null) {
            // Use cached user if available
            if (_cachedUser != null) {
              return _buildProfileContent(_cachedUser!);
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    color: Colors.grey,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.profileNotFound,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final UserModel user = snapshot.data!;
          
          // Always update cache with latest data (especially for coin changes)
          // This ensures real-time updates for coin balances
          _cachedUser = user;
          
          // Always return content with latest user data
          return _buildProfileContent(user);
        },
      ),
    );
  }

  // Separated profile content to reduce rebuild scope
  Widget _buildProfileContent(UserModel user) {
    return SafeArea(
        child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Top Section - Profile Header
            _buildProfileHeader(user),
              
              const SizedBox(height: 2),
              
              // Image Slider Section (Dynamic Banners)
              _buildImageSlider(user),
              
              const SizedBox(height: 2),
              
              // Main Options Menu
            _buildMainOptionsMenu(user),
            ],
        ),
      ),
    );
  }

  // ========== PROFILE HEADER (HORIZONTAL LAYOUT) ==========
  Widget _buildProfileHeader(UserModel user) {
    return Padding(
      key: ValueKey('profile_header_${user.userId}'), // Key prevents animation restart
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Section - Horizontal Layout
            Row(
              children: [
                // Profile Avatar (LEFT SIDE) - Cartoon Style Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: user.photoURL != null && user.photoURL!.isNotEmpty
                      ? CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.network(
                              user.photoURL!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              cacheWidth: 160,
                              cacheHeight: 160,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF69B4),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading profile image: $error');
                                debugPrint('Failed URL: ${user.photoURL}');
                                return Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF9C27B0),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFF5F5F5),
                            child: Image.network(
                              'https://api.dicebear.com/7.x/avataaars/png?seed=${user.numericUserId}&backgroundColor=b6e3f4,c0aede,d1d4f9&size=80&randomizeIds=true',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              cacheWidth: 80,
                              cacheHeight: 80,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF69B4),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading default avatar: $error');
                                return Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF9C27B0), // purple fallback
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 45,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
                
                const SizedBox(width: 18),
                
                // User Info (RIGHT SIDE - Username and ID vertically stacked)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username with Gender Icon
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName ?? AppLocalizations.of(context)!.setYourName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.gender != null && user.gender!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: user.gender!.toLowerCase() == 'male'
                                    ? Colors.blue
                                    : Colors.pink,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (user.gender!.toLowerCase() == 'male'
                                        ? Colors.blue
                                        : Colors.pink).withValues(alpha:0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                user.gender!.toLowerCase() == 'male'
                                    ? Icons.male
                                    : Icons.female,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 5),
                      
                      // User ID with Copy functionality
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (!mounted) return;
                              try {
                                final displayId = IdGeneratorService.getDisplayId(user.numericUserId);
                                Clipboard.setData(ClipboardData(text: displayId));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text('ID $displayId copied to clipboard!'),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFFF1B7C),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint('Error copying to clipboard: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Failed to copy ID'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha:0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha:0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 12,
                                    color: Colors.grey[700],
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  'ID: ${IdGeneratorService.getDisplayId(user.numericUserId)}',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 10,
                                  color: Colors.grey[700],
                                ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 7),
                      
                      // Country and City
                      if (user.city != null || user.country != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                                '${user.city ?? ''}${user.city != null && user.country != null ? ', ' : ''}${user.country ?? ''}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Language
                      if (user.language != null && user.language!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.language_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.language!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Edit/Arrow Button (RIGHT SIDE)
                GestureDetector(
                  onTap: () {
                    if (!mounted) return;
                    _stopAutoScroll(); // Stop slider when navigating
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            phoneNumber: widget.phoneNumber,
                          ),
                        ),
                      ).then((_) {
                        // Clear cache to force refresh of user data
                        if (mounted) {
                          setState(() {
                            _cachedUser = null;
                          });
                        }
                        // Resume slider when returning
                        if (mounted) {
                          _startAutoScroll();
                        }
                      });
                    } catch (e) {
                      debugPrint('Navigation error: $e');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 18),
            
            // Stats Row - Followers, Following, Level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatButton(
                  icon: Icons.groups_outlined,
                  count: user.followersCount.toString(),
                  label: AppLocalizations.of(context)!.followers,
                  onTap: () {
                      if (!mounted) return;
                      _stopAutoScroll(); // Stop slider when navigating
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowersListScreen(
                              userId: user.uid,
                              userName: user.displayName ?? AppLocalizations.of(context)!.setYourName,
                            ),
                          ),
                        ).then((_) {
                          // Resume slider when returning
                          if (mounted) {
                            _startAutoScroll();
                          }
                        });
                      } catch (e) {
                        debugPrint('Navigation error: $e');
                      }
                    },
                  ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey.withValues(alpha:0.2),
                ),
                _buildStatButton(
                  icon: Icons.person_add_alt_outlined,
                  count: user.followingCount.toString(),
                  label: AppLocalizations.of(context)!.following,
                  onTap: () {
                    if (!mounted) return;
                    _stopAutoScroll(); // Stop slider when navigating
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FollowingListScreen(
                            userId: user.uid,
                            userName: user.displayName ?? AppLocalizations.of(context)!.setYourName,
                          ),
                        ),
                      ).then((_) {
                        // Resume slider when returning
                        if (mounted) {
                          _startAutoScroll();
                        }
                      });
                    } catch (e) {
                      debugPrint('Navigation error: $e');
                    }
                  },
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey.withValues(alpha:0.2),
                ),
                _buildStatButton(
                  icon: Icons.star_border_rounded,
                  count: user.level.toString(),
                  label: AppLocalizations.of(context)!.level,
                  onTap: () {
                    if (!mounted) return;
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LevelScreen(userLevel: user.level),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Navigation error: $e');
                    }
                  },
                ),
              ],
            ),
          ],
      ),
    );
  }

  // Stat Button Widget for Followers, Following, Level
  Widget _buildStatButton({
    required IconData icon,
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== IMAGE SLIDER SECTION (Dynamic Banners) ==========
  Widget _buildImageSlider(UserModel user) {
    // Get isHost status from Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user.userId).snapshots(),
      builder: (context, userSnapshot) {
        final isHost = userSnapshot.hasData && userSnapshot.data!.exists
          ? (userSnapshot.data!.data() as Map<String, dynamic>)['isHost'] ?? false
          : false;
        
        return StreamBuilder<List<BannerModel>>(
          stream: _bannerService.getActiveBannersStream(
            userLevel: user.level,
            userType: isHost ? 'host' : 'audience',
            userCountry: user.countryCode,
          ),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 60,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF69B4),
                strokeWidth: 2,
              ),
            ),
          );
        }

        // Error state - hide banner section
        if (snapshot.hasError) {
          debugPrint('❌ Error loading banners: ${snapshot.error}');
          return SizedBox.shrink();
        }

        final banners = snapshot.data ?? [];
        
        // No banners - hide section
        if (banners.isEmpty) {
          return SizedBox.shrink();
        }

        // Update current banners list for auto-scroll
        // Only reset page if banner count actually changed (not on every rebuild)
        final bannerIds = banners.map((b) => b.id).toList();
        final currentBannerIds = _currentBanners.map((b) => b.id).toList();
        
        if (bannerIds.toString() != currentBannerIds.toString()) {
          // Banners actually changed (added/removed)
          _currentBanners = banners;
          debugPrint('📋 Banners changed: ${_currentBanners.length} -> ${banners.length}');
          
          // Only reset to first page if banner COUNT changed AND user is not scrolling
          if (_currentBanners.length != currentBannerIds.length) {
            if (_pageController.hasClients && mounted && !_isUserScrolling) {
              _currentPage = 0;
              _pageController.jumpToPage(0); // Use jumpToPage to instantly reset without animation
              debugPrint('🔄 Reset to page 0 due to banner count change (${currentBannerIds.length} -> ${_currentBanners.length})');
            } else if (_isUserScrolling) {
              debugPrint('⏸️ Skipping page reset - user is scrolling');
            }
          } else {
            // Same count, just update list reference (DON'T reset page position - this was the bug!)
            debugPrint('📋 Banners list updated but count same (${_currentBanners.length}) - keeping current page $_currentPage');
          }
          
          // Restart auto-scroll if we have banners now
          if (banners.length > 1 && !_isSliderActive) {
            _startAutoScroll();
          }
        } else {
          // Banners are the same, just update the list reference
          _currentBanners = banners;
        }
        
        // Ensure auto-scroll is running if we have multiple banners
        if (banners.length > 1 && !_isSliderActive) {
          _startAutoScroll();
        }

        return Container(
          key: const ValueKey('image_slider'),
          height: 60,
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Detect when user starts manually scrolling
                  if (notification is ScrollStartNotification) {
                    _isUserScrolling = true;
                    debugPrint('👆 User started scrolling - pausing auto-scroll');
                    // Reset flag after scroll completes (delay)
                    Future.delayed(Duration(milliseconds: 500), () {
                      _isUserScrolling = false;
                    });
                  }
                  return false; // Allow notification to continue
                },
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    // Always update current page when PageView changes (user swipe or auto-scroll)
                    if (mounted) {
                      // Update _currentPage to match PageView (don't use setState to avoid rebuild)
                      _currentPage = index;
                      // Reset scrolling flag after page change completes
                      Future.delayed(Duration(milliseconds: 100), () {
                        _isUserScrolling = false;
                      });
                      debugPrint('📄 PageView changed to page $index (total: ${banners.length})');
                      // Track impression when banner is viewed
                      if (index < banners.length) {
                        _bannerService.trackImpression(banners[index].id);
                      }
                    }
                  },
                  itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  
                  return GestureDetector(
                    onTap: () {
                      _bannerService.handleBannerAction(
                        context,
                        banner,
                        widget.phoneNumber,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      child: Image.network(
                        banner.imageUrl,
                        width: double.infinity,
                        height: 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFE91E63),
                                  Color(0xFF9C27B0),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Error loading banner image: $error');
                          return Container(
                            height: 60,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFE91E63),
                                  Color(0xFF9C27B0),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 24,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                ),
              ),
              // Page Indicators (dots)
              if (banners.length > 1)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(banners.length, (index) {
                      return Container(
                        width: _currentPage == index ? 7 : 5,
                        height: 5,
                        margin: EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(2.5),
                          color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
        },
      );
      },
    );
  }

  // ========== MAIN OPTIONS MENU ==========
  Widget _buildMainOptionsMenu(UserModel user) {
    return Padding(
      key: ValueKey('options_menu_${user.userId}'), // Key prevents animation restart
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
          children: [
            // Wallet with Real-time Coin Balance (checks both wallets and users collections)
            StreamBuilder<DocumentSnapshot>(
              stream: _auth.currentUser != null
                  ? _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots()
                  : Stream<DocumentSnapshot>.empty(),
              builder: (context, userCoinSnapshot) {
                // Also listen to wallets collection for real-time updates
                return StreamBuilder<DocumentSnapshot>(
                  stream: _auth.currentUser != null
                      ? _firestore.collection('wallets').doc(_auth.currentUser!.uid).snapshots()
                      : Stream<DocumentSnapshot>.empty(),
                  builder: (context, walletSnapshot) {
                    // Get real-time coin balance - ALWAYS prioritize users collection (PRIMARY SOURCE OF TRUTH)
                    // This is the same logic as wallet_screen.dart to ensure consistency
                    int uCoinsBalance = 0;
                    
                    // PRIMARY: Always use users collection uCoins (it's always updated during deductions)
                    if (userCoinSnapshot.hasData && userCoinSnapshot.data!.exists) {
                      final userData = userCoinSnapshot.data!.data() as Map<String, dynamic>?;
                      if (userData != null) {
                        final userUCoins = (userData['uCoins'] as int?) ?? 0;
                        final userCoins = (userData['coins'] as int?) ?? 0;
                        
                        // ALWAYS use uCoins as primary (it's always updated during deductions)
                        // Only use coins if uCoins is 0 and coins has value (legacy data)
                        uCoinsBalance = userUCoins > 0 ? userUCoins : (userCoins > 0 ? userCoins : 0);
                      }
                    }
                    
                    // SECONDARY: Only use wallets collection if users collection doesn't exist or hasn't loaded yet
                    if (uCoinsBalance == 0 && walletSnapshot.hasData && walletSnapshot.data!.exists) {
                      final walletData = walletSnapshot.data!.data() as Map<String, dynamic>?;
                      if (walletData != null) {
                        final walletBalance = (walletData['balance'] as int?) ?? 
                                             (walletData['coins'] as int?) ?? 0;
                        uCoinsBalance = walletBalance;
                      }
                    }
                    
                    // Final fallback to cached user data if streams haven't loaded yet
                    if (uCoinsBalance == 0 && (!userCoinSnapshot.hasData || !userCoinSnapshot.data!.exists)) {
                      uCoinsBalance = user.uCoins;
                    }
                    
                    return _buildMenuOption(
                      icon: Icons.account_balance_wallet_rounded,
                      title: AppLocalizations.of(context)!.wallet,
                      subtitle: AppLocalizations.of(context)!.balanceRechargeWithdrawal,
                      color: const Color(0xFFFFB800),
                      iconImage: 'assets/images/walleticon.png', // Use custom wallet icon
                      showCoinIcon: true,
                      coinBalance: uCoinsBalance, // Real-time coin balance
                      onTap: () {
                        if (!mounted) return;
                        _stopAutoScroll(); // Stop slider when navigating
                        try {
                          // Get host status from user document data
                          bool isHost = false;
                          if (userCoinSnapshot.hasData && userCoinSnapshot.data!.exists) {
                            final userData = userCoinSnapshot.data!.data() as Map<String, dynamic>?;
                            isHost = userData?['isHost'] ?? false;
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WalletScreen(
                                phoneNumber: widget.phoneNumber,
                                isHost: isHost,
                              ),
                            ),
                          ).then((_) {
                            // Resume slider when returning
                            if (mounted) {
                              _startAutoScroll();
                            }
                          });
                        } catch (e) {
                          debugPrint('Navigation error: $e');
                        }
                      },
                    );
                  },
                );
              },
            ),
            _buildDivider(),
            
            // My Earning with Real-time Coin Balance
            // NOTE: Use earnings.totalCCoins (SINGLE SOURCE OF TRUTH) instead of users.cCoins
            StreamBuilder<DocumentSnapshot>(
              stream: _auth.currentUser != null
                  ? _firestore.collection('earnings').doc(_auth.currentUser!.uid).snapshots()
                  : Stream<DocumentSnapshot>.empty(),
              builder: (context, earningsSnapshot) {
                // Get real-time C Coins balance from earnings collection (SINGLE SOURCE OF TRUTH)
                int cCoinsBalance = 0;
                if (earningsSnapshot.hasData && earningsSnapshot.data!.exists) {
                  final data = earningsSnapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null && data.containsKey('totalCCoins')) {
                    cCoinsBalance = data['totalCCoins'] as int? ?? 0;
                  }
                }
                
                return _buildMenuOption(
                  icon: Icons.monetization_on_rounded,
                  title: AppLocalizations.of(context)!.myEarning,
                  subtitle: AppLocalizations.of(context)!.earningsWithdrawals,
                  color: const Color(0xFF10B981),
                  showCoin2Icon: true,
                  coinBalance: cCoinsBalance, // Real-time C Coins balance from earnings collection
                  onTap: () {
                    if (!mounted) return;
                    _stopAutoScroll();
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyEarningScreen(
                            phoneNumber: widget.phoneNumber,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) {
                          _startAutoScroll();
                        }
                      });
                    } catch (e) {
                      debugPrint('Navigation error: $e');
                    }
                  },
                );
              },
            ),
            _buildDivider(),
            
            // Messages with Unread Badge
            StreamBuilder<int>(
              stream: _chatService.getTotalUnreadCount(user.uid),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data ?? 0;
                return _buildMenuOption(
                  icon: Icons.forum_rounded,
                  title: AppLocalizations.of(context)!.messages,
                  subtitle: AppLocalizations.of(context)!.chatInbox,
                  color: const Color(0xFF3B82F6),
                  iconImage: 'assets/images/comment.png', // Use custom comment icon
                  badgeCount: unreadCount,
                  showBadgeOnTrailing: true, // Show badge on right side like level
                  onTap: () {
                    if (!mounted) return;
                    _stopAutoScroll();
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatListScreen(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          _startAutoScroll();
                        }
                      });
                    } catch (e) {
                      debugPrint('Navigation error: $e');
                    }
                  },
                );
              },
            ),
            _buildDivider(),
            
            // Event Section with Badge Counter (Announcements + Events)
            StreamBuilder<List<AnnouncementModel>>(
              stream: _eventService.getAnnouncementsStream(),
              builder: (context, announcementSnapshot) {
                return StreamBuilder<List<EventModel>>(
                  stream: _eventService.getEventsStream(),
                  builder: (context, eventSnapshot) {
                    return StreamBuilder<Set<String>>(
                      stream: _trackingService.getSeenAnnouncementIdsStream(),
                      builder: (context, seenAnnouncementSnapshot) {
                        return StreamBuilder<Set<String>>(
                          stream: _trackingService.getDismissedAnnouncementIdsStream(),
                          builder: (context, dismissedAnnouncementSnapshot) {
                            return StreamBuilder<Set<String>>(
                              stream: _trackingService.getSeenEventIdsStream(),
                              builder: (context, seenEventSnapshot) {
                                final announcements = announcementSnapshot.data ?? [];
                                final events = eventSnapshot.data ?? [];
                                final seenAnnouncementIds = seenAnnouncementSnapshot.data ?? {};
                                final dismissedAnnouncementIds = dismissedAnnouncementSnapshot.data ?? {};
                                final seenEventIds = seenEventSnapshot.data ?? {};
                                
                                // Count unseen NEW announcements
                                final unseenAnnouncementCount = announcements
                                    .where((a) => 
                                      a.isNew && 
                                      !seenAnnouncementIds.contains(a.id) &&
                                      !dismissedAnnouncementIds.contains(a.id))
                                    .length;
                                
                                // Count unseen NEW events
                                final unseenEventCount = events
                                    .where((e) => 
                                      e.isNew && 
                                      !seenEventIds.contains(e.id))
                                    .length;
                                
                                // Total unseen count
                                final totalUnseenCount = unseenAnnouncementCount + unseenEventCount;
                                
                                return _buildMenuOption(
                                  icon: Icons.campaign_rounded,
                                  title: AppLocalizations.of(context)!.events,
                                  subtitle: AppLocalizations.of(context)!.upcomingEventsPosters,
                                  color: const Color(0xFF8B5CF6),
                                  badgeCount: totalUnseenCount > 0 ? totalUnseenCount : null,
                                  showBadgeOnTrailing: true, // Show badge on right side like level
                                  onTap: () async {
                                    if (!mounted) return;
                                    _stopAutoScroll();
                                    
                                    try {
                                      // Mark all new announcements as seen
                                      final newAnnouncementIds = announcements
                                          .where((a) => a.isNew && !seenAnnouncementIds.contains(a.id))
                                          .map((a) => a.id)
                                          .toList();
                                      
                                      if (newAnnouncementIds.isNotEmpty) {
                                        try {
                                          await _trackingService.markMultipleAsSeen(newAnnouncementIds);
                                        } catch (e) {
                                          debugPrint('Error marking announcements as seen: $e');
                                        }
                                      }
                                      
                                      // Mark all new events as seen
                                      final newEventIds = events
                                          .where((e) => e.isNew && !seenEventIds.contains(e.id))
                                          .map((e) => e.id)
                                          .toList();
                                      
                                      if (newEventIds.isNotEmpty) {
                                        try {
                                          await _trackingService.markMultipleEventsAsSeen(newEventIds);
                                        } catch (e) {
                                          debugPrint('Error marking events as seen: $e');
                                        }
                                      }
                                      
                                      if (mounted) {
                                        try {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const EventScreen(),
                                            ),
                                          ).then((_) {
                                            if (mounted) {
                                              _startAutoScroll();
                                            }
                                          });
                                        } catch (e) {
                                          debugPrint('Navigation error: $e');
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint('Error in events navigation: $e');
                                    }
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            _buildDivider(),
            
            // Level - placed after Events
            _buildMenuOption(
              icon: Icons.military_tech,
              title: AppLocalizations.of(context)!.level,
              subtitle: AppLocalizations.of(context)!.yourProgressAchievements,
              color: const Color(0xFFF59E0B),
              showLevel: true,
              userLevel: user.level,
              onTap: () {
                if (!mounted) return;
                _stopAutoScroll();
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LevelScreen(userLevel: user.level),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _startAutoScroll();
                    }
                  });
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              },
            ),
            _buildDivider(),
            
            // Promotion Screen
            _buildMenuOption(
              icon: Icons.campaign_rounded,
              title: AppLocalizations.of(context)!.promotion,
              subtitle: AppLocalizations.of(context)!.shareAndEarnRewards,
              color: const Color(0xFFFF1B7C), // Pink - matches app theme
              onTap: () {
                if (!mounted) return;
                _stopAutoScroll();
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PromotionScreen(),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _startAutoScroll();
                    }
                  });
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              },
            ),
            _buildDivider(),
            
            // Become a Creator - Only show if user is not already a host
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(user.userId).snapshots(),
              builder: (context, userSnapshot) {
                final isHost = userSnapshot.hasData && userSnapshot.data!.exists
                    ? (userSnapshot.data!.data() as Map<String, dynamic>)['isHost'] ?? false
                    : false;
                
                // Don't show if user is already a host
                if (isHost) {
                  return const SizedBox.shrink();
                }
                
                // Check application status
                return StreamBuilder<DocumentSnapshot?>(
                  stream: _hostApplicationService.getApplicationStatus(user.userId),
                  builder: (context, appSnapshot) {
                    // Show menu item if no application or application is rejected
                    final hasPendingOrApproved = appSnapshot.hasData && appSnapshot.data != null;
                    if (hasPendingOrApproved) {
                      final appData = appSnapshot.data!.data() as Map<String, dynamic>?;
                      final status = appData?['status'] ?? 'pending';
                      
                      // Only show if rejected (can reapply) or pending (show status)
                      if (status == 'approved') {
                        return const SizedBox.shrink(); // Already approved, don't show
                      }
                      
                      // Show with status badge if pending
                      return Column(
                        children: [
                          _buildMenuOption(
                            icon: Icons.star_rounded,
                            title: 'Become a Creator',
                            subtitle: status == 'pending'
                                ? 'Application under review'
                                : 'Reapply to become a creator',
                            color: const Color(0xFFFF1B7C),
                            badgeCount: status == 'pending' ? 1 : null,
                            showBadgeOnTrailing: true,
                            onTap: () {
                              if (!mounted) return;
                              _stopAutoScroll();
                              try {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BecomeCreatorScreen(
                                      phoneNumber: widget.phoneNumber,
                                    ),
                                  ),
                                ).then((_) {
                                  if (mounted) {
                                    _startAutoScroll();
                                  }
                                });
                              } catch (e) {
                                debugPrint('Navigation error: $e');
                              }
                            },
                          ),
                          _buildDivider(),
                        ],
                      );
                    }
                    
                    // No application - show normal menu item
                    return Column(
                      children: [
                        _buildMenuOption(
                          icon: Icons.star_rounded,
                          title: 'Become a Creator',
                          subtitle: 'Apply to become a host and earn more',
                          color: const Color(0xFFFF1B7C),
                          onTap: () {
                            if (!mounted) return;
                            _stopAutoScroll();
                            try {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BecomeCreatorScreen(
                                    phoneNumber: widget.phoneNumber,
                                  ),
                                ),
                              ).then((_) {
                                if (mounted) {
                                  _startAutoScroll();
                                }
                              });
                            } catch (e) {
                              debugPrint('Navigation error: $e');
                            }
                          },
                        ),
                        _buildDivider(),
                      ],
                    );
                  },
                );
              },
            ),
            
            _buildMenuOption(
              icon: Icons.thumb_down_rounded,
              title: AppLocalizations.of(context)!.warnings,
              subtitle: AppLocalizations.of(context)!.viewWarningsGuidelines,
              color: const Color(0xFFEF4444),
              onTap: () {
                if (!mounted) return;
                _stopAutoScroll();
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WarningScreen(),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _startAutoScroll();
                    }
                  });
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              },
            ),
            _buildDivider(),
            
            _buildMenuOption(
              icon: Icons.verified_user_rounded,
              title: AppLocalizations.of(context)!.accountSecurity,
              subtitle: AppLocalizations.of(context)!.phonePasswordAccountSettings,
              color: const Color(0xFF8B5CF6),
              onTap: () {
                if (!mounted) return;
                _stopAutoScroll();
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountSecurityScreen(
                        phoneNumber: widget.phoneNumber,
                        userId: IdGeneratorService.getDisplayId(user.numericUserId),
                      ),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _startAutoScroll();
                    }
                  });
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              },
            ),
            _buildDivider(),
            
            _buildMenuOption(
              icon: Icons.tune_rounded,
              title: AppLocalizations.of(context)!.settings,
              subtitle: AppLocalizations.of(context)!.appPreferencesPrivacyTerms,
              color: const Color(0xFF64748B),
              onTap: () {
                if (!mounted) return;
                _stopAutoScroll();
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _startAutoScroll();
                    }
                  });
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              },
            ),
            _buildDivider(),
            
            _buildMenuOption(
              icon: Icons.support_agent_rounded,
              title: AppLocalizations.of(context)!.contactSupport,
              subtitle: AppLocalizations.of(context)!.getHelpReportIssues,
              color: const Color(0xFF06B6D4),
              onTap: () {
                if (!mounted) return;
                _stopAutoScroll();
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactSupportScreen(),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _startAutoScroll();
                    }
                  });
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              },
            ),
            _buildDivider(),
            
            _buildMenuOption(
              icon: Icons.contact_support_rounded,
              title: AppLocalizations.of(context)!.helpAndFeedback,
              subtitle: AppLocalizations.of(context)!.faqsCommonIssues,
              color: const Color(0xFFEC4899),
              onTap: () {
                if (!mounted) return;
                _stopAutoScroll();
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpFeedbackScreen(),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _startAutoScroll();
                    }
                  });
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
    bool showCoinIcon = false,
    bool showCoin2Icon = false,
    int? coinBalance, // Coin balance to display
    bool showLevel = false,
    int? userLevel, // User level to display
    bool showBadgeOnTrailing = false, // Show badge on trailing (right side) instead of icon
    String? iconImage, // Optional image path to replace icon
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: iconImage != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      color,
                      BlendMode.srcIn, // Use srcIn to replace image colors with the color
                    ),
                    child: Image.asset(
                      iconImage,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  )
                : Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
          ),
          // Unread Badge (only show on icon if not showing on trailing)
          if (badgeCount != null && badgeCount > 0 && !showBadgeOnTrailing)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha:0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coin Balance Display (for Wallet with coinBalance)
          if (showCoinIcon && coinBalance != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                _formatCoinBalance(coinBalance),
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          // Coin Icon (only for Wallet)
          if (showCoinIcon)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Image.asset(
                'assets/images/coin3.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          // Coin Balance Display (for My Earning with coinBalance)
          if (showCoin2Icon && coinBalance != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                _formatCoinBalance(coinBalance),
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          // Coin2 Icon (only for My Earning)
          if (showCoin2Icon)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Image.asset(
                'assets/images/coin2.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          // User Level Display (for Level menu)
          if (showLevel && userLevel != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1B7C), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1B7C).withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Lv.$userLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          // Badge Count Display (for Messages and Events - shown on right side like level)
          if (showBadgeOnTrailing && badgeCount != null && badgeCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          // Forward Arrow
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
      indent: 70,
    );
  }

  // Format coin balance with comma separators for readability
  String _formatCoinBalance(int balance) {
    // Add comma separators for thousands
    final balanceStr = balance.toString();
    final buffer = StringBuffer();
    
    for (int i = 0; i < balanceStr.length; i++) {
      if (i > 0 && (balanceStr.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(balanceStr[i]);
    }
    
    return buffer.toString();
  }

}

