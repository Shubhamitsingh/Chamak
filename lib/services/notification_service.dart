import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Import navigatorKey
import '../screens/wallet_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/team_messages_screen.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 Background message received: ${message.messageId}");
  print("📩 Background message data: ${message.data}");
  
  // Show notification even when app is in background
  if (message.notification != null) {
    print('📩 Notification Title: ${message.notification!.title}');
    print('📩 Notification Body: ${message.notification!.body}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Initialize notification service
  Future<void> initialize() async {
    try {
      print('🔔 Initializing Notification Service...');

      // Request permission for iOS and Android 13+
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      print('🔔 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ User granted notification permission');
        
        // Initialize local notifications
        await _initializeLocalNotifications();
        
        // Get FCM token
        await _getFCMToken();
        
        // Setup message handlers
        _setupMessageHandlers();
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_updateFCMToken);
        
        print('✅ Notification Service initialized successfully');
      } else {
        print('❌ User declined notification permission');
      }
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  // Initialize local notifications for displaying notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    // Message notifications channel
    const AndroidNotificationChannel messagesChannel = AndroidNotificationChannel(
      'chamak_messages', // id
      'Message Notifications', // name
      description: 'Notifications for new messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Wallet notifications channel
    const AndroidNotificationChannel walletChannel = AndroidNotificationChannel(
      'chamak_wallet', // id
      'Wallet Notifications', // name
      description: 'Notifications for wallet updates and coin additions',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messagesChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(walletChannel);
    
    print('✅ Local notifications initialized');
  }

  // Handle notification tap
  // ⚠️ CRITICAL FIX: Implement deep linking navigation
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        // Use the global navigator key to navigate
        _handleNotificationTap(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null) {
        print('✅ FCM Token obtained: $_fcmToken');
        
        // Save token to Firestore in background (non-blocking)
        // Don't await this to prevent blocking initialization
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          _saveFCMTokenToFirestore(userId, _fcmToken!).catchError((error) {
            print('⚠️ Error saving FCM token (non-critical): $error');
          });
        }
      } else {
        print('❌ FCM Token is null');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ FCM Token saved to Firestore');
    } catch (e) {
      print('❌ Error saving FCM token to Firestore: $e');
    }
  }

  // Update FCM token when it refreshes
  Future<void> _updateFCMToken(String newToken) async {
    _fcmToken = newToken;
    print('🔄 FCM Token refreshed: $newToken');
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _saveFCMTokenToFirestore(userId, newToken);
    }
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message received: ${message.messageId}');
      print('📩 Data: ${message.data}');
      
      if (message.notification != null) {
        print('📩 Title: ${message.notification!.title}');
        print('📩 Body: ${message.notification!.body}');
        
        // Show local notification when app is in foreground
        _showLocalNotification(message);
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Message opened app: ${message.messageId}');
      print('🔔 Data: ${message.data}');
      
      // Handle navigation based on message data
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from a terminated state via notification
    _checkInitialMessage();
  }

  // Check initial message (when app is opened from terminated state)
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    
    if (initialMessage != null) {
      print('🔔 App opened from terminated state via notification');
      print('🔔 Data: ${initialMessage.data}');
      
      // Handle navigation
      _handleNotificationTap(initialMessage.data);
    }
  }

  // Handle notification tap navigation
  // ⚠️ CRITICAL FIX: Implement deep linking to navigate to appropriate screens
  void _handleNotificationTap(Map<String, dynamic> data) {
    print('🔔 Handling notification tap with data: $data');
    
    final notificationType = data['type'] as String?;
    final navigator = navigatorKey.currentState;
    
    if (navigator == null) {
      print('⚠️ Navigator not available yet, navigation will be handled when app is ready');
      return;
    }
    
    // Handle different notification types
    if (notificationType == 'coin_addition' || notificationType == 'wallet') {
      print('💰 Coin addition/wallet notification tapped - Navigating to WalletScreen');
      // Get current user's phone number for WalletScreen
      final currentUser = FirebaseAuth.instance.currentUser;
      final phoneNumber = currentUser?.phoneNumber ?? '';
      if (phoneNumber.isEmpty) {
        print('⚠️ Cannot navigate to WalletScreen: User phone number not available');
        return;
      }
      navigator.push(
        MaterialPageRoute(
          builder: (context) => WalletScreen(phoneNumber: phoneNumber),
        ),
      );
    } else if (notificationType == 'team_message') {
      print('📢 Team message notification tapped - Navigating to TeamMessagesScreen');
      // Navigate to Team Messages Screen when team message notification is tapped
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const TeamMessagesScreen(),
        ),
      );
    } else if (notificationType == 'message' || notificationType == 'chat') {
      print('📩 Message notification tapped');
      final chatId = data['chatId'] as String?;
      final userId = data['userId'] as String?;
      
      // ⚠️ CRITICAL FIX: ChatScreen requires both chatId and otherUser
      // For now, navigate to ChatListScreen and let user select the chat
      // In a future enhancement, we can fetch the UserModel from userId/chatId
      // and then navigate directly to ChatScreen
      if (chatId != null && chatId.isNotEmpty || userId != null && userId.isNotEmpty) {
        print('📱 Navigating to ChatListScreen (will auto-select chat if possible)');
        // TODO: Enhance this to fetch UserModel and navigate directly to ChatScreen
        // For now, navigate to chat list where user can see the new message
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const ChatListScreen(),
          ),
        );
      } else {
        // No specific chat, navigate to chat list
        print('📱 Navigating to ChatListScreen');
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const ChatListScreen(),
          ),
        );
      }
    } else if (notificationType == 'live_stream' || notificationType == 'stream') {
      print('📺 Live stream notification tapped');
      final streamId = data['streamId'] as String?;
      // Navigate to live stream screen if streamId is provided
      // Note: You may need to import AgoraLiveStreamScreen and pass streamId
      print('📺 Stream ID: $streamId (navigation to be implemented based on your stream screen)');
    } else {
      print('ℹ️ Unknown notification type: $notificationType, defaulting to home');
      // For unknown types, do nothing (stay on current screen)
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // Determine notification channel based on type
      final notificationType = message.data['type'] as String?;
      final channelId = notificationType == 'coin_addition' 
          ? 'chamak_wallet' 
          : 'chamak_messages';
      final channelName = notificationType == 'coin_addition'
          ? 'Wallet Notifications'
          : 'Message Notifications';
      final channelDescription = notificationType == 'coin_addition'
          ? 'Notifications for wallet updates and coin additions'
          : 'Notifications for new messages';

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? 'You have a new message',
        notificationDetails,
        payload: json.encode(message.data),
      );
      
      print('✅ Local notification shown');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // Send notification to specific user (this would typically be done server-side)
  // This is a client-side helper to trigger server-side notification
  Future<void> sendMessageNotification({
    required String receiverUserId,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore
          .collection('users')
          .doc(receiverUserId)
          .get();
      
      if (!receiverDoc.exists) {
        print('❌ Receiver user not found');
        return;
      }

      final receiverToken = receiverDoc.data()?['fcmToken'] as String?;
      
      if (receiverToken == null || receiverToken.isEmpty) {
        print('❌ Receiver FCM token not found');
        return;
      }

      // Store notification request in Firestore
      // This will be picked up by Cloud Functions to send the actual notification
      await _firestore.collection('notificationRequests').add({
        'token': receiverToken,
        'notification': {
          'title': senderName,
          'body': messageText,
        },
        'data': {
          'type': 'message',
          'chatId': chatId,
          'senderId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });
      
      print('✅ Notification request created');
    } catch (e) {
      print('❌ Error sending notification request: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    print('🗑️ All notifications cleared');
  }

  // Clear specific notification
  Future<void> clearNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
    print('🗑️ Notification $notificationId cleared');
  }

  // Update badge count (iOS)
  Future<void> updateBadgeCount(int count) async {
    try {
      // This will work on iOS to update app badge
      // Note: Badge count needs to be managed manually
      print('📱 Badge count updated: $count');
    } catch (e) {
      print('❌ Error updating badge count: $e');
    }
  }

  // Delete FCM token (call on logout)
  Future<void> deleteFCMToken() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId != null) {
        // Remove token from Firestore
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
        });
      }
      
      // Delete token from Firebase
      await _messaging.deleteToken();
      _fcmToken = null;
      
      print('✅ FCM Token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }
}



