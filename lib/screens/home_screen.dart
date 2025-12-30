import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'user_search_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'wallet_screen.dart';
import 'agora_live_stream_screen.dart';
import '../widgets/announcement_panel.dart';
import '../widgets/live_chat_panel.dart';
import '../services/live_stream_service.dart';
import '../services/chat_service.dart';
import '../services/event_service.dart';
import '../services/announcement_tracking_service.dart';
import '../services/coin_popup_service.dart';
import '../services/database_service.dart';
import '../models/live_stream_model.dart';
import '../models/announcement_model.dart';
import '../widgets/coin_purchase_popup.dart';
import '../services/location_permission_service.dart';
import '../services/agora_token_service.dart';

class HomeScreen extends StatefulWidget {
  final String phoneNumber;
  
  const HomeScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomIndex = 0;
  int _topTabIndex = 0; // 0 = Explore, 1 = Live, 2 = Following, 3 = New
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  final ChatService _chatService = ChatService();
  final EventService _eventService = EventService();
  final AnnouncementTrackingService _trackingService = AnnouncementTrackingService();
  final CoinPopupService _popupService = CoinPopupService();
  final DatabaseService _databaseService = DatabaseService();
  final LocationPermissionService _locationPermissionService = LocationPermissionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // 📍 Request location for new users (first time opening app)
    _requestLocationForNewUser();
    // 🪙 Coin Purchase Popup
    // Test Mode: Shows EVERY TIME (see coin_popup_service.dart line 8)
    // Production: Shows strategically (max 3/week, smart timing)
    Future.delayed(const Duration(seconds: 2), () {
      _checkAndShowCoinPopup();
    });
  }

  // Build benefit item widget
  Widget _buildBenefitItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E24AA), Color(0xFF5E35B1)], // deeper purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Request location permission and save for new users
  Future<void> _requestLocationForNewUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Check if user is new (no location saved)
      final isNewUser = await _locationPermissionService.isNewUserWithoutLocation();
      
      if (!isNewUser) {
        debugPrint('✅ User already has location saved');
        return;
      }

      debugPrint('🆕 New user detected - requesting location permission...');

      // Small delay to let screen load first
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      // Show dialog asking for location permission
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha:0.6),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.15),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE91E63),
                        Color(0xFF9C27B0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Animated Location Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.enableLocation,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'We need your location to provide better services and show you relevant content.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Benefits list
                      _buildBenefitItem(
                        icon: Icons.near_me,
                        text: AppLocalizations.of(context)!.discoverLocalContent,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        icon: Icons.explore,
                        text: AppLocalizations.of(context)!.findNearbyHosts,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        icon: Icons.security,
                        text: AppLocalizations.of(context)!.yourDataStaysPrivate,
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Skip button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            try {
                              Navigator.pop(context, false);
                            } catch (e) {
                              debugPrint('Error closing dialog: $e');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.skip,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Allow button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            try {
                              Navigator.pop(context, true);
                            } catch (e) {
                              debugPrint('Error closing dialog: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shadowColor: const Color(0xFFE91E63).withValues(alpha:0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.allow,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (shouldRequest == true && mounted) {
        // Request and save location
        final success = await _locationPermissionService.requestAndSaveLocation();
        
        if (mounted) {
          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Location saved successfully!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xFFE91E63),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 2),
              ),
            );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Location permission denied. You can add it later in profile settings.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 3),
              ),
            );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting location for new user: $e');
      // Don't disrupt user experience if location fails
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Check if coin popup should be shown based on smart logic
  Future<void> _checkAndShowCoinPopup() async {
    if (!mounted) return;
    
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Get user data to check coin balance
      final userData = await _databaseService.getUserData(currentUser.uid);
      // Use uCoins as primary (it's always updated during deductions)
      // Only use coins if uCoins is 0 and coins has value (legacy data)
      final userCoins = (userData?.uCoins ?? 0) > 0 ? (userData?.uCoins ?? 0) : (userData?.coins ?? 0);
      
      // Check if popup should be shown
      final shouldShow = await _popupService.shouldShowPopup(
        userCoins: userCoins,
      );
      
      if (shouldShow && mounted) {
        if (mounted) {
          // Show the popup
          await CoinPurchasePopup().show(
            context,
            specialOffer: userCoins < 100 
                ? '💰 Your coins are running low!' 
                : null,
          );
        }
      }
    } catch (e) {
      // Silently fail - don't disrupt user experience
      debugPrint('Error checking coin popup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentBottomIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildWalletTab();
      case 2:
        return _buildGoLiveTab();
      case 3:
        return _buildMessageTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // Build page content based on index
  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return _buildExploreContent();
      case 1:
        return _buildLiveContent();
      case 2:
        return _buildFollowingContent();
      case 3:
        return _buildNewHostsContent();
      default:
        return _buildExploreContent();
    }
  }

  // ========== HOME TAB (Explore/Live) ==========
  Widget _buildHomeTab() {
    return SafeArea(
      child: Column(
        children: [
          // Top Bar with Explore/Live Toggle and Search in One Line
          _buildTopBar(),
          
          // Main Content Area - Swipeable PageView
          Expanded(
            child: ClipRect(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _topTabIndex = index;
                  });
                },
                physics: const PageScrollPhysics(),
                allowImplicitScrolling: false,
                pageSnapping: true,
                itemCount: 4,
                itemBuilder: (context, index) {
                  return _buildPageContent(index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== TOP BAR (Explore/Live/Following Toggle + Search in One Line) ==========
  Widget _buildTopBar() {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        height: 42,
        child: Row(
          children: [
            // Text-Only Tabs (Left Side) - Scrollable
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Explore Button
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.explore,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _topTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _topTabIndex == 0 ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_topTabIndex == 0)
                        Container(
                          width: 30,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1B7C), // pink underline
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 15),
                
                // Live Button
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (_topTabIndex != 1)
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.red,
                            ),
                          if (_topTabIndex != 1)
                            const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.live,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _topTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                              color: _topTabIndex == 1 ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_topTabIndex == 1)
                        Container(
                          width: 30,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1B7C), // pink underline
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 15),
                
                // Following Button
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.following,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _topTabIndex == 2 ? FontWeight.bold : FontWeight.w500,
                          color: _topTabIndex == 2 ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_topTabIndex == 2)
                        Container(
                          width: 30,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1B7C), // pink underline
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 15),
                
                // New Button
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      3,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.newHosts,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _topTabIndex == 3 ? FontWeight.bold : FontWeight.w500,
                              color: _topTabIndex == 3 ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                          if (_topTabIndex != 3) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_topTabIndex == 3)
                        Container(
                          width: 30,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1B7C), // pink underline
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Announcement Icon with Badge Counter (Only Unseen)
            StreamBuilder<List<AnnouncementModel>>(
              stream: _eventService.getAnnouncementsStream(),
              builder: (context, announcementSnapshot) {
                return StreamBuilder<Set<String>>(
                  stream: _trackingService.getSeenAnnouncementIdsStream(),
                  builder: (context, seenSnapshot) {
                    return StreamBuilder<Set<String>>(
                      stream: _trackingService.getDismissedAnnouncementIdsStream(),
                      builder: (context, dismissedSnapshot) {
                        final announcements = announcementSnapshot.data ?? [];
                        final seenIds = seenSnapshot.data ?? {};
                        final dismissedIds = dismissedSnapshot.data ?? {};
                        
                        // Count only NEW and UNSEEN and NOT DISMISSED announcements
                        final unseenNewCount = announcements
                            .where((a) => 
                              a.isNew && 
                              !seenIds.contains(a.id) &&
                              !dismissedIds.contains(a.id))
                            .length;
                        
                        return GestureDetector(
                          onTap: () async {
                            // Mark all current new announcements as seen when opening
                            final newAnnouncementIds = announcements
                                .where((a) => a.isNew && !seenIds.contains(a.id))
                                .map((a) => a.id)
                                .toList();
                            
                            if (newAnnouncementIds.isNotEmpty) {
                              await _trackingService.markMultipleAsSeen(newAnnouncementIds);
                            }
                            
                            _showAnnouncementPanel(context);
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.whatshot_rounded,
                                  color: Colors.orange[700],
                                  size: 26,
                                ),
                              ),
                              // Counter Badge (Only Unseen)
                              if (unseenNewCount > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withValues(alpha:0.5),
                                          blurRadius: 6,
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
                                        unseenNewCount > 9 ? '9+' : unseenNewCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            
            const SizedBox(width: 1),
            
            // User Search Icon (Search People by ID)
            GestureDetector(
              onTap: () {
                if (!mounted) return;
                try {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UserSearchScreen(),
                    ),
                  );
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.search_rounded,
                  color: Colors.grey[700],
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== LIVE CONTENT ==========
  Widget _buildLiveContent() {
    final liveStreamService = LiveStreamService();
    
    return StreamBuilder<List<LiveStreamModel>>(
      stream: liveStreamService.getActiveLiveStreams(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF69B4), // pink loader
            ),
          );
        }
        
        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorLoadingStreams,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        
        // No data state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.live_tv, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.noLiveStreamsAtMoment,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.beFirstToGoLive,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Display streams
        final liveStreams = snapshot.data!;
        
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          physics: const NeverScrollableScrollPhysics(),
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
          itemCount: liveStreams.length,
          itemBuilder: (context, index) {
            final stream = liveStreams[index];
            return RepaintBoundary(
              child: GestureDetector(
                onTap: () async {
                  if (!mounted) return;
                  // Navigate to live stream as audience/viewer
                  // Generate token dynamically using AgoraTokenService
                  debugPrint('👁️ Viewer joining stream: ${stream.streamId}');
                  debugPrint('📺 Channel: ${stream.channelName}');
                  
                  try {
                    final tokenService = AgoraTokenService();
                    final token = await tokenService.getAudienceToken(
                      channelName: stream.channelName,
                      uid: 0,
                    );
                    debugPrint('✅ Generated audience token: ${token.length} chars');
                    
                    if (!mounted) return;
                    
                    // Increment viewer count
                    liveStreamService.joinStream(stream.streamId);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgoraLiveStreamScreen(
                          channelName: stream.channelName, // Use channel name from Firebase
                          token: token,
                          isHost: false, // Viewer mode
                          streamId: stream.streamId, // Pass streamId for cleanup
                        ),
                      ),
                    ).then((_) {
                      // Decrement viewer count when viewer leaves
                      liveStreamService.leaveStream(stream.streamId);
                    });
                  } catch (e) {
                    debugPrint('❌ Error generating token: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to join stream: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                  child: _buildLiveStreamCard(
                    hostName: stream.hostName,
                    title: stream.title,
                    viewers: stream.viewerCount,
                    thumbnail: Icons.live_tv,
                    isLive: true,
                    hostPhotoUrl: stream.hostPhotoUrl,
                    streamId: stream.streamId, // Pass streamId for chat
                    hostId: stream.hostId, // Pass hostId to fetch user data
                  ),
              ),
            );
          },
        );
      },
    );
  }

  // ========== EXPLORE CONTENT ==========
  Widget _buildExploreContent() {
    // Show real-time live streams from Firebase (same as Live tab)
    final liveStreamService = LiveStreamService();
    
    return StreamBuilder<List<LiveStreamModel>>(
      stream: liveStreamService.getActiveLiveStreams(),
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
                Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorLoadingStreams,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        
        // No data state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.live_tv, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.noLiveStreamsAtMoment,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.beFirstToGoLive,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Display streams
        final liveStreams = snapshot.data!;
        
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: liveStreams.length,
          itemBuilder: (context, index) {
            final stream = liveStreams[index];
            return FadeInUp(
              delay: Duration(milliseconds: 50 * index),
              child: GestureDetector(
                onTap: () async {
                  if (!mounted) return;
                  // Navigate to live stream as viewer
                  // Generate token dynamically using AgoraTokenService
                  debugPrint('👁️ Viewer joining stream: ${stream.streamId}');
                  debugPrint('📺 Channel: ${stream.channelName}');
                  
                  try {
                    final tokenService = AgoraTokenService();
                    final token = await tokenService.getAudienceToken(
                      channelName: stream.channelName,
                      uid: 0,
                    );
                    debugPrint('✅ Generated audience token: ${token.length} chars');
                    
                    if (!mounted) return;
                    
                    // Increment viewer count
                    liveStreamService.joinStream(stream.streamId);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgoraLiveStreamScreen(
                          channelName: stream.channelName,
                          token: token,
                          isHost: false, // Viewer mode
                          streamId: stream.streamId, // Pass streamId for cleanup
                        ),
                      ),
                    ).then((_) {
                      // Decrement viewer count when viewer leaves
                      liveStreamService.leaveStream(stream.streamId);
                    });
                  } catch (e) {
                    debugPrint('❌ Error generating token: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to join stream: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                  child: _buildLiveStreamCard(
                    hostName: stream.hostName,
                    title: stream.title,
                    viewers: stream.viewerCount,
                    thumbnail: Icons.live_tv,
                    isLive: true,
                    hostPhotoUrl: stream.hostPhotoUrl,
                    streamId: stream.streamId, // Pass streamId for chat
                    hostId: stream.hostId, // Pass hostId to fetch user data
                  ),
              ),
            );
          },
        );
      },
    );
  }

  // ========== LIVE STREAM CARD ==========
  Widget _buildLiveStreamCard({
    required String hostName,
    required String title,
    required int viewers,
    required IconData thumbnail,
    required bool isLive,
    String? hostPhotoUrl,
    String? streamId, // Add streamId for chat
    String? hostId, // Add hostId to fetch user data
  }) {
    // Default gradient background (fallback) - Pink and White gradient
    final defaultDecoration = BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF1B7C), // Pink
          Colors.white,      // White
        ],
      ),
      borderRadius: const BorderRadius.all(Radius.circular(15)),
    );

    return Container(
      decoration: defaultDecoration,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: hostId != null
            ? StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(hostId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  String? coverImageUrl;
                  
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    final coverURL = userData?['coverURL'] as String?;
                    
                    // Get first cover image URL if available
                    if (coverURL != null && coverURL.isNotEmpty) {
                      final coverImages = coverURL.split(',').where((url) => url.trim().isNotEmpty).toList();
                      if (coverImages.isNotEmpty) {
                        coverImageUrl = coverImages[0].trim();
                      }
                    }
                  }
                  
                  // If cover image exists, show it, otherwise show gradient
                  return Stack(
                    children: [
                      // Background: Cover Image or Gradient
                      if (coverImageUrl != null && coverImageUrl.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            coverImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to gradient if image fails to load
                              return Container(decoration: defaultDecoration);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              // Show gradient while loading
                              return Container(decoration: defaultDecoration);
                            },
                          ),
                        )
                      else
                        Container(decoration: defaultDecoration),
                      
                      // Gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Live Badge & Viewers (Top)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(context)!.liveLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.remove_red_eye,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            _formatViewers(viewers),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Language + Country + Video Icon (Bottom - Horizontal Row)
                            userSnapshot.hasData && userSnapshot.data!.exists
                                ? Builder(
                                    builder: (context) {
                                      final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                      final language = userData?['language'] ?? 'English';
                                      final country = userData?['country'];
                                      
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Language (no icon)
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              language,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                            ),
                                          ),
                                          // Country (if available) or empty space
                                          Expanded(
                                            flex: 1,
                                            child: country != null && country.toString().isNotEmpty
                                                ? Text(
                                                    country.toString(),
                                                    style: TextStyle(
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                          // Video Icon in Pink Circle
                                          Expanded(
                                            flex: 1,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFF1B7C), // Pink color
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Image.asset(
                                                    'assets/images/video.png',
                                                    width: 20,
                                                    height: 20,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.videocam_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Fallback if no user data
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'English',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.start,
                                        ),
                                      ),
                                      // Empty space for country
                                      const Expanded(
                                        flex: 1,
                                        child: SizedBox.shrink(),
                                      ),
                                      // Video Icon in Pink Circle
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF1B7C), // Pink color
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Image.asset(
                                                'assets/images/video.png',
                                                width: 20,
                                                height: 20,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.videocam_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              )
            : Stack(
                children: [
                  // Default gradient background when no hostId
                  Container(decoration: defaultDecoration),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Live Badge & Viewers (Top)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!.liveLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.remove_red_eye,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _formatViewers(viewers),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Language + Country + Video Icon (Bottom - Horizontal Row)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Fallback if no hostId
                            Expanded(
                              flex: 1,
                              child: Text(
                                'English',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                            // Empty space for country
                            const Expanded(
                              flex: 1,
                              child: SizedBox.shrink(),
                            ),
                            // Video Icon in Pink Circle
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF1B7C), // Pink color
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/video.png',
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.videocam_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ========== FOLLOWING CONTENT ==========
  Widget _buildFollowingContent() {
    // Following feature - Shows live streams from followed hosts
    // Note: This feature requires a follow/unfollow system to be implemented in the database
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFEF4444)],
                ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha:0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                Icons.favorite_rounded,
                        color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              AppLocalizations.of(context)!.followingTabTitle,
              style: const TextStyle(
                fontSize: 24,
                      fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              AppLocalizations.of(context)!.followingTabDescription,
              textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== NEW HOSTS CONTENT ==========
  Widget _buildNewHostsContent() {
    // Show real-time live streams (same as Live and Explore tabs)
    final liveStreamService = LiveStreamService();
    
    return StreamBuilder<List<LiveStreamModel>>(
      stream: liveStreamService.getActiveLiveStreams(),
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
                Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorLoadingStreams,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        
        // No data state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.live_tv, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.noLiveStreamsAtMoment,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.beFirstToGoLive,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Display streams
        final liveStreams = snapshot.data!;
        
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          physics: const NeverScrollableScrollPhysics(),
          addAutomaticKeepAlives: false,
          itemCount: liveStreams.length,
          itemBuilder: (context, index) {
            final stream = liveStreams[index];
            return GestureDetector(
              onTap: () async {
                if (!mounted) return;
                // Navigate to live stream as viewer
                // Generate token dynamically using AgoraTokenService
                debugPrint('👁️ Viewer joining stream: ${stream.streamId}');
                debugPrint('📺 Channel: ${stream.channelName}');
                
                try {
                  final tokenService = AgoraTokenService();
                  final token = await tokenService.getAudienceToken(
                    channelName: stream.channelName,
                    uid: 0,
                  );
                  debugPrint('✅ Generated audience token: ${token.length} chars');
                  
                  if (!mounted) return;
                  
                  // Increment viewer count
                  liveStreamService.joinStream(stream.streamId);
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgoraLiveStreamScreen(
                        channelName: stream.channelName,
                        token: token,
                        isHost: false, // Viewer mode
                        streamId: stream.streamId, // Pass streamId for cleanup
                      ),
                    ),
                  ).then((_) {
                    // Decrement viewer count when viewer leaves
                    liveStreamService.leaveStream(stream.streamId);
                  });
                } catch (e) {
                  debugPrint('❌ Error generating token: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to join stream: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
                  child: _buildLiveStreamCard(
                    hostName: stream.hostName,
                    title: stream.title,
                    viewers: stream.viewerCount,
                    thumbnail: Icons.live_tv,
                    isLive: true,
                    hostPhotoUrl: stream.hostPhotoUrl,
                    streamId: stream.streamId, // Pass streamId for chat
                    hostId: stream.hostId, // Pass hostId to fetch user data
                  ),
            );
          },
        );
      },
    );
  }

  // ========== WALLET TAB ==========
  Widget _buildWalletTab() {
    return WalletScreen(
      phoneNumber: widget.phoneNumber,
      isHost: false,
      showBackButton: false, // No back button from homepage
    );
  }

  // ========== GO LIVE TAB ==========
  Widget _buildGoLiveTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeIn(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E24AA), Color(0xFF5E35B1)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E24AA).withValues(alpha:0.45),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              AppLocalizations.of(context)!.startYourLiveStream,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              AppLocalizations.of(context)!.shareYourMoments,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _startLiveStream();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E24AA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 5,
                shadowColor: const Color(0xFF8E24AA).withValues(alpha:0.4),
              ),
              child: Text(
                AppLocalizations.of(context)!.goLiveNow,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== START LIVE STREAM ==========
  // Open chat panel for live stream
  void _openChatPanel(String streamId) {
    final currentUser = _auth.currentUser;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LiveChatPanel(
        liveStreamId: streamId,
        isHost: false, // Always false when opening from home screen
        currentUserId: currentUser?.uid,
        currentUserName: currentUser?.displayName,
        currentUserImage: currentUser?.photoURL,
      ),
    );
  }

  Future<void> _startLiveStream() async {
    if (!mounted) return;
    
    // Navigator reference for closing loading dialog
    NavigatorState? navigator;
    bool isLoadingDialogShown = false;
    
    try {
      // Step 1: Check authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseLoginToStartLiveStream),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Step 2: Check for existing active stream (prevent concurrent streams)
      final liveStreamService = LiveStreamService();
      final existingStream = await liveStreamService.getHostActiveStream(currentUser.uid)
          .timeout(const Duration(seconds: 10));
      
      if (existingStream != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You already have an active live stream. Please end it before starting a new one.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Step 3: Request camera and microphone permissions BEFORE creating stream
      if (!mounted) return;
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();
      
      if (cameraStatus.isDenied || micStatus.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera and microphone permissions are required to start a live stream.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enable camera and microphone permissions in app settings.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      // Step 4: Show loading indicator
      if (!mounted) return;
      navigator = Navigator.of(context);
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF69B4),
            ),
          ),
        );
        isLoadingDialogShown = true;
      } catch (e) {
        debugPrint('Error showing dialog: $e');
        return;
      }

      // Step 5: Get user data
      final userData = await _databaseService.getUserData(currentUser.uid)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      
      final hostName = userData?.name ?? currentUser.displayName ?? currentUser.phoneNumber ?? 'Host';
      final hostPhotoUrl = userData?.photoURL;

      // Step 6: Generate unique stream ID and channel name
      final firestore = FirebaseFirestore.instance;
      final streamId = firestore.collection('live_streams').doc().id;
      final channelName = streamId; // Use streamId as unique channel name
      
      // Step 7: Generate token FIRST (before creating stream to avoid orphaned streams)
      final tokenService = AgoraTokenService();
      String token;
      try {
        token = await tokenService.getHostToken(
          channelName: channelName,
          uid: 0,
        ).timeout(const Duration(seconds: 15));
        debugPrint('✅ Generated host token: ${token.length} chars');
        debugPrint('📋 Token preview: ${token.substring(0, 20)}...');
      } catch (e) {
        debugPrint('❌ Error generating token: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate token: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return; // Don't create stream if token generation fails
      }

      if (!mounted) return;

      // Step 8: Create stream model
      final stream = LiveStreamModel(
        streamId: streamId,
        channelName: channelName,
        hostId: currentUser.uid,
        hostName: hostName,
        hostPhotoUrl: hostPhotoUrl,
        title: AppLocalizations.of(context)!.liveStream,
        viewerCount: 0,
        startedAt: DateTime.now(),
        isActive: true,
      );
      
      // Step 9: Save to Firebase (AFTER token generation succeeds)
      await liveStreamService.createStream(stream)
          .timeout(const Duration(seconds: 10));
      
      debugPrint('✅ Live stream created in Firebase: $streamId');
      debugPrint('📺 Channel name: $channelName');
      debugPrint('📺 Stream ID: $streamId');
      debugPrint('📺 Stream will appear in home page grid');
      
      if (!mounted) return;

      // Step 10: Navigate to Agora Live Streaming Screen as Host
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgoraLiveStreamScreen(
              channelName: channelName,
              token: token,
              isHost: true, // Host mode
              streamId: streamId, // Pass streamId for cleanup
            ),
          ),
        );
      } catch (e) {
        debugPrint('Navigation error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start live stream: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error starting live stream: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting live stream: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Step 11: Always close loading dialog if it was shown
      if (isLoadingDialogShown && mounted && navigator != null) {
        try {
          navigator.pop();
        } catch (e) {
          debugPrint('Error closing dialog: $e');
          // Try alternative method if first fails
          try {
            Navigator.of(context, rootNavigator: true).pop();
          } catch (e2) {
            debugPrint('Error closing dialog (alternative): $e2');
          }
        }
      }
    }
  }

  // ========== PROFILE TAB ==========
  Widget _buildProfileTab() {
    return ProfileScreen(phoneNumber: widget.phoneNumber);
  }

  // ========== MESSAGE TAB ==========
  Widget _buildMessageTab() {
    return const ChatListScreen();
  }

  // ========== BOTTOM NAVIGATION BAR ==========
  Widget _buildBottomNavigationBar() {
    final currentUser = _auth.currentUser;
    
    return BottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: (index) {
          // Handle (+) button click (index 2) - navigate to live streaming screen
          if (index == 2) {
            _startLiveStream();
            // Don't change the selected index, keep it on current tab
            return;
          }
          
          setState(() {
            _currentBottomIndex = index;
          });
        },
        selectedItemColor: Colors.black, // Black for selected items
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        iconSize: 28,
        items: [
          // Home
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded, size: 28),
            label: AppLocalizations.of(context)!.home,
          ),
          
          // Wallet
          BottomNavigationBarItem(
            icon: _buildColoredIcon(
              'assets/images/walleticon.png',
              isSelected: _currentBottomIndex == 1,
            ),
            label: AppLocalizations.of(context)!.wallet,
          ),
          
          // Go Live (Plus Icon - Centered)
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300], // Gray background
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha:0.2), // Gray shadow
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.black, // Black icon
                  size: 24,
                  weight: 700,
                ),
              ),
            ),
            label: '',
          ),
          
          // Message with Badge
          BottomNavigationBarItem(
            icon: currentUser != null
                ? StreamBuilder<int>(
                    stream: _chatService.getTotalUnreadCount(currentUser.uid),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return _buildMessageIconWithBadge(unreadCount);
                    },
                  )
                : _buildColoredIcon(
                    'assets/images/comment.png',
                    isSelected: _currentBottomIndex == 3,
                  ),
            label: AppLocalizations.of(context)!.messages,
          ),
          
          // Me (Profile)
          BottomNavigationBarItem(
            icon: const Icon(Icons.person, size: 28),
            label: AppLocalizations.of(context)!.me,
          ),
        ],
      );
  }

  // Message Icon with Badge
  Widget _buildMessageIconWithBadge(int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildColoredIcon(
          'assets/images/comment.png',
          isSelected: _currentBottomIndex == 3,
        ),
        if (unreadCount > 0)
          Positioned(
            top: -4,
            right: -6,
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
                    color: Colors.red.withValues(alpha:0.5),
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
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
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
    );
  }


  // ========== SHOW ANNOUNCEMENT PANEL ==========
  void _showAnnouncementPanel(BuildContext context) {
    if (!mounted) return;
    try {
      showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.announcementPanel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AnnouncementPanel();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Start from right
        const end = Offset.zero; // End at position
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
    } catch (e) {
      debugPrint('Error showing announcement panel: $e');
    }
  }

  // ========== HELPER METHODS ==========
  String _formatViewers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Build colored icon (black when selected, gray when not selected)
  Widget _buildColoredIcon(String imagePath, {required bool isSelected}) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected ? Colors.black : Colors.grey,
        BlendMode.srcATop,
      ),
      child: Image.asset(
        imagePath,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            imagePath.contains('walleticon') 
                ? Icons.account_balance_wallet 
                : Icons.message,
            size: 28,
            color: isSelected ? Colors.black : Colors.grey,
          );
        },
      ),
    );
  }
}