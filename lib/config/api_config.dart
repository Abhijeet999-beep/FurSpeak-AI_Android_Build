import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // Toggle this bool manually if you are testing on EMULATOR vs REAL DEVICE
  static const bool isRunningOnEmulator = true; 

  static String get _localBaseUrl {
    // Check .env for IP override
    try {
      final configuredIp = dotenv.env['LOCAL_API_URL'];
      if (configuredIp != null && configuredIp.isNotEmpty) {
        return configuredIp;
      }
    } catch (_) {}

    return 'http://10.0.2.2:8000';
  }
  
  static const String _stagingBaseUrl = 'https://staging-api.furspeak.ai';
  static const String _productionBaseUrl = 'https://furspeak-ai-production.up.railway.app';

  // API Endpoints
  static const String _detectImageEndpoint = '/api/v1/detect/image';
  static const String _detectVideoEndpoint = '/api/v1/detect/video';
  static const String _staticEndpoint = '/api/v1/static';

  // Get base URL based on environment
  static String get baseUrl {
    try {
      final env = dotenv.env['ENVIRONMENT'] ?? 'development';
      switch (env) {
        case 'production':
          return _productionBaseUrl;
        case 'staging':
          return _stagingBaseUrl;
        default:
          return _localBaseUrl;
      }
    } catch (_) {
      return _localBaseUrl; // Safe fallback
    }
  }

  // Detection Endpoints
  static String get detectImage => _detectImageEndpoint;
  static String get detectVideo => _detectVideoEndpoint;
  static String get staticFiles => _staticEndpoint;
  static String get statusEndpoint => '/api/v1/detect/status';

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
