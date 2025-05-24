// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmotionResponse _$EmotionResponseFromJson(Map<String, dynamic> json) =>
    EmotionResponse(
      imagePath: json['imagePath'] as String?,
      emotion: json['emotion'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      caption: json['caption'] as String,
      processingTime: (json['processing_time'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      videoInfo: json['video_info'] as Map<String, dynamic>?,
      timelineSummary: json['timeline_summary'] as String?,
      frameImagePath: json['frame_image_path'] as String?,
      frameImageUrl: json['frame_image_url'] as String?,
    );

Map<String, dynamic> _$EmotionResponseToJson(EmotionResponse instance) =>
    <String, dynamic>{
      'imagePath': instance.imagePath,
      'emotion': instance.emotion,
      'confidence': instance.confidence,
      'caption': instance.caption,
      'processing_time': instance.processingTime,
      'timestamp': instance.timestamp,
      'video_info': instance.videoInfo,
      'timeline_summary': instance.timelineSummary,
      'frame_image_path': instance.frameImagePath,
      'frame_image_url': instance.frameImageUrl,
    };

VideoInfo _$VideoInfoFromJson(Map<String, dynamic> json) => VideoInfo(
      originalDuration: (json['original_duration'] as num).toDouble(),
      processedDuration: (json['processed_duration'] as num).toDouble(),
      wasTrimmed: json['was_trimmed'] as bool,
      processingMessage: json['processing_message'] as String?,
    );

Map<String, dynamic> _$VideoInfoToJson(VideoInfo instance) => <String, dynamic>{
      'original_duration': instance.originalDuration,
      'processed_duration': instance.processedDuration,
      'was_trimmed': instance.wasTrimmed,
      'processing_message': instance.processingMessage,
    };
