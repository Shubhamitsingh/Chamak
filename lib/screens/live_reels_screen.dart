import 'package:flutter/material.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import '../services/agora_token_service.dart';
import 'agora_live_stream_screen.dart';

/// Reels-style vertical live viewer for active hosts.
class LiveReelsScreen extends StatefulWidget {
  const LiveReelsScreen({super.key});

  @override
  State<LiveReelsScreen> createState() => _LiveReelsScreenState();
}

class _LiveReelsScreenState extends State<LiveReelsScreen> {
  final LiveStreamService _liveStreamService = LiveStreamService();
  final AgoraTokenService _tokenService = AgoraTokenService();
  final PageController _pageController = PageController();
  final Map<String, Future<String>> _tokenCache = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<String> _getToken(LiveStreamModel stream) {
    return _tokenCache.putIfAbsent(
      stream.channelName,
      () => _tokenService.getAudienceToken(channelName: stream.channelName, uid: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LiveStreamModel>>(
      stream: _liveStreamService.getActiveLiveStreams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
          );
        }

        final streams = snapshot.data ?? [];
        if (streams.isEmpty) {
          return Center(
            child: Text(
              'No one is live right now',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
              builder: (context, tokenSnap) {
                if (tokenSnap.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
                    ),
                  );
                }
                if (!tokenSnap.hasData || tokenSnap.hasError) {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Text(
                        'Unable to load stream',
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                    ),
                  );
                }

                final token = tokenSnap.data!;
                return AgoraLiveStreamScreen(
                  key: ValueKey('reel_${stream.streamId}'),
                  channelName: stream.channelName,
                  token: token,
                  isHost: false,
                  streamId: stream.streamId,
                );
              },
            );
          },
        );
      },
    );
  }
}
