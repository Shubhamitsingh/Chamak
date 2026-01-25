# 🔥 Firebase Crashlytics Implementation Report
## Complete Guide for Chamak Live Streaming App

**Generated:** January 2025  
**Project:** Chamak (Live Streaming App)  
**Current Status:** Firebase Core, Auth, Firestore, Messaging, Storage, Remote Config ✅  
**Missing:** Firebase Crashlytics ❌

---

## 📋 Table of Contents

1. [What is Firebase Crashlytics?](#what-is-firebase-crashlytics)
2. [Available Features](#available-features)
3. [Why You Need It](#why-you-need-it)
4. [Step-by-Step Implementation](#step-by-step-implementation)
5. [What Happens After Implementation](#what-happens-after-implementation)
6. [Senior Developer Best Practices](#senior-developer-best-practices)
7. [Integration with Your Current Code](#integration-with-your-current-code)
8. [Monitoring & Alerts Setup](#monitoring--alerts-setup)
9. [Production Checklist](#production-checklist)

---

## 🎯 What is Firebase Crashlytics?

**Firebase Crashlytics** is a real-time crash reporting tool that helps you:
- **Track crashes** in production apps
- **Get detailed crash reports** with stack traces
- **Identify issues** before users report them
- **Monitor app stability** with crash-free statistics
- **Debug faster** with user context and device info

### Key Benefits:
✅ **Real-time crash reporting** - Know about crashes within minutes  
✅ **Automatic crash collection** - No code changes needed for basic crashes  
✅ **Rich context** - Device info, OS version, user actions before crash  
✅ **Crash-free statistics** - Track app stability over time  
✅ **Free tier** - No cost for most apps

---

## 🚀 Available Features

### 1. **Automatic Crash Reporting**
- Automatically captures unhandled exceptions
- Captures fatal errors (app crashes)
- Captures non-fatal errors (exceptions caught in try-catch)

### 2. **Custom Logging**
- Log custom events and user actions
- Add breadcrumbs to track user journey before crash
- Log important app state changes

### 3. **User Identification**
- Set user IDs to track crashes per user
- Set custom user attributes (email, subscription tier, etc.)
- Filter crashes by user segments

### 4. **Custom Keys**
- Add custom key-value pairs to crash reports
- Track app version, feature flags, user preferences
- Add context about app state at crash time

### 5. **Crash-Free Statistics**
- Track crash-free user percentage
- Monitor stability trends over time
- Set stability goals and alerts

### 6. **Velocity Alerts**
- Get notified when crash rate spikes
- Email alerts for critical issues
- Slack/email integration

### 7. **Crash Grouping**
- Automatically groups similar crashes
- Identifies crash patterns
- Helps prioritize fixes

### 8. **Stack Traces**
- Full stack traces for all crashes
- Symbolicated (readable) stack traces
- Line numbers and file names

### 9. **Device & OS Information**
- Device model, OS version
- App version, build number
- Memory usage, disk space
- Network conditions

### 10. **User Journey Tracking**
- See what user did before crash
- Track navigation path
- See API calls and responses

---

## 💡 Why You Need It

### Current State of Your App:
Based on code analysis, your app currently:
- ✅ Has try-catch blocks in most places
- ✅ Shows error messages via SnackBar
- ⚠️ Uses `debugPrint()` for error logging (only works in debug mode)
- ⚠️ No production error tracking
- ⚠️ No crash reporting
- ⚠️ No visibility into production issues

### Problems Without Crashlytics:
1. **Silent Failures** - Users experience crashes but you don't know
2. **No Production Visibility** - Can't see what's breaking in production
3. **Hard to Debug** - No stack traces or context
4. **User Complaints** - Users report issues but you can't reproduce
5. **No Metrics** - Don't know app stability percentage

### Benefits With Crashlytics:
1. **Proactive Issue Detection** - Know about crashes before users report
2. **Faster Debugging** - Full stack traces and context
3. **Better User Experience** - Fix issues users are experiencing
4. **Data-Driven Decisions** - Prioritize fixes based on crash frequency
5. **Stability Monitoring** - Track crash-free percentage over time

---

## 📝 Step-by-Step Implementation

### **Phase 1: Add Dependencies**

#### Step 1.1: Update `pubspec.yaml`

Add Firebase Crashlytics dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing Firebase dependencies
  firebase_core: ^4.2.0
  firebase_auth: ^6.1.1
  cloud_firestore: ^6.0.3
  firebase_messaging: ^16.0.3
  firebase_storage: ^13.0.3
  firebase_remote_config: ^6.1.2
  
  # ✅ ADD THIS - Firebase Crashlytics
  firebase_crashlytics: ^4.1.3
```

#### Step 1.2: Install Dependencies

```bash
flutter pub get
```

---

### **Phase 2: Enable Crashlytics in Firebase Console**

#### Step 2.1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **chamak-39472**
3. Click **"Crashlytics"** in the left menu
4. Click **"Get started"** (if not already enabled)

#### Step 2.2: Enable Crashlytics
- Firebase will automatically enable Crashlytics for your project
- No additional configuration needed in console

---

### **Phase 3: Android Configuration**

#### Step 3.1: Update `android/app/build.gradle`

Add Crashlytics dependency to your existing Firebase BOM:

```gradle
dependencies {
  // Import the Firebase BoM (already exists)
  implementation platform('com.google.firebase:firebase-bom:34.4.0')

  // Firebase Analytics (already exists)
  implementation 'com.google.firebase:firebase-analytics'
  
  // ✅ ADD THIS - Firebase Crashlytics
  implementation 'com.google.firebase:firebase-crashlytics'
}
```

#### Step 3.2: Update `android/build.gradle`

Add Crashlytics Gradle plugin:

```gradle
buildscript {
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.0'
        // ✅ ADD THIS - Crashlytics Gradle plugin
        classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.2'
    }
}
```

#### Step 3.3: Apply Plugin in `android/app/build.gradle`

Add at the **bottom** of the file (after all other plugins):

```gradle
plugins {
    id "com.android.application"
    id 'com.google.gms.google-services'
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    // ✅ ADD THIS - Apply Crashlytics plugin
    id 'com.google.firebase.crashlytics'
}
```

---

### **Phase 4: Initialize Crashlytics in Flutter**

#### Step 4.1: Update `lib/main.dart`

Add Crashlytics initialization and error handlers:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // ✅ ADD THIS
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/intro_logo_screen.dart';
import 'screens/login_screen.dart';
import 'providers/language_provider.dart';
import 'services/notification_service.dart';
import 'services/update_service.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

// ⚠️ CRITICAL FIX: Global navigator key for deep linking from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (required before app starts)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ ADD THIS - Initialize Crashlytics Error Handlers
  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    // Log to console in debug mode
    FlutterError.presentError(errorDetails);
    
    // Send to Crashlytics
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  // ✅ ADD THIS - Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  // Initialize Firebase Cloud Messaging - Background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize Update Service (for checking app updates)
  UpdateService().initialize().catchError((error) {
    debugPrint('⚠️ Update service initialization error: $error');
    // ✅ ADD THIS - Log to Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      StackTrace.current,
      reason: 'Update service initialization failed',
      fatal: false,
    );
  });
  
  // Set system UI overlay style (non-blocking)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Start the app immediately - don't wait for notification service
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const LiveVibeApp(),
    ),
  );
  
  // Listen to auth state changes to handle logout scenarios
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      debugPrint('🔐 Auth state changed: User logged out');
    } else {
      debugPrint('🔐 Auth state changed: User logged in - ${user.uid}');
      // ✅ ADD THIS - Set user ID in Crashlytics
      FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
    }
  });
  
  // Initialize Notification Service in background (non-blocking)
  NotificationService().initialize().catchError((error) {
    debugPrint('⚠️ Notification service initialization error: $error');
    // ✅ ADD THIS - Log to Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      StackTrace.current,
      reason: 'Notification service initialization failed',
      fatal: false,
    );
  });
}
```

---

### **Phase 5: Create Error Logging Service**

#### Step 5.1: Create `lib/services/crashlytics_service.dart`

Create a centralized service for Crashlytics operations:

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized service for Firebase Crashlytics operations
/// 
/// Usage:
/// ```dart
/// // Log non-fatal error
/// CrashlyticsService.logError(error, stackTrace, context: 'Payment processing');
/// 
/// // Log custom event
/// CrashlyticsService.logEvent('user_sent_gift', {'gift_id': 'rose', 'amount': 10});
/// 
/// // Set user identifier
/// CrashlyticsService.setUserId(userId);
/// 
/// // Set custom key
/// CrashlyticsService.setCustomKey('subscription_tier', 'premium');
/// ```
class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Log a non-fatal error
  /// 
  /// Use this for errors that don't crash the app but should be tracked
  /// Example: API failures, validation errors, network timeouts
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: context,
        fatal: fatal,
      );
      
      if (kDebugMode) {
        debugPrint('📊 Crashlytics: Logged error - ${error.toString()}');
        if (context != null) {
          debugPrint('📊 Context: $context');
        }
      }
    } catch (e) {
      // Don't let Crashlytics errors crash the app
      if (kDebugMode) {
        debugPrint('⚠️ Failed to log to Crashlytics: $e');
      }
    }
  }

  /// Log a custom event (breadcrumb)
  /// 
  /// Use this to track user actions and app state changes
  /// Example: 'user_opened_live_stream', 'payment_initiated', 'gift_sent'
  static Future<void> logEvent(String eventName, [Map<String, dynamic>? data]) async {
    try {
      String message = eventName;
      if (data != null && data.isNotEmpty) {
        message += ': ${data.toString()}';
      }
      
      await _crashlytics.log(message);
      
      if (kDebugMode) {
        debugPrint('📊 Crashlytics: Logged event - $message');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to log event to Crashlytics: $e');
      }
    }
  }

  /// Set user identifier
  /// 
  /// Use this to track crashes per user
  /// Call this after user logs in
  static Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      
      if (kDebugMode) {
        debugPrint('📊 Crashlytics: Set user ID - $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to set user ID in Crashlytics: $e');
      }
    }
  }

  /// Clear user identifier
  /// 
  /// Call this after user logs out
  static Future<void> clearUserId() async {
    try {
      await _crashlytics.setUserIdentifier('');
      
      if (kDebugMode) {
        debugPrint('📊 Crashlytics: Cleared user ID');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to clear user ID in Crashlytics: $e');
      }
    }
  }

  /// Set custom key-value pair
  /// 
  /// Use this to add context to crash reports
  /// Example: app version, feature flags, user preferences
  static Future<void> setCustomKey(String key, dynamic value) async {
    try {
      if (value is String) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is int) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is double) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is bool) {
        await _crashlytics.setCustomKey(key, value);
      } else {
        await _crashlytics.setCustomKey(key, value.toString());
      }
      
      if (kDebugMode) {
        debugPrint('📊 Crashlytics: Set custom key - $key: $value');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to set custom key in Crashlytics: $e');
      }
    }
  }

  /// Set multiple custom keys at once
  static Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    for (var entry in keys.entries) {
      await setCustomKey(entry.key, entry.value);
    }
  }

  /// Enable/disable Crashlytics collection
  /// 
  /// Useful for disabling in debug mode or for specific users
  static Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
      
      if (kDebugMode) {
        debugPrint('📊 Crashlytics: Collection ${enabled ? "enabled" : "disabled"}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to set Crashlytics collection: $e');
      }
    }
  }

  /// Check if Crashlytics is enabled
  static bool get isCrashlyticsCollectionEnabled {
    return _crashlytics.isCrashlyticsCollectionEnabled;
  }
}
```

---

### **Phase 6: Integrate with Existing Error Handling**

#### Step 6.1: Update `lib/screens/otp_screen.dart`

Add Crashlytics logging to existing error handling:

```dart
import 'package:Chamak/services/crashlytics_service.dart'; // ✅ ADD THIS

// In your _verifyOTP method, update error handling:
} on FirebaseAuthException catch (e) {
  debugPrint('❌ Firebase OTP verification failed: ${e.code} - ${e.message}');
  
  // ✅ ADD THIS - Log to Crashlytics
  CrashlyticsService.logError(
    e,
    StackTrace.current,
    context: 'OTP verification failed: ${e.code}',
    fatal: false,
  );
  
  if (!mounted) return;
  
  String errorMessage = 'Invalid OTP';
  // ... rest of error handling
} on Exception catch (e) {
  debugPrint('❌ Database or other error: $e');
  
  // ✅ ADD THIS - Log to Crashlytics
  CrashlyticsService.logError(
    e,
    StackTrace.current,
    context: 'Database error during OTP verification',
    fatal: false,
  );
  
  if (!mounted) return;
  _showErrorSnackBar('Database error: ${e.toString()}');
} catch (e, stackTrace) {
  debugPrint('❌ Unexpected error during OTP verification: $e');
  
  // ✅ ADD THIS - Log to Crashlytics
  CrashlyticsService.logError(
    e,
    stackTrace,
    context: 'Unexpected error during OTP verification',
    fatal: false,
  );
  
  if (!mounted) return;
  _showErrorSnackBar('Error: ${e.toString()}');
}
```

#### Step 6.2: Update `lib/screens/agora_live_stream_screen.dart`

Add Crashlytics logging to Agora errors:

```dart
import 'package:Chamak/services/crashlytics_service.dart'; // ✅ ADD THIS

// In your onError handler:
onError: (errCode, errMsg) {
  debugPrint('❌ Agora RTC Error: $errCode - $errMsg');
  
  // ✅ ADD THIS - Log to Crashlytics
  CrashlyticsService.logError(
    'Agora RTC Error: $errCode - $errMsg',
    StackTrace.current,
    context: 'Agora SDK error in live stream',
    fatal: false,
  );
  
  // Log event for tracking
  CrashlyticsService.logEvent('agora_error', {
    'error_code': errCode,
    'error_message': errMsg,
  });
  
  // ... rest of error handling
},
```

#### Step 6.3: Update Payment Services

Add Crashlytics logging to payment errors:

```dart
// In lib/services/payprime_payment_service.dart
import 'package:Chamak/services/crashlytics_service.dart'; // ✅ ADD THIS

// In your payment methods, add error logging:
try {
  // Payment processing code
} catch (e, stackTrace) {
  // ✅ ADD THIS - Log payment errors
  CrashlyticsService.logError(
    e,
    stackTrace,
    context: 'Payment processing failed',
    fatal: false,
  );
  
  // Log custom event
  CrashlyticsService.logEvent('payment_failed', {
    'payment_method': 'payprime',
    'error': e.toString(),
  });
  
  // ... rest of error handling
}
```

---

### **Phase 7: Add User Context**

#### Step 7.1: Update Login/Auth Flow

Set user ID and custom keys after login:

```dart
// In your login success handler:
Future<void> _handleLoginSuccess(User user) async {
  // ✅ ADD THIS - Set user ID in Crashlytics
  await CrashlyticsService.setUserId(user.uid);
  
  // ✅ ADD THIS - Set user custom keys
  await CrashlyticsService.setCustomKeys({
    'user_email': user.email ?? 'N/A',
    'user_phone': user.phoneNumber ?? 'N/A',
    'login_method': 'phone', // or 'email', 'google', etc.
  });
  
  // Log login event
  await CrashlyticsService.logEvent('user_logged_in', {
    'user_id': user.uid,
    'method': 'phone',
  });
}
```

#### Step 7.2: Update Logout Flow

Clear user ID on logout:

```dart
// In your logout handler:
Future<void> _handleLogout() async {
  // ✅ ADD THIS - Clear user ID
  await CrashlyticsService.clearUserId();
  
  // Log logout event
  await CrashlyticsService.logEvent('user_logged_out');
}
```

---

### **Phase 8: Add App Version Tracking**

#### Step 8.1: Update `lib/main.dart`

Set app version and build number:

```dart
import 'package:package_info_plus/package_info_plus.dart'; // Already imported
import 'package:Chamak/services/crashlytics_service.dart'; // ✅ ADD THIS

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ ADD THIS - Set app version info
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    await CrashlyticsService.setCustomKeys({
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'package_name': packageInfo.packageName,
    });
  } catch (e) {
    debugPrint('⚠️ Failed to set app version in Crashlytics: $e');
  }
  
  // ... rest of initialization
}
```

---

## 🎯 What Happens After Implementation

### **Immediate Benefits (Day 1)**

1. **Automatic Crash Collection**
   - All unhandled exceptions are automatically captured
   - Crashes appear in Firebase Console within minutes
   - No code changes needed for basic crash reporting

2. **Real-time Monitoring**
   - See crashes as they happen
   - Get email alerts for critical issues
   - Monitor crash-free percentage

3. **Better Debugging**
   - Full stack traces for all crashes
   - Device information (model, OS, memory)
   - User actions before crash

### **Short-term Benefits (Week 1-2)**

1. **Issue Identification**
   - Identify most common crashes
   - See crash patterns and trends
   - Prioritize fixes based on impact

2. **User Context**
   - See which users are affected
   - Track crashes per user
   - Filter by user segments

3. **Stability Metrics**
   - Track crash-free percentage
   - Monitor stability over time
   - Set stability goals

### **Long-term Benefits (Month 1+)**

1. **Proactive Issue Resolution**
   - Fix issues before users report
   - Reduce support tickets
   - Improve user satisfaction

2. **Data-Driven Development**
   - Prioritize fixes based on crash frequency
   - Identify problematic features
   - Make informed decisions

3. **Quality Improvement**
   - Track stability improvements
   - Measure impact of bug fixes
   - Maintain high quality standards

---

## 👨‍💻 Senior Developer Best Practices

### **1. Error Classification**

**Fatal Errors** (app crashes):
- Unhandled exceptions
- System-level errors
- Critical failures

**Non-Fatal Errors** (caught exceptions):
- Network timeouts
- Validation errors
- Business logic failures
- User input errors

```dart
// Fatal error (app will crash)
FlutterError.onError = (errorDetails) {
  FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
};

// Non-fatal error (caught in try-catch)
try {
  // Some operation
} catch (e, stackTrace) {
  CrashlyticsService.logError(e, stackTrace, fatal: false);
}
```

### **2. Context is King**

Always add context to error logs:

```dart
// ❌ BAD - No context
CrashlyticsService.logError(error, stackTrace);

// ✅ GOOD - With context
CrashlyticsService.logError(
  error,
  stackTrace,
  context: 'Payment processing failed for order ${orderId}',
  fatal: false,
);

// ✅ BETTER - With custom keys
await CrashlyticsService.setCustomKeys({
  'order_id': orderId,
  'payment_method': 'payprime',
  'amount': amount.toString(),
  'user_id': userId,
});
CrashlyticsService.logError(error, stackTrace, context: 'Payment failed');
```

### **3. Breadcrumb Trail**

Log important events to track user journey:

```dart
// User opens live stream
CrashlyticsService.logEvent('live_stream_opened', {
  'stream_id': streamId,
  'host_id': hostId,
});

// User sends gift
CrashlyticsService.logEvent('gift_sent', {
  'gift_id': giftId,
  'amount': amount,
  'stream_id': streamId,
});

// User joins channel
CrashlyticsService.logEvent('agora_channel_joined', {
  'channel_name': channelName,
  'user_role': 'viewer',
});
```

### **4. User Identification**

Always set user ID after login:

```dart
// After successful login
await CrashlyticsService.setUserId(user.uid);

// After logout
await CrashlyticsService.clearUserId();
```

### **5. Custom Keys for Context**

Set custom keys for important app state:

```dart
// App version
await CrashlyticsService.setCustomKey('app_version', '1.0.8');

// Feature flags
await CrashlyticsService.setCustomKey('new_payment_enabled', true);

// User subscription
await CrashlyticsService.setCustomKey('subscription_tier', 'premium');

// Network status
await CrashlyticsService.setCustomKey('network_type', 'wifi');
```

### **6. Don't Log Sensitive Data**

**Never log:**
- Passwords
- Credit card numbers
- API keys
- Personal information (unless necessary)

**Safe to log:**
- User IDs (hashed if possible)
- Error messages
- Device info
- App state
- Feature flags

### **7. Debug vs Production**

Disable Crashlytics in debug mode (optional):

```dart
void main() async {
  // ... Firebase initialization
  
  // Disable Crashlytics in debug mode (optional)
  if (kDebugMode) {
    await CrashlyticsService.setCrashlyticsCollectionEnabled(false);
  } else {
    await CrashlyticsService.setCrashlyticsCollectionEnabled(true);
  }
  
  // ... rest of initialization
}
```

### **8. Error Handling Best Practices**

**Always handle errors gracefully:**

```dart
// ❌ BAD - Let error propagate
Future<void> processPayment() async {
  final result = await paymentApi.charge(amount);
  // If this throws, app might crash
}

// ✅ GOOD - Catch and log
Future<void> processPayment() async {
  try {
    final result = await paymentApi.charge(amount);
    // Success handling
  } catch (e, stackTrace) {
    // Log to Crashlytics
    CrashlyticsService.logError(
      e,
      stackTrace,
      context: 'Payment processing failed',
      fatal: false,
    );
    
    // Show user-friendly message
    showErrorSnackBar('Payment failed. Please try again.');
  }
}
```

### **9. Monitor and Act**

**Daily:**
- Check crash reports
- Review new crashes
- Prioritize fixes

**Weekly:**
- Review crash-free percentage
- Identify trends
- Plan improvements

**Monthly:**
- Analyze stability trends
- Review velocity alerts
- Update error handling

### **10. Integration with CI/CD**

Add Crashlytics to your build process:

```yaml
# .github/workflows/build.yml
- name: Build and upload symbols
  run: |
    flutter build apk --release
    # Upload symbols for better stack traces
```

---

## 🔗 Integration with Your Current Code

### **Files to Update:**

1. **`pubspec.yaml`** ✅
   - Add `firebase_crashlytics: ^4.1.3`

2. **`android/app/build.gradle`** ✅
   - Add Crashlytics dependency
   - Apply Crashlytics plugin

3. **`android/build.gradle`** ✅
   - Add Crashlytics Gradle plugin

4. **`lib/main.dart`** ✅
   - Initialize Crashlytics
   - Set error handlers
   - Set app version

5. **`lib/services/crashlytics_service.dart`** ✅ (NEW)
   - Create centralized service

6. **`lib/screens/otp_screen.dart`** ✅
   - Add error logging

7. **`lib/screens/agora_live_stream_screen.dart`** ✅
   - Add Agora error logging

8. **`lib/services/payprime_payment_service.dart`** ✅
   - Add payment error logging

9. **Login/Auth screens** ✅
   - Set user ID after login
   - Clear user ID on logout

### **Estimated Implementation Time:**

- **Basic Setup:** 1-2 hours
- **Service Creation:** 30 minutes
- **Integration:** 2-3 hours
- **Testing:** 1 hour
- **Total:** 4-6 hours

---

## 📊 Monitoring & Alerts Setup

### **1. Firebase Console Dashboard**

**Access:**
1. Go to Firebase Console
2. Select your project
3. Click "Crashlytics" in left menu

**What You'll See:**
- Crash-free user percentage
- Number of crashes
- Crash groups
- Affected users
- Device/OS breakdown

### **2. Velocity Alerts**

**Setup:**
1. Go to Crashlytics → Settings
2. Click "Alerts"
3. Enable "Velocity alerts"
4. Set threshold (e.g., 5 crashes in 1 hour)
5. Add email addresses

**What You'll Get:**
- Email when crash rate spikes
- Notifications for critical issues
- Daily/weekly summaries

### **3. Crash Grouping**

Crashlytics automatically groups similar crashes:
- Same stack trace = same group
- Helps identify patterns
- Prioritize fixes

### **4. Crash Details**

Each crash report includes:
- **Stack trace** (full, symbolicated)
- **Device info** (model, OS, memory)
- **App version** (version, build number)
- **User info** (user ID, custom keys)
- **Breadcrumbs** (events before crash)
- **Timeline** (when crash occurred)

---

## ✅ Production Checklist

### **Before Going Live:**

- [ ] Crashlytics dependency added to `pubspec.yaml`
- [ ] Android configuration updated
- [ ] Crashlytics initialized in `main.dart`
- [ ] Error handlers set up
- [ ] `CrashlyticsService` created
- [ ] User ID set after login
- [ ] App version tracked
- [ ] Critical errors logged
- [ ] Test crash sent (see below)
- [ ] Velocity alerts configured
- [ ] Team notified of alerts

### **Test Crash (Optional):**

Add a test button to verify Crashlytics is working:

```dart
// In debug mode only
if (kDebugMode) {
  FloatingActionButton(
    onPressed: () {
      // Test fatal crash
      throw Exception('Test crash from Crashlytics');
    },
    child: Icon(Icons.bug_report),
  );
}
```

**Or use Crashlytics test crash:**

```dart
// Test non-fatal error
CrashlyticsService.logError(
  'Test error',
  StackTrace.current,
  context: 'Testing Crashlytics integration',
  fatal: false,
);
```

---

## 📈 Expected Results

### **Week 1:**
- Start seeing crash reports
- Identify most common issues
- Set up monitoring

### **Week 2-4:**
- Fix high-priority crashes
- See crash-free percentage improve
- Better understanding of issues

### **Month 2+:**
- Stable crash-free percentage
- Proactive issue resolution
- Data-driven development

### **Target Metrics:**
- **Crash-free percentage:** > 99%
- **Response time:** < 24 hours for critical crashes
- **Fix rate:** > 80% of crashes fixed within 1 week

---

## 🚨 Common Issues & Solutions

### **Issue 1: Crashes Not Appearing**

**Solution:**
- Check Firebase Console → Crashlytics is enabled
- Verify `google-services.json` is correct
- Ensure Crashlytics plugin is applied
- Check app is in release mode (or enable debug collection)

### **Issue 2: Stack Traces Not Symbolicated**

**Solution:**
- Upload ProGuard mapping file (for release builds)
- Ensure build is not obfuscated in debug mode
- Check Firebase Console → Settings → Symbols

### **Issue 3: Too Many Non-Fatal Errors**

**Solution:**
- Review error logging strategy
- Only log important errors
- Use custom keys instead of logging every error

### **Issue 4: User ID Not Set**

**Solution:**
- Verify `setUserId()` is called after login
- Check user ID is not empty
- Ensure it's called on app startup if user is already logged in

---

## 📚 Additional Resources

- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Flutter Crashlytics Guide](https://firebase.google.com/docs/crashlytics/flutter/get-started)
- [Best Practices](https://firebase.google.com/docs/crashlytics/best-practices)
- [Velocity Alerts](https://firebase.google.com/docs/crashlytics/get-started?platform=flutter#set-up-alerts)

---

## 🎉 Summary

**Firebase Crashlytics** is essential for production apps. It provides:
- ✅ Real-time crash reporting
- ✅ Detailed error context
- ✅ User journey tracking
- ✅ Stability monitoring
- ✅ Proactive issue detection

**Implementation is straightforward:**
1. Add dependency
2. Configure Android
3. Initialize in Flutter
4. Integrate with error handling
5. Set user context

**After implementation, you'll have:**
- Full visibility into production issues
- Better debugging capabilities
- Data-driven development
- Improved app stability
- Better user experience

**Next Steps:**
1. Follow the step-by-step guide above
2. Test with a test crash
3. Monitor Firebase Console
4. Set up alerts
5. Start fixing issues!

---

**Report Generated:** January 2025  
**Status:** Ready for Implementation  
**Priority:** 🔴 **HIGH** - Essential for Production
