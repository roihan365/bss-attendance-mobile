import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AppLogger {
  static final DateFormat _timeFormat = DateFormat('HH:mm:ss.SSS');

  static void i(String tag, String message) {
    _log('INFO', tag, message);
  }

  static void d(String tag, String message) {
    _log('DEBUG', tag, message);
  }

  static void w(String tag, String message) {
    _log('WARN', tag, message);
  }

  static void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', tag, message, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String level,
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final now = _timeFormat.format(DateTime.now());
    final formattedMessage = '[$now][$level][$tag] $message';

    if (kDebugMode) {
      debugPrint(formattedMessage);
      if (error != null) {
        debugPrint('  Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('  StackTrace: $stackTrace');
      }
    }

    developer.log(
      message,
      name: tag,
      time: DateTime.now(),
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static int _levelToInt(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 800;
    }
  }
}
