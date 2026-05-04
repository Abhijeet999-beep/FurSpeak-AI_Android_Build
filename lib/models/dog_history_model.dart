import 'package:cloud_firestore/cloud_firestore.dart';

class DogHistoryModel {
  final String id;
  final String emotion;
  final double confidence;
  final String caption;
  final String? suggestion;
  final String? mediaUrl;
  final DateTime timestamp;

  DogHistoryModel({
    required this.id,
    required this.emotion,
    required this.confidence,
    required this.caption,
    this.suggestion,
    this.mediaUrl,
    required this.timestamp,
  });

  factory DogHistoryModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DogHistoryModel(
      id: doc.id,
      emotion: data['emotion'] ?? 'Unknown',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      caption: data['caption'] ?? '',
      suggestion: data['suggestion'],
      mediaUrl: data['mediaUrl'],
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'caption': caption,
      'suggestion': suggestion,
      'mediaUrl': mediaUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
