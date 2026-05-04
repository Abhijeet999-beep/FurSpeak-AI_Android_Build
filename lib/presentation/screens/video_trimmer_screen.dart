import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/media/services/media_orchestrator.dart';
/// WhatsApp Status-inspired video trimmer with a bold rectangular selection
/// box overlaying a video thumbnail strip, thick draggable side handles,
/// and dimmed out-of-range regions.
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

  // Handle accent color
  static const Color _handleColor = Color(0xFF00D679); // WhatsApp green
  static const Color _bgDark = Color(0xFF1A1A2E);

  final String _requestId = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
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
          _endValue = _totalDuration.inMilliseconds.toDouble();
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
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () {
            FurHaptics.tap();
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              'Trim Video',
              style: AppTheme.titleStyle.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (!_isLoading)
              Text(
                '${_formatDuration(_selectedDuration)} selected  •  ${widget.maxDurationSeconds}s max',
                style: AppTheme.captionStyle.copyWith(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      // IMPORTANT: Always build the editor so TrimViewer is mounted
      // and listening for TrimmerEvent.initialized BEFORE loadVideo completes.
      // Otherwise the broadcast event is missed and TrimViewer renders empty.
      body: Stack(
        children: [
          _buildEditor(),
          if (_isLoading)
            Container(
              color: _bgDark,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: _handleColor,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      'Loading video...',
                      style: AppTheme.captionStyle.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video Player
                RepaintBoundary(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                    child: VideoViewer(trimmer: _trimmer),
                  ),
                ),

                // Play/Pause overlay
                AnimatedOpacity(
                  duration: AppTheme.animFast,
                  opacity: _isPlaying ? 0.0 : 1.0,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTheme.space16),

        // ── WhatsApp-Style Trim Timeline ──────────────────────────────
        _buildTrimTimeline(maxDur),

        const SizedBox(height: AppTheme.space12),

        // ── Duration Info Row ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Start time
              _TimeLabel(
                label: _formatDuration(
                    Duration(milliseconds: _startValue.toInt())),
                icon: Icons.flag_outlined,
              ),
              // Selected duration chip
              _SelectedDurationChip(
                duration: _formatDuration(_selectedDuration),
                isOverLimit: _isOverLimit,
              ),
              // End time
              _TimeLabel(
                label:
                    _formatDuration(Duration(milliseconds: _endValue.toInt())),
                icon: Icons.flag_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.space8),

        // ── Helper text ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
          child: Text(
            needsTrim
                ? 'Drag the handles to select up to ${widget.maxDurationSeconds} seconds'
                : '✅ This video is short enough — no trimming needed!',
            textAlign: TextAlign.center,
            style: AppTheme.captionStyle.copyWith(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: AppTheme.space16),

        // ── Action Buttons ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.space24, 0, AppTheme.space24, AppTheme.space24),
          child: Row(
            children: [
              // Cancel
              Expanded(
                child: SquishButton(
                  onPressed: () {
                    FurHaptics.tap();
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTheme.titleStyle.copyWith(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppTheme.space12),

              // Trim & Use
              Expanded(
                flex: 2,
                child: SquishButton(
                  onPressed: _isTrimming ? null : _onTrimPressed,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00B865), Color(0xFF00D679)],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: _handleColor.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _isTrimming
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.content_cut_rounded,
                                  size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                needsTrim ? 'Trim & Analyze' : 'Use Video',
                                style: AppTheme.titleStyle.copyWith(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the WhatsApp Status-style trim timeline with a rectangular
  /// selection box overlaying thumbnail frames.
  Widget _buildTrimTimeline(Duration maxDur) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TrimViewer(
            trimmer: _trimmer,
            viewerHeight: 72,
            viewerWidth: constraints.maxWidth,
            maxVideoLength: maxDur,
            type: ViewerType.auto,
            showDuration: false,
            paddingFraction: 0.1,
            onChangeStart: (value) {
              setState(() => _startValue = value);
            },
            onChangeEnd: (value) {
              setState(() => _endValue = value);
            },
            onChangePlaybackState: (isPlaying) {
              setState(() => _isPlaying = isPlaying);
            },
            editorProperties: TrimEditorProperties(
              // Bold rectangular border — WhatsApp-style selection box
              borderWidth: 4.0,
              borderRadius: 6,
              // Side handle circles — prominent & draggable
              circleSize: 10,
              circleSizeOnDrag: 14,
              // Scrubber: thin white playhead line
              scrubberWidth: 2.5,
              // Colors — vivid green for high contrast
              borderPaintColor: _handleColor,
              circlePaintColor: _handleColor,
              scrubberPaintColor: Colors.white,
              // Wide touch area for comfortable dragging
              sideTapSize: 32,
            ),
            areaProperties: TrimAreaProperties(
              borderRadius: 6,
              thumbnailQuality: 50,
              thumbnailFit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}

/// Small label showing a time value with an icon.
class _TimeLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _TimeLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white30),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.captionStyle.copyWith(
            color: Colors.white54,
            fontSize: 12,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Chip showing the selected duration with color-coded status.
class _SelectedDurationChip extends StatelessWidget {
  final String duration;
  final bool isOverLimit;

  const _SelectedDurationChip({
    required this.duration,
    required this.isOverLimit,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOverLimit ? AppTheme.errorColor : const Color(0xFF00D679);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverLimit
                ? Icons.warning_amber_rounded
                : Icons.content_cut_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            duration,
            style: AppTheme.captionStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
