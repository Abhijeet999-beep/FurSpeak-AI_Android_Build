import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // Toggle this bool manually if you are testing on EMULATOR vs REAL DEVICE
  static const bool isRunningOnEmulator = true; 

  static String get _localBaseUrl {
    // 1. Check .env for IP override — wrapped defensively so a missing .env
    //    never crashes the app with NotInitializedError.
    try {
      final configuredIp = dotenv.env['LOCAL_API_URL'];
      if (configuredIp != null && configuredIp.isNotEmpty) {
        return configuredIp;
      }
    } catch (_) {
      // dotenv not loaded yet — fall through to defaults
    }

    // 2. Fallback defaults
    if (isRunningOnEmulator) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000'; // ← ADB reverse proxy (USB tunnel)
    }
  }
  
  static const String _stagingBaseUrl = 'https://staging-api.furspeak.ai';
  static const String _productionBaseUrl = 'https://api.furspeak.ai';

  // API Endpoints
  static const String _detectEndpoint = '/api/v1/predict'; // Fixed endpoint path
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
  static String get detectEmotion => _detectEndpoint;
  static String get staticFiles => _staticEndpoint;
  static String get statusEndpoint => '/api/v1/status';

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
