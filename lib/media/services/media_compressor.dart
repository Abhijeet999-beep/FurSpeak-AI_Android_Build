import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MediaCompressor {
  /// Fetches video duration in seconds using FFprobe
  static Future<double> getVideoDuration(File file) async {
    try {
      final infoSession = await FFprobeKit.getMediaInformation(file.path);
      final info = infoSession.getMediaInformation();
      if (info != null) {
        return double.tryParse(info.getDuration() ?? '0') ?? 0;
      }
    } catch (e) {
      debugPrint('⚠️ [COMPRESSOR] Could not get duration via FFprobe: $e');
    }
    return 0;
  }

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
  /// Shared flags:
  ///   -hwaccel auto     → use hardware decoding where available
  ///   -threads 2        → cap CPU to 2 cores
  ///   -preset ultrafast → fastest libx264 preset
  static Future<File?> compressVideo(File file, {void Function(double)? onProgress}) async {
    final fileSize = await file.length();
    debugPrint('🎬 [COMPRESSOR] Video size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

    // ── Tier 0: Skip — file is already tiny ──────────────────────────────
    if (fileSize < _skipThresholdBytes) {
      debugPrint('⚡ [COMPRESSOR] < 5 MB — skipping compression (Tier 0 fast path)');
      onProgress?.call(1.0);
      return file;
    }

    // ── Get Duration for progress tracking ──────────────────────────────
    double duration = await getVideoDuration(file);
    if (duration > 0) {
      debugPrint('⏱️ [COMPRESSOR] Video duration: ${duration.toStringAsFixed(2)}s');
    }

    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    // ── Tier selection ────────────────────────────────────────────────────
    final bool   isLightPass = fileSize <= _lightThresholdBytes;
    final String resolution  = isLightPass ? '480'  : '720';   
    final String fps         = isLightPass ? '15'   : '20';    
    final String gop         = isLightPass ? '15'   : '20';    
    final String crf         = isLightPass ? '32'   : '28';    
    
    debugPrint('📦 [COMPRESSOR] Compressing to ${resolution}p @ ${fps}fps...');

    // ── Progress Callback ────────────────────────────────────────────────
    if (onProgress != null && duration > 0) {
      FFmpegKitConfig.enableStatisticsCallback((stats) {
        final double progress = (stats.getTime() / (duration * 1000)).clamp(0.0, 1.0);
        onProgress(progress);
      });
    }

    final stopwatch = Stopwatch()..start();

    final session = await FFmpegKit.executeWithArguments([
      '-hwaccel',  'auto',
      '-i',        file.path,
      '-vf',       'scale=-2:$resolution',
      '-r',        fps,
      '-c:v',      'libx264',
      '-preset',   'ultrafast',
      '-crf',      crf,
      '-g',        gop,
      '-threads',  '2',
      '-c:a',      'copy',
      '-movflags', '+faststart',
      '-y',
      targetPath,
    ]);

    // Cleanup callback
    FFmpegKitConfig.enableStatisticsCallback(null);

    stopwatch.stop();
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      onProgress?.call(1.0);
      final compressedFile = File(targetPath);
      final newSize = await compressedFile.length();
      debugPrint('✅ [COMPRESSOR] Finished in ${stopwatch.elapsedMilliseconds}ms. New size: ${(newSize / 1024).toStringAsFixed(0)} KB');
      
      if (file.path.contains('camera_') || file.path.contains('trim_')) {
        try { await file.delete(); } catch (_) {}
      }
      return compressedFile;
    } else {
      debugPrint('❌ [COMPRESSOR] FFmpeg failed — using original.');
      return file; 
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
