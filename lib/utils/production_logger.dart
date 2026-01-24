import 'package:flutter/foundation.dart';

/// ⚠️ CRITICAL FIX: Production-safe logger that redacts sensitive data
/// 
/// This logger replaces all print() and debugPrint() statements to prevent
/// sensitive user data (phone numbers, UIDs, payment info) from appearing in logs
/// in production builds.
class ProductionLogger {
  /// Log a message (only in debug mode)
  /// In production, sensitive data is automatically redacted
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final redactedMessage = _redactSensitiveData(message);
      if (tag != null) {
        debugPrint('[$tag] $redactedMessage');
      } else {
        debugPrint(redactedMessage);
      }
    }
    // In production, do nothing (no logging)
  }

  /// Log an error message
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (kDebugMode) {
      final redactedMessage = _redactSensitiveData(message);
      if (tag != null) {
        debugPrint('❌ [$tag] ERROR: $redactedMessage');
      } else {
        debugPrint('❌ ERROR: $redactedMessage');
      }
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   StackTrace: $stackTrace');
      }
    }
    // In production, do nothing (no logging)
  }

  /// Log a warning message
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final redactedMessage = _redactSensitiveData(message);
      if (tag != null) {
        debugPrint('⚠️ [$tag] WARNING: $redactedMessage');
      } else {
        debugPrint('⚠️ WARNING: $redactedMessage');
      }
    }
    // In production, do nothing (no logging)
  }

  /// Log an info message
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final redactedMessage = _redactSensitiveData(message);
      if (tag != null) {
        debugPrint('ℹ️ [$tag] INFO: $redactedMessage');
      } else {
        debugPrint('ℹ️ INFO: $redactedMessage');
      }
    }
    // In production, do nothing (no logging)
  }

  /// Log a success message
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      final redactedMessage = _redactSensitiveData(message);
      if (tag != null) {
        debugPrint('✅ [$tag] SUCCESS: $redactedMessage');
      } else {
        debugPrint('✅ SUCCESS: $redactedMessage');
      }
    }
    // In production, do nothing (no logging)
  }

  /// Redact sensitive data from log messages
  /// This prevents phone numbers, UIDs, payment info, etc. from appearing in production logs
  static String _redactSensitiveData(String message) {
    if (kReleaseMode) {
      // In production, redact all sensitive patterns
      String redacted = message;

      // Redact phone numbers (various formats)
      redacted = redacted.replaceAll(
        RegExp(r'\+?\d{1,4}[-.\s]?\(?\d{1,4}\)?[-.\s]?\d{1,9}[-.\s]?\d{1,9}'),
        '[PHONE_REDACTED]',
      );

      // Redact UIDs (Firebase UIDs are typically 28 characters)
      redacted = redacted.replaceAllMapped(
        RegExp(r'\b[a-zA-Z0-9]{20,30}\b'),
        (match) {
          // Check if it looks like a Firebase UID
          if (match.group(0)!.length >= 20 && match.group(0)!.length <= 30) {
            return '[UID_REDACTED]';
          }
          return match.group(0)!;
        },
      );

      // Redact UTR numbers (typically 12-16 digits)
      redacted = redacted.replaceAll(
        RegExp(r'\b\d{12,16}\b'),
        '[UTR_REDACTED]',
      );

      // Redact payment amounts (currency patterns)
      redacted = redacted.replaceAll(
        RegExp(r'[₹$€£]\s?\d+([.,]\d{2})?'),
        '[AMOUNT_REDACTED]',
      );

      // Redact email addresses
      redacted = redacted.replaceAll(
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
        '[EMAIL_REDACTED]',
      );

      // Redact tokens (long alphanumeric strings)
      redacted = redacted.replaceAll(
        RegExp(r'\b[a-zA-Z0-9]{40,}\b'),
        '[TOKEN_REDACTED]',
      );

      return redacted;
    }

    // In debug mode, return original message
    return message;
  }

  /// Print a message (for backward compatibility with existing print() calls)
  /// This will be automatically redacted in production
  static void print(String message) {
    log(message);
  }
}
