import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/behavior_insights.dart';
import '../data/models/detection_result.dart';
import '../data/models/analytics_models.dart';
import '../services/result_storage_service.dart';
import '../services/analytics_service.dart';

class HistoryController extends ChangeNotifier {
  final ResultStorageService _storageService;

  HistoryController(this._storageService);

  List<DetectionResult> results = [];
  BehaviorInsights? insights;
  EnrichedAnalytics? cachedAnalytics;
  TrendInsights? get cachedInsights => cachedAnalytics?.trends;
  List<FlSpot>? cachedDailySpots;
  String? _lastCacheKey;
  bool isLoading = true;
  String? error;

  Future<void> _updateAnalyticsCache() async {
    final allData = _storageService.getAllResults();
    if (allData.isEmpty) {
      cachedAnalytics = AnalyticsService.getEnrichedAnalytics([]);
      _lastCacheKey = "0_none";
      return;
    }

    final String currentKey = "${allData.length}_${allData.first.timestamp.millisecondsSinceEpoch}_${allData.last.timestamp.millisecondsSinceEpoch}";
    if (_lastCacheKey != currentKey) {
      if (allData.length >= 150) {
        cachedAnalytics = await compute(AnalyticsService.getEnrichedAnalytics, allData);
      } else {
        cachedAnalytics = AnalyticsService.getEnrichedAnalytics(allData);
      }
      
      if (cachedInsights != null) {
        final sortedDaily = List<DailyScanCount>.from(cachedInsights!.daily)
          ..sort((a, b) => a.date.compareTo(b.date));
        final displayData = sortedDaily.length > 7
            ? sortedDaily.sublist(sortedDaily.length - 7)
            : sortedDaily;
            
        cachedDailySpots = displayData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
        }).toList();
      }

      _lastCacheKey = currentKey;
      debugPrint('📈 [ANALYTICS] Cache busted. Computed TrendInsights for key: $currentKey');
    } else {
      debugPrint('📈 [ANALYTICS] Cache hit for key: $currentKey');
    }
  }

  Future<void> loadHistory() async {
    debugPrint('📜 [HISTORY] loadHistory() called');
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // 1. Compute Insights based on full data directly from service
      insights = _storageService.getInsights();
      
      // Compute TrendAnalytics Cache via O(N) service single pass
      await _updateAnalyticsCache();

      // 2. Fetch only latest 50 for UI memory limits (Pagination ready)
      results = _storageService.getResults(limit: 50, offset: 0);
      debugPrint('📜 [HISTORY] loadHistory() successful. Results: ${results.length}, Top Emotion: ${insights?.mostFrequentEmotion}');
    } catch (e) {
      error = "Failed to load history.";
      results = [];
      insights = BehaviorInsights.empty();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads history data without completely wiping state before fetch completes.
  Future<void> refresh() async {
    debugPrint('📜 [HISTORY] refresh() called');
    // Only difference is we do not want to set isLoading = true
    // because pull-to-refresh indicator will handle the spinner.
    try {
      final newInsights = _storageService.getInsights();
      await _updateAnalyticsCache();
      final newResults = _storageService.getResults(limit: 50, offset: 0);
      
      insights = newInsights;
      results = newResults;
      error = null;
      debugPrint('📜 [HISTORY] refresh() successful. Results: ${results.length}, Top Emotion: ${insights?.mostFrequentEmotion}');
    } catch (e) {
      error = "Failed to refresh history.";
    } finally {
      notifyListeners();
    }
  }
}
