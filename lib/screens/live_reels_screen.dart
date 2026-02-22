import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import '../services/agora_token_service.dart';
import 'agora_live_stream_screen.dart';

/// Reels-style vertical live viewer showing only active live hosts.
class LiveReelsScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  
  const LiveReelsScreen({super.key, this.onBackPressed});

  @override
  State<LiveReelsScreen> createState() => _LiveReelsScreenState();
}

class _LiveReelsScreenState extends State<LiveReelsScreen> {
  final LiveStreamService _liveStreamService = LiveStreamService();
  final AgoraTokenService _tokenService = AgoraTokenService();
  final PageController _pageController = PageController();
  final Map<String, Future<String>> _tokenCache = {};

  @override
  void initState() {
    super.initState();
    // Enforce pink status bar while in reels view
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFF1B7C),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    // Reset status bar to default (transparent) - HomeScreen will handle final theme
    // This prevents status bar conflicts when navigating away
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _pageController.dispose();
    super.dispose();
  }

  Future<String> _getToken(LiveStreamModel stream) {
    return _tokenCache.putIfAbsent(
      stream.channelName,
      () => _tokenService.getAudienceToken(
        channelName: stream.channelName,
        uid: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: const Color(0xFFFF1B7C), // Pink theme
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false, // Prevent default pop - handle manually
        onPopInvoked: (didPop) {
          if (didPop) return;
          // Handle Android back button - navigate to Explore tab
          if (widget.onBackPressed != null) {
            widget.onBackPressed!();
          }
        },
        child: StreamBuilder<List<LiveStreamModel>>(
        stream: _liveStreamService.getActiveLiveStreams(),
        builder: (context, snapshot) {
          // Only show loading indicator on initial load, not on rebuilds
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
            );
          }

          final streams = snapshot.data ?? [];
          if (streams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No live streams available right now.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: streams.length,
            itemBuilder: (context, index) {
              final stream = streams[index];
              return FutureBuilder<String>(
                future: _getToken(stream),
                builder: (context, tokenSnapshot) {
                  if (tokenSnapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFFF1B7C)),
                      ),
                    );
                  }

                  if (!tokenSnapshot.hasData || tokenSnapshot.hasError) {
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          'Unable to load stream',
                          style:
                              TextStyle(color: Colors.grey[300], fontSize: 14),
                        ),
                      ),
                    );
                  }

                  final token = tokenSnapshot.data!;
                  return AgoraLiveStreamScreen(
                    key: ValueKey('reel_${stream.streamId}'),
                    channelName: stream.channelName,
                    token: token,
                    isHost: false,
                    streamId: stream.streamId,
                    isInReelsView: true, // Mark that it's in reels view
                    onReelsBackPressed: widget.onBackPressed, // Pass callback
                  );
                },
              );
            },
          );
        },
        ),
      ),
    );
  }
}
