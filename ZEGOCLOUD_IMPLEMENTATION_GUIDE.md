# 🎥 ZegoCloud Live Streaming & Video Call - Complete Implementation Guide

## 📋 **Overview**

This guide will help you implement ZegoCloud SDK for:
- ✅ **Live Streaming** (Host & Viewer)
- ✅ **Video Calls** (1-on-1 & Group)
- ✅ **Real-time Audio/Video**
- ✅ **Screen Sharing** (optional)

---

## 🎯 **Step 1: Create ZegoCloud Account & Get Credentials**

### 1.1 Sign Up / Login
1. Go to: **https://console.zegocloud.com/**
2. Sign up with email or use existing account
3. Verify your email if required

### 1.2 Create Project
1. Click **"Create Project"** or **"New Project"**
2. Select **"Live Streaming"** or **"Video Call"** (or both)
3. Enter project name: `Chamak Live Streaming`
4. Click **"Create"**

### 1.3 Get Credentials
1. Go to **"Project Settings"** or **"App Settings"**
2. Find your **App ID** (e.g., `1234567890`)
3. Find your **App Sign** (long string, e.g., `a1b2c3d4e5f6...`)
4. **Copy both** - you'll need them in Step 3

**⚠️ Important:**
- **App Sign** is sensitive - keep it secure
- Don't commit App Sign to public repositories
- Use environment variables for production

---

## 📦 **Step 2: Add ZegoCloud Dependencies**

### 2.1 Open `pubspec.yaml`
Open your project's `pubspec.yaml` file

### 2.2 Add ZegoCloud Packages
Add these dependencies under the `dependencies:` section:

```yaml
dependencies:
  # ... existing dependencies ...
  
  # ZegoCloud SDK - Core Engine
  zego_express_engine: ^3.22.1
  
  # ZegoCloud UI Kit - Pre-built Components (Recommended)
  zego_uikit_prebuilt_live_streaming: ^3.14.0
  zego_uikit_prebuilt_call: ^4.14.0
  
  # ZegoCloud Signaling Plugin (for call features)
  zego_uikit_signaling_plugin: ^2.8.19
  
  # Optional: For advanced features
  zego_uikit: ^2.28.18
```

### 2.3 Install Dependencies
Run in terminal:
```bash
flutter pub get
```

**Expected time:** 2-5 minutes (first time downloads ~200-500 MB)

---

## ⚙️ **Step 3: Configure ZegoCloud Credentials**

### 3.1 Create Config File
Create new file: `lib/config/zego_config.dart`

### 3.2 Add Configuration Code
```dart
class ZegoConfig {
  // Replace with YOUR App ID from ZegoCloud Console
  static const int appID = 1234567890; // ⚠️ CHANGE THIS
  
  // Replace with YOUR App Sign from ZegoCloud Console
  static const String appSign = 'YOUR_APP_SIGN_HERE'; // ⚠️ CHANGE THIS
  
  // Server URL (optional, for token-based auth in production)
  static const String? serverSecret = null; // Set if using token auth
}
```

### 3.3 Update Values
- Replace `appID` with your actual App ID
- Replace `appSign` with your actual App Sign

**⚠️ Security Note:** For production, use environment variables or secure storage instead of hardcoding.

---

## 🔐 **Step 4: Configure Android Permissions**

### 4.1 Open `android/app/src/main/AndroidManifest.xml`

### 4.2 Add Permissions
Add these permissions inside `<manifest>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Existing permissions -->
    
    <!-- ZegoCloud Required Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    
    <!-- For Android 12+ -->
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
    
    <!-- Optional: Screen sharing -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    
    <application>
        <!-- ... existing code ... -->
    </application>
</manifest>
```

### 4.3 Request Runtime Permissions (Already in your app via permission_handler)

---

## 🍎 **Step 5: Configure iOS Permissions (if needed)**

### 5.1 Open `ios/Runner/Info.plist`

### 5.2 Add Permissions
Add these keys inside `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for live streaming and video calls</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for live streaming and video calls</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access for sharing media</string>
```

---

## 🏗️ **Step 6: Configure Android Gradle**

### 6.1 Open `android/build.gradle`

### 6.2 Add ZegoCloud Maven Repository
Find `repositories` block and add:

```gradle
allprojects {
    repositories {
        // ... existing repositories ...
        
        // ZegoCloud Maven Repository
        maven {
            url 'https://www.zegocloud.com/maven'
        }
    }
}
```

### 6.3 Update `android/app/build.gradle`
Ensure minimum SDK version:

```gradle
android {
    compileSdkVersion 34  // or higher
    
    defaultConfig {
        minSdkVersion 21  // ZegoCloud requires at least 21
        targetSdkVersion 34
        // ... rest of config
    }
}
```

---

## 📱 **Step 7: Create ZegoCloud Service**

### 7.1 Create Service File
Create: `lib/services/zego_service.dart`

### 7.2 Basic Service Structure
```dart
import 'package:zego_express_engine/zego_express_engine.dart';
import '../config/zego_config.dart';

class ZegoService {
  static ZegoExpressEngine? _engine;
  
  // Initialize ZegoCloud Engine
  static Future<void> initialize() async {
    if (_engine != null) return;
    
    _engine = ZegoExpressEngine.createEngine(
      ZegoConfig.appID,
      ZegoConfig.appSign,
      isTestEnv: false, // Set to true for testing
      scenario: ZegoScenario.General, // or ZegoScenario.Communication
    );
    
    print('✅ ZegoCloud Engine initialized');
  }
  
  // Get engine instance
  static ZegoExpressEngine? get engine => _engine;
  
  // Cleanup
  static Future<void> dispose() async {
    await _engine?.destroyEngine();
    _engine = null;
  }
}
```

---

## 🎥 **Step 8: Implement Live Streaming Screen**

### 8.1 Update `lib/screens/live_page.dart`

**Option A: Using Pre-built UI Kit (Easiest - Recommended)**

```dart
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/zego_config.dart';

class LivePage extends StatelessWidget {
  final String liveID;
  final bool isHost;

  const LivePage({
    super.key,
    required this.liveID,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userID = currentUser?.uid ?? 'anonymous';
    final userName = currentUser?.displayName ?? 'User';

    return ZegoUIKitPrebuiltLiveStreaming(
      appID: ZegoConfig.appID,
      appSign: ZegoConfig.appSign,
      userID: userID,
      userName: userName,
      liveID: liveID,
      config: isHost
          ? ZegoUIKitPrebuiltLiveStreamingConfig.host(
              // Host configuration
              audioVideoViewConfig: ZegoPrebuiltAudioVideoViewConfig(
                showSoundWavesInAudioMode: true,
              ),
              bottomMenuBarConfig: ZegoLiveStreamingBottomMenuBarConfig(
                buttons: [
                  ZegoLiveStreamingBottomMenuBarButton.toggleMicrophone,
                  ZegoLiveStreamingBottomMenuBarButton.toggleCamera,
                  ZegoLiveStreamingBottomMenuBarButton.endLive,
                ],
              ),
            )
          : ZegoUIKitPrebuiltLiveStreamingConfig.audience(
              // Viewer configuration
              bottomMenuBarConfig: ZegoLiveStreamingBottomMenuBarConfig(
                buttons: [
                  ZegoLiveStreamingBottomMenuBarButton.leave,
                ],
              ),
            ),
    );
  }
}
```

**Option B: Custom Implementation (Advanced)**

This requires more code but gives full control. Let me know if you want this approach.

---

## 📞 **Step 9: Implement Video Call Screen**

### 9.1 Create Video Call Screen
Create: `lib/screens/video_call_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/zego_config.dart';

class VideoCallScreen extends StatelessWidget {
  final String callID;
  final String otherUserID;
  final String otherUserName;
  final bool isCaller;

  const VideoCallScreen({
    super.key,
    required this.callID,
    required this.otherUserID,
    required this.otherUserName,
    this.isCaller = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userID = currentUser?.uid ?? 'anonymous';
    final userName = currentUser?.displayName ?? 'User';

    return ZegoUIKitPrebuiltCall(
      appID: ZegoConfig.appID,
      appSign: ZegoConfig.appSign,
      userID: userID,
      userName: userName,
      callID: callID,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(
        // Caller configuration
        onHangUpConfirmation: (BuildContext context) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('End Call?'),
              content: const Text('Are you sure you want to end this call?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('End Call'),
                ),
              ],
            ),
          ) ?? false;
        },
        // Video call features
        audioVideoViewConfig: ZegoPrebuiltAudioVideoViewConfig(
          showSoundWavesInAudioMode: true,
        ),
        // Bottom menu buttons
        bottomMenuBarConfig: ZegoCallBottomMenuBarConfig(
          buttons: [
            ZegoCallBottomMenuBarButton.toggleMicrophone,
            ZegoCallBottomMenuBarButton.switchCamera,
            ZegoCallBottomMenuBarButton.toggleCamera,
            ZegoCallBottomMenuBarButton.hangUp,
          ],
        ),
      ),
    );
  }
}
```

### 9.2 Update Chat Screen to Add Video Call Button
In `lib/screens/chat_screen.dart`, update the video call button:

```dart
// In the AppBar actions section
GestureDetector(
  onTap: () {
    final currentUser = FirebaseAuth.instance.currentUser;
    final callID = '${currentUser?.uid}_${widget.otherUser.uid}';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          callID: callID,
          otherUserID: widget.otherUser.uid,
          otherUserName: widget.otherUser.name,
          isCaller: true,
        ),
      ),
    );
  },
  // ... existing button UI code ...
)
```

---

## 🚀 **Step 10: Initialize ZegoCloud in Main App**

### 10.1 Update `lib/main.dart`

Add initialization in `main()` function:

```dart
import 'services/zego_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize ZegoCloud
  await ZegoService.initialize();
  
  // ... rest of your main() code ...
  
  runApp(MyApp());
}
```

---

## 🧪 **Step 11: Test the Implementation**

### 11.1 Test Live Streaming
1. Run app: `flutter run`
2. Navigate to live streaming page
3. As **Host**: Start live stream
4. As **Viewer**: Join live stream
5. Verify:
   - ✅ Video appears
   - ✅ Audio works
   - ✅ Can toggle camera/mic
   - ✅ Can end/leave stream

### 11.2 Test Video Call
1. Open chat with another user
2. Tap **"Video Call"** button
3. Verify:
   - ✅ Call connects
   - ✅ Video appears
   - ✅ Audio works
   - ✅ Can toggle camera/mic
   - ✅ Can switch camera
   - ✅ Can hang up

---

## 🔧 **Step 12: Handle Permissions**

### 12.1 Request Permissions Before Starting
Update your live streaming or video call screens to request permissions:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> _requestPermissions() async {
  final cameraStatus = await Permission.camera.request();
  final micStatus = await Permission.microphone.request();
  
  if (cameraStatus.isGranted && micStatus.isGranted) {
    return true;
  } else {
    // Show error dialog
    return false;
  }
}
```

Call this before initializing ZegoCloud:

```dart
@override
void initState() {
  super.initState();
  _initializeStream();
}

Future<void> _initializeStream() async {
  final hasPermissions = await _requestPermissions();
  if (hasPermissions) {
    // Start streaming/call
  }
}
```

---

## 📝 **Step 13: Error Handling**

### 13.1 Add Error Listeners
In your ZegoService, add error handling:

```dart
static Future<void> initialize() async {
  // ... existing code ...
  
  _engine?.setEventHandler(
    ZegoEventHandler(
      onError: (errorCode, errorMessage) {
        print('❌ ZegoCloud Error: $errorCode - $errorMessage');
        // Handle errors (show snackbar, etc.)
      },
      onRoomStateUpdate: (roomID, state, errorCode, extendedData) {
        if (state == ZegoRoomState.Connected) {
          print('✅ Connected to room: $roomID');
        } else if (state == ZegoRoomState.Disconnected) {
          print('⚠️ Disconnected from room: $roomID');
        }
      },
    ),
  );
}
```

---

## 🎨 **Step 14: Customize UI (Optional)**

### 14.1 Customize Pre-built UI
The pre-built UI kits are highly customizable:

```dart
config: ZegoUIKitPrebuiltLiveStreamingConfig.host(
  // Customize colors
  theme: ZegoUIKitPrebuiltLiveStreamingTheme(
    primaryColor: Colors.purple,
    backgroundColor: Colors.black,
  ),
  
  // Customize layout
  layout: ZegoLayout.pictureInPicture,
  
  // Add custom buttons
  bottomMenuBarConfig: ZegoLiveStreamingBottomMenuBarConfig(
    buttons: [
      ZegoLiveStreamingBottomMenuBarButton.toggleMicrophone,
      ZegoLiveStreamingBottomMenuBarButton.toggleCamera,
      ZegoLiveStreamingBottomMenuBarButton.endLive,
      // Add custom button
      ZegoLiveStreamingBottomMenuBarButton(
        icon: Icon(Icons.star),
        onPressed: () {
          // Custom action
        },
      ),
    ],
  ),
)
```

---

## 🔒 **Step 15: Production Security (Important!)**

### 15.1 Use Token Authentication
For production, use token-based authentication instead of App Sign:

1. Generate tokens on your backend server
2. Update config to use tokens:

```dart
// In zego_config.dart
static Future<String> getToken(String userID) async {
  // Call your backend API to get token
  final response = await http.post(
    Uri.parse('https://your-backend.com/api/zego/token'),
    body: {'userID': userID},
  );
  return response.body;
}
```

3. Use token in initialization:

```dart
final token = await ZegoConfig.getToken(userID);
// Use token instead of appSign
```

---

## 📊 **Step 16: Monitor & Analytics**

### 16.1 Add Analytics
ZegoCloud provides analytics in their console:
- View active streams
- Monitor quality metrics
- Track usage statistics

Access at: https://console.zegocloud.com/

---

## ✅ **Step 17: Testing Checklist**

Before going live, test:

- [ ] Live streaming works (host)
- [ ] Live streaming works (viewer)
- [ ] Video call connects
- [ ] Audio works both ways
- [ ] Camera toggle works
- [ ] Microphone toggle works
- [ ] Switch camera works (front/back)
- [ ] End/Leave buttons work
- [ ] Permissions requested correctly
- [ ] Error handling works
- [ ] Works on different devices
- [ ] Works on different networks (WiFi, 4G, 5G)

---

## 🐛 **Troubleshooting**

### Issue: "App ID or App Sign invalid"
- **Solution:** Double-check credentials in `zego_config.dart`
- Verify in ZegoCloud console

### Issue: "No video/audio"
- **Solution:** Check permissions are granted
- Verify camera/mic work in other apps

### Issue: "Connection failed"
- **Solution:** Check internet connection
- Verify firewall isn't blocking ZegoCloud servers

### Issue: "Build errors"
- **Solution:** 
  ```bash
  flutter clean
  flutter pub get
  cd android && ./gradlew clean && cd ..
  flutter run
  ```

### Issue: "Package not found"
- **Solution:**
  ```bash
  flutter pub cache repair
  flutter pub get
  ```

---

## 📚 **Additional Resources**

- **ZegoCloud Documentation:** https://docs.zegocloud.com/
- **Flutter SDK Guide:** https://docs.zegocloud.com/article/14846
- **API Reference:** https://docs.zegocloud.com/article/14847
- **Sample Code:** https://github.com/ZEGOCLOUD/zego_uikit_prebuilt_live_streaming_flutter

---

## 🎯 **Quick Command Reference**

```bash
# 1. Install dependencies
flutter pub get

# 2. Clean build
flutter clean
flutter pub get

# 3. Run app
flutter run

# 4. Build APK
flutter build apk --release
```

---

## 🎉 **You're Ready!**

Follow these steps in order, and you'll have:
- ✅ Live streaming (host & viewer)
- ✅ Video calls (1-on-1)
- ✅ Real-time audio/video
- ✅ Full UI controls

**Start with Step 1 and work through each step!** 🚀

---

**Need help?** Check ZegoCloud documentation or test each step individually before moving to the next.



