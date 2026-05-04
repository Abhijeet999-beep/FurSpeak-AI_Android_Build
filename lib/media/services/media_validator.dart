import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:furspeak_ai/media/services/media_orchestrator.dart';

class MediaValidator {
  static const int maxVideoDurationSeconds = 30;

  /// Hard rejection limit — videos above this are never processed.
  static const int hardRejectDurationSeconds = 60;

  static const int backendSizeLimitMB = 50;

  static Future<bool> isVideo(File file) async {
    final lowerPath = file.path.toLowerCase();
    return lowerPath.endsWith('.mp4') || lowerPath.endsWith('.mov') || lowerPath.endsWith('.avi');
  }

  static Future<bool> isImage(File file) async {
    final lowerPath = file.path.toLowerCase();
    return lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.png');
  }

  /// Returns the video duration in seconds, or -1 if unreadable.
  ///
  /// Used for defense-in-depth validation in [MediaProcessor].
  static Future<int> getDurationSeconds(File file) async {
    final completer = Completer<int>();
    final requestId = UniqueKey().toString();

    mediaOrchestrator.request(
      MediaRequest(MediaIntent.processing, () async {
        final controller = VideoPlayerController.file(file);
        mediaOrchestrator.videoPlayerController = controller;

        try {
          await controller.initialize();
          if (!completer.isCompleted) {
            completer.complete(controller.value.duration.inSeconds);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.complete(-1);
          }
        } finally {
          await controller.dispose();
          mediaOrchestrator.videoPlayerController = null;
        }
      }, requestId),
    );

    return completer.future;
  }

  /// Validates duration. Returns true if <= 30 seconds.
  static Future<bool> validateVideoDuration(File file) async {
    final seconds = await getDurationSeconds(file);
    if (seconds < 0) return false;
    return seconds <= maxVideoDurationSeconds;
  }

  static Future<bool> validateSize(File file) async {
    if (!await file.exists()) return false;
    final sizeBytes = await file.length();
    return sizeBytes <= (backendSizeLimitMB * 1024 * 1024);
  }
}
