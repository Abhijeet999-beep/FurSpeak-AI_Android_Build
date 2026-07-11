import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:furspeak_ai/services/guest_guard_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/media/services/media_orchestrator.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/presentation/widgets/radial_glow.dart';
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
  final GlobalKey _shareCardKey = GlobalKey();
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
    
    if (GuestGuardService.shouldShowConversionPrompt(auth)) {
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

  Future<void> _handleShare() async {
    FurHaptics.heavy();
    
    final r = _detectionResult;
    if (r == null) return;

    try {
      debugPrint('[SHARE] Initiating off-screen render capture...');
      
      // Get boundary
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('[SHARE] Error: RepaintBoundary render object not found.');
        _fallbackTextShare(r);
        return;
      }

      // Capture image at 1.0 pixel ratio to get exactly 1080x1350 PNG
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('[SHARE] Error: toByteData returned null.');
        _fallbackTextShare(r);
        return;
      }
      
      final buffer = byteData.buffer.asUint8List();
      
      // Save file temporarily
      final tempDir = await getTemporaryDirectory();
      final sharePath = '${tempDir.path}/furspeak_result_${r.uuid}.png';
      final file = File(sharePath);
      await file.writeAsBytes(buffer, flush: true);
      
      debugPrint('[SHARE] PNG saved to temporary path: $sharePath. Sharing...');

      final emoji = EmotionStyle.fromEmotion(r.emotion).emoji;
      final caption = r.caption.isNotEmpty 
          ? r.caption 
          : 'My dog feels ${r.emotion}!';

      String shareText = '🐾 FurSpeak AI — Dog Emotion Insight\n\n';
      shareText += 'My dog feels ${r.emotion} $emoji\n';
      shareText += 'Analysis: $caption\n\n';
      shareText += 'Understand your pet better with FurSpeak AI! ✨';

      await Share.shareXFiles(
        [XFile(sharePath)],
        text: shareText,
        subject: 'My Dog\'s Emotion Analysis',
      );
    } catch (e, stack) {
      debugPrint('❌ [SHARE] Error capturing/sharing card: $e\n$stack');
      _fallbackTextShare(r);
    }
  }

  void _fallbackTextShare(DetectionResult r) {
    final emoji = EmotionStyle.fromEmotion(r.emotion).emoji;
    final caption = r.caption.isNotEmpty 
        ? r.caption 
        : 'My dog feels ${r.emotion}!';

    String shareText = '🐾 FurSpeak AI — Dog Emotion Insight\n\n';
    shareText += 'My dog feels ${r.emotion} $emoji\n';
    shareText += 'Analysis: $caption\n\n';
    shareText += 'Understand your pet better with FurSpeak AI! ✨';

    Share.share(shareText, subject: 'My Dog\'s Emotion Analysis');
  }

  // ─── MEDIA PREVIEW ──────────────────────────────────────────────────
  Widget _mediaPreview() {
    final r = _detectionResult;
    if (r == null) return _failedPreviewWidget();

    final bool isVideo = r.isVideo;
    final String localPath = r.mediaPath;
    final String? networkUrl = r.frameImageUrl;

    // --- VIDEO PREVIEW ---
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

    // --- LOCAL IMAGE PREVIEW ---
    if (!isVideo && localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If local file fails to load, try network fallback immediately
            if (networkUrl != null && networkUrl.isNotEmpty) {
              return _networkPreview(networkUrl);
            }
            return _failedPreviewWidget();
          },
        );
      }
    }

    // --- NETWORK IMAGE FALLBACK ---
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return _networkPreview(networkUrl);
    }

    // --- STATUS-BASED FALLBACK (No Dog / Unknown) ---
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

  Widget _networkPreview(String url) {
    return CachedNetworkImage(
      imageUrl: url,
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
            // Offscreen Share Card for generating clean PNG
            Positioned(
              left: -9999,
              top: 0,
              child: RepaintBoundary(
                key: _shareCardKey,
                child: _ShareCard(
                  result: r,
                  emotionStyle: emotionStyle,
                ),
              ),
            ),
            // Background Pattern for immersion
            Positioned.fill(
              child: RepaintBoundary(
                child: Opacity(
                  opacity: 0.05, // Consistent with Home Screen
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
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: AppTheme.softShadow,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppTheme.radiusExtraLarge),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppTheme.radiusExtraLarge),
                        ),
                        child: _mediaPreview(),
                      ),
                    ),
                    // Back button
                    Positioned(
                      top: AppTheme.space16,
                      left: AppTheme.space16,
                      child: SquishButton(
                        onPressed: () => context.goHome(),
                        child: PetMoodGlass(
                          borderRadius: const BorderRadius.all(Radius.circular(50)),
                          opacity: 0.35,
                          color: Colors.black,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.space10),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),
                    // Emotion badge overlay
                    Positioned(
                      bottom: AppTheme.space16,
                      right: AppTheme.space16,
                      child: PetMoodGlass(
                        opacity: 0.95,
                        color: emotionStyle.color.withValues(alpha: 0.2),
                        borderRadius: AppTheme.borderRadiusPill,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space20,
                            vertical: AppTheme.space10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emotionStyle.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: AppTheme.space10),
                              Text(
                                emotionStyle.label.toUpperCase(),
                                style: AppTheme.titleStyle.copyWith(
                                  color: AppTheme.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: StaggeredEntrance(
                    children: [
                      // ═══ 2. EMOTION HEADLINE ═══
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.space16),
                              decoration: BoxDecoration(
                                color: emotionStyle.color.withValues(alpha: 0.12),
                                borderRadius: AppTheme.borderRadiusLarge,
                                boxShadow: [
                                  BoxShadow(
                                    color: emotionStyle.color.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: RadialGlow(
                                color: emotionStyle.color,
                                size: 50,
                                child: Icon(emotionStyle.icon, color: emotionStyle.color, size: 36),
                              ),
                            ).animate().shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(width: AppTheme.space20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your dog feels',
                                    style: AppTheme.captionStyle.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textLightColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        emotionStyle.color,
                                        emotionStyle.color.withValues(alpha: 0.6),
                                      ],
                                    ).createShader(bounds),
                                    child: Text(
                                      '${emotionStyle.label} ${emotionStyle.emoji}',
                                      style: AppTheme.headingStyle.copyWith(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.space24),

                      // ═══ 3. CONFIDENCE BAR ═══
                      PetMoodGlass(
                        borderRadius: AppTheme.borderRadiusExtraLarge,
                        opacity: 0.5,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.space24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.query_stats_rounded, size: 18, color: AppTheme.textColor.withValues(alpha: 0.6)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Confidence Score',
                                        style: AppTheme.titleStyle.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textColor.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (confidence >= 80 ? AppTheme.successColor : emotionStyle.color).withValues(alpha: 0.15),
                                      borderRadius: AppTheme.borderRadiusPill,
                                    ),
                                    child: Text(
                                      '${confidence.toInt()}% $confidenceLabel',
                                      style: AppTheme.titleStyle.copyWith(
                                        color: confidence >= 80 ? AppTheme.successColor : emotionStyle.color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space20),
                              Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: emotionStyle.color.withValues(alpha: 0.08),
                                      borderRadius: AppTheme.borderRadiusPill,
                                    ),
                                  ),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: confidence / 100),
                                    duration: const Duration(milliseconds: 1800),
                                    curve: Curves.easeOutQuart,
                                    builder: (context, value, child) {
                                      return GlowPulse(
                                        color: emotionStyle.color.withValues(alpha: 0.3),
                                        duration: const Duration(seconds: 3),
                                        child: FractionallySizedBox(
                                          widthFactor: value,
                                          child: Shimmer.fromColors(
                                            baseColor: emotionStyle.color,
                                            highlightColor: Colors.white.withValues(alpha: 0.6),
                                            period: const Duration(seconds: 3),
                                            child: Container(
                                              height: 12,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    emotionStyle.color,
                                                    emotionStyle.color.withValues(alpha: 0.8),
                                                  ],
                                                ),
                                                borderRadius: AppTheme.borderRadiusPill,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: emotionStyle.color.withValues(alpha: 0.4),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                        opacity: 0.7,
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
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: emotionStyle.color.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.auto_awesome_rounded,
                                            size: 18, color: emotionStyle.color),
                                      ),
                                      const SizedBox(width: AppTheme.space12),
                                      Text(
                                        'Emotional Insight',
                                        style: AppTheme.titleStyle.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: emotionStyle.color,
                                          letterSpacing: 0.3,
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
                                      FurHaptics.tap();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: AppTheme.borderRadiusSmall,
                                      ),
                                      child: Icon(Icons.copy_rounded, size: 18, color: emotionStyle.color.withValues(alpha: 0.6)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space20),
                              Text(
                                isError
                                    ? 'No emotion detected. Please ensure your dog\'s face is visible and try again.'
                                    : caption,
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 17,
                                  height: 1.7,
                                  fontWeight: FontWeight.w400,
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

                      const SizedBox(height: AppTheme.space24),

                      // ═══ 7. BOTTOM ACTION BAR ═══
                      Row(
                        children: [
                          Expanded(
                            child: SquishButton(
                              onPressed: _handleAnalyzeAnother,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh,
                                  borderRadius: AppTheme.borderRadiusPill,
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh_rounded, color: AppTheme.primaryColor, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Scan Again',
                                      style: AppTheme.titleStyle.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: SquishButton(
                              onPressed: _handleShare,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: AppTheme.borderRadiusPill,
                                  boxShadow: AppTheme.floatShadow,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Share Result',
                                      style: AppTheme.titleStyle.copyWith(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                               .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.1)),
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
        Row(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 20, color: AppTheme.textColor.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(
              'Mood Timeline',
              style: AppTheme.titleStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          summary, 
          style: AppTheme.captionStyle.copyWith(
            fontSize: 13,
            color: AppTheme.textColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppTheme.space16),

        // Timeline bar
        PetMoodGlass(
          opacity: 0.4,
          borderRadius: AppTheme.borderRadiusExtraLarge,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (int i = 0; i < emotions.length; i++) ...[
                    if (i > 0)
                      Container(
                        width: 20,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              EmotionStyle.fromEmotion(emotions[i-1]).color.withValues(alpha: 0.3),
                              EmotionStyle.fromEmotion(emotions[i]).color.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    _TimelineDot(emotion: emotions[i]).animate()
                      .fadeIn(delay: (i * 100).ms)
                      .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack, delay: (i * 100).ms),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Timeline summary bullets
        if (timelineSummary.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space12),
          ...timelineSummary.asMap().entries.map((entry) {
            final int i = entry.key;
            final String point = entry.value;
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
            ).animate().fadeIn(delay: (400 + i * 100).ms).slideX(begin: 0.1, end: 0);
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
        GlowPulse(
          color: style.color.withValues(alpha: 0.1),
          duration: const Duration(seconds: 4),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: style.color.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: style.color.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 1,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            child: Center(
              child: Text(style.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          style.label,
          style: AppTheme.captionStyle.copyWith(
            fontSize: 10,
            color: style.color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
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
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: widget.emotionStyle.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: Icon(Icons.expand_more_rounded, color: widget.emotionStyle.color, size: 24),
                      ),
                    ),
                  ],
                ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space24, 0, AppTheme.space24, AppTheme.space24),
              child: StaggeredEntrance(
                staggerDelay: const Duration(milliseconds: 60),
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
                          color: widget.emotionStyle.color.withValues(alpha: 0.5),
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
                            color: AppTheme.textColor.withValues(alpha: 0.85),
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

    return PetMoodGlass(
      opacity: 0.98,
      color: AppTheme.bgColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusExtraLarge)),
      child: Container(
        padding: EdgeInsets.only(
          top: AppTheme.space24,
          left: AppTheme.space24,
          right: AppTheme.space24,
          bottom: MediaQuery.of(context).padding.bottom + AppTheme.space32,
        ),
        child: StaggeredEntrance(
          staggerDelay: const Duration(milliseconds: 100),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.textLightColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space32),
            
            // Emotional Icon
            Center(
              child: GlowPulse(
                color: AppTheme.accentColor.withValues(alpha: 0.2),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 48,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            Text(
              "Save your dog's journey",
              textAlign: TextAlign.center,
              style: AppTheme.headingStyle.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              "Create a free account to keep scan history, unlock deeper insights, and track your dog's moods over time.",
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 16,
                height: 1.5,
                color: AppTheme.textColor.withValues(alpha: 0.7),
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
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: AppTheme.borderRadiusPill,
                  boxShadow: AppTheme.floatShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: AppTheme.space12),
                    Text(
                      'Continue with Google',
                      style: AppTheme.titleStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space16),

            // Secondary CTA: Maybe Later
            Center(
              child: TextButton(
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
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textLightColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final DetectionResult result;
  final EmotionStyle emotionStyle;

  const _ShareCard({
    required this.result,
    required this.emotionStyle,
  });

  String _formatTimestamp(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final year = dt.year;
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final bool isError = (result.emotion.toLowerCase() == 'unknown' || result.confidence == 0.0);
    final String caption = result.caption.isNotEmpty 
        ? result.caption 
        : 'My dog feels ${result.emotion}!';
    
    // Limit to 1 suggestion for video (due to timeline space) and 2 for images
    final displaySuggestions = result.suggestions.take(result.isVideo ? 1 : 2).toList();
    
    // Parse timeline
    final emotionsList = result.timeline
        .map((e) => (e as Map<String, dynamic>)['emotion']?.toString() ?? 'unknown')
        .toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 1080,
        height: 1350,
        padding: const EdgeInsets.all(72.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48.0),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF161B2E),
              Color(0xFF0C0E1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pets_rounded,
                      size: 48,
                      color: emotionStyle.color,
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      'FurSpeak AI',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                  ),
                  child: Text(
                    'EMOTION REPORT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 56),

            // ─── MAIN RESULT DISPLAY ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 2.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: emotionStyle.color.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: emotionStyle.color.withOpacity(0.2),
                        width: 3.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emotionStyle.emoji,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your dog feels',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.4),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emotionStyle.label,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: emotionStyle.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${result.confidence.toInt()}% Match',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: emotionStyle.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // ─── CAPTION INSIGHT ───
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 28, color: emotionStyle.color),
                const SizedBox(width: 16),
                const Text(
                  'Emotional Insight',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              isError
                  ? 'No emotion detected. Please ensure your dog\'s face is visible and try again.'
                  : caption,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 26,
                height: 1.6,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.85),
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 48),

            // ─── TIMELINE (IF VIDEO) ───
            if (result.isVideo && emotionsList.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 28, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 16),
                  const Text(
                    'Mood Timeline',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < math.min(emotionsList.length, 6); i++) ...[
                    if (i > 0)
                      Container(
                        width: 48,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              EmotionStyle.fromEmotion(emotionsList[i - 1]).color.withOpacity(0.3),
                              EmotionStyle.fromEmotion(emotionsList[i]).color.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: EmotionStyle.fromEmotion(emotionsList[i]).color.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: EmotionStyle.fromEmotion(emotionsList[i]).color.withOpacity(0.2),
                              width: 2.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              EmotionStyle.fromEmotion(emotionsList[i]).emoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          EmotionStyle.fromEmotion(emotionsList[i]).label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: EmotionStyle.fromEmotion(emotionsList[i]).color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 48),
            ],

            // ─── SUGGESTIONS ───
            if (displaySuggestions.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 28, color: emotionStyle.color),
                  const SizedBox(width: 16),
                  const Text(
                    'Response Suggestion',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...displaySuggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: emotionStyle.color.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            s.trim(),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              height: 1.4,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],

            const Spacer(),

            // ─── FOOTER ───
            Container(
              padding: const EdgeInsets.only(top: 32),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTimestamp(result.timestamp),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppTheme.successColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analyzed with FurSpeak AI',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
