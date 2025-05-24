import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:furspeak_ai/models/emotion_result.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'dart:convert';
import 'package:furspeak_ai/data/models/emotion_history.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;

  const ResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _hasSaved = false;

  // Theme Colors
  static const Color _bgColor = Color(0xFFFFFAF2); // Vanilla Cream
  static const Color _primaryColor = Color(0xFF7E8CE0); // Soft Periwinkle
  static const Color _accentColor = Color(0xFFFFB347); // Gentle Orange
  static const Color _tertiaryColor = Color(0xFFFFE084); // Pastel Yellow
  static const Color _successColor = Color(0xFF43E97B); // Mint Green

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return AppTheme.successColor;
      case 'sad':
        return AppTheme.primaryColor;
      case 'angry':
        return AppTheme.errorColor;
      case 'fearful':
        return AppTheme.accentColor;
      case 'surprised':
        return AppTheme.tertiaryColor;
      case 'disgusted':
        return AppTheme.errorColor;
      case 'neutral':
        return AppTheme.textLightColor;
      case 'relax':
      case 'relaxed':
        return AppTheme.primaryColor;
      case 'playful':
        return AppTheme.accentColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'fearful':
        return '😨';
      case 'surprised':
        return '😲';
      case 'disgusted':
        return '🤢';
      case 'neutral':
        return '😐';
      case 'relax':
      case 'relaxed':
        return '😌';
      case 'playful':
        return '🐾';
      default:
        return '🐕';
    }
  }

  @override
  void initState() {
    super.initState();
    _speakResult();
    _autoSaveToHistory();
    if (widget.result['videoPath'] != null &&
        widget.result['videoPath']!.isNotEmpty) {
      _videoController =
          VideoPlayerController.file(File(widget.result['videoPath']!))
            ..initialize().then((_) {
              setState(() {});
            });
    }
    HapticFeedback.mediumImpact();
  }

  Future<void> _autoSaveToHistory() async {
    final authService = AuthService();
    if (!authService.isGuest && !_hasSaved) {
      try {
        final isar = GetIt.instance<Isar>();
        final history = EmotionHistory(
          userId: authService.currentUser?.id ?? '',
          emotion: widget.result['emotion'] as String,
          confidence: widget.result['confidence'] as double,
          caption: widget.result['caption'] as String,
          frameImagePath: widget.result['frame_image_path'] as String?,
          timestamp: DateTime.now(),
        );

        await isar.writeTxn(() async {
          await isar.emotionHistorys.put(history);
        });

        setState(() {
          _hasSaved = true;
        });
      } catch (e) {
        debugPrint('Error saving to history: $e');
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakResult() async {
    try {
      final text = widget.result['caption'] ?? '';
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

  String _getEmotionAnimation(String? emotion) {
    final e = (emotion ?? 'neutral').toLowerCase();
    const available = [
      'dog_1',
      'dog_2',
      'dog_3',
      'dog_4',
      'dog_5',
      'dog_6',
      'dog_7',
      'dog_8',
      'corgi_in_box',
      'corgi_wave',
      'floating_ball',
      'floating_bone',
    ];
    if (available.contains(e)) {
      return 'assets/animations/$e.json';
    }
    // fallback for common emotions
    switch (e) {
      case 'happy':
        return 'assets/animations/dog_1.json';
      case 'relaxed':
      case 'relax':
        return 'assets/animations/dog_2.json';
      case 'alert':
        return 'assets/animations/dog_3.json';
      case 'angry':
        return 'assets/animations/dog_4.json';
      case 'frown':
        return 'assets/animations/dog_4.json'; // Use angry animation for frown
      case 'neutral':
        return 'assets/animations/dog_5.json';
      default:
        return 'assets/animations/dog_1.json';
    }
  }

  String? _getBestFrameImagePath(Map<String, dynamic> result) {
    // Check all possible key variants for best frame
    final keys = [
      'frame_image_path',
      'frameImagePath',
      'frame_image_url',
      'frameImageUrl',
      'imagePath',
      'image_path',
    ];
    for (final key in keys) {
      final value = result[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  Widget _mediaPreview() {
    // Always prefer frame_image_url or frameImageUrl if present and not empty
    final frameImageUrl =
        widget.result['frame_image_url'] ?? widget.result['frameImageUrl'];
    debugPrint('ResultScreen - frame_image_url: $frameImageUrl');

    if (frameImageUrl != null && frameImageUrl.toString().isNotEmpty) {
      debugPrint('Using network frame_image_url for preview: $frameImageUrl');
      return CachedNetworkImage(
        imageUrl: frameImageUrl,
        height: 260,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(height: 260, color: Colors.white),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Error loading frame_image_url: $error');
          return _failedPreviewWidget();
        },
      );
    }

    // If no emotion/dog detected, show failed.json Lottie asset
    final emotion = widget.result['emotion']?.toString().toLowerCase() ?? '';
    if (emotion == 'unknown' ||
        emotion == 'no dog detected' ||
        emotion.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Lottie.asset(
            'assets/animations/failed.json',
            width: 260,
            height: 260,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    debugPrint('No valid preview source found, showing failed widget');
    return _failedPreviewWidget();
  }

  Widget _failedPreviewWidget() {
    return Container(
      height: 260,
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey, size: 100),
            SizedBox(height: 16),
            Text('No preview available',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    if (widget.result['timeline'] == null) return const SizedBox.shrink();

    final timeline =
        (widget.result['timeline'] as List).cast<Map<String, dynamic>>();
    final transitions = widget.result['timeline_summary']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emotion Timeline',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A5BD9), // Sky Indigo
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transitions,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Color(0xFF777777), // Stone Gray
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: timeline.map((frame) {
                    return _EmotionChip(
                      emotion: frame['emotion'] as String,
                      confidence: 1.0, // Timeline doesn't include confidence
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  final TextEditingController _noteController = TextEditingController();

  Widget _confidenceBadge(double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF43E97B).withOpacity(0.15), // Mint green pastel
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Color(0xFF43E97B), size: 18),
          const SizedBox(width: 6),
          Text(
            '${confidence.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Color(0xFF43E97B),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, {IconData? icon, Color? color}) {
    return Row(
      children: [
        if (icon != null) Icon(icon, color: color ?? const Color(0xFF5A5BD9)),
        if (icon != null) const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF5A5BD9),
          ),
        ),
      ],
    );
  }

  // Helper: Generate contextual caption from timeline
  String _generateContextualCaption(Map<String, dynamic> result) {
    final timeline = result['timeline'] as List<dynamic>?;
    if (timeline == null || timeline.isEmpty) {
      return result['caption'] ?? '';
    }
    // Aggregate emotions
    final emotions = timeline.map((e) => e['emotion'] as String).toList();
    if (emotions.isEmpty) return result['caption'] ?? '';
    final first = emotions.first;
    final last = emotions.last;
    // Count frequencies
    final freq = <String, int>{};
    for (final e in emotions) {
      freq[e] = (freq[e] ?? 0) + 1;
    }
    // Most frequent
    final mostFrequent = (freq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
    // Detect transitions
    final transitions = <String>[];
    String? prev;
    for (final e in emotions) {
      if (prev != null && prev != e) {
        transitions.add('$prev→$e');
      }
      prev = e;
    }
    // Build natural caption
    if (first == last && transitions.isEmpty) {
      return 'Your dog remained $first throughout the video.';
    }
    if (transitions.isEmpty) {
      return 'Your dog started $first and ended $last.';
    }
    // Weighted bias: if last part is happy/relaxed, bias towards positive
    String moodSummary = '';
    if (last == 'happy' || last == 'relaxed' || last == 'playful') {
      moodSummary =
          'After some $first, your dog became $last, showing positive engagement.';
    } else if (last == 'alert' || last == 'anxious') {
      moodSummary =
          'Your dog started $first and ended $last, showing some caution or alertness.';
    } else {
      moodSummary =
          'Your dog experienced $first, then $mostFrequent, and ended $last.';
    }
    // Add transition summary
    final transitionStr =
        transitions.isNotEmpty ? 'Transitions: ${transitions.join(', ')}.' : '';
    return '$moodSummary $transitionStr';
  }

  Color _emotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return const Color(0xFF43E97B); // Mint Green
      case 'alert':
        return const Color(0xFFFFA726); // Amber
      case 'relaxed':
      case 'relax':
        return const Color(0xFF7E8CE0); // Blue Violet
      case 'frown':
        return const Color(0xFFB0B0B0); // Soft Gray
      case 'angry':
        return const Color(0xFFF95F62); // Coral Red
      default:
        return const Color(0xFF6E6E6E); // Neutral
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ResultScreen widget.result: ' + widget.result.toString());
    final result = widget.result;
    final emotion = result['emotion'] ?? 'Unknown';
    final confidence = (result['confidence'] ?? 0.0) as double;
    final emoji = _getEmotionEmoji(emotion);
    final caption = result['caption'] ?? '';
    final timelineSummary = result['timeline_summary'] ?? '';
    final timeline = (result['timeline'] as List?) ?? [];
    final isError = (emotion == 'unknown' || confidence == 0.0);
    final color = _emotionColor(emotion);
    final authService = AuthService();
    final isGuest = authService.isGuest;

    return WillPopScope(
      onWillPop: () async {
        // If a dialog is open, block back
        if (ModalRoute.of(context)?.isCurrent == false) return false;
        context.goHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          title: Text('Analysis Result', style: AppTheme.titleStyle),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            Semantics(
              label: 'Show timeline moods and analysis info',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.info_outline,
                    color: AppTheme.primaryColor, size: 32),
                tooltip: 'Show analysis info',
                onPressed: () {
                  // Robustly parse timeline and summary
                  final timelineRaw = widget.result['timeline'];
                  List<Map<String, dynamic>> timeline = [];
                  if (timelineRaw is List) {
                    timeline = timelineRaw.cast<Map<String, dynamic>>();
                  } else if (timelineRaw is String && timelineRaw.isNotEmpty) {
                    try {
                      final decoded = json.decode(timelineRaw);
                      if (decoded is List) {
                        timeline = List<Map<String, dynamic>>.from(decoded);
                      }
                    } catch (_) {}
                  }
                  final moods = timeline
                      .map((e) => e['emotion'] as String? ?? 'Unknown')
                      .where((m) => m.isNotEmpty && m != 'Unknown')
                      .toList();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.timeline, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Mood Timeline'),
                        ],
                      ),
                      content: SizedBox(
                        width: 320,
                        child: moods.isNotEmpty
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline bar
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (int i = 0; i < moods.length; i++)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            child: Column(
                                              children: [
                                                Icon(_moodIcon(moods[i]),
                                                    color:
                                                        _emotionColor(moods[i]),
                                                    size: 28),
                                                Text(moods[i].capitalize(),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: _emotionColor(
                                                          moods[i]),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    )),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Summary
                                  if (widget.result['timeline_summary'] !=
                                          null &&
                                      widget.result['timeline_summary']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      widget.result['timeline_summary']
                                          .toString(),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF2C2C2C)),
                                    ),
                                  const SizedBox(height: 16),
                                  // Legend
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _legendChip('Happy', Icons.emoji_emotions,
                                          _emotionColor('happy')),
                                      _legendChip(
                                          'Relaxed',
                                          Icons.nightlight_round,
                                          _emotionColor('relaxed')),
                                      _legendChip(
                                          'Angry',
                                          Icons.warning_amber_rounded,
                                          _emotionColor('angry')),
                                      _legendChip('Alert', Icons.visibility,
                                          _emotionColor('alert')),
                                      _legendChip(
                                          'Frown',
                                          Icons.sentiment_dissatisfied,
                                          _emotionColor('frown')),
                                      _legendChip('Playful', Icons.pets,
                                          _emotionColor('playful')),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 48, color: AppTheme.primaryColor),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No timeline was generated for this analysis.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _mediaPreview(),
                    ),
                    // Paw watermark overlay
                    Positioned(
                      bottom: 12,
                      right: 18,
                      child: Opacity(
                        opacity: 0.18,
                        child: Icon(Icons.pets, size: 48, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Tag
                Text(
                  'Most expressive moment',
                  style: TextStyle(
                    color: color.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 18),
                // 2. Detected Emotion Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      emotion.toString().capitalize(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Text(
                    'Confidence: ${confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // 3. Timeline-Based Caption
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF6FF),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isError
                          ? 'No emotion detected. Please ensure your dog\'s face is visible and try again.'
                          : caption,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // 4. What This Means (timeline summary as bullet points)
                if (timelineSummary != null &&
                    timelineSummary.toString().isNotEmpty)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'What this means:',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._parseTimelineSummary(timelineSummary),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                // 5. Emotion Timeline Visualization (optional)
                if (timeline.isNotEmpty) _buildTimelineBar(timeline, color),
                const SizedBox(height: 28),
                // 6. Bottom Actions
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleAnalyzeAnother,
                      icon: const Icon(Icons.pets, color: Colors.white),
                      label: const Text('Analyze Another'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Parse timeline summary into bullet points with icons
  List<Widget> _parseTimelineSummary(dynamic summary) {
    final text = summary.toString();
    final points = text.split(',');
    final List<Widget> widgets = [];
    for (final point in points) {
      final trimmed = point.trim();
      if (trimmed.isEmpty) continue;
      IconData icon = Icons.check_circle;
      if (trimmed.toLowerCase().contains('relax'))
        icon = Icons.nightlight_round;
      if (trimmed.toLowerCase().contains('alert')) icon = Icons.visibility;
      if (trimmed.toLowerCase().contains('angry'))
        icon = Icons.warning_amber_rounded;
      if (trimmed.toLowerCase().contains('frown'))
        icon = Icons.sentiment_dissatisfied;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF43E97B), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trimmed,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  // Optional: Timeline bar visualization
  Widget _buildTimelineBar(List timeline, Color color) {
    if (timeline.isEmpty) return const SizedBox.shrink();
    final emotions = timeline.map((e) => e['emotion'] as String).toList();
    final unique = emotions.toSet().toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < emotions.length; i++)
            Container(
              width: 12,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _emotionColor(emotions[i]),
                borderRadius: BorderRadius.circular(6),
                border: i > 0 && emotions[i] != emotions[i - 1]
                    ? Border.all(
                        color: Colors.black.withOpacity(0.18), width: 2)
                    : null,
              ),
            ),
          const SizedBox(width: 8),
          const Text('Timeline',
              style: TextStyle(fontSize: 13, color: Color(0xFF777777))),
        ],
      ),
    );
  }

  // Helper for mood icons
  IconData _moodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Icons.emoji_emotions;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.warning_amber_rounded;
      case 'fearful':
        return Icons.visibility;
      case 'surprised':
        return Icons.flash_on;
      case 'disgusted':
        return Icons.sick;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'relax':
      case 'relaxed':
        return Icons.nightlight_round;
      case 'playful':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  Widget _legendChip(String label, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}

class _EmotionChip extends StatelessWidget {
  final String emotion;
  final double confidence;

  const _EmotionChip({
    required this.emotion,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _emotionColor(emotion).withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: _emotionColor(emotion).withAlpha((255 * 0.2).toInt()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emotion,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _emotionColor(emotion),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _emotionColor(emotion).withAlpha((255 * 0.8).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Color _emotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return const Color(0xFF43E97B); // Mint Green
      case 'alert':
        return const Color(0xFFFFA726); // Amber
      case 'relaxed':
      case 'relax':
        return const Color(0xFF7E8CE0); // Blue Violet
      case 'frown':
        return const Color(0xFFB0B0B0); // Soft Gray
      case 'angry':
        return const Color(0xFFF95F62); // Coral Red
      default:
        return const Color(0xFF6E6E6E); // Neutral
    }
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
