class BehaviorInsights {
  final int totalScans;
  final String mostFrequentEmotion;
  final DateTime? lastScanTime;
  final Map<String, int> emotionDistribution;

  BehaviorInsights({
    required this.totalScans,
    required this.mostFrequentEmotion,
    this.lastScanTime,
    this.emotionDistribution = const {},
  });

  /// Returns an empty insights object if there's no history.
  factory BehaviorInsights.empty() {
    return BehaviorInsights(
      totalScans: 0,
      mostFrequentEmotion: 'None yet',
      lastScanTime: null,
      emotionDistribution: {},
    );
  }
}
