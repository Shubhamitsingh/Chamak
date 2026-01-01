import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../models/live_stream_model.dart';
import '../services/agora_token_service.dart';

// Agora App ID (same as in agora_live_stream_screen.dart)
const String _appId = '43bb5e13c835444595c8cf087a0ccaa4';

class LiveStreamPreviewCard extends StatefulWidget {
  final LiveStreamModel stream;
  final bool shouldShowPreview; // Whether to show video preview after delay
  final VoidCallback onTap;
  final String? hostPhotoUrl;

  const LiveStreamPreviewCard({
    super.key,
    required this.stream,
    required this.shouldShowPreview,
    required this.onTap,
    this.hostPhotoUrl,
  });

  @override
  State<LiveStreamPreviewCard> createState() => _LiveStreamPreviewCardState();
}

class _LiveStreamPreviewCardState extends State<LiveStreamPreviewCard> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _isVideoReady = false;
  bool _isInitializing = false;
  bool _isDisposed = false;
  Timer? _initTimer;

  // Default gradient background (fallback)
  final BoxDecoration _defaultDecoration = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFF1B7C), // Pink
        Colors.white,      // White
      ],
    ),
    borderRadius: BorderRadius.all(Radius.circular(15)),
  );

  @override
  void initState() {
    super.initState();
    debugPrint('🆕 Preview card created for ${widget.stream.channelName}, shouldShow=${widget.shouldShowPreview}');
    // Initialize video preview when shouldShowPreview becomes true
    if (widget.shouldShowPreview) {
      debugPrint('✅ Initializing preview immediately (shouldShow=true on init)');
      _initializePreview();
    }
  }

  @override
  void didUpdateWidget(LiveStreamPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🔄 Preview card updated for ${widget.stream.channelName}: oldShouldShow=${oldWidget.shouldShowPreview}, newShouldShow=${widget.shouldShowPreview}');
    
    // If shouldShowPreview changed from false to true, initialize preview
    if (!oldWidget.shouldShowPreview && widget.shouldShowPreview) {
      debugPrint('✅ shouldShowPreview changed to true - initializing preview');
      _initializePreview();
    }
    // If stream changed or shouldShowPreview became false, cleanup
    if (oldWidget.stream.streamId != widget.stream.streamId ||
        (!widget.shouldShowPreview && oldWidget.shouldShowPreview)) {
      debugPrint('🧹 Cleaning up preview (stream changed or shouldShow became false)');
      _cleanupEngine();
    }
  }

  Future<void> _initializePreview() async {
    if (_isInitializing || _engine != null || _isDisposed) {
      debugPrint('⚠️ Preview init skipped: isInitializing=$_isInitializing, engine=${_engine != null}, disposed=$_isDisposed');
      return;
    }

    debugPrint('🎬 Starting preview initialization for: ${widget.stream.channelName}');
    setState(() {
      _isInitializing = true;
    });

    try {
      // Small delay to avoid initializing too many engines at once
      await Future.delayed(const Duration(milliseconds: 300));

      if (_isDisposed) {
        debugPrint('⚠️ Preview init cancelled: widget disposed');
        return;
      }

      // Create and initialize Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      if (_isDisposed) {
        await _cleanupEngine();
        return;
      }

      // Enable video for preview
      await _engine!.enableVideo();
      debugPrint('📹 Video enabled for preview: ${widget.stream.channelName}');

      // Set event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Preview joined channel: ${connection.channelId} (${elapsed}ms)');
            if (!_isDisposed && mounted) {
              setState(() {
                _isInitializing = false;
              });
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('👤 Preview: Remote user $remoteUid joined channel: ${connection.channelId}');
            if (!_isDisposed && mounted) {
              setState(() {
                _remoteUid = remoteUid;
                _isVideoReady = true;
                _isInitializing = false;
              });
              debugPrint('✅ Preview video ready for stream: ${widget.stream.streamId}');
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('👋 Preview: Remote user $remoteUid left channel. Reason: $reason');
            if (!_isDisposed && mounted) {
              setState(() {
                _remoteUid = null;
                _isVideoReady = false;
              });
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Agora preview error for ${widget.stream.channelName}: $err - $msg');
            if (!_isDisposed && mounted) {
              setState(() {
                _isInitializing = false;
              });
            }
          },
        ),
      );

      // Get token for preview
      debugPrint('🔑 Getting token for preview: ${widget.stream.channelName}');
      final tokenService = AgoraTokenService();
      final token = await tokenService.getAudienceToken(
        channelName: widget.stream.channelName,
        uid: 0,
      );
      debugPrint('✅ Token received: ${token.length} chars');

      if (_isDisposed) {
        await _cleanupEngine();
        return;
      }

      // Join channel as audience (viewer mode, muted)
      debugPrint('🚪 Joining channel as audience: ${widget.stream.channelName}');
      await _engine!.joinChannel(
        token: token,
        channelId: widget.stream.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          autoSubscribeAudio: false, // Muted
          autoSubscribeVideo: true,
        ),
      );
      debugPrint('✅ Join channel request sent for preview');
    } catch (e) {
      debugPrint('❌ Error initializing preview for ${widget.stream.channelName}: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      if (!_isDisposed && mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _cleanupEngine() async {
    if (_engine == null) return;

    try {
      await _engine!.leaveChannel();
      await _engine!.release();
    } catch (e) {
      debugPrint('⚠️ Error cleaning up preview engine: $e');
    } finally {
      if (!_isDisposed) {
        setState(() {
          _engine = null;
          _remoteUid = null;
          _isVideoReady = false;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _initTimer?.cancel();
    _cleanupEngine();
    super.dispose();
  }

  Widget _buildCoverImage() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.stream.hostId)
          .snapshots(),
      builder: (context, userSnapshot) {
        String? coverImageUrl;
        
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final coverURL = userData?['coverURL'] as String?;
          
          if (coverURL != null && coverURL.isNotEmpty) {
            final coverImages = coverURL.split(',').where((url) => url.trim().isNotEmpty).toList();
            if (coverImages.isNotEmpty) {
              coverImageUrl = coverImages[0].trim();
            }
          }
        }
        
        return Stack(
          children: [
            // Background: Cover Image or Gradient
            if (coverImageUrl != null && coverImageUrl.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(decoration: _defaultDecoration);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(decoration: _defaultDecoration);
                  },
                ),
              )
            else
              Container(decoration: _defaultDecoration),
            
            // Gradient overlay
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
            
            // Overlay UI
            _buildOverlayUI(),
          ],
        );
      },
    );
  }

  Widget _buildVideoPreview() {
    if (_remoteUid == null || _engine == null) {
      return _buildCoverImage();
    }

    return Stack(
      children: [
        // Video preview
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine!,
            canvas: VideoCanvas(
              uid: _remoteUid,
              renderMode: RenderModeType.renderModeFit, // Fit in card
            ),
            connection: RtcConnection(channelId: widget.stream.channelName),
          ),
        ),
        // Overlay UI
        _buildOverlayUI(),
      ],
    );
  }

  Widget _buildOverlayUI() {
    return Padding(
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
                          _formatViewers(widget.stream.viewerCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Host Name (Bottom - Moved down, title removed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.stream.hostName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 6,
                  ),
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatViewers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Always check if we should initialize when shouldShowPreview is true
    if (widget.shouldShowPreview && !_isInitializing && _engine == null && !_isDisposed) {
      debugPrint('🚀 Preview card build() - shouldShow=true, triggering init for ${widget.stream.channelName}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.shouldShowPreview && !_isInitializing && _engine == null) {
          debugPrint('✅ PostFrameCallback - initializing preview for ${widget.stream.channelName}');
          _initializePreview();
        }
      });
    }
    
    // Debug logging
    if (widget.shouldShowPreview && !_isVideoReady) {
      debugPrint('📊 Preview state for ${widget.stream.channelName}: shouldShow=${widget.shouldShowPreview}, videoReady=$_isVideoReady, initializing=$_isInitializing, remoteUid=$_remoteUid, engine=${_engine != null}');
    }
    
    // Show cover image initially or if preview not ready
    if (!widget.shouldShowPreview || !_isVideoReady || _isInitializing) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            child: _buildCoverImage(),
          ),
        ),
      );
    }

    // Show video preview with fade transition
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildVideoPreview(),
          ),
        ),
      ),
    );
  }
}
