import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:furspeak_ai/presentation/screens/video_trimmer_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:furspeak_ai/data/services/api_service.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/presentation/screens/preview_screen.dart';
import 'package:furspeak_ai/config/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _authService = AuthService();
  bool _isProcessing = false;
  bool _isLoading = false;
  Map<String, dynamic>? _pendingResult;
  String? _pendingFilePath;
  bool _isVideo = false;

  // Animation assets
  final List<String> _dogAnimations = List.generate(
    10,
    (i) => 'assets/animations/dog_${i + 1}.json',
  );
  int _currentAnimIndex = 0;
  late Timer _timer;
  final List<LottieComposition?> _preloadedCompositions = List.filled(10, null);
  bool _allPreloaded = false;

  // Add a state variable to track analysis completion
  bool _analysisComplete = false;

  @override
  void initState() {
    super.initState();
    _preloadLotties();
    _startAnimationShuffle();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _preloadLotties() async {
    for (int i = 0; i < _dogAnimations.length; i++) {
      final comp = await AssetLottie('' + _dogAnimations[i]).load();
      _preloadedCompositions[i] = comp;
      if (i == _dogAnimations.length - 1) {
        setState(() {
          _allPreloaded = true;
        });
      }
    }
  }

  void _startAnimationShuffle() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        int next;
        do {
          next =
              (List.generate(_dogAnimations.length, (i) => i)..shuffle()).first;
        } while (next == _currentAnimIndex);
        _currentAnimIndex = next;
      });
    });
  }

  Future<bool> checkAllMediaPermissions() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    bool storage = false;

    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) {
        storage = true;
      } else if (await Permission.photos.isGranted) {
        storage = true;
      } else if (await Permission.mediaLibrary.isGranted) {
        storage = true;
      } else if (await Permission.manageExternalStorage.isGranted) {
        storage = true;
      } else if (await Permission.videos.isGranted) {
        storage = true;
      } else if (await Permission.audio.isGranted) {
        storage = true;
      } else if (await Permission.accessMediaLocation.isGranted) {
        storage = true;
      }
    } else {
      storage = await Permission.photos.isGranted;
    }

    return camera.isGranted && mic.isGranted && storage;
  }

  Future<void> _processMedia(String filePath, bool isVideo) async {
    setState(() {
      _isProcessing = true;
      _isLoading = true;
      _pendingFilePath = filePath;
      _isVideo = isVideo;
    });

    try {
      final apiService = ApiServiceFactory.create();
      final response = await apiService.detectEmotion(File(filePath));

      if (!mounted) return;

      setState(() {
        _pendingResult = {
          'imagePath': filePath,
          'emotion': response.emotion,
          'confidence': response.confidence,
          'caption': response.caption,
          'processing_time': response.processingTime,
          'timestamp': response.timestamp,
          'video_info': response.videoInfo,
          'frame_image_path': response.frameImagePath,
          'frame_image_url': response.frameImageUrl,
        };
        _isProcessing = false;
        _isLoading = false;
        _analysisComplete = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isLoading = false;
        _pendingResult = null;
        _pendingFilePath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error processing media: ${e.toString()}',
            style: AppTheme.bodyStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _handleCapture() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _isProcessing = true;
    });
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.photos,
      Permission.videos,
    ];
    await permissions.request();
    final hasPermissions = await checkAllMediaPermissions();
    if (!hasPermissions) {
      setState(() {
        _isLoading = false;
        _isProcessing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Camera, microphone and storage permissions are required.',
            style: AppTheme.bodyStyle,
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = false;
    });
    final result = await context.push<String>('/camera');
    if (result != null && mounted) {
      final isVideo = result.toLowerCase().endsWith('.mp4') ||
          result.toLowerCase().endsWith('.mov') ||
          result.toLowerCase().endsWith('.avi');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isVideo ? Icons.videocam : Icons.camera_alt,
                color: AppTheme.successColor,
              ),
              SizedBox(width: 8),
              Text(
                isVideo ? 'Video captured!' : 'Image captured!',
                style: AppTheme.bodyStyle,
              ),
            ],
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = true;
        _isProcessing = true;
      });
      await _processMedia(result, isVideo);
    } else {
      setState(() {
        _isLoading = false;
        _isProcessing = false;
      });
    }
  }

  void _handleGallery() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _isProcessing = true;
    });
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.photos,
      Permission.videos,
    ];
    await permissions.request();
    final hasPermissions = await checkAllMediaPermissions();
    if (!hasPermissions) {
      setState(() {
        _isLoading = false;
        _isProcessing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Camera, microphone and storage permissions are required.',
            style: AppTheme.bodyStyle,
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppTheme.primaryColor),
              title: Text('Pick Image', style: AppTheme.titleStyle),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppTheme.accentColor),
              title: Text('Pick Video', style: AppTheme.titleStyle),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) {
      setState(() {
        _isLoading = false;
        _isProcessing = false;
      });
      return;
    }
    if (choice == 'image') {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _isLoading = false;
        _isProcessing = false;
      });
      if (picked == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.camera_alt, color: AppTheme.successColor),
              SizedBox(width: 8),
              Text('Image selected!', style: AppTheme.bodyStyle),
            ],
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isLoading = true;
        _isProcessing = true;
      });
      await _processMedia(picked.path, false);
      return;
    }
    if (choice == 'video') {
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
        });
        return;
      }
      final controller = VideoPlayerController.file(File(picked.path));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      setState(() {
        _isLoading = false;
      });

      if (duration.inSeconds > 30) {
        if (!mounted) return;
        final trimmed = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => VideoTrimmerScreen(
              videoPath: picked.path,
              onTrimmed: (trimmedPath) {
                Navigator.pop(context, trimmedPath);
              },
            ),
          ),
        );
        if (trimmed != null) {
          setState(() {
            _isLoading = true;
            _isProcessing = true;
          });
          await _processMedia(trimmed, true);
        } else {
          setState(() {
            _isLoading = false;
            _isProcessing = false;
          });
        }
      } else {
        setState(() {
          _isLoading = true;
          _isProcessing = true;
        });
        await _processMedia(picked.path, true);
      }
    }
  }

  void _handleStartDetection() {
    if (_pendingResult != null) {
      context.goResult(_pendingResult!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isProcessing || _isLoading) return false;
        // If there is a pending result, always go to Home root
        if (_pendingResult != null) {
          context.goHome();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Subtle background paw prints for playfulness
            Positioned.fill(
              child: Opacity(
                opacity: 0.07,
                child: Lottie.asset(
                  'assets/animations/paw_prints_bg.json',
                  fit: BoxFit.cover,
                  repeat: true,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PawMood ',
                          style: AppTheme.headingStyle.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Icon(Icons.pets,
                            color: AppTheme.primaryColor, size: 32),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Animated Dog in a playful card
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: Container(
                        key: ValueKey(_currentAnimIndex),
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: _allPreloaded &&
                                  _preloadedCompositions[_currentAnimIndex] !=
                                      null
                              ? Lottie(
                                  composition: _preloadedCompositions[
                                      _currentAnimIndex]!,
                                  fit: BoxFit.contain,
                                )
                              : Lottie.asset(_dogAnimations[_currentAnimIndex],
                                  fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // Reduced space below animation
                    // Buttons
                    _HomeActionButton(
                      label: 'Capture Image or Video',
                      color: AppTheme.successColor,
                      icon: Icons.camera_alt,
                      onPressed:
                          _isProcessing || _isLoading ? null : _handleCapture,
                      height: 58,
                    ),
                    const SizedBox(height: 14),
                    _HomeActionButton(
                      label: 'Upload from Gallery',
                      color: AppTheme.primaryColor,
                      icon: Icons.photo_library,
                      onPressed:
                          _isProcessing || _isLoading ? null : _handleGallery,
                      height: 58,
                    ),
                    const SizedBox(height: 14),
                    _HomeActionButton(
                      label: 'Start Detection',
                      color: AppTheme.accentColor,
                      icon: Icons.auto_awesome,
                      onPressed: _isProcessing ? null : _handleStartDetection,
                      height: 58,
                    ),
                    const Spacer(),
                    SizedBox(height: 8), // Add a little space above nav bar
                  ],
                ),
              ),
            ),
            // Fixed analysis complete note
            if (_analysisComplete && !_isProcessing && !_isLoading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 56, // closer to nav bar, less overlap
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.successColor, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Analysis complete! Tap "Start Detection" to view results.',
                              style: AppTheme.bodyStyle.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isLoading || _isProcessing)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
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
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: AppTheme.bgColor,
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;

  const _HomeActionButton({
    required this.label,
    required this.color,
    required this.icon,
    this.onPressed,
    this.height = 58,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 10,
            shadowColor: color.withOpacity(0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: AppTheme.titleStyle.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
