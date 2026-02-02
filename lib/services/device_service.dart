import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// Get unique device ID
  /// Returns a unique identifier for the device/app installation
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use Android ID (unique per app installation)
        // This changes if user uninstalls and reinstalls app
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use identifierForVendor (unique per app)
        // This changes if user uninstalls and reinstalls app
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      }
      return 'unknown_device';
    } catch (e) {
      debugPrint('❌ [DEVICE SERVICE] Error getting device ID: $e');
      return 'unknown_device';
    }
  }
  
  /// Get device name/model for display
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      }
      return 'Unknown Device';
    } catch (e) {
      debugPrint('❌ [DEVICE SERVICE] Error getting device name: $e');
      return 'Unknown Device';
    }
  }
  
  /// Get device platform info
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'deviceId': androidInfo.id,
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'version': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
        };
      }
      return {'platform': 'Unknown'};
    } catch (e) {
      debugPrint('❌ [DEVICE SERVICE] Error getting device info: $e');
      return {'platform': 'Unknown', 'error': e.toString()};
    }
  }
}
