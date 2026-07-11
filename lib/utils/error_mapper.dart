/// Centralized error mapper for FurSpeak AI.
/// Converts raw backend errors into user-friendly, playful messages.
///
/// Backend error_type codes:
///   NO_DOG_DETECTED, NO_EMOTION_DETECTED, INVALID_ROI,
///   INVALID_FILE, CORRUPT_MEDIA, UNSUPPORTED_MEDIA,
///   FILE_TOO_LARGE
library;

import 'package:flutter/material.dart';

enum AppErrorType {
  noDogDetected,
  multipleDogsDetected,
  noEmotion,
  invalidRoi,
  corruptMedia,
  unsupportedMedia,
  fileTooLarge,
  networkError,
  timeout,
  cancelled,
  serverError,
  unknown,
}

class AppError {
  final AppErrorType type;
  final String userMessage;
  final String emoji;
  final IconData icon;
  final bool canRetry;
  /// Optional hint text shown below the main message.
  final String? hint;

  const AppError({
    required this.type,
    required this.userMessage,
    required this.emoji,
    required this.icon,
    this.canRetry = true,
    this.hint,
  });
}

class ErrorMapper {
  /// Maps a raw error string/exception to a friendly [AppError].
  ///
  /// Recognizes both backend `error_type` codes (e.g. "NO_DOG_DETECTED")
  /// and human-readable strings from exception messages.
  static AppError mapException(dynamic error) {
    final message = error.toString().toLowerCase();
    final isPreResponse = message.contains('[pre_response]');

    // ── Multiple Dogs Detected ─────────────────────────────────────────
    if (message.contains('multiple_dogs') ||
        message.contains('multiple dogs') ||
        message.contains('more than one dog') ||
        message.contains('too many dogs')) {
      return const AppError(
        type: AppErrorType.multipleDogsDetected,
        userMessage: "Only one dog is allowed per scan!",
        emoji: '🐕🐕',
        icon: Icons.pets_rounded,
        canRetry: false,
        hint:
            '• Please ensure only one dog is in the image or video\n• Crop the image to show only one dog',
      );
    }

    // ── No Dog Detected ──────────────────────────────────────────────
    if (message.contains('no_dog_detected') ||
        message.contains('no dog detected') ||
        message.contains('not_a_dog')) {
      return const AppError(
        type: AppErrorType.noDogDetected,
        userMessage: "We couldn't spot a dog in this one!",
        emoji: '🔍',
        icon: Icons.pets_rounded,
        canRetry: false,
        hint:
            '• Make sure your pup is clearly visible in the frame\n• Ensure their face and ears are not blocked\n• Try scanning in a brighter room',
      );
    }

    // ── No Emotion Detected ──────────────────────────────────────────
    if (message.contains('no_emotion_detected') ||
        message.contains('no emotion detected') ||
        message.contains('could not detect')) {
      return const AppError(
        type: AppErrorType.noEmotion,
        userMessage: "Hmm, we couldn't read your pup's mood.",
        emoji: '🤔',
        icon: Icons.sentiment_neutral_rounded,
        canRetry: false,
        hint:
            '• Get closer so your dog fills the screen\n• Make sure their face is well-lit\n• Wait for them to settle before capturing',
      );
    }

    // ── Invalid ROI / Bounding Box ───────────────────────────────────
    if (message.contains('invalid_roi') ||
        message.contains('invalid bounding box') ||
        message.contains('invalid roi')) {
      return const AppError(
        type: AppErrorType.invalidRoi,
        userMessage: "The image was too tricky for us to analyze.",
        emoji: '🖼️',
        icon: Icons.crop_rounded,
        canRetry: false,
        hint: '• Keep your dog centered in the camera view\n• Avoid zooming in too much\n• Hold the camera steady',
      );
    }

    // ── File Too Large ───────────────────────────────────────────────
    if (message.contains('file_too_large') ||
        message.contains('file exceeds') ||
        message.contains('too large')) {
      return const AppError(
        type: AppErrorType.fileTooLarge,
        userMessage: 'This file is too large to process.',
        emoji: '📦',
        icon: Icons.storage_rounded,
        canRetry: false,
        hint: '• Trim your video to be under 30 seconds\n• Lower the video recording quality slightly\n• Capture a photo instead of a video',
      );
    }

    // ── Corrupt / Invalid Media ──────────────────────────────────────
    if (message.contains('corrupt') ||
        message.contains('invalid') ||
        message.contains('unsupported_media') ||
        message.contains('unsupported media') ||
        message.contains('verification failed')) {
      return const AppError(
        type: AppErrorType.corruptMedia,
        userMessage: 'This media file seems invalid.',
        emoji: '⚠️',
        icon: Icons.broken_image_rounded,
        canRetry: false,
        hint: '• Try capturing a fresh photo or video\n• Ensure the format is MP4, MOV, or JPEG\n• Don\'t use heavily edited files',
      );
    }

    // ── Timeout ──────────────────────────────────────────────────────
    if (message.contains('timeout') || message.contains('timed out')) {
      final isUnknownState = message.contains('[unknown_state]');
      return AppError(
        type: AppErrorType.timeout,
        userMessage: 'The request took too long.',
        emoji: '⏳',
        icon: Icons.timer_off_rounded,
        canRetry: isPreResponse || isUnknownState, // Safe to retry because of idempotency
        hint: isUnknownState 
          ? '• The server might have finished, try again to resume\n• Check your internet connection\n• Restart the app if it hangs'
          : '• Check your internet connection\n• Ensure you have strong cellular or WiFi signal\n• Wait a moment and try again',
      );
    }

    // ── Network / Connection ─────────────────────────────────────────
    if (message.contains('socket') ||
        message.contains('connection') ||
        message.contains('network') ||
        message.contains('failed host lookup') ||
        message.contains('errno') ||
        message.contains('unreachable')) {
      return AppError(
        type: AppErrorType.networkError,
        userMessage: 'Unable to reach the server.',
        emoji: '📡',
        icon: Icons.wifi_off_rounded,
        canRetry: isPreResponse,
        hint: "• Make sure you have an active internet connection\n• Try switching between WiFi and Cellular\n• Verify your network isn't blocking the app",
      );
    }

    // ── Server Error ─────────────────────────────────────────────────
    if (message.contains('500') || message.contains('server error')) {
      return AppError(
        type: AppErrorType.serverError,
        userMessage: 'Our servers are having a moment.',
        emoji: '🔧',
        icon: Icons.cloud_off_rounded,
        canRetry: isPreResponse,
        hint: '• Wait a few minutes as servers might be down\n• Check for app updates\n• Try a different photo or video',
      );
    }

    // ── Timeout & Cancelled ──────────────────────────────────────────
    if (message.contains('took too long') || message.contains('timeout')) {
      return const AppError(
        type: AppErrorType.timeout,
        userMessage: 'Processing took too long. Please try again.',
        emoji: '⏳',
        icon: Icons.timer_off_rounded,
        canRetry: true,
      );
    }

    if (message.contains('cancelled')) {
      return const AppError(
        type: AppErrorType.cancelled,
        userMessage: 'Processing cancelled.',
        emoji: '🛑',
        icon: Icons.cancel_rounded,
        canRetry: true,
      );
    }

    // ── Fallback ─────────────────────────────────────────────────────
    return AppError(
      type: AppErrorType.unknown,
      userMessage: 'Something went wrong.',
      emoji: '🐾',
      icon: Icons.error_outline_rounded,
      canRetry: isPreResponse,
      hint: '• Please try scanning again\n• If it persists, restart the app\n• Ensure your media file is not corrupted',
    );
  }

  /// Returns a short one-line error message (for snackbars).
  static String mapErrorShort(dynamic error) {
    final appError = mapException(error);
    return '${appError.emoji} ${appError.userMessage}';
  }
}
