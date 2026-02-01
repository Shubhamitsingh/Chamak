import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animate_do/animate_do.dart';
import 'package:country_picker/country_picker.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/call_request_model.dart';
import '../services/follow_service.dart';
import '../services/chat_service.dart';
import '../services/online_status_service.dart';
import '../services/call_request_service.dart';
import '../services/agora_token_service.dart';
import '../services/database_service.dart';
import '../widgets/gift_selection_sheet.dart';
import '../widgets/call_request_dialog.dart';
import 'chat_screen.dart';
import 'private_call_screen.dart';

class UserProfileViewScreen extends StatefulWidget {
  final UserModel user;

  const UserProfileViewScreen({super.key, required this.user});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> with SingleTickerProviderStateMixin {
  final FollowService _followService = FollowService();
  final ChatService _chatService = ChatService();
  final OnlineStatusService _onlineStatusService = OnlineStatusService();
  final CallRequestService _callRequestService = CallRequestService();
  final AgoraTokenService _tokenService = AgoraTokenService();
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isFollowing = false;
  bool _isLoading = true;
  int _followersCount = 0;
  int _followingCount = 0;
  
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Call request state
  String? _currentCallRequestId;
  bool _isCallRequestPending = false; // Track if call request is pending
  bool _isCallRejected = false; // Track if call was rejected
  StreamSubscription<List<CallRequestModel>>? _incomingCallSubscription;
  StreamSubscription<CallRequestModel?>? _callStatusSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _setupIncomingCallListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomingCallSubscription?.cancel();
    _callStatusSubscription?.cancel();
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
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to start a chat'),
            backgroundColor: Colors.red,
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
        child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
      ),
    );

    try {
      // Get current user data
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      // If user document doesn't exist, create it with basic data
      if (!currentUserDoc.exists || currentUserDoc.data() == null) {
        debugPrint('📝 User document not found, creating basic profile...');
        
        // Get phone number from Firebase Auth
        final phoneNumber = currentUser.phoneNumber ?? '';
        String countryCode = '+91'; // Default to India
        String cleanPhone = '';
        
        if (phoneNumber.isNotEmpty) {
          // Extract country code (everything before last 10 digits)
          if (phoneNumber.startsWith('+')) {
            if (phoneNumber.length > 10) {
              countryCode = phoneNumber.substring(0, phoneNumber.length - 10);
              cleanPhone = phoneNumber.substring(phoneNumber.length - 10);
            } else {
              cleanPhone = phoneNumber.substring(1); // Remove +
            }
          } else {
            // No + prefix, assume it's just the number
            cleanPhone = phoneNumber.length > 10 
                ? phoneNumber.substring(phoneNumber.length - 10)
                : phoneNumber;
          }
        }
        
        // Create basic user document using DatabaseService method
        try {
          await _databaseService.createOrUpdateUser(
            phoneNumber: cleanPhone,
            countryCode: countryCode,
          );
        } catch (dbError) {
          debugPrint('⚠️ Error using DatabaseService, creating manually: $dbError');
          // Fallback: Create manually if DatabaseService fails
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'userId': currentUser.uid,
            'phoneNumber': cleanPhone,
            'countryCode': countryCode,
            'displayName': null, // Will be set when profile is completed
            'photoURL': null, // Will be set when profile is completed
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'isActive': false, // New users need admin approval
            'followersCount': 0,
            'followingCount': 0,
            'level': 1,
          }, SetOptions(merge: true));
        }
        
        // Re-fetch the document
        currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        debugPrint('✅ User document created successfully');
      }
      
      final currentUserModel = UserModel.fromFirestore(currentUserDoc);

      // Use fallback values for chat participant names
      // If displayName is null or 'User', use phone number or userId as fallback
      String currentUserName = currentUserModel.displayName ?? 
          (currentUserModel.phoneNumber.isNotEmpty 
              ? '${currentUserModel.countryCode}${currentUserModel.phoneNumber}' 
              : currentUser.uid.substring(0, 8));
      
      String otherUserName = widget.user.displayName ?? 
          (widget.user.phoneNumber.isNotEmpty 
              ? '${widget.user.countryCode}${widget.user.phoneNumber}' 
              : widget.user.uid.substring(0, 8));

      // Create UserModel with fallback names for chat creation
      final currentUserForChat = currentUserModel.copyWith(
        displayName: currentUserName,
      );
      
      final otherUserForChat = widget.user.copyWith(
        displayName: otherUserName,
      );

      // Create or get chat (now works with any logged-in user)
      final chatId = await _chatService.createOrGetChat(currentUserForChat, otherUserForChat);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Small delay to ensure chat document is fully committed to Firestore
      // This prevents permission errors when ChatScreen tries to listen to messages
      await Future.delayed(const Duration(milliseconds: 300));

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
      debugPrint('❌ Error opening chat: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        debugPrint('❌ Firebase error code: ${e.code}');
        debugPrint('❌ Firebase error message: ${e.message}');
      }
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      String errorMessage = 'Failed to open chat. Please try again.';
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          errorMessage = 'Unable to create chat. Please try again later.';
        } else if (e.code == 'unavailable') {
          errorMessage = 'Service temporarily unavailable. Please try again later.';
        } else if (e.code == 'network-request-failed') {
          errorMessage = 'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Failed to open chat: ${e.message ?? e.code}';
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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

      // Update earnings for recipient (SINGLE SOURCE OF TRUTH)
      // NOTE: Only update earnings.totalCCoins, not users.cCoins (to avoid duplicate field issues)
      // Convert U Coins to C Coins: giftCost × 5 = C Coins
      final cCoinsToCredit = giftCost * 5; // 1 U Coin = 5 C Coins
      final earningsRef = _firestore.collection('earnings').doc(widget.user.uid);
      await earningsRef.set({
        'userId': widget.user.uid,
        'totalCCoins': FieldValue.increment(cCoinsToCredit),
        'totalGiftsReceived': FieldValue.increment(1),
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

  // Setup incoming call listener for chat calls
  void _setupIncomingCallListener() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _incomingCallSubscription = _callRequestService
        .listenToIncomingChatCallRequests(currentUserId)
        .listen((requests) {
      if (requests.isNotEmpty && mounted) {
        final request = requests.first;
        _showIncomingCallDialog(request);
      }
    });
  }

  // Initiate video call from profile
  Future<void> _initiateVideoCall() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to start a video call'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if calling yourself
    if (currentUser.uid == widget.user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot call yourself'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Request permissions
    if (!mounted) return;
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied || micStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and microphone permissions are required for video calls'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enable camera and microphone permissions in app settings'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
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
        child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
      ),
    );

    try {
      // Get current user data
      final userData = await _databaseService.getUserData(currentUser.uid);
      final callerName = userData?.displayName ?? userData?.name ?? currentUser.displayName ?? 'User';
      final callerImage = userData?.photoURL ?? currentUser.photoURL;

      // Create call request
      final requestId = await _callRequestService.sendChatCallRequest(
        callerId: currentUser.uid,
        callerName: callerName,
        callerImage: callerImage,
        receiverId: widget.user.uid,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      setState(() {
        _currentCallRequestId = requestId;
        _isCallRequestPending = true; // Show calling popup
        _isCallRejected = false; // Reset rejected state
      });

      // Listen for call request status (accepted/rejected)
      _callStatusSubscription?.cancel(); // Cancel previous subscription if any
      _callStatusSubscription = _callRequestService
          .listenToCallRequestStatus(requestId)
          .listen((callRequest) async {
        if (callRequest == null || !mounted) return;

        if (callRequest.status == 'accepted') {
          // Call accepted - navigate to call screen
          _callStatusSubscription?.cancel();
          
          if (!mounted) return;
          
          setState(() {
            _isCallRequestPending = false;
            _currentCallRequestId = null;
          });
          
          final callChannelName = callRequest.callChannelName ?? 'private_call_$requestId';
          final callToken = callRequest.callToken;
          
          if (callToken == null || callToken.isEmpty) {
            // Generate token if not available
            try {
              final generatedToken = await _tokenService.getHostToken(
                channelName: callChannelName,
              );
              
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivateCallScreen(
                      callChannelName: callChannelName,
                      callToken: generatedToken,
                      streamId: '', // Empty for chat calls
                      requestId: requestId,
                      otherUserId: widget.user.uid,
                      otherUserName: widget.user.name,
                      otherUserImage: widget.user.profileImage,
                      isHost: false, // Caller is not host in chat calls
                    ),
                  ),
                );
              }
            } catch (e) {
              debugPrint('❌ Error generating token: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to start call. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // Token already available
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivateCallScreen(
                    callChannelName: callChannelName,
                    callToken: callToken,
                    streamId: '', // Empty for chat calls
                    requestId: requestId,
                    otherUserId: widget.user.uid,
                    otherUserName: widget.user.name,
                    otherUserImage: widget.user.profileImage,
                    isHost: false, // Caller is not host in chat calls
                  ),
                ),
              );
            }
          }
        } else if (callRequest.status == 'rejected') {
          // Call rejected - show rejected popup
          _callStatusSubscription?.cancel();
          if (mounted) {
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
          }
        } else if (callRequest.status == 'cancelled' || callRequest.status == 'ended') {
          // Call cancelled or ended
          _callStatusSubscription?.cancel();
          if (mounted) {
            setState(() {
              _isCallRequestPending = false;
              _isCallRejected = false;
              _currentCallRequestId = null;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error initiating video call: $e');
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      String errorMessage = 'Failed to start video call. Please try again.';
      if (e.toString().contains('Insufficient')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please check your connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Show incoming call dialog
  void _showIncomingCallDialog(CallRequestModel request) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CallRequestDialog(
        callRequest: request,
        onAccept: () => _handleAcceptCall(request),
        onReject: () => _handleRejectCall(request.requestId),
      ),
    );
  }

  // Handle accept call
  Future<void> _handleAcceptCall(CallRequestModel request) async {
    try {
      // Generate call channel name and token
      final callChannelName = 'private_call_${request.requestId}';
      final callToken = await _tokenService.getHostToken(
        channelName: callChannelName,
      );

      // Accept call request
      await _callRequestService.acceptCallRequest(
        requestId: request.requestId,
        streamId: null, // No streamId for chat calls
        callerId: request.callerId,
        callChannelName: callChannelName,
        callToken: callToken,
      );

      if (!mounted) return;
      
      // Navigate to call screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrivateCallScreen(
            callChannelName: callChannelName,
            callToken: callToken,
            streamId: '', // Empty for chat calls
            requestId: request.requestId,
            otherUserId: request.callerId,
            otherUserName: request.callerName,
            otherUserImage: request.callerImage,
            isHost: true, // Receiver is host (doesn't pay coins)
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
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

  // Handle reject call
  Future<void> _handleRejectCall(String requestId) async {
    try {
      await _callRequestService.rejectCallRequest(requestId);
    } catch (e) {
      debugPrint('❌ Error rejecting call: $e');
    }
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
          : Stack(
              children: [
                // Main Content
                SingleChildScrollView(
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
                                      fontWeight: FontWeight.w700,
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
                                  fontWeight: FontWeight.w700,
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
                                spacing: 4,
                                runSpacing: 3,
                                children: [
                                  // Age
                                  if (widget.user.age != null)
                                    _buildInfoChip('${widget.user.age} yrs'),
                                  // Language
                                  if (widget.user.language != null && widget.user.language!.isNotEmpty)
                                    _buildInfoChip(widget.user.language!),
                                  // Country (with flag emoji)
                                  if (widget.user.country != null && widget.user.country!.isNotEmpty)
                                    _buildCountryChip(widget.user.country!, widget.user.countryCode),
                                ],
                              ),
                              
                              const SizedBox(height: 6),
                              
                              // Real-time Status Indicator (Always Visible)
                              StreamBuilder<String>(
                                stream: _onlineStatusService.getUserStatusStream(widget.user.uid),
                                builder: (context, snapshot) {
                                  final status = snapshot.data ?? 'offline';
                                  
                                  // Determine status color and text (only Online/Offline)
                                  Color statusColor;
                                  String statusText;
                                  bool showDot;
                                  
                                  if (status == 'online') {
                                    // User is online (within 5 minutes)
                                    statusColor = const Color(0xFF4CAF50); // Green
                                    statusText = 'Online';
                                    showDot = true;
                                  } else {
                                    // User is offline
                                    statusColor = Colors.grey[600]!; // Gray for offline
                                    statusText = 'Offline';
                                    showDot = false; // No dot for offline
                                  }
                                  
                                  return Row(
                                    children: [
                                      // Status Dot (only show for Online)
                                      if (showDot)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      if (showDot) const SizedBox(width: 4),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: statusColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
                                      fontWeight: FontWeight.w400,
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
                          onTap: _initiateVideoCall,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
                                                    fontWeight: FontWeight.w700,
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
                                        fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w700,
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
          
                // Call request popup (top-left side, similar to live stream screen)
                if (_isCallRequestPending)
                  Positioned(
                    left: 16,
                    top: MediaQuery.of(context).padding.top + 80,
                    child: _buildCallRequestPopup(),
                  ),
                
                // Call rejected popup (top-left, just below calling popup)
                if (_isCallRejected)
                  Positioned(
                    left: 16,
                    top: MediaQuery.of(context).padding.top + 130,
                    child: _buildCallRejectedPopup(),
                  ),
              ],
            ),
    );
  }

  // Build call request popup (shows "Calling" when request is pending)
  Widget _buildCallRequestPopup() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final callerPhotoUrl = currentUser?.photoURL;
    
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Caller profile icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipOval(
                  child: callerPhotoUrl != null && callerPhotoUrl.isNotEmpty
                      ? Image.network(
                          callerPhotoUrl,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              // Receiver profile icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipOval(
                  child: widget.user.profileImage.isNotEmpty
                      ? Image.network(
                          widget.user.profileImage,
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
                          child: Text(
                            widget.user.name.isNotEmpty 
                                ? widget.user.name[0].toUpperCase() 
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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
        ),
      ),
    );
  }

  // Build call rejected popup (shows "User declined" when call is rejected)
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
                'User declined call',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
            fontWeight: FontWeight.w700,
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

  // Build info chip for Age, Language
  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
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

  // Build country chip with flag emoji
  Widget _buildCountryChip(String countryName, String countryCode) {
    // Get flag emoji from country code or country name
    String flagEmoji = _getFlagEmoji(countryCode, countryName);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flag emoji
          if (flagEmoji.isNotEmpty)
            Text(
              flagEmoji,
              style: const TextStyle(fontSize: 12),
            ),
          if (flagEmoji.isNotEmpty) const SizedBox(width: 3),
          // Country name
          Text(
            countryName,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to get flag emoji from country code or country name
  String _getFlagEmoji(String countryCode, String countryName) {
    try {
      // First, try to find country by name (most reliable if country name is available)
      if (countryName.isNotEmpty) {
        try {
          // Try common country name mappings
          final countryNameMap = {
            'India': 'IN',
            'United States': 'US',
            'United Kingdom': 'GB',
            'Canada': 'CA',
            'Australia': 'AU',
            'United Arab Emirates': 'AE',
            'Singapore': 'SG',
            'Malaysia': 'MY',
            'Pakistan': 'PK',
            'Bangladesh': 'BD',
            'China': 'CN',
            'Japan': 'JP',
            'South Korea': 'KR',
            'Germany': 'DE',
            'France': 'FR',
            'Italy': 'IT',
            'Spain': 'ES',
            'Brazil': 'BR',
            'Mexico': 'MX',
            'Russia': 'RU',
          };
          
          // Check if country name matches any in our map
          String? matchedCode = countryNameMap[countryName];
          if (matchedCode == null) {
            // Try case-insensitive match
            for (var entry in countryNameMap.entries) {
              if (entry.key.toLowerCase() == countryName.toLowerCase()) {
                matchedCode = entry.value;
                break;
              }
            }
          }
          
          if (matchedCode != null) {
            try {
              final country = Country.parse(matchedCode);
              return country.flagEmoji;
            } catch (e) {
              // Fall through to country code method
            }
          }
        } catch (e) {
          // Continue to country code method
        }
      }
      
      // Second, try to parse as ISO country code (2 letters like "IN", "US")
      if (countryCode.isNotEmpty) {
        String code = countryCode.toUpperCase().trim();
        
        // Remove phone code prefix if present (e.g., "+91" -> "91")
        if (code.startsWith('+')) {
          code = code.substring(1);
        }
        
        // If it's a 2-letter code, try to parse directly
        if (code.length == 2 && code.contains(RegExp(r'^[A-Z]{2}$'))) {
          try {
            final country = Country.parse(code);
            return country.flagEmoji;
          } catch (e) {
            // If parsing fails, try Unicode conversion
            return _countryCodeToFlagEmoji(code);
          }
        }
        
        // If countryCode is a phone code (like "91"), try to find country by phone code
        if (code.length <= 3 && code.contains(RegExp(r'^\d+$'))) {
          // Try to find country by phone code using country_picker
          try {
            // Search through common countries
            final commonCountries = ['IN', 'US', 'GB', 'CA', 'AU', 'AE', 'SG', 'MY', 'PK', 'BD', 'CN', 'JP', 'KR', 'DE', 'FR', 'IT', 'ES', 'BR', 'MX', 'RU'];
            for (String isoCode in commonCountries) {
              try {
                final country = Country.parse(isoCode);
                if (country.phoneCode == code) {
                  return country.flagEmoji;
                }
              } catch (e) {
                continue;
              }
            }
          } catch (e) {
            // Continue to fallback
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting flag emoji: $e');
    }
    return ''; // Return empty if unable to get flag
  }

  // Convert 2-letter country code to flag emoji using Unicode
  String _countryCodeToFlagEmoji(String code) {
    if (code.length != 2) return '';
    
    // Validate that it's only letters
    if (!code.contains(RegExp(r'^[A-Z]{2}$'))) return '';
    
    // Unicode regional indicator symbols: A=0x1F1E6, B=0x1F1E7, etc.
    // Flag emoji = regional indicator for first letter + regional indicator for second letter
    try {
      final codePoints = code
          .toUpperCase()
          .split('')
          .map((char) {
            final charCode = char.codeUnitAt(0);
            if (charCode >= 0x41 && charCode <= 0x5A) { // A-Z
              return 0x1F1E6 + (charCode - 0x41);
            }
            return null;
          })
          .where((codePoint) => codePoint != null)
          .cast<int>()
          .toList();
      
      if (codePoints.length == 2) {
        return String.fromCharCodes(codePoints);
      }
    } catch (e) {
      debugPrint('Error converting country code to flag: $e');
    }
    return '';
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
                fontWeight: FontWeight.w400,
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
                      fontWeight: FontWeight.w400,
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
      // Create shareable content with Play Store URL (including user ID)
      final playStoreUrl = 'https://play.google.com/store/apps/details?id=com.chamakz.app&pcampaignid=web_share&userId=${widget.user.uid}';
      final shareText = 'Check out ${widget.user.name}\'s profile on Chamakz!\nDownload the app: $playStoreUrl';
      
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
            fontWeight: FontWeight.w700,
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






































