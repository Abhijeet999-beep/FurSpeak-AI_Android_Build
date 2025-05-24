import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'auth_token';

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: Duration(milliseconds: ApiConfig.connectionTimeout),
            receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
            headers: ApiConfig.getHeaders(),
          ),
        ),
        _storage = const FlutterSecureStorage() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token expired or invalid
            await _storage.delete(key: _tokenKey);
            // You might want to trigger a re-authentication flow here
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Detect emotion from image or video
  Future<Map<String, dynamic>> detectEmotion(
    File file, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiConfig.detectEmotion,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: onSendProgress,
      );

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to process file: ${e.toString()}');
    }
  }

  // Get static files (if needed)
  Future<String> getStaticFile(String path) async {
    try {
      if (path.isEmpty) {
        throw Exception('Path cannot be empty');
      }

      final response = await _dio.get(
        '${ApiConfig.staticFiles}/$path',
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      return response.data.toString();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to get static file: ${e.toString()}');
    }
  }

  // Error handling
  Exception _handleError(DioException error) {
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message =
            'Connection timeout. Please check your internet connection and try again.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        if (data is Map) {
          message = data['detail'] ?? data['message'] ?? 'An error occurred';
        } else {
          message = 'Server error: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network settings.';
        break;
      default:
        message = 'An unexpected error occurred. Please try again.';
    }
    return Exception(message);
  }

  // Token management
  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
