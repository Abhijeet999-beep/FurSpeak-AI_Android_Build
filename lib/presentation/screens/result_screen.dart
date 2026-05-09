import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:furspeak_ai/data/models/detection_result.dart';
import 'package:furspeak_ai/services/result_storage_service.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/media/services/media_orchestrator.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:provider/provider.dart';

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

    debugPrint('[RESULT_SCREEN] Loading result for ID: ${widget.resultId}');
    debugPrint('[RESULT_SCREEN] Full Result: ${result.toJson()}');
    debugPrint('[RESULT_SCREEN] Emotion: ${result.emotion}');
    debugPrint('[RESULT_SCREEN] Confidence: ${result.confidence}');
    debugPrint('[RESULT_SCREEN] Caption: ${result.caption}');
    debugPrint('[RESULT_SCREEN] MediaPath: ${result.mediaPath}');

    _speakResult();
    _initVideoIfNeeded();
    _checkGuestConversion();
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

  void _checkGuestConversion() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // Show after 2nd successful scan (count is incremented before reaching this screen)
    if (auth.isGuest && !auth.guestConversionDismissed && auth.guestScanCount >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            _showGuestConversionBottomSheet();
          }
        });
      });
    }
  }

  void _showGuestConversionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GuestConversionBottomSheet(),
    );
  }

  void _handleAnalyzeAnother() {
    HapticFeedback.mediumImpact();
    context.goHome();
  }

  void _handleShare() {
    HapticFeedback.heavyImpact();
    
    final r = _detectionResult;
    if (r == null) return;

    final emoji = EmotionStyle.fromEmotion(r.emotion).emoji;
    final caption = r.caption.isNotEmpty 
        ? r.caption 
        : 'My dog feels ${r.emotion}!';

    String shareText = '🐾 FurSpeak AI — Dog Emotion Insight\n\n';
    shareText += 'My dog feels ${r.emotion} $emoji\n';
    shareText += 'Analysis: $caption\n\n';
    shareText += 'Understand your pet better with FurSpeak AI! ✨';

    final mediaPath = r.mediaPath;
    if (mediaPath.isNotEmpty && File(mediaPath).existsSync()) {
      Share.shareXFiles([XFile(mediaPath)], text: shareText, subject: 'My Dog\'s Emotion Analysis');
    } else {
      Share.share(shareText, subject: 'My Dog\'s Emotion Analysis');
    }
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
            color: AppTheme.surfaceContainerLow,
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
          child: RepaintBoundary(
            child: Lottie.asset(
              LottieRegistry.get('failed'),
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error_outline_rounded, size: 80, color: AppTheme.primaryColor),
            ),
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
        color: AppTheme.surfaceContainerLow,
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
        body: Stack(
          children: [
            // Background Pattern for immersion
            Positioned.fill(
              child: RepaintBoundary(
                child: Opacity(
                  opacity: 0.04,
                  child: Lottie.asset(
                    LottieRegistry.get('paw_prints_bg'),
                    fit: BoxFit.cover,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ═══ 1. MEDIA PREVIEW WITH OVERLAY ═══
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppTheme.radiusExtraLarge),
                      ),
                      child: _mediaPreview(),
                    ),
                    // Back button
                    Positioned(
                      top: AppTheme.space16,
                      left: AppTheme.space16,
                      child: SquishButton(
                        onPressed: () => context.goHome(),
                        child: PetMoodGlass(
                          borderRadius: const BorderRadius.all(Radius.circular(50)),
                          opacity: 0.25,
                          color: Colors.black,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.space12),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                    // Emotion badge overlay
                    Positioned(
                      bottom: AppTheme.space16,
                      right: AppTheme.space16,
                      child: PetMoodGlass(
                        opacity: 0.9,
                        color: emotionStyle.color.withValues(alpha: 0.1),
                        borderRadius: AppTheme.borderRadiusPill,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space16,
                            vertical: AppTheme.space8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emotionStyle.emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: AppTheme.space8),
                              Text(
                                emotionStyle.label,
                                style: AppTheme.titleStyle.copyWith(
                                  color: AppTheme.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: StaggeredEntrance(
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
                      PetMoodGlass(
                        borderRadius: AppTheme.borderRadiusExtraLarge,
                        opacity: 0.4,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.space24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Confidence Score',
                                    style: AppTheme.titleStyle.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: emotionStyle.color.withValues(alpha: 0.12),
                                      borderRadius: AppTheme.borderRadiusPill,
                                    ),
                                    child: Text(
                                      '${confidence.toInt()}% $confidenceLabel',
                                      style: AppTheme.titleStyle.copyWith(
                                        color: emotionStyle.color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space16),
                              Stack(
                                children: [
                                  Container(
                                    height: 10,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: emotionStyle.color.withValues(alpha: 0.08),
                                      borderRadius: AppTheme.borderRadiusPill,
                                    ),
                                  ),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: confidence / 100),
                                    duration: const Duration(milliseconds: 1500),
                                    curve: Curves.easeOutQuart,
                                    builder: (context, value, child) {
                                      return FractionallySizedBox(
                                        widthFactor: value,
                                        child: Container(
                                          height: 10,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                emotionStyle.color,
                                                emotionStyle.color.withOpacity(0.7),
                                              ],
                                            ),
                                            borderRadius: AppTheme.borderRadiusPill,
                                            boxShadow: [
                                              BoxShadow(
                                                color: emotionStyle.color.withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.space16),

                      // ═══ 4. CAPTION CARD ═══
                      PetMoodGlass(
                        color: emotionStyle.actionCardColor,
                        opacity: 0.6,
                        borderRadius: AppTheme.borderRadiusExtraLarge,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.space24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: emotionStyle.color.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.auto_awesome_rounded,
                                            size: 16, color: emotionStyle.color),
                                      ),
                                      const SizedBox(width: AppTheme.space12),
                                      Text(
                                        'Emotional Insight',
                                        style: AppTheme.titleStyle.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: emotionStyle.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SquishButton(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: isError ? 'No emotion detected' : caption));
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Caption copied!'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: emotionStyle.color,
                                          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
                                        ),
                                      );
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Icon(Icons.copy_rounded, size: 20, color: emotionStyle.color.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space16),
                              Text(
                                isError
                                    ? 'No emotion detected. Please ensure your dog\'s face is visible and try again.'
                                    : caption,
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 16,
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textColor.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
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
                      const SizedBox(height: AppTheme.space24),

                      // ═══ 7. BOTTOM ACTION BAR ═══
                      Row(
                        children: [
                          Expanded(
                            child: SquishButton(
                              onPressed: _handleAnalyzeAnother,
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh,
                                  borderRadius: AppTheme.borderRadiusPill,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh_rounded, color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Scan Again',
                                      style: AppTheme.titleStyle.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: SquishButton(
                              onPressed: _handleShare,
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: AppTheme.borderRadiusPill,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Share Result',
                                      style: AppTheme.titleStyle.copyWith(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
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
              ],
            ),
          ),
        ),
      ],
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
        PetMoodGlass(
          opacity: 0.3,
          borderRadius: AppTheme.borderRadiusMedium,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < emotions.length; i++) ...[
                    if (i > 0)
                      Container(
                        width: 12,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    _TimelineDot(emotion: emotions[i]),
                  ],
                ],
              ),
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
    return PetMoodGlass(
      opacity: 0.5,
      borderRadius: AppTheme.borderRadiusExtraLarge,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              HapticFeedback.lightImpact();
            },
            borderRadius: AppTheme.borderRadiusExtraLarge,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.emotionStyle.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lightbulb_outline_rounded, size: 24, color: widget.emotionStyle.color),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Text(
                      'How to respond',
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 17, 
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutBack,
                    child: Icon(Icons.expand_more_rounded, color: widget.emotionStyle.color.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space24, 0, AppTheme.space24, AppTheme.space24),
              child: Column(
                children: widget.suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.emotionStyle.color.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 15, 
                            height: 1.6,
                            color: AppTheme.textColor.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 400),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }
}

class _GuestConversionBottomSheet extends StatelessWidget {
  const _GuestConversionBottomSheet();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusExtraLarge)),
      ),
      padding: EdgeInsets.only(
        top: AppTheme.space32,
        left: AppTheme.space24,
        right: AppTheme.space24,
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.space32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textLightColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppTheme.space32),
          
          // Emotional Icon
          Container(
            padding: const EdgeInsets.all(AppTheme.space24),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          Text(
            "Save your dog's emotional journey 🐾",
            textAlign: TextAlign.center,
            style: AppTheme.headingStyle.copyWith(
              fontSize: 24,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            "Create a free account to keep scan history, emotional insights, and personalized tracking for your companion.",
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 16,
              height: 1.5,
              color: AppTheme.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppTheme.space32),

          // Primary CTA: Continue with Google
          SquishButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.signInWithGoogle();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: AppTheme.borderRadiusPill,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppTheme.space12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space16),

          // Secondary CTA: Maybe Later
          TextButton(
            onPressed: () {
              auth.dismissGuestConversion();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              foregroundColor: AppTheme.textLightColor,
            ),
            child: Text(
              'Maybe Later',
              style: AppTheme.titleStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLightColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
