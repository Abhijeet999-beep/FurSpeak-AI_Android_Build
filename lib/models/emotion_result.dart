class EmotionResult {
  final String emotion;
  final double confidence;
  final String caption;
  final String imagePath;
  final String? videoPath;
  final String? frameImagePath;
  final String? frameImageUrl;
  final Map<String, String>? timelineSummary;

  const EmotionResult({
    required this.emotion,
    required this.confidence,
    required this.caption,
    required this.imagePath,
    this.videoPath,
    this.frameImagePath,
    this.frameImageUrl,
    this.timelineSummary,
  });

  factory EmotionResult.fromJson(Map<String, dynamic> json) {
    return EmotionResult(
      emotion: json['emotion'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      caption: json['caption'] as String,
      imagePath: json['imagePath'] as String,
      videoPath: json['videoPath'] as String?,
      frameImagePath: json['frameImagePath'] as String?,
      frameImageUrl: json['frameImageUrl'] as String?,
      timelineSummary: json['timelineSummary'] != null
          ? Map<String, String>.from(json['timelineSummary'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'caption': caption,
      'imagePath': imagePath,
      'videoPath': videoPath,
      'frameImagePath': frameImagePath,
      'frameImageUrl': frameImageUrl,
      'timelineSummary': timelineSummary,
    };
  }
}
