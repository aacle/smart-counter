import 'package:flutter/foundation.dart';

/// Lightweight app logger that uses debugPrint (no-op in release builds).
/// Centralized so we can swap to a real logging framework later
/// (e.g., for crash reporting with Sentry/Crashlytics).
class AppLogger {
  AppLogger._();

  /// Log an informational message
  static void info(String tag, String message) {
    debugPrint('[$tag] $message');
  }

  /// Log a warning
  static void warning(String tag, String message) {
    debugPrint('[WARN][$tag] $message');
  }

  /// Log an error with optional exception and stack trace
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR][$tag] $message');
    if (error != null) {
      debugPrint('[ERROR][$tag] Exception: $error');
    }
    if (stackTrace != null) {
      debugPrint('[ERROR][$tag] StackTrace: $stackTrace');
    }
  }
}
