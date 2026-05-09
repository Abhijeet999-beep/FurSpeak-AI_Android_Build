import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/history_controller.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../data/models/detection_result.dart';
import '../../data/models/behavior_insights.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/weekly_trend_card.dart';
import '../widgets/emotion_distribution_chart.dart';
import '../widgets/daily_activity_chart.dart';
import '../widgets/insight_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text('History & Insights', style: AppTheme.titleStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<HistoryController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return _buildShimmerLoading();
          }

          if (controller.error != null) {
            return _buildErrorState(context, controller);
          }

          if (controller.results.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildInsightsHeader(controller),
                ),
                if (controller.cachedAnalytics?.intelligence != null && controller.cachedAnalytics!.intelligence.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final insight = controller.cachedAnalytics!.intelligence[index];
                          return PetMoodGlass(
                            color: AppTheme.surfaceActive,
                            opacity: 0.4,
                            borderRadius: AppTheme.borderRadiusLarge,
                            child: InsightCard(insight: insight),
                          );
                        },
                        childCount: controller.cachedAnalytics!.intelligence.length,
                      ),
                    ),
                  ),
                ],
                if (controller.cachedInsights != null) ...[
                  SliverToBoxAdapter(
                    child: WeeklyTrendCard(insights: controller.cachedInsights!),
                  ),
                  SliverToBoxAdapter(
                    child: EmotionDistributionChart(insights: controller.cachedInsights!),
                  ),
                  SliverToBoxAdapter(
                    child: DailyActivityChart(
                      insights: controller.cachedInsights!,
                      cachedSpots: controller.cachedDailySpots ?? [],
                    ),
                  ),
                ],
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final result = controller.results[index];
                        return RepaintBoundary(
                          child: _HistoryItemCard(result: result),
                        );
                      },
                      childCount: controller.results.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── SHIMMER LOADING ────────────────────────────────────────────────
  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surfaceElevated,
        highlightColor: AppTheme.surfaceBase,
        child: Column(
          children: List.generate(4, (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space12),
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radiusMedium),
                        bottomLeft: Radius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(height: 14, width: 80, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 10, width: 120, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }

  // ─── INSIGHTS HEADER ────────────────────────────────────────────────
  Widget _buildInsightsHeader(HistoryController controller) {
    final insights = controller.insights;
    if (insights == null || insights.totalScans == 0) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: PetMoodGlass(
        color: AppTheme.surfaceActive,
        opacity: 0.7,
        borderRadius: AppTheme.borderRadiusExtraLarge,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                    child: const Icon(Icons.insights_rounded, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Text(
                    'Behavior Insights',
                    style: AppTheme.titleStyle.copyWith(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLow.withOpacity(0.5),
                  borderRadius: AppTheme.borderRadiusLarge,
                ),
                child: Text(
                  'Scan more videos to unlock behavioral insights.\nWe need a bit more data to analyze your dog\'s mood patterns.',
                  textAlign: TextAlign.center,
                  style: AppTheme.captionStyle.copyWith(color: AppTheme.textLightColor, height: 1.5, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    }

    final topEmotion = EmotionStyle.fromEmotion(insights.mostFrequentEmotion);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: PetMoodGlass(
        color: topEmotion.color,
        opacity: 0.05,
        borderRadius: AppTheme.borderRadiusExtraLarge,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: topEmotion.color.withOpacity(0.1), width: 1.5),
            borderRadius: AppTheme.borderRadiusExtraLarge,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: topEmotion.color.withOpacity(0.1),
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                    child: Icon(Icons.insights_rounded, color: topEmotion.color, size: 24),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Text(
                    'Behavior Insights',
                    style: AppTheme.titleStyle.copyWith(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: topEmotion.color.withOpacity(0.08),
                  borderRadius: AppTheme.borderRadiusLarge,
                ),
                child: Text(
                  controller.cachedInsights?.summary ?? 'Your dog has been mostly ${topEmotion.label} recently🐾',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 14,
                    color: topEmotion.color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Row(
                children: [
                  Expanded(
                    child: _InsightStatCard(
                      icon: Icons.analytics_outlined,
                      value: insights.totalScans.toString(),
                      label: 'Total Scans',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: _InsightStatCard(
                      icon: topEmotion.icon,
                      value: topEmotion.label,
                      label: 'Most Frequent',
                      color: topEmotion.color,
                    ),
                  ),
                ],
              ),
              // Emotion distribution preview
              if (insights.emotionDistribution.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space16),
                _EmotionDistributionBar(distribution: insights.emotionDistribution),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets_rounded, size: 64,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'No scans yet — try your first analysis',
              textAlign: TextAlign.center,
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => context.goHome(),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Start Scanning'),
                style: AppTheme.primaryButtonStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ERROR STATE ────────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, HistoryController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.errorColor),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              controller.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppTheme.space24),
            ElevatedButton.icon(
              onPressed: () => controller.loadHistory(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: AppTheme.primaryButtonStyle.copyWith(
                backgroundColor: WidgetStateProperty.all(AppTheme.errorColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HISTORY ITEM CARD — Enhanced with emotion badge, relative time, confidence
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _HistoryItemCard extends StatelessWidget {
  final DetectionResult result;
  const _HistoryItemCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final emotionStyle = EmotionStyle.fromEmotion(result.emotion);
    final relativeTime = _formatRelativeTime(result.timestamp);

    return PetMoodGlass(
      color: AppTheme.surfaceActive,
      opacity: 0.5,
      borderRadius: AppTheme.borderRadiusLarge,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        decoration: BoxDecoration(
          border: Border.all(color: emotionStyle.color.withOpacity(0.1), width: 1),
          borderRadius: AppTheme.borderRadiusLarge,
        ),
        child: InkWell(
          borderRadius: AppTheme.borderRadiusLarge,
          onTap: () => context.pushResult(result.uuid),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Row(
              children: [
                // Thumbnail with emotion color border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.borderRadiusMedium,
                    border: Border.all(color: emotionStyle.color.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: emotionStyle.color.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: _buildThumbnail(result),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
  
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emotion badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: emotionStyle.color.withOpacity(0.12),
                          borderRadius: AppTheme.borderRadiusPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emotionStyle.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              emotionStyle.label,
                              style: AppTheme.captionStyle.copyWith(
                                fontSize: 12,
                                color: emotionStyle.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Relative timestamp
                      Text(
                        relativeTime,
                        style: AppTheme.captionStyle.copyWith(
                          fontSize: 12,
                          color: AppTheme.textLightColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
  
                // Confidence indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Circular confidence
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: result.confidence / 100,
                            strokeWidth: 3,
                            backgroundColor: emotionStyle.color.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(emotionStyle.color),
                          ),
                          Text(
                            '${result.confidence.toStringAsFixed(0)}',
                            style: AppTheme.captionStyle.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: emotionStyle.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '%',
                      style: AppTheme.captionStyle.copyWith(
                        fontSize: 9,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppTheme.space8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textLightColor.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(DetectionResult result) {
    if (!result.isVideo) {
      if (File(result.mediaPath).existsSync()) {
        return Image.file(
          File(result.mediaPath),
          fit: BoxFit.cover,
        );
      }
    } else {
      if (result.frameImagePath != null &&
          File(result.frameImagePath!).existsSync()) {
        return Image.file(
          File(result.frameImagePath!),
          fit: BoxFit.cover,
        );
      }
    }

    final emotionStyle = EmotionStyle.fromEmotion(result.emotion);
    return Container(
      color: emotionStyle.color.withOpacity(0.08),
      child: Center(
        child: Text(emotionStyle.emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// REUSABLE INSIGHT STAT CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _InsightStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InsightStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppTheme.space8),
          Text(
            value,
            style: AppTheme.titleStyle.copyWith(
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.captionStyle.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EMOTION DISTRIBUTION BAR (compact visualization)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _EmotionDistributionBar extends StatelessWidget {
  final Map<String, int> distribution;
  const _EmotionDistributionBar({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    // Sort by count descending
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stacked bar
        ClipRRect(
          borderRadius: AppTheme.borderRadiusPill,
          child: SizedBox(
            height: 8,
            child: Row(
              children: sorted.map((entry) {
                final ratio = entry.value / total;
                final style = EmotionStyle.fromEmotion(entry.key);
                return Expanded(
                  flex: (ratio * 100).round().clamp(1, 100),
                  child: Container(color: style.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        // Legend
        Wrap(
          spacing: AppTheme.space12,
          runSpacing: 4,
          children: sorted.take(4).map((entry) {
            final style = EmotionStyle.fromEmotion(entry.key);
            final pct = ((entry.value / total) * 100).round();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: style.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${style.label} $pct%',
                  style: AppTheme.captionStyle.copyWith(fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
