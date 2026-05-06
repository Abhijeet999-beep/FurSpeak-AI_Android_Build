import 'package:flutter_test/flutter_test.dart';
import 'package:furspeak_ai/utils/error_mapper.dart';

void main() {
  group('ErrorMapper.mapException', () {
    // ── No Dog Detected ────────────────────────────────────────────
    test('maps NO_DOG_DETECTED backend error', () {
      final error = ErrorMapper.mapException('NO_DOG_DETECTED');
      expect(error.type, AppErrorType.noDogDetected);
      expect(error.canRetry, false);
    });

    test('maps "no dog detected" human-readable string', () {
      final error = ErrorMapper.mapException('no dog detected in this frame');
      expect(error.type, AppErrorType.noDogDetected);
    });

    test('maps NOT_A_DOG validation error', () {
      final error = ErrorMapper.mapException('NOT_A_DOG');
      expect(error.type, AppErrorType.noDogDetected);
    });

    // ── No Emotion Detected ────────────────────────────────────────
    test('maps NO_EMOTION_DETECTED', () {
      final error = ErrorMapper.mapException('NO_EMOTION_DETECTED');
      expect(error.type, AppErrorType.noEmotion);
      expect(error.canRetry, false);
    });

    // ── Invalid ROI ────────────────────────────────────────────────
    test('maps INVALID_ROI', () {
      final error = ErrorMapper.mapException('INVALID_ROI');
      expect(error.type, AppErrorType.invalidRoi);
      expect(error.canRetry, false);
    });

    // ── File Too Large ─────────────────────────────────────────────
    test('maps FILE_TOO_LARGE', () {
      final error = ErrorMapper.mapException('FILE_TOO_LARGE');
      expect(error.type, AppErrorType.fileTooLarge);
      expect(error.canRetry, false);
    });

    // ── Corrupt Media ──────────────────────────────────────────────
    test('maps CORRUPT_MEDIA', () {
      final error = ErrorMapper.mapException('CORRUPT_MEDIA: File verification failed');
      expect(error.type, AppErrorType.corruptMedia);
      expect(error.canRetry, false);
    });

    test('maps UNSUPPORTED_MEDIA', () {
      final error = ErrorMapper.mapException('UNSUPPORTED_MEDIA');
      expect(error.type, AppErrorType.corruptMedia);
    });

    // ── Timeout ────────────────────────────────────────────────────
    test('maps timeout error', () {
      final error = ErrorMapper.mapException('Connection timeout');
      expect(error.type, AppErrorType.timeout);
    });

    test('maps timeout with [pre_response] allows retry', () {
      final error = ErrorMapper.mapException('[pre_response] Connection timeout');
      expect(error.type, AppErrorType.timeout);
      expect(error.canRetry, true);
    });

    // ── Network Error ──────────────────────────────────────────────
    test('maps socket error', () {
      final error = ErrorMapper.mapException('SocketException: Connection refused');
      expect(error.type, AppErrorType.networkError);
    });

    test('maps failed host lookup', () {
      final error = ErrorMapper.mapException('Failed host lookup');
      expect(error.type, AppErrorType.networkError);
    });

    // ── Server Error ───────────────────────────────────────────────
    test('maps 500 server error', () {
      final error = ErrorMapper.mapException('500 Internal Server Error');
      expect(error.type, AppErrorType.serverError);
    });

    // ── Cancelled ──────────────────────────────────────────────────
    test('maps cancelled', () {
      final error = ErrorMapper.mapException('Request cancelled');
      expect(error.type, AppErrorType.cancelled);
      expect(error.canRetry, true);
    });

    // ── Unknown / Fallback ─────────────────────────────────────────
    test('maps unknown error as fallback', () {
      final error = ErrorMapper.mapException('some completely unknown error xyz');
      expect(error.type, AppErrorType.unknown);
    });

    // ── Short message helper ───────────────────────────────────────
    test('mapErrorShort returns emoji + message', () {
      final short = ErrorMapper.mapErrorShort('NO_DOG_DETECTED');
      expect(short, contains('🔍'));
      expect(short, contains("couldn't spot a dog"));
    });
  });
}
