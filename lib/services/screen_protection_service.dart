import 'package:screen_protector/screen_protector.dart';
import 'package:flutter/foundation.dart';

/// Service to manage screenshot and screen recording prevention
/// 
/// This service prevents users from taking screenshots or recording
/// the screen while using sensitive features like live streaming
/// or video calls.
class ScreenProtectionService {
  static final ScreenProtectionService _instance = ScreenProtectionService._internal();
  factory ScreenProtectionService() => _instance;
  ScreenProtectionService._internal();

  bool _isProtected = false;

  /// Check if screen protection is currently active
  bool get isProtected => _isProtected;

  /// Enable screen protection (prevent screenshots and screen recording)
  /// 
  /// Call this when entering sensitive screens like:
  /// - Live streaming
  /// - Video calls
  /// - Private chats
  /// - Payment screens
  Future<void> enableProtection() async {
    if (_isProtected) {
      debugPrint('🛡️ Screen protection already enabled');
      return;
    }

    try {
      // Enable screenshot and screen recording prevention
      // protectDataLeakageOn() prevents both screenshots and screen recording
      await ScreenProtector.protectDataLeakageOn();
      
      _isProtected = true;
      debugPrint('🛡️ Screen protection ENABLED - Screenshots and screen recording blocked');
    } catch (e) {
      debugPrint('⚠️ Failed to enable screen protection: $e');
      // Don't throw - allow app to continue even if protection fails
    }
  }

  /// Disable screen protection (allow screenshots and screen recording)
  /// 
  /// Call this when leaving sensitive screens
  Future<void> disableProtection() async {
    if (!_isProtected) {
      debugPrint('🛡️ Screen protection already disabled');
      return;
    }

    try {
      // Disable screenshot and screen recording prevention
      await ScreenProtector.protectDataLeakageOff();
      
      _isProtected = false;
      debugPrint('🛡️ Screen protection DISABLED - Screenshots and screen recording allowed');
    } catch (e) {
      debugPrint('⚠️ Failed to disable screen protection: $e');
      // Don't throw - allow app to continue even if protection fails
    }
  }

  /// Toggle screen protection on/off
  Future<void> toggleProtection() async {
    if (_isProtected) {
      await disableProtection();
    } else {
      await enableProtection();
    }
  }

  /// Enable protection for the entire app (global protection)
  /// 
  /// Use this if you want to prevent screenshots everywhere in the app
  Future<void> enableGlobalProtection() async {
    await enableProtection();
    debugPrint('🛡️ Global screen protection enabled for entire app');
  }

  /// Disable global protection
  Future<void> disableGlobalProtection() async {
    await disableProtection();
    debugPrint('🛡️ Global screen protection disabled');
  }
}
