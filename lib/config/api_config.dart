import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String _localBaseUrl = 'http://127.0.0.1:8000';
  static const String _stagingBaseUrl = 'https://staging-api.furspeak.ai';
  static const String _productionBaseUrl = 'https://api.furspeak.ai';

  // API Endpoints
  static const String _detectEndpoint = '/api/v1/detect';
  static const String _staticEndpoint = '/api/v1/static';

  // Get base URL based on environment
  static String get baseUrl {
    final env = dotenv.env['ENVIRONMENT'] ?? 'development';
    switch (env) {
      case 'production':
        return _productionBaseUrl;
      case 'staging':
        return _stagingBaseUrl;
      default:
        return _localBaseUrl;
    }
  }

  // Detection Endpoints
  static String get detectEmotion => _detectEndpoint;
  static String get staticFiles => _staticEndpoint;

  // Helper method to get full URL
  static String getFullUrl(String endpoint) => '$baseUrl$endpoint';

  // API Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Version': apiVersion,
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // API Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // API Version
  static const String apiVersion = 'v1';
}
