import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:country_picker/country_picker.dart';
import 'user_search_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'wallet_screen.dart';
import 'agora_live_stream_screen.dart';
import 'host_rules_screen.dart';
import 'user_profile_view_screen.dart';
import '../widgets/announcement_panel.dart';
import '../services/live_stream_service.dart';
import '../services/chat_service.dart';
import '../services/event_service.dart';
import '../services/announcement_tracking_service.dart';
import '../services/coin_popup_service.dart';
import '../services/database_service.dart';
import '../services/online_status_service.dart';
import '../models/live_stream_model.dart';
import '../models/announcement_model.dart';
import '../widgets/coin_purchase_popup.dart';
import '../services/location_permission_service.dart';
import '../services/agora_token_service.dart';
import '../services/telegram_popup_service.dart';
import '../widgets/telegram_channel_popup.dart';
import '../widgets/enhanced_loading_screen.dart';
import 'live_reels_screen.dart';
import 'nearby_users_screen.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

// Optimized Scrolling Text Widget for Banner
class _ScrollingText extends StatelessWidget {
  final String text;
  final AnimationController controller;

  const _ScrollingText({
    required this.text,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Transform.translate(
              offset: Offset(-controller.value * 300, 0),
              child: Row(
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                  const SizedBox(width: 100),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String phoneNumber;

  const HomeScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentBottomIndex = 0;
  int _topTabIndex = 0; // 0 = Explore, 1 = Live, 2 = Following, 3 = New, 4 = Nearby
  final TextEditingController _searchController = TextEditingController();
  late final PageController _pageController;
  final ScrollController _topMenuScrollController = ScrollController(); // For scrolling menu to active tab
  final ChatService _chatService = ChatService();
  final EventService _eventService = EventService();
  final AnnouncementTrackingService _trackingService =
      AnnouncementTrackingService();
  final CoinPopupService _popupService = CoinPopupService();
  final TelegramPopupService _telegramPopupService = TelegramPopupService();
  final DatabaseService _databaseService = DatabaseService();
  final LocationPermissionService _locationPermissionService =
      LocationPermissionService();
  final OnlineStatusService _onlineStatusService = OnlineStatusService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _marqueeController;

  // Live stream preview state
  Timer? _previewDelayTimer;
  final ValueNotifier<bool> _previewDelayNotifier = ValueNotifier<bool>(false);
  bool get _isLiveReelsFullScreen =>
      _currentBottomIndex == 0 && _topTabIndex == 1;

  @override
  void initState() {
    super.initState();
    // Initialize PageController with the current topTabIndex to preserve state
    _pageController = PageController(initialPage: _topTabIndex);
    
    // Add lifecycle observer for app state tracking
    WidgetsBinding.instance.addObserver(this);
    
    // Ensure status bar and navigation overlays stay visible (including Live tab)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    // Force status bar style so battery/network icons stay visible on light background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    // Initialize marquee animation controller
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Start delay timer for live stream previews (3 seconds)
    _startPreviewDelayTimer();

    // 📍 Request location for new users (first time opening app)
    _requestLocationForNewUser();
    
    // 🔴 Initialize online status tracking
    _onlineStatusService.initializeStatusTracking();
    
    // 🪙 Coin Purchase Popup
    // Test Mode: Shows EVERY TIME (see coin_popup_service.dart line 8)
    // Production: Shows strategically (max 3/week, smart timing)
    Future.delayed(const Duration(seconds: 2), () {
      _checkAndShowCoinPopup();
    });
    
    // 📱 Telegram Channel Popup
    // Shows after coin popup (6 seconds delay to allow coin popup to show and be dismissed)
    // Reset session flag on app start
    _telegramPopupService.resetSessionFlag();
    Future.delayed(const Duration(seconds: 6), () {
      _checkAndShowTelegramPopup();
    });
    
    // Sync topTabIndex with PageController's initial page after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        final currentPage = _pageController.page?.round() ?? 0;
        if (_topTabIndex != currentPage) {
          setState(() {
            _topTabIndex = currentPage;
          });
        }
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync topTabIndex when returning to this screen (when bottom tab changes to Home)
    if (_currentBottomIndex == 0 && _pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? _topTabIndex;
      if (_topTabIndex != currentPage && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentBottomIndex == 0) {
            setState(() {
              _topTabIndex = currentPage;
            });
            // Scroll menu to show active tab
            _scrollMenuToActiveTab();
          }
        });
      }
    }
  }
  
  // Scroll menu to show the active tab
  void _scrollMenuToActiveTab() {
    if (!_topMenuScrollController.hasClients) return;
    
    // Calculate approximate position for each tab
    // Each tab is approximately 80-100 pixels wide (including spacing)
    final tabWidth = 100.0;
    final scrollPosition = _topTabIndex * tabWidth;
    
    // Scroll to show the active tab
    _topMenuScrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - update status immediately
        _onlineStatusService.updateLastSeen(userId);
        _onlineStatusService.initializeStatusTracking();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App went to background - stop periodic updates (lastSeen will remain until timeout)
        _onlineStatusService.stopStatusTracking();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startPreviewDelayTimer() {
    debugPrint('⏱️ Starting preview delay timer (3 seconds)');
    _previewDelayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        debugPrint('✅ Preview delay passed - enabling video previews');
        setState(() {});
        _previewDelayNotifier.value = true; // Notify ValueListenableBuilder
      }
    });
  }

  // Build benefit item widget
  Widget _buildBenefitItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFFF1744).withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: const Color(0xFFFF1744).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFF1744),
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
              height: 1.25,
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
      final isNewUser =
          await _locationPermissionService.isNewUserWithoutLocation();

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
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 12, bottom: 10, left: 14, right: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF1744), // App primary pink
                        Color(0xFFFF5252), // Lighter pink
                        Color(0xFFE91E63), // Darker pink
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Location Icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.enableLocation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    children: [
                      Text(
                        'We need your location to provide better services and show you relevant content.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Benefits list
                      _buildBenefitItem(
                        icon: Icons.near_me,
                        text:
                            AppLocalizations.of(context)!.discoverLocalContent,
                      ),
                      const SizedBox(height: 6),
                      _buildBenefitItem(
                        icon: Icons.explore,
                        text: AppLocalizations.of(context)!.findNearbyHosts,
                      ),
                      const SizedBox(height: 6),
                      _buildBenefitItem(
                        icon: Icons.security,
                        text:
                            AppLocalizations.of(context)!.yourDataStaysPrivate,
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.skip,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                            backgroundColor: const Color(0xFFFF1744),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.all(
                              const Color(0xFFFF1744),
                            ),
                            overlayColor: MaterialStateProperty.all(
                              Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.allow,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
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
        final success =
            await _locationPermissionService.requestAndSaveLocation();

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
    WidgetsBinding.instance.removeObserver(this);
    _onlineStatusService.stopStatusTracking();
    _previewDelayTimer?.cancel();
    _previewDelayNotifier.dispose();
    _searchController.dispose();
    _pageController.dispose();
    _topMenuScrollController.dispose();
    _marqueeController.dispose();
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
      final userCoins = (userData?.uCoins ?? 0) > 0
          ? (userData?.uCoins ?? 0)
          : (userData?.coins ?? 0);

      // Check if popup should be shown
      final shouldShow = await _popupService.shouldShowPopup(
        userCoins: userCoins,
      );

      if (shouldShow && mounted) {
        if (mounted) {
          // Show the popup
          await CoinPurchasePopup().show(
            context,
            specialOffer:
                userCoins < 100 ? '💰 Your coins are running low!' : null,
          );
        }
      }
    } catch (e) {
      // Silently fail - don't disrupt user experience
      debugPrint('Error checking coin popup: $e');
    }
  }

  /// Check if Telegram popup should be shown and display it
  Future<void> _checkAndShowTelegramPopup() async {
    if (!mounted) return;

    try {
      // Check if should show popup
      final shouldShow = await _telegramPopupService.shouldShowPopup();
      if (!shouldShow) return;

      // Check if user is in live stream (don't show during live)
      if (_isLiveReelsFullScreen) {
        return; // Don't show during live streams
      }

      // Mark as shown in session
      await _telegramPopupService.markShownInSession();
      await _telegramPopupService.incrementShowCount();

      // Show popup
      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true, // Allow tap outside to dismiss
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) => TelegramChannelPopup(
          telegramChannelUrl: 'https://t.me/+kwidFzpWJ-k4ZTdl',
          appName: 'Chamakz',
          popupService: _telegramPopupService,
        ),
      );

      // Handle result (optional analytics)
      if (result == true) {
        debugPrint('✅ User joined Telegram channel');
      } else {
        debugPrint('ℹ️ User skipped Telegram popup');
      }
    } catch (e) {
      // Silently fail - don't disrupt user experience
      debugPrint('Error showing Telegram popup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: _buildBody(),
      bottomNavigationBar:
          _isLiveReelsFullScreen ? null : _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentBottomIndex) {
      case 0:
        // When returning to Home tab, ensure PageController is on the correct page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentBottomIndex == 0 && _pageController.hasClients) {
            final currentPage = _pageController.page?.round() ?? _topTabIndex;
            if (currentPage != _topTabIndex) {
              // PageController is on different page, sync it
              _pageController.jumpToPage(_topTabIndex);
            }
          }
        });
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
      case 4:
        return _buildNearbyContent();
      default:
        return _buildExploreContent();
    }
  }

  // ========== HOME TAB (Explore/Live) ==========
  Widget _buildHomeTab() {
    final overlayStyle = SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent, // let top bar background show through
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (!_isLiveReelsFullScreen) _buildTopBar(),
                if (!_isLiveReelsFullScreen) _buildAnnouncementBar(),
                Expanded(
                  child: ClipRect(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (mounted) {
                          setState(() {
                            _topTabIndex = index;
                          });
                          debugPrint('📱 Page changed to index: $index, _topTabIndex: $_topTabIndex');
                          // Scroll menu to show active tab
                          _scrollMenuToActiveTab();
                        }
                      },
                      physics: const PageScrollPhysics(),
                      allowImplicitScrolling: false,
                      pageSnapping: true,
                      itemCount: 5, // 0=Explore, 1=Live, 2=Following, 3=New, 4=Nearby
                      itemBuilder: (context, index) {
                        return _buildPageContent(index);
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_isLiveReelsFullScreen)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _topTabIndex = 0;
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========== TOP BAR (Explore/Live/Following Toggle + Search in One Line) ==========
  Widget _buildTopBar() {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        height: 42,
        child: Row(
          children: [
            // Text-Only Tabs (Left Side) - Scrollable
            Expanded(
              child: SingleChildScrollView(
                controller: _topMenuScrollController,
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
                              fontWeight: _topTabIndex == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _topTabIndex == 0
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_topTabIndex == 0)
                            Container(
                              width: 30,
                              height: 3,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFFF1B7C), // pink underline
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
                              if (_topTabIndex != 1) const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.live,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _topTabIndex == 1
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _topTabIndex == 1
                                      ? Colors.black87
                                      : Colors.grey[600],
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
                                color:
                                    const Color(0xFFFF1B7C), // pink underline
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
                              fontWeight: _topTabIndex == 2
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _topTabIndex == 2
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_topTabIndex == 2)
                            Container(
                              width: 30,
                              height: 3,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFFF1B7C), // pink underline
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
                                  fontWeight: _topTabIndex == 3
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _topTabIndex == 3
                                      ? Colors.black87
                                      : Colors.grey[600],
                                ),
                              ),
                              if (_topTabIndex != 3) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
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
                                color:
                                    const Color(0xFFFF1B7C), // pink underline
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 15),

                    // Nearby Button
                    GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          4,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.near_me,
                                size: 16,
                                color: Color(0xFFFF1B7C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Nearby',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _topTabIndex == 4
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _topTabIndex == 4
                                      ? Colors.black87
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_topTabIndex == 4)
                            Container(
                              width: 30,
                              height: 3,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFFF1B7C), // pink underline
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

            // Announcement Icon with Badge Counter (Only Unseen) - Optimized
            StreamBuilder<List<AnnouncementModel>>(
              stream: _eventService.getAnnouncementsStream(),
              builder: (context, announcementSnapshot) {
                if (!announcementSnapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.whatshot_rounded,
                      color: Colors.orange[700],
                      size: 26,
                    ),
                  );
                }

                final announcements = announcementSnapshot.data ?? [];

                return StreamBuilder<Set<String>>(
                  stream: _trackingService.getSeenAnnouncementIdsStream(),
                  builder: (context, seenSnapshot) {
                    if (!seenSnapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.whatshot_rounded,
                          color: Colors.orange[700],
                          size: 26,
                        ),
                      );
                    }

                    final seenIds = seenSnapshot.data ?? {};

                    return StreamBuilder<Set<String>>(
                      stream:
                          _trackingService.getDismissedAnnouncementIdsStream(),
                      builder: (context, dismissedSnapshot) {
                        if (!mounted) {
                          return const SizedBox.shrink();
                        }

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
                            if (!mounted) return;
                            // Mark all current new announcements as seen when opening
                            final newAnnouncementIds = announcements
                                .where(
                                    (a) => a.isNew && !seenIds.contains(a.id))
                                .map((a) => a.id)
                                .toList();

                            if (newAnnouncementIds.isNotEmpty) {
                              await _trackingService
                                  .markMultipleAsSeen(newAnnouncementIds);
                            }

                            if (mounted) {
                              _showAnnouncementPanel(context);
                            }
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
                                        colors: [
                                          Color(0xFFFF5722),
                                          Color(0xFFFF9800)
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange
                                              .withValues(alpha: 0.5),
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
                                        unseenNewCount > 9
                                            ? '9+'
                                            : unseenNewCount.toString(),
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

  // Helper method to sanitize text and remove problematic characters
  String _sanitizeText(String? text) {
    if (text == null || text.isEmpty) return '';

    try {
      // Remove null characters, control characters, and problematic unicode
      String sanitized = text
          .replaceAll('\x00', '') // Remove null characters
          .replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'),
              '') // Remove control characters
          .trim()
          .replaceAll(
              RegExp(r'\s+'), ' '); // Replace multiple spaces with single space

      // Ensure it's valid UTF-8 and doesn't contain widget references
      sanitized = sanitized.replaceAll(
          RegExp(r'<[^>]*>'), ''); // Remove any HTML-like tags
      sanitized = sanitized.replaceAll(RegExp(r'\{[^}]*\}'),
          ''); // Remove any brace patterns that might be widget references

      return sanitized;
    } catch (e) {
      debugPrint('Error sanitizing text: $e');
      return text.trim();
    }
  }

  // ========== SCROLLING ANNOUNCEMENT BAR ==========
  Widget _buildAnnouncementBar() {
    return RepaintBoundary(
      child: StreamBuilder<List<AnnouncementModel>>(
        stream: _eventService.getAnnouncementsStream(),
        builder: (context, announcementSnapshot) {
          // Show loading state with a placeholder
          if (announcementSnapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 30,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF69B4), Color(0xFFFF1B7C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Loading announcements...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Handle errors
          if (announcementSnapshot.hasError) {
            debugPrint('Announcement bar error: ${announcementSnapshot.error}');
            return const SizedBox.shrink();
          }

          final announcements = announcementSnapshot.data ?? [];

          // Get announcement text
          String announcementText;
          if (announcements.isEmpty) {
            debugPrint('No announcements found - showing placeholder');
            announcementText =
                'Welcome to Chamakz! Stay tuned for exciting updates and announcements • ';
          } else {
            // Get the first active announcement
            AnnouncementModel? activeAnnouncement;
            try {
              activeAnnouncement = announcements.firstWhere(
                (a) => a.isActive,
                orElse: () => announcements.first,
              );
            } catch (e) {
              debugPrint('Error getting announcement: $e');
              announcementText =
                  'Welcome to Chamakz! Stay tuned for exciting updates • ';
            }

            if (activeAnnouncement == null) {
              announcementText =
                  'Welcome to Chamakz! Stay tuned for exciting updates • ';
            } else {
              // Clean the text - remove any extra spaces, null characters, and ensure proper formatting
              final title = _sanitizeText(activeAnnouncement.title);
              final description = _sanitizeText(activeAnnouncement.description);
              announcementText = '$title • $description';
            }
          }

          return Container(
            height: 30,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF69B4), Color(0xFFFF1B7C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF69B4).withValues(alpha: 0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                // Scrolling Text
                Expanded(
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: _ScrollingText(
                      text: announcementText,
                      controller: _marqueeController,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========== LIVE CONTENT ==========
  Widget _buildLiveContent() {
    return const LiveReelsScreen();
  }

  // ========== EXPLORE CONTENT ==========
  Widget _buildExploreContent() {
    debugPrint('🚀 [EXPLORE] _buildExploreContent() called');
    final liveStreamService = LiveStreamService();

    // Combine two streams: All hosts + Live streams status
    return StreamBuilder<List<LiveStreamModel>>(
      stream: liveStreamService.getActiveLiveStreams(),
      builder: (context, liveStreamsSnapshot) {
        debugPrint('📡 [EXPLORE] Live streams snapshot state: ${liveStreamsSnapshot.connectionState}, hasData: ${liveStreamsSnapshot.hasData}, hasError: ${liveStreamsSnapshot.hasError}');
        // Get all hosts from users collection
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('isHost', isEqualTo: true)
              .limit(200) // Increased significantly to ensure all hosts are included
              .snapshots(),
          builder: (context, hostsSnapshot) {
            debugPrint('👥 [EXPLORE] Hosts snapshot state: ${hostsSnapshot.connectionState}, hasData: ${hostsSnapshot.hasData}, hasError: ${hostsSnapshot.hasError}');
            debugPrint('📡 [EXPLORE] Live streams snapshot state: ${liveStreamsSnapshot.connectionState}, hasData: ${liveStreamsSnapshot.hasData}, hasError: ${liveStreamsSnapshot.hasError}');
            
            // Loading state - wait only if hosts data not yet available
            if (hostsSnapshot.connectionState == ConnectionState.waiting &&
                !hostsSnapshot.hasData) {
              debugPrint('⏳ [EXPLORE] Waiting for hosts data...');
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF69B4),
                ),
              );
            }

            // Error state
            if (hostsSnapshot.hasError || liveStreamsSnapshot.hasError) {
              if (!mounted) return const SizedBox.shrink();
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

            // No hosts returned - try fallback to live streams list
            if (!hostsSnapshot.hasData || hostsSnapshot.data!.docs.isEmpty) {
              debugPrint('⚠️ [EXPLORE] No hosts data available from users collection');
              
              // Fallback: if we have live streams, show them directly
              if (liveStreamsSnapshot.hasData &&
                  liveStreamsSnapshot.data != null &&
                  liveStreamsSnapshot.data!.isNotEmpty) {
                final liveStreams = [...liveStreamsSnapshot.data!];
                // Shuffle streams randomly for fair distribution
                liveStreams.shuffle(Random());
                debugPrint('✅ [EXPLORE] Fallback: showing ${liveStreams.length} live streams without host docs');
                
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 3,
                    childAspectRatio: 0.70,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: liveStreams.length > 200 ? 200 : liveStreams.length,
                  itemBuilder: (context, index) {
                    final stream = liveStreams[index];
                    return GestureDetector(
                      onTap: () async {
                        if (!mounted) return;
                        
                        // Show enhanced loading screen BEFORE token generation
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierColor: Colors.transparent,
                          builder: (context) => EnhancedLoadingScreen(
                            hostPhotoUrl: stream.hostPhotoUrl,
                            hostName: stream.hostName,
                            message: 'Connecting to ${stream.hostName}...',
                          ),
                        );
                        
                        try {
                          final tokenService = AgoraTokenService();
                          final token = await tokenService.getAudienceToken(
                            channelName: stream.channelName,
                            uid: 0,
                          );

                          if (!mounted) return;

                          // Close loading dialog
                          Navigator.of(context).pop();

                          liveStreamService.joinStream(stream.streamId);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AgoraLiveStreamScreen(
                                channelName: stream.channelName,
                                token: token,
                                isHost: false,
                                streamId: stream.streamId,
                              ),
                            ),
                          ).then((_) {
                            liveStreamService.leaveStream(stream.streamId);
                          });
                        } catch (e) {
                          debugPrint('❌ Error joining stream (fallback): $e');
                          // Close loading dialog if still open
                          if (mounted) {
                            try {
                              Navigator.of(context).pop();
                            } catch (_) {}
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
                        streamId: stream.streamId,
                        hostId: stream.hostId,
                      ),
                    );
                  },
                );
              }

              if (!mounted) return const SizedBox.shrink();
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No hosts available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            debugPrint('✅ [EXPLORE] Hosts data ready - proceeding with host matching');
            debugPrint('   - Hosts count: ${hostsSnapshot.data!.docs.length}');
            debugPrint('   - Live streams hasData: ${liveStreamsSnapshot.hasData}');
            debugPrint('   - Live streams connectionState: ${liveStreamsSnapshot.connectionState}');
            if (liveStreamsSnapshot.hasData) {
              debugPrint('   - Live streams count: ${liveStreamsSnapshot.data!.length}');
            } else {
              debugPrint('   ⚠️ Live streams not ready yet - will show all hosts, live status will update when ready');
            }
            
            // Create a map of live streams by hostId for quick lookup
            // If live streams aren't ready yet, we'll just show all hosts without live indicators
            // The grid will update automatically when live streams data arrives
            final liveStreamsMap = <String, LiveStreamModel>{};
            final liveHostIds = <String>{};
            if (liveStreamsSnapshot.hasData) {
              debugPrint('📺 [EXPLORE] Found ${liveStreamsSnapshot.data!.length} active live streams');
              for (var stream in liveStreamsSnapshot.data!) {
                liveStreamsMap[stream.hostId] = stream;
                liveHostIds.add(stream.hostId);
                debugPrint('   ✅ Live: ${stream.hostName} (hostId: ${stream.hostId})');
              }
              debugPrint('🔍 [EXPLORE] Live hostIds: ${liveHostIds.toList()}');
            } else {
              debugPrint('📺 [EXPLORE] No live streams found');
            }

            // Get all hosts
            final hosts = hostsSnapshot.data!.docs;
            debugPrint('👥 [EXPLORE] Found ${hosts.length} total hosts');
            
            // Debug: Check if any host IDs match live stream hostIds
            debugPrint('🔍 [EXPLORE] Checking host ID matches...');
            for (var host in hosts) {
              if (liveHostIds.contains(host.id)) {
                final hostData = host.data() as Map<String, dynamic>?;
                final hostName = hostData?['displayName'] ?? 'Unknown';
                debugPrint('   ✅ MATCH FOUND: Host $hostName (ID: ${host.id}) matches live stream!');
              }
            }
            
            // Separate live hosts and non-live hosts
            final liveHosts = <DocumentSnapshot>[];
            final nonLiveHosts = <DocumentSnapshot>[];
            
            for (var host in hosts) {
              if (liveStreamsMap.containsKey(host.id)) {
                liveHosts.add(host);
                final hostData = host.data() as Map<String, dynamic>?;
                final hostName = hostData?['displayName'] ?? 'Unknown';
                debugPrint('   ✅ Host $hostName (ID: ${host.id}) is LIVE - will show in grid');
              } else {
                nonLiveHosts.add(host);
                // Debug: Log first few non-live host IDs for comparison
                if (nonLiveHosts.length <= 3) {
                  debugPrint('   ⚪ Non-live host ID: ${host.id} - HIDDEN from grid');
                }
              }
            }
            
            // Show ONLY live hosts (real-time availability)
            final sortedHosts = [...liveHosts];
            // Shuffle hosts randomly for fair distribution
            sortedHosts.shuffle(Random());
            debugPrint('📊 [EXPLORE] Showing ${liveHosts.length} live hosts only (${nonLiveHosts.length} offline hosts hidden)');
            
            // Show empty state if no hosts are live
            if (sortedHosts.isEmpty) {
              debugPrint('⚠️ [EXPLORE] No live hosts available');
              if (!mounted) return const SizedBox.shrink();
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tv_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No hosts are live right now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for live streams',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Debug: Check current user
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId != null) {
              debugPrint('🔍 [EXPLORE] Current user ID: $currentUserId');
              debugPrint('   - Is in live streams: ${liveStreamsMap.containsKey(currentUserId)}');
              debugPrint('   - Is in hosts list: ${hosts.any((h) => h.id == currentUserId)}');
              if (liveStreamsMap.containsKey(currentUserId)) {
                debugPrint('   ✅ CURRENT USER IS LIVE! Should appear in grid.');
              } else {
                debugPrint('   ⚠️ Current user is NOT in live streams map');
                debugPrint('   - Check if hostId in live_streams document matches user ID');
              }
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 3,
                childAspectRatio: 0.70,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: sortedHosts.length > 200 ? 200 : sortedHosts.length,
              itemBuilder: (context, index) {
                final hostDoc = sortedHosts[index];
                final hostData = hostDoc.data() as Map<String, dynamic>;
                final hostId = hostDoc.id;
                final hostName = hostData['displayName'] ?? 'Host';
                final hostPhotoUrl = hostData['photoURL'];

                // Check if this host is live
                final isLive = liveStreamsMap.containsKey(hostId);
                final liveStream = isLive ? liveStreamsMap[hostId] : null;
                
                // Debug: Log if this is the current user
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId == hostId) {
                  debugPrint('🔍 [EXPLORE] Current user found at index $index: $hostName');
                  debugPrint('   - isLive: $isLive');
                  debugPrint('   - liveStream: ${liveStream != null ? liveStream.streamId : "null"}');
                  if (isLive && liveStream != null) {
                    debugPrint('   ✅ Current user IS LIVE and should appear in grid!');
                  } else {
                    debugPrint('   ⚠️ Current user is NOT detected as live');
                    debugPrint('   - Check if liveStreams collection has entry with hostId: $hostId');
                    debugPrint('   - Check if isActive == true in liveStreams document');
                  }
                }

                return GestureDetector(
                  onTap: () async {
                    if (!mounted) return;
                    
                    if (isLive && liveStream != null) {
                      // Show enhanced loading screen BEFORE token generation
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.transparent,
                        builder: (context) => EnhancedLoadingScreen(
                          hostPhotoUrl: hostPhotoUrl,
                          hostName: hostName,
                          message: 'Connecting to $hostName...',
                        ),
                      );
                      
                      // Navigate to live stream
                      try {
                        final tokenService = AgoraTokenService();
                        final token = await tokenService.getAudienceToken(
                          channelName: liveStream.channelName,
                          uid: 0,
                        );

                        if (!mounted) return;

                        // Close loading dialog
                        Navigator.of(context).pop();

                        liveStreamService.joinStream(liveStream.streamId);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgoraLiveStreamScreen(
                              channelName: liveStream.channelName,
                              token: token,
                              isHost: false,
                              streamId: liveStream.streamId,
                            ),
                          ),
                        ).then((_) {
                          liveStreamService.leaveStream(liveStream.streamId);
                        });
                      } catch (e) {
                        debugPrint('❌ Error joining stream: $e');
                        // Close loading dialog if still open
                        if (mounted) {
                          try {
                            Navigator.of(context).pop();
                          } catch (_) {}
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to join stream: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    } else {
                      // Navigate to host profile - fetch user data first
                      try {
                        final userData = await DatabaseService().getUserData(hostId);
                        if (userData != null && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileViewScreen(
                                user: userData,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('❌ Error loading user profile: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to load profile'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: _buildLiveStreamCard(
                    hostName: hostName,
                    title: liveStream?.title ?? '',
                    viewers: liveStream?.viewerCount ?? 0,
                    thumbnail: Icons.live_tv,
                    isLive: isLive,
                    hostPhotoUrl: hostPhotoUrl,
                    streamId: liveStream?.streamId,
                    hostId: hostId,
                  ),
                );
              },
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
    // Logo placeholder widget (replaces pink gradient)
    Widget _buildLogoPlaceholder() {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Center(
          child: Opacity(
            opacity: 0.6, // 60% opacity for better visibility
            child: Image.asset(
              'assets/images/logopink.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: hostId != null
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(hostId)
                  .snapshots(),
              builder: (context, userSnapshot) {
                String? coverImageUrl;

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final coverURL = userData?['coverURL'] as String?;

                  // Get first cover image URL if available
                  if (coverURL != null && coverURL.isNotEmpty) {
                    final coverImages = coverURL
                        .split(',')
                        .where((url) => url.trim().isNotEmpty)
                        .toList();
                    if (coverImages.isNotEmpty) {
                      coverImageUrl = coverImages[0].trim();
                    }
                  }
                }

                // If cover image exists, show it, otherwise show logo
                return Stack(
                  children: [
                    // Background: Cover Image or Logo
                    if (coverImageUrl != null && coverImageUrl.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to logo if image fails to load
                            return _buildLogoPlaceholder();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            // Show logo while loading
                            return _buildLogoPlaceholder();
                          },
                        ),
                      )
                    else
                      _buildLogoPlaceholder(),

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
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
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

                            // Spacer to push username to bottom
                            const Spacer(),

                            // Host Name with Level Badge (Just above bottom elements with minimal spacing)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  // Level Badge
                                  if (userSnapshot.hasData && userSnapshot.data!.exists)
                                    Builder(
                                      builder: (context) {
                                        final userData = userSnapshot.data!.data()
                                            as Map<String, dynamic>?;
                                        final hostLevel = userData?['hostLevel'] ?? userData?['level'] ?? 1;
                                        
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF1B7C).withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(7),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            'Lv.$hostLevel',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              height: 1.1,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  if (userSnapshot.hasData && userSnapshot.data!.exists)
                                    const SizedBox(width: 5),
                                  // Host Name
                                  Expanded(
                                    child: Text(
                                      hostName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Language + Country + Video Icon (Bottom - Horizontal Row)
                            userSnapshot.hasData && userSnapshot.data!.exists
                                ? Builder(
                                    builder: (context) {
                                      final userData = userSnapshot.data!.data()
                                          as Map<String, dynamic>?;
                                      final language =
                                          userData?['language'] ?? 'English';
                                      final country = userData?['country'];
                                      
                                      // Get country flag emoji
                                      String? countryFlag;
                                      String? countryName;
                                      if (country != null && country.toString().isNotEmpty) {
                                        try {
                                          final countryStr = country.toString().trim().toUpperCase();
                                          // Try to parse as country code (e.g., "IN", "US")
                                          final countryObj = Country.parse(countryStr);
                                          countryFlag = countryObj.flagEmoji;
                                          countryName = countryObj.name;
                                        } catch (e) {
                                          // If parsing fails, use country as name
                                          countryName = country.toString();
                                          countryFlag = null;
                                        }
                                      }

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Language (left)
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              language,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                            ),
                                          ),
                                          // Country Flag + Name (center)
                                          Expanded(
                                            flex: 1,
                                            child: countryName != null && countryName.isNotEmpty
                                                ? Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      if (countryFlag != null) ...[
                                                        Text(
                                                          countryFlag,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                      ],
                                                      Flexible(
                                                        child: Text(
                                                          countryName,
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withValues(alpha: 0.9),
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                          // Video Icon in Pink Circle (right)
                                          Expanded(
                                            flex: 1,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: const BoxDecoration(
                                                  color: Color(
                                                      0xFFFF1B7C), // Pink color
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Image.asset(
                                                    'assets/images/video.png',
                                                    width: 16,
                                                    height: 16,
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.videocam_rounded,
                                                        color: Colors.white,
                                                        size: 16,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Fallback if no user data - Language
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'English',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 11,
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
                                      // Video Icon in Pink Circle (right)
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(
                                              color: Color(
                                                  0xFFFF1B7C), // Pink color
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Image.asset(
                                                'assets/images/video.png',
                                                width: 16,
                                                height: 16,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.videocam_rounded,
                                                    color: Colors.white,
                                                    size: 16,
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
                  // Default logo background when no hostId
                  _buildLogoPlaceholder(),

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
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
    );
  }

  // ========== FOLLOWING CONTENT ==========
  Widget _buildFollowingContent() {
    final liveStreamService = LiveStreamService();

    // Combine two streams: All hosts + Live streams status
    return StreamBuilder<List<LiveStreamModel>>(
      stream: liveStreamService.getActiveLiveStreams(),
      builder: (context, liveStreamsSnapshot) {
        // Get all hosts from users collection
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('isHost', isEqualTo: true)
              .limit(100) // Increased to ensure live hosts are included
              .snapshots(),
          builder: (context, hostsSnapshot) {
            // Loading state - wait only for hosts data
            if (hostsSnapshot.connectionState == ConnectionState.waiting &&
                !hostsSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF69B4),
                ),
              );
            }

            // Error state
            if (hostsSnapshot.hasError || liveStreamsSnapshot.hasError) {
              if (!mounted) return const SizedBox.shrink();
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

            // No hosts: fallback to live streams if available
            if (!hostsSnapshot.hasData || hostsSnapshot.data!.docs.isEmpty) {
              if (liveStreamsSnapshot.hasData &&
                  liveStreamsSnapshot.data != null &&
                  liveStreamsSnapshot.data!.isNotEmpty) {
                final liveStreams = [...liveStreamsSnapshot.data!];
                // Shuffle streams randomly for fair distribution
                liveStreams.shuffle(Random());
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 3,
                    childAspectRatio: 0.70,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: liveStreams.length > 100 ? 100 : liveStreams.length,
                  itemBuilder: (context, index) {
                    final stream = liveStreams[index];
                    return GestureDetector(
                      onTap: () async {
                        if (!mounted) return;
                        
                        // Show enhanced loading screen BEFORE token generation
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierColor: Colors.transparent,
                          builder: (context) => EnhancedLoadingScreen(
                            hostPhotoUrl: stream.hostPhotoUrl,
                            hostName: stream.hostName,
                            message: 'Connecting to ${stream.hostName}...',
                          ),
                        );
                        
                        try {
                          final tokenService = AgoraTokenService();
                          final token = await tokenService.getAudienceToken(
                            channelName: stream.channelName,
                            uid: 0,
                          );

                          if (!mounted) return;

                          // Close loading dialog
                          Navigator.of(context).pop();

                          liveStreamService.joinStream(stream.streamId);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AgoraLiveStreamScreen(
                                channelName: stream.channelName,
                                token: token,
                                isHost: false,
                                streamId: stream.streamId,
                              ),
                            ),
                          ).then((_) {
                            liveStreamService.leaveStream(stream.streamId);
                          });
                        } catch (e) {
                          debugPrint('❌ Error joining stream (fallback following): $e');
                          // Close loading dialog if still open
                          if (mounted) {
                            try {
                              Navigator.of(context).pop();
                            } catch (_) {}
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
                        streamId: stream.streamId,
                        hostId: stream.hostId,
                      ),
                    );
                  },
                );
              }

              if (!mounted) return const SizedBox.shrink();
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No hosts available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Create a map of live streams by hostId for quick lookup
            final liveStreamsMap = <String, LiveStreamModel>{};
            if (liveStreamsSnapshot.hasData) {
              for (var stream in liveStreamsSnapshot.data!) {
                liveStreamsMap[stream.hostId] = stream;
              }
            }

            // Get all hosts and filter to ONLY live hosts
            final hosts = hostsSnapshot.data!.docs;
            final liveHosts = hosts.where((host) => liveStreamsMap.containsKey(host.id)).toList();
            // Shuffle hosts randomly for fair distribution
            liveHosts.shuffle(Random());
            
            debugPrint('📊 [FOLLOWING] Showing ${liveHosts.length} live hosts only (${hosts.length - liveHosts.length} offline hosts hidden)');
            
            // Show empty state if no hosts are live
            if (liveHosts.isEmpty) {
              if (!mounted) return const SizedBox.shrink();
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tv_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No hosts are live right now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for live streams',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 3,
                childAspectRatio: 0.70,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: liveHosts.length > 50 ? 50 : liveHosts.length,
              itemBuilder: (context, index) {
                final hostDoc = liveHosts[index];
                final hostData = hostDoc.data() as Map<String, dynamic>;
                final hostId = hostDoc.id;
                final hostName = hostData['displayName'] ?? 'Host';
                final hostPhotoUrl = hostData['photoURL'];

                // Check if this host is live
                final isLive = liveStreamsMap.containsKey(hostId);
                final liveStream = isLive ? liveStreamsMap[hostId] : null;

                return GestureDetector(
                  onTap: () async {
                    if (!mounted) return;
                    
                    if (isLive && liveStream != null) {
                      // Show enhanced loading screen BEFORE token generation
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.transparent,
                        builder: (context) => EnhancedLoadingScreen(
                          hostPhotoUrl: hostPhotoUrl,
                          hostName: hostName,
                          message: 'Connecting to $hostName...',
                        ),
                      );
                      
                      // Navigate to live stream
                      try {
                        final tokenService = AgoraTokenService();
                        final token = await tokenService.getAudienceToken(
                          channelName: liveStream.channelName,
                          uid: 0,
                        );

                        if (!mounted) return;

                        // Close loading dialog
                        Navigator.of(context).pop();

                        liveStreamService.joinStream(liveStream.streamId);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgoraLiveStreamScreen(
                              channelName: liveStream.channelName,
                              token: token,
                              isHost: false,
                              streamId: liveStream.streamId,
                            ),
                          ),
                        ).then((_) {
                          liveStreamService.leaveStream(liveStream.streamId);
                        });
                      } catch (e) {
                        debugPrint('❌ Error joining stream: $e');
                        // Close loading dialog if still open
                        if (mounted) {
                          try {
                            Navigator.of(context).pop();
                          } catch (_) {}
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to join stream: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    } else {
                      // Navigate to host profile - fetch user data first
                      try {
                        final userData = await DatabaseService().getUserData(hostId);
                        if (userData != null && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileViewScreen(
                                user: userData,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('❌ Error loading user profile: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to load profile'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: _buildLiveStreamCard(
                    hostName: hostName,
                    title: liveStream?.title ?? '',
                    viewers: liveStream?.viewerCount ?? 0,
                    thumbnail: Icons.live_tv,
                    isLive: isLive,
                    hostPhotoUrl: hostPhotoUrl,
                    streamId: liveStream?.streamId,
                    hostId: hostId,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ========== NEW HOSTS CONTENT ==========
  Widget _buildNewHostsContent() {
    final liveStreamService = LiveStreamService();

    // Combine two streams: All hosts + Live streams status
    return StreamBuilder<List<LiveStreamModel>>(
      stream: liveStreamService.getActiveLiveStreams(),
      builder: (context, liveStreamsSnapshot) {
        // Get all hosts from users collection
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('isHost', isEqualTo: true)
              .limit(100) // Increased to ensure live hosts are included
              .snapshots(),
          builder: (context, hostsSnapshot) {
            // Loading state - wait only for hosts data
            if (hostsSnapshot.connectionState == ConnectionState.waiting &&
                !hostsSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF69B4),
                ),
              );
            }

            // Error state
            if (hostsSnapshot.hasError || liveStreamsSnapshot.hasError) {
              if (!mounted) return const SizedBox.shrink();
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

            // No hosts: fallback to live streams if available
            if (!hostsSnapshot.hasData || hostsSnapshot.data!.docs.isEmpty) {
              if (liveStreamsSnapshot.hasData &&
                  liveStreamsSnapshot.data != null &&
                  liveStreamsSnapshot.data!.isNotEmpty) {
                final liveStreams = [...liveStreamsSnapshot.data!];
                // Shuffle streams randomly for fair distribution
                liveStreams.shuffle(Random());
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 3,
                    childAspectRatio: 0.70,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: liveStreams.length > 100 ? 100 : liveStreams.length,
                  itemBuilder: (context, index) {
                    final stream = liveStreams[index];
                    return GestureDetector(
                      onTap: () async {
                        if (!mounted) return;
                        
                        // Show enhanced loading screen BEFORE token generation
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierColor: Colors.transparent,
                          builder: (context) => EnhancedLoadingScreen(
                            hostPhotoUrl: stream.hostPhotoUrl,
                            hostName: stream.hostName,
                            message: 'Connecting to ${stream.hostName}...',
                          ),
                        );
                        
                        try {
                          final tokenService = AgoraTokenService();
                          final token = await tokenService.getAudienceToken(
                            channelName: stream.channelName,
                            uid: 0,
                          );

                          if (!mounted) return;

                          // Close loading dialog
                          Navigator.of(context).pop();

                          liveStreamService.joinStream(stream.streamId);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AgoraLiveStreamScreen(
                                channelName: stream.channelName,
                                token: token,
                                isHost: false,
                                streamId: stream.streamId,
                              ),
                            ),
                          ).then((_) {
                            liveStreamService.leaveStream(stream.streamId);
                          });
                        } catch (e) {
                          debugPrint('❌ Error joining stream (fallback new): $e');
                          // Close loading dialog if still open
                          if (mounted) {
                            try {
                              Navigator.of(context).pop();
                            } catch (_) {}
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
                        streamId: stream.streamId,
                        hostId: stream.hostId,
                      ),
                    );
                  },
                );
              }

              if (!mounted) return const SizedBox.shrink();
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No hosts available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Create a map of live streams by hostId for quick lookup
            final liveStreamsMap = <String, LiveStreamModel>{};
            if (liveStreamsSnapshot.hasData) {
              for (var stream in liveStreamsSnapshot.data!) {
                liveStreamsMap[stream.hostId] = stream;
              }
            }

            // Get all hosts and filter to ONLY live hosts
            final hosts = hostsSnapshot.data!.docs;
            final liveHosts = hosts.where((host) => liveStreamsMap.containsKey(host.id)).toList();
            // Shuffle hosts randomly for fair distribution
            liveHosts.shuffle(Random());
            
            debugPrint('📊 [NEW HOSTS] Showing ${liveHosts.length} live hosts only (${hosts.length - liveHosts.length} offline hosts hidden)');
            
            // Show empty state if no hosts are live
            if (liveHosts.isEmpty) {
              if (!mounted) return const SizedBox.shrink();
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tv_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No hosts are live right now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for live streams',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 3,
                childAspectRatio: 0.70,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: liveHosts.length > 50 ? 50 : liveHosts.length,
              itemBuilder: (context, index) {
                final hostDoc = liveHosts[index];
                final hostData = hostDoc.data() as Map<String, dynamic>;
                final hostId = hostDoc.id;
                final hostName = hostData['displayName'] ?? 'Host';
                final hostPhotoUrl = hostData['photoURL'];

                // Check if this host is live
                final isLive = liveStreamsMap.containsKey(hostId);
                final liveStream = isLive ? liveStreamsMap[hostId] : null;

                return GestureDetector(
                  onTap: () async {
                    if (!mounted) return;
                    
                    if (isLive && liveStream != null) {
                      // Show enhanced loading screen BEFORE token generation
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.transparent,
                        builder: (context) => EnhancedLoadingScreen(
                          hostPhotoUrl: hostPhotoUrl,
                          hostName: hostName,
                          message: 'Connecting to $hostName...',
                        ),
                      );
                      
                      // Navigate to live stream
                      try {
                        final tokenService = AgoraTokenService();
                        final token = await tokenService.getAudienceToken(
                          channelName: liveStream.channelName,
                          uid: 0,
                        );

                        if (!mounted) return;

                        // Close loading dialog
                        Navigator.of(context).pop();

                        liveStreamService.joinStream(liveStream.streamId);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgoraLiveStreamScreen(
                              channelName: liveStream.channelName,
                              token: token,
                              isHost: false,
                              streamId: liveStream.streamId,
                            ),
                          ),
                        ).then((_) {
                          liveStreamService.leaveStream(liveStream.streamId);
                        });
                      } catch (e) {
                        debugPrint('❌ Error joining stream: $e');
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
                    } else {
                      // Navigate to host profile - fetch user data first
                      try {
                        final userData = await DatabaseService().getUserData(hostId);
                        if (userData != null && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileViewScreen(
                                user: userData,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('❌ Error loading user profile: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to load profile'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: _buildLiveStreamCard(
                    hostName: hostName,
                    title: liveStream?.title ?? '',
                    viewers: liveStream?.viewerCount ?? 0,
                    thumbnail: Icons.live_tv,
                    isLive: isLive,
                    hostPhotoUrl: hostPhotoUrl,
                    streamId: liveStream?.streamId,
                    hostId: hostId,
                  ),
                );
              },
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
                      color: const Color(0xFF8E24AA).withValues(alpha: 0.45),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HostRulesScreen(
                      onGoLive: _startLiveStream,
                    ),
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
                shadowColor: const Color(0xFF8E24AA).withValues(alpha: 0.4),
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

  // ========== NEARBY CONTENT ==========
  Widget _buildNearbyContent() {
    return const NearbyUsersScreen();
  }

  // ========== START LIVE STREAM ==========
  Future<void> _startLiveStream() async {
    if (!mounted) return;

    // Step 1: Check authentication
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.pleaseLoginToStartLiveStream),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Step 1.5: Check if account is approved for live streaming
    try {
      final userData = await _databaseService.getUserData(currentUser.uid);
      if (userData == null || !userData.isActive) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: const Text(
                      'Account Not Approved',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your account requires approval before you can access host rules and guidelines and start live streaming.',
                          textAlign: TextAlign.start,
                          softWrap: true,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please contact admin to get your account approved.',
                          textAlign: TextAlign.start,
                          softWrap: true,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(const ClipboardData(text: 'info@chamakz.app'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email address copied to clipboard'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.black87,
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: const Color(0xFFFF69B4),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0xFF9C27B0), // Purple
                                      Color(0xFFE91E63), // Pink
                                    ],
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'info@chamakz.app',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white, // This color will be masked by the gradient
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.copy,
                                color: const Color(0xFFFF69B4),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Button Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF69B4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.all(const Color(0xFFFF69B4)),
                          overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF69B4).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Understood',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return; // Don't start stream
      }
    } catch (e) {
      debugPrint('❌ Error checking account approval: $e');
      // Continue if check fails (don't block user if error occurs)
    }

    // Step 2: Check for existing active stream and auto-end if found
    final liveStreamService = LiveStreamService();
    LiveStreamModel? existingStream;
    try {
      existingStream = await liveStreamService
          .getHostActiveStream(currentUser.uid)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('⚠️ Error checking existing stream (continuing anyway): $e');
      // Continue even if check fails
    }

    // Auto-end previous stream if exists (no popup - direct action)
    if (existingStream != null) {
      try {
        // Automatically end the existing stream (fire and forget - don't wait)
        liveStreamService
            .endLiveStream(existingStream.streamId)
            .timeout(const Duration(seconds: 5))
            .catchError(
                (e) => debugPrint('⚠️ Error ending previous stream: $e'));
        debugPrint('✅ Previous stream auto-ending in background...');
      } catch (e) {
        debugPrint('⚠️ Error ending previous stream (continuing anyway): $e');
        // Continue even if ending fails - don't block user
      }
    }

    // Step 3: Show loading dialog BEFORE permissions
    if (!mounted) return;
    bool isLoadingDialogShown = false;
    NavigatorState? navigator;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFFFF69B4),
              ),
              const SizedBox(height: 20),
              const Text(
                'Starting live stream...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
      isLoadingDialogShown = true;
      navigator = Navigator.of(context);
    } catch (e) {
      debugPrint('Error showing dialog: $e');
      return;
    }

    try {
      // Step 4: Request permissions (parallel)
      if (!mounted) return;
      final permissions = await Future.wait([
        Permission.camera.request(),
        Permission.microphone.request(),
      ]);
      final cameraStatus = permissions[0];
      final micStatus = permissions[1];

      if (cameraStatus.isDenied || micStatus.isDenied) {
        if (isLoadingDialogShown) navigator.pop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Camera and microphone permissions are required to start a live stream.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
        if (isLoadingDialogShown) navigator.pop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Please enable camera and microphone permissions in app settings.'),
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

      // Step 5: Get user data and generate stream ID in parallel
      if (!mounted) return;

      // Generate stream ID immediately (no network needed)
      final streamId =
          FirebaseFirestore.instance.collection('live_streams').doc().id;
      final channelName = streamId;

      // Get user data with longer timeout and fallback
      dynamic userData;
      try {
        userData = await _databaseService
            .getUserData(currentUser.uid)
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('⚠️ Error getting user data (using fallback): $e');
        userData = null; // Use fallback values
      }

      final hostName = userData?.name ??
          currentUser.displayName ??
          currentUser.phoneNumber ??
          'Host';
      final hostPhotoUrl = userData?.photoURL;

      // Step 6: Generate token (most time-consuming step)
      if (!mounted) return;
      final tokenService = AgoraTokenService();
      String token;
      try {
        token = await tokenService
            .getHostToken(
              channelName: channelName,
              uid: 0,
            )
            .timeout(const Duration(
                seconds: 15)); // Increased timeout for token generation
        debugPrint('✅ Generated host token: ${token.length} chars');
      } catch (e) {
        if (isLoadingDialogShown) {
          try {
            navigator.pop();
          } catch (_) {}
        }
        debugPrint('❌ Error generating token: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to generate token. Please check your internet connection and try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Step 7: Create stream in Firebase
      if (!mounted) return;
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

      // Create stream with longer timeout and better error handling
      try {
        await liveStreamService
            .createStream(stream)
            .timeout(const Duration(seconds: 10));
        debugPrint('✅ Live stream created: $streamId');
      } catch (e) {
        debugPrint('⚠️ Error creating stream (but continuing): $e');
        // Continue anyway - stream might still work
      }

      // Close loading dialog
      if (isLoadingDialogShown) {
        navigator.pop();
        isLoadingDialogShown = false;
      }

      if (!mounted) return;

      // Step 8: Navigate to live stream screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AgoraLiveStreamScreen(
            channelName: channelName,
            token: token,
            isHost: true,
            streamId: streamId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error starting live stream: $e');

      // Close loading dialog
      if (isLoadingDialogShown) {
        try {
          navigator.pop();
        } catch (e) {
          try {
            Navigator.of(context, rootNavigator: true).pop();
          } catch (e2) {
            debugPrint('Error closing dialog: $e2');
          }
        }
      }

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
        // Handle (+) button click (index 2) - navigate to host rules screen
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HostRulesScreen(
                onGoLive: _startLiveStream,
              ),
            ),
          );
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
                    color: Colors.grey.withValues(alpha: 0.2), // Gray shadow
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
                    color: Colors.red.withValues(alpha: 0.5),
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
