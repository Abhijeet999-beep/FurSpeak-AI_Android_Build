import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:furspeak_ai/data/services/api_service.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/services/emotion_service.dart';

class PreviewScreen extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const PreviewScreen({
    super.key,
    required this.filePath,
    required this.isVideo,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late VideoPlayerController? _controller;
  bool _isProcessing = true;
  bool _hasError = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _controller = VideoPlayerController.file(File(widget.filePath))
        ..initialize().then((_) {
          setState(() {});
          _controller?.play();
        });
    } else {
      _controller = null;
    }
    _startProcessing();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _errorMessage = null;
    });
    try {
      // Use the HTTP service to get the raw backend map
      final resultMap =
          await EmotionService.analyzeEmotion(File(widget.filePath));
      if (!mounted) return;
      setState(() {
        // Only add imagePath if not present, but NEVER overwrite the backend map!
        final fullResult = Map<String, dynamic>.from(resultMap);
        fullResult['imagePath'] = widget.filePath;
        _result = fullResult;
        debugPrint('Final result map: $_result');
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  void _onStartDetection() {
    if (_result != null) {
      debugPrint('GOING TO RESULT:');
      debugPrint(jsonEncode(_result));
      final deepCopy = jsonDecode(jsonEncode(_result!));
      context.goResult(deepCopy);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If loading, block back
        // (Assume you have a _isLoading or similar state; if not, allow back)
        // Replace _isLoading with your actual loading state variable if needed
        // if (_isLoading) return false;
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          title: Text(
            widget.isVideo ? 'Video Preview' : 'Image Preview',
            style: AppTheme.titleStyle,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: widget.isVideo
                      ? _controller?.value.isInitialized ?? false
                          ? AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: VideoPlayer(_controller!),
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            )
                      : Image.file(
                          File(widget.filePath),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _onStartDetection,
                      style: AppTheme.primaryButtonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(
                          _isProcessing
                              ? AppTheme.textLightColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isProcessing)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            const Icon(Icons.auto_awesome),
                          const SizedBox(width: 12),
                          Text(
                            _isProcessing ? 'Processing...' : 'Start Detection',
                            style: AppTheme.titleStyle.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textLightColor,
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTheme.bodyStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
