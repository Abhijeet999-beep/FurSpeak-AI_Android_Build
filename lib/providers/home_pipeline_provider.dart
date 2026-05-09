import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../services/api_service.dart';
import 'package:furspeak_ai/media/services/media_compressor.dart';
import '../utils/error_mapper.dart';
import '../models/api_pipeline_response.dart';
import '../models/pipeline_types.dart';
import '../services/result_storage_service.dart';
import '../data/models/detection_result.dart';
import 'package:furspeak_ai/media/services/media_orchestrator.dart';
import 'auth_provider.dart';

enum HomeState { idle, compressing, uploading, processing, success, error, cancelled }

class HomePipelineProvider extends ChangeNotifier with WidgetsBindingObserver {
  HomePipelineProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  HomeState _state = HomeState.idle;
  HomeState get state => _state;

  /// Convenience alias — true when the pipeline is actively working.
  /// UI should disable input buttons when this is true.
  bool get isProcessing =>
      _state == HomeState.compressing ||
      _state == HomeState.uploading ||
      _state == HomeState.processing;

  /// The active request identity. Used for idempotency AND stale-response rejection.
  String? _requestId;
  String? get requestId => _requestId;

  int _retryCount = 0;
  int get retryCount => _retryCount;

  static const int maxRetries = 3;

  String? _pendingFilePath;
  String? get pendingFilePath => _pendingFilePath;

  String? _activeCompressedFilePath;

  bool _isVideo = false;
  bool get isVideo => _isVideo;

  ApiPipelineResponse? _pendingResult;
  ApiPipelineResponse? get pendingResult => _pendingResult;

  ApiPipelineResponse? _result;
  ApiPipelineResponse? get result => _result;

  AppError? _error;
  AppError? get error => _error;

  double _uploadProgress = 0.0;
  double _compressionProgress = 0.0;
  double _processingProgress = 0.0;

  double get uploadProgress => _uploadProgress;
  double get compressionProgress => _compressionProgress;
  double get processingProgress => _processingProgress;

  /// The UUID of the last successfully persisted result.
  /// Used for ID-based navigation: `/result?id=<lastResultId>`
  String? _lastResultId;
  String? get lastResultId => _lastResultId;

  /// True after the UI has consumed a success result for navigation.
  /// Prevents duplicate pushes to the result screen.
  bool _hasNavigated = false;
  bool get hasNavigated => _hasNavigated;

  /// Human-readable status message for the current stage.
  String get statusMessage {
    switch (_state) {
      case HomeState.idle:
        return '';
      case HomeState.compressing:
        final pct = (_compressionProgress * 100).toInt();
        return 'Processing media... ($pct%)';
      case HomeState.uploading:
        final pct = (_uploadProgress * 100).toInt();
        return 'Uploading... ($pct%)';
      case HomeState.processing:
        final pct = (_processingProgress * 100).toInt();
        return 'Analyzing your pet... ($pct%)';
      case HomeState.success:
        return 'Analysis complete!';
      case HomeState.cancelled:
        return 'Cancelled.';
      case HomeState.error:
        return _error?.userMessage ?? 'Something went wrong.';
    }
  }

  ApiService get _apiService => GetIt.instance<ApiService>();

  CancelToken? _cancelToken;
  Timer? _processingTimer;

  void _startProcessingSimulation() {
    _processingProgress = 0.0;
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_state != HomeState.processing) {
        timer.cancel();
        return;
      }
      // Slow crawl: 0 -> 0.95
      if (_processingProgress < 0.95) {
        _processingProgress += 0.015; 
        notifyListeners();
      }
    });
  }

  // ─── LIFECYCLE PROTECTION ──────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_apiService.isUploading) {
      debugPrint('[UPLOAD] ⚠️ APP LIFECYCLE → ${state.name} while upload in-flight!');
      debugPrint('[UPLOAD] BLOCKED — upload must complete before app can safely exit.');
    }
    if (_state == HomeState.uploading || _state == HomeState.processing) {
      debugPrint('[PIPELINE] ⚠️ APP LIFECYCLE → ${state.name} during ${_state.name}');
    }
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─── RESET GUARANTEE ──────────────────────────────────────────────────
  /// Lightweight reset after successful navigation.
  ///
  /// Clears success/navigation state so the pipeline returns to idle,
  /// but preserves [_pendingFilePath] and [_isVideo] so retry remains
  /// functional if the user returns to the home screen.
  void resetPipeline() {
    _state = HomeState.idle;
    _hasNavigated = false;
    _lastResultId = null;
    _error = null;
    _pendingResult = null;
    notifyListeners();
  }

  /// Resets the pipeline to idle. Cancels active polling/upload.
  /// After this call, ALL state is cleared:
  ///   - requestId = null
  ///   - result = null
  ///   - error = null
  ///   - cancelToken cancelled
  ///   - state = idle
  void reset() {
    _cancelToken?.cancel("Pipeline reset by user");
    MediaCompressor.cancelCurrentCompression();
    _cancelToken = null;
    
    // Delete pending file if we are resetting before success and it's temp-owned
    if (_pendingFilePath != null && _state != HomeState.success) {
      final path = _pendingFilePath!;
      getTemporaryDirectory().then((tempDir) {
        if (path.startsWith(tempDir.path)) {
          try {
            final file = File(path);
            if (file.existsSync()) file.deleteSync();
            debugPrint("🗑️ [PIPELINE] Deleted temp-owned pending file on reset.");
          } catch (_) {}
        }
      }).catchError((_) {});
    }

    if (_activeCompressedFilePath != null && _state != HomeState.success) {
      final path = _activeCompressedFilePath!;
      getTemporaryDirectory().then((tempDir) {
        if (path.startsWith(tempDir.path)) {
          try {
            final file = File(path);
            if (file.existsSync()) file.deleteSync();
            debugPrint("🗑️ [PIPELINE] Deleted active compressed file on reset.");
          } catch (_) {}
        }
      }).catchError((_) {});
    }

    _state = HomeState.idle;
    _requestId = null;
    _retryCount = 0;
    _pendingFilePath = null;
    _activeCompressedFilePath = null;
    _isVideo = false;
    _result = null;
    _pendingResult = null;
    _error = null;
    _lastResultId = null;
    _hasNavigated = false;
    _uploadProgress = 0.0;
    _compressionProgress = 0.0;
    _processingProgress = 0.0;
    _processingTimer?.cancel();
    notifyListeners();
  }

  void cancelProcessing() {
    developer.log("PIPELINE CANCELLED: stage=${_state.name}", name: "FurSpeak");
    debugPrint("🛑 [PIPELINE] User triggered cancellation.");
    _cancelToken?.cancel("Processing cancelled by user.");
    MediaCompressor.cancelCurrentCompression();
    _changeState(HomeState.cancelled);
  }

  /// Consume the success result for navigation.
  ///
  /// Returns [lastResultId] exactly once per successful pipeline.
  /// After calling this, [hasNavigated] becomes true and subsequent
  /// calls return null — preventing duplicate navigation pushes.
  String? consumeSuccess() {
    if (_state != HomeState.success) return null;
    if (_hasNavigated) return null;
    if (_lastResultId == null) return null;

    _hasNavigated = true;
    notifyListeners();
    return _lastResultId;
  }

  // ─── NEW MEDIA ────────────────────────────────────────────────────────
  Future<void> processNewMedia(String filePath, bool isVideo, AuthProvider authProvider) async {
    if (isProcessing) {
      debugPrint("⚠️ [PIPELINE] Canceling currently active pipeline ($_state) to process new media.");
      cancelProcessing();
    }
    reset();

    // Generate a new globally unique identity for THIS specific media task
    _requestId = const Uuid().v4();
    _retryCount = 0;
    _pendingFilePath = filePath;
    _isVideo = isVideo;
    _result = null;
    _error = null;
    _hasNavigated = false;

    // Route through the orchestrator so processing always preempts any
    // queued preview requests (e.g. video initialisation on other screens).
    await mediaOrchestrator.request(
      MediaRequest(
        MediaIntent.processing,
        () async => _executePipeline(authProvider),
        _requestId!,
      ),
    );
  }

  // ─── RETRY ────────────────────────────────────────────────────────────
  Future<void> retryPipeline(AuthProvider authProvider) async {
    if (_requestId == null || _pendingFilePath == null) {
      debugPrint("⚠️ [PIPELINE] Cannot retry without an active request identity. Resetting.");
      reset();
      return;
    }

    if (_state != HomeState.error) {
      debugPrint("⚠️ [PIPELINE] Ignoring retry request: Pipeline is not in an error state.");
      return;
    }

    if (_retryCount >= maxRetries) {
      _error = const AppError(
        type: AppErrorType.unknown,
        userMessage: 'Too many attempts. Please try selecting the media again.',
        emoji: '🔄',
        icon: Icons.refresh_rounded,
        canRetry: false,
      );
      notifyListeners();
      return;
    }

    _retryCount++;
    debugPrint("🔄 [PIPELINE] Retrying request: $_requestId (Attempt $_retryCount)");

    // Start processing via orchestrator
    mediaOrchestrator.request(
      MediaRequest(
        MediaIntent.processing,
        () async {
          // Guard: ensure the request hasn't been reset before this task runs.
          if (_requestId != null) {
            await _executePipeline(authProvider);
          }
        },
        _requestId!,
      ),
    );
  }

  // ─── RETRY STORAGE ────────────────────────────────────────────────────
  Future<void> retryStorage() async {
    if (_pendingResult == null) {
      debugPrint("⚠️ [PIPELINE] Cannot retry storage: No pending result.");
      return;
    }

    _changeState(HomeState.processing);
    
    try {
      final resultUuid = const Uuid().v4();
      final detection = _createDetectionResult(resultUuid);

      final storage = GetIt.instance<ResultStorageService>();
      await storage.saveResult(detection);

      _lastResultId = resultUuid;
      _pendingResult = null;

      _changeState(HomeState.success);
    } catch (e) {
      debugPrint('⚠️ [PIPELINE] Failed to persist result on retry: $e');
      _error = const AppError(
          type: AppErrorType.unknown,
          userMessage: 'Failed to save result. Please try again.',
          emoji: '💾',
          icon: Icons.save_alt_rounded,
          canRetry: true,
      );
      _changeState(HomeState.error);
    }
  }

  DetectionResult _createDetectionResult(String uuid) {
    return DetectionResult()
      ..uuid = uuid
      ..timestamp = DateTime.now()
      ..emotion = _pendingResult!.emotion ?? 'Unknown'
      ..confidence = _pendingResult!.confidence
      ..caption = _pendingResult!.caption ?? ''
      ..suggestions = <String>[]
      ..mediaPath = _pendingFilePath ?? ''
      ..sourceType = _isVideo ? 'video' : 'image'
      ..processingTime = _pendingResult!.processingTime
      ..status = _pendingResult!.status
      ..frameImagePath = _pendingResult!.frameImagePath
      ..frameImageUrl = _pendingResult!.frameImageUrl
      ..timelineJson = _pendingResult!.timeline.isNotEmpty
          ? jsonEncode(_pendingResult!.timeline)
          : null
      ..timelineSummaryJson = _pendingResult!.timelineSummary.isNotEmpty
          ? jsonEncode(_pendingResult!.timelineSummary)
          : null;
  }
  // ─── CORE PIPELINE ────────────────────────────────────────────────────
  Future<void> _executePipeline(AuthProvider authProvider) async {
    // Snapshot the request ID at the START of this execution.
    // If reset() is called during execution, _requestId changes to null,
    // and this snapshot will no longer match → we bail out.
    final activeRequestId = _requestId;

    developer.log("PIPELINE START: requestId=$activeRequestId, mediaPath=$_pendingFilePath", name: "FurSpeak");

    _cancelToken = CancelToken();
    _changeState(HomeState.compressing);

    File? compressedFile;

    try {
      File originalFile = File(_pendingFilePath!);
      if (!originalFile.existsSync()) {
        throw PipelineException(
          message: 'Source file not found: $_pendingFilePath',
          stage: PipelineStage.processing,
          canRetry: false,
        );
      }

      try {
        final compressionCompleter = Completer<File?>();
        final cancelCompleter = Completer<File?>();

        _cancelToken?.whenCancel.then((_) {
          if (!cancelCompleter.isCompleted) {
            cancelCompleter.completeError(
              const PipelineException(message: 'Processing cancelled.', stage: PipelineStage.processing)
            );
          }
        });

        Future<File?> getCompression() async {
          if (_isVideo) {
            return await MediaCompressor.compressVideo(
              originalFile,
              onProgress: (p) {
                _compressionProgress = p;
                notifyListeners();
              },
            );
          } else {
            return await MediaCompressor.compressImage(originalFile);
          }
        }

        getCompression().then((file) {
          if (!compressionCompleter.isCompleted) {
            compressionCompleter.complete(file);
          }
        }).catchError((e) {
          debugPrint("⚠️ [PIPELINE] Compression failed, falling back to original: $e");
          if (!compressionCompleter.isCompleted) {
            compressionCompleter.complete(null);
          }
        });

        compressedFile = await Future.any([
          compressionCompleter.future,
          cancelCompleter.future,
        ]);
        if (compressedFile != null) {
          _activeCompressedFilePath = compressedFile.path;
        }
      } catch (e) {
        if (e is PipelineException) rethrow; // cancellation error
        compressedFile = null;
      }

      // ── STALE CHECK after async gap ────────────────────────────────
      if (_requestId != activeRequestId) {
        debugPrint("🛑 [PIPELINE] Request ID changed during compression. Aborting stale pipeline.");
        return;
      }
      if (_cancelToken?.isCancelled == true) return;

      final uploadFile = compressedFile ?? originalFile;
      _changeState(HomeState.uploading);

      bool pipelineSuccess = false;

      void deleteCompressedFile() {
        if (compressedFile != null) {
          final path = compressedFile.path;
          getTemporaryDirectory().then((tempDir) {
            if (path.startsWith(tempDir.path)) {
              try {
                if (compressedFile?.existsSync() == true) {
                  compressedFile?.deleteSync();
                  developer.log("PIPELINE CLEANUP: temp file deleted safely: $path", name: "FurSpeak");
                  debugPrint("🗑️ Safe to delete compressed file");
                }
              } catch (_) {}
            }
          }).catchError((_) {});
        }
      }

      // ── UPLOAD (orchestrator lock is HELD for the entire duration) ────
      debugPrint('[PIPELINE] ════ UPLOAD PHASE START ════');
      debugPrint('[PIPELINE] Upload file: ${uploadFile.path}');
      debugPrint('[PIPELINE] Upload file exists: ${uploadFile.existsSync()}');
      debugPrint('[PIPELINE] Upload file size: ${uploadFile.existsSync() ? uploadFile.lengthSync() : "N/A"} bytes');
      
      final uploadStopwatch = Stopwatch()..start();

      ApiPipelineResponse data = await _apiService.uploadMedia(
        file: uploadFile,
        requestId: activeRequestId!,
        authProvider: authProvider,
        isVideo: _isVideo,
        cancelToken: _cancelToken,
        onProgress: (progress) {
          _uploadProgress = progress;
          if (progress >= 1.0 && _state == HomeState.uploading) {
            _changeState(HomeState.processing);
            _startProcessingSimulation();
          } else {
            notifyListeners();
          }
        },
      );

      uploadStopwatch.stop();
      debugPrint('[PIPELINE] ════ UPLOAD PHASE COMPLETE ════');
      debugPrint('[PIPELINE] Upload wall-clock: ${uploadStopwatch.elapsedMilliseconds}ms');
      debugPrint("📤 Upload completed successfully");

      // ── STALE CHECK after upload ───────────────────────────────────
      if (_requestId != activeRequestId) {
        debugPrint("🛑 [PIPELINE] Request ID changed after upload. Ignoring stale response.");
        return;
      }
      if (_cancelToken?.isCancelled == true) return;

      // Handle Polling State
      if (data.status == 'processing') {
        debugPrint("🔄 [PIPELINE] Backend returned 'processing'. Initiating polling.");
        _changeState(HomeState.processing);
        _startProcessingSimulation();

        data = await _apiService.pollStatus(
          requestId: activeRequestId,
          authProvider: authProvider,
          cancelToken: _cancelToken!,
        ).timeout(
          const Duration(seconds: 25),
          onTimeout: () {
            throw const PipelineException(
              message: "Processing took too long. Please try again.",
              stage: PipelineStage.processing,
            );
          },
        );
      }

      // ── STALE CHECK after polling ──────────────────────────────────
      if (_requestId != activeRequestId) {
        debugPrint("🛑 [PIPELINE] Request ID changed after polling. Discarding stale result.");
        return;
      }
      if (_cancelToken?.isCancelled == true) return;

      if (data.status != 'success') {
        throw PipelineException(
          message: 'Server failed to process the request (Status: ${data.status}).',
          stage: PipelineStage.uploading,
        );
      }

      // Ensure processing state was shown visually
      if (_state == HomeState.uploading) {
        _changeState(HomeState.processing);
      }

      // Attach client-side local media metadata so ResultScreen can show local previews
      _result = data.withLocalMedia(path: _pendingFilePath, isVideo: _isVideo);

      // ── PERSIST to local storage ───────────────────────────────────
      _pendingResult = _result;

      try {
        final resultUuid = const Uuid().v4();
        final detection = _createDetectionResult(resultUuid);

        final storage = GetIt.instance<ResultStorageService>();
        await storage.saveResult(detection);
        
        _lastResultId = resultUuid;
        _pendingResult = null;
        debugPrint('✅ [PIPELINE] Result persisted: $resultUuid');
      } catch (e) {
        debugPrint('⚠️ [PIPELINE] Failed to persist result: $e');
        _error = const AppError(
            type: AppErrorType.unknown,
            userMessage: 'Failed to save result. Please try again.',
            emoji: '💾',
            icon: Icons.save_alt_rounded,
            canRetry: true,
        );
        _changeState(HomeState.error);
        return;
      }

      if (_lastResultId == null) {
        _error = const AppError(
            type: AppErrorType.unknown,
            userMessage: 'Result unavailable. Please retry.',
            emoji: '⚠️',
            icon: Icons.error_outline_rounded,
            canRetry: true,
        );
        _changeState(HomeState.error);
        return;
      }

      _changeState(HomeState.success);
      pipelineSuccess = true;
      debugPrint("📦 Pipeline completed successfully");

      // Increment guest scan count if applicable
      if (authProvider.isGuest) {
        await authProvider.incrementGuestScanCount();
      }

      if (pipelineSuccess == true) {
        deleteCompressedFile();
      }
    } catch (e) {
      if (_state == HomeState.cancelled) {
        debugPrint("🛑 [PIPELINE] Cancelled state active. Suppressing error.");
        return;
      }
      // Suppress errors from cancelled or stale pipelines
      if (_cancelToken?.isCancelled == true || _requestId != activeRequestId || e.toString().contains('cancelled')) {
        debugPrint("🛑 [PIPELINE] Cancelled/stale pipeline error suppressed: $e");
        return;
      }
      _error = ErrorMapper.mapException(e);
      _changeState(HomeState.error);
    } finally {
      // Handle pending file lifecycle for failures
      if (_state != HomeState.success && _state != HomeState.idle) {
         if (_pendingFilePath != null) {
            final path = _pendingFilePath!;
            getTemporaryDirectory().then((tempDir) {
              if (path.startsWith(tempDir.path)) {
                try {
                  final pf = File(path);
                  if (pf.existsSync()) pf.deleteSync();
                  debugPrint("🗑️ [PIPELINE] Deleted temp-owned pending file on failure/cancel.");
                } catch (_) {}
              }
            }).catchError((_) {});
         }
      }
    }
  }

  // ─── STATE MACHINE GUARD ──────────────────────────────────────────────
  void _changeState(HomeState newState) {
    bool isValid = false;
    switch (_state) {
      case HomeState.idle:
        isValid = newState == HomeState.compressing || newState == HomeState.idle;
        break;
      case HomeState.compressing:
        isValid = newState == HomeState.uploading || newState == HomeState.error || newState == HomeState.idle || newState == HomeState.cancelled;
        break;
      case HomeState.uploading:
        isValid = newState == HomeState.processing || newState == HomeState.error || newState == HomeState.idle || newState == HomeState.cancelled;
        break;
      case HomeState.processing:
        isValid = newState == HomeState.success || newState == HomeState.error || newState == HomeState.idle || newState == HomeState.cancelled;
        break;
      case HomeState.success:
        isValid = newState == HomeState.idle;
        break;
      case HomeState.error:
        isValid = newState == HomeState.compressing || newState == HomeState.idle;
        break;
      case HomeState.cancelled:
        isValid = newState == HomeState.idle || newState == HomeState.compressing;
        break;
    }

    if (!isValid && newState != HomeState.idle) {
      debugPrint("⚠️ [STATE MACHINE] ILLEGAL TRANSITION BLOCKED: $_state -> $newState");
      return;
    }

    _state = newState;
    notifyListeners();
  }
}
