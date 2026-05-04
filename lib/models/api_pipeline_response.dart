class ApiPipelineResponse {
  final String status;
  final String? emotion;
  final double confidence;
  final String? caption;
  final double processingTime;
  final String? timestamp;
  final Map<String, dynamic>? videoInfo;
  final String? frameImagePath;
  final String? frameImageUrl;
  final List<dynamic> timeline;
  final List<String> timelineSummary;

  // ── Client-side local metadata (NOT from API) ─────────────────────
  final String? localMediaPath;
  final bool isVideo;

  ApiPipelineResponse({
    required this.status,
    this.emotion,
    required this.confidence,
    this.caption,
    required this.processingTime,
    this.timestamp,
    this.videoInfo,
    this.frameImagePath,
    this.frameImageUrl,
    required this.timeline,
    required this.timelineSummary,
    this.localMediaPath,
    this.isVideo = false,
  });

  factory ApiPipelineResponse.fromJson(Map<String, dynamic> json) {
    // 1. Normalize timelineSummary
    List<String> safeTimelineSummary = [];
    final rawSummary = json['timeline_summary'];
    if (rawSummary != null) {
      if (rawSummary is String) {
        // If the backend returns a string but NO string splitting logic is allowed:
        // "If timeline is string -> wrap as SINGLE item list"
        safeTimelineSummary = [rawSummary];
      } else if (rawSummary is List) {
        // If it's a list, safely cast elements to strings
        safeTimelineSummary = rawSummary.map((e) => e.toString()).toList();
      }
    }

    // 2. Normalize standard list
    List<dynamic> safeTimeline = [];
    if (json['timeline'] is List) {
      safeTimeline = json['timeline'] as List;
    }

    // 3. Normalize confidence strictly to double
    double safeConfidence = 0.0;
    if (json['confidence'] != null) {
      if (json['confidence'] is int) {
        safeConfidence = (json['confidence'] as int).toDouble();
      } else if (json['confidence'] is double) {
        safeConfidence = json['confidence'] as double;
      } else {
        safeConfidence = double.tryParse(json['confidence'].toString()) ?? 0.0;
      }
    }

    // 4. Normalize processingTime
    double safeTime = 0.0;
    if (json['processing_time'] != null) {
      if (json['processing_time'] is int) {
        safeTime = (json['processing_time'] as int).toDouble();
      } else if (json['processing_time'] is double) {
        safeTime = json['processing_time'] as double;
      } else {
        safeTime = double.tryParse(json['processing_time'].toString()) ?? 0.0;
      }
    }

    return ApiPipelineResponse(
      status: json['status']?.toString() ?? 'success',
      emotion: json['emotion']?.toString(),
      confidence: safeConfidence,
      caption: json['caption']?.toString(),
      processingTime: safeTime,
      timestamp: json['timestamp']?.toString(),
      videoInfo: json['video_info'] is Map<String, dynamic> ? json['video_info'] : null,
      frameImagePath: json['frame_image_path']?.toString(),
      frameImageUrl: json['frame_image_url']?.toString(),
      timeline: safeTimeline,
      timelineSummary: safeTimelineSummary,
      localMediaPath: json['local_media_path']?.toString(),
      isVideo: json['is_video'] == true,
    );
  }

  /// Returns a copy with client-side local metadata attached.
  ApiPipelineResponse withLocalMedia({required String? path, required bool isVideo}) {
    return ApiPipelineResponse(
      status: status,
      emotion: emotion,
      confidence: confidence,
      caption: caption,
      processingTime: processingTime,
      timestamp: timestamp,
      videoInfo: videoInfo,
      frameImagePath: frameImagePath,
      frameImageUrl: frameImageUrl,
      timeline: timeline,
      timelineSummary: timelineSummary,
      localMediaPath: path,
      isVideo: isVideo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'emotion': emotion,
      'confidence': confidence,
      'caption': caption,
      'processing_time': processingTime,
      'timestamp': timestamp,
      'video_info': videoInfo,
      'frame_image_path': frameImagePath,
      'frame_image_url': frameImageUrl,
      'timeline': timeline,
      'timeline_summary': timelineSummary,
      'local_media_path': localMediaPath,
      'is_video': isVideo,
    };
  }
}
