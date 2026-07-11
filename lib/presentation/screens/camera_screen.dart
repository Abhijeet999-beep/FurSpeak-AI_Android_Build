import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// go_router removed — camera uses native Navigator (imperative flow)
import 'package:permission_handler/permission_handler.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/utils/action_lock.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIdx = 0;
  bool _isRecording = false;
  double _recordProgress = 0.0;
  Timer? _recordTimer;
  int _recordSeconds = 0;
  static const int _maxDuration = 60; // seconds
  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  bool _isDisposed = false;
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.off;

  // Blinking animation for recording indicator
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _checkPermissions();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _blinkController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(_cameras![_selectedCameraIdx]);
    }
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

  Future<void> _checkPermissions() async {
    try {
      final permissions = [
        Permission.camera,
        Permission.microphone,
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ];
      await permissions.request();
      final hasPermissions = await checkAllMediaPermissions();
      if (hasPermissions) {
        if (!mounted || _isDisposed) return;
        setState(() => _isPermissionGranted = true);
        await _initCamera();
      } else {
        if (!mounted || _isDisposed) return;
        _showPermissionSettingsDialog();
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showPermissionSettingsDialog();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }
      await _onNewCameraSelected(_cameras![_selectedCameraIdx]);
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showFriendlySnackBar(
        '📷 Could not initialize camera. Please try again.',
        Icons.camera_alt_rounded,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_isDisposed) return;

    final oldController = _controller;
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      if (!mounted || _isDisposed) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showFriendlySnackBar(
        '📷 Camera error. Please try again.',
        Icons.camera_alt_rounded,
      );
      Navigator.pop(context);
    }

    oldController?.dispose();
  }

  void _showFriendlySnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          'Allow Access',
          style: AppTheme.headingStyle.copyWith(fontSize: 22, color: AppTheme.primaryColor),
        ),
        content: Text(
          'FurSpeak AI requires Camera and Microphone access to record and analyze your dog\'s emotions. Please enable permissions in your device settings.',
          style: AppTheme.bodyStyle.copyWith(color: AppTheme.textLightColor, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              'Open Settings',
              style: AppTheme.titleStyle.copyWith(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCapturePressed() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDisposed || _isProcessing) {
      return;
    }
    if (globalActionLock.isLocked) return;

    await globalActionLock.execute(() async {
      setState(() => _isProcessing = true);
      try {
        HapticFeedback.mediumImpact();
        final file = await _controller!.takePicture();
        if (!mounted || _isDisposed) return;
        Navigator.pop(context, file.path);
      } catch (e) {
        if (!mounted || _isDisposed) return;
        setState(() => _isProcessing = false);
        _showFriendlySnackBar(
          '📷 Could not capture image. Please try again.',
          Icons.camera_alt_rounded,
        );
      }
    });
  }

  Future<void> _onRecordStart() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDisposed) {
      return;
    }
    try {
      HapticFeedback.mediumImpact();
      setState(() {
        _isRecording = true;
        _recordProgress = 0.0;
        _recordSeconds = 0;
      });
      _blinkController.repeat(reverse: true);
      await _controller!.startVideoRecording();
      _recordTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted || _isDisposed) {
          timer.cancel();
          return;
        }
        setState(() {
          _recordProgress = timer.tick / (_maxDuration * 10);
          _recordSeconds = timer.tick ~/ 10;
        });
        if (timer.tick >= _maxDuration * 10) {
          _onRecordStop();
        }
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() => _isRecording = false);
      _blinkController.stop();
      _showFriendlySnackBar(
        '🎥 Could not start recording. Please try again.',
        Icons.videocam_off_rounded,
      );
    }
  }

  Future<void> _onRecordStop() async {
    if (!_isRecording || _isDisposed || _isProcessing) return;
    if (globalActionLock.isLocked) return;

    _recordTimer?.cancel();
    _blinkController.stop();
    _blinkController.reset();
    setState(() {
      _isRecording = false;
      _recordProgress = 0.0;
      _recordSeconds = 0;
    });
    
    await globalActionLock.execute(() async {
      setState(() => _isProcessing = true);
      try {
        final file = await _controller!.stopVideoRecording();
        if (!mounted || _isDisposed) return;
        Navigator.pop(context, file.path);
      } catch (e) {
        if (!mounted || _isDisposed) return;
        setState(() => _isProcessing = false);
        _showFriendlySnackBar(
          '🎥 Could not save recording. Please try again.',
          Icons.videocam_off_rounded,
        );
      }
    });
  }

  void _onCameraSwitch() {
    if (_cameras == null || _cameras!.length < 2 || _isDisposed || _isRecording) {
      return;
    }
    setState(() {
      _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    });
    _onNewCameraSelected(_cameras![_selectedCameraIdx]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || _isRecording) return;
    final newMode =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(newMode);
    setState(() => _flashMode = newMode);
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF43E97B)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Setting up camera...',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_isRecording && !_isProcessing,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          if (_isRecording && !_isProcessing) {
            await _onRecordStop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera Preview — clipped to prevent overflow
            if (_controller != null && _controller!.value.isInitialized)
              Positioned.fill(
                child: ClipRRect(
                  child: CameraPreview(_controller!),
                ),
              )
            else
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF43E97B)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading camera...',
                      style: TextStyle(color: Colors.white70, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),

            // 2. Focus Frame + Guide Text
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 240, // Slightly smaller for better fit
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isRecording
                            ? const Color(0xFFF95F62)
                            : const Color(0xFF43E97B),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isRecording
                          ? '🎥 Recording your pup...'
                          : '🐕 Place dog\'s face here',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. UI Overlays (Top/Bottom)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // TOP BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Flash Button
                        AnimatedOpacity(
                          opacity: _isRecording ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: _isRecording,
                            child: _buildRoundIconButton(
                              icon: _flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off,
                              color: const Color(0xFFFFA726),
                              onTap: _toggleFlash,
                            ),
                          ),
                        ),

                        // Timer (if recording)
                        if (_isRecording)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FadeTransition(
                                  opacity: _blinkAnimation,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF95F62),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimer(_recordSeconds),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Switch Camera
                        AnimatedOpacity(
                          opacity: _isRecording ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: _isRecording,
                            child: _buildRoundIconButton(
                              icon: Icons.flip_camera_ios,
                              color: const Color(0xFF5A5BD9),
                              onTap: _onCameraSwitch,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // BOTTOM BAR: Capture Button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onLongPress: (_isRecording || _isProcessing) ? null : _onRecordStart,
                          onLongPressUp: (_isRecording && !_isProcessing) ? _onRecordStop : null,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Progress Ring (while recording)
                              if (_isRecording)
                                SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: CircularProgressIndicator(
                                    value: _recordProgress,
                                    strokeWidth: 5,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF95F62)),
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              
                              // Main Button Container (Stable Lerp Fix)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                width: _isRecording ? 72 : 84,
                                height: _isRecording ? 72 : 84,
                                decoration: BoxDecoration(
                                  color: _isRecording ? const Color(0xFFF95F62) : const Color(0xFFFFD85C),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isRecording ? Colors.white : const Color(0xFFFFA726),
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isRecording 
                                          ? const Color(0xFFF95F62).withOpacity(0.3)
                                          : const Color(0xFFFFA000).withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: _isProcessing ? null : (_isRecording ? _onRecordStop : _onCapturePressed),
                                  customBorder: const CircleBorder(),
                                  child: Center(
                                    child: _isProcessing
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Icon(
                                            _isRecording ? Icons.stop_rounded : Icons.camera_alt_rounded,
                                            color: _isRecording ? Colors.white : const Color(0xFF5A5BD9),
                                            size: 32,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Hint text — wrapped in Container for styling
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _isRecording
                                ? 'Tap to stop recording'
                                : 'Tap for photo • Hold for video',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10), // Safe spacing from screen edge
                      ],
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

  Widget _buildRoundIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 24, color: color),
      ),
    );
  }

}
