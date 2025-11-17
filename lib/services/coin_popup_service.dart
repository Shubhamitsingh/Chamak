import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage coin purchase popup display logic
/// Ensures popup is shown strategically without annoying users
class CoinPopupService {
  // ⚠️ TEST MODE: Set to true to show popup EVERY TIME (for testing)
  // 🚀 PRODUCTION: Set to false before releasing app
  static const bool TEST_MODE = true; // ← Change this to false for production!
  
  static const String _keyLastShown = 'coin_popup_last_shown';
  static const String _keyShowCount = 'coin_popup_show_count';
  static const String _keyDontShowAgain = 'coin_popup_dont_show';
  static const String _keyRemindLater = 'coin_popup_remind_later';
  static const String _keyFirstInstall = 'app_first_install_date';
  
  // Configuration
  static const int _maxShowsPerWeek = 3;
  static const int _daysBetweenShows = 2; // Minimum days between popups
  static const int _daysBeforeFirstShow = 3; // Wait 3 days for new users
  static const int _remindLaterDays = 3; // Show again after 3 days if "Remind Later"
  
  /// Check if popup should be shown based on smart logic
  Future<bool> shouldShowPopup({
    required int userCoins,
    int? userActiveDays,
  }) async {
    // 🧪 TEST MODE: Always show popup (bypass all checks)
    if (TEST_MODE) {
      return true; // Show every time in test mode!
    }
    
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user disabled popup permanently
    final dontShow = prefs.getBool(_keyDontShowAgain) ?? false;
    if (dontShow) {
      return false;
    }
    
    // Check if user clicked "Remind Later"
    final remindLaterDate = prefs.getString(_keyRemindLater);
    if (remindLaterDate != null) {
      final remindDate = DateTime.parse(remindLaterDate);
      final daysSinceRemind = DateTime.now().difference(remindDate).inDays;
      if (daysSinceRemind < _remindLaterDays) {
        return false; // Still within "Remind Later" period
      } else {
        // Clear remind later flag after period expires
        await prefs.remove(_keyRemindLater);
      }
    }
    
    // Check if new user (wait 3 days before showing)
    final firstInstall = prefs.getString(_keyFirstInstall);
    if (firstInstall == null) {
      await prefs.setString(_keyFirstInstall, DateTime.now().toIso8601String());
      return false; // First time, don't show
    }
    
    final installDate = DateTime.parse(firstInstall);
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;
    if (daysSinceInstall < _daysBeforeFirstShow) {
      return false; // Too soon for new users
    }
    
    // Check when popup was last shown
    final lastShownStr = prefs.getString(_keyLastShown);
    if (lastShownStr != null) {
      final lastShown = DateTime.parse(lastShownStr);
      final daysSinceLastShow = DateTime.now().difference(lastShown).inDays;
      
      if (daysSinceLastShow < _daysBetweenShows) {
        return false; // Too soon since last show
      }
    }
    
    // Check weekly show count
    final showCount = await _getWeeklyShowCount();
    if (showCount >= _maxShowsPerWeek) {
      return false; // Already shown max times this week
    }
    
    // Smart conditions: Show if coins are low
    if (userCoins < 100) {
      return true;
    }
    
    // Show to active users occasionally (every 7 days if not shown)
    if (lastShownStr != null) {
      final lastShown = DateTime.parse(lastShownStr);
      final daysSinceLastShow = DateTime.now().difference(lastShown).inDays;
      if (daysSinceLastShow >= 7) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Record that popup was shown
  Future<void> recordPopupShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastShown, DateTime.now().toIso8601String());
    
    // Increment weekly show count
    final currentCount = await _getWeeklyShowCount();
    await prefs.setInt(_keyShowCount, currentCount + 1);
  }
  
  /// User clicked "Don't Show Again"
  Future<void> setDontShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDontShowAgain, true);
  }
  
  /// User clicked "Remind Me Later"
  Future<void> setRemindLater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRemindLater, DateTime.now().toIso8601String());
  }
  
  /// Reset all popup preferences (for testing)
  Future<void> resetPopupPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastShown);
    await prefs.remove(_keyShowCount);
    await prefs.remove(_keyDontShowAgain);
    await prefs.remove(_keyRemindLater);
  }
  
  /// Get weekly show count (resets every Monday)
  Future<int> _getWeeklyShowCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownStr = prefs.getString(_keyLastShown);
    
    if (lastShownStr == null) {
      return 0;
    }
    
    final lastShown = DateTime.parse(lastShownStr);
    final now = DateTime.now();
    
    // Check if it's a new week (reset on Monday)
    final lastMonday = _getLastMonday(lastShown);
    final currentMonday = _getLastMonday(now);
    
    if (currentMonday.isAfter(lastMonday)) {
      // New week, reset count
      await prefs.setInt(_keyShowCount, 0);
      return 0;
    }
    
    return prefs.getInt(_keyShowCount) ?? 0;
  }
  
  /// Get the last Monday from a given date
  DateTime _getLastMonday(DateTime date) {
    final weekday = date.weekday;
    final daysToSubtract = weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day).subtract(
      Duration(days: daysToSubtract),
    );
  }
  
  /// Check if popup can be shown today (for UI indicators)
  Future<bool> canShowToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownStr = prefs.getString(_keyLastShown);
    
    if (lastShownStr == null) {
      return true;
    }
    
    final lastShown = DateTime.parse(lastShownStr);
    final today = DateTime.now();
    
    return lastShown.day != today.day ||
           lastShown.month != today.month ||
           lastShown.year != today.year;
  }
}

