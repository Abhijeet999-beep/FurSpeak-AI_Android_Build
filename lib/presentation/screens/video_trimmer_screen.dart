import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_trimmer/video_trimmer.dart';
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

  Future<void> _onTrimPressed() async {
    FurHaptics.impact();
    setState(() => _isTrimming = true);

    await _trimmer.saveTrimmedVideo(
      startValue: _startValueNotifier.value,
      endValue: _endValueNotifier.value,
      onSave: (outputPath) {
        if (!mounted) return;
        setState(() => _isTrimming = false);
        if (outputPath != null) {
          FurHaptics.heavy();
          widget.onTrimmed(outputPath);
        } else {
          _showError('Trimming failed. Please try again.');
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
