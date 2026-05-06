import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lottie/lottie.dart';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:furspeak_ai/presentation/screens/video_trimmer_screen.dart';
import 'package:furspeak_ai/presentation/screens/camera_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/theme/app_animations.dart';

import 'package:furspeak_ai/utils/error_mapper.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';

import 'package:furspeak_ai/providers/home_pipeline_provider.dart';
import 'package:furspeak_ai/media/services/media_validator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isRetrying = false;
  bool _isPickerOpen = false;

  Future<void> _startPipeline(String filePath, bool isVideo) async {
    final authProvider = context.read<AuthProvider>();
    final pipeline = context.read<HomePipelineProvider>();

    await pipeline.processNewMedia(filePath, isVideo, authProvider);

    if (!mounted) return;
    final resultId = pipeline.consumeSuccess();
    if (resultId == null) return;

    context.pushResult(resultId);
    if (mounted) pipeline.resetPipeline();
  }

  Widget _buildMediaPickerSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.space8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: AppTheme.borderRadiusPill,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text('Choose how to scan 🐶', style: AppTheme.titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.space16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: InkWell(
                onTap: () => Navigator.pop(context, 'camera'),
                borderRadius: AppTheme.borderRadiusMedium,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    borderRadius: AppTheme.borderRadiusMedium,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('📷', style: TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Take Photo', style: AppTheme.titleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text('Use your camera', style: AppTheme.captionStyle.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: InkWell(
                onTap: () => Navigator.pop(context, 'gallery'),
                borderRadius: AppTheme.borderRadiusMedium,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    borderRadius: AppTheme.borderRadiusMedium,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Choose from Gallery', style: AppTheme.titleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text('Pick from your photos', style: AppTheme.captionStyle.copyWith(fontSize: 13)),
                          ],
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
    );
  }

  Future<void> _showMediaPicker() async {
    if (_isPickerOpen) return;
    setState(() => _isPickerOpen = true);

    try {
      final pipeline = context.read<HomePipelineProvider>();
      if (pipeline.isProcessing) return;

      HapticFeedback.mediumImpact();

      // PERMISSION CHECK
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          if (mounted) {
            _showFriendlySnackBar('We need access to see your dog 🐶', Icons.no_photography_rounded);
          }
          return;
        }
      }

      // OPEN BOTTOM SHEET ONCE
      if (!mounted) return;
      final choice = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surfaceActive,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _buildMediaPickerSheet(),
      );

      if (choice == null) return;

      if (choice == 'camera') {
        if (!mounted) return;
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );

        if (result != null && mounted) {
          final isVideo = result.toLowerCase().endsWith('.mp4') ||
              result.toLowerCase().endsWith('.mov') ||
              result.toLowerCase().endsWith('.avi');

          _showFriendlySnackBar(
            isVideo ? '🎥 Video captured!' : '📷 Image captured!',
            isVideo ? Icons.videocam : Icons.camera_alt,
          );

          await _startPipeline(result, isVideo);
        }
        return;
      }

      if (choice == 'gallery') {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) return;

        if (!mounted) return;
        _showFriendlySnackBar('📷 Image selected!', Icons.camera_alt);
        await _startPipeline(picked.path, false);
      }
    } catch (e) {
      debugPrint('MediaPicker Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickerOpen = false);
      }
    }
  }

  void _handleRetry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final pipeline = context.read<HomePipelineProvider>();

      final isStorageError = pipeline.error?.userMessage ==
          'Failed to save result. Please try again.';

      if (isStorageError) {
        await pipeline.retryStorage();
      } else {
        await pipeline.retryPipeline(authProvider);
      }

      if (!mounted) return;
      final resultId = pipeline.consumeSuccess();
      if (resultId == null) return;

      context.pushResult(resultId);
      if (mounted) pipeline.resetPipeline();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  void _showFriendlySnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                message,
                style: AppTheme.captionStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.textColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(AppTheme.space16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Isolate rebuilds to just the isProcessing boundary
    final isProcessing =
        context.select((HomePipelineProvider p) => p.isProcessing);
    final isGuest = context.select((AuthProvider p) => p.isGuest);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: isProcessing,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.space24),
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.space24),
                    // Header
                    Text(
                      'How is your dog feeling today? 🐾',
                      textAlign: TextAlign.center,
                      style: AppTheme.headingStyle.copyWith(
                        color: AppTheme.primaryColor,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Let\'s find out together',
                      textAlign: TextAlign.center,
                      style: AppTheme.captionStyle.copyWith(
                        fontSize: 15,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                    if (isGuest) ...[
                      const SizedBox(height: AppTheme.space12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space12,
                            vertical: AppTheme.space8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: AppTheme.borderRadiusPill,
                          border: Border.all(
                              color: AppTheme.accentColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pets,
                                size: 14, color: AppTheme.accentColor),
                            const SizedBox(width: AppTheme.space8),
                            Flexible(
                              child: Text(
                                "Scanning as guest — sign in to save your dog's insights",
                                style: AppTheme.captionStyle.copyWith(
                                  color: AppTheme.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.space24),

                    // Animated Dog Card
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceActive,
                        borderRadius: AppTheme.borderRadiusLarge,
                        boxShadow: AppTheme.floatShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Lottie.asset(
                          LottieRegistry.get('dog_happy'),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.pets_rounded,
                                  size: 64, color: AppTheme.primaryColor),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ═══ PRIMARY CTA: Scan Emotion ═══
                    Opacity(
                      opacity: _isPickerOpen ? 0.6 : 1.0,
                      child: IgnorePointer(
                        ignoring: _isPickerOpen,
                        child: BoundedPulse(
                          child: SquishButton(
                            onPressed: isProcessing || _isPickerOpen
                                ? null
                                : _showMediaPicker,
                            pressScale: 0.95,
                            child: Container(
                              width: double.infinity,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: AppTheme.borderRadiusLarge,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: AppTheme.borderRadiusMedium,
                                    ),
                                    child: const Icon(
                                        Icons.document_scanner_rounded,
                                        size: 24,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: AppTheme.space12),
                                  Text(
                                    'Scan Emotion',
                                    style: AppTheme.titleStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.space16),

                    // View Results CTA (only when result ready)
                    Selector<HomePipelineProvider, bool>(
                      selector: (_, p) => p.state == HomeState.success,
                      builder: (context, isResult, _) {
                        if (!isResult) return const SizedBox.shrink();

                        return BoundedPulse(
                          maxPulses: 3,
                          child: SquishButton(
                            onPressed: () {
                              final pipeline =
                                  context.read<HomePipelineProvider>();
                              final resultId = pipeline.consumeSuccess();
                              if (resultId != null) {
                                context.pushResult(resultId);
                                pipeline.resetPipeline();
                              } else {
                                if (pipeline.lastResultId != null)
                                  context.pushResult(pipeline.lastResultId!);
                                pipeline.resetPipeline();
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
                                borderRadius: AppTheme.borderRadiusLarge,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.successColor.withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded,
                                      size: 22, color: Colors.white),
                                  const SizedBox(width: AppTheme.space8),
                                  Text(
                                    'View Results ✨',
                                    style: AppTheme.titleStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          // ===== ERROR STATE CARD =====
          Selector<HomePipelineProvider, AppError?>(
            selector: (_, p) => p.state == HomeState.error ? p.error : null,
            builder: (context, error, _) {
              if (error == null) return const SizedBox.shrink();

              return Positioned(
                left: 0,
                right: 0,
                bottom: 56,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Material(
                    elevation: 0,
                    borderRadius: AppTheme.borderRadiusLarge,
                    color: AppTheme.surfaceActive,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: AppTheme.borderRadiusLarge,
                        color: AppTheme.surfaceActive,
                        boxShadow: AppTheme.floatShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Emoji hero
                          Text(
                            error.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: AppTheme.space12),
                          // Main message
                          Text(
                            error.userMessage,
                            textAlign: TextAlign.center,
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Hint / guidance
                          if (error.hint != null) ...[
                            const SizedBox(height: AppTheme.space8),
                            Text(
                              error.hint!,
                              textAlign: TextAlign.center,
                              style: AppTheme.captionStyle.copyWith(
                                fontSize: 13,
                                color: AppTheme.textLightColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppTheme.space16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () => context
                                    .read<HomePipelineProvider>()
                                    .reset(),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.textLightColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                ),
                                child: const Text('Dismiss'),
                              ),
                              if (error.canRetry) ...[
                                const SizedBox(width: AppTheme.space12),
                                SquishButton(
                                  onPressed: _handleRetry,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.space24,
                                        vertical: AppTheme.space12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: AppTheme.borderRadiusMedium,
                                      boxShadow: AppTheme.softShadow,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.refresh_rounded,
                                            size: 18, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Try Again',
                                          style: AppTheme.titleStyle.copyWith(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // ===== RESULT STATE CARD =====
          Selector<HomePipelineProvider, bool>(
            selector: (_, p) =>
                p.state == HomeState.success && p.result != null,
            builder: (context, hasResult, _) {
              if (!hasResult) return const SizedBox.shrink();
              return Positioned(
                left: 0,
                right: 0,
                bottom: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space24, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: AppTheme.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceActive,
                      borderRadius: AppTheme.borderRadiusLarge,
                      boxShadow: AppTheme.floatShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: AppTheme.borderRadiusMedium,
                          ),
                          child: Icon(Icons.check_circle_rounded,
                              color: AppTheme.successColor, size: 28),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Analysis complete! ✨',
                                style: AppTheme.titleStyle.copyWith(
                                  fontSize: 16,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "View Results" to see details',
                                style: AppTheme.captionStyle
                                    .copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ===== PROCESSING OVERLAY (Stage-Based) =====
          if (isProcessing)
            Consumer<HomePipelineProvider>(
              builder: (context, pipeline, _) {
                return Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RepaintBoundary(
                          child: Builder(
                            builder: (context) {
                              try {
                                return Lottie.asset(
                                  'assets/animations/loading.json',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.contain,
                                );
                              } catch (_) {
                                return const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.space24),
                        PetMoodGlass(
                          opacity: 0.92,
                          borderRadius: AppTheme.borderRadiusLarge,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space24,
                                vertical: AppTheme.space16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Stage indicator
                                _PipelineStageIndicator(state: pipeline.state),
                                const SizedBox(height: AppTheme.space12),
                                ProcessingMessageRotator(
                                  isActive: true,
                                  textStyle: AppTheme.titleStyle.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                if (pipeline.statusMessage.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    pipeline.statusMessage,
                                    style: AppTheme.captionStyle.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.textLightColor,
                                    ),
                                  ),
                                ],
                                if (isGuest) ...[
                                  const SizedBox(height: AppTheme.space12),
                                  Text(
                                    "Sign in after to save results",
                                    style: AppTheme.captionStyle.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            pipeline.cancelProcessing();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.surfaceActive,
                            backgroundColor:
                                AppTheme.surfaceActive.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space24,
                                vertical: AppTheme.space12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.borderRadiusPill,
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: Text('Cancel',
                              style: AppTheme.titleStyle.copyWith(
                                  color: AppTheme.surfaceActive, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PipelineStageIndicator extends StatelessWidget {
  final HomeState state;
  const _PipelineStageIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('Preparing', HomeState.compressing),
      ('Uploading', HomeState.uploading),
      ('Analyzing', HomeState.processing),
    ];

    int activeIndex = stages.indexWhere((s) => s.$2 == state);
    if (activeIndex < 0) activeIndex = 0;

    final currentStep = activeIndex + 1;
    final totalSteps = stages.length;
    final progress = currentStep / totalSteps;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stages[activeIndex].$1,
              style: AppTheme.titleStyle.copyWith(
                fontSize: 13,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              'Step $currentStep of $totalSteps',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        ClipRRect(
          borderRadius: AppTheme.borderRadiusPill,
          child: AnimatedContainer(
            duration: AppTheme.animMedium,
            height: 6,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceElevated,
            ),
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: AppTheme.borderRadiusPill,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
