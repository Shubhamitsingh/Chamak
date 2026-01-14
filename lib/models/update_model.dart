/// Model class for app update information
class UpdateModel {
  final String latestVersion;
  final String currentVersion;
  final bool updateAvailable;
  final bool forceUpdate;
  final List<String> features;
  final List<String> improvements;
  final List<String> bugFixes;
  final String updateMessage;
  final DateTime? releaseDate;

  UpdateModel({
    required this.latestVersion,
    required this.currentVersion,
    required this.updateAvailable,
    this.forceUpdate = false,
    this.features = const [],
    this.improvements = const [],
    this.bugFixes = const [],
    this.updateMessage = '',
    this.releaseDate,
  });

  /// Create UpdateModel from Firebase Remote Config data
  factory UpdateModel.fromRemoteConfig({
    required String currentVersion,
    required Map<String, dynamic> remoteData,
  }) {
    final latestVersion = remoteData['latest_version'] as String? ?? currentVersion;
    final updateDetails = remoteData['update_details'] as Map<String, dynamic>? ?? {};
    
    final updateAvailable = _compareVersions(currentVersion, latestVersion) < 0;
    
    return UpdateModel(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      updateAvailable: updateAvailable,
      forceUpdate: updateDetails['force_update'] as bool? ?? false,
      features: (updateDetails['features'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      improvements: (updateDetails['improvements'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      bugFixes: (updateDetails['bug_fixes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      updateMessage: updateDetails['update_message'] as String? ?? 
          'A new version is available with exciting features and improvements!',
      releaseDate: updateDetails['release_date'] != null
          ? DateTime.tryParse(updateDetails['release_date'].toString())
          : null,
    );
  }

  /// Compare two version strings (e.g., "1.0.6" vs "1.0.7")
  /// Returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    // Pad with zeros if lengths differ
    while (parts1.length < parts2.length) parts1.add(0);
    while (parts2.length < parts1.length) parts2.add(0);
    
    for (int i = 0; i < parts1.length; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  /// Create a default "up to date" model
  factory UpdateModel.upToDate(String currentVersion) {
    return UpdateModel(
      latestVersion: currentVersion,
      currentVersion: currentVersion,
      updateAvailable: false,
      updateMessage: 'You are using the latest version of the app.',
    );
  }
}
