class EmotionFrequency {
  final String emotion;
  final int count;

  EmotionFrequency(this.emotion, this.count);
}

class DailyScanCount {
  final DateTime date;
  final int count;

  DailyScanCount(this.date, this.count);
}

class TimePattern {
  final String label;
  final int count;

  TimePattern(this.label, this.count);
}

class WeeklyTrend {
  final String weekLabel;
  final Map<String, int> emotionCounts;

  WeeklyTrend(this.weekLabel, this.emotionCounts);
}

class TrendInsights {
  final List<EmotionFrequency> emotions;
  final List<DailyScanCount> daily;
  final List<TimePattern> timePatterns;
  final String summary;
  final String weeklySummary;
  final List<WeeklyTrend> weeklyTrends;
  final Map<String, dynamic> meta;

  TrendInsights({
    required this.emotions,
    required this.daily,
    required this.timePatterns,
    required this.summary,
    required this.weeklySummary,
    required this.weeklyTrends,
    this.meta = const {},
  });
}

enum InsightType {
  pattern,
  anomaly,
  consistency,
  shift
}

class BehaviorInsight {
  final InsightType type;
  final String title;
  final String description;
  final double confidence;
  final String relatedEmotion;

  BehaviorInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.relatedEmotion,
  });
}

class EnrichedAnalytics {
  final TrendInsights trends;
  final List<BehaviorInsight> intelligence;

  EnrichedAnalytics({
    required this.trends,
    required this.intelligence,
  });
}
