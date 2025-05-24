import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:furspeak_ai/config/app_config.dart';
import 'package:furspeak_ai/data/models/emotion_response.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: AppConfig.apiBaseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST('/detect/')
  Future<EmotionResponse> detectEmotion(
    @Part(name: 'file') File file,
  );

  @GET(AppConfig.historyEndpoint)
  Future<List<EmotionHistory>> getHistory();

  @POST(AppConfig.historyEndpoint)
  Future<void> saveHistory(@Body() EmotionHistory history);
}

class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final DioException? dioError;

  ApiError({
    required this.message,
    this.statusCode,
    this.data,
    this.dioError,
  });

  @override
  String toString() => 'ApiError: $message (Status: $statusCode)';
}

class ApiServiceFactory {
  static ApiService create() {
    final dio = Dio()
      ..options.connectTimeout = const Duration(seconds: 30)
      ..options.receiveTimeout = const Duration(seconds: 30)
      ..options.sendTimeout = const Duration(seconds: 30)
      ..options.validateStatus = (status) => status != null && status < 500;

    dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if needed
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            // Retry on timeout
            final retryCount = e.requestOptions.extra['retryCount'] ?? 0;
            if (retryCount < 3) {
              e.requestOptions.extra['retryCount'] = retryCount + 1;
              await Future.delayed(Duration(seconds: retryCount + 1));
              return handler.resolve(await dio.fetch(e.requestOptions));
            }
          }

          final error = ApiError(
            message: e.message ?? 'Unknown error occurred',
            statusCode: e.response?.statusCode,
            data: e.response?.data,
            dioError: e,
          );
          return handler.reject(e);
        },
      ),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    ]);

    return ApiService(dio);
  }
}

class EmotionPrediction {
  final String emotion;
  final double confidence;
  final String caption;

  EmotionPrediction({
    required this.emotion,
    required this.confidence,
    required this.caption,
  });

  factory EmotionPrediction.fromJson(Map<String, dynamic> json) {
    return EmotionPrediction(
      emotion: json['emotion'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      caption: json['caption'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'caption': caption,
    };
  }
}

class EmotionHistory {
  final String userId;
  final String emotion;
  final double confidence;
  final String caption;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime timestamp;

  EmotionHistory({
    required this.userId,
    required this.emotion,
    required this.confidence,
    required this.caption,
    this.imageUrl,
    this.videoUrl,
    required this.timestamp,
  });

  factory EmotionHistory.fromJson(Map<String, dynamic> json) {
    return EmotionHistory(
      userId: json['user_id'] as String,
      emotion: json['emotion'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      caption: json['caption'] as String,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'emotion': emotion,
      'confidence': confidence,
      'caption': caption,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
