import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/presentation/widgets/permission_interstitial.dart';
import 'package:furspeak_ai/presentation/screens/camera_screen.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/providers/home_pipeline_provider.dart';
import 'package:furspeak_ai/presentation/screens/video_trimmer_screen.dart';
import 'package:furspeak_ai/utils/error_mapper.dart';
import 'package:furspeak_ai/utils/media_utils.dart';
import 'package:furspeak_ai/presentation/widgets/radial_glow.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isRetrying = false;
  bool _isPickerOpen = false;
  late String _randomDogKey;

  @override
  void initState() {
    super.initState();
    _randomDogKey = LottieRegistry.getRandomDog();
  }

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusExtraLarge)),
      ),
      child: PetMoodGlass(
        opacity: 0.05, // Much subtler for a large sheet
        color: AppTheme.surfaceLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusExtraLarge)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space24, AppTheme.space12, AppTheme.space24, AppTheme.space32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Handle
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.textColor.withOpacity(0.05),
                        AppTheme.textColor.withOpacity(0.15),
                        AppTheme.textColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: AppTheme.borderRadiusPill,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                
                StaggeredEntrance(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'Capture a Moment 📸',
                        style: AppTheme.titleStyle.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'How would you like to scan your pet?',
                      style: AppTheme.captionStyle.copyWith(
                        color: AppTheme.textLightColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space32),
                
                StaggeredEntrance(
                  staggerDelay: const Duration(milliseconds: 100),
                  children: [
                    // Camera Options
                    Row(
                      children: [
                        Expanded(
                          child: SquishButton(
                            useGlobalLock: false,
                            onPressed: () => Navigator.pop(context, 'camera_photo'),
                            child: _buildPickerOption(
                              title: 'Snap Photo',
                              subtitle: 'Instant results',
                              icon: '📸',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: SquishButton(
                            useGlobalLock: false,
                            onPressed: () => Navigator.pop(context, 'camera_video'),
                            child: _buildPickerOption(
                              title: 'Record Video',
                              subtitle: 'Deep analysis',
                              icon: '🎥',
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space16),
                    
                    // Gallery Options
                    Row(
                      children: [
                        Expanded(
                          child: SquishButton(
                            useGlobalLock: false,
                            onPressed: () => Navigator.pop(context, 'gallery_photo'),
                            child: _buildPickerOption(
                              title: 'From Gallery',
                              subtitle: 'Past memories',
                              icon: '🖼️',
                              color: AppTheme.tertiaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: SquishButton(
                            useGlobalLock: false,
                            onPressed: () => Navigator.pop(context, 'gallery_video'),
                            child: _buildPickerOption(
                              title: 'Import Video',
                              subtitle: 'Detailed look',
                              icon: '🎞️',
                              color: const Color(0xFF7B61FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Text(icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            title, 
            textAlign: TextAlign.center,
            style: AppTheme.titleStyle.copyWith(
              fontSize: 15, 
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle, 
            textAlign: TextAlign.center,
            style: AppTheme.captionStyle.copyWith(
              fontSize: 11,
              color: AppTheme.textLightColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerMediaPicker() async {
    debugPrint('HomeScreen: _triggerMediaPicker called');
    await _showMediaPicker();
  }

  Future<void> _showMediaPicker() async {
    debugPrint('HomeScreen: _showMediaPicker called, _isPickerOpen=$_isPickerOpen');
    if (_isPickerOpen) return;
    
    setState(() => _isPickerOpen = true);
    String? choice;

    try {
      final pipeline = context.read<HomePipelineProvider>();
      debugPrint('HomeScreen: pipeline.isProcessing=${pipeline.isProcessing}');
      if (pipeline.isProcessing) return;

      FurHaptics.impact();

      if (!mounted) return;
      choice = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (_) => _buildMediaPickerSheet(),
      );
    } catch (e) {
      debugPrint('MediaPicker Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickerOpen = false);
      }
    }

    if (choice == null) return;

    if (choice.startsWith('camera')) {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        if (status.isDenied) {
          final shouldRequest = await showEducationalPermissionSheet(context);
          if (!shouldRequest) return;
        }
        
        await [Permission.camera, Permission.microphone].request();
        
        final newStatus = await Permission.camera.status;
        if (!newStatus.isGranted) {
          if (newStatus.isPermanentlyDenied) {
            if (mounted) {
              _showFriendlySnackBar(
                  'Camera access disabled. Please enable it in Settings.', Icons.settings);
            }
          } else {
            if (mounted) {
              _showFriendlySnackBar(
                  'We need access to see your dog 🐶', Icons.no_photography_rounded);
            }
          }
          return;
        }
      }

      final picker = ImagePicker();
      String? result;
      bool isVideo = choice == 'camera_video';

      if (isVideo) {
        final XFile? pickedVideo = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(seconds: 60),
        );
        if (pickedVideo != null) {
          if (!mounted) return;
          result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => VideoTrimmerScreen(
                videoPath: pickedVideo.path,
                onTrimmed: (path) => Navigator.pop(context, path),
              ),
            ),
          );
        }
      } else {
        result = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );
      }

      if (result != null && mounted) {
        if (!isVideo) {
          final cropped = await MediaUtils.cropImage(File(result));
          if (cropped != null) {
            result = cropped.path;
          } else {
            // User cancelled crop, abort pipeline
            return;
          }
        }

        _showFriendlySnackBar(
          isVideo ? '🎥 Video captured!' : '📷 Image captured!',
          isVideo ? Icons.videocam : Icons.camera_alt,
        );

        await _startPipeline(result, isVideo);
      }
      return;
    }

    if (choice.startsWith('gallery')) {
      // Permission check for gallery
      if (Platform.isAndroid) {
        final status = await Permission.photos.status;
        final videoStatus = await Permission.videos.status;
        if (!status.isGranted && !videoStatus.isGranted) {
          await [Permission.photos, Permission.videos].request();
        }
      }

      final picker = ImagePicker();
      XFile? picked;
      bool isVideo = choice == 'gallery_video';

      if (isVideo) {
        picked = await picker.pickVideo(source: ImageSource.gallery);
      } else {
        picked = await picker.pickImage(source: ImageSource.gallery);
      }
      
      if (picked == null) return;

      if (!mounted) return;
      
      String? finalPath;
      if (isVideo) {
        finalPath = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => VideoTrimmerScreen(
              videoPath: picked!.path,
              onTrimmed: (path) => Navigator.pop(context, path),
            ),
          ),
        );
      } else {
        final cropped = await MediaUtils.cropImage(File(picked.path));
        if (cropped != null) {
          finalPath = cropped.path;
        }
      }

      if (finalPath == null) return;

      _showFriendlySnackBar(
        isVideo ? '🎥 Video selected!' : '📷 Image selected!',
        isVideo ? Icons.videocam : Icons.camera_alt,
      );
      
      await _startPipeline(finalPath, isVideo);
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
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(AppTheme.space16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = context.select((HomePipelineProvider p) => p.isProcessing);
    final isGuest = context.select((AuthProvider p) => p.isGuest);
    final error = context.select((HomePipelineProvider p) => p.error);


    return PopScope(
      canPop: !isProcessing,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (isProcessing) {
          _showFriendlySnackBar('Still thinking! Cancel to go back.', Icons.hourglass_top_rounded);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: Stack(
          children: [
            // Background Pattern
            Positioned.fill(
              child: RepaintBoundary(
                child: Opacity(
                  opacity: 0.05,
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
            IgnorePointer(
              ignoring: isProcessing,
              child: SafeArea(
                bottom: false, // Handle bottom padding manually for better control
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppTheme.space24,
                              0,
                              AppTheme.space24,
                              MediaQuery.of(context).padding.bottom + AppTheme.space24,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: AppTheme.space24),
                                StaggeredEntrance(
                                  staggerDelay: const Duration(milliseconds: 120), // More deliberate
                                  children: [
                                    Text(
                                      'How is your',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.headingStyle.copyWith(
                                        color: AppTheme.textColor.withOpacity(0.85),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    ShaderMask(
                                      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                                      child: Text(
                                        'dog',
                                        textAlign: TextAlign.center,
                                        style: AppTheme.headingStyle.copyWith(
                                          color: Colors.white,
                                          fontSize: 84, // Slightly larger for impact
                                          fontWeight: FontWeight.w800,
                                          height: 0.85,
                                          letterSpacing: -5.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'feeling today?',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.headingStyle.copyWith(
                                        color: AppTheme.textColor,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.5,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.space20),
                                    const SizedBox(height: AppTheme.space16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceLow.withOpacity(0.4),
                                        borderRadius: AppTheme.borderRadiusPill,
                                      ),
                                      child: Text(
                                        'Explore their emotional world ✨',
                                        textAlign: TextAlign.center,
                                        style: AppTheme.captionStyle.copyWith(
                                          fontSize: 14,
                                          color: AppTheme.textLightColor,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isGuest) ...[
                                  const SizedBox(height: AppTheme.space12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceContainerLow,
                                      borderRadius: AppTheme.borderRadiusPill,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.pets, size: 14, color: AppTheme.accentColor),
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
                                 StaggeredEntrance(
                                   initialDelay: const Duration(milliseconds: 400),
                                   children: [
                                     RadialGlow(
                                       color: AppTheme.primaryColor.withOpacity(0.35),
                                       size: 340,
                                       child: FloatingLottie(
                                         distance: 14.0, 
                                         duration: const Duration(milliseconds: 3500),
                                         child: PetMoodGlass(
                                           opacity: 0.8,
                                           borderRadius: AppTheme.borderRadiusExtraLarge,
                                           child: Container(
                                             width: double.infinity,
                                             height: 280,
                                             padding: const EdgeInsets.all(AppTheme.space24),
                                             child: RepaintBoundary(
                                               child: Lottie.asset(
                                                 LottieRegistry.get(_randomDogKey),
                                                 fit: BoxFit.contain,
                                                 errorBuilder: (context, error, stackTrace) {
                                                   return const Center(
                                                     child: Icon(Icons.pets_rounded, size: 80, color: AppTheme.primaryColor),
                                                   );
                                                 },
                                               ),
                                             ),
                                           ),
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),

                                const SizedBox(height: 32),

                                // ═══ PRIMARY CTA: Scan Emotion ═══
                                StaggeredEntrance(
                                  initialDelay: const Duration(milliseconds: 600),
                                  children: [
                                    Opacity(
                                      opacity: _isPickerOpen ? 0.6 : 1.0,
                                      child: IgnorePointer(
                                        ignoring: _isPickerOpen,
                                        child: BoundedPulse(
                                          child: SquishButton(
                                            useGlobalLock: false,
                                            onPressed: isProcessing || _isPickerOpen ? null : _triggerMediaPicker,
                                            pressScale: 0.95,
                                            child: Container(
                                              width: double.infinity,
                                              height: 72,
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.primaryGradient,
                                                borderRadius: AppTheme.borderRadiusPill,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor.withOpacity(0.35),
                                                    blurRadius: 24,
                                                    offset: const Offset(0, 10),
                                                  ),
                                                ],
                                              ),
                                              child: Shimmer.fromColors(
                                                baseColor: Colors.white,
                                                highlightColor: Colors.white.withOpacity(0.5),
                                                period: const Duration(milliseconds: 3000),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.2),
                                                        borderRadius: AppTheme.borderRadiusMedium,
                                                      ),
                                                      child: const Icon(Icons.auto_awesome_rounded, size: 28, color: Colors.white),
                                                    ),
                                                    const SizedBox(width: AppTheme.space16),
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Scan Emotion',
                                                          style: AppTheme.titleStyle.copyWith(
                                                            color: Colors.white,
                                                            fontSize: 22,
                                                            fontWeight: FontWeight.w800,
                                                            letterSpacing: -0.5,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Photo or Video',
                                                          style: AppTheme.captionStyle.copyWith(
                                                            color: Colors.white.withOpacity(0.85),
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: AppTheme.space16),

                                // View Results CTA
                                StaggeredEntrance(
                                  initialDelay: const Duration(milliseconds: 800),
                                  children: [
                                    Selector<HomePipelineProvider, bool>(
                                      selector: (_, p) => p.state == HomeState.success,
                                      builder: (context, isResult, _) {
                                        if (!isResult) return const SizedBox.shrink();

                                    return BoundedPulse(
                                      maxPulses: 3,
                                      child: SquishButton(
                                          onPressed: () {
                                            FurHaptics.success();
                                            final pipeline = context.read<HomePipelineProvider>();
                                            final resultId = pipeline.consumeSuccess();
                                            if (resultId != null) {
                                              context.pushResult(resultId);
                                              pipeline.resetPipeline();
                                            } else if (pipeline.lastResultId != null) {
                                              context.pushResult(pipeline.lastResultId!);
                                              pipeline.resetPipeline();
                                            }
                                          },
                                        child: Container(
                                          width: double.infinity,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppTheme.successColor,
                                                Color(0xFF2ECC71),
                                              ],
                                            ),
                                            borderRadius: AppTheme.borderRadiusPill,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.successColor.withOpacity(0.35),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Shimmer.fromColors(
                                            baseColor: Colors.white,
                                            highlightColor: Colors.white.withOpacity(0.6),
                                            period: const Duration(seconds: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.auto_awesome_rounded, size: 24, color: Colors.white),
                                                const SizedBox(width: AppTheme.space12),
                                                Text(
                                                  'View Results ✨',
                                                  style: AppTheme.titleStyle.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.2,
                                                  ),
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
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Error State
            Selector<HomePipelineProvider, AppError?>(
              selector: (_, p) => p.state == HomeState.error ? p.error : null,
              builder: (context, error, _) {
                if (error == null) return const SizedBox.shrink();

                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Material(
                      elevation: 0,
                      borderRadius: AppTheme.borderRadiusLarge,
                      color: AppTheme.surfaceContainerHigh,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: AppTheme.borderRadiusLarge,
                          color: AppTheme.surfaceContainerHigh,
                          boxShadow: AppTheme.floatShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(error.emoji, style: const TextStyle(fontSize: 40)),
                            const SizedBox(height: AppTheme.space12),
                            Text(
                              error.userMessage,
                              textAlign: TextAlign.center,
                              style: AppTheme.titleStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                                  onPressed: () => context.read<HomePipelineProvider>().reset(),
                                  child: const Text('Dismiss'),
                                ),
                                if (error.canRetry) ...[
                                  const SizedBox(width: AppTheme.space12),
                                  SquishButton(
                                    onPressed: _handleRetry,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: AppTheme.borderRadiusMedium,
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text('Try Again', style: TextStyle(color: Colors.white)),
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

            // Processing Overlay
            if (isProcessing)
              Consumer<HomePipelineProvider>(
                builder: (context, pipeline, _) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RepaintBoundary(
                            child: Lottie.asset(
                              LottieRegistry.get('loading'),
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const CircularProgressIndicator(),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),
                          PetMoodGlass(
                            opacity: 0.92,
                            borderRadius: AppTheme.borderRadiusLarge,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PipelineStageIndicator(
                                    state: pipeline.state,
                                    uploadProgress: pipeline.uploadProgress,
                                    compressionProgress: pipeline.compressionProgress,
                                    processingProgress: pipeline.processingProgress,
                                  ),
                                  const SizedBox(height: AppTheme.space12),
                                  ProcessingMessageRotator(
                                    isActive: true,
                                    textStyle: AppTheme.titleStyle.copyWith(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextButton.icon(
                            onPressed: () => pipeline.cancelProcessing(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            label: const Text('Cancel', style: TextStyle(color: Colors.white)),
                            style: TextButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PipelineStageIndicator extends StatelessWidget {
  final HomeState state;
  final double uploadProgress;
  final double compressionProgress;
  final double processingProgress;

  const _PipelineStageIndicator({
    required this.state,
    this.uploadProgress = 0.0,
    this.compressionProgress = 0.0,
    this.processingProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('Preparing', HomeState.compressing),
      ('Uploading', HomeState.uploading),
      ('Analyzing', HomeState.processing),
    ];

    int activeIndex = stages.indexWhere((s) => s.$2 == state);
    if (activeIndex < 0) activeIndex = 0;

    double stageInternalProgress = 0.0;
    if (state == HomeState.compressing) stageInternalProgress = compressionProgress;
    else if (state == HomeState.uploading) stageInternalProgress = uploadProgress;
    else if (state == HomeState.processing) stageInternalProgress = processingProgress;

    final totalProgress = (activeIndex + stageInternalProgress) / stages.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(stages[activeIndex].$1, style: AppTheme.titleStyle.copyWith(fontSize: 13, color: AppTheme.primaryColor)),
            Text('Step ${activeIndex + 1} of ${stages.length}', style: AppTheme.captionStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        ClipRRect(
          borderRadius: AppTheme.borderRadiusPill,
          child: Container(
            height: 6,
            width: double.infinity,
            color: AppTheme.surfaceElevated,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: totalProgress.clamp(0.0, 1.0),
              child: Container(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
