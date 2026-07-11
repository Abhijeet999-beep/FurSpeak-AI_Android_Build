import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_colors.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/media/services/media_orchestrator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// WhatsApp Status-inspired video trimmer with a bold rectangular selection
/// box overlaying a video thumbnail strip, thick draggable side handles,
/// and dimmed out-of-range regions. Refined for FurSpeak AI "Velvet Paw" DS.
class VideoTrimmerScreen extends StatefulWidget {
  final String videoPath;
  final int maxDurationSeconds;
  final void Function(String trimmedPath) onTrimmed;

  const VideoTrimmerScreen({
    super.key,
    required this.videoPath,
    this.maxDurationSeconds = 30,
    required this.onTrimmed,
  });

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen>
    with SingleTickerProviderStateMixin {
  final Trimmer _trimmer = Trimmer();

  final ValueNotifier<double> _startValueNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _endValueNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);

  bool _isLoading = true;
  bool _isTrimming = false;
  bool _isEmulator = false;

  Duration _totalDuration = Duration.zero;
  int _lastHapticTime = 0;

  // Design System Integration
  static const Color _bgDark = Color(0xFF121418); // Sleeker dark
  static const Color _surfaceDark = Color(0xFF1E2228);
  
  final String _requestId = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkEmulator();
    _loadVideo();
  }

  Future<void> _checkEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _isEmulator = !androidInfo.isPhysicalDevice;
      }
    } catch (_) {
      _isEmulator = false;
    }
  }

  Future<void> _loadVideo() async {
    mediaOrchestrator.request(MediaRequest(MediaIntent.preview, () async {
      await _trimmer.loadVideo(videoFile: File(widget.videoPath));
      
      if (!mounted) return;
      
      final controller = _trimmer.videoPlayerController;
      if (controller != null) {
        mediaOrchestrator.videoPlayerController = controller;
        
        final duration = controller.value.duration;
        final maxMs = (widget.maxDurationSeconds * 1000).toDouble();
        final endVal = duration.inMilliseconds.toDouble() > maxMs 
            ? maxMs 
            : duration.inMilliseconds.toDouble();
            
        _startValueNotifier.value = 0.0;
        _endValueNotifier.value = endVal;
        
        setState(() {
          _totalDuration = duration;
          _isLoading = false;
        });
      }
    }, _requestId));
  }

  @override
  void dispose() {
    mediaOrchestrator.cancel(_requestId);
    _startValueNotifier.dispose();
    _endValueNotifier.dispose();
    _isPlayingNotifier.dispose();
    _trimmer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Duration _getSelectedDuration(double start, double end) {
    final ms = (end - start).clamp(0, double.infinity);
    return Duration(milliseconds: ms.toInt());
  }

  bool _getIsOverLimit(double start, double end) =>
      _getSelectedDuration(start, end).inSeconds > widget.maxDurationSeconds;

  void _debouncedHaptic() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticTime > 100) { // 100ms debounce
      FurHaptics.select();
      _lastHapticTime = now;
    }
  }

  Future<bool> _isValidMp4Container(File file) async {
    try {
      if (!await file.exists()) return false;
      final size = await file.length();
      if (size < 8) return false;
      
      final raf = await file.open(mode: FileMode.read);
      try {
        final bytes = await raf.read(8);
        if (bytes.length < 8) return false;
        
        // MP4 magic bytes: 'ftyp' starting at index 4
        return bytes[4] == 0x66 && // 'f'
               bytes[5] == 0x74 && // 't'
               bytes[6] == 0x79 && // 'y'
               bytes[7] == 0x70;   // 'p'
      } finally {
        await raf.close();
      }
    } catch (e) {
      debugPrint('⚠️ [TRIMMER] Error validating MP4 container: $e');
      return false;
    }
  }

  Future<bool> _waitForFileRelease(File file, {int maxAttempts = 15, int delayMs = 150}) async {
    int attempts = 0;
    int lastSize = -1;
    
    while (attempts < maxAttempts) {
      if (await file.exists()) {
        final size = await file.length();
        debugPrint('🎬 [TRIMMER] Wait attempt ${attempts + 1}: Size is $size bytes (last size was $lastSize)');
        if (size > 0 && size == lastSize) {
          // File size has stabilized! Let's check readability
          try {
            final raf = await file.open(mode: FileMode.read);
            await raf.close();
            debugPrint('🎬 [TRIMMER] File successfully unlocked and stable at $size bytes.');
            return true;
          } catch (e) {
            debugPrint('🎬 [TRIMMER] File exists but still locked: $e');
          }
        }
        lastSize = size;
      } else {
        debugPrint('🎬 [TRIMMER] Wait attempt ${attempts + 1}: File does not exist yet.');
      }
      
      attempts++;
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    return false;
  }

  Future<Map<String, dynamic>> _verifyExportedVideo(String outputPath) async {
    final file = File(outputPath);

    // Wait for the file to be fully written and closed on disk
    final released = await _waitForFileRelease(file);
    
    // Retrieve FFmpeg exit code and logs if possible
    int? lastExitCode;
    String? ffmpegLogs;
    try {
      final sessions = await FFmpegKit.listSessions();
      if (sessions.isNotEmpty) {
        final lastSession = sessions.last;
        final returnCode = await lastSession.getReturnCode();
        lastExitCode = returnCode?.getValue();

        final logs = await lastSession.getLogs();
        ffmpegLogs = logs.map((l) => l.getMessage()).join('\n');
      }
    } catch (e) {
      debugPrint('⚠️ [TRIMMER] Error retrieving last FFmpeg session: $e');
    }

    final exists = await file.exists();
    int size = 0;
    DateTime? lastModified;
    if (exists) {
      size = await file.length();
      lastModified = await file.lastModified();
    }

    // Log required verification data
    debugPrint('🎬 [TRIMMER] VERIFICATION LOGS:');
    debugPrint('🎬 [TRIMMER] - Output Path: $outputPath');
    debugPrint('🎬 [TRIMMER] - File Exists: $exists');
    debugPrint('🎬 [TRIMMER] - File Released: $released');
    debugPrint('🎬 [TRIMMER] - File Length (Size): $size bytes');
    debugPrint('🎬 [TRIMMER] - Last Modified Time: $lastModified');
    debugPrint('🎬 [TRIMMER] - FFmpeg/Trimmer Exit Code: $lastExitCode');

    if (!exists) {
      return {
        'valid': false,
        'exitCode': lastExitCode,
        'ffmpegLogs': ffmpegLogs,
        'error': 'Exported file does not exist on disk.',
      };
    }

    if (!released || size <= 0) {
      return {
        'valid': false,
        'exitCode': lastExitCode,
        'ffmpegLogs': ffmpegLogs,
        'error': 'Exported file is empty or locked by the system.',
      };
    }
    
    // Check container
    final isMp4 = await _isValidMp4Container(file);
    if (!isMp4) {
      return {
        'valid': false,
        'exitCode': lastExitCode,
        'ffmpegLogs': ffmpegLogs,
        'error': 'Exported file is not a valid MP4 video.',
      };
    }

    // Try extracting metadata using FFprobeKit (primary source - robust for local files)
    int durationMs = 0;
    try {
      debugPrint('🎬 [TRIMMER] Probing metadata using FFprobeKit...');
      final session = await FFprobeKit.getMediaInformation(outputPath);
      final mediaInfo = session.getMediaInformation();
      if (mediaInfo != null) {
        final durationStr = mediaInfo.getDuration();
        debugPrint('🎬 [TRIMMER] FFprobe duration string: $durationStr');
        if (durationStr != null && durationStr.isNotEmpty) {
          final double? durationSec = double.tryParse(durationStr);
          if (durationSec != null) {
            durationMs = (durationSec * 1000).toInt();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [TRIMMER] FFprobe media information check failed: $e');
    }

    // Fall back to VideoPlayerController if FFprobe failed or returned 0ms
    if (durationMs <= 0) {
      debugPrint('🎬 [TRIMMER] FFprobe returned 0 duration. Falling back to VideoPlayerController...');
      final tempController = VideoPlayerController.file(file);
      try {
        await tempController.initialize();
        final duration = tempController.value.duration;
        durationMs = duration.inMilliseconds;
        await tempController.dispose();
      } catch (e) {
        await tempController.dispose();
        debugPrint('⚠️ [TRIMMER] VideoPlayerController fallback check failed: $e');
      }
    }

    debugPrint('🎬 [TRIMMER] - Metadata Duration: $durationMs ms');

    if (durationMs <= 0) {
      return {
        'valid': false,
        'exitCode': lastExitCode,
        'ffmpegLogs': ffmpegLogs,
        'durationMs': durationMs,
        'error': 'Exported video has an invalid duration (0ms).',
      };
    }

    return {
      'valid': true,
      'size': size,
      'durationMs': durationMs,
      'exitCode': lastExitCode,
      'ffmpegLogs': ffmpegLogs,
    };
  }

  Future<void> _onTrimPressed() async {
    final double start = _startValueNotifier.value;
    final double end = _endValueNotifier.value;

    if (start >= end) {
      _showError('Invalid trim range: Start time must be before end time.');
      return;
    }

    FurHaptics.impact();
    setState(() => _isTrimming = true);

    final originalName = widget.videoPath.split('/').last.split('.').first;
    // Replace colons, spaces, and other special characters with underscores to prevent URI scheme parsing errors
    final cleanOriginalName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String customFileName = '${cleanOriginalName}_trimmed_$timestamp';

    final DateTime exportStartTime = DateTime.now();
    debugPrint('🎬 [TRIMMER] Starting export at $exportStartTime');
    debugPrint('🎬 [TRIMMER] Target trim range: ${start}ms to ${end}ms (duration: ${end - start}ms)');
    debugPrint('🎬 [TRIMMER] Saving trimmed video with custom filename: $customFileName');

    _trimmer.saveTrimmedVideo(
      startValue: start,
      endValue: end,
      videoFileName: customFileName,
      onSave: (outputPath) async {
        if (!mounted) return;

        final DateTime exportEndTime = DateTime.now();
        final elapsed = exportEndTime.difference(exportStartTime);

        if (outputPath != null) {
          debugPrint('🎬 [TRIMMER] saveTrimmedVideo callback: outputPath = $outputPath');
          debugPrint('🎬 [TRIMMER] Export completed in ${elapsed.inMilliseconds}ms');
          
          final verification = await _verifyExportedVideo(outputPath);
          
          debugPrint('🎬 [TRIMMER] Verification result: ${verification['valid']}');
          
          if (verification['valid'] == true) {
            setState(() => _isTrimming = false);
            FurHaptics.heavy();
            widget.onTrimmed(outputPath);
          } else {
            setState(() => _isTrimming = false);
            final String errorMsg = verification['error'] ?? 'Unknown trimming failure.';
            final String details = 'Path: $outputPath\n'
                'Size: ${verification['size'] ?? "N/A"} bytes\n'
                'Duration: ${verification['durationMs'] ?? "N/A"} ms\n'
                'Exit Code: ${verification['exitCode'] ?? "N/A"}\n'
                'Error: $errorMsg\n'
                'FFmpeg Logs:\n${verification['ffmpegLogs'] ?? "None"}';
            debugPrint('❌ [TRIMMER] Video verification failed:\n$details');
            _showError('Video export failed: $errorMsg');
          }
        } else {
          setState(() => _isTrimming = false);
          _showError('Trimming failed (no output path returned). Please try again.');
        }
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    FurHaptics.tap();
    final controller = _trimmer.videoPlayerController;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
      _isPlayingNotifier.value = false;
    } else {
      controller.play();
      _isPlayingNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () {
            FurHaptics.tap();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Clip Highlights',
          style: AppTheme.titleStyle.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildEditor(),
          if (_isLoading)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: _bgDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.successColor,
              strokeWidth: 3,
            ).animate(onPlay: (c) => c.repeat())
             .shimmer(duration: 1500.ms, color: Colors.white24),
            const SizedBox(height: AppTheme.space24),
            Text(
              'Preparing your pet\'s video...',
              style: AppTheme.bodyStyle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final maxDur = Duration(seconds: widget.maxDurationSeconds);
    final needsTrim = _totalDuration > maxDur;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenHeight = constraints.maxHeight;
        // Adjust preview height based on available space
        final bool isSmallScreen = screenHeight < 600;

        return Column(
          children: [
            // ── Video Preview ──────────────────────────────────────────────
            Expanded(
              flex: isSmallScreen ? 3 : 5,
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  AppTheme.space12,
                  MediaQuery.of(context).padding.top + 20,
                  AppTheme.space12,
                  AppTheme.space12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoViewer(trimmer: _trimmer),
                        
                        // Play/Pause Overlay
                        ValueListenableBuilder<bool>(
                          valueListenable: _isPlayingNotifier,
                          builder: (context, isPlaying, child) {
                            return AnimatedOpacity(
                              duration: AppTheme.animFast,
                              opacity: isPlaying ? 0.0 : 1.0,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 1.5),
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Controls & Actions ──────────────────────────────────────────
            Flexible(
              flex: isSmallScreen ? 4 : 3,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppTheme.space8),
                    _buildManualTrimSection(maxDur),
                    _buildActionButtons(needsTrim),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  Widget _buildManualTrimSection(Duration maxDur) {
    return Column(
      key: const ValueKey('manual_trim'),
      children: [
        _buildTrimTimeline(maxDur),
        const SizedBox(height: AppTheme.space16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
          child: ValueListenableBuilder<double>(
            valueListenable: _startValueNotifier,
            builder: (context, start, _) {
              return ValueListenableBuilder<double>(
                valueListenable: _endValueNotifier,
                builder: (context, end, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TimeLabel(
                        label: _formatDuration(Duration(milliseconds: start.toInt())),
                        icon: Icons.start_rounded,
                      ),
                      _SelectedDurationChip(
                        duration: _formatDuration(_getSelectedDuration(start, end)),
                        isOverLimit: _getIsOverLimit(start, end),
                      ),
                      _TimeLabel(
                        label: _formatDuration(Duration(milliseconds: end.toInt())),
                        icon: Icons.stop_rounded,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.space20),
      ],
    );
  }

  Widget _buildTrimTimeline(Duration maxDur) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: 80,
            child: PetMoodGlass(
              opacity: 0.15,
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
              child: TrimViewer(
                trimmer: _trimmer,
                viewerHeight: 80,
                viewerWidth: constraints.maxWidth,
                maxVideoLength: maxDur,
                type: ViewerType.auto,
                showDuration: false,
                paddingFraction: 0,
                onChangeStart: (value) {
                  _debouncedHaptic();
                  _startValueNotifier.value = value;
                },
                onChangeEnd: (value) {
                  _debouncedHaptic();
                  _endValueNotifier.value = value;
                },
                onChangePlaybackState: (isPlaying) => _isPlayingNotifier.value = isPlaying,
                editorProperties: const TrimEditorProperties(
                  borderWidth: 6.0,
                  borderRadius: 2,
                  circleSize: 15,
                  circleSizeOnDrag: 22,
                  scrubberWidth: 2,
                  borderPaintColor: AppColors.tertiary,
                  circlePaintColor: AppColors.tertiary,
                  scrubberPaintColor: Colors.white,
                  sideTapSize: 48,
                ),
                areaProperties: TrimAreaProperties(
                  borderRadius: 12,
                  thumbnailQuality: _isEmulator ? 10 : 25,
                  thumbnailFit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(bool needsTrim) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Row(
        children: [
          Expanded(
            child: SquishButton(
              onPressed: () => Navigator.pop(context),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  'Cancel',
                  style: AppTheme.titleStyle.copyWith(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            flex: 2,
            child: SquishButton(
              onPressed: _isTrimming ? null : _onTrimPressed,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)], // Fresh Mint Gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successColor.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _isTrimming
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  needsTrim ? 'Trim & Analyze' : 'Start Analysis',
                                  style: AppTheme.titleStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _TimeLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.captionStyle.copyWith(
              color: Colors.white70,
              fontSize: 13,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDurationChip extends StatelessWidget {
  final String duration;
  final bool isOverLimit;

  const _SelectedDurationChip({required this.duration, required this.isOverLimit});

  @override
  Widget build(BuildContext context) {
    final color = isOverLimit ? AppTheme.errorColor : AppTheme.successColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverLimit ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            duration,
            style: AppTheme.captionStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
