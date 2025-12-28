import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart' hide UserInfo;
import 'package:agora_rtc_engine/agora_rtc_engine.dart' as agora show UserInfo;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/call_request_service.dart';
import '../services/call_coin_deduction_service.dart';

// Agora App ID (same as live stream)
const String agoraAppId = '43bb5e13c835444595c8cf087a0ccaa4';

class PrivateCallScreen extends StatefulWidget {
  final String callChannelName;
  final String callToken;
  final String streamId;
  final String requestId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final bool isHost; // true if host, false if viewer/caller

  const PrivateCallScreen({
    super.key,
    required this.callChannelName,
    required this.callToken,
    required this.streamId,
    required this.requestId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    required this.isHost,
  });

  @override
  State<PrivateCallScreen> createState() => _PrivateCallScreenState();
}

class _PrivateCallScreenState extends State<PrivateCallScreen> {
  // Agora RTC Engine instance
  late RtcEngine _engine;

  // State variables
  bool _localPreviewReady = false;
  int? _remoteUid;
  bool _isLoading = true;
  bool _isMuted = false;
  bool _isVideoEnabled = true; // Always true for video calls
  bool _isFrontCamera = true;
  String? _errorMessage;
  
  // Draggable local video position (absolute position from top-left)
  Offset _localVideoPosition = Offset.zero; // Will be initialized to top-right
  bool _isDraggingLocalVideo = false;
  
  // Video swap state - false = default (remote full, local small), true = swapped (local full, remote small)
  bool _isVideosSwapped = false;

  // Services
  final CallRequestService _callRequestService = CallRequestService();
  final CallCoinDeductionService _coinDeductionService = CallCoinDeductionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Timer and coin deduction state
  Timer? _callTimer;
  Timer? _deductionTimer;
  int _callDurationSeconds = 0;
  int _totalCoinsDeducted = 0;
  int _userBalance = 0;
  bool _isDeducting = false;
  bool _lowBalanceWarning = false;
  int _lastDeductionMinute = -1; // Track which minute we last deducted
  
  // Real-time balance listener
  StreamSubscription<DocumentSnapshot>? _balanceSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
    // Only start timer and deduction if caller (not host)
    if (!widget.isHost) {
      _startCallTimer();
      _loadUserBalance();
      _setupRealtimeBalanceListener();
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _deductionTimer?.cancel();
    _balanceSubscription?.cancel();
    _cleanupAgoraEngine();
    super.dispose();
  }
  
  /// Setup real-time balance listener (PRIMARY - updates immediately when coins are deducted)
  void _setupRealtimeBalanceListener() {
    if (widget.isHost) return;
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    debugPrint('🔄 PrivateCall: Setting up real-time balance listener for user: $userId');
    
    // Listen to users collection uCoins field (PRIMARY SOURCE OF TRUTH)
    _balanceSubscription = _firestore
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
            debugPrint('📡 PrivateCall: Real-time balance update: $_userBalance → $newBalance');
            setState(() {
              _userBalance = newBalance;
            });
            
            // Auto-end call if insufficient balance
            if (newBalance < 1000 && !_lowBalanceWarning) {
              _autoEndCallDueToInsufficientBalance();
            }
            
            // Update low balance warning state
            if (newBalance < 1000 && !_lowBalanceWarning) {
              setState(() {
                _lowBalanceWarning = true;
              });
              _showLowBalanceWarning();
            } else if (newBalance >= 1000 && _lowBalanceWarning) {
              setState(() {
                _lowBalanceWarning = false;
              });
            }
          }
        }
      },
      onError: (error) {
        debugPrint('❌ PrivateCall: Error in balance listener: $error');
      },
    );
  }
  
  /// Load user's current balance (initial load)
  Future<void> _loadUserBalance() async {
    if (widget.isHost) return;
    
    try {
      final balance = await _coinDeductionService.getUserBalance(_auth.currentUser!.uid);
      if (mounted) {
        setState(() {
          _userBalance = balance;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user balance: $e');
    }
  }
  
  /// Start call timer and deduction logic
  void _startCallTimer() {
    if (widget.isHost) return;
    
    // Update timer every second
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
        
        // Real-time balance updates are handled by StreamBuilder listener
        // No need to check balance periodically anymore
        
        // Show low balance warning at 30 seconds before running out
        final minutesRemaining = (_userBalance / 1000).floor();
        if (minutesRemaining <= 1 && _userBalance < 1000 && !_lowBalanceWarning) {
          setState(() {
            _lowBalanceWarning = true;
          });
          _showLowBalanceWarning();
        }
      }
    });
    
    // Deduct coins every minute
    _deductionTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      await _deductMinute();
    });
    
    // Initial deduction check (for first minute)
    Future.delayed(const Duration(seconds: 1), () {
      _deductMinute(); // Deduct immediately when call starts
    });
  }
  
  
  /// Deduct coins for current minute
  Future<void> _deductMinute() async {
    if (widget.isHost || _isDeducting) return;
    
    final currentMinute = (_callDurationSeconds / 60).floor();
    
    // Skip if we already deducted for this minute
    if (currentMinute <= _lastDeductionMinute) {
      return;
    }
    
    setState(() {
      _isDeducting = true;
    });
    
    try {
      final success = await _coinDeductionService.deductCallMinute(
        callerId: _auth.currentUser!.uid,
        hostId: widget.otherUserId,
        callRequestId: widget.requestId,
        streamId: widget.streamId,
      );
      
      if (success) {
        if (mounted) {
          setState(() {
            _totalCoinsDeducted += 1000;
            _lastDeductionMinute = currentMinute;
            _userBalance -= 1000;
          });
        }
        
        debugPrint('✅ Deducted 1000 coins for minute ${currentMinute + 1}');
      } else {
        debugPrint('❌ Failed to deduct coins - insufficient balance');
        _autoEndCallDueToInsufficientBalance();
      }
    } catch (e) {
      debugPrint('❌ Error deducting minute: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDeducting = false;
        });
      }
    }
  }
  
  /// Show low balance warning
  void _showLowBalanceWarning() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Low balance! Call will end automatically when coins run out.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Auto-end call due to insufficient balance
  Future<void> _autoEndCallDueToInsufficientBalance() async {
    if (!mounted) return;
    
    // Deduct partial minute before ending
    final partialSeconds = _callDurationSeconds % 60;
    if (partialSeconds > 0 && _lastDeductionMinute < (_callDurationSeconds / 60).floor()) {
      await _deductPartialMinute(partialSeconds);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Insufficient balance. Call ended.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // End call
      await _endCall();
    }
  }
  
  /// Deduct coins for partial minute
  Future<void> _deductPartialMinute(int durationSeconds) async {
    if (widget.isHost || durationSeconds <= 0) return;
    
    try {
      final success = await _coinDeductionService.deductPartialMinute(
        callerId: _auth.currentUser!.uid,
        hostId: widget.otherUserId,
        callRequestId: widget.requestId,
        durationSeconds: durationSeconds,
        streamId: widget.streamId,
      );
      
      if (success) {
        final coinsToDeduct = ((durationSeconds / 60) * 1000).round();
        if (mounted) {
          setState(() {
            _totalCoinsDeducted += coinsToDeduct;
            _userBalance -= coinsToDeduct;
          });
        }
        debugPrint('✅ Deducted $coinsToDeduct coins for partial minute ($durationSeconds seconds)');
      }
    } catch (e) {
      debugPrint('❌ Error deducting partial minute: $e');
    }
  }
  
  /// Format duration as MM:SS
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Initialize Agora RTC Engine
  Future<void> _initializeAgora() async {
    try {
      setState(() => _isLoading = true);

      // Request permissions
      await [Permission.microphone, Permission.camera].request();

      // CRITICAL: Leave any existing channel first to avoid error -17
      // This is especially important for hosts who are already in a live stream channel
      try {
        // Try to leave any existing channel (if engine exists from previous session)
        // Note: We create a new engine, but if there's a global state issue, this helps
        debugPrint('📞 Initializing private call - ensuring clean state...');
      } catch (e) {
        debugPrint('ℹ️ No existing channel to leave: $e');
      }

      // Create engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      
      // CRITICAL: Ensure we're not in any channel before joining
      try {
        await _engine.leaveChannel();
        await Future.delayed(const Duration(milliseconds: 300));
        debugPrint('✅ Ensured clean channel state');
      } catch (e) {
        debugPrint('ℹ️ No channel to leave (expected for new engine): $e');
      }

      // Register event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Joined private call channel: ${connection.channelId}');
            debugPrint('   Local UID: ${connection.localUid}');
            setState(() {
              _isLoading = false;
            });
            
            // Note: onUserJoined will fire when remote user joins
            // If remote user already joined, onUserJoined should have fired before this
            // But we'll handle it in onUserJoined callback
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('👤 Remote user joined: $remoteUid');
            debugPrint('   Connection channel: ${connection.channelId}');
            debugPrint('   Local UID: ${connection.localUid}');
            debugPrint('   Elapsed time: ${elapsed}ms');
            
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
              });
              
              // CRITICAL: Enable remote video/audio immediately
              // Try multiple times to ensure it works
              Future.delayed(const Duration(milliseconds: 100), () async {
                try {
                  await _engine.muteRemoteVideoStream(uid: remoteUid, mute: false);
                  await _engine.muteRemoteAudioStream(uid: remoteUid, mute: false);
                  debugPrint('✅ Step 1: Enabled remote video/audio for UID: $remoteUid');
                  
                  // Try again after a delay to ensure subscription
                  Future.delayed(const Duration(milliseconds: 500), () async {
                    try {
                      await _engine.muteRemoteVideoStream(uid: remoteUid, mute: false);
                      await _engine.muteRemoteAudioStream(uid: remoteUid, mute: false);
                      debugPrint('✅ Step 2: Re-enabled remote video/audio for UID: $remoteUid');
                      
                      if (mounted) {
                        setState(() {
                          // Force UI refresh
                        });
                      }
                    } catch (e) {
                      debugPrint('❌ Error in step 2: $e');
                    }
                  });
                } catch (e) {
                  debugPrint('❌ Error enabling remote video: $e');
                }
              });
            }
          },
          onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUid, int width, int height, int elapsed) {
            debugPrint('📹 First remote video frame received: $remoteUid (${width}x${height})');
            if (mounted) {
              setState(() {
                // Force UI update when first frame arrives
              });
            }
          },
          onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
            debugPrint('📹 Remote video state changed: UID=$remoteUid, State=$state, Reason=$reason');
            if (state == RemoteVideoState.remoteVideoStateStarting || 
                state == RemoteVideoState.remoteVideoStateDecoding) {
              debugPrint('✅ Remote video is starting/decoding');
            } else if (state == RemoteVideoState.remoteVideoStateStopped) {
              debugPrint('⚠️ Remote video stopped');
            }
          },
          onUserInfoUpdated: (int remoteUid, agora.UserInfo userInfo) {
            debugPrint('👤 User info updated: $remoteUid');
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('👤 Remote user left: $remoteUid');
            setState(() {
              _remoteUid = null;
            });
            // Auto-end call if remote user leaves
            _endCall();
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Agora error: $err - $msg');
            setState(() {
              _errorMessage = 'Error: $msg';
              _isLoading = false;
            });
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('👋 Left private call channel');
            setState(() {
              _remoteUid = null;
            });
          },
        ),
      );

      // Enable video
      await _engine.enableVideo();
      await _engine.startPreview();
      
      // Enable remote video subscription by default
      // Note: autoSubscribeVideo in ChannelMediaOptions handles this
      debugPrint('✅ Remote video/audio will auto-subscribe via ChannelMediaOptions');

      // Set video encoder configuration
      await _engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 400,
          orientationMode: OrientationMode.orientationModeFixedPortrait,
        ),
      );

      // Enable local video
      await _engine.enableLocalVideo(true);
      await _engine.muteLocalAudioStream(_isMuted);

      setState(() => _localPreviewReady = true);

      // Join channel
      // Generate UID from user ID hash (to avoid parsing errors with non-hex strings)
      final userId = _auth.currentUser!.uid;
      final uid = userId.hashCode.abs() % 100000; // Use hash code to generate numeric UID
      
      debugPrint('📞 Joining private call channel: ${widget.callChannelName} with UID: $uid');
      
      // Final check: ensure we're not in a channel before joining
      try {
        await _engine.leaveChannel();
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        // Ignore - might not be in a channel
        debugPrint('ℹ️ Pre-join leave check: $e');
      }
      
      // Use token, or fallback to hardcoded token if empty
      final tokenToUse = widget.callToken.isNotEmpty
          ? widget.callToken
          : '007eJxTYNj7OUCHa4mdwceXM39cEojtKmgI+l99e9HCbq0mhbMloX8VGEyMk5JMUw2Nky2MTU1MTEwtTZMtktMMLMwTDZKTExNNlj/WzmwIZGSQmnqemZEBAkF8dobkjMTcxOwqBgYANxgiaQ==';
      
      debugPrint('📞 Using token length: ${tokenToUse.length}');
      
      await _engine.joinChannel(
        token: tokenToUse,
        channelId: widget.callChannelName,
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          autoSubscribeVideo: true, // Automatically subscribe to remote video
          autoSubscribeAudio: true, // Automatically subscribe to remote audio
          publishCameraTrack: true, // CRITICAL: Publish camera track
          publishMicrophoneTrack: true, // CRITICAL: Publish microphone track
        ),
      );
      
      debugPrint('📞 Joined channel with publishCameraTrack: true, publishMicrophoneTrack: true');
    } catch (e) {
      debugPrint('❌ Error initializing Agora: $e');
      setState(() {
        _errorMessage = 'Failed to initialize call: $e';
        _isLoading = false;
      });
    }
  }

  // Cleanup Agora engine
  Future<void> _cleanupAgoraEngine() async {
    try {
      await _engine.leaveChannel();
      await _engine.stopPreview();
      await _engine.disableVideo();
      await _engine.release();
      debugPrint('✅ Agora engine cleaned up');
    } catch (e) {
      debugPrint('❌ Error cleaning up Agora: $e');
    }
  }

  // Toggle mute/unmute
  Future<void> _toggleMute() async {
    try {
      await _engine.muteLocalAudioStream(!_isMuted);
      setState(() => _isMuted = !_isMuted);
      debugPrint('🔇 Microphone ${_isMuted ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('❌ Error toggling mute: $e');
    }
  }

  // Toggle video on/off
  Future<void> _toggleVideo() async {
    try {
      await _engine.enableLocalVideo(!_isVideoEnabled);
      setState(() => _isVideoEnabled = !_isVideoEnabled);
      debugPrint('📹 Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Error toggling video: $e');
    }
  }

  // Switch camera
  Future<void> _switchCamera() async {
    try {
      await _engine.switchCamera();
      setState(() => _isFrontCamera = !_isFrontCamera);
      debugPrint('📷 Camera switched');
    } catch (e) {
      debugPrint('❌ Error switching camera: $e');
    }
  }

  // Toggle video swap (swap local and remote video positions)
  void _toggleVideoSwap() {
    setState(() {
      _isVideosSwapped = !_isVideosSwapped;
    });
    debugPrint('🔄 Videos swapped: ${_isVideosSwapped ? "Local full, Remote small" : "Remote full, Local small"}');
  }

  // End call
  Future<void> _endCall() async {
    try {
      // Cancel timers
      _callTimer?.cancel();
      _deductionTimer?.cancel();
      
      // Deduct partial minute if call ended before full minute
      if (!widget.isHost && _callDurationSeconds > 0) {
        final partialSeconds = _callDurationSeconds % 60;
        final fullMinutes = _callDurationSeconds ~/ 60;
        
        // If we haven't deducted for the last partial minute, deduct it now
        if (partialSeconds > 0 && _lastDeductionMinute < fullMinutes) {
          await _deductPartialMinute(partialSeconds);
        }
      }
      
      // Update call request status and make host available
      await _callRequestService.endCall(
        requestId: widget.requestId,
        streamId: widget.streamId,
      );

      // Navigate back
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error ending call: $e');
      // Still navigate back even if update fails
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _endCall,
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Only swap if remote user has joined
            if (_remoteUid != null) {
              _toggleVideoSwap();
            }
          },
          child: Stack(
            children: [
              // Full screen video (remote or local based on swap state)
              if (_remoteUid != null)
                // Remote user has joined - show based on swap state
                Positioned.fill(
                  key: ValueKey('fullscreen_${_isVideosSwapped ? "local" : "remote"}'),
                  child: Container(
                    color: Colors.black,
                    child: _isVideosSwapped
                        // Swapped: Local video full screen
                        ? (_localPreviewReady && _isVideoEnabled
                            ? AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: _engine,
                                  canvas: const VideoCanvas(uid: 0),
                                ),
                              )
                            : Container(color: Colors.black))
                        // Default: Remote video full screen
                        : AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: _engine,
                              canvas: VideoCanvas(
                                uid: _remoteUid!,
                                renderMode: RenderModeType.renderModeHidden,
                              ),
                              connection: RtcConnection(channelId: widget.callChannelName),
                            ),
                          ),
                  ),
                ),
              if (_localPreviewReady && _isVideoEnabled && _remoteUid == null)
                // No remote user yet - show local video full screen
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
            
            // Waiting overlay (only shown when no remote user and local video not ready)
            if (_remoteUid == null && (!_localPreviewReady || !_isVideoEnabled))
              Positioned.fill(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Other user's profile picture
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            image: widget.otherUserImage != null &&
                                    widget.otherUserImage!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(widget.otherUserImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: widget.otherUserImage == null ||
                                    widget.otherUserImage!.isEmpty
                                ? Colors.white.withValues(alpha: 0.2)
                                : null,
                          ),
                          child: widget.otherUserImage == null ||
                                  widget.otherUserImage!.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 60,
                                )
                              : null,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Connecting...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.otherUserName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Small grid video (local or remote based on swap state) - shown when remote user joins
            if (_remoteUid != null && _localPreviewReady && _isVideoEnabled)
              Builder(
                builder: (context) {
                  // Initialize position to top-right on first render
                  if (_localVideoPosition == Offset.zero) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _localVideoPosition = Offset(screenWidth - 140, 20); // 120 width + 20 padding
                        });
                      }
                    });
                  }
                  
                  // Use right positioning if not initialized, left if dragged
                  final position = _localVideoPosition == Offset.zero
                      ? null
                      : _localVideoPosition.dx;
                  final rightPosition = _localVideoPosition == Offset.zero
                      ? 10.0
                      : null;
                  final topPosition = _localVideoPosition == Offset.zero
                      ? 20.0
                      : _localVideoPosition.dy;
                  
                  return Positioned(
                    left: position,
                    right: rightPosition,
                    top: topPosition,
                    child: GestureDetector(
                      onTap: () {
                        // Prevent tap from propagating to parent (which would swap)
                        // Allow dragging but not swapping on tap of small video
                      },
                      onPanStart: (details) {
                        setState(() {
                          _isDraggingLocalVideo = true;
                          // Convert from right-based to left-based positioning when dragging starts
                          if (_localVideoPosition == Offset.zero) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            _localVideoPosition = Offset(screenWidth - 110, 20); // 100 width + 10 padding
                          }
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final screenHeight = MediaQuery.of(context).size.height;
                          const videoWidth = 100.0;
                          const videoHeight = 130.0;
                          const padding = 20.0;
                          
                          // Get current position (convert from right if needed)
                          double currentX = _localVideoPosition == Offset.zero
                              ? screenWidth - 110
                              : _localVideoPosition.dx;
                          double currentY = _localVideoPosition == Offset.zero
                              ? 20.0
                              : _localVideoPosition.dy;
                          
                          // Calculate new position
                          double newX = currentX + details.delta.dx;
                          double newY = currentY + details.delta.dy;
                          
                          // Constrain to screen bounds
                          final minX = padding;
                          final maxX = screenWidth - videoWidth - padding;
                          final minY = padding;
                          final maxY = screenHeight - videoHeight - padding;
                          
                          _localVideoPosition = Offset(
                            newX.clamp(minX, maxX),
                            newY.clamp(minY, maxY),
                          );
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _isDraggingLocalVideo = false;
                        });
                      },
                      child: Container(
                        width: 100,
                        height: 130,
                        decoration: _isDraggingLocalVideo
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: const [Color(0xFFFF69B4), Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF1B7C).withValues(alpha: 0.6),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
                                ],
                              )
                            : BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                        child: Container(
                          margin: _isDraggingLocalVideo ? const EdgeInsets.all(2) : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _isVideosSwapped
                              // Swapped: Show remote video in small grid
                              ? AgoraVideoView(
                                  controller: VideoViewController.remote(
                                    rtcEngine: _engine,
                                    canvas: VideoCanvas(
                                      uid: _remoteUid!,
                                      renderMode: RenderModeType.renderModeFit,
                                    ),
                                    connection: RtcConnection(channelId: widget.callChannelName),
                                  ),
                                )
                              // Default: Show local video in small grid
                              : AgoraVideoView(
                                  controller: VideoViewController(
                                    rtcEngine: _engine,
                                    canvas: const VideoCanvas(uid: 0),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Loading indicator
            if (_isLoading)
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),

            // Top bar with other user info
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile picture
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: widget.otherUserImage != null &&
                                widget.otherUserImage!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(widget.otherUserImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: widget.otherUserImage == null ||
                                widget.otherUserImage!.isEmpty
                            ? Colors.white.withValues(alpha: 0.2)
                            : null,
                      ),
                      child: widget.otherUserImage == null ||
                              widget.otherUserImage!.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Name
                    Text(
                      widget.otherUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Call timer and coin info (only for caller, not host)
            if (!widget.isHost)
              Positioned(
                top: 80,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timer display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _lowBalanceWarning ? Colors.orange : Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_callDurationSeconds),
                            style: TextStyle(
                              color: _lowBalanceWarning ? Colors.orange : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [const FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Coins info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Used: ${NumberFormat.decimalPattern().format(_totalCoinsDeducted)} coins',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                color: _userBalance < 1000 ? Colors.orange : Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Balance: ${NumberFormat.decimalPattern().format(_userBalance)} coins',
                                style: TextStyle(
                                  color: _userBalance < 1000 ? Colors.orange : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: _userBalance < 1000 ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Low balance warning banner
                    if (_lowBalanceWarning)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Low balance! Call will end when coins run out.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Bottom controls
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted ? Colors.red : Colors.white.withValues(alpha: 0.2),
                  ),
                  // Video toggle button
                  _buildControlButton(
                    icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    onPressed: _toggleVideo,
                    backgroundColor: _isVideoEnabled
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.red,
                  ),
                  // Switch camera button
                  _buildControlButton(
                    icon: Icons.flip_camera_ios,
                    onPressed: _switchCamera,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    size: 60,
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 50,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

