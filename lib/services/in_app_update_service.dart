import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_service.dart';
import 'crashlytics_service.dart';

/// Service for handling Google Play In-App Updates
/// 
/// This service combines:
/// - Google Play In-App Updates API (native dialog, in-app download)
/// - Firebase Remote Config (update details, force update flag)
/// 
/// Usage:
/// ```dart
/// final updateService = InAppUpdateService();
/// await updateService.checkForUpdate();
/// ```
class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  /// Check for update availability and show dialog if needed
  /// 
  /// Parameters:
  /// - [forceCheck]: Force check even if checked recently
  /// - [showFlexible]: Show flexible update dialog (default: true)
  /// - [showImmediate]: Show immediate update dialog (default: true)
  /// 
  /// Returns:
  /// - true if update dialog was shown
  /// - false if no update available or already up-to-date
  Future<bool> checkForUpdate({
    bool forceCheck = false,
    bool showFlexible = true,
    bool showImmediate = true,
  }) async {
    try {
      // Check update availability from Google Play
      final appUpdateInfo = await InAppUpdate.checkForUpdate();
      
      if (kDebugMode) {
        debugPrint('📱 In-App Update Check:');
        debugPrint('   Update Available: ${appUpdateInfo.updateAvailability}');
        debugPrint('   Immediate Allowed: ${appUpdateInfo.immediateUpdateAllowed}');
        debugPrint('   Flexible Allowed: ${appUpdateInfo.flexibleUpdateAllowed}');
        debugPrint('   Available Version Code: ${appUpdateInfo.availableVersionCode}');
      }

      // Log to Crashlytics
      CrashlyticsService.logEvent('in_app_update_check', {
        'update_available': appUpdateInfo.updateAvailability.toString(),
        'immediate_allowed': appUpdateInfo.immediateUpdateAllowed.toString(),
        'flexible_allowed': appUpdateInfo.flexibleUpdateAllowed.toString(),
      });

      // Check if update is available
      if (appUpdateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        if (kDebugMode) {
          debugPrint('✅ App is up to date');
        }
        return false;
      }

      // Get current version for logging
      final packageInfo = await PackageInfo.fromPlatform();
      if (kDebugMode) {
        debugPrint('📱 Current Version Code: ${packageInfo.buildNumber}');
        debugPrint('🆕 Available Version Code: ${appUpdateInfo.availableVersionCode}');
      }

      // Get update details from Remote Config
      final updateService = UpdateService();
      await updateService.initialize();
      final updateModel = await updateService.checkForUpdates();

      // Determine update type based on Remote Config and Play Store
      final shouldForceUpdate = updateModel.forceUpdate;
      final canDoImmediate = appUpdateInfo.immediateUpdateAllowed;
      final canDoFlexible = appUpdateInfo.flexibleUpdateAllowed;

      // Priority: Force Update > Immediate > Flexible
      if (shouldForceUpdate && canDoImmediate && showImmediate) {
        // Force update - show immediate dialog
        return await _performImmediateUpdate(appUpdateInfo, updateModel);
      } else if (canDoImmediate && showImmediate) {
        // High priority update - show immediate dialog
        return await _performImmediateUpdate(appUpdateInfo, updateModel);
      } else if (canDoFlexible && showFlexible) {
        // Normal update - show flexible dialog
        return await _performFlexibleUpdate(appUpdateInfo, updateModel);
      }

      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking for update: $e');
      
      // Log to Crashlytics
      CrashlyticsService.logError(
        e,
        stackTrace,
        context: 'In-app update check failed',
        fatal: false,
      );
      
      return false;
    }
  }

  /// Perform immediate update (blocks app usage)
  Future<bool> _performImmediateUpdate(
    AppUpdateInfo appUpdateInfo,
    dynamic updateModel,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting immediate update...');
      }

      // Log event
      CrashlyticsService.logEvent('in_app_update_immediate_started');

      // Start immediate update flow
      final result = await InAppUpdate.performImmediateUpdate();

      if (result == AppUpdateResult.success) {
        if (kDebugMode) {
          debugPrint('✅ Immediate update completed successfully');
        }
        CrashlyticsService.logEvent('in_app_update_immediate_success');
        return true;
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        if (kDebugMode) {
          debugPrint('⚠️ User denied immediate update');
        }
        CrashlyticsService.logEvent('in_app_update_immediate_denied');
        return false;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Immediate update failed: $result');
        }
        CrashlyticsService.logEvent('in_app_update_immediate_failed', {
          'result': result.toString(),
        });
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error performing immediate update: $e');
      CrashlyticsService.logError(
        e,
        stackTrace,
        context: 'Immediate update failed',
        fatal: false,
      );
      return false;
    }
  }

  /// Perform flexible update (background download)
  Future<bool> _performFlexibleUpdate(
    AppUpdateInfo appUpdateInfo,
    dynamic updateModel,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting flexible update...');
      }

      // Log event
      CrashlyticsService.logEvent('in_app_update_flexible_started');

      // Start flexible update flow
      final result = await InAppUpdate.startFlexibleUpdate();

      if (result == AppUpdateResult.success) {
        if (kDebugMode) {
          debugPrint('✅ Flexible update started successfully');
        }
        CrashlyticsService.logEvent('in_app_update_flexible_started_success');

        // Listen for update completion
        InAppUpdate.completeFlexibleUpdate().then((_) {
          if (kDebugMode) {
            debugPrint('✅ Flexible update completed - app restart recommended');
          }
          CrashlyticsService.logEvent('in_app_update_flexible_completed');
        }).catchError((e) {
          debugPrint('❌ Error completing flexible update: $e');
          CrashlyticsService.logError(
            e,
            StackTrace.current,
            context: 'Flexible update completion failed',
            fatal: false,
          );
        });

        return true;
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        if (kDebugMode) {
          debugPrint('⚠️ User denied flexible update');
        }
        CrashlyticsService.logEvent('in_app_update_flexible_denied');
        return false;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Flexible update failed: $result');
        }
        CrashlyticsService.logEvent('in_app_update_flexible_failed', {
          'result': result.toString(),
        });
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error performing flexible update: $e');
      CrashlyticsService.logError(
        e,
        stackTrace,
        context: 'Flexible update failed',
        fatal: false,
      );
      return false;
    }
  }

  /// Check if app needs to be restarted after flexible update
  Future<bool> checkForRestart() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get update info without showing dialog
  Future<AppUpdateInfo?> getUpdateInfo() async {
    try {
      return await InAppUpdate.checkForUpdate();
    } catch (e) {
      debugPrint('❌ Error getting update info: $e');
      return null;
    }
  }
}
