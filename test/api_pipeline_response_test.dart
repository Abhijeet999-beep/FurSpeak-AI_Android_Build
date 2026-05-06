import 'package:flutter_test/flutter_test.dart';
import 'package:furspeak_ai/models/api_pipeline_response.dart';

void main() {
  group('ApiPipelineResponse.fromJson', () {
    test('parses a complete valid response', () {
      final json = {
        'status': 'success',
        'emotion': 'happy',
        'confidence': 95.5,
        'caption': 'Your dog looks happy!',
        'processing_time': 2.3,
        'timestamp': '2026-01-01T00:00:00Z',
        'timeline': [
          {'frame': 0, 'emotion': 'happy'},
          {'frame': 5, 'emotion': 'relaxed'},
        ],
        'timeline_summary': ['Started happy', 'Ended relaxed'],
        'frame_image_url': 'http://example.com/frame.jpg',
        'frame_image_path': '/tmp/frame.jpg',
      };

      final response = ApiPipelineResponse.fromJson(json);

      expect(response.status, 'success');
      expect(response.emotion, 'happy');
      expect(response.confidence, 95.5);
      expect(response.caption, 'Your dog looks happy!');
      expect(response.processingTime, 2.3);
      expect(response.timeline.length, 2);
      expect(response.timelineSummary.length, 2);
    });

    test('handles null emotion gracefully', () {
      final json = {
        'status': 'error',
        'emotion': null,
        'confidence': 0,
        'processing_time': 0,
        'timeline': [],
        'timeline_summary': [],
      };

      final response = ApiPipelineResponse.fromJson(json);
      expect(response.emotion, isNull);
      expect(response.confidence, 0.0);
    });

    test('handles integer confidence (backend type mismatch)', () {
      final json = {
        'confidence': 85,
        'processing_time': 3,
        'timeline': [],
        'timeline_summary': [],
      };

      final response = ApiPipelineResponse.fromJson(json);
      expect(response.confidence, 85.0);
      expect(response.confidence, isA<double>());
    });

    test('handles string confidence (defensive)', () {
      final json = {
        'confidence': '72.5',
        'processing_time': '1.5',
        'timeline': [],
        'timeline_summary': [],
      };

      final response = ApiPipelineResponse.fromJson(json);
      expect(response.confidence, 72.5);
      expect(response.processingTime, 1.5);
    });

    test('handles timeline_summary as a single string', () {
      final json = {
        'confidence': 0,
        'processing_time': 0,
        'timeline': [],
        'timeline_summary': 'Just one summary string',
      };

      final response = ApiPipelineResponse.fromJson(json);
      expect(response.timelineSummary, ['Just one summary string']);
    });

    test('handles missing fields with safe defaults', () {
      final json = <String, dynamic>{};

      final response = ApiPipelineResponse.fromJson(json);
      expect(response.status, 'success');
      expect(response.emotion, isNull);
      expect(response.confidence, 0.0);
      expect(response.processingTime, 0.0);
      expect(response.timeline, isEmpty);
      expect(response.timelineSummary, isEmpty);
      expect(response.isVideo, false);
    });

    test('withLocalMedia returns copy with local metadata', () {
      final original = ApiPipelineResponse.fromJson({
        'emotion': 'happy',
        'confidence': 90,
        'processing_time': 1,
        'timeline': [],
        'timeline_summary': [],
      });

      final withMedia = original.withLocalMedia(
        path: '/local/path/video.mp4',
        isVideo: true,
      );

      expect(withMedia.localMediaPath, '/local/path/video.mp4');
      expect(withMedia.isVideo, true);
      expect(withMedia.emotion, 'happy'); // Preserved
      expect(withMedia.confidence, 90.0); // Preserved
    });

    test('toMap round-trips correctly', () {
      final json = {
        'status': 'success',
        'emotion': 'sad',
        'confidence': 45.0,
        'caption': 'test caption',
        'processing_time': 1.5,
        'timestamp': '2026-01-01',
        'timeline': [],
        'timeline_summary': ['summary'],
      };

      final response = ApiPipelineResponse.fromJson(json);
      final map = response.toMap();

      expect(map['emotion'], 'sad');
      expect(map['confidence'], 45.0);
      expect(map['processing_time'], 1.5);
      expect(map['timeline_summary'], ['summary']);
    });
  });
}
