import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:furspeak_ai/data/models/detection_result.dart';
import 'package:furspeak_ai/services/result_storage_service.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/media/services/media_orchestrator.dart';

class ResultScreen extends StatefulWidget {
  final String resultId;

  const ResultScreen({
    super.key,
    required this.resultId,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  VideoPlayerController? _videoController;
  bool _isDisposed = false;
  final String _requestId = UniqueKey().toString();
  MediaUIState _mediaUIState = MediaUIState.idle;

  /// The persisted detection result, loaded from Isar by ID.
  DetectionResult? _detectionResult;
  bool _isLoading = true;
  bool _showGuestCard = true;

  @override
  void initState() {
    super.initState();
    _loadResult();
    HapticFeedback.mediumImpact();
  }

  /// Load result from persistent storage by ID.
  void _loadResult() {
    final storage = GetIt.instance<ResultStorageService>();
    final result = storage.getResultById(widget.resultId);

    if (result == null) {
      debugPrint('⚠️ [RESULT] No result found for id: ${widget.resultId}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goHome();
      });
      return;
    }

    _detectionResult = result;
    _isLoading = false;

    _speakResult();
    _initVideoIfNeeded();
  }

  Future<void> _initVideoIfNeeded() async {
    final r = _detectionResult;
    if (r == null) return;
    final videoPath = r.mediaPath;
    if (videoPath.isEmpty || !r.isVideo) return;

    if (!mounted) return;
    setState(() {
      _mediaUIState = MediaUIState.waitingInQueue;
    });

    mediaOrchestrator.request(
      MediaRequest(MediaIntent.preview, () async {
        if (_isDisposed || !mounted) return;

        setState(() {
          _mediaUIState = MediaUIState.executing;
        });

        final controller = VideoPlayerController.file(File(videoPath));
        mediaOrchestrator.videoPlayerController = controller;

        try {
          await controller.initialize();
          if (_isDisposed || !mounted) {
            controller.dispose();
            return;
          }
          setState(() {
            _videoController = controller;
            _mediaUIState = MediaUIState.idle;
          });
        } catch (e) {
          debugPrint('VideoPlayerController init failed: $e');
          try {
            controller.dispose();
          } catch (_) {}
          
          if (!_isDisposed && mounted) {
            setState(() {
              _videoController = null;
              _mediaUIState = MediaUIState.idle;
            });
          }
        }
      }, _requestId),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    mediaOrchestrator.cancel(_requestId);
    _videoController?.dispose();
    _videoController = null;
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakResult() async {
    final r = _detectionResult;
    if (r == null) return;
    try {
      final text = r.caption;
      if (text.isEmpty || text.contains('No emotion detected')) return;
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking result: $e');
    }
  }

  void _handleAnalyzeAnother() {
    HapticFeedback.mediumImpact();
    context.goHome();
  }

  void _handleShare() {
    HapticFeedback.mediumImpact();
    // TODO: Implement share_plus functionality here.
    // final text = 'I just analyzed my dog with FurSpeak AI! Looks like they are ${_detectionResult?.emotion}.';
    // Share.share(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sharing result... (Coming soon)'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  // ─── MEDIA PREVIEW ──────────────────────────────────────────────────
  Widget _mediaPreview() {
    final r = _detectionResult;
    if (r == null) return _failedPreviewWidget();

    final bool isVideo = r.isVideo;
    final String localImagePath = r.mediaPath;

    if (isVideo) {
      if (_mediaUIState == MediaUIState.waitingInQueue || _mediaUIState == MediaUIState.executing) {
        if (_videoController == null || !_videoController!.value.isInitialized) {
          return Container(
            height: 280,
            width: double.infinity,
            color: AppTheme.surfaceElevated,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }
      }

      if (_videoController != null && _videoController!.value.isInitialized) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
            });
          },
          child: Container(
            height: 280,
            width: double.infinity,
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  if (!_videoController!.value.isPlaying)
                    Container(
                      color: Colors.black26,
                      child: const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (!isVideo && localImagePath.isNotEmpty) {
      final file = File(localImagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _failedPreviewWidget(),
        );
      }
    }

    final frameImageUrl = r.frameImageUrl;
    if (frameImageUrl != null && frameImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: frameImageUrl,
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: AppTheme.surfaceElevated,
          highlightColor: AppTheme.surfaceBase,
          child: Container(height: 280, color: AppTheme.surfaceActive),
        ),
        errorWidget: (context, url, error) => _failedPreviewWidget(),
      );
    }

    final emotion = r.emotion.toLowerCase();
    if (emotion == 'unknown' || emotion == 'no dog detected' || emotion.isEmpty) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Lottie.asset(
            LottieRegistry.get('failed'),
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return _failedPreviewWidget();
  }

  Widget _failedPreviewWidget() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: AppTheme.borderRadiusLarge,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: AppTheme.textLightColor, size: 64),
            const SizedBox(height: AppTheme.space16),
            Text('No preview available', style: AppTheme.captionStyle),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading / not-found guard
    if (_isLoading || _detectionResult == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: AppTheme.space16),
              Text('Loading result...', style: AppTheme.captionStyle),
            ],
          ),
        ),
      );
    }

    final r = _detectionResult!;
    final emotionStyle = EmotionStyle.fromEmotion(r.emotion);
    final confidence = r.confidence;
    final caption = r.caption;
    final isError = (r.emotion.toLowerCase() == 'unknown' || confidence == 0.0);
    final isGuest = context.watch<AuthProvider>().isGuest;
    
    String confidenceLabel = 'Low';
    if (confidence >= 80.0) confidenceLabel = 'High';
    else if (confidence >= 50.0) confidenceLabel = 'Medium';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.goHome();
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ═══ 1. MEDIA PREVIEW WITH OVERLAY ═══
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppTheme.radiusLarge),
                      ),
                      child: _mediaPreview(),
                    ),
                    // Back button
                    Positioned(
                      top: AppTheme.space8,
                      left: AppTheme.space8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: AppTheme.borderRadiusMedium,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => context.goHome(),
                        ),
                      ),
                    ),
                    // Emotion badge overlay
                    Positioned(
                      bottom: AppTheme.space16,
                      right: AppTheme.space16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space12,
                          vertical: AppTheme.space8,
                        ),
                        decoration: BoxDecoration(
                          color: emotionStyle.color,
                          borderRadius: AppTheme.borderRadiusPill,
                          boxShadow: [
                            BoxShadow(
                              color: emotionStyle.color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emotionStyle.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              emotionStyle.label,
                              style: AppTheme.titleStyle.copyWith(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ═══ 2. EMOTION HEADLINE ═══
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space12),
                            decoration: BoxDecoration(
                              color: emotionStyle.color.withOpacity(0.12),
                              borderRadius: AppTheme.borderRadiusMedium,
                            ),
                            child: Icon(emotionStyle.icon, color: emotionStyle.color, size: 32),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your dog feels',
                                  style: AppTheme.captionStyle.copyWith(fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${emotionStyle.label} ${emotionStyle.emoji}',
                                  style: AppTheme.headingStyle.copyWith(
                                    color: emotionStyle.color,
                                    fontSize: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.space24),

                      // ═══ 3. CONFIDENCE BAR ═══
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceActive,
                          borderRadius: AppTheme.borderRadiusMedium,
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Confidence',
                                  style: AppTheme.titleStyle.copyWith(fontSize: 14),
                                ),
                                Text(
                                  confidenceLabel,
                                  style: AppTheme.titleStyle.copyWith(
                                    color: emotionStyle.color,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
                            ClipRRect(
                              borderRadius: AppTheme.borderRadiusPill,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: confidence / 100),
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: emotionStyle.color.withOpacity(0.12),
                                    valueColor: AlwaysStoppedAnimation<Color>(emotionStyle.color),
                                    minHeight: 10,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.space16),

                      // ═══ 4. CAPTION CARD ═══
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: emotionStyle.actionCardColor,
                          borderRadius: AppTheme.borderRadiusMedium,
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 18, color: emotionStyle.color),
                                const SizedBox(width: AppTheme.space8),
                                Text(
                                  'What we detected',
                                  style: AppTheme.titleStyle.copyWith(
                                    fontSize: 14,
                                    color: emotionStyle.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space12),
                            Text(
                              isError
                                  ? 'No emotion detected. Please ensure your dog\'s face is visible and try again.'
                                  : caption,
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.space16),

                      // ═══ 5. SUGGESTED ACTIONS ═══
                      if (r.suggestions.isNotEmpty) ...[
                        _ExpandableInsights(
                          suggestions: r.suggestions,
                          emotionStyle: emotionStyle,
                        ),
                        const SizedBox(height: AppTheme.space16),
                      ],

                      // ═══ 6. TIMELINE (if video) ═══
                      if (r.timeline.isNotEmpty)
                        _TimelineSection(
                          timeline: r.timeline,
                          timelineSummary: r.timelineSummary,
                        ),

                      if (isGuest && _showGuestCard) ...[
                        const SizedBox(height: AppTheme.space24),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.05),
                            borderRadius: AppTheme.borderRadiusLarge,
                            border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.pets, color: AppTheme.accentColor, size: 20),
                                  const SizedBox(width: AppTheme.space8),
                                  Expanded(
                                    child: Text(
                                      "This is your dog's first insight 🐾",
                                      style: AppTheme.titleStyle.copyWith(
                                        color: AppTheme.accentColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20, color: AppTheme.textLightColor),
                                    onPressed: () {
                                      setState(() {
                                        _showGuestCard = false;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space12),
                              Text(
                                "Sign in now to save this result and track your dog's emotional journey over time.",
                                style: AppTheme.bodyStyle.copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: AppTheme.space16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.goWelcome();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
                                      ),
                                      child: const Text('Sign in to Save', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.space8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _showGuestCard = false;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textColor,
                                        side: BorderSide(color: AppTheme.textLightColor.withOpacity(0.3)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
                                      ),
                                      child: const Text('Keep Exploring'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppTheme.space24),

                      // ═══ 7. BOTTOM ACTION BAR ═══
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _handleAnalyzeAnother,
                                icon: const Icon(Icons.refresh_rounded, color: AppTheme.surfaceActive),
                                label: Text(
                                  'Scan Again',
                                  style: AppTheme.titleStyle.copyWith(color: AppTheme.surfaceActive, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceElevated,
                                  foregroundColor: AppTheme.textColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppTheme.borderRadiusMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _handleShare,
                                icon: const Icon(Icons.share_rounded, color: AppTheme.surfaceActive),
                                label: Text(
                                  'Share Result',
                                  style: AppTheme.titleStyle.copyWith(color: AppTheme.surfaceActive, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: AppTheme.surfaceActive,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppTheme.borderRadiusMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.space16),
                    ],
                  ),
                ),
              ].animate(interval: 60.ms).fadeIn(
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ).slideY(
                    begin: 0.08,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── TIMELINE SECTION ──────────────────────────────────────────────────

class _TimelineSection extends StatelessWidget {
  final List timeline;
  final List<String> timelineSummary;
  const _TimelineSection({required this.timeline, required this.timelineSummary});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) return const SizedBox.shrink();

    final emotions = timeline
        .map((e) => (e as Map<String, dynamic>)['emotion']?.toString() ?? 'unknown')
        .toList();

    // Generate one-sentence summary
    String summary = 'Your dog showed a variety of emotions.';
    if (emotions.isNotEmpty) {
      final first = emotions.first;
      final last = emotions.last;
      if (first == last) {
        summary = 'Your dog remained mostly ${first.toLowerCase()} throughout.';
      } else {
        summary = 'Your dog transitioned from ${first.toLowerCase()} to ${last.toLowerCase()}.';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood Timeline',
          style: AppTheme.titleStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(summary, style: AppTheme.captionStyle),
        const SizedBox(height: AppTheme.space12),

        // Timeline bar
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceActive,
            borderRadius: AppTheme.borderRadiusMedium,
            boxShadow: AppTheme.softShadow,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < emotions.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 16,
                      height: 2,
                      color: AppTheme.surfaceElevated,
                    ),
                  _TimelineDot(emotion: emotions[i]),
                ],
              ],
            ),
          ),
        ),

        // Timeline summary bullets
        if (timelineSummary.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space12),
          ...timelineSummary.map((point) {
            final style = EmotionStyle.fromEmotion(
              point.toLowerCase().contains('happy') ? 'happy'
              : point.toLowerCase().contains('sad') ? 'sad'
              : point.toLowerCase().contains('angry') ? 'angry'
              : point.toLowerCase().contains('relax') ? 'relaxed'
              : 'neutral',
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(style.icon, color: style.color, size: 18),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      point.trim(),
                      style: AppTheme.bodyStyle.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final String emotion;
  const _TimelineDot({required this.emotion});

  @override
  Widget build(BuildContext context) {
    final style = EmotionStyle.fromEmotion(emotion);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: style.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(style.emoji, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          style.label,
          style: AppTheme.captionStyle.copyWith(
            fontSize: 10,
            color: style.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class _ExpandableInsights extends StatefulWidget {
  final List<String> suggestions;
  final EmotionStyle emotionStyle;

  const _ExpandableInsights({required this.suggestions, required this.emotionStyle});

  @override
  State<_ExpandableInsights> createState() => _ExpandableInsightsState();
}

class _ExpandableInsightsState extends State<_ExpandableInsights> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceActive,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.softShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
            if (expanded) {
              HapticFeedback.lightImpact();
            }
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.emotionStyle.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(Icons.lightbulb_outline_rounded, size: 20, color: widget.emotionStyle.color),
              ),
              const SizedBox(width: AppTheme.space12),
              Text(
                'Helpful Insights',
                style: AppTheme.titleStyle.copyWith(fontSize: 16),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.only(left: AppTheme.space16, right: AppTheme.space16, bottom: AppTheme.space16),
          children: widget.suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.check_circle_outline, size: 16, color: widget.emotionStyle.color),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: AppTheme.bodyStyle.copyWith(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}
