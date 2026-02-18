import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle rate limiting for OTP requests and attempts
class RateLimitingService {
  // Keys for SharedPreferences
  static const String _keyOtpLastSent = 'otp_last_sent_';
  static const String _keyOtpAttemptCount = 'otp_attempt_count_';
  static const String _keyOtpLockoutUntil = 'otp_lockout_until_';
  static const String _keyOtpResendCount = 'otp_resend_count_';
  
  // Rate limiting constants
  static const int _otpCooldownMinutes = 10; // 10 minutes between OTP requests
  static const int _maxOtpAttempts = 5; // Max 5 OTP verification attempts
  static const int _lockoutDurationMinutes = 15; // 15 minutes lockout after max attempts
  static const int _maxResendsPerHour = 3; // Max 3 resends per hour
  
  /// Check if OTP can be sent (rate limiting)
  /// Returns (canSend, remainingSeconds, errorMessage)
  Future<Map<String, dynamic>> canSendOTP(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyOtpLastSent$phoneNumber';
      final lastSentTimestamp = prefs.getInt(key);
      
      if (lastSentTimestamp == null) {
        // First time sending OTP
        return {
          'canSend': true,
          'remainingSeconds': 0,
          'errorMessage': null,
        };
      }
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedSeconds = (now - lastSentTimestamp) ~/ 1000;
      final cooldownSeconds = _otpCooldownMinutes * 60;
      
      if (elapsedSeconds < cooldownSeconds) {
        final remainingSeconds = cooldownSeconds - elapsedSeconds;
        return {
          'canSend': false,
          'remainingSeconds': remainingSeconds,
          'errorMessage': 'Please wait ${_formatTime(remainingSeconds)} before requesting another OTP',
        };
      }
      
      return {
        'canSend': true,
        'remainingSeconds': 0,
        'errorMessage': null,
      };
    } catch (e) {
      // On error, allow sending (fail open for better UX)
      return {
        'canSend': true,
        'remainingSeconds': 0,
        'errorMessage': null,
      };
    }
  }
  
  /// Record that OTP was sent
  Future<void> recordOTPSent(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyOtpLastSent$phoneNumber';
      await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error recording OTP sent: $e');
    }
  }
  
  /// Check if OTP can be verified (attempt limiting)
  /// Returns (canVerify, remainingAttempts, isLocked, lockoutRemainingSeconds, errorMessage)
  Future<Map<String, dynamic>> canVerifyOTP(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptKey = '$_keyOtpAttemptCount$phoneNumber';
      final lockoutKey = '$_keyOtpLockoutUntil$phoneNumber';
      
      // Check if account is locked
      final lockoutUntil = prefs.getInt(lockoutKey);
      if (lockoutUntil != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now < lockoutUntil) {
          final remainingSeconds = (lockoutUntil - now) ~/ 1000;
          return {
            'canVerify': false,
            'remainingAttempts': 0,
            'isLocked': true,
            'lockoutRemainingSeconds': remainingSeconds,
            'errorMessage': 'Account locked. Please wait ${_formatTime(remainingSeconds)} before trying again',
          };
        } else {
          // Lockout expired, reset
          await prefs.remove(lockoutKey);
          await prefs.remove(attemptKey);
        }
      }
      
      final attemptCount = prefs.getInt(attemptKey) ?? 0;
      final remainingAttempts = _maxOtpAttempts - attemptCount;
      
      if (remainingAttempts <= 0) {
        // Lock account
        final lockoutUntil = DateTime.now().add(Duration(minutes: _lockoutDurationMinutes)).millisecondsSinceEpoch;
        await prefs.setInt(lockoutKey, lockoutUntil);
        
        return {
          'canVerify': false,
          'remainingAttempts': 0,
          'isLocked': true,
          'lockoutRemainingSeconds': _lockoutDurationMinutes * 60,
          'errorMessage': 'Too many failed attempts. Account locked for ${_lockoutDurationMinutes} minutes',
        };
      }
      
      return {
        'canVerify': true,
        'remainingAttempts': remainingAttempts,
        'isLocked': false,
        'lockoutRemainingSeconds': 0,
        'errorMessage': null,
      };
    } catch (e) {
      // On error, allow verification (fail open for better UX)
      return {
        'canVerify': true,
        'remainingAttempts': _maxOtpAttempts,
        'isLocked': false,
        'lockoutRemainingSeconds': 0,
        'errorMessage': null,
      };
    }
  }
  
  /// Record successful OTP verification (reset attempts)
  Future<void> recordOTPSuccess(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptKey = '$_keyOtpAttemptCount$phoneNumber';
      final lockoutKey = '$_keyOtpLockoutUntil$phoneNumber';
      
      await prefs.remove(attemptKey);
      await prefs.remove(lockoutKey);
    } catch (e) {
      debugPrint('Error recording OTP success: $e');
    }
  }
  
  /// Record failed OTP verification (increment attempts)
  Future<void> recordOTPFailure(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attemptKey = '$_keyOtpAttemptCount$phoneNumber';
      final currentAttempts = prefs.getInt(attemptKey) ?? 0;
      await prefs.setInt(attemptKey, currentAttempts + 1);
      
      // If max attempts reached, lock account
      if (currentAttempts + 1 >= _maxOtpAttempts) {
        final lockoutKey = '$_keyOtpLockoutUntil$phoneNumber';
        final lockoutUntil = DateTime.now().add(Duration(minutes: _lockoutDurationMinutes)).millisecondsSinceEpoch;
        await prefs.setInt(lockoutKey, lockoutUntil);
      }
    } catch (e) {
      debugPrint('Error recording OTP failure: $e');
    }
  }
  
  /// Check if OTP can be resent
  Future<Map<String, dynamic>> canResendOTP(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resendKey = '$_keyOtpResendCount$phoneNumber';
      final resendTimestampKey = '${resendKey}_timestamp';
      
      final resendCount = prefs.getInt(resendKey) ?? 0;
      final lastResendTimestamp = prefs.getInt(resendTimestampKey);
      
      // Reset count if more than 1 hour has passed
      if (lastResendTimestamp != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedHours = (now - lastResendTimestamp) / (1000 * 60 * 60);
        if (elapsedHours >= 1) {
          await prefs.setInt(resendKey, 0);
          return {
            'canResend': true,
            'remainingResends': _maxResendsPerHour,
            'errorMessage': null,
          };
        }
      }
      
      if (resendCount >= _maxResendsPerHour) {
        return {
          'canResend': false,
          'remainingResends': 0,
          'errorMessage': 'Maximum resend limit reached. Please try again after 1 hour',
        };
      }
      
      return {
        'canResend': true,
        'remainingResends': _maxResendsPerHour - resendCount,
        'errorMessage': null,
      };
    } catch (e) {
      return {
        'canResend': true,
        'remainingResends': _maxResendsPerHour,
        'errorMessage': null,
      };
    }
  }
  
  /// Record that OTP was resent
  Future<void> recordOTPResent(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resendKey = '$_keyOtpResendCount$phoneNumber';
      final resendTimestampKey = '${resendKey}_timestamp';
      
      final currentCount = prefs.getInt(resendKey) ?? 0;
      await prefs.setInt(resendKey, currentCount + 1);
      await prefs.setInt(resendTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error recording OTP resend: $e');
    }
  }
  
  /// Format seconds to human-readable time
  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '$minutes minute${minutes > 1 ? 's' : ''}';
      } else {
        return '$minutes minute${minutes > 1 ? 's' : ''} $remainingSeconds second${remainingSeconds > 1 ? 's' : ''}';
      }
    }
  }
  
  /// Reset all rate limiting for a phone number (for testing)
  Future<void> resetRateLimit(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyOtpLastSent$phoneNumber');
      await prefs.remove('$_keyOtpAttemptCount$phoneNumber');
      await prefs.remove('$_keyOtpLockoutUntil$phoneNumber');
      await prefs.remove('$_keyOtpResendCount$phoneNumber');
      final resendKey = '$_keyOtpResendCount$phoneNumber';
      await prefs.remove('${resendKey}_timestamp');
    } catch (e) {
      debugPrint('Error resetting rate limit: $e');
    }
  }
}
