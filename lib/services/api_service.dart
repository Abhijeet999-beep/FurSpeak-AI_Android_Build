import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../models/api_pipeline_response.dart';
import '../models/pipeline_types.dart';

/// Central API service for the FurSpeak pipeline.
///
/// Rules:
///   - Every error path throws [PipelineException] — never raw [Exception].
///   - Upload lifecycle is fully tracked: START → SUCCESS | FAILURE | TIMEOUT.
///   - Hard timeout of 120s prevents infinite hangs.
///   - Automatic retry (up to 2 retries) on transient failures.
///   - Response validation ensures only 200 is accepted.
class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
    ),
  );

  /// True when an upload is actively in-flight.
  /// Used by lifecycle observers to prevent silent cancellation.
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  /// Hard timeout for the entire upload operation (connection + send + receive).
  static const Duration _uploadHardTimeout = Duration(seconds: 120);

  /// Maximum number of automatic retries on transient failures.
  static const int _maxRetries = 2;

  /// Uploads media to the backend for emotion detection.
  ///
  /// Features:
  ///   - Full lifecycle logging (START / SUCCESS / FAILURE / TIMEOUT)
  ///   - Hard timeout guarantee — no infinite hangs
  ///   - Automatic retry on transient network errors (up to [_maxRetries])
  ///   - Response validation (only 200 accepted)
  ///   - Upload-in-flight flag for lifecycle protection
  ///
  /// Throws [PipelineException] on any failure.
  Future<ApiPipelineResponse> uploadMedia({
    required File file,
    required String requestId,
    required AuthProvider authProvider,
    CancelToken? cancelToken,
    Function(double)? onProgress,
  }) async {
    // ── PRE-FLIGHT CHECKS ──────────────────────────────────────────────
    if (!file.existsSync()) {
      throw PipelineException(
        message: 'File not found at path: ${file.path}. It may have been deleted after compression.',
        stage: PipelineStage.uploading,
        canRetry: false,
      );
    }

    final int fileSize = file.lengthSync();
    final String endpointUrl = ApiConfig.getFullUrl(ApiConfig.detectEmotion);
    final DateTime startTime = DateTime.now();

    debugPrint('[UPLOAD] ════════════════════════════════════════════');
    debugPrint('[UPLOAD] START → $endpointUrl');
    debugPrint('[UPLOAD] FILE SIZE → $fileSize bytes (${(fileSize / 1024).toStringAsFixed(1)} KB)');
    debugPrint('[UPLOAD] FILE PATH → ${file.path}');
    debugPrint('[UPLOAD] REQUEST ID → $requestId');
    debugPrint('[UPLOAD] TIME → $startTime');
    debugPrint('[UPLOAD] ════════════════════════════════════════════');

    _isUploading = true;

    try {
      return await _uploadWithRetry(
        file: file,
        fileSize: fileSize,
        requestId: requestId,
        endpointUrl: endpointUrl,
        startTime: startTime,
        authProvider: authProvider,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
    } finally {
      _isUploading = false;
      final elapsed = DateTime.now().difference(startTime);
      debugPrint('[UPLOAD] TOTAL WALL-CLOCK → ${elapsed.inMilliseconds}ms');
    }
  }

  /// Internal retry wrapper. Retries up to [_maxRetries] times on transient errors.
  Future<ApiPipelineResponse> _uploadWithRetry({
    required File file,
    required int fileSize,
    required String requestId,
    required String endpointUrl,
    required DateTime startTime,
    required AuthProvider authProvider,
    CancelToken? cancelToken,
    Function(double)? onProgress,
  }) async {
    int retries = 0;
    
    while (true) {
      try {
        return await _singleUploadAttempt(
          file: file,
          fileSize: fileSize,
          requestId: requestId,
          endpointUrl: endpointUrl,
          startTime: startTime,
          authProvider: authProvider,
          cancelToken: cancelToken,
          onProgress: onProgress,
          attemptNumber: retries + 1,
        );
      } on PipelineException catch (e) {
        // Only retry if the error is retryable and we haven't exhausted retries
        if (!e.canRetry || retries >= _maxRetries) {
          rethrow;
        }
        retries++;
        debugPrint('[UPLOAD] RETRY $retries/$_maxRetries → ${e.message}');
        // Brief backoff before retry
        await Future.delayed(Duration(milliseconds: 500 * retries));
      }
    }
  }

  /// Executes a single upload attempt with hard timeout and full lifecycle logging.
  Future<ApiPipelineResponse> _singleUploadAttempt({
    required File file,
    required int fileSize,
    required String requestId,
    required String endpointUrl,
    required DateTime startTime,
    required AuthProvider authProvider,
    CancelToken? cancelToken,
    Function(double)? onProgress,
    required int attemptNumber,
  }) async {
    try {
      // --- Auth token ---
      String? token;
      try {
        token = await authProvider.getToken();
      } catch (e) {
        debugPrint("[UPLOAD] ⚠️ getToken() failed ($e). Proceeding without token.");
      }

      String fileName = file.path.split('/').last;

      // Re-check file existence right before building FormData
      if (!file.existsSync()) {
        throw PipelineException(
          message: 'File disappeared before upload attempt $attemptNumber: ${file.path}',
          stage: PipelineStage.uploading,
          canRetry: false,
        );
      }

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
        "request_id": requestId,
      });

      debugPrint('[UPLOAD] ATTEMPT $attemptNumber → Sending ${(fileSize / 1024).toStringAsFixed(1)} KB to $endpointUrl');

      // ── HARD TIMEOUT WRAPPING ──────────────────────────────────────
      final response = await _dio.post(
        endpointUrl,
        data: formData,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            "x-source": "mobile_app",
            "Authorization": "Bearer $token"
          },
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
        onSendProgress: (int sent, int total) {
          if (total != -1 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      ).timeout(
        _uploadHardTimeout,
        onTimeout: () {
          final elapsed = DateTime.now().difference(startTime);
          debugPrint('[UPLOAD] ❌ TIMEOUT after ${elapsed.inSeconds}s (hard limit: ${_uploadHardTimeout.inSeconds}s)');
          throw PipelineException(
            message: 'Upload timed out after ${_uploadHardTimeout.inSeconds}s. Please try again.',
            stage: PipelineStage.uploading,
            canRetry: true,
          );
        },
      );

      // ── RESPONSE VALIDATION ────────────────────────────────────────
      final elapsed = DateTime.now().difference(startTime);
      
      if (response.statusCode == 200) {
        debugPrint('[UPLOAD] ✅ SUCCESS → status=${response.statusCode} (${elapsed.inMilliseconds}ms)');
        debugPrint('[UPLOAD] RESPONSE → ${response.data}');
        return ApiPipelineResponse.fromJson(response.data);
      } else {
        debugPrint('[UPLOAD] ❌ FAILED → status=${response.statusCode} (${elapsed.inMilliseconds}ms)');
        debugPrint('[UPLOAD] RESPONSE BODY → ${response.data}');
        throw PipelineException(
          message: 'Upload failed with status: ${response.statusCode}.',
          stage: PipelineStage.uploading,
          canRetry: response.statusCode != null && response.statusCode! >= 500,
        );
      }
    } on PipelineException {
      rethrow; // Already typed — propagate directly
    } on DioException catch (dioErr) {
      final elapsed = DateTime.now().difference(startTime);
      
      if (CancelToken.isCancel(dioErr)) {
        debugPrint('[UPLOAD] ❌ CANCELLED by user/system (${elapsed.inMilliseconds}ms)');
        throw const PipelineException(
          message: 'Request was cancelled.',
          stage: PipelineStage.idle,
          canRetry: false,
        );
      }
      
      debugPrint('[UPLOAD] ❌ FAILED → DioException: ${dioErr.type} | ${dioErr.message} (${elapsed.inMilliseconds}ms)');
      if (dioErr.response != null) {
        debugPrint('[UPLOAD] RESPONSE STATUS → ${dioErr.response?.statusCode}');
        debugPrint('[UPLOAD] RESPONSE BODY → ${dioErr.response?.data}');
      }
      
      throw _mapDioError(dioErr, fallbackStage: PipelineStage.uploading);
    } catch (e) {
      final elapsed = DateTime.now().difference(startTime);
      debugPrint('[UPLOAD] ❌ FAILED → Unknown error: $e (${elapsed.inMilliseconds}ms)');
      throw PipelineException(
        message: 'Upload error: $e',
        stage: PipelineStage.uploading,
      );
    }
  }

  /// Polls the backend for processing status using exponential backoff.
  ///
  /// Throws [PipelineException] on timeout, cancellation, or terminal error.
  Future<ApiPipelineResponse> pollStatus({
    required String requestId,
    required AuthProvider authProvider,
    required CancelToken cancelToken,
  }) async {
    const int maxAttempts = 10;
    const Duration pollInterval = Duration(seconds: 2);
    int attempts = 0;

    while (attempts < maxAttempts) {
      attempts++;

      if (cancelToken.isCancelled) {
        throw const PipelineException(
          message: 'Processing cancelled.',
          stage: PipelineStage.processing,
          canRetry: true,
        );
      }

      String? token;
      try {
        token = await authProvider.getToken();
      } catch (_) {
        debugPrint("[POLL] ⚠️ getToken() failed. Proceeding without token.");
      }

      try {
        final endpoint = "${ApiConfig.getFullUrl(ApiConfig.statusEndpoint)}/$requestId";
        final response = await _dio.get(
          endpoint,
          cancelToken: cancelToken,
          options: Options(
            headers: {
              "x-source": "mobile_app",
              "Authorization": "Bearer $token"
            },
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200) {
          final result = ApiPipelineResponse.fromJson(response.data);
          if (result.status == 'success' || result.status == 'error') {
            return result;
          }
        }
      } on DioException catch (dioErr) {
        if (CancelToken.isCancel(dioErr)) {
          throw const PipelineException(
            message: 'Processing cancelled.',
            stage: PipelineStage.processing,
            canRetry: true,
          );
        }
        // Transient network errors during polling → continue retrying
        debugPrint("⚠️ [API SERVICE] Polling heartbeat error, continuing to retry... ${dioErr.message}");
      }

      if (cancelToken.isCancelled) {
        throw const PipelineException(
          message: 'Processing cancelled.',
          stage: PipelineStage.processing,
          canRetry: true,
        );
      }

      await Future.delayed(pollInterval);
    }

    throw const PipelineException(
      message: 'Processing took too long. Please try again.',
      stage: PipelineStage.processing,
      canRetry: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DIO ERROR → PIPELINE EXCEPTION MAPPER
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [DioException] to a typed [PipelineException].
  ///
  /// All Dio errors pass through here — no raw [Exception] escapes.
  PipelineException _mapDioError(
    DioException dioErr, {
    required PipelineStage fallbackStage,
  }) {
    switch (dioErr.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return PipelineException(
          message: 'Network timeout. Please check your connection.',
          stage: fallbackStage,
          canRetry: true,
        );

      case DioExceptionType.connectionError:
        return PipelineException(
          message: 'Unable to connect. Ensure your phone and server are on the same WiFi network.',
          stage: fallbackStage,
          canRetry: true,
        );

      default:
        // Extract server error details if available
        final responseData = dioErr.response?.data;
        if (responseData is Map<String, dynamic>) {
          final errorType = responseData['error_type'] ?? '';
          final errorMsg = responseData['message'] ?? 'Unknown server error';
          return PipelineException(
            message: '$errorType: $errorMsg',
            stage: fallbackStage,
            canRetry: false,
          );
        }

        return PipelineException(
          message: dioErr.message ?? 'Network error occurred.',
          stage: fallbackStage,
        );
    }
  }
}
