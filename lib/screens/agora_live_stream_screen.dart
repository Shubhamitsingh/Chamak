import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../services/live_stream_service.dart';
import '../models/live_stream_model.dart';
import '../widgets/bouncy_icon_button.dart';
import '../widgets/gift_selection_sheet.dart';
import '../models/gift_model.dart';
import '../services/live_chat_service.dart';
import '../services/live_stream_chat_service.dart';
import '../services/database_service.dart';
import '../services/follow_service.dart';
import '../models/user_model.dart';
import '../services/call_request_service.dart';
import '../models/call_request_model.dart';
import '../widgets/call_request_dialog.dart';
import '../widgets/call_status_overlay.dart';
import '../widgets/viewer_list_sheet.dart';
import '../services/agora_token_service.dart';
import '../services/call_coin_deduction_service.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../models/live_stream_chat_message.dart';
import 'user_profile_view_screen.dart';
import 'private_call_screen.dart';
import 'messages_screen.dart';
import 'chat_screen.dart';
import '../widgets/low_coin_popup.dart';

// Agora App ID
const String appId = '43bb5e13c835444595c8cf087a0ccaa4';

class AgoraLiveStreamScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final bool isHost;
  final String? streamId; // Stream ID for cleanup when host ends stream

  const AgoraLiveStreamScreen({
    super.key,
    required this.channelName,
    required this.token,
    this.isHost = true,
    this.streamId,
  });

  @override
  State<AgoraLiveStreamScreen> createState() => _AgoraLiveStreamScreenState();
}

class _AgoraLiveStreamScreenState extends State<AgoraLiveStreamScreen> with TickerProviderStateMixin {
  // Agora RTC Engine instance
  late RtcEngine _engine;

  // State variables for tracking users
  bool _localUserJoined = false;
  bool _localPreviewReady = false;
  int? _remoteUid;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFrontCamera = true; // Track camera position (true = front, false = back)
  bool _isMuted = false; // Track host mic mute status
  bool _isViewerMuted = false; // Track viewer-side sound mute (host voice)
  bool _hostIsOffline = false; // Track if host has gone offline
  bool _isViewsSwapped = false; // Track if host and user views are swapped
  DateTime? _joinTime; // Track when viewer joined to avoid false offline detection
  
  bool _isFollowingHost = false; // Track if viewer is following the host
  bool _isFollowLoading = false; // Track follow/unfollow loading state
  bool _hasCheckedFollowStatus = false; // Track if follow status has been checked
  
  // Call request state
  String? _currentCallRequestId; // Current call request ID (for viewer)
  bool _isCallRequestPending = false; // Track if call request is pending
  bool _isHostInCall = false; // Track if host is in a private call
  bool _isCallRejected = false; // Track if call was rejected by host
  late AnimationController _heartAnimationController; // Animation controller for heart icon
  StreamSubscription? _callRequestStatusSubscription; // Subscription for call request status
  StreamSubscription? _hostStatusSubscription; // Subscription for host status
  StreamSubscription? _incomingCallRequestSubscription; // Subscription for incoming call requests (host)
  bool _isCallDialogShowing = false; // Track if call dialog is currently showing (prevent duplicates)
  
  // Services
  final FollowService _followService = FollowService();
  final CallRequestService _callRequestService = CallRequestService();
  final LiveStreamService _liveStreamService = LiveStreamService();
  final CallCoinDeductionService _coinDeductionService = CallCoinDeductionService();
  final ChatService _chatService = ChatService();
  
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Coin balance state (for viewers)
  int _userBalance = 0;
  bool _isLoadingBalance = false;
  StreamSubscription<DocumentSnapshot>? _balanceSubscription; // Real-time balance listener
  
  // Promotional overlay state
  bool _showPromoOverlay = true;
  Duration _promoDuration = const Duration(hours: 10); // 10 hours countdown
  Timer? _promoTimer;
  final ValueNotifier<Duration> _promoDurationNotifier = ValueNotifier<Duration>(const Duration(hours: 10));
  
  // Admin message popup state
  String? _currentAdminMessage;
  bool _adminMessageShown = false;
  Timer? _adminMessageTimer;
  StreamSubscription<QuerySnapshot>? _viewersSubscription; // Listen for new viewers
  
  // Chat state
  bool _isChatOpen = false;
  final TextEditingController _chatMessageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _chatFocusNode = FocusNode();
  final LiveStreamChatService _liveStreamChatService = LiveStreamChatService();
  double _previousKeyboardHeight = 0.0; // Track keyboard height to detect dismissal
  

  @override
  void initState() {
    super.initState();
    // Set pink status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFF1B7C), // Pink color
        statusBarIconBrightness: Brightness.light, // Light icons for dark background
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Start promotional timer
    _startPromoTimer();
    
    // Setup admin message listener for new viewers
    if (!widget.isHost && widget.streamId != null) {
      _setupAdminMessageListener();
    }
    
    _initializeAgora();
    // Initialize heart animation controller
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    // Load user balance if viewer and setup real-time listener
    if (!widget.isHost) {
      _loadUserBalance();
      _setupRealtimeBalanceListener();
    }
    
    // Setup call request listeners
    // Add a small delay to ensure widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.isHost) {
          debugPrint('📞 Setting up call listener for HOST');
          _setupIncomingCallRequestListener();
        } else {
          debugPrint('📞 Setting up host status listener for VIEWER');
          _setupHostStatusListener();
        }
      }
    });
    
    // Listen for keyboard dismissal to close chat (backup method)
    _chatFocusNode.addListener(() {
      if (!_chatFocusNode.hasFocus && _isChatOpen) {
        // Keyboard dismissed, close chat after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_chatFocusNode.hasFocus && _isChatOpen) {
            setState(() {
              _isChatOpen = false;
            });
          }
        });
      }
    });
  }

  // Start promotional timer
  void _startPromoTimer() {
    _promoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_promoDuration.inSeconds > 0) {
        _promoDuration = Duration(seconds: _promoDuration.inSeconds - 1);
        _promoDurationNotifier.value = _promoDuration;
      } else {
        timer.cancel();
      }
    });
  }
  
  // Setup admin message listener for new viewers
  void _setupAdminMessageListener() {
    // Show admin message when user first visits the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.isHost) {
        // Get current user name
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get()
              .then((userDoc) {
            if (userDoc.exists && mounted) {
              final userData = userDoc.data();
              final userName = userData?['name'] as String? ?? 
                             userData?['displayName'] as String? ?? 
                             currentUser.displayName ?? 
                             'Someone';
              
              // Show admin message popup
              _showAdminMessagePopup('$userName has joined');
            }
          });
        }
      }
    });
    
    // Also listen for new viewers joining
    _viewersSubscription = FirebaseFirestore.instance
        .collection('live_streams')
        .doc(widget.streamId!)
        .collection('viewers')
        .orderBy('joinedAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        final viewerData = snapshot.docs.first.data();
        final viewerId = viewerData['viewerId'] as String?;
        final joinedAt = viewerData['joinedAt'] as Timestamp?;
        final currentUserId = _auth.currentUser?.uid;
        
        // Don't show for current user (already shown on page load)
        if (viewerId != null && joinedAt != null && viewerId != currentUserId) {
          // Check if this is a new join (within last 5 seconds)
          final joinTime = joinedAt.toDate();
          final now = DateTime.now();
          if (now.difference(joinTime).inSeconds < 5) {
                // Get viewer name and VIP status
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(viewerId)
                    .get()
                    .then((userDoc) {
              if (userDoc.exists && mounted) {
                final userData = userDoc.data();
                final viewerName = userData?['name'] as String? ?? 
                                 userData?['displayName'] as String? ?? 
                                 'Someone';
                final vipLevel = userData?['vipLevel'] as String?; // BRONZE, SILVER, GOLD, etc.
                
                // Show admin message popup with VIP status if available
                String message = '$viewerName has joined';
                if (vipLevel != null && vipLevel.isNotEmpty) {
                  message = '$viewerName $vipLevel VIP has joined';
                }
                _showAdminMessagePopup(message);
              }
            });
          }
        }
      }
    });
  }
  
  // Show admin message popup
  void _showAdminMessagePopup(String message) {
    // Reset flag to allow showing again
    _adminMessageShown = false;
    
    setState(() {
      _currentAdminMessage = message;
      _adminMessageShown = true;
    });
    
    // Auto-close after 3 seconds
    _adminMessageTimer?.cancel();
    _adminMessageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentAdminMessage = null;
          _adminMessageShown = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Reset status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    _heartAnimationController.dispose();
    
    // Cancel promotional timer
    _promoTimer?.cancel();
    _promoDurationNotifier.dispose();
    
    // Cancel admin message timer and subscription
    _adminMessageTimer?.cancel();
    _viewersSubscription?.cancel();
    
    _callRequestStatusSubscription?.cancel();
    _hostStatusSubscription?.cancel();
    _incomingCallRequestSubscription?.cancel();
    
    // Dispose chat controllers
    _chatMessageController.dispose();
    _chatScrollController.dispose();
    _chatFocusNode.dispose();
    
    _cleanupAgoraEngine();
    super.dispose();
  }

  // Set up the Agora RTC engine instance
  Future<void> _initializeAgoraVideoSDK() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    
    // Enable video immediately for host
    if (widget.isHost) {
      await _engine.enableVideo();
      debugPrint('✅ Video enabled during initialization');
    }
  }

  // Get user-friendly error message from Agora error code
  String _getErrorMessage(ErrorCodeType errorCode, String message) {
    // Map error codes to user-friendly messages
    final errorCodeStr = errorCode.toString();
    String userMessage = message;
    
    // Check common error codes by string matching
    // Note: Error codes 109 (token expired) and 110 (invalid token) are deprecated
    // Use onConnectionStateChanged with ConnectionChangedReasonType instead
    if (errorCodeStr.contains('errJoinChannelRejected') || errorCodeStr.contains('17')) {
      userMessage = 'Cannot join channel - already in a channel.\n\n'
          'This usually happens when:\n'
          '- You tried to join multiple times\n'
          '- Previous session did not close properly\n\n'
          'Try closing and reopening the app, or wait a few seconds and retry.';
    } else if (errorCodeStr.contains('errInvalidToken') || errorCodeStr.contains('110')) {
      // Deprecated: This error is now handled in onConnectionStateChanged
      userMessage = 'Invalid token.\n\n'
          'Possible causes:\n'
          '1. App Certificate is enabled but token is not provided\n'
          '2. Token was generated for different channel name\n'
          '3. Token was generated with different UID\n\n'
          'Solution:\n'
          '1. Go to Agora Console > Your Project\n'
          '2. Check App Certificate status\n'
          '3. Generate new token for channel: "${widget.channelName}" and UID: 0';
    } else if (errorCodeStr.contains('errTokenExpired') || errorCodeStr.contains('109')) {
      // Deprecated: This error is now handled in onConnectionStateChanged
      userMessage = 'Token expired.\n\n'
          'Temporary tokens expire quickly.\n'
          'Generate a new token from Agora Console.';
    } else if (errorCodeStr.contains('errTokenExpired') || errorCodeStr.contains('109')) {
      userMessage = 'Token expired. Please generate a new token.';
    } else if (errorCodeStr.contains('errInvalidAppId') || errorCodeStr.contains('101')) {
      userMessage = 'Invalid App ID. Please check your configuration.';
    } else if (errorCodeStr.contains('errInvalidChannelName') || errorCodeStr.contains('102')) {
      userMessage = 'Invalid channel name. Please use a valid channel name.';
    } else if (errorCodeStr.contains('errNoPermission') || errorCodeStr.contains('9')) {
      userMessage = 'Permission denied. Please grant camera and microphone permissions.';
    } else if (errorCodeStr.contains('errNotReady') || errorCodeStr.contains('3')) {
      userMessage = 'SDK not ready. Please wait and try again.';
    } else if (errorCodeStr.contains('errNotInitialized') || errorCodeStr.contains('7')) {
      userMessage = 'SDK not initialized. Please restart the app.';
    } else if (errorCodeStr.contains('errJoinChannelRejected') || errorCodeStr.contains('17')) {
      userMessage = 'Already in channel. Please wait or restart.';
    } else if (errorCodeStr.contains('errNetwork') || errorCodeStr.contains('111') || errorCodeStr.contains('112')) {
      userMessage = 'Network connection issue. Please check your internet connection.';
    } else if (errorCodeStr.contains('errTimeout') || errorCodeStr.contains('10')) {
      userMessage = 'Request timed out. Please check your network connection.';
    } else {
      // Use original message if we can't map it
      userMessage = 'Error: $message';
    }
    
    return userMessage;
  }

  // Register an event handler for Agora RTC
  void _setupEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("✅ Local user ${connection.localUid} joined channel: ${connection.channelId}");
          if (mounted) {
            setState(() {
              _localUserJoined = true;
              _errorMessage = null; // Clear any previous errors
            });
          }
          
          // If viewer joins, increment viewer count in Firebase
          if (!widget.isHost && widget.streamId != null) {
            final liveStreamService = LiveStreamService();
            final currentUser = _auth.currentUser;
            // Use UID as primary identifier (more reliable than phoneNumber)
            // Phone number might not be available or might be in different format
            final viewerId = currentUser?.uid;
            debugPrint('👥 Viewer joining stream: ${widget.streamId}');
            debugPrint('   Current user UID: ${currentUser?.uid}');
            debugPrint('   Phone number: ${currentUser?.phoneNumber}');
            debugPrint('   ViewerId to use: $viewerId');
            if (viewerId == null || viewerId.isEmpty) {
              debugPrint('❌ Error: viewerId is null or empty! Cannot track viewer.');
            } else {
              liveStreamService.joinStream(widget.streamId!, viewerId: viewerId);
              debugPrint('👥 Viewer joined - incrementing viewer count and adding to list');
            }
            // Track join time to avoid false offline detection
            _joinTime = DateTime.now();
          }
          
          // Chat panel will be shown automatically when host joins (no delay needed)
        },
        onError: (ErrorCodeType err, String msg) {
          final errorMsg = _getErrorMessage(err, msg);
          debugPrint('❌ Agora Error: $err');
          debugPrint('   Error message: $msg');
          debugPrint('   User-friendly: $errorMsg');
          if (mounted) {
            setState(() {
              _errorMessage = errorMsg;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $errorMsg'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    _initializeAgora();
                  },
                ),
              ),
            );
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("✅ Remote user $remoteUid joined channel: ${connection.channelId}");
          // Only track remote users for viewers, NOT for hosts
          // Hosts should only see their own video, not other users' videos
          if (mounted && !widget.isHost) {
            setState(() => _remoteUid = remoteUid);
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("👋 Remote user $remoteUid left channel. Reason: $reason");
          // Only clear remote UID for viewers, NOT for hosts
          if (mounted && !widget.isHost) {
            setState(() => _remoteUid = null);
          }
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          debugPrint('🔗 Connection state changed: $state (Reason: $reason)');
          
          // Handle token errors (new way - replaces deprecated error codes 109, 110)
          if (reason == ConnectionChangedReasonType.connectionChangedInvalidToken) {
            final errorMsg = 'Invalid token.\n\n'
                'Possible causes:\n'
                '1. App Certificate is enabled but token is not provided\n'
                '2. Token was generated for different channel name\n'
                '3. Token was generated with different UID\n'
                '4. Token format is incorrect\n\n'
                'Solution:\n'
                '1. Go to Agora Console > Your Project\n'
                '2. Check App Certificate status\n'
                '3. Generate new token for channel: "${widget.channelName}" and UID: 0\n'
                '4. Update token in home_screen.dart';
            
            debugPrint('❌ Token Error (ConnectionChangedInvalidToken): $errorMsg');
            if (mounted) {
              setState(() {
                _errorMessage = errorMsg;
                _isLoading = false;
              });
            }
          } else if (reason == ConnectionChangedReasonType.connectionChangedTokenExpired) {
            final errorMsg = 'Token expired.\n\n'
                'Temporary tokens expire quickly.\n'
                'Generate a new token from Agora Console.';
            
            debugPrint('❌ Token Expired (ConnectionChangedTokenExpired): $errorMsg');
            if (mounted) {
              setState(() {
                _errorMessage = errorMsg;
                _isLoading = false;
              });
            }
          } else if (state == ConnectionStateType.connectionStateDisconnected) {
            debugPrint('⚠️ Disconnected from channel');
            if (mounted) {
              setState(() {
                _localUserJoined = false;
                _remoteUid = null;
              });
            }
          } else if (state == ConnectionStateType.connectionStateConnected) {
            debugPrint('✅ Connected to channel');
            if (mounted) {
              setState(() {
                _localUserJoined = true;
                _errorMessage = null; // Clear any previous errors
              });
            }
          } else if (state == ConnectionStateType.connectionStateReconnecting) {
            debugPrint('🔄 Reconnecting to channel...');
          } else if (state == ConnectionStateType.connectionStateFailed) {
            debugPrint('❌ Connection failed. Reason: $reason');
            String? errorMsg;
            
            // Map connection failure reasons to user-friendly messages
            switch (reason) {
              case ConnectionChangedReasonType.connectionChangedInvalidToken:
                errorMsg = 'Invalid token. Please check your token configuration.';
                break;
              case ConnectionChangedReasonType.connectionChangedTokenExpired:
                errorMsg = 'Token expired. Please generate a new token.';
                break;
              case ConnectionChangedReasonType.connectionChangedRejectedByServer:
                errorMsg = 'Connection rejected by server. Please check your App ID and configuration.';
                break;
              default:
                errorMsg = 'Connection failed. Reason: $reason';
            }
            
            if (mounted) {
              setState(() {
                _errorMessage = errorMsg;
                _isLoading = false;
              });
            }
          }
        },
      ),
    );
  }

  // Join a channel
  Future<void> _joinChannel() async {
    // Use provided token directly (App Certificate is enabled, token is required)
    String tokenToUse = widget.token;
    
    // Validate token is provided
    if (tokenToUse.isEmpty) {
      debugPrint('❌ ERROR: Token is empty but required (App Certificate is enabled)');
      debugPrint('   widget.token value: "${widget.token}"');
      debugPrint('   widget.token.isEmpty: ${widget.token.isEmpty}');
      throw Exception('Token is required but not provided. Please generate a token first.');
    }
    
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔑 JOIN CHANNEL DETAILS:');
    debugPrint('   Channel Name: ${widget.channelName}');
    debugPrint('   Token: ${tokenToUse.isEmpty ? "EMPTY (ERROR!)" : "PROVIDED (${tokenToUse.length} chars)"}');
    debugPrint('   Token preview: ${tokenToUse.isEmpty ? "N/A" : tokenToUse.substring(0, 20)}...');
    debugPrint('   UID: 0');
    debugPrint('   App ID: $appId');
    debugPrint('═══════════════════════════════════════');
    
    try {
      // Check if already in a channel and leave first (fixes error -17)
      try {
        await _engine.leaveChannel();
        debugPrint('🔄 Left any existing channel before joining new one');
        // Wait a bit for the leave to complete
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // Ignore errors if not in a channel
        debugPrint('ℹ️ Not in a channel (or already left): $e');
      }
      
      await _engine.joinChannel(
        token: tokenToUse,
        channelId: widget.channelName,
        options: ChannelMediaOptions(
          autoSubscribeVideo: true, // Automatically subscribe to all video streams
          autoSubscribeAudio: true, // Automatically subscribe to all audio streams
          publishCameraTrack: widget.isHost, // Only publish if host
          publishMicrophoneTrack: widget.isHost, // Only publish if host
          // Use clientRoleBroadcaster for host, clientRoleAudience for viewers
          clientRoleType: widget.isHost 
              ? ClientRoleType.clientRoleBroadcaster 
              : ClientRoleType.clientRoleAudience,
          // Set the audience latency level
          audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelUltraLowLatency,
        ),
        uid: 0,
      );
      debugPrint('✅ Join channel request sent successfully');
    } catch (e) {
      debugPrint('❌ Error joining channel: $e');
      // Re-throw to be handled by error handler
      rethrow;
    }
  }

  // Display the local video
  Future<void> _setupLocalVideo() async {
    // Only setup local video if host (viewers don't need local preview)
    if (!widget.isHost) {
      debugPrint('👁️ Viewer mode - skipping local video setup');
      return;
    }
    
    debugPrint('📹 Setting up camera for host...');
    
    // Enable video module first
    await _engine.enableVideo();
    debugPrint('✅ Video module enabled');
    
    // Start preview first (this initializes the camera)
    await _engine.startPreview();
    debugPrint('✅ Camera preview started');
    
    // Then setup the video canvas
    await _engine.setupLocalVideo(
      const VideoCanvas(
        uid: 0,
        renderMode: RenderModeType.renderModeFit,
      ),
    );
    debugPrint('✅ Local video canvas setup complete');
    
    // Give a small delay for camera to initialize
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      setState(() => _localPreviewReady = true);
    }
    debugPrint('✅ Local video preview ready - camera should be visible now');
  }

  // Handle permissions
  Future<void> _requestPermissions() async {
    // Only request permissions if host (viewers don't need camera/mic)
    if (widget.isHost) {
      await [Permission.microphone, Permission.camera].request();
    } else {
      debugPrint('👁️ Viewer mode - skipping permissions');
    }
  }

  // Start Interactive Live Streaming
  Future<void> _initializeAgora() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('🎬 Starting Agora live stream initialization...');
      debugPrint('📺 Channel: ${widget.channelName}');
      
      // Request permissions first (for host)
      if (widget.isHost) {
        debugPrint('🔐 Requesting permissions...');
        await _requestPermissions();
      }
      
      // Initialize SDK
      debugPrint('⚙️ Initializing Agora SDK...');
      await _initializeAgoraVideoSDK();
      
      // Setup event handlers (before joining channel)
      debugPrint('📡 Setting up event handlers...');
      _setupEventHandlers();
      
      // For host: Setup local video preview FIRST (camera opens immediately)
      if (widget.isHost) {
        debugPrint('📹 Setting up local video preview (camera)...');
        await _setupLocalVideo();
        // Camera should now be visible
        if (mounted) {
          setState(() => _isLoading = false); // Stop loading so camera shows
        }
      }
      
      // Join channel
      debugPrint('🚪 Joining channel...');
      await _joinChannel();
      
      debugPrint('✅ Agora initialization complete!');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing Agora: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting live stream: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Leaves the channel and releases resources
  Future<void> _cleanupAgoraEngine() async {
    try {
      debugPrint('🧹 Starting cleanup process...');
      
      // If viewer leaves, decrement viewer count in Firebase BEFORE leaving channel
      if (!widget.isHost && widget.streamId != null) {
        try {
          final liveStreamService = LiveStreamService();
          final currentUser = _auth.currentUser;
          // Use UID as primary identifier (consistent with join)
          final viewerId = currentUser?.uid;
          if (viewerId != null && viewerId.isNotEmpty) {
            await liveStreamService.leaveStream(widget.streamId!, viewerId: viewerId);
            debugPrint('👥 Viewer left - decrementing viewer count and removing from list');
          } else {
            debugPrint('⚠️ Warning: viewerId is null, only decrementing count');
          await liveStreamService.leaveStream(widget.streamId!);
          }
        } catch (e) {
          debugPrint('⚠️ Error decrementing viewer count: $e');
          // Continue with cleanup even if this fails
        }
      }
      
      // If host, end the live stream in Firebase BEFORE leaving channel
      if (widget.isHost && widget.streamId != null) {
        try {
          final liveStreamService = LiveStreamService();
          await liveStreamService.endLiveStream(widget.streamId!);
          debugPrint('✅ Live stream ended in Firebase: ${widget.streamId}');
          
          // Wait a moment to ensure Firestore update propagates
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint('❌ Error ending live stream: $e');
          // Try one more time with a simpler approach
          try {
            final liveStreamService = LiveStreamService();
            await liveStreamService.endLiveStream(widget.streamId!);
            debugPrint('✅ Retry successful - stream ended');
          } catch (retryError) {
            debugPrint('❌ Retry also failed: $retryError');
            // Continue with cleanup even if ending stream fails
          }
        }
      }
      
      // Leave Agora channel and release engine
      try {
        await _engine.leaveChannel();
        debugPrint('✅ Left Agora channel');
      } catch (e) {
        debugPrint('⚠️ Error leaving channel: $e');
      }
      
      try {
        await _engine.release();
        debugPrint('✅ Released Agora engine');
      } catch (e) {
        debugPrint('⚠️ Error releasing engine: $e');
      }
      
      debugPrint('✅ Cleanup process completed');
    } catch (e) {
      debugPrint('❌ Error in cleanup process: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  // ========== VIEWER UI WIDGETS ==========
  
  // Build top bar - left side (Host info bar)
  Widget _buildViewerTopBarLeft() {
    if (widget.streamId == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    // Use existing service instance instead of creating new one
    return StreamBuilder<LiveStreamModel?>(
      key: ValueKey('topBar_${widget.streamId}'), // Prevent unnecessary rebuilds
      stream: _liveStreamService.getLiveStream(widget.streamId!),
      builder: (context, snapshot) {
        // Only show loading on initial connection, not on rebuilds
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }
        
        final stream = snapshot.data;
        final hostName = stream?.hostName ?? 'Host';
        final hostPhotoUrl = stream?.hostPhotoUrl;
        final viewerCount = stream?.viewerCount ?? 0;
        final hostId = stream?.hostId;
        
        if (hostId != null && hostId.isNotEmpty && !widget.isHost && !_hasCheckedFollowStatus) {
          _hasCheckedFollowStatus = true;
          _checkFollowStatus(hostId);
        }
        
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        
        return GestureDetector(
          onTap: () async {
            if (hostId != null && hostId.isNotEmpty) {
              await _showProfileBottomSheet(hostId, hostName, hostPhotoUrl);
            }
          },
          child: Container(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.75,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 10, 
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Host Profile Image with Pink Border
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF1B7C), // Solid pink color instead of gradient
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: ClipOval(
                      child: hostPhotoUrl != null && hostPhotoUrl.isNotEmpty
                          ? Image.network(
                              hostPhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Host Info Column - Made flexible to prevent overflow
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name + Age + Verified Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              hostName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 11 : 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Age (if available)
                          StreamBuilder<DocumentSnapshot>(
                            stream: hostId != null
                                ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(hostId)
                                    .snapshots()
                                : null,
                            builder: (context, userSnapshot) {
                              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                final age = userData?['age'] as int?;
                                if (age != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      ', $age',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isSmallScreen ? 10 : 12,
                                      ),
                                    ),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(width: 4),
                          // Verified Badge
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF1DA1F2),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Coins + Viewer Count Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Coins Display
                          StreamBuilder<DocumentSnapshot>(
                            stream: !widget.isHost && _auth.currentUser != null
                                ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_auth.currentUser!.uid)
                                    .snapshots()
                                : null,
                            builder: (context, balanceSnapshot) {
                              int coins = _userBalance;
                              if (balanceSnapshot.hasData && balanceSnapshot.data!.exists) {
                                final userData = balanceSnapshot.data!.data() as Map<String, dynamic>?;
                                coins = (userData?['uCoins'] as int?) ?? _userBalance;
                              }
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/coin3.png',
                                    width: 14,
                                    height: 14,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatNumber(coins.toDouble()),
                                    style: TextStyle(
                                      color: Colors.amber[300],
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Viewer Count
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.remove_red_eye,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatViewerCount(viewerCount),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isSmallScreen ? 10 : 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Pink Plus/Follow Button
                if (!widget.isHost && hostId != null && hostId.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      await _toggleFollowHost(hostId, hostName);
                    },
                    child: Container(
                      width: isSmallScreen ? 24 : 28,
                      height: isSmallScreen ? 24 : 28,
                      decoration: BoxDecoration(
                        color: _isFollowingHost 
                            ? Colors.grey[600] 
                            : const Color(0xFFFF1B7C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF1B7C).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isFollowLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isFollowingHost ? Icons.check : Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show profile bottom sheet popup
  Future<void> _showProfileBottomSheet(String hostId, String hostName, String? hostPhotoUrl) async {
    try {
      final databaseService = DatabaseService();
      final hostUserData = await databaseService.getUserData(hostId);
      
      if (hostUserData == null || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load host profile'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Check follow status
      final currentUserId = _auth.currentUser?.uid;
      bool isFollowing = false;
      if (currentUserId != null && currentUserId != hostId) {
        isFollowing = await _followService.isFollowing(currentUserId, hostId);
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (context) => _ProfileBottomSheet(
          user: hostUserData,
          hostPhotoUrl: hostPhotoUrl,
          isFollowing: isFollowing,
          onFollowTap: () async {
            if (currentUserId != null && currentUserId != hostId) {
              await _toggleFollowHost(hostId, hostName);
              Navigator.pop(context);
            }
          },
          onProfileTap: () {
            Navigator.pop(context);
            _navigateToHostProfile(hostId);
          },
          onReportTap: () {
            Navigator.pop(context);
            _showReportUserDialog(hostId, hostName);
          },
          onVideoChatTap: () {
            Navigator.pop(context);
            // Start video chat - create call request
            if (widget.streamId != null && currentUserId != null) {
              _createCallRequest(hostId, hostName, hostPhotoUrl);
            }
          },
          onMessageTap: () async {
            Navigator.pop(context);
            await _openChatWithHost(hostUserData);
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing profile bottom sheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading profile'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Navigate to host profile view screen
  Future<void> _navigateToHostProfile(String hostId) async {
    try {
      final databaseService = DatabaseService();
      final hostUserData = await databaseService.getUserData(hostId);
      
      if (hostUserData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileViewScreen(
              user: hostUserData,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load host profile'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error navigating to host profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading profile'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Show report user dialog
  void _showReportUserDialog(String reportedUserId, String reportedUserName) {
    final List<String> reportReasons = const [
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Why are you reporting this?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Report Reasons List - Flexible to prevent overflow
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: reportReasons.length,
                  itemBuilder: (context, index) {
                    final reason = reportReasons[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await _submitReport(reportedUserId, reportedUserName, reason);
                          if (mounted) Navigator.pop(context);
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Submit report
  Future<void> _submitReport(String reportedUserId, String reportedUserName, String reason) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance.collection('reports').add({
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reporterId': currentUser.uid,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report submitted successfully. Our team will review this.'),
            backgroundColor: const Color(0xFF2196F3), // Blue color
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
      if (mounted) {
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

  // Create call request for video chat
  Future<void> _createCallRequest(String hostId, String hostName, String? hostImage) async {
    if (widget.streamId == null || widget.isHost) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Check if host is in a call
      if (_isHostInCall) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Host is currently busy in a private video call'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Send call request
      await _callRequestService.sendCallRequest(
        streamId: widget.streamId!,
        callerId: currentUser.uid,
        callerName: currentUser.displayName ?? 'User',
        callerImage: currentUser.photoURL,
        hostId: hostId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call request sent to $hostName'),
            backgroundColor: const Color(0xFFFF1B7C),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating call request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Insufficient') 
                ? e.toString() 
                : 'Failed to send call request. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Open chat with host
  Future<void> _openChatWithHost(UserModel hostUser) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get current user data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final currentUserModel = UserModel.fromFirestore(currentUserDoc);

      // Create or get chat
      final chatId = await _chatService.createOrGetChat(currentUserModel, hostUser);

      if (!mounted) return;

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUser: hostUser,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open chat'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Check if viewer is following the host
  Future<void> _checkFollowStatus(String hostId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId == hostId) return;

    try {
      final isFollowing = await _followService.isFollowing(currentUserId, hostId);
      if (mounted) {
        setState(() {
          _isFollowingHost = isFollowing;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking follow status: $e');
    }
  }

  // Toggle follow/unfollow host
  Future<void> _toggleFollowHost(String hostId, String hostName) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId == hostId) return;

    setState(() => _isFollowLoading = true);

    try {
      final databaseService = DatabaseService();
      final hostUserData = await databaseService.getUserData(hostId);
      
      if (hostUserData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load host data'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (_isFollowingHost) {
        // Unfollow
        final success = await _followService.unfollowUser(currentUserId, hostId);
        if (success && mounted) {
          setState(() {
            _isFollowingHost = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unfollowed $hostName'),
              backgroundColor: Colors.grey[700],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Follow
        final success = await _followService.followUser(currentUserId, hostUserData);
        if (success && mounted) {
          setState(() {
            _isFollowingHost = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Following $hostName'),
              backgroundColor: const Color(0xFF9C27B0), // Purple
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }
  
  // Build top bar - right side (Flag, Block, Group icon + Close button)
  Widget _buildViewerTopBarRight() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Viewer Avatars (horizontal row) - Clickable to show viewer list
        GestureDetector(
          onTap: () {
            if (widget.streamId != null) {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                isDismissible: true,
                enableDrag: true,
                barrierColor: Colors.black.withValues(alpha: 0.3),
                builder: (context) => GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () {}, // Prevent tap from closing when tapping on sheet
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                            ),
                            child: ViewerListSheet(
                              streamId: widget.streamId!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          },
          child: StreamBuilder<QuerySnapshot>(
          stream: widget.streamId != null
              ? FirebaseFirestore.instance
                  .collection('live_streams')
                  .doc(widget.streamId!)
                  .collection('viewers')
                  .limit(3)
                  .snapshots()
              : null,
          builder: (context, viewersSnapshot) {
            if (viewersSnapshot.hasData && viewersSnapshot.data!.docs.isNotEmpty) {
              final viewers = viewersSnapshot.data!.docs;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < viewers.length && i < 3; i++)
                    Transform.translate(
                        offset: Offset(i * -8.0, 0),
                      child: Container(
                          width: 32,
                          height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF1B7C), // Pink border
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: viewers[i].data() != null
                              ? Image.network(
                                  (viewers[i].data() as Map<String, dynamic>)['photoURL'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[400],
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                          size: 18,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[400],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                      size: 18,
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
          ),
        ),
        const SizedBox(height: 8),
        // Action Buttons (stacked vertically)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close "X" button (top)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () async {
                  debugPrint('❌ Close button pressed - cleaning up...');
                  await _cleanupAgoraEngine();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // Flag/Report button
            StreamBuilder<LiveStreamModel?>(
              stream: widget.streamId != null
                  ? _liveStreamService.getLiveStream(widget.streamId!)
                  : null,
              builder: (context, streamSnapshot) {
                final stream = streamSnapshot.data;
                final hostId = stream?.hostId ?? '';
                final hostName = stream?.hostName ?? 'Host';
                
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.flag_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      if (hostId.isNotEmpty) {
                        _showReportUserDialog(hostId, hostName);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to report. Host information not available.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Mute button (for viewers - mute host audio)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  _isViewerMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  _toggleViewerSound();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Build viewer count widget (real-time from Firebase)
  // Build camera toggle button for host (single toggle button)
  Widget _buildCameraToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _switchCamera();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // Switch camera between front and back
  Future<void> _switchCamera() async {
    try {
      await _engine.switchCamera();
      if (mounted) {
        setState(() {
          _isFrontCamera = !_isFrontCamera;
        });
      }
      debugPrint('📷 Camera switched to: ${_isFrontCamera ? "Front" : "Back"}');
    } catch (e) {
      debugPrint('❌ Error switching camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch camera: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Toggle mute/unmute microphone
  Future<void> _toggleMute() async {
    try {
      await _engine.muteLocalAudioStream(!_isMuted);
      if (mounted) {
        setState(() {
          _isMuted = !_isMuted;
        });
      }
      debugPrint('🔇 Microphone ${_isMuted ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('❌ Error toggling mute: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle mute: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Setup listener for incoming call requests (host only)
  void _setupIncomingCallRequestListener() {
    if (widget.streamId == null) {
      debugPrint('⚠️ Cannot setup call listener: streamId is null');
      return;
    }
    
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      debugPrint('⚠️ Cannot setup call listener: currentUserId is null');
      return;
    }

    debugPrint('✅ Setting up incoming call request listener for host: $currentUserId');

    _incomingCallRequestSubscription = _callRequestService
        .listenToIncomingCallRequests(currentUserId)
        .listen(
      (requests) {
        debugPrint('📞 Incoming call requests received: ${requests.length}');
        if (!mounted) return;
        
        // Show dialog for the most recent pending request
        if (requests.isNotEmpty && !_isCallDialogShowing) {
          final request = requests.first;
          debugPrint('📞 Showing call request dialog for: ${request.callerName} (${request.requestId})');
          _showCallRequestDialog(request);
        } else if (requests.isEmpty) {
          debugPrint('📞 No pending call requests');
        } else if (_isCallDialogShowing) {
          debugPrint('📞 Call dialog already showing, skipping');
        }
      },
      onError: (error) {
        debugPrint('❌ Error in call request listener: $error');
      },
    );
  }

  // Setup listener for host status (viewer only)
  void _setupHostStatusListener() {
    if (widget.streamId == null) return;

    // Use Firestore stream directly
    _hostStatusSubscription = FirebaseFirestore.instance
        .collection('live_streams')
        .doc(widget.streamId!)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;
      
      final data = snapshot.data();
      final hostStatus = data?['hostStatus'] ?? 'live';
      final isInCall = hostStatus == 'in_call';
      
      if (_isHostInCall != isInCall) {
        setState(() {
          _isHostInCall = isInCall;
        });
      }
    });
  }

  // Show call request dialog (host)
  void _showCallRequestDialog(CallRequestModel request) {
    // Check if dialog is already showing
    if (!mounted || _isCallDialogShowing) {
      debugPrint('⚠️ Cannot show dialog: mounted=$mounted, alreadyShowing=$_isCallDialogShowing');
      return;
    }
    
    setState(() {
      _isCallDialogShowing = true;
    });
    
    debugPrint('📞 Showing call request dialog for: ${request.callerName}');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CallRequestDialog(
        callRequest: request,
        onAccept: () {
          setState(() {
            _isCallDialogShowing = false;
          });
          _handleAcceptCallRequest(request);
        },
        onReject: () {
          setState(() {
            _isCallDialogShowing = false;
          });
          _handleRejectCallRequest(request.requestId);
        },
      ),
    ).then((_) {
      // Dialog closed
      if (mounted) {
        setState(() {
          _isCallDialogShowing = false;
        });
      }
    });
  }

  // Handle accept call request (host)
  Future<void> _handleAcceptCallRequest(CallRequestModel request) async {
    try {
      // CRITICAL: Leave live stream channel before joining private call
      // This prevents Agora error -17 (ERR_JOIN_CHANNEL_REJECTED)
      debugPrint('📞 Host accepting call - leaving live stream channel first...');
      try {
        await _engine.leaveChannel();
        debugPrint('✅ Left live stream channel');
        // Wait a bit for the leave to complete
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('⚠️ Error leaving channel (may already be left): $e');
        // Continue anyway - might already be left
      }

      // Generate call channel name and token dynamically
      // Use unique channel name for private calls (based on request ID)
      final callChannelName = 'private_call_${request.requestId}';
      
      // Generate token dynamically for private call
      final tokenService = AgoraTokenService();
      final callToken = await tokenService.getHostToken(
        channelName: callChannelName,
      );
      
      debugPrint('📞 Generated token for private call: $callChannelName');
      
      // Update call request with channel info
      await _callRequestService.acceptCallRequest(
        requestId: request.requestId,
        streamId: request.streamId,
        callerId: request.callerId,
        callChannelName: callChannelName,
        callToken: callToken,
      );

      // Navigate to private call screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrivateCallScreen(
              callChannelName: callChannelName,
              callToken: callToken,
              streamId: request.streamId,
              requestId: request.requestId,
              otherUserId: request.callerId,
              otherUserName: request.callerName,
              otherUserImage: request.callerImage,
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error accepting call request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle reject call request (host)
  Future<void> _handleRejectCallRequest(String requestId) async {
    try {
      await _callRequestService.rejectCallRequest(requestId);
    } catch (e) {
      debugPrint('❌ Error rejecting call request: $e');
    }
  }

  /// Setup real-time balance listener (PRIMARY - updates immediately when coins are deducted)
  void _setupRealtimeBalanceListener() {
    if (widget.isHost) return;
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    debugPrint('🔄 AgoraLiveStream: Setting up real-time balance listener for user: $userId');
    
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Listen to users collection uCoins field (PRIMARY SOURCE OF TRUTH)
    _balanceSubscription = firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted || widget.isHost) return;
        
        if (snapshot.exists) {
          final userData = snapshot.data();
          final uCoins = (userData?['uCoins'] as int?) ?? 0;
          final coins = (userData?['coins'] as int?) ?? 0;
          
          // Use uCoins as primary (it's always updated during deductions)
          // Only use coins if uCoins is 0 and coins has value (legacy data)
          final newBalance = uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
          
          if (newBalance != _userBalance) {
            debugPrint('📡 AgoraLiveStream: Real-time balance update: $_userBalance → $newBalance');
            setState(() {
              _userBalance = newBalance;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('❌ AgoraLiveStream: Error in balance listener: $error');
      },
    );
  }
  
  // Send call request (viewer)
  /// Load user balance (initial load)
  Future<void> _loadUserBalance() async {
    if (widget.isHost) return;
    
    setState(() => _isLoadingBalance = true);
    try {
      final balance = await _coinDeductionService.getUserBalance(_auth.currentUser!.uid);
      if (mounted) {
        setState(() {
          _userBalance = balance;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading balance: $e');
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
  }
  
  Future<void> _sendCallRequest() async {
    if (widget.streamId == null) return;
    if (_isHostInCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Host is currently busy in a private video call'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isCallRequestPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call request already pending. Please wait...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Check balance before sending request
    if (!widget.isHost) {
      final hasEnoughCoins = await _coinDeductionService.hasEnoughCoins(_auth.currentUser!.uid);
      if (!hasEnoughCoins) {
        await _loadUserBalance(); // Refresh balance
        if (mounted) {
          await LowCoinPopup.show(
            context,
            currentBalance: _userBalance,
            requiredCoins: 1000,
            phoneNumber: _auth.currentUser?.phoneNumber,
          );
        }
        return;
      }
    }

    try {
      setState(() => _isCallRequestPending = true);

      // Get current user info
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get stream info to get host ID
      final stream = await _liveStreamService.getLiveStreamOnce(widget.streamId!);
      if (stream == null) {
        throw Exception('Stream not found');
      }

      // Get user data for caller name and image
      final databaseService = DatabaseService();
      final userData = await databaseService.getUserData(currentUser.uid);

      // Send call request (coin validation already done in service)
      String requestId;
      try {
        requestId = await _callRequestService.sendCallRequest(
          streamId: widget.streamId!,
          callerId: currentUser.uid,
          callerName: userData?.name ?? 'User',
          callerImage: userData?.photoURL,
          hostId: stream.hostId,
        );
      } catch (e) {
        // Handle coin validation error
        setState(() => _isCallRequestPending = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _currentCallRequestId = requestId;
      });

      // Listen to call request status
      _callRequestStatusSubscription?.cancel();
      _callRequestStatusSubscription = _callRequestService
          .listenToCallRequestStatus(requestId)
          .listen((request) {
        if (!mounted || request == null) return;

        if (request.status == 'accepted') {
          // Navigate to private call screen
          // Use token from request, or generate new token if empty/invalid
          if (request.callToken != null && request.callToken!.isNotEmpty && 
              request.callChannelName != null && request.callChannelName!.isNotEmpty) {
            // Use token from request (already generated when call was accepted)
            final callToken = request.callToken!;
            final callChannelName = request.callChannelName!;
            debugPrint('📞 Using token from call request');
            
            // Navigate immediately with token from request
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrivateCallScreen(
                  callChannelName: callChannelName,
                  callToken: callToken,
                  streamId: request.streamId,
                  requestId: request.requestId,
                  otherUserId: stream.hostId,
                  otherUserName: stream.hostName,
                  otherUserImage: stream.hostPhotoUrl,
                  isHost: false,
                ),
              ),
            );
            setState(() {
              _isCallRequestPending = false;
              _currentCallRequestId = null;
            });
          } else {
            // Generate new token dynamically (fallback) - async handling
            final callChannelName = 'private_call_${request.requestId}';
            final tokenService = AgoraTokenService();
            
            tokenService.getHostToken(channelName: callChannelName).then((callToken) {
              if (!mounted) return;
              
              debugPrint('📞 Generated new token for call');
              debugPrint('📞 Call accepted - Channel: $callChannelName, Token length: ${callToken.length}');
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivateCallScreen(
                    callChannelName: callChannelName,
                    callToken: callToken,
                    streamId: request.streamId,
                    requestId: request.requestId,
                    otherUserId: stream.hostId,
                    otherUserName: stream.hostName,
                    otherUserImage: stream.hostPhotoUrl,
                    isHost: false,
                  ),
                ),
              );
              setState(() {
                _isCallRequestPending = false;
                _currentCallRequestId = null;
              });
            }).catchError((error) {
              debugPrint('❌ Error generating token for call: $error');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to join call: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
          }
        } else if (request.status == 'rejected') {
          setState(() {
            _isCallRequestPending = false;
            _isCallRejected = true;
            _currentCallRequestId = null;
          });
          // Auto-hide rejected popup after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _isCallRejected = false;
              });
            }
          });
        } else if (request.status == 'cancelled' || request.status == 'ended') {
          setState(() {
            _isCallRequestPending = false;
            _currentCallRequestId = null;
          });
        }
      });

      // Popup will show automatically via _isCallRequestPending state
      // No need for snackbar - popup is better UX
    } catch (e) {
      debugPrint('❌ Error sending call request: $e');
      setState(() => _isCallRequestPending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send call request: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Toggle viewer-side sound (mute/unmute host audio locally)
  Future<void> _toggleViewerSound() async {
    // Only meaningful for viewers (audience role)
    if (widget.isHost) return;
    try {
      final shouldMute = !_isViewerMuted;
      // Mute/unmute all remote audio streams for this viewer
      await _engine.muteAllRemoteAudioStreams(shouldMute);
      if (mounted) {
        setState(() {
          _isViewerMuted = shouldMute;
        });
      }
      debugPrint('🔊 Viewer sound ${shouldMute ? "muted" : "unmuted"} (host audio)');
    } catch (e) {
      debugPrint('❌ Error toggling viewer sound: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change sound: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Build mute button for host
  Widget _buildMuteButton() {
    return Container(
      decoration: BoxDecoration(
        color: _isMuted 
            ? Colors.red.withValues(alpha: 0.8) 
            : Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleMute,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              _isMuted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewerCount() {
    if (widget.streamId == null) {
      return const SizedBox.shrink();
    }
    
    final liveStreamService = LiveStreamService();
    
    return StreamBuilder<LiveStreamModel?>(
      stream: liveStreamService.getLiveStream(widget.streamId!),
      builder: (context, snapshot) {
        final viewerCount = snapshot.data?.viewerCount ?? 0;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.remove_red_eye,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                _formatViewerCount(viewerCount),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Format viewer count (e.g., 1234 -> "1.2K")
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  String _formatViewerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }


  // Displays the local user's video view using the Agora engine (full screen for host)
  Widget _localVideo() {
    if (!_localPreviewReady) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine, // Uses the Agora engine instance
        canvas: const VideoCanvas(
          uid: 0, // Specifies the local user
          renderMode: RenderModeType.renderModeHidden, // Crop to fill - no black bars
        ),
      ),
    );
  }

  // If a remote user has joined, render their video (full screen for viewers), else display a waiting message
  Widget _remoteVideo() {
    // Check if host is offline (for viewers only)
    if (!widget.isHost && widget.streamId != null) {
      return StreamBuilder<LiveStreamModel?>(
        stream: LiveStreamService().getLiveStream(widget.streamId!),
        builder: (context, snapshot) {
          final stream = snapshot.data;
          final isStreamActive = stream?.isActive ?? true;
          final hostStatus = stream?.hostStatus ?? 'live';
          
          // Calculate time since join (if viewer just joined)
          final timeSinceJoin = _joinTime != null 
              ? DateTime.now().difference(_joinTime!)
              : const Duration(seconds: 10); // Default to 10 seconds if join time not set
          
          // Only consider host offline if:
          // 1. Stream is explicitly inactive/ended, OR
          // 2. Remote UID is null AND we've waited at least 5 seconds (to avoid false positives on initial join)
          final isHostOffline = (!isStreamActive || hostStatus == 'ended') || 
              (_remoteUid == null && timeSinceJoin.inSeconds >= 5);
          
          // Update offline state
          if (isHostOffline != _hostIsOffline) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hostIsOffline = isHostOffline;
                });
              }
            });
          }
          
          // If host is offline (and we've waited enough time), show offline message
          if (isHostOffline && (!isStreamActive || hostStatus == 'ended')) {
            return _buildHostOfflineScreen();
          }
          
          // If remote video is available, show it
          if (_remoteUid != null) {
            return AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(
                  uid: _remoteUid,
                  renderMode: RenderModeType.renderModeHidden,
                ),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            );
          }
          
          // No video available yet - show black screen (waiting for connection)
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
          );
        },
      );
    }
    
    // For hosts: Never show remote video - hosts should only see their own local video
    // This prevents hosts from seeing other hosts' videos
    if (widget.isHost) {
      // Host should never see remote video - return black screen
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
      );
    }
    
    // For viewers without streamId: show remote video if available
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(
            uid: _remoteUid,
            renderMode: RenderModeType.renderModeHidden,
          ),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
      } else {
        // No video available - show black screen
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
        );
      }
    }
  
  // Build gift row (horizontal scrollable gifts above bottom nav)
  Widget _buildGiftRow() {
    // Match UI exactly: Ganesha (199), Sunflowers (199), Star (400), Donut (250), Pac-Man (429), Throne (499)
    final featuredGifts = [
      GiftModel(id: 'ganesha', name: 'Ganesha', cost: 199, category: 'Hot', emoji: '🕉️'),
      GiftModel(id: 'sunflowers', name: 'Sunflowers', cost: 199, category: 'Hot', emoji: '🌻'),
      GiftModel(id: 'star', name: 'Star', cost: 400, category: 'Hot', emoji: '⭐'),
      GiftModel(id: 'donut', name: 'Donut', cost: 250, category: 'Funny', emoji: '🍩'),
      GiftModel(id: 'pacman', name: 'Pac-Man', cost: 429, category: 'Funny', emoji: '👾'),
      GiftModel(id: 'throne', name: 'Throne', cost: 499, category: 'Luxury', emoji: '👑'),
    ];
    final newGiftIndices = [0, 1, 4, 5]; // Ganesha, Sunflowers, Pac-Man, Throne have NEW badge
    
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: featuredGifts.length,
        itemBuilder: (context, index) {
          final gift = featuredGifts[index];
          final isNew = newGiftIndices.contains(index);
          
          return GestureDetector(
            onTap: () {
              _showGiftSelectionSheet();
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Gift content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Gift emoji
                        Text(
                          gift.emoji ?? '🎁',
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        // Gift cost
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/coin3.png',
                              width: 12,
                              height: 12,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatNumber((gift.cost ?? 0).toDouble()),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // NEW badge
                  if (isNew)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                          ),
                          borderRadius: BorderRadius.circular(4),
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
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Build viewer bottom icons row (Chat, Start Video Chat, Gift)
  Widget _buildViewerBottomIconsRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360; // Small phones
    final isVerySmallScreen = screenWidth < 320; // Very small phones
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 16), 
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Left: Chat Button (Black rounded rectangle)
          BouncyIconButton(
            onTap: () {
              final newChatState = !_isChatOpen;
              setState(() {
                _isChatOpen = newChatState;
              });
              // Focus the chat input field to show keyboard
              if (newChatState) {
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted && _isChatOpen) {
                    _chatFocusNode.requestFocus();
                  }
                });
              } else {
                _chatFocusNode.unfocus();
              }
            },
            child: Container(
              width: isVerySmallScreen ? 28 : (isSmallScreen ? 32 : 36),
              height: isVerySmallScreen ? 28 : (isSmallScreen ? 32 : 36),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  'assets/images/chatliveicon.png',
                  width: 10,
                  height: 10,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Center: Start Video Chat Button (Pink Gradient)
          Expanded(
            child: Center(
              child: BouncyIconButton(
                onTap: () async {
                  // Check if button is disabled
                  if (_isHostInCall || _isCallRequestPending || (!widget.isHost && _userBalance < 1000)) {
                    if (_isHostInCall) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Host is currently busy in a private call'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else if (_isCallRequestPending) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Call request already pending. Please wait...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else if (!widget.isHost && _userBalance < 1000) {
                      await LowCoinPopup.show(
                        context,
                        currentBalance: _userBalance,
                        requiredCoins: 1000,
                        phoneNumber: _auth.currentUser?.phoneNumber,
                      );
                    }
                    return;
                  }
                  
                  if (!widget.isHost) {
                    _sendCallRequest();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hosts cannot call viewers'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: isVerySmallScreen ? 120 : (isSmallScreen ? 140 : 160),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12),
                    vertical: isSmallScreen ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: (_isHostInCall || _isCallRequestPending || (!widget.isHost && _userBalance < 1000))
                        ? Colors.grey
                        : const Color(0xFFFF1B7C), // Solid pink color instead of gradient
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1B7C).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/video.png',
                        width: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                        height: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                        color: Colors.white,
                      ),
                      SizedBox(width: isVerySmallScreen ? 4 : 6),
                      Flexible(
                        child: Text(
                          'Start Video Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 14),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Gift box icon - Right side
          BouncyIconButton(
            onTap: () {
              _showGiftSelectionSheet();
            },
            child: Container(
              width: isVerySmallScreen ? 28 : (isSmallScreen ? 32 : 36),
              height: isVerySmallScreen ? 28 : (isSmallScreen ? 32 : 36),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  'assets/images/gift-box.png',
                  width: 10,
                  height: 10,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build call rejected popup (shows "Host declined" when call is rejected)
  Widget _buildCallRejectedPopup() {
    return SlideInLeft(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: FadeInLeft(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE53935), // Red
                Color(0xFFD32F2F), // Darker red
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.call_end,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Host declined call',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build call request popup (shows "Call to host" when request is pending)
  Widget _buildCallRequestPopup() {
    // Get current user photo
    final currentUser = _auth.currentUser;
    final userPhotoUrl = currentUser?.photoURL;
    
    // Get host photo from stream
    return StreamBuilder<LiveStreamModel?>(
      stream: LiveStreamService().getLiveStream(widget.streamId!),
      builder: (context, snapshot) {
        final stream = snapshot.data;
        final hostPhotoUrl = stream?.hostPhotoUrl;
        
        return SlideInLeft(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: FadeInLeft(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
      child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF9C27B0), // Purple
              Color(0xFFE91E63), // Pink
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
                borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
            ),
          ],
        ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Row(
          mainAxisSize: MainAxisSize.min,
          children: [
                      // User profile icon (caller)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: ClipOval(
                          child: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                              ? Image.network(
                                  userPhotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      child: const Icon(
                                        Icons.person,
              color: Colors.white,
                                        size: 14,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                        ),
            ),
            const SizedBox(width: 8),
            // Text
            const Text(
                        'Calling',
              style: TextStyle(
                color: Colors.white,
                          fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
                      // Host profile icon
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: ClipOval(
                          child: hostPhotoUrl != null && hostPhotoUrl.isNotEmpty
                              ? Image.network(
                                  hostPhotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Cancel icon
                      GestureDetector(
                        onTap: () async {
                          if (_currentCallRequestId != null) {
                            try {
                              await _callRequestService.cancelCallRequest(_currentCallRequestId!);
                              setState(() {
                                _isCallRequestPending = false;
                                _currentCallRequestId = null;
                              });
                            } catch (e) {
                              debugPrint('❌ Error cancelling call request: $e');
                            }
                          }
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Animated heart icons moving from user to host (3 hearts with staggered delays)
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _heartAnimationController,
                      builder: (context, child) {
                        // Staggered delay for each heart (0.0, 0.33, 0.66)
                        final delay = index * 0.33;
                        double animationValue = (_heartAnimationController.value + delay) % 1.0;
                        
                        // Calculate position: 0.0 = user profile, 1.0 = host profile
                        // User profile: 24px width, center at 12px
                        // Text "Calling": ~50px width
                        // Spacing: 8px between each element
                        // Host profile: 24px width, center at (24 + 8 + 50 + 8 + 12) = 102px
                        final startX = 12.0; // Center of user profile (24/2)
                        final endX = 102.0; // Center of host profile (24 + 8 + 50 + 8 + 12)
                        final currentX = startX + (endX - startX) * animationValue;
                        
                        // Fade in/out at edges
                        double opacity = 1.0;
                        if (animationValue < 0.1) {
                          opacity = animationValue / 0.1;
                        } else if (animationValue > 0.9) {
                          opacity = (1.0 - animationValue) / 0.1;
                        }
                        
                        return Positioned(
                          left: currentX - 8, // Center the heart icon (16/2)
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
              width: 16,
              height: 16,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build viewer chat input field
  // Old chat methods removed - using new chat system
  
  // Build admin message popup widget (without Positioned wrapper)
  Widget _buildAdminMessageContent() {
    return SlideInLeft(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: FadeInLeft(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 12,
                offset: const Offset(0, 3),
        ),
            ],
          ),
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Green star/badge icon
            Container(
                padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
              ),
                child: const Icon(
                  Icons.star,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _currentAdminMessage!,
                  style: const TextStyle(
                      color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    ),
                  ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  // Build live streaming chat overlay (always visible, messages scroll up continuously)
  Widget _buildLiveStreamChat() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    // Calculate bottom icons row height (approximately 60px with padding)
    const bottomIconsHeight = 60.0;
    // Bottom icons are now at bottom: 0 with SafeArea handling padding
    
    // Chat input panel height (approximately 50px)
    const chatInputHeight = 50.0;
    const chatInputSpacing = 8.0; // Spacing from bottom for input field
    const chatBubbleSpacing = 12.0; // Spacing between chat bubbles and elements below
    
    // Show only last 5 messages to avoid covering too much screen
    const maxVisibleMessages = 5;
    
    // Calculate position based on state
    double bottomPosition;
    if (_isChatOpen && isKeyboardVisible) {
      // Chat input is open with keyboard: position above keyboard + input field + spacing
      bottomPosition = keyboardHeight + chatInputSpacing + chatInputHeight + chatBubbleSpacing;
    } else if (_isChatOpen && !isKeyboardVisible) {
      // Chat input is open but no keyboard: input is above bottom icons
      // Bottom icons are at safeAreaBottom + bottomIconsHeight (SafeArea handles padding)
      final inputBottom = safeAreaBottom + bottomIconsHeight + 12;
      bottomPosition = inputBottom + chatInputHeight + chatBubbleSpacing;
    } else {
      // Chat closed: position above bottom icons with spacing
      // Bottom icons are at safeAreaBottom + bottomIconsHeight (SafeArea handles padding)
      bottomPosition = safeAreaBottom + bottomIconsHeight + chatBubbleSpacing;
    }
    
    // Ensure chat bubbles don't go too high - limit to 40% of screen height max
    final screenHeight = MediaQuery.of(context).size.height;
    final topBarHeight = MediaQuery.of(context).padding.top + 100; // Space for top bar
    final availableHeight = screenHeight - topBarHeight - bottomPosition;
    final maxChatHeight = (screenHeight * 0.4).clamp(0.0, availableHeight.clamp(0.0, 200.0));
    
    return Positioned(
      left: 8,
      right: 8, // Add right padding to prevent overflow
      bottom: bottomPosition,
      child: Container(
          constraints: BoxConstraints(
            maxHeight: maxChatHeight, // Dynamic max height based on available space
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
              child: StreamBuilder<List<LiveStreamChatMessage>>(
          key: ValueKey('chatMessages_${widget.streamId}'), // Prevent unnecessary rebuilds
                stream: widget.streamId != null
                    ? _liveStreamChatService.getMessages(widget.streamId!)
                    : Stream.value([]),
                builder: (context, snapshot) {
            debugPrint('📥 Viewer chat StreamBuilder - StreamId: ${widget.streamId}, HasData: ${snapshot.hasData}, MessageCount: ${snapshot.data?.length ?? 0}');
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            
            final allMessages = snapshot.data!;
            // Show only recent messages
            final visibleMessages = allMessages.length > maxVisibleMessages
                ? allMessages.sublist(allMessages.length - maxVisibleMessages)
                : allMessages;
            
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxChatHeight,
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.bottomLeft, // Messages align to bottom
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: visibleMessages.map((message) {
                      final isCurrentUser = message.userId == _auth.currentUser?.uid;
                      
                      return FadeInLeft(
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75 - 24, // Account for left (8) and right (8) padding + margins (8)
                            ),
                        child: Row(
                              mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                // User avatar (only for other users)
                            if (!isCurrentUser && message.userPhotoUrl != null)
                              Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    message.userPhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[400],
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                              size: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                                // Message bubble
                            Flexible(
                              child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75 - 58, // Account for avatar (20+6), padding (8*2), margins (8), and container padding (16)
                                    ),
                                padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isCurrentUser)
                                      Text(
                                        message.userName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                      ),
                                    if (!isCurrentUser) const SizedBox(height: 2),
                                    Text(
                                      message.message,
                                      style: const TextStyle(
                                        color: Colors.white,
                                            fontSize: 11,
                                      ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Build live streaming chat overlay (always visible, messages scroll up continuously) - wrapper with visibility
  Widget _buildLiveStreamChatWithVisibility() {
    return _buildLiveStreamChat();
  }
  
  // Build live streaming chat for host (positioned just above input field)
  Widget _buildHostLiveStreamChat() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final inputFieldHeight = 50.0; // Approximate height of input field
    final spacing = 8.0; // Space between input field and chat bubbles
    
    // Show only last 5 messages to avoid covering too much screen
    const maxVisibleMessages = 5;
    
    return Positioned(
      left: 8,
      bottom: keyboardHeight + inputFieldHeight + spacing, // Just above input field
      child: Container(
          constraints: BoxConstraints(
            maxHeight: 200, // Fixed max height
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: StreamBuilder<List<LiveStreamChatMessage>>(
            key: ValueKey('chatMessages_host_${widget.streamId}'), // Prevent unnecessary rebuilds
            stream: widget.streamId != null
                ? _liveStreamChatService.getMessages(widget.streamId!)
                : Stream.value([]),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final allMessages = snapshot.data!;
              // Show only recent messages
              final visibleMessages = allMessages.length > maxVisibleMessages
                  ? allMessages.sublist(allMessages.length - maxVisibleMessages)
                  : allMessages;
              
              return ClipRect(
                child: Align(
                  alignment: Alignment.bottomLeft, // Messages align to bottom
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: visibleMessages.map((message) {
                      final isCurrentUser = message.userId == _auth.currentUser?.uid;
                      
                      return FadeInLeft(
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User avatar (only for other users)
                              if (!isCurrentUser && message.userPhotoUrl != null)
                              Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    message.userPhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[400],
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                            size: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Message bubble
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
              decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 1,
                ),
              ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                children: [
                                      if (!isCurrentUser)
                                        Text(
                                          message.userName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                        ),
                                      if (!isCurrentUser) const SizedBox(height: 2),
                                      Text(
                                        message.message,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
      ),
    );
  }
  
  // Send chat message
  Future<void> _sendChatMessage() async {
    if (_chatMessageController.text.trim().isEmpty || widget.streamId == null) {
      return;
    }
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    final messageText = _chatMessageController.text.trim();
    
    // Get user data
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    final userData = userDoc.data();
    final userName = userData?['name'] as String? ?? 
                     userData?['displayName'] as String? ?? 
                     currentUser.displayName ?? 
                     'User';
    final userPhotoUrl = userData?['photoURL'] as String? ?? 
                         currentUser.photoURL;
    
    debugPrint('📤 Sending chat message - StreamId: ${widget.streamId}, IsHost: ${widget.isHost}, UserId: ${currentUser.uid}, Message: $messageText');
    
    final success = await _liveStreamChatService.sendMessage(
      streamId: widget.streamId!,
      userId: currentUser.uid,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      message: messageText,
      isHost: widget.isHost,
    );
    
    if (success) {
      debugPrint('✅ Chat message sent successfully');
    _chatMessageController.clear();
    } else {
      debugPrint('❌ Failed to send chat message');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Send gift message
  Future<void> _sendGiftMessage(String giftName, int giftCost, String giftEmoji) async {
    if (widget.streamId == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    try {
      final chatService = LiveChatService();
      final success = await chatService.sendGiftMessage(
        liveStreamId: widget.streamId!,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'User',
        senderImage: currentUser.photoURL,
        giftName: giftName,
        giftCost: giftCost,
        giftEmoji: giftEmoji,
        isHost: false,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$giftEmoji $giftName sent!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send gift. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending gift: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending gift. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Show gift selection sheet
  void _showGridOptionsPopup() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.2,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Icons in horizontal row (starting from left edge)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Message icon with unread count badge
                  StreamBuilder<List<ChatModel>>(
                    stream: _auth.currentUser != null
                        ? _chatService.getUserChats(_auth.currentUser!.uid)
                        : Stream<List<ChatModel>>.empty(),
                    builder: (context, snapshot) {
                      int totalUnreadCount = 0;
                      if (snapshot.hasData && _auth.currentUser != null) {
                        final userId = _auth.currentUser!.uid;
                        for (var chat in snapshot.data!) {
                          final unreadCount = chat.getUnreadCount(userId);
                          totalUnreadCount += unreadCount;
                        }
                      }
                      
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              // Open MessagesScreen in popup
                              _showMessagesPopup();
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/chat.png',
                                width: 22,
                                height: 22,
                                color: const Color(0xFF9C27B0),
                              ),
                            ),
                          ),
                          // Unread count badge
                          if (totalUnreadCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    totalUnreadCount > 99 ? '99+' : totalUnreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 30),
                  // Coin icon
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      // Open gift selection (which uses coins)
                      _showGiftSelectionSheet();
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          'assets/images/coin3.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }


  void _showMessagesPopup() {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // MessagesScreen content embedded in popup
            Expanded(
              child: MessagesScreen(
                hideSearchBar: true,
                hideFloatingButton: true,
                hideAppBarActions: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiftSelectionSheet() {
    if (widget.streamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stream not available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GiftSelectionSheet(
        liveStreamId: widget.streamId!,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'User',
        senderImage: currentUser.photoURL,
        onGiftSelected: _sendGiftMessage,
      ),
    );
  }
  
  // Build individual bottom icon
  Widget _buildBottomIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // Build host offline screen (when host ends stream)
  Widget _buildHostOfflineScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.grey[900]!.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated offline icon with pulsing effect
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing ring
                    Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    // Inner icon container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.8),
                            Colors.orange.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_off,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
              onEnd: () {
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 32),
            // Main message
            FadeIn(
              child: Text(
                'Host is Offline Now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle message
            FadeIn(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'The live stream has ended.\nPlease check back later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only set pink status bar on phones (not tablets/desktop)
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;
    
    // Check keyboard visibility only when chat is open (lightweight check)
    final currentKeyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (_isChatOpen) {
      // Only check when chat is actually open to avoid unnecessary work
      if (_previousKeyboardHeight > 0 && currentKeyboardHeight == 0) {
        // Keyboard was dismissed, close chat input field
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isChatOpen && !_chatFocusNode.hasFocus) {
            setState(() {
              _isChatOpen = false;
            });
          }
        });
      }
      _previousKeyboardHeight = currentKeyboardHeight;
    } else {
      // Reset when chat is closed
      _previousKeyboardHeight = 0.0;
    }
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: isPhone ? const Color(0xFFFF1B7C) : Colors.transparent, // Pink status bar only on phones
        statusBarIconBrightness: isPhone ? Brightness.light : Brightness.dark, // Light icons for pink, dark for transparent
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false, // Prevent default back button behavior
        onPopInvoked: (didPop) async {
          if (didPop) return;
          // Ensure cleanup happens when back button is pressed
          debugPrint('🔙 Back button pressed - cleaning up...');
          await _cleanupAgoraEngine();
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false, // Prevent screen resize when keyboard appears
        // Remove AppBar for full-screen experience
        body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing live stream...'),
                ],
              ),
            )
          : _errorMessage != null
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 24),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                  _isLoading = true;
                                });
                                _initializeAgora();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8E24AA),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    // Toggle view swap on tap
                    setState(() {
                      _isViewsSwapped = !_isViewsSwapped;
                    });
                  },
                  child: Stack(
                    children: [
                      // Large video view (main view)
                      Positioned.fill(
                        child: _isViewsSwapped
                            ? (widget.isHost ? _localVideo() : _localVideo()) // Swapped: host always shows local, viewer shows local
                            : (widget.isHost ? _localVideo() : _remoteVideo()), // Normal: host shows local, viewer shows remote
                      ),
                      
                      // Small thumbnail view (corner view) - only for viewers (hosts should never see remote video)
                      if (!widget.isHost && _localPreviewReady)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 100, // Position below top bar elements
                          right: 16,
                          width: 100,
                          height: 140,
                          child: GestureDetector(
                            onTap: () {
                              // Also swap when tapping thumbnail
                              setState(() {
                                _isViewsSwapped = !_isViewsSwapped;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _isViewsSwapped
                                  ? (widget.isHost ? _localVideo() : _remoteVideo()) // Swapped: host always shows local, viewer shows remote
                                  : (widget.isHost ? _localVideo() : _localVideo()), // Normal: host shows local, viewer shows local in thumbnail
                            ),
                          ),
                        ),
                    
                    // ========== HOST UI ==========
                    if (widget.isHost && _localUserJoined) ...[
                      // Status indicator overlay (for host)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Viewer count overlay (only for host)
                      if (widget.streamId != null)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 90, // Position next to LIVE badge
                          child: _buildViewerCount(),
                        ),
                      
                      // Camera toggle and Mute buttons (only for host) - below top bar on right
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 60, // More padding from top
                        right: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mute button
                            _buildMuteButton(),
                            const SizedBox(height: 8),
                            // Camera toggle button
                            _buildCameraToggleButtons(),
                          ],
                        ),
                      ),
                      
                      // Old host chat panel removed - using new chat system
                      
                      // Group icon and Close button overlay (top right) - for host
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Group icon (viewer list)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (widget.streamId != null) {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      isDismissible: true,
                                      enableDrag: true,
                                      barrierColor: Colors.black.withValues(alpha: 0.3),
                                      builder: (context) => GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                        child: Container(
                                          color: Colors.transparent,
                                          child: SafeArea(
                                            child: Align(
                                              alignment: Alignment.bottomCenter,
                                              child: GestureDetector(
                                                onTap: () {}, // Prevent tap from closing when tapping on sheet
                                                child: Container(
                                                  height: MediaQuery.of(context).size.height * 0.5,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                                                  ),
                                                  child: ViewerListSheet(
                                                    streamId: widget.streamId!,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Stream information not available'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Close button
                            Container(
                              width: 32,
                              height: 32,
                          decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () async {
                              debugPrint('❌ Close button pressed - cleaning up...');
                              await _cleanupAgoraEngine();
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Chat Input Panel (always visible for host)
                      if (widget.streamId != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 32, // Adjust for keyboard with more padding
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _chatMessageController,
                                      focusNode: _chatFocusNode,
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                      decoration: InputDecoration(
                                        hintText: 'Type a message...',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 10,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                      ),
                                      onSubmitted: (_) {
                                        _sendChatMessage();
                                        _chatMessageController.clear();
                                      },
                                      onTap: () {
                                        // Ensure keyboard stays open when tapping input
                                        _chatFocusNode.requestFocus();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white, size: 14),
                                    onPressed: () {
                                      _sendChatMessage();
                                      _chatMessageController.clear();
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ),
                    ],
                    
                    // ========== VIEWER UI ==========
                    if (!widget.isHost && _localUserJoined && widget.streamId != null) ...[
                      // Call status overlay (when host is in call)
                      if (_isHostInCall)
                        Positioned.fill(
                          child: const CallStatusOverlay(),
                        ),
                      
                      // Pink Header Bar Background (full width at top) - Only on phones
                      if (MediaQuery.of(context).size.shortestSide < 600) // Phone check (tablets/desktop >= 600)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                          child: Container(
                              height: MediaQuery.of(context).padding.top, // Match system status bar height only
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF1B7C), // Solid pink color instead of gradient
                            ),
                          ),
                        ),
                      
                      // Top Bar - Left Side (Host info bar)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: _buildViewerTopBarLeft(),
                      ),
                      
                      // Top Bar - Right Side (Group icon + Close button)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: _buildViewerTopBarRight(),
                      ),
                      
                      // Call request popup (left side of screen, just below top bar, slides in from left)
                      if (_isCallRequestPending && !widget.isHost)
                        Positioned(
                          left: 16,
                          top: MediaQuery.of(context).padding.top + 80, // More space below top bar
                          child: _buildCallRequestPopup(),
                        ),
                      
                      // Call rejected popup (left side, just below calling popup)
                      if (_isCallRejected && !widget.isHost)
                        Positioned(
                          left: 16,
                          top: MediaQuery.of(context).padding.top + 130, // Just below calling popup
                          child: _buildCallRejectedPopup(),
                        ),
                      
                      // CRAZY SALE Promotional Overlay (middle-right, vertically oriented)
                      if (_showPromoOverlay && !widget.isHost)
                        Positioned(
                          right: 16,
                          top: MediaQuery.of(context).size.height * 0.42, // Middle-right position
                          child: SlideInRight(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5722), // Reddish-orange top
                                    Color(0xFFFF9800), // Orange middle
                                    Color(0xFFFFC107), // Yellowish-orange bottom
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.6),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Close button (top-right)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showPromoOverlay = false;
                                          });
                                        },
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // CRAZY SALE text (bold, uppercase, white)
                                  const Text(
                                    'CRAZY SALE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black38,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Timer (monospaced font for alignment)
                                  ValueListenableBuilder<Duration>(
                                    valueListenable: _promoDurationNotifier,
                                    builder: (context, duration, child) {
                                      final hours = duration.inHours.toString().padLeft(2, '0');
                                      final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
                                      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
                                      return Text(
                                        '$hours:$minutes:$seconds',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                          letterSpacing: 0.5,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      // Admin Message Popup (bottom-left, above bottom icons - shows when user joins)
                      if (_currentAdminMessage != null && !widget.isHost)
                        Positioned(
                          left: 16,
                          bottom: 100, // Above bottom icons
                          child: _buildAdminMessageContent(),
                        ),
                      
                      // Live Streaming Chat removed - only chat icon is shown on viewer screen
                      // Chat bubbles are not displayed on viewer screen
                      
                      // Chat Input Panel (shows when chat icon is tapped)
                      if (_isChatOpen && !widget.isHost && widget.streamId != null)
                        Builder(
                          builder: (context) {
                            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                            final safeAreaBottom = MediaQuery.of(context).padding.bottom;
                            const bottomIconsHeight = 60.0;
                            const spacing = 8.0;
                            
                            // Calculate bottom position: above keyboard if visible, otherwise above bottom icons
                            // Bottom icons are now at bottom: 0 with SafeArea, so they're at safeAreaBottom + bottomIconsHeight
                            final chatInputBottom = keyboardHeight > 0
                                ? keyboardHeight + spacing
                                : safeAreaBottom + bottomIconsHeight + spacing;
                            
                            return Positioned(
                              left: 16,
                              right: 16,
                              bottom: chatInputBottom, // Adjust for keyboard and bottom icons
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _chatMessageController,
                                    focusNode: _chatFocusNode,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    onSubmitted: (_) {
                                      _sendChatMessage();
                                      setState(() {
                                        _isChatOpen = false;
                                      });
                                      _chatFocusNode.unfocus();
                                    },
                                    onTap: () {
                                      // Ensure keyboard stays open when tapping input
                                      _chatFocusNode.requestFocus();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                  onPressed: () {
                                    _sendChatMessage();
                                    setState(() {
                                      _isChatOpen = false;
                                    });
                                    _chatFocusNode.unfocus();
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                            );
                          },
                        ),
                      
                      // Bottom icon row (Chat, Start Video Chat, Gift) - Fixed position
                      if (!widget.isHost && widget.streamId != null)
                        Positioned(
                          bottom: 0, // No bottom padding - keep at bottom
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            top: false,
                            bottom: true, // Enable bottom safe area to respect device notches
                            child: _buildViewerBottomIconsRow(),
                          ),
                        ),
                      
                    ], // Close spread operator list from line 4003
                    ], // Close Stack children list from line 3728
                ),
              ),
            ),
          ),
    );
  }

}

// Profile Bottom Sheet Widget
class _ProfileBottomSheet extends StatefulWidget {
  final UserModel user;
  final String? hostPhotoUrl;
  final bool isFollowing;
  final VoidCallback onFollowTap;
  final VoidCallback onProfileTap;
  final VoidCallback onReportTap;
  final VoidCallback onVideoChatTap;
  final VoidCallback onMessageTap;

  const _ProfileBottomSheet({
    required this.user,
    this.hostPhotoUrl,
    required this.isFollowing,
    required this.onFollowTap,
    required this.onProfileTap,
    required this.onReportTap,
    required this.onVideoChatTap,
    required this.onMessageTap,
  });

  @override
  State<_ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<_ProfileBottomSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Prevent tap from closing when tapping on sheet
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A), // Dark background
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content with padding for profile
              Padding(
                padding: const EdgeInsets.only(top: 30), // Space for profile extending out (15%)
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // Top Section: Follow, Profile, Report
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left and Right buttons row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Follow Button (Left) - Wider
                              Container(
                                width: 100,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFFF1B7C),
                                    width: 1.5,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: widget.onFollowTap,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          widget.isFollowing ? Icons.check : Icons.add,
                                          color: const Color(0xFFFF1B7C),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          widget.isFollowing ? 'Followed' : 'Follow',
                                          style: const TextStyle(
                                            color: Color(0xFFFF1B7C),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Report Icon (Right)
                              GestureDetector(
                                onTap: widget.onReportTap,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.flag_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                
                const SizedBox(height: 20),
                
                // User Name
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Country
                if (widget.user.country != null && widget.user.country!.isNotEmpty)
                  Text(
                    widget.user.country!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                
                const SizedBox(height: 12),
                
                // Bio
                if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      widget.user.bio!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                const SizedBox(height: 22),
                
                // Action Buttons Row
                Row(
                  children: [
                    // Start Video Chat Button
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1B7C),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF1B7C).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onVideoChatTap,
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
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Message Button
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onMessageTap,
                            borderRadius: BorderRadius.circular(22),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/comment.png',
                                  width: 18,
                                  height: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Message',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
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
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        
        // Profile Picture (Positioned outside - 15% above)
        Positioned(
          top: -14, // 15% of 90px = 13.5px ≈ 14px (extends 15% outside)
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
                              onTap: widget.onProfileTap,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1B7C).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3.5),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: ClipOval(
                                child: (widget.hostPhotoUrl != null && widget.hostPhotoUrl!.isNotEmpty)
                                    ? Image.network(
                                        widget.hostPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                      size: 45,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 45,
                                ),
                              ),
                      ),
                    ),
                    // LIVE Indicator with Animation
                    Positioned(
                      bottom: 2,
                      left: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseAnimation.value,
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
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
      ),
    );
  }
}

