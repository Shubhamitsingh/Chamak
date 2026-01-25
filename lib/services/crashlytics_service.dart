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
