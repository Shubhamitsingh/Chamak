import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_search_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'wallet_screen.dart';
import '../widgets/announcement_panel.dart';
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
        print('✅ User already has location saved');
        return;
      }

      print('🆕 New user detected - requesting location permission...');

      // Small delay to let screen load first
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      // Show dialog asking for location permission
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
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
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enable Location',
                        style: TextStyle(
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
                        text: 'Discover local content',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        icon: Icons.explore,
                        text: 'Find nearby hosts',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        icon: Icons.security,
                        text: 'Your data stays private',
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
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
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
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shadowColor: const Color(0xFFE91E63).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Allow',
                                style: TextStyle(
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
          } else {
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
    } catch (e) {
      print('❌ Error requesting location for new user: $e');
      // Don't disrupt user experience if location fails
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      final userCoins = userData?.coins ?? 0;
      
      // Check if popup should be shown
      final shouldShow = await _popupService.shouldShowPopup(
        userCoins: userCoins,
      );
      
      if (shouldShow && mounted) {
        // Show the popup
        await CoinPurchasePopup().show(
          context,
          specialOffer: userCoins < 100 
              ? '💰 Your coins are running low!' 
              : null,
        );
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

  // ========== HOME TAB (Explore/Live) ==========
  Widget _buildHomeTab() {
    return SafeArea(
      child: Column(
        children: [
          // Top Bar with Explore/Live Toggle and Search in One Line
          _buildTopBar(),
          
          // Main Content Area
          Expanded(
            child: _topTabIndex == 0 
                ? _buildExploreContent() 
                : _topTabIndex == 1
                    ? _buildLiveContent()
                    : _topTabIndex == 2
                        ? _buildFollowingContent()
                        : _buildNewHostsContent(),
          ),
        ],
      ),
    );
  }

  // ========== TOP BAR (Explore/Live/Following Toggle + Search in One Line) ==========
  Widget _buildTopBar() {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        height: 45,
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
                    setState(() {
                      _topTabIndex = 0;
                    });
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
                            color: const Color(0xFF8E24AA), // purple underline
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Live Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _topTabIndex = 1;
                    });
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
                            color: const Color(0xFF8E24AA), // purple underline
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Following Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _topTabIndex = 2;
                    });
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
                            color: const Color(0xFF8E24AA),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // New Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _topTabIndex = 3;
                    });
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
                            color: const Color(0xFF8E24AA),
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
                                          color: Colors.orange.withOpacity(0.5),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UserSearchScreen(),
                  ),
                );
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
              color: Color(0xFF8E24AA), // purple loader
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
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: true,
          cacheExtent: 500,
          itemCount: liveStreams.length,
          itemBuilder: (context, index) {
            final stream = liveStreams[index];
            return FadeInUp(
              delay: Duration(milliseconds: 50 * index),
              child: RepaintBoundary(
                child: GestureDetector(
                  onTap: () {
                    // Live streaming feature coming soon
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.liveStreamingComingSoon),
                        backgroundColor: const Color(0xFF8E24AA),
                      ),
                    );
                  },
                  child: _buildLiveStreamCard(
                    hostName: stream.hostName,
                    title: stream.title,
                    viewers: stream.viewerCount,
                    thumbnail: Icons.live_tv,
                    isLive: true,
                    hostPhotoUrl: stream.hostPhotoUrl,
                  ),
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
    // Sample data for 20 live hosts
    final List<Map<String, dynamic>> liveHosts = List.generate(20, (index) {
      final countries = ['USA', 'India', 'UK', 'Brazil', 'Japan', 'France', 'Germany', 'Italy', 'Spain', 'Canada'];
      final languages = ['English', 'Hindi', 'Spanish', 'Portuguese', 'Japanese', 'French', 'German', 'Italian', 'Korean', 'Arabic'];
      final names = ['Sarah', 'Mike', 'Priya', 'Carlos', 'Yuki', 'Emma', 'Hans', 'Sofia', 'Kim', 'Ahmed', 'Anna', 'John', 'Maria', 'David', 'Chen', 'Lisa', 'Raj', 'Nina', 'Alex', 'Maya'];
      
      return {
        'name': names[index % names.length],
        'country': countries[index % countries.length],
        'language': languages[index % languages.length],
        'viewers': (index + 1) * 123,
        'isLive': true,
      };
    });
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: liveHosts.length,
      itemBuilder: (context, index) {
        final host = liveHosts[index];
        return FadeInUp(
          delay: Duration(milliseconds: 30 * index),
          child: _buildExploreHostCard(
            name: host['name'],
            country: host['country'],
            language: host['language'],
            viewers: host['viewers'],
            isLive: host['isLive'],
          ),
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
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xCC04B104),
            Color(0xE6038103),
          ],
        ),
        borderRadius: BorderRadius.all(Radius.circular(15)),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D04B104),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Icon
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              thumbnail,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live Badge & Viewers
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
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
                
                // Title & Host Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          backgroundImage: hostPhotoUrl != null && hostPhotoUrl.isNotEmpty
                              ? NetworkImage(hostPhotoUrl)
                              : null,
                          child: hostPhotoUrl == null || hostPhotoUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Color(0xFF8E24AA),
                                )
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            hostName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== EXPLORE HOST CARD (For Explore Section) ==========
  Widget _buildExploreHostCard({
    required String name,
    required String country,
    required String language,
    required int viewers,
    required bool isLive,
  }) {
    return GestureDetector(
      onTap: () {
        // Live streaming feature coming soon
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.connectingToLiveStream(name)),
            backgroundColor: const Color(0xFF8E24AA),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B9D),
              Color(0xFFC06C84),
              Color(0xFF6C5B7B),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Host Image Placeholder (Background Pattern)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_outline,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Column(
              children: [
                // Top Bar - LIVE Badge (Left Side)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.liveLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Bottom Bar - Host Info & Call Button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Host Name
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Country, Language, and Call Button in One Row
                      Row(
                        children: [
                          // Country
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      country,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          
                          // Language
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.language,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      language,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          
                          // Call Button
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E24AA), Color(0xFF5E35B1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8E24AA).withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Viewers Count (Top Right)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    color: const Color(0xFFEC4899).withOpacity(0.4),
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
    // Sample data for newly joined hosts (last 7 days)
    final List<Map<String, dynamic>> newHosts = List.generate(12, (index) {
      final countries = ['USA', 'India', 'UK', 'Brazil', 'Japan', 'France', 'Germany', 'Italy', 'Spain', 'Canada'];
      final languages = ['English', 'Hindi', 'Spanish', 'Portuguese', 'Japanese', 'French', 'German', 'Italian', 'Korean', 'Arabic'];
      final names = ['Sarah', 'Mike', 'Priya', 'Carlos', 'Yuki', 'Emma', 'Hans', 'Sofia', 'Kim', 'Ahmed', 'Anna', 'John'];
      
      return {
        'name': names[index % names.length],
        'country': countries[index % countries.length],
        'language': languages[index % languages.length],
        'joinedDays': index + 1, // Days since joined
        'isLive': index % 3 == 0, // Some are live
      };
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 4, 15, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fiber_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.newlyJoinedHosts,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.discoverNewTalent,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Grid of New Hosts
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: newHosts.length,
            itemBuilder: (context, index) {
              final host = newHosts[index];
              return FadeInUp(
                delay: Duration(milliseconds: 30 * index),
                child: _buildNewHostCard(
                  name: host['name'],
                  country: host['country'],
                  language: host['language'],
                  joinedDays: host['joinedDays'],
                  isLive: host['isLive'],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // New Host Card Widget
  Widget _buildNewHostCard({
    required String name,
    required String country,
    required String language,
    required int joinedDays,
    required bool isLive,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.connectingToLiveStream(name)),
            backgroundColor: const Color(0xFF8E24AA),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEF4444),
              Color(0xFFEC4899),
              Color(0xFF8B5CF6),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_outline,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Column(
              children: [
                // Top Badges
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // NEW Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.newLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      
                      // LIVE Badge (if live)
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.liveLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom Info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Host Name
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Joined Days Ago
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: Colors.yellow[300],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            joinedDays == 1
                                ? AppLocalizations.of(context)!.joinedToday
                                : AppLocalizations.of(context)!.joinedDaysAgo(joinedDays.toString()),
                            style: TextStyle(
                              color: Colors.yellow[300],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Country and Language
                      Row(
                        children: [
                          // Country
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      country,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          
                          // Language
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.language,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      language,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ],
        ),
      ),
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
                      color: const Color(0xFF8E24AA).withOpacity(0.45),
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
                // Live streaming feature coming soon
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.liveStreamingComingSoon),
                    backgroundColor: const Color(0xFF8E24AA),
                    duration: const Duration(seconds: 2),
                  ),
                );
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
                shadowColor: const Color(0xFF8E24AA).withOpacity(0.4),
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
          setState(() {
            _currentBottomIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF9C27B0), // Purple for selected items
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
            icon: Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.home,
                  size: 28,
                );
              },
            ),
            label: AppLocalizations.of(context)!.home,
          ),
          
          // Wallet
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet, size: 28),
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
                      color: Colors.grey.withOpacity(0.2), // Gray shadow
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF9C27B0), // Purple icon
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
                : const Icon(Icons.message, size: 28),
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
        const Icon(Icons.message, size: 28),
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
                    color: Colors.red.withOpacity(0.5),
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Announcement Panel',
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
  }

  // ========== HELPER METHODS ==========
  String _formatViewers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}