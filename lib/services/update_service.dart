import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/update_model.dart';

/// Service class for checking app updates
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  /// Initialize Firebase Remote Config
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set default values (fallback if Firebase is not configured)
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set defaults (only strings, numbers, and booleans are allowed)
      await _remoteConfig!.setDefaults({
        'latest_version': '1.0.6',
        'update_details_features': '',
        'update_details_improvements': '',
        'update_details_bug_fixes': '',
        'update_details_force_update': false,
        'update_details_message': 'A new version is available!',
      });

      // Fetch from Firebase
      try {
        await _remoteConfig!.fetchAndActivate();
        debugPrint('✅ Remote Config fetched successfully');
      } catch (e) {
        debugPrint('⚠️ Remote Config fetch failed: $e (using defaults)');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('❌ Error initializing Remote Config: $e');
      _initialized = false;
    }
  }

  /// Get current app version
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version; // e.g., "1.0.6"
    } catch (e) {
      debugPrint('Error getting app version: $e');
      return '1.0.6'; // Fallback
    }
  }

  /// Check for available updates
  Future<UpdateModel> checkForUpdates() async {
    try {
      // Ensure Remote Config is initialized
      if (!_initialized) {
        await initialize();
      }

      // Get current version
      final currentVersion = await getCurrentVersion();

      // If Remote Config is not available, return up-to-date status
      if (_remoteConfig == null || !_initialized) {
        debugPrint('⚠️ Remote Config not available, returning up-to-date status');
        return UpdateModel.upToDate(currentVersion);
      }

      // Get latest version from Remote Config
      final latestVersion = _remoteConfig!.getString('latest_version');
      
      // Get update details from individual Remote Config parameters
      final featuresStr = _remoteConfig!.getString('update_details_features');
      final improvementsStr = _remoteConfig!.getString('update_details_improvements');
      final bugFixesStr = _remoteConfig!.getString('update_details_bug_fixes');
      final forceUpdate = _remoteConfig!.getBool('update_details_force_update');
      final updateMessage = _remoteConfig!.getString('update_details_message');
      
      // Build update details map
      Map<String, dynamic> updateDetails = {
        'version': latestVersion,
        'features': featuresStr.isNotEmpty
            ? featuresStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : [],
        'improvements': improvementsStr.isNotEmpty
            ? improvementsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : [],
        'bug_fixes': bugFixesStr.isNotEmpty
            ? bugFixesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : [],
        'force_update': forceUpdate,
        'update_message': updateMessage.isNotEmpty 
            ? updateMessage 
            : 'A new version is available with exciting features and improvements!',
      };

      // Create UpdateModel
      final updateModel = UpdateModel.fromRemoteConfig(
        currentVersion: currentVersion,
        remoteData: {
          'latest_version': latestVersion,
          'update_details': updateDetails,
        },
      );

      debugPrint('📱 Current Version: $currentVersion');
      debugPrint('🆕 Latest Version: $latestVersion');
      debugPrint('🔄 Update Available: ${updateModel.updateAvailable}');

      return updateModel;
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      // Return up-to-date status on error
      final currentVersion = await getCurrentVersion();
      return UpdateModel.upToDate(currentVersion);
    }
  }

  /// Force fetch latest data from Firebase
  Future<void> refresh() async {
    if (_remoteConfig != null && _initialized) {
      try {
        await _remoteConfig!.fetchAndActivate();
        debugPrint('✅ Remote Config refreshed');
      } catch (e) {
        debugPrint('⚠️ Error refreshing Remote Config: $e');
      }
    }
  }
}
