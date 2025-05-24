import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoTrimmerScreen extends StatefulWidget {
  final String videoPath;
  final int maxDurationSeconds;
  final void Function(String trimmedPath) onTrimmed;

  const VideoTrimmerScreen({
    super.key,
    required this.videoPath,
    this.maxDurationSeconds = 60,
    required this.onTrimmed,
  });

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isLoading = true;
  bool _isTrimming = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    await _trimmer.loadVideo(videoFile: File(widget.videoPath));
    setState(() {
      _isLoading = false;
      _endValue =
          _trimmer.videoPlayerController?.value.duration.inSeconds.toDouble() ??
              widget.maxDurationSeconds.toDouble();
      if (_endValue > widget.maxDurationSeconds) {
        _endValue = widget.maxDurationSeconds.toDouble();
      }
    });
  }

  Future<void> _onTrimPressed() async {
    setState(() => _isTrimming = true);
    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (outputPath) {
        setState(() => _isTrimming = false);
        if (outputPath != null) {
          widget.onTrimmed(outputPath);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trim Video'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5A5BD9),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: VideoViewer(trimmer: _trimmer),
                ),
                // TODO: Add trim slider/editor here when available in your video_trimmer version
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Trim slider/editor not available in this package version. Please update the package or add the widget.',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isTrimming ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isTrimming ? null : _onTrimPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A5BD9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isTrimming
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Trim'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
