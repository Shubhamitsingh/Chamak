import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Agora App ID
const String appId = '43bb5e13c835444595c8cf087a0ccaa4';

// Agora RTC Engine instance
late RtcEngine _engine;

// Channel and token variables (to be set when joining)
String token = ''; // Token for authentication
String channel = ''; // Channel name

// State variables for tracking users
bool _localUserJoined = false;
int? _remoteUid;

// Set up the Agora RTC engine instance
Future<void> _initializeAgoraVideoSDK() async {
  _engine = createAgoraRtcEngine();
  await _engine.initialize(const RtcEngineContext(
    appId: appId,
    channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
  ));
}

// Register an event handler for Agora RTC
void _setupEventHandlers() {
  _engine.registerEventHandler(
    RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("Local user ${connection.localUid} joined");
        _localUserJoined = true;
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("Remote user $remoteUid joined");
        _remoteUid = remoteUid;
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        debugPrint("Remote user $remoteUid left");
        _remoteUid = null;
      },
    ),
  );
}

// Join a channel
Future<void> _joinChannel() async {
  await _engine.joinChannel(
    token: token,
    channelId: channel,
    options: const ChannelMediaOptions(
      autoSubscribeVideo: true, // Automatically subscribe to all video streams
      autoSubscribeAudio: true, // Automatically subscribe to all audio streams
      publishCameraTrack: true, // Publish camera-captured video
      publishMicrophoneTrack: true, // Publish microphone-captured audio
      // Use clientRoleBroadcaster to act as a host or clientRoleAudience for audience
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      // Set the audience latency level
      audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelUltraLowLatency,
    ),
    uid: 0,
  );
}

// Display the local video
Future<void> _setupLocalVideo() async {
  // The video module and preview are disabled by default.
  await _engine.enableVideo();
  await _engine.startPreview();
}

// Displays the local user's video view using the Agora engine.
Widget _localVideo() {
  return AgoraVideoView(
    controller: VideoViewController(
      rtcEngine: _engine, // Uses the Agora engine instance
      canvas: const VideoCanvas(
        uid: 0, // Specifies the local user
        renderMode: RenderModeType.renderModeHidden, // Sets the video rendering mode
      ),
    ),
  );
}

// If a remote user has joined, render their video, else display a waiting message
Widget _remoteVideo() {
  if (_remoteUid != null) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine, // Uses the Agora engine instance
        canvas: VideoCanvas(uid: _remoteUid), // Binds the remote user's video
        connection: RtcConnection(channelId: channel), // Specifies the channel
      ),
    );
  } else {
    return const Text(
      'Waiting for remote user to join...',
      textAlign: TextAlign.center,
    );
  }
}

// Handle permissions
Future<void> _requestPermissions() async {
  await [Permission.microphone, Permission.camera].request();
}

// Start Interactive Live Streaming
// Request permissions, initialize SDK, setup local video, setup event handlers, and join channel
Future<void> startLiveStreaming() async {
  await _requestPermissions();
  await _initializeAgoraVideoSDK();
  await _setupLocalVideo();
  _setupEventHandlers();
  await _joinChannel();
}

// Leaves the channel and releases resources
Future<void> _cleanupAgoraEngine() async {
  await _engine.leaveChannel();
  await _engine.release();
}

