import 'package:shared_preferences/shared_preferences.dart';

class TelegramPopupService {
  static const String _keyHasJoined = 'telegram_popup_has_joined';
  static const String _keyLastDismissed = 'telegram_popup_last_dismissed';
  static const String _keyShownInSession = 'telegram_popup_shown_session';
  static const String _keyShowCount = 'telegram_popup_show_count';
  
  // Days to wait before showing again after dismissal
  static const int _dismissalCooldownDays = 7;
  
  /// Check if user has already joined Telegram channel
  Future<bool> hasJoinedTelegram() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasJoined) ?? false;
  }
  
  /// Mark user as having joined Telegram
  Future<void> markAsJoined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasJoined, true);
  }
  
  /// Check if popup was dismissed recently
  Future<bool> wasDismissedRecently() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDismissed = prefs.getInt(_keyLastDismissed);
    
    if (lastDismissed == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysSinceDismissal = (now - lastDismissed) / (1000 * 60 * 60 * 24);
    
    return daysSinceDismissal < _dismissalCooldownDays;
  }
  
  /// Record that popup was dismissed
  Future<void> recordDismissal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastDismissed, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Check if popup was shown in current session
  Future<bool> shownInCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShownInSession) ?? false;
  }
  
  /// Mark popup as shown in current session
  Future<void> markShownInSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShownInSession, true);
  }
  
  /// Get total show count (for analytics)
  Future<int> getShowCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyShowCount) ?? 0;
  }
  
  /// Increment show count
  Future<void> incrementShowCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getShowCount();
    await prefs.setInt(_keyShowCount, current + 1);
  }
  
  /// Check if popup should be shown
  Future<bool> shouldShowPopup() async {
    // TEST MODE: Always show popup (for testing purposes)
    // TODO: Remove this for production - uncomment the checks below
    return true;
    
    // Production mode (uncomment when ready):
    // // Don't show if user already joined
    // if (await hasJoinedTelegram()) return false;
    // 
    // // Don't show if dismissed recently
    // if (await wasDismissedRecently()) return false;
    // 
    // // Don't show if already shown in this session
    // if (await shownInCurrentSession()) return false;
    // 
    // return true;
  }
  
  /// Reset session flag (call on app start)
  Future<void> resetSessionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShownInSession, false);
  }
}
