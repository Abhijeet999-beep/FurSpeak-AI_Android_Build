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
    // 0. Robust Unwrapping Logic
    // Handles: BaseResponse (production), JobStatusResponse (polling), and results (mock)
    Map<String, dynamic> data = json;

    // Check for BaseResponse wrapper (FastAPI production style: {success: bool, data: Map, message: string})
    if (json.containsKey('success') && json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    }

    // Check for JobStatusResponse wrapper (FastAPI polling style: {job_id: string, status: string, result: Map})
    // OR Mock server results wrapper: {status: string, request_id: string, results: Map}
    final nestedResult = data['result'] ?? data['results'];
    if (nestedResult != null && nestedResult is Map<String, dynamic>) {
      final outerStatus = data['status']?.toString();
      data = Map<String, dynamic>.from(nestedResult);
      // If nested data doesn't have status, inherit from outer wrapper
      if (!data.containsKey('status') && outerStatus != null) {
        data['status'] = outerStatus;
      }
    }

    // 1. Normalize timelineSummary / suggestions / recommendations
    List<String> safeTimelineSummary = [];
    final rawSummary = data['timeline_summary'] ?? 
                      data['suggestion'] ?? 
                      data['suggestions'] ?? 
                      data['recommendations'];
    if (rawSummary != null) {
      if (rawSummary is String) {
        safeTimelineSummary = [rawSummary];
      } else if (rawSummary is List) {
        safeTimelineSummary = rawSummary.map((e) => e.toString()).toList();
      }
    }

    // 2. Normalize standard list
    List<dynamic> safeTimeline = [];
    if (data['timeline'] is List) {
      safeTimeline = data['timeline'] as List;
    }

    // 3. Normalize confidence strictly to double and handle 0-1 vs 0-100 scaling
    double safeConfidence = 0.0;
    final rawConfidence = data['confidence'];
    if (rawConfidence != null) {
      if (rawConfidence is num) {
        safeConfidence = rawConfidence.toDouble();
      } else {
        safeConfidence = double.tryParse(rawConfidence.toString()) ?? 0.0;
      }
      
      // Auto-normalization: If the value is in 0-1 range (and not exactly 0 or 1), 
      // assume it's a float probability and convert to percentage.
      if (safeConfidence > 0 && safeConfidence <= 1.0) {
        safeConfidence *= 100.0;
      }
    }

    // 4. Normalize processingTime
    double safeTime = 0.0;
    final rawTime = data['processing_time'];
    if (rawTime != null) {
      if (rawTime is num) {
        safeTime = rawTime.toDouble();
      } else {
        safeTime = double.tryParse(rawTime.toString()) ?? 0.0;
      }
    }

    // 5. Final Assembly with field name fallbacks (summary -> caption, thumbnail_url -> frame_image_url)
    return ApiPipelineResponse(
      status: data['status']?.toString() ?? (json['success'] == true ? 'success' : 'error'),
      emotion: data['emotion']?.toString() ?? 'unknown',
      confidence: safeConfidence,
      caption: (data['caption'] ?? data['summary'] ?? data['description'])?.toString() ?? '',
      processingTime: safeTime,
      timestamp: data['timestamp']?.toString(),
      videoInfo: data['video_info'] is Map<String, dynamic> ? data['video_info'] : null,
      frameImagePath: data['frame_image_path']?.toString(),
      frameImageUrl: (data['frame_image_url'] ?? data['thumbnail_url'])?.toString(),
      timeline: safeTimeline,
      timelineSummary: safeTimelineSummary,
      localMediaPath: data['local_media_path']?.toString(),
      isVideo: data['is_video'] == true,
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
