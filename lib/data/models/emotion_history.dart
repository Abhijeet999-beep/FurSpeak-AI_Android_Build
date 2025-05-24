import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'emotion_history.g.dart';

@Collection()
@JsonSerializable()
class EmotionHistory {
  Id id = Isar.autoIncrement;

  @Index()
  final String userId;

  final String emotion;
  final double confidence;
  final String caption;
  final String? imageUrl;
  final String? videoUrl;
  final String? frameImagePath;
  final String? frameImageUrl;
  final DateTime timestamp;
  final bool isSynced;

  EmotionHistory({
    required this.userId,
    required this.emotion,
    required this.confidence,
    required this.caption,
    this.imageUrl,
    this.videoUrl,
    this.frameImagePath,
    this.frameImageUrl,
    required this.timestamp,
    this.isSynced = false,
  });

  factory EmotionHistory.fromJson(Map<String, dynamic> json) =>
      _$EmotionHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$EmotionHistoryToJson(this);

  EmotionHistory copyWith({
    String? emotion,
    double? confidence,
    String? caption,
    String? imageUrl,
    String? videoUrl,
    String? frameImagePath,
    String? frameImageUrl,
    bool? isSynced,
  }) {
    return EmotionHistory(
      userId: userId,
      emotion: emotion ?? this.emotion,
      confidence: confidence ?? this.confidence,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      frameImagePath: frameImagePath ?? this.frameImagePath,
      frameImageUrl: frameImageUrl ?? this.frameImageUrl,
      timestamp: timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
