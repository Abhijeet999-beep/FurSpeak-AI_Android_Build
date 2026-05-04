import 'dart:math';

import '../data/models/analytics_models.dart';
import '../data/models/detection_result.dart';

class AnalyticsService {
  static EnrichedAnalytics getEnrichedAnalytics(List<DetectionResult> results) {
    final trends = getTrendInsights(results);
    final intelligence = _generateIntelligence(results, trends);
    return EnrichedAnalytics(trends: trends, intelligence: intelligence);
  }

  static TrendInsights getTrendInsights(List<DetectionResult> results) {
    if (results.isEmpty) {
      return TrendInsights(
        emotions: [],
        daily: [],
        timePatterns: [],
        summary: "Not enough data to detect patterns yet.",
        weeklySummary: "",
        weeklyTrends: [],
      );
    }

    final Map<String, int> emotionMap = {};
    final Map<String, int> dailyMap = {};
    
    final Map<String, int> thisWeekEmotions = {};
    final Map<String, int> lastWeekEmotions = {};

    final DateTime now = DateTime.now();
    final DateTime currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final DateTime previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));

    int morning = 0;
    int afternoon = 0;
    int evening = 0;
    int night = 0;

    // Single Pass Computation (O(N))
    for (final result in results) {
      // 1. Normalize Emotion
      final emotion = result.emotion.trim().toLowerCase();
      emotionMap[emotion] = (emotionMap[emotion] ?? 0) + 1;

      // 2. Normalize Timestamp to Local Date
      final localTime = result.timestamp.toLocal();
      final localDate = DateTime(localTime.year, localTime.month, localTime.day);
      
      if (!localDate.isBefore(currentWeekStart)) {
        thisWeekEmotions[emotion] = (thisWeekEmotions[emotion] ?? 0) + 1;
      } else if (!localDate.isBefore(previousWeekStart)) {
        lastWeekEmotions[emotion] = (lastWeekEmotions[emotion] ?? 0) + 1;
      }

      // Fast path for grouping date (YYYY-MM-DD string key)
      final dateStr = '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}';
      dailyMap[dateStr] = (dailyMap[dateStr] ?? 0) + 1;

      // 3. Time Buckets (Morning 5-11, Afternoon 12-16, Evening 17-20, Night 21-4)
      final hour = localTime.hour;
      if (hour >= 5 && hour < 12) {
        morning++;
      } else if (hour >= 12 && hour < 17) {
        afternoon++;
      } else if (hour >= 17 && hour < 21) {
        evening++;
      } else {
        night++;
      }
    }

    // Sorting emotions (Descending)
    final emotionEntries = emotionMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final emotionsList = emotionEntries
        .map((e) => EmotionFrequency(e.key, e.value))
        .toList();

    // Sorting daily trends (Ascending)
    final dailyEntries = dailyMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final dailyList = dailyEntries
        .map((e) => DailyScanCount(DateTime.parse(e.key), e.value))
        .toList();

    // Sorting time patterns (Descending)
    final List<TimePattern> timePatterns = [
      if (morning > 0) TimePattern("Morning", morning),
      if (afternoon > 0) TimePattern("Afternoon", afternoon),
      if (evening > 0) TimePattern("Evening", evening),
      if (night > 0) TimePattern("Night", night),
    ]..sort((a, b) => b.count.compareTo(a.count)); 

    if (results.length < 3) {
      return TrendInsights(
        emotions: emotionsList,
        daily: dailyList,
        timePatterns: timePatterns,
        summary: "Not enough data to detect patterns yet.",
        weeklySummary: "Keep scanning to discover next week's trend 🐾",
        weeklyTrends: [
          WeeklyTrend("This Week", thisWeekEmotions),
          WeeklyTrend("Last Week", lastWeekEmotions),
        ],
      );
    }

    // Summary Generation
    final total = results.length;
    final topEmotion = emotionsList.first;
    final domEmotionNormalized = _capitalizeFirst(topEmotion.emotion);
    
    String summary = "";
    final random = Random();
    
    if (topEmotion.count > (total * 0.5)) {
      final templates = [
        "Your dog has been mostly $domEmotionNormalized recently \uD83D\uDC3E",
        "We're seeing a lot of $domEmotionNormalized behavior lately \uD83D\uDC3E",
        "$domEmotionNormalized seems to be your dog's most common mood recently \uD83D\uDC3E",
      ];
      summary = templates[random.nextInt(templates.length)];
    } else {
      final templates = [
        "Your dog seems to have mixed emotions recently \uD83D\uDC3E",
        "We're seeing a diverse range of moods lately \uD83D\uDC3E",
        "No single emotion dominates your dog's recent scans \uD83D\uDC3E",
      ];
      summary = templates[random.nextInt(templates.length)];
    }

    if (timePatterns.isNotEmpty) {
      final topTime = timePatterns.first;
      // Margin of dominance: At least 40% of all scans, AND cleanly greater than the 2nd most active slot.
      bool clearlyDominant = topTime.count > (total * 0.4);
      if (timePatterns.length > 1) {
        clearlyDominant = clearlyDominant && (topTime.count >= timePatterns[1].count * 1.5);
      }

      if (clearlyDominant) { 
        // Small tweak to map string representation clearly
        String timeIcon = "\uD83C\uDF06";
        if (topTime.label == "Morning") timeIcon = "\uD83C\uDF04";
        if (topTime.label == "Afternoon") timeIcon = "\u2600\uFE0F";
        if (topTime.label == "Night") timeIcon = "\uD83C\uDF19";

        summary += "\nand seems more active in the ${topTime.label.toLowerCase()}s $timeIcon";
      }
    }

    // Weekly Generation
    int thisWeekTotal = thisWeekEmotions.values.fold(0, (sum, val) => sum + val);
    int lastWeekTotal = lastWeekEmotions.values.fold(0, (sum, val) => sum + val);

    String topThisWeek = "";
    int maxThisWeek = 0;
    thisWeekEmotions.forEach((key, val) {
      if (val > maxThisWeek) {
        maxThisWeek = val;
        topThisWeek = key;
      }
    });

    String topLastWeek = "";
    int maxLastWeek = 0;
    lastWeekEmotions.forEach((key, val) {
      if (val > maxLastWeek) {
        maxLastWeek = val;
        topLastWeek = key;
      }
    });

    String weeklySummary = "Keep scanning to discover next week's trend 🐾";
    if (thisWeekTotal >= 3 || lastWeekTotal >= 3) {
      if (lastWeekTotal > 0 && thisWeekTotal > lastWeekTotal * 1.5 && thisWeekTotal >= 3) {
        weeklySummary = "Activity increased this week 📈";
      } else if (topThisWeek.isNotEmpty && topThisWeek == "happy" && topLastWeek != "happy" && maxThisWeek >= 2) {
        weeklySummary = "Your dog has been happier this week compared to last 🐾";
      } else if (topThisWeek.isNotEmpty && topThisWeek == "relaxed" && topLastWeek != "relaxed" && maxThisWeek >= 2) {
         weeklySummary = "Your dog seems more relaxed recently 🌿";
      } else if (topThisWeek.isNotEmpty && topThisWeek == topLastWeek && maxThisWeek >= 2) {
         weeklySummary = "Consistent behavior. Your dog remains mostly ${_capitalizeFirst(topThisWeek)}.";
      } else if (topThisWeek.isNotEmpty && maxThisWeek >= 2) {
         weeklySummary = "Most common mood this week: ${_capitalizeFirst(topThisWeek)}";
      }
    }

    final List<WeeklyTrend> weeklyTrends = [
      WeeklyTrend("This Week", thisWeekEmotions),
      WeeklyTrend("Last Week", lastWeekEmotions),
    ];

    return TrendInsights(
      emotions: emotionsList,
      daily: dailyList,
      timePatterns: timePatterns,
      summary: summary,
      weeklySummary: weeklySummary,
      weeklyTrends: weeklyTrends,
      meta: {
        'totalScansProcessed': total,
        'computedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static List<BehaviorInsight> _generateIntelligence(List<DetectionResult> results, TrendInsights trends) {
    if (results.isEmpty || trends.emotions.isEmpty) return [];

    final totalScans = results.length;
    final List<BehaviorInsight> insights = [];

    // 1. Consistency Detection
    final topEmotion = trends.emotions.first;
    if (topEmotion.count >= (totalScans * 0.7) && totalScans >= 5) {
      insights.add(BehaviorInsight(
        type: InsightType.consistency,
        title: "Highly Consistent Mood",
        description: "Your dog has been very consistently ${_capitalizeFirst(topEmotion.emotion)} recently.",
        confidence: (topEmotion.count / totalScans).clamp(0.0, 1.0),
        relatedEmotion: topEmotion.emotion,
      ));
    }

    // 2. Behavior Shift Detection (Week over Week)
    if (trends.weeklyTrends.length == 2) {
      final thisWeek = trends.weeklyTrends.firstWhere((w) => w.weekLabel == "This Week", orElse: () => WeeklyTrend("", {}));
      final lastWeek = trends.weeklyTrends.firstWhere((w) => w.weekLabel == "Last Week", orElse: () => WeeklyTrend("", {}));
      
      final thisWeekTotal = thisWeek.emotionCounts.values.fold(0, (sum, val) => sum + val);
      final lastWeekTotal = lastWeek.emotionCounts.values.fold(0, (sum, val) => sum + val);

      if (thisWeekTotal >= 3 && lastWeekTotal >= 3) {
        String topThisWeek = "";
        int maxThisWeek = 0;
        thisWeek.emotionCounts.forEach((k, v) { if (v > maxThisWeek) { maxThisWeek = v; topThisWeek = k; } });

        String topLastWeek = "";
        int maxLastWeek = 0;
        lastWeek.emotionCounts.forEach((k, v) { if (v > maxLastWeek) { maxLastWeek = v; topLastWeek = k; } });

        if (topThisWeek.isNotEmpty && topLastWeek.isNotEmpty && topThisWeek != topLastWeek && maxThisWeek >= (thisWeekTotal * 0.5)) {
          insights.add(BehaviorInsight(
            type: InsightType.shift,
            title: "Behavior Shift",
            description: "Shifted from mostly ${_capitalizeFirst(topLastWeek)} last week to ${_capitalizeFirst(topThisWeek)} this week.",
            confidence: 0.85, 
            relatedEmotion: topThisWeek,
          ));
        }
      }
    }

    // 3. Anomaly Detection (Sudden Spikes)
    if (trends.daily.length >= 3) {
      final avgScans = totalScans / trends.daily.length;
      final sortedDaily = List<DailyScanCount>.from(trends.daily)..sort((a,b) => b.date.compareTo(a.date));
      final lastDay = sortedDaily.first;

      if (lastDay.count > (avgScans * 2.5) && lastDay.count >= 3) {
        // Need to find what emotion caused the spike. Just grab dominant from results on that day
        final lastDayDateStr = '${lastDay.date.year}-${lastDay.date.month.toString().padLeft(2, '0')}-${lastDay.date.day.toString().padLeft(2, '0')}';
        // But doing O(N) over results here is fine since we do it once
        final spikeMap = <String, int>{};
        for (var r in results) {
          final lDate = r.timestamp.toLocal();
          if (lDate.year == lastDay.date.year && lDate.month == lastDay.date.month && lDate.day == lastDay.date.day) {
             final em = r.emotion.trim().toLowerCase();
             spikeMap[em] = (spikeMap[em] ?? 0) + 1;
          }
        }
        
        String spikeEmotion = "";
        int maxSpike = 0;
        spikeMap.forEach((k,v) { if (v > maxSpike) { maxSpike = v; spikeEmotion = k; } });

        insights.add(BehaviorInsight(
          type: InsightType.anomaly,
          title: "Activity Spike Detected",
          description: "Unusual burst of activity recently, strongly marked by ${_capitalizeFirst(spikeEmotion)} behavior.",
          confidence: 0.9,
          relatedEmotion: spikeEmotion,
        ));
      }
    }

    // 4. Pattern Detection (Time of Day Patterns)
    if (trends.timePatterns.isNotEmpty) {
      final topTime = trends.timePatterns.first;
      if (topTime.count > (totalScans * 0.45) && topTime.count >= 4) {
        insights.add(BehaviorInsight(
          type: InsightType.pattern,
          title: "Time Routine",
          description: "Your dog shows distinct patterns of being active primarily during the ${topTime.label}.",
          confidence: 0.8,
          relatedEmotion: topEmotion.emotion, 
        ));
      }
    }

    // 5. Filter & Deduplicate
    final filtered = insights.where((i) => i.confidence >= 0.6).toList();
    filtered.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    final Map<String, BehaviorInsight> distinctMap = {};
    for (var insight in filtered) {
      final key = '${insight.type}_${insight.relatedEmotion}';
      if (!distinctMap.containsKey(key)) {
        distinctMap[key] = insight;
      }
    }

    final topInsights = distinctMap.values.take(3).toList();
    return topInsights;
  }
}
