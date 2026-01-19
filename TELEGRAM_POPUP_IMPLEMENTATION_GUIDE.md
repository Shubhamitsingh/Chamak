# 🚀 Telegram Popup UI - Implementation Guide

## Quick Start

This guide provides step-by-step instructions to implement the Telegram channel promotion popup matching your reference design.

---

## Step 1: Create Telegram Popup Service

**File:** `lib/services/telegram_popup_service.dart`

```dart
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
    // Don't show if user already joined
    if (await hasJoinedTelegram()) return false;
    
    // Don't show if dismissed recently
    if (await wasDismissedRecently()) return false;
    
    // Don't show if already shown in this session
    if (await shownInCurrentSession()) return false;
    
    return true;
  }
  
  /// Reset session flag (call on app start)
  Future<void> resetSessionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShownInSession, false);
  }
}
```

---

## Step 2: Create Telegram Popup Widget

**File:** `lib/widgets/telegram_channel_popup.dart`

```dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/telegram_popup_service.dart';

class TelegramChannelPopup extends StatefulWidget {
  final String telegramChannelUrl;
  final String appName;
  final TelegramPopupService popupService;
  
  const TelegramChannelPopup({
    super.key,
    required this.telegramChannelUrl,
    required this.appName,
    required this.popupService,
  });

  @override
  State<TelegramChannelPopup> createState() => _TelegramChannelPopupState();
}

class _TelegramChannelPopupState extends State<TelegramChannelPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _soundWaveController;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    // Animation for sound waves (optional)
    _soundWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _soundWaveController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinTelegram() async {
    if (_isJoining) return;
    
    setState(() => _isJoining = true);
    
    try {
      // Mark as joined
      await widget.popupService.markAsJoined();
      
      // Open Telegram link
      final uri = Uri.parse(widget.telegramChannelUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open Telegram. Please install Telegram app.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
      // Close popup after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop(true); // true = user joined
      }
    } catch (e) {
      debugPrint('Error opening Telegram: $e');
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _handleSkip() async {
    await widget.popupService.recordDismissal();
    if (mounted) {
      Navigator.of(context).pop(false); // false = user skipped
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient and megaphone
              _buildHeader(),
              
              // Content box
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B9D), // Pink
            Color(0xFFFF8E53), // Orange
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Megaphone icon with sound waves
          FadeInLeft(
            duration: const Duration(milliseconds: 500),
            child: _buildMegaphoneIcon(),
          ),
          const SizedBox(width: 12),
          // "Notice" text
          const Expanded(
            child: FadeInRight(
              duration: Duration(milliseconds: 500),
              child: Text(
                'Notice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMegaphoneIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Sound waves animation
        AnimatedBuilder(
          animation: _soundWaveController,
          builder: (context, child) {
            return CustomPaint(
              painter: SoundWavePainter(
                progress: _soundWaveController.value,
              ),
              size: const Size(40, 40),
            );
          },
        ),
        // Megaphone icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF9C27B0), // Purple
                Color(0xFF2196F3), // Blue
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.campaign,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message with bell icon
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 100),
            child: _buildWelcomeMessage(),
          ),
          
          const SizedBox(height: 16),
          
          // Call to action text
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: _buildCallToAction(),
          ),
          
          const SizedBox(height: 20),
          
          // Benefits list
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 300),
            child: _buildBenefitsList(),
          ),
          
          const SizedBox(height: 24),
          
          // Join button
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 400),
            child: _buildJoinButton(),
          ),
          
          const SizedBox(height: 12),
          
          // Direct link
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 500),
            child: _buildDirectLink(),
          ),
          
          const SizedBox(height: 8),
          
          // Skip button
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 600),
            child: _buildSkipButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notifications_active,
            color: Color(0xFFFFD700),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Welcome to Our Platform!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallToAction() {
    return Text(
      'Stay updated and enjoy exclusive benefits by joining our official Telegram channel:',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
        height: 1.5,
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {'emoji': '🎁', 'text': 'Special user rewards'},
      {'emoji': '🎉', 'text': 'Priority access to events'},
      {'emoji': '🧧', 'text': 'Lucky draws & bonus activities'},
    ];

    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                benefit['emoji']!,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  benefit['text']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isJoining ? null : _handleJoinTelegram,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3), // Blue
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isJoining
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('👍', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'Join the Official Telegram Channel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDirectLink() {
    return Center(
      child: Column(
        children: [
          Text(
            'Or open the link:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: _handleJoinTelegram,
            child: Text(
              widget.telegramChannelUrl,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2196F3),
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _handleSkip,
        child: Text(
          'Skip',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Custom painter for sound waves animation
class SoundWavePainter extends CustomPainter {
  final double progress;

  SoundWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 3 sound wave arcs
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.3) % 1.0;
      final waveRadius = radius + (waveProgress * 15);
      final opacity = 1.0 - waveProgress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: waveRadius),
        -0.5,
        1.0,
        false,
        paint..color = Colors.white.withOpacity(opacity * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(SoundWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
```

---

## Step 3: Integrate with Home Screen

**File:** `lib/screens/home_screen.dart`

Add these imports at the top:

```dart
import '../widgets/telegram_channel_popup.dart';
import '../services/telegram_popup_service.dart';
```

Add service instance in `_HomeScreenState`:

```dart
final TelegramPopupService _telegramPopupService = TelegramPopupService();
```

Add popup check in `initState()` method (after existing popup checks):

```dart
@override
void initState() {
  super.initState();
  // ... existing code ...
  
  // Telegram Channel Popup
  // Show after 2-3 seconds delay, only if conditions are met
  Future.delayed(const Duration(seconds: 2), () {
    _checkAndShowTelegramPopup();
  });
  
  // Reset session flag on app start
  _telegramPopupService.resetSessionFlag();
}
```

Add the method to check and show popup:

```dart
Future<void> _checkAndShowTelegramPopup() async {
  if (!mounted) return;
  
  // Check if should show popup
  final shouldShow = await _telegramPopupService.shouldShowPopup();
  if (!shouldShow) return;
  
  // Check if user is in live stream (don't show during live)
  if (_isLiveReelsFullScreen) {
    return; // Don't show during live streams
  }
  
  // Mark as shown in session
  await _telegramPopupService.markShownInSession();
  await _telegramPopupService.incrementShowCount();
  
  // Show popup
  if (!mounted) return;
  
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true, // Allow tap outside to dismiss
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => TelegramChannelPopup(
      telegramChannelUrl: 'https://t.me/your_channel_name', // ⚠️ CHANGE THIS
      appName: 'Chamak', // ⚠️ CHANGE THIS
      popupService: _telegramPopupService,
    ),
  );
  
  // Handle result (optional analytics)
  if (result == true) {
    debugPrint('✅ User joined Telegram channel');
    // Track analytics: user joined
  } else {
    debugPrint('❌ User skipped Telegram popup');
    // Track analytics: user skipped
  }
}
```

---

## Step 4: Configuration

### Update Telegram Channel URL

In `home_screen.dart`, replace:
```dart
telegramChannelUrl: 'https://t.me/your_channel_name',
```

With your actual Telegram channel URL:
```dart
telegramChannelUrl: 'https://t.me/chamak_official', // Example
```

### Update App Name

Replace:
```dart
appName: 'Chamak',
```

With your app's display name.

---

## Step 5: Customization Options

### Change Colors

In `telegram_channel_popup.dart`, modify gradient colors:

```dart
// Header gradient
colors: [
  Color(0xFFFF6B9D), // Pink - Change this
  Color(0xFFFF8E53), // Orange - Change this
],

// Megaphone gradient
colors: [
  Color(0xFF9C27B0), // Purple - Change this
  Color(0xFF2196F3), // Blue - Change this
],

// Join button color
backgroundColor: const Color(0xFF2196F3), // Blue - Change this
```

### Change Benefits

In `_buildBenefitsList()`, modify the benefits array:

```dart
final benefits = [
  {'emoji': '🎁', 'text': 'Special user rewards'},
  {'emoji': '🎉', 'text': 'Priority access to events'},
  {'emoji': '🧧', 'text': 'Lucky draws & bonus activities'},
  // Add more benefits here
];
```

### Change Timing

In `home_screen.dart`, modify delay:

```dart
// Show after 2 seconds (change to your preference)
Future.delayed(const Duration(seconds: 2), () {
  _checkAndShowTelegramPopup();
});
```

### Change Frequency Capping

In `telegram_popup_service.dart`, modify:

```dart
// Days to wait before showing again after dismissal
static const int _dismissalCooldownDays = 7; // Change to your preference
```

---

## Step 6: Testing

### Test Cases

1. **First Time User**
   - ✅ Popup shows after 2 seconds
   - ✅ Can join Telegram
   - ✅ Can skip popup

2. **User Who Skipped**
   - ✅ Popup doesn't show again for 7 days
   - ✅ After 7 days, popup shows again

3. **User Who Joined**
   - ✅ Popup never shows again
   - ✅ Telegram opens correctly

4. **During Live Stream**
   - ✅ Popup doesn't show during live streams

5. **Multiple Sessions**
   - ✅ Popup shows once per session maximum

### Manual Testing

```dart
// Test: Force show popup (add to home_screen.dart temporarily)
Future.delayed(const Duration(seconds: 1), () {
  showDialog(
    context: context,
    builder: (context) => TelegramChannelPopup(
      telegramChannelUrl: 'https://t.me/your_channel_name',
      appName: 'Chamak',
      popupService: _telegramPopupService,
    ),
  );
});
```

---

## Step 7: Analytics (Optional)

Add analytics tracking in `_checkAndShowTelegramPopup()`:

```dart
// Track popup shown
FirebaseAnalytics.instance.logEvent(
  name: 'telegram_popup_shown',
  parameters: {
    'show_count': await _telegramPopupService.getShowCount(),
  },
);

// Track user joined
if (result == true) {
  FirebaseAnalytics.instance.logEvent(
    name: 'telegram_popup_joined',
  );
}

// Track user skipped
if (result == false) {
  FirebaseAnalytics.instance.logEvent(
    name: 'telegram_popup_skipped',
  );
}
```

---

## Troubleshooting

### Popup Not Showing

1. Check `shouldShowPopup()` returns `true`
2. Check delay timer is working
3. Check user is not in live stream
4. Check session flag is reset on app start

### Telegram Not Opening

1. Check URL format: `https://t.me/channel_name`
2. Check `url_launcher` package is added
3. Check device has Telegram installed
4. Test URL in browser first

### Performance Issues

1. Reduce animation complexity
2. Use `RepaintBoundary` for animations
3. Test on low-end devices
4. Simplify gradient effects if needed

---

## Next Steps

1. ✅ Implement service (`telegram_popup_service.dart`)
2. ✅ Implement widget (`telegram_channel_popup.dart`)
3. ✅ Integrate with home screen
4. ✅ Configure Telegram URL
5. ✅ Test on device
6. ✅ Deploy to production

---

**Ready to implement?** Follow the steps above, and your Telegram popup will be ready in no time! 🚀
