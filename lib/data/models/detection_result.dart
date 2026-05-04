import 'dart:convert';
import 'package:isar/isar.dart';

part 'detection_result.g.dart';

/// Persistent detection result stored locally via Isar.
/// This is the single source of truth for the /result screen and History feature.
///
/// Navigation uses the [uuid] field as query parameter: `/result?id=<uuid>`
@Collection()
class DetectionResult {
  Id isarId = Isar.autoIncrement;

  /// Unique identifier for this result (UUIDv4). Used as the route query param.
  @Index(unique: true)
  late String uuid;

  /// When this result was created.
  late DateTime timestamp;

  /// Detected emotion label (e.g. "happy", "sad", "angry").
  late String emotion;

  /// Confidence score (0.0 – 100.0).
  late double confidence;

  /// AI-generated caption describing the detection.
  late String caption;

  /// Actionable suggestions for the pet owner.
  late List<String> suggestions;

  /// Local file path to the source media.
  late String mediaPath;

  /// Source type: "image" or "video".
  late String sourceType;

  /// Processing time in seconds from the API response.
  late double processingTime;

  /// API response status (e.g. "success").
  late String status;

  /// Frame image path (local server path from API).
  String? frameImagePath;

  /// Frame image URL (network URL from API).
  String? frameImageUrl;

  /// Serialized timeline data as JSON string.
  /// Isar does not support List<Map>, so we serialize.
  String? timelineJson;

  /// Serialized timeline summary as JSON string.
  String? timelineSummaryJson;

  // ─── JSON Serialization ──────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'timestamp': timestamp.toIso8601String(),
      'emotion': emotion,
      'confidence': confidence,
      'caption': caption,
      'suggestions': suggestions,
      'media_path': mediaPath,
      'source_type': sourceType,
      'processing_time': processingTime,
      'status': status,
      'frame_image_path': frameImagePath,
      'frame_image_url': frameImageUrl,
      'timeline': timelineJson,
      'timeline_summary': timelineSummaryJson,
    };
  }

  static DetectionResult fromJson(Map<String, dynamic> json) {
    return DetectionResult()
      ..uuid = json['uuid'] as String
      ..timestamp = DateTime.parse(json['timestamp'] as String)
      ..emotion = json['emotion'] as String
      ..confidence = (json['confidence'] as num).toDouble()
      ..caption = json['caption'] as String
      ..suggestions = List<String>.from(json['suggestions'] as List)
      ..mediaPath = json['media_path'] as String
      ..sourceType = json['source_type'] as String
      ..processingTime = (json['processing_time'] as num).toDouble()
      ..status = json['status'] as String
      ..frameImagePath = json['frame_image_path'] as String?
      ..frameImageUrl = json['frame_image_url'] as String?
      ..timelineJson = json['timeline'] as String?
      ..timelineSummaryJson = json['timeline_summary'] as String?;
  }

  // ─── Convenience Accessors ───────────────────────────────────────────

  /// Deserialize timeline from JSON string.
  @ignore
  List<dynamic> get timeline {
    if (timelineJson == null || timelineJson!.isEmpty) return [];
    try {
      return jsonDecode(timelineJson!) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  /// Deserialize timeline summary from JSON string.
  @ignore
  List<String> get timelineSummary {
    if (timelineSummaryJson == null || timelineSummaryJson!.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(timelineSummaryJson!) as List);
    } catch (_) {
      return [];
    }
  }

  /// Whether this result is from a video source.
  @ignore
  bool get isVideo => sourceType == 'video';
}
