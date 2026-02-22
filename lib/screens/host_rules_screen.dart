import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/database_service.dart';

const String _agoraAppId = '43bb5e13c835444595c8cf087a0ccaa4';

class HostRulesScreen extends StatefulWidget {
  final VoidCallback onGoLive;

  const HostRulesScreen({
    super.key,
    required this.onGoLive,
  });

  @override
  State<HostRulesScreen> createState() => _HostRulesScreenState();
}

class _HostRulesScreenState extends State<HostRulesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  
  // Agora engine for camera preview
  RtcEngine? _engine;
  bool _isPreviewReady = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isCheckingPermission = false;
            _hasPermission = false;
          });
          _goBack();
        }
        return;
      }

      final userData = await _databaseService.getUserData(userId);
      if (mounted) {
        setState(() {
          _hasPermission = userData?.isActive ?? false;
          _isCheckingPermission = false;
        });

        if (_hasPermission) {
          await _initializeCameraPreview();
        } else {
          _goBack();
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking permission: $e');
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
          _hasPermission = false;
        });
        _goBack();
      }
    }
  }

  void _goBack() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _initializeCameraPreview() async {
    try {
      // Request camera and microphone permissions
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (cameraStatus.isDenied || micStatus.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera and microphone permissions are required to go live'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Initialize Agora engine for preview only
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: _agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      // Enable video
      await _engine!.enableVideo();

      // Start preview
      await _engine!.startPreview();

      // Setup local video view
      await _engine!.setupLocalVideo(
        const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeFit,
        ),
      );

      if (mounted) {
        setState(() {
          _isPreviewReady = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing camera preview: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Clean up Agora engine
    _engine?.stopPreview();
    _engine?.disableVideo();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Go Live',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isCheckingPermission
          ? const SizedBox.shrink() // Open simply – no spinner; popup or camera when check done
          : _hasPermission
              ? _buildCameraPreview()
              : const SizedBox.shrink(), // No permission: popup handles the UI
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: _isPreviewReady && _engine != null
              ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
                    canvas: const VideoCanvas(
                      uid: 0,
                      renderMode: RenderModeType.renderModeHidden,
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF1B7C),
                  ),
                ),
        ),
        
        // Go Live Button - Container with reduced width, moved upward from bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 48, 72),
              child: _buildGoLiveButton(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoLiveButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Call the onGoLive callback to start the live stream
            widget.onGoLive();
          },
          borderRadius: BorderRadius.circular(10),
          child: const Center(
            child: Text(
              'Go Live',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
