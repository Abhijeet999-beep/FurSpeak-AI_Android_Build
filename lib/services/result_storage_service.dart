import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/detection_result.dart';
import '../data/models/behavior_insights.dart';
import '../models/pipeline_types.dart';

/// Thin Isar wrapper for DetectionResult persistence.
///
/// Rules:
///   - No UI logic
///   - No business logic (validation, transformation)
///   - CRUD only
///   - Write errors throw [PipelineException] so the controller
///     can set [PipelineStage.error] deterministically.
class ResultStorageService {
  final Isar _isar;

  ResultStorageService(this._isar);

  // ─── WRITE ─────────────────────────────────────────────────────────────

  /// Saves a [DetectionResult] to local storage.
  /// If a result with the same UUID already exists, it is updated.
  ///
  /// Throws [PipelineException] on Isar failure.
  Future<void> saveResult(DetectionResult result) async {
    debugPrint('💾 [STORAGE] Attempting to save result: ${result.uuid}');
    try {
      await _isar.writeTxn(() async {
        await _isar.detectionResults.put(result);
      });
      debugPrint('💾 [STORAGE] Successfully saved result: ${result.uuid}');
    } catch (e) {
      debugPrint('❌ [STORAGE] Failed to save result: $e');
      throw const PipelineException(
        message: 'Failed to save analysis result locally. Please try again.',
        stage: PipelineStage.saving,
      );
    }
  }

  // ─── READ ──────────────────────────────────────────────────────────────

  /// Fetches a single result by its UUID.
  /// Returns null if not found.
  DetectionResult? getResultById(String uuid) {
    return _isar.detectionResults
        .filter()
        .uuidEqualTo(uuid)
        .findFirstSync();
  }

  /// Returns all results, sorted by timestamp descending (newest first).
  /// Ready for the History feature.
  List<DetectionResult> getAllResults() {
    return _isar.detectionResults
        .where()
        .sortByTimestampDesc()
        .findAllSync();
  }

  /// Pagination-ready fetch for Results. 
  /// Offset based, sorted newest first.
  List<DetectionResult> getResults({int limit = 50, int offset = 0}) {
    debugPrint('📜 [STORAGE] Fetching history (limit: $limit, offset: $offset)');
    final results = _isar.detectionResults
        .where()
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAllSync();
    debugPrint('📜 [STORAGE] History loaded: ${results.length} items');
    return results;
  }

  /// Computes overarching Behavior Insights from local data.
  BehaviorInsights getInsights() {
    final allResults = getAllResults();
    debugPrint('📊 [STORAGE] Computing insights from ${allResults.length} records...');
    
    if (allResults.isEmpty) {
      return BehaviorInsights.empty();
    }

    final total = allResults.length;
    final latestTime = allResults.first.timestamp;

    final emotionCounts = <String, int>{};
    final firstSeenIndex = <String, int>{};

    for (int i = 0; i < allResults.length; i++) {
      final emotion = allResults[i].emotion;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      
      // Store the index of its first (most recent) appearance 
      firstSeenIndex.putIfAbsent(emotion, () => i);
    }

    String mostFrequent = "None";
    int maxCount = 0;

    emotionCounts.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequent = emotion;
      } else if (count == maxCount) {
        // Tie breaker: pick the one that appeared more recently (lower index)
        if (firstSeenIndex[emotion]! < (firstSeenIndex[mostFrequent] ?? 999999)) {
          mostFrequent = emotion;
        }
      }
    });

    debugPrint('📊 [STORAGE] Insights computed: $total records evaluated. Top emotion: $mostFrequent');

    return BehaviorInsights(
      totalScans: total,
      mostFrequentEmotion: mostFrequent,
      lastScanTime: latestTime,
      emotionDistribution: emotionCounts,
    );
  }

  // ─── DELETE ────────────────────────────────────────────────────────────

  /// Deletes a result by its UUID.
  /// Also deletes the associated physical media files if they are temp-owned (cached).
  Future<void> deleteResult(String uuid) async {
    final result = getResultById(uuid);
    if (result == null) return;

    // Delete associated physical media files ONLY if app-owned (in temp cache)
    _deleteFileIfTempOwned(result.mediaPath);
    _deleteFileIfTempOwned(result.frameImagePath);

    await _isar.writeTxn(() async {
      await _isar.detectionResults.filter().uuidEqualTo(uuid).deleteAll();
    });
    debugPrint('🗑️ [STORAGE] Deleted result: $uuid');
  }

  void _deleteFileIfTempOwned(String? path) {
    if (path == null) return;
    
    getTemporaryDirectory().then((tempDir) {
      if (path.startsWith(tempDir.path)) {
        try {
          final file = File(path);
          if (file.existsSync()) {
            file.deleteSync();
            debugPrint('🗑️ [STORAGE] Deleted temp-owned file: $path');
          }
        } catch (_) {}
      }
    }).catchError((_) {});
  }
}

