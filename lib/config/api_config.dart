import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _resolvedBaseUrl;

  static void setBaseUrl(String url) {
    _resolvedBaseUrl = url;
  }

  // Load base URL from .env file (supports local and production toggles)
  static String get baseUrl {
    if (_resolvedBaseUrl != null) {
      return _resolvedBaseUrl!;
    }

    final envUrl = dotenv.env['API_BASE_URL'];
    final isProduction = dotenv.env['ENVIRONMENT'] == 'production';

    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl.endsWith('/') ? envUrl.substring(0, envUrl.length - 1) : envUrl;
    }

    if (isProduction) {
      throw Exception('API_BASE_URL must be defined in .env for production environment');
    }

    return 'http://10.0.2.2:8000';
  }

  // API Endpoints
  static const String detectImage = '/api/v1/detect/image';
  static const String detectVideo = '/api/v1/detect/video';
  static const String staticFiles = '/api/v1/static';
  static const String statusEndpoint = '/api/v1/detect/status';

  // Helper method to get full URL
  static String getFullUrl(String endpoint) => '$baseUrl$endpoint';

  // API Version
  static const String apiVersion = 'v1';
}
