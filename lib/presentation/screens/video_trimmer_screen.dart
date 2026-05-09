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

  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isLoading = true;
  bool _isTrimming = false;
  bool _isPlaying = false;

  Duration _totalDuration = Duration.zero;

  // Design System Integration
  static const Color _bgDark = Color(0xFF121418); // Sleeker dark
  static const Color _surfaceDark = Color(0xFF1E2228);
  
  final String _requestId = UniqueKey().toString();
  bool _isManualMode = false;

  @override
  void initState() {
    super.initState();
    // Force dark status bar for media editing
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    mediaOrchestrator.request(MediaRequest(MediaIntent.preview, () async {
      await _trimmer.loadVideo(videoFile: File(widget.videoPath));
      
      if (!mounted) return;
      
      final controller = _trimmer.videoPlayerController;
      if (controller != null) {
        mediaOrchestrator.videoPlayerController = controller;
        setState(() {
          _totalDuration = controller.value.duration;
          final maxMs = (widget.maxDurationSeconds * 1000).toDouble();
          _endValue = _totalDuration.inMilliseconds.toDouble() > maxMs 
              ? maxMs 
              : _totalDuration.inMilliseconds.toDouble();
          _isLoading = false;
        });
      }
    }, _requestId));
  }

  @override
  void dispose() {
    mediaOrchestrator.cancel(_requestId);
    _trimmer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Duration get _selectedDuration {
    final ms = (_endValue - _startValue).clamp(0, double.infinity);
    return Duration(milliseconds: ms.toInt());
  }

  bool get _isOverLimit =>
      _selectedDuration.inSeconds > widget.maxDurationSeconds;

  Future<void> _onTrimPressed() async {
    FurHaptics.impact();
    setState(() => _isTrimming = true);

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
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
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _isPlaying = false;
      } else {
        controller.play();
        _isPlaying = true;
      }
    });
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
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () {
            FurHaptics.tap();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Review Video',
          style: AppTheme.titleStyle.copyWith(
            color: Colors.white,
            fontSize: 18,
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

    return Column(
      children: [
        // ── Video Preview ──────────────────────────────────────────────
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 100, 12, 12),
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
                    AnimatedOpacity(
                      duration: AppTheme.animFast,
                      opacity: _isPlaying ? 0.0 : 1.0,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppTheme.space16),

        // ── Controls Section ───────────────────────────────────────────
        AnimatedSwitcher(
          duration: AppTheme.animMedium,
          child: (needsTrim && !_isManualMode)
              ? _buildMagicTrimCard()
              : _buildManualTrimSection(maxDur),
        ),

        // ── Action Buttons ────────────────────────────────────────────
        _buildActionButtons(needsTrim),
      ],
    );
  }

  Widget _buildMagicTrimCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      child: Container(
        key: const ValueKey('magic_trim'),
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.successColor, size: 20),
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Magic Trim Active',
                        style: AppTheme.titleStyle.copyWith(color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Analyzing the first ${widget.maxDurationSeconds}s for the best results.',
                        style: AppTheme.bodyStyle.copyWith(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space16),
            SquishButton(
              onPressed: () => setState(() => _isManualMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded, size: 14, color: AppTheme.successColor),
                    const SizedBox(width: 8),
                    Text(
                      'Customize Trim Range',
                      style: AppTheme.captionStyle.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildManualTrimSection(Duration maxDur) {
    return Column(
      key: const ValueKey('manual_trim'),
      children: [
        _buildTrimTimeline(maxDur),
        const SizedBox(height: AppTheme.space16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimeLabel(
                label: _formatDuration(Duration(milliseconds: _startValue.toInt())),
                icon: Icons.start_rounded,
              ),
              _SelectedDurationChip(
                duration: _formatDuration(_selectedDuration),
                isOverLimit: _isOverLimit,
              ),
              _TimeLabel(
                label: _formatDuration(Duration(milliseconds: _endValue.toInt())),
                icon: Icons.stop_rounded,
              ),
            ],
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
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: TrimViewer(
              trimmer: _trimmer,
              viewerHeight: 80,
              viewerWidth: constraints.maxWidth,
              maxVideoLength: maxDur,
              type: ViewerType.auto,
              showDuration: false,
              paddingFraction: 0, // Fill the container
              onChangeStart: (value) => setState(() => _startValue = value),
              onChangeEnd: (value) => setState(() => _endValue = value),
              onChangePlaybackState: (isPlaying) => setState(() => _isPlaying = isPlaying),
              editorProperties: TrimEditorProperties(
                borderWidth: 4.0,
                borderRadius: 8,
                circleSize: 12,
                circleSizeOnDrag: 16,
                scrubberWidth: 3,
                borderPaintColor: AppTheme.successColor,
                circlePaintColor: AppTheme.successColor,
                scrubberPaintColor: Colors.white,
                sideTapSize: 32,
              ),
              areaProperties: TrimAreaProperties(
                borderRadius: 8,
                thumbnailQuality: 40,
                thumbnailFit: BoxFit.cover,
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
                      color: AppTheme.successColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _isTrimming
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            needsTrim ? 'Trim & Analyze' : 'Start Analysis',
                            style: AppTheme.titleStyle.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
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
