import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MediaCompressor {
  // ── Tiered video compression thresholds ───────────────────────────────────
  // < 5 MB  → skip entirely (already tiny)
  // 5–15 MB → Tier 1 light:  480p @ 15fps, CRF 32 — approx. 90% fewer pixel-frames vs 1080p@30fps
  // > 15 MB → Tier 2 full:   720p @ 20fps, CRF 28
  static const int _skipThresholdBytes  = 5  * 1024 * 1024;  //  5 MB
  static const int _lightThresholdBytes = 15 * 1024 * 1024;  // 15 MB

  // Skip image compression if file is under this threshold
  static const int _imageSkipThresholdBytes = 500 * 1024; // 500 KB

  /// Compresses a video file with a three-tier strategy:
  ///
  ///   Tier 0  < 5 MB  → skip (return original instantly — no FFmpeg call)
  ///   Tier 1  5–15 MB → 480p @ 15 fps, CRF 32, ultrafast, GOP 15
  ///   Tier 2  > 15 MB → 720p @ 20 fps, CRF 28, ultrafast, GOP 20
  ///
  /// Why 480p / 15fps for Tier 1?
  ///   The YOLO model internally resizes every frame to 640×640 anyway, so
  ///   480p gives it all the spatial detail it needs. Half the resolution
  ///   means ~75% fewer pixels per frame; half the frame rate halves the
  ///   number of frames. Combined that is ≈90% fewer pixel-frames to encode,
  ///   cutting wall-clock time from ~15s to ~2–4s on mid-range Android.
  ///
  /// Shared flags:
  ///   -hwaccel auto     → use hardware decoding where available (no-op on
  ///                       unsupported devices, free speedup where supported)
  ///   -threads 2        → cap CPU to 2 cores → UI render thread never starved
  ///   -preset ultrafast → fastest libx264 preset → 4–6 s saved on mobile
  ///   -g <fps>          → 1 I-frame per second → backend cv2 MSEC seek O(1)
  ///   -c:a copy         → stream-copy audio → zero re-encode overhead
  ///   -movflags +faststart → moov atom at file start → faster upload init
  static Future<File?> compressVideo(File file) async {
    final fileSize = await file.length();
    debugPrint('🎬 [COMPRESSOR] Video size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

    // ── Tier 0: Skip — file is already tiny ──────────────────────────────
    if (fileSize < _skipThresholdBytes) {
      debugPrint('⚡ [COMPRESSOR] < 5 MB — skipping compression (Tier 0 fast path)');
      return file;
    }

    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    // ── Tier selection ────────────────────────────────────────────────────
    // Tier 1 (5–15 MB): 480p @ 15fps — YOLO needs at most 640px, 15fps is
    //   sufficient for emotion trend. ~90% fewer pixel-frames vs 1080p@30fps.
    // Tier 2 (> 15 MB): 720p @ 20fps — slightly higher quality for large files.
    final bool   isLightPass = fileSize <= _lightThresholdBytes;
    final String resolution  = isLightPass ? '480'  : '720';   // output height
    final String fps         = isLightPass ? '15'   : '20';    // output frame rate
    final String gop         = isLightPass ? '15'   : '20';    // 1 I-frame/sec
    final String crf         = isLightPass ? '32'   : '28';    // quality
    final String tierLabel   = isLightPass
        ? 'Tier 1 light (5–15 MB) → ${resolution}p @ ${fps}fps CRF $crf'
        : 'Tier 2 full  (>15 MB)  → ${resolution}p @ ${fps}fps CRF $crf';
    debugPrint('📦 [COMPRESSOR] $tierLabel | ultrafast, 2 threads, GOP $gop, hwaccel auto');

    // ── Benchmark: wall-clock time for compression ────────────────────────
    final stopwatch = Stopwatch()..start();

    final session = await FFmpegKit.executeWithArguments([
      '-hwaccel',  'auto',              // HW decode where available (no-op if unsupported)
      '-i',        file.path,
      '-vf',       'scale=-2:$resolution',  // e.g. → 480p or 720p, keep AR
      '-r',        fps,                // halve frame rate → fewer frames to encode
      '-c:v',      'libx264',
      '-preset',   'ultrafast',        // fastest libx264 preset → min CPU time
      '-crf',      crf,
      '-g',        gop,                // I-frame every output-fps frames ≈ 1 s
      '-threads',  '2',               // 2 cores max → UI thread never starved
      '-c:a',      'copy',             // stream-copy audio → zero overhead
      '-movflags', '+faststart',       // moov at file start → faster upload
      '-y',                            // overwrite without prompt
      targetPath,
    ]);

    // Suppress verbose FFmpeg logs (keeps debug console clean)
    FFmpegKitConfig.disableLogs();

    stopwatch.stop();
    debugPrint('⏱️ [COMPRESSOR] FFmpeg wall-clock: ${stopwatch.elapsedMilliseconds} ms');

    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final compressedFile = File(targetPath);
      final newSize = await compressedFile.length();
      final reduction = ((fileSize - newSize) / fileSize * 100).toStringAsFixed(1);
      debugPrint(
        '✅ [COMPRESSOR] ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB '
        '→ ${(newSize / 1024).toStringAsFixed(0)} KB ($reduction% reduction) '
        '| ${resolution}p @ ${fps}fps | ${stopwatch.elapsedMilliseconds}ms',
      );

      // Clean up temp camera/trim files — never delete gallery originals
      if (file.path.contains('camera_') || file.path.contains('trim_')) {
        if (!file.path.contains('DCIM')) {
          try { await file.delete(); } catch (_) {}
        }
      }
      return compressedFile;
    } else {
      final failLog = await session.getFailStackTrace();
      debugPrint('❌ [COMPRESSOR] FFmpeg failed — using original. Trace: $failLog');
      return file; // graceful fallback: send the original
    }
  }

  /// Compresses an image. Skips for files < 500 KB.
  static Future<File?> compressImage(File file) async {
    final fileSize = await file.length();
    debugPrint('🖼️ [COMPRESSOR] Image size: ${(fileSize / 1024).toStringAsFixed(0)} KB');

    if (fileSize < _imageSkipThresholdBytes) {
      debugPrint('⚡ [COMPRESSOR] Image < 500 KB — skipping compression (fast path)');
      return file;
    }

    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      'opt_img_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final stopwatch = Stopwatch()..start();

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 1024,
      minHeight: 1024,
    );

    stopwatch.stop();
    debugPrint('⏱️ [COMPRESSOR] Image compress wall-clock: ${stopwatch.elapsedMilliseconds} ms');

    if (result != null) {
      final newSize = await File(result.path).length();
      debugPrint('✅ [COMPRESSOR] Image: ${(fileSize / 1024).toStringAsFixed(0)} KB → ${(newSize / 1024).toStringAsFixed(0)} KB');
      return File(result.path);
    }

    debugPrint('⚠️ [COMPRESSOR] Image compression returned null — using original.');
    return file;
  }

  /// Cleans up temp cache files safely
  static Future<void> cleanupTempFile(File? file) async {
    if (file != null && await file.exists() && file.path.contains('cache')) {
      try { await file.delete(); } catch (_) {}
    }
  }

  /// Cancels any ongoing FFmpeg compression
  static void cancelCurrentCompression() {
    FFmpegKit.cancel();
    debugPrint('🛑 [COMPRESSOR] FFmpeg execution cancelled.');
  }
}
