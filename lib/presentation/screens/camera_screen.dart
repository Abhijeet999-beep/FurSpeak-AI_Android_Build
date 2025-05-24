import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIdx = 0;
  bool _isRecording = false;
  double _recordProgress = 0.0;
  Timer? _recordTimer;
  static const int _maxDuration = 60; // seconds
  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  bool _isDisposed = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Camera, microphone and storage permissions are required'),
            duration: Duration(seconds: 3),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking permissions: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
      context.pop();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing camera: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
      context.pop();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing camera: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
      context.pop();
    }

    oldController?.dispose();
  }

  Future<void> _onCapturePressed() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDisposed)
      return;
    try {
      HapticFeedback.mediumImpact();
      final file = await _controller!.takePicture();
      if (!mounted || _isDisposed) return;
      context.pop(file.path);
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _onRecordStart() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDisposed)
      return;
    try {
      HapticFeedback.mediumImpact();
      setState(() {
        _isRecording = true;
        _recordProgress = 0.0;
      });
      await _controller!.startVideoRecording();
      _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted || _isDisposed) {
          timer.cancel();
          return;
        }
        setState(() {
          _recordProgress = timer.tick / (_maxDuration * 10);
        });
        if (timer.tick >= _maxDuration * 10) {
          _onRecordStop();
        }
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting recording: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _onRecordStop() async {
    if (!_isRecording || _isDisposed) return;
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordProgress = 0.0;
    });
    try {
      final file = await _controller!.stopVideoRecording();
      if (!mounted || _isDisposed) return;
      context.pop(file.path);
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping recording: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onCameraSwitch() {
    if (_cameras == null || _cameras!.length < 2 || _isDisposed) return;
    setState(() {
      _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    });
    _onNewCameraSelected(_cameras![_selectedCameraIdx]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final newMode =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(newMode);
    setState(() => _flashMode = newMode);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isRecording) {
          await _onRecordStop();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera Preview
            if (_controller != null && _controller!.value.isInitialized)
              Positioned.fill(
                child: Stack(
                  children: [
                    CameraPreview(_controller!),
                    // Centered Focus Frame Overlay
                    Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF43E97B),
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
            // Flashlight Toggle (top-left)
            Positioned(
              top: 48,
              left: 32,
              child: GestureDetector(
                onTap: _toggleFlash,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _flashMode == FlashMode.torch
                        ? Icons.flash_on
                        : Icons.flash_off,
                    size: 32,
                    color: const Color(0xFFFFA726),
                  ),
                ),
              ),
            ),
            // Camera Switch Button (top-right)
            Positioned(
              top: 48,
              right: 32,
              child: GestureDetector(
                onTap: _onCameraSwitch,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.flip_camera_ios,
                      size: 32, color: Color(0xFF5A5BD9)),
                ),
              ),
            ),
            // Snapchat-style Capture Button
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isRecording ? null : _onCapturePressed,
                  onLongPress: _isRecording ? null : _onRecordStart,
                  onLongPressUp: _isRecording ? _onRecordStop : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isRecording ? 92 : 104,
                    height: _isRecording ? 92 : 104,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD85C), // Pastel yellow
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFA726),
                        width: 6,
                      ),
                    ),
                    child: Icon(
                      _isRecording ? Icons.videocam : Icons.camera_alt,
                      color: _isRecording
                          ? const Color(0xFFFFA726)
                          : const Color(0xFF5A5BD9),
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
            // Progress ring for video recording
            if (_isRecording)
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _recordProgress,
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFA726)),
                      backgroundColor: Colors.white.withOpacity(0.3),
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
