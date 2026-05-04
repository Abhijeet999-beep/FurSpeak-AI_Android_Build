import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

enum MediaIntent {
  preview,
  processing,
}

enum MediaUIState {
  idle,
  waitingInQueue,
  executing,
}

class MediaRequest {
  final MediaIntent intent;
  final Future<void> Function() task;
  final String id;
  bool isCancelled = false;

  MediaRequest(this.intent, this.task, this.id);
}

class MediaOrchestrator {
  static final MediaOrchestrator instance = MediaOrchestrator._internal();

  MediaOrchestrator._internal();

  final Queue<MediaRequest> _queue = Queue();
  static const int MAX_QUEUE_SIZE = 5;

  bool _isProcessingQueue = false;
  VideoPlayerController? videoPlayerController;
  
  // Track ownership simply for clarity, though queue processing ensures serialized execution
  MediaIntent? _owner;

  Future<void> request(MediaRequest request) async {
    // Decision 2 — Preview Deduplication
    if (request.intent == MediaIntent.preview) {
      _queue.removeWhere((r) => r.intent == MediaIntent.preview);
    }
    
    // Decision 9 — Processing Supremacy
    if (request.intent == MediaIntent.processing) {
      _queue.removeWhere((r) => r.intent == MediaIntent.preview);
      await _forceReleasePreview();
    }

    // Decision 1 — Queue Size Limit
    if (_queue.length >= MAX_QUEUE_SIZE) {
      debugPrint('[Orchestrator] DROP: preview (queue full)');
      _queue.removeWhere((r) => r.intent == MediaIntent.preview);
    }

    _queue.add(request);
    debugPrint('[Orchestrator] ENQUEUE: ${request.intent.name} id=${request.id} queue=${_queue.length}');

    // Decision 3 — Priority System (Processing > Preview)
    final list = _queue.toList();
    list.sort((a, b) => b.intent.index.compareTo(a.intent.index));
    _queue.clear();
    _queue.addAll(list);

    _processQueue();
  }

  void cancel(String id) {
    for (final r in _queue) {
      if (r.id == id) {
        debugPrint('[Orchestrator] CANCELLED: ${r.intent.name} id=$id');
        r.isCancelled = true;
      }
    }
  }

  void reset() {
    debugPrint('[Orchestrator] HARD RESET TRIGGERED');
    _owner = null;
    _queue.clear();
    _forceReleasePreview();
    _isProcessingQueue = false;
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_queue.isNotEmpty) {
      final request = _queue.removeFirst();
      
      if (request.isCancelled) continue;

      try {
        await _acquire(request.intent);
        
        // Re-check cancellation just in case wait took long
        if (request.isCancelled) {
           _release();
           continue;
        }

        debugPrint('[Orchestrator] EXECUTE: ${request.intent.name} id=${request.id}');
        final stopwatch = Stopwatch()..start();
        
        await request.task();
        
        stopwatch.stop();
        debugPrint('[Orchestrator] DURATION: ${stopwatch.elapsedMilliseconds}ms');
      } catch (e) {
        debugPrint('[Orchestrator] EXECUTION ERROR: $e');
      } finally {
        _release();
      }
    }

    _isProcessingQueue = false;
  }

  Future<void> _acquire(MediaIntent intent) async {
    final timeout = const Duration(seconds: 5);

    try {
      await Future.any([
        _waitForFree(),
        Future.delayed(timeout, () => throw Exception('Deadlock detected')),
      ]);
      _owner = intent;
    } catch (e) {
      if (e.toString().contains('Deadlock')) {
        debugPrint('[Orchestrator] TIMEOUT RESET TRIGGERED');
        reset();
      }
      rethrow;
    }
  }

  Future<void> _waitForFree() async {
    // Simplified: because _processQueue uses `while`, 
    // it naturally serializes. But if we need to wait for external releases:
    while (_owner != null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _release() {
    _owner = null;
    // Decision 6 — Starvation Protection: The while loop automatically grabs the next one,
    // and since processing clears preview requests, there's no starvation.
  }

  Future<void> _forceReleasePreview() async {
    if (videoPlayerController != null) {
      debugPrint('[Orchestrator] FORCE RELEASE PREVIEW');
      try {
        await videoPlayerController?.pause();
        await videoPlayerController?.dispose();
      } catch (_) {}
      videoPlayerController = null;
      await Future.delayed(const Duration(milliseconds: 120));
    }
    if (_owner == MediaIntent.preview) {
      _owner = null;
    }
  }
}

final mediaOrchestrator = MediaOrchestrator.instance;
