# 🎨 DeepAR Extension - Complete Guide

## Overview

**DeepAR** is an AR/beauty filter extension available in Agora's Extensions Marketplace.

**Extension Link:** https://console.agora.io/extensions-marketplace/deepar

---

## 💰 **Pricing Information**

### **Free vs Paid:**

**DeepAR typically offers:**
- ✅ **Free Trial Period** - Usually 14-30 days free trial
- ⚠️ **Paid Subscription** - After trial period
- 💵 **Pricing Model:**
  - Usually based on:
    - Monthly active users (MAU)
    - Number of effects used
    - API calls
    - Or flat monthly fee

**⚠️ Important:** 
- Check your Agora Console for exact pricing
- Pricing may vary by region
- Some features may be free, others paid
- Contact Agora sales for enterprise pricing

---

## 🎯 **What is DeepAR?**

DeepAR is a real-time AR/beauty filter SDK that provides:

### **Features:**
- ✅ **Beauty Filters** - Skin smoothing, face enhancement
- ✅ **AR Effects** - Face masks, filters, animations
- ✅ **Face Tracking** - Real-time face detection
- ✅ **Makeup Effects** - Virtual makeup application
- ✅ **3D Effects** - 3D objects and animations
- ✅ **Real-time Processing** - Low latency

### **Key Benefits:**
- High-quality filters
- Good performance
- Easy integration
- Cross-platform (Android & iOS)
- Regular effect updates

---

## 📋 **Setup & Integration Guide**

### **Step 1: Access Agora Console**

1. **Log in to Agora Console**
   - Visit: https://console.agora.io
   - Sign in with your account

2. **Navigate to Extensions Marketplace**
   - Go to **Extensions** → **Marketplace**
   - Or visit: https://console.agora.io/extensions-marketplace/deepar

---

### **Step 2: Subscribe to DeepAR**

1. **Find DeepAR Extension**
   - Search for "DeepAR" in marketplace
   - Click on DeepAR extension

2. **Review Details**
   - Check pricing information
   - Review features
   - Read terms and conditions

3. **Subscribe/Enable**
   - Click **"Subscribe"** or **"Enable"** button
   - Complete subscription process
   - Note your subscription details

---

### **Step 3: Download Extension Files**

1. **Download SDK**
   - Download Android SDK (`.aar` or `.jar` files)
   - Download iOS SDK (`.framework` files)
   - Download effect resources

2. **Get License Key**
   - Obtain your DeepAR license key
   - Save license information securely

3. **Download Documentation**
   - Get integration guide
   - Download sample code
   - Review API reference

---

### **Step 4: Android Integration**

#### **4.1 Add Files to Project**

```
android/
  app/
    libs/
      deepar-sdk.aar          ← Add DeepAR SDK
    src/
      main/
        assets/
          effects/            ← Add effect resources
```

#### **4.2 Update `android/app/build.gradle`**

```gradle
dependencies {
    // DeepAR SDK
    implementation files('libs/deepar-sdk.aar')
    // Or if using Maven:
    // implementation 'com.deepar:deepar-sdk:x.x.x'
}
```

#### **4.3 Add Permissions (if needed)**

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="true"/>
<uses-feature android:name="android.hardware.camera.autofocus"/>
```

#### **4.4 Initialize DeepAR**

Create `android/app/src/main/kotlin/.../DeepARPlugin.kt`:

```kotlin
import io.flutter.plugin.common.MethodChannel
import com.deepar.ar.DeepAR

class DeepARPlugin : MethodCallHandler {
    private var deepAR: DeepAR? = null
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val licenseKey = call.argument<String>("licenseKey")
                deepAR = DeepAR(context)
                deepAR?.setLicenseKey(licenseKey)
                result.success(true)
            }
            "enableBeauty" -> {
                deepAR?.switchEffect("beauty")
                result.success(true)
            }
            "setIntensity" -> {
                val intensity = call.argument<Double>("intensity")
                deepAR?.setIntensity(intensity)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
```

---

### **Step 5: iOS Integration**

#### **5.1 Add Framework**

1. Copy `.framework` to `ios/` directory
2. Add to Xcode project
3. Link in Build Phases

#### **5.2 Update Podfile (if using CocoaPods)**

```ruby
pod 'DeepAR', '~> x.x.x'
```

#### **5.3 Initialize DeepAR**

Create `ios/Runner/DeepARPlugin.swift`:

```swift
import Flutter
import DeepAR

public class DeepARPlugin: NSObject, FlutterPlugin {
    private var deepAR: DeepAR?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "deepar", binaryMessenger: registrar.messenger())
        let instance = DeepARPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            let args = call.arguments as! [String: Any]
            let licenseKey = args["licenseKey"] as! String
            deepAR = DeepAR()
            deepAR?.setLicenseKey(licenseKey)
            result(true)
        case "enableBeauty":
            deepAR?.switchEffect("beauty")
            result(true)
        case "setIntensity":
            let args = call.arguments as! [String: Any]
            let intensity = args["intensity"] as! Double
            deepAR?.setIntensity(intensity)
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

---

### **Step 6: Flutter Integration**

#### **6.1 Create DeepAR Service**

Create `lib/services/deepar_beauty_service.dart`:

```dart
import 'package:flutter/services.dart';

class DeepARBeautyService {
  static const MethodChannel _channel = MethodChannel('deepar');
  
  bool _isEnabled = false;
  double _intensity = 0.5;
  String? _licenseKey;
  
  // Initialize DeepAR
  Future<bool> initialize(String licenseKey) async {
    _licenseKey = licenseKey;
    try {
      final result = await _channel.invokeMethod('initialize', {
        'licenseKey': licenseKey,
      });
      return result == true;
    } catch (e) {
      print('Error initializing DeepAR: $e');
      return false;
    }
  }
  
  // Enable beauty filter
  Future<void> enableBeautyFilter() async {
    try {
      await _channel.invokeMethod('enableBeauty');
      _isEnabled = true;
    } catch (e) {
      print('Error enabling beauty filter: $e');
    }
  }
  
  // Disable beauty filter
  Future<void> disableBeautyFilter() async {
    try {
      await _channel.invokeMethod('disableBeauty');
      _isEnabled = false;
    } catch (e) {
      print('Error disabling beauty filter: $e');
    }
  }
  
  // Set intensity (0.0 to 1.0)
  Future<void> setIntensity(double intensity) async {
    _intensity = intensity.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod('setIntensity', {
        'intensity': _intensity,
      });
    } catch (e) {
      print('Error setting intensity: $e');
    }
  }
  
  // Apply specific effect
  Future<void> applyEffect(String effectPath) async {
    try {
      await _channel.invokeMethod('applyEffect', {
        'effectPath': effectPath,
      });
    } catch (e) {
      print('Error applying effect: $e');
    }
  }
  
  bool get isEnabled => _isEnabled;
  double get intensity => _intensity;
}
```

#### **6.2 Integrate with Live Streaming**

Update `lib/screens/agora_live_stream_screen.dart`:

```dart
import '../services/deepar_beauty_service.dart';

class _AgoraLiveStreamScreenState extends State<AgoraLiveStreamScreen> {
  final DeepARBeautyService _deepARService = DeepARBeautyService();
  bool _beautyFilterEnabled = false;
  double _beautyIntensity = 0.5;
  
  @override
  void initState() {
    super.initState();
    _initializeDeepAR();
    _initializeAgora();
  }
  
  Future<void> _initializeDeepAR() async {
    // Get license key from your config or Agora Console
    const licenseKey = 'YOUR_DEEPAR_LICENSE_KEY';
    await _deepARService.initialize(licenseKey);
  }
  
  void _toggleBeautyFilter() {
    setState(() {
      _beautyFilterEnabled = !_beautyFilterEnabled;
      if (_beautyFilterEnabled) {
        _deepARService.enableBeautyFilter();
      } else {
        _deepARService.disableBeautyFilter();
      }
    });
  }
  
  void _adjustIntensity(double value) {
    setState(() {
      _beautyIntensity = value;
      _deepARService.setIntensity(value);
    });
  }
}
```

---

### **Step 7: Add UI Controls**

```dart
// Beauty filter toggle button
IconButton(
  icon: Icon(
    _beautyFilterEnabled ? Icons.face : Icons.face_outlined,
    color: _beautyFilterEnabled ? Colors.amber : Colors.white,
  ),
  onPressed: _toggleBeautyFilter,
  tooltip: 'Beauty Filter',
)

// Intensity slider
if (_beautyFilterEnabled)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        Text('Intensity: ${(_beautyIntensity * 100).toInt()}%'),
        Slider(
          value: _beautyIntensity,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          onChanged: _adjustIntensity,
        ),
      ],
    ),
  )
```

---

## 🎨 **Available Features**

### **Beauty Filters:**
- Skin smoothing
- Face shaping
- Eye enhancement
- Lip enhancement
- Makeup effects

### **AR Effects:**
- Face masks
- 3D objects
- Animations
- Filters
- Background effects

---

## ⚙️ **Configuration**

### **License Key Setup:**
1. Get license key from Agora Console
2. Store securely (use environment variables or secure storage)
3. Initialize with license key

### **Effect Resources:**
1. Download effects from DeepAR
2. Add to `assets/effects/` directory
3. Reference by path when applying

---

## 💡 **Pricing Details (Check Console)**

To get exact pricing:

1. **Log in to Agora Console**
2. **Go to Extensions Marketplace**
3. **Click on DeepAR**
4. **Check Pricing Tab**
5. **Review:**
   - Free trial period
   - Monthly subscription cost
   - Usage-based pricing
   - Enterprise pricing

**Common Pricing Models:**
- Free trial (14-30 days)
- Monthly subscription ($X/month)
- Per MAU (Monthly Active Users)
- Per API call
- Enterprise (custom pricing)

---

## 📚 **Resources**

- **Agora Console:** https://console.agora.io/extensions-marketplace/deepar
- **DeepAR Documentation:** Check Agora Console for docs
- **Sample Code:** Available in Agora Console
- **Support:** Contact Agora support for help

---

## ⚠️ **Important Notes**

1. **License Required:** You need a valid DeepAR license key
2. **Pricing:** Check Agora Console for current pricing
3. **Trial Period:** Usually 14-30 days free trial
4. **Performance:** Test on various devices
5. **No Blur:** DeepAR maintains image quality

---

## 🚀 **Next Steps**

1. ✅ **Check Agora Console** - Review DeepAR extension
2. ✅ **Check Pricing** - See if it fits your budget
3. ✅ **Start Free Trial** - If available
4. ✅ **Download SDK** - Get extension files
5. ✅ **Integrate** - Follow setup steps above
6. ✅ **Test** - Verify beauty filters work

---

## 📞 **Need Help?**

- **Agora Support:** Contact through Agora Console
- **Documentation:** Check extension page in console
- **Community:** Agora Developer Forum

**Ready to integrate?** Let me know and I'll help you implement DeepAR step by step! 🎨











