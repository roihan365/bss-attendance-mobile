import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String defaultBaseUrl = 'http://bss-attendance-be.test/api';

  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? defaultBaseUrl;
  }

  static String get environment {
    return dotenv.env['APP_ENV'] ?? 'development';
  }

  static bool get isDevelopment => environment == 'development';

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Fallback silently if .env file is missing or not packaged
    }
  }
}
