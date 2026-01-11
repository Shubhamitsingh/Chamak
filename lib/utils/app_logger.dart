import 'package:flutter/foundation.dart';

/// Production-ready logger utility
/// Replaces all print() statements with proper logging
class AppLogger {
  static final bool _isDebugMode = kDebugMode;
  
  /// Debug level logging (only in debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_isDebugMode) {
      debugPrint('🐛 DEBUG: $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   StackTrace: $stackTrace');
      }
    }
  }
  
  /// Info level logging (only in debug mode)
  static void info(String message) {
    if (_isDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }
  
  /// Warning level logging (always logged)
  static void warning(String message, [Object? error]) {
    debugPrint('⚠️ WARNING: $message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    // In production, send to crash reporting service
  }
  
  /// Error level logging (always logged)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ ERROR: $message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   StackTrace: $stackTrace');
    }
    // In production, send to crash reporting service (Firebase Crashlytics)
  }
  
  /// Success level logging (only in debug mode)
  static void success(String message) {
    if (_isDebugMode) {
      debugPrint('✅ SUCCESS: $message');
    }
  }
  
  /// Network request logging (only in debug mode)
  static void network(String method, String url, [Map<String, dynamic>? data]) {
    if (_isDebugMode) {
      debugPrint('🌐 NETWORK: $method $url');
      if (data != null) {
        debugPrint('   Data: $data');
      }
    }
  }
  
  /// Payment transaction logging (sensitive - only in debug mode)
  static void payment(String message, [Map<String, dynamic>? data]) {
    if (_isDebugMode) {
      debugPrint('💳 PAYMENT: $message');
      if (data != null) {
        // Don't log sensitive payment data in production
        debugPrint('   Data: $data');
      }
    }
  }
}
