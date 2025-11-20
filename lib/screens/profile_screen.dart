import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../services/database_service.dart';
import '../services/id_generator_service.dart';
import '../services/chat_service.dart';
import '../services/event_service.dart';
import '../services/announcement_tracking_service.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';
import '../models/event_model.dart';

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

  // Image slider variables
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  bool _isSliderActive = false;
  
  // Cache user data to prevent unnecessary rebuilds
  UserModel? _cachedUser;
  
  // Sample images for the slider
  final List<String> _sliderImages = [
    'assets/images/adimage.png',
    'assets/images/adimage2.png',
    'assets/images/adimage3.png',
  ];

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
      
      int nextPage;
      if (_currentPage < _sliderImages.length - 1) {
        nextPage = _currentPage + 1;
      } else {
        nextPage = 0;
      }
      
      if (mounted && _pageController.hasClients) {
        // Don't call setState, just animate
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
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
                color: Color(0xFFE91E63),
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
          
          // Check if user data actually changed (deduplication)
          bool dataChanged = _cachedUser == null ||
              _cachedUser!.userId != user.userId ||
              _cachedUser!.numericUserId != user.numericUserId ||
              _cachedUser!.displayName != user.displayName ||
              _cachedUser!.photoURL != user.photoURL ||
              _cachedUser!.followersCount != user.followersCount ||
              _cachedUser!.followingCount != user.followingCount ||
              _cachedUser!.level != user.level ||
              _cachedUser!.gender != user.gender ||
              _cachedUser!.city != user.city ||
              _cachedUser!.country != user.country ||
              _cachedUser!.language != user.language;
          
          // Only update cache and rebuild if data actually changed
          if (dataChanged) {
            _cachedUser = user;
          }
          
          // Always return content (even if cached)
          return _buildProfileContent(_cachedUser!);
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
              
              // Image Slider Section
              _buildImageSlider(),
              
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
    return Container(
      key: ValueKey('profile_header_${user.userId}'), // Key prevents animation restart
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
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
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(user.photoURL!),
                            onBackgroundImageError: (exception, stackTrace) {
                              debugPrint('Error loading profile image: $exception');
                            },
                          ),
                        )
                      : CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFF5F5F5),
                            child: ClipOval(
                              child: Image.network(
                                'https://api.dicebear.com/7.x/avataaars/png?seed=${user.numericUserId}&backgroundColor=b6e3f4,c0aede,d1d4f9&size=80&randomizeIds=true',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                cacheWidth: 80,
                                cacheHeight: 80,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
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
                                      backgroundColor: const Color(0xFF9C27B0),
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
                        // Resume slider when returning
                        if (mounted) {
                          _startAutoScroll();
                        }
                      });
                    } catch (e) {
                      debugPrint('Navigation error: $e');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                    // TODO: Navigate to followers list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.followersListComingSoon),
                        backgroundColor: const Color(0xFF9C27B0),
                        duration: const Duration(seconds: 2),
                      ),
                    );
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
                    // TODO: Navigate to following list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.followingListComingSoon),
                        backgroundColor: const Color(0xFF9C27B0),
                        duration: const Duration(seconds: 2),
                      ),
                    );
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

  // ========== IMAGE SLIDER SECTION ==========
  Widget _buildImageSlider() {
    return Container(
      key: const ValueKey('image_slider'), // Key prevents animation restart
        height: 50,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            // Only update state if value actually changed (prevents unnecessary rebuilds)
            if (_currentPage != index && mounted) {
              setState(() {
                _currentPage = index;
              });
            }
          },
          itemCount: _sliderImages.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: Image.asset(
                _sliderImages[index],
                width: double.infinity,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 50,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 28,
                            color: Colors.white.withValues(alpha:0.8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Slide ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
      ),
    );
  }

  // ========== MAIN OPTIONS MENU ==========
  Widget _buildMainOptionsMenu(UserModel user) {
    return Container(
      key: ValueKey('options_menu_${user.userId}'), // Key prevents animation restart
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuOption(
              icon: Icons.account_balance_wallet_rounded,
              title: AppLocalizations.of(context)!.wallet,
              subtitle: AppLocalizations.of(context)!.balanceRechargeWithdrawal,
              color: const Color(0xFFFFB800),
              showCoinIcon: true,
              onTap: () {
                if (!mounted) return;
                _stopAutoScroll(); // Stop slider when navigating
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WalletScreen(
                        phoneNumber: widget.phoneNumber,
                        isHost: false, // TODO: Implement host status
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
            _buildDivider(),
            
            _buildMenuOption(
              icon: Icons.monetization_on_rounded,
              title: AppLocalizations.of(context)!.myEarning,
              subtitle: AppLocalizations.of(context)!.earningsWithdrawals,
              color: const Color(0xFF10B981),
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
                  badgeCount: unreadCount,
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
            
            _buildMenuOption(
              icon: Icons.military_tech,
              title: AppLocalizations.of(context)!.level,
              subtitle: AppLocalizations.of(context)!.yourProgressAchievements,
              color: const Color(0xFFF59E0B),
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
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          // Unread Badge
          if (badgeCount != null && badgeCount > 0)
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
          // Coin Star Icon (only for Wallet)
          if (showCoinIcon)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFB800)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB800).withValues(alpha:0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 11,
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

}

