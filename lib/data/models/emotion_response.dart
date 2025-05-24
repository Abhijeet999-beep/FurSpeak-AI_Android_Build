import 'package:json_annotation/json_annotation.dart';

part 'emotion_response.g.dart';

@JsonSerializable()
class EmotionResponse {
  final String? imagePath;
  final String emotion;
  final double confidence;
  final String caption;
  @JsonKey(name: 'processing_time')
  final double processingTime;
  final String timestamp;
  @JsonKey(name: 'video_info')
  final Map<String, dynamic>? videoInfo;
  @JsonKey(name: 'timeline_summary')
  final String? timelineSummary;
  @JsonKey(name: 'frame_image_path')
  final String? frameImagePath;
  @JsonKey(name: 'frame_image_url')
  final String? frameImageUrl;

  EmotionResponse({
    this.imagePath,
    required this.emotion,
    required this.confidence,
    required this.caption,
    required this.processingTime,
    required this.timestamp,
    this.videoInfo,
    this.timelineSummary,
    this.frameImagePath,
    this.frameImageUrl,
  });

  factory EmotionResponse.fromJson(Map<String, dynamic> json) =>
      _$EmotionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EmotionResponseToJson(this);
}

@JsonSerializable()
class VideoInfo {
  @JsonKey(name: 'original_duration')
  final double originalDuration;
  @JsonKey(name: 'processed_duration')
  final double processedDuration;
  @JsonKey(name: 'was_trimmed')
  final bool wasTrimmed;
  @JsonKey(name: 'processing_message')
  final String? processingMessage;

  VideoInfo({
    required this.originalDuration,
    required this.processedDuration,
    required this.wasTrimmed,
    this.processingMessage,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VideoInfoToJson(this);
}
